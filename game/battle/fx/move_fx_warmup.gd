class_name MoveFxWarmup
extends RefCounted
## Préchauffage des effets de combat (RP-263, QA S24 CV.1 : à-coup au premier effet du premier
## combat de la partie). Classe pure : choisit ce qu'il faut préparer ; [method MoveFxPlayer.warm_up]
## le dessine une fois, à peine visible, pendant l'entrée en combat (pipelines de rendu des
## mélanges normal et additif, sprites, traits, émetteurs de particules, art peint des familles).
##
## Couverture : les attaques connues des deux équipes (une chorégraphie par attaque, issue « le
## coup porte »), donc leurs familles, variantes d'impact, modificateurs et signatures.


## Chorégraphies des attaques connues des Pokémon de [param parties] (sans doublon, dans l'ordre
## des équipes). Une attaque inconnue des données est ignorée.
static func plans_for(catalog: MoveFxCatalog, data: PokemonData, parties: Array[Party],
		mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL) -> Array[MoveFxPlan]:
	var plans: Array[MoveFxPlan] = []
	var seen: Dictionary[StringName, bool] = {}
	for party: Party in parties:
		if party == null:
			continue
		for pokemon: Pokemon in party.get_all():
			for slot: MoveSlot in pokemon.moves:
				if seen.has(slot.move_id):
					continue
				seen[slot.move_id] = true
				var move := data.get_move(slot.move_id)
				if move == null:
					continue
				var category := StringName(MoveData.CATEGORY_NAMES.find_key(move.category))
				plans.append(MoveFxPlan.build(catalog, catalog.entry(move.id, move.type, category),
					move, null, mode))
	return plans


## Familles couvertes par [param plans] (sans doublon).
static func families(plans: Array[MoveFxPlan]) -> Array[StringName]:
	var found: Array[StringName] = []
	for plan: MoveFxPlan in plans:
		if not found.has(plan.family):
			found.append(plan.family)
	return found


## Identifiants d'art peint de [param plans] (tous rôles, sans doublon, triés).
static func art_ids(plans: Array[MoveFxPlan]) -> Array[StringName]:
	var found: Array[StringName] = []
	for plan: MoveFxPlan in plans:
		for id: StringName in plan.art.values():
			if not found.has(id):
				found.append(id)
	found.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return found
