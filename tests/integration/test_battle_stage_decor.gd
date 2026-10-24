extends GutTest
## BattleStage avec décor peint (CB.3) : le lieu choisit le décor (Route 1) ou le repli (labo :
## carte recadrée au zoom de combat). Avec décor : le monde se floute puis se fond dans le décor
## (transition en temps simulé), décor opaque posé par sa ligne de sol (pieds et ombres sur le
## sol peint), premier plan devant ton Pokémon, caméra qui avance à peine, flou du monde coupé
## une fois le décor opaque ; coups, critique, capture ; sortie : décor rendu, caméra intacte.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STAGE_SCENE := "res://game/battle/battle_stage.tscn"
const PLAYER_CELL := Vector2i(11, 7)
const PLAYER_SIDE := BattleEvent.SideId.PLAYER
const FOE_SIDE := BattleEvent.SideId.FOE

var _stage: BattleStage
var _camera: Camera2D


func before_each() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var owner_node := Node2D.new()
	owner_node.position = Grid.cell_to_world(PLAYER_CELL)
	world.add_child(owner_node)
	_camera = Camera2D.new()
	owner_node.add_child(_camera)
	_camera.make_current()
	_stage = (load(STAGE_SCENE) as PackedScene).instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	await wait_process_frames(2)


func _view() -> Vector2:
	return _stage.get_viewport().get_visible_rect().size


func _backdrop() -> CanvasItem:
	return _stage.get_node(^"%Backdrop") as CanvasItem


func _wild(species: StringName = &"pidgey") -> void:
	await _stage.play_wild_intro(_camera, species, Grid.cell_to_world(PLAYER_CELL + Vector2i.UP))
	await _stage.play_partner_enter(&"charmander")


func test_place_picks_the_route_1_decor_or_falls_back() -> void:
	assert_not_null(_stage.set_place(&"route_1", Vector2i(10, 30)))
	assert_eq(_stage.get_decor().id, &"route_1_chemin")
	assert_null(_stage.set_place(&"oak_lab", Vector2i(5, 5)), "labo : repli")
	assert_null(_stage.get_decor())


func test_wild_battle_on_the_painted_decor() -> void:
	_stage.set_place(&"route_1", Vector2i(10, 30))
	await _wild()
	var back := _stage.get_decor_back()
	var front := _stage.get_decor_front()
	assert_true(back.visible and back.modulate.a == 1.0, "décor opaque")
	assert_true(front.visible and front.modulate.a == 1.0, "premier plan affiché")
	assert_not_null(back.texture)
	assert_eq(back.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	assert_false(_backdrop().visible, "flou du monde coupé sous le décor opaque")
	assert_almost_eq(_camera.zoom.x, BattleStage.PAINTED_ZOOM, 0.001, "la caméra avance à peine")
	# Ordre de dessin : fond < ombres < adversaire < premier plan < ton Pokémon (cadrage B : le
	# dos agrandi passe devant le feuillage flou) < éclair.
	var mine := _stage.get_sprite(PLAYER_SIDE)
	assert_lt(back.get_index(), _stage.get_node(^"%FoeShadow").get_index())
	assert_gt(front.get_index(), _stage.get_sprite(FOE_SIDE).get_index(), "premier plan devant l'adversaire")
	assert_lt(front.get_index(), mine.get_index(), "ton Pokémon devant le premier plan")
	assert_lt(front.get_index(), _stage.get_node(^"%Flash").get_index())
	# Pieds sur la ligne de sol du décor.
	var decor := _stage.get_decor()
	var rect := decor.fit(_view())
	var scale := rect.size.x / decor.size.x
	var foe_ground := rect.position.round() + decor.foe_feet * scale
	var mine_ground := rect.position.round() + decor.player_feet * scale
	assert_almost_eq(_stage.get_sprite(FOE_SIDE).position.distance_to(foe_ground), 0.0, 3.0)
	# Ton Pokémon (cadrage B) ne se pose plus sur le sol du décor : il est coupé par le bord bas.
	assert_gt(mine.position.y, mine_ground.y, "dos sous la ligne de sol, coupé par le bord")
	assert_eq((_stage.get_node(^"%FoeShadow") as Node2D).position,
		_stage.get_sprite(FOE_SIDE).position, "ombre sous les pieds")
	assert_eq(back.position, rect.position.round())


func test_moves_critical_capture_and_exit_on_the_decor() -> void:
	_stage.set_place(&"route_1", Vector2i(10, 30))
	await _wild(&"rattata")
	var back := _stage.get_decor_back()
	var rest := back.position
	await _stage.play_move(PLAYER_SIDE, MoveData.Category.PHYSICAL)
	await _stage.play_hit(FOE_SIDE, true)
	assert_eq(back.position, rest, "décor revenu en place après le critique")
	assert_eq(_camera.offset, Vector2.ZERO)
	await _stage.play_throw()
	assert_true(_stage.get_ball().visible)
	assert_gt(_stage.get_ball().get_index(), _stage.get_decor_front().get_index(),
		"la Ball n'est pas sous le premier plan")
	await _stage.play_ball_shake()
	await _stage.play_catch_burst()
	await _stage.exit()
	assert_false(back.visible)
	assert_null(back.texture, "image rendue après le combat")
	assert_null(_stage.get_decor_front().texture)
	assert_null(_stage.get_decor(), "le lieu se repose à chaque combat")
	assert_eq(_camera.zoom, Vector2.ONE, "caméra rendue")
	assert_false(_backdrop().visible)


func test_fallback_keeps_the_old_backdrop() -> void:
	_stage.set_place(&"oak_lab", Vector2i(5, 5))
	await _wild()
	assert_false(_stage.get_decor_back().visible)
	assert_false(_stage.get_decor_front().visible)
	assert_true(_backdrop().visible, "carte voilée et floutée")
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)
	await _stage.exit()


