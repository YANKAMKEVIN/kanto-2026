extends GutTest
## Scène Npc (jalon 3A §2.3) : placement, apparence (générique si l'apparence n'existe pas),
## orientation vers une case (axe dominant), début et fin d'interaction, réaction,
## interaction stable (même instance).
## Jalon 3B (T3) : GridMover (enter_grid, leave_grid), pas de marche et de course, case
## libérée au départ, step_finished, animations walk_/run_ (ou idle_), _process coupé au
## repos.
## Jalon 4 (T1) : surcharge d'interaction, élan (lean_toward / settle) et saut depuis un
## meuble (hop_to) dans les styles de NpcSpec.HOP_STYLES.

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


## Attente animée (jalon 7, Jadielle agrandie) : il se tourne tour à tour vers chaque
## orientation, en commençant par celle qui suit son repos ; rien pendant un dialogue.
func test_look_around_turns_through_its_facings_but_not_while_talking() -> void:
	var facings: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
	var npc := _make(_spec({"facing": Vector2i.UP, "look_facings": facings,
		"look_every": NpcSpec.LOOK_EVERY_MIN}))
	assert_true(npc.is_looking_around())
	assert_eq(npc.get_facing(), Vector2i.UP)
	await wait_seconds(NpcSpec.LOOK_EVERY_MIN + 0.1)
	assert_eq(npc.get_facing(), Vector2i.LEFT, "première orientation après le repos")
	await wait_seconds(NpcSpec.LOOK_EVERY_MIN)
	assert_eq(npc.get_facing(), Vector2i.RIGHT)
	npc.begin_interaction(CELL + Vector2i.DOWN)
	await wait_seconds(NpcSpec.LOOK_EVERY_MIN * 2.0 + 0.1)
	assert_eq(npc.get_facing(), Vector2i.DOWN, "tourné vers le joueur tout le dialogue")
	npc.end_interaction()
	assert_eq(npc.get_facing(), Vector2i.UP, "reprend son repos")
	await wait_seconds(NpcSpec.LOOK_EVERY_MIN + 0.1)
	assert_ne(npc.get_facing(), Vector2i.DOWN, "l'attente reprend")


func test_without_look_no_look_loop() -> void:
	var npc := _make(_spec())
	assert_false(npc.is_looking_around())


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
	# Point le plus haut du bond, relevé à chaque pas jusqu'au retour ; temps simulé
	# ([method _step_tween]) : indépendant de la charge de la machine.
	var highest := sprite.position.y
	var steps := 0
	while _step_tween(npc._hop):
		steps += 1
		highest = minf(highest, sprite.position.y)
	_assert_lasts(steps, Npc.HOP_DURATION, "bond de HOP_DURATION")
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


## Fait avancer [param tween] d'un pas de [constant FRAME] à la main (temps simulé : la
## charge de la machine ne change ni la durée mesurée ni les états vus). Faux quand il n'y
## a plus rien à jouer (tween fini ou absent) ; il est mis en pause au premier appel pour
## que le moteur ne le fasse plus avancer en parallèle.
func _step_tween(tween: Tween) -> bool:
	if tween == null or not tween.is_valid():
		return false
	tween.pause()
	return tween.custom_step(FRAME)


## [param steps] pas de [constant FRAME] couvrent [param seconds] au pas près : pas fini
## avant, au plus un pas de plus (le dernier pas déborde de la fin).
func _assert_lasts(steps: int, seconds: float, label: String) -> void:
	assert_between(steps * FRAME, seconds - 0.0001, seconds + FRAME + 0.0001,
		"%s (%d pas)" % [label, steps])


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


# --- Jalon 4 (T1) : surcharge, élan, saut ----------------------------------------------

