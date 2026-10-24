extends GutTest
## FishingSpot (jalon 22 T3, §2.5) : case d'eau pêchable devant le joueur seulement (pas en
## diagonale, pas derrière une entité, pas sur la Piste, pas depuis l'eau ni depuis un mur).
##
## Carte de test 5 × 5 : colonne x = 3 en eau, x = 4 en eau ; seules (3, 1..3) sont pêchables.
## Le joueur se tient en (2, 2).

const PLAYER: Vector2i = Vector2i(2, 2)


func _grid() -> GridWorld:
	var grid := GridWorld.new(Vector2i(5, 5))
	for y: int in 5:
		grid.set_water(Vector2i(3, y))
		grid.set_water(Vector2i(4, y))
	return grid


func _fishable() -> Dictionary[Vector2i, bool]:
	return {Vector2i(3, 1): true, Vector2i(3, 2): true, Vector2i(3, 3): true}


func test_water_in_front_is_returned() -> void:
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i.RIGHT, false, _fishable()),
		Vector2i(3, 2))


func test_not_facing_water_gives_none() -> void:
	for facing: Vector2i in [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		assert_eq(FishingSpot.in_front(_grid(), PLAYER, facing, false, _fishable()),
			FishingSpot.NONE)


func test_diagonal_is_refused() -> void:
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i(1, 1), false, _fishable()),
		FishingSpot.NONE)
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i(1, -1), false, _fishable()),
		FishingSpot.NONE)
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i.ZERO, false, _fishable()),
		FishingSpot.NONE)


func test_water_not_marked_fishable_gives_none() -> void:
	var grid := _grid()
	var fishable: Dictionary[Vector2i, bool] = {}
	assert_eq(FishingSpot.in_front(grid, PLAYER, Vector2i.RIGHT, false, fishable),
		FishingSpot.NONE)
	fishable[Vector2i(3, 2)] = false
	assert_eq(FishingSpot.in_front(grid, PLAYER, Vector2i.RIGHT, false, fishable),
		FishingSpot.NONE)


func test_fishable_mark_on_dry_land_is_ignored() -> void:
	var fishable: Dictionary[Vector2i, bool] = {Vector2i(1, 2): true}
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i.LEFT, false, fishable),
		FishingSpot.NONE)


func test_entity_in_front_blocks_fishing() -> void:
	var grid := _grid()
	var swimmer := RefCounted.new()
	assert_true(grid.occupy(Vector2i(3, 2), swimmer))
	assert_eq(FishingSpot.in_front(grid, PLAYER, Vector2i.RIGHT, false, _fishable()),
		FishingSpot.NONE)


func test_cycling_road_forbids_fishing() -> void:
	assert_eq(FishingSpot.in_front(_grid(), PLAYER, Vector2i.RIGHT, true, _fishable()),
		FishingSpot.NONE)


func test_player_must_stand_on_walkable_cell() -> void:
	var grid := _grid()
	var fishable := _fishable()
	fishable[Vector2i(4, 2)] = true
	# Depuis l'eau (3, 2), vers (4, 2) : refusé.
	assert_eq(FishingSpot.in_front(grid, Vector2i(3, 2), Vector2i.RIGHT, false, fishable),
		FishingSpot.NONE)
	# Depuis une case solide : refusé.
	grid.set_solid(PLAYER)
	assert_eq(FishingSpot.in_front(grid, PLAYER, Vector2i.RIGHT, false, fishable),
		FishingSpot.NONE)


func test_out_of_bounds_gives_none() -> void:
	var fishable: Dictionary[Vector2i, bool] = {Vector2i(-1, 2): true}
	assert_eq(FishingSpot.in_front(_grid(), Vector2i(0, 2), Vector2i.LEFT, false, fishable),
		FishingSpot.NONE)
	assert_eq(FishingSpot.in_front(null, PLAYER, Vector2i.RIGHT, false, _fishable()),
		FishingSpot.NONE)
