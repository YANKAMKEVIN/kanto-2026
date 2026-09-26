extends GutTest
## Scène Npc (jalon 3A §2.3) : placement, apparence (générique si l'apparence n'existe pas),
## orientation vers une case (axe dominant), début et fin d'interaction, réaction,
## interaction stable (même instance).
## Jalon 3B (T3) : GridMover (enter_grid, leave_grid), pas de marche et de course, case
## libérée au départ, step_finished, animations walk_/run_ (ou idle_), _process coupé au
## repos.

const NPC_SCENE := "res://game/world/npc/npc.tscn"
const CELL := Vector2i(5, 5)
const FRAME := 1.0 / 60.0


func _spec(overrides: Dictionary = {}) -> NpcSpec:
	var spec := NpcSpec.new()
	spec.id = &"villager"
	spec.cell = CELL
	spec.facing = Vector2i.DOWN
	spec.sprite = &"villager"
	spec.dialogue = &"villager_talk"
	for key: String in overrides:
		spec.set(key, overrides[key])
	return spec


func _make(spec: NpcSpec) -> Npc:
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	add_child_autofree(npc)
	return npc


func _sprite(npc: Npc) -> AnimatedSprite2D:
	return npc.get_node(^"%Sprite") as AnimatedSprite2D


func test_setup_places_feet_on_cell() -> void:
	var npc := _make(_spec())
	assert_eq(npc.get_cell(), CELL)
	assert_eq(npc.position, Grid.cell_to_world(CELL))
	assert_eq(npc.get_id(), &"villager")
	assert_eq(npc.get_facing(), Vector2i.DOWN)
	assert_false(npc.is_processing(), "_process coupé au repos")


func test_sprite_is_pixel_art_nearest_scaled_twice_feet_on_origin() -> void:
	var sprite := _sprite(_make(_spec()))
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(sprite.scale, Vector2(2, 2))
	var frame := sprite.sprite_frames.get_frame_texture(&"idle_down", 0)
	assert_eq(frame.get_size(), Vector2(32, 64))
	assert_eq(sprite.offset.y + frame.get_size().y / 2.0, 0.0, "pieds sur l'origine")
	assert_eq(sprite.position, Vector2.ZERO)
	assert_true(sprite.is_playing())
	assert_eq(sprite.animation, &"idle_down")


func test_unknown_sprite_falls_back_to_generic_frames() -> void:
	assert_false(Npc.has_frames(&"villager"))
	assert_true(Npc.has_frames(Npc.FALLBACK_SPRITE))
	var sprite := _sprite(_make(_spec()))
	assert_eq(sprite.sprite_frames.resource_path, Npc.frames_path(Npc.FALLBACK_SPRITE))
	for anim: StringName in [&"idle_down", &"idle_up", &"idle_left", &"idle_right"]:
		assert_true(sprite.sprite_frames.has_animation(anim), anim)
		assert_eq(sprite.sprite_frames.get_frame_count(anim), 2, "%s : 2 images" % anim)


func test_initial_facing_from_spec() -> void:
	var npc := _make(_spec({"facing": Vector2i.RIGHT}))
	assert_eq(npc.get_facing(), Vector2i.RIGHT)
	assert_eq(_sprite(npc).animation, &"idle_right")


func test_lift_raises_sprite_without_changing_cell() -> void:
	var npc := _make(_spec({"lift": 56}))
	assert_eq(npc.get_cell(), CELL)
	assert_eq(npc.position, Grid.cell_to_world(CELL))
	assert_eq(_sprite(npc).position.y, -56.0)
	assert_eq((npc.get_node(^"%Shadow") as Node2D).position.y, -6.0 - 56.0)


func test_face_toward_uses_dominant_axis() -> void:
	var npc := _make(_spec())
	var cases: Dictionary[Vector2i, Vector2i] = {
		CELL + Vector2i(3, 1): Vector2i.RIGHT,
		CELL + Vector2i(-2, 1): Vector2i.LEFT,
		CELL + Vector2i(1, -4): Vector2i.UP,
		CELL + Vector2i(0, 1): Vector2i.DOWN,
	}
	for target: Vector2i in cases:
		npc.face(Vector2i.DOWN if cases[target] != Vector2i.DOWN else Vector2i.UP)
		npc.face_toward(target)
		assert_eq(npc.get_facing(), cases[target], "vers %s" % target)
		assert_eq(_sprite(npc).animation, StringName("idle_" + _dir_name(cases[target])))


