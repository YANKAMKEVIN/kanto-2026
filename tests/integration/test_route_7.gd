extends GutTest
## Carte route_7 (jalon 20 T15, docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23 §5) sur la vraie
## scène : métadonnées et lumière, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_7.txt` case par case, raccords (Céladopole « à venir » tant que la ville du
## T16 n'existe pas, poste de Safrania, bâtiment d'entrée du souterrain), hautes herbes évitables,
## panneaux, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_7.tscn"
const PLAN_PATH := "res://tools/plans/route_7.txt"
const SIZE := Vector2i(28, 24)
const NODE_BUDGET := 3000
const INF := 1 << 30
const WEST := [Vector2i(0, 10), Vector2i(0, 11), Vector2i(0, 12)]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


func test_metadata_and_light() -> void:
	assert_eq(_map.map_id, &"route_7")
	assert_eq(_map.display_name, "Route 7")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_7"), &"golden_hour")


func test_scene_grid_is_the_functional_grid() -> void:
	var props: Array[Vector2i] = _plan.cells_at("panneau_route") \
		+ _plan.cells_at("panneau_souterrain")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or props.has(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell) != (mark == "h"):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_7.txt")
	assert_eq(_plan.walkable, ".=hD")


func test_west_edge_waits_for_celadon_row_by_row() -> void:
	var suffixes := ["n", "c", "s"]
	var built := MapCatalog.has_map(&"celadon_city")
	for i: int in WEST.size():
		var cell: Vector2i = WEST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % cell)
		if warp != null:
			if built:
				assert_eq([warp.target_map, warp.target_spawn],
					[&"celadon_city", StringName("from_route_7_" + suffixes[i])])
			else:
				assert_eq(warp.coming_soon, "Céladopole")
				assert_eq(warp.target_spawn, StringName("from_celadon_" + suffixes[i]))
		assert_eq(_map.get_spawn_cell(StringName("from_celadon_" + suffixes[i])), cell)


func test_doors_lead_into_the_two_buildings_and_back() -> void:
	for entry: Array in [["porte_poste", &"route_7_gate", "from_poste", &"from_gate"],
			["porte_souterrain", &"route_7_underground_gate", "from_souterrain",
			&"from_underground"]]:
		var door := _plan.cell_of(entry[0])
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp, "porte %s" % door)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [entry[1], &"entrance"])
		assert_eq(_map.get_spawn_cell(entry[3]), _plan.cell_of(entry[2]))
		var room := (load(MapCatalog.scene_path(entry[1])) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(room)
		var out := room.get_warps().find_on_step(Vector2i(4, 7), Vector2i.DOWN)
		assert_not_null(out, "%s : sortie" % entry[1])
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"route_7", entry[3]])
	var dist := GridPaths.distances(_terrain, WEST)
	for id: String in ["porte_poste", "porte_souterrain"]:
		assert_true(dist.has(_plan.cell_of(id)), "%s atteignable depuis Céladopole" % id)


func test_tall_grass_is_avoidable() -> void:
	var grass: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		grass[cell] = true
	for id: String in ["porte_poste", "porte_souterrain"]:
		assert_eq(GridPaths.min_crossed(_terrain, WEST, [_plan.cell_of(id)], grass), 0,
			"aucune herbe obligatoire vers %s" % id)


func test_signs_read_their_texts() -> void:
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Interactables").get_children():
		found[(point as InteractPoint).dialogue_id] = (point as InteractPoint).get_cell()
	assert_eq(found.get(&"route_7_sign"), _plan.cell_of("panneau_route"))
	assert_eq(found.get(&"route_7_underground_sign"), _plan.cell_of("panneau_souterrain"))
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_eq(dialogues.get_dialogue(&"route_7_sign").variants[0].pages[0].text,
		"ROUTE 7\nCéladopole ← → Safrania", "texte 11")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_7 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)
