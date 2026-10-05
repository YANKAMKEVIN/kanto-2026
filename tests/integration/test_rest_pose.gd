extends GutTest
## Pose d'attente (QA téléphone, scène oak_parcel) : après chaque pas, marche ou course,
## après un pivot (face) ou une réaction (react), le personnage reprend son animation
## idle_<dir> (image de repos), jamais une pose de marche figée.

const NPC_SCENE := "res://game/world/npc/npc.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const FRAME := 1.0 / 60.0
const CELL := Vector2i(5, 5)

var _grid: GridWorld


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(16, 12))


func _npc(sprite: StringName) -> Npc:
	_grid = GridWorld.new(Vector2i(16, 12))
	var spec := NpcSpec.new()
	spec.id = &"rest_npc"
	spec.cell = CELL
	spec.facing = Vector2i.DOWN
	spec.sprite = sprite
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	add_child_autofree(npc)
	npc.enter_grid(_grid)
	npc.set_process(false)
	return npc


func _player() -> Player:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(player)
	player.enter_map(_grid, CELL, Vector2i.DOWN, Grid.map_pixel_rect(Vector2i(16, 12)))
	player.set_process(false)
	return player


func _run_npc(npc: Npc) -> void:
	for i: int in 120:
		if not npc.is_moving():
			return
		npc._process(FRAME)


func _run_player(player: Player) -> void:
	for i: int in 120:
		player._process(FRAME)


func _assert_rest(sprite: AnimatedSprite2D, facing: Vector2i, label: String) -> void:
	var anim := StringName("idle_" + Grid.direction_name(facing))
	assert_eq(sprite.animation, anim, label + " : animation")
	assert_eq(sprite.frame, 0, label + " : image de repos")
	assert_true(sprite.is_playing() or sprite.sprite_frames.get_frame_count(anim) == 1, label)


func test_npc_rests_after_walk_and_run() -> void:
	for look: StringName in [&"rival", &"kid", &"villager"]:
		for run: bool in [false, true]:
			var npc := _npc(look)
			var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
			for dir: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
				assert_true(npc.step(dir, run))
				_run_npc(npc)
				_assert_rest(sprite, dir, "%s run=%s %s" % [look, run, dir])


func test_npc_rests_after_face_and_react() -> void:
	var npc := _npc(&"rival")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	npc.step(Vector2i.RIGHT)
	_run_npc(npc)
	npc.face(Vector2i.UP)
	_assert_rest(sprite, Vector2i.UP, "face")
	npc.react()
	sprite.animation_finished.emit()
	_assert_rest(sprite, Vector2i.UP, "react")


func test_npc_background_step_chain_then_face_rests() -> void:
	var npc := _npc(&"rival")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	for dir: Vector2i in [Vector2i.UP, Vector2i.UP, Vector2i.LEFT]:
		npc.step(dir)
		_run_npc(npc)
	npc.face(Vector2i.DOWN)
	_assert_rest(sprite, Vector2i.DOWN, "chaîne puis face")


func test_player_rests_after_scripted_step_face_and_react() -> void:
	var player := _player()
	var sprite := player.get_node(^"%Sprite") as AnimatedSprite2D
	for run: bool in [false, true]:
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
			assert_true(player.script_step(dir, run))
			_run_player(player)
			_assert_rest(sprite, dir, "joueur run=%s %s" % [run, dir])
	player.face(Vector2i.LEFT)
	_assert_rest(sprite, Vector2i.LEFT, "joueur face")
	player.react()
	sprite.animation_finished.emit()
	_run_player(player)
	_assert_rest(sprite, Vector2i.LEFT, "joueur react")


func test_player_keep_facing_step_rests_in_facing() -> void:
	var player := _player()
	var sprite := player.get_node(^"%Sprite") as AnimatedSprite2D
	player.face(Vector2i.UP)
	assert_true(player.script_step(Vector2i.DOWN, false, true))
	_run_player(player)
	_assert_rest(sprite, Vector2i.UP, "recul")