func test_face_toward_own_cell_does_nothing() -> void:
	var npc := _make(_spec({"facing": Vector2i.LEFT}))
	npc.face_toward(CELL)
	assert_eq(npc.get_facing(), Vector2i.LEFT)


func test_face_ignores_non_cardinal() -> void:
	var npc := _make(_spec())
	npc.face(Vector2i(1, 1))
	npc.face(Vector2i.ZERO)
	assert_eq(npc.get_facing(), Vector2i.DOWN)


func test_begin_interaction_turns_to_player_then_end_restores_facing() -> void:
	var npc := _make(_spec({"facing": Vector2i.UP}))
	npc.begin_interaction(CELL + Vector2i.LEFT)
	assert_eq(npc.get_facing(), Vector2i.LEFT)
	npc.end_interaction()
	assert_eq(npc.get_facing(), Vector2i.UP, "retourne à ses affaires")


func test_without_turn_to_player_begin_keeps_facing() -> void:
	var npc := _make(_spec({"facing": Vector2i.RIGHT, "turn_to_player": false}))
	npc.begin_interaction(CELL + Vector2i.DOWN)
	assert_eq(npc.get_facing(), Vector2i.RIGHT)
	# Une page face_player le tourne ; à la fin, il reprend son orientation.
	npc.face_toward(CELL + Vector2i.DOWN)
	assert_eq(npc.get_facing(), Vector2i.DOWN)
	npc.end_interaction()
	assert_eq(npc.get_facing(), Vector2i.RIGHT)


func test_keep_facing_keeps_orientation_after_interaction() -> void:
	var npc := _make(_spec({"facing": Vector2i.UP, "keep_facing": true}))
	npc.begin_interaction(CELL + Vector2i.RIGHT)
	npc.end_interaction()
	assert_eq(npc.get_facing(), Vector2i.RIGHT)


func test_get_interaction_is_same_instance_with_source_and_verb() -> void:
	var npc := _make(_spec())
	var first := npc.get_interaction()
	assert_not_null(first)
	assert_same(npc.get_interaction(), first)
	assert_same(first.source, npc)
	assert_eq(first.cell, CELL)
	assert_eq(first.kind, Interaction.Kind.TALK)
	assert_eq(first.dialogue_id, &"villager_talk")
	assert_true(first.accepts(Vector2i.LEFT) and first.accepts(Vector2i.UP), "de tous côtés")


func test_observe_verb_for_pokemon() -> void:
	var npc := _make(_spec({"verb": Interaction.Kind.OBSERVE}))
	assert_eq(npc.get_interaction().kind, Interaction.Kind.OBSERVE)


func test_non_interactive_npc_has_no_interaction() -> void:
	var npc := _make(_spec({"dialogue": &""}))
	assert_null(npc.get_interaction())


func test_react_without_react_animation_hops_and_comes_back() -> void:
	var npc := _make(_spec({"lift": 20}))
	var sprite := _sprite(npc)
	assert_false(sprite.sprite_frames.has_animation(Npc.REACT_ANIM))
	npc.react()
	# Point le plus haut du bond, relevé à chaque image jusqu'au retour.
	var highest := sprite.position.y
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < int(Npc.HOP_DURATION * 1000.0) + 200:
		await get_tree().process_frame
		highest = minf(highest, sprite.position.y)
	assert_lt(highest, -20.0 - Npc.HOP_HEIGHT / 2.0, "le sprite a bondi (%.1f)" % highest)
	assert_gte(highest, -20.0 - Npc.HOP_HEIGHT, "bond de %d px au plus" % Npc.HOP_HEIGHT)
	assert_eq(sprite.position.y, -20.0, "retour à sa hauteur")
	assert_eq(npc.get_cell(), CELL)
	assert_push_error_count(0)


func test_react_twice_does_not_drift() -> void:
	var npc := _make(_spec())
	npc.react()
	await wait_seconds(0.05)
	npc.react()
	await wait_seconds(Npc.HOP_DURATION + 0.1)
	assert_eq(_sprite(npc).position.y, 0.0)


