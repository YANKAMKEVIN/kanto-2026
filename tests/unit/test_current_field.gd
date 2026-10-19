extends GutTest
## CurrentField (jalon 24, T9 ; dossier 27 §7.4, `jalon-24.md` §2.6) : trajet d'un courant actif,
## calculé d'avance (cases, directions, fin sur l'eau calme, la rive ou un passage), erreurs de
## données (boucle, blocage, longueur). Sur les vraies grilles : mêmes trajets que
## `tools/art/plan_check_j24_seafoam.py` (critère e).

const SeafoamFloor := preload("res://tests/helpers/seafoam_floor.gd")

var _grid: GridWorld


func before_each() -> void:
	# 6 × 3, tout en eau surfable.
	_grid = GridWorld.new(Vector2i(6, 3))
	for y: int in 3:
		for x: int in 6:
			_grid.set_surfable(Vector2i(x, y))


func test_not_a_current() -> void:
	var ride := CurrentField.ride(_grid, Vector2i(0, 0))
	assert_eq(ride.status, CurrentField.Status.NOT_A_CURRENT)
	assert_eq(ride.end, Vector2i(0, 0))
	assert_false(ride.is_sliding())
	assert_true(ride.can_save())
	assert_false(CurrentField.is_active_at(_grid, Vector2i(0, 0)))


func test_ride_stops_on_calm_water() -> void:
	_grid.set_current(Vector2i(0, 1), Vector2i.RIGHT)
	_grid.set_current(Vector2i(1, 1), Vector2i.RIGHT)
	_grid.set_current(Vector2i(2, 1), Vector2i.DOWN)
	var ride := CurrentField.ride(_grid, Vector2i(0, 1))
	assert_true(ride.is_ok())
	assert_eq(ride.cells, [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)] as Array[Vector2i])
	assert_eq(ride.facings, [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.DOWN] as Array[Vector2i])
	assert_eq(ride.end, Vector2i(2, 2))
	assert_false(ride.warp)
	assert_false(ride.dismounts)


func test_ride_is_played_step_by_step_without_save() -> void:
	_grid.set_current(Vector2i(0, 0), Vector2i.RIGHT)
	_grid.set_current(Vector2i(1, 0), Vector2i.RIGHT)
	var ride := CurrentField.ride(_grid, Vector2i(0, 0))
	assert_eq(ride.size(), 2)
	assert_true(ride.is_sliding())
	assert_false(ride.can_save(), "pas de sauvegarde pendant la glissade")
	assert_eq(ride.next_direction(), Vector2i.RIGHT)
	ride.step_done()
	ride.step_done()
	assert_false(ride.is_sliding())
	assert_true(ride.can_save())
	assert_eq(ride.next_direction(), Vector2i.ZERO)
	ride.step_done()
	assert_eq(ride.steps_done, 2)


func test_ride_dismounts_on_land() -> void:
	_grid.set_surfable(Vector2i(3, 0), false)
	_grid.set_water(Vector2i(3, 0), false)
	_grid.set_current(Vector2i(1, 0), Vector2i.RIGHT)
	_grid.set_current(Vector2i(2, 0), Vector2i.RIGHT)
	var ride := CurrentField.ride(_grid, Vector2i(1, 0))
	assert_true(ride.is_ok())
	assert_eq(ride.end, Vector2i(3, 0))
	assert_true(ride.dismounts)


func test_ride_ends_on_a_terminal() -> void:
	_grid.set_current(Vector2i(0, 2), Vector2i.RIGHT)
	_grid.set_current(Vector2i(1, 2), Vector2i.RIGHT)
	_grid.set_current(Vector2i(2, 2), Vector2i.RIGHT)
	var ride := CurrentField.ride(_grid, Vector2i(0, 2), {Vector2i(2, 2): true})
	assert_true(ride.is_ok())
	assert_eq(ride.end, Vector2i(2, 2))
	assert_true(ride.warp, "passage : transfert")


