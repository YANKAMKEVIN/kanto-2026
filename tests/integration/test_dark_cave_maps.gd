extends GutTest
## Les deux étages de la Grotte Sombre (jalon 18 T13, docs/tech/jalon-18.md §4.1–§4.3, §6) sur
## les **vraies scènes** : métadonnées, grille de la scène = grille du plan, échelles A et B
## (mêmes coordonnées, aller-retour), graphe entrée nord → A → B1F → B → moitié sud → sortie sud,
## moitiés du 1F **non reliées** et jamais visibles ensemble, retour à l'entrée de partout,
## gravats `g` = RUBBLE (aucune table de rencontre), 10 gravats sur le plus court chemin, halos,
## budget, passage étroit. Vie (T20) : PNJ des données, points d'examen et objet caché.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const WALKABLE: String = ".gjUVEe"
const NODE_BUDGET: int = 3000
const MAX_GLOWS: int = 16
const FLOORS: Dictionary = {
	&"dark_cave_1f": ["res://tools/plans/grotte_sombre_1f.txt", Vector2i(56, 49), &"dark_cave_1f"],
	&"dark_cave_b1f": ["res://tools/plans/grotte_sombre_b1f.txt", Vector2i(48, 38), &"dark_cave_b1f"],
}
## Décors bloquants posés sur une case praticable de la grille (lampes, panneau).
const DECOR_BLOCKED: Dictionary = {
	&"dark_cave_1f": [Vector2i(23, 4), Vector2i(17, 44), Vector2i(26, 2)],
	&"dark_cave_b1f": [Vector2i(30, 26)],
}
const NORTH_ENTRY: Array[Vector2i] = [Vector2i(27, 0), Vector2i(28, 0)]
const SOUTH_EXIT: Array[Vector2i] = [Vector2i(8, 48), Vector2i(9, 48)]
## Vue de jeu : 2340 × 1080 (zoom 1, 96 px par case) ; cases entières visibles de part et
## d'autre du centre (demi-vue + demi-case), et disque de sécurité.
const VIEW_HALF_X: int = 12
const VIEW_HALF_Y: int = 6
const SAFE_RADIUS: float = 9.0

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in FLOORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(FLOORS[map_id][0]), plan.error)
		_plans[map_id] = plan
		var scene := load(MapCatalog.scene_path(map_id)) as PackedScene
		if scene != null:
			var map := scene.instantiate() as GameMap
			add_child(map)
			_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _find_all(node: Node, out: Array[Node], test: Callable) -> void:
	if test.call(node):
		out.append(node)
	for child: Node in node.get_children():
		_find_all(child, out, test)


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


# --- Métadonnées, lumière, budgets ----------------------------------------------------------


func test_floors_exist_as_outdoor_cave_maps() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	for map_id: StringName in FLOORS:
		assert_true(_maps.has(map_id), "%s construite" % map_id)
		var map: GameMap = _maps.get(map_id)
		if map == null:
			continue
		assert_eq(map.map_id, map_id)
		assert_eq(map.display_name, "Grotte Sombre")
		assert_eq(map.region, "")
		assert_false(map.interior)
		assert_eq(map.size, FLOORS[map_id][1])
		assert_eq(map.light_profile, FLOORS[map_id][2])
		assert_true(caves.is_cave(map_id))
		assert_eq(caves.cave_of(map_id), &"dark_cave")
		assert_not_null(map.get_node_or_null(^"PaintedGround"))
		assert_not_null(map.get_node_or_null(^"CaveShade"), "pénombre précalculée")


func test_caves_json_entry_and_rope() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_eq(caves.get_maps(&"dark_cave"),
		[&"dark_cave_1f", &"dark_cave_b1f"] as Array[StringName])
	for map_id: StringName in FLOORS:
		var exit := caves.escape_target(map_id)
		assert_not_null(exit)
		assert_eq(exit.map, &"route_10")
		assert_eq(exit.facing, Vector2i.DOWN)
		assert_eq(exit.spawn, &"from_dark_cave_n_w")
		# T15 (fusion du J17) : grotte obscure, couverte par le voile du J17 (`test_dark_cave_flash`).
		assert_true(caves.is_dark(map_id), "%s : obscure" % map_id)
	for map_id: StringName in caves.get_maps(&"mt_moon"):
		assert_false(caves.is_dark(map_id), "%s : jamais de voile" % map_id)


