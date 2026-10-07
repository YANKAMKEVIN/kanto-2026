class_name Evolution
extends RefCounted
## Règles d'évolution (décision de Kevin, jalon 4 §8 point 4). Statique et pur : dit
## [b]vers quoi[/b] un Pokémon peut évoluer, [b]qui[/b] évolue à la fin d'un combat
## ([method candidates], jalon-09.md §2.3.1) et [b]ce qui change[/b] ([method evolve] : espèce,
## statistiques, capacités à apprendre). La séquence à l'écran (annulable) est jouée par
## [EvolutionDirector], qui n'appelle [method evolve] qu'une fois la transformation menée à son
## terme (dossier 04 §7). Les règles « trade » ne sont jamais déclenchées ici (adaptation solo à
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


## Pokémon de [param party] qui évoluent à la fin d'un combat gagné ou d'une capture
## (jalon-09.md §2.3.1) : ceux dont la place figure dans [param leveled] (ils ont gagné au moins
## un niveau dans ce combat, [method ExpSummary.leveled_indices]), debout, et dont
## [method level_up_target] n'est pas vide ; dans l'ordre de l'équipe. Une seule évolution par
## Pokémon et par combat : un Chenipan passé du niveau 6 au niveau 10 devient Chrysacier, et
## Papilusion attendra le prochain niveau gagné. Une évolution annulée n'est notée nulle part :
## elle revient au prochain niveau gagné (Rouge/Bleu, Q-2). L'issue du combat n'est pas jugée
## ici : l'appelant ne demande les candidats qu'après une victoire ou une capture.
static func candidates(party: Party, leveled: Array[int], data: PokemonData) \
		-> Array[EvolutionCandidate]:
	var result: Array[EvolutionCandidate] = []
	if party == null or data == null:
		return result
	for index: int in party.size():
		if not leveled.has(index):
			continue
		var pokemon := party.get_at(index)
		if pokemon == null or pokemon.is_fainted():
			continue
		var into := level_up_target(pokemon, data)
		if not into.is_empty():
			result.append(EvolutionCandidate.new(index, pokemon.species_id, into))
	return result


## Fait évoluer [param pokemon] en [param into] ([method Pokemon.evolve_into] : statistiques
## recalculées, PV perdus gardés ; surnom, sexe, IV, EV, XP, niveau, rencontre, favori, statut,
## capacités et PP gardés) et renvoie les capacités de la nouvelle espèce que le Pokémon ne
## connaît pas encore, dans l'ordre des données, sans doublon : celles que la nouvelle espèce
## apprend entre le niveau où l'évolution est devenue possible (niveau de la règle) et le
## niveau actuel. Évolution au niveau de la règle : les capacités de ce niveau (Chrysacier
## apprend Armure au niveau 7, Q-5) ; évolution plus tardive (annulée puis reproposée, ou
## plusieurs niveaux gagnés d'un coup) : les mêmes capacités que si elle avait eu lieu à
## temps, jamais moins. Rien n'est appris ici (la présentation le fait, [MoveLearnPrompt]).
## Vide, et rien ne change, si l'espèce [param into] est inconnue.
static func evolve(pokemon: Pokemon, into: StringName, data: PokemonData) -> Array[StringName]:
	var result: Array[StringName] = []
	if pokemon == null or data == null:
		return result
	var from := _rule_level(data.get_species(pokemon.species_id), into, pokemon.level)
	if not pokemon.evolve_into(into, data):
		return result
	var species := data.get_species(into)
	for entry: Array in species.learnset:
		var level := int(entry[0])
		var move_id: StringName = entry[1]
		if level >= from and level <= pokemon.level and not pokemon.knows_move(move_id) \
				and not result.has(move_id):
			result.append(move_id)
	return result


## Niveau de la règle « level » de [param species] vers [param into] (au plus [param level]) ;
## [param level] s'il n'y en a pas (évolution par objet : les capacités du niveau actuel).
static func _rule_level(species: SpeciesData, into: StringName, level: int) -> int:
	if species == null:
		return level
	for rule: EvolutionRule in species.evolutions:
		if rule.into == into and rule.method == EvolutionRule.Method.LEVEL:
			return mini(rule.level, level)
	return level
