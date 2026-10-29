extends GutTest
## Copie de secours de la sauvegarde (J33 T4, `jalon-33.md` §T4) : `save.json.bak` garde la
## dernière sauvegarde valide ; reprise depuis elle si le principal est illisible ou absent ;
## coupure à chaque étape de l'écriture ; stockage plein. Critère : aucun scénario ne laisse
## zéro sauvegarde valide alors qu'une existait.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const CrashingFs := preload("res://tests/helpers/crashing_file_system.gd")
const PATH := "user://test/save.json"
const BAK := PATH + ".bak"
const CORRUPT := PATH + ".corrupt"
const GARBAGE := "{ pas du json"

var _fs: MemoryFs
var _save: SaveSystem


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


## Texte exact écrit par SaveSystem pour la génération [param n].
func _text(n: int) -> String:
	return JSON.stringify({"generation": n, SaveSystem.VERSION_KEY: SaveSystem.VERSION}, "\t")


func _generation(content: Dictionary) -> int:
	return JsonFields.get_int(content, "generation", -1)


# --- Écriture -------------------------------------------------------------------------------

func test_first_write_has_no_backup_then_each_write_keeps_the_previous_one() -> void:
	assert_eq(_save.write({"generation": 1}), OK)
	assert_false(_fs.exists(BAK), "rien à garder au premier écrit")
	assert_eq(_save.write({"generation": 2}), OK)
	assert_eq(_fs.files[BAK], _text(1))
	assert_eq(_save.write({"generation": 3}), OK)
	assert_eq(_fs.files[BAK], _text(2), "une seule copie : la dernière valide")
	assert_eq(_fs.files[PATH], _text(3))
	assert_false(_fs.exists(PATH + ".tmp"))


func test_rotation_is_a_rename_between_the_temp_check_and_the_final_rename() -> void:
	_save.write({"generation": 1})
	_fs.journal.clear()
	_save.write({"generation": 2})
	assert_eq(_fs.journal, ["write %s.tmp" % PATH, "rename %s -> %s" % [PATH, BAK],
		"rename %s.tmp -> %s" % [PATH, PATH]] as Array[String],
		"aucune copie octet par octet : pas de place disque en plus")


func test_a_fresh_system_checks_the_main_file_before_keeping_it() -> void:
	_fs.files[PATH] = _text(1)
	assert_eq(SaveSystem.new(_fs, PATH).write({"generation": 2}), OK)
	assert_eq(_fs.files[BAK], _text(1))


func test_a_main_file_corrupted_on_disk_never_replaces_the_backup() -> void:
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = _text(1)
	assert_eq(SaveSystem.new(_fs, PATH).write({"generation": 2}), OK)
	assert_eq(_fs.files[BAK], _text(1), "la copie valide reste")
	assert_eq(_fs.files[CORRUPT], GARBAGE, "le principal illisible est mis de côté, pas détruit")
	assert_eq(_fs.files[PATH], _text(2))


func test_failed_rotation_writes_nothing() -> void:
	_save.write({"generation": 1})
	_save.write({"generation": 2})
	_fs.fail_rename_to = BAK
	assert_ne(_save.write({"generation": 3}), OK)
	assert_eq(_fs.files[PATH], _text(2))
	assert_eq(_fs.files[BAK], _text(1))
	assert_false(_fs.exists(PATH + ".tmp"), "temporaire effacé")
	assert_true(_save.last_error.contains("copie de secours"), _save.last_error)


func test_failed_final_rename_still_leaves_the_previous_save_readable() -> void:
	_save.write({"generation": 1})
	_save.write({"generation": 2})
	_fs.fail_rename_to = PATH  # le remplacement final, et la remise en place, échouent
	assert_ne(_save.write({"generation": 3}), OK)
	assert_false(_fs.exists(PATH + ".tmp"))
	_fs.fail_rename_to = ""
	var reader := SaveSystem.new(_fs, PATH)
	assert_eq(_generation(reader.read()), 2, "la génération 2 survit dans la copie de secours")
	assert_true(reader.restored_from_backup)


