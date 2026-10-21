extends GutTest
## Raccord Lavanville ↔ Route 8 (jalon 20 T15, docs/tech/jalon-20.md §0.0, §2.1) : une partie
## sauvegardée sur chaque case du bord ouest de Lavanville (colonnes 0 et 1, rangées 10..12) se
## recharge sur la **même case**, praticable, de la Lavanville régénérée ; le bord mène à la
## Route 8 et le retour revient sur la même rangée.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_lavender_route_8_save.json"
const SUFFIXES: Array[String] = ["n", "c", "s"]

var _lavender: GameMap
var _route: GameMap


func before_all() -> void:
	_lavender = (load(MapCatalog.scene_path(&"lavender_town")) as PackedScene).instantiate() \
		as GameMap
	add_child(_lavender)
	_route = (load(MapCatalog.scene_path(&"route_8")) as PackedScene).instantiate() as GameMap
	add_child(_route)


func after_all() -> void:
	_lavender.free()
	_route.free()


func test_a_save_on_the_west_edge_resumes_on_the_same_cell() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	var grid := _lavender.get_grid()
	for x: int in [0, 1]:
		for y: int in range(10, 13):
			var cell := Vector2i(x, y)
			var state: Node = autofree(GameStateScript.new())
			state.clock = FixedClock.new("2026-10-19T10:00:00")
			state.new_game(7)
			state.set_player_location(&"lavender_town", cell, Vector2i.LEFT)
			assert_eq(save.write(state.to_dict()), OK, "sauvegarde en %s" % cell)
			var loaded: Node = autofree(GameStateScript.new())
			assert_true(loaded.load_dict(save.read(), data), "rechargée en %s" % cell)
			assert_eq([loaded.current_map, loaded.player_cell], [&"lavender_town", cell])
			assert_false(grid.is_solid(cell), "%s praticable" % cell)
			assert_eq(_lavender.find_standing_cell(cell), cell, "%s : reprise sur la case" % cell)


func test_the_edge_and_the_way_back_keep_the_row() -> void:
	for i: int in SUFFIXES.size():
		var row := 10 + i
		var out := _lavender.get_warps().find_on_push(Vector2i(0, row), Vector2i.LEFT)
		assert_not_null(out, "bord ouest, rangée %d" % row)
		if out == null:
			continue
		assert_eq(out.target_map, &"route_8")
		var arrival := _route.get_spawn_cell(out.target_spawn)
		assert_eq(arrival, Vector2i(79, row), "arrivée sur la même rangée")
		var back := _route.get_warps().find_on_push(arrival, Vector2i.RIGHT)
		assert_not_null(back, "retour depuis la Route 8")
		if back != null:
			assert_eq(back.target_map, &"lavender_town")
			assert_eq(_lavender.get_spawn_cell(back.target_spawn), Vector2i(1, row),
				"retour sur la même rangée")
