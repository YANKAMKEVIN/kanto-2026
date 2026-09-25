extends SceneTree
## Génère game/ui/theme/ui_theme.tres à partir de UiTokens (seule source du style).
##
##   godot --headless --path . -s res://tools/build_ui_theme.gd
##
## Variations de type (theme_type_variation) :
##   ZoneTitleName    Label   nom de zone, 44, gras, ombre portée
##   ZoneTitleRegion  Label   région, 24, TEXT_MUTED, ombre portée
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
