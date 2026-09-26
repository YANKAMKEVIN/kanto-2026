extends SceneTree
## Génère game/ui/theme/ui_theme.tres à partir de UiTokens (seule source du style).
##
##   godot --headless --path . -s res://tools/build_ui_theme.gd
##
## Variations de type (theme_type_variation) :
##   ZoneTitleName    Label   nom de zone, 44, gras, ombre portée
##   ZoneTitleRegion  Label   région, 24, TEXT_MUTED, ombre portée
##   DialogBox        PanelContainer  boîte de dialogue sombre translucide (bible UI/UX §3)
##   DialogSpeaker    Label   nom du locuteur, gras, DIALOG_SPEAKER
##   DialogText       Label   réplique, FONT_BODY, TEXT
##   DialogNarration  Label   narration (Examiner, Observer), italique, DIALOG_NARRATION
##   DialogContinue   Label   indicateur de suite « › », gras, ACCENT
##   InteractLabel    PanelContainer  pastille du verbe du bouton contextuel
##   InteractLabelText Label  verbe (PARLER…), gras, majuscules
## tests/unit/test_ui_theme.gd vérifie que le fichier est à jour avec les tokens.

const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const THEME_PATH: String = "res://game/ui/theme/ui_theme.tres"


func _init() -> void:
	var t: GDScript = load(TOKENS_PATH)
	var theme := Theme.new()
	theme.default_font_size = t.FONT_BODY
	theme.set_color(&"font_color", &"Label", t.TEXT)

	var bold := FontVariation.new()
	bold.resource_name = "BoldDefault"
	bold.variation_embolden = t.FONT_BOLD_EMBOLDEN

	_add_label_variation(theme, &"ZoneTitleName", t.FONT_TITLE, t.TEXT, t)
	theme.set_font(&"font", &"ZoneTitleName", bold)
	_add_label_variation(theme, &"ZoneTitleRegion", t.FONT_CAPTION, t.TEXT_MUTED, t)

	var italic := FontVariation.new()
	italic.resource_name = "ItalicDefault"
	italic.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(t.DIALOG_ITALIC_SLANT, 1.0),
		Vector2.ZERO)

	var dialog_box := _panel_style(t.DIALOG_PANEL_BG, t.DIALOG_RADIUS, t)
	dialog_box.set_content_margin(SIDE_LEFT, t.DIALOG_PAD_H)
	dialog_box.set_content_margin(SIDE_RIGHT, t.DIALOG_PAD_H)
	dialog_box.set_content_margin(SIDE_TOP, t.DIALOG_PAD_V)
	dialog_box.set_content_margin(SIDE_BOTTOM, t.DIALOG_PAD_V)
	theme.set_type_variation(&"DialogBox", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DialogBox", dialog_box)

	_add_plain_label(theme, &"DialogSpeaker", t.DIALOG_SPEAKER_FONT, t.DIALOG_SPEAKER, bold)
	_add_plain_label(theme, &"DialogText", t.FONT_BODY, t.TEXT, null)
	_add_plain_label(theme, &"DialogNarration", t.FONT_BODY, t.DIALOG_NARRATION, italic)
	for type: StringName in [&"DialogText", &"DialogNarration"]:
		theme.set_constant(&"line_spacing", type, t.DIALOG_LINE_SPACING)
	_add_plain_label(theme, &"DialogContinue", t.DIALOG_CONTINUE_FONT, t.ACCENT, bold)

	var pill := _panel_style(t.PANEL_BG, t.ROUND_BUTTON, t)
	pill.shadow_size = 0
	pill.set_content_margin(SIDE_LEFT, t.INTERACT_LABEL_PAD_H)
	pill.set_content_margin(SIDE_RIGHT, t.INTERACT_LABEL_PAD_H)
	pill.set_content_margin(SIDE_TOP, t.INTERACT_LABEL_PAD_V)
	pill.set_content_margin(SIDE_BOTTOM, t.INTERACT_LABEL_PAD_V)
	theme.set_type_variation(&"InteractLabel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"InteractLabel", pill)
	_add_plain_label(theme, &"InteractLabelText", t.INTERACT_LABEL_FONT, t.TEXT, bold)

	var err := ResourceSaver.save(theme, THEME_PATH)
	print("ui_theme.tres : ", error_string(err))
	quit(0 if err == OK else 1)


func _add_label_variation(
	theme: Theme, type: StringName, size: int, color: Color, t: GDScript
) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	theme.set_color(&"font_shadow_color", type, t.TEXT_SHADOW)
	theme.set_constant(&"shadow_offset_x", type, 0)
	theme.set_constant(&"shadow_offset_y", type, t.TEXT_SHADOW_OFFSET)
	theme.set_constant(&"shadow_outline_size", type, t.TEXT_SHADOW_OFFSET * 2)


## Label sans ombre (texte posé sur un panneau) ; [param font] null = police du thème.
func _add_plain_label(
	theme: Theme, type: StringName, size: int, color: Color, font: Font
) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	if font != null:
		theme.set_font(&"font", type, font)


## Panneau arrondi : fond, bordure PANEL_BORDER, ombre SHADOW, anticrénelé.
func _panel_style(bg: Color, radius: int, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = t.PANEL_BORDER
	box.set_border_width_all(t.BORDER_WIDTH)
	box.set_corner_radius_all(radius)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE
	box.anti_aliasing = true
	return box
