extends GutTest
## Joystick tactile (TouchJoystick, scène virtual_joystick.tscn) et bouton courir :
## événements tactiles injectés dans le viewport, effets lus sur l'InputMap.

const JOYSTICK_SCENE := "res://game/ui/components/virtual_joystick.tscn"
const RUN_SCENE := "res://game/ui/components/run_button.tscn"
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

var _joystick: TouchJoystick
## Point de départ du pouce : au quart de la largeur, à mi-hauteur (moitié gauche).
var _origin: Vector2
var _width: float


func before_each() -> void:
	_joystick = (load(JOYSTICK_SCENE) as PackedScene).instantiate() as TouchJoystick
	add_child_autofree(_joystick)
	var rect := _joystick.get_viewport_rect()
	_width = rect.size.x
	_origin = rect.position + Vector2(rect.size.x * 0.25, rect.size.y * 0.5)


func after_each() -> void:
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
	Input.action_release(&"run")


func _touch(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	get_viewport().push_input(event, true)


func _drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	get_viewport().push_input(event, true)


func _pressed_moves() -> Array[StringName]:
	var pressed: Array[StringName] = []
	for action: StringName in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			pressed.append(action)
	return pressed


## Pose le doigt 0 et le fait glisser de [param offset].
func _swipe(offset: Vector2) -> void:
	_touch(0, _origin, true)
	_drag(0, _origin + offset)


func _right_half_point() -> Vector2:
	return Vector2(_width * 0.75, _origin.y)


func test_invisible_and_idle_at_rest() -> void:
	assert_false(_joystick.is_active())
	assert_eq(_joystick.modulate.a, 0.0)
	assert_eq(_joystick.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(_pressed_moves(), [] as Array[StringName])


func test_touch_in_left_half_appears_under_thumb() -> void:
	_touch(0, _origin, true)
	assert_true(_joystick.is_active())
	assert_eq(_joystick.get_center(), _origin)
	await wait_seconds(UiTokens.JOYSTICK_FADE_IN + 0.1)
	assert_almost_eq(_joystick.modulate.a, 1.0, 0.01)
	assert_eq(_pressed_moves(), [] as Array[StringName], "toucher sans glisser : immobile")


func test_swipe_right_presses_move_right_only() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL * 0.8, 0.0))
	assert_true(Input.is_action_pressed(&"move_right"))
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])
	assert_eq(_joystick.get_direction(), Vector2i.RIGHT)


func test_each_direction_presses_its_action() -> void:
	var cases := {
		Vector2.UP: &"move_up", Vector2.DOWN: &"move_down",
		Vector2.LEFT: &"move_left", Vector2.RIGHT: &"move_right",
	}
	for dir: Vector2 in cases:
		_swipe(dir * UiTokens.JOYSTICK_TRAVEL)
		assert_eq(_pressed_moves(), [cases[dir]] as Array[StringName], str(dir))
		_touch(0, _origin + dir * UiTokens.JOYSTICK_TRAVEL, false)


func test_changing_direction_keeps_a_single_action() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_drag(0, _origin + Vector2(0.0, -UiTokens.JOYSTICK_TRAVEL))
	assert_eq(_pressed_moves(), [&"move_up"] as Array[StringName])
	_drag(0, _origin + Vector2(-UiTokens.JOYSTICK_TRAVEL, 0.0))
	assert_eq(_pressed_moves(), [&"move_left"] as Array[StringName])


func test_diagonal_presses_a_single_action_with_hysteresis() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	# Diagonale presque parfaite : l'axe horizontal précédent est conservé.
	_drag(0, _origin + Vector2(1.0, -1.1) * UiTokens.JOYSTICK_TRAVEL * 0.6)
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])


func test_small_move_inside_deadzone_does_nothing() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL * 0.2, 0.0))
	assert_eq(_pressed_moves(), [] as Array[StringName])
	_drag(0, _origin + Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_drag(0, _origin + Vector2(UiTokens.JOYSTICK_TRAVEL * 0.1, 0.0))
	assert_eq(_pressed_moves(), [] as Array[StringName], "retour au centre : relâché")


func test_lifting_finger_releases_all_moves_and_fades_out() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_touch(0, _origin + Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0), false)
	assert_eq(_pressed_moves(), [] as Array[StringName])
	assert_false(_joystick.is_active())
	assert_eq(_joystick.get_direction(), Vector2i.ZERO)
	await wait_seconds(UiTokens.JOYSTICK_FADE_OUT + 0.1)
	assert_almost_eq(_joystick.modulate.a, 0.0, 0.001)


func test_canceled_touch_releases_all_moves() -> void:
	_swipe(Vector2(0.0, UiTokens.JOYSTICK_TRAVEL))
	assert_true(Input.is_action_pressed(&"move_down"))
	_touch(0, _origin, false, true)
	assert_eq(_pressed_moves(), [] as Array[StringName])
	assert_false(_joystick.is_active())


