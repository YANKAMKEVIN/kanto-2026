extends GutTest
## Chapitre Johto, JOH2 (`jalon-joh2.md` §4) : le **vrai Boot** sur les départs de débogage de
## Rosalia, sans téléphone :
## - `johto_rosalia_night` : moment forcé `night`, profil `johto_night` appliqué, lampes du
##   groupe `night_lights` allumées ; `johto_rosalia` (jour) : profil `johto_day`, lampes éteintes ;
## - `johto_rosalia` : le premier pas vers l'est joue la scène des Sbires (R-12 à R-14, sans
##   combat), les Sbires quittent la carte, le drapeau est posé, le sage dit R-15, et la scène ne
##   rejoue pas ;
## - `johto_rosalia_tuesday` : Margot est là ; un mercredi (horloge injectée), elle n'y est pas.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_joh2_boot_save.json"
const SETTINGS_PATH := "user://test_joh2_boot_settings.json"
const ABSENT := "user://test_joh2_boot_absent.json"
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _saved_router: Array = []
var _previous_scene: Node


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-04T12:00:00") # un mercredi, le jour


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	GameState.clock = DeviceClock.new()


func _launch(start: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.settings_store = SettingsStore.new(MemoryFs.new(), SETTINGS_PATH)
	_boot.debug_start_path = STARTS + start + ".json"
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = true
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"ecruteak_city", start)


func _lamps(map: GameMap) -> Array[Node]:
	var lamps: Array[Node] = []
	for node: Node in map.get_node(^"NightLights").get_children():
		lamps.append(node)
	return lamps


## Avance les dialogues tant que la scène tourne.
func _play_scene_to_the_end() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while director.is_running() and Time.get_ticks_msec() < deadline:
		if runner.is_running() and box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "la scène s'est terminée")


func test_night_start_lights_the_lamps_and_day_start_keeps_them_off() -> void:
	await _launch("johto_rosalia_night")
	assert_eq(_boot.get_world_clock().period_name(), &"night")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"johto_night")
	var lamps := _lamps(_boot.get_map())
	assert_gt(lamps.size(), 0)
	for lamp: Node in lamps:
		assert_true((lamp as CanvasItem).visible, "%s allumée la nuit" % lamp.name)
	_boot.free()
	_boot = null
	await _launch("johto_rosalia")
	assert_eq(_boot.get_world_clock().period_name(), &"day", "12 h : le jour")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"johto_day")
	for lamp: Node in _lamps(_boot.get_map()):
		assert_false((lamp as CanvasItem).visible, "%s éteinte le jour" % lamp.name)


func test_the_rockets_scene_plays_once_at_the_entrance() -> void:
	await _launch("johto_rosalia")
	var map := _boot.get_map()
	var player := _boot.get_player()
	var director := _boot.get_cutscene_director()
	assert_eq(player.get_cell(), Vector2i(0, 14), "arrivée from_route_38 (première case du bord)")
	assert_not_null(map.get_npc(&"sbire_1"), "les Sbires attendent devant la Tour Cendrée")
	assert_not_null(map.get_npc(&"sbire_2"))
	var played: Array[StringName] = []
	director.cutscene_started.connect(func(id: StringName) -> void: played.append(id))
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(played, [&"ecruteak_rockets"] as Array[StringName], "le premier pas joue la scène")
	await _play_scene_to_the_end()
	assert_eq(said, [&"ecruteak_rocket_1", &"ecruteak_sage_refuses", &"ecruteak_rocket_2"]
		as Array[StringName], "R-12, R-13, R-14")
	assert_true(GameState.flags.has_flag(&"johto_rosalia_rockets_seen"))
	assert_null(map.get_npc(&"sbire_1"), "les Sbires ont fui vers l'est")
	assert_null(map.get_npc(&"sbire_2"))
	assert_not_null(map.get_npc(&"sage_tour"), "le sage reste")
	assert_true(player.is_input_enabled(), "contrôles rendus")
	assert_eq(GameState.party.size(), 3, "aucun combat : l'équipe est intacte")
	# Le sage dit R-15 désormais ; revenir sur l'entrée ne rejoue rien.
	var sage := _boot.get_dialogue_library().get_dialogue(&"ecruteak_city_sage_tour")
	assert_true(sage.pick(GameState.flags).pages[0].text.begins_with("Merci, jeune Dresseur"))
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return player.get_cell().x == 0, TIMEOUT)
	Input.action_release(&"move_left")
	await wait_until(func() -> bool: return not player.is_moving(), TIMEOUT)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return player.get_cell().x == 2, TIMEOUT)
	Input.action_release(&"move_right")
	await wait_process_frames(5)
	assert_eq(played.size(), 1, "une seule fois")
	assert_false(director.is_running())


func test_margot_is_there_on_tuesday_only() -> void:
	await _launch("johto_rosalia_tuesday")
	assert_eq(_boot.get_world_clock().weekday_name(), &"tuesday", "jour imposé par le départ")
	var margot := _boot.get_map().get_npc(&"margot")
	assert_not_null(margot, "Margot, conteuse du mardi, près du Centre")
	if margot != null:
		assert_eq(margot.get_cell(), Vector2i(13, 29))
	_boot.free()
	_boot = null
	await _launch("johto_rosalia")
	assert_eq(_boot.get_world_clock().weekday_name(), &"wednesday", "horloge injectée : mercredi")
	assert_null(_boot.get_map().get_npc(&"margot"), "absente un autre jour")
