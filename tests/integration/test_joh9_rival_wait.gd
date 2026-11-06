extends GutTest
## Sommet du Mont Argenté (décision de Kevin du 2026-11-06, `docs/tech/qa-johto-a17.md` Q1) : après
## Giovanni, le rival arrive, parle et attend sans combat. Le **vrai Boot** joue la scène ; le
## joueur garde la main, le déclencheur du palier ne rejoue rien, le combat ne part qu'après
## confirmation (refuser ne coûte rien). Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tests/fixtures/debug_start/johto_rival_wait.json"
const SAVE_PATH := "user://test_joh9_rival_wait_save.json"
const SETTINGS_PATH := "user://test_joh9_rival_wait_settings.json"
const ABSENT := "user://test_joh9_rival_wait_absent.json"
const SCENE_TIMEOUT_MS := 40000

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node
var _answers: Array[bool] = []
var _battles: Array[StringName] = []


func before_each() -> void:
	_fs = MemoryFs.new()
	_answers.clear()
	_battles.clear()
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-06T12:00:00")


func after_each() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	GameState.clock = DeviceClock.new()


func _launch() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = START
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = true
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_cutscene_director().step_played.connect(_on_step)
	await wait_process_frames(2)


func _on_step(step: CutsceneStep) -> void:
	if step.kind == CutsceneStep.Kind.BATTLE:
		_battles.append(step.trainer_id)


## Joue ce qui est en cours, pages tournées, choix répondus ; s'arrête à l'entrée d'un combat.
func _play_out() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS  # temps réel : délai de garde
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and _battles.is_empty() and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var yes: bool = _answers.pop_front() if not _answers.is_empty() else false
			(cards.get_confirm_button() if yes else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)


func _flag(flag: StringName) -> bool:
	return GameState.flags.has_flag(flag)


func _play(scene: StringName) -> bool:
	var started := _boot.get_cutscene_director().play(scene)
	await _play_out()
	return started


func test_the_rival_waits_and_the_fight_needs_a_confirmation() -> void:
	await _launch()
	assert_true(await _play(&"mt_silver_summit"), "Giovanni, Cenere puis le rival")
	assert_true(_flag(&"johto_giovanni_seen"))
	assert_true(_flag(&"johto_rival_final_arrived"), "A-40, A-41, A-41b dits")
	assert_false(_flag(&"johto_rival_final_met"), "pas de combat engagé")
	assert_eq(_battles, [] as Array[StringName], "le joueur garde la main")
	assert_false(_boot.get_cutscene_director().is_running())
	var rival := _boot.get_map().get_npc(&"rival_sommet")
	assert_not_null(rival, "il reste au sommet")
	assert_eq(rival.get_cell(), Vector2i(14, 8))
	assert_eq(rival.get_spec().dialogue, &"mt_silver_summit_rival_talk", "il répond quand on lui parle")
	# Le palier (16, 5) est le chemin de l'échelle : il ne rejoue plus rien.
	assert_false(_boot.get_cutscene_director().play(&"mt_silver_summit"), "descente libre")
	# Refuser : ni combat ni réveil, il attend toujours.
	_answers = [false]
	assert_true(await _play(&"mt_silver_rival_talk"))
	assert_eq(_battles, [] as Array[StringName], "« PAS ENCORE » ne lance rien")
	assert_false(_flag(&"johto_rival_final_ready"))
	assert_false(_flag(&"johto_rival_final_met"))
	assert_eq(_boot.get_map().map_id, &"mt_silver_summit", "pas de réveil au Centre")
	assert_not_null(_boot.get_map().get_npc(&"rival_sommet"))
	# Accepter : le combat final part.
	_answers = [true]
	assert_true(await _play(&"mt_silver_rival_talk"))
	assert_eq(_battles, [&"mt_silver_rival_final"] as Array[StringName])
	assert_true(_flag(&"johto_rival_final_met"))
