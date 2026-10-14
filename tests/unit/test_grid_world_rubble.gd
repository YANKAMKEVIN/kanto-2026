extends GutTest
## Gravats dans la grille (jalon 12, T20 ; `jalon-12.md` §2.5) : drapeau informatif comme les
## hautes herbes (aucune règle de déplacement), lu par [GameMap] depuis la donnée de tuile
## `rubble` ; les vraies cartes : gravats du Mont Sélénite = cases `g` du plan, aucune ailleurs
## (Route 1, Route 3, Forêt de Jade).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLOORS: Dictionary = {
	&"mt_moon_1f": "res://tools/plans/mont_selenite_1f.txt",
	&"mt_moon_b1f": "res://tools/plans/mont_selenite_b1f.txt",
	&"mt_moon_b2f": "res://tools/plans/mont_selenite_b2f.txt",
}


func test_rubble_flag_is_independent_and_informative() -> void:
	var grid := GridWorld.new(Vector2i(4, 4))
	var cell := Vector2i(1, 1)
	assert_false(grid.is_rubble(cell))
	assert_true(grid.set_rubble(cell))
	assert_true(grid.is_rubble(cell))
	assert_false(grid.is_tall_grass(cell), "pas d'herbe")
	assert_false(grid.is_solid(cell), "pas solide")
	assert_true(grid.can_enter(cell, Vector2i.RIGHT), "on y marche")
	assert_true(grid.is_free(cell), "on s'y tient")
	assert_eq(grid.get_step_target(Vector2i(0, 1), Vector2i.RIGHT), cell)
	# Les autres drapeaux de la case ne bougent pas.
	grid.set_tall_grass(cell)
	grid.set_ledge(cell, GridWorld.Ledge.DOWN)
	assert_true(grid.is_rubble(cell))
	grid.set_rubble(cell, false)
	assert_false(grid.is_rubble(cell))
	assert_true(grid.is_tall_grass(cell), "herbe gardée")
	assert_eq(grid.get_ledge(cell), GridWorld.Ledge.DOWN, "rebord gardé")
	assert_false(grid.set_rubble(Vector2i(9, 9)), "hors carte")
	assert_false(grid.is_rubble(Vector2i(-1, 0)))


func test_real_floors_read_rubble_exactly_on_g_cells() -> void:
	for map_id: StringName in FLOORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(FLOORS[map_id]), plan.error)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		var grid := map.get_grid()
		var count := 0
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(grid.is_rubble(cell), plan.at(cell) == "g", "%s %s" % [map_id, cell])
				if grid.is_rubble(cell):
					count += 1
					assert_false(grid.is_solid(cell), "%s %s : praticable" % [map_id, cell])
		assert_gt(count, 0, "%s : des gravats" % map_id)
		map.free()


func test_no_rubble_outside_caves() -> void:
	for map_id: StringName in [&"route_1", &"route_3", &"viridian_forest", &"pewter_city"]:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		var grid := map.get_grid()
		var size := grid.get_size()
		var found := 0
		for y: int in size.y:
			for x: int in size.x:
				if grid.is_rubble(Vector2i(x, y)):
					found += 1
		assert_eq(found, 0, "%s : aucun gravat" % map_id)
		map.free()