func test_no_place_is_the_fallback() -> void:
	await _wild()
	assert_null(_stage.get_decor())
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)
	await _stage.exit()


## Transition réelle (temps simulé) : le monde se floute d'abord, le décor arrive ensuite en
## fondu (jamais d'écran noir), la transition dure WILD_DECOR_DURATION.
func test_transition_blurs_the_world_into_the_decor() -> void:
	_stage.speed_scale = 1.0
	_stage.set_place(&"route_1", Vector2i(10, 30))
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var intro := func() -> void:
		await _stage.play_wild_intro(_camera, &"pidgey", Vector2.ZERO)
		done[0] = true
	intro.call()
	var back := _stage.get_decor_back()
	clock.run_until(func() -> bool: return false, BattleStage.WILD_DECOR_DURATION * 0.2)
	assert_true(_backdrop().visible, "le monde se floute")
	assert_false(back.visible, "décor pas encore là au début")
	clock.run_until(func() -> bool: return false, BattleStage.WILD_DECOR_DURATION * 0.45)
	assert_true(back.visible and _backdrop().visible, "fondu monde → décor")
	assert_between(back.modulate.a, 0.05, 0.95, "décor en fondu")
	var steps := clock.run_until(func() -> bool: return back.modulate.a >= 1.0, 2.0)
	assert_lt(steps, int(BattleStage.WILD_DECOR_DURATION * 60.0) + 2, "fondu fini à temps")
	clock.run_until(func() -> bool: return done[0], 2.0)
	clock.release()
	assert_true(done[0])
	_stage.speed_scale = 0.0
	await _stage.exit()


# --- Correctifs après la QA S24 -----------------------------------------------------------

## Le décor de la carte est préchargé en tâche de fond à l'entrée de la carte, puis repris tel
## quel au combat ; une carte sans décor rend celui de la précédente (un seul décor gardé).
func test_decor_is_preloaded_on_map_entry_and_reused() -> void:
	var cache := _stage.get_decor_cache()
	_stage.prepare_place(&"oak_lab")
	assert_eq(cache.get_paths().size(), 0, "labo : rien à précharger")
	_stage.prepare_place(&"route_1")
	var decor := BattleDecorCatalog.load_file().default_for(&"route_1")
	assert_eq(cache.get_paths().size(), 2, "fond et premier plan demandés")
	var deadline := Time.get_ticks_msec() + 10000
	while not cache.is_ready(decor.back_path) and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
	assert_true(cache.is_ready(decor.back_path), "chargé en tâche de fond")
	var back := cache.take(decor.back_path)
	_stage.set_place(&"route_1", Vector2i(10, 30))
	await _wild()
	assert_same(_stage.get_decor_back().texture, back, "image préchargée reprise")
	await _stage.exit()
	assert_eq(cache.get_paths().size(), 2, "gardé hors combat sur cette carte")
	_stage.prepare_place(&"oak_lab")
	assert_eq(cache.get_paths().size(), 0, "rendu en quittant la carte")


## Le coup (Griffe) fait disparaître franchement l'adversaire pendant le clignotement (plus de
## « fantôme » translucide décalé) ; son ombre reste au sol.
func test_hit_blink_hides_the_foe_and_keeps_its_shadow() -> void:
	_stage.set_place(&"route_1", Vector2i(10, 30))
	await _wild()
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(FOE_SIDE)
	var shadow := _stage.get_node(^"%FoeShadow") as CanvasItem
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void: await _stage.play_hit(FOE_SIDE, false)
	runner.call()
	clock.run_until(func() -> bool: return sprite.modulate.a <= 0.0, 0.5)
	assert_eq(sprite.modulate.a, 0.0, "adversaire caché au creux du clignotement")
	assert_true(shadow.visible and shadow.modulate.a == 1.0, "ombre au sol")
	clock.run_until(func() -> bool: return false, 0.6)
	clock.release()
	assert_eq(sprite.modulate.a, 1.0, "de retour")
