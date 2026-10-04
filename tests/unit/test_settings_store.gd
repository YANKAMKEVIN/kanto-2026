extends GutTest
## SettingsStore (jalon-06.md §3.8, §5.3) : fichier à part, écriture atomique, fichier absent
## ou illisible → défauts (illisible mis de côté), version plus récente laissée intacte.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const PATH := "user://test/settings.json"
const FIXTURE := "res://tests/fixtures/settings/v1_mixed.json"

var _fs: MemoryFs
var _store: SettingsStore


func before_each() -> void:
	_fs = MemoryFs.new()
	_store = SettingsStore.new(_fs, PATH)


func _custom() -> GameSettings:
	var settings := GameSettings.new()
	settings.text_speed = GameSettings.TextSpeed.FAST
	settings.left_handed = true
	settings.joystick_opacity = 0.6
	settings.graphics = GameSettings.Graphics.ECO
	return settings


func test_default_path_is_separate_from_the_save() -> void:
	assert_eq(SettingsStore.DEFAULT_PATH, "user://settings.json")
	assert_ne(SettingsStore.DEFAULT_PATH, SaveSystem.DEFAULT_PATH)
	assert_eq(SettingsStore.new(_fs).get_path(), SettingsStore.DEFAULT_PATH)


func test_missing_file_gives_defaults_without_writing() -> void:
	assert_false(_store.has_file())
	var settings := _store.load_settings()
	assert_true(settings.equals(GameSettings.new()))
	assert_eq(_store.last_status, ERR_FILE_NOT_FOUND)
	assert_eq(_store.last_error, "", "premier lancement : pas une erreur")
	assert_true(_fs.journal.is_empty(), "rien n'est écrit à la lecture")


func test_round_trip_through_the_file() -> void:
	assert_eq(_store.save_settings(_custom()), OK)
	assert_true(_store.has_file())
	var back := SettingsStore.new(_fs, PATH).load_settings()
	assert_true(back.equals(_custom()))
	var parsed: Dictionary = JSON.parse_string(_fs.files[PATH])
	assert_eq(int(parsed["version"]), SettingsStore.VERSION)
	assert_eq(parsed["graphics"], "eco")


func test_write_is_atomic() -> void:
	_store.save_settings(_custom())
	assert_eq(_fs.journal, ["write %s.tmp" % PATH, "rename %s.tmp -> %s" % [PATH, PATH]])
	assert_false(_fs.files.has(PATH + ".tmp"))


func test_cut_write_keeps_previous_file() -> void:
	_store.save_settings(_custom())
	var before: String = _fs.files[PATH]
	_fs.truncate_writes = true
	var other := GameSettings.new()
	other.haptics = false
	assert_ne(_store.save_settings(other), OK)
	assert_eq(_fs.files[PATH], before, "ancien fichier intact")
	assert_false(_fs.files.has(PATH + ".tmp"), "temporaire effacé")
	_fs.truncate_writes = false
	assert_true(_store.load_settings().equals(_custom()))


func test_failed_rename_keeps_previous_file() -> void:
	_store.save_settings(_custom())
	var before: String = _fs.files[PATH]
	_fs.fail_renames = true
	assert_ne(_store.save_settings(GameSettings.new()), OK)
	assert_eq(_fs.files[PATH], before)
	assert_ne(_store.last_error, "")


func test_corrupt_file_gives_defaults_and_is_set_aside() -> void:
	_fs.files[PATH] = "{ pas du json"
	var settings := _store.load_settings()
	assert_true(settings.equals(GameSettings.new()))
	assert_eq(_store.last_status, ERR_FILE_CORRUPT)
	assert_false(_fs.files.has(PATH), "plus à sa place")
	assert_eq(_fs.files.get(PATH + ".corrupt"), "{ pas du json", "mis de côté, jamais détruit")
	# Le changement de réglage suivant écrit un fichier neuf.
	assert_eq(_store.save_settings(_custom()), OK)
	assert_true(_store.load_settings().equals(_custom()))


func test_file_without_version_is_corrupt() -> void:
	_fs.files[PATH] = JSON.stringify(_custom().to_dict())
	assert_true(_store.load_settings().equals(GameSettings.new()))
	assert_eq(_store.last_status, ERR_FILE_CORRUPT)


func test_newer_version_gives_defaults_and_leaves_file() -> void:
	var dict := _custom().to_dict()
	dict["version"] = SettingsStore.VERSION + 1
	var text := JSON.stringify(dict)
	_fs.files[PATH] = text
	assert_true(_store.load_settings().equals(GameSettings.new()))
	assert_eq(_store.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[PATH], text, "laissé tel quel")


func test_fixture_with_unknown_fields() -> void:
	_fs.files[PATH] = FileAccess.get_file_as_string(FIXTURE)
	var settings := _store.load_settings()
	assert_eq(_store.last_status, OK)
	assert_eq(settings.text_speed, GameSettings.TextSpeed.FAST)
	assert_eq(settings.graphics, GameSettings.Graphics.ECO)
	assert_false(settings.high_contrast)
	_store.save_settings(settings)
	var parsed: Dictionary = JSON.parse_string(_fs.files[PATH])
	assert_false(parsed.has("music_volume"), "un champ inconnu ne survit pas à l'écriture")
	assert_false(parsed.has("autosave"))
