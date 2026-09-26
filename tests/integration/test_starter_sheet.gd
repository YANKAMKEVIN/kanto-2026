extends GutTest
## Fiche du starter (StarterSheet, jalon 4A T2) : calque, contenu (nom, pastilles de type,
## phrase en italique), boutons ≥ TOUCH_MIN dans SAFE_MARGIN à 1920 et 2340 de large, un
## toucher = un signal, fermée = invisible et sourde, « interact » sans effet, animations.

const SHEET_SCENE := "res://game/ui/starter/starter_sheet.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0

var _sheet: StarterSheet


func before_each() -> void:
	_sheet = (load(SHEET_SCENE) as PackedScene).instantiate() as StarterSheet
	add_child_autofree(_sheet)


func after_each() -> void:
	Input.action_release(&"interact")


func _charmander() -> StarterSheetView:
	return StarterSheetView.new("Salamèche", [&"fire"] as Array[StringName],
		["Feu"] as Array[String], "Fougueux et courageux.")


func _bulbasaur() -> StarterSheetView:
	return StarterSheetView.new("Bulbizarre", [&"grass", &"poison"] as Array[StringName],
		["Plante", "Poison"] as Array[String], "Calme et tenace.")


func _open_settled(view: StarterSheetView) -> void:
	_sheet.open(view)
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)


## Un toucher sur le téléphone : l'écran tactile, puis la souris émulée depuis le toucher
## (sur Mac, l'inverse : souris, puis toucher émulé). Les deux arrivent à l'interface.
func _tap(position: Vector2) -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = position
		touch.pressed = pressed
		get_viewport().push_input(touch, true)
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = position
		mouse.global_position = position
		mouse.pressed = pressed
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		get_viewport().push_input(mouse, true)
		await wait_process_frames(1)


func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## Rectangle d'un contrôle de la fiche pour un écran de [param width] × 1080 (la fiche est
## ancrée au bord gauche et centrée verticalement).
func _rect_at(control: Control, width: float) -> Rect2:
	var root := _sheet.get_node(^"%Root") as Control
	root.size = Vector2(width, SCREEN_HEIGHT)
	return control.get_global_rect()


func test_is_menu_canvas_layer() -> void:
	assert_eq(_sheet.layer, UiTokens.LAYER_MENU)
	assert_eq(UiTokens.LAYER_MENU, 20)


func test_closed_at_start_invisible() -> void:
	assert_false(_sheet.visible)
	assert_false(_sheet.is_open())


func test_open_shows_name_badge_and_italic_phrase() -> void:
	await _open_settled(_charmander())
	assert_true(_sheet.visible)
	assert_true(_sheet.is_open())
	assert_eq(_sheet.get_name_text(), "SALAMÈCHE")
	var badges := _sheet.get_badges()
	assert_eq(badges.size(), 1)
	assert_eq(badges[0].get_type_text(), "FEU")
	assert_eq(badges[0].get_color(), UiTokens.TYPE_COLORS[&"fire"])
	assert_not_null(badges[0].get_icon(), "icône du type")
	var phrase := _sheet.get_phrase_label()
	assert_eq(phrase.text, "Fougueux et courageux.")
	assert_eq(phrase.get_theme_font_size(&"font_size"), UiTokens.FONT_BODY)
	var italic := phrase.get_theme_font(&"font") as FontVariation
	assert_not_null(italic, "phrase en italique")
	if italic != null:
		assert_gt(italic.variation_transform.y.x, 0.0, "pente de l'italique")
	var name_label := _sheet.get_node(^"%NameLabel") as Label
	assert_eq(name_label.get_theme_font_size(&"font_size"), UiTokens.FONT_TITLE)


func test_two_types_two_badges_with_type_colors() -> void:
	await _open_settled(_bulbasaur())
	var badges := _sheet.get_badges()
	assert_eq(badges.size(), 2)
	assert_eq(badges[0].get_type_text(), "PLANTE")
	assert_eq(badges[0].get_color(), UiTokens.TYPE_COLORS[&"grass"])
	assert_eq(badges[1].get_type_text(), "POISON")
	assert_eq(badges[1].get_color(), UiTokens.TYPE_COLORS[&"poison"])
	assert_ne(badges[0].get_icon(), badges[1].get_icon(), "une icône par type")


