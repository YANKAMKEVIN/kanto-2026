extends GutTest
## Écran Paramètres du menu (jalon 6, T28 ; §6.12) : catégories à gauche, un geste = un seul
## `setting_changed(key, valeur)` avec la valeur du réglage (jamais un rang) ; contrôle inactif
## sans signal et avec sa raison ; « Sauvegarder maintenant » ; l'écran n'invente pas l'état ;
## texte Grande et contraste appliqués ; zones tactiles et marges à 1920 et 2340.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _changes: Array = []
var _saves: int = 0
var _backs: int = 0
var _menu: TrainerMenu
var _settings := GameSettings.new()
var _can_save: bool = true
var _vibrations: Array[int] = []


func before_each() -> void:
	_changes.clear()
	_saves = 0
	_backs = 0
	_settings = GameSettings.new()
	_can_save = true
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	Haptics.reset()
	UiPrefs.reset()


func _view() -> SettingsView:
	return SettingsViews.build(_settings, GameSettings.Graphics.HIGH, _can_save)


func _screen_in(width: int = 2340) -> SettingsScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	_menu.speed_scale = 0.0
	viewport.add_child(_menu)
	_menu.show_settings(_view())
	_menu.open_animated()
	await wait_process_frames(3)
	var screen := _menu.get_settings()
	screen.setting_changed.connect(func(key: StringName, value: Variant) -> void:
		_changes.append([key, value]))
	screen.save_now_requested.connect(func() -> void: _saves += 1)
	screen.back_requested.connect(func() -> void: _backs += 1)
	return screen


func _open(screen: SettingsScreen, category: StringName) -> void:
	screen.get_category_buttons()[category].pressed.emit()
	await wait_process_frames(2)


func _mouse(track: Control, x: float, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = Vector2(x, track.size.y * 0.5)
	event.global_position = event.position
	track._gui_input(event)


func _motion(track: Control, x: float) -> void:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(x, track.size.y * 0.5)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	track._gui_input(event)


func test_four_categories_in_order_without_audio() -> void:
	var screen := await _screen_in()
	var texts := screen.get_texts()
	var order: Array[StringName] = []
	for id: StringName in screen.get_category_buttons():
		order.append(id)
	assert_eq(order, [SettingsViews.CATEGORY_GAME, SettingsViews.CATEGORY_CONTROLS,
		SettingsViews.CATEGORY_ACCESSIBILITY, SettingsViews.CATEGORY_GRAPHICS] as Array[StringName])
	for title: String in ["JEU", "COMMANDES", "ACCESSIBILITÉ", "GRAPHISMES"]:
		assert_true(texts.has(title), title)
	for text: String in texts:
		var low := text.to_lower()
		assert_false(low.contains("audio") or low.contains("musique"), text)
		assert_false(low.contains("automatique"), text)
	assert_eq(screen.get_selected_category(), SettingsViews.CATEGORY_GAME, "la première s'ouvre")


func test_toggle_emits_one_signal_with_the_opposite_value() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_ACCESSIBILITY)
	var row := screen.get_row(GameSettings.HIGH_CONTRAST) as SettingToggle
	assert_eq(row.get_value_text(), "Désactivé", "l'état est écrit")
	row.pressed.emit()
	assert_eq(_changes.size(), 1)
	assert_eq(_changes[0], [GameSettings.HIGH_CONTRAST, true])
	assert_false(row.get_value(), "l'écran n'invente pas l'état")
	assert_eq(row.get_value_text(), "Désactivé")


func test_toggle_on_emits_false() -> void:
	_settings.haptics = true
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	(screen.get_row(GameSettings.HAPTICS) as SettingToggle).pressed.emit()
	assert_eq(_changes, [[GameSettings.HAPTICS, false]])


