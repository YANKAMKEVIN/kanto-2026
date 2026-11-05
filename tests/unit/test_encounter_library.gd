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
	dict["route_1_grass"]["slots"][0]["species"] = "missingno"
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
	# Jalon 17 (T8) : Route 11, Cave Taupiqueur ; jalon 18 (T16) : Route 9, Route 10, Grotte Sombre ;
	# jalon 19 (T5) : Tour Pokémon (la table d'eau de la carte de QA S2C est retirée en S2Z) ;
	# Jalon 21 (T5) : sommet de la Tour (7F) ; jalon 24 (T4) : eau des Routes 19 à 21 et de
	# Cramois'Île, herbe de la Route 21, sol des Îles Écume (test_j24_data) ; jalon 31 (T4) : sol
	# des trois étages de la Grotte Azurée.
	assert_eq(lib.get_ids(), [
		# Arc des Pierres, JOHP3 : Ébènelle (jour / nuit), gravats de l'Antre.
		&"alph_gallery_rubble", &"blackthorn_city_grass_day", &"blackthorn_city_grass_night",
		&"burned_tower_1f_floor", &"cerulean_cave_1f_floor", &"cerulean_cave_2f_floor",
		&"cerulean_cave_b1f_floor", &"cianwood_grass_day", &"cianwood_grass_night", &"cinnabar_island_water", &"dark_cave_1f_rubble",
		&"dark_cave_b1f_rubble", &"digletts_cave_rubble", &"dragons_den_rubble",
		# Chapitre Johto, JOH2 : herbe des tours de Rosalia (nuit), Routes 38 et 39 (jour / nuit).
		&"ecruteak_towers_night",
		# Chapitre Johto, JOH4 : Bois aux Chênes (matin / jour / nuit), Route 34, Puits Ramoloss.
		&"ilex_forest_grass_day", &"ilex_forest_grass_morning", &"ilex_forest_grass_night",
		# JOH6 : Lac Colère (rives jour / nuit, eau).
		&"lake_of_rage_grass_day", &"lake_of_rage_grass_night", &"lake_of_rage_water",
		&"mt_moon_1f_rubble",
		&"mt_moon_b1f_rubble", &"mt_moon_b2f_rubble",
		# Chapitre Johto (JOH9) : Mont Argenté (grotte et extérieur, tables datées dehors).
		&"mt_silver_1f_rubble", &"mt_silver_1f_water", &"mt_silver_2f_rubble",
		&"mt_silver_3f_rubble", &"mt_silver_outside_grass_day", &"mt_silver_outside_grass_night",
		&"pokemon_mansion_1f_floor",
		&"pokemon_mansion_2f_floor", &"pokemon_mansion_3f_floor", &"pokemon_mansion_b1f_floor",
		&"pokemon_tower_high", &"pokemon_tower_low",
		&"pokemon_tower_mid", &"pokemon_tower_top",
		# Jalon 32 (N-11, lot 32G) : sol de la Centrale (la carte attend sa grille).
		&"power_plant_floor", &"route_10_grass", &"route_11_grass",
		&"route_12_south_grass", &"route_13_grass", &"route_14_grass", &"route_15_grass",
		&"route_16_west_grass", &"route_17_grass", &"route_18_grass", &"route_19_water",
		&"route_1_grass", &"route_20_water", &"route_21_grass", &"route_21_water",
		&"route_22_grass", &"route_23_grass", &"route_24_grass", &"route_25_grass",
		&"route_28_grass_day", &"route_2_grass",
		&"route_2_north_grass", &"route_34_grass_day", &"route_34_grass_night", &"route_34_water",
		# Chapitre Johto (JOH3) : herbe par moment des Routes 37, 36, 35 et Surf de l'étang.
		&"route_35_grass_day", &"route_35_grass_night", &"route_35_surf", &"route_36_grass_day",
		&"route_36_grass_morning", &"route_36_grass_night", &"route_37_grass_day",
		&"route_37_grass_night", &"route_38_grass_day", &"route_38_grass_night",
		&"route_39_grass_day", &"route_39_grass_night", &"route_3_grass", &"route_40_water",
		&"route_41_water",
		# JOH6 : Routes 42 (jour / nuit, lac) et 43 (jour / nuit).
		&"route_42_grass_day", &"route_42_grass_night", &"route_42_water", &"route_43_grass_day",
		&"route_43_grass_night", &"route_4_grass", &"route_5_grass",
		&"route_6_grass", &"route_7_grass", &"route_8_grass", &"route_9_grass",
		# Jalon 23 (T13) : Parc Safari.
		# JOHP1 : Ruines d'Alpha (herbes, jour et nuit).
		&"ruins_of_alph_grass_day", &"ruins_of_alph_grass_night",
		&"safari_zone_center_grass", &"safari_zone_east_grass", &"safari_zone_north_grass",
		&"safari_zone_west_grass",
		# Chapitre Johto (JOH1) : l'eau de la grotte marine (deux salles).
		&"sea_cave_water",
		&"seafoam_1f_floor", &"seafoam_b1f_floor", &"seafoam_b2f_floor", &"seafoam_b3f_floor",
		&"seafoam_b4f_floor",
		# JOH9 : Sentier du Mont Argenté (jour, nuit).
		&"silver_trail_grass_day", &"silver_trail_grass_night",
		&"slowpoke_well_rubble", &"slowpoke_well_water", &"tide_cave_1f_rubble", &"tide_cave_b1f_rubble",
		&"victory_road_1f_rubble", &"victory_road_2f_rubble",
		&"victory_road_3f_rubble", &"viridian_forest_grass",
		# Chapitre Johto, JOH7 : la mer et les Îles Tourbillon (dossier JOH-08 §5).
		&"whirl_islands_1f_rubble_day", &"whirl_islands_1f_rubble_night",
		&"whirl_islands_b1f_rubble", &"whirl_islands_b1f_water"] as Array[StringName])


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
	# J29 : les herbes de la partie ouest (route_22_west) suivent la même table.
	assert_eq(table.maps, [&"route_22", &"route_22_west"] as Array[StringName])
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


