extends GutTest
## La vie du sas de la Route 4 (jalon 12 T28, jalon-12.md §1.3 n° 5, §2.15, §2.16 ; dossier 15
## §14, §15, §20 n° 36–39) avec la vraie scène Boot, la vraie carte, le départ `route_4` et une
## sauvegarde en mémoire :
## - premier pas vers l'est (colonne 4) → `route_4_reached` en silence → objectif « continuer
##   vers Azuria. », gardé au rechargement ;
## - panneau lu de face (« ROUTE 4 » / « Mont Sélénite ← → Azuria »), rien de côté ;
## - retour dans la grotte par la bouche (→ B2F, pied de l'échelle de sortie), puis l'échelle de
##   sortie ramène au sas (les deux sens).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_4.json"
const SAVE_PATH := "user://test_route_4_life_save.json"
const ARRIVAL := Vector2i(3, 6)
const MOUTH := Vector2i(2, 6)
const SIGN := Vector2i(6, 5)
const B2F_ARRIVAL := Vector2i(11, 30)
const B2F_LADDER := Vector2i(11, 29)
const FADE := 0.05
const TIMEOUT := 12.0

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _events: Array[String] = []
var _pages: Array[String] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T15:00:00")
	_fs = MemoryFs.new()
	_events.clear()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot dans le sas (arrivée de B2F) ; [param fresh] applique le départ `route_4`, sinon la
## partie relue de la sauvegarde.
func _start(fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_4"
	_boot.start_spawn = &"from_mt_moon"
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(_title: String, _detail: String) -> void: _events.append("toast"))
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
		_pages.append(_runner.get_session().get_text()))
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_dialogue() -> void:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Un pas dans [param direction] qui change de carte : attend la fin de la transition.
func _step_to_map(direction: Vector2i, map_id: StringName) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(5)


func test_first_step_east_sets_the_cerulean_objective_silently() -> void:
	await _start(true)
	assert_eq(_player.get_cell(), ARRIVAL, "arrivée de B2F")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	assert_eq(objectives.current(GameState.flags), "traverser le Mont Sélénite.")
	await _walk(Vector2i.RIGHT, ARRIVAL + Vector2i.RIGHT)
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_4_reached"),
		TIMEOUT)
	assert_true(GameState.flags.has_flag(&"route_4_reached"))
	assert_eq(objectives.current(GameState.flags), "continuer vers Azuria.", "§20 n° 39")
	await wait_process_frames(5)
	assert_eq(_events, [] as Array[String], "en silence")
	assert_true(_player.is_input_enabled(), "le joueur garde la main")
	# Gardé au rechargement.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	GameState.flags.set_flag(&"route_4_reached", false)
	await _start(false)
	assert_true(GameState.flags.has_flag(&"route_4_reached"), "relu de la sauvegarde")
	assert_eq(objectives.current(GameState.flags), "continuer vers Azuria.")
	assert_push_error_count(0)


func test_sign_is_read_from_the_front_only() -> void:
	await _start(true)
	_boot.get_map().spawn_player_at(_player, SIGN + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_dialogue()
	assert_eq(_pages, ["ROUTE 4\nMont Sélénite ← → Azuria"] as Array[String], "§20 n° 36")
	_boot.get_map().spawn_player_at(_player, SIGN + Vector2i.RIGHT, Vector2i.LEFT)
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(), "de côté : rien")


func test_back_into_the_cave_and_out_again() -> void:
	await _start(true)
	await _step_to_map(Vector2i.LEFT, &"mt_moon_b2f")
	assert_eq(_player.get_cell(), B2F_ARRIVAL, "pied de l'échelle de sortie")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "dos à l'échelle")
	assert_false(GameState.flags.has_flag(&"route_4_reached"), "la bouche ne lève rien")
	await _step_to_map(Vector2i.UP, &"route_4")
	assert_eq(_player.get_cell(), ARRIVAL, "de retour dans le sas")
	assert_eq(_player.get_facing(), Vector2i.RIGHT)
	assert_push_error_count(0)
