extends GutTest
## Ascenseur dans le moteur (jalon 20 T13, `docs/tech/jalon-20.md` §2.3.3, §2.3.5 ; dossier 23 §9,
## §13.4, §19). Vraie scène Boot sur les cartes de QA `qa_elevator_j20` (cabine) et
## `qa_elevator_j20_1f` / `_2f` (étages), retirées au T24 ; ascenseurs de test lus dans
## `tests/fixtures/elevators/` ([member Boot.elevators_path]). Les tests sur le vrai grand
## magasin viendront avec ses cartes (T16).
## - 1er → cabine → panneau → 2e → sortie au 2e (arrivée `from_elevator`) ;
## - FERMER (et retour Android) : rien ne change, la sortie mène toujours au 1er ;
## - sauvegarde écrite dans la cabine → position de l'arrivée de l'étage courant ; reprise ;
## - ascenseur à clé sans la Clé → T-50, pas de panneau ; avec la Clé → panneau.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_elevator_flow_save.json"
const OPEN := "res://tests/fixtures/elevators/qa_j20_open.json"
const KEYED := "res://tests/fixtures/elevators/qa_j20_key.json"
const CAR := &"qa_elevator_j20"
const FLOOR_1 := &"qa_elevator_j20_1f"
const FLOOR_2 := &"qa_elevator_j20_2f"
## Arrivée `from_elevator` des deux étages, et arrivée `entrance` de la cabine.
const ARRIVAL := Vector2i(3, 1)
const CAR_ENTRANCE := Vector2i(2, 1)
const T50 := "Le panneau ne répond pas. Il faut une clé."
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []
var _events: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_events.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_up", &"move_down"]:
		Input.action_release(action)


func test_ride_to_the_second_floor_and_walk_out_there() -> void:
	await _start(OPEN)
	await _enter_car()
	var director := _boot.get_elevator_director()
	assert_eq(director.get_current_floor(), &"1f", "on vient du 1er")
	assert_eq(_exit_target(), [FLOOR_1, &"from_elevator"], "sortie vers le 1er")
	await _examine_panel()
	assert_true(director.is_panel_open(), "panneau ouvert")
	var panel := director.get_panel() as ElevatorPanel
	assert_true(panel.is_open(), "écran provisoire ouvert")
	assert_eq(panel.get_view().current_floor(), &"1f", "étage courant grisé")
	assert_eq(panel.get_view().choosable_ids(), [&"2f"] as Array[StringName])
	assert_false(_boot.is_stable(), "panneau ouvert : partie pas stable")
	panel.floor_chosen.emit(&"2f")
	assert_true(director.is_riding(), "trajet en cours")
	assert_false(_boot.is_stable(), "aucune écriture pendant le trajet")
	assert_true(director.handle_back(), "retour Android avalé pendant le trajet")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_events, ["started:2f", "finished:2f"] as Array[String])
	assert_eq(director.get_current_floor(), &"2f")
	assert_eq(_boot.get_map().map_id, CAR, "toujours dans la cabine : on sort à pied")
	assert_eq(_exit_target(), [FLOOR_2, &"from_elevator"], "sortie réorientée")
	assert_false(panel.is_open())
	await _step(Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, FLOOR_2, "sortie au 2e")
	assert_eq(_player.get_cell(), ARRIVAL, "devant la porte de l'ascenseur")
	assert_eq(director.get_elevator(), null, "hors cabine")
	assert_push_error_count(0)


func test_close_changes_nothing() -> void:
	await _start(OPEN)
	await _enter_car()
	var director := _boot.get_elevator_director()
	await _examine_panel()
	(director.get_panel() as ElevatorPanel).closed.emit()
	assert_false(director.is_panel_open(), "FERMER")
	assert_true(_boot.is_stable(), "joueur libre")
	assert_eq(_events, ["closed"] as Array[String])
	# Même chose avec le retour Android.
	await _examine_panel()
	_boot._on_go_back()
	assert_false(director.is_panel_open(), "retour Android = FERMER")
	assert_false(_boot.get_menu_director().is_open(), "le retour n'ouvre pas le menu")
	assert_eq(director.get_current_floor(), &"1f", "étage inchangé")
	assert_eq(_exit_target(), [FLOOR_1, &"from_elevator"])
	await _step(Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, FLOOR_1, "on ressort au 1er")


