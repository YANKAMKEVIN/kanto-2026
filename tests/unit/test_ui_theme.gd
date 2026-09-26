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


func test_dialog_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_eq(theme.get_type_variation_base(&"DialogBox"), &"PanelContainer")
	var box := theme.get_stylebox(&"panel", &"DialogBox") as StyleBoxFlat
	assert_not_null(box)
	assert_eq(box.bg_color, UiTokens.DIALOG_PANEL_BG)
	assert_eq(box.corner_radius_top_left, UiTokens.DIALOG_RADIUS)
	assert_eq(box.get_content_margin(SIDE_LEFT), float(UiTokens.DIALOG_PAD_H))
	assert_eq(box.get_content_margin(SIDE_TOP), float(UiTokens.DIALOG_PAD_V))
	assert_eq(theme.get_font_size(&"font_size", &"DialogSpeaker"), UiTokens.DIALOG_SPEAKER_FONT)
	assert_eq(theme.get_color(&"font_color", &"DialogSpeaker"), UiTokens.DIALOG_SPEAKER)
	assert_eq(theme.get_font_size(&"font_size", &"DialogText"), UiTokens.FONT_BODY)
	assert_eq(theme.get_color(&"font_color", &"DialogText"), UiTokens.TEXT)
	assert_eq(theme.get_constant(&"line_spacing", &"DialogText"), UiTokens.DIALOG_LINE_SPACING)
	assert_eq(theme.get_color(&"font_color", &"DialogNarration"), UiTokens.DIALOG_NARRATION)
	var italic := theme.get_font(&"font", &"DialogNarration") as FontVariation
	assert_not_null(italic)
	assert_almost_eq(italic.variation_transform.y.x, UiTokens.DIALOG_ITALIC_SLANT, 0.0001)
	assert_eq(theme.get_color(&"font_color", &"DialogContinue"), UiTokens.ACCENT)
	assert_eq(theme.get_font_size(&"font_size", &"DialogContinue"), UiTokens.DIALOG_CONTINUE_FONT)


func test_interact_label_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	var pill := theme.get_stylebox(&"panel", &"InteractLabel") as StyleBoxFlat
	assert_not_null(pill)
	assert_eq(pill.bg_color, UiTokens.PANEL_BG)
	assert_eq(pill.get_content_margin(SIDE_LEFT), float(UiTokens.INTERACT_LABEL_PAD_H))
	assert_eq(theme.get_font_size(&"font_size", &"InteractLabelText"),
		UiTokens.INTERACT_LABEL_FONT)
	assert_eq(theme.get_color(&"font_color", &"InteractLabelText"), UiTokens.TEXT)
	assert_not_null(theme.get_font(&"font", &"InteractLabelText") as FontVariation, "gras")


func test_dialog_tokens_from_plan() -> void:
	assert_eq(UiTokens.DIALOG_BOX_WIDTH, 1400)
	assert_eq(UiTokens.DIALOG_BOX_MIN_HEIGHT, 200)
	assert_eq(UiTokens.DIALOG_MAX_LINES, 3)
	assert_eq(UiTokens.DIALOG_CHARS_PER_SECOND, 45.0)
	assert_eq(UiTokens.DIALOG_CONTINUE_BLINK, 0.5)
	assert_eq(UiTokens.DIALOG_BOTTOM_MARGIN, UiTokens.SAFE_MARGIN)
	assert_eq(UiTokens.DIALOG_OPEN, 0.18)
	assert_eq(UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER, Vector2(190, 360))
	assert_eq(UiTokens.LAYER_DIALOG, 30)


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


