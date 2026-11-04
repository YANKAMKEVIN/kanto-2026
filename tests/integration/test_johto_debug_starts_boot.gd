extends GutTest
## JOH0 (validation déléguée par Kevin le 2026-11-04, `jalon-joh0.md` §4) : le **vrai Boot** sur
## les trois parcours du sous-jalon A, sans téléphone :
## - Continuer sur la sauvegarde v9 de fin de Kanto (`v9_fin_kanto.json`, écrite par `main`) :
##   lue comme une v9, partie reprise, premier autosave réécrit en v10 avec le lien de migration ;
## - départ `johto_return` (ici sa copie avec `autosave`) : la scène `johto_return_test` joue à
##   l'entrée de carte, l'écran du choix des 6 s'ouvre avec les 7 de la réserve, VALIDER rend les
##   6 à l'équipe et range le 7e au Stockage, les objets reviennent au Sac, `johto_team_returned`
##   est posé, la section `confiscated` disparaît du fichier écrit (v10) ;
## - départ `johto_confiscated` : le terminal du Centre répond « Le réseau de Kanto ne répond
##   pas. » et le Stockage ne s'ouvre pas.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const FIXTURE_V9 := "res://tests/fixtures/save/v9_fin_kanto.json"
const START_RETURN := "res://tests/fixtures/debug_start/johto_return_autosave.json"
const START_CONFISCATED := "res://tools/debug_start/johto_confiscated.json"
const SAVE_PATH := "user://test_johto_boot_save.json"
const SETTINGS_PATH := "user://test_johto_boot_settings.json"
const ABSENT := "user://test_johto_boot_absent.json"
const TIMEOUT := 12.0

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node


func before_each() -> void:
	_fs = MemoryFs.new()
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-04T12:00:00")


func after_each() -> void:
	Input.action_release(&"interact")
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	GameState.clock = DeviceClock.new()


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


## Écritures réelles de la sauvegarde (renommage du fichier temporaire).
func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


## Avance le dialogue en cours jusqu'à sa fin.
func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le dialogue s'est terminé")


func _species(party: Array[Pokemon]) -> Array[StringName]:
	var result: Array[StringName] = []
	for pokemon: Pokemon in party:
		result.append(pokemon.species_id)
	return result


# --- Continuer sur la v9 de fin de Kanto -------------------------------------------------------

