extends GutTest
## Carte route_2_north (jalon 10 T11, docs/tech/jalon-10.md §1.3, §2.1 ; dossier 12 §3) :
## métadonnées et lumière, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_2_nord.txt` case par case, raccords (Argenta au nord, porte du poste nord
## de la forêt au sud), points d'examen, critères de `tools/art/plan_check_argenta.py` refaits sur
## la vraie grille de la scène (positions `bloque` en plus), objets peints sur des cases
## bloquées, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_2_north.tscn"
const PLAN_PATH := "res://tools/plans/route_2_nord.txt"
const WALKABLE := ".=hvDp"
const SIZE := Vector2i(30, 24)
const NORTH := [Vector2i(14, 0), Vector2i(15, 0), Vector2i(16, 0)]
const GATE_DOOR := Vector2i(15, 21)
const GATE_FRONT := Vector2i(15, 20)
const NODE_BUDGET := 3000
## Mesure du T1 (plan_check_argenta.py) : du devant de la porte du poste au bord nord.
const GATE_TO_NORTH := 20
const INF := 1 << 30

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (PNJ, Potion, panneau).
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_plan.walkable = WALKABLE
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


func _grass() -> Dictionary:
	var cells: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		cells[cell] = true
	return cells


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_2_north")
	assert_eq(_map.display_name, "Route 2")
	assert_eq(_map.region, "Forêt de Jade — Argenta", "sous-titre porté par la carte (§20)")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_eq(_map.music, &"", "musique : intention seulement")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"route_2_north"), &"route_2", "2e carte de la zone Route 2 (Q-3)")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	assert_not_null(_map.get_node_or_null(^"ForestFloor"), "sous-bois")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		var mask := ground.mask.get_image()
		assert_eq(GroundMask.kind_at(mask, Vector2i(15, 10)), GroundMask.Kind.PATH)
		assert_eq(GroundMask.kind_at(mask, Vector2i(27, 16)), GroundMask.Kind.PATH,
			"sentier fermé peint derrière les éboulis")
		assert_eq(GroundMask.kind_at(mask, Vector2i(5, 12)), GroundMask.Kind.GRASS)
	assert_not_null(_map.grass_front, "cache-jambes peint")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_route")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell) or signs.has(cell)
			var ok := _grid.is_solid(cell) == solid \
				and _grid.is_tall_grass(cell) == (_plan.at(cell) == "h")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_2_nord.txt")


# --- Passages ----------------------------------------------------------------------------

func test_north_edge_leads_to_pewter_city() -> void:
	var suffixes := ["w", "c", "e"]
	for i: int in NORTH.size():
		var cell: Vector2i = NORTH[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.UP)
		assert_not_null(warp, "sortie nord %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"pewter_city",
				StringName("from_route_2_north_" + suffixes[i]), Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName("from_pewter_" + suffixes[i])), cell)
	assert_eq(_map.get_warps().size(), 4, "trois sorties nord et la porte du poste")


func test_gate_door_leads_to_the_north_gate_and_back() -> void:
	var warp := _map.get_warps().find_on_step(GATE_DOOR, Vector2i.DOWN)
	assert_not_null(warp, "porte du poste (STEP_ON ↓)")
	if warp != null:
		assert_eq([warp.target_map, warp.target_spawn, warp.facing],
			[&"viridian_forest_gate_north", &"north_door", Vector2i.DOWN])
	assert_eq(_map.get_spawn_cell(&"from_forest_gate"), GATE_FRONT)
	assert_false(_grid.is_solid(GATE_DOOR), "la porte se franchit")
	var gate := _map.get_node_or_null(^"GroundDecals/ForestGate") as WorldProp
	assert_not_null(gate, "poste vu du nord, couche du sol (T10)")
	if gate == null:
		return
	var expected: Array[Vector2i] = _plan.cells_of("P")
	var solid := gate.get_solid_cells()
	solid.sort()
	expected.sort()
	assert_eq(solid, expected, "emprise du poste = cases P (porte libre)")


