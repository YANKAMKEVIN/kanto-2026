class_name TouchFinger
extends RefCounted
## Doigt simulé pour les tests d'écrans qui défilent : pousse dans le viewport **ce que le
## téléphone envoie**, un toucher (`InputEventScreenTouch` / `ScreenDrag`) et la souris émulée
## (`InputEventMouseButton` / `MouseMotion`), dans l'ordre réel. Positions en coordonnées du
## viewport (les tests posent leurs écrans dans un SubViewport 2340×1080 sans transformation).

var viewport: Viewport
var position: Vector2 = Vector2.ZERO
var down: bool = false


func _init(target: Viewport) -> void:
	viewport = target


func press(at: Vector2) -> void:
	position = at
	down = true
	_touch(true)
	_mouse_button(true)


## Déplace le doigt en [param steps] petits pas jusqu'à [param to].
func move_to(to: Vector2, steps: int = 10) -> void:
	var from := position
	for i: int in range(1, steps + 1):
		var next := from.lerp(to, float(i) / float(steps))
		var relative := next - position
		position = next
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = position
		drag.relative = relative
		viewport.push_input(drag, true)
		var motion := InputEventMouseMotion.new()
		motion.position = position
		motion.global_position = position
		motion.relative = relative
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(motion, true)


func release() -> void:
	down = false
	_touch(false)
	_mouse_button(false)


## Toucher court et immobile.
func tap(at: Vector2) -> void:
	press(at)
	release()


## Glisser de [param delta] depuis [param at], puis relâcher.
func swipe(at: Vector2, delta: Vector2) -> void:
	press(at)
	move_to(at + delta)
	release()


func _touch(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = pressed
	viewport.push_input(event, true)


func _mouse_button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	viewport.push_input(event, true)