func test_focus_out_releases_all_moves() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_joystick.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(_pressed_moves(), [] as Array[StringName])
	assert_false(_joystick.is_active())
	assert_eq(_joystick.modulate.a, 0.0)


func test_application_paused_releases_all_moves() -> void:
	_swipe(Vector2(-UiTokens.JOYSTICK_TRAVEL, 0.0))
	_joystick.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_pressed_moves(), [] as Array[StringName])


func test_exit_tree_releases_all_moves() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	remove_child(_joystick)
	assert_eq(_pressed_moves(), [] as Array[StringName])
	add_child(_joystick)
	assert_false(_joystick.is_active())


func test_hiding_releases_all_moves() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_joystick.hide()
	assert_eq(_pressed_moves(), [] as Array[StringName])


func test_after_release_a_later_drag_is_ignored() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_touch(0, _origin, false)
	_drag(0, _origin + Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	assert_eq(_pressed_moves(), [] as Array[StringName])


func test_touch_in_right_half_is_ignored() -> void:
	var point := _right_half_point()
	_touch(0, point, true)
	_drag(0, point + Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	assert_false(_joystick.is_active())
	assert_eq(_pressed_moves(), [] as Array[StringName])


func test_second_finger_in_right_half_does_not_disturb() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	var point := _right_half_point()
	_touch(1, point, true)
	_drag(1, point + Vector2(0.0, -UiTokens.JOYSTICK_TRAVEL))
	_touch(1, point, false)
	assert_true(_joystick.is_active())
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])
	assert_eq(_joystick.get_center(), _origin)


func test_second_finger_in_left_half_is_ignored() -> void:
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	var other := _origin + Vector2(0.0, 200.0)
	_touch(1, other, true)
	_drag(1, other + Vector2(0.0, UiTokens.JOYSTICK_TRAVEL))
	assert_eq(_joystick.get_center(), _origin)
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])
	_touch(1, other, false)
	assert_true(_joystick.is_active(), "lever l'autre doigt ne relâche pas le joystick")


func test_mouse_events_are_ignored() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = _origin
	click.pressed = true
	get_viewport().push_input(click, true)
	var motion := InputEventMouseMotion.new()
	motion.position = _origin + Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	assert_false(_joystick.is_active())
	assert_eq(_pressed_moves(), [] as Array[StringName])
	click.pressed = false
	get_viewport().push_input(click, true)


func test_direction_changed_signal() -> void:
	watch_signals(_joystick)
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_touch(0, _origin, false)
	assert_signal_emit_count(_joystick, "direction_changed", 2)
	assert_signal_emitted_with_parameters(_joystick, "direction_changed", [Vector2i.ZERO])


# --- Bouton courir ------------------------------------------------------------------------


func _make_run_button() -> TouchScreenButton:
	var button := (load(RUN_SCENE) as PackedScene).instantiate() as TouchScreenButton
	button.position = _right_half_point()
	add_child_autofree(button)
	return button


func test_run_button_setup() -> void:
	var button := _make_run_button()
	assert_eq(button.action, "run")
	assert_eq(button.visibility_mode, TouchScreenButton.VISIBILITY_ALWAYS)
	var shape := button.shape as CircleShape2D
	assert_not_null(shape)
	assert_eq(shape.radius * 2.0, float(UiTokens.ROUND_BUTTON))
	assert_true(UiTokens.ROUND_BUTTON >= UiTokens.TOUCH_MIN)


func test_run_button_held_presses_run() -> void:
	var button := _make_run_button()
	var visual := button.get_node(^"Visual") as RoundButtonVisual
	_touch(3, button.position, true)
	assert_true(Input.is_action_pressed(&"run"))
	assert_true(visual.is_pressed())
	_touch(3, button.position, false)
	assert_false(Input.is_action_pressed(&"run"))
	assert_false(visual.is_pressed())


func test_run_button_touch_outside_circle_ignored() -> void:
	var button := _make_run_button()
	var outside := button.position + Vector2(UiTokens.ROUND_BUTTON * 0.6, 0.0)
	_touch(3, outside, true)
	assert_false(Input.is_action_pressed(&"run"))
	_touch(3, outside, false)


func test_run_button_and_joystick_together() -> void:
	var button := _make_run_button()
	_swipe(Vector2(UiTokens.JOYSTICK_TRAVEL, 0.0))
	_touch(1, button.position, true)
	assert_true(Input.is_action_pressed(&"run"))
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])
	_touch(1, button.position, false)
	assert_false(Input.is_action_pressed(&"run"))
	assert_eq(_pressed_moves(), [&"move_right"] as Array[StringName])
