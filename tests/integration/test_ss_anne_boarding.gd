extends GutTest
## Embarquement sur le quai de Carmin (jalon 16, textes TXT-01 / TXT-02 du dossier 19 §0.5) avec la
## vraie scène Boot et les vraies entrées :
## - sans Passe Bateau : TXT-02, le marin reste en (31, 26), la passerelle est fermée ;
## - avec : TXT-01, le marin s'écarte en (30, 26) (drapeau `ss_anne_gangway_open`), le joueur
##   monte à bord (titre « S.S. ANNE ») ; le retour arrive en `from_ss_anne_w` sans être
##   rebloqué, la remontée ne redemande rien ; le Passe Bateau n'est jamais consommé ;
## - après `ss_anne_departed` : DEP-03, marin en (31, 26), rien n'est franchissable.

const BOOT_SCENE := preload("res://game/boot.tscn")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const SAVE_PATH := "user://test_ss_anne_boarding_save.json"
const STARTS := "res://tools/debug_start/%s.json"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
const WALK_STOP := &"test_walk_stop"
const CITY := &"vermilion_city"
const DECK := &"ss_anne_main_deck"
const DOCK := Vector2i(31, 24)
const TXT_01: Array[String] = ["Ton Passe Bateau, s'il te plaît.", "Parfait, bienvenue à bord !"]
const TXT_02 := "Il te faut un Passe Bateau\npour monter sur ce navire."
const DEP_03 := "Le S.S. Anne a pris le large."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(start_name: String, extra_flags: Array[StringName] = []) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(STARTS % start_name, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_i: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	_player.moved.connect(_on_player_moved)
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in extra_flags:
		GameState.flags.set_flag(flag)
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(_player.get_cell(), DOCK)


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


## Marche vers [param direction] jusqu'à [param until] ou jusqu'à l'arrêt (obstacle, scène).
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


## Marche sans cible : tient la direction ~40 images (butée contre un obstacle).
func _bump(direction: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_process_frames(40)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func _play_out() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)


func _interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_out()


func _sailor() -> Npc:
	return _boot.get_map().get_npc(&"sailor")


func _wait_map(map_id: StringName) -> void:
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == map_id and not SceneRouter.is_transitioning(), TIMEOUT)
	await _play_out()


func test_without_the_pass_the_gangway_stays_closed() -> void:
	await _start("vermilion_dock")
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 0)
	await _walk(Vector2i.DOWN, DOCK + Vector2i.DOWN)
	await _interact()
	assert_eq(_pages, [TXT_02] as Array[String], "TXT-02")
	assert_eq(_sailor().get_cell(), Vector2i(31, 26))
	assert_false(GameState.flags.has_flag(&"ss_anne_gangway_open"))
	await _bump(Vector2i.DOWN)
	assert_eq(_player.get_cell(), DOCK + Vector2i.DOWN, "on ne passe pas")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_push_error_count(0)


func test_with_the_pass_txt01_then_boarding_and_round_trip() -> void:
	await _start("vermilion_dock_ticket")
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1)
	await _walk(Vector2i.DOWN, DOCK + Vector2i.DOWN)
	await _interact()
	assert_eq(_pages, TXT_01, "TXT-01")
	assert_true(GameState.flags.has_flag(&"ss_anne_gangway_open"))
	assert_eq(_sailor().get_cell(), Vector2i(30, 26), "le marin s'est écarté")
	var zones: Array[String] = []
	_boot.zone_announced.connect(func(zone: String, _region: String) -> void:
		zones.append(zone))
	await _walk(Vector2i.DOWN, Vector2i(31, 28))
	await _wait_map(DECK)
	assert_eq(_boot.get_map().map_id, DECK, "à bord")
	assert_true(zones.has("S.S. Anne"), "titre S.S. ANNE : %s" % [zones])
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1, "Passe Bateau conservé")
	# Retour à terre (avant la CS01 : sortie libre), arrivée sur la passerelle, marin écarté.
	var exit_cell := Vector2i(12, 11)
	await _walk(Vector2i.DOWN, exit_cell)
	await _play_out()
	Input.action_press(&"move_down")
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == CITY and not SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(&"move_down")
	await _play_out()
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(_player.get_cell(), Vector2i(31, 27))
	assert_eq(_sailor().get_cell(), Vector2i(30, 26), "marin écarté au retour")
	# Sortie vers le quai sans être rebloqué, puis remontée sans rien redemander.
	_pages.clear()
	await _walk(Vector2i.UP, DOCK + Vector2i.DOWN)
	await _walk(Vector2i.UP, DOCK)
	assert_eq(_player.get_cell(), DOCK, "retour sur le quai")
	await _walk(Vector2i.DOWN, Vector2i(31, 28))
	await _wait_map(DECK)
	assert_eq(_boot.get_map().map_id, DECK, "remontée libre")
	assert_eq(_pages.filter(func(t: String) -> bool: return t.contains("Passe")),
		[] as Array[String], "rien redemandé")
	assert_push_error_count(0)


func test_after_the_departure_nothing_is_passable() -> void:
	await _start("vermilion_dock_ticket", [&"ss_anne_gangway_open", &"ss_anne_departed"])
	assert_eq(_sailor().get_cell(), Vector2i(31, 26), "marin de retour")
	await _walk(Vector2i.DOWN, DOCK + Vector2i.DOWN)
	await _interact()
	assert_eq(_pages, [DEP_03] as Array[String], "DEP-03")
	await _bump(Vector2i.DOWN)
	assert_eq(_player.get_cell(), DOCK + Vector2i.DOWN)
	await _walk(Vector2i.RIGHT, DOCK + Vector2i(1, 1))
	await _bump(Vector2i.DOWN)
	assert_eq(_player.get_cell(), DOCK + Vector2i(1, 1), "bitte et garde-fou")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1)
	assert_push_error_count(0)
