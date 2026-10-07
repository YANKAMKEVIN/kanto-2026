extends GutTest
## Menu rapproché des maquettes, MM.3 (docs/tech/menu-maquettes.md) : écran Paramètres présenté
## comme la maquette **sans réglage nouveau** : « ‹ » à la place du ×, bandeau d'état, catégories
## de verre avec icône, section (icône, titre, sous-titre), lignes séparées par un filet,
## sélecteur « ‹ Valeur › », interrupteurs, curseur, action sur toute sa ligne. Chaque réglage
## existant est présent et fonctionne ; rien de hors champ. Vraies vues (SettingsViews).

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080
## Textes de la maquette hors champ (dossier 08 §7 « exclus », plan MM.3).
const OUT_OF_SCOPE: Array[String] = ["difficult", "cloud", "hdr", "langue", "compte",
	"daltonien", "aperçu", "audio", "musique", "caméra", "manette", "voix", "crédits",
	"automatique", "restaurer", "supprimer"]

var _menu: TrainerMenu
var _changes: Array = []
var _saves: int = 0


func before_each() -> void:
	_changes.clear()
	_saves = 0
	Haptics.sink = func(_ms: int) -> void: pass


func after_each() -> void:
	Haptics.reset()
	UiPrefs.reset()


func _screen_in(width: int = 2340, settings: GameSettings = null) -> SettingsScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	_menu.speed_scale = 0.0
	viewport.add_child(_menu)
	_menu.set_zone_name("Route 1")
	var source := settings if settings != null else GameSettings.new()
	_menu.show_settings(SettingsViews.build(source, GameSettings.Graphics.HIGH, true))
	_menu.open_animated()
	await wait_process_frames(3)
	var screen := _menu.get_settings()
	screen.setting_changed.connect(func(key: StringName, value: Variant) -> void:
		_changes.append([key, value]))
	screen.save_now_requested.connect(func() -> void: _saves += 1)
	return screen


func _open(screen: SettingsScreen, id: StringName) -> void:
	screen.get_category_buttons()[id].pressed.emit()
	await wait_process_frames(2)


func test_back_replaces_the_close_button_and_the_status_bar_stays() -> void:
	var screen := await _screen_in()
	assert_true(screen.owns_back)
	assert_false(_menu.get_close_button().visible, "le × est caché")
	var back := screen.get_back_button()
	assert_true(back.is_visible_in_tree())
	assert_eq(back.theme_type_variation, &"MenuRoundButton", "« ‹ » rond compact")
	assert_eq(back.text, "", "icône seule")
	assert_true(_menu.get_status_bar().is_visible_in_tree(), "bandeau d'état (lieu)")
	assert_true(screen.get_texts().has(SettingsScreen.TITLE))
	assert_almost_eq(screen.backdrop_dim, UiTokens.MENU_GLASS_DIM, 0.001, "fond clair, verre")


func test_categories_are_glass_rows_with_icons_in_sentence_case() -> void:
	var screen := await _screen_in()
	var titles: Array[String] = []
	for id: StringName in screen.get_category_buttons():
		var button := screen.get_category_buttons()[id]
		assert_not_null(button.icon, String(id))
		assert_eq(button.theme_type_variation, &"SettingsCategory")
		titles.append(button.text)
	assert_eq(titles, ["Jeu", "Commandes", "Accessibilité", "Graphismes"] as Array[String])
	var panel := screen.get_category_buttons()[SettingsViews.CATEGORY_GAME].get_parent() \
		.get_parent() as PanelContainer
	assert_eq(panel.theme_type_variation, &"MenuGlass")


func test_section_has_icon_title_and_subtitle_of_the_open_category() -> void:
	var screen := await _screen_in()
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		assert_eq(screen.get_panel_title().text, SettingsScreen.display_title(category.title))
		assert_true(screen.get_panel_title().is_visible_in_tree(), "titre de section visible")
		assert_eq(screen.get_panel_subtitle().text, category.subtitle)
		assert_true(screen.get_panel_subtitle().is_visible_in_tree())
		assert_eq(screen.get_section_icon().texture,
			screen.get_category_buttons()[category.id].icon, "icône de la catégorie")


func test_every_existing_setting_is_present_with_its_control() -> void:
	var screen := await _screen_in()
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	var seen: Array[StringName] = []
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		for item: SettingControlView in category.controls:
			var row := screen.get_row(item.key)
			assert_not_null(row, String(item.key))
			match item.kind:
				SettingControlView.Kind.TOGGLE:
					assert_true(row is SettingToggle, String(item.key))
				SettingControlView.Kind.CHOICE:
					assert_true(row is SettingChoice, String(item.key))
				SettingControlView.Kind.SLIDER:
					assert_true(row is SettingSlider, String(item.key))
				SettingControlView.Kind.ACTION:
					assert_same(row, screen.get_action_button(), "toute la ligne")
			assert_true(screen.get_texts().has(item.label), item.label)
			seen.append(item.key)
	for key: StringName in GameSettings.KEYS:
		assert_true(seen.has(key), String(key))
	assert_eq(seen.size(), GameSettings.KEYS.size() + 1, "aucun réglage nouveau")


