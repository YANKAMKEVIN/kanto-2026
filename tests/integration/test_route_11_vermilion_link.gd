extends GutTest
## Raccord Carmin-sur-Mer ↔ Route 11 (jalon 17 T17, jalon-17.md §2.1) avec la vraie scène Boot et
## l'autoload SceneRouter (fondus raccourcis) : sur chacune des trois rangées, pousser vers l'est
## au bord de Carmin (63, 11..13) mène à la Route 11 (0, 11..13) **même rangée**, tourné vers
## l'est, avec le titre d'arrivée ; pousser vers l'ouest au bord de la Route 11 ramène sur la même
## rangée de Carmin, tourné vers l'ouest, sans écran « à venir ». Bouche de la Cave : en attente
## propre tant que `digletts_cave` (T15) n'existe pas.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_route_11_vermilion_link_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const ROWS: Array[String] = ["n", "c", "s"]

var _boot: Boot
var _player: Player
var _zones: Array[String] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")
	_zones.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_left", &"move_right", &"move_up"]:
		Input.action_release(action)


func _start(map_id: StringName, spawn: StringName, facing: Vector2i) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_boot.zone_announced.connect(func(zone: String, _region: String) -> void:
		_zones.append(zone))
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
		_zones.clear()
		await _start(&"vermilion_city", StringName("from_route_11_" + ROWS[i]), Vector2i.RIGHT)
		assert_eq(_player.get_cell(), Vector2i(63, 11 + i), "rangée %s : bord est de Carmin" % ROWS[i])
		await _push_until(&"move_right", &"route_11")
		assert_eq(_boot.get_map().map_id, &"route_11", "rangée %s : Route 11" % ROWS[i])
		assert_eq(_player.get_cell(), Vector2i(0, 11 + i), "rangée %s : arrivée" % ROWS[i])
		assert_eq(_player.get_facing(), Vector2i.RIGHT)
		assert_true(_player.is_input_enabled())
		assert_true(_zones.has("Route 11"), "titre d'arrivée « Route 11 »")
		assert_true(GameState.discovered_maps.has(&"route_11"), "carte découverte")
		assert_false(_boot.get_coming_soon_screen().is_showing(), "aucun écran « à venir »")
		await _push_until(&"move_left", &"vermilion_city")
		assert_eq(_boot.get_map().map_id, &"vermilion_city", "rangée %s : retour" % ROWS[i])
		assert_eq(_player.get_cell(), Vector2i(63, 11 + i), "rangée %s : même rangée" % ROWS[i])
		assert_eq(_player.get_facing(), Vector2i.LEFT)
		_boot.queue_free()
		await wait_process_frames(2)
	assert_push_error_count(0)


## Bouche de la Cave : Route 11 (15..16, 7) STEP_ON ↑ → `digletts_cave` (T15), arrivée tournée ↑ ;
## en attente tant que la carte n'existe pas.
func test_cave_mouth_round_trip_waits_for_the_cave() -> void:
	if not MapCatalog.has_map(&"digletts_cave"):
		pending("digletts_cave pas encore construite (T15) : raccord de la bouche à vérifier")
		return
	for i: int in 2:
		await _start(&"route_11", StringName("from_cave_" + ["w", "e"][i]), Vector2i.UP)
		var mouth := Vector2i(15 + i, 7)
		assert_eq(_player.get_cell(), mouth + Vector2i.DOWN)
		await _push_until(&"move_up", &"digletts_cave")
		assert_eq(_boot.get_map().map_id, &"digletts_cave")
		assert_eq(_player.get_cell(), Vector2i(15 + i, 78), "bouche sud de la Cave")
		assert_eq(_player.get_facing(), Vector2i.UP)
		await _push_until(&"move_down", &"route_11")
		assert_eq(_player.get_cell(), mouth + Vector2i.DOWN, "retour devant la bouche")
		_boot.queue_free()
		await wait_process_frames(2)
	assert_push_error_count(0)