func test_light_profile_and_battle_decor() -> void:
	var library := LightingLibrary.new()
	assert_true(library.load_file())
	assert_eq(library.get_map_profile(&"dark_cave_1f"), &"dark_cave_1f")
	assert_eq(library.get_map_profile(&"dark_cave_b1f"), &"dark_cave_b1f")
	var catalog := BattleDecorCatalog.load_file()
	for map_id: StringName in FLOORS:
		assert_eq(catalog.default_for(map_id).id, &"dark_cave_galerie", String(map_id))


func test_glows_within_budget_and_no_light2d() -> void:
	var library := LightGlow.library()
	for map_id: StringName in _maps:
		var glows: Array[Node] = []
		_find_all(_maps[map_id], glows, func(n: Node) -> bool: return n is LightGlow)
		assert_between(glows.size(), 1, MAX_GLOWS, "%s : %d halos" % [map_id, glows.size()])
		for glow: Node in glows:
			assert_true(library.has_type((glow as LightGlow).glow_type), str(glow.name))
		var lights: Array[Node] = []
		_find_all(_maps[map_id], lights, func(n: Node) -> bool: return n is Light2D)
		assert_eq(lights.size(), 0, "%s : aucune Light2D" % map_id)


func test_node_budget() -> void:
	for map_id: StringName in _maps:
		var nodes := _count(_maps[map_id])
		gut.p("%s : %d nœuds" % [map_id, nodes])
		assert_lte(nodes, NODE_BUDGET, String(map_id))


## T16 : Dresseurs et objets en données ; T20 : examens (T-6, T-8 à T-10) et objet caché.
func test_cave_life_is_the_t16_data_and_the_t20_examinations() -> void:
	var expected := {&"dark_cave_1f": 5, &"dark_cave_b1f": 3}
	# 1F : le panneau ; B1F : colonne 5 × 6, une racine, la paroi fendue, l'objet caché.
	var points := {&"dark_cave_1f": 1, &"dark_cave_b1f": 33}
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		assert_eq(map.get_node(^"Interactables").get_child_count(), points[map_id],
			"%s : points d'examen" % map_id)
		assert_eq(map.get_node(^"Triggers").get_child_count(), 0, "%s : aucun déclencheur" % map_id)
		var npcs: Array[Node] = []
		_find_all(map, npcs, func(n: Node) -> bool: return n is Npc)
		var on_map: Array[String] = []
		for npc: Node in npcs:
			on_map.append(String((npc as Npc).get_id()))
		var data: Array[String] = []
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(null):
			data.append(String(spec.id))
		on_map.sort()
		data.sort()
		assert_eq(on_map, data, "%s : PNJ de data/npcs/" % map_id)
		assert_eq(data.size(), expected.get(map_id, 0), "%s : Dresseurs et objets" % map_id)


func _interaction_dialogue(map_id: StringName, cell: Vector2i) -> StringName:
	for point: Node in (_maps[map_id] as GameMap).get_node(^"Interactables").get_children():
		if (point as InteractPoint).get_cell() == cell:
			return (point as InteractPoint).dialogue_id
	return &""


func test_examinations_and_hidden_item_cells() -> void:
	assert_eq(_interaction_dialogue(&"dark_cave_1f", Vector2i(26, 2)), &"dark_cave_1f_sign")
	assert_eq(_interaction_dialogue(&"dark_cave_b1f", Vector2i(21, 14)), &"dark_cave_column")
	assert_eq(_interaction_dialogue(&"dark_cave_b1f", Vector2i(43, 32)), &"dark_cave_roots")
	assert_eq(_interaction_dialogue(&"dark_cave_b1f", Vector2i(32, 1)), &"dark_cave_crack")
	# Objet caché : la racine (41, 32), face à l'indice depuis (42, 32).
	assert_eq(_interaction_dialogue(&"dark_cave_b1f", Vector2i(41, 32)),
		&"dark_cave_b1f_hidden_1")
	var library := DialogueLibrary.new()
	library.load_dir()
	for id: StringName in [&"dark_cave_1f_sign", &"dark_cave_column", &"dark_cave_roots",
			&"dark_cave_crack", &"dark_cave_b1f_hidden_1"]:
		assert_not_null(library.get_dialogue(id), String(id))


