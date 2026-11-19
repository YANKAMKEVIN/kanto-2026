class_name StatStageChip
extends PanelContainer
## Puce d'un cran de statistique sur une carte de combat : « ATT ▲2 », « DÉF ▼1 ».
##
## Petite capsule sombre : libellé court, flèche dessinée (vers le haut = hausse, vers le bas =
## baisse) et nombre de crans. Le sens se lit à la flèche, la couleur ne fait que le doubler.
## Elle ne connaît ni le moteur ni les données : un libellé et un entier. Purement visuelle.

var _stage: int = 0
var _row := HBoxContainer.new()
var _label := Label.new()
var _arrow := Arrow.new()
var _count := Label.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = UiTokens.STAT_CHIP_BG
	box.set_corner_radius_all(UiTokens.STAT_CHIP_RADIUS)
	box.content_margin_left = UiTokens.STAT_CHIP_PAD_H
	box.content_margin_right = UiTokens.STAT_CHIP_PAD_H
	box.content_margin_top = UiTokens.STAT_CHIP_PAD_V
	box.content_margin_bottom = UiTokens.STAT_CHIP_PAD_V
	box.anti_aliasing = true
	add_theme_stylebox_override(&"panel", box)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(&"separation", UiTokens.STAT_CHIP_GAP)
	add_child(_row)
	for label: Label in [_label, _count]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override(&"font_size", UiTokens.STAT_CHIP_FONT)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label.add_theme_color_override(&"font_color", UiTokens.TEXT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.custom_minimum_size = Vector2.ONE * UiTokens.STAT_CHIP_ARROW
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(_label)
	_row.add_child(_arrow)
	_row.add_child(_count)


## Pose [param label] (« ATT ») et [param stage] (cran de −6 à +6, jamais 0 : une puce à zéro
## n'existe pas, la carte la retire).
func set_stage(label: String, stage: int) -> void:
	_stage = stage
	_label.text = label
	_count.text = str(absi(stage))
	var color := UiTokens.STAT_CHIP_UP if stage > 0 else UiTokens.STAT_CHIP_DOWN
	_count.add_theme_color_override(&"font_color", color)
	_arrow.set_arrow(stage > 0, color)


func get_stage() -> int:
	return _stage


func get_label_text() -> String:
	return _label.text


## « ATT +2 », « DÉF -1 » (lecture de la puce, pour les tests).
func get_text() -> String:
	return "%s %s%d" % [_label.text, "+" if _stage > 0 else "-", absi(_stage)]


## Vrai si la flèche pointe vers le haut.
func is_up() -> bool:
	return _arrow.is_up()


## Triangle plein, pointe en haut (hausse) ou en bas (baisse).
class Arrow extends Control:
	var _up: bool = true
	var _color: Color = UiTokens.TEXT

	func set_arrow(up: bool, color: Color) -> void:
		_up = up
		_color = color
		queue_redraw()

	func is_up() -> bool:
		return _up

	func _draw() -> void:
		var tip_y := 0.0 if _up else size.y
		var base_y := size.y if _up else 0.0
		draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.5, tip_y),
			Vector2(size.x, base_y), Vector2(0.0, base_y)]), _color)