func test_route_2_table_follows_dossier_11() -> void:
	# Dossier 11 §8 (jalon-08.md §2.9) : une table pour H1, H2, H3 ; poids = pourcentages ;
	# rythme de la Route 1 (taux 25, rampe 15 → 20).
	var lib := _lib()
	lib.load_dir()
	var table := lib.get_table(&"route_2", &"grass")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(table.maps, [&"route_2"] as Array[StringName])
	assert_eq(table.rate, 25)
	assert_eq([table.ramp_from, table.ramp_max], [15, 20])
	assert_eq(table.total_weight(), 100)
	var expected := {
		&"pidgey": [0.35, 4, 6], &"rattata": [0.30, 4, 6], &"nidoran_f": [0.12, 4, 6],
		&"nidoran_m": [0.12, 4, 6], &"spearow": [0.08, 5, 6], &"mankey": [0.03, 5, 6],
	}
	for species: StringName in expected:
		assert_almost_eq(table.chance_of(species), float(expected[species][0]), 0.0001,
			String(species))
	for slot: EncounterSlot in table.slots:
		assert_true(expected.has(slot.species), "%s : hors du bestiaire" % slot.species)
		assert_eq([slot.min_level, slot.max_level],
			[expected[slot.species][1], expected[slot.species][2]], String(slot.species))
		# Aucun Insecte ni Pikachu : la forêt garde ses rencontres (dossier 11 §8).
		assert_ne(slot.species, &"pikachu")
		assert_false(_data.get_species(slot.species).types.has(&"bug"),
			"%s : pas d'Insecte sur la Route 2" % slot.species)