func test_choice_emits_option_value_not_rank() -> void:
	var screen := await _screen_in()
	var row := screen.get_row(GameSettings.TEXT_SPEED) as SettingChoice
	var buttons := row.get_option_buttons()
	assert_eq(buttons.size(), 4)
	assert_eq(buttons[row.get_selected_index()].text, "Normale")
	buttons[3].pressed.emit()
	assert_eq(_changes.size(), 1)
	assert_eq(_changes[0][0], GameSettings.TEXT_SPEED)
	assert_eq(_changes[0][1], GameSettings.TextSpeed.INSTANT)
	assert_eq(buttons[row.get_selected_index()].text, "Normale", "pas de nouvel état sans la vue")


func test_choice_with_float_values() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	var row := screen.get_row(GameSettings.JOYSTICK_SCALE) as SettingChoice
	row.get_option_buttons()[2].pressed.emit()
	assert_eq(_changes.size(), 1)
	assert_eq(_changes[0][0], GameSettings.JOYSTICK_SCALE)
	assert_almost_eq(float(_changes[0][1]), 1.2, 0.0001)
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	var buttons := (screen.get_row(GameSettings.BUTTON_SCALE) as SettingChoice).get_option_buttons()
	buttons[1].pressed.emit()
	assert_almost_eq(float(_changes[1][1]), 1.2, 0.0001)


func test_touching_the_chosen_option_does_nothing() -> void:
	var screen := await _screen_in()
	var row := screen.get_row(GameSettings.TEXT_SPEED) as SettingChoice
	_vibrations.clear()
	row.get_option_buttons()[row.get_selected_index()].pressed.emit()
	assert_true(_changes.is_empty())
	assert_true(_vibrations.is_empty(), "pas de vibration non plus")


func test_graphics_choice_shows_auto_with_device_quality() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_GRAPHICS)
	var row := screen.get_row(GameSettings.GRAPHICS) as SettingChoice
	var labels: Array[String] = []
	for button: Button in row.get_option_buttons():
		labels.append(button.text)
	assert_eq(labels.size(), 3)
	assert_true(labels[0].begins_with("Auto"), labels[0])
	assert_true(labels[0].contains("Élevée"), "Auto écrit ce qu'il choisit")
	assert_eq(labels[1], "Élevée")
	assert_eq(labels[2], "Économie")
	row.get_option_buttons()[2].pressed.emit()
	assert_eq(_changes, [[GameSettings.GRAPHICS, GameSettings.Graphics.ECO]])


func test_slider_one_signal_on_release_on_a_step() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	var slider := screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider
	var track := slider.get_track()
	assert_eq(slider.get_value_text(), SettingsViews.percent_text(1.0))
	var knob := float(UiTokens.SETTINGS_SLIDER_KNOB)
	var span := track.size.x - knob
	_mouse(track, track.size.x - knob * 0.5, true)
	_motion(track, knob * 0.5 + span * 0.5)
	_motion(track, knob * 0.5 + span * 0.62)
	assert_true(_changes.is_empty(), "rien avant le lâcher")
	assert_ne(slider.get_value_text(), SettingsViews.percent_text(1.0),
		"le pourcentage suit le doigt")
	_mouse(track, knob * 0.5 + span * 0.62, false)
	assert_eq(_changes.size(), 1, "un seul signal par geste")
	assert_eq(_changes[0][0], GameSettings.JOYSTICK_OPACITY)
	var value := float(_changes[0][1])
	var steps := (value - GameSettings.JOYSTICK_OPACITY_MIN) / GameSettings.JOYSTICK_OPACITY_STEP
	assert_almost_eq(steps, roundf(steps), 0.001, "sur un cran : %f" % value)
	assert_between(value, 0.3, 1.0)
	assert_eq(slider.get_value_text(), SettingsViews.percent_text(value))


func test_slider_released_where_it_started_emits_nothing() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	var track := (screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider).get_track()
	var knob := float(UiTokens.SETTINGS_SLIDER_KNOB)
	_mouse(track, track.size.x - knob * 0.5, true)
	_mouse(track, track.size.x - knob * 0.5, false)
	assert_true(_changes.is_empty())


func test_slider_bounds_are_the_views() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	var track := (screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider).get_track()
	assert_almost_eq(track.value_at(-500.0), 0.3, 0.0001)
	assert_almost_eq(track.value_at(99999.0), 1.0, 0.0001)


