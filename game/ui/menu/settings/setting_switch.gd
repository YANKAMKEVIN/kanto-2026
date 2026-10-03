class_name SettingSwitch
extends Control
## Interrupteur dessiné (piste arrondie, pastille blanche) : purement visuel, il ne reçoit aucun
## toucher (la ligne qui le porte est le bouton). L'état est aussi écrit en toutes lettres à côté :
## la couleur et la position ne sont jamais seules à le dire.

## Durées multipliées (0 = instantané).
var speed_scale: float = 1.0

var _on: bool = false
## 0 (éteint) → 1 (allumé), animé.
var _amount: float = 0.0
var _tween: Tween
var _track := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = UiTokens.SETTINGS_SWITCH_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_track.set_corner_radius_all(roundi(UiTokens.SETTINGS_SWITCH_SIZE.y * 0.5))
	_track.anti_aliasing = true


func _draw() -> void:
	_track.bg_color = UiTokens.SETTINGS_SWITCH_OFF.lerp(UiTokens.SUCCESS, _amount)
	draw_style_box(_track, Rect2(Vector2.ZERO, size))
	var knob := float(UiTokens.SETTINGS_SWITCH_KNOB)
	var margin := (size.y - knob) * 0.5
	var travel := size.x - knob - margin * 2.0
	var center := Vector2(margin + knob * 0.5 + travel * _amount, size.y * 0.5)
	draw_circle(center, knob * 0.5, UiTokens.SETTINGS_SWITCH_KNOB_COLOR, true, -1.0, true)


func is_on() -> bool:
	return _on


## Pose l'état ; [param animate] : la pastille glisse (ANIM_MICRO).
func set_on(on: bool, animate: bool = false) -> void:
	var target := 1.0 if on else 0.0
	if on == _on and is_equal_approx(_amount, target):
		return
	_on = on
	if _tween != null:
		_tween.kill()
		_tween = null
	var time := UiTokens.ANIM_MICRO * speed_scale
	if not animate or time <= 0.0 or not is_inside_tree():
		_amount = target
		queue_redraw()
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_amount, _amount, target, time)


func _set_amount(value: float) -> void:
	_amount = value
	queue_redraw()
