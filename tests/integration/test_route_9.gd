extends GutTest
## Carte route_9 (jalon 18 T12, docs/tech/jalon-18.md §4.1 à §4.3 ; dossier 21 §3) sur la vraie
## scène : métadonnées et lumière, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_9.txt` case par case (solide, hautes herbes, rebords), raccords (bord ouest
## vers Azuria, variante J18 : arbre à couper du J16 ; bord est vers la Route 10), critères de
## `tools/art/plan_check_route_9.py` refaits sur la vraie grille (Lou et Benoît inévitables, les
## autres évitables, hautes herbes), cases réservées libres de tout décor, budget de nœuds.
## La vie (PNJ, objets, rencontres, déclencheur) : T18, voir test_route_9_life et _trainers.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_9.tscn"
const PLAN_PATH := "res://tools/plans/route_9.txt"
const SIZE := Vector2i(80, 36)
const WEST := [Vector2i(0, 22), Vector2i(0, 23), Vector2i(0, 24)]
const EAST := [Vector2i(79, 12), Vector2i(79, 13), Vector2i(79, 14)]
const NODE_BUDGET := 3000
const INF := 1 << 30

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


func _without(cells: Variant) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


func _nearest(dist: Dictionary, cells: Array) -> int:
	var best := INF
	for cell: Vector2i in cells:
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


func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_9")
	assert_eq(_map.display_name, "Route 9")
	assert_eq(_map.region, "Azuria — Route 10")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_9"), &"golden_hour")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_9"), &"route_9")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ouest")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or signs.has(cell)
			var ledge := GridWorld.Ledge.DOWN if mark == "v" else GridWorld.Ledge.NONE
			var ok := _grid.is_solid(cell) == solid \
				and _grid.is_tall_grass(cell) == (mark == "h") and _grid.get_ledge(cell) == ledge
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s, rebord %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell), _grid.get_ledge(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_9.txt")
	assert_eq(_plan.walkable, ".=hvo")


func test_west_edge_leads_to_azuria_row_by_row() -> void:
	var rows := ["_n", "", "_s"]
	for i: int in WEST.size():
		var cell: Vector2i = WEST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon(), "Azuria est reliée (variante J18)")
			assert_eq([warp.target_map, warp.target_spawn],
				[&"cerulean_city", StringName("from_route_9" + rows[i])])
			assert_eq(warp.facing, Vector2i.LEFT, "arrivée tournée vers l'ouest")
		assert_eq(_map.get_spawn_cell(StringName("from_cerulean" + rows[i])), cell)


func test_east_edge_leads_to_route_10_same_rows() -> void:
	var names := [&"from_route_9_n", &"from_route_9", &"from_route_9_s"]
	for i: int in EAST.size():
		var warp := _map.get_warps().find_on_push(EAST[i], Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % EAST[i])
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_10", names[i], Vector2i.RIGHT])
	assert_eq(_map.get_warps().size(), 6)
	assert_true(_map.has_spawn(&"from_route_10"), "spawn du plan")


## T16 : PNJ, Dresseurs et objets en données ; panneau et déclencheurs posés au T18.
func test_life_is_the_t16_data_only() -> void:
	# T18 : un point d'examen (panneau) et un déclencheur silencieux, dans les tests de vie.
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 1)
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 1)
	var ids := _npc_ids_and_data(_map.get_entities(), &"route_9")
	assert_eq(ids[0], ids[1], "PNJ de data/npcs/route_9.json")
	assert_eq((ids[1] as Array).size(), 12, "7 Dresseurs, 3 objets, 2 Pokémon d'ambiance")


func test_west_reaches_east_and_every_row_of_each() -> void:
	var dist := GridPaths.distances(_terrain, WEST)
	for cell: Vector2i in EAST:
		assert_lt(int(dist.get(cell, INF)), INF, "%s atteignable depuis l'ouest" % cell)
	var back := GridPaths.distances(_terrain, EAST)
	for cell: Vector2i in WEST:
		assert_lt(int(back.get(cell, INF)), INF, "%s atteignable depuis l'est" % cell)
	gut.p("route_9 : chemin principal %d pas" % _nearest(dist, EAST))


