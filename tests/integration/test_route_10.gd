extends GutTest
## Carte route_10 (jalon 18 T12, docs/tech/jalon-18.md §4.1 à §4.3 ; dossier 21 §4) sur la vraie
## scène : **grille de la scène = grille fonctionnelle** `tools/plans/route_10.txt`, **deux
## secteurs non reliés à pied** (nord depuis le raccord ouest, sud depuis la sortie sud de la
## grotte), eau jamais praticable, centrale sans porte ni texte, raccords (Route 9, Centre,
## bouches de la grotte et Lavanville « à venir » tant que leurs cartes n'existent pas), cases
## réservées libres de décor, budget de nœuds. La vie : T18 (nord) et T24 (sud).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_10.tscn"
const PLAN_PATH := "res://tools/plans/route_10.txt"
const SIZE := Vector2i(34, 76)
const WEST := [Vector2i(0, 12), Vector2i(0, 13), Vector2i(0, 14)]
const NODE_BUDGET := 3000
const INF := 1 << 30

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
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
	# `relief` ne copie pas l'eau (ni solide, ni praticable) : on la ferme explicitement.
	for cell: Vector2i in _plan.cells_of("w"):
		assert_true(_grid.is_water(cell))
		_terrain.set_solid(cell)
	for mark: String in ["D", "Q"]:
		for cell: Vector2i in _plan.cells_of(mark):
			_stops[cell] = true


func after_all() -> void:
	_map.free()


func _front_of(id: String) -> Array:
	return _plan.cells_at(id)


func test_metadata_light_and_zone() -> void:
	assert_eq(_map.map_id, &"route_10")
	assert_eq(_map.display_name, "Route 10")
	assert_eq(_map.region, "Route 9 — Lavanville")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_10"), &"golden_hour")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_10"), &"route_10")
	assert_eq(zones.zone_of(&"route_10_center"), &"route_10")
	assert_not_null(_map.get_node_or_null(^"PaintedGround"), "sol peint")


