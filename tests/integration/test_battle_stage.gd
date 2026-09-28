extends GutTest
## BattleStage (jalon-04.md §14.4, §14.11 T6) sur une mini-carte : caméra enfant d'un
## « joueur », deux PNJ Pokémon posés au sol. Entrée : PNJ cachés, sprites de combat aux
## ancres (NEAREST, ×4 de dos, ×3 de face, bonnes textures), caméra recadrée ; animations des
## temps qui se terminent ; sortie : PNJ réaffichés sur leur case, caméra rendue à
## l'identique ; reset ; entrée refusée pendant un combat ; aucun orphelin.
## Transition réelle (speed_scale = 1) : à mi-course, caméra et sprites avancent ensemble.

const STAGE_SCENE := "res://game/battle/battle_stage.tscn"
const NPC_SCENE := "res://game/world/npc/npc.tscn"
const PLAYER_CELL := Vector2i(11, 7)
const MINE_CELL := Vector2i(10, 7)
const FOE_CELL := Vector2i(8, 7)
const RIVAL_CELL := Vector2i(7, 7)
const LIMITS: Array[int] = [-213, -12, 1749, 1068]
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
	owner_node.position = Grid.cell_to_world(PLAYER_CELL)
	world.add_child(owner_node)
	_camera = Camera2D.new()
	_camera.limit_left = LIMITS[0]
	_camera.limit_top = LIMITS[1]
	_camera.limit_right = LIMITS[2]
	_camera.limit_bottom = LIMITS[3]
	owner_node.add_child(_camera)
	_camera.make_current()
	_mine = _npc(world, &"charmander", MINE_CELL, Vector2i.RIGHT)
	_foe = _npc(world, &"squirtle", FOE_CELL, Vector2i.LEFT)
	_stage = (load(STAGE_SCENE) as PackedScene).instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	await wait_process_frames(2)


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


func _enter(foe: Npc = null) -> void:
	var rival: Array[Vector2i] = [RIVAL_CELL]
	await _stage.enter(_camera, _mine, foe if foe != null else _foe, &"charmander",
		&"squirtle", rival)


func _anchors() -> Dictionary:
	return BattleLayout.anchors(_stage.get_viewport().get_visible_rect().size)


func test_idle_stage_shows_nothing() -> void:
	assert_false(_stage.is_active())
	assert_eq(_stage.layer, UiTokens.LAYER_BATTLE_STAGE)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_false((_stage.get_node(^"%Backdrop") as CanvasItem).visible)


func test_enter_hides_world_pokemon_and_shows_battle_sprites_at_anchors() -> void:
	await _enter()
	var a := _anchors()
	assert_true(_stage.is_active())
	assert_false(_mine.visible, "PNJ du joueur caché")
	assert_false(_foe.visible, "PNJ adverse caché")
	var mine := _stage.get_sprite(PLAYER_SIDE)
	var foe := _stage.get_sprite(FOE_SIDE)
	for sprite: Sprite2D in [mine, foe]:
		assert_true(sprite.visible)
		assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_eq(sprite.modulate, Color.WHITE)
		assert_eq(sprite.offset, Vector2(0, -32), "pieds sur l'origine")
	assert_eq(mine.position, a["player_feet"])
	assert_eq(foe.position, a["foe_feet"])
	assert_eq(mine.scale, Vector2.ONE * 4, "de dos ×4")
	assert_eq(foe.scale, Vector2.ONE * 3, "de face ×3")
	assert_eq(mine.texture.resource_path, BattleStage.sprite_path(&"charmander", true))
	assert_eq(foe.texture.resource_path, BattleStage.sprite_path(&"squirtle", false))
	assert_string_ends_with(mine.texture.resource_path, "charmander_back.png")
	assert_string_ends_with(foe.texture.resource_path, "squirtle_front.png")
	assert_eq(mine.texture.get_size(), Vector2(64, 64))
	assert_true((_stage.get_node(^"%PlayerShadow") as CanvasItem).visible, "ombre au sol")
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible, "voile posé")


func test_enter_recomposes_the_camera_on_the_arena() -> void:
	await _enter()
	# Le parent de la caméra n'a pas de get_cell ici : cadrage sur le rival et les Pokémon.
	var cells: Array[Vector2i] = [RIVAL_CELL, MINE_CELL, FOE_CELL]
	assert_eq(_stage.get_focus(), BattleLayout.focus(cells))
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)
	assert_eq(_camera.global_position, _stage.get_focus().round())
	assert_eq(_camera.limit_left, -BattleStage.LIMIT_FREE, "limites levées")


func test_moves_hits_stats_and_faint_finish_and_come_back_to_the_anchor() -> void:
	await _enter()
	var a := _anchors()
	await _stage.play_move(PLAYER_SIDE, MoveData.Category.PHYSICAL)
	await _stage.play_move(FOE_SIDE, MoveData.Category.SPECIAL)
	await _stage.play_move(FOE_SIDE, MoveData.Category.STATUS)
	await _stage.play_hit(FOE_SIDE, false)
	await _stage.play_hit(PLAYER_SIDE, true)
	await _stage.play_stat(PLAYER_SIDE, true)
	await _stage.play_stat(FOE_SIDE, false)
	assert_eq(_stage.get_sprite(PLAYER_SIDE).position, a["player_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).position, a["foe_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).modulate, Color.WHITE)
	assert_eq(_camera.offset, Vector2.ZERO, "retour immédiat au cadrage")
	assert_eq((_stage.get_node(^"%Flash") as ColorRect).color.a, 0.0)
	await _stage.play_faint(FOE_SIDE)
	assert_false(_stage.get_sprite(FOE_SIDE).visible, "K.O. : sprite tombé et effacé")
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible)