func test_react_plays_react_animation_when_available() -> void:
	var npc := _make(_spec())
	var sprite := _sprite(npc)
	var frames := sprite.sprite_frames.duplicate() as SpriteFrames
	frames.add_animation(Npc.REACT_ANIM)
	frames.set_animation_loop(Npc.REACT_ANIM, false)
	frames.set_animation_speed(Npc.REACT_ANIM, 20.0)
	frames.add_frame(Npc.REACT_ANIM, frames.get_frame_texture(&"idle_down", 0))
	sprite.sprite_frames = frames
	npc.react()
	assert_eq(sprite.animation, Npc.REACT_ANIM)
	await wait_seconds(0.3)
	assert_eq(sprite.animation, &"idle_down", "retour à l'attente")


func test_react_prefers_the_animation_of_its_facing() -> void:
	var npc := _make(_spec({"facing": Vector2i.RIGHT}))
	var sprite := _sprite(npc)
	var frames := sprite.sprite_frames.duplicate() as SpriteFrames
	for anim: StringName in [Npc.REACT_ANIM, &"react_right"]:
		frames.add_animation(anim)
		frames.set_animation_loop(anim, false)
		frames.set_animation_speed(anim, 20.0)
		frames.add_frame(anim, frames.get_frame_texture(&"idle_right", 0))
	sprite.sprite_frames = frames
	npc.react()
	assert_eq(sprite.animation, &"react_right", "réaction dans son orientation")
	await wait_seconds(0.3)
	assert_eq(sprite.animation, &"idle_right", "retour à l'attente, même orientation")


# --- Marche (jalon 3B, T3) --------------------------------------------------------------

## PNJ inscrit sur une grille 10 × 10 ; ses images sont simulées à la main.
func _make_on_grid(spec: NpcSpec, grid: GridWorld) -> Npc:
	var npc := _make(spec)
	assert_true(npc.enter_grid(grid), "enter_grid")
	return npc


## Simule [param frames] images du PNJ (le moteur ne le fait pas tourner en parallèle).
func _simulate(npc: Npc, frames: int) -> void:
	npc.set_process(false)
	for i: int in frames:
		if not npc.is_moving():
			return
		npc._process(FRAME)


func test_enter_grid_occupies_its_cell() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"facing": Vector2i.LEFT}), grid)
	assert_same(grid.get_occupant(CELL), npc)
	assert_eq(npc.get_cell(), CELL)
	assert_eq(npc.get_facing(), Vector2i.LEFT)
	assert_false(npc.is_moving())
	assert_false(npc.is_processing(), "_process coupé au repos")


func test_enter_grid_on_a_taken_or_outside_cell_fails() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var blocker := RefCounted.new()
	grid.occupy(CELL, blocker)
	var npc := _make(_spec())
	assert_false(npc.enter_grid(grid))
	assert_same(grid.get_occupant(CELL), blocker)
	assert_false(npc.step(Vector2i.RIGHT), "hors grille : pas de pas")
	var outside := _make(_spec({"id": &"far", "cell": Vector2i(20, 20)}))
	assert_false(outside.enter_grid(grid))


func test_walk_step_takes_walk_duration_and_frees_the_old_cell_at_once() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	watch_signals(npc)
	var target := CELL + Vector2i.RIGHT
	assert_true(npc.step(Vector2i.RIGHT))
	assert_true(npc.is_moving())
	assert_true(npc.is_processing(), "_process pendant le pas")
	assert_eq(npc.get_facing(), Vector2i.RIGHT)
	assert_false(grid.is_occupied(CELL), "case quittée libérée dès le départ")
	assert_same(grid.get_occupant(target), npc, "case visée réservée")
	assert_eq(npc.get_cell(), CELL, "case de départ pendant le pas")
	var frames := int(Grid.WALK_STEP_DURATION / FRAME)
	_simulate(npc, frames - 1)
	assert_true(npc.is_moving(), "encore en marche avant %.2f s" % Grid.WALK_STEP_DURATION)
	assert_gt(npc.position.x, Grid.cell_to_world(CELL).x, "position interpolée")
	_simulate(npc, 3)
	assert_false(npc.is_moving())
	assert_eq(npc.get_cell(), target)
	assert_eq(npc.position, Grid.cell_to_world(target))
	assert_signal_emitted_with_parameters(npc, "step_finished", [target])
	assert_eq(npc.get_interaction().cell, target, "interaction à jour")
	assert_false(npc.is_processing(), "_process coupé à l'arrêt")


