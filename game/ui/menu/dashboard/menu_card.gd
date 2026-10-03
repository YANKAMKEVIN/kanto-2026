class_name MenuCard
extends Button
## Grande carte du tableau de bord (dossier 08 §1) : icône, barre de teinte, nom, une ligne de
## description et une pastille « › ». Toute la carte est la zone tactile (un toucher = un
## signal [signal chosen], au relâchement) ; elle ne sait pas ce que l'écran ouvre.
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

var _screen: StringName = &""
var _tween: Tween

var _icon: TextureRect
var _bar: Panel
var _title: Label
var _caption: Label


func _init() -> void:
	theme_type_variation = &"MenuCard"
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()
	pressed.connect(_on_pressed)
	button_down.connect(_press_feedback.bind(true))
	button_up.connect(_press_feedback.bind(false))
	resized.connect(_update_pivot)


## Remplit la carte avec [param view].
func setup(view: MenuCardView) -> void:
	_screen = view.screen
	_title.text = view.title
	_caption.text = view.caption
	_caption.visible = not view.caption.is_empty()
	_icon.texture = ICONS.get(view.screen, null)
	_icon.visible = _icon.texture != null
	var tint: Color = UiTokens.MENU_CARD_TINTS.get(view.screen, UiTokens.MENU_CARD_TINT_DEFAULT)
	_apply_tint(tint)


func get_screen() -> StringName:
	return _screen


func get_title_text() -> String:
	return _title.text


func get_caption_text() -> String:
	return _caption.text


func get_icon() -> Texture2D:
	return _icon.texture


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.MENU_CARD_PAD)
	add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	margin.add_child(column)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.MENU_CARD_ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_icon)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var chevron := Panel.new()
	chevron.theme_type_variation = &"MenuCardChevron"
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.custom_minimum_size = Vector2.ONE * UiTokens.MENU_CARD_CHEVRON
	chevron.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(chevron)
	var chevron_icon := TextureRect.new()
	chevron_icon.texture = CHEVRON
	chevron_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chevron_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chevron_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := float(UiTokens.MENU_CARD_CHEVRON - UiTokens.MENU_CARD_CHEVRON_ICON) * 0.5
	chevron_icon.offset_left = inset
	chevron_icon.offset_top = inset
	chevron_icon.offset_right = -inset
	chevron_icon.offset_bottom = -inset
	chevron.add_child(chevron_icon)

	var fill := Control.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(fill)

	_bar = Panel.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.custom_minimum_size = UiTokens.MENU_CARD_BAR
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_bar)
	_title = Label.new()
	_title.theme_type_variation = &"MenuCardTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_title)
	_caption = Label.new()
	_caption.theme_type_variation = &"MenuCardCaption"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_caption)


## Teinte propre à la carte : fond, liseré, barre ; enfoncée = plus dense, liseré ACCENT.
func _apply_tint(tint: Color) -> void:
	var normal := (get_theme_stylebox(&"normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	normal.bg_color = UiTokens.menu_card_bg(tint)
	normal.border_color = UiTokens.menu_card_border(tint)
	var pressed_box := (get_theme_stylebox(&"pressed") as StyleBoxFlat).duplicate() \
		as StyleBoxFlat
	pressed_box.bg_color = UiTokens.menu_card_bg_pressed(tint)
	for state: StringName in [&"normal", &"hover", &"disabled"]:
		add_theme_stylebox_override(state, normal)
	for state: StringName in [&"pressed", &"hover_pressed"]:
		add_theme_stylebox_override(state, pressed_box)
	var bar := StyleBoxFlat.new()
	bar.bg_color = tint
	bar.set_corner_radius_all(int(UiTokens.MENU_CARD_BAR.y))
	_bar.add_theme_stylebox_override(&"panel", bar)


func _on_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	chosen.emit(_screen)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _press_feedback(down: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	_tween.tween_property(self, ^"scale", target, UiTokens.ANIM_MICRO)
