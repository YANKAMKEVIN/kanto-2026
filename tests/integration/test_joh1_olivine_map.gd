extends GutTest
## Oliville, carte extérieure (jalon JOH1 T5, docs/tech/jalon-joh1.md §2.7 ; dossier JOH-02
## §3.3) sur la **vraie scène** : métadonnées, grille de la scène = grille du plan, arrivées,
## passages, déclencheurs, points d'examen, lampes de nuit, accessibilité (à pied et en Surf).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN: String = "res://tools/plans/oliville.txt"
const SCENE: String = "res://game/world/maps/olivine_city.tscn"
const WALKABLE: String = ".pgqwDE"
const BLOCKED_ON_WALKABLE: String = "ynk"
## Panneaux et lampadaires : décors bloquants posés sur une case d'herbe ou de falaise.
const SIGNS: Array[Vector2i] = [Vector2i(23, 19), Vector2i(6, 19), Vector2i(12, 19),
	Vector2i(22, 19), Vector2i(33, 19), Vector2i(44, 19)]

var _plan: PlanGrid
var _map: GameMap


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN), _plan.error)
	var scene := load(SCENE) as PackedScene
	assert_not_null(scene, "scène chargée")
	if scene != null:
		_map = scene.instantiate() as GameMap
		add_child(_map)


func after_all() -> void:
	if _map != null:
		_map.free()


func _spawn_cell(spawn_name: String) -> Vector2i:
	var marker := _map.get_node("Spawns/%s" % spawn_name) as Marker2D
	return Vector2i(int(marker.position.x) / 96, int(marker.position.y) / 96 - 1)


func _warp(warp_name: String) -> Node:
	return _map.get_node_or_null("Warps/%s" % warp_name)


func _check_warp(warp_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i, soon: String = "") -> void:
	var warp := _warp(warp_name)
	assert_not_null(warp, warp_name)
	if warp == null:
		return
	assert_eq(Vector2i(int(warp.position.x) / 96, int(warp.position.y) / 96 - 1), cell, warp_name)
	assert_eq(int(warp.get(&"trigger")), trigger, warp_name)
	assert_eq(warp.get(&"direction"), direction, warp_name)
	assert_eq(warp.get(&"target_map"), target, warp_name)
	assert_eq(warp.get(&"target_spawn"), spawn, warp_name)
	assert_eq(warp.get(&"arrival_facing"), facing, warp_name)
	assert_eq(warp.get(&"coming_soon"), soon, warp_name)


func test_metadata() -> void:
	assert_eq(_map.map_id, &"olivine_city")
	assert_eq(_map.display_name, "Oliville")
	assert_eq(_map.light_profile, &"johto_auto")
	assert_eq(_map.size, Vector2i(50, 40))
	assert_eq(_plan.width, 50)
	assert_eq(_plan.height, 40)
	assert_false(_map.interior)


func test_scene_grid_matches_the_plan() -> void:
	var grid := _map.get_grid()
	var wrong: Array[Vector2i] = []
	for y: int in _plan.height:
		for x: int in _plan.width:
			var cell := Vector2i(x, y)
			var mark: String = _plan.at(cell)
			var solid: bool = not WALKABLE.contains(mark) or BLOCKED_ON_WALKABLE.contains(mark) \
				or SIGNS.has(cell)
			if grid.is_solid(cell) != solid:
				wrong.append(cell)
			if mark == "w":
				if not (grid.is_water(cell) and grid.is_surfable(cell)):
					wrong.append(cell)
			elif grid.is_surfable(cell):
				wrong.append(cell)
	assert_eq(wrong, [] as Array[Vector2i], "cases différentes du plan")


func test_spawns() -> void:
	var expected: Dictionary = {
		"from_route_39": Vector2i(49, 20), "from_route_39_1": Vector2i(49, 21),
		"from_route_39_2": Vector2i(49, 22), "from_sea_cave": Vector2i(11, 31),
		"from_sea_cave_1": Vector2i(11, 32), "from_center": Vector2i(27, 20),
		"from_center_1": Vector2i(28, 20), "from_mart": Vector2i(37, 20),
		"from_mart_1": Vector2i(38, 20), "from_house_1": Vector2i(16, 20),
		"from_house_2": Vector2i(37, 31),
	}
	for i: int in 10:
		expected["from_route_40" if i == 0 else "from_route_40_%d" % i] = Vector2i(20 + i, 39)
	for spawn_name: String in expected:
		assert_not_null(_map.get_node_or_null("Spawns/%s" % spawn_name), spawn_name)
		if _map.get_node_or_null("Spawns/%s" % spawn_name) != null:
			assert_eq(_spawn_cell(spawn_name), expected[spawn_name], spawn_name)
	assert_eq(_map.get_node(^"Spawns").get_child_count(), expected.size())
	assert_eq(_map.forced_surf_cells.size(), 10)
	for i: int in 10:
		assert_true(_map.forced_surf_cells.has(Vector2i(20 + i, 39)))


