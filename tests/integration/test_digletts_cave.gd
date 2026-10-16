extends GutTest
## La Cave Taupiqueur (jalon 17 T15, docs/tech/jalon-17.md §2.1, §2.3 ; dossier 20 §3.3) sur la
## **vraie scène** : grille de la scène = grille du plan, 96 pas d'une bouche à l'autre, gravats
## obligatoires seulement en G2 (G1, G3, G4 évitables), Corde Sortie depuis les deux moitiés,
## budget de nœuds, raccords avec la Route 11 (T16) et la Route 2 est (T19) en attente propre
## tant que ces cartes manquent.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH: String = "res://tools/plans/digletts_cave.txt"
const MAP_ID: StringName = &"digletts_cave"
const WALKABLE: String = ".gE"
const NODE_BUDGET: int = 3000
const MAX_GLOWS: int = 16
const SIZE := Vector2i(34, 80)

var _plan: PlanGrid
var _map: GameMap


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	var scene := load(MapCatalog.scene_path(MAP_ID)) as PackedScene
	assert_not_null(scene, "scène construite (tools/build_digletts_cave.gd)")
	if scene != null:
		_map = scene.instantiate() as GameMap
		add_child(_map)


func after_all() -> void:
	if _map != null:
		_map.free()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


## Distances (pas) depuis [param starts] sur les cases praticables de la scène, sans entrer dans
## [param blocked].
func _distances(starts: Array[Vector2i], blocked: Dictionary = {}) -> Dictionary:
	var grid := _map.get_grid()
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	for start: Vector2i in starts:
		dist[start] = 0
		queue.append(start)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + step
			if grid.is_in_bounds(next) and not grid.is_solid(next) and not dist.has(next) \
					and not blocked.has(next):
				dist[next] = int(dist[cell]) + 1
				queue.append(next)
	return dist


func _rubble_group(origin: Vector2i) -> Dictionary:
	var group: Dictionary = {}
	var stack: Array[Vector2i] = [origin]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if group.has(cell) or _plan.at(cell) != "g":
			continue
		group[cell] = true
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			stack.append(cell + step)
	return group


func test_metadata_and_light() -> void:
	assert_eq(_map.map_id, MAP_ID)
	assert_eq(_map.display_name, "Cave Taupiqueur")
	assert_eq(_map.size, SIZE)
	assert_false(_map.interior, "grotte = extérieure (compagnon visible)")
	assert_eq(_map.light_profile, &"cave_sand")
	var library := LightingLibrary.new()
	assert_true(library.load_file())
	var sand := library.get_profile(&"cave_sand")
	var first := library.get_profile(&"cave_1f")
	assert_not_null(sand)
	var sum := func(p: LightProfile) -> float:
		return (p.grade_shadows + p.grade_midtones + p.grade_highlights).dot(Vector3.ONE)
	assert_gt(sum.call(sand), sum.call(first), "plus clair que le Mont Sélénite 1F")
	assert_false(sand.has_cast_shadow())
	assert_false(sand.has_wind())
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_true(caves.is_cave(MAP_ID))
	assert_false(caves.is_dark(MAP_ID), "la Cave n'est pas obscure")
	assert_null(_map.get_node_or_null(^"CaveShade"), "aucun voile de pénombre")


func test_scene_grid_matches_the_plan() -> void:
	var grid := _map.get_grid()
	var wrong: Array[Vector2i] = []
	var rubble_wrong: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if grid.is_solid(cell) == WALKABLE.contains(_plan.at(cell)) \
					or (_plan.at(cell) == "g" and grid.is_solid(cell)):
				wrong.append(cell)
			if grid.is_rubble(cell) != (_plan.at(cell) == "g"):
				rubble_wrong.append(cell)
	assert_eq(wrong, [] as Array[Vector2i], "cases différentes du plan")
	assert_eq(rubble_wrong, [] as Array[Vector2i], "gravats = cases g, et elles seules")


func test_ninety_six_steps_from_mouth_to_mouth() -> void:
	var south := _arrival_cells(&"from_route_11")
	var north := _arrival_cells(&"from_route_2_east")
	assert_eq(south, [Vector2i(15, 78), Vector2i(16, 78)] as Array[Vector2i])
	assert_eq(north, [Vector2i(16, 1), Vector2i(17, 1)] as Array[Vector2i])
	var mouths_north: Array[Vector2i] = [Vector2i(16, 0), Vector2i(17, 0)]
	var mouths_south: Array[Vector2i] = [Vector2i(15, 79), Vector2i(16, 79)]
	var there := _distances(south)
	var back := _distances(north)
	assert_eq(_min_of(there, mouths_north), 96, "sud → nord")
	assert_eq(_min_of(back, mouths_south), 96, "nord → sud")


func _min_of(dist: Dictionary, cells: Array[Vector2i]) -> int:
	var best := 1 << 30
	for cell: Vector2i in cells:
		best = mini(best, int(dist.get(cell, 1 << 30)))
	return best