func test_continue_on_the_v9_save_rewrites_it_as_v10_with_the_migration_bond() -> void:
	_fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V9)
	await _launch(ABSENT)
	var title := _boot.get_opening().get_screen()
	assert_not_null(title, "écran titre")
	if title == null:
		return
	assert_eq(title.get_featured(), &"continue", "partie reconnue")
	title.get_entry_button(&"continue").pressed.emit()
	await wait_until(func() -> bool: return _boot.get_opening().is_finished(), TIMEOUT)
	await wait_process_frames(2)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.save_system.read_version, 9, "lue comme une v9 (journal « v9 → v10 »)")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V9))
	var party_size: int = (original["party"] as Array).size()
	assert_eq(GameState.party.size(), party_size, "même équipe")
	assert_true(GameState.confiscated.is_empty(), "rien de confisqué")
	assert_false(GameState.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	assert_eq(_writes(), 1, "premier autosave écrit")
	assert_false(_fs.files.has(SAVE_PATH + ".rejected"), "rien d'écarté")
	var saved := _saved()
	assert_eq(int(saved["version"]), 10, "réécrite en v10")
	assert_eq((saved["party"] as Array).size(), party_size)
	for member: Dictionary in saved["party"]:
		assert_eq(member.get("bond"), SaveSystem.V10_MIGRATED_BOND * 1.0, "lien de migration")
	assert_false(saved.has("confiscated"))


# --- Retour de l'équipe (écran du choix des 6) ---------------------------------------------------

func test_the_return_scene_opens_the_choice_and_validate_restores_six() -> void:
	await _launch(START_RETURN)
	assert_eq(_boot.get_map().map_id, &"viridian_center")
	assert_eq(GameState.confiscated.party.size(), 5, "5 confisqués")
	var overlay: TeamReturnOverlay = _boot._team_return_overlay
	assert_not_null(overlay)
	var director := _boot.get_cutscene_director()
	# La scène joue à l'entrée de carte (différée) : dialogue d'avant, puis l'écran du choix.
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_until(func() -> bool: return overlay.is_open(), TIMEOUT)
	assert_true(overlay.is_open(), "l'écran du choix des 6 est ouvert")
	assert_eq(director.get_cutscene_id(), &"johto_return_test", "la scène attend le choix")
	assert_eq(overlay.get_buttons().size(), 7, "2 de Johto + 5 confisqués")
	assert_eq(overlay.get_count_text(), "6 / 6", "sélection par défaut : les 6 premiers")
	assert_false(overlay.get_confirm_button().disabled, "VALIDER permis")
	assert_true(overlay.handle_back(), "le retour Android est avalé")
	assert_eq(_writes(), 0, "rien d'écrit avant VALIDER")
	overlay.get_confirm_button().pressed.emit()
	await wait_until(func() -> bool: return not overlay.is_open(), TIMEOUT)
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogue()
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	await wait_process_frames(2)
	assert_eq(_species(GameState.party.get_all()),
		[&"squirtle", &"rattata", &"charizard", &"pidgeot", &"raticate", &"nidoking"],
		"les 6 premiers, dans l'ordre de la réserve")
	assert_eq(_species(GameState.storage.get_all()), [&"alakazam"], "le 7e au Stockage")
	assert_true(GameState.confiscated.is_empty(), "plus rien de confisqué")
	assert_true(GameState.flags.has_flag(TeamConfiscation.RETURNED))
	assert_false(GameState.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_eq(GameState.bag.count_of(&"great_ball"), 7, "les objets reviennent")
	assert_eq(GameState.bag.count_of(&"poke_ball"), 6)
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	var saved := _saved()
	assert_eq(int(saved["version"]), 10)
	assert_eq((saved["party"] as Array).size(), 6)
	assert_eq((saved["storage"] as Array).size(), 1)
	assert_false(saved.has("confiscated"), "section « confiscated » disparue")
	assert_true((saved["flags"] as Array).has("johto_team_returned"))


# --- Stockage hors ligne ---------------------------------------------------------------------------

func test_the_center_terminal_says_the_network_is_down_and_opens_nothing() -> void:
	await _launch(START_CONFISCATED)
	assert_eq(_boot.get_map().map_id, &"viridian_center")
	assert_true(TeamConfiscation.is_storage_offline(GameState.flags), "Stockage hors ligne")
	assert_eq(_boot.get_player().get_cell(), _boot.get_map().get_spawn_cell(&"terminal"))
	var played: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(
		func(id: StringName) -> void: played.append(id))
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	# La réplique du terminal (« Un terminal de Stockage Pokémon. »), puis, à sa fin,
	# l'avis hors ligne à la place du Stockage.
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	await wait_until(func() -> bool: return runner.is_running(), TIMEOUT)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not played.has(TeamConfiscation.STORAGE_OFFLINE_DIALOGUE) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_eq(played.size(), 2, "sa réplique puis « storage_offline »")
	assert_eq(played.back(), TeamConfiscation.STORAGE_OFFLINE_DIALOGUE,
		"le terminal répond par « storage_offline »")
	await wait_until(func() -> bool: return box.is_open(), TIMEOUT)
	assert_string_contains(box.get_text(), "réseau de Kanto")
	await _finish_dialogue()
	await wait_process_frames(2)
	assert_false(_boot.get_menu_director().is_open(), "le Stockage ne s'ouvre pas")
	assert_eq(_writes(), 0, "départ de débogage sans autosave : rien d'écrit")