func test_examine_points() -> void:
	var sign := _map.get_interactions().find(Vector2i(13, 19), Vector2i.UP)
	assert_not_null(sign, "panneau « ROUTE 2 » lu depuis le sud")
	if sign != null:
		assert_eq(sign.dialogue_id, &"route_2_north_sign")
	for cell: Vector2i in _plan.cells_at("examen_eboulis"):
		var rubble := _map.get_interactions().find(cell, Vector2i.RIGHT)
		assert_not_null(rubble, "éboulis %s" % cell)
		if rubble != null:
			assert_eq(rubble.dialogue_id, &"route_2_north_rockslide")
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0, "aucun déclencheur")


# --- Critères (plan_check_argenta.py) ----------------------------------------------------

func test_gate_to_argenta_is_a_short_straight_walk() -> void:
	var dist := GridPaths.distances(_terrain, [GATE_FRONT])
	for cell: Vector2i in NORTH:
		assert_true(dist.has(cell), "raccord nord %s atteignable" % cell)
	assert_eq(int(dist.get(Vector2i(15, 0), -1)), GATE_TO_NORTH, "20 pas, chemin droit")


func test_grass_patches_are_optional() -> void:
	assert_eq(GridPaths.min_crossed(_terrain, [GATE_FRONT], NORTH, _grass()), 0,
		"H1 et H2 évitables")


func test_potion_is_reached_off_the_grass_by_the_west_detour() -> void:
	var potion := _plan.cell_of("potion")
	assert_eq(potion, Vector2i(4, 1))
	var around: Array = []
	for side: Vector2i in GridPaths.DIRECTIONS:
		if not _terrain.is_solid(potion + side) and _terrain.is_in_bounds(potion + side):
			around.append(potion + side)
	assert_gt(around.size(), 0)
	assert_eq(GridPaths.min_crossed(_terrain, [GATE_FRONT], around, _grass()), 0,
		"Potion hors herbes")
	var direct := int(GridPaths.distances(_terrain, [GATE_FRONT]).get(Vector2i(15, 0), 0))
	var detour := INF
	var dist := GridPaths.distances(_terrain, [GATE_FRONT])
	for cell: Vector2i in around:
		detour = mini(detour, int(dist.get(cell, INF)))
	assert_gt(detour, direct / 2, "un petit détour, pas sur le chemin")


func test_rockslide_closes_the_east_path() -> void:
	var dist := GridPaths.distances(_terrain, [GATE_FRONT])
	for cell: Vector2i in dist:
		assert_lt(cell.x, 24, "rien d'atteignable à l'est des éboulis (%s)" % cell)
	for cell: Vector2i in _plan.cells_at("examen_eboulis"):
		assert_true(_grid.is_solid(cell), "éboulis %s bloqués" % cell)


func test_mountaineer_stays_off_the_path_and_the_grass() -> void:
	for cell: Vector2i in _plan.cells_at("montagnard"):
		assert_eq(_plan.at(cell), ".", "Montagnard %s sur l'herbe rase" % cell)
	var spec := NpcRoster.load_for_map(&"route_2_north").get_spec(&"mountaineer")
	assert_not_null(spec)
	if spec != null:
		for cell: Vector2i in spec.route_cells:
			assert_true(_plan.cells_at("montagnard").has(cell), "routine %s dans la grille" % cell)


# --- Objets peints et budget -------------------------------------------------------------

func test_props_never_block_a_walkable_cell() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_route")
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or signs.has(cell),
					"%s bloque la case praticable %s" % [prop.name, cell])


func test_npcs_and_potion_are_placed() -> void:
	assert_not_null(_map.get_npc(&"mountaineer"), "Montagnard")
	assert_not_null(_map.get_npc(&"route_2_north_ball_1"), "Potion visible")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_2_north : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds (budget du J9)")

