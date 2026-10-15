extends GutTest
## Voile d'obscurité (J17 T9, brique commune avec le J18 : docs/tech/jalon-18.md §2.13 ;
## dossier 21 I-7, I-8) sur une vraie carte (`mt_moon_1f`, ses halos) et le vrai joueur : z
## absolu au-dessus du monde, rectangle qui couvre la vue, centre qui suit le joueur **image par
## image**, trous des halos, voile caché hors du noir, ouverture du halo au pas près, « Réduire
## les animations », grille inchangée, bulles au-dessus du voile. Puis dans le vrai Boot : le
## Mont Sélénite n'a pas de voile.

const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const MAP_PATH := "res://game/world/maps/mt_moon_1f.tscn"
const START := Vector2i(29, 40)
const TIMEOUT := 12.0

var _world: Node2D
var _map: GameMap
var _player: Player
var _darkness: DarknessController


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	_world.add_child(_map)
	_player = (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	_map.spawn_player_at(_player, _map.find_standing_cell(START), Vector2i.DOWN)
	_player.set_input_enabled(false)
	_darkness = DarknessController.new()
	add_child_autofree(_darkness)
	_darkness.setup(_world, _player)


func after_each() -> void:
	LightGlow.set_reduce_motion(false)


func _body() -> Vector2:
	return VeilMath.body_center(_player.global_position, _darkness.get_profile().center_offset)


func _view() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()


func _glow_count() -> int:
	var count := 0
	for node: Node in _map.find_children("*", "Sprite2D", true, false):
		if node is LightGlow:
			count += 1
	return count


func test_hidden_outside_the_dark() -> void:
	_darkness.set_map(_map, false, false)
	var veil := _darkness.get_veil()
	assert_false(veil.visible, "caché hors d'une grotte obscure")
	assert_false(_darkness.is_processing(), "aucun coût hors du noir")
	assert_false(_darkness.is_dark())
	assert_eq(veil.get_sources().size(), 0)


func test_dark_veil_above_the_world() -> void:
	_darkness.set_map(_map, true, false)
	var veil := _darkness.get_veil()
	assert_true(veil.visible)
	assert_true(_darkness.is_processing())
	assert_false(veil.z_as_relative, "z absolu")
	assert_eq(veil.z_index, WorldLighting.Z_VEIL)
	assert_gt(WorldLighting.Z_VEIL, LightGlow.Z_GLOW)
	assert_gt(WorldLighting.Z_VEIL, 10, "au-dessus des surplombs (Overhead : 10)")
	assert_eq(veil.get_parent(), _world, "dans le monde, pas dans un calque")
	assert_true(veil.get_view_rect().encloses(_view()), "couvre toute la vue")
	assert_eq(veil.get_center(), _body(), "centré sur le corps du joueur")
	var params := veil.get_params()
	assert_almost_eq(params.clear_px, 2.5 * 96.0, 0.01, "≈ 2,5 cases sans Flash")
	assert_almost_eq(params.fade_px, 4.0 * 96.0, 0.01)
	assert_lt(params.outside, 1.0, "jamais de noir total")
	assert_false(_darkness.is_lit())
	assert_eq(veil.alpha_at(_player.global_position), 0.0, "le joueur n'est jamais voilé")


func test_glows_pierce_the_veil() -> void:
	var glows := _glow_count()
	assert_between(glows, 1, VeilMath.MAX_SOURCES, "halos de la carte (budget du J12)")
	_darkness.set_map(_map, true, false)
	var sources := _darkness.get_veil().get_sources()
	assert_eq(sources.size(), glows, "un trou par halo")
	var first := sources[0]
	assert_eq(_darkness.get_veil().alpha_at(Vector2(first.x, first.y)), 0.0, "lampe visible")


func test_lit_state_on_arrival() -> void:
	_darkness.set_map(_map, true, true)
	assert_true(_darkness.is_lit(), "Flash déjà allumée : posé ouvert, sans animation")
	assert_false(_darkness.is_opening())
	assert_almost_eq(_darkness.get_veil().get_params().clear_px, 7.0 * 96.0, 0.01, "≈ 7 cases")


func test_center_follows_the_player_frame_by_frame() -> void:
	_darkness.set_map(_map, true, false)
	var veil := _darkness.get_veil()
	var direction := Vector2i.ZERO
	for candidate: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		if _map.get_grid().is_free(_player.get_cell() + candidate):
			direction = candidate
			break
	assert_ne(direction, Vector2i.ZERO, "un pas possible")
	var sim := FrameSim.new(get_tree(), [_player, _darkness])
	var start := _player.global_position
	assert_true(_player.script_step(direction))
	var moved := false
	for i: int in 40:
		await sim.frame()
		assert_eq(veil.get_center(), _body(), "image %d : centre = corps du joueur" % i)
		moved = moved or _player.global_position != start
	sim.finish()
	assert_true(moved, "le joueur a bougé")


func test_center_follows_the_player_while_running() -> void:
	# Course : plusieurs pas enchaînés, plus rapides que la marche ; le centre du trou (voile et
	# lueur au sol) égale le corps du joueur à CHAQUE image, et le joueur ne sort jamais du trou.
	_darkness.set_map(_map, true, false)
	var veil := _darkness.get_veil()
	var floor_light := _darkness.get_floor_light()
	var direction := Vector2i.UP
	var sim := FrameSim.new(get_tree(), [_player, _darkness])
	var start := _player.global_position
	var steps := 0
	var frames := 0
	var farthest := 0.0
	while steps < 4 and frames < 400:
		if not _player.is_moving():
			if not _map.get_grid().is_free(_player.get_cell() + direction):
				break
			assert_true(_player.script_step(direction, true), "pas de course %d" % steps)
			steps += 1
		await sim.frame()
		frames += 1
		assert_true(_player.is_running() or not _player.is_moving(), "en course")
		assert_eq(veil.get_center(), _body(), "image %d : voile = corps" % frames)
		assert_eq(floor_light.lift_at(_body()), floor_light.get_strength(), "lueur = corps")
		assert_eq(veil.alpha_at(_player.global_position), 0.0, "joueur jamais voilé")
		farthest = maxf(farthest, start.distance_to(_player.global_position))
	while _player.is_moving() and frames < 600:
		await sim.frame()
		frames += 1
	sim.finish()
	assert_eq(steps, 4, "quatre pas de course enchaînés")
	assert_almost_eq(farthest, 4.0 * Grid.TILE_SIZE, Grid.TILE_SIZE, "il a bien avancé")
	assert_eq(veil.get_center(), _body(), "centre final")


func test_floor_light_follows_and_matches_the_math() -> void:
	var floor_light := _darkness.get_floor_light()
	assert_false(floor_light.visible, "caché avant la carte")
	_darkness.set_map(_map, true, false)
	assert_true(floor_light.visible)
	assert_false(floor_light.z_as_relative)
	assert_eq(floor_light.z_index, WorldLighting.Z_GROUND_DECALS, "sous les personnages")
	assert_eq(floor_light.get_parent(), _world)
	assert_true(floor_light.get_view_rect_for_test().encloses(_view()))
	var strength := floor_light.get_strength()
	assert_almost_eq(strength, _darkness.get_profile().floor_lift, 0.0001)
	assert_gt(strength, 0.0)
	assert_almost_eq(floor_light.lift_at(_body()), strength, 0.0001, "plein au centre")
	assert_eq(floor_light.lift_at(_body() + Vector2(4.5 * 96.0, 0.0)), 0.0, "nul hors du fondu")
	_darkness.set_map(_map, false, false)
	assert_false(floor_light.visible, "caché hors du noir")


func test_open_runs_its_duration() -> void:
	_darkness.set_map(_map, true, false)
	watch_signals(_darkness)
	var clock := TweenClock.new(get_tree())
	_darkness.open()
	assert_true(_darkness.is_opening())
	var duration := _darkness.get_profile().open_duration
	var steps := clock.run_until(func() -> bool: return not _darkness.is_opening())
	clock.release()
	assert_gte(steps * TweenClock.STEP, duration - 0.0001, "pas finie avant 0,6 s")
	assert_lte(steps, int(ceil(duration / TweenClock.STEP)) + 1, "au plus un pas de plus")
	assert_true(_darkness.is_lit())
	assert_signal_emit_count(_darkness, "opened", 1)
	assert_almost_eq(_darkness.get_veil().get_params().clear_px, 7.0 * 96.0, 0.01)


func test_open_midway_is_between_the_radii() -> void:
	_darkness.set_map(_map, true, false)
	var clock := TweenClock.new(get_tree())
	_darkness.open()
	for i: int in 15:
		clock.step()
	var clear := _darkness.get_veil().get_params().clear_px
	clock.release()
	assert_between(clear, 2.5 * 96.0 + 1.0, 7.0 * 96.0 - 1.0, "rayon animé")
	assert_between(_darkness.lit_amount(), 0.01, 0.99)


func test_reduce_motion_opens_at_once_and_stops_the_breath() -> void:
	_darkness.set_map(_map, true, false)
	assert_gt(_darkness.get_veil().get_breath(), 0.0, "battement léger")
	_darkness.set_reduce_motion(true)
	assert_eq(_darkness.get_veil().get_breath(), 0.0, "battement coupé")
	watch_signals(_darkness)
	_darkness.open()
	assert_true(_darkness.is_lit(), "ouverture dans le même appel")
	assert_false(_darkness.is_opening())
	assert_signal_emit_count(_darkness, "opened", 1)


func test_leaving_the_dark_resets_flash() -> void:
	_darkness.set_map(_map, true, true)
	_darkness.set_map(_map, false, false)
	assert_false(_darkness.is_lit())
	assert_eq(_darkness.lit_amount(), 0.0)
	assert_false(_darkness.get_veil().visible)


func test_grid_identical_with_and_without_the_veil() -> void:
	var grid := _map.get_grid()
	var before: Array[bool] = []
	var size := _map.size
	for y: int in size.y:
		for x: int in size.x:
			before.append(grid.is_free(Vector2i(x, y)))
	_darkness.set_map(_map, true, false)
	_darkness.set_map(_map, true, true)
	var after: Array[bool] = []
	for y: int in size.y:
		for x: int in size.x:
			after.append(grid.is_free(Vector2i(x, y)))
	assert_eq(after, before, "le voile n'est qu'un rendu")


func test_bubbles_above_the_veil() -> void:
	var spec := NpcSpec.new()
	spec.id = &"villager"
	spec.cell = Vector2i(29, 38)
	spec.facing = Vector2i.DOWN
	spec.sprite = &"villager"
	var npc := (load("res://game/world/npc/npc.tscn") as PackedScene).instantiate() as Npc
	npc.setup(spec)
	_map.get_entities().add_child(npc)
	npc.show_emote(&"exclamation")
	var bubble := npc.get_node_or_null(^"EmoteBubble") as Sprite2D
	assert_not_null(bubble)
	if bubble != null:
		assert_false(bubble.z_as_relative, "z absolu")
		assert_eq(bubble.z_index, WorldLighting.Z_ABOVE_VEIL)
		assert_gt(bubble.z_index, WorldLighting.Z_VEIL, "« ! » au-dessus du voile")
	var note := EmoteBubble.new()
	_map.get_entities().add_child(note)
	note.play(EmoteBubble.NOTE)
	var icon := note.get_node_or_null(^"Icon") as Sprite2D
	assert_not_null(icon)
	if icon != null:
		assert_false(icon.z_as_relative)
		assert_eq(icon.z_index, WorldLighting.Z_ABOVE_VEIL)


# --- Vrai Boot ---------------------------------------------------------------------------------

func test_boot_mt_moon_has_no_veil() -> void:
	var fades := [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_darkness_veil_save.json")
	boot.start_map = &"mt_moon_1f"
	boot.start_spawn = &"arrivee_a"
	boot.start_facing = Vector2i.DOWN
	add_child_autofree(boot)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	var darkness := boot.get_darkness()
	assert_not_null(darkness)
	assert_eq(boot.get_map().map_id, &"mt_moon_1f")
	assert_false(darkness.is_dark(), "Mont Sélénite : aucun voile (dossier 21 §5.2)")
	assert_false(darkness.get_veil().visible)
	assert_false(darkness.is_processing())
	assert_true(darkness.get_veil().is_inside_tree(), "voile posé une fois sous le monde")
	var menu := boot.get_menu_director()
	assert_true(menu.change_setting(GameSettings.REDUCE_MOTION, true))
	assert_eq(darkness.get_veil().get_breath(), 0.0, "réglage branché")
	assert_true(menu.change_setting(GameSettings.REDUCE_MOTION, false))
	SceneRouter.fade_out_duration = fades[0]
	SceneRouter.fade_in_duration = fades[1]
	GameState.clock = DeviceClock.new()