## T16 : gravats seulement (I-10), une table par étage (test_j18_data).
func test_rubble_tables_only() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir())
	for map_id: StringName in FLOORS:
		assert_not_null(library.get_table(map_id, &"rubble"), "%s : table des gravats" % map_id)
		assert_null(library.get_table(map_id), "%s : aucune table d'herbe" % map_id)


# --- Grille ---------------------------------------------------------------------------------


func test_scene_grid_matches_the_plan() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var grid := (_maps[map_id] as GameMap).get_grid()
		var decor: Array = DECOR_BLOCKED.get(map_id, [])
		var wrong: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var walkable := WALKABLE.contains(plan.at(cell)) and not decor.has(cell)
				if grid.is_solid(cell) == walkable:
					wrong.append(cell)
		assert_eq(wrong, [] as Array[Vector2i], "%s : cases différentes du plan" % map_id)


func test_rubble_tiles_exactly_on_g_cells() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var ground := (_maps[map_id] as GameMap).get_node(^"Ground") as TileMapLayer
		var count := 0
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var data := ground.get_cell_tile_data(cell)
				var rubble: bool = data.get_custom_data(OverworldTiles.DATA_RUBBLE)
				assert_eq(rubble, plan.at(cell) == "g", "%s %s" % [map_id, cell])
				assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
				if rubble:
					count += 1
		assert_gt(count, 0, "%s : des gravats" % map_id)


func test_narrow_passage_is_six_cells_of_one() -> void:
	var grid := (_maps[&"dark_cave_b1f"] as GameMap).get_grid()
	var run := 0
	for x: int in range(35, 41):
		var cell := Vector2i(x, 34)
		assert_false(grid.is_solid(cell), str(cell))
		assert_true(grid.is_solid(cell + Vector2i.UP) and grid.is_solid(cell + Vector2i.DOWN),
			"%s : 1 case de large" % cell)
		run += 1
	assert_eq(run, 6)
	assert_false(grid.is_solid(Vector2i(34, 34)))
	assert_false(grid.is_solid(Vector2i(41, 34)))
	# Chaque extrémité s'ouvre sur une salle (plus d'une case de large).
	assert_false(grid.is_solid(Vector2i(34, 33)) and grid.is_solid(Vector2i(34, 35)))


# --- Échelles et passages -------------------------------------------------------------------


func test_ladders_a_and_b_share_coordinates_and_pair_up() -> void:
	var expected := {"A": Vector2i(44, 2), "B": Vector2i(44, 34)}
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var map: GameMap = _maps[map_id]
		for pair: String in expected:
			var id := "echelle_%s" % pair.to_lower()
			assert_eq(plan.cell_of(id), expected[pair], "%s : échelle %s" % [map_id, pair])
			var warp := _warp_at(map, expected[pair])
			assert_not_null(warp, "%s : passage de l'échelle %s" % [map_id, pair])
			if warp == null:
				continue
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
			assert_eq(warp.direction, Vector2i.ZERO)
			var other_id: StringName = &"dark_cave_b1f" if map_id == &"dark_cave_1f" \
				else &"dark_cave_1f"
			assert_eq(warp.target_map, other_id)
			var other: GameMap = _maps[other_id]
			var arrival := other.get_spawn_cell(warp.target_spawn)
			assert_eq(arrival, (expected[pair] as Vector2i) + (Vector2i.DOWN if pair == "A"
				else Vector2i.LEFT), "%s : arrivée de l'échelle %s" % [map_id, pair])
			assert_false(other.get_grid().is_solid(arrival))
			assert_eq(warp.facing, arrival - expected[pair], "tourné à l'opposé de l'échelle")
			var back := _warp_at(other, expected[pair])
			assert_eq(back.target_map, map_id, "aller-retour %s" % pair)
			assert_eq(map.get_spawn_cell(back.target_spawn), arrival, "même arrivée au retour")


## Échelle B : l'arrivée (43, 34) est tournée ← (face au couloir libre, jamais vers la paroi) ;
## le commentaire de la grille du B1F (→) est corrigé en conséquence.
func test_ladder_b_arrival_faces_the_open_corridor() -> void:
	for map_id: StringName in _maps:
		var warp := _warp_at(_maps[map_id], Vector2i(44, 34))
		assert_eq(warp.facing, Vector2i.LEFT, String(map_id))


