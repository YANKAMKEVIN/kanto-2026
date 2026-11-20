extends GutTest
## WhatsNew (data/opening/whats_new.json) et WhatsNewStore : nouveautés d'une version, montrées
## une fois au premier lancement après une mise à jour ; validation stricte du fichier ; dernière
## version vue gardée à part de la sauvegarde et des réglages.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const STORE_PATH := "user://test_whats_new.json"


func _valid() -> Dictionary:
	return {"version": "1.2.3", "title": "Nouveautés de la {version}",
		"hint": "Touche la carte pour la fermer", "lines": ["Une chose.", "Une autre."]}


func test_the_real_file_loads_and_stays_short() -> void:
	var notes := WhatsNew.new()
	assert_true(notes.load_file(), "\n".join(notes.get_errors()))
	assert_gt(GameVersion.code_of(notes.version), 0, "version au format du projet")
	assert_between(notes.lines.size(), WhatsNew.MIN_LINES, WhatsNew.MAX_LINES)
	assert_true(notes.title_text().contains(notes.version), "le titre nomme la version")
	assert_false(notes.title_text().contains("{"), "aucune marque oubliée")
	assert_false(notes.hint.is_empty())


func test_title_and_lines_from_a_dictionary() -> void:
	var notes := WhatsNew.new()
	assert_false(notes.is_loaded())
	assert_true(notes.add_from_dict(_valid(), "test"))
	assert_eq(notes.title_text(), "Nouveautés de la 1.2.3")
	assert_eq(notes.lines, PackedStringArray(["Une chose.", "Une autre."]))


func test_shown_once_for_the_build_version_with_a_game_to_continue() -> void:
	var notes := WhatsNew.new()
	notes.add_from_dict(_valid(), "test")
	assert_true(notes.should_show("1.2.3", "1.2.2", true), "mise à jour : à montrer")
	assert_true(notes.should_show("1.2.3", "", true), "jamais rien vu, partie en cours")
	assert_false(notes.should_show("1.2.3", "1.2.3", true), "déjà vues")
	assert_false(notes.should_show("1.2.3", "1.2.2", false), "aucune partie : rien de nouveau")
	assert_false(notes.should_show("1.2.4", "1.2.2", true),
		"fichier resté sur une version passée : jamais de lignes périmées")
	assert_false(WhatsNew.new().should_show("1.2.3", "", true), "fichier non chargé")


func test_a_broken_file_is_refused_whole() -> void:
	for broken: Dictionary in [
		{"version": "1.2", "title": "T", "hint": "H", "lines": ["a"]},
		{"version": "1.2.3", "title": "", "hint": "H", "lines": ["a"]},
		{"version": "1.2.3", "title": "T", "hint": "H", "lines": []},
		{"version": "1.2.3", "title": "T", "hint": "H", "lines": ["a", "b", "c", "d", "e", "f"]},
		{"version": "1.2.3", "title": "T", "hint": "H", "lines": ["a", ""]},
		{"version": "1.2.3", "title": "T", "hint": "H", "lines": ["a"], "extra": 1},
	]:
		var notes := WhatsNew.new()
		assert_false(notes.add_from_dict(broken, "test"), str(broken))
		assert_false(notes.is_loaded())
		assert_gt(notes.get_errors().size(), 0)


func test_store_remembers_the_seen_version() -> void:
	var fs := MemoryFs.new()
	var store := WhatsNewStore.new(fs, STORE_PATH)
	assert_eq(store.load_seen(), "", "premier lancement : aucune version vue")
	assert_eq(store.save_seen("0.37.3"), OK)
	assert_eq(WhatsNewStore.new(fs, STORE_PATH).load_seen(), "0.37.3", "relue d'un autre lancement")
	assert_eq(store.save_seen("0.38.0"), OK)
	assert_eq(store.load_seen(), "0.38.0")


func test_store_without_a_readable_file_has_seen_nothing() -> void:
	var fs := MemoryFs.new()
	fs.files[STORE_PATH] = JSON.stringify({"version": WhatsNewStore.VERSION, "seen": 12})
	assert_eq(WhatsNewStore.new(fs, STORE_PATH).load_seen(), "", "champ mal formé")
	fs.fail_writes = true
	assert_ne(WhatsNewStore.new(fs, STORE_PATH).save_seen("0.37.3"), OK, "échec rendu")