func test_each_starter_type_has_color_and_icon() -> void:
	for type_id: StringName in [&"normal", &"grass", &"poison", &"fire", &"water"]:
		assert_true(UiTokens.TYPE_COLORS.has(type_id), String(type_id))
		assert_true(TypeBadge.ICONS.has(type_id), String(type_id))


func test_reopen_replaces_content() -> void:
	await _open_settled(_bulbasaur())
	_sheet.open(_charmander())
	await wait_process_frames(1)
	assert_eq(_sheet.get_name_text(), "SALAMÈCHE")
	assert_eq(_sheet.get_badges().size(), 1)


func test_invalid_view_refused() -> void:
	_sheet.open(StarterSheetView.new("Salamèche", [] as Array[StringName], [] as Array[String],
		"x"))
	assert_push_error("vue invalide")
	assert_false(_sheet.is_open())
	assert_false(_sheet.visible)


func test_card_is_dark_translucent_rounded_panel() -> void:
	var box := _sheet.get_card().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_not_null(box)
	assert_eq(box.bg_color, UiTokens.PANEL_BG)
	assert_lt(box.bg_color.a, 1.0, "translucide")
	assert_eq(box.corner_radius_top_left, UiTokens.RADIUS)
	assert_eq(_sheet.get_card().size.x, float(UiTokens.STARTER_SHEET_WIDTH))


func test_buttons_labels_styles_and_no_focus() -> void:
	assert_eq(_sheet.get_choose_button().text, "CHOISIR")
	assert_eq(_sheet.get_back_button().text, "RETOUR")
	assert_eq(_sheet.get_choose_button().theme_type_variation, &"AccentButton")
	assert_eq(_sheet.get_back_button().theme_type_variation, &"PanelButton")
	for button: Button in [_sheet.get_choose_button(), _sheet.get_back_button()]:
		assert_eq(button.focus_mode, Control.FOCUS_NONE, button.text)


func test_card_left_centered_buttons_touchable_inside_safe_margin() -> void:
	await _open_settled(_bulbasaur())
	for width: float in SCREEN_WIDTHS:
		var card := _rect_at(_sheet.get_card(), width)
		assert_true(card.position.x >= UiTokens.SAFE_MARGIN, "bord gauche (%d)" % width)
		assert_true(card.end.x <= width * 0.4, "fiche à gauche, table visible (%d)" % width)
		assert_almost_eq(card.get_center().y, SCREEN_HEIGHT * 0.5, 1.0, "centrée (%d)" % width)
		for button: Button in [_sheet.get_choose_button(), _sheet.get_back_button()]:
			var rect := _rect_at(button, width)
			assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
				"%s ≥ TOUCH_MIN (%s)" % [button.text, rect.size])
			assert_true(rect.position.x >= UiTokens.SAFE_MARGIN, "%s bord gauche" % button.text)
			assert_true(rect.end.x <= width - UiTokens.SAFE_MARGIN, "%s bord droit" % button.text)
			assert_true(rect.position.y >= UiTokens.SAFE_MARGIN, "%s bord haut" % button.text)
			assert_true(rect.end.y <= SCREEN_HEIGHT - UiTokens.SAFE_MARGIN,
				"%s bord bas (%d)" % [button.text, width])
			assert_true(card.encloses(rect), "%s dans la carte" % button.text)
		var choose := _rect_at(_sheet.get_choose_button(), width)
		var back := _rect_at(_sheet.get_back_button(), width)
		assert_false(choose.intersects(back), "boutons séparés")


func test_touch_on_choose_emits_one_choose_pressed() -> void:
	await _open_settled(_charmander())
	watch_signals(_sheet)
	await _tap(_center(_sheet.get_choose_button()))
	assert_signal_emit_count(_sheet, "choose_pressed", 1)
	assert_signal_not_emitted(_sheet, "back_pressed")


func test_touch_on_back_emits_one_back_pressed() -> void:
	await _open_settled(_charmander())
	watch_signals(_sheet)
	await _tap(_center(_sheet.get_back_button()))
	assert_signal_emit_count(_sheet, "back_pressed", 1)
	assert_signal_not_emitted(_sheet, "choose_pressed")