func test_scene_grid_is_the_functional_grid() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_grotte") + _plan.cells_at("panneau_centre")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or signs.has(cell)
			var ok := (_grid.is_solid(cell) or _grid.is_water(cell)) == solid \
				and _grid.is_tall_grass(cell) == (mark == "h") \
				and _grid.is_water(cell) == (mark == "w")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s, eau %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell), _grid.is_water(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_10.txt")
	assert_eq(_plan.walkable, ".=hoDQ")


func test_water_is_never_walkable() -> void:
	var water: Array[Vector2i] = _plan.cells_of("w")
	assert_eq(water.size(), 5 * SIZE.y)
	for cell: Vector2i in water:
		assert_true(_grid.is_water(cell), "%s est de l'eau" % cell)
		for side: Vector2i in GridPaths.DIRECTIONS:
			assert_ne(_grid.get_step_target(cell + side, -side), cell, "on n'entre pas en %s" % cell)


func test_two_sectors_are_not_connected_on_foot() -> void:
	var north := GridPaths.distances(_terrain, WEST, _stops)
	var south_start: Array = _plan.cells_at("from_dark_cave_s")
	var south := GridPaths.distances(_terrain, south_start, _stops)
	for cell: Vector2i in north:
		assert_false(south.has(cell), "%s est dans les deux secteurs" % cell)
	for cell: Vector2i in north:
		assert_lt(cell.y, 29, "le secteur nord s'arrête avant la bande centrale")
	for cell: Vector2i in south:
		assert_gte(cell.y, 47, "le secteur sud commence à la sortie de la grotte")
	assert_true(north.has(_plan.cell_of("herbes_h1")))
	assert_true(south.has(_plan.cell_of("herbes_h2")))
	# Les portes se touchent mais ne se traversent pas : Centre et bouche nord au nord, bouche
	# sud et Lavanville au sud.
	for cell: Vector2i in _plan.cells_at("porte_centre") + _plan.cells_at("entree_grotte_nord"):
		assert_true(north.has(cell))
	for cell: Vector2i in _plan.cells_at("entree_grotte_sud") + _plan.cells_at("warp_sud"):
		assert_true(south.has(cell), "%s atteignable depuis la sortie sud" % cell)
	# Rien de praticable dans la bande centrale (y 29..46), ni sur la rive est.
	for y: int in range(29, 47):
		for x: int in SIZE.x:
			assert_true(_terrain.is_solid(Vector2i(x, y)), "bande centrale libre en %d,%d" % [x, y])
	# Sur la vraie scène (sans les positions de la grille) : le même constat.
	var real := GridPaths.distances(_grid, WEST, _stops)
	assert_false(real.has(_plan.cell_of("from_dark_cave_s")), "sortie sud non reliée (scène)")
	for cell: Vector2i in _plan.cells_of("E"):
		assert_true(_terrain.is_solid(cell), "centrale %s bloquée" % cell)


func test_central_has_no_door_no_text() -> void:
	var cells: Array[Vector2i] = _plan.cells_at("centrale")
	assert_eq(cells.size(), 5 * 7)
	for cell: Vector2i in cells:
		assert_eq(_plan.at(cell), "E")
		assert_true(_grid.is_solid(cell))
	for warp: Warp in _map.get_warps().get_all():
		assert_false(cells.has(warp.cell) or cells.has(warp.cell + Vector2i.UP))
	var box := Rect2i(29, 2, 5, 8)
	for point: Node in _map.get_node(^"Interactables").get_children():
		assert_false(box.has_point(Vector2i((point as Node2D).position / Grid.TILE_SIZE)))
	assert_not_null(_map.get_node_or_null(^"Entities/Central"), "décor posé")


func test_west_edge_leads_to_route_9_same_rows() -> void:
	var names := [&"from_route_10_n", &"from_route_10", &"from_route_10_s"]
	for i: int in WEST.size():
		var warp := _map.get_warps().find_on_push(WEST[i], Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % WEST[i])
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_9", names[i], Vector2i.LEFT])
	assert_true(_map.has_spawn(&"from_route_9"))
	assert_eq(_map.get_spawn_cell(&"from_route_9"), Vector2i(0, 13))


func test_center_door_leads_to_the_center_and_back() -> void:
	for cell: Vector2i in _plan.cells_at("porte_centre"):
		assert_false(_grid.is_solid(cell))
		var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "porte %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_10_center", &"entrance", Vector2i.ZERO])
	assert_eq(_map.get_spawn_cell(&"from_center"), Vector2i(7, 12))
	var center := _map.get_node_or_null(^"Entities/PokemonCenter") as WorldProp
	assert_not_null(center)
	if center != null:
		for cell: Vector2i in center.get_solid_cells():
			assert_eq(_plan.at(cell), "C", "emprise du Centre (%s)" % cell)


## Bouches de la grotte et raccord sud : la vraie carte si elle existe, sinon « à venir ».
func test_cave_mouths_and_south_edge() -> void:
	var cave_built := MapCatalog.has_map(&"dark_cave_1f")
	for id: String in ["entree_grotte_nord", "entree_grotte_sud"]:
		for cell: Vector2i in _plan.cells_at(id):
			assert_false(_grid.is_solid(cell))
			var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
			assert_not_null(warp, "bouche %s" % cell)
			if warp == null:
				continue
			if cave_built:
				assert_eq(warp.target_map, &"dark_cave_1f")
				assert_eq(warp.target_spawn, StringName("from_route_10_%s_%s" % [
					"n" if id.ends_with("nord") else "s", "we"[cell.x - _plan.cells_at(id)[0].x]]))
			else:
				assert_eq(warp.coming_soon, "Grotte Sombre")
				assert_eq(warp.facing, Vector2i.DOWN)
				assert_eq(_map.get_spawn_cell(warp.target_spawn), cell + Vector2i.DOWN)
	for spawn: StringName in [&"from_dark_cave_n_w", &"from_dark_cave_n_e",
			&"from_dark_cave_s_w", &"from_dark_cave_s_e"]:
		assert_true(_map.has_spawn(spawn))
	assert_eq(_map.get_spawn_cell(&"from_dark_cave_n_w"), Vector2i(16, 8))
	assert_eq(_map.get_spawn_cell(&"from_dark_cave_s_w"), Vector2i(8, 48))
	var lavender_built := MapCatalog.has_map(&"lavender_town")
	for cell: Vector2i in _plan.cells_at("warp_sud"):
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "raccord sud %s" % cell)
		if warp == null:
			continue
		if lavender_built:
			assert_eq(warp.target_map, &"lavender_town")
			assert_eq(warp.target_spawn, StringName("from_route_10_" + "wce"[cell.x - 21]))
		else:
			assert_eq(warp.coming_soon, "Lavanville")
			assert_eq(_map.get_spawn_cell(warp.target_spawn), cell)
	for suffix: String in ["w", "c", "e"]:
		assert_true(_map.has_spawn(StringName("from_lavender_" + suffix)))


