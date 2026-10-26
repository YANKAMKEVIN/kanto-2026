extends GutTest
## Départs de débogage du jalon 26 (T14, `jalon-26.md` §2.6) : fichiers valides, cartes et points
## d'apparition réels, starter non évolué en tête (le rival n° 6 lit `starter_species`), drapeaux
## et Sac de chaque étape (postes, Carte, rival, Giovanni, Master Ball, Lokhlass).

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, drapeaux présents, drapeaux absents, objets au Sac,
## objets absents, niveau du starter].
const STARTS := {
	"saffron_gate": [&"route_8_gate", &"entrance", [&"route_8_reached", &"badge_rainbow"],
		[&"saffron_gates_open"], [&"fresh_water"], [&"card_key"], 38],
	"silph_1f": [&"silph_co_1f", &"from_city", [&"saffron_gates_open"],
		[&"rival_silph_won", &"silph_giovanni_defeated"], [&"silph_scope"], [&"card_key"], 38],
	"silph_5f": [&"silph_co_5f", &"from_elevator", [&"saffron_gates_open"],
		[&"got_silph_co_5f_card_key"], [], [&"card_key"], 38],
	"silph_7f_rival_bulbasaur": [&"silph_co_7f", &"tp_5", [&"got_silph_co_5f_card_key"],
		[&"rival_silph_won"], [&"card_key"], [], 38],
	"silph_7f_rival_charmander": [&"silph_co_7f", &"tp_5", [&"got_silph_co_5f_card_key"],
		[&"rival_silph_won"], [&"card_key"], [], 38],
	"silph_7f_rival_squirtle": [&"silph_co_7f", &"tp_5", [&"got_silph_co_5f_card_key"],
		[&"rival_silph_won"], [&"card_key"], [], 38],
	"silph_11f": [&"silph_co_11f", &"tp_4", [&"rival_silph_won", &"door_silph_co_11f_d1_open"],
		[&"silph_giovanni_defeated", &"silph_master_ball_received"], [&"card_key"],
		[&"master_ball"], 42],
	"saffron_free": [&"saffron_city", &"from_silph",
		[&"silph_giovanni_defeated", &"silph_master_ball_received", &"silph_lapras_received"],
		[], [&"master_ball", &"card_key"], [], 42],
}
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_starts_are_valid_and_land_on_real_spawns() -> void:
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var expected: Array = STARTS[name]
		assert_eq([start.map, start.spawn], expected.slice(0, 2), name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		for flag: StringName in expected[2]:
			assert_true(start.flags.has(flag), "%s : %s posé" % [name, flag])
		for flag: StringName in expected[3]:
			assert_false(start.flags.has(flag), "%s : %s absent" % [name, flag])
		for item: StringName in expected[4]:
			assert_gt(int(start.bag.get(String(item), 0)), 0, "%s : %s au Sac" % [name, item])
		for item: StringName in expected[5]:
			assert_eq(int(start.bag.get(String(item), 0)), 0, "%s : pas de %s" % [name, item])
		var starter := StringName(start.party[0]["species"])
		assert_true(STARTERS.has(starter), "%s : starter non évolué en tête" % name)
		assert_eq(int(start.party[0]["level"]), expected[6], name)
		assert_true(start.flags.has(StringName("taken_%s" % starter)),
			"%s : la Poké Ball du starter prise au labo" % name)


func test_the_rival_starts_cover_the_three_starters() -> void:
	for starter: StringName in STARTERS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + "silph_7f_rival_%s.json" % starter, _data,
			_items))
		assert_eq(StringName(start.party[0]["species"]), starter)
		var state := (load("res://game/autoload/game_state.gd") as GDScript).new() as Node
		start.apply(state, _data)
		assert_eq(state.starter_species, starter, "le combat du rival lit ce starter")
		state.free()


func test_saffron_free_has_lapras_and_rests_at_saffron() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "saffron_free.json", _data, _items))
	var species: Array = start.party.map(func(m: Dictionary) -> String: return str(m["species"]))
	assert_has(species, "lapras")
	assert_eq(start.rest_point, &"saffron_center")
	assert_eq(int(start.bag.get("master_ball", 0)), 1)
