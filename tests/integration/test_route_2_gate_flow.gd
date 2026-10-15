extends GutTest
## La barrière de FUTUR B de bout en bout (jalon-17.md §2.13, T21 ; dossier 20 §3.5) avec la vraie
## scène Boot, la vraie Route 2 et les vraies entrées : arrivé du couloir par l'est, on lit T-8
## depuis (35, 43) ; la barrière s'ouvre **sans changer de carte** (même instance, drapeau
## `route_2_east_gate_open`, sauvegarde) ; on la franchit vers l'ouest puis vers l'est ; le
## panneau (33, 42) lit T-9. Rechargement : la barrière reste ouverte.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_2_east.json"
const SAVE_PATH := "user://test_route_2_gate_flow_save.json"
const GATE_FLAG := &"route_2_east_gate_open"
const TIMEOUT := 12.0
const WALK_STOP := &"test_walk_stop"
const FADE := 0.05
const T8: Array[String] = ["La barrière s'ouvre de ce côté.", "Le sentier rejoint la Route 2."]
const T9 := "SENTIER ROUVERT\nRoute 2 — Cave Taupiqueur"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_2"
	_boot.start_spawn = &"from_route_2_east_n"
	_boot.start_facing = Vector2i.LEFT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"route_2")
	assert_eq(_player.get_cell(), Vector2i(41, 43))


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Interagit avec la case devant le joueur ; renvoie les pages lues.
func _interact(facing: Vector2i) -> Array[String]:
	_player.face(facing)
	var box := _boot.get_dialogue_box()
	var pages: Array[String] = []
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + 20000
	while (_boot.get_dialogue_runner().is_running() or box.is_open()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			var text := box.get_text()
			if pages.is_empty() or pages.back() != text:
				pages.append(text)
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(3)
	return pages


func test_the_gate_opens_from_the_east_without_changing_map_and_stays_open() -> void:
	await _start()
	var map := _boot.get_map()
	await _walk(Vector2i.LEFT, Vector2i(35, 43))
	assert_true(map.get_grid().is_occupied(Vector2i(34, 43)), "barrière fermée")
	assert_false(GameState.flags.has_flag(GATE_FLAG))
	var pages := await _interact(Vector2i.LEFT)
	assert_eq(pages, T8, "T-8")
	assert_true(GameState.flags.has_flag(GATE_FLAG), "drapeau posé en fin de dialogue")
	assert_same(_boot.get_map(), map, "sans changer de carte")
	assert_eq(_boot.get_map().map_id, &"route_2")
	for y: int in [43, 44]:
		assert_false(map.get_grid().is_occupied(Vector2i(34, y)), "case (34, %d) libérée" % y)
	assert_true(map.get_node(^"Entities/OpenGate").visible, "barrière ouverte peinte")
	assert_false(map.get_node(^"Entities/ClosedGateGate").visible, "barrière fermée retirée")
	# On la franchit vers l'ouest, puis vers l'est.
	await _walk(Vector2i.LEFT, Vector2i(33, 43))
	assert_eq(_player.get_cell(), Vector2i(33, 43), "passé à l'ouest")
	# Plus de T9 face à la case libre ; le panneau (33, 42) lit T-9.
	var sign_pages := await _interact(Vector2i.UP)
	assert_eq(sign_pages, [T9], "T-9 depuis (33, 43)")
	await _walk(Vector2i.RIGHT, Vector2i(41, 43))
	assert_eq(_player.get_cell(), Vector2i(41, 43), "et retour vers l'est")
	# Rechargement : la barrière reste ouverte (état déduit du drapeau).
	var reloaded := (load(MapCatalog.scene_path(&"route_2")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(reloaded)
	reloaded.refresh_npcs(GameState.flags)
	for y: int in [43, 44]:
		assert_false(reloaded.get_grid().is_occupied(Vector2i(34, y)))
	assert_push_error_count(0)