func test_every_wild_species_has_battle_sprites() -> void:
	# jalon-07.md Q-2 : sprites de combat provisoires (tools/gen_placeholder_battlers.gd).
	var lib := _lib()
	lib.load_dir()
	# + 3 tables de la Tour Pokémon (J19) : hors de la boucle, car leurs rencontres sont des
	# SPECTRES sans le Scope (dossier 22 §6) ; Osselait n'a pas de sprite avant le J20.
	# (La table d'eau de la carte de QA S2C est retirée en S2Z.)
	# Jalon 21 (T5) : + la table du 7F (`pokemon_tower_top`), hors de la boucle comme les
	# autres tables de la Tour (SPECTRES sans le Scope). Jalon 23 (T13) : + 4 du Parc Safari ;
	# jalon 25 : + 4 du Manoir. Jalon 29 (T4) : + Route 23 et les 3 niveaux de la Route Victoire.
	# Jalon 31 : + les 3 tables de la Grotte Azurée. Jalon 32 : + la Centrale.
	# Chapitre Johto, JOH1 : l'eau de la grotte marine ; JOH2 : + 5 tables datées (Routes 39 et 38
	# jour / nuit, herbe des tours de Rosalia), hors de la boucle (tables par moment :
	# `test_joh2_data`) ; JOH3 : + 8 (`test_joh3_data`) ; JOH4 : + 8 (Route 34, Bois aux Chênes, Puits Ramoloss : `test_joh4_data`) ;
	# JOH6 : + 9 (`test_joh6_data`) ; JOH7 : + 6 tables de la mer et des Îles Tourbillon (`test_joh7_data`) ;
	# JOH9 : + 9 tables du Mont Argenté, du sentier et de la Route 28 (`test_joh9_data`).
	# Arc des Pierres, JOHP3 : + 3 tables d'Ébènelle et de l'Antre (`test_johp3_data`).
	assert_eq(lib.size(), 115, "les 3 du JOHP1, les 4 du JOHP2, les 3 du JOHP3, une table par couple ci-dessous, plus les 4 de la Tour (J19, J21), l'eau de la grotte marine (JOH1), les 5 du JOH2, les 8 du JOH3, les 8 du JOH4, les 9 du JOH6, les 6 du JOH7 et les 9 du JOH9")
	for pair: Array in [[&"route_1", &"grass"], [&"route_2", &"grass"],
			[&"route_22", &"grass"], [&"viridian_forest", &"grass"], [&"route_2_north", &"grass"],
			[&"route_3", &"grass"], [&"mt_moon_1f", &"rubble"], [&"mt_moon_b1f", &"rubble"],
			[&"mt_moon_b2f", &"rubble"], [&"route_4", &"grass"], [&"route_24", &"grass"],
			[&"route_25", &"grass"], [&"route_5", &"grass"], [&"route_6", &"grass"],
			# Jalon 17 (T8) : Route 11 et Cave Taupiqueur.
			[&"route_11", &"grass"], [&"digletts_cave", &"rubble"],
			# Jalon 18 (T16) : Route 9, Route 10, Grotte Sombre.
			[&"route_9", &"grass"], [&"route_10", &"grass"], [&"dark_cave_1f", &"rubble"],
			[&"dark_cave_b1f", &"rubble"], [&"alph_gallery", &"rubble"],
			# Jalon 20 (T7) : Routes 8 et 7.
			[&"route_8", &"grass"], [&"route_7", &"grass"],
			# Jalon 22 : Routes 12 sud à 18.
			[&"route_12_south", &"grass"], [&"route_13", &"grass"], [&"route_14", &"grass"],
			[&"route_15", &"grass"], [&"route_16_west", &"grass"], [&"route_17", &"grass"],
			[&"route_18", &"grass"],
			# Jalon 24 (T4).
			[&"route_19", &"water"], [&"route_20", &"water"], [&"route_21", &"water"],
			[&"route_21", &"grass"], [&"cinnabar_island", &"water"],
			[&"seafoam_1f", &"floor"], [&"seafoam_b1f", &"floor"], [&"seafoam_b2f", &"floor"],
			[&"seafoam_b3f", &"floor"], [&"seafoam_b4f", &"floor"],
			# Jalon 25 (T9) : Manoir Pokémon.
			[&"pokemon_mansion_1f", &"floor"], [&"pokemon_mansion_2f", &"floor"],
			[&"pokemon_mansion_3f", &"floor"], [&"pokemon_mansion_b1f", &"floor"],
			# Jalon 23 (T13) : Parc Safari.
			[&"safari_zone_center", &"grass"], [&"safari_zone_east", &"grass"],
			[&"safari_zone_north", &"grass"], [&"safari_zone_west", &"grass"],
			# Jalon 32 (N-11) : la Centrale (Élektek et Raichu, union Rouge + Bleu).
			[&"power_plant", &"floor"]]:
		for slot: EncounterSlot in lib.get_table(pair[0], pair[1]).slots:
			for view: String in ["front", "back"]:
				var path := "res://assets/sprites/pokemon/placeholder/%s_%s.png" % [
					slot.species, view]
				assert_true(ResourceLoader.exists(path), path)


