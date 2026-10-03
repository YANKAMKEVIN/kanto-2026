class_name StatGauge
extends Control
## Jauge d'une statistique (dossier 08 §2 : jauges et valeurs, jamais un tableau) : fond clair
## translucide et remplissage de TEAM_GAUGE_FILL (ou de la couleur donnée), coins ronds. Elle ne
## connaît qu'une part 0..1.

var _ratio: float = 0.0
var _fill_color: Color = UiTokens.TEAM_GAUGE_FILL
var _track: StyleBoxFlat
var _fill: StyleBoxFlat


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = UiTokens.TEAM_GAUGE_HEIGHT
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_track = _rounded(UiTokens.HP_BAR_TRACK)
	_fill = _rounded(_fill_color)


func _draw() -> void:
	draw_style_box(_track, Rect2(Vector2.ZERO, size))
	if _ratio <= 0.0:
		return
	var width := maxf(size.x * _ratio, size.y)
	draw_style_box(_fill, Rect2(Vector2.ZERO, Vector2(width, size.y)))


## Part affichée (0..1) et couleur du remplissage.
func set_ratio(ratio: float, color: Color = UiTokens.TEAM_GAUGE_FILL) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_fill_color = color
	_fill.bg_color = color
	queue_redraw()


func get_ratio() -> float:
	return _ratio


func get_fill_color() -> Color:
	return _fill_color


func _rounded(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(UiTokens.TEAM_GAUGE_HEIGHT)
	box.anti_aliasing = true
	return box