func test_failed_final_rename_puts_the_main_file_back_when_possible() -> void:
	_save.write({"generation": 1})
	_save.write({"generation": 2})
	var fs := _OnceFailingFs.new()
	fs.files = _fs.files.duplicate()
	fs.fail_once_to = PATH
	var save := SaveSystem.new(fs, PATH)
	assert_ne(save.write({"generation": 3}), OK)
	assert_eq(fs.files[PATH], _text(2), "principal remis en place")


func test_crash_after_each_operation_never_loses_the_last_valid_save() -> void:
	var start: Dictionary[String, String] = {PATH: _text(2), BAK: _text(1)}
	var total := 3  # temporaire, rotation, remplacement
	for crash_at: int in total + 1:
		var fs := CrashingFs.new()
		fs.files = start.duplicate()
		fs.crash_after = crash_at
		SaveSystem.new(fs, PATH).write({"generation": 3})
		var reader := SaveSystem.new(fs, PATH)
		var content := reader.read()
		assert_eq(reader.last_status, OK, "panne après %d opérations : lisible" % crash_at)
		var expected := 3 if crash_at >= total else 2
		assert_eq(_generation(content), expected,
			"panne après %d opérations : la dernière partie complète" % crash_at)
		assert_eq(reader.restored_from_backup, crash_at == 2,
			"entre les deux renommages : reprise depuis la copie")


func test_crash_during_the_first_ever_write_leaves_no_save_and_no_garbage_read() -> void:
	for crash_at: int in 3:
		var fs := CrashingFs.new()
		fs.crash_after = crash_at
		SaveSystem.new(fs, PATH).write({"generation": 1})
		var reader := SaveSystem.new(fs, PATH)
		var content := reader.read()
		assert_true(reader.last_status == OK or reader.last_status == ERR_FILE_NOT_FOUND,
			"panne %d : %s" % [crash_at, reader.last_error])
		if reader.last_status == OK:
			assert_eq(_generation(content), 1)


func test_backup_is_off_for_other_files() -> void:
	_save.keep_backup = false
	_save.write({"generation": 1})
	_fs.journal.clear()
	_save.write({"generation": 2})
	assert_false(_fs.exists(BAK))
	assert_eq(_fs.journal, ["write %s.tmp" % PATH, "rename %s.tmp -> %s" % [PATH, PATH]]
		as Array[String])


func test_settings_store_keeps_no_backup() -> void:
	var store := SettingsStore.new(_fs, "user://test/settings.json")
	store.save_settings(GameSettings.new())
	store.save_settings(GameSettings.new())
	assert_false(_fs.exists("user://test/settings.json.bak"))


# --- Lecture --------------------------------------------------------------------------------

func test_corrupt_main_is_quarantined_and_the_backup_is_loaded() -> void:
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = _text(1)
	var content := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(_generation(content), 1)
	assert_true(_save.restored_from_backup)
	assert_eq(_save.loaded_path, BAK)
	assert_eq(_fs.files[CORRUPT], GARBAGE, "mis de côté, jamais détruit")
	assert_eq(_fs.files[BAK], _text(1), "copie intacte")
	assert_false(_fs.exists(PATH))


func test_after_a_restore_the_next_write_keeps_the_backup_until_a_valid_main_exists() -> void:
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = _text(1)
	_save.read()
	assert_eq(_save.write({"generation": 2}), OK)
	assert_eq(_fs.files[BAK], _text(1), "pas de principal à garder : la copie reste")
	assert_eq(_save.write({"generation": 3}), OK)
	assert_eq(_fs.files[BAK], _text(2))
	assert_eq(_fs.files[CORRUPT], GARBAGE)


func test_missing_main_with_a_backup_is_restored() -> void:
	_fs.files[BAK] = _text(1)
	assert_true(_save.has_save(), "Continuer est proposé")
	assert_eq(_generation(_save.read()), 1)
	assert_true(_save.restored_from_backup)


func test_a_valid_main_is_read_without_the_backup() -> void:
	_fs.files[PATH] = _text(2)
	_fs.files[BAK] = _text(1)
	assert_eq(_generation(_save.read()), 2)
	assert_false(_save.restored_from_backup)
	assert_eq(_save.loaded_path, PATH)