func test_every_setting_works_from_the_screen() -> void:
	var screen := await _screen_in()
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	var expected: Array = []
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		for item: SettingControlView in category.controls:
			var row := screen.get_row(item.key)
			match item.kind:
				SettingControlView.Kind.TOGGLE:
					(row as SettingToggle).pressed.emit()
					expected.append([item.key, not bool(item.value)])
				SettingControlView.Kind.CHOICE:
					var choice := row as SettingChoice
					var selected := item.selected_option()
					if selected + 1 < item.options.size():
						choice.get_next_button().pressed.emit()
						expected.append([item.key, item.options[selected + 1].value])
					else:
						choice.get_prev_button().pressed.emit()
						expected.append([item.key, item.options[selected - 1].value])
				SettingControlView.Kind.SLIDER:
					var track := (row as SettingSlider).get_track()
					var press := InputEventMouseButton.new()
					press.button_index = MOUSE_BUTTON_LEFT
					press.pressed = true
					press.position = Vector2(UiTokens.SETTINGS_SLIDER_KNOB * 0.5,
						track.size.y * 0.5)
					press.global_position = press.position
					track._gui_input(press)
					var release := press.duplicate() as InputEventMouseButton
					release.pressed = false
					track._gui_input(release)
					expected.append([item.key, item.min_value])
				SettingControlView.Kind.ACTION:
					screen.get_action_button().pressed.emit()
	assert_eq(_saves, 1, "Sauvegarder maintenant")
	assert_eq(_changes.size(), expected.size())
	for i: int in mini(_changes.size(), expected.size()):
		assert_eq(_changes[i][0], expected[i][0])
		if typeof(expected[i][1]) == TYPE_FLOAT:
			assert_almost_eq(float(_changes[i][1]), float(expected[i][1]), 0.0001,
				String(expected[i][0]))
		else:
			assert_eq(_changes[i][1], expected[i][1], String(expected[i][0]))


func test_rows_are_separated_by_a_divider_except_the_last() -> void:
	var screen := await _screen_in()
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		var count := category.controls.size()
		for i: int in count:
			var variation := String(screen.get_row(category.controls[i].key).theme_type_variation)
			assert_eq(variation.ends_with("Last"), i == count - 1,
				"%s : %s" % [category.controls[i].key, variation])


func test_nothing_out_of_scope_even_greyed() -> void:
	var screen := await _screen_in()
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	for category: SettingsCategoryView in view.categories:
		await _open(screen, category.id)
		for text: String in screen.get_texts():
			for word: String in OUT_OF_SCOPE:
				assert_false(text.to_lower().contains(word), "%s (%s)" % [text, word])


func test_touch_targets_and_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width)
		var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, true)
		for category: SettingsCategoryView in view.categories:
			await _open(screen, category.id)
			var scroll_rect := screen.get_scroll().get_global_rect()
			for control: Control in screen.get_touch_controls():
				var rect := control.get_global_rect()
				var label := "%s %s à %d" % [category.id, control.name, width]
				if screen.get_scroll().is_ancestor_of(control):
					assert_true(scroll_rect.has_point(rect.get_center()),
						"tout tient sans défiler à 1080 : " + label)
				assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, label)
				assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN) - 0.5, label)
				assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5, label)
				assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5, label)
				assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5, label)
				assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5, label)


func test_large_text_still_shows_every_value() -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	UiPrefs.apply(settings)
	var screen := await _screen_in(1920, settings)
	await _open(screen, SettingsViews.CATEGORY_GRAPHICS)
	var row := screen.get_row(GameSettings.GRAPHICS) as SettingChoice
	assert_eq(row.get_value_text(), "Auto (Élevée)")
	var row_rect := row.get_global_rect()
	var pill := row.get_selector().get_global_rect()
	assert_true(row_rect.encloses(pill), "le sélecteur tient dans sa ligne : %s / %s" \
		% [pill, row_rect])
	var label := row.find_children("*", "Label", true, false)[0] as Label
	assert_gt(label.size.x, float(UiTokens.SETTINGS_TEXT_MIN_WIDTH) - 0.5,
		"le libellé garde sa place")


func test_a_short_section_does_not_stretch_and_a_long_one_fills_the_height() -> void:
	var screen := await _screen_in()
	var section := screen.get_scroll().get_parent().get_parent() as Control
	await _open(screen, SettingsViews.CATEGORY_GRAPHICS)
	await wait_process_frames(2)
	var body := section.get_parent() as Control
	assert_lt(section.size.y, body.size.y * 0.5, "Graphismes : une ligne, section courte")
	var scroll := screen.get_scroll()
	assert_almost_eq(scroll.size.y, scroll.get_child(0).get_combined_minimum_size().y, 1.0,
		"la liste entière, sans vide dessous")
	await _open(screen, SettingsViews.CATEGORY_CONTROLS)
	await wait_process_frames(2)
	assert_gt(section.size.y, body.size.y * 0.8, "Commandes : presque toute la hauteur")
	assert_lte(section.size.y, body.size.y + 0.5, "jamais plus haute que le corps")