func test_blocked_loop_and_too_long_are_data_errors() -> void:
	_grid.set_current(Vector2i(5, 0), Vector2i.RIGHT)
	assert_eq(CurrentField.ride(_grid, Vector2i(5, 0)).status, CurrentField.Status.BLOCKED,
		"sort de la carte")
	_grid.set_current(Vector2i(0, 0), Vector2i.RIGHT)
	_grid.set_solid(Vector2i(1, 0))
	assert_eq(CurrentField.ride(_grid, Vector2i(0, 0)).status, CurrentField.Status.BLOCKED)
	_grid.set_solid(Vector2i(1, 0), false)
	_grid.set_water(Vector2i(1, 0))
	_grid.set_surfable(Vector2i(1, 0), false)
	assert_eq(CurrentField.ride(_grid, Vector2i(0, 0)).status, CurrentField.Status.BLOCKED,
		"eau décor")
	var loop := GridWorld.new(Vector2i(2, 2))
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		loop.set_surfable(cell)
	loop.set_current(Vector2i(0, 0), Vector2i.RIGHT)
	loop.set_current(Vector2i(1, 0), Vector2i.DOWN)
	loop.set_current(Vector2i(1, 1), Vector2i.LEFT)
	loop.set_current(Vector2i(0, 1), Vector2i.UP)
	assert_eq(CurrentField.ride(loop, Vector2i(0, 0)).status, CurrentField.Status.LOOP)
	var long_grid := GridWorld.new(Vector2i(CurrentField.MAX_STEPS + 3, 1))
	for x: int in CurrentField.MAX_STEPS + 3:
		long_grid.set_surfable(Vector2i(x, 0))
		long_grid.set_current(Vector2i(x, 0), Vector2i.RIGHT)
	long_grid.set_current(Vector2i(CurrentField.MAX_STEPS + 2, 0), Vector2i.ZERO)
	assert_eq(CurrentField.ride(long_grid, Vector2i(0, 0)).status, CurrentField.Status.TOO_LONG)


func test_ride_ignores_the_mover_but_not_others() -> void:
	var player := RefCounted.new()
	_grid.set_current(Vector2i(0, 0), Vector2i.RIGHT)
	_grid.occupy(Vector2i(0, 0), player)
	assert_true(CurrentField.ride(_grid, Vector2i(0, 0), {}, player).is_ok())
	_grid.occupy(Vector2i(1, 0), RefCounted.new())
	assert_eq(CurrentField.ride(_grid, Vector2i(0, 0), {}, player).status,
		CurrentField.Status.BLOCKED)


# --- Vraies grilles ------------------------------------------------------------------

func test_current_1_on_b3f_matches_the_python_check() -> void:
	var storey := _floor(&"seafoam_b3f", StoryFlags.new())
	var terms := storey.terminals_for(storey.open_holes)
	var ride := CurrentField.ride(storey.grid, Vector2i(15, 8), terms)
	assert_true(ride.is_ok())
	var path: Array[Vector2i] = [ride.start]
	path.append_array(ride.cells)
	# Trajet affiché par plan_check_j24_seafoam.py (critère e).
	var expected: Array[Vector2i] = []
	for xy: Array in [[15, 8], [15, 9], [15, 10], [15, 11], [16, 11], [17, 11], [18, 11],
			[19, 11], [20, 11], [20, 12], [20, 13], [20, 14], [20, 15], [20, 16], [20, 17]]:
		expected.append(Vector2i(xy[0], xy[1]))
	assert_eq(path, expected)
	assert_true(ride.warp, "fin : passage W1 → B4F, mer est")
	for source: Vector2i in [Vector2i(18, 7), Vector2i(19, 7)]:
		var other := CurrentField.ride(storey.grid, source, terms)
		assert_true(other.is_ok() and other.warp, str(source))
		assert_eq(other.end, Vector2i(20, 17))


func test_current_1_is_calm_once_both_b2f_holes_are_filled() -> void:
	var flags := StoryFlags.new()
	flags.set_flag(&"seafoam_b2f_hole_1_filled")
	assert_true(_floor(&"seafoam_b3f", flags).grid.is_current(Vector2i(15, 8)), "un seul trou")
	flags.set_flag(&"seafoam_b2f_hole_2_filled")
	var storey := _floor(&"seafoam_b3f", flags)
	assert_false(storey.grid.is_current(Vector2i(15, 8)))
	assert_eq(CurrentField.ride(storey.grid, Vector2i(15, 8)).status,
		CurrentField.Status.NOT_A_CURRENT)


func test_current_2_on_b4f_carries_to_the_central_platform() -> void:
	var storey := _floor(&"seafoam_b4f", StoryFlags.new())
	var terms := storey.terminals_for(storey.open_holes)
	for source: Vector2i in [Vector2i(4, 14), Vector2i(5, 14)]:
		var ride := CurrentField.ride(storey.grid, source, terms)
		assert_true(ride.is_ok(), str(source))
		assert_eq(ride.end, Vector2i(7, 11), "escalier de la plateforme")
		assert_true(ride.dismounts)
		assert_false(ride.warp)


func test_every_current_cell_of_the_grids_ends_well() -> void:
	for map_id: StringName in [&"seafoam_b3f", &"seafoam_b4f"]:
		var storey := _floor(map_id, StoryFlags.new())
		var terms := storey.terminals_for(storey.open_holes)
		var cells := storey.state.active_current_cells()
		assert_gt(cells.size(), 0)
		for cell: Vector2i in cells:
			assert_true(CurrentField.ride(storey.grid, cell, terms).is_ok(), "%s %s" % [map_id, cell])


func _floor(map_id: StringName, flags: StoryFlags) -> SeafoamFloor:
	var state := SeafoamState.new()
	state.load_file()
	var storey := SeafoamFloor.new()
	storey.setup(map_id, state.floor_state(map_id, flags))
	return storey
