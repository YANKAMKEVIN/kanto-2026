extends GutTest
## Chapitre Johto, JOH4 (`jalon-joh4.md` §2.5, dossier joh-05 §4 et §11) : le **vrai Boot** sur
## les départs de débogage, sans téléphone :
## - `johto_kurt_house` : le récit de Fargas (E-11 à E-13), puis devant le puits le Sbire fuit
##   (E-14) et Fargas descend ; la barrière est levée ;
## - `johto_brace` : la scène de Brace (combat remplacé par une issue imposée) : victoire → fuite,
##   papiers (E-21, deux objets clés), Fargas et la Roche Royale ; défaite → réveil au Centre
##   d'Écorcia, Brace reste ;
## - `johto_azalea_after` : les Ramoloss sont de retour dans Écorcia ; `johto_azalea` : aucun.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_joh4_story_save.json"
const SETTINGS_PATH := "user://test_joh4_story_settings.json"
const ABSENT := "user://test_joh4_story_absent.json"
const FADE := 0.05
const TIMEOUT := 40.0


## Faux directeur de combat : renvoie une issue imposée sans jouer le combat.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.WIN
	var calls: Array[StringName] = []

	func run(trainer_id: StringName, _map: GameMap,
			_world_actors: Dictionary[StringName, StringName]) -> int:
		calls.append(trainer_id)
		await get_tree().process_frame
		return outcome_to_return


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


func _said() -> Array[StringName]:
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	return said


func test_kurt_tells_the_story_and_goes_down_the_well() -> void:
	await _launch("johto_kurt_house", &"azalea_kurt_house")
	assert_not_null(_boot.get_map().get_npc(&"fargas"), "Fargas est chez lui")
	var said := _said()
	var director := _boot.get_cutscene_director()
	assert_true(director.play(&"azalea_kurt_story"))
	await _play_scene_to_the_end()
	assert_eq(said, [&"azalea_kurt_greeting", &"azalea_kurt_story", &"azalea_kurt_leaves",
		&"azalea_well_grunt_flees"] as Array[StringName], "E-11 à E-14")
	assert_true(GameState.flags.has_flag(&"johto_kurt_told"))
	var map := _boot.get_map()
	assert_eq(map.map_id, &"azalea_town", "devant le puits")
	assert_eq(_boot.get_player().get_cell(), Vector2i(38, 11))
	for id: StringName in [&"sbire_puits", &"sbire_scene", &"fargas_scene"]:
		assert_null(map.get_npc(id), "%s est descendu" % id)
	assert_true(_boot.get_player().is_input_enabled(), "contrôles rendus")


## Victoire contre Brace (issue imposée) : fuite, papiers, Fargas, Roche Royale ; objets clés au Sac.
func test_brace_then_papers_then_kings_rock() -> void:
	await _launch("johto_brace", &"slowpoke_well_b2f")
	var stub := StubRunner.new()
	add_child_autofree(stub)
	stub.outcome_to_return = Battle.Outcome.WIN
	var director := _boot.get_cutscene_director()
	director.set_battle_runner(stub)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"brace"), "Brace attend dans son alcôve")
	assert_null(map.get_npc(&"papiers"))
	var said := _said()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_up")
	await _play_scene_to_the_end()
	assert_eq(stub.calls, [&"slowpoke_well_admin_brace"] as Array[StringName], "un seul combat")
	assert_eq(said, [&"slowpoke_well_brace_before", &"slowpoke_well_brace_defeated",
		&"slowpoke_well_brace_after", &"slowpoke_well_brace_flees"] as Array[StringName],
		"E-17 à E-20")
	assert_true(GameState.flags.has_flag(&"johto_brace_defeated"))
	assert_null(map.get_npc(&"brace"), "Brace s'est enfui")
	assert_not_null(map.get_npc(&"papiers"), "les papiers sont tombés")
	assert_not_null(map.get_npc(&"fargas_b2f"), "Fargas, remis, attend à l'échelle")
	# Les papiers (E-21).
	assert_true(director.play(&"slowpoke_well_papers"))
	await _play_scene_to_the_end()
	assert_eq(GameState.bag.count_of(&"mission_order"), 1, "Ordre de mission")
	assert_eq(GameState.bag.count_of(&"radio_card"), 1, "Carte d'accès")
	assert_true(GameState.flags.has_flag(&"johto_radio_pass"))
	assert_null(map.get_npc(&"papiers"))
	# Fargas et la Roche Royale (E-23, E-24).
	assert_true(director.play(&"slowpoke_well_kings_rock"))
	await _play_scene_to_the_end()
	assert_eq(GameState.bag.count_of(&"kings_rock"), 1, "Roche Royale")
	assert_true(GameState.flags.has_flag(&"johto_slowpoke_well_cleared"))
	# Le déclencheur ne rejoue pas.
	assert_false(director.play(&"slowpoke_well_brace"), "Brace une seule fois")


## Défaite (dossier §11) : réveil au Centre d'Écorcia ; Brace reste, rien n'est posé.
func test_losing_to_brace_wakes_up_at_azalea_center() -> void:
	await _launch("johto_brace", &"slowpoke_well_b2f")
	var stub := StubRunner.new()
	add_child_autofree(stub)
	stub.outcome_to_return = Battle.Outcome.LOSS
	var director := _boot.get_cutscene_director()
	director.set_battle_runner(stub)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_up")
	await _play_scene_to_the_end()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"azalea_center", TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"azalea_center", "réveil au Centre d'Écorcia")
	assert_false(GameState.flags.has_flag(&"johto_brace_defeated"))
	assert_eq(GameState.bag.count_of(&"mission_order"), 0)


func test_slowpokes_come_back_to_azalea() -> void:
	await _launch("johto_azalea", &"azalea_town")
	for id: StringName in [&"ramoloss_1", &"ramoloss_2", &"ramoloss_3", &"ramoloss_margelle"]:
		assert_null(_boot.get_map().get_npc(id), "%s absent avant le puits (E-10)" % id)
	assert_not_null(_boot.get_map().get_npc(&"sbire_puits"), "le Sbire garde la descente")
	_boot.free()
	_boot = null
	await _launch("johto_azalea_after", &"azalea_town")
	for id: StringName in [&"ramoloss_1", &"ramoloss_2", &"ramoloss_3", &"ramoloss_margelle"]:
		assert_not_null(_boot.get_map().get_npc(id), "%s de retour (E-26, E-27)" % id)
	assert_null(_boot.get_map().get_npc(&"sbire_puits"))
