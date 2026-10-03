extends GutTest
## ChoiceCards (jalon 6, T28 ; §6.12, bible UI/UX §4) : deux grandes cartes, un seul `chosen` par
## question, jamais « Oui / Non », zones et marges à 1920 et 2340, texte Grande appliqué,
## apparition instantanée à speed_scale = 0.

const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _chosen: Array[bool] = []
var _vibrations: Array[int] = []


func before_each() -> void:
	_chosen.clear()
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	Haptics.reset()
	UiPrefs.reset()


func _view() -> ChoiceView:
	var view := ChoiceView.new("Oublier Charge ?", "OUBLIER", "GARDER")
	view.detail = "Salamèche ne pourra plus l'utiliser."
	view.confirm_detail = "La capacité est perdue."
	view.cancel_detail = "Il la garde."
	return view


func _cards_in(width: int = 2340) -> ChoiceCards:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var cards := ChoiceCards.new()
	cards.speed_scale = 0.0
	viewport.add_child(cards)
	cards.chosen.connect(func(confirmed: bool) -> void: _chosen.append(confirmed))
	await wait_process_frames(2)
	return cards


func test_hidden_until_shown_and_ignores_touch() -> void:
	var cards := await _cards_in()
	assert_false(cards.visible)
	assert_false(cards.is_showing())
	assert_eq(cards.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_shows_question_and_two_cards_never_yes_no() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	await wait_process_frames(2)
	assert_true(cards.is_showing())
	assert_true(cards.visible)
	assert_eq(cards.modulate.a, 1.0, "instantané à speed_scale = 0")
	var texts := cards.get_texts()
	assert_eq(texts, PackedStringArray(["Oublier Charge ?", "Salamèche ne pourra plus l'utiliser.",
		"GARDER", "Il la garde.", "OUBLIER", "La capacité est perdue."]))
	for text: String in texts:
		assert_false(text.to_upper() == "OUI" or text.to_upper() == "NON", text)
	assert_eq(cards.find_children("*", "Button", true, false).size(), 2, "deux cartes, pas plus")


func test_empty_details_are_absent() -> void:
	var cards := await _cards_in()
	cards.show_choice(ChoiceView.new("Soigner ?", "SOIGNER", "PAS MAINTENANT"))
	assert_eq(cards.get_texts(), PackedStringArray(["Soigner ?", "PAS MAINTENANT", "SOIGNER"]))


func test_confirm_emits_true_once_and_closes() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	cards.get_confirm_button().pressed.emit()
	cards.get_confirm_button().pressed.emit()
	cards.get_cancel_button().pressed.emit()
	assert_eq(_chosen, [true] as Array[bool], "un seul choix émis par question")
	assert_false(cards.is_showing())
	assert_false(cards.visible)
	assert_eq(_vibrations.size(), 1)


func test_cancel_emits_false() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	cards.get_cancel_button().pressed.emit()
	assert_eq(_chosen, [false] as Array[bool])


func test_can_ask_again_after_an_answer() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	cards.get_cancel_button().pressed.emit()
	cards.show_choice(_view())
	cards.get_confirm_button().pressed.emit()
	assert_eq(_chosen, [false, true] as Array[bool])


func test_hide_choice_emits_nothing() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	cards.hide_choice()
	assert_false(cards.is_showing())
	cards.get_confirm_button().pressed.emit()
	assert_true(_chosen.is_empty())


func test_card_is_accent_and_action_is_on_the_right() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	await wait_process_frames(2)
	var confirm_box := cards.get_confirm_button().get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(confirm_box.bg_color, UiTokens.ACCENT)
	assert_gt(cards.get_confirm_button().global_position.x,
		cards.get_cancel_button().global_position.x)


func test_zones_and_safe_margin_at_both_widths() -> void:
	for width: int in WIDTHS:
		var cards := await _cards_in(width)
		cards.show_choice(_view())
		await wait_process_frames(2)
		for button: Button in [cards.get_confirm_button(), cards.get_cancel_button()]:
			var rect := button.get_global_rect()
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN))
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN))
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN), "à %d" % width)
			assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN), "à %d" % width)
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN))
			assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN))
		assert_almost_eq(cards.get_confirm_button().get_global_rect().end.x
			+ cards.get_cancel_button().get_global_rect().position.x, float(width), 2.0,
			"centré à %d" % width)


func test_large_text_is_applied() -> void:
	var cards := await _cards_in()
	cards.show_choice(_view())
	var title := cards.get_title_label()
	var base := title.get_theme_font_size(&"font_size")
	assert_eq(base, UiTokens.CHOICE_TITLE_FONT)
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	UiPrefs.apply(settings)
	cards.show_choice(_view())
	assert_eq(title.get_theme_font_size(&"font_size"), roundi(base * UiTokens.TEXT_SCALE_LARGE))
	UiPrefs.reset()
	cards.show_choice(_view())
	assert_eq(title.get_theme_font_size(&"font_size"), base)


func test_animated_show_reaches_full_opacity() -> void:
	var cards := await _cards_in()
	cards.speed_scale = 1.0
	cards.show_choice(_view())
	assert_lt(cards.modulate.a, 1.0)
	await wait_seconds(UiTokens.CHOICE_FADE + 0.1)
	assert_eq(cards.modulate.a, 1.0)
