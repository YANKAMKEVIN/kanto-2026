extends GutTest
## DebugUnlocks : drapeau de débogage du Pokédex (jalon-06.md §3.2, §4). Jamais sous GUT ni en
## release, jamais un drapeau d'histoire, jamais sauvegardé.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FIXTURES := "res://tests/fixtures/debug_unlocks/"


func test_same_guard_as_debug_start() -> void:
	assert_true(DebugUnlocks.is_allowed(true, true))
	assert_false(DebugUnlocks.is_allowed(false, true), "export release : jamais")
	assert_false(DebugUnlocks.is_allowed(true, false), "GUT, outils : jamais")
	assert_false(DebugUnlocks.is_allowed(false, false))


func test_never_allowed_under_gut() -> void:
	assert_true(OS.is_debug_build())
	var current := get_tree().current_scene
	assert_false(current is Boot)
	assert_false(DebugUnlocks.is_allowed(OS.is_debug_build(), current is Boot))


func test_user_file_path_and_defaults() -> void:
	assert_eq(DebugUnlocks.USER_PATH, "user://debug_unlocks.json")
	assert_eq(DebugUnlocks.KEYS, ["pokedex"] as Array[String],
		"mêmes noms que tools/deploy_s24.sh --debug-unlock")
	var unlocks := DebugUnlocks.new()
	assert_false(unlocks.pokedex)
	assert_eq(unlocks.describe(), "aucun")


func test_valid_fixture() -> void:
	var unlocks := DebugUnlocks.new()
	assert_true(unlocks.load_file(FIXTURES + "pokedex.json"))
	assert_true(unlocks.pokedex)
	assert_eq(unlocks.describe(), "pokedex")
	assert_eq(unlocks.get_errors().size(), 0)


func test_empty_object_unlocks_nothing() -> void:
	var unlocks := DebugUnlocks.new()
	assert_true(unlocks.add_from_dict({}))
	assert_false(unlocks.pokedex)


func test_missing_file() -> void:
	var unlocks := DebugUnlocks.new()
	assert_false(unlocks.load_file(FIXTURES + "absent.json"))
	assert_push_error("fichier introuvable")


func test_broken_json_reports_its_line() -> void:
	var unlocks := DebugUnlocks.new()
	assert_false(unlocks.load_file(FIXTURES + "broken.json"))
	assert_string_contains("\n".join(unlocks.get_errors()), "broken.json, ligne")
	assert_push_error_count(1)
	assert_false(unlocks.pokedex)


func test_strict_keys_and_values_all_or_nothing() -> void:
	var unlocks := DebugUnlocks.new()
	assert_false(unlocks.add_from_dict({"pokedex": true, "storage": true}, "t"))
	assert_false(unlocks.pokedex, "tout ou rien")
	assert_false(unlocks.add_from_dict({"pokedex": "yes"}, "t"))
	assert_false(unlocks.add_from_dict({"pokedex": 1}, "t"))
	assert_false(unlocks.pokedex)
	assert_push_error_count(3)
	assert_string_contains("\n".join(unlocks.get_errors()), "clé inconnue « storage »")


func test_not_an_object() -> void:
	var unlocks := DebugUnlocks.new()
	var path := "user://test_debug_unlocks_list.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[true]")
	file.close()
	assert_false(unlocks.load_file(path))
	assert_push_error("un objet est attendu")
	DirAccess.remove_absolute(path)


func test_apply_sets_the_menu_flag_and_never_the_story_flag() -> void:
	var state: Node = GameStateScript.new()
	state.new_game(1)
	var menu := MenuUnlocks.new(state.flags, state.party)
	var unlocks := DebugUnlocks.new()
	unlocks.add_from_dict({"pokedex": true})
	unlocks.apply(menu)
	assert_true(menu.debug_pokedex)
	assert_true(menu.pokedex_visible())
	assert_false(state.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED))
	var saved: Dictionary = state.to_dict()
	assert_false(JSON.stringify(saved).contains("pokedex_activated"),
		"la sauvegarde d'une session débloquée ne contient pas le drapeau")
	unlocks.apply(null)
	state.free()