func test_interaction_override_is_returned_then_cleared() -> void:
	var npc := _make(_spec({"verb": Interaction.Kind.OBSERVE}))
	var own := npc.get_interaction()
	var meet := Interaction.new(Interaction.Kind.MEET, CELL, &"", Vector2i.ZERO, npc)
	npc.set_interaction_override(meet)
	assert_true(npc.has_interaction_override())
	assert_same(npc.get_interaction(), meet, "surcharge renvoyée")
	assert_same(npc.get_interaction(), meet, "même instance à chaque appel")
	assert_true(npc.get_interaction().is_valid())
	npc.clear_interaction_override()
	assert_false(npc.has_interaction_override())
	assert_same(npc.get_interaction(), own, "interaction de la description retrouvée")


func test_interaction_override_follows_the_cell() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	var meet := Interaction.new(Interaction.Kind.MEET, Vector2i.ZERO, &"", Vector2i.ZERO, npc)
	npc.set_interaction_override(meet)
	assert_eq(meet.cell, CELL, "case du PNJ à la pose")
	npc.step(Vector2i.RIGHT)
	_simulate(npc, 30)
	assert_eq(meet.cell, CELL + Vector2i.RIGHT, "suit le pas")


func test_every_hop_style_has_parameters() -> void:
	var styles: Array[StringName] = [&""]
	styles.append_array(NpcSpec.HOP_STYLES)
	for style: StringName in styles:
		assert_true(Npc.HOP_STYLE_PARAMS.has(style), "paramètres du style « %s »" % style)
		var params: Dictionary = Npc.HOP_STYLE_PARAMS.get(style, {})
		for key: String in ["hesitate", "hesitate_px", "windup", "windup_px", "duration",
				"height", "trans", "bounces", "sway", "squash"]:
			assert_true(params.has(key), "« %s » : clé %s" % [style, key])
		assert_gt(float(params.get("duration", 0.0)), 0.0)
		assert_gt(float(params.get("height", 0.0)), 0.0)
		assert_false(params.has("wiggle"), "« %s » : plus de rotation (QA R2)" % style)
		assert_between(float(params.get("squash", 0.0)), 0.0, 0.15,
			"« %s » : compression légère" % style)
	assert_eq(Npc.HOP_STYLE_PARAMS.size(), styles.size(), "aucun style en trop")
	assert_eq(Npc.hop_params(&"unknown"), Npc.HOP_STYLE_PARAMS[&""], "inconnu : défaut")


func test_hop_durations_calm_then_eager_then_playful() -> void:
	assert_gt(Npc.hop_flight_duration(&"calm"), Npc.hop_flight_duration(&"eager"))
	assert_gt(Npc.hop_flight_duration(&"eager"), Npc.hop_flight_duration(&"playful"))
	assert_gt(Npc.hop_total_duration(&"calm"), Npc.hop_total_duration(&"eager"))
	assert_gt(Npc.hop_total_duration(&"eager"), Npc.hop_total_duration(&"playful"))
	assert_almost_eq(Npc.hop_flight_duration(&"", 2), 0.35 * 1.25, 0.001,
		"+25 % par case supplémentaire")


func test_hop_styles_look_different() -> void:
	# Hauteur d'arc : l'enthousiaste saute le plus haut ; hésitation seulement pour le calme,
	# rebonds pour l'enthousiaste et le joueur, dandinement (décalage horizontal) seulement
	# pour le joueur ; l'enthousiaste atterrit le plus lourdement.
	var calm := Npc.hop_params(&"calm")
	var eager := Npc.hop_params(&"eager")
	var playful := Npc.hop_params(&"playful")
	assert_gt(float(eager["height"]), float(playful["height"]))
	assert_gt(float(eager["height"]), float(calm["height"]))
	assert_gt(float(calm["hesitate"]), 0.0)
	assert_eq(float(eager["hesitate"]), 0.0)
	assert_gt(float(eager["windup"]), 0.0)
	assert_eq((calm["bounces"] as Array).size(), 0)
	assert_eq((eager["bounces"] as Array).size(), 1)
	assert_eq((playful["bounces"] as Array).size(), 2)
	assert_gt(float(playful["sway"]), 0.0)
	assert_eq(float(eager["sway"]), 0.0)
	assert_eq(float(calm["sway"]), 0.0)
	assert_gt(float(eager["squash"]), float(playful["squash"]))
	assert_gt(float(playful["squash"]), float(calm["squash"]))


