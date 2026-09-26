extends GutTest
## DialogueSession : silence, texte progressif, avance au toucher, locuteur par page
## (jalon 3 §2.5).


func _pages(texts: Array) -> Array[DialoguePage]:
	var pages: Array[DialoguePage] = []
	for item: Variant in texts:
		pages.append(item if item is DialoguePage else DialoguePage.new(item))
	return pages


func _page(text: String, pause: float = 0.0, speaker: String = "") -> DialoguePage:
	var page := DialoguePage.new(text)
	page.pause = pause
	page.speaker = speaker
	return page


func test_text_is_revealed_at_the_given_speed() -> void:
	var session := DialogueSession.new(_pages(["0123456789"]), "Maman", 20.0)
	assert_eq(session.get_visible_characters(), 0)
	assert_false(session.is_page_complete())
	session.update(0.25)
	assert_eq(session.get_visible_characters(), 5)
	session.update(1.0)
	assert_eq(session.get_visible_characters(), 10, "jamais plus que la page")
	assert_true(session.is_page_complete())


func test_zero_speed_shows_the_page_at_once() -> void:
	var session := DialogueSession.new(_pages(["Bonjour."]), "", 0.0)
	assert_true(session.is_page_complete())
	assert_eq(session.get_visible_characters(), 8)


func test_advance_while_writing_reveals_the_whole_page() -> void:
	var session := DialogueSession.new(_pages(["Bonjour !", "Suite."]), "Maman", 10.0)
	session.update(0.1)
	assert_eq(session.advance(), DialogueSession.Step.REVEALED)
	assert_true(session.is_page_complete())
	assert_eq(session.get_page_index(), 0, "on reste sur la page")


func test_advance_on_a_complete_page_goes_to_the_next_then_finishes() -> void:
	var session := DialogueSession.new(_pages(["Un.", "Deux."]), "Maman", 0.0)
	assert_false(session.is_last_page())
	assert_eq(session.advance(), DialogueSession.Step.NEXT_PAGE)
	assert_eq(session.get_page_index(), 1)
	assert_eq(session.get_text(), "Deux.")
	assert_true(session.is_last_page())
	assert_eq(session.advance(), DialogueSession.Step.FINISHED)
	assert_true(session.is_finished())
	assert_eq(session.advance(), DialogueSession.Step.NONE, "plus rien après la fin")


func test_new_page_starts_empty_when_writing() -> void:
	var session := DialogueSession.new(_pages(["Un.", "Deux."]), "", 30.0)
	session.update(1.0)
	session.advance()
	assert_eq(session.get_visible_characters(), 0)
	assert_false(session.is_page_complete())


func test_pause_delays_the_text() -> void:
	var session := DialogueSession.new(_pages([_page("Moi, je suis prêt.", 0.5)]), "", 10.0)
	assert_true(session.is_pausing())
	session.update(0.4)
	assert_eq(session.get_visible_characters(), 0, "petit silence")
	assert_false(session.is_page_complete())
	session.update(0.2)
	assert_false(session.is_pausing())
	assert_eq(session.get_visible_characters(), 1, "le temps restant écrit déjà")


func test_pause_with_zero_speed_then_whole_page() -> void:
	var session := DialogueSession.new(_pages([_page("Encore.", 0.3)]), "", 0.0)
	assert_false(session.is_page_complete(), "silence d'abord")
	session.update(0.31)
	assert_true(session.is_page_complete())


func test_advance_during_a_pause_skips_it() -> void:
	var session := DialogueSession.new(_pages([_page("Encore.", 1.0)]), "", 10.0)
	assert_eq(session.advance(), DialogueSession.Step.REVEALED)
	assert_false(session.is_pausing())
	assert_true(session.is_page_complete())


func test_speaker_comes_from_the_page_or_the_dialogue() -> void:
	var pages := _pages(["Enfin.", _page("Un peu de patience.", 0.0, "Chen")])
	var session := DialogueSession.new(pages, "Rival", 0.0)
	assert_eq(session.get_speaker(), "Rival")
	session.advance()
	assert_eq(session.get_speaker(), "Chen")


func test_page_exposes_stage_directions() -> void:
	var page := _page("...enfin, presque.")
	page.react = &"leo_rattata"
	var session := DialogueSession.new(_pages(["Regarde !", page]), "Léo", 0.0)
	assert_eq(session.get_page().react, &"")
	session.advance()
	assert_eq(session.get_page().react, &"leo_rattata")


func test_empty_dialogue_is_finished_at_once() -> void:
	var empty: Array[DialoguePage] = []
	var session := DialogueSession.new(empty, "", 10.0)
	assert_true(session.is_finished())
	assert_null(session.get_page())
	assert_eq(session.get_text(), "")
	assert_eq(session.advance(), DialogueSession.Step.NONE)


func test_update_with_no_time_changes_nothing() -> void:
	var session := DialogueSession.new(_pages(["Bonjour."]), "", 10.0)
	session.update(0.0)
	session.update(-1.0)
	assert_eq(session.get_visible_characters(), 0)