func test_second_touch_before_close_emits_nothing_more() -> void:
	await _open_settled(_charmander())
	watch_signals(_sheet)
	await _tap(_center(_sheet.get_choose_button()))
	await _tap(_center(_sheet.get_choose_button()))
	await _tap(_center(_sheet.get_back_button()))
	assert_signal_emit_count(_sheet, "choose_pressed", 1)
	assert_signal_not_emitted(_sheet, "back_pressed")


func test_reopened_sheet_answers_again() -> void:
	await _open_settled(_charmander())
	await _tap(_center(_sheet.get_back_button()))
	_sheet.close()
	await wait_for_signal(_sheet.closed, 1.0)
	await _open_settled(_bulbasaur())
	watch_signals(_sheet)
	await _tap(_center(_sheet.get_choose_button()))
	assert_signal_emit_count(_sheet, "choose_pressed", 1)


func test_touch_on_card_background_emits_nothing() -> void:
	await _open_settled(_charmander())
	watch_signals(_sheet)
	await _tap(_sheet.get_card().get_global_rect().position + Vector2.ONE * 10.0)
	assert_signal_not_emitted(_sheet, "choose_pressed")
	assert_signal_not_emitted(_sheet, "back_pressed")


func test_closed_sheet_invisible_and_receives_nothing() -> void:
	await _open_settled(_charmander())
	var choose := _center(_sheet.get_choose_button())
	var back := _center(_sheet.get_back_button())
	_sheet.close()
	assert_false(_sheet.is_open(), "fermée dès l'appel")
	assert_true(await wait_for_signal(_sheet.closed, 1.0))
	assert_false(_sheet.visible)
	watch_signals(_sheet)
	await _tap(choose)
	await _tap(back)
	assert_signal_not_emitted(_sheet, "choose_pressed")
	assert_signal_not_emitted(_sheet, "back_pressed")


func test_touch_during_close_animation_emits_nothing() -> void:
	await _open_settled(_charmander())
	var choose := _center(_sheet.get_choose_button())
	_sheet.close()
	watch_signals(_sheet)
	await _tap(choose)
	assert_signal_not_emitted(_sheet, "choose_pressed")


func test_never_opened_sheet_receives_nothing() -> void:
	watch_signals(_sheet)
	await _tap(Vector2(UiTokens.STARTER_SHEET_LEFT + 100.0, SCREEN_HEIGHT * 0.5))
	assert_signal_not_emitted(_sheet, "choose_pressed")
	assert_signal_not_emitted(_sheet, "back_pressed")


func test_interact_has_no_effect() -> void:
	await _open_settled(_charmander())
	watch_signals(_sheet)
	for keycode: Key in [KEY_E, KEY_SPACE, KEY_ENTER]:
		for pressed: bool in [true, false]:
			var key := InputEventKey.new()
			key.keycode = keycode
			key.physical_keycode = keycode
			key.pressed = pressed
			get_viewport().push_input(key)
	var action := InputEventAction.new()
	action.action = &"interact"
	action.pressed = true
	get_viewport().push_input(action)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_signal_not_emitted(_sheet, "choose_pressed")
	assert_signal_not_emitted(_sheet, "back_pressed")
	assert_true(_sheet.is_open(), "toujours ouverte")


func test_open_slides_in_from_left_with_fade() -> void:
	_sheet.open(_charmander())
	assert_eq(_sheet.offset, Vector2(-UiTokens.PANEL_SLIDE, 0.0), "part décalée à gauche")
	assert_eq(_sheet.get_card().modulate.a, 0.0, "part transparente")
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_eq(_sheet.offset, Vector2.ZERO)
	assert_almost_eq(_sheet.get_card().modulate.a, 1.0, 0.001)


func test_close_slides_out_then_hidden() -> void:
	await _open_settled(_charmander())
	_sheet.close()
	assert_true(_sheet.visible, "pas de disparition sèche")
	await wait_for_signal(_sheet.closed, 1.0)
	assert_false(_sheet.visible)
	assert_eq(_sheet.offset, Vector2(-UiTokens.PANEL_SLIDE, 0.0))


func test_close_when_closed_does_nothing() -> void:
	watch_signals(_sheet)
	_sheet.close()
	await wait_process_frames(2)
	assert_signal_not_emitted(_sheet, "closed")
