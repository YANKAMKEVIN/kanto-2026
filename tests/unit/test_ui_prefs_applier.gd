extends GutTest
## UiPrefsApplier (jalon 6, T28) : taille Grande ×1,15 et contraste renforcé posés sur un arbre
## de contrôles, réversibles, sans toucher aux surcharges de l'écran ni aux voiles décoratifs.

var _root: Control
var _label: Label
var _muted: Label
var _panel: PanelContainer
var _veil: PanelContainer
var _button: Button


func before_each() -> void:
	UiPrefs.reset()
	_root = Control.new()
	add_child_autofree(_root)
	_label = Label.new()
	_label.theme_type_variation = &"SettingsLabel"
	_root.add_child(_label)
	_muted = Label.new()
	_muted.theme_type_variation = &"SettingsDetail"
	_root.add_child(_muted)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"MenuPanel"
	_root.add_child(_panel)
	_veil = PanelContainer.new()
	_veil.theme_type_variation = &"SettingsRowBox"
	_root.add_child(_veil)
	_button = Button.new()
	_button.theme_type_variation = &"PanelButton"
	_root.add_child(_button)


func after_each() -> void:
	UiPrefs.reset()


func _prefs(large: bool, contrast: bool) -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE if large else GameSettings.TextSize.NORMAL
	settings.high_contrast = contrast
	UiPrefs.apply(settings)


func test_neutral_changes_nothing() -> void:
	var base := _label.get_theme_font_size(&"font_size")
	UiPrefsApplier.apply(_root)
	assert_true(UiPrefsApplier.is_neutral())
	assert_eq(_label.get_theme_font_size(&"font_size"), base)
	assert_false(_label.has_theme_font_size_override(&"font_size"))


func test_large_text_scales_labels_and_buttons() -> void:
	var base_label := _label.get_theme_font_size(&"font_size")
	var base_button := _button.get_theme_font_size(&"font_size")
	_prefs(true, false)
	UiPrefsApplier.apply(_root)
	assert_eq(_label.get_theme_font_size(&"font_size"), roundi(base_label * 1.15))
	assert_eq(_button.get_theme_font_size(&"font_size"), roundi(base_button * 1.15))


func test_applying_twice_does_not_compound() -> void:
	var base := _label.get_theme_font_size(&"font_size")
	_prefs(true, false)
	UiPrefsApplier.apply(_root)
	UiPrefsApplier.apply(_root)
	assert_eq(_label.get_theme_font_size(&"font_size"), roundi(base * 1.15))


func test_back_to_normal_restores() -> void:
	var base := _label.get_theme_font_size(&"font_size")
	_prefs(true, true)
	UiPrefsApplier.apply(_root)
	_prefs(false, false)
	UiPrefsApplier.apply(_root)
	assert_eq(_label.get_theme_font_size(&"font_size"), base)
	assert_false(_label.has_theme_font_size_override(&"font_size"))
	assert_false(_panel.has_theme_stylebox_override(&"panel"))
	assert_false(_muted.has_theme_color_override(&"font_color"))


func test_screen_overrides_are_the_base_and_survive() -> void:
	_label.add_theme_font_size_override(&"font_size", 40)
	_prefs(true, false)
	UiPrefsApplier.apply(_root)
	assert_eq(_label.get_theme_font_size(&"font_size"), 46)
	_prefs(false, false)
	UiPrefsApplier.apply(_root)
	assert_eq(_label.get_theme_font_size(&"font_size"), 40, "la surcharge de l'écran revient")


func test_contrast_raises_panel_opacity_but_not_veils() -> void:
	var veil_before := (_veil.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color
	_prefs(false, true)
	UiPrefsApplier.apply(_root)
	var panel := _panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_gte(panel.bg_color.a, UiTokens.CONTRAST_PANEL_ALPHA - 0.001)
	assert_eq((_veil.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color, veil_before,
		"un voile de 6 % reste un voile")


func test_contrast_lightens_muted_text_only() -> void:
	_prefs(false, true)
	UiPrefsApplier.apply(_root)
	assert_eq(_muted.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED_CONTRAST)
	assert_eq(_label.get_theme_color(&"font_color"), UiTokens.TEXT)


func test_new_nodes_are_fitted_on_the_next_pass() -> void:
	_prefs(true, false)
	UiPrefsApplier.apply(_root)
	var late := Label.new()
	late.theme_type_variation = &"SettingsLabel"
	_root.add_child(late)
	var base := late.get_theme_font_size(&"font_size")
	UiPrefsApplier.apply(_root)
	assert_eq(late.get_theme_font_size(&"font_size"), roundi(base * 1.15))