func test_caption_and_starter_sheet_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_eq(theme.get_type_variation_base(&"WorldCaption"), &"Label")
	assert_eq(theme.get_font_size(&"font_size", &"WorldCaption"), UiTokens.FONT_TITLE)
	assert_eq(theme.get_color(&"font_shadow_color", &"WorldCaption"), UiTokens.TEXT_SHADOW)
	assert_eq(theme.get_constant(&"shadow_outline_size", &"WorldCaption"),
		UiTokens.CAPTION_SHADOW_OUTLINE)
	assert_false(theme.has_stylebox(&"normal", &"WorldCaption"), "légende sans fond")
	var card := theme.get_stylebox(&"panel", &"StarterSheet") as StyleBoxFlat
	assert_not_null(card)
	assert_eq(card.bg_color, UiTokens.PANEL_BG)
	assert_eq(card.corner_radius_bottom_right, UiTokens.RADIUS)
	assert_eq(card.get_content_margin(SIDE_TOP), float(UiTokens.STARTER_SHEET_PAD))
	assert_eq(theme.get_font_size(&"font_size", &"StarterSheetName"), UiTokens.FONT_TITLE)
	assert_eq(theme.get_font_size(&"font_size", &"StarterSheetPhrase"), UiTokens.FONT_BODY)
	var italic := theme.get_font(&"font", &"StarterSheetPhrase") as FontVariation
	assert_not_null(italic)
	assert_almost_eq(italic.variation_transform.y.x, UiTokens.DIALOG_ITALIC_SLANT, 0.0001)
	var badge := theme.get_stylebox(&"panel", &"TypeBadge") as StyleBoxFlat
	assert_not_null(badge)
	assert_eq(badge.corner_radius_top_left, UiTokens.TYPE_BADGE_RADIUS)
	assert_eq(theme.get_font_size(&"font_size", &"TypeBadgeText"), UiTokens.TYPE_BADGE_FONT)
	var accent := theme.get_stylebox(&"normal", &"AccentButton") as StyleBoxFlat
	assert_eq(accent.bg_color, UiTokens.ACCENT)
	assert_eq(theme.get_color(&"font_color", &"AccentButton"), UiTokens.ACCENT_TEXT)
	assert_eq(theme.get_font_size(&"font_size", &"AccentButton"), UiTokens.FONT_BUTTON)
	var back := theme.get_stylebox(&"normal", &"PanelButton") as StyleBoxFlat
	assert_eq(back.bg_color, UiTokens.BUTTON_BG)
	assert_eq((theme.get_stylebox(&"pressed", &"PanelButton") as StyleBoxFlat).bg_color,
		UiTokens.ACCENT)
	assert_eq(theme.get_color(&"font_color", &"PanelButton"), UiTokens.TEXT)


func test_type_colors_cover_all_types_of_the_data() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/pokemon/types.json"))
	var types: Dictionary = data["types"]
	assert_eq(UiTokens.TYPE_COLORS.size(), types.size())
	for type_id: String in types:
		assert_true(UiTokens.TYPE_COLORS.has(StringName(type_id)), type_id)
	assert_eq(UiTokens.TYPE_COLORS[&"fire"], Color("#EE8130"))
	assert_eq(UiTokens.TYPE_COLORS[&"electric"], Color("#F7D02C"))
	assert_eq(UiTokens.TYPE_COLORS[&"steel"], Color("#B7B7CE"))
	assert_eq(UiTokens.TYPE_COLORS[&"dark"], Color("#705746"))
	assert_eq(UiTokens.TYPE_COLORS[&"fairy"], Color("#D685AD"))
	assert_eq(UiTokens.CAPTION_HOLD, 3.0)
	assert_eq(UiTokens.STARTER_SHEET_WIDTH, 600)
	assert_true(UiTokens.STARTER_SHEET_LEFT >= UiTokens.SAFE_MARGIN)


func test_no_hardcoded_color_in_ui_files() -> void:
	for path: String in _ui_files():
		if path.get_file() == TOKENS_FILE:
			continue
		var text := FileAccess.get_file_as_string(path)
		for pattern: String in ["Color(", "Color8(", "Color.html", "\"#"]:
			assert_false(text.contains(pattern), "%s contient %s" % [path, pattern])


func test_ui_does_not_know_player_map_or_router() -> void:
	for path: String in _ui_files():
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("Player"), "%s référence Player" % path)
		assert_false(text.contains("res://game/player"), "%s charge le joueur" % path)
		assert_false(text.contains("SceneRouter"), "%s référence SceneRouter" % path)
		assert_false(text.contains("GameMap"), "%s référence la carte" % path)
		assert_false(text.contains("res://game/world"), "%s charge le monde" % path)
		assert_false(text.contains("res://game/systems"), "%s charge un système" % path)
		assert_false(text.contains("res://data"), "%s lit des données" % path)
		assert_false(text.contains("res://game/pokemon"), "%s charge un Pokémon" % path)
		assert_false(text.contains("res://game/battle"), "%s charge le combat" % path)
		for logic_class: String in ["Interaction", "DialogueSession", "DialogueLibrary",
				"DialogueRunner", "DialoguePage", "DialogueVariant", "StoryFlags", "GameState",
				"NpcSpec", "NpcRoster", "PokemonData", "PokemonFactory", "SpeciesData",
				"StarterOffer", "StarterChoice", "TypeChart", "MoveData", "DamageCalc"]:
			assert_false(text.contains(logic_class), "%s référence %s" % [path, logic_class])


func _ui_files(dir: String = UI_DIR) -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn"]:
			files.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		files.append_array(_ui_files(dir.path_join(sub)))
	return files
