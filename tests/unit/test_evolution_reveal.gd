extends GutTest
## EvolutionReveal : la lignée sans spoiler (jalon-06.md §3.3 ; Q-9 verrouillée : avant
## l'activation « ??? » ; après, seulement ce que le joueur a découvert ; ni niveau, ni nom
## d'une évolution inconnue ; Q-1 de Kevin, 2026-10-06 : son numéro, pour la silhouette).

var _data: PokemonData
var _dex: Pokedex


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	# Une lignée à branches (Évoli), absente des données du J6 : numéros hors de Kanto.
	var species := {}
	for entry: Array in [["eevee", 1001, "Évoli", "normal"], ["vaporeon", 1002, "Aquali",
			"water"], ["jolteon", 1003, "Voltali", "electric"], ["flareon", 1004, "Pyroli",
			"fire"]]:
		species[entry[0]] = {
			"dex": entry[1], "name": entry[2], "types": [entry[3]],
			"base_stats": {"hp": 55, "atk": 55, "def": 50, "spa": 45, "spd": 65, "spe": 55},
			"male_ratio": 0.875, "growth_rate": "medium_fast", "base_exp": 65,
			"catch_rate": 45, "learnset": [[1, "tackle"]],
		}
	species["eevee"]["evolutions"] = [
		{"into": "vaporeon", "method": "item", "item": "water_stone"},
		{"into": "jolteon", "method": "item", "item": "thunder_stone"},
		{"into": "flareon", "method": "item", "item": "fire_stone"},
	]
	assert_true(_data.add_species_from_dict(species, "test"))


func before_each() -> void:
	_dex = Pokedex.new()


func _text(species: StringName, visible: bool = true) -> String:
	return EvolutionReveal.text(EvolutionReveal.chain(species, _data, _dex, visible))


func test_family_in_columns() -> void:
	var expected: Array[Array] = [[&"charmander"], [&"charmeleon"], [&"charizard"]]
	assert_eq(EvolutionReveal.family(&"charmeleon", _data), expected)
	assert_eq(EvolutionReveal.family(&"charizard", _data), expected, "depuis le dernier stade")
	assert_eq(EvolutionReveal.family(&"vaporeon", _data),
		[[&"eevee"], [&"vaporeon", &"jolteon", &"flareon"]] as Array[Array])
	assert_eq(EvolutionReveal.family(&"missingno", _data), [] as Array[Array])


func test_before_activation_only_question_marks() -> void:
	_dex.mark_seen(&"charmeleon")
	_dex.mark_seen(&"charizard")
	var stages := EvolutionReveal.chain(&"charmander", _data, _dex, false)
	assert_eq(stages.size(), 1, "« Évolution : ??? », même si Reptincel a été vu")
	assert_false(stages[0].known)
	assert_eq(stages[0].species_id, &"")
	assert_eq(EvolutionReveal.text(stages), "???")
	assert_eq(_text(&"charizard", false), "???", "dernier stade : la section existe aussi")


func test_after_activation_only_what_was_seen() -> void:
	assert_eq(_text(&"charmander"), "Salamèche → ???",
		"un seul « ??? » : jamais le nombre de stades restants")
	_dex.mark_seen(&"charmeleon")
	assert_eq(_text(&"charmander"), "Salamèche → Reptincel → ???")
	_dex.mark_seen(&"charizard")
	assert_eq(_text(&"charmander"), "Salamèche → Reptincel → Dracaufeu")


func test_a_gap_between_two_known_stages() -> void:
	_dex.mark_seen(&"charizard")
	assert_eq(_text(&"charmander"), "Salamèche → ??? → Dracaufeu")


func test_the_current_species_is_always_known() -> void:
	assert_eq(_text(&"charmeleon"), "??? → Reptincel → ???")
	var stages := EvolutionReveal.chain(&"charmeleon", _data, _dex, true)
	assert_true(stages[1].current)
	assert_eq(stages[1].species_id, &"charmeleon")
	assert_false(stages[0].current)


