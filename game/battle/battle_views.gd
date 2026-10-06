class_name BattleViews
extends RefCounted
## Traduit l'état du combat en vues de l'interface ([BattleCardView], [BattleMoveView]) :
## des chaînes et des entiers, pour que les composants de `game/ui/battle/` ne connaissent
## ni le moteur ni les données (jalon-04.md §3.8, §14.2). Classe pure, statique.

## Actions de la grille disponibles contre un Pokémon sauvage (jalons 5B et 5D) : ATTAQUER, SAC
## (lancer une Ball) et FUITE ; ÉQUIPE s'y ajoute par [method with_team] (jalon 7).
## Clés : ActionGrid.ACTIONS.
const WILD_BATTLE_ACTIONS: Dictionary[StringName, bool] = {
	&"attack": true, &"bag": true, &"run": true,
}

## Actions de la grille disponibles contre [param trainer] : ATTAQUER, et SAC si
## [member TrainerData.allow_bag] (décision de Kevin du 2026-10-03 : SAC contre tous les
## Dresseurs ; le combat du labo le garde muet, décision n° 12). ÉQUIPE et FUITE restent
## atténués (pas de changement de Pokémon, pas de fuite contre un dresseur). Sans dresseur :
## SAC permis. ÉQUIPE s'y ajoute par [method with_team] (jalon 7). Clés : ActionGrid.ACTIONS.
static func trainer_actions(trainer: TrainerData) -> Dictionary[StringName, bool]:
	var actions: Dictionary[StringName, bool] = {&"attack": true}
	if trainer == null or trainer.allow_bag:
		actions[&"bag"] = true
	return actions


## [param actions] avec ÉQUIPE active si l'équipe du joueur compte au moins deux Pokémon
## ([param party_size]) ; seul, il n'aurait personne à envoyer (ÉQUIPE reste atténué, le combat du
## labo ne change pas). Défaut du jalon 7 (jalon-07.md §15.23). Copie : l'original ne change pas.
static func with_team(actions: Dictionary[StringName, bool],
		party_size: int) -> Dictionary[StringName, bool]:
	var result := actions.duplicate()
	if party_size > 1:
		result[&"team"] = true
	return result


## Le panneau ÉQUIPE (jalon 7) : un [BattlePartyView] par Pokémon de l'équipe du joueur, dans
## l'ordre de l'équipe ; le Pokémon en jeu est « actif » ; [member BattlePartyView.can_send]
## suit [method Battle.check_switch], et la raison vient de [param texts]
## (« switch_reason_active », « switch_reason_fainted »).
static func party(battle: Battle, data: PokemonData,
		texts: BattleText) -> Array[BattlePartyView]:
	var views: Array[BattlePartyView] = []
	var side := battle.get_player_side()
	var active := side.active.pokemon if side.active != null else null
	var chart := data.get_type_chart()
	var members := side.party.get_all()
	for i: int in members.size():
		var pokemon := members[i]
		var view := BattlePartyView.new()
		view.party_index = i
		view.species_id = pokemon.species_id
		view.display_name = pokemon.display_name(data)
		view.level = pokemon.level
		view.hp = pokemon.hp
		view.max_hp = pokemon.max_hp()
		var species := data.get_species(pokemon.species_id)
		if species != null:
			view.type_ids = species.types.duplicate()
			for type: StringName in species.types:
				view.type_names.append(chart.get_type_name(type))
		view.status_text = TeamMemberView.STATUS_FAINTED if pokemon.is_fainted() else ""
		view.active = pokemon == active and not pokemon.is_fainted()
		var check := battle.check_switch(i)
		view.can_send = check == Battle.SwitchCheck.OK
		match check:
			Battle.SwitchCheck.ACTIVE:
				view.reason = texts.get_template(&"switch_reason_active")
			Battle.SwitchCheck.FAINTED:
				view.reason = texts.get_template(&"switch_reason_fainted")
		views.append(view)
	return views


## Carte d'information du Pokémon envoyé par [param event] (SENT_OUT) : nom, sexe, niveau,
## PV ; PV chiffrés du côté du joueur seulement (dossier 05 §5).
static func card(event: BattleEvent) -> BattleCardView:
	return BattleCardView.new(event.pokemon_name, card_gender(event.gender), event.level,
		event.hp, event.max_hp, event.side == BattleEvent.SideId.PLAYER)


