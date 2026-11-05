extends GutTest
## Le Réveil et la sauvegarde sur le **vrai Boot** (JOHP0, `jalon-joh-pierres.md` §2.4 ; dossier
## JOH-11 §15) : application tuée pendant le film (rien sur le disque, la scène reprend à l'autel),
## tuée pendant l'écran du Réveil (Réveil acquis, attaques non choisies perdues), « Continuer » sur
## chaque fichier, format v10 inchangé. Tuer = libérer Boot sans rien écrire de plus. Système de
## fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tests/fixtures/debug_start/johto_awakening_autosave.json"
const SAVE_PATH := "user://test_awakening_save.json"
const SETTINGS_PATH := "user://test_awakening_settings.json"
const ABSENT := "user://test_awakening_absent.json"
const TIMEOUT := 12.0
const TARGET := 59

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node


func before_each() -> void:
	_fs = MemoryFs.new()
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-05T12:00:00")


func after_each() -> void:
	_kill()
	GameState.clock = DeviceClock.new()


## L'application meurt : Boot disparaît, rien de plus n'est écrit.
func _kill() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null


func _launch(debug_start: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = debug_start
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = debug_start != ABSENT
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)


func _continue() -> void:
	await _launch(ABSENT)
	var title := _boot.get_opening().get_screen()
	assert_not_null(title, "écran titre")
	if title == null:
		return
	title.get_entry_button(&"continue").pressed.emit()
	await wait_until(func() -> bool: return _boot.get_opening().is_finished(), TIMEOUT)
	await wait_process_frames(2)
	assert_true(_boot.has_resumed(), "partie reprise")


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le dialogue s'est terminé")


## Le départ (la scène de test écrit d'abord l'état « avant »), jusqu'à ce que le film tourne.
func _start_until_film() -> void:
	await _launch(START)
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_until(func() -> bool:
		return _boot._awakening_overlay.get_phase() == AwakeningOverlay.Phase.SILENCE, TIMEOUT)


func _levels(saved: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for member: Dictionary in saved["party"]:
		result.append(int(member["level"]))
	return result


func test_killed_during_the_film_the_file_is_before_and_the_scene_replays() -> void:
	await _start_until_film()
	assert_true(GameState.flags.has_flag(StoneAwakening.AWAKENED), "en mémoire : déjà appliqué")
	assert_eq(GameState.party.get_at(1).level, TARGET)
	assert_false(_boot.is_stable(), "aucune écriture différée pendant le film")
	_boot.request_autosave("essai")
	await wait_process_frames(3)
	var saved := _saved()
	assert_eq(int(saved["version"]), 10)
	assert_false((saved["flags"] as Array).has(String(StoneAwakening.AWAKENED)), "rien d'écrit")
	assert_eq(_levels(saved), [44, 42, 6, 38, 40, 41] as Array[int])
	_kill()
	await _continue()
	assert_false(GameState.flags.has_flag(StoneAwakening.AWAKENED))
	assert_eq(GameState.party.get_at(0).level, 44, "rien n'a changé")
	assert_eq(GameState.party.get_at(2).species_id, &"caterpie")
	assert_eq(GameState.confiscated.party.size(), 5, "équipe confisquée intacte")
	# La scène reprend à l'autel : le Réveil rejoue.
	assert_true(_boot.get_cutscene_director().play(&"johto_awakening_test"))
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_until(func() -> bool:
		return _boot._awakening_overlay.get_phase() == AwakeningOverlay.Phase.SILENCE, TIMEOUT)
	assert_true(GameState.flags.has_flag(StoneAwakening.AWAKENED), "le Réveil rejoue")


func test_killed_during_the_screen_the_awakening_is_kept_and_moves_are_lost() -> void:
	await _launch(START)
	_boot._battle_director.speed_scale = 0.0 # Film instantané : l'écran paraît après l'écriture.
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	var overlay: AwakeningOverlay = _boot._awakening_overlay
	await wait_until(func() -> bool:
		return overlay.get_phase() == AwakeningOverlay.Phase.REVIEW, TIMEOUT)
	var saved := _saved()
	assert_false(saved.is_empty(), "écrit avant l'écran")
	assert_eq(int(saved["version"]), 10, "format inchangé")
	assert_true((saved["flags"] as Array).has(String(StoneAwakening.AWAKENED)))
	assert_eq(_levels(saved), [TARGET, TARGET, TARGET, TARGET, TARGET, TARGET] as Array[int])
	assert_true(saved.has("confiscated"), "l'équipe de Kanto attend toujours")
	var moves := GameState.party.get_at(0).moves.size()
	_kill()
	await _continue()
	assert_true(GameState.flags.has_flag(StoneAwakening.AWAKENED))
	var lead := GameState.party.get_at(0)
	assert_eq(lead.species_id, &"meganium")
	assert_eq(lead.level, TARGET)
	assert_eq(lead.moves.size(), moves, "attaques non choisies perdues, rien d'autre")
	assert_eq(lead.hp, lead.max_hp())
	assert_eq(GameState.party.get_at(5).status, StatusRules.NONE)
	assert_eq(GameState.party.get_at(2).species_id, &"butterfree")
	assert_eq(GameState.storage.get_at(0).level, TARGET)
	assert_true(GameState.pokedex.is_caught(&"metapod"))
	assert_true(GameState.pokedex.is_caught(&"butterfree"))
	# La scène rejouée ne revoit pas le Réveil.
	assert_true(_boot.get_cutscene_director().play(&"johto_awakening_test"))
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	assert_eq(_boot._awakening_overlay.get_phase(), AwakeningOverlay.Phase.IDLE)
	await _finish_dialogue()


func test_a_move_learned_on_the_screen_reaches_the_file() -> void:
	await _launch(START)
	_boot._battle_director.speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	var overlay: AwakeningOverlay = _boot._awakening_overlay
	await wait_until(func() -> bool:
		return overlay.get_phase() == AwakeningOverlay.Phase.REVIEW, TIMEOUT)
	assert_true(overlay.handle_back(), "retour avalé")
	# Le Chenipan a deux capacités : place libre, l'attaque s'apprend.
	var buttons := overlay.get_row_buttons()
	assert_eq(buttons.size(), 6)
	var row := 2
	var butterfree := GameState.party.get_at(row)
	var before := butterfree.moves.size()
	var offered := overlay._row_results[row].new_moves.size()
	assert_gt(offered, 0)
	buttons[row].pressed.emit()
	var banner := overlay.get_message_banner()
	var prompt := _boot._battle_director.get_move_learn_prompt()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while overlay._teaching and Time.get_ticks_msec() < deadline:
		banner.skip()
		var panel := prompt.get_forget_panel()
		if panel != null and panel.is_shown() and not panel.is_answered():
			panel.get_skip_button().pressed.emit()
		await wait_process_frames(1)
	assert_false(overlay._teaching, "le déroulé des attaques est allé au bout")
	assert_gt(butterfree.moves.size(), before, "attaque apprise")
	assert_true(buttons[row].disabled, "plus rien à voir")
	overlay.get_continue_button().pressed.emit()
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	var saved := _saved()
	assert_eq((saved["party"][row]["moves"] as Array).size(), butterfree.moves.size(),
		"l'écriture de fin d'écran porte l'attaque")
	await _finish_dialogue()
