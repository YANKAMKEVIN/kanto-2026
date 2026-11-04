class_name LocalTrade
extends RefCounted
## Terminal d'échange local (jalon 32, T4 ; `jalon-32.md` §1.2, N-15 : tous les Centres
## Pokémon). Classe pure, sans scène ni écran (l'écran est T5).
##
## Le terminal simule l'échange d'un Pokémon avec soi-même : le Pokémon part, évolue selon sa
## règle `"method": "trade"` ([enum EvolutionRule.Method] TRADE) et revient **le même
## individu** : identifiant, surnom, sexe, IV, EV, XP, niveau, capacités, PP, statut, rencontre
## et dresseur d'origine gardés (seuls l'espèce et les statistiques changent,
## [method Pokemon.evolve_into]). Ce choix remplace le « Cordon d'échange » [D] du J14
## (dossier 17 E-3), jamais codé : le plan J32 et N-15 le priment.
##
## Atomique ([method execute]) : l'évolution se fait d'abord sur une **copie de travail**
## (`to_dict` → `from_dict`) ; si quoi que ce soit échoue, l'équipe n'a pas changé. Sinon la
## copie prend la place de l'original, au même rang, dans un seul bloc synchrone : aucune
## sauvegarde ne peut tomber entre le retrait et l'ajout (même règle qu'[InGameTrade]), et une
## équipe pleine ne perd rien. Les capacités à apprendre sont rendues à la présentation
## ([MoveLearnPrompt]), comme pour une évolution par niveau.

enum Status {
	DONE, ## Échange fait : le Pokémon a évolué.
	INCOMPATIBLE, ## Le Pokémon n'a pas d'évolution par échange connue des données.
	INVALID, ## Index ou données invalides ; rien n'a changé.
}

## Textes [D] (`jalon-32.md` §3, deux lignes de 40 caractères au plus).
const PICK_TEXT: String = "Choisis un Pokémon à échanger."
const CONFIRM_TEXT: String = "Échanger %s ?"
const RESULT_TEXT: String = "%s a évolué !"
## Raison d'une place refusée dans le choix [D].
const REFUSED_REASON: String = "Rien ne se passerait"


## Règle TRADE qui s'applique à [param pokemon] (première règle vers une espèce connue ; une
## règle avec objet, JOH0 `jalon-joh0.md` §2.8, ne compte que si [param bag] contient l'objet),
## ou null.
static func trade_rule(pokemon: Pokemon, data: PokemonData, bag: Bag = null) -> EvolutionRule:
	if pokemon == null or data == null:
		return null
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return null
	for rule: EvolutionRule in species.evolutions:
		if rule.method != EvolutionRule.Method.TRADE or not data.has_species(rule.into):
			continue
		if not rule.item.is_empty() and (bag == null or not bag.has(rule.item)):
			continue
		return rule
	return null


## Espèce obtenue par échange de [param pokemon] ([method trade_rule]), ou &"".
static func trade_target(pokemon: Pokemon, data: PokemonData, bag: Bag = null) -> StringName:
	var rule := trade_rule(pokemon, data, bag)
	return rule.into if rule != null else &""


## Objet que l'échange de [param pokemon] consommerait (JOH0 : Peau Métal…), ou &"".
static func trade_item(pokemon: Pokemon, data: PokemonData, bag: Bag = null) -> StringName:
	var rule := trade_rule(pokemon, data, bag)
	return rule.item if rule != null else &""


## Index des Pokémon de [param party] que le terminal accepte, dans l'ordre de l'équipe.
static func candidates(party: Party, data: PokemonData, bag: Bag = null) -> Array[int]:
	var result: Array[int] = []
	if party == null:
		return result
	for i: int in party.size():
		if not trade_target(party.get_at(i), data, bag).is_empty():
			result.append(i)
	return result


## Échange le Pokémon d'index [param index]. Rend `{status, pokemon, from, into, moves,
## companion_evolved}` : `pokemon` est l'individu évolué (désormais dans l'équipe), `moves` les
## capacités à proposer ([method Evolution.evolve]). Si le Pokémon est le compagnon
## ([param companion_uid]), `companion_evolved` est vrai : l'appelant rafraîchit son apparence
## (même identifiant, nouvelle espèce). Pokédex : la nouvelle espèce est vue et capturée.
static func execute(party: Party, index: int, data: PokemonData, pokedex: Pokedex = null,
		map: StringName = &"", date: String = "", companion_uid: String = "",
		bag: Bag = null) -> Dictionary:
	var result := {"status": Status.INVALID, "pokemon": null, "from": &"", "into": &"",
		"moves": [] as Array[StringName], "companion_evolved": false, "item": &""}
	if party == null or data == null or index < 0 or index >= party.size():
		return result
	var original := party.get_at(index)
	var rule := trade_rule(original, data, bag)
	var into := rule.into if rule != null else &""
	if into.is_empty():
		result["status"] = Status.INCOMPATIBLE
		return result
	original.ensure_uid()
	# Copie de travail : tout ce qui peut échouer se fait ici, l'original n'est pas touché.
	var copy := Pokemon.from_dict(original.to_dict(), data)
	if copy == null:
		return result
	var moves := Evolution.evolve(copy, into, data)
	if copy.species_id != into or copy.uid != original.uid:
		return result
	# Bloc synchrone : remplacement au même rang (équipe pleine : retrait puis ajout) ; l'objet
	# de la règle (JOH0) part dans le même bloc : jamais un objet consommé sans évolution.
	party.remove_at(index)
	party.add(copy)
	party.move(party.size() - 1, index)
	if not rule.item.is_empty() and bag != null:
		bag.remove(rule.item)
		result["item"] = rule.item
	if pokedex != null:
		pokedex.mark_seen(into, map, date)
		pokedex.mark_caught(into, map, date)
	result["status"] = Status.DONE
	result["pokemon"] = copy
	result["from"] = original.species_id
	result["into"] = into
	result["moves"] = moves
	result["companion_evolved"] = not companion_uid.is_empty() and copy.uid == companion_uid
	return result


## Vue du choix pour le [PartyPicker] : toute l'équipe, les places non compatibles avec leur
## raison.
static func picker_view(party: Party, data: PokemonData, bag: Bag = null) -> PartyPickerView:
	var picker := PartyPickerView.new()
	picker.title = PICK_TEXT
	var accepted := candidates(party, data, bag)
	var members := party.get_all()
	for i: int in members.size():
		var ok := i in accepted
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			ok, "" if ok else REFUSED_REASON, REFUSED_REASON))
	return picker
