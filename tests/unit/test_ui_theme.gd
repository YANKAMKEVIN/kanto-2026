extends GutTest
## Thème UI : ui_theme.tres est à jour avec UiTokens et assigné au projet ; les fichiers de
## game/ui/ ne mettent aucune couleur en dur et ne connaissent pas le joueur.

const THEME_PATH := "res://game/ui/theme/ui_theme.tres"
const UI_DIR := "res://game/ui"
const TOKENS_FILE := "ui_tokens.gd"
## Classes de logique (combat, Pokémon, partie, carte) que l'interface ne doit pas connaître.
## Recherche en mot entier (frontières \b) : « BattleCardView », « BattleInfoCard » ou
## « PartyPips » sont légitimes, « Battle », « Battle.Outcome » ou « Party » ne le sont pas.
const LOGIC_CLASSES: Array[String] = [
	"Battle", "BattleEvent", "Battler", "BattleSide", "BattleAction", "BattleAI", "BattleText",
	"BattleDirector", "BattleStage", "BattleLayout", "DamageCalc", "DamageResult", "TrainerData",
	"TrainerLibrary", "TrainerSlot", "Pokemon", "Party", "MoveData", "MoveSlot", "MoveEffect",
	"SpeciesData", "PokemonData", "PokemonFactory", "TypeChart", "GameState", "GameRng",
	"Player", "GameMap", "SceneRouter", "BattleBeat", "BattlePlayback", "BattleViews",
	"BattleConclusion", "ItemData", "ItemLibrary",
]


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


func test_ui_does_not_know_battle_logic() -> void:
	var regex := RegEx.create_from_string("\\b(%s)\\b" % "|".join(LOGIC_CLASSES))
	assert_not_null(regex.search("var b: Battle = x"), "la règle attrape « Battle »")
	assert_not_null(regex.search("return Battle.Outcome.WIN"), "…et « Battle.Outcome »")
	assert_not_null(regex.search("func f(p: Party)"), "…et « Party »")
	assert_null(regex.search("var v: BattleCardView ; PartyPips ; BattleInfoCard"),
		"pas de faux positif sur les classes de vue")
	for path: String in _ui_files():
		var text := FileAccess.get_file_as_string(path)
		var found := regex.search(text)
		assert_null(found, "%s référence %s" % [path, found.get_string() if found else ""])
		for folder: String in ["res://game/battle", "res://game/pokemon", "res://data",
				"res://game/world", "res://game/player", "res://game/autoload"]:
			assert_false(text.contains(folder), "%s charge %s" % [path, folder])


func test_battle_tokens_from_plan() -> void:
	assert_eq(UiTokens.LAYER_BATTLE_STAGE, 5)
	assert_eq(UiTokens.LAYER_BATTLE_HUD, 12)
	assert_between(UiTokens.LAYER_BATTLE_STAGE, 0, UiTokens.LAYER_HUD, "sous l'UI")
	assert_between(UiTokens.LAYER_BATTLE_HUD, UiTokens.LAYER_HUD, UiTokens.LAYER_MENU)
	assert_eq(UiTokens.HP_BAR_HEIGHT, 14)
	assert_eq(UiTokens.HP_TWEEN, 0.4)
	assert_lt(UiTokens.HP_TWEEN_FAST, UiTokens.HP_TWEEN, "gros coup : plus rapide")
	assert_eq(UiTokens.LONG_PRESS, 0.45)
	assert_almost_eq(UiTokens.BATTLE_MESSAGE_HOLD, 0.9, 0.001)
	assert_eq(UiTokens.HP_HIGH_THRESHOLD, 0.5)
	assert_eq(UiTokens.HP_LOW_THRESHOLD, 0.2)
	assert_gt(UiTokens.HAPTIC_CRIT_MS, UiTokens.HAPTIC_HIT_MS, "critique plus marqué")
	assert_gt(UiTokens.HAPTIC_HIT_MS, UiTokens.HAPTIC_TAP_MS)
	assert_between(UiTokens.BATTLE_DIM, 0.0, 0.5)
	assert_between(UiTokens.BATTLE_ZOOM, 1.0, 1.1)
	assert_eq(UiTokens.PARTY_SIZE, 6)
	assert_true(UiTokens.BATTLE_ACTION_SIZE.y >= UiTokens.TOUCH_MIN, "actions ≥ TOUCH_MIN")
	assert_true(UiTokens.MOVE_CARD_SIZE.y >= UiTokens.TOUCH_MIN, "capacités ≥ TOUCH_MIN")
	assert_true(UiTokens.BATTLE_BACK_SIZE >= UiTokens.TOUCH_MIN, "« ‹ » ≥ TOUCH_MIN")
	assert_true(UiTokens.MOVE_GAP_H >= UiTokens.MOVE_SELECT_ARROW.x, "la flèche ▶ tient")
	for color: Color in [UiTokens.ACTION_ATTACK, UiTokens.ACTION_BAG, UiTokens.ACTION_TEAM,
			UiTokens.ACTION_RUN, UiTokens.GENDER_MALE, UiTokens.GENDER_FEMALE]:
		assert_gt(color.a, 0.5, str(color))
	assert_lt(UiTokens.BATTLE_CARD_BG.a, 1.0, "cartes translucides (Q17)")
	assert_lt(UiTokens.BATTLE_MESSAGE_BG.a, 1.0, "bandeau translucide")