func test_lou_and_benoit_cannot_be_avoided() -> void:
	for id: String in ["lou", "benoit"]:
		var sight := _sight(id)
		assert_eq(sight.size(), int(_plan.attr(id, "sight")), "%s : vue dégagée" % id)
		assert_eq(_nearest(GridPaths.distances(_without(sight), WEST), EAST), INF,
			"%s inévitable" % id)


func test_the_other_trainers_can_be_avoided_together() -> void:
	var seen: Array[Vector2i] = []
	for id: String in ["adam", "jules", "zoe", "gilles", "noa"]:
		var sight := _sight(id)
		assert_gt(sight.size(), 0, "%s voit devant lui" % id)
		seen.append_array(sight)
	for id: String in ["adam", "jules"]:
		assert_lt(_nearest(GridPaths.distances(_without(_sight(id)), WEST), EAST), INF,
			"%s évitable" % id)
	assert_lt(_nearest(GridPaths.distances(_without(seen), WEST), EAST), INF,
		"évitables ensemble")


func test_the_two_corridors_each_suffice() -> void:
	var high := _plan.cells_at("itineraire_haut")
	var low := _plan.cells_at("itineraire_bas")
	assert_lt(_nearest(GridPaths.distances(_without(high), WEST), EAST), INF, "le bas suffit")
	assert_lt(_nearest(GridPaths.distances(_without(low), WEST), EAST), INF, "le haut suffit")
	assert_eq(_nearest(GridPaths.distances(_without(high + low), WEST), EAST), INF,
		"couper les deux ferme")


func test_ledges_jump_south_and_never_climb() -> void:
	for cell: Vector2i in _plan.cells_of("v"):
		assert_eq(_grid.get_step_target(cell + Vector2i.DOWN, Vector2i.UP),
			cell + Vector2i.DOWN, "rebord %s : ne se monte pas" % cell)
		if not _grid.is_solid(cell + Vector2i.UP):
			assert_eq(_grid.get_step_target(cell + Vector2i.UP, Vector2i.DOWN),
				cell + Vector2i.DOWN, "rebord %s : sauté vers le sud" % cell)


func test_tall_grass_h4_is_mandatory_h1_avoidable() -> void:
	var zones := {}
	for name: String in ["h1", "h4"]:
		var start := _plan.cell_of("herbes_" + name)
		var zone := {start: true}
		var stack: Array[Vector2i] = [start]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in GridPaths.DIRECTIONS:
				var next := cell + side
				if not zone.has(next) and _plan.at(next) == "h":
					zone[next] = true
					stack.append(next)
		zones[name] = zone
	assert_gt(GridPaths.min_crossed(_terrain, WEST, EAST, zones["h4"]), 0, "H4 incontournable")
	assert_eq(GridPaths.min_crossed(_terrain, WEST, EAST, zones["h1"]), 0, "H1 évitable")


func _props() -> Array[WorldProp]:
	var props: Array[WorldProp] = []
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				props.append(child as WorldProp)
	return props


func test_props_never_block_a_walkable_cell() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ouest")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(not _plan.is_walkable(cell) or signs.has(cell),
				"%s bloque la case praticable %s" % [prop.name, cell])


func test_reserved_cells_stay_free_of_decor() -> void:
	var kinds := ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
	var reserved: Dictionary = {}
	for id: String in _plan.positions:
		if kinds.has(_plan.positions[id]["kind"]):
			for cell: Vector2i in _plan.cells_at(id):
				reserved[cell] = true
	assert_eq(reserved.size(), 12, "7 Dresseurs, 3 objets, 2 Pokémon d'ambiance")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			var perch := _plan.at(cell) in ["R", "K"]
			assert_false(reserved.has(cell) and not perch,
				"%s sur la case réservée %s" % [prop.name, cell])
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Forest"):
			var foot := Vector2i(((child as Node2D).position - Vector2(0, 1)) / Grid.TILE_SIZE)
			assert_false(reserved.has(foot), "%s sur la case réservée %s" % [child.name, foot])


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_9 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds")


## Identifiants des PNJ de [param root] (scène chargée) et ceux des données (T16, nouvelle partie).
func _npc_ids_and_data(root: Node, map_id: StringName) -> Array:
	var on_map: Array[String] = []
	for node: Node in root.find_children("*", "Npc", true, false):
		on_map.append(String((node as Npc).get_id()))
	var data: Array[String] = []
	for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(null):
		data.append(String(spec.id))
	on_map.sort()
	data.sort()
	return [on_map, data]
