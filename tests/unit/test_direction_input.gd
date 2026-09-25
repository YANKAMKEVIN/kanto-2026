extends GutTest
## DirectionInput : priorité à la dernière direction pressée, quantification du joystick.

var _input: DirectionInput


func before_each() -> void:
	_input = DirectionInput.new()


func test_nothing_held_gives_zero() -> void:
	assert_eq(_input.update(false, false, false, false), Vector2i.ZERO)


func test_single_direction() -> void:
	assert_eq(_input.update(true, false, false, false), Vector2i.UP)
	assert_eq(_input.update(false, true, false, false), Vector2i.DOWN)
	assert_eq(_input.update(false, false, true, false), Vector2i.LEFT)
	assert_eq(_input.update(false, false, false, true), Vector2i.RIGHT)


func test_last_pressed_wins_and_previous_resumes() -> void:
	_input.update(true, false, false, false)
	assert_eq(_input.update(true, false, false, true), Vector2i.RIGHT)
	assert_eq(_input.update(true, false, false, false), Vector2i.UP)
	assert_eq(_input.update(false, false, false, false), Vector2i.ZERO)


func test_holding_keeps_first_direction_until_new_press() -> void:
	_input.update(false, false, true, false)
	assert_eq(_input.update(false, false, true, false), Vector2i.LEFT)
	assert_eq(_input.update(false, true, true, false), Vector2i.DOWN)
	assert_eq(_input.update(false, true, true, false), Vector2i.DOWN)


func test_simultaneous_press_gives_one_cardinal_direction() -> void:
	var direction := _input.update(true, false, false, true)
	assert_true(Grid.is_cardinal(direction))


func test_reset() -> void:
	_input.update(true, false, false, false)
	_input.reset()
	assert_eq(_input.get_direction(), Vector2i.ZERO)


func test_quantize_deadzone() -> void:
	assert_eq(DirectionInput.quantize(Vector2(0.1, 0.1)), Vector2i.ZERO)
	assert_eq(DirectionInput.quantize(Vector2.ZERO), Vector2i.ZERO)


func test_quantize_main_axes() -> void:
	assert_eq(DirectionInput.quantize(Vector2(1, 0)), Vector2i.RIGHT)
	assert_eq(DirectionInput.quantize(Vector2(-1, 0)), Vector2i.LEFT)
	assert_eq(DirectionInput.quantize(Vector2(0, -1)), Vector2i.UP)
	assert_eq(DirectionInput.quantize(Vector2(0, 1)), Vector2i.DOWN)
	assert_eq(DirectionInput.quantize(Vector2(0.8, -0.3)), Vector2i.RIGHT)


func test_quantize_hysteresis_keeps_previous_axis_near_diagonal() -> void:
	var near_diagonal := Vector2(0.6, 0.55)
	assert_eq(DirectionInput.quantize(near_diagonal), Vector2i.RIGHT)
	assert_eq(DirectionInput.quantize(near_diagonal, Vector2i.DOWN), Vector2i.DOWN)
	assert_eq(DirectionInput.quantize(Vector2(0.55, 0.6), Vector2i.RIGHT), Vector2i.RIGHT)


func test_quantize_switches_axis_when_clearly_dominant() -> void:
	assert_eq(DirectionInput.quantize(Vector2(0.9, 0.3), Vector2i.DOWN), Vector2i.RIGHT)
	assert_eq(DirectionInput.quantize(Vector2(0.2, -0.9), Vector2i.RIGHT), Vector2i.UP)