func test_viridian_forest_table_follows_the_dossier() -> void:
	# Dossier 10 §6 et arbitrages 5–6 (jalon-09.md §2.5) : une seule table pour la forêt
	# (la carte de QA qui la partageait est retirée au T23), Chenipan 35 %, Aspicot 35 %, Coconfort 13 %, Chrysacier 12 %, Pikachu 5 %
	# partout ; ni Roucool ni Rattata ; taux et rampe de la Route 1 (défaut).
	var lib := _lib()
	lib.load_dir()
	var table := lib.get_table(&"viridian_forest", &"grass")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(table.maps, [&"viridian_forest"] as Array[StringName])
	assert_false(lib.has_table(&"qa_forest_systems"), "carte de QA retirée")
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


# --- Jalon 19 (T5) : terrain « floor » et clé « ghost_unless_item » ----------------------------

func _floor_dict() -> Dictionary:
	return {
		"tower_floor": {
			"maps": ["tower_3f"], "terrain": "floor", "rate": 10,
			"ghost_unless_item": "silph_scope",
			"slots": [
				{ "species": "pidgey", "levels": [18, 24], "weight": 229 },
				{ "species": "rattata", "levels": [25, 25], "weight": 3 },
			],
		},
	}


func test_floor_table_with_ghost_item_loads() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_floor_dict(), "test"), "\n".join(lib.get_errors()))
	assert_true(lib.has_table(&"tower_3f", &"floor"))
	assert_false(lib.has_table(&"tower_3f", &"grass"), "aucune table d'herbes")
	var table := lib.get_table(&"tower_3f", &"floor")
	assert_eq(table.terrain, &"floor")
	assert_eq(table.ghost_unless_item, &"silph_scope")
	assert_false(table.has_ramp())


func test_unknown_item_is_accepted() -> void:
	# « silph_scope » n'existe qu'au J20 : l'identifiant n'est pas vérifié contre ItemLibrary.
	var dict := _floor_dict()
	dict["tower_floor"]["ghost_unless_item"] = "objet_qui_n_existe_pas"
	var lib := _lib()
	assert_true(lib.add_from_dict(dict, "test"), "\n".join(lib.get_errors()))
	assert_eq(lib.get_table(&"tower_3f", &"floor").ghost_unless_item, &"objet_qui_n_existe_pas")


func test_empty_ghost_item_is_rejected() -> void:
	var dict := _floor_dict()
	dict["tower_floor"]["ghost_unless_item"] = ""
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_false(lib.has_table(&"tower_3f", &"floor"))
	assert_string_contains(lib.get_errors()[0], "ghost_unless_item")
	assert_push_error("ghost_unless_item")


func test_non_text_ghost_item_is_rejected() -> void:
	var dict := _floor_dict()
	dict["tower_floor"]["ghost_unless_item"] = true
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"))
	assert_push_error("ghost_unless_item")


func test_table_without_ghost_item_never_masks() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_valid_dict(), "test"))
	assert_eq(lib.get_table(&"route_1").ghost_unless_item, &"", "vide : jamais de SPECTRE")


func test_real_tables_carry_no_ghost_item_outside_the_tower() -> void:
	var lib := _lib()
	lib.load_dir()
	for id: StringName in lib.get_ids():
		var table := lib.get_table_by_id(id)
		if String(id).begins_with("pokemon_tower_"):
			continue
		assert_true(table.ghost_unless_item.is_empty(), String(id))
		# Jalon 24 (T4) : le sol des Îles Écume est aussi un terrain « floor », sans SPECTRE ; J25 : Manoir ;
		# jalon 31 : celui de la Grotte Azurée aussi.
		if not (String(id).begins_with("seafoam_") or String(id).begins_with("pokemon_mansion_")
				or String(id).begins_with("cerulean_cave_") or String(id).begins_with("power_plant")
				or String(id).begins_with("burned_tower_")):
			assert_ne(table.terrain, &"floor", String(id))