## Saute de la table (lift 56) d'une case vers le bas dans le style [param style] ;
## vérifie la grille au départ et l'état à l'arrivée.
func _check_hop(style: StringName) -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"id": StringName("hop_" + String(style)), "lift": 56,
		"hop_style": style}), grid)
	var meet := Interaction.new(Interaction.Kind.MEET, CELL, &"", Vector2i.ZERO, npc)
	npc.set_interaction_override(meet)
	var target := CELL + Vector2i.DOWN
	watch_signals(npc)
	# Temps simulé (pas de 1/60 s, indépendant de la charge de la machine) ; point le plus
	# haut du sprite ; rotation, décalage horizontal, compression et plan de dessin vus.
	# Relevés pas par pas dans le test lui-même.
	var peak := 0.0
	var rotated := false
	var swayed := false
	var squashed := false
	var raised := false
	var sprite := _sprite(npc)
	assert_true(npc.hop_to(target, grid), "« %s » : saut accepté" % style)
	assert_true(npc.is_hopping())
	assert_false(grid.is_occupied(CELL), "« %s » : case quittée libérée au départ" % style)
	assert_same(grid.get_occupant(target), npc, "« %s » : arrivée réservée" % style)
	assert_eq(npc.get_cell(), CELL, "case de départ pendant le saut")
	assert_eq(npc.get_facing(), Vector2i.DOWN, "tourné vers l'arrivée")
	assert_false(npc.step(Vector2i.RIGHT), "pas de pas pendant un saut")
	assert_false(npc.hop_to(target + Vector2i.DOWN, grid), "pas de second saut")
	var steps := 0
	while npc.is_hopping() and _step_tween(npc._hop_tween):
		steps += 1
		peak = minf(peak, sprite.position.y)
		rotated = rotated or not is_zero_approx(sprite.rotation)
		swayed = swayed or not is_zero_approx(sprite.position.x)
		squashed = squashed or sprite.scale.y < 2.0
		assert_eq(sprite.scale.x, 2.0, "« %s » : largeur inchangée" % style)
		raised = raised or npc.z_index > 0
	assert_signal_emitted_with_parameters(npc, "hopped", [target])
	assert_false(npc.is_hopping())
	assert_eq(npc.get_cell(), target, "« %s » : case changée" % style)
	assert_same(grid.get_occupant(target), npc)
	assert_eq(npc.position, Grid.cell_to_world(target))
	assert_eq(npc.get_lift(), 0.0, "« %s » : élévation à 0" % style)
	assert_eq(sprite.position, Vector2.ZERO, "« %s » : sprite au sol" % style)
	assert_eq(sprite.rotation, 0.0)
	var shadow := npc.get_node(^"%Shadow") as Sprite2D
	assert_eq(shadow.position, Vector2(0.0, -6.0), "« %s » : ombre au sol" % style)
	assert_eq(shadow.scale, Vector2.ONE)
	assert_eq(meet.cell, target, "la surcharge suit la case")
	assert_lt(peak, -56.0, "« %s » : l'arc monte au-dessus de la table" % style)
	var params := Npc.hop_params(style)
	assert_false(rotated, "« %s » : jamais de rotation du pixel art" % style)
	assert_eq(swayed, float(params["sway"]) > 0.0, "« %s » : dandinement" % style)
	assert_eq(squashed, float(params["squash"]) > 0.0, "« %s » : compression" % style)
	assert_eq(sprite.scale, Vector2(2, 2), "« %s » : échelle rétablie" % style)
	assert_true(raised, "« %s » : dessiné au-dessus des personnages en vol" % style)
	assert_eq(npc.z_index, 0, "« %s » : de nouveau trié au sol" % style)
	var expected := Npc.hop_total_duration(style)
	_assert_lasts(steps, expected, "« %s » : %.2f s" % [style, expected])
	# Il marche normalement ensuite.
	assert_true(npc.step(Vector2i.DOWN))


func test_hop_default_style() -> void:
	await _check_hop(&"")


func test_hop_calm_style() -> void:
	await _check_hop(&"calm")


