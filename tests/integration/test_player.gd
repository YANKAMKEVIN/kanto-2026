extends GutTest
## Player sur une petite GridWorld : entrées par actions (Input.action_press, comme le
## joystick), marche, course, obstacle, pivot, position à l'arrêt, caméra, blocage des
## entrées pendant une transition (jalon 2 §2.4).

const PLAYER_SCENE := "res://game/player/player.tscn"
const FRAME := 1.0 / 60.0
const START := Vector2i(1, 4)
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run",
]

var _grid: GridWorld
var _player: Player


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(16, 8))
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(_player)
	_player.enter_map(_grid, START, Vector2i.RIGHT, Grid.map_pixel_rect(Vector2i(16, 8)))
	# Les images sont simulées à la main : pas de _process du moteur en parallèle.
	_player.set_process(false)
	watch_signals(_player)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


func _simulate(seconds: float) -> void:
	var frames := roundi(seconds / FRAME)
	for i: int in frames:
		_player._process(FRAME)


## Relâche tout et laisse finir le pas en cours.
func _settle() -> void:
	after_each()
	_simulate(0.5)


func test_enter_map_places_player_facing_and_occupation() -> void:
	assert_eq(_player.get_cell(), START)
	assert_eq(_player.get_facing(), Vector2i.RIGHT)
	assert_eq(_player.position, Grid.cell_to_world(START))
	assert_eq(_grid.get_occupant(START), _player)


func test_enter_map_again_releases_previous_cell() -> void:
	_player.enter_map(_grid, Vector2i(5, 5), Vector2i.UP, Grid.map_pixel_rect(Vector2i(16, 8)))
	assert_false(_grid.is_occupied(START))
	assert_eq(_grid.get_occupant(Vector2i(5, 5)), _player)
	assert_eq(_player.get_facing(), Vector2i.UP)


func test_move_right_for_quarter_second_moves_one_cell() -> void:
	Input.action_press(&"move_right")
	_simulate(0.25)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT)
	assert_signal_emitted_with_parameters(_player, "moved", [START + Vector2i.RIGHT])


func test_tap_right_moves_exactly_one_cell_then_stops() -> void:
	Input.action_press(&"move_right")
	_simulate(0.1)
	_settle()
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT)
	assert_false(_player.is_moving())


func test_holding_one_second_chains_at_least_four_cells() -> void:
	Input.action_press(&"move_right")
	_simulate(1.0)
	var walked := _player.get_cell().x - START.x
	assert_true(walked >= 4, "%d cases en 1 s" % walked)
	assert_true(_player.is_moving(), "enchaînement sans pause")


func test_running_one_second_covers_at_least_eight_cells() -> void:
	Input.action_press(&"run")
	Input.action_press(&"move_right")
	_simulate(1.0)
	var ran := _player.get_cell().x - START.x
	assert_true(ran >= 8, "%d cases en 1 s de course" % ran)
	assert_true(_player.is_running())


func test_obstacle_stops_player_and_emits_bumped() -> void:
	_grid.set_solid(START + Vector2i.RIGHT)
	Input.action_press(&"move_right")
	_simulate(0.5)
	assert_eq(_player.get_cell(), START)
	assert_false(_player.is_moving())
	assert_signal_emitted_with_parameters(_player, "bumped", [Vector2i.RIGHT])
	assert_signal_emit_count(_player, "bumped", 1)
	assert_eq(_player.position, Grid.cell_to_world(START))


func test_walking_into_obstacle_after_steps_stops_before_it() -> void:
	_grid.set_solid(Vector2i(4, 4))
	Input.action_press(&"move_right")
	_simulate(1.5)
	assert_eq(_player.get_cell(), Vector2i(3, 4))
	assert_signal_emitted(_player, "bumped")


func test_short_press_other_direction_only_turns() -> void:
	Input.action_press(&"move_up")
	_simulate(0.05)
	_settle()
	assert_eq(_player.get_cell(), START)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_signal_emitted_with_parameters(_player, "facing_changed", [Vector2i.UP])
	assert_signal_not_emitted(_player, "moved")


func test_position_matches_cell_when_idle() -> void:
	Input.action_press(&"move_right")
	_simulate(0.6)
	_settle()
	assert_false(_player.is_moving())
	assert_eq(_player.position, Grid.cell_to_world(_player.get_cell()))
	assert_ne(_player.get_cell(), START)


func test_position_is_rounded_during_step() -> void:
	Input.action_press(&"move_right")
	_simulate(0.1)
	assert_eq(_player.position, _player.position.round())
	assert_true(_player.position.x > Grid.cell_to_world(START).x)


func test_animation_follows_state() -> void:
	var sprite := _player.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.animation, &"idle_right")
	Input.action_press(&"move_right")
	_simulate(0.05)
	assert_eq(sprite.animation, &"walk_right")
	Input.action_press(&"run")
	_simulate(0.3)
	assert_eq(sprite.animation, &"run_right")
	_settle()
	assert_eq(sprite.animation, &"idle_right")


