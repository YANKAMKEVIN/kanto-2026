extends GutTest
## CutsceneMoves : case d'arrivée « à côté de » et chemin du suiveur (jalon 3B §2.3).

const NEAR_PLAYER: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]

var _world: GridWorld


func before_each() -> void:
	_world = GridWorld.new(Vector2i(48, 34))


func test_resolve_near_takes_the_first_free_offset() -> void:
	var player := RefCounted.new()
	_world.occupy(Vector2i(23, 3), player)
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(23, 3), NEAR_PLAYER),
		Vector2i(24, 3))


func test_resolve_near_skips_solid_and_occupied_cells() -> void:
	# Chemin de la Route 1 : clôture à droite de (24, 3), joueur en (24, 3).
	_world.set_solid(Vector2i(25, 3))
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(24, 3), NEAR_PLAYER),
		Vector2i(23, 3))
	_world.occupy(Vector2i(23, 3), RefCounted.new())
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(24, 3), NEAR_PLAYER),
		Vector2i(24, 4), "puis la case du dessous")
	_world.set_water(Vector2i(24, 4))
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(24, 3), NEAR_PLAYER),
		CutsceneStep.NO_CELL, "aucune case libre")


func test_resolve_near_ignores_the_mover_and_the_anchor_itself() -> void:
	var oak := RefCounted.new()
	_world.occupy(Vector2i(24, 3), oak)
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(23, 3), NEAR_PLAYER, oak),
		Vector2i(24, 3), "sa propre case lui convient")
	var zero: Array[Vector2i] = [Vector2i.ZERO]
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(5, 5), zero), CutsceneStep.NO_CELL)
	assert_eq(CutsceneMoves.resolve_near(_world, Vector2i(0, 0), [Vector2i(-1, 0)]
		as Array[Vector2i]), CutsceneStep.NO_CELL, "hors carte")


func test_follow_path_is_one_step_behind() -> void:
	var down: Array[Vector2i] = [Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN]
	# Chen en (24, 3), le joueur à sa gauche en (23, 3) : un pas vers Chen, puis ses pas.
	var path := CutsceneMoves.follow_path(Vector2i(23, 3), Vector2i(24, 3), down)
	assert_eq(path, [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.DOWN] as Array[Vector2i])
	var follower := CutsceneMoves.path_cells(Vector2i(23, 3), path)
	var leader := CutsceneMoves.path_cells(Vector2i(24, 3), down)
	assert_eq(follower[-1], leader[-2], "finit sur l'avant-dernière case du meneur")
	for i: int in path.size():
		var leader_before: Vector2i = Vector2i(24, 3) if i == 0 else leader[i - 1]
		assert_eq(follower[i], leader_before, "entre dans la case que le meneur quitte")


func test_follow_path_needs_neighbours_and_a_moving_leader() -> void:
	var down: Array[Vector2i] = [Vector2i.DOWN]
	assert_true(CutsceneMoves.follow_path(Vector2i(20, 3), Vector2i(24, 3), down).is_empty())
	assert_true(CutsceneMoves.follow_path(Vector2i(23, 2), Vector2i(24, 3), down).is_empty(),
		"diagonale")
	assert_true(CutsceneMoves.follow_path(Vector2i(24, 3), Vector2i(24, 3), down).is_empty())
	assert_true(CutsceneMoves.follow_path(Vector2i(23, 3), Vector2i(24, 3), []).is_empty())
	assert_eq(CutsceneMoves.follow_path(Vector2i(24, 2), Vector2i(24, 3), down),
		[Vector2i.DOWN] as Array[Vector2i], "un seul pas du meneur : le suiveur prend sa case")


func test_path_cells() -> void:
	assert_eq(CutsceneMoves.path_cells(Vector2i(7, 9), [Vector2i.UP, Vector2i.UP]
		as Array[Vector2i]), [Vector2i(7, 8), Vector2i(7, 7)] as Array[Vector2i])
	assert_true(CutsceneMoves.path_cells(Vector2i(7, 9), []).is_empty())