## T16 : PNJ, Dresseurs et objet en données ; panneaux et déclencheurs posés au T18 (nord) et au
## T24 (sortie sud de la grotte : `dark_cave_crossed`, testé dans `test_route_10_life`).
func test_life_is_the_t16_data_and_the_t24_trigger() -> void:
	var scenes: Array[StringName] = []
	for point: Node in _map.get_node(^"Triggers").get_children():
		scenes.append(point.get(&"cutscene_id"))
	assert_true(scenes.has(&"dark_cave_crossed"), "sortie sud de la grotte (T24)")
	# T18 : un point d'examen (panneau) et un déclencheur silencieux (route_10_reached).
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 2)
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 2)
	var ids := _npc_ids_and_data(_map.get_entities(), &"route_10")
	assert_eq(ids[0], ids[1], "PNJ de data/npcs/route_10.json")
	assert_eq((ids[1] as Array).size(), 4, "Hector, Paul, le randonneur, la Super Potion")


func test_trainers_are_optional_and_the_sectors_reach_their_exits() -> void:
	var north := GridPaths.distances(_terrain, WEST, _stops)
	assert_true(north.has(_plan.cell_of("herbes_h1")))
	var south := GridPaths.distances(_terrain, _plan.cells_at("from_dark_cave_s"), _stops)
	for id: String in ["hector", "paul"]:
		var facing := Grid.direction_from_name(_plan.attr(id, "facing"))
		var origin := _plan.cell_of(id)
		var seen: Array[Vector2i] = []
		for k: int in range(1, int(_plan.attr(id, "sight")) + 1):
			var cell := origin + facing * k
			if _terrain.is_solid(cell):
				break
			seen.append(cell)
		var blocked := GridPaths.relief(_terrain, SIZE)
		for cell: Vector2i in seen:
			blocked.set_solid(cell)
		var reach := GridPaths.distances(blocked, _plan.cells_at("from_dark_cave_s"), _stops)
		for cell: Vector2i in _plan.cells_at("warp_sud"):
			assert_true(reach.has(cell), "%s évitable : Lavanville reste atteignable" % id)
	var item := _plan.cell_of("route_10_item_1")
	var touched := false
	for side: Vector2i in GridPaths.DIRECTIONS:
		touched = touched or south.has(item + side)
	assert_true(touched, "objet du secteur sud ramassable")


func _props() -> Array[WorldProp]:
	var props: Array[WorldProp] = []
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				props.append(child as WorldProp)
	return props


func test_props_never_block_a_walkable_cell() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_grotte") + _plan.cells_at("panneau_centre")
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
	assert_eq(reserved.size(), 4, "2 Dresseurs, 1 PNJ, 1 objet")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_false(reserved.has(cell) and _plan.at(cell) != "R",
				"%s sur la case réservée %s" % [prop.name, cell])
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Forest"):
			var foot := Vector2i(((child as Node2D).position - Vector2(0, 1)) / Grid.TILE_SIZE)
			assert_false(reserved.has(foot), "%s sur la case réservée %s" % [child.name, foot])


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_10 : %d nœuds" % count)
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
