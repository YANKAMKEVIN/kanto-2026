class_name MenuCard
extends Button
## Grande carte du tableau de bord (dossier 08 §1 ; maquette menu-tableau-de-bord-v1.jpg pour la
## DA, MM.1) : une **illustration peinte** couvre la carte ([MenuArt], rognée autour de son haut,
## coins arrondis), un dégradé vers la teinte de la carte en bas ; dessus, l'icône blanche, le
## nom, une barre de teinte, une ligne de description et une pastille ronde « › » teintée.
## Toute la carte est la zone tactile (un toucher = un signal [signal chosen], au relâchement) ;
## elle ne sait pas ce que l'écran ouvre. Sans illustration : la teinte seule (fond de la carte).
## Teinte par écran : UiTokens.MENU_CARD_TINTS (planche : bleu, rouge, or, vert, violet, gris).

## La carte est touchée ; porte l'écran qu'elle ouvre ([constant MenuRoute.TEAM]…).
signal chosen(screen: StringName)

const ICONS: Dictionary[StringName, Texture2D] = {
	MenuRoute.TEAM: preload("res://assets/ui/icons/battle/team.svg"),
	MenuRoute.POKEDEX: preload("res://assets/ui/icons/pokedex.svg"),
	MenuRoute.BAG: preload("res://assets/ui/icons/battle/bag.svg"),
	MenuRoute.MAP: preload("res://assets/ui/icons/menu/map.svg"),
	MenuRoute.TRAINER: preload("res://assets/ui/icons/menu/trainer.svg"),
	MenuRoute.SETTINGS: preload("res://assets/ui/icons/menu/settings.svg"),
}
const CHEVRON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")
const ART_SHADER: Shader = preload("res://game/ui/menu/dashboard/menu_card_art.gdshader")

var _screen: StringName = &""
var _tween: Tween

var _art: TextureRect
var _material: ShaderMaterial
var _rim: Panel
var _icon: TextureRect
var _bar: Panel
var _title: Label
var _caption: Label
var _round: Panel


func _init() -> void:
	theme_type_variation = &"MenuArtCard"
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()
	pressed.connect(_on_pressed)
	button_down.connect(_press_feedback.bind(true))
	button_up.connect(_press_feedback.bind(false))
	resized.connect(_on_resized)


## Remplit la carte avec [param view].
func setup(view: MenuCardView) -> void:
	_screen = view.screen
	_title.text = view.title
	_caption.text = view.caption
	_caption.visible = not view.caption.is_empty()
	_icon.texture = ICONS.get(view.screen, null)
	_icon.visible = _icon.texture != null
	var tint: Color = UiTokens.MENU_CARD_TINTS.get(view.screen, UiTokens.MENU_CARD_TINT_DEFAULT)
	var texture := MenuArt.card_illustration(view.screen)
	_art.texture = texture
	_art.visible = texture != null
	if texture != null:
		_material.set_shader_parameter(&"texture_size", texture.get_size())
	_apply_tint(tint)


func get_screen() -> StringName:
	return _screen


func get_title_text() -> String:
	return _title.text


func get_caption_text() -> String:
	return _caption.text


func get_icon() -> Texture2D:
	return _icon.texture


## Illustration peinte affichée (null : aucune, la teinte seule).
func get_illustration() -> Texture2D:
	return _art.texture if _art.visible else null


func _build() -> void:
	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = ART_SHADER
	_material.set_shader_parameter(&"radius", float(UiTokens.MENU_ART_RADIUS))
	_material.set_shader_parameter(&"fade_from", UiTokens.MENU_ART_FADE_FROM)
	_material.set_shader_parameter(&"focus", Vector2(0.5, UiTokens.MENU_ART_FOCUS_Y))
	_art.material = _material
	_art.visible = false
	add_child(_art)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.MENU_CARD_PAD)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	margin.add_child(row)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override(&"separation", UiTokens.GAP / 4)
	row.add_child(column)
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.MENU_ART_TITLE_ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_icon)
	_title = Label.new()
	_title.theme_type_variation = &"MenuArtTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.clip_text = true
	column.add_child(_title)
	_bar = Panel.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.custom_minimum_size = UiTokens.MENU_CARD_BAR
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_bar)
	_caption = Label.new()
	_caption.theme_type_variation = &"MenuArtCaption"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_caption)

	_round = Panel.new()
	_round.theme_type_variation = &"MenuArtRound"
	_round.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round.custom_minimum_size = Vector2.ONE * UiTokens.MENU_ART_ROUND
	_round.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_round)
	var chevron := TextureRect.new()
	chevron.texture = CHEVRON
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chevron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chevron.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := float(UiTokens.MENU_ART_ROUND - UiTokens.MENU_ART_ROUND_ICON) * 0.5
	chevron.offset_left = inset
	chevron.offset_top = inset
	chevron.offset_right = -inset
	chevron.offset_bottom = -inset
	_round.add_child(chevron)

	_rim = Panel.new()
	_rim.theme_type_variation = &"MenuArtRim"
	_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rim)


## Teinte propre à la carte : fond (sans illustration), dégradé du bas, barre, pastille ronde.
func _apply_tint(tint: Color) -> void:
	var normal := (get_theme_stylebox(&"normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	normal.bg_color = UiTokens.menu_card_bg(tint)
	for state: StringName in [&"normal", &"hover", &"disabled", &"pressed", &"hover_pressed"]:
		add_theme_stylebox_override(state, normal)
	var fade := UiTokens.menu_card_bg(tint)
	fade.a = UiTokens.MENU_ART_FADE_ALPHA
	_material.set_shader_parameter(&"fade_color", fade)
	var bar := StyleBoxFlat.new()
	bar.bg_color = tint
	bar.set_corner_radius_all(int(UiTokens.MENU_CARD_BAR.y))
	_bar.add_theme_stylebox_override(&"panel", bar)
	var round := (_round.get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() \
		as StyleBoxFlat
	round.bg_color = UiTokens.tinted(tint, UiTokens.MENU_ART_FADE_ALPHA)
	_round.add_theme_stylebox_override(&"panel", round)


func _on_resized() -> void:
	pivot_offset = size * 0.5
	_material.set_shader_parameter(&"rect_size", size)


func _on_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	chosen.emit(_screen)


func _press_feedback(down: bool) -> void:
	_rim.theme_type_variation = &"MenuArtRimPressed" if down else &"MenuArtRim"
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	_tween.tween_property(self, ^"scale", target, UiTokens.ANIM_MICRO)