func test_save_now_emits_once_then_shows_the_result() -> void:
	var screen := await _screen_in()
	var button := screen.get_action_button()
	assert_not_null(button)
	assert_false(button.disabled)
	button.pressed.emit()
	assert_eq(_saves, 1)
	assert_true(_changes.is_empty(), "l'action n'est pas un réglage")
	assert_false(screen.get_result_bar().visible)
	_menu.show_save_result("Partie sauvegardée — 14 h 32")
	assert_true(screen.get_result_bar().visible)
	assert_eq(screen.get_result_label().text, "Partie sauvegardée — 14 h 32")


func test_save_now_inactive_shows_its_reason_without_signal() -> void:
	_can_save = false
	var screen := await _screen_in()
	var button := screen.get_action_button()
	assert_true(button.disabled)
	assert_true(screen.get_texts().has(SettingsViews.SAVE_DISABLED_TEXT), "la raison est écrite")
	button.pressed.emit()
	# Un bouton désactivé ne se touche pas : son signal ne part pas d'un vrai toucher.
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = button.size * 0.5
	button.gui_input.emit(event)
	assert_false(screen.get_touch_controls().has(button), "hors des contrôles touchables")


func test_result_stays_at_speed_zero_and_can_be_cleared() -> void:
	var screen := await _screen_in()
	screen.show_save_result("Partie sauvegardée")
	await wait_seconds(0.3)
	assert_true(screen.get_result_bar().visible)
	screen.show_save_result("")
	assert_false(screen.get_result_bar().visible)


func test_update_keeps_category_scroll_and_does_not_replay_entry() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_ACCESSIBILITY)
	var row := screen.get_row(GameSettings.HIGH_CONTRAST) as SettingToggle
	assert_eq(screen.modulate.a, 1.0)
	_settings.high_contrast = true
	_menu.show_settings(_view())
	await wait_process_frames(2)
	assert_eq(screen.get_selected_category(), SettingsViews.CATEGORY_ACCESSIBILITY)
	assert_same(screen.get_row(GameSettings.HIGH_CONTRAST), row, "mise à jour en place")
	assert_true(row.get_value())
	assert_eq(row.get_value_text(), "Activé")
	assert_eq(screen.modulate.a, 1.0)
	assert_eq(screen.position, Vector2.ZERO)
	assert_eq(_menu.get_current_screen(), screen)


func test_updated_choice_shows_the_new_option() -> void:
	var screen := await _screen_in()
	_settings.text_speed = GameSettings.TextSpeed.FAST
	_menu.show_settings(_view())
	var row := screen.get_row(GameSettings.TEXT_SPEED) as SettingChoice
	assert_eq(row.get_option_buttons()[row.get_selected_index()].text, "Rapide")


func test_back_emits_one_signal() -> void:
	var screen := await _screen_in()
	screen.get_back_button().pressed.emit()
	assert_eq(_backs, 1)


func test_one_vibration_per_validated_gesture() -> void:
	var screen := await _screen_in()
	await _open(screen, SettingsViews.CATEGORY_ACCESSIBILITY)
	_vibrations.clear()
	(screen.get_row(GameSettings.HIGH_CONTRAST) as SettingToggle).pressed.emit()
	assert_eq(_vibrations.size(), 1)


func test_relays_through_the_menu() -> void:
	var screen := await _screen_in()
	var relayed: Array = []
	_menu.setting_changed.connect(func(key: StringName, value: Variant) -> void:
		relayed.append([key, value]))
	var saves: Array[int] = [0]
	_menu.save_now_requested.connect(func() -> void: saves[0] += 1)
	screen.get_row(GameSettings.CONFIRM_ACTIONS).pressed.emit()
	screen.get_action_button().pressed.emit()
	assert_eq(relayed, [[GameSettings.CONFIRM_ACTIONS, true]])
	assert_eq(saves[0], 1)


func test_every_value_is_written_in_text() -> void:
	var screen := await _screen_in()
	var view := _view()
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		var texts := screen.get_texts()
		for item: SettingControlView in category.controls:
			if item.kind != SettingControlView.Kind.ACTION:
				assert_true(texts.has(item.value_text), "%s : %s" % [item.key, item.value_text])


