extends GutTest
## Départs de débogage de la Tour Pokémon (jalon 19 T14, QA 19A, `jalon-19.md` T15) : fichiers
## valides, cartes et points d'apparition réels, point de repos (clé `rest_point`), drapeaux.

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation, drapeaux présents, drapeaux absents].
const STARTS := {
	"tower_ghost_qa": [&"pokemon_tower_3f", &"arrivee_T23", Vector2i.RIGHT,
		[&"tower_stairs_open", &"lavender_reached"], [&"rival_tower_won"]],
	"tower_exorcist_weak": [&"pokemon_tower_4f", &"arrivee_T34", Vector2i.LEFT,
		[&"tower_stairs_open", &"lavender_reached"], [&"beaten_tower_channeler_3"]],
	"tower_6f_block": [&"pokemon_tower_6f", &"devant_spectre", Vector2i.DOWN,
		[&"tower_stairs_open", &"lavender_reached"],
		[&"rival_tower_won", &"ghost_marowak_calmed"]],
}

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
		assert_eq([start.map, start.spawn, start.facing], expected.slice(0, 3), name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		for flag: StringName in expected[3]:
			assert_true(start.flags.has(flag), "%s : %s posé" % [name, flag])
		for flag: StringName in expected[4]:
			assert_false(start.flags.has(flag), "%s : %s absent" % [name, flag])
		assert_eq(start.rest_point, &"lavender_center", "%s : Centre de Lavanville" % name)


func test_rest_point_registers_the_center_in_the_game_state() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "tower_exorcist_weak.json", _data, _items))
	var state := (load("res://game/autoload/game_state.gd") as GDScript).new() as Node
	start.apply(state, _data)
	assert_eq(state.heal_map, &"lavender_center")
	assert_eq(state.heal_spawn, &"heal")
	state.free()


func test_ghost_qa_has_the_qa_party() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "tower_ghost_qa.json", _data, _items))
	assert_eq(start.wild_terrain, &"floor", "table de la Tour forcée")
	assert_false(start.wild.is_empty())
	var statuses: Array = start.party.map(func(m: Dictionary) -> String: return m.get("status", ""))
	assert_has(statuses, "sleep", "un Pokémon endormi")
	assert_gt(int(start.bag.get("poke_ball", 0)), 0, "des Poké Balls")
	assert_gt(int(start.bag.get("super_potion", 0)), 0, "des Super Potions")


func test_rest_point_is_validated() -> void:
	var party := [{"species": "pikachu", "level": 5}]
	for value: Variant in ["viridian_house", "pallet_town", 3, true]:
		var start := DebugStart.new()
		assert_false(start.add_from_dict({"party": party, "rest_point": value}, _data, _items,
			"t"), str(value))
		assert_string_contains("\n".join(start.get_errors()), "rest_point")
	assert_push_error_count(4)
	var none := DebugStart.new()
	assert_true(none.add_from_dict({"party": party}, _data, _items, "t"))
	assert_eq(none.rest_point, &"", "absent : aucun point de repos forcé")