func test_exit_gives_back_npcs_on_their_cell_and_the_camera_unchanged() -> void:
	var zoom := _camera.zoom
	var position := _camera.position
	var offset := _camera.offset
	await _enter()
	await _stage.play_faint(FOE_SIDE)
	await _stage.exit()
	assert_false(_stage.is_active())
	for pair: Array in [[_mine, MINE_CELL], [_foe, FOE_CELL]]:
		var npc: Npc = pair[0]
		assert_true(npc.visible, "%s réaffiché" % npc.name)
		assert_eq(npc.modulate, Color.WHITE)
		assert_eq(npc.get_cell(), pair[1])
		assert_eq(npc.position, Grid.cell_to_world(pair[1]))
	assert_eq(_camera.zoom, zoom)
	assert_eq(_camera.position, position)
	assert_eq(_camera.offset, offset)
	assert_eq([_camera.limit_left, _camera.limit_top, _camera.limit_right,
		_camera.limit_bottom] as Array[int], LIMITS)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_false((_stage.get_node(^"%Backdrop") as CanvasItem).visible)


func test_reset_puts_everything_back_immediately() -> void:
	var position := _camera.position
	await _enter()
	_stage.reset()
	assert_false(_stage.is_active())
	assert_true(_mine.visible)
	assert_true(_foe.visible)
	assert_eq(_camera.zoom, Vector2.ONE)
	assert_eq(_camera.position, position)
	assert_eq(_camera.limit_right, LIMITS[2])
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_null(_stage.get_sprite(PLAYER_SIDE).texture)


func test_enter_during_a_battle_is_refused() -> void:
	await _enter()
	await _stage.enter(_camera, _foe, _mine, &"bulbasaur", &"bulbasaur")
	assert_push_error("déjà affiché")
	assert_string_ends_with(_stage.get_sprite(PLAYER_SIDE).texture.resource_path,
		"charmander_back.png", "le combat affiché ne change pas")
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)


func test_show_pokemon_without_world_npc_and_no_effect_when_shown() -> void:
	var rival: Array[Vector2i] = [RIVAL_CELL]
	await _stage.enter(_camera, _mine, null, &"charmander", &"bulbasaur", rival)
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_true(foe.visible, "sans PNJ : il apparaît à son ancre")
	assert_eq(foe.position, _anchors()["foe_feet"])
	_stage.show_pokemon(FOE_SIDE, &"bulbasaur")
	assert_eq(foe.position, _anchors()["foe_feet"], "déjà affiché : sans effet")
	assert_eq(foe.modulate, Color.WHITE)
	await _stage.play_faint(FOE_SIDE)
	_stage.show_pokemon(FOE_SIDE, &"squirtle")
	await wait_process_frames(2)
	assert_true(foe.visible, "le suivant entre en jeu")
	assert_string_ends_with(foe.texture.resource_path, "squirtle_front.png")
	await _stage.exit()
	assert_true(_mine.visible)


## Transition réelle : à mi-course, le décor est visible (jamais noir), la caméra est entre
## les deux cadrages et le sprite, entre la place du PNJ et son ancre, a une taille
## intermédiaire (effet de caméra, pas de gonflement sur place).
func test_real_transition_moves_camera_and_sprites_together() -> void:
	_stage.speed_scale = 1.0
	var rival: Array[Vector2i] = [RIVAL_CELL]
	_stage.enter(_camera, _mine, _foe, &"charmander", &"squirtle", rival)
	await wait_seconds(BattleStage.ENTER_DURATION * 0.45)
	var mine := _stage.get_sprite(PLAYER_SIDE)
	assert_between(_camera.zoom.x, 1.01, BattleStage.ZOOM - 0.01, "caméra en mouvement")
	assert_between(mine.scale.x, 1.1, 3.9, "taille intermédiaire")
	assert_ne(mine.position, _anchors()["player_feet"], "en chemin")
	assert_true(mine.visible)
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible)
	await wait_for_signal(_stage.entered, 2.0)
	assert_eq(mine.position, _anchors()["player_feet"])
	_stage.exit()
	await wait_for_signal(_stage.exited, 2.0)
	assert_true(_mine.visible)
	assert_eq(_camera.zoom, Vector2.ONE)


func test_no_orphans_after_a_full_battle() -> void:
	await _enter()
	await _stage.play_hit(FOE_SIDE, true)
	await _stage.exit()
	assert_no_new_orphans()


## Avec une arène (tapis du labo) : le cadrage suit BattleLayout.arena_focus, puis set_frame
## est oublié à la sortie.
func test_set_frame_frames_the_arena() -> void:
	var arena := Rect2(576, 480, 384, 288)
	var bounds := Rect2(0, 0, 1536, 1056)
	_stage.set_frame(arena, bounds)
	await _enter()
	var view := _stage.get_viewport().get_visible_rect().size
	assert_eq(_stage.get_focus(), BattleLayout.arena_focus(arena, bounds, view, BattleStage.ZOOM))
	await _stage.exit()
	await _enter()
	var cells: Array[Vector2i] = [RIVAL_CELL, MINE_CELL, FOE_CELL]
	assert_eq(_stage.get_focus(), BattleLayout.focus(cells), "cadrage oublié après la sortie")
