extends GutTest
## Constantes et conversions de Grid.


func test_tile_size_is_96() -> void:
	assert_eq(Grid.TILE_SIZE, 96)
	assert_eq(Grid.HALF_TILE * 2, Grid.TILE_SIZE)


func test_speeds_are_positive_and_running_is_faster() -> void:
	assert_gt(Grid.WALK_STEP_DURATION, 0.0)
	assert_gt(Grid.RUN_STEP_DURATION, 0.0)
	assert_lt(Grid.RUN_STEP_DURATION, Grid.WALK_STEP_DURATION)
	assert_lt(Grid.TURN_HOLD_DURATION, Grid.WALK_STEP_DURATION)


func test_cell_to_world_is_bottom_center() -> void:
	assert_eq(Grid.cell_to_world(Vector2i(0, 0)), Vector2(48, 96))
	assert_eq(Grid.cell_to_world(Vector2i(2, 3)), Vector2(240, 384))


func test_world_to_cell_round_trip() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(5, 7), Vector2i(47, 31), Vector2i(-1, -1)]:
		assert_eq(Grid.world_to_cell(Grid.cell_to_world(cell)), cell, str(cell))


func test_world_to_cell_of_cell_center() -> void:
	var cell := Vector2i(12, 9)
	var center := Vector2(cell * Grid.TILE_SIZE) + Vector2(Grid.HALF_TILE, Grid.HALF_TILE)
	assert_eq(Grid.world_to_cell(center), cell)


func test_world_to_cell_top_edge_belongs_to_cell_above() -> void:
	assert_eq(Grid.world_to_cell(Vector2(10, 1)), Vector2i(0, 0))
	assert_eq(Grid.world_to_cell(Vector2(10, 96)), Vector2i(0, 0))
	assert_eq(Grid.world_to_cell(Vector2(10, 97)), Vector2i(0, 1))


func test_map_pixel_rect() -> void:
	assert_eq(Grid.map_pixel_rect(Vector2i(48, 32)), Rect2i(0, 0, 4608, 3072))


func test_is_cardinal() -> void:
	assert_true(Grid.is_cardinal(Vector2i.UP))
	assert_true(Grid.is_cardinal(Vector2i.DOWN))
	assert_true(Grid.is_cardinal(Vector2i.LEFT))
	assert_true(Grid.is_cardinal(Vector2i.RIGHT))
	assert_false(Grid.is_cardinal(Vector2i.ZERO))
	assert_false(Grid.is_cardinal(Vector2i(1, 1)))
	assert_false(Grid.is_cardinal(Vector2i(2, 0)))


# --- Noms de direction et « se tourner vers » (jalon 3B) ---------------------------------

func test_direction_names_round_trip() -> void:
	for name: String in ["up", "down", "left", "right"]:
		assert_true(Grid.is_direction_name(name), name)
		assert_eq(Grid.direction_name(Grid.direction_from_name(name)), StringName(name))
	assert_eq(Grid.direction_from_name("up"), Vector2i.UP)
	assert_eq(Grid.direction_from_name("left"), Vector2i.LEFT)


func test_unknown_direction_names() -> void:
	for name: String in ["", "north", "Up", "player", "oak"]:
		assert_false(Grid.is_direction_name(name), name)
		assert_eq(Grid.direction_from_name(name), Vector2i.ZERO, name)
	assert_eq(Grid.direction_name(Vector2i.ZERO), &"")
	assert_eq(Grid.direction_name(Vector2i(1, 1)), &"")


func test_dominant_direction() -> void:
	var from := Vector2i(5, 5)
	assert_eq(Grid.dominant_direction(from, Vector2i(9, 6)), Vector2i.RIGHT)
	assert_eq(Grid.dominant_direction(from, Vector2i(1, 4)), Vector2i.LEFT)
	assert_eq(Grid.dominant_direction(from, Vector2i(6, 1)), Vector2i.UP)
	assert_eq(Grid.dominant_direction(from, Vector2i(4, 9)), Vector2i.DOWN)
	assert_eq(Grid.dominant_direction(from, Vector2i(6, 6)), Vector2i.DOWN,
		"à égalité, l'axe vertical")
	assert_eq(Grid.dominant_direction(from, from), Vector2i.ZERO)
	# Scène du labo (jalon 3B §3.4) : le rival (9, 6) vers Chen (8, 4), puis vers le joueur.
	assert_eq(Grid.dominant_direction(Vector2i(9, 6), Vector2i(8, 4)), Vector2i.UP)
	assert_eq(Grid.dominant_direction(Vector2i(9, 6), Vector2i(7, 7)), Vector2i.LEFT)
