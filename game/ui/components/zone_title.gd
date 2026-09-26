class_name ZoneTitle
extends MarginContainer
## Titre de zone : Poké Ball + NOM (44, gras, majuscules) + région (24, TEXT_MUTED).
##
## En haut à gauche, à SAFE_MARGIN des bords. Il glisse en apparaissant (300 ms), reste
## 2,5 s, puis glisse en disparaissant. Purement visuel : il ignore souris et toucher.
## Fond : panneau sombre translucide arrondi à gauche, prolongé par un dégradé vers la
## transparence (planche DA 2026).

signal title_shown
signal title_hidden

@export var slide_duration: float = UiTokens.ANIM_PANEL
@export var hold_duration: float = UiTokens.ZONE_TITLE_HOLD

var _tween: Tween
var _box := StyleBoxFlat.new()

@onready var _row: HBoxContainer = %Row
@onready var _lines: VBoxContainer = %Lines
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _region_label: Label = %RegionLabel


func _ready() -> void:
	add_theme_constant_override(&"margin_left", UiTokens.PAD)
	add_theme_constant_override(&"margin_top", UiTokens.GAP)
	add_theme_constant_override(&"margin_right", UiTokens.PAD + UiTokens.ZONE_TITLE_FADE)
	add_theme_constant_override(&"margin_bottom", UiTokens.GAP)
	_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	_lines.add_theme_constant_override(&"separation", UiTokens.ZONE_TITLE_LINE_GAP)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.ZONE_TITLE_ICON
	_box.bg_color = UiTokens.PANEL_BG
	_box.corner_radius_top_left = UiTokens.RADIUS
	_box.corner_radius_bottom_left = UiTokens.RADIUS
	_box.anti_aliasing = true
	position = get_rest_position()
	modulate.a = 0.0
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var fade_start := maxf(size.x - UiTokens.ZONE_TITLE_FADE, 0.0)
	draw_style_box(_box, Rect2(0.0, 0.0, fade_start, size.y))
	var clear := UiTokens.PANEL_BG_CLEAR
	draw_polygon(
		PackedVector2Array([
			Vector2(fade_start, 0.0), Vector2(size.x, 0.0),
			Vector2(size.x, size.y), Vector2(fade_start, size.y),
		]),
		PackedColorArray([UiTokens.PANEL_BG, clear, clear, UiTokens.PANEL_BG])
	)


## Affiche le titre (nom mis en MAJUSCULES) ; relance l'animation s'il était déjà visible.
func show_title(zone_name: String, region: String) -> void:
	_name_label.text = zone_name.to_upper()
	_region_label.text = region
	_region_label.visible = not region.is_empty()
	reset_size()
	if _tween != null:
		_tween.kill()
	var rest := get_rest_position()
	var away := rest - Vector2(UiTokens.PANEL_SLIDE, 0.0)
	position = away
	modulate.a = 0.0
	visible = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"position", rest, slide_duration)
	_tween.parallel().tween_property(self, ^"modulate:a", 1.0, slide_duration)
	_tween.tween_callback(title_shown.emit)
	_tween.tween_interval(hold_duration)
	_tween.tween_property(self, ^"position", away, slide_duration).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, ^"modulate:a", 0.0, slide_duration) \
		.set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_hidden)


## Masque tout de suite le titre (fondu court), par exemple au début d'une transition :
## sinon un titre encore visible réapparaîtrait par-dessus la carte suivante. Émet
## title_hidden à la fin ; sans effet si le titre n'est pas affiché.
func hide_now(duration: float = UiTokens.ANIM_MICRO) -> void:
	if not visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"modulate:a", 0.0, duration)
	_tween.tween_callback(_on_hidden)


func is_showing() -> bool:
	return visible


func get_zone_name_text() -> String:
	return _name_label.text


func get_region_text() -> String:
	return _region_label.text


## Position de repos (coin haut gauche du panneau), à SAFE_MARGIN des bords.
func get_rest_position() -> Vector2:
	return Vector2.ONE * UiTokens.SAFE_MARGIN


func _on_hidden() -> void:
	visible = false
	title_hidden.emit()