func test_sprite_is_pixel_art_nearest_scaled_twice() -> void:
	var sprite := _player.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(sprite.scale, Vector2(2, 2))
	var frame := sprite.sprite_frames.get_frame_texture(&"idle_down", 0)
	assert_eq(frame.get_size(), Vector2(32, 64))
	# Pieds sur l'origine : bas du cadre (offset + moitié de la hauteur) à y = 0.
	assert_eq(sprite.offset.y + frame.get_size().y / 2.0, 0.0)


func test_camera_zoom_one_and_limits_from_bounds() -> void:
	_player.enter_map(_grid, START, Vector2i.DOWN, Grid.map_pixel_rect(Vector2i(48, 34)))
	var camera := _player.get_camera()
	assert_eq(camera.zoom, Vector2.ONE)
	assert_eq(camera.limit_left, 0)
	assert_eq(camera.limit_top, 0)
	assert_eq(camera.limit_right, 4608)
	assert_eq(camera.limit_bottom, 3264)
	assert_false(camera.position_smoothing_enabled)


# --- Blocage des entrées (jalon 2 §2.4) -----------------------------------------

func test_input_enabled_by_default() -> void:
	assert_true(_player.is_input_enabled())


func test_lock_during_step_finishes_it_and_starts_no_other() -> void:
	Input.action_press(&"move_right")
	_simulate(0.1)
	assert_true(_player.is_moving(), "pas en cours")
	_player.set_input_enabled(false)
	assert_false(_player.is_input_enabled())
	_simulate(1.0)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT, "le pas en cours se termine")
	assert_false(_player.is_moving())
	assert_signal_emit_count(_player, "moved", 1)
	assert_signal_not_emitted(_player, "bumped")
	assert_eq(_player.position, Grid.cell_to_world(START + Vector2i.RIGHT))
	var sprite := _player.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.animation, &"idle_right")


func test_locked_player_ignores_obstacle_turn_and_run() -> void:
	_grid.set_solid(START + Vector2i.RIGHT)
	_player.set_input_enabled(false)
	Input.action_press(&"run")
	Input.action_press(&"move_right")
	_simulate(0.5)
	Input.action_release(&"move_right")
	Input.action_press(&"move_up")
	_simulate(0.5)
	assert_eq(_player.get_cell(), START)
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "ni pivot")
	assert_signal_not_emitted(_player, "bumped")
	assert_signal_not_emitted(_player, "facing_changed")
	assert_false(_player.is_running())


func test_lock_from_moved_handler_prevents_chained_step() -> void:
	# Comme le routeur de scènes sur une porte : verrou posé dans le signal moved.
	_player.moved.connect(func(_cell: Vector2i) -> void: _player.set_input_enabled(false))
	Input.action_press(&"move_right")
	_simulate(1.0)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT)
	assert_false(_player.is_moving())
	assert_false(_grid.is_occupied(START + Vector2i.RIGHT * 2), "case au-delà libre")


func test_lock_survives_enter_map() -> void:
	_player.set_input_enabled(false)
	_player.enter_map(_grid, Vector2i(5, 5), Vector2i.UP, Grid.map_pixel_rect(Vector2i(16, 8)))
	assert_false(_player.is_input_enabled())
	Input.action_press(&"move_up")
	_simulate(0.5)
	assert_eq(_player.get_cell(), Vector2i(5, 5))
	assert_signal_not_emitted(_player, "moved")


func test_unlocked_player_moves_again() -> void:
	_player.set_input_enabled(false)
	_player.enter_map(_grid, Vector2i(5, 5), Vector2i.UP, Grid.map_pixel_rect(Vector2i(16, 8)))
	Input.action_press(&"move_up")
	_simulate(0.3)
	assert_eq(_player.get_cell(), Vector2i(5, 5))
	_player.set_input_enabled(true)
	assert_true(_player.is_input_enabled())
	_simulate(0.3)
	assert_eq(_player.get_cell(), Vector2i(5, 4))
	assert_signal_emitted_with_parameters(_player, "moved", [Vector2i(5, 4)])


# --- Blocage par raisons (jalon 3A §2.8) -------------------------------------------

func test_two_reasons_block_until_both_released() -> void:
	_player.set_input_enabled(false, &"transition")
	_player.set_input_enabled(false, &"dialogue")
	assert_false(_player.is_input_enabled())
	_player.set_input_enabled(true, &"dialogue")
	assert_false(_player.is_input_enabled(), "la transition bloque encore")
	assert_true(_player.is_blocked_by(&"transition"))
	assert_false(_player.is_blocked_by(&"dialogue"))
	Input.action_press(&"move_right")
	_simulate(0.5)
	assert_eq(_player.get_cell(), START, "toujours bloqué")
	_player.set_input_enabled(true, &"transition")
	assert_true(_player.is_input_enabled())
	_simulate(0.3)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT, "libre : il avance")


