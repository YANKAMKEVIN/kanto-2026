extends GutTest
## Règles d'accès de GridWorld : limites, solide, eau, rebords, occupation.

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _world: GridWorld


func before_each() -> void:
	_world = GridWorld.new(Vector2i(10, 8))


# --- Limites -----------------------------------------------------------------

func test_size_and_bounds() -> void:
	assert_eq(_world.get_size(), Vector2i(10, 8))
	assert_true(_world.is_in_bounds(Vector2i(0, 0)))
	assert_true(_world.is_in_bounds(Vector2i(9, 7)))
	assert_false(_world.is_in_bounds(Vector2i(-1, 0)))
	assert_false(_world.is_in_bounds(Vector2i(0, -1)))
	assert_false(_world.is_in_bounds(Vector2i(10, 0)))
	assert_false(_world.is_in_bounds(Vector2i(0, 8)))


func test_empty_cell_can_be_entered_from_every_direction() -> void:
	for direction: Vector2i in DIRECTIONS:
		assert_true(_world.can_enter(Vector2i(4, 4), direction), str(direction))


func test_out_of_bounds_cannot_be_entered() -> void:
	assert_false(_world.can_enter(Vector2i(-1, 3), Vector2i.LEFT))
	assert_false(_world.can_enter(Vector2i(3, -1), Vector2i.UP))
	assert_false(_world.can_enter(Vector2i(10, 3), Vector2i.RIGHT))
	assert_false(_world.can_enter(Vector2i(3, 8), Vector2i.DOWN))


func test_non_cardinal_direction_is_refused() -> void:
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i.ZERO))
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i(1, 1)))
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i(0, 2)))


func test_setters_out_of_bounds_are_ignored() -> void:
	assert_false(_world.set_solid(Vector2i(-1, 0)))
	assert_false(_world.set_water(Vector2i(10, 0)))
	assert_false(_world.set_ledge(Vector2i(0, 8), GridWorld.Ledge.DOWN))
	assert_false(_world.is_solid(Vector2i(-1, 0)))
	assert_false(_world.is_water(Vector2i(10, 0)))
	assert_eq(_world.get_ledge(Vector2i(0, 8)), GridWorld.Ledge.NONE)


func test_zero_size_world_has_no_cell() -> void:
	var empty := GridWorld.new(Vector2i.ZERO)
	assert_false(empty.is_in_bounds(Vector2i.ZERO))
	assert_false(empty.can_enter(Vector2i.ZERO, Vector2i.DOWN))


# --- Solide et eau -----------------------------------------------------------

func test_solid_cell_cannot_be_entered() -> void:
	assert_true(_world.set_solid(Vector2i(2, 2)))
	assert_true(_world.is_solid(Vector2i(2, 2)))
	for direction: Vector2i in DIRECTIONS:
		assert_false(_world.can_enter(Vector2i(2, 2), direction))


func test_solid_can_be_cleared() -> void:
	_world.set_solid(Vector2i(2, 2))
	_world.set_solid(Vector2i(2, 2), false)
	assert_false(_world.is_solid(Vector2i(2, 2)))
	assert_true(_world.can_enter(Vector2i(2, 2), Vector2i.DOWN))


func test_water_cell_cannot_be_entered_on_foot() -> void:
	assert_true(_world.set_water(Vector2i(3, 6)))
	assert_true(_world.is_water(Vector2i(3, 6)))
	assert_false(_world.is_solid(Vector2i(3, 6)))
	assert_false(_world.can_enter(Vector2i(3, 6), Vector2i.DOWN))


func test_flags_are_independent() -> void:
	var cell := Vector2i(5, 5)
	_world.set_water(cell)
	_world.set_ledge(cell, GridWorld.Ledge.RIGHT)
	_world.set_solid(cell)
	_world.set_solid(cell, false)
	assert_true(_world.is_water(cell))
	assert_eq(_world.get_ledge(cell), GridWorld.Ledge.RIGHT)
	_world.set_water(cell, false)
	assert_eq(_world.get_ledge(cell), GridWorld.Ledge.RIGHT)
	_world.set_ledge(cell, GridWorld.Ledge.NONE)
	assert_false(_world.is_water(cell))
	assert_false(_world.is_solid(cell))


func test_footprint_marks_cells_relative_to_anchor() -> void:
	var footprint: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]
	assert_eq(_world.add_solid_footprint(Vector2i(4, 3), footprint), 6)
	for offset: Vector2i in footprint:
		assert_true(_world.is_solid(Vector2i(4, 3) + offset), str(offset))
	assert_false(_world.is_solid(Vector2i(4, 4)))
	assert_false(_world.is_solid(Vector2i(2, 3)))


