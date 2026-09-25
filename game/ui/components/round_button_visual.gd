class_name RoundButtonVisual
extends Node2D
## Visuel d'un bouton rond d'exploration (courir, parler, menu), centré sur l'origine.
##
## Enfant d'un TouchScreenButton : cercle ROUND_BUTTON sur fond PANEL_BG, contour clair,
## icône blanche. Enfoncé : fond ACCENT, icône ACCENT_TEXT, échelle PRESSED_SCALE.
## Il ne fait qu'afficher : l'action (ex. « run ») est portée par le TouchScreenButton,
## dont il règle la zone touchable (cercle ROUND_BUTTON centré sur l'origine).

@export var icon: Texture2D

var _pressed: bool = false
var _tween: Tween


func _ready() -> void:
	var button := get_parent() as TouchScreenButton
	if button != null:
		var shape := CircleShape2D.new()
		shape.radius = UiTokens.ROUND_BUTTON * 0.5
		button.shape = shape
		button.shape_centered = false
		button.pressed.connect(_set_pressed.bind(true))
		button.released.connect(_set_pressed.bind(false))


func _draw() -> void:
	var radius := UiTokens.ROUND_BUTTON * 0.5
	var width := UiTokens.ROUND_BUTTON_OUTLINE_WIDTH
	var fill := UiTokens.ACCENT if _pressed else UiTokens.PANEL_BG
	draw_circle(Vector2.ZERO, radius, fill, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius - width * 0.5, UiTokens.ROUND_BUTTON_OUTLINE, false,
		width, true)
	if icon != null:
		var icon_size := Vector2.ONE * UiTokens.ROUND_BUTTON_ICON
		var tint := UiTokens.ACCENT_TEXT if _pressed else UiTokens.TEXT
		draw_texture_rect(icon, Rect2(-icon_size * 0.5, icon_size), false, tint)


func is_pressed() -> bool:
	return _pressed


func _set_pressed(pressed: bool) -> void:
	_pressed = pressed
	queue_redraw()
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if pressed else 1.0)
	_tween.tween_property(self, ^"scale", target, UiTokens.ANIM_MICRO)
