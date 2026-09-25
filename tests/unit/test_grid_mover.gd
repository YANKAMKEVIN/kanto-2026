extends GutTest
## GridMover : pivot, marche, course, enchaînement, obstacles, rebords, occupation.

const START := Vector2i(5, 5)
const FRAME := 0.016

var _world: GridWorld
var _entity: RefCounted
var _mover: GridMover


func before_each() -> void:
	_world = GridWorld.new(Vector2i(10, 10))
	_entity = RefCounted.new()
	_mover = GridMover.new(_world, _entity)
	assert_true(_mover.place(START, Vector2i.DOWN))
	watch_signals(_mover)


# --- Placement ---------------------------------------------------------------

func test_place_sets_cell_facing_and_occupation() -> void:
	assert_eq(_mover.get_cell(), START)
	assert_eq(_mover.get_facing(), Vector2i.DOWN)
	assert_eq(_mover.get_state(), GridMover.State.IDLE)
	assert_eq(_world.get_occupant(START), _entity)
	assert_eq(_mover.get_world_position(), Grid.cell_to_world(START))


func test_place_moves_occupation() -> void:
	assert_true(_mover.place(Vector2i(1, 1), Vector2i.UP))
	assert_false(_world.is_occupied(START))
	assert_eq(_world.get_occupant(Vector2i(1, 1)), _entity)
	assert_eq(_mover.get_facing(), Vector2i.UP)


func test_place_fails_out_of_bounds_or_on_other_entity() -> void:
	assert_false(_mover.place(Vector2i(-1, 0)))
	var other := RefCounted.new()
	_world.occupy(Vector2i(2, 2), other)
	assert_false(_mover.place(Vector2i(2, 2)))
	assert_eq(_mover.get_cell(), START)


func test_place_cancels_current_step() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_true(_mover.is_moving())
	_mover.place(Vector2i(1, 1))
	assert_false(_mover.is_moving())
	assert_false(_world.is_occupied(START + Vector2i.DOWN))
	assert_eq(_mover.get_world_position(), Grid.cell_to_world(Vector2i(1, 1)))


func test_mover_without_entity_does_not_occupy() -> void:
	var ghost := GridMover.new(_world)
	assert_true(ghost.place(Vector2i(0, 0)))
	assert_false(_world.is_occupied(Vector2i(0, 0)))


# --- Pivot et départ ---------------------------------------------------------

func test_idle_without_input_stays_put() -> void:
	_mover.update(1.0, Vector2i.ZERO, false)
	assert_eq(_mover.get_cell(), START)
	assert_signal_not_emitted(_mover, "step_started")


func test_pressing_facing_direction_steps_immediately() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_true(_mover.is_moving())
	assert_eq(_mover.get_target_cell(), START + Vector2i.DOWN)
	assert_eq(_mover.get_cell(), START, "la case logique change à la fin du pas")
	assert_signal_emitted_with_parameters(_mover, "step_started",
		[START, START + Vector2i.DOWN, false])


func test_short_tap_in_new_direction_only_turns() -> void:
	_mover.update(0.05, Vector2i.RIGHT, false)
	assert_eq(_mover.get_facing(), Vector2i.RIGHT)
	assert_eq(_mover.get_state(), GridMover.State.TURNING)
	_mover.update(FRAME, Vector2i.ZERO, false)
	assert_eq(_mover.get_state(), GridMover.State.IDLE)
	_mover.update(1.0, Vector2i.ZERO, false)
	assert_eq(_mover.get_cell(), START)
	assert_signal_emitted_with_parameters(_mover, "facing_changed", [Vector2i.RIGHT])
	assert_signal_not_emitted(_mover, "step_started")


func test_holding_new_direction_moves_after_turn_delay() -> void:
	_mover.update(FRAME, Vector2i.RIGHT, false)
	_mover.update(0.05, Vector2i.RIGHT, false)
	assert_false(_mover.is_moving(), "0,05 s < délai de pivot")
	_mover.update(0.05, Vector2i.RIGHT, false)
	assert_true(_mover.is_moving())
	assert_eq(_mover.get_target_cell(), START + Vector2i.RIGHT)


