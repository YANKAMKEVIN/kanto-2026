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


## Espèce obtenue par échange de [param pokemon] (première règle TRADE vers une espèce
## connue), ou &"".
static func trade_target(pokemon: Pokemon, data: PokemonData) -> StringName:
	if pokemon == null or data == null:
		return &""
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return &""
	for rule: EvolutionRule in species.evolutions:
		if rule.method == EvolutionRule.Method.TRADE and data.has_species(rule.into):
			return rule.into
	return &""


## Index des Pokémon de [param party] que le terminal accepte, dans l'ordre de l'équipe.
static func candidates(party: Party, data: PokemonData) -> Array[int]:
	var result: Array[int] = []
	if party == null:
		return result
	for i: int in party.size():
		if not trade_target(party.get_at(i), data).is_empty():
			result.append(i)
	return result


## Échange le Pokémon d'index [param index]. Rend `{status, pokemon, from, into, moves,
## companion_evolved}` : `pokemon` est l'individu évolué (désormais dans l'équipe), `moves` les
## capacités à proposer ([method Evolution.evolve]). Si le Pokémon est le compagnon
## ([param companion_uid]), `companion_evolved` est vrai : l'appelant rafraîchit son apparence
## (même identifiant, nouvelle espèce). Pokédex : la nouvelle espèce est vue et capturée.
static func execute(party: Party, index: int, data: PokemonData, pokedex: Pokedex = null,
		map: StringName = &"", date: String = "", companion_uid: String = "") -> Dictionary:
	var result := {"status": Status.INVALID, "pokemon": null, "from": &"", "into": &"",
		"moves": [] as Array[StringName], "companion_evolved": false}
	if party == null or data == null or index < 0 or index >= party.size():
		return result
	var original := party.get_at(index)
	var into := trade_target(original, data)
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
	# Bloc synchrone : remplacement au même rang (équipe pleine : retrait puis ajout).
	party.remove_at(index)
	party.add(copy)
	party.move(party.size() - 1, index)
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
static func picker_view(party: Party, data: PokemonData) -> PartyPickerView:
	var picker := PartyPickerView.new()
	picker.title = PICK_TEXT
	var accepted := candidates(party, data)
	var members := party.get_all()
	for i: int in members.size():
		var ok := i in accepted
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			ok, "" if ok else REFUSED_REASON, REFUSED_REASON))
	return picker
