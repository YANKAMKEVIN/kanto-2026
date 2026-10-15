extends GutTest
## Carte route_5 (jalon 15 T13 et T21, docs/tech/jalon-15.md §1.3, §2.1, §2.8 ; dossier 18 §3,
## §4.1, §13.1) sur la vraie scène : métadonnées et lumière, **grille de la scène = grille
## fonctionnelle** `tools/plans/route_5.txt` v2 case par case, raccord nord réel avec Azuria
## (trois colonnes, T21), portes de la Pension, du poste et de l'entrée du souterrain, panneaux,
## Antidote caché (point d'examen `unless_flags`), déclencheur de l'arrivée, critères de
## `tools/art/plan_check_j15.py` refaits sur la vraie grille (herbes évitables, détour facultatif),
## cases réservées libres de décor, jardin clos, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_5.tscn"
const PLAN_PATH := "res://tools/plans/route_5.txt"
const SIZE := Vector2i(42, 62)
const NORTH := [Vector2i(19, 0), Vector2i(20, 0), Vector2i(21, 0)]
const SUFFIXES := ["w", "c", "e"]
## [porte, carte, spawn de la carte intérieure, spawn de sortie d'ici].
const DOORS := [
	[Vector2i(27, 27), &"route_5_daycare", &"entrance", &"from_daycare"],
	[Vector2i(34, 44), &"route_5_gate", &"from_route_5", &"from_gate"],
	[Vector2i(11, 56), &"route_5_underground_gate", &"from_route_5", &"from_underground"],
]
const NODE_BUDGET := 3000
const INF := 1 << 30

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (PNJ, objets, panneaux, indice).
var _terrain: GridWorld
var _stops: Dictionary = {}


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)
	for entry: Array in DOORS:
		_stops[entry[0]] = true


func after_all() -> void:
	_map.free()


func _doors() -> Array:
	var cells: Array = []
	for entry: Array in DOORS:
		cells.append(entry[0])
	return cells


func _grass(start_id: String) -> Dictionary:
	var start := _plan.cell_of(start_id)
	var zone := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		for side: Vector2i in GridPaths.DIRECTIONS:
			var next := cell + side
			if not zone.has(next) and _plan.at(next) == "h":
				zone[next] = true
				stack.append(next)
	return zone


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_5")
	assert_eq(_map.display_name, "Route 5")
	assert_eq(_map.region, "Azuria — Safrania")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_5"), &"golden_hour", "au plan de lumière")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_5"), &"route_5")
	assert_eq(zones.get_zone(&"route_5").subtitle, _map.region, "sous-titre = zone (annexe A)")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		assert_eq(GroundMask.kind_at(ground.mask.get_image(), Vector2i(20, 5)),
			GroundMask.Kind.PATH, "chemin du raccord")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var blocking := _plan.blocking_cells()
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			# Panneaux et indice : cases `bloque` sur l'herbe, fermées par leur décor.
			var decor := blocking.has(cell) and _plan.at(cell) == "." \
				and not _is_character_cell(cell)
			var solid := not _plan.is_walkable(cell) or decor
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell) != (mark == "h") \
					or _grid.is_water(cell) or _grid.get_ledge(cell) != GridWorld.Ledge.NONE:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_5.txt")
	assert_eq(_plan.walkable, ".=hDGE")


## PNJ et objet visible : leur case reste praticable dans le relief (ils l'occupent à l'exécution).
func _is_character_cell(cell: Vector2i) -> bool:
	for id: String in ["promeneuse", "voyageur", "route_5_item_1"]:
		if _plan.cells_at(id).has(cell):
			return true
	return false


# --- Passages ----------------------------------------------------------------------------

## T21 : le bord nord mène à la vraie Azuria, colonne pour colonne : (19..21, 0) ↔ (31..33, 40),
## arrivée tournée vers le nord ; arrivées d'Azuria `from_cerulean_w|c|e` sur les mêmes cases.
func test_north_edge_leads_to_cerulean_column_by_column() -> void:
	var cerulean := (load("res://game/world/maps/cerulean_city.tscn") as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(cerulean)
	for i: int in NORTH.size():
		var cell: Vector2i = NORTH[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.UP)
		assert_not_null(warp, "raccord nord %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon(), "plus de bouchon « à venir »")
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"cerulean_city", StringName("from_route_5_" + SUFFIXES[i]), Vector2i.UP])
			assert_eq(cerulean.get_spawn_cell(warp.target_spawn), Vector2i(31 + i, 40),
				"même colonne côté Azuria (décalage de 12)")
		assert_eq(_map.get_spawn_cell(StringName("from_cerulean_" + SUFFIXES[i])), cell)
		assert_eq(_plan.cell_of("from_cerulean_" + SUFFIXES[i]), cell, "grille corrigée")
		var back := cerulean.get_warps().find_on_push(Vector2i(31 + i, 40), Vector2i.DOWN)
		assert_not_null(back, "Azuria → Route 5 (%s)" % SUFFIXES[i])
		if back != null:
			assert_false(back.is_coming_soon(), "« ROUTE 5 — À venir » retiré côté Azuria")
			assert_eq([back.target_map, back.target_spawn, back.facing], [&"route_5",
				StringName("from_cerulean_" + SUFFIXES[i]), Vector2i.DOWN])