func test_footprint_ignores_cells_outside_map() -> void:
	var footprint: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(_world.add_solid_footprint(Vector2i(8, 0), footprint), 2)
	assert_true(_world.is_solid(Vector2i(9, 0)))


# --- Rebords -----------------------------------------------------------------

func test_ledge_direction_mapping() -> void:
	assert_eq(GridWorld.ledge_direction(GridWorld.Ledge.NONE), Vector2i.ZERO)
	assert_eq(GridWorld.ledge_direction(GridWorld.Ledge.DOWN), Vector2i.DOWN)
	assert_eq(GridWorld.ledge_direction(GridWorld.Ledge.LEFT), Vector2i.LEFT)
	assert_eq(GridWorld.ledge_direction(GridWorld.Ledge.RIGHT), Vector2i.RIGHT)


func test_ledge_values_match_tile_data() -> void:
	# Donnée de tuile `ledge` : 0 aucun, 1 bas, 2 gauche, 3 droite (skill world-tiles).
	assert_eq(int(GridWorld.Ledge.NONE), 0)
	assert_eq(int(GridWorld.Ledge.DOWN), 1)
	assert_eq(int(GridWorld.Ledge.LEFT), 2)
	assert_eq(int(GridWorld.Ledge.RIGHT), 3)


func test_ledge_can_only_be_entered_in_its_direction() -> void:
	_world.set_ledge(Vector2i(4, 4), GridWorld.Ledge.DOWN)
	assert_true(_world.can_enter(Vector2i(4, 4), Vector2i.DOWN))
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i.UP))
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i.LEFT))
	assert_false(_world.can_enter(Vector2i(4, 4), Vector2i.RIGHT))


func test_step_target_on_free_cell_is_neighbour() -> void:
	assert_eq(_world.get_step_target(Vector2i(4, 4), Vector2i.RIGHT), Vector2i(5, 4))


func test_step_target_when_blocked_is_start() -> void:
	_world.set_solid(Vector2i(5, 4))
	assert_eq(_world.get_step_target(Vector2i(4, 4), Vector2i.RIGHT), Vector2i(4, 4))
	assert_eq(_world.get_step_target(Vector2i(0, 0), Vector2i.UP), Vector2i(0, 0))


func test_step_over_ledge_lands_two_cells_away() -> void:
	_world.set_ledge(Vector2i(4, 4), GridWorld.Ledge.DOWN)
	assert_eq(_world.get_step_target(Vector2i(4, 3), Vector2i.DOWN), Vector2i(4, 5))


func test_ledge_cannot_be_climbed_back() -> void:
	_world.set_ledge(Vector2i(4, 4), GridWorld.Ledge.DOWN)
	assert_eq(_world.get_step_target(Vector2i(4, 5), Vector2i.UP), Vector2i(4, 5))


func test_ledge_with_blocked_landing_is_refused() -> void:
	_world.set_ledge(Vector2i(4, 4), GridWorld.Ledge.DOWN)
	_world.set_solid(Vector2i(4, 5))
	assert_eq(_world.get_step_target(Vector2i(4, 3), Vector2i.DOWN), Vector2i(4, 3))


func test_ledge_at_map_edge_is_refused() -> void:
	_world.set_ledge(Vector2i(4, 7), GridWorld.Ledge.DOWN)
	assert_eq(_world.get_step_target(Vector2i(4, 6), Vector2i.DOWN), Vector2i(4, 6))


func test_double_ledge_is_refused() -> void:
	_world.set_ledge(Vector2i(4, 4), GridWorld.Ledge.RIGHT)
	_world.set_ledge(Vector2i(5, 4), GridWorld.Ledge.RIGHT)
	assert_eq(_world.get_step_target(Vector2i(3, 4), Vector2i.RIGHT), Vector2i(3, 4))


# --- Occupation --------------------------------------------------------------

func test_occupied_cell_blocks_other_entities() -> void:
	var npc := RefCounted.new()
	var player := RefCounted.new()
	assert_true(_world.occupy(Vector2i(2, 2), npc))
	assert_true(_world.is_occupied(Vector2i(2, 2)))
	assert_eq(_world.get_occupant(Vector2i(2, 2)), npc)
	assert_false(_world.can_enter(Vector2i(2, 2), Vector2i.DOWN))
	assert_false(_world.can_enter(Vector2i(2, 2), Vector2i.DOWN, player))


