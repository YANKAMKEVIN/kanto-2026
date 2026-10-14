extends GutTest
## Sas de la Route 4, carte `route_4` (jalon 12 T8, docs/tech/jalon-12.md §0.2 n° 15, §2.1,
## §2.15 ; dossier 15 §14) sur la vraie scène : métadonnées, grille de la scène = grille
## `tools/plans/route_4_sas.txt`, bouche de la grotte vers B2F (carte du T9), point d'arrivée
## (3, 6) gardé pour le J13, raccord est « Azuria » à venir, aucun Dresseur, herbe ni objet ;
## panneau examinable et déclencheur `route_4_reached` (T28, §1.3 n° 5, §2.15) ; budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_4.tscn"
const PLAN_PATH := "res://tools/plans/route_4_sas.txt"
const SIZE := Vector2i(24, 14)
const MOUTH := Vector2i(2, 6)
const ARRIVAL := Vector2i(3, 6)
const EAST := [Vector2i(23, 6), Vector2i(23, 7)]

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


func test_metadata_light_and_zone() -> void:
	assert_eq(_map.map_id, &"route_4", "identifiant de la vraie Route 4 dès le J12")
	assert_eq(_map.display_name, "Route 4")
	assert_eq(_map.region, "Mont Sélénite — Azuria")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_4"), &"route_4")
	assert_not_null(_map.get_node_or_null(^"PaintedGround"), "sol peint")


func test_scene_grid_is_the_functional_grid() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_route_4")
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell) or sign.has(cell)
			assert_eq(_grid.is_solid(cell), solid, "case %s « %s »" % [cell, _plan.at(cell)])
			assert_false(_grid.is_tall_grass(cell), "aucune herbe haute")


func test_mouth_leads_to_b2f_and_the_arrival_is_kept_for_the_j13() -> void:
	var warp := _map.get_warps().find_on_step(MOUTH, Vector2i.LEFT)
	assert_not_null(warp, "bouche de la grotte (STEP_ON ←)")
	if warp != null:
		assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"mt_moon_b2f",
			&"arrivee_s", Vector2i.DOWN])
	assert_eq(_map.get_spawn_cell(&"from_mt_moon"), ARRIVAL, "point d'arrivée (3, 6)")
	assert_eq(_plan.cell_of("from_mt_moon"), ARRIVAL)
	assert_false(_grid.is_solid(ARRIVAL))
	# On n'entre dans la bouche que depuis l'est.
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
		assert_true(_grid.is_solid(MOUTH + side), "paroi autour de la bouche (%s)" % side)


func test_east_edge_is_azuria_coming_soon() -> void:
	var suffixes := ["n", "s"]
	for i: int in EAST.size():
		var cell: Vector2i = EAST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % cell)
		if warp == null:
			continue
		assert_true(warp.is_coming_soon())
		assert_eq(warp.coming_soon, "Azuria")
		assert_eq(warp.target_spawn, StringName("from_cerulean_" + suffixes[i]))
		assert_eq(_map.get_spawn_cell(warp.target_spawn), cell, "retour sur la case")
		assert_eq(warp.facing, Vector2i.LEFT)
	assert_eq(_map.get_warps().size(), 3)


func test_the_whole_sas_is_reachable_and_closed() -> void:
	var dist := GridPaths.distances(_grid, [ARRIVAL])
	for cell: Vector2i in _plan.cells_of(_plan.walkable):
		if not _plan.cells_at("panneau_route_4").has(cell):
			assert_true(dist.has(cell), "%s atteignable" % cell)
	for cell: Vector2i in dist:
		assert_true(_plan.is_walkable(cell), "%s fermé par la grille" % cell)


func test_nothing_but_the_path_the_sign_and_the_view() -> void:
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 1, "route_4_reached (T28)")
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 1, "panneau (T28)")
	assert_false(FileAccess.file_exists("res://data/npcs/route_4.json"), "aucun PNJ ni objet")
	assert_not_null(_map.get_node_or_null(^"Entities/SignRoute4"), "panneau (décor)")
	assert_not_null(_map.get_node_or_null(^"GroundDecals/CaveMouth"), "bouche de la grotte")


func test_props_never_block_a_walkable_cell() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_route_4")
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or sign.has(cell),
					"%s bloque la case praticable %s" % [prop.name, cell])


func test_node_budget() -> void:
	assert_lte(GridPaths.count_nodes(_map), 3000)


## T28 (§2.15, dossier 15 §20 n° 36) : panneau lu de face, depuis la case au sud.
func test_sign_is_read_from_the_south() -> void:
	var point := _map.get_node(^"Interactables").get_child(0) as InteractPoint
	assert_not_null(point)
	if point == null:
		return
	assert_eq(point.get_cells(), _plan.cells_at("panneau_route_4"))
	assert_eq(point.dialogue_id, &"route_4_sign")
	assert_eq(point.facing, Vector2i.UP)
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_true(dialogues.has_dialogue(&"route_4_sign"))


## T28 (§1.3 n° 5) : `route_4_reached` couvre toute la largeur du sas (colonne 4, rangées 5..9),
## toute direction ; au nord et au sud, la paroi.
func test_reached_trigger_spans_the_whole_sas() -> void:
	var trigger := _map.get_node(^"Triggers").get_child(0) as EventTriggerPoint
	assert_not_null(trigger)
	if trigger == null:
		return
	assert_eq(trigger.cutscene_id, &"route_4_reached")
	assert_eq(trigger.direction, Vector2i.ZERO, "toute direction")
	var cells := trigger.get_cells()
	assert_eq(cells.size(), 5)
	for y: int in range(5, 10):
		assert_true(cells.has(Vector2i(4, y)), "(4, %d) couverte" % y)
		assert_false(_grid.is_solid(Vector2i(4, y)), "(4, %d) praticable" % y)
	assert_true(_grid.is_solid(Vector2i(4, 4)), "paroi au nord")
	assert_true(_grid.is_solid(Vector2i(4, 10)), "paroi au sud")
	assert_false(cells.has(ARRIVAL), "l'arrivée n'est pas couverte : un pas vers l'est")
