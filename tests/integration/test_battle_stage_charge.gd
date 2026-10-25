extends GutTest
## BattleStage : Tunnel et Téléport (jalon 14 T9). Sprite caché sous terre, rendu en surface,
## sprite adverse effacé par le Téléport ; « Réduire les animations » : fondu court sans
## mouvement. Durées en temps simulé (TweenClock).

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STAGE_SCENE := "res://game/battle/battle_stage.tscn"
const NPC_SCENE := "res://game/world/npc/npc.tscn"
const PLAYER_SIDE := BattleEvent.SideId.PLAYER
const FOE_SIDE := BattleEvent.SideId.FOE

var _stage: BattleStage
var _camera: Camera2D
var _mine: Npc
var _foe: Npc


func before_each() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var owner_node := Node2D.new()
	owner_node.position = Grid.cell_to_world(Vector2i(11, 7))
	world.add_child(owner_node)
	_camera = Camera2D.new()
	_camera.limit_left = -213
	_camera.limit_top = -12
	_camera.limit_right = 1749
	_camera.limit_bottom = 1068
	owner_node.add_child(_camera)
	_camera.make_current()
	_mine = _npc(world, &"charmander", Vector2i(10, 7), Vector2i.RIGHT)
	_foe = _npc(world, &"squirtle", Vector2i(8, 7), Vector2i.LEFT)
	_stage = (load(STAGE_SCENE) as PackedScene).instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	await wait_process_frames(2)
	var rival: Array[Vector2i] = [Vector2i(7, 7)]
	await _stage.enter(_camera, _mine, _foe, &"charmander", &"squirtle", rival)


func _npc(parent: Node, id: StringName, cell: Vector2i, facing: Vector2i) -> Npc:
	var spec := NpcSpec.new()
	spec.id = id
	spec.sprite = id
	spec.cell = cell
	spec.facing = facing
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	parent.add_child(npc)
	return npc


func test_burrow_hides_the_sprite_and_surface_gives_it_back() -> void:
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var feet := sprite.position
	assert_true(sprite.visible)
	await _stage.play_burrow(PLAYER_SIDE)
	assert_false(sprite.visible, "caché sous terre")
	assert_true(_stage.is_buried(PLAYER_SIDE))
	assert_false(_stage.get_sprite(FOE_SIDE).visible == false, "l'autre camp ne bouge pas")
	await _stage.play_surface(PLAYER_SIDE)
	assert_true(sprite.visible, "remonté")
	assert_false(_stage.is_buried(PLAYER_SIDE))
	assert_eq(sprite.position, feet, "de retour à son ancre")
	assert_eq(sprite.modulate.a, 1.0)


func test_surface_without_burrow_changes_nothing() -> void:
	var sprite := _stage.get_sprite(FOE_SIDE)
	var before := sprite.position
	await _stage.play_surface(FOE_SIDE)
	assert_true(sprite.visible)
	assert_eq(sprite.position, before)


func test_teleport_erases_the_foe_sprite() -> void:
	await _stage.play_vanish(FOE_SIDE)
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible, "le joueur reste")


func test_burrow_sinks_while_fading_in_a_third_of_a_second() -> void:
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var feet := sprite.position
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _stage.play_burrow(PLAYER_SIDE)
		done[0] = true
	runner.call()
	var half := roundi(BattleStage.BURROW_DURATION / 2.0 / TweenClock.STEP)
	for i: int in half:
		clock.step()
	assert_gt(sprite.position.y, feet.y, "il s'enfonce")
	assert_between(sprite.modulate.a, 0.05, 0.95, "il s'efface")
	assert_true(sprite.visible)
	var steps := half + clock.run_until(func() -> bool: return done[0], 2.0)
	clock.release()
	assert_true(done[0])
	assert_false(sprite.visible)
	assert_lte(steps, ceili(BattleStage.BURROW_DURATION / TweenClock.STEP) + 1)


func test_reduced_motion_burrow_is_a_short_fade_without_movement() -> void:
	_stage.speed_scale = 1.0
	_stage.reduce_motion = true
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var feet := sprite.position
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _stage.play_burrow(PLAYER_SIDE)
		done[0] = true
	runner.call()
	for i: int in 4:
		clock.step()
		assert_eq(sprite.position, feet, "aucun mouvement")
	var steps := 4 + clock.run_until(func() -> bool: return done[0], 2.0)
	clock.release()
	assert_true(done[0])
	assert_lte(steps, ceili(BattleStage.REDUCED_FADE / TweenClock.STEP) + 1)
	assert_false(sprite.visible)


func test_reduced_motion_surface_does_not_move() -> void:
	_stage.reduce_motion = true
	await _stage.play_burrow(PLAYER_SIDE)
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void: await _stage.play_surface(PLAYER_SIDE)
	runner.call()
	clock.step()
	assert_true(sprite.visible)
	assert_eq(sprite.position, _stage.get_sprite(PLAYER_SIDE).position)
	# Cadrage B : pieds du dos de Salamèche au bord bas, enfoncés de la part coupée.
	var view := _stage.get_viewport().get_visible_rect().size
	var image := BattleArt.new().image(&"charmander", true)
	var box: Rect2 = image["box"]
	var scale := BattleLayout.back_scale(box.size, BattleArt.new().height_m(&"charmander"), view.y,
		image["crop"])
	var rest_y: float = BattleLayout.anchors(view)["player_back"].y \
		+ BattleLayout.back_sink(box.size, scale, image["crop"])
	assert_eq(sprite.position.y, rest_y, "à l'ancre dès le début")
	clock.run_until(func() -> bool: return sprite.modulate.a >= 1.0, 2.0)
	clock.release()


func test_reset_forgets_the_burrow() -> void:
	await _stage.play_burrow(PLAYER_SIDE)
	_stage.reset()
	assert_false(_stage.is_buried(PLAYER_SIDE))