func test_changing_direction_while_turning_restarts_turn() -> void:
	_mover.update(0.08, Vector2i.RIGHT, false)
	_mover.update(0.05, Vector2i.LEFT, false)
	assert_eq(_mover.get_facing(), Vector2i.LEFT)
	_mover.update(0.05, Vector2i.LEFT, false)
	assert_false(_mover.is_moving(), "le délai de pivot repart de zéro")
	_mover.update(0.05, Vector2i.LEFT, false)
	assert_true(_mover.is_moving())
	assert_eq(_mover.get_target_cell(), START + Vector2i.LEFT)


func test_diagonal_input_is_ignored() -> void:
	_mover.update(1.0, Vector2i(1, 1), false)
	assert_eq(_mover.get_state(), GridMover.State.IDLE)
	assert_eq(_mover.get_facing(), Vector2i.DOWN)


# --- Marche, course, enchaînement -------------------------------------------

func test_walk_step_completes_after_walk_duration() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION - 0.01, Vector2i.ZERO, false)
	assert_true(_mover.is_moving())
	_mover.update(0.02, Vector2i.ZERO, false)
	assert_false(_mover.is_moving())
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN)
	assert_signal_emitted_with_parameters(_mover, "step_finished", [START + Vector2i.DOWN])


func test_released_input_finishes_current_step_then_stops() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(1.0, Vector2i.ZERO, false)
	_mover.update(1.0, Vector2i.ZERO, false)
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN)
	assert_signal_emit_count(_mover, "step_started", 1)


func test_run_step_is_faster() -> void:
	_mover.update(FRAME, Vector2i.DOWN, true)
	assert_true(_mover.is_running())
	assert_signal_emitted_with_parameters(_mover, "step_started",
		[START, START + Vector2i.DOWN, true])
	_mover.update(Grid.RUN_STEP_DURATION, Vector2i.ZERO, false)
	assert_false(_mover.is_moving())
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN)


func test_walk_is_not_finished_after_run_duration() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_false(_mover.is_running())
	_mover.update(Grid.RUN_STEP_DURATION, Vector2i.DOWN, false)
	assert_true(_mover.is_moving())
	assert_eq(_mover.get_cell(), START)


func test_holding_direction_chains_steps_without_pause() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION + FRAME, Vector2i.DOWN, false)
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN)
	assert_true(_mover.is_moving(), "le pas suivant démarre dans la même image")
	assert_eq(_mover.get_target_cell(), START + Vector2i.DOWN * 2)
	assert_almost_eq(_mover.get_progress(), FRAME / Grid.WALK_STEP_DURATION, 0.001,
		"le temps restant est reporté sur le pas suivant")
	assert_signal_emit_count(_mover, "step_started", 2)


func test_three_held_steps_take_three_durations() -> void:
	var frames := 0
	while _mover.get_cell() != START + Vector2i.DOWN * 3 and frames < 1000:
		_mover.update(FRAME, Vector2i.DOWN, false)
		frames += 1
	var expected := int(ceil(3.0 * Grid.WALK_STEP_DURATION / FRAME))
	assert_between(frames, expected - 1, expected + 1)


func test_turning_while_moving_has_no_delay() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION, Vector2i.RIGHT, false)
	assert_eq(_mover.get_facing(), Vector2i.RIGHT)
	assert_true(_mover.is_moving())
	assert_eq(_mover.get_target_cell(), START + Vector2i.DOWN + Vector2i.RIGHT)


func test_run_can_start_mid_chain() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION, Vector2i.DOWN, true)
	assert_true(_mover.is_running())


func test_world_position_is_interpolated() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION / 2.0, Vector2i.DOWN, false)
	var from := Grid.cell_to_world(START)
	var to := Grid.cell_to_world(START + Vector2i.DOWN)
	var position := _mover.get_world_position()
	assert_almost_eq(position.x, from.x, 0.01)
	assert_almost_eq(position.y, (from.y + to.y) / 2.0, 0.5)


