class_name Evolution
extends RefCounted
## Règles d'évolution (décision de Kevin, jalon 4 §8 point 4). Statique et pur : dit
## [b]vers quoi[/b] un Pokémon peut évoluer ; l'évolution elle-même est
## [method Pokemon.evolve_into], appelée par la présentation (moment d'évolution,
## dossier 04 §7). Les règles « trade » ne sont jamais déclenchées ici (adaptation solo à
## décider par Kevin).


## Espèce vers laquelle [param pokemon] évolue à son niveau actuel (première règle
## « level » satisfaite), ou &"" s'il n'y en a pas.
static func level_up_target(pokemon: Pokemon, data: PokemonData) -> StringName:
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return &""
	for rule: EvolutionRule in species.evolutions:
		if rule.method == EvolutionRule.Method.LEVEL and pokemon.level >= rule.level:
			return rule.into
	return &""


## Espèce obtenue en utilisant l'objet [param item_id] sur [param pokemon], ou &"".
static func item_target(pokemon: Pokemon, item_id: StringName, data: PokemonData) -> StringName:
	var species := data.get_species(pokemon.species_id)
	if species == null or item_id.is_empty():
		return &""
	for rule: EvolutionRule in species.evolutions:
		if rule.method == EvolutionRule.Method.ITEM and rule.item == item_id:
			return rule.into
	return &""
