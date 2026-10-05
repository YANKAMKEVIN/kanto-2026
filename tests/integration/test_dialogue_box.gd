extends GutTest
## Boîte de dialogue 2026 (DialogueBox, bible UI/UX §3) : calque, états ouverte / fermée,
## nom du locuteur, écriture du texte, « › », toucher → advance_requested, placement à 1920
## et 2340 de large, narration en italique.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
const MOM_LINE := "Bonjour ! Tu es enfin réveillé ?"

var _box: DialogueBox


func before_each() -> void:
	_box = (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(_box)


func _touch(position: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	get_viewport().push_input(event, true)


func _root() -> Control:
	return _box.get_node(^"%Root") as Control


func _continue() -> Label:
	return _box.get_node(^"%Continue") as Label


func _speaker() -> Label:
	return _box.get_node(^"%Speaker") as Label


func _text() -> Label:
	return _box.get_node(^"%Text") as Label


func test_is_dialog_canvas_layer() -> void:
	assert_eq(_box.layer, UiTokens.LAYER_DIALOG)
	assert_eq(UiTokens.LAYER_DIALOG, 30)


func test_closed_box_is_invisible_and_ignores_mouse() -> void:
	assert_false(_box.visible)
	assert_false(_box.is_open())
	assert_eq(_root().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_open_shows_box_and_stops_mouse() -> void:
	_box.open()
	assert_true(_box.visible)
	assert_true(_box.is_open())
	assert_eq(_root().mouse_filter, Control.MOUSE_FILTER_STOP)


func test_open_slides_up_from_below_without_pop() -> void:
	_box.open()
	assert_eq(_box.offset, Vector2(0.0, UiTokens.DIALOG_SLIDE), "part plus bas")
	assert_eq(_root().modulate.a, 0.0, "part transparente")
	assert_eq(_root().scale, Vector2.ONE, "pas de mise à l'échelle (« pop »)")
	await wait_seconds(UiTokens.DIALOG_OPEN + 0.1)
	assert_eq(_box.offset, Vector2.ZERO)
	assert_almost_eq(_root().modulate.a, 1.0, 0.001)


func test_open_duration_within_bible_range() -> void:
	assert_between(UiTokens.DIALOG_OPEN, 0.15, 0.2, "150–200 ms (bible §3)")


func test_show_page_with_speaker() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	assert_true(_speaker().visible)
	assert_eq(_speaker().text, "Maman")
	assert_eq(_box.get_speaker_text(), "Maman")
	assert_eq(_box.get_text(), MOM_LINE)
	assert_false(_box.is_narration())


func test_speaker_above_text_inside_panel() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	await wait_process_frames(2)
	var panel_rect := _box.get_panel().get_global_rect()
	var speaker_rect := _speaker().get_global_rect()
	var text_rect := _text().get_global_rect()
	assert_true(panel_rect.encloses(speaker_rect), "nom dans le panneau")
	assert_true(speaker_rect.end.y <= text_rect.position.y, "nom au-dessus du texte")
	assert_ne(_speaker().get_theme_color(&"font_color"), _text().get_theme_color(&"font_color"),
		"nom distinct du texte")


func test_empty_speaker_hides_name() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	_box.show_page("", "Ton petit-déjeuner est encore chaud.", true)
	assert_false(_speaker().visible)
	assert_eq(_box.get_speaker_text(), "")


func test_narration_uses_italic_variation() -> void:
	_box.open()
	_box.show_page("", "Ton petit-déjeuner est encore chaud.", true)
	assert_true(_box.is_narration())
	assert_eq(_text().theme_type_variation, &"DialogNarration")
	var font := _text().get_theme_font(&"font") as FontVariation
	assert_not_null(font, "police italique")
	if font != null:
		assert_ne(font.variation_transform, Transform2D.IDENTITY, "pente de l'italique")
	_box.show_page("Maman", MOM_LINE, false)
	assert_eq(_text().theme_type_variation, &"DialogText")


func test_visible_characters() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	assert_eq(_text().visible_characters, 0, "une nouvelle page part vide")
	_box.set_visible_characters(5)
	assert_eq(_text().visible_characters, 5)
	_box.set_visible_characters(-1)
	assert_eq(_text().visible_characters, -1)
	assert_eq(_text().visible_characters_behavior, TextServer.VC_CHARS_AFTER_SHAPING,
		"les mots ne sautent pas de ligne en s'écrivant")


func test_continue_indicator_only_when_asked() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	assert_false(_continue().visible)
	assert_false(_box.is_continue_visible())
	_box.set_continue_visible(true)
	assert_true(_continue().visible)
	assert_eq(_continue().text, "›")
	_box.show_page("Maman", "J'ai laissé quelque chose à manger sur la table.", false)
	assert_false(_continue().visible, "caché à chaque nouvelle page")
	_box.set_continue_visible(true)
	_box.set_continue_visible(false)
	assert_false(_continue().visible)


func test_continue_indicator_blinks() -> void:
	_box.open()
	_box.set_continue_visible(true)
	var lowest := 1.0
	var elapsed := 0.0
	while elapsed < UiTokens.DIALOG_CONTINUE_BLINK * 2.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		lowest = minf(lowest, _continue().modulate.a)
	assert_true(lowest < 0.6, "l'opacité baisse (min %f)" % lowest)
	assert_true(lowest >= UiTokens.DIALOG_CONTINUE_DIM - 0.01, "sans disparaître")


func test_one_touch_gives_one_advance() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	watch_signals(_box)
	_touch(Vector2(300, 200), true)
	assert_signal_emit_count(_box, "advance_requested", 1)
	_touch(Vector2(300, 200), false)
	assert_signal_emit_count(_box, "advance_requested", 1, "le relâchement ne compte pas")


func test_touch_anywhere_advances() -> void:
	_box.open()
	watch_signals(_box)
	_touch(Vector2(1800, 60), true)
	_touch(Vector2(1800, 60), false)
	_touch(Vector2(960, 1000), true)
	_touch(Vector2(960, 1000), false)
	assert_signal_emit_count(_box, "advance_requested", 2)


func test_mouse_click_alone_does_not_advance() -> void:
	# Sur Mac, emulate_touch_from_mouse ajoute un InputEventScreenTouch à chaque clic :
	# compter aussi le clic compterait deux fois.
	_box.open()
	watch_signals(_box)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(500, 500)
	get_viewport().push_input(click, true)
	assert_signal_not_emitted(_box, "advance_requested")


func test_closed_box_ignores_touch() -> void:
	watch_signals(_box)
	_touch(Vector2(300, 200), true)
	_touch(Vector2(300, 200), false)
	assert_signal_not_emitted(_box, "advance_requested")


func test_close_emits_closed_and_hides() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	_box.set_continue_visible(true)
	watch_signals(_box)
	await _box.close()
	assert_signal_emit_count(_box, "closed", 1)
	assert_false(_box.visible)
	assert_false(_box.is_open())
	assert_false(_continue().visible)
	assert_eq(_root().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_no_advance_while_closing() -> void:
	_box.open()
	watch_signals(_box)
	_box.close()
	_touch(Vector2(300, 200), true)
	_touch(Vector2(300, 200), false)
	assert_signal_not_emitted(_box, "advance_requested")
	await wait_for_signal(_box.closed, 1.0)


func test_close_when_closed_returns_without_signal() -> void:
	watch_signals(_box)
	await _box.close()
	assert_signal_not_emitted(_box, "closed")


func test_reopen_during_close_resumes_caller() -> void:
	_box.open()
	await wait_seconds(UiTokens.DIALOG_OPEN + 0.05)
	watch_signals(_box)
	var done := {"closed": false}
	var closer := func() -> void:
		await _box.close()
		done["closed"] = true
	closer.call()
	await wait_process_frames(1)
	_box.open()
	await wait_process_frames(1)
	assert_true(done["closed"], "l'appel de close interrompu rend la main")
	assert_signal_not_emitted(_box, "closed")
	assert_true(_box.is_open())
	assert_true(_box.visible)
	await wait_seconds(UiTokens.DIALOG_OPEN + 0.05)
	assert_eq(_box.offset, Vector2.ZERO)


func test_open_clears_previous_page() -> void:
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	await _box.close()
	_box.open()
	assert_eq(_box.get_text(), "")
	assert_eq(_box.get_speaker_text(), "")


func test_width_and_margins_at_both_screen_widths() -> void:
	for width: float in SCREEN_WIDTHS:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(int(width), int(SCREEN_HEIGHT))
		add_child_autofree(viewport)
		var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
		viewport.add_child(box)
		box.open()
		box.show_page("Maman", MOM_LINE, false)
		await wait_process_frames(2)
		var rect := box.get_panel().get_global_rect()
		assert_eq(rect.size.x, float(UiTokens.DIALOG_BOX_WIDTH), "largeur (%d)" % width)
		assert_true(rect.size.y >= UiTokens.DIALOG_BOX_MIN_HEIGHT, "hauteur min (%d)" % width)
		assert_almost_eq(rect.get_center().x, width * 0.5, 0.5, "centrée (%d)" % width)
		assert_almost_eq(rect.end.y, SCREEN_HEIGHT - UiTokens.DIALOG_BOTTOM_MARGIN, 0.5,
			"marge du bas (%d)" % width)
		assert_true(rect.position.x >= UiTokens.SAFE_MARGIN, "bord gauche (%d)" % width)
		assert_true(rect.end.x <= width - UiTokens.SAFE_MARGIN, "bord droit (%d)" % width)
		assert_true(rect.position.y > SCREEN_HEIGHT * 0.5, "en bas de l'écran (%d)" % width)


func test_three_lines_fit_and_grow_upward() -> void:
	_box.open()
	var long_text := " ".join(PackedStringArray([
		"Quand il commence à observer des Pokémon, il oublie complètement l'heure.",
		"Quand il commence à observer des Pokémon, il oublie complètement l'heure.",
		"Quand il commence à observer des Pokémon, il oublie",
	]))
	_box.show_page("Maya", long_text, false)
	_box.set_visible_characters(-1)
	await wait_process_frames(2)
	assert_eq(_text().get_line_count(), 3)
	assert_eq(_text().get_visible_line_count(), 3, "trois lignes affichées")
	var rect := _box.get_panel().get_global_rect()
	var screen_bottom := _box.get_viewport().get_visible_rect().size.y
	assert_almost_eq(rect.end.y, screen_bottom - UiTokens.DIALOG_BOTTOM_MARGIN, 0.5,
		"le bas reste en place")
	assert_true(rect.encloses(_text().get_global_rect()), "le texte tient dans le panneau")


func test_panel_style_is_dark_translucent_and_rounded() -> void:
	var style := _box.get_panel().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_not_null(style)
	assert_eq(style.bg_color, UiTokens.DIALOG_PANEL_BG)
	assert_true(style.bg_color.a > 0.7 and style.bg_color.a < 1.0, "translucide")
	assert_true(style.bg_color.get_luminance() < 0.2, "sombre")
	assert_eq(style.corner_radius_top_left, UiTokens.DIALOG_RADIUS)
	assert_eq(_text().get_theme_color(&"font_color"), UiTokens.TEXT)
	assert_eq(_text().get_theme_font_size(&"font_size"), UiTokens.FONT_BODY)


func test_no_portrait_in_box() -> void:
	for node: Node in _box.find_children("*", "TextureRect", true, false):
		fail_test("portrait inattendu : %s" % node.name)
	pass_test("aucun portrait")


# --- Taille du texte et contraste (UiPrefs, T28) ----------------------------------------------


func _prefs(large: bool, contrast: bool) -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE if large else GameSettings.TextSize.NORMAL
	settings.high_contrast = contrast
	UiPrefs.apply(settings)


func test_large_text_scales_speaker_and_text_on_every_page() -> void:
	_prefs(true, false)
	_box.open()
	_box.show_page("Maman", MOM_LINE, false)
	assert_eq(_text().get_theme_font_size(&"font_size"),
		roundi(UiTokens.FONT_BODY * UiTokens.TEXT_SCALE_LARGE))
	assert_eq(_speaker().get_theme_font_size(&"font_size"),
		roundi(UiTokens.DIALOG_SPEAKER_FONT * UiTokens.TEXT_SCALE_LARGE))
	_box.show_page("", MOM_LINE, true)
	assert_eq(_text().get_theme_font_size(&"font_size"),
		roundi(UiTokens.FONT_BODY * UiTokens.TEXT_SCALE_LARGE), "narration aussi, sans cumul")
	_prefs(false, false)
	_box.show_page("Maman", MOM_LINE, false)
	assert_eq(_text().get_theme_font_size(&"font_size"), UiTokens.FONT_BODY, "retour à la normale")
	UiPrefs.reset()


func test_high_contrast_keeps_the_panel_at_least_as_opaque() -> void:
	var panel := _box.get_node(^"%Panel") as PanelContainer
	var before := (panel.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color.a
	_prefs(false, true)
	_box.open()
	var after := (panel.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color.a
	assert_gte(after, UiTokens.CONTRAST_PANEL_ALPHA - 0.001)
	assert_gte(after, before)
	UiPrefs.reset()


func test_large_text_box_stays_inside_the_screen() -> void:
	_prefs(true, true)
	_box.open()
	_box.show_page("Maman", MOM_LINE + " " + MOM_LINE + " " + MOM_LINE, false)
	_box.set_visible_characters(-1)
	await wait_process_frames(3)
	var rect := (_box.get_node(^"%Panel") as Control).get_global_rect()
	var screen := (_box.get_node(^"%Panel") as Control).get_viewport_rect()
	assert_lte(rect.end.y, screen.end.y - UiTokens.SAFE_MARGIN + 0.5, "bas dans SAFE_MARGIN")
	assert_gte(rect.position.y, 0.0, "reste dans l'écran")
	assert_lt(rect.size.y, UiTokens.DIALOG_BOX_MIN_HEIGHT + 80.0, "la boîte reste compacte")
	UiPrefs.reset()


# --- Choix à deux cartes (jalon 7, T7) ----------------------------------------------------------


func _nurse_view() -> ChoiceView:
	return ChoiceView.new("Veux-tu soigner tes Pokémon ?", "SOIGNER", "PAS MAINTENANT")


func _open_with_choice() -> void:
	_box.open()
	_box.show_page("Infirmière", "Bienvenue au Centre Pokémon !", false)
	_box.show_choice(_nurse_view())
	_box.get_choice_cards().speed_scale = 0.0
	_box.show_choice(_nurse_view())


func test_show_choice_on_closed_box_is_ignored() -> void:
	_box.show_choice(_nurse_view())
	assert_false(_box.is_choice_showing())
	assert_push_warning_count(1)


func test_show_choice_shows_two_cards_with_question() -> void:
	_open_with_choice()
	assert_true(_box.is_choice_showing())
	var cards := _box.get_choice_cards()
	assert_eq(cards.get_texts(), PackedStringArray(["Veux-tu soigner tes Pokémon ?",
		"PAS MAINTENANT", "SOIGNER"]))
	assert_true(_box.is_open(), "la boîte reste ouverte derrière")


func _tap_card_twice(confirmed: bool) -> void:
	_open_with_choice()
	watch_signals(_box)
	var cards := _box.get_choice_cards()
	var button := cards.get_confirm_button() if confirmed else cards.get_cancel_button()
	button.pressed.emit()
	button.pressed.emit()
	cards.get_confirm_button().pressed.emit()
	cards.get_cancel_button().pressed.emit()
	assert_signal_emit_count(_box, "choice_made", 1)
	assert_signal_emitted_with_parameters(_box, "choice_made", [confirmed])
	assert_false(_box.is_choice_showing())


func test_confirm_card_gives_exactly_one_choice_made() -> void:
	_tap_card_twice(true)


func test_cancel_card_gives_exactly_one_choice_made() -> void:
	_tap_card_twice(false)


func test_choice_suspends_advance_by_touch() -> void:
	_open_with_choice()
	watch_signals(_box)
	_touch(Vector2(300, 200), true)
	_touch(Vector2(300, 200), false)
	assert_signal_not_emitted(_box, "advance_requested")


func test_cancel_choice_emits_false_once() -> void:
	_open_with_choice()
	watch_signals(_box)
	assert_true(_box.cancel_choice())
	assert_signal_emit_count(_box, "choice_made", 1)
	assert_signal_emitted_with_parameters(_box, "choice_made", [false])
	assert_false(_box.is_choice_showing())
	assert_false(_box.cancel_choice(), "rien à annuler ensuite")
	assert_signal_emit_count(_box, "choice_made", 1)


func test_cancel_choice_without_choice_does_nothing() -> void:
	_box.open()
	watch_signals(_box)
	assert_false(_box.cancel_choice())
	assert_signal_not_emitted(_box, "choice_made")


func test_ui_cancel_acts_as_cancel_choice() -> void:
	_open_with_choice()
	watch_signals(_box)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(_box, "choice_made", [false])


func test_hide_choice_is_silent_and_close_hides_choice() -> void:
	_open_with_choice()
	watch_signals(_box)
	_box.hide_choice()
	assert_false(_box.is_choice_showing())
	assert_signal_not_emitted(_box, "choice_made")
	_box.show_choice(_nurse_view())
	await _box.close()
	assert_false(_box.is_choice_showing())
	assert_signal_not_emitted(_box, "choice_made")


func test_touch_advances_again_after_choice() -> void:
	_open_with_choice()
	_box.get_choice_cards().get_cancel_button().pressed.emit()
	watch_signals(_box)
	_touch(Vector2(300, 200), true)
	_touch(Vector2(300, 200), false)
	assert_signal_emit_count(_box, "advance_requested", 1)


func test_cards_inside_safe_margin_and_touch_min_at_both_widths() -> void:
	for width: float in SCREEN_WIDTHS:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(int(width), int(SCREEN_HEIGHT))
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
		viewport.add_child(box)
		box.open()
		box.show_choice(_nurse_view())
		box.get_choice_cards().speed_scale = 0.0
		box.show_choice(_nurse_view())
		await wait_process_frames(2)
		var cards := box.get_choice_cards()
		for button: Button in [cards.get_confirm_button(), cards.get_cancel_button()]:
			var rect := button.get_global_rect()
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "largeur (%d)" % width)
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN), "hauteur (%d)" % width)
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN), "gauche (%d)" % width)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN, "droite (%d)" % width)
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN), "haut (%d)" % width)
			assert_lte(rect.end.y, SCREEN_HEIGHT - UiTokens.SAFE_MARGIN, "bas (%d)" % width)
		var title := cards.get_title_label().get_global_rect()
		assert_gte(title.position.y, float(UiTokens.SAFE_MARGIN), "question dans la marge")
		assert_almost_eq(cards.get_confirm_button().get_global_rect().end.y,
			SCREEN_HEIGHT * 0.5, SCREEN_HEIGHT * 0.3, "contenu centré verticalement (%d)" % width)


func test_cards_follow_large_text_and_contrast() -> void:
	_open_with_choice()
	var title := _box.get_choice_cards().get_title_label()
	var base := title.get_theme_font_size(&"font_size")
	_prefs(true, true)
	_box.show_choice(_nurse_view())
	assert_eq(title.get_theme_font_size(&"font_size"), roundi(base * UiTokens.TEXT_SCALE_LARGE))
	var confirm := _box.get_choice_cards().get_confirm_button()
	var normal := confirm.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_gte(normal.bg_color.a, 0.99, "carte d'action opaque")
	UiPrefs.reset()