func test_occupant_can_enter_its_own_cell() -> void:
	var npc := RefCounted.new()
	_world.occupy(Vector2i(2, 2), npc)
	assert_true(_world.can_enter(Vector2i(2, 2), Vector2i.DOWN, npc))


func test_occupy_fails_when_taken_or_out_of_bounds() -> void:
	var a := RefCounted.new()
	var b := RefCounted.new()
	assert_true(_world.occupy(Vector2i(1, 1), a))
	assert_true(_world.occupy(Vector2i(1, 1), a), "réoccuper sa propre case est permis")
	assert_false(_world.occupy(Vector2i(1, 1), b))
	assert_false(_world.occupy(Vector2i(-1, 1), a))
	assert_false(_world.occupy(Vector2i(2, 1), null))


func test_release_only_by_occupant() -> void:
	var a := RefCounted.new()
	var b := RefCounted.new()
	_world.occupy(Vector2i(1, 1), a)
	_world.release(Vector2i(1, 1), b)
	assert_eq(_world.get_occupant(Vector2i(1, 1)), a)
	_world.release(Vector2i(1, 1), a)
	assert_null(_world.get_occupant(Vector2i(1, 1)))
	assert_true(_world.can_enter(Vector2i(1, 1), Vector2i.DOWN))


func test_move_occupant() -> void:
	var a := RefCounted.new()
	_world.occupy(Vector2i(1, 1), a)
	assert_true(_world.move_occupant(a, Vector2i(1, 1), Vector2i(1, 2)))
	assert_false(_world.is_occupied(Vector2i(1, 1)))
	assert_eq(_world.get_occupant(Vector2i(1, 2)), a)


func test_move_occupant_fails_onto_other_entity() -> void:
	var a := RefCounted.new()
	var b := RefCounted.new()
	_world.occupy(Vector2i(1, 1), a)
	_world.occupy(Vector2i(1, 2), b)
	assert_false(_world.move_occupant(a, Vector2i(1, 1), Vector2i(1, 2)))
	assert_eq(_world.get_occupant(Vector2i(1, 1)), a)
	assert_eq(_world.get_occupant(Vector2i(1, 2)), b)


func test_freed_entity_no_longer_occupies() -> void:
	var node := Node.new()
	_world.occupy(Vector2i(3, 3), node)
	node.free()
	assert_null(_world.get_occupant(Vector2i(3, 3)))
	assert_true(_world.can_enter(Vector2i(3, 3), Vector2i.DOWN))


func test_occupation_does_not_change_terrain() -> void:
	var a := RefCounted.new()
	_world.occupy(Vector2i(3, 3), a)
	assert_false(_world.is_solid(Vector2i(3, 3)))


# --- Accessibilité -----------------------------------------------------------

func test_find_reachable_in_enclosed_area() -> void:
	# Enclos 3×3 fermé par des murs, autour de (5,4).
	for x: int in range(3, 8):
		_world.set_solid(Vector2i(x, 2))
		_world.set_solid(Vector2i(x, 6))
	for y: int in range(2, 7):
		_world.set_solid(Vector2i(3, y))
		_world.set_solid(Vector2i(7, y))
	var reached := _world.find_reachable(Vector2i(5, 4))
	assert_eq(reached.size(), 9)
	assert_true(reached.has(Vector2i(4, 3)))
	assert_false(reached.has(Vector2i(0, 0)))


func test_find_reachable_follows_one_way_ledges() -> void:
	# Mur horizontal en y = 4 avec un rebord vers le bas en (5,4).
	for x: int in range(10):
		_world.set_solid(Vector2i(x, 4))
	_world.set_solid(Vector2i(5, 4), false)
	_world.set_ledge(Vector2i(5, 4), GridWorld.Ledge.DOWN)
	var from_top := _world.find_reachable(Vector2i(0, 0))
	assert_true(from_top.has(Vector2i(0, 7)), "le haut rejoint le bas en sautant")
	assert_false(from_top.has(Vector2i(5, 4)), "on ne s'arrête jamais sur un rebord")
	var from_bottom := _world.find_reachable(Vector2i(0, 7))
	assert_false(from_bottom.has(Vector2i(0, 0)), "le bas ne remonte pas")


func test_find_reachable_outside_map_is_empty() -> void:
	assert_eq(_world.find_reachable(Vector2i(-1, -1)).size(), 0)
