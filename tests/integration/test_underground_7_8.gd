extends GutTest
## Le souterrain des Routes 7 et 8 (jalon 20 T15, docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23
## §4) sur la **vraie scène** : ni grotte ni intérieur (profil `underground`, hors `caves.json`),
## grille de la scène = grille du plan, **aucune rencontre** (ni herbe ni table), un seul
## itinéraire ouest → est, couloir de deux cases au moins (le compagnon suit), escaliers vers les
## deux bâtiments d'entrée et retours, indices des objets cachés, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const PLAN_PATH := "res://tools/plans/souterrain_7_8.txt"
const SIZE := Vector2i(48, 10)
const NODE_BUDGET := 3000
## Escaliers → [bâtiment, direction du pas].
const STAIRS: Dictionary = {
	Vector2i(2, 5): [&"route_7_underground_gate", Vector2i.LEFT],
	Vector2i(2, 6): [&"route_7_underground_gate", Vector2i.LEFT],
	Vector2i(45, 7): [&"route_8_underground_gate", Vector2i.RIGHT],
	Vector2i(45, 8): [&"route_8_underground_gate", Vector2i.RIGHT],
}

var _plan: PlanGrid
var _map: GameMap
var _grid: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MapCatalog.scene_path(&"underground_path_7_8")) as PackedScene).instantiate() \
		as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func test_metadata_neither_cave_nor_interior() -> void:
	assert_eq(_map.map_id, &"underground_path_7_8")
	assert_eq(_map.size, SIZE)
	assert_false(_map.interior, "compagnon visible")
	assert_eq(_map.light_profile, &"underground")
	var caves := CaveLibrary.new()
	caves.load_file()
	assert_false(caves.is_cave(&"underground_path_7_8"), "hors caves.json : pas de Corde Sortie")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"underground_path_7_8"), &"underground")


func test_scene_grid_is_the_functional_grid_without_grass() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell) or _plan.blocking_cells().has(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = souterrain_7_8.txt, aucune herbe")
	assert_false(FileAccess.file_exists("res://data/encounters/underground_path_7_8.json"),
		"aucune table de rencontres")


func test_one_route_west_to_east_two_cells_wide() -> void:
	var dist := GridPaths.distances(_grid, [Vector2i(3, 5)])
	assert_true(dist.has(Vector2i(44, 7)), "ouest → est")
	gut.p("souterrain 7-8 : %d pas" % int(dist[Vector2i(44, 7)]))
	# Largeur lue sur la grille (sol praticable `.` `E`) : les cases-indices des objets cachés
	# sont du sol, bloqué seulement par l'objet (règle de la grille, plan_check_routes_j20.py).
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if not _plan.is_walkable(cell) or _plan.blocking_cells().has(cell):
				continue
			var wide := false
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1),
					Vector2i(-1, -1)]:
				var origin := cell + corner
				var square := true
				for offset: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
						Vector2i(1, 1)]:
					square = square and _plan.is_walkable(origin + offset)
				wide = wide or square
			assert_true(wide, "%s dans un carré 2 × 2 praticable" % cell)


func test_stairs_lead_to_both_entrance_buildings_and_back() -> void:
	for cell: Vector2i in STAIRS:
		var info: Array = STAIRS[cell]
		var warp := _map.get_warps().find_on_step(cell, info[1])
		assert_not_null(warp, "escalier %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [info[0], &"from_underground"])
	for route: int in [7, 8]:
		var gate := (load(MapCatalog.scene_path(StringName("route_%d_underground_gate" % route)))
			as PackedScene).instantiate() as GameMap
		add_child_autofree(gate)
		assert_true(gate.has_spawn(&"from_underground"))
		for i: int in 2:
			var suffix: String = ["n", "s"][i]
			var down := gate.get_warps().find_on_step(Vector2i(4 + i, 2), Vector2i.UP)
			assert_not_null(down, "route %d : escalier %d" % [route, i])
			if down != null:
				var spawn := StringName("from_route_%d_%s" % [route, suffix])
				assert_eq([down.target_map, down.target_spawn], [&"underground_path_7_8", spawn])
				assert_true(_map.has_spawn(spawn), String(spawn))
	assert_eq(_map.get_spawn_cell(&"from_route_7_n"), Vector2i(3, 5))
	assert_eq(_map.get_spawn_cell(&"from_route_8_s"), Vector2i(44, 8))


func test_hidden_item_clues_are_blocked() -> void:
	# Points EXAMINER, dialogues et scènes : avec la vie (T17).
	for i: int in 2:
		var clue := _plan.cell_of("souterrain_hidden_%d" % (i + 1))
		assert_true(_grid.is_solid(clue), "%s bloquée" % clue)
		assert_not_null(_map.get_node_or_null(NodePath("Entities/CrackedTile%d" % i)))


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("underground_path_7_8 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)