func test_doors_lead_into_the_three_buildings_and_back() -> void:
	for entry: Array in DOORS:
		var door: Vector2i = entry[0]
		assert_false(_grid.is_solid(door), "porte %s praticable" % door)
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp, "passage STEP_ON ↑ en %s" % door)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [entry[1], entry[2]])
		assert_eq(_map.get_spawn_cell(entry[3]), door + Vector2i.DOWN, "sortie devant la porte")
		var room := (load(MapCatalog.scene_path(entry[1])) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(room)
		assert_true(room.has_spawn(entry[2]), "%s : arrivée %s" % [entry[1], entry[2]])
		var exits := 0
		for back: Warp in room.get_warps().get_all():
			if back.target_map == &"route_5":
				exits += 1
				assert_eq(back.target_spawn, entry[3], "%s : retour devant la porte" % entry[1])
		assert_gt(exits, 0, "%s : sortie vers la Route 5" % entry[1])
	assert_eq(_map.get_warps().size(), 3 + 3, "raccord nord et trois portes, rien d'autre")


func test_signs_hidden_item_and_arrival_trigger() -> void:
	var expected := {
		_plan.cell_of("panneau_route"): [&"route_5_sign", Vector2i.RIGHT],
		_plan.cell_of("panneau_pension"): [&"route_5_daycare_sign", Vector2i.DOWN],
		_plan.cell_of("panneau_carrefour"): [&"route_5_crossroads_sign", Vector2i.RIGHT],
		_plan.cell_of("route_5_hidden_1"): [&"route_5_hidden_1", Vector2i.ZERO],
	}
	var points := _map.get_node(^"Interactables").get_children()
	assert_eq(points.size(), 4, "trois panneaux et l'indice")
	for child: Node in points:
		var point := child as InteractPoint
		assert_true(expected.has(point.get_cell()), "point en %s" % point.get_cell())
		if expected.has(point.get_cell()):
			assert_eq([point.dialogue_id, point.facing], expected[point.get_cell()])
		assert_true(_grid.is_solid(point.get_cell()), "%s bloqué" % point.name)
	var hidden := _map.get_node(^"Interactables/HiddenAntidote") as InteractPoint
	assert_eq(hidden.unless_flags, [&"got_route_5_hidden_1"] as Array[StringName])
	assert_not_null(_map.get_node_or_null(^"Entities/TrunkClue"), "tronc d'une autre teinte")
	var triggers := _map.get_triggers()
	assert_eq(triggers.size(), 3, "rangée 1, x 19..21")
	for cell: Vector2i in NORTH:
		var trigger := triggers.find_on_step(cell + Vector2i.DOWN, Vector2i.DOWN)
		assert_not_null(trigger, "arrivée en %s" % (cell + Vector2i.DOWN))
		if trigger != null:
			assert_eq(trigger.cutscene_id, &"route_5_arrival")


# --- Critères (plan_check_j15.py) --------------------------------------------------------

func test_every_door_is_reached_from_cerulean_without_tall_grass() -> void:
	var dist := GridPaths.distances(_terrain, NORTH, _stops)
	for door: Vector2i in _doors():
		assert_lt(int(dist.get(door, INF)), INF, "porte %s atteinte" % door)
	gut.p("route_5 : Pension %d, poste %d, souterrain %d pas" % [dist.get(DOORS[0][0], INF),
		dist.get(DOORS[1][0], INF), dist.get(DOORS[2][0], INF)])
	for zone: String in ["herbes_h1", "herbes_h2"]:
		assert_eq(GridPaths.min_crossed(_terrain, NORTH, _doors(), _grass(zone)), 0,
			"%s évitable" % zone)


func test_hidden_antidote_is_reached_by_the_optional_detour() -> void:
	var clue := _plan.cell_of("route_5_hidden_1")
	assert_eq(clue, Vector2i(16, 31))
	assert_true(GridPaths.distances(_terrain, NORTH, _stops).has(clue + Vector2i.DOWN),
		"indice examinable depuis (16, 32)")


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


func test_reserved_cells_stay_free() -> void:
	var reserved: Dictionary = {}
	for id: String in ["promeneuse", "voyageur", "route_5_item_1"]:
		reserved[_plan.cell_of(id)] = true
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_false(reserved.has(cell), "%s sur la case réservée %s" % [prop.name, cell])


func test_buildings_cover_their_grid_cells_and_leave_the_door() -> void:
	var specs := [["Daycare", "W", Vector2i(27, 27), 7 * 6], ["SaffronGate", "P",
		Vector2i(34, 44), 7 * 4], ["UndergroundEntrance", "U", Vector2i(11, 56), 7 * 4]]
	for spec: Array in specs:
		var building := _map.get_node_or_null(NodePath("Entities/" + spec[0])) as WorldProp
		assert_not_null(building, spec[0])
		if building == null:
			continue
		var solid := building.get_solid_cells()
		assert_eq(solid.size(), int(spec[3]) - 1, "%s : emprise moins la porte" % spec[0])
		assert_false(solid.has(spec[2]), "%s : porte libre" % spec[0])
		for cell: Vector2i in solid:
			assert_eq(_plan.at(cell), spec[1], "%s : emprise sur les cases %s" % [spec[0],
				spec[1]])


func test_garden_is_closed_by_the_fence_and_has_no_pokemon() -> void:
	var fence: Dictionary = {}
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Fence") and child is WorldProp:
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				fence[cell] = true
	for cell: Vector2i in _plan.cells_of("c"):
		assert_true(fence.has(cell), "clôture sur %s" % cell)
	for cell: Vector2i in fence:
		assert_eq(_plan.at(cell), "c", "clôture hors des cases c (%s)" % cell)
	var roster := NpcRoster.load_for_map(&"route_5")
	for spec: NpcSpec in roster.get_all():
		assert_false(String(spec.sprite).begins_with("pokemon/"), "aucun Pokémon (F-4)")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_5 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds")