# --- Chapitre Johto (JOH0, jalon-joh0.md §2.5) : tables par moment -----------------------------

func _dated_dict() -> Dictionary:
	return {
		"route_38_day": {
			"maps": ["route_38"], "terrain": "grass", "rate": 25, "period": ["morning", "day"],
			"slots": [{ "species": "rattata", "levels": [6, 9], "weight": 10 }],
		},
		"route_38_night": {
			"maps": ["route_38"], "terrain": "grass", "rate": 25, "period": "night",
			"slots": [{ "species": "zubat", "levels": [6, 9], "weight": 10 }],
		},
		"route_38_water": {
			"maps": ["route_38"], "terrain": "water", "rate": 10,
			"slots": [{ "species": "tentacool", "levels": [10, 20], "weight": 10 }],
		},
	}


func test_dated_tables_are_picked_by_period_and_fall_back_to_all_day() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_dated_dict(), "test"), str(lib.get_errors()))
	assert_eq(lib.get_table_by_id(&"route_38_day").periods, [&"morning", &"day"]
		as Array[StringName])
	assert_true(lib.get_table_by_id(&"route_38_water").is_all_day())
	assert_eq(lib.get_table(&"route_38", &"grass", &"morning").id, &"route_38_day")
	assert_eq(lib.get_table(&"route_38", &"grass", &"day").id, &"route_38_day")
	assert_eq(lib.get_table(&"route_38", &"grass", &"night").id, &"route_38_night")
	assert_null(lib.get_table(&"route_38", &"grass"), "sans heure, aucune table datée ne vaut")
	assert_false(lib.has_table(&"route_38", &"grass", &""))
	assert_true(lib.has_table(&"route_38", &"grass", &"night"))
	assert_eq(lib.get_table(&"route_38", &"water", &"night").id, &"route_38_water",
		"une table de toute la journée vaut à tout moment")
	assert_eq(lib.get_table(&"route_38", &"water").id, &"route_38_water")


func test_kanto_tables_ignore_the_period() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_valid_dict(), "test"))
	for period: StringName in [&"", &"morning", &"day", &"night"]:
		assert_eq(lib.get_table(&"route_1", &"grass", period).id, &"route_1_grass", period)
	var real := _lib()
	assert_true(real.load_dir(), "les vraies tables se chargent")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for id: StringName in real.get_ids():
		var table := real.get_table_by_id(id)
		if zones.region_of(table.maps[0]) == ZoneData.REGION_JOHTO:
			continue # JOH2, JOH9 : les tables de Johto sont datées (test_joh2_data, test_joh9_data).
		assert_true(table.is_all_day(), "Kanto sans « period » : %s" % id)


func test_dated_and_all_day_tables_cannot_share_a_map_and_terrain() -> void:
	var dict := _dated_dict()
	dict["route_38_all"] = {"maps": ["route_38"], "terrain": "grass", "rate": 20,
		"slots": [{ "species": "pidgey", "levels": [3, 4], "weight": 1 }]}
	var lib := _lib()
	assert_false(lib.add_from_dict(dict, "test"), "toute la journée après des tables datées")
	var reversed := {"all": dict["route_38_all"], "night": _dated_dict()["route_38_night"]}
	var lib2 := _lib()
	assert_false(lib2.add_from_dict(reversed, "test"), "table datée après toute la journée")
	var twice := {"a": _dated_dict()["route_38_night"], "b": _dated_dict()["route_38_night"]}
	var lib3 := _lib()
	assert_false(lib3.add_from_dict(twice, "test"), "deux tables sur le même moment")
	assert_push_error_count(3)


func test_invalid_periods_are_rejected() -> void:
	for bad: Variant in ["dusk", [], ["day", "day"], 3, ["night", "noon"]]:
		var dict := _valid_dict()
		dict["route_1_grass"]["period"] = bad
		var lib := _lib()
		assert_false(lib.add_from_dict(dict, "test"), str(bad))
	assert_push_error_count(5)
