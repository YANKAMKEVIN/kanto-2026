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


# --- Vraies données -------------------------------------------------------------------------

func test_real_tables_load_without_error() -> void:
	var lib := _lib()
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	assert_eq(lib.get_ids(), [&"route_1_grass", &"route_22_grass", &"viridian_forest_grass"]
		as Array[StringName])


func test_route_22_table_is_red_blue_with_both_nidoran_and_mankey() -> void:
	# jalon-07.md §3.7 : bestiaire du dossier 09 §12. Rattata et Piafabec : taux et niveaux de
	# Rouge/Bleu (pret/pokered, data/wild/maps/Route22.asm ; PokeAPI kanto-route-22-area).
	# Les deux Nidoran se partagent les emplacements que chaque version donne au sien ;
	# Férosinge (Jaune, Rouge Feu / Vert Feuille) prend l'emplacement du Nidoran Nv. 2 et
	# ceux du Nidoran de l'autre version. Même taux et même rampe que la Route 1.
	var lib := _lib()
	lib.load_dir()
	var table := lib.get_table(&"route_22", &"grass")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(table.maps, [&"route_22"] as Array[StringName])
	assert_eq(table.rate, 25)
	assert_eq([table.ramp_from, table.ramp_max], [15, 20])
	assert_eq(table.total_weight(), 100)
	var expected := {
		&"rattata": [0.45, 2, 4], &"spearow": [0.10, 3, 5], &"mankey": [0.15, 3, 5],
		&"nidoran_f": [0.15, 3, 4], &"nidoran_m": [0.15, 3, 4],
	}
	for species: StringName in expected:
		assert_almost_eq(table.chance_of(species), float(expected[species][0]), 0.0001,
			String(species))
		var low := 100
		var high := 1
		for slot: EncounterSlot in table.slots:
			if slot.species == species:
				low = mini(low, slot.min_level)
				high = maxi(high, slot.max_level)
		assert_eq([low, high], [expected[species][1], expected[species][2]], String(species))
	for slot: EncounterSlot in table.slots:
		assert_true(expected.has(slot.species), "%s : hors du bestiaire" % slot.species)


func test_every_wild_species_has_battle_sprites() -> void:
	# jalon-07.md Q-2 : sprites de combat provisoires (tools/gen_placeholder_battlers.gd).
	var lib := _lib()
	lib.load_dir()
	assert_eq(lib.size(), 3, "une table par carte ci-dessous")
	for map_id: StringName in [&"route_1", &"route_22", &"viridian_forest"]:
		for slot: EncounterSlot in lib.get_table(map_id).slots:
			for view: String in ["front", "back"]:
				var path := "res://assets/sprites/pokemon/placeholder/%s_%s.png" % [
					slot.species, view]
				assert_true(ResourceLoader.exists(path), path)


func test_viridian_forest_table_follows_the_dossier() -> void:
	# Dossier 10 §6 et arbitrages 5–6 (jalon-09.md §2.5) : une seule table pour la forêt et la
	# carte de QA, Chenipan 35 %, Aspicot 35 %, Coconfort 13 %, Chrysacier 12 %, Pikachu 5 %
	# partout ; ni Roucool ni Rattata ; taux et rampe de la Route 1 (défaut).
	var lib := _lib()
	lib.load_dir()
	var table := lib.get_table(&"viridian_forest", &"grass")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(lib.get_table(&"qa_forest_systems", &"grass"), table, "même table en QA")
	assert_eq(table.maps, [&"viridian_forest", &"qa_forest_systems"] as Array[StringName])
	assert_eq(table.rate, 25)
	assert_eq([table.ramp_from, table.ramp_max], [15, 20])
	assert_eq(table.total_weight(), 100)
	var expected := {
		&"caterpie": [0.35, 3, 5], &"weedle": [0.35, 3, 5], &"kakuna": [0.13, 4, 6],
		&"metapod": [0.12, 4, 6], &"pikachu": [0.05, 4, 5],
	}
	for species: StringName in expected:
		assert_almost_eq(table.chance_of(species), float(expected[species][0]), 0.0001,
			String(species))
		var low := 100
		var high := 1
		for slot: EncounterSlot in table.slots:
			if slot.species == species:
				low = mini(low, slot.min_level)
				high = maxi(high, slot.max_level)
		assert_eq([low, high], [expected[species][1], expected[species][2]], String(species))
	for slot: EncounterSlot in table.slots:
		assert_true(expected.has(slot.species), "%s : hors du bestiaire" % slot.species)
		assert_false(slot.species in [&"pidgey", &"rattata"], "arbitrage 6")
