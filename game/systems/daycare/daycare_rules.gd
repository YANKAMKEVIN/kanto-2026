class_name DaycareRules
extends RefCounted
## Règles de la Pension Pokémon (J15, 15.0 ; dossier 18 : V-1, V-2, F-1 à F-4 et §6, décisions de
## Kevin du 2026-10-11), sur le modèle de [StorageRules] : classe pure et statique, sans écran.
## Les nombres viennent de [DaycareConfig] (`data/daycare/daycare.json`).
##
## - **Dépôt** : un seul Pokémon (OCCUPIED sinon) ; jamais le dernier Pokémon apte de l'équipe
##   (refus LAST_POKEMON / LAST_ABLE de [method StorageRules.keep_status]) ; un K.O. peut être
##   déposé. Rien ne change pendant le séjour.
## - **Prix** : [member DaycareConfig.price_base] + [member DaycareConfig.price_per_level] par
##   niveau gagné (F-2).
## - **Paiement** : argent insuffisant → TAKE_ALL : le Pokémon est rendu et tout l'argent est
##   pris ; REFUSE : refus NO_MONEY. Les règles ne touchent pas à l'argent : elles disent le
##   montant à débiter ([member DaycareWithdrawal.paid]), l'appelant le débite.
## - **Retrait** : refus EMPTY, puis PARTY_FULL, puis NO_MONEY. Sinon l'XP en attente passe par
##   [method Pokemon.gain_exp], le Pokémon est soigné (PV, PP, statut) et rejoint la fin de
##   l'équipe ; le plan rendu liste les capacités à proposer dans l'ordre (V-2) et l'évolution à
##   proposer ensuite (F-3).
## - **Évolution (F-3)** : proposée seulement si au moins un niveau a été gagné à la Pension et
##   que [method Evolution.level_up_target] donne une espèce (même règle qu'en fin de combat :
##   une évolution annulée revient au prochain niveau gagné).

enum Status {
	OK,
	EMPTY, ## Retrait : la Pension est vide.
	OCCUPIED, ## Dépôt : la Pension garde déjà un Pokémon (V-1).
	PARTY_FULL, ## Retrait : l'équipe a déjà 6 Pokémon.
	LAST_POKEMON, ## Dépôt : l'équipe serait vide.
	LAST_ABLE, ## Dépôt : il ne resterait que des Pokémon K.O.
	NOT_FOUND, ## Dépôt : aucune place à cet index.
	NO_MONEY, ## Retrait : argent insuffisant, politique REFUSE seulement.
}


## Raison d'un refus de dépôt du Pokémon [param index] de [param party], ou OK.
static func can_deposit(daycare: Daycare, party: Party, index: int) -> Status:
	if party == null or party.get_at(index) == null:
		return Status.NOT_FOUND
	if daycare == null or not daycare.is_empty():
		return Status.OCCUPIED
	match StorageRules.keep_status(party, index):
		StorageRules.Status.LAST_POKEMON:
			return Status.LAST_POKEMON
		StorageRules.Status.LAST_ABLE:
			return Status.LAST_ABLE
	return Status.OK


## Confie le Pokémon [param index] de l'équipe à la Pension (la même instance, sans soin).
## Refus : rien ne change.
static func deposit(daycare: Daycare, party: Party, index: int, data: PokemonData) -> Status:
	var status := can_deposit(daycare, party, index)
	if status == Status.OK:
		daycare.put(party.remove_at(index), data)
	return status


## Prix du retrait pour [param levels] niveaux gagnés.
static func price(levels: int, config: DaycareConfig) -> int:
	return config.price_base + config.price_per_level * maxi(levels, 0)


## Montant réellement débité pour [param amount_due] quand le joueur a [param money] : le prix
## s'il suffit ; sinon tout l'argent (TAKE_ALL) ou rien (REFUSE, le retrait est refusé).
static func payment(money: int, amount_due: int, config: DaycareConfig) -> int:
	if money >= amount_due:
		return amount_due
	if config.money_policy == DaycareConfig.MoneyPolicy.TAKE_ALL:
		return maxi(money, 0)
	return 0


## Raison d'un refus de retrait, ou OK.
static func can_withdraw(daycare: Daycare, party: Party, money: int, config: DaycareConfig,
		data: PokemonData) -> Status:
	if daycare == null or daycare.is_empty():
		return Status.EMPTY
	if party == null or party.is_full():
		return Status.PARTY_FULL
	if config.money_policy == DaycareConfig.MoneyPolicy.REFUSE \
			and money < price(daycare.levels_gained(data), config):
		return Status.NO_MONEY
	return Status.OK


## Ce que le gardien annonce (F-4), sans rien changer.
static func preview(daycare: Daycare, party: Party, money: int, config: DaycareConfig,
		data: PokemonData) -> DaycarePreview:
	var view := DaycarePreview.new()
	view.status = can_withdraw(daycare, party, money, config, data)
	if daycare == null or daycare.is_empty():
		return view
	view.pokemon = daycare.pokemon
	view.levels_gained = daycare.levels_gained(data)
	view.level_after = daycare.level_after(data)
	view.price = price(view.levels_gained, config)
	view.paid = payment(money, view.price, config)
	return view


## Rend le Pokémon gardé et dit ce qu'il reste à proposer ([DaycareWithdrawal]). Refus : rien ne
## change. Le montant [member DaycareWithdrawal.paid] reste à débiter par l'appelant.
static func withdraw(daycare: Daycare, party: Party, money: int, config: DaycareConfig,
		data: PokemonData) -> DaycareWithdrawal:
	var plan := DaycareWithdrawal.new()
	plan.status = can_withdraw(daycare, party, money, config, data)
	if daycare != null:
		plan.pokemon = daycare.pokemon
	if plan.status != Status.OK:
		return plan
	plan.price = price(daycare.levels_gained(data), config)
	plan.paid = payment(money, plan.price, config)
	var pending := daycare.pending_exp
	var mon := daycare.take()
	plan.level_ups = mon.gain_exp(pending, data)
	for step: LevelUp in plan.level_ups:
		for move_id: StringName in step.moves:
			if not plan.moves.has(move_id):
				plan.moves.append(move_id)
	if config.evolve_on_withdraw and not plan.level_ups.is_empty():
		plan.evolution = Evolution.level_up_target(mon, data)
	mon.heal_full()
	party.add(mon)
	return plan
