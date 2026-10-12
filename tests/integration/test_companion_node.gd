extends GutTest
## Nœud du compagnon (jalon 11, T20b ; `jalon-11-compagnon.md` §2.4) : planche peinte seule,
## pas glissés à la durée du pas du joueur, saut de rebord en arc, devant de touffe dans les herbes,
## apparition en fin de pas, éclat de Ball (et sa version réduite), bulles « ♪ » / « … », saut de
## joie ; aucun nœud de grille occupé.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const FRAME := 1.0 / 60.0

var _grid: GridWorld
var _companion: Companion


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(12, 12))
	_companion = Companion.new()
	add_child_autofree(_companion)
	_companion.set_grid(_grid)
	assert_true(_companion.set_species(&"pidgey", &"pokemon/pidgey"))
	_companion.place(Vector2i(5, 5), Vector2i.UP)
	_companion.visible = true


func _step(from: Vector2i, to: Vector2i, kind: StringName, pace: StringName,
		appear: bool = false) -> CompanionTrail.Step:
	var step := CompanionTrail.Step.new()
	step.from_cell = from
	step.to_cell = to
	step.kind = kind
	step.pace = pace
	step.appear = appear
	return step


func _run(seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		_companion._process(FRAME)


func test_only_a_painted_sheet_and_at_most_six_nodes() -> void:
	assert_eq(_companion.get_sprite().texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	var other := Companion.new()
	add_child_autofree(other)
	assert_false(other.set_species(&"caterpie", &"pokemon/caterpie"),
		"pas de planche de marche peinte : aucun substitut")
	assert_push_error("planche peinte absente")
	var count := 0
	var stack: Array[Node] = [_companion]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		count += 1
		stack.append_array(node.get_children())
	assert_lte(count, 6, "nœud léger (budget de la forêt)")
	assert_false(_grid.is_occupied(Vector2i(5, 5)), "n'occupe pas la grille")


func test_a_walk_and_a_run_last_the_player_step_durations() -> void:
	_companion.move(_step(Vector2i(5, 5), Vector2i(5, 4), CompanionTrail.WALK,
		CompanionTrail.WALK))
	assert_true(_companion.is_moving())
	assert_eq(_companion.get_facing(), Vector2i.UP)
	assert_true(String(_companion.get_sprite().animation).begins_with("walk_up"))
	_run(Grid.WALK_STEP_DURATION / 2.0)
	assert_true(_companion.is_moving(), "à mi-pas")
	assert_between(_companion.position.y, Grid.cell_to_world(Vector2i(5, 4)).y,
		Grid.cell_to_world(Vector2i(5, 5)).y)
	_run(Grid.WALK_STEP_DURATION / 2.0 + FRAME)
	assert_false(_companion.is_moving())
	assert_eq(_companion.position, Grid.cell_to_world(Vector2i(5, 4)))
	assert_eq(_companion.get_sprite().animation, &"idle_up")
	_companion.move(_step(Vector2i(5, 4), Vector2i(6, 4), CompanionTrail.RUN, CompanionTrail.RUN))
	_run(Grid.RUN_STEP_DURATION + FRAME)
	assert_false(_companion.is_moving(), "course : même durée que le joueur")
	assert_eq(_companion.get_cell(), Vector2i(6, 4))


func test_a_ledge_jump_arcs_over_two_cells() -> void:
	_companion.move(_step(Vector2i(5, 5), Vector2i(5, 7), CompanionTrail.JUMP,
		CompanionTrail.WALK))
	assert_true(_companion.is_jumping())
	_run(Grid.WALK_STEP_DURATION / 2.0)
	assert_lt(_companion.get_sprite().position.y, -20.0, "en l'air")
	_run(Grid.WALK_STEP_DURATION)
	assert_false(_companion.is_jumping())
	assert_almost_eq(_companion.get_sprite().position.y, 0.0, 0.01, "reposé")
	assert_eq(_companion.get_cell(), Vector2i(5, 7))


func test_half_hidden_in_tall_grass_but_not_while_jumping() -> void:
	_grid.set_tall_grass(Vector2i(5, 4))
	_companion.move(_step(Vector2i(5, 5), Vector2i(5, 4), CompanionTrail.WALK,
		CompanionTrail.WALK))
	assert_true(_companion.is_grass_front_visible(), "dès le pas qui entre dans l'herbe")
	_run(0.5)
	assert_true(_companion.is_grass_front_visible())
	_grid.set_tall_grass(Vector2i(5, 6))
	_companion.move(_step(Vector2i(5, 4), Vector2i(5, 6), CompanionTrail.JUMP,
		CompanionTrail.JUMP))
	assert_false(_companion.is_grass_front_visible(), "caché pendant un saut")
	_run(0.5)
	assert_true(_companion.is_grass_front_visible())


func test_appearing_happens_at_the_end_of_the_step_with_a_ball_burst() -> void:
	_companion.visible = false
	var clock := TweenClock.new(get_tree())
	_companion.move(_step(CompanionTrail.NONE, Vector2i(5, 6), CompanionTrail.WALK,
		CompanionTrail.WALK, true))
	assert_false(_companion.visible, "rien pendant le pas")
	_run(Grid.WALK_STEP_DURATION + FRAME)
	assert_true(_companion.visible, "apparaît sur la case quittée")
	assert_eq(_companion.position, Grid.cell_to_world(Vector2i(5, 6)))
	assert_lt(_companion.get_sprite().scale.x, 1.0, "éclat : il grandit depuis la Ball")
	var settled := func() -> bool:
		return _companion.get_sprite().scale.x >= 1.0 \
			and _companion.get_sprite().modulate == Color.WHITE
	var steps := clock.run_until(settled, 2.0)
	assert_between(steps * TweenClock.STEP, Companion.BURST - 0.05, Companion.BURST + 0.05)
	clock.release()


func test_withdraw_shrinks_then_hides_and_reduced_motion_only_fades() -> void:
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var run := func() -> void:
		await _companion.withdraw()
		done[0] = true
	run.call()
	var steps := clock.run_until(func() -> bool: return done[0], 2.0)
	assert_false(_companion.visible)
	assert_between(steps * TweenClock.STEP, Companion.BURST - 0.05, Companion.BURST + 0.05)
	_companion.reduce_motion = true
	done[0] = false
	var out := func() -> void:
		await _companion.appear()
		done[0] = true
	out.call()
	assert_eq(_companion.get_sprite().scale.x, 1.0, "réduit : pas de grossissement")
	steps = clock.run_until(func() -> bool: return done[0], 2.0)
	assert_between(steps * TweenClock.STEP, Companion.BURST_REDUCED - 0.05,
		Companion.BURST_REDUCED + 0.05)
	assert_true(_companion.visible)
	clock.release()


func test_bubbles_and_joy_hop() -> void:
	_companion.show_emote(EmoteBubble.NOTE)
	assert_true(_companion.get_bubble().is_playing())
	assert_eq(_companion.get_bubble().get_icon(), EmoteBubble.ICONS[EmoteBubble.NOTE])
	_companion.show_emote(EmoteBubble.DOTS)
	assert_eq(_companion.get_bubble().get_icon(), EmoteBubble.ICONS[EmoteBubble.DOTS])
	var clock := TweenClock.new(get_tree())
	_companion.hop()
	clock.run_until(func() -> bool: return false, Companion.HOP / 2.0)
	assert_lt(_companion.get_sprite().position.y, -5.0, "petit saut")
	clock.run_until(func() -> bool: return false, Companion.HOP)
	assert_almost_eq(_companion.get_sprite().position.y, 0.0, 0.01)
	clock.release()
