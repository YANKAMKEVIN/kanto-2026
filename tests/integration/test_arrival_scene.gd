extends GutTest
## Micro-scène d'arrivée à Jadielle (jalon 7 T4, dossier 09 §2, plan §13) avec le vrai Boot et
## le départ de débogage `viridian` (entrée sud de Jadielle) : on monte jusqu'au premier pas sur la
## place (haut du grand escalier sud, Jadielle agrandie) ; la scène
## se joue **une seule fois**, en **4 s au plus** de bout en bout, **sans dialogue** ; les
## contrôles reviennent ; le Roucool du toit de la Boutique est parti pour la visite et revient
## au changement de carte ; l'objectif « rejoindre Jadielle » disparaît.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/viridian.json"
const SAVE_PATH := "user://test_arrival_scene_save.json"
const FADE := 0.05
const TIMEOUT := 10.0
## Durée maximale de la scène (dossier 09 §2).
const MAX_SECONDS := 4.0

var _boot: Boot
var _player: Player
var _director: CutsceneDirector
var _saved_router: Array = []
var _started_ms: int = -1
var _finished_ms: int = -1
var _plays: int = 0
var _dialogues: int = 0


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-05T17:00:00")
	_started_ms = -1
	_finished_ms = -1
	_plays = 0
	_dialogues = 0


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.force_debug_start = true
	_boot.debug_start_path = START
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_director = _boot.get_cutscene_director()
	_director.cutscene_started.connect(func(id: StringName) -> void:
		if id == &"viridian_arrival":
			_plays += 1
			_started_ms = Time.get_ticks_msec())
	_director.cutscene_finished.connect(func(id: StringName) -> void:
		if id == &"viridian_arrival":
			_finished_ms = Time.get_ticks_msec())
	_boot.get_dialogue_runner().dialogue_started.connect(func(_id: StringName) -> void:
		_dialogues += 1)
	await wait_process_frames(3)


func _objective() -> String:
	return _boot.get_menu_director().build_dashboard().objective_text


## Monte vers le nord jusqu'au début de la scène, puis attend sa fin.
func _walk_in_and_watch() -> void:
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _director.is_running(), TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func test_debug_start_lands_at_the_south_entrance() -> void:
	await _start()
	var map := _boot.get_map()
	assert_eq(map.map_id, &"viridian_city")
	assert_eq(_player.get_cell(), Vector2i(28, 39))
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_not_null(map.get_npc(&"arrival_kid"), "l'enfant attend la scène")
	assert_not_null(map.get_npc(&"viridian_roof_pidgey"), "le Roucool est sur le toit")
	assert_null(map.get_npc(&"kid"), "l'enfant « ordinaire » vient après l'arrivée")
	assert_eq(_objective(), "Objectif : rejoindre Jadielle")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"golden_hour", "lumière C2")
	assert_true(_boot.get_world_lighting().is_grade_visible())


func test_the_arrival_plays_once_in_four_seconds_without_dialogue() -> void:
	await _start()
	var map := _boot.get_map()
	await _walk_in_and_watch()
	assert_eq(_plays, 1, "la scène s'est jouée")
	assert_eq(_player.get_cell(), Vector2i(28, 23), "premier pas sur la place (haut de l'escalier)")
	var seconds := (_finished_ms - _started_ms) / 1000.0
	gut.p("micro-scène d'arrivée : %.2f s" % seconds)
	assert_between(seconds, 0.5, MAX_SECONDS, "4 s au plus de bout en bout")
	assert_eq(_dialogues, 0, "aucun dialogue")
	assert_true(_player.is_input_enabled(), "contrôles rendus")
	assert_true(GameState.flags.has_flag(&"viridian_arrived"))
	assert_eq(_objective(), "", "« rejoindre Jadielle » disparaît, en silence")
	await wait_seconds(Npc.FLY_DURATION + 0.2)
	assert_null(map.get_npc(&"viridian_roof_pidgey"), "le Roucool s'est envolé")
	assert_null(map.get_npc(&"arrival_traveler"), "le voyageur a continué vers le sud")
	assert_not_null(map.get_npc(&"arrival_kid"), "l'enfant reste pour la visite")
	assert_eq(map.get_npc(&"arrival_rattata").get_cell(), Vector2i(30, 22))
	# Revenir sur le déclencheur ne rejoue rien.
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(28, 24), TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(28, 22), TIMEOUT)
	Input.action_release(&"move_up")
	await wait_process_frames(5)
	assert_eq(_plays, 1, "une seule fois")
	assert_false(_director.is_running())
	assert_null(map.get_npc(&"viridian_roof_pidgey"), "toujours absent pendant la visite")
	assert_push_error_count(0)


func test_the_pidgey_is_back_after_a_map_change_and_the_town_lives_normally() -> void:
	await _start()
	await _walk_in_and_watch()
	await wait_seconds(Npc.FLY_DURATION + 0.2)
	SceneRouter.change_map(&"viridian_center", &"entrance", Vector2i.UP)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"viridian_center")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"interior_warm")
	SceneRouter.change_map(&"viridian_city", &"from_center", Vector2i.DOWN)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	var map := _boot.get_map()
	assert_eq(_player.get_cell(), Vector2i(21, 21), "devant la porte du Centre")
	assert_not_null(map.get_npc(&"viridian_roof_pidgey"), "le Roucool est revenu")
	for id: StringName in [&"arrival_kid", &"arrival_rattata", &"arrival_traveler"]:
		assert_null(map.get_npc(id), "%s : seulement pour la première arrivée" % id)
	for id: StringName in [&"kid", &"kid_rattata", &"traveler", &"courier", &"lass",
			&"old_man", &"gym_watcher"]:
		assert_not_null(map.get_npc(id), "%s présent" % id)
	assert_eq(_plays, 1)
	assert_push_error_count(0)


## Route 1 → Jadielle : le bord nord de la Route 1 mène à l'entrée sud de Jadielle, avec le
## titre de zone ; la sortie sud de Jadielle ramène sur la Route 1.
func test_route_1_and_viridian_are_linked_by_walking() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_viridian_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var zones: Array[String] = []
	_boot.zone_announced.connect(func(zone: String, _region: String) -> void:
		zones.append(zone))
	await wait_process_frames(3)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"viridian_city",
		TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"viridian_city")
	assert_eq(_player.get_cell(), Vector2i(28, 39))
	assert_true(zones.has("Jadielle"), "titre « JADIELLE »")
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_1", TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(23, 1))
	assert_push_error_count(0)