func _arrival_cells(prefix: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for suffix: String in ["w", "e"]:
		var name := StringName("%s_%s" % [prefix, suffix])
		assert_true(_map.has_spawn(name), String(name))
		cells.append(_map.get_spawn_cell(name))
	return cells


func test_rubble_is_mandatory_only_in_g2() -> void:
	var south := _arrival_cells(&"from_route_11")
	var north := _arrival_cells(&"from_route_2_east")
	var groups := {&"G1": Vector2i(14, 61), &"G2": Vector2i(6, 49), &"G3": Vector2i(20, 28),
		&"G4": Vector2i(15, 10)}
	var all_rubble: Dictionary = {}
	for group_id: StringName in groups:
		var group := _rubble_group(groups[group_id])
		assert_gt(group.size(), 0, String(group_id))
		for cell: Vector2i in group:
			all_rubble[cell] = true
		var reach := _distances(south, group)
		var open := reach.has(north[0]) or reach.has(north[1])
		assert_eq(open, group_id != &"G2", "%s : %s" % [group_id,
			"obligatoire" if group_id == &"G2" else "évitable"])
	var none := _distances(south, all_rubble)
	assert_false(none.has(north[0]) or none.has(north[1]), "sans gravats, pas de traversée")


func test_escape_rope_from_both_halves() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var north := caves.escape_target(MAP_ID, Vector2i(16, 5))
	var north_edge := caves.escape_target(MAP_ID, Vector2i(10, 39))
	var south := caves.escape_target(MAP_ID, Vector2i(15, 70))
	var south_edge := caves.escape_target(MAP_ID, Vector2i(10, 40))
	for exit: CaveExit in [north, north_edge]:
		assert_not_null(exit)
		assert_eq([exit.map, exit.spawn], [&"route_2_east", &"from_cave_w"])
	for exit: CaveExit in [south, south_edge]:
		assert_not_null(exit)
		assert_eq([exit.map, exit.spawn], [&"route_11", &"from_cave_w"])


func test_node_budget_and_glows() -> void:
	var nodes := _count(_map)
	gut.p("%s : %d nœuds" % [MAP_ID, nodes])
	assert_lte(nodes, NODE_BUDGET)
	var glows: Array[Node] = []
	_find(_map, glows, func(n: Node) -> bool: return n is LightGlow)
	assert_between(glows.size(), 4, MAX_GLOWS)
	var lights: Array[Node] = []
	_find(_map, lights, func(n: Node) -> bool: return n is Light2D)
	assert_eq(lights.size(), 0, "aucune Light2D")


func _find(node: Node, out: Array[Node], test: Callable) -> void:
	if test.call(node):
		out.append(node)
	for child: Node in node.get_children():
		_find(child, out, test)


func test_ambient_diglett_data_matches_the_plan() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/digletts_cave.json"))
	# Trois Taupiqueur d'ambiance et la Corde Sortie du renfoncement R1 (posée à l'intégration).
	assert_eq(data.size(), 4)
	var rope: Array = data["digletts_cave_item_1"]["cell"]
	assert_eq(Vector2i(int(rope[0]), int(rope[1])), _plan.cells_at("cave_item_1")[0],
		"position cave_item_1 de la grille")
	assert_eq(_plan.attr("cave_item_1", "item"), "escape_rope")
	for i: int in 3:
		var cell: Array = data["taupiqueur_%d" % (i + 1)]["cell"]
		var expected: Vector2i = [Vector2i(17, 62), Vector2i(22, 29), Vector2i(18, 13)][i]
		assert_eq(Vector2i(int(cell[0]), int(cell[1])), expected)
		assert_eq(data["taupiqueur_%d" % (i + 1)]["shy"]["action"], "hide")
		assert_ne(_plan.at(expected), "#")


# --- Raccords avec la Route 11 et la Route 2 est (intégrés au J17) --------------------------


func test_junctions_with_route_11_and_route_2_east() -> void:
	var pairs := {
		&"route_11": [[Vector2i(15, 79), &"from_cave_w"], [Vector2i(16, 79), &"from_cave_e"]],
		&"route_2_east": [[Vector2i(16, 0), &"from_cave_w"], [Vector2i(17, 0), &"from_cave_e"]],
	}
	for target: StringName in pairs:
		var warps: Array = []
		for warp: Warp in _map.get_warps().get_all():
			if pairs[target].any(func(p: Array) -> bool: return p[0] == warp.cell):
				warps.append(warp)
		assert_eq(warps.size(), 2, "deux cases de bouche vers %s" % target)
		assert_true(MapCatalog.has_map(target), String(target))
		for warp: Warp in warps:
			assert_false(warp.is_coming_soon(), "relancer tools/build_digletts_cave.gd")
			assert_eq(warp.target_map, target)
		var other := (load(MapCatalog.scene_path(target)) as PackedScene).instantiate() as GameMap
		add_child(other)
		for pair: Array in pairs[target]:
			assert_true(other.has_spawn(pair[1]), "%s : %s" % [target, pair[1]])
		# Aller-retour : la case d'arrivée de la Cave porte, sur l'autre carte, un warp qui y revient.
		var back_names: Array = ["from_route_11_w", "from_route_11_e"] if target == &"route_11" \
			else ["from_route_2_east_w", "from_route_2_east_e"]
		for name: String in back_names:
			assert_true(_map.has_spawn(StringName(name)))
		var returns := 0
		for warp: Warp in other.get_warps().get_all():
			if warp.target_map == MAP_ID and _map.has_spawn(warp.target_spawn):
				returns += 1
		assert_gte(returns, 2, "%s : retour vers la Cave" % target)
		other.free()