# --- Obstacles et bords ------------------------------------------------------

func test_blocked_step_keeps_position_and_bumps_once() -> void:
	_world.set_solid(START + Vector2i.DOWN)
	for i: int in 10:
		_mover.update(FRAME, Vector2i.DOWN, false)
	assert_eq(_mover.get_cell(), START)
	assert_eq(_mover.get_state(), GridMover.State.IDLE)
	assert_signal_emit_count(_mover, "bumped", 1)
	assert_signal_emitted_with_parameters(_mover, "bumped", [Vector2i.DOWN])
	assert_signal_not_emitted(_mover, "step_started")


func test_bump_again_after_release() -> void:
	_world.set_solid(START + Vector2i.DOWN)
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(FRAME, Vector2i.ZERO, false)
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_signal_emit_count(_mover, "bumped", 2)


func test_turning_into_wall_turns_then_bumps() -> void:
	_world.set_water(START + Vector2i.LEFT)
	_mover.update(FRAME, Vector2i.LEFT, false)
	assert_signal_not_emitted(_mover, "bumped", "le pivot seul ne cogne pas")
	_mover.update(0.1, Vector2i.LEFT, false)
	assert_eq(_mover.get_facing(), Vector2i.LEFT)
	assert_eq(_mover.get_cell(), START)
	assert_signal_emit_count(_mover, "bumped", 1)


func test_map_edge_blocks() -> void:
	_mover.place(Vector2i(5, 0), Vector2i.UP)
	_mover.update(1.0, Vector2i.UP, false)
	assert_eq(_mover.get_cell(), Vector2i(5, 0))
	assert_signal_emitted(_mover, "bumped")


func test_chain_stops_at_obstacle() -> void:
	_world.set_solid(START + Vector2i.DOWN * 2)
	_mover.update(FRAME, Vector2i.DOWN, false)
	_mover.update(Grid.WALK_STEP_DURATION, Vector2i.DOWN, false)
	assert_false(_mover.is_moving())
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN)
	assert_signal_emit_count(_mover, "bumped", 1)


# --- Occupation --------------------------------------------------------------

func test_target_cell_is_reserved_at_step_start() -> void:
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_eq(_world.get_occupant(START + Vector2i.DOWN), _entity)
	assert_false(_world.is_occupied(START))


func test_other_entity_blocks() -> void:
	var npc := RefCounted.new()
	_world.occupy(START + Vector2i.DOWN, npc)
	_mover.update(FRAME, Vector2i.DOWN, false)
	assert_false(_mover.is_moving())
	assert_signal_emitted(_mover, "bumped")


func test_two_movers_cannot_enter_same_cell() -> void:
	var other_entity := RefCounted.new()
	var other := GridMover.new(_world, other_entity)
	other.place(START + Vector2i(2, 0), Vector2i.LEFT)
	_mover.place(START, Vector2i.RIGHT)
	_mover.update(FRAME, Vector2i.RIGHT, false)
	other.update(FRAME, Vector2i.LEFT, false)
	assert_true(_mover.is_moving())
	assert_false(other.is_moving())
	assert_eq(_world.get_occupant(START + Vector2i.RIGHT), _entity)


# --- Rebords -----------------------------------------------------------------

func test_ledge_jump() -> void:
	_world.set_ledge(START + Vector2i.DOWN, GridWorld.Ledge.DOWN)
	_mover.update(FRAME, Vector2i.DOWN, true)
	assert_true(_mover.is_jumping())
	assert_false(_mover.is_running(), "un saut n'est pas une course")
	assert_eq(_mover.get_target_cell(), START + Vector2i.DOWN * 2)
	_mover.update(Grid.WALK_STEP_DURATION, Vector2i.ZERO, false)
	assert_true(_mover.is_moving(), "le saut dure plus longtemps qu'un pas")
	_mover.update(Grid.LEDGE_JUMP_DURATION, Vector2i.ZERO, false)
	assert_eq(_mover.get_cell(), START + Vector2i.DOWN * 2)
	assert_false(_mover.is_jumping())