func test_north_entry_and_south_exit_go_to_route_10_or_are_coming_soon() -> void:
	var map: GameMap = _maps[&"dark_cave_1f"]
	var built := MapCatalog.has_map(&"route_10")
	for cell: Vector2i in NORTH_ENTRY + SOUTH_EXIT:
		var warp := _warp_at(map, cell)
		assert_not_null(warp, str(cell))
		if warp == null:
			continue
		var north := cell.y == 0
		assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
		assert_eq(warp.direction, Vector2i.UP if north else Vector2i.DOWN)
		var side := "w" if cell.x in [27, 8] else "e"
		if built:
			assert_false(warp.is_coming_soon(), "route_10 existe : relancer build_dark_cave.gd")
			assert_eq(warp.target_map, &"route_10")
			assert_eq(warp.target_spawn,
				StringName("from_dark_cave_%s_%s" % ["n" if north else "s", side]))
			assert_eq(warp.facing, Vector2i.DOWN)
		else:
			assert_true(warp.is_coming_soon(), "repli « Route 10 — À venir »")
			var spawn := StringName("from_route_10_%s_%s" % ["n" if north else "s", side])
			assert_eq(warp.target_spawn, spawn)
			assert_eq(map.get_spawn_cell(spawn), cell + (Vector2i.DOWN if north else Vector2i.UP))
	if not built:
		pending("route_10 pas encore construite (T12) : sorties en repli « à venir »")


# --- Graphe ---------------------------------------------------------------------------------


## Voisins d'un nœud [carte, case] : pas à pied et, si [param ladders], échelle sous les pieds.
func _neighbours(node: Array, ladders: bool) -> Array:
	var map: GameMap = _maps[node[0]]
	var grid := map.get_grid()
	var out: Array = []
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell: Vector2i = node[1] + step
		if grid.is_in_bounds(cell) and not grid.is_solid(cell):
			out.append([node[0], cell])
	if ladders:
		var warp := _warp_at(map, node[1])
		if warp != null and _maps.has(warp.target_map):
			out.append([warp.target_map, (_maps[warp.target_map] as GameMap).get_spawn_cell(
				warp.target_spawn)])
	return out


## Distances (pas) depuis [param starts] ; le graphe est celui des étages.
func _bfs(starts: Array, ladders: bool) -> Dictionary:
	var dist: Dictionary = {}
	var queue: Array = []
	for start: Array in starts:
		dist[start] = 0
		queue.append(start)
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		for next: Array in _neighbours(node, ladders):
			if not dist.has(next):
				dist[next] = dist[node] + 1
				queue.append(next)
	return dist


func _north_start() -> Array:
	var map: GameMap = _maps[&"dark_cave_1f"]
	return [&"dark_cave_1f", map.get_spawn_cell(&"from_route_10_n_w")]


func test_route_north_ladder_a_b1f_ladder_b_south_half_exit() -> void:
	var dist := _bfs([_north_start()], true)
	for key: Array in [[&"dark_cave_1f", Vector2i(44, 2)], [&"dark_cave_b1f", Vector2i(44, 3)],
			[&"dark_cave_b1f", Vector2i(44, 34)], [&"dark_cave_1f", Vector2i(43, 34)],
			[&"dark_cave_1f", Vector2i(8, 47)], [&"dark_cave_1f", Vector2i(9, 47)]]:
		assert_true(dist.has(key), "atteignable : %s" % [key])
	# Ordre du parcours : A avant B1F avant B avant la sortie sud.
	assert_lt(dist[[&"dark_cave_1f", Vector2i(44, 2)]], dist[[&"dark_cave_b1f", Vector2i(44, 34)]])
	assert_lt(dist[[&"dark_cave_b1f", Vector2i(44, 34)]], dist[[&"dark_cave_1f", Vector2i(8, 47)]])
	gut.p("entrée nord → sortie sud : %d pas" % dist[[&"dark_cave_1f", Vector2i(8, 47)]])