func test_hop_eager_style() -> void:
	await _check_hop(&"eager")


func test_hop_playful_style() -> void:
	await _check_hop(&"playful")


func test_hop_refused_on_taken_solid_or_own_cell() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"lift": 56}), grid)
	var blocker := RefCounted.new()
	grid.occupy(CELL + Vector2i.DOWN, blocker)
	grid.set_solid(CELL + Vector2i.LEFT)
	watch_signals(npc)
	assert_false(npc.hop_to(CELL + Vector2i.DOWN, grid), "case prise")
	assert_false(npc.hop_to(CELL + Vector2i.LEFT, grid), "case solide")
	assert_false(npc.hop_to(CELL, grid), "sa propre case")
	assert_false(npc.hop_to(Vector2i(20, 20), grid), "hors carte")
	assert_false(npc.is_hopping())
	assert_same(grid.get_occupant(CELL), npc, "il garde sa case")
	assert_same(grid.get_occupant(CELL + Vector2i.DOWN), blocker)
	assert_eq(npc.get_lift(), 56.0, "toujours sur la table")
	var loose := _make(_spec({"id": &"loose"}))
	assert_false(loose.hop_to(CELL + Vector2i.RIGHT), "sans grille")
	assert_signal_not_emitted(npc, "hopped")


func test_hop_uses_its_own_grid_by_default() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	assert_true(npc.hop_to(CELL + Vector2i(2, 0)))
	await wait_for_signal(npc.hopped, 3.0)
	assert_eq(npc.get_cell(), CELL + Vector2i(2, 0))
	assert_same(grid.get_occupant(CELL + Vector2i(2, 0)), npc)


func test_leave_grid_during_a_hop_cancels_it() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"lift": 56, "hop_style": &"calm"}), grid)
	watch_signals(npc)
	npc.hop_to(CELL + Vector2i.DOWN, grid)
	npc.leave_grid()
	assert_false(npc.is_hopping())
	assert_false(grid.is_occupied(CELL))
	assert_false(grid.is_occupied(CELL + Vector2i.DOWN))
	await wait_seconds(Npc.hop_total_duration(&"calm") + 0.1)
	assert_signal_not_emitted(npc, "hopped")
	assert_eq(npc.get_cell(), CELL)


func test_lean_toward_then_settle_without_changing_cell() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"lift": 56}), grid)
	var sprite := _sprite(npc)
	var shadow := npc.get_node(^"%Shadow") as Sprite2D
	watch_signals(npc)
	npc.lean_toward(CELL + Vector2i(0, 3))
	assert_true(npc.is_leaning())
	await wait_for_signal(npc.lean_finished, 1.0)
	assert_false(npc.is_leaning())
	assert_eq(npc.get_lean_offset(), Vector2(0.0, Npc.LEAN_DISTANCE), "élan vers le bas")
	assert_eq(sprite.position, Vector2(0.0, -56.0 + Npc.LEAN_DISTANCE))
	assert_eq(shadow.position, Vector2(0.0, -6.0 - 56.0 + Npc.LEAN_DISTANCE))
	assert_eq(npc.get_cell(), CELL, "même case")
	assert_eq(npc.position, Grid.cell_to_world(CELL))
	assert_same(grid.get_occupant(CELL), npc)
	npc.settle()
	await wait_for_signal(npc.lean_finished, 1.0)
	assert_eq(npc.get_lean_offset(), Vector2.ZERO)
	assert_eq(sprite.position, Vector2(0.0, -56.0), "revenu à sa hauteur")
	assert_eq(npc.get_cell(), CELL)
	assert_signal_emit_count(npc, "lean_finished", 2)


func test_lean_sideways_and_toward_own_cell() -> void:
	var npc := _make(_spec())
	npc.lean_toward(CELL + Vector2i(-4, 1))
	await wait_for_signal(npc.lean_finished, 1.0)
	assert_eq(npc.get_lean_offset(), Vector2(-Npc.LEAN_DISTANCE, 0.0), "axe dominant")
	npc.settle()
	await wait_for_signal(npc.lean_finished, 1.0)
	npc.lean_toward(CELL)
	assert_false(npc.is_leaning(), "sa propre case : rien")
	assert_eq(npc.get_lean_offset(), Vector2.ZERO)


