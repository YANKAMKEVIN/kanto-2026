extends GutTest
## Carte route_8 (jalon 20 T15, docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23 §3) sur la vraie
## scène : métadonnées et lumière, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_8.txt` case par case (corniche comprise), raccords (Lavanville rangée par
## rangée, poste de Safrania, bâtiment d'entrée du souterrain), critères de
## `tools/art/plan_check_routes_j20.py` (profil route_8) refaits sur la vraie grille : D1, D2, D4
## et D5 inévitables, D3, D6 et D7 évitables (un à un et ensemble), corniche à sens unique ;
## panneaux, indice de l'objet caché, décor, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_8.tscn"
const PLAN_PATH := "res://tools/plans/route_8.txt"
const SIZE := Vector2i(80, 26)
const NODE_BUDGET := 3000
const INF := 1 << 30
const EAST := [Vector2i(79, 10), Vector2i(79, 11), Vector2i(79, 12)]
const INEVITABLE := ["d1_intello", "d2_joueur", "d4_fillette", "d5_fillette"]
const AVOIDABLE := ["d3_intello", "d6_joueur", "d7_fillette"]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief plus les positions `bloque` de la grille (Dresseurs, objets, panneaux).
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


func _without(cells: Array) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


func _steps(grid: GridWorld, target: Vector2i) -> int:
	return int(GridPaths.distances(grid, EAST).get(target, INF))


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