func test_run_step_takes_run_duration() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	assert_true(npc.step(Vector2i.UP, true))
	var frames := int(Grid.RUN_STEP_DURATION / FRAME)
	_simulate(npc, frames - 1)
	assert_true(npc.is_moving())
	_simulate(npc, 3)
	assert_false(npc.is_moving())
	assert_eq(npc.get_cell(), CELL + Vector2i.UP)
	assert_true(Grid.RUN_STEP_DURATION < Grid.WALK_STEP_DURATION)


func test_step_refused_against_an_obstacle_or_during_a_step() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	grid.set_solid(CELL + Vector2i.LEFT)
	var npc := _make_on_grid(_spec(), grid)
	watch_signals(npc)
	assert_false(npc.step(Vector2i.LEFT), "obstacle")
	assert_eq(npc.get_facing(), Vector2i.LEFT, "tourné quand même")
	assert_eq(npc.get_cell(), CELL)
	assert_same(grid.get_occupant(CELL), npc)
	assert_false(npc.is_processing())
	assert_false(npc.step(Vector2i(1, 1)), "direction non cardinale")
	assert_true(npc.step(Vector2i.DOWN))
	assert_false(npc.step(Vector2i.RIGHT), "déjà en marche")
	npc.face(Vector2i.UP)
	assert_eq(npc.get_facing(), Vector2i.DOWN, "pas de pivot pendant un pas")
	_simulate(npc, 30)
	assert_eq(npc.get_cell(), CELL + Vector2i.DOWN)
	assert_signal_emit_count(npc, "step_finished", 1)


func test_walk_and_run_animations_when_the_appearance_has_them() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"sprite": &"oak"}), grid)
	var sprite := _sprite(npc)
	assert_eq(sprite.sprite_frames.resource_path, Npc.frames_path(&"oak"))
	npc.step(Vector2i.RIGHT)
	assert_eq(sprite.animation, &"walk_right")
	assert_true(sprite.is_playing())
	_simulate(npc, 30)
	assert_eq(sprite.animation, &"idle_right", "attente à l'arrêt")
	npc.step(Vector2i.UP, true)
	assert_eq(sprite.animation, &"run_up")
	_simulate(npc, 30)
	assert_eq(sprite.animation, &"idle_up")


func test_without_walk_animation_idle_is_played() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	var sprite := _sprite(npc)
	assert_false(sprite.sprite_frames.has_animation(&"walk_right"))
	npc.step(Vector2i.RIGHT)
	assert_eq(sprite.animation, &"idle_right")
	_simulate(npc, 30)
	assert_push_error_count(0)


func test_get_cell_follows_the_mover_and_face_toward_uses_it() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	npc.step(Vector2i.RIGHT)
	_simulate(npc, 30)
	npc.step(Vector2i.RIGHT)
	_simulate(npc, 30)
	assert_eq(npc.get_cell(), CELL + Vector2i(2, 0))
	assert_eq(npc.get_spec().cell, CELL, "la description ne change pas")
	npc.face_toward(CELL + Vector2i(2, 3))
	assert_eq(npc.get_facing(), Vector2i.DOWN, "depuis sa case courante")


func test_leave_grid_frees_its_cells() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	npc.step(Vector2i.RIGHT)
	npc.leave_grid()
	assert_false(grid.is_occupied(CELL))
	assert_false(grid.is_occupied(CELL + Vector2i.RIGHT))
	assert_false(npc.is_moving())
	assert_false(npc.is_processing())
	assert_eq(npc.get_cell(), CELL)


func test_enter_a_new_grid_keeps_the_current_cell() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	npc.step(Vector2i.DOWN)
	_simulate(npc, 30)
	var rebuilt := GridWorld.new(Vector2i(10, 10))
	assert_true(npc.enter_grid(rebuilt))
	assert_same(rebuilt.get_occupant(CELL + Vector2i.DOWN), npc)
	assert_eq(npc.get_facing(), Vector2i.DOWN)
	assert_true(npc.step(Vector2i.DOWN), "marche sur la nouvelle grille")
	assert_false(rebuilt.is_occupied(CELL + Vector2i.DOWN))


func _dir_name(direction: Vector2i) -> String:
	match direction:
		Vector2i.UP:
			return "up"
		Vector2i.LEFT:
			return "left"
		Vector2i.RIGHT:
			return "right"
	return "down"
