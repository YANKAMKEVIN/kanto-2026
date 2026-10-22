extends GutTest
## SettingsViews (dossier 08 §7, jalon-06.md §6.12) : catégories sans AUDIO, chaque réglage a
## un contrôle, valeurs écrites en texte, « Sauvegarder maintenant » inactif sans écriture.


func _build(settings: GameSettings = null, can_save: bool = true) -> SettingsView:
	return SettingsViews.build(settings if settings != null else GameSettings.new(),
		GameSettings.Graphics.HIGH, can_save)


func test_categories_in_order_without_audio() -> void:
	var ids: Array[StringName] = []
	var titles: Array[String] = []
	for category: SettingsCategoryView in _build().categories:
		ids.append(category.id)
		titles.append(category.title)
		assert_false(category.controls.is_empty(), String(category.id))
	assert_eq(ids, [SettingsViews.CATEGORY_GAME, SettingsViews.CATEGORY_CONTROLS,
		SettingsViews.CATEGORY_ACCESSIBILITY, SettingsViews.CATEGORY_GRAPHICS] as Array[StringName])
	assert_false(titles.has("AUDIO"), "Q-17")


func test_every_setting_has_exactly_one_control() -> void:
	var view := _build()
	var keys: Array[StringName] = []
	for category: SettingsCategoryView in view.categories:
		for item: SettingControlView in category.controls:
			assert_false(keys.has(item.key), "doublon " + String(item.key))
			keys.append(item.key)
	for key: StringName in GameSettings.KEYS:
		assert_true(keys.has(key), String(key))
	assert_true(keys.has(SettingsViews.SAVE_NOW))
	assert_eq(keys.size(), GameSettings.KEYS.size() + 1, "aucune option en plus")


func test_every_control_writes_its_value() -> void:
	for category: SettingsCategoryView in _build().categories:
		for item: SettingControlView in category.controls:
			assert_ne(item.label, "", String(item.key))
			if item.kind != SettingControlView.Kind.ACTION:
				assert_ne(item.value_text, "", String(item.key) + " : valeur en texte")


func test_toggle_texts() -> void:
	var settings := GameSettings.new()
	settings.left_handed = true
	var view := _build(settings)
	assert_eq(view.control(GameSettings.LEFT_HANDED).value_text, SettingsViews.ON_TEXT)
	assert_eq(view.control(GameSettings.LEFT_HANDED).value, true)
	assert_eq(view.control(GameSettings.HIGH_CONTRAST).value_text, SettingsViews.OFF_TEXT)


func test_choice_values_are_setting_values() -> void:
	var settings := GameSettings.new()
	settings.joystick_scale = 1.2
	var view := _build(settings)
	var joystick := view.control(GameSettings.JOYSTICK_SCALE)
	assert_eq(joystick.kind, SettingControlView.Kind.CHOICE)
	assert_eq(joystick.options.size(), 3)
	assert_eq(joystick.selected_option(), 2)
	assert_eq(joystick.value_text, "Grande")
	# Chaque option se renvoie telle quelle à GameSettings.set_value.
	for category: SettingsCategoryView in view.categories:
		for item: SettingControlView in category.controls:
			for option: SettingOptionView in item.options:
				assert_true(GameSettings.is_valid(item.key, option.value),
					"%s = %s" % [item.key, option.value])
	var speed := view.control(GameSettings.TEXT_SPEED)
	assert_eq(speed.options.size(), 4)
	assert_eq(speed.value_text, "Normale")


func test_opacity_slider() -> void:
	var settings := GameSettings.new()
	settings.joystick_opacity = 0.7
	var slider := _build(settings).control(GameSettings.JOYSTICK_OPACITY)
	assert_eq(slider.kind, SettingControlView.Kind.SLIDER)
	assert_eq(slider.min_value, 0.3)
	assert_eq(slider.max_value, 1.0)
	assert_eq(slider.step, 0.1)
	assert_eq(slider.value_text, "70 %")
	for i: int in 8:
		assert_true(GameSettings.is_valid(GameSettings.JOYSTICK_OPACITY,
			slider.min_value + i * slider.step), "cran %d" % i)


func test_graphics_auto_names_the_device_profile() -> void:
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.ECO, true)
	assert_eq(view.control(GameSettings.GRAPHICS).value_text, "Auto (Économie)")
	assert_eq(_build().control(GameSettings.GRAPHICS).value_text, "Auto (Élevée)")
	var settings := GameSettings.new()
	settings.graphics = GameSettings.Graphics.ECO
	assert_eq(_build(settings).control(GameSettings.GRAPHICS).value_text, "Économie")
	assert_eq(_build().control(GameSettings.GRAPHICS).options.size(), 3, "Q-17 : trois choix")


func test_save_now_enabled_or_explained() -> void:
	var save := _build().control(SettingsViews.SAVE_NOW)
	assert_eq(save.kind, SettingControlView.Kind.ACTION)
	assert_true(save.enabled)
	var disabled := _build(null, false).control(SettingsViews.SAVE_NOW)
	assert_false(disabled.enabled)
	assert_eq(disabled.detail, SettingsViews.SAVE_DISABLED_TEXT)
	var game := _build().category(SettingsViews.CATEGORY_GAME)
	assert_eq((game.controls.back() as SettingControlView).key, SettingsViews.SAVE_NOW,
		"dans JEU (dossier 08 §7)")


func test_save_result_text() -> void:
	assert_eq(SettingsViews.save_result_text(OK, {"hour": 14, "minute": 5}),
		"Partie sauvegardée — 14 h 05")
	assert_eq(SettingsViews.save_result_text(OK, {}), SettingsViews.SAVE_DONE_TEXT)
	assert_eq(SettingsViews.save_result_text(ERR_FILE_CANT_WRITE, {"hour": 1, "minute": 2}),
		SettingsViews.SAVE_FAILED_TEXT)


func test_every_category_has_a_section_subtitle() -> void:
	var subtitles: Array[String] = []
	for category: SettingsCategoryView in _build().categories:
		assert_ne(category.subtitle, "", String(category.id))
		assert_false(subtitles.has(category.subtitle), "un sous-titre par section")
		subtitles.append(category.subtitle)
	assert_eq(_build().category(SettingsViews.CATEGORY_CONTROLS).subtitle,
		SettingsViews.SUBTITLE_CONTROLS)


## OUV.1 (dossier 13 §5.3) : depuis l'écran titre, les mêmes catégories et réglages, sans
## « Sauvegarder maintenant » (absent, pas seulement inactif).
func test_without_save_now_for_the_title() -> void:
	var view := SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH, false, false)
	var keys: Array[StringName] = []
	for category: SettingsCategoryView in view.categories:
		for item: SettingControlView in category.controls:
			keys.append(item.key)
	assert_false(keys.has(SettingsViews.SAVE_NOW))
	assert_eq(keys.size(), GameSettings.KEYS.size(), "tous les réglages, rien d'autre")
	assert_eq(view.categories.size(), _build().categories.size(), "mêmes catégories")
	assert_false(view.category(SettingsViews.CATEGORY_GAME).controls.is_empty())


func test_economy_toggle_is_in_graphics_with_its_help_text() -> void:
	var view := _build().control(GameSettings.ECONOMY)
	assert_eq(view.kind, SettingControlView.Kind.TOGGLE)
	assert_eq(view.label, "Économie")
	assert_eq(view.detail, "Coupe la lumière d'ambiance pour plus de fluidité sur les petits téléphones.")
	assert_false(view.value)