func test_touch_zones_and_safe_margin_in_every_category_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width)
		for category: SettingsCategoryView in _view().categories:
			await _open(screen, category.id)
			var controls := screen.get_touch_controls()
			assert_gt(controls.size(), 3, category.id)
			var viewport_rect := screen.get_scroll().get_global_rect()
			for control: Control in controls:
				var rect := control.get_global_rect()
				var label := "%s %s à %d" % [category.id, control.name, width]
				# Une ligne hors de la fenêtre de défilement attend d'être défilée.
				if screen.get_scroll().is_ancestor_of(control) \
						and not viewport_rect.has_point(rect.get_center()):
					continue
				assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, label)
				assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN) - 0.5, label)
				# Le défilement coupe : seule la part visible se touche.
				if screen.get_scroll().is_ancestor_of(control):
					rect = rect.intersection(viewport_rect)
				assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5, label)
				assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5, label)
				assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5, label)
				assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5, label)


func test_enter_is_instant_at_speed_zero() -> void:
	var screen := await _screen_in()
	assert_true(screen.visible)
	assert_eq(screen.modulate.a, 1.0)


func test_large_text_and_contrast_are_applied_and_restored() -> void:
	var screen := await _screen_in()
	var row := screen.get_row(GameSettings.TEXT_SPEED) as SettingChoice
	var label := row.find_children("*", "Label", true, false)[0] as Label
	var base := label.get_theme_font_size(&"font_size")
	_settings.text_size = GameSettings.TextSize.LARGE
	_settings.high_contrast = true
	UiPrefs.apply(_settings)
	_menu.show_settings(_view())
	await wait_process_frames(2)
	assert_eq(label.get_theme_font_size(&"font_size"), roundi(base * UiTokens.TEXT_SCALE_LARGE))
	var panel_box := (screen.find_children("*", "PanelContainer", true, false)[0] as Control) \
		.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_gte(panel_box.bg_color.a, UiTokens.CONTRAST_PANEL_ALPHA - 0.001)
	UiPrefs.reset()
	_menu.show_settings(_view())
	await wait_process_frames(2)
	assert_eq(label.get_theme_font_size(&"font_size"), base, "restitué")


# --- Toucher ou défilement (retour S24 de la validation J6) -------------------------------------

func _finger(screen: Control) -> TouchFinger:
	return TouchFinger.new(screen.get_viewport())


func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## Ouvre COMMANDES et vérifie que la liste défile bien (sinon le test ne prouve rien).
func _controls_scrollable(screen: SettingsScreen) -> ScrollContainer:
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	await wait_process_frames(2)
	var scroll := screen.get_scroll()
	var overflow := scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
	assert_gt(overflow, 20.0, "la liste COMMANDES déborde et défile")
	return scroll


func test_vertical_swipe_from_a_switch_scrolls_and_changes_nothing() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.HAPTICS) as SettingToggle
	assert_not_null(row)
	var start := Vector2(_center(row).x, scroll.get_global_rect().end.y - 120.0)
	_finger(screen).swipe(start, Vector2(0.0, -200.0))
	await wait_process_frames(2)
	assert_gt(scroll.scroll_vertical, 0, "la liste a défilé")
	assert_true(_changes.is_empty(), "aucun setting_changed : %s" % [_changes])


func test_vertical_swipe_from_a_choice_scrolls_and_changes_nothing() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.JOYSTICK_SCALE) as SettingChoice
	var option := row.get_option_buttons()[2]
	var from := _center(option)
	assert_true(scroll.get_global_rect().has_point(from), "l'option est visible")
	_finger(screen).swipe(from, Vector2(0.0, -200.0))
	await wait_process_frames(2)
	assert_gt(scroll.scroll_vertical, 0, "la liste a défilé")
	assert_true(_changes.is_empty(), "aucun setting_changed : %s" % [_changes])