func test_unknown_stages_carry_no_species_nor_name() -> void:
	for stage: EvolutionStageView in EvolutionReveal.chain(&"pidgey", _data, _dex, true):
		if not stage.known:
			assert_eq(stage.species_id, &"")
			assert_eq(stage.name, "???")


func test_known_stages_carry_their_number() -> void:
	_dex.mark_seen(&"charmeleon")
	var stages := EvolutionReveal.chain(&"charmander", _data, _dex, true)
	assert_eq(stages[0].number, 4)
	assert_true(stages[0].known)
	assert_eq(stages[1].number, 5)
	assert_true(stages[1].known)


func test_unknown_stages_carry_their_number_for_the_silhouette() -> void:
	var stages := EvolutionReveal.chain(&"charmander", _data, _dex, true)
	assert_eq(stages.size(), 2)
	assert_false(stages[1].known, "indicateur inconnu")
	assert_eq(stages[1].number, 5, "Reptincel : silhouette")
	assert_eq(stages[1].name, "???")
	assert_eq(stages[1].species_id, &"")
	_dex.mark_seen(&"charizard")
	stages = EvolutionReveal.chain(&"charmander", _data, _dex, true)
	assert_eq(stages[1].number, 5, "un trou entre deux stades connus aussi")
	assert_false(stages[1].known)


func test_no_silhouette_when_the_stage_is_not_one_species() -> void:
	var stages := EvolutionReveal.chain(&"eevee", _data, _dex, true)
	assert_eq(stages[1].number, 0, "trois branches inconnues : aucune forme choisie")
	assert_false(stages[1].known)
	stages = EvolutionReveal.chain(&"charmander", _data, _dex, false)
	assert_eq(stages[0].number, 0, "avant l'activation : rond vide")
	assert_eq(EvolutionReveal.chain(&"vaporeon", _data, _dex, true)[0].number, 1001,
		"Évoli jamais vu, seul de sa colonne : silhouette")


func test_never_a_condition() -> void:
	_dex.mark_seen(&"wartortle")
	_dex.mark_seen(&"eevee")
	_dex.mark_seen(&"jolteon")
	for species: StringName in [&"squirtle", &"wartortle", &"bulbasaur", &"eevee"]:
		for visible: bool in [false, true]:
			var line := _text(species, visible)
			assert_false(line.contains("Nv"), line)
			assert_false(line.contains("niveau"), line)
			assert_false(line.contains("Pierre"), line)
			for digit: int in 10:
				assert_false(line.contains(str(digit)), "aucun nombre : " + line)


func test_branches_only_the_seen_ones() -> void:
	assert_eq(_text(&"eevee"), "Évoli → ???", "trois branches inconnues : un seul « ??? »")
	_dex.mark_seen(&"jolteon")
	assert_eq(_text(&"eevee"), "Évoli → Voltali", "les branches inconnues sont tues")
	_dex.mark_seen(&"flareon")
	assert_eq(_text(&"eevee"), "Évoli → Voltali / Pyroli")
	assert_eq(_text(&"vaporeon"), "??? → Aquali / Voltali / Pyroli", "Évoli jamais vu")


func test_a_species_without_evolution_has_no_section() -> void:
	var data := PokemonData.new()
	assert_true(data.add_species_from_dict({"tauros": {
		"dex": 128, "name": "Tauros", "types": ["normal"],
		"base_stats": {"hp": 75, "atk": 100, "def": 95, "spa": 40, "spd": 70, "spe": 110},
		"male_ratio": 1.0, "growth_rate": "slow", "base_exp": 172, "catch_rate": 45,
		"learnset": [[1, "tackle"]],
	}}, "test"))
	assert_eq(EvolutionReveal.chain(&"tauros", data, _dex, true).size(), 0)
	assert_eq(EvolutionReveal.chain(&"tauros", data, _dex, false).size(), 0)
	assert_eq(EvolutionReveal.chain(&"missingno", _data, _dex, true).size(), 0)


func test_without_pokedex_only_the_current_species() -> void:
	assert_eq(EvolutionReveal.text(EvolutionReveal.chain(&"rattata", _data, null, true)),
		"Rattata → ???")