## Sexe du modèle Pokémon → sexe affiché par la carte.
static func card_gender(gender: Pokemon.Gender) -> BattleCardView.Gender:
	match gender:
		Pokemon.Gender.MALE:
			return BattleCardView.Gender.MALE
		Pokemon.Gender.FEMALE:
			return BattleCardView.Gender.FEMALE
	return BattleCardView.Gender.NONE


## Cartes des capacités de [param pokemon], dans l'ordre de ses emplacements (1 à 4) :
## nom, type (identifiant et nom affiché), catégorie, PP restants et max, puissance,
## précision, description. Une capacité inconnue des données est omise (push_error).
static func moves(pokemon: Pokemon, data: PokemonData) -> Array[BattleMoveView]:
	var views: Array[BattleMoveView] = []
	var chart := data.get_type_chart()
	for slot: MoveSlot in pokemon.moves:
		var move := data.get_move(slot.move_id)
		if move == null:
			push_error("BattleViews : capacité inconnue « %s »" % slot.move_id)
			continue
		views.append(BattleMoveView.new(move.name, move.type, chart.get_type_name(move.type),
			move_category(move.category), slot.pp, slot.max_pp, move.power, move.accuracy,
			move.description))
	return views


## Carte de la capacité [param move_id] proposée à l'apprentissage (panneau d'oubli, jalon
## 5C) : PP pleins (elle n'a jamais servi). Null si la capacité est inconnue des données.
static func offered_move(move_id: StringName, data: PokemonData) -> BattleMoveView:
	var move := data.get_move(move_id)
	if move == null:
		push_error("BattleViews : capacité inconnue « %s »" % move_id)
		return null
	return BattleMoveView.new(move.name, move.type,
		data.get_type_chart().get_type_name(move.type), move_category(move.category),
		move.pp, move.pp, move.power, move.accuracy, move.description)


## Lignes du bilan de fin de combat ([ExpSummaryRowView], demande n° 1), une par Pokémon de
## [param summary], dans l'ordre de l'équipe : « +11 XP », « Nv. 8 », puis pour chaque niveau
## gagné « Nv. 9 » et les gains de statistiques cumulés jusque-là. Les vignettes sont posées
## par l'appelant (textures).
static func exp_summary(summary: ExpSummary, texts: BattleText) -> Array[ExpSummaryRowView]:
	var rows: Array[ExpSummaryRowView] = []
	for entry: ExpSummaryEntry in summary.get_entries():
		var row := ExpSummaryRowView.new()
		row.display_name = entry.pokemon_name
		row.gain_text = texts.summary_exp(entry.exp_gained)
		row.start_level_text = texts.summary_level(entry.start_level)
		for i: int in entry.levels_gained():
			row.level_texts.append(texts.summary_level(entry.level_ups[i].level))
			row.stat_texts.append(texts.summary_stats(entry.stat_gains(i + 1)))
		row.segments = entry.segments.duplicate()
		row.points = entry.points.duplicate()
		rows.append(row)
	return rows


## Catégorie du modèle → catégorie affichée par la fiche.
static func move_category(category: MoveData.Category) -> BattleMoveView.Category:
	match category:
		MoveData.Category.SPECIAL:
			return BattleMoveView.Category.SPECIAL
		MoveData.Category.STATUS:
			return BattleMoveView.Category.STATUS
	return BattleMoveView.Category.PHYSICAL


## Objets du Sac de combat ([BagEntryView]) : enveloppe de [method BagQuery.entries] dans
## [param context] (combat sauvage par défaut, pertinence : Balls puis soins ; combat de
## dresseur : les Balls n'y sont pas utilisables). Un objet inconnu de [param items] est omis
## (push_error). Nom au singulier, catégorie en identifiant des données ;
## [member BagEntryView.usable] selon les règles des données (Balls et soins).
static func bag_entries(bag: Bag, items: ItemLibrary,
		context: StringName = BagQuery.CONTEXT_WILD_BATTLE) -> Array[BagEntryView]:
	return BagQuery.entries(bag, items, context)
