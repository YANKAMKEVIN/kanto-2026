class_name TouchJoystick
extends Control
## Joystick tactile flottant : apparaît sous le pouce posé dans la moitié gauche de
## l'écran, invisible au repos (fondu 200 ms au relâchement).
##
## Il ne connaît pas le joueur : il presse et relâche les actions move_* avec
## Input.action_press / action_release (un seul chemin d'entrée, comme le clavier).
## - Le vecteur du pouce est réduit à 4 directions par DirectionInput.quantize.
## - Une seule action move_* est pressée à la fois.
## - Il suit l'index de son doigt et ignore les autres doigts ainsi que les événements
##   souris (émulés depuis le toucher sur Android). Sur Mac, emulate_touch_from_mouse
##   transforme la souris en toucher : il se teste donc à la souris.
## - Il relâche toujours tout : doigt levé, toucher annulé, perte de focus, mise en
##   pause (application ou arbre), masquage, sortie de l'arbre.
## Le nœud couvre tout l'écran (ancres pleines) et ignore la souris (mouse_filter).
## Nommé TouchJoystick car Godot 4.7 a une classe native VirtualJoystick (analogique,
## deux actions possibles en diagonale : incompatible avec la règle « une seule move_* »).

signal direction_changed(direction: Vector2i)

const NO_FINGER := -1
const MOVE_ACTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up",
	Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left",
	Vector2i.RIGHT: &"move_right",
}

@export var fade_in_duration: float = UiTokens.JOYSTICK_FADE_IN
@export var fade_out_duration: float = UiTokens.JOYSTICK_FADE_OUT

var _finger: int = NO_FINGER
## Centre de l'anneau, en coordonnées du viewport.
var _center := Vector2.ZERO
## Déplacement du pouce normalisé par JOYSTICK_TRAVEL (longueur 0..1).
var _vector := Vector2.ZERO
var _direction := Vector2i.ZERO
var _tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_PAUSED:
			_end(true)
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_end(true)
		NOTIFICATION_EXIT_TREE:
			_end(true)


func _draw() -> void:
	if modulate.a <= 0.0 and _finger == NO_FINGER:
		return
	var center := get_global_transform_with_canvas().affine_inverse() * _center
	var ring_radius := UiTokens.JOYSTICK_RING * 0.5
	draw_circle(center, ring_radius, UiTokens.JOYSTICK_RING_FILL, true, -1.0, true)
	draw_circle(center, ring_radius - UiTokens.JOYSTICK_RING_WIDTH * 0.5,
		UiTokens.JOYSTICK_RING_LINE, false, UiTokens.JOYSTICK_RING_WIDTH, true)
	for dir: Vector2i in MOVE_ACTIONS:
		var color := UiTokens.ACCENT if dir == _direction else UiTokens.JOYSTICK_ARROW
		_draw_arrow(center, Vector2(dir), color)
	var knob := center + _vector * UiTokens.JOYSTICK_TRAVEL
	var knob_radius := UiTokens.JOYSTICK_KNOB * 0.5
	draw_circle(knob, knob_radius, UiTokens.JOYSTICK_KNOB_FILL, true, -1.0, true)
	var line := UiTokens.JOYSTICK_KNOB_LINE_WIDTH
	draw_circle(knob, knob_radius - line * 0.5, UiTokens.JOYSTICK_KNOB_LINE, false, line, true)


## Vrai tant qu'un doigt tient le joystick.
func is_active() -> bool:
	return _finger != NO_FINGER


func get_direction() -> Vector2i:
	return _direction


## Centre de l'anneau (coordonnées du viewport) ; significatif seulement si actif.
func get_center() -> Vector2:
	return _center


## Relâche le joystick et toutes les actions move_* (sans effet s'il est déjà au repos).
func release() -> void:
	_end(true)


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		if _finger != NO_FINGER and touch.index != _finger:
			return
		if _finger == NO_FINGER and not _is_in_zone(touch.position):
			return
		_start(touch.index, touch.position)
	elif touch.index == _finger:
		_end(false)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_drag(drag: InputEventScreenDrag) -> void:
	if drag.index != _finger:
		return
	_update_vector(drag.position)
	get_viewport().set_input_as_handled()


## Zone d'apparition : moitié gauche du viewport.
func _is_in_zone(point: Vector2) -> bool:
	var rect := get_viewport_rect()
	return point.x < rect.position.x + rect.size.x * 0.5


func _start(finger: int, point: Vector2) -> void:
	_finger = finger
	_center = point
	_vector = Vector2.ZERO
	_set_direction(Vector2i.ZERO)
	_fade_to(1.0, fade_in_duration)
	queue_redraw()


func _update_vector(point: Vector2) -> void:
	_vector = ((point - _center) / UiTokens.JOYSTICK_TRAVEL).limit_length(1.0)
	_set_direction(DirectionInput.quantize(_vector, _direction))
	queue_redraw()


## [param immediate] : sans fondu (tout sauf le doigt levé : pause, focus, masquage…).
func _end(immediate: bool) -> void:
	if _finger == NO_FINGER and _direction == Vector2i.ZERO:
		return
	_finger = NO_FINGER
	_vector = Vector2.ZERO
	for action: StringName in MOVE_ACTIONS.values():
		Input.action_release(action)
	if _direction != Vector2i.ZERO:
		_direction = Vector2i.ZERO
		direction_changed.emit(_direction)
	if immediate or not is_inside_tree():
		if _tween != null:
			_tween.kill()
		modulate.a = 0.0
	else:
		_fade_to(0.0, fade_out_duration)
	queue_redraw()


func _set_direction(direction: Vector2i) -> void:
	if direction == _direction:
		return
	if _direction != Vector2i.ZERO:
		Input.action_release(MOVE_ACTIONS[_direction])
	if direction != Vector2i.ZERO:
		Input.action_press(MOVE_ACTIONS[direction])
	_direction = direction
	direction_changed.emit(direction)


func _fade_to(alpha: float, duration: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", alpha, duration)


## Flèche (triangle) pointant vers [param dir], à l'intérieur de l'anneau.
func _draw_arrow(center: Vector2, dir: Vector2, color: Color) -> void:
	var tip_distance := UiTokens.JOYSTICK_RING * 0.5 - UiTokens.JOYSTICK_ARROW_INSET
	var tip := center + dir * tip_distance
	var base := tip - dir * UiTokens.JOYSTICK_ARROW_SIZE
	var side := Vector2(-dir.y, dir.x) * UiTokens.JOYSTICK_ARROW_SIZE
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