func test_metadata_and_light() -> void:
	assert_eq(_map.map_id, &"route_8")
	assert_eq(_map.display_name, "Route 8")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_8"), &"golden_hour", "au plan de lumière")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var props: Array[Vector2i] = _plan.cells_at("panneau_route") \
		+ _plan.cells_at("panneau_souterrain") + _plan.cells_at("route_8_hidden_1")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or props.has(cell)
			var ledge := mark == "v"
			var ok := _grid.is_solid(cell) == solid and _grid.is_tall_grass(cell) == (mark == "h") \
				and (_grid.get_ledge(cell) != GridWorld.Ledge.NONE) == ledge
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s, rebord %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell), _grid.get_ledge(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_8.txt")
	assert_eq(_plan.walkable, ".=hveD")


# --- Passages ----------------------------------------------------------------------------

func test_east_edge_leads_to_lavender_row_by_row() -> void:
	var lavender := (load("res://game/world/maps/lavender_town.tscn") as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(lavender)
	var suffixes := ["n", "c", "s"]
	for i: int in EAST.size():
		var cell: Vector2i = EAST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[&"lavender_town", StringName("from_route_8_" + suffixes[i])])
			assert_eq(lavender.get_spawn_cell(warp.target_spawn), Vector2i(1, cell.y),
				"même rangée, une case à l'intérieur de Lavanville")
		assert_eq(_map.get_spawn_cell(StringName("from_lavender_" + suffixes[i])), cell)
		var back := lavender.get_warps().find_on_push(Vector2i(0, cell.y), Vector2i.LEFT)
		assert_not_null(back, "retour depuis Lavanville")
		if back != null:
			assert_eq([back.target_map, back.target_spawn],
				[&"route_8", StringName("from_lavender_" + suffixes[i])])


func test_doors_lead_into_the_two_buildings_and_back() -> void:
	for entry: Array in [["porte_poste", &"route_8_gate", "from_poste", &"from_gate"],
			["porte_souterrain", &"route_8_underground_gate", "from_souterrain",
			&"from_underground"]]:
		var door := _plan.cell_of(entry[0])
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp, "porte %s STEP_ON ↑" % door)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [entry[1], &"entrance"])
		assert_eq(_map.get_spawn_cell(entry[3]), _plan.cell_of(entry[2]))
		var room := (load(MapCatalog.scene_path(entry[1])) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(room)
		assert_true(room.has_spawn(&"entrance"), "%s : arrivée" % entry[1])
		var exits := 0
		for x: int in [4, 5]:
			var out := room.get_warps().find_on_step(Vector2i(x, 7), Vector2i.DOWN)
			if out != null and out.target_map == &"route_8" and out.target_spawn == entry[3]:
				exits += 1
		assert_eq(exits, 2, "%s : sortie vers la Route 8" % entry[1])
	assert_eq(_map.get_warps().size(), 5, "trois raccords est, deux portes")


# --- Critères (plan_check_routes_j20.py, route_8) ------------------------------------------

func test_main_path_crosses_the_route() -> void:
	var steps := _steps(_terrain, _plan.cell_of("porte_souterrain"))
	gut.p("route_8 : Lavanville → souterrain en %d pas" % steps)
	assert_between(steps, 70, 110)
	assert_lt(_steps(_terrain, _plan.cell_of("porte_poste")), INF, "poste atteignable")


func test_d1_d2_and_the_duo_cannot_be_avoided() -> void:
	var underground := _plan.cell_of("porte_souterrain")
	var gate := _plan.cell_of("porte_poste")
	for id: String in INEVITABLE:
		var sight := _sight(id)
		assert_eq(sight.size(), int(_plan.attr(id, "sight")), "%s : vue dégagée" % id)
		var blocked := sight.duplicate()
		assert_eq(_steps(_without(blocked), underground), INF, "%s inévitable" % id)
		if id == "d1_intello":
			assert_lt(_steps(_without(blocked), gate), INF, "D1 ne garde que le souterrain")
		else:
			assert_eq(_steps(_without(blocked), gate), INF, "%s ferme aussi le poste" % id)
	# Le duo D4 / D5 : côte à côte, même direction (combats successifs, jamais en duo).
	assert_eq(_plan.cell_of("d5_fillette") - _plan.cell_of("d4_fillette"), Vector2i(1, 0))
	assert_eq(_plan.attr("d4_fillette", "facing"), _plan.attr("d5_fillette", "facing"))


func test_d3_d6_and_d7_can_be_avoided_even_together() -> void:
	var underground := _plan.cell_of("porte_souterrain")
	var seen: Array[Vector2i] = []
	for id: String in AVOIDABLE:
		var sight := _sight(id)
		assert_gt(sight.size(), 0, "%s voit devant lui" % id)
		assert_lt(_steps(_without(sight), underground), INF, "%s évitable" % id)
		seen.append_array(sight)
	assert_lt(_steps(_without(seen), underground), INF, "D3, D6 et D7 évitables ensemble")


func test_the_ledge_is_one_way() -> void:
	for cell: Vector2i in _plan.cells_of("v"):
		assert_eq(_grid.get_ledge(cell), GridWorld.Ledge.DOWN, "%s : sauté vers le sud" % cell)
		var above := cell + Vector2i.UP
		var below := cell + Vector2i.DOWN
		assert_eq(_grid.get_step_target(above, Vector2i.DOWN), below, "%s : on saute" % cell)
		assert_eq(_grid.get_step_target(below, Vector2i.UP), below, "%s : on ne remonte pas" % cell)


# --- Vie posée par la carte ----------------------------------------------------------------

func test_signs_and_the_hidden_revive_clue() -> void:
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Interactables").get_children():
		found[(point as InteractPoint).dialogue_id] = point
	for entry: Array in [["panneau_route", &"route_8_sign"],
			["panneau_souterrain", &"route_8_underground_sign"]]:
		assert_true(found.has(entry[1]), String(entry[1]))
		if found.has(entry[1]):
			var point: InteractPoint = found[entry[1]]
			assert_eq([point.get_cell(), point.facing], [_plan.cell_of(entry[0]), Vector2i.UP])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_eq(dialogues.get_dialogue(&"route_8_sign").variants[0].pages[0].text,
		"ROUTE 8\nLavanville → ← Safrania", "texte 1")
	assert_eq(dialogues.get_dialogue(&"route_8_underground_sign").variants[0].pages[0].text,
		"PASSAGE SOUTERRAIN\nRoute 7 — Céladopole", "texte 2")
	# Objet caché : la pierre-indice (case bloquée) ; son point EXAMINER vient avec la vie (T17).
	var clue := _plan.cell_of("route_8_hidden_1")
	assert_true(_grid.is_solid(clue), "indice bloqué")
	assert_not_null(_map.get_node_or_null(^"Entities/HiddenReviveClue"), "pierre-indice")


func test_trainer_and_item_cells_are_free_of_forest() -> void:
	for id: String in INEVITABLE + AVOIDABLE + ["route_8_item_1"]:
		var cell := _plan.cell_of(id)
		assert_true(_plan.is_walkable(cell), "%s sur une case praticable de la grille" % id)


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
	for node: String in ["UndergroundEntrance", "SaffronGate"]:
		assert_not_null(_map.get_node_or_null(NodePath("Entities/" + node)), node)


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_8 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds")
