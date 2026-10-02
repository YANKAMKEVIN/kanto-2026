extends GutTest
## EncounterLibrary : chargement et validation stricte des tables de rencontres
## (jalon 5 §2.2). Espèces vérifiées contre PokemonData, poids > 0, niveaux valides, taux
## 1..255, au plus une table par couple (carte, terrain), JSON illisible avec la ligne.

const FIXTURES: String = "res://tests/fixtures/encounters/"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _lib() -> EncounterLibrary:
	return EncounterLibrary.new(_data)


func _valid_dict() -> Dictionary:
	return {
		"route_1_grass": {
			"maps": ["route_1", "pallet_town"], "terrain": "grass", "rate": 25,
			"slots": [
				{ "species": "pidgey", "levels": [2, 5], "weight": 20 },
				{ "species": "rattata", "levels": [2, 4], "weight": 10 },
			],
		},
	}


func test_valid_table_loads() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_valid_dict(), "test"))
	assert_eq(lib.get_errors().size(), 0)
	assert_true(lib.has_table(&"route_1", &"grass"))
	assert_true(lib.has_table(&"pallet_town", &"grass"), "les deux cartes partagent la table")
	var table := lib.get_table(&"route_1")
	assert_eq(table.rate, 25)
	assert_eq(table.total_weight(), 30)
	assert_eq(lib.get_ids(), [&"route_1_grass"] as Array[StringName])


func test_unknown_key_is_rejected() -> void:
	var dict := _valid_dict()
	dict["route_1_grass"]["biome"] = "forest"
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_string_contains(lib.get_errors()[0], "clé inconnue")
	assert_push_error("clé inconnue")


func test_unknown_species_is_rejected() -> void:
	var dict := _valid_dict()
	dict["route_1_grass"]["slots"][0]["species"] = "mewtwo"
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_string_contains(lib.get_errors()[0], "espèce inconnue")
	assert_push_error("espèce inconnue")


func test_inverted_levels_are_rejected() -> void:
	var dict := _valid_dict()
	dict["route_1_grass"]["slots"][0]["levels"] = [5, 2]
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_string_contains(lib.get_errors()[0], "niveaux")
	assert_push_error("niveaux")


func test_zero_weight_is_rejected() -> void:
	var dict := _valid_dict()
	dict["route_1_grass"]["slots"][0]["weight"] = 0
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_string_contains(lib.get_errors()[0], "weight")
	assert_push_error("weight")


func test_rate_out_of_range_is_rejected() -> void:
	var dict := _valid_dict()
	dict["route_1_grass"]["rate"] = 300
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_string_contains(lib.get_errors()[0], "rate")
	assert_push_error("rate")


func test_two_tables_for_the_same_map_are_rejected() -> void:
	var dict := _valid_dict()
	dict["other_grass"] = {
		"maps": ["route_1"], "terrain": "grass", "rate": 10,
		"slots": [{ "species": "pidgey", "levels": [2, 2], "weight": 1 }],
	}
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	var joined := "\n".join(lib.get_errors())
	assert_string_contains(joined, "déjà la table")
	assert_push_error("déjà la table")


func test_broken_json_reports_the_line() -> void:
	var lib := _lib()
	assert_false(lib.load_file(FIXTURES + "broken.json"))
	assert_string_contains(lib.get_errors()[0], "broken.json, ligne")
	assert_push_error("broken.json, ligne 6")


func test_load_dir_keeps_valid_and_reports_broken() -> void:
	# Le dossier contient valid.json (bon) et broken.json (cassé) : la bonne table reste.
	var lib := _lib()
	assert_false(lib.load_dir(FIXTURES))
	assert_true(lib.has_table(&"route_x", &"grass"))
	assert_true(lib.get_errors().size() >= 1)
	assert_push_error("broken.json, ligne 6")