## Jalon 5 (QA S24 du 5B) : le dernier pas d'une fuite se termine pendant GridMover.update() ;
## la fuite fait alors quitter la grille au PNJ, et _process ne doit plus lire son GridMover.
func test_flee_leaves_the_grid_at_the_end_of_its_last_step_without_error() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec(), grid)
	watch_signals(npc)
	var last := CELL + Vector2i(2, 0)
	npc.flee([Vector2i.RIGHT, Vector2i.RIGHT])
	assert_true(npc.is_moving(), "premier pas de fuite")
	_simulate(npc, int(2.0 * Grid.RUN_STEP_DURATION / FRAME) + 6)
	assert_false(npc.is_moving())
	assert_false(grid.is_occupied(last), "case libérée en quittant la grille")
	assert_eq(npc.position, Grid.cell_to_world(last))
	await wait_seconds(Npc.FLEE_FADE_DURATION + 0.1)
	assert_signal_emitted(npc, "left_scene")


# --- Jalon 7 (T4) : entrer dans un bâtiment, animation d'ambiance ---------------------------

## Le livreur : arrivé sur la case d'entrée de sa boucle, il s'efface, libère sa case, reste
## absent le temps prévu puis ressort sur la même case et reprend sa boucle.
func test_route_enter_cell_hides_frees_then_returns() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var door := CELL + Vector2i.UP
	var route: Array[Vector2i] = [CELL, door]
	var npc := _make_on_grid(_spec({"route_cells": route, "route_pause": 0.05,
		"route_enter_cell": door, "route_enter_seconds": 0.3}), grid)
	watch_signals(npc)
	await wait_until(func() -> bool: return npc.is_inside_building(), 3.0)
	assert_signal_emitted(npc, "entered_building")
	assert_false(grid.is_occupied(door), "porte libérée pendant l'absence")
	assert_false(grid.is_occupied(CELL))
	await wait_seconds(Npc.ENTER_FADE_DURATION + 0.05)
	assert_almost_eq(npc.modulate.a, 0.0, 0.01, "invisible à l'intérieur")
	await wait_until(func() -> bool: return not npc.is_inside_building(), 3.0)
	assert_signal_emitted(npc, "left_building")
	assert_eq(npc.get_cell(), door, "ressort par la porte")
	assert_same(grid.get_occupant(door), npc)
	await wait_seconds(Npc.ENTER_FADE_DURATION + 0.05)
	assert_almost_eq(npc.modulate.a, 1.0, 0.01, "visible de nouveau")
	await wait_until(func() -> bool: return npc.get_cell() == CELL, 3.0)
	assert_eq(npc.get_cell(), CELL, "la boucle reprend")


## Le joueur se tient sur la porte : le PNJ attend qu'elle se libère pour ressortir.
func test_route_enter_waits_until_the_door_is_free() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var door := CELL + Vector2i.UP
	var route: Array[Vector2i] = [CELL, door]
	var npc := _make_on_grid(_spec({"route_cells": route, "route_pause": 0.05,
		"route_enter_cell": door, "route_enter_seconds": 0.2}), grid)
	await wait_until(func() -> bool: return npc.is_inside_building(), 3.0)
	var player := RefCounted.new()
	assert_true(grid.occupy(door, player), "le joueur prend la porte")
	await wait_seconds(0.2 + 2.0 * Npc.ENTER_FADE_DURATION + Npc.ENTER_RETRY_DELAY)
	assert_true(npc.is_inside_building(), "toujours dedans")
	grid.release(door, player)
	await wait_until(func() -> bool: return not npc.is_inside_building(),
		Npc.ENTER_RETRY_DELAY * 3.0)
	assert_same(grid.get_occupant(door), npc)