func test_battle_card_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	var card := theme.get_stylebox(&"panel", &"BattleCard") as StyleBoxFlat
	assert_not_null(card)
	assert_eq(card.bg_color, UiTokens.BATTLE_CARD_BG)
	assert_eq(card.corner_radius_top_left, UiTokens.RADIUS)
	assert_eq(card.get_content_margin(SIDE_LEFT), float(UiTokens.BATTLE_CARD_PAD_H))
	assert_eq(theme.get_font_size(&"font_size", &"BattleCardName"), UiTokens.BATTLE_CARD_NAME_FONT)
	assert_not_null(theme.get_font(&"font", &"BattleCardName") as FontVariation, "nom gras")
	assert_eq(theme.get_font_size(&"font_size", &"BattleCardHp"),
		UiTokens.BATTLE_HP_NUMBERS_FONT)
	assert_eq(theme.get_type_variation_base(&"HpBar"), &"HBoxContainer")
	var track := theme.get_stylebox(&"background", &"HpBar") as StyleBoxFlat
	assert_eq(track.bg_color, UiTokens.HP_BAR_TRACK)
	assert_eq(track.corner_radius_top_left, UiTokens.HP_BAR_HEIGHT / 2)
	assert_eq((theme.get_stylebox(&"fill", &"HpBar") as StyleBoxFlat).bg_color, UiTokens.HP_HIGH)
	assert_eq(theme.get_font_size(&"font_size", &"HpBarLabel"), UiTokens.HP_BAR_LABEL_FONT)
	assert_eq((theme.get_stylebox(&"panel", &"PartyPipEmpty") as StyleBoxFlat).bg_color,
		UiTokens.PARTY_PIP_EMPTY)
	var back := theme.get_stylebox(&"normal", &"BattleBackButton") as StyleBoxFlat
	assert_eq(back.bg_color, UiTokens.PANEL_BG)
	assert_eq((theme.get_stylebox(&"pressed", &"BattleBackButton") as StyleBoxFlat).bg_color,
		UiTokens.ACCENT)


func test_battle_action_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_eq(theme.get_type_variation_base(&"ActionButton"), &"Button")
	assert_eq(theme.get_font_size(&"font_size", &"ActionButton"), UiTokens.FONT_BUTTON)
	assert_eq(theme.get_color(&"font_disabled_color", &"ActionButton"), UiTokens.TEXT_DISABLED)
	var colors := {
		&"ActionButtonAttack": UiTokens.ACTION_ATTACK, &"ActionButtonBag": UiTokens.ACTION_BAG,
		&"ActionButtonTeam": UiTokens.ACTION_TEAM, &"ActionButtonRun": UiTokens.ACTION_RUN,
	}
	for type: StringName in colors:
		assert_eq(theme.get_type_variation_base(type), &"ActionButton", String(type))
		var normal := theme.get_stylebox(&"normal", type) as StyleBoxFlat
		assert_eq(normal.bg_color, colors[type], String(type))
		var disabled := theme.get_stylebox(&"disabled", type) as StyleBoxFlat
		assert_lt(disabled.bg_color.a, normal.bg_color.a + 0.001, "%s atténué" % type)
		assert_ne(disabled.bg_color, normal.bg_color, "%s atténué" % type)
	var glow := theme.get_stylebox(&"panel", &"ActionGlow") as StyleBoxFlat
	assert_eq(glow.border_color, UiTokens.ACCENT)
	assert_eq(glow.shadow_color, UiTokens.ACTION_GLOW)


func test_battle_move_and_message_variations_match_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_eq((theme.get_stylebox(&"panel", &"MoveBand") as StyleBoxFlat).bg_color,
		UiTokens.MOVE_BAND_BG)
	var selected := theme.get_stylebox(&"panel", &"MoveCardSelected") as StyleBoxFlat
	assert_eq(selected.border_color, UiTokens.ACCENT)
	assert_eq(selected.border_width_left, UiTokens.MOVE_CARD_SELECTED_BORDER)
	assert_eq((theme.get_stylebox(&"panel", &"MoveCardEmpty") as StyleBoxFlat).bg_color,
		UiTokens.MOVE_CARD_EMPTY_BG)
	assert_eq(theme.get_font_size(&"font_size", &"MoveCardName"), UiTokens.MOVE_CARD_NAME_FONT)
	assert_eq(theme.get_color(&"font_color", &"MoveCardPpTag"), UiTokens.TEXT_MUTED)
	assert_eq(theme.get_color(&"font_color", &"MoveCardPp"), UiTokens.TEXT)
	var sheet := theme.get_stylebox(&"panel", &"MoveDetailSheet") as StyleBoxFlat
	assert_eq(sheet.bg_color, UiTokens.MOVE_DETAIL_BG)
	var banner := theme.get_stylebox(&"panel", &"BattleMessage") as StyleBoxFlat
	assert_eq(banner.bg_color, UiTokens.BATTLE_MESSAGE_BG)
	assert_eq(theme.get_font_size(&"font_size", &"BattleMessageText"), UiTokens.FONT_BODY)


func _ui_files(dir: String = UI_DIR) -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn"]:
			files.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		files.append_array(_ui_files(dir.path_join(sub)))
	return files