func test_1f_halves_are_not_connected_on_foot() -> void:
	var dist := _bfs([_north_start()], false)
	var map: GameMap = _maps[&"dark_cave_1f"]
	var grid := map.get_grid()
	var north: Array[Vector2i] = []
	var south: Array[Vector2i] = []
	for y: int in FLOORS[&"dark_cave_1f"][1].y:
		for x: int in FLOORS[&"dark_cave_1f"][1].x:
			var cell := Vector2i(x, y)
			if grid.is_solid(cell):
				continue
			if dist.has([&"dark_cave_1f", cell]):
				north.append(cell)
			else:
				south.append(cell)
	assert_gt(north.size(), 0)
	assert_gt(south.size(), 0)
	assert_true(north.has(Vector2i(44, 3)), "l'échelle A est dans la moitié nord")
	assert_true(south.has(Vector2i(43, 34)) and south.has(Vector2i(8, 47)), "moitié sud")
	assert_false(north.has(Vector2i(43, 34)))
	assert_false(dist.has([&"dark_cave_1f", Vector2i(8, 47)]))
	# Jamais visibles ensemble : rectangle de vue 2340 × 1080 et disque de 9 cases.
	var worst_dy := 999
	var worst_dist := 999.0
	var shared_view := 0
	for a: Vector2i in north:
		for b: Vector2i in south:
			var d := (a - b).abs()
			worst_dy = mini(worst_dy, d.y)
			worst_dist = minf(worst_dist, Vector2(a - b).length())
			if d.x <= VIEW_HALF_X and d.y <= VIEW_HALF_Y:
				shared_view += 1
	assert_eq(shared_view, 0, "paires de cases dans une même vue 2340 × 1080")
	assert_gt(worst_dist, SAFE_RADIUS, "disque de 9 cases")
	gut.p("écart vertical minimal entre les deux moitiés : %d cases" % worst_dy)


func test_every_walkable_cell_connects_back_to_the_north_entrance() -> void:
	var dist := _bfs([_north_start()], true)
	for map_id: StringName in _maps:
		var grid := (_maps[map_id] as GameMap).get_grid()
		var missing: Array[Vector2i] = []
		var size: Vector2i = FLOORS[map_id][1]
		for y: int in size.y:
			for x: int in size.x:
				var cell := Vector2i(x, y)
				if not grid.is_solid(cell) and not dist.has([map_id, cell]):
					missing.append(cell)
		assert_eq(missing, [] as Array[Vector2i], "%s : cases coupées de l'entrée nord" % map_id)


## Entre l'entrée nord et la sortie sud, le minimum de gravats franchis est 10 (les quatre bandes
## obligatoires : 3 + 2 au 1F, 2 + 3 au B1F).
func test_shortest_path_crosses_ten_rubble_cells() -> void:
	var goal := [&"dark_cave_1f", Vector2i(8, 47)]
	var start := _north_start()
	var parent: Dictionary = {start: start}
	var queue: Array = [start]
	var head := 0
	while head < queue.size():
		var current: Array = queue[head]
		head += 1
		for next: Array in _neighbours(current, true):
			if not parent.has(next):
				parent[next] = current
				queue.append(next)
	assert_true(parent.has(goal))
	var node: Array = goal
	var rubble := 0
	while node != start:
		if (_maps[node[0]] as GameMap).get_grid().is_rubble(node[1]):
			rubble += 1
		node = parent[node]
	if (_maps[start[0]] as GameMap).get_grid().is_rubble(start[1]):
		rubble += 1
	# Un plus court chemin en pas peut longer des gravats évitables au prix d'aucun pas de plus ;
	# le plan en compte 10 sur le chemin qui les évite (minimum ci-dessous).
	assert_gte(rubble, 10, "gravats sur un plus court chemin en pas")
	gut.p("plus court chemin en pas : %d gravats" % rubble)
	# Minimum possible : file à deux bouts (0-1 BFS, un gravat coûte 1).
	var cost: Dictionary = {start: 0}
	var open: Array = [start]
	var index := 0
	while index < open.size():
		var current: Array = open[index]
		index += 1
		for next: Array in _neighbours(current, true):
			var step := 1 if (_maps[next[0]] as GameMap).get_grid().is_rubble(next[1]) else 0
			if not cost.has(next) or cost[current] + step < cost[next]:
				cost[next] = cost[current] + step
				open.append(next)
	assert_eq(cost[goal], 10, "minimum de gravats entre l'entrée nord et la sortie sud")
