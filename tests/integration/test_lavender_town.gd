extends GutTest
## Carte lavender_town (Lavanville, jalon 18 T14, docs/tech/jalon-18.md §4.1 à §4.3 ; dossier 21 §6)
## sur la vraie scène : métadonnées, **grille de la scène = grille fonctionnelle**
## `tools/plans/lavanville.txt`, raccords (nord vers la Route 10, ouest et sud `coming_soon`),
## six portes, **sans vie** (aucun PNJ, examen ni déclencheur ; case du panneau du Scope du J19
## libre), budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/lavender_town.tscn"
const PLAN_PATH := "res://tools/plans/lavanville.txt"
const SIZE := Vector2i(44, 36)
const NODE_BUDGET := 3000
const ENTRY := Vector2i(22, 1)
## Porte → [intérieur, spawn d'ici].
const DOORS := {
	Vector2i(8, 21): [&"lavender_center", &"retour_centre"],
	Vector2i(9, 21): [&"lavender_center", &"retour_centre"],
	Vector2i(30, 21): [&"lavender_mart", &"retour_boutique"],
	Vector2i(31, 21): [&"lavender_mart", &"retour_boutique"],
	Vector2i(14, 9): [&"pokemon_house", &"retour_fuji"],
	Vector2i(15, 9): [&"pokemon_house", &"retour_fuji"],
	Vector2i(6, 9): [&"lavender_house_1", &"retour_maison_1"],
	Vector2i(39, 21): [&"lavender_house_2", &"retour_maison_2"],
	Vector2i(34, 10): [&"pokemon_tower_1f", &"retour_tour"],
	Vector2i(35, 10): [&"pokemon_tower_1f", &"retour_tour"],
}

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func _reach() -> Dictionary:
	var terrain := GridPaths.relief(_grid, SIZE)
	var stops: Dictionary = {}
	for warp: Warp in _map.get_warps().get_all():
		if warp.trigger == Warp.Trigger.STEP_ON:
			stops[warp.cell] = true
	return GridPaths.distances(terrain, [ENTRY], stops)


func test_metadata_light_and_zone() -> void:
	assert_eq(_map.map_id, &"lavender_town")
	assert_eq(_map.display_name, "Lavanville")
	assert_eq(_map.region, "Kanto")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"lavender")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"lavender_town"), &"lavender")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"lavender_town"), &"lavender_town")
	assert_eq(zones.zone_of(&"pokemon_tower_1f"), &"lavender_town")
	assert_not_null(_map.get_node_or_null(^"PaintedGround"))


func test_scene_grid_is_the_functional_grid() -> void:
	# Panneaux : positions `bloque` posées sur une case de pelouse ou de pavés (décor, solide) ;
	# cases des PNJ : réservées, libres au T14.
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ville") + _plan.cells_at(
		"panneau_tour") + _plan.cells_at("panneau_fuji")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var ok := _grid.is_solid(cell) == (not _plan.is_walkable(cell) or signs.has(cell))
			ok = ok and not _grid.is_water(cell) and not _grid.is_tall_grass(cell)
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/lavanville.txt")
	assert_eq(_plan.walkable, ".pD")


func test_without_life() -> void:
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 0, "aucun examen")
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0, "aucun déclencheur")
	assert_eq(_map.get_npcs().size(), 0, "aucun PNJ")
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "pnj":
			for cell: Vector2i in _plan.cells_at(id):
				assert_false(_grid.is_solid(cell) or _grid.is_occupied(cell),
					"%s : case réservée libre" % id)
	# Emplacement du panneau du Scope du J19 (42, 11) : rien n'y est posé.
	var scope := _plan.cell_of("panneau_scope_j19")
	assert_eq(scope, Vector2i(42, 11))
	assert_false(_grid.is_solid(scope))
	assert_true(_reach().has(scope + Vector2i.LEFT), "lisible depuis (41, 11)")


func test_north_edge_leads_to_route_10_or_coming_soon() -> void:
	var built := MapCatalog.has_map(&"route_10")
	var suffixes := ["w", "c", "e"]
	for i: int in 3:
		var cell := Vector2i(21 + i, 0)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.UP)
		assert_not_null(warp, "raccord nord %s" % cell)
		if warp != null:
			if built:
				assert_eq([warp.target_map, warp.target_spawn, warp.facing],
					[&"route_10", StringName("from_lavender_" + suffixes[i]), Vector2i.UP])
			else:
				assert_eq(warp.coming_soon, "Route 10")
		assert_eq(_map.get_spawn_cell(StringName("from_route_10_" + suffixes[i])), cell)
	assert_eq(_map.get_spawn_cell(&"from_route_10"), Vector2i(22, 0))


func test_west_and_south_edges_are_coming_soon_and_reachable() -> void:
	var dist := _reach()
	for entry: Array in [[Vector2i(0, 10), Vector2i.LEFT, "Route 8", "from_route_8_"],
			[Vector2i(21, 35), Vector2i.DOWN, "Route 12", "from_route_12_"]]:
		for i: int in 3:
			var cell: Vector2i = entry[0] + (Vector2i(0, i) if entry[1] == Vector2i.LEFT
				else Vector2i(i, 0))
			var warp := _map.get_warps().find_on_push(cell, entry[1])
			assert_not_null(warp, "raccord %s" % cell)
			if warp != null:
				assert_true(warp.is_coming_soon())
				assert_eq(warp.coming_soon, entry[2])
				var back := _map.get_spawn_cell(warp.target_spawn)
				assert_false(_grid.is_solid(back), "retour praticable")
				assert_ne(warp.facing, Vector2i.ZERO)
			assert_true(dist.has(cell), "bord %s atteignable" % cell)


func test_doors_lead_into_the_interiors_and_back() -> void:
	var dist := _reach()
	for door: Vector2i in DOORS:
		var info: Array = DOORS[door]
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp, "porte %s" % door)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [info[0], &"entrance"])
		assert_true(dist.has(door), "porte %s atteignable" % door)
		assert_true(_map.has_spawn(info[1]), "spawn %s" % info[1])
		var room := (load(MapCatalog.scene_path(info[0])) as PackedScene).instantiate() \
			as GameMap
		var mat := room.get_spawn_cell(&"entrance")
		var back := room.get_warps().find_on_push(mat, Vector2i.DOWN)
		assert_not_null(back, "%s : sortie" % info[0])
		if back != null:
			assert_eq([back.target_map, back.target_spawn], [&"lavender_town", info[1]])
		room.free()
	# 3 + 3 (bords) + 10 cases de porte.
	assert_eq(_map.get_warps().size(), 3 + 3 + 3 + DOORS.size())


func test_return_spawns_are_in_front_of_the_doors() -> void:
	for id: String in ["retour_centre", "retour_boutique", "retour_fuji", "retour_maison_1",
			"retour_maison_2", "retour_tour"]:
		var cell := _map.get_spawn_cell(StringName(id))
		assert_true(_plan.cells_at(id).has(cell), "%s dans les cases de la grille" % id)
		assert_false(_grid.is_solid(cell))


func test_everything_walkable_is_connected() -> void:
	var dist := _reach()
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ville") + _plan.cells_at(
		"panneau_tour") + _plan.cells_at("panneau_fuji")
	for cell: Vector2i in _plan.cells_of(".pD"):
		if signs.has(cell):
			continue
		assert_true(dist.has(cell), "case %s atteignable" % cell)


func test_node_budget() -> void:
	assert_lte(GridPaths.count_nodes(_map), NODE_BUDGET)