func test_both_corrupt_is_corrupt_and_destroys_nothing() -> void:
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = "{}"
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_CORRUPT)
	assert_false(_save.restored_from_backup)
	assert_eq(_fs.files[CORRUPT], GARBAGE)
	assert_eq(_fs.files[BAK], "{}", "copie illisible laissée en place")
	assert_true(_save.last_error.contains("copie de secours illisible"), _save.last_error)


func test_newer_main_is_refused_without_falling_back_on_the_backup() -> void:
	var newer := "{\"version\": %d}" % (SaveSystem.VERSION + 1)
	_fs.files[PATH] = newer
	_fs.files[BAK] = _text(1)
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[PATH], newer, "laissé intact")
	assert_eq(_fs.files[BAK], _text(1))
	assert_false(_save.restored_from_backup)


func test_newer_backup_behind_a_corrupt_main_is_refused_and_left_untouched() -> void:
	var newer := "{\"version\": %d}" % (SaveSystem.VERSION + 1)
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = newer
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[BAK], newer)
	assert_eq(_fs.files[CORRUPT], GARBAGE)


func test_an_older_backup_is_migrated() -> void:
	_fs.files[PATH] = GARBAGE
	_fs.files[BAK] = "{\"version\": 7, \"generation\": 1}"
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	assert_eq(_save.read_version, 7)
	assert_eq(int(content[SaveSystem.VERSION_KEY]), SaveSystem.VERSION)


func test_erase_removes_the_backup_too() -> void:
	_save.write({"generation": 1})
	_save.write({"generation": 2})
	assert_eq(_save.erase(), OK)
	assert_false(_save.has_save())
	assert_false(_fs.exists(BAK))


# --- Stockage plein -------------------------------------------------------------------------

func test_full_storage_refuses_the_write_and_touches_nothing() -> void:
	_save.write({"generation": 1})
	_save.write({"generation": 2})
	_fs.space_left_bytes = 10
	assert_eq(_save.write({"generation": 3}), SaveSystem.STORAGE_FULL)
	assert_eq(_save.last_status, SaveSystem.STORAGE_FULL)
	assert_true(_save.last_error.contains("stockage plein"), _save.last_error)
	assert_eq(_fs.files[PATH], _text(2))
	assert_eq(_fs.files[BAK], _text(1))
	assert_false(_fs.exists(PATH + ".tmp"))
	_fs.space_left_bytes = -1
	assert_eq(_save.write({"generation": 3}), OK, "place libérée : l'écriture reprend")


func test_a_write_failure_with_room_left_is_not_reported_as_full() -> void:
	_fs.fail_writes = true
	_fs.space_left_bytes = 1 << 30
	assert_eq(_save.write({"generation": 1}), ERR_FILE_CANT_WRITE)
	_fs.space_left_bytes = -1
	assert_eq(_save.write({"generation": 1}), ERR_FILE_CANT_WRITE, "place inconnue")


func test_storage_full_texts() -> void:
	assert_eq(SettingsViews.save_result_text(SaveSystem.STORAGE_FULL, {}),
		"Sauvegarde impossible : espace insuffisant. Libère de la place.")
	assert_eq(SettingsViews.save_result_text(ERR_FILE_CANT_WRITE, {}),
		SettingsViews.SAVE_FAILED_TEXT)


func test_real_file_system_reports_free_space() -> void:
	assert_gt(SaveFileSystem.new().space_left("user://save.json"), 0)


# --- Nouvelle partie (OpeningCommit) --------------------------------------------------------

func test_new_game_over_a_backup_only_save_copies_the_backup_to_previous() -> void:
	_fs.files[BAK] = _text(1)
	var commit := OpeningCommit.new(_fs, PATH, "user://test/save.previous.json")
	var built := func() -> Dictionary: return {"generation": 9}
	assert_eq(commit.run(built), OpeningCommit.Result.OK)
	assert_eq(_fs.files["user://test/save.previous.json"], _text(1),
		"la partie que Continuer aurait reprise est gardée")


## Système de fichiers dont un seul renommage vers [member fail_once_to] échoue.
class _OnceFailingFs:
	extends "res://tests/helpers/memory_file_system.gd"
	var fail_once_to: String = ""

	func rename(from: String, to: String) -> Error:
		if to == fail_once_to:
			fail_once_to = ""
			journal.append("rename %s -> %s" % [from, to])
			return ERR_CANT_OPEN
		return super(from, to)