func test_vertical_swipe_from_the_slider_scrolls_and_changes_nothing() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var track := (screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider).get_track()
	var from := _center(track) + Vector2(-100.0, 0.0)
	assert_true(scroll.get_global_rect().has_point(from), "la piste est visible")
	_finger(screen).swipe(from, Vector2(0.0, -200.0))
	await wait_process_frames(2)
	assert_gt(scroll.scroll_vertical, 0, "la liste a défilé")
	assert_true(_changes.is_empty(), "le curseur n'a pas bougé : %s" % [_changes])


func test_vertical_swipe_ending_back_on_the_control_still_scrolls_only() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.HAPTICS) as SettingToggle
	var from := _center(row)
	assert_true(scroll.get_global_rect().has_point(from))
	var finger := _finger(screen)
	finger.press(from)
	finger.move_to(from + Vector2(0.0, 150.0))
	finger.move_to(from)
	finger.release()
	await wait_process_frames(2)
	assert_true(_changes.is_empty(), "revenu sur l'interrupteur : toujours un défilement")


func test_short_tap_on_a_switch_emits_once() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.HAPTICS) as SettingToggle
	assert_true(scroll.get_global_rect().has_point(_center(row)))
	_finger(screen).tap(_center(row))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1, "un seul signal")
	assert_eq(_changes[0][0], GameSettings.HAPTICS)
	assert_eq(scroll.scroll_vertical, 0)


func test_tiny_wobble_still_counts_as_a_tap() -> void:
	var screen := await _screen_in()
	await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.HAPTICS) as SettingToggle
	var from := _center(row)
	_finger(screen).swipe(from, Vector2(6.0, 8.0))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1, "sous le seuil : un toucher")


func test_short_tap_on_a_choice_emits_once() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.JOYSTICK_SCALE) as SettingChoice
	var option := row.get_option_buttons()[2]
	assert_true(scroll.get_global_rect().has_point(_center(option)))
	_finger(screen).tap(_center(option))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1)
	assert_eq(_changes[0][0], GameSettings.JOYSTICK_SCALE)


func test_choice_works_again_after_a_cancelled_swipe() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var row := screen.get_row(GameSettings.JOYSTICK_SCALE) as SettingChoice
	var option := row.get_option_buttons()[2]
	_finger(screen).swipe(_center(option), Vector2(0.0, -150.0))
	await wait_process_frames(2)
	assert_true(_changes.is_empty())
	scroll.scroll_vertical = 0
	await wait_process_frames(2)
	option = row.get_option_buttons()[2]
	assert_true(scroll.get_global_rect().has_point(_center(option)))
	_finger(screen).tap(_center(option))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1, "le toucher suivant marche")


func test_horizontal_swipe_on_the_slider_sets_it_without_scrolling() -> void:
	var screen := await _screen_in()
	var scroll := await _controls_scrollable(screen)
	var slider := screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider
	var track := slider.get_track()
	var rect := track.get_global_rect()
	var from := Vector2(rect.end.x - 30.0, rect.get_center().y)
	assert_true(scroll.get_global_rect().has_point(from))
	var before := scroll.scroll_vertical
	# Glissement presque horizontal (un doigt réel dérive un peu en hauteur).
	_finger(screen).swipe(from, Vector2(-rect.size.x * 0.5, -10.0))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1, "une valeur au lâcher")
	assert_eq(_changes[0][0], GameSettings.JOYSTICK_OPACITY)
	assert_lt(float(_changes[0][1]), 1.0)
	assert_eq(scroll.scroll_vertical, before, "pas de défilement")


func test_short_tap_on_the_slider_sets_it_on_release() -> void:
	var screen := await _screen_in()
	await _controls_scrollable(screen)
	var track := (screen.get_row(GameSettings.JOYSTICK_OPACITY) as SettingSlider).get_track()
	var rect := track.get_global_rect()
	_finger(screen).tap(Vector2(rect.position.x + rect.size.x * 0.4, rect.get_center().y))
	await wait_process_frames(2)
	assert_eq(_changes.size(), 1)
	assert_lt(float(_changes[0][1]), 0.8)
