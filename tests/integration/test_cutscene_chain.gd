extends GutTest
## Briques du monde du jalon 13 (jalon-13.md §2.8, §2.9 ; T16) avec la vraie scène Boot, l'autoload
## SceneRouter (fondus raccourcis) et une sauvegarde en mémoire :
## - enchaînement « next » : à la fin d'une scène qui a une suite, la sauvegarde est écrite tout
##   de suite (le drapeau de la première scène y est, pas celui de la suite), puis la suite est
##   jouée si une de ses variantes s'applique ; sinon rien ; jamais de second enchaînement ;
## - Grand moment du rival : un seul par Dresseur ; « moment »: "win" → seulement à la victoire.
## Les scènes de test sont ajoutées à la bibliothèque de Boot ; les vraies scènes du rival n° 3 et
## d'Ondine (T19) seront couvertes par `test_route_24_misty`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_cutscene_chain_save.json"
const DATE := "2026-10-12T10:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000

var _fs: MemoryFs
var _boot: Boot
var _saved_router: Array = []
var _started: Array[StringName] = []
## Drapeaux de la sauvegarde au début de chaque scène, et nombre d'écritures.
var _saved_flags_at_start: Array[Array] = []
var _writes_at_start: Array[int] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_started.clear()
	_saved_flags_at_start.clear()
	_writes_at_start.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()


func _start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await _until_stable()
	assert_true(_boot.is_stable(), "partie stable avant le test")
	assert_true(_boot.is_autosave_enabled())
	var director := _boot.get_cutscene_director()
	director.cutscene_started.connect(_on_cutscene_started)
	assert_true(_boot.get_cutscene_library().add_from_dict({
		"t16_first": {"next": "t16_second", "steps": [{"set": ["t16_first_done"]}]},
		"t16_second": {"unless": ["t16_second_done"], "steps": [
			{"wait": 0.05}, {"set": ["t16_second_done"]}]},
	}, "test"))
	assert_true(_boot.get_cutscene_library().check_next_references())


func _until_stable() -> void:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not _boot.is_stable() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
	await wait_process_frames(2)


func _until_no_scene() -> void:
	var director := _boot.get_cutscene_director()
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)


## Relevé au moment de l'événement (la sauvegarde vue au début de chaque scène).
func _on_cutscene_started(cutscene_id: StringName) -> void:
	_started.append(cutscene_id)
	_saved_flags_at_start.append(JsonFields.get_array(_saved(), "flags"))
	_writes_at_start.append(_writes())


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


# --- Enchaînement « next » (§2.9) ------------------------------------------------------------

func test_save_is_written_between_the_two_scenes() -> void:
	await _start()
	_fs.journal.clear()
	assert_true(_boot.get_cutscene_director().play(&"t16_first"))
	await _until_no_scene()
	assert_eq(_started, [&"t16_first", &"t16_second"] as Array[StringName], "suite jouée")
	assert_eq(_writes_at_start[0], 0, "rien d'écrit pendant la première scène")
	assert_eq(_writes_at_start[1], 1, "une écriture entre les deux scènes")
	var flags: Array = _saved_flags_at_start[1]
	assert_true(flags.has("t16_first_done"), "la sauvegarde d'entre-scènes a la première")
	assert_false(flags.has("t16_second_done"), "et pas encore la suite")
	assert_true(GameState.flags.has_flag(&"t16_second_done"), "suite jouée jusqu'au bout")


func test_next_is_not_played_when_no_variant_applies() -> void:
	await _start()
	GameState.flags.set_flag(&"t16_second_done")
	_fs.journal.clear()
	assert_true(_boot.get_cutscene_director().play(&"t16_first"))
	await _until_no_scene()
	assert_eq(_started, [&"t16_first"] as Array[StringName], "suite désarmée : rien")
	assert_eq(_writes(), 1, "la sauvegarde est écrite quand même")
	assert_true(JsonFields.get_array(_saved(), "flags").has("t16_first_done"))
	assert_false(_boot.get_cutscene_director().is_running())
	assert_true(_boot.get_player().is_input_enabled(), "joueur rendu")


func test_only_one_chain_per_scene_end() -> void:
	await _start()
	assert_true(_boot.get_cutscene_director().play(&"t16_first"))
	await _until_no_scene()
	await wait_process_frames(5)
	assert_eq(_started.size(), 2, "la suite, sans « next », n'enchaîne rien")
	_started.clear()
	assert_true(_boot.get_cutscene_director().play(&"t16_first"), "rejouable")
	await _until_no_scene()
	assert_eq(_started, [&"t16_first"] as Array[StringName], "suite déjà jouée : désarmée")


func test_a_scene_without_next_keeps_the_ordinary_autosave() -> void:
	await _start()
	assert_true(_boot.get_cutscene_library().add_from_dict({
		"t16_plain": {"steps": [{"set": ["t16_plain_done"]}]}}, "test"))
	_fs.journal.clear()
	assert_true(_boot.get_cutscene_director().play(&"t16_plain"))
	await _until_no_scene()
	await wait_process_frames(3)
	assert_eq(_started, [&"t16_plain"] as Array[StringName])
	assert_eq(_writes(), 1, "autosave de fin de scène, à la première image stable")


# --- Grand moment du rival (§2.8) ------------------------------------------------------------

func _rival_moments(trainer_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(GameState.MOMENT_RIVAL_BATTLE) \
				and (moment.get("details", {}) as Dictionary).get("trainer") == trainer_id:
			found.append(moment)
	return found


func test_rival_three_records_one_moment_at_the_win_only() -> void:
	await _start()
	GameState.moments.clear()
	var battles := _boot.get_battle_director()
	battles.battle_finished.emit(&"rival_cerulean", Battle.Outcome.LOSS)
	battles.battle_finished.emit(&"rival_cerulean", Battle.Outcome.LOSS)
	assert_eq(_rival_moments("rival_cerulean").size(), 0, "défaites : aucun moment")
	battles.battle_finished.emit(&"rival_cerulean", Battle.Outcome.WIN)
	battles.battle_finished.emit(&"rival_cerulean", Battle.Outcome.WIN)
	var moments := _rival_moments("rival_cerulean")
	assert_eq(moments.size(), 1, "exactement un moment")
	if moments.size() == 1:
		assert_eq((moments[0]["details"] as Dictionary).get("outcome"), "win")


func test_rivals_one_and_two_keep_one_moment_per_battle_without_duplicates() -> void:
	await _start()
	GameState.moments.clear()
	var battles := _boot.get_battle_director()
	battles.battle_finished.emit(&"rival_lab", Battle.Outcome.LOSS)
	battles.battle_finished.emit(&"rival_route22", Battle.Outcome.WIN)
	assert_eq(_rival_moments("rival_lab").size(), 1, "n° 1 : défaite comptée")
	assert_eq(_rival_moments("rival_route22").size(), 1, "n° 2 : victoire comptée")
	battles.battle_finished.emit(&"rival_route22", Battle.Outcome.LOSS)
	assert_eq(_rival_moments("rival_route22").size(), 1, "jamais deux")
	battles.battle_finished.emit(&"pewter_gym_brock", Battle.Outcome.WIN)
	assert_eq(GameState.moments.size(), 2, "Pierre n'est pas un rival")