func test_a_save_in_the_car_resumes_in_front_of_the_floor_door() -> void:
	await _start(OPEN)
	await _enter_car()
	await _examine_panel()
	_boot.get_elevator_director().choose_floor(&"2f")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_boot._write_save("test"), OK)
	var saved: Dictionary = JSON.parse_string(_fs.read_text(SAVE_PATH))
	assert_eq(saved.get("map"), String(FLOOR_2), "jamais la cabine")
	var cell: Array = saved.get("cell", [])
	var facing: Array = saved.get("facing", [])
	assert_eq(Vector2i(int(cell[0]), int(cell[1])), ARRIVAL, "arrivée `from_elevator` du 2e")
	assert_eq(Vector2i(int(facing[0]), int(facing[1])), Vector2i.DOWN,
		"orientation de la sortie (↓)")
	# Ouvrir le menu dans la cabine pousse la même position (Carte, Dresseur).
	_boot.get_menu_director().open()
	assert_eq([GameState.current_map, GameState.player_cell], [FLOOR_2, ARRIVAL])
	_boot.get_menu_director().close()
	_boot.queue_free()
	await wait_process_frames(2)
	await _boot_on(OPEN, &"", &"")
	assert_eq(_boot.get_map().map_id, FLOOR_2, "reprise au 2e")
	assert_eq(_player.get_cell(), ARRIVAL, "devant la porte")


func test_keyed_elevator_without_the_key_says_t50() -> void:
	await _start(KEYED)
	await _enter_car()
	var director := _boot.get_elevator_director()
	_pages.clear()
	await _examine_panel()
	assert_false(director.is_panel_open(), "le panneau ne répond pas")
	assert_eq(_pages, [T50] as Array[String], "T-50")
	assert_true(_boot.is_stable())
	assert_eq(director.choose_floor(&"2f"), ElevatorRules.Status.UNKNOWN_FLOOR, "aucun trajet")
	(GameState.bag as Bag).add(&"lift_key")
	await _examine_panel()
	assert_true(director.is_panel_open(), "avec la Clé, le panneau s'ouvre")
	assert_eq(director.panel_view().floors.map(func(f: Dictionary) -> String: return f["label"]),
		["B1F", "B2F"])
	director.close_panel()


# --- Outils -----------------------------------------------------------------------------------

func _start(elevators: String) -> void:
	await _boot_on(elevators, FLOOR_1, &"from_elevator")
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _boot_on(elevators: String, map: StringName, spawn: StringName) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.elevators_path = elevators
	if not map.is_empty():
		_boot.start_map = map
		_boot.start_spawn = spawn
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	var director := _boot.get_elevator_director()
	director.ride_started.connect(func(id: StringName) -> void: _events.append("started:%s" % id))
	director.ride_finished.connect(func(id: StringName) -> void:
		_events.append("finished:%s" % id))
	director.panel_closed.connect(func() -> void: _events.append("closed"))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Du 1er (devant la porte, tourné ↑) à la cabine.
func _enter_car() -> void:
	await _step(Vector2i.UP)
	assert_eq(_boot.get_map().map_id, CAR, "dans la cabine")
	assert_eq(_player.get_cell(), CAR_ENTRANCE)


## Un pas (ou un passage) vers [param direction], puis la partie stable.
func _step(direction: Vector2i) -> void:
	var action := &"move_up" if direction == Vector2i.UP else &"move_down"
	var from_map := _boot.get_map().map_id
	var from_cell := _player.get_cell()
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _player.is_moving() or _player.get_cell() != from_cell \
			or SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await wait_process_frames(2)
	await wait_until(func() -> bool:
		return _boot.is_stable() and not _player.is_moving(), TIMEOUT)
	if _boot.get_map().map_id == from_map and SceneRouter.is_transitioning():
		await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## EXAMINER le panneau (tourné ↑ sous lui) et dérouler le dialogue.
func _examine_panel() -> void:
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(2)


## [carte, arrivée] de la sortie de la cabine.
func _exit_target() -> Array:
	for warp: Warp in _boot.get_map().get_warps().get_all():
		return [warp.target_map, warp.target_spawn]
	return []