func test_leave_grid_inside_a_building_cancels_the_return() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var door := CELL + Vector2i.UP
	var route: Array[Vector2i] = [CELL, door]
	var npc := _make_on_grid(_spec({"route_cells": route, "route_pause": 0.05,
		"route_enter_cell": door, "route_enter_seconds": 0.2}), grid)
	await wait_until(func() -> bool: return npc.is_inside_building(), 3.0)
	npc.leave_grid()
	assert_false(npc.is_inside_building())
	assert_eq(npc.modulate.a, 1.0)
	await wait_seconds(0.5)
	assert_false(grid.is_occupied(door), "il ne ressort plus")


## Le Roucool de la Dresseuse : petit bond toutes les N secondes, sans bouger de sa case.
func test_idle_react_plays_periodically() -> void:
	var npc := _make(_spec({"idle_react_every": 0.15, "dialogue": &""}))
	watch_signals(npc)
	await wait_seconds(0.5)
	assert_signal_emit_count(npc, "reacted", 3)
	assert_eq(npc.get_cell(), CELL)


func test_without_idle_react_nothing_plays() -> void:
	var npc := _make(_spec())
	watch_signals(npc)
	await wait_seconds(0.4)
	assert_signal_not_emitted(npc, "reacted")


# --- Retours T5 (jalon-07.md §15.21) : marcher ou courir, jamais un mélange --------------

## Planche peinte sans course (le vieil homme ; l'enfant a désormais sa planche de course) :
## un pas demandé en course est marché, à la cadence de marche, avec l'animation de marche.
func test_a_painted_look_without_run_walks_when_asked_to_run() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"sprite": &"old_man"}), grid)
	var sprite := _sprite(npc)
	assert_false(sprite.sprite_frames.has_animation(&"run_right"), "pas de fausse course")
	assert_false(npc.can_run())
	assert_true(npc.step(Vector2i.RIGHT, true))
	assert_eq(sprite.animation, &"walk_right")
	_simulate(npc, int(Grid.RUN_STEP_DURATION / FRAME) + 2)
	assert_true(npc.is_moving(), "encore en marche après la durée d'un pas de course")
	_simulate(npc, int((Grid.WALK_STEP_DURATION - Grid.RUN_STEP_DURATION) / FRAME) + 2)
	assert_false(npc.is_moving())
	assert_eq(npc.get_cell(), CELL + Vector2i.RIGHT)


## Le héros, l'enfant et le Rattata peints courent (planches de course) ; les apparences provisoires (Chen : marche et
## course ; générique : aucune animation de pas) gardent la course.
func test_looks_with_a_run_or_without_any_step_animation_can_run() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	assert_true(_make_on_grid(_spec({"sprite": &"player"}), grid).can_run())
	assert_true(_make_on_grid(_spec({"id": &"kid", "sprite": &"kid",
		"cell": Vector2i(3, 3)}), grid).can_run())
	assert_true(_make_on_grid(_spec({"id": &"rat", "sprite": &"pokemon/rattata",
		"cell": Vector2i(6, 2)}), grid).can_run())
	assert_true(_make_on_grid(_spec({"id": &"oak", "sprite": &"oak",
		"cell": Vector2i(1, 1)}), grid).can_run())
	assert_true(_make_on_grid(_spec({"id": &"npc2", "cell": Vector2i(8, 8)}), grid).can_run())


## Un pas = un demi-cycle (2 images sur 4) ; les pas alternent les deux pieds, même avec
## un arrêt entre deux pas (routines) : jamais le même pied à chaque case.
func test_steps_alternate_feet_even_after_a_stop() -> void:
	var grid := GridWorld.new(Vector2i(10, 10))
	var npc := _make_on_grid(_spec({"sprite": &"kid"}), grid)
	var sprite := _sprite(npc)
	var first_frames: Array[int] = []
	for direction: Vector2i in [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		assert_true(npc.step(direction))
		first_frames.append(sprite.frame)
		_simulate(npc, int(Grid.WALK_STEP_DURATION / FRAME) + 3)
		assert_false(npc.is_moving())
	assert_eq(first_frames, [0, 2, 0, 2] as Array[int], "pied gauche, pied droit…")
