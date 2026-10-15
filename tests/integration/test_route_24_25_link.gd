extends GutTest
## Raccord Route 24 ↔ Route 25 (jalon 14 T15, jalon-14.md §2.1) avec la vraie scène Boot et
## l'autoload SceneRouter (fondus raccourcis) : sur chacune des trois rangées, pousser vers l'est
## au bord de la Route 24 (55, 6..8) mène à la Route 25 (0, 13..15), tourné vers l'est ; pousser
## vers l'ouest au bord de la Route 25 ramène sur la même rangée de la Route 24, tourné vers
## l'ouest.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_route_24_25_link_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const ROWS: Array[String] = ["n", "c", "s"]

var _boot: Boot
var _player: Player
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T10:00:00")


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_left", &"move_right"]:
		Input.action_release(action)


func _start(spawn: StringName) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_24"
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Pousse vers [param action] jusqu'à l'arrivée sur [param map_id].
func _push_until(action: StringName, map_id: StringName) -> void:
	Input.action_press(action)
	await wait_until(func() -> bool: return SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _boot.get_map().map_id == map_id, TIMEOUT)
	await wait_process_frames(2)


func test_there_and_back_on_each_row() -> void:
	for i: int in ROWS.size():
		await _start(StringName("from_route_25_" + ROWS[i]))
		assert_eq(_player.get_cell(), Vector2i(55, 6 + i), "rangée %s : bord est" % ROWS[i])
		await _push_until(&"move_right", &"route_25")
		assert_eq(_boot.get_map().map_id, &"route_25", "rangée %s : Route 25" % ROWS[i])
		assert_eq(_player.get_cell(), Vector2i(0, 13 + i), "rangée %s : arrivée" % ROWS[i])
		assert_eq(_player.get_facing(), Vector2i.RIGHT)
		assert_true(_player.is_input_enabled())
		await _push_until(&"move_left", &"route_24")
		assert_eq(_boot.get_map().map_id, &"route_24", "rangée %s : retour" % ROWS[i])
		assert_eq(_player.get_cell(), Vector2i(55, 6 + i), "rangée %s : même rangée" % ROWS[i])
		assert_eq(_player.get_facing(), Vector2i.LEFT)
		assert_false(_boot.get_coming_soon_screen().is_showing(), "aucun écran « à venir »")
		_boot.queue_free()
		await wait_process_frames(2)
	assert_push_error_count(0)
