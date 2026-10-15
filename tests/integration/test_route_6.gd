extends GutTest
## Carte route_6 (jalon 15 T14, docs/tech/jalon-15.md §2.1, §2.4, §2.8 ; dossier 18 §6, §7) sur la
## vraie scène : métadonnées et lumière, étang peint, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_6.txt` case par case, raccords (bâtiment de sortie du souterrain, Carmin,
## poste de Safrania « à venir »), critères de `tools/art/plan_check_carmin.py` (profil route_6)
## refaits sur la vraie grille : Chloé inévitable par géométrie, les cinq autres évitables un à un
## et ensemble, hautes herbes évitables, porte du poste inatteignable (garde) ; garde et recul,
## objet caché, décor (emprises, vue du port), budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_6.tscn"
const PLAN_PATH := "res://tools/plans/route_6.txt"
const SIZE := Vector2i(42, 56)
const NODE_BUDGET := 3000
const INF := 1 << 30
const ARRIVAL := Vector2i(7, 5)
const SOUTH := [Vector2i(25, 55), Vector2i(26, 55), Vector2i(27, 55)]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief (eau comprise) plus les positions `bloque` de la grille.
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_water(Vector2i(x, y)):
				_terrain.set_solid(Vector2i(x, y))
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


func _without(cells: Array) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