func test_warps() -> void:
	for i: int in 2:
		_check_warp("PorteCentre_%d" % i, Vector2i(27 + i, 19), 0, Vector2i.UP,
			&"olivine_center", &"entrance", Vector2i.UP)
		_check_warp("PorteBoutique_%d" % i, Vector2i(37 + i, 19), 0, Vector2i.UP,
			&"olivine_mart", &"entrance", Vector2i.UP)
		_check_warp("WarpGrotte_%d" % i, Vector2i(10, 31 + i), 0, Vector2i.LEFT,
			&"sea_cave_2", &"from_olivine_city" if i == 0 else &"from_olivine_city_1",
			Vector2i.UP)
	_check_warp("PorteMaison1", Vector2i(16, 19), 0, Vector2i.UP, &"olivine_house_1",
		&"entrance", Vector2i.UP)
	_check_warp("PorteMaison2", Vector2i(37, 30), 0, Vector2i.UP, &"olivine_house_2",
		&"entrance", Vector2i.UP)
	# JOH2 : la Route 39 existe, le passage est réel (arrivées `from_olivine`, `_1`, `_2`).
	for i: int in 3:
		_check_warp("WarpEst_%d" % i, Vector2i(49, 20 + i), 1, Vector2i.RIGHT, &"route_39",
			&"from_olivine" if i == 0 else StringName("from_olivine_%d" % i), Vector2i.RIGHT, "")
	for i: int in 10:
		_check_warp("WarpSudMer_%d" % i, Vector2i(20 + i, 39), 1, Vector2i.DOWN, &"",
			&"from_route_40" if i == 0 else StringName("from_route_40_%d" % i), Vector2i.UP,
			"Route 40")


func test_interaction_points_and_triggers() -> void:
	var town := _map.get_node_or_null("Interactables/PanneauVille")
	var lighthouse := _map.get_node_or_null("Interactables/PanneauPhare")
	assert_not_null(town)
	assert_not_null(lighthouse)
	if town != null:
		assert_eq(town.get(&"dialogue_id"), &"olivine_city_sign")
		assert_eq(town.get(&"facing"), Vector2i.UP)
		assert_eq(Vector2i(int(town.position.x) / 96, int(town.position.y) / 96 - 1),
			Vector2i(23, 19))
	if lighthouse != null:
		assert_eq(lighthouse.get(&"dialogue_id"), &"olivine_lighthouse_sign")
		assert_eq(lighthouse.get(&"facing"), Vector2i.UP)
		assert_eq(Vector2i(int(lighthouse.position.x) / 96, int(lighthouse.position.y) / 96 - 1),
			Vector2i(6, 19))
	var arrival := _map.get_node_or_null("Triggers/OlivineArrival")
	var arrival_2 := _map.get_node_or_null("Triggers/OlivineArrival2")
	var guard := _map.get_node_or_null("Triggers/GuardBarrier")
	assert_not_null(arrival)
	assert_not_null(arrival_2)
	assert_not_null(guard)
	if arrival != null:
		assert_eq(arrival.get(&"cutscene_id"), &"olivine_arrival")
		assert_eq(arrival.get(&"size"), Vector2i(1, 2))
		assert_eq(arrival.get(&"direction"), Vector2i.ZERO)
		assert_eq(Vector2i(int(arrival.position.x) / 96, int(arrival.position.y) / 96 - 1),
			Vector2i(12, 32))
	if arrival_2 != null:
		assert_eq(arrival_2.get(&"cutscene_id"), &"olivine_arrival")
		assert_eq(arrival_2.get(&"size"), Vector2i(1, 1))
		assert_eq(Vector2i(int(arrival_2.position.x) / 96, int(arrival_2.position.y) / 96 - 1),
			Vector2i(11, 33))
	if guard != null:
		assert_eq(guard.get(&"cutscene_id"), &"olivine_guard_block")
		assert_eq(guard.get(&"size"), Vector2i(1, 3))
		assert_eq(guard.get(&"direction"), Vector2i.RIGHT)
		assert_eq(Vector2i(int(guard.position.x) / 96, int(guard.position.y) / 96 - 1),
			Vector2i(48, 22))


func test_night_lights_follow_set_night() -> void:
	var lights := get_tree().get_nodes_in_group(&"night_lights").filter(
		func(n: Node) -> bool: return _map.is_ancestor_of(n))
	assert_gte(lights.size(), 7)
	# LightGlow se rallume à son _ready : c'est Boot qui rappelle set_night au chargement.
	var lighting := WorldLighting.new()
	add_child_autofree(lighting)
	lighting.set_night(false, _map)
	for light: Node in lights:
		assert_false((light as CanvasItem).visible, str(light.name))
	lighting.set_night(true, _map)
	for light: Node in lights:
		assert_true((light as CanvasItem).visible, str(light.name))
	assert_eq(_map.get_node(^"NightLights").get_child_count(), lights.size())


func test_all_walkable_cells_reachable_from_sea_cave() -> void:
	var grid := _map.get_grid()
	var reached := SurfRules.find_reachable(grid, _spawn_cell("from_sea_cave"), true)
	var missing: Array[Vector2i] = []
	var npc_cells: Array[Vector2i] = []
	for npc: Npc in _map.get_npcs():
		npc_cells.append(npc.get_cell())
	for y: int in _plan.height:
		for x: int in _plan.width:
			var cell := Vector2i(x, y)
			if not grid.is_solid(cell) and not reached.has(cell) and not npc_cells.has(cell):
				missing.append(cell)
	assert_eq(missing, [] as Array[Vector2i], "cases praticables inatteignables")
