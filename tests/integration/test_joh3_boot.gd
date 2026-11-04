extends GutTest
## Chapitre Johto, JOH3 (`jalon-joh3.md` §4) : le **vrai Boot** sur les départs de débogage de la
## grande ville, sans téléphone :
## - `johto_route_37_night` : les deux Sbires sont là la nuit ; `johto_route_37` (jour) : absents ;
## - `johto_goldenrod` : le premier pas dans la ville joue le haut-parleur (D-10) une seule fois ;
##   la promotion du jour suit l'horloge (un mercredi : Super Ball à moitié prix) ;
## - Jérôme n'est là que le jeudi ;
## - `johto_goldenrod_full_party` : Orme garde l'œuf (D-14), puis le donne quand une place se
##   libère.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_joh3_boot_save.json"
const SETTINGS_PATH := "user://test_joh3_boot_settings.json"
const ABSENT := "user://test_joh3_boot_absent.json"
const FADE := 0.05
const TIMEOUT := 40.0

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
	_close()
	GameState.clock = DeviceClock.new()


func _close() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null


func _launch(start: String, map_id: StringName) -> void:
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
	assert_eq(_boot.get_map().map_id, map_id, start)


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


func test_route_37_grunts_come_out_at_night_only() -> void:
	await _launch("johto_route_37_night", &"route_37")
	assert_eq(_boot.get_world_clock().period_name(), &"night")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"johto_night")
	assert_not_null(_boot.get_map().get_npc(&"sbire_a"), "Sbire A la nuit")
	assert_not_null(_boot.get_map().get_npc(&"sbire_b"), "Sbire B la nuit")
	_close()
	await _launch("johto_route_37", &"route_37")
	assert_eq(_boot.get_world_clock().period_name(), &"day")
	assert_null(_boot.get_map().get_npc(&"sbire_a"), "aucun Sbire le jour (JH-31)")
	assert_null(_boot.get_map().get_npc(&"sbire_b"))
	assert_not_null(_boot.get_map().get_npc(&"lise"), "Lise à toute heure")


func test_the_speaker_crackles_once_at_the_city_entrance() -> void:
	await _launch("johto_goldenrod", &"goldenrod_city")
	var player := _boot.get_player()
	var director := _boot.get_cutscene_director()
	assert_eq(player.get_cell(), Vector2i(34, 0))
	var played: Array[StringName] = []
	director.cutscene_started.connect(func(id: StringName) -> void: played.append(id))
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_down")
	assert_eq(played, [&"goldenrod_arrival"] as Array[StringName])
	await _play_scene_to_the_end()
	assert_eq(said, [&"goldenrod_speaker"] as Array[StringName], "D-10")
	assert_true(GameState.flags.has_flag(&"johto_goldenrod_arrived"))
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return player.get_cell().y <= 2, TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return not player.is_moving(), TIMEOUT)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return player.get_cell().y >= 4, TIMEOUT)
	Input.action_release(&"move_down")
	await wait_process_frames(5)
	assert_eq(played.size(), 1, "une seule fois")
	# Promotion du jour : le jour de l'horloge, à Johto (mercredi : Super Ball).
	assert_eq(StringName(_boot.get_menu_director().weekday_source.call()), &"wednesday")
	assert_null(_boot.get_map().get_npc(&"jerome"), "Jérôme absent un mercredi")


func test_jerome_delivers_on_thursday() -> void:
	await _launch("johto_goldenrod_thursday", &"goldenrod_city")
	assert_eq(_boot.get_world_clock().weekday_name(), &"thursday")
	var jerome := _boot.get_map().get_npc(&"jerome")
	assert_not_null(jerome, "Jérôme devant le Grand Magasin")
	if jerome != null:
		assert_eq(jerome.get_cell(), Vector2i(56, 27))


func test_orme_keeps_the_egg_while_the_team_is_full() -> void:
	await _launch("johto_goldenrod_full_party", &"goldenrod_center")
	assert_not_null(_boot.get_map().get_npc(&"orme"), "Orme attend au Centre")
	var director := _boot.get_cutscene_director()
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	assert_eq(GameState.party.size(), 6)
	assert_true(director.play(&"goldenrod_orme_egg"))
	await _play_scene_to_the_end()
	assert_true(said.has(&"goldenrod_orme_full"), "D-14")
	assert_false(GameState.flags.has_flag(&"johto_egg_received"))
	assert_eq(GameState.party.size(), 6)
	GameState.party.remove_at(5)
	assert_true(director.play(&"goldenrod_orme_egg"))
	await _play_scene_to_the_end()
	assert_true(GameState.flags.has_flag(&"johto_egg_received"))
	assert_true(GameState.party.get_at(5).is_egg(), "l'œuf de Togepi dans l'équipe")
	assert_eq(GameState.party.get_at(5).species_id, &"togepi")
