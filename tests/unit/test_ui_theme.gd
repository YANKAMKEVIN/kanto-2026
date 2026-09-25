extends GutTest
## Thème UI : ui_theme.tres est à jour avec UiTokens et assigné au projet ; les fichiers de
## game/ui/ ne mettent aucune couleur en dur et ne connaissent pas le joueur.

const THEME_PATH := "res://game/ui/theme/ui_theme.tres"
const UI_DIR := "res://game/ui"
const TOKENS_FILE := "ui_tokens.gd"


func test_theme_assigned_to_project() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), THEME_PATH)


func test_theme_matches_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_eq(theme.default_font_size, UiTokens.FONT_BODY)
	assert_eq(theme.get_font_size(&"font_size", &"ZoneTitleName"), UiTokens.FONT_TITLE)
	assert_eq(theme.get_color(&"font_color", &"ZoneTitleName"), UiTokens.TEXT)
	assert_eq(theme.get_font_size(&"font_size", &"ZoneTitleRegion"), UiTokens.FONT_CAPTION)
	assert_eq(theme.get_color(&"font_color", &"ZoneTitleRegion"), UiTokens.TEXT_MUTED)
	assert_eq(theme.get_color(&"font_shadow_color", &"ZoneTitleName"), UiTokens.TEXT_SHADOW)
	var bold := theme.get_font(&"font", &"ZoneTitleName") as FontVariation
	assert_not_null(bold)
	assert_almost_eq(bold.variation_embolden, UiTokens.FONT_BOLD_EMBOLDEN, 0.0001)


func test_token_values_from_skill() -> void:
	assert_eq(UiTokens.ACCENT, Color("#F5C542"))
	assert_eq(UiTokens.TEXT_MUTED, Color("#B8C4D6"))
	assert_eq(UiTokens.SAFE_MARGIN, 48)
	assert_eq(UiTokens.ROUND_BUTTON, 128)
	assert_eq(UiTokens.JOYSTICK_RING, 260)
	assert_eq(UiTokens.JOYSTICK_KNOB, 110)
	assert_eq(UiTokens.JOYSTICK_FADE_OUT, 0.2)
	assert_eq(UiTokens.FONT_TITLE, 44)
	assert_eq(UiTokens.FONT_CAPTION, 24)


func test_no_hardcoded_color_in_ui_files() -> void:
	for path: String in _ui_files():
		if path.get_file() == TOKENS_FILE:
			continue
		var text := FileAccess.get_file_as_string(path)
		for pattern: String in ["Color(", "Color8(", "Color.html", "\"#"]:
			assert_false(text.contains(pattern), "%s contient %s" % [path, pattern])


func test_ui_does_not_know_player() -> void:
	for path: String in _ui_files():
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("Player"), "%s référence Player" % path)
		assert_false(text.contains("res://game/player"), "%s charge le joueur" % path)


func _ui_files(dir: String = UI_DIR) -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn"]:
			files.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		files.append_array(_ui_files(dir.path_join(sub)))
	return files
