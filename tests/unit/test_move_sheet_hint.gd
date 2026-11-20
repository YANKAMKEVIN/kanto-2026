extends GutTest
## MoveSheetHint et HintStore : la consigne « Maintiens une capacité pour voir sa fiche » est due
## aux trois premiers choix de capacité, plus jamais une fois une fiche ouverte ; ce qui a été vu
## est gardé sur l'appareil, à part de la sauvegarde et des drapeaux d'histoire.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const STORE_PATH := "user://test_hints.json"


func test_due_three_times_then_never() -> void:
	var hint := MoveSheetHint.new()
	for i: int in MoveSheetHint.MAX_SHOWN:
		assert_true(hint.is_due(), "affichage %d" % (i + 1))
		hint.record_shown()
	assert_false(hint.is_due(), "montrée trois fois : elle ne revient plus")
	hint.record_shown()
	assert_eq(hint.get_shown(), MoveSheetHint.MAX_SHOWN, "rien de plus")
	assert_eq(MoveSheetHint.MAX_SHOWN, 3)


func test_opening_a_sheet_ends_it_at_once() -> void:
	var hint := MoveSheetHint.new()
	hint.record_shown()
	hint.record_opened()
	assert_false(hint.is_due(), "le joueur connaît le geste")
	assert_true(hint.is_opened())
	assert_eq(hint.get_shown(), 1)


func test_what_was_seen_stays_on_the_device() -> void:
	var fs := MemoryFs.new()
	var hint := MoveSheetHint.new()
	hint.attach(HintStore.new(fs, STORE_PATH))
	assert_true(hint.is_due(), "premier lancement : rien n'a été vu")
	hint.record_shown()
	hint.record_shown()
	var next_launch := MoveSheetHint.new()
	next_launch.attach(HintStore.new(fs, STORE_PATH))
	assert_eq(next_launch.get_shown(), 2, "relu au lancement suivant")
	assert_true(next_launch.is_due())
	next_launch.record_opened()
	var later := MoveSheetHint.new()
	later.attach(HintStore.new(fs, STORE_PATH))
	assert_false(later.is_due(), "fiche ouverte une fois : finie pour de bon")


func test_without_a_store_nothing_is_written() -> void:
	var hint := MoveSheetHint.new()
	hint.attach(null)
	hint.record_shown()
	hint.record_opened()
	assert_false(hint.is_due(), "le compte vit en mémoire")


func test_store_keeps_the_other_hints_and_ignores_bad_fields() -> void:
	var fs := MemoryFs.new()
	var store := HintStore.new(fs, STORE_PATH)
	assert_eq(store.load_hint("a"), {})
	assert_eq(store.save_hint("a", {"shown": 1}), OK)
	assert_eq(store.save_hint("b", {"opened": true}), OK)
	var reread := HintStore.new(fs, STORE_PATH)
	assert_eq(reread.load_hint("a"), {"shown": 1.0}, "les autres consignes sont gardées")
	assert_eq(reread.load_hint("b"), {"opened": true})
	fs.files[STORE_PATH] = JSON.stringify({"version": HintStore.VERSION,
		"move_sheet": {"shown": "trois", "opened": "oui"}})
	var odd := MoveSheetHint.new()
	odd.attach(HintStore.new(fs, STORE_PATH))
	assert_true(odd.is_due(), "champs mal formés : rien n'a été vu")
	assert_eq(odd.get_shown(), 0)


func test_the_text_exists_and_speaks_to_the_player() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var hint := texts.get_template(&"move_sheet_hint")
	assert_false(hint.is_empty())
	assert_true(hint.begins_with("Maintiens"), "tutoiement")
