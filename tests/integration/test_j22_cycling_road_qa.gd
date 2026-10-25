extends GutTest
## Défaut de la QA de nuit du J22 sur A17 (2026-10-22, n° 6) rejoué sur la vraie scène Boot avec
## les départs de débogage du téléphone : à la sortie du poste 16 côté Piste, le héros était
## dessiné à pied (bouton Vélo grisé, « Pas de marche à pied… » à l'appui). L'état était bien
## « en selle » ; c'est l'apparence qui n'avait pas d'animations `bike_*` (art non livré) et le
## joueur retombait sur la marche. Correction : vélo provisoire sous le héros
## ([method Player.is_bike_drawn]).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START_CYCLING_ROAD := "res://tools/debug_start/cycling_road_qa.json"
const START_FUCHSIA := "res://tools/debug_start/fuchsia_qa.json"
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _player: Player
var _pages: Array[String] = []
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T10:00:00")
	_pages.clear()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _start(start_path: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_j22_cycling_road_qa.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = start_path
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _finish() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _step(direction: StringName) -> void:
	var before := _player.get_cell()
	Input.action_press(direction)
	await wait_until(func() -> bool: return _player.get_cell() != before \
		or _boot.get_cutscene_director().is_running(), 3.0)
	Input.action_release(direction)
	await wait_until(func() -> bool: return not _player.is_moving(), 3.0)
	await _finish()


func test_leaving_gate_16_onto_the_road_draws_the_player_in_the_saddle() -> void:
	await _start(START_CYCLING_ROAD)
	assert_eq(_boot.get_map().map_id, &"route_16_gate")
	assert_false(_player.is_bike_drawn(), "à pied dans le poste")
	for i: int in 4:
		await _step(&"move_left")
	assert_has(_pages, "La Piste descend jusqu'à Parmanie.\nBonne route, et gare aux Motards !")
	while _player.get_cell().x > 2:
		await _step(&"move_left")
	await _step(&"move_down")
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_16_west", TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning() \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"route_16_west")
	assert_true(_boot.get_map().is_cycling_road_at(_player.get_cell()), "sur la Piste")
	assert_eq(_player.get_mount(), Mount.Kind.BIKE, "monté d'office")
	assert_eq(GameState.player_mount, Mount.Kind.BIKE, "monture d'état")
	assert_true(_player.is_bike_drawn(), "le vélo se voit")
	# Bouton grisé et refus de descendre : voulus sur la Piste (dossier 25 §16.1.4).
	assert_true(_boot.get_mount_director().is_bike_blocked())
	await wait_until(func() -> bool: return not _player.is_moving() and _boot.is_stable(),
		TIMEOUT)
	_pages.clear()
	assert_eq(_boot.get_mount_director().toggle_bike(), BikeRules.Check.ON_CYCLING_ROAD)
	await _finish()
	assert_has(_pages, "Pas de marche à pied")
	assert_true(_player.is_bike_drawn(), "toujours en selle")


func test_the_bike_button_in_fuchsia_draws_then_hides_the_bike() -> void:
	await _start(START_FUCHSIA)
	assert_eq(_boot.get_map().map_id, &"fuchsia_city")
	assert_false(_player.is_bike_drawn())
	assert_eq(_boot.get_mount_director().toggle_bike(), BikeRules.Check.OK)
	await wait_process_frames(2)
	assert_eq(_player.get_mount(), Mount.Kind.BIKE)
	assert_true(_player.is_bike_drawn(), "en selle à l'écran")
	for direction: StringName in [&"move_left", &"move_down", &"move_right", &"move_up"]:
		Input.action_press(direction)
		await wait_process_frames(2)
		Input.action_release(direction)
		await wait_until(func() -> bool: return not _player.is_moving(), 3.0)
		assert_true(_player.is_bike_drawn(), "vélo visible vers %s" % direction)
	assert_eq(_boot.get_mount_director().toggle_bike(), BikeRules.Check.OK)
	await wait_process_frames(2)
	assert_false(_player.is_bike_drawn(), "à pied")
