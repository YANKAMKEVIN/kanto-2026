extends GutTest
## Table forcée par terrain (jalon 12, T20 ; `jalon-12.md` §2.5, §0.4 n° 4) :
## [method EncounterLibrary.override_table] (les herbes en sont un cas, inchangé) et la clé
## « terrain » facultative de « wild » dans un départ de débogage (« rubble » : gravats de la
## grotte, défaut « grass »).

var _data: PokemonData
var _items: ItemLibrary
var _wild := {"rate": 200, "slots": [{"species": "zubat", "levels": [9, 9], "weight": 1}]}


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_override_rubble_replaces_only_that_terrain() -> void:
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir())
	var grass_route_3 := library.get_table(&"route_3")
	var rubble_b1f := library.get_table(&"mt_moon_b1f", &"rubble")
	assert_not_null(rubble_b1f, "table de B1F")
	assert_true(library.override_table(&"mt_moon_1f", &"rubble", _wild, "t"))
	var forced := library.get_table(&"mt_moon_1f", &"rubble")
	assert_eq(forced.rate, 200)
	assert_eq(forced.terrain, &"rubble")
	assert_eq(forced.id, &"debug_mt_moon_1f_rubble")
	assert_eq(forced.slots[0].species, &"zubat")
	assert_false(library.has_table(&"mt_moon_1f", &"grass"), "aucune table d'herbes créée")
	assert_eq(library.get_table(&"mt_moon_b1f", &"rubble"), rubble_b1f, "les autres étages")
	assert_eq(library.get_table(&"route_3"), grass_route_3, "les herbes ailleurs")


func test_override_grass_keeps_its_old_identifier() -> void:
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir())
	assert_true(library.override_grass(&"route_1", _wild, "t"))
	assert_eq(library.get_table(&"route_1").id, &"debug_route_1")
	assert_eq(library.get_table(&"route_1").terrain, &"grass")


func test_override_refuses_unknown_terrain_and_terrain_key() -> void:
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir())
	var before := library.get_table(&"mt_moon_1f", &"rubble")
	assert_false(library.override_table(&"mt_moon_1f", &"lava", _wild, "t"))
	assert_string_contains("\n".join(library.get_errors()), "terrain inconnu")
	var with_terrain := _wild.duplicate()
	with_terrain["terrain"] = "rubble"
	assert_false(library.override_table(&"mt_moon_1f", &"rubble", with_terrain, "t"))
	assert_push_error_count(2)
	assert_eq(library.get_table(&"mt_moon_1f", &"rubble"), before, "rien n'a changé")


func test_debug_start_wild_terrain() -> void:
	var dict := {
		"map": "mt_moon_1f", "spawn": "from_route_3_w",
		"party": [{"species": "pikachu", "level": 12}],
		"wild": {"terrain": "rubble", "rate": 200,
			"slots": [{"species": "geodude", "levels": [10, 10], "weight": 1}]},
	}
	var start := DebugStart.new()
	assert_true(start.add_from_dict(dict, _data, _items, "t"), "\n".join(start.get_errors()))
	assert_eq(start.wild_terrain, &"rubble")
	assert_false(start.wild.has("terrain"), "la table seule")
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir())
	assert_true(library.override_table(start.map, start.wild_terrain, start.wild, "t"))
	assert_eq(library.get_table(&"mt_moon_1f", &"rubble").slots[0].species, &"geodude")
	# Sans « terrain » : les herbes, comme au J11.
	var grass := DebugStart.new()
	var grass_dict: Dictionary = dict.duplicate(true)
	(grass_dict["wild"] as Dictionary).erase("terrain")
	grass_dict["map"] = "route_1"
	grass_dict["spawn"] = "from_pallet_w"
	assert_true(grass.add_from_dict(grass_dict, _data, _items, "t"))
	assert_eq(grass.wild_terrain, &"grass")
	# Terrain inconnu : refusé, rien n'est gardé.
	var bad := DebugStart.new()
	var bad_dict: Dictionary = dict.duplicate(true)
	bad_dict["wild"]["terrain"] = "lava"
	assert_false(bad.add_from_dict(bad_dict, _data, _items, "t"))
	assert_string_contains("\n".join(bad.get_errors()), "terrain inconnu")
	assert_true(bad.wild.is_empty())
	assert_push_error_count(1, "le terrain inconnu")


## Jalon 19 (T5) : une table forcée peut porter « ghost_unless_item » et le terrain « floor »
## (départs de débogage de la Tour : `tower_ghost_qa`). Carte d'avant le J19 : la bibliothèque
## ne vérifie pas les cartes.
func test_debug_start_wild_floor_with_ghost_item() -> void:
	var dict := {
		"map": "mt_moon_1f", "spawn": "from_route_3_w",
		"party": [{"species": "pikachu", "level": 12}],
		"wild": {"terrain": "floor", "rate": 200, "ghost_unless_item": "silph_scope",
			"slots": [{"species": "zubat", "levels": [20, 20], "weight": 1}]},
	}
	var start := DebugStart.new()
	assert_true(start.add_from_dict(dict, _data, _items, "t"), "\n".join(start.get_errors()))
	assert_eq(start.wild_terrain, &"floor")
	assert_eq(start.wild.get("ghost_unless_item"), "silph_scope", "gardée dans la table")
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir())
	assert_true(library.override_table(start.map, start.wild_terrain, start.wild, "t"))
	var forced := library.get_table(&"mt_moon_1f", &"floor")
	assert_eq(forced.id, &"debug_mt_moon_1f_floor")
	assert_eq(forced.ghost_unless_item, &"silph_scope")
	assert_not_null(library.get_table(&"mt_moon_1f", &"rubble"), "les gravats restent")
	# Identifiant vide : refusé, rien n'est gardé.
	var bad := DebugStart.new()
	var bad_dict: Dictionary = dict.duplicate(true)
	bad_dict["wild"]["ghost_unless_item"] = ""
	assert_false(bad.add_from_dict(bad_dict, _data, _items, "t"))
	assert_string_contains("\n".join(bad.get_errors()), "ghost_unless_item")
	assert_true(bad.wild.is_empty())
	assert_push_error_count(1, "l'identifiant vide")