func _to_south(grid: GridWorld) -> int:
	var dist := GridPaths.distances(grid, [ARRIVAL])
	var best := INF
	for cell: Vector2i in SOUTH:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func _sight(id: String) -> Array[Vector2i]:
	var facing := Grid.direction_from_name(_plan.attr(id, "facing"))
	var origin := _plan.cell_of(id)
	var cells: Array[Vector2i] = []
	for k: int in range(1, int(_plan.attr(id, "sight")) + 1):
		var cell := origin + facing * k
		if not _grid.is_in_bounds(cell) or _terrain.is_solid(cell):
			break
		cells.append(cell)
	return cells


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_painted_pond() -> void:
	assert_eq(_map.map_id, &"route_6")
	assert_eq(_map.display_name, "Route 6")
	assert_eq(_map.region, "Safrania — Carmin-sur-Mer")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_6"), &"golden_hour", "au plan de lumière")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_6"), &"route_6")
	assert_eq(zones.zone_of(&"route_6_underground_gate"), &"route_6")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		assert_not_null(ground.shore_mask, "étang peint")
		assert_true(ground.square_shore, "étang à angles droits")
		assert_eq(GroundMask.shore_at(ground.shore_mask.get_image(), Vector2i(15, 30)),
			GroundMask.Kind.WATER)
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	# Panneaux et indice de l'objet caché : positions `bloque` de la grille, posées sur l'herbe.
	var props: Array[Vector2i] = _plan.cells_at("panneau_route") + _plan.cells_at(
		"panneau_poste") + _plan.cells_at("route_6_hidden_1")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var water := mark == "W"
			var solid := not _plan.is_walkable(cell) or props.has(cell)
			var ok := (water or _grid.is_solid(cell) == solid) \
				and _grid.is_water(cell) == water and _grid.is_tall_grass(cell) == (mark == "h")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_water(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_6.txt")
	assert_eq(_plan.walkable, ".=hD")


# --- Passages ----------------------------------------------------------------------------

func test_underground_exit_door_and_arrival() -> void:
	var door := _plan.cell_of("warp_souterrain")
	var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
	assert_not_null(warp, "porte du bâtiment STEP_ON ↑")
	if warp != null:
		assert_false(warp.is_coming_soon())
		assert_eq([warp.target_map, warp.target_spawn],
			[&"route_6_underground_gate", &"from_route_6"])
	assert_eq(_map.get_spawn_cell(&"from_underground"), ARRIVAL)
	var gate := (load("res://game/world/maps/route_6_underground_gate.tscn") as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(gate)
	assert_true(gate.has_spawn(&"from_route_6"), "arrivée dans le bâtiment")


func test_south_edge_leads_to_vermilion_column_by_column() -> void:
	var vermilion := (load("res://game/world/maps/vermilion_city.tscn") as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(vermilion)
	var suffixes := ["w", "c", "e"]
	for i: int in SOUTH.size():
		var cell: Vector2i = SOUTH[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "raccord sud %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn],
				[&"vermilion_city", StringName("from_route_6_" + suffixes[i])])
			assert_eq(vermilion.get_spawn_cell(warp.target_spawn), cell + Vector2i(5, -55),
				"décalage de 5 colonnes")
		assert_eq(_map.get_spawn_cell(StringName("from_vermilion_" + suffixes[i])), cell)
		var back := vermilion.get_warps().find_on_push(cell + Vector2i(5, -55), Vector2i.UP)
		assert_not_null(back, "retour depuis Carmin")
		if back != null:
			assert_eq([back.target_map, back.target_spawn],
				[&"route_6", StringName("from_vermilion_" + suffixes[i])])


func test_saffron_gate_door_is_coming_soon_and_unreachable() -> void:
	var door := _plan.cell_of("porte_safrania")
	var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
	assert_not_null(warp)
	if warp != null:
		assert_true(warp.is_coming_soon(), "Safrania fermée")
	var dist := GridPaths.distances(_terrain, [ARRIVAL])
	assert_false(dist.has(door), "porte derrière le garde")
	assert_true(GridPaths.distances(_without([]), [ARRIVAL]).has(door + Vector2i.DOWN * 2))
	assert_eq(_map.get_warps().size(), 5, "sortie du souterrain, trois raccords sud, poste")


# --- Critères (plan_check_carmin.py, route_6) ---------------------------------------------

func test_main_path_reaches_vermilion() -> void:
	var steps := _to_south(_terrain)
	gut.p("route_6 : sortie du souterrain → Carmin en %d pas" % steps)
	assert_between(steps, 60, 90)


func test_chloe_cannot_be_avoided() -> void:
	var sight := _sight("chloe")
	assert_eq(sight.size(), 5, "vue dégagée")
	assert_eq(_to_south(_without(sight)), INF, "Chloé inévitable")


func test_the_five_others_can_be_avoided_even_together() -> void:
	var seen: Array[Vector2i] = []
	for id: String in ["lucas", "axel", "mathis", "manon", "timeo"]:
		var sight := _sight(id)
		assert_gt(sight.size(), 0, "%s voit devant lui" % id)
		assert_lt(_to_south(_without(sight)), INF, "%s évitable" % id)
		seen.append_array(sight)
	# Chloé battue : sa case reste bloquée, sa vue non.
	assert_lt(_to_south(_without(seen)), INF, "D2 à D6 évitables ensemble")


func test_tall_grass_is_avoidable() -> void:
	var all: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		all[cell] = true
	assert_eq(GridPaths.min_crossed(_terrain, [ARRIVAL], SOUTH, all), 0,
		"aucune herbe obligatoire")


func test_guard_triggers_push_back() -> void:
	var expected := {
		Vector2i(35, 8): &"route_6_gate_rule_w", Vector2i(37, 8): &"route_6_gate_rule_e",
		Vector2i(35, 9): &"route_6_gate_rule_s", Vector2i(36, 9): &"route_6_gate_rule_s",
		Vector2i(37, 9): &"route_6_gate_rule_s",
	}
	var cells: Array[Vector2i] = []
	for point: Node in _map.get_node(^"Triggers").get_children():
		cells.append_array((point as EventTriggerPoint).get_cells())
	assert_eq(cells.size(), 5, "cases du verrou")
	for cell: Vector2i in expected:
		assert_eq(cells.count(cell), 1, "%s couverte" % cell)
		var found := _map.get_triggers().find_on_step(cell, Vector2i.UP)
		assert_not_null(found, "déclencheur en %s, toute direction" % cell)
		if found != null:
			assert_eq(found.cutscene_id, expected[cell], String(expected[cell]))
			assert_eq(found.direction, Vector2i.ZERO)
	var plan_cells: Array[Vector2i] = _plan.cells_at("verrou_safrania")
	plan_cells.sort()
	cells.sort()
	assert_eq(cells, plan_cells, "= verrou_safrania de la grille")
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir())
	for id: StringName in [&"route_6_gate_rule_w", &"route_6_gate_rule_e",
			&"route_6_gate_rule_s"]:
		assert_not_null(library.get_cutscene(id), String(id))


func test_hidden_super_potion_behind_the_rushes() -> void:
	var clue := _plan.cell_of("route_6_hidden_1")
	assert_eq(clue, Vector2i(10, 32))
	assert_true(_grid.is_solid(clue), "indice bloqué")
	var found: InteractPoint = null
	for point: Node in _map.get_node(^"Interactables").get_children():
		if (point as InteractPoint).dialogue_id == &"route_6_hidden_1":
			found = point
	assert_not_null(found, "point d'examen")
	if found != null:
		assert_eq(found.get_cell(), clue)
		assert_eq(found.unless_flags, [&"got_route_6_hidden_1"] as Array[StringName])
	var dist := GridPaths.distances(_terrain, [ARRIVAL])
	assert_true(dist.has(clue + Vector2i.UP) or dist.has(clue + Vector2i.DOWN),
		"examinable depuis la rive")
	assert_not_null(_map.get_node_or_null(^"Entities/HiddenClue1"), "joncs couchés")


# --- Décor ---------------------------------------------------------------------------------

func _props() -> Array[WorldProp]:
	var props: Array[WorldProp] = []
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				props.append(child as WorldProp)
	return props


func test_props_never_block_a_walkable_cell() -> void:
	var blocking := _plan.blocking_cells()
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(not _plan.is_walkable(cell) or blocking.has(cell),
				"%s bloque la case praticable %s" % [prop.name, cell])


func test_buildings_and_port_view() -> void:
	for node: String in ["UndergroundExit", "SaffronGate"]:
		assert_not_null(_map.get_node_or_null(NodePath("Entities/" + node)), node)
	var view := _map.get_node_or_null(^"Entities/PortView") as Node2D
	assert_not_null(view, "vue lointaine du port")
	if view != null:
		assert_gt(view.z_index, 0, "au-dessus des cimes")
		var foot := Vector2i(view.position / Grid.TILE_SIZE)
		var belvedere := _plan.cell_of("vue_port")
		assert_lte(absi(foot.x - belvedere.x), 2)
		assert_lte(absi(foot.y - belvedere.y), 4)


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_6 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds")
