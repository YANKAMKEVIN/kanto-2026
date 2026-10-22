extends GutTest
## Données du jalon 21 (T5 ; docs/tech/jalon-21.md §2.10, §2.11, annexe A) : Ronflex, Ptitard et
## Tentacool (data/pokemon/species/kanto_j21.json), Constriction et Bouclier pour les learnsets
## complets (moves/j21.json), entrées de Pokédex d'Ossatueur, Ronflex, Ptitard et Tentacool.
## Fichier séparé des tests partagés que d'autres jalons modifient en parallèle.
##
## Dépend des J17 (Coup d'Boule, Hypnose, Soporifik) et J19 (Ultralaser, Ossatueur) : ne passe
## qu'après la fusion de main (T9).

## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, capture, croissance]
## (PokeAPI, valeurs actuelles comme les espèces existantes).
const SPECIES := {
	&"poliwag": [60, "Ptitard", [&"water"], 40, 50, 40, 40, 40, 90, 60, 255,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"tentacool": [72, "Tentacool", [&"water", &"poison"], 40, 40, 35, 50, 100, 70, 67, 190,
		ExpCurve.Rate.SLOW],
	&"snorlax": [143, "Ronflex", [&"normal"], 160, 110, 65, 65, 110, 30, 189, 25,
		ExpCurve.Rate.SLOW],
}
## Capacités au niveau de rencontre (Rouge/Bleu ; L-12 pour Ronflex).
const MOVES_AT := {
	&"snorlax": [30, [&"headbutt", &"amnesia", &"rest"]],
	&"marowak": [30, [&"bone_club", &"growl", &"leer", &"focus_energy"]],
	&"poliwag": [22, [&"bubble", &"hypnosis", &"water_gun"]],
	&"tentacool": [24, [&"supersonic", &"wrap", &"poison_sting", &"water_gun"]],
}
## Pokédex : [taille, poids, description] (dossier 24 §15.10 ; annexe A de jalon-21.md, Q-3).
const POKEDEX := {
	&"marowak": [1.0, 45.0, "Il manie l'os qu'il tient depuis l'enfance. Devenu fort, il protège"
		+ " farouchement les siens."],
	&"snorlax": [2.1, 460.0, "Il ne fait que manger et dormir. Quand il s'endort au milieu d'un"
		+ " chemin, plus personne ne passe."],
	&"poliwag": [0.6, 12.4, "Sa peau est si fine qu'on voit ses entrailles en spirale. Il marche"
		+ " mal sur ses jambes toutes neuves."],
	&"tentacool": [0.9, 45.5, "Il dérive près de la surface. Son corps presque transparent le"
		+ " rend difficile à voir dans l'eau."],
}

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_data_loads_without_error() -> void:
	assert_eq(_data.get_errors(), PackedStringArray())


func test_species_values() -> void:
	for id: StringName in SPECIES:
		var row: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name, species.types], [row[0], row[1], row[2]])
		var stats: Array = []
		for stat: StringName in [&"hp", &"atk", &"def", &"spa", &"spd", &"spe"]:
			stats.append(species.base_stats[stat])
		assert_eq(stats, row.slice(3, 9), String(id))
		assert_eq([species.base_exp, species.catch_rate, species.growth_rate],
			[row[9], row[10], row[11]], String(id))
		assert_eq(species.source, "res://data/pokemon/species/kanto_j21.json")
	assert_eq(_data.get_species(&"snorlax").male_ratio, 0.875)


func test_moves_at_encounter_level() -> void:
	for id: StringName in MOVES_AT:
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		var level: int = MOVES_AT[id][0]
		var got: Array = species.moves_at(level)
		var expected: Array = MOVES_AT[id][1]
		got.sort()
		expected = expected.duplicate()
		expected.sort()
		assert_eq(got, expected, "%s N%d" % [id, level])


func test_no_evolution_towards_a_missing_species() -> void:
	# Ptitard → Têtarte et Tentacool → Tentacruel : omises tant que la cible manque (§2.11).
	for id: StringName in SPECIES:
		var species := _data.get_species(id)
		if species == null:
			fail_test(String(id))
			continue
		for rule: EvolutionRule in species.evolutions:
			assert_true(_data.has_species(rule.into), "%s → %s" % [id, rule.into])
	assert_eq(_data.get_species(&"snorlax").evolutions.size(), 0)


func test_learnset_moves_exist() -> void:
	for id: StringName in SPECIES:
		var species := _data.get_species(id)
		if species == null:
			continue
		for move_id: StringName in species.learnset_moves():
			assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])


func test_constrict_and_barrier() -> void:
	var constrict := _data.get_move(&"constrict")
	assert_not_null(constrict)
	if constrict != null:
		assert_eq([constrict.name, constrict.type, constrict.power, constrict.accuracy,
			constrict.pp], ["Constriction", &"normal", 10, 100, 35])
		var effect := constrict.effects[0]
		assert_eq([effect.kind, effect.stat, effect.stages, effect.target, effect.chance],
			[MoveEffect.Kind.STAT_STAGE, &"spe", -1, MoveEffect.Target.FOE, 10])
	var barrier := _data.get_move(&"barrier")
	assert_not_null(barrier)
	if barrier != null:
		assert_eq([barrier.name, barrier.type, barrier.category, barrier.pp],
			["Bouclier", &"psychic", MoveData.Category.STATUS, 20])
		var effect := barrier.effects[0]
		assert_eq([effect.kind, effect.stat, effect.stages, effect.target],
			[MoveEffect.Kind.STAT_STAGE, &"def", 2, MoveEffect.Target.SELF])
	for move: MoveData in [constrict, barrier]:
		if move != null:
			assert_eq(move.pending_effects.size(), 0, move.name)


func test_pokedex_entries() -> void:
	var lib := PokedexLibrary.new()
	lib.load_file()
	for id: StringName in POKEDEX:
		var info := lib.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(POKEDEX[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(POKEDEX[id][1]), 0.001, String(id))
		assert_eq(info.description, POKEDEX[id][2])
		assert_eq(info.notes.size(), 0, "%s : aucune note au J21 [D]" % id)