func test_dialogue_released_first_or_last_gives_same_result() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_player.set_input_enabled(false)
	_player.set_input_enabled(true)
	assert_false(_player.is_input_enabled(), "le dialogue bloque encore")
	_player.set_input_enabled(true, &"dialogue")
	assert_true(_player.is_input_enabled())


func test_same_reason_does_not_stack() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_player.set_input_enabled(false, &"dialogue")
	_player.set_input_enabled(true, &"dialogue")
	assert_true(_player.is_input_enabled())


func test_default_reason_is_transition() -> void:
	_player.set_input_enabled(false)
	assert_true(_player.is_blocked_by(&"transition"))
	_player.set_input_enabled(true, &"transition")
	assert_true(_player.is_input_enabled())


func test_releasing_unknown_reason_keeps_block() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_player.set_input_enabled(true, &"cutscene")
	assert_false(_player.is_input_enabled())


func test_reasons_survive_enter_map() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_player.enter_map(_grid, Vector2i(5, 5), Vector2i.UP, Grid.map_pixel_rect(Vector2i(16, 8)))
	Input.action_press(&"move_up")
	_simulate(0.5)
	assert_eq(_player.get_cell(), Vector2i(5, 5))
	_player.set_input_enabled(true, &"dialogue")
	_simulate(0.3)
	assert_eq(_player.get_cell(), Vector2i(5, 4))


# --- Pivot scripté (jalon 3A §2.8) --------------------------------------------------

func test_face_at_rest_turns_without_step() -> void:
	_player.face(Vector2i.LEFT)
	assert_eq(_player.get_facing(), Vector2i.LEFT)
	assert_eq(_player.get_cell(), START)
	assert_false(_player.is_moving())
	assert_signal_emitted_with_parameters(_player, "facing_changed", [Vector2i.LEFT])
	assert_signal_not_emitted(_player, "moved")
	var sprite := _player.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.animation, &"idle_left")
	_simulate(0.5)
	assert_eq(_player.get_cell(), START, "aucun pas ensuite")


func test_face_works_while_blocked() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_player.face(Vector2i.UP)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_signal_emitted_with_parameters(_player, "facing_changed", [Vector2i.UP])


func test_face_during_step_does_nothing() -> void:
	Input.action_press(&"move_right")
	_simulate(0.1)
	assert_true(_player.is_moving())
	_player.face(Vector2i.LEFT)
	assert_eq(_player.get_facing(), Vector2i.RIGHT)
	assert_signal_not_emitted(_player, "facing_changed")
	_simulate(0.2)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT, "le pas continue")


func test_face_same_direction_or_invalid_emits_nothing() -> void:
	_player.face(Vector2i.RIGHT)
	_player.face(Vector2i(1, 1))
	_player.face(Vector2i.ZERO)
	assert_eq(_player.get_facing(), Vector2i.RIGHT)
	assert_signal_not_emitted(_player, "facing_changed")


# --- Pas scripté (jalon 3B §2.5, T3) ------------------------------------------------------

func test_script_step_moves_one_cell_while_blocked_for_a_cutscene() -> void:
	_player.set_input_enabled(false, &"cutscene")
	assert_true(_player.script_step(Vector2i.UP))
	assert_true(_player.is_moving())
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_false(_grid.is_occupied(START), "case quittée libérée dès le départ")
	_simulate(0.3)
	assert_eq(_player.get_cell(), START + Vector2i.UP)
	assert_false(_player.is_moving(), "aucun pas de plus, joueur bloqué")
	assert_signal_emitted_with_parameters(_player, "moved", [START + Vector2i.UP])
	assert_true(_player.is_blocked_by(&"cutscene"), "toujours bloqué")
	_player.set_input_enabled(true, &"cutscene")


func test_script_step_run_uses_run_animation_and_duration() -> void:
	_player.set_input_enabled(false, &"cutscene")
	assert_true(_player.script_step(Vector2i.RIGHT, true))
	assert_true(_player.is_running())
	_simulate(FRAME)
	var sprite := _player.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.animation, &"run_right")
	_simulate(Grid.RUN_STEP_DURATION + 2 * FRAME)
	assert_eq(_player.get_cell(), START + Vector2i.RIGHT)
	assert_false(_player.is_moving())
	_player.set_input_enabled(true, &"cutscene")


func test_script_step_refused_during_a_step_or_against_an_obstacle() -> void:
	_grid.set_solid(START + Vector2i.DOWN)
	assert_false(_player.script_step(Vector2i.DOWN), "obstacle")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "tourné quand même")
	assert_signal_not_emitted(_player, "bumped")
	assert_false(_player.script_step(Vector2i(1, 1)))
	assert_true(_player.script_step(Vector2i.UP))
	assert_false(_player.script_step(Vector2i.RIGHT), "déjà en marche")
	_simulate(0.3)
	assert_eq(_player.get_cell(), START + Vector2i.UP)
	assert_signal_emit_count(_player, "moved", 1)
