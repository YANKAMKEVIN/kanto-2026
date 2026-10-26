extends GutTest
## Carte viridian_forest (jalon 9 T19, docs/tech/jalon-09.md §2.7 ; dossier 10) : métadonnées et
## lumière, **grille de la scène = grille fonctionnelle** `tools/plans/viridian_forest.txt` case
## par case, passages et points d'apparition, critères du §2.7.1 (`tools/art/plan_check.py`)
## refaits par recherche de chemin sur la **vraie grille** de la scène (positions `bloque` de la
## grille en obstacles, comme plan_check), objets cachés sur l'herbe rase, PNJ aux cases de la
## grille, forêt dont le feuillage ne couvre aucune case praticable, objets peints sur les cases
## bloquées, budget de nœuds (≤ 3 000). Forêt agrandie du 2026-10-08 (§7) : 70 × 90, H3 et H5
## obligatoires, Théo et Milo inévitables (décision XL-1).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_PATH := "res://game/world/maps/viridian_forest.tscn"
const PLAN_PATH := "res://tools/plans/viridian_forest.txt"
const SIZE := Vector2i(70, 90)
const ENTRANCE: Array[Vector2i] = [Vector2i(44, 89), Vector2i(45, 89)]
const DOOR := Vector2i(28, 5)
const NODE_BUDGET := 3000
## Mesures de la grille (plan_check.py) : la scène doit les reproduire exactement.
const SHORTEST := 338
const PATH_RANGE := Vector2i(330, 360)
## Zones d'herbes obligatoires → cases traversées au moins (H3 6–8, H5 « courte » 4–6).
const MANDATORY: Dictionary = {"H3": 7, "H5": 5}
const ZONE_NAMES: Array[String] = ["H1", "H2", "H3", "H4", "H5"]
## Dresseurs inévitables : Théo (D1) et Milo (D4, décision XL-1 du 2026-10-08).
const UNAVOIDABLE: Array[String] = ["scout_theo", "scout_milo"]
const O1_MAX := 25
const O6_MAX := 15
const D1_FIRST_SEEN := 3
const INF := 1 << 30
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (obstacles de plan_check).
var _terrain: GridWorld
## Zones d'herbes, cases → vrai ; nommées H1..H5 par les positions `herbes` de la grille.
var _zones: Array[Dictionary] = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = _relief(_grid)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)
	_zones = _grass_zones()


func after_all() -> void:
	_map.free()


func _relief(source: GridWorld) -> GridWorld:
	var grid := GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if source.is_solid(cell):
				grid.set_solid(cell)
			if source.is_tall_grass(cell):
				grid.set_tall_grass(cell)
	return grid


func _without(cells: Dictionary) -> GridWorld:
	var grid := _relief(_terrain)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


## Zones d'herbes connexes, triées du sud au nord (H1 au sud).
func _grass_zones() -> Array[Dictionary]:
	var left: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		left[cell] = true
	var zones: Array[Dictionary] = []
	while not left.is_empty():
		var seed_cell: Vector2i = left.keys()[0]
		left.erase(seed_cell)
		var zone := {seed_cell: true}
		var stack: Array[Vector2i] = [seed_cell]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for direction: Vector2i in DIRECTIONS:
				if left.has(cell + direction):
					left.erase(cell + direction)
					zone[cell + direction] = true
					stack.append(cell + direction)
		zones.append(zone)
	zones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _mean_y(a) > _mean_y(b))
	return zones


## Zone d'herbes nommée [param zone_name] (H1..H5) : celle de la position `herbes_hN`.
func _zone(zone_name: String) -> Dictionary:
	var marker := _plan.cell_of("herbes_" + zone_name.to_lower())
	for zone: Dictionary in _zones:
		if zone.has(marker):
			return zone
	return {}


func _all_grass() -> Dictionary:
	var all_grass: Dictionary = {}
	for zone: Dictionary in _zones:
		all_grass.merge(zone)
	return all_grass


func _mean_y(zone: Dictionary) -> float:
	var total := 0.0
	for cell: Vector2i in zone:
		total += cell.y
	return total / zone.size()


func _distances(grid: GridWorld, starts: Array) -> Dictionary:
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	for start: Vector2i in starts:
		dist[start] = 0
		queue.append(start)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction: Vector2i in DIRECTIONS:
			var next := grid.get_step_target(cell, direction)
			if next != cell and not dist.has(next):
				dist[next] = int(dist[cell]) + 1
				queue.append(next)
	return dist


func _distance(grid: GridWorld, from: Array, to: Vector2i) -> int:
	return int(_distances(grid, from).get(to, INF))


func _min_crossed(grid: GridWorld, starts: Array, goal: Vector2i, counted: Dictionary) -> int:
	var cost: Dictionary = {}
	var deque: Array[Vector2i] = []
	for start: Vector2i in starts:
		cost[start] = 0
		deque.append(start)
	while not deque.is_empty():
		var cell: Vector2i = deque.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := grid.get_step_target(cell, direction)
			if next == cell:
				continue
			var k := int(cost[cell]) + (1 if counted.has(next) else 0)
			if k < int(cost.get(next, INF)):
				cost[next] = k
				if k > int(cost[cell]):
					deque.append(next)
				else:
					deque.push_front(next)
	return int(cost.get(goal, INF))


## Ligne de vue d'un Dresseur de la grille (TrainerRules : s'arrête au premier obstacle).
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


func _as_set(cells: Array[Vector2i]) -> Dictionary:
	var result: Dictionary = {}
	for cell: Vector2i in cells:
		result[cell] = true
	return result


## Cases d'où l'on prend un objet : la sienne (caché) ou ses voisines praticables (visible).
func _access(id: String) -> Array[Vector2i]:
	var cell := _plan.cell_of(id)
	var cells: Array[Vector2i] = []
	if not _plan.positions[id]["blocks"]:
		cells.append(cell)
		return cells
	for direction: Vector2i in DIRECTIONS:
		if not _terrain.is_solid(cell + direction) and _grid.is_in_bounds(cell + direction):
			cells.append(cell + direction)
	return cells


func _nearest(dist: Dictionary, cells: Array[Vector2i]) -> int:
	var best := INF
	for cell: Vector2i in cells:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func _prop_id(node: Node) -> String:
	return node.scene_file_path.get_file().get_basename()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"viridian_forest")
	assert_eq(_map.display_name, "Forêt de Jade")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"forest", "profil de la forêt (T18)")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"viridian_forest"), &"viridian_forest")
	assert_eq(_map.region, zones.get_zone(&"viridian_forest").subtitle)
	assert_eq(_map.region, "Jadielle — Argenta")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_true(lighting.has_profile(&"forest"))
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	var floor_node := _map.get_node_or_null(^"ForestFloor") as ForestFloor
	assert_not_null(ground, "sol peint")
	assert_not_null(floor_node, "sous-bois")
	if ground == null or floor_node == null:
		return
	var mask := ground.mask.get_image()
	assert_eq(Vector2i(mask.get_size()), SIZE, "1 pixel = 1 case")
	assert_eq(GroundMask.kind_at(mask, Vector2i(44, 85)), GroundMask.Kind.PATH, "sentier")
	assert_eq(GroundMask.kind_at(mask, Vector2i(38, 82)), GroundMask.Kind.GRASS, "clairière C1")
	assert_true(floor_node.is_forest(Vector2i(10, 85)), "sous-bois plein sous la forêt")
	assert_false(floor_node.is_forest(Vector2i(38, 82)), "pas de sous-bois dans C1")
	var strip := floor_node.mask.get_image().get_pixelv(Vector2i(13, 23)).r
	assert_almost_eq(strip, 0.5, 0.01, "bande de sous-bois « . » partielle (taches)")
	_check_light_layers(ground, floor_node)
	assert_not_null(_map.grass_front, "cache-jambes peint")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			# Le sac posé de la randonneuse (décor « bloque » de la grille) est un objet solide.
			var solid := not _plan.is_walkable(cell) or cell == _plan.cell_of("hiker_bag")
			var ok := _grid.is_solid(cell) == solid \
				and _grid.is_tall_grass(cell) == (mark == "h")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/viridian_forest.txt")
	assert_eq(_zones.size(), 5, "cinq zones d'herbes H1..H5")
	for zone_name: String in ZONE_NAMES:
		assert_false(_zone(zone_name).is_empty(), "zone %s nommée par la grille" % zone_name)


# --- Passages ----------------------------------------------------------------------------

func test_south_exit_and_north_door_lead_to_the_gates() -> void:
	var entrance: Array[Vector2i] = []
	for x: int in SIZE.x:
		if not _grid.is_solid(Vector2i(x, SIZE.y - 1)):
			entrance.append(Vector2i(x, SIZE.y - 1))
	assert_eq(entrance, ENTRANCE, "sortie sud = 2 cases (44..45, 89)")
	for cell: Vector2i in ENTRANCE:
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie sud %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"viridian_forest_gate_south", &"from_forest", Vector2i.DOWN])
	assert_eq(_map.get_spawn_cell(&"from_gate_south"), Vector2i(44, 89))
	var door := _map.get_warps().find_on_step(DOOR, Vector2i.UP)
	assert_not_null(door, "porte du poste nord, STEP_ON ↑")
	if door != null:
		assert_eq([door.target_map, door.target_spawn, door.facing],
			[&"viridian_forest_gate_north", &"from_forest", Vector2i.UP])
	assert_eq(_map.get_spawn_cell(&"from_gate_north"), Vector2i(28, 6))
	assert_false(_grid.is_solid(DOOR), "la porte s'ouvre dans l'emprise du poste")
	var gate := _map.get_entities().get_node_or_null(^"ForestGate") as WorldProp
	assert_not_null(gate, "façade du poste nord")
	if gate != null:
		assert_eq(_prop_id(gate), "bldg_poste_foret_01")
		assert_eq(gate.get_solid_cells().size(), _plan.cells_of("P").size())
	# Bords fermés : seule la sortie sud touche le bord.
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var edge := x == 0 or y == 0 or x == SIZE.x - 1 or y == SIZE.y - 1
			if edge and not _grid.is_solid(cell):
				assert_has(ENTRANCE, cell, "seule la sortie sud touche le bord")


## Clôture du J9 (T23) : le point d'apparition des départs `trainers_qa` / `trainers_weak_qa`
## (ex-couloir de la carte de QA) est sur le sentier, hors de toute vue, et quatre pas vers
## l'ouest entrent dans la vue de Théo (au quatrième, pas avant).
func test_before_theo_spawn_is_four_steps_from_his_sight() -> void:
	var cell := _map.get_spawn_cell(&"before_theo")
	assert_eq(cell, _plan.cell_of("before_theo"), "position de la grille")
	assert_true(_grid.is_free(cell), "case libre")
	var theo := _map.get_npc(&"scout_theo").get_spec()
	var sight := func(at: Vector2i) -> int:
		return TrainerRules.sight_distance(_grid, theo.cell, theo.facing, theo.sight, at)
	for step: int in range(4):
		var at := cell + Vector2i.LEFT * step
		assert_false(_grid.is_solid(at), "sentier en %s" % at)
		assert_lt(sight.call(at), 1, "hors de la vue de Théo en %s" % at)
	assert_gt(sight.call(cell + Vector2i.LEFT * 4), 0, "vu au quatrième pas")
	for npc: Npc in _map.get_npcs():
		var spec := npc.get_spec()
		if spec.is_trainer() and spec.id != &"scout_theo":
			assert_lt(TrainerRules.sight_distance(_grid, spec.cell, spec.facing, spec.sight,
				cell), 1, "hors de la vue de %s" % spec.id)


# --- Critères du §2.7.1 sur la vraie grille ------------------------------------------------

func test_main_path_length_and_width() -> void:
	var steps := _distance(_terrain, ENTRANCE, DOOR)
	assert_eq(steps, SHORTEST, "chemin principal (grille : 338 pas)")
	assert_between(steps, PATH_RANGE.x, PATH_RANGE.y, "forêt agrandie (2026-10-08)")
	# Avec les PNJ réels en place, la porte reste atteignable.
	assert_lt(_distance(_grid, ENTRANCE, DOOR), INF, "porte atteignable avec les PNJ")


func test_mandatory_grass_is_in_h3_and_h5_only() -> void:
	var all_grass := _all_grass()
	var total := 0
	var required: Dictionary = {}
	for zone_name: String in MANDATORY:
		var zone := _zone(zone_name)
		required.merge(zone)
		total += int(MANDATORY[zone_name])
		assert_eq(_min_crossed(_terrain, ENTRANCE, DOOR, zone), MANDATORY[zone_name],
			"%s : cases traversées au moins" % zone_name)
		assert_eq(_distance(_without(zone), ENTRANCE, DOOR), INF, "%s incontournable" % zone_name)
	assert_eq(_min_crossed(_terrain, ENTRANCE, DOOR, all_grass), total, "herbes obligatoires")
	var others := all_grass.duplicate()
	for cell: Vector2i in required:
		others.erase(cell)
	assert_eq(_min_crossed(_terrain, ENTRANCE, DOOR, others), 0,
		"hors H3 et H5 : aucune obligatoire")
	for zone_name: String in ["H1", "H2", "H4"]:
		assert_eq(_distance(_without(_zone(zone_name)), ENTRANCE, DOOR), SHORTEST,
			"%s évitable sans détour" % zone_name)


func test_trainers_sight_lines() -> void:
	for id: String in UNAVOIDABLE:
		var sight := _sight(id)
		assert_eq(sight.size(), int(_plan.attr(id, "sight")), "%s : vue dégagée" % id)
		assert_eq(_distance(_without(_as_set(sight)), ENTRANCE, DOOR), INF, "%s inévitable" % id)
		var on_path := 0
		for cell: Vector2i in sight:
			if _plan.at(cell) == "=":
				on_path += 1
		assert_eq(on_path, 2, "%s : toute la largeur du sentier" % id)
		# Première case vue en venant du sud : au moins 2 cases libres entre eux.
		var dist := _distances(_without(_as_set(sight.slice(0, D1_FIRST_SEEN - 1))), ENTRANCE)
		var reached := false
		for i: int in range(D1_FIRST_SEEN - 1, sight.size()):
			reached = reached or dist.has(sight[i])
		assert_true(reached, "%s voit d'abord le joueur à %d cases ou plus" % [id,
			D1_FIRST_SEEN])
	assert_eq(_sight("scout_theo").size(), 4, "Théo voit 4 cases")
	assert_eq(_sight("scout_milo").size(), 5, "Milo voit 5 cases")
	for id: String in ["scout_noe", "youngster_tom", "scout_eli"]:
		assert_lt(_distance(_without(_as_set(_sight(id))), ENTRANCE, DOOR), INF,
			"%s évitable" % id)


# --- Dresseurs sur la vraie scène, avec tous les PNJ (T21) --------------------------------

## Relief de la scène + cases des PNJ, objets et Pokémon d'ambiance posés (occupation réelle),
## plus [param extra] : le monde tel que le joueur le trouve (routines tenues sur leur case).
func _real_world(extra: Dictionary = {}) -> GridWorld:
	var grid := _relief(_grid)
	for npc: Npc in _map.get_npcs():
		grid.set_solid(npc.get_cell())
	for cell: Vector2i in extra:
		grid.set_solid(cell)
	return grid


func _trainers() -> Array[NpcSpec]:
	var trainers: Array[NpcSpec] = []
	for spec: NpcSpec in NpcRoster.load_for_map(&"viridian_forest").get_all():
		if spec.is_trainer():
			trainers.append(spec)
	return trainers


## Cases où le joueur est vu par [param spec], par [method TrainerRules.sight_distance] sur la
## **vraie grille** (les autres personnages coupent la vue, comme en jeu).
func _real_sight(spec: NpcSpec) -> Dictionary:
	var seen: Dictionary = {}
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _grid.is_solid(cell) or _grid.is_occupied(cell):
				continue
			if TrainerRules.sight_distance(_grid, spec.cell, spec.facing, spec.sight, cell) > 0:
				seen[cell] = true
	return seen


func test_real_scene_sight_matches_the_grid_and_the_npcs_stay_off_it() -> void:
	var trainers := _trainers()
	assert_eq(trainers.size(), 5, "cinq Dresseurs")
	for spec: NpcSpec in trainers:
		var real := _real_sight(spec)
		var planned := _as_set(_sight(String(spec.id)))
		for cell: Vector2i in planned:
			assert_true(real.has(cell), "%s voit %s (grille)" % [spec.id, cell])
		for cell: Vector2i in real:
			assert_true(planned.has(cell), "%s ne devrait pas voir %s" % [spec.id, cell])
		assert_gt(real.size(), 0, "%s voit au moins une case" % spec.id)
		# Aucun autre personnage, Pokémon d'ambiance ni objet sur sa ligne de vue.
		for npc: Npc in _map.get_npcs():
			assert_false(real.has(npc.get_cell()), "%s sur la vue de %s" % [npc.get_id(),
				spec.id])
			for cell: Vector2i in npc.get_spec().route_cells:
				assert_false(real.has(cell), "routine de %s sur la vue de %s" % [npc.get_id(),
					spec.id])


func test_real_scene_trainer_avoidance_with_the_npcs() -> void:
	var seen: Dictionary = {}
	for spec: NpcSpec in _trainers():
		seen[String(spec.id)] = _real_sight(spec)
	var door_open := func(blocked: Dictionary) -> bool:
		return _distance(_real_world(blocked), ENTRANCE, DOOR) < INF
	assert_true(door_open.call({}), "la porte est atteignable avec tous les PNJ")
	assert_false(door_open.call(seen["scout_theo"]), "Théo (D1) est inévitable")
	assert_false(door_open.call(seen["scout_milo"]),
		"Milo (D4) est inévitable, même par les hautes herbes (XL-1)")
	for id: String in ["scout_noe", "youngster_tom", "scout_eli"]:
		assert_true(door_open.call(seen[id]), "%s (D2, D3, D5) est évitable" % id)


func test_trainers_never_close_a_passage_where_they_stop() -> void:
	# Le Dresseur qui s'est approché reste à la case d'arrêt (jusqu'au rechargement) : la porte
	# reste atteignable pour chaque distance de détection possible (hors Dresseur sur sa case).
	for spec: NpcSpec in _trainers():
		var real := _real_sight(spec)
		for distance: int in range(1, spec.sight + 1):
			var stop := spec.cell + spec.facing * (distance - 1)
			var world := _real_world()
			world.set_solid(stop, true)
			world.set_solid(spec.cell, false)
			if _grid.is_solid(stop):
				continue
			# Le Dresseur n'a bougé que s'il a vu le joueur : cases d'arrêt sur sa vue.
			if distance > 1 and not real.has(stop + spec.facing):
				continue
			assert_lt(_distance(world, ENTRANCE, DOOR), INF, "%s arrêté en %s ferme la forêt"
				% [spec.id, stop])


func test_npc_routines_stay_off_grass_and_off_the_main_passage() -> void:
	for id: StringName in [&"naturalist", &"hiker"]:
		var npc := _map.get_npc(id)
		assert_not_null(npc, "%s posé" % id)
		var route := npc.get_spec().route_cells
		assert_gt(route.size(), 2, "%s a une boucle" % id)
		for cell: Vector2i in route:
			assert_false(_grid.is_solid(cell) and not _grid.is_occupied(cell),
				"%s : %s praticable" % [id, cell])
			assert_false(_grid.is_tall_grass(cell), "%s : %s hors des hautes herbes" % [id, cell])
			var world := _real_world()
			world.set_solid(npc.get_cell(), false)
			world.set_solid(cell, true)
			assert_lt(_distance(world, ENTRANCE, DOOR), INF,
				"%s en %s : la porte reste atteignable" % [id, cell])


func test_objects_are_reachable_and_placed_as_the_grid_says() -> void:
	var from_south := _distances(_terrain, ENTRANCE)
	var from_door := _distances(_terrain, [DOOR])
	for i: int in range(1, 7):
		var id := "viridian_forest_item_%d" % i
		assert_lt(_nearest(from_south, _access(id)), INF, "%s atteignable" % id)
	assert_lt(_nearest(from_south, _access("viridian_forest_item_1")), O1_MAX, "O1 près")
	assert_lt(_nearest(from_door, _access("viridian_forest_item_6")), O6_MAX, "O6 près")
	var h2_blocked := _distances(_without(_zone("H2")), ENTRANCE)
	assert_eq(_nearest(h2_blocked, _access("viridian_forest_item_2")), INF, "O2 derrière H2")


func test_hidden_items_on_short_grass() -> void:
	var expected := {}
	for i: int in [3, 4, 6]:
		var id := "viridian_forest_item_%d" % i
		expected[StringName(id)] = _plan.cell_of(id)
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Triggers").get_children():
		var trigger := point as EventTriggerPoint
		found[trigger.cutscene_id] = trigger.get_cell()
		assert_eq(trigger.size, Vector2i.ONE)
		assert_eq(trigger.direction, Vector2i.ZERO)
	assert_eq(found, expected)
	for id: StringName in expected:
		var cell: Vector2i = expected[id]
		assert_true(".C".contains(_plan.at(cell)), "%s sur l'herbe rase" % id)
		assert_false(_grid.is_tall_grass(cell))


func test_npcs_are_at_their_grid_cells() -> void:
	var roster := NpcRoster.load_for_map(&"viridian_forest")
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	for spec: NpcSpec in roster.get_all():
		assert_has(_plan.cells_at(String(spec.id)), spec.cell, "%s : case de la grille" % spec.id)
		if GameMap.awaits_painted_look(spec):
			assert_null(_map.get_npc(spec.id), "%s : sans planche, sauté" % spec.id)
			continue
		assert_not_null(_map.get_npc(spec.id), "%s posé sur la carte" % spec.id)
	for id: StringName in [&"scout_theo", &"scout_noe", &"youngster_tom", &"scout_milo",
			&"scout_eli"]:
		var npc := _map.get_npc(id)
		assert_not_null(npc, "Dresseur %s posé" % id)


# --- Image -------------------------------------------------------------------------------

func _forest_sprites() -> Array[Node2D]:
	var trees: Array[Node2D] = []
	for child: Node in _map.get_entities().get_children():
		if child is Sprite2D and String(child.name).begins_with("Forest"):
			trees.append(child as Node2D)
	return trees


func test_forest_canopy_never_covers_a_walkable_cell() -> void:
	var trees := _forest_sprites()
	assert_gt(trees.size(), 800, "forêt serrée")
	for tree: Node2D in trees:
		if String(tree.name).begins_with("ForestBush"):
			continue  # garnissage (ForestBush…) : contrôlé plus bas
		var foot := tree.position / float(Grid.TILE_SIZE)
		for cell: Vector2i in DenseForest.canopy_cells(foot):
			if not _grid.is_in_bounds(cell):
				continue
			assert_eq(_plan.at(cell), "T", "%s : %s est de la forêt" % [tree.name, cell])


func test_undergrowth_shrubs_barely_reach_walkable_cells() -> void:
	# Jeunes arbres du garnissage (ForestBush…) : pied sur la forêt ; la cime déborde d'au plus
	# 0,35 case sur une case praticable au-dessus (règle de build_route_2.gd), sauf à l'échelle
	# plancher (0,4), où elle déborde d'au plus une demi-case.
	var shrubs := 0
	for tree: Node2D in _forest_sprites():
		if not String(tree.name).begins_with("ForestBush"):
			continue
		shrubs += 1
		var sprite := tree as Sprite2D
		var foot := tree.position / float(Grid.TILE_SIZE)
		var top := foot.y - sprite.texture.get_height() * tree.scale.y / Grid.TILE_SIZE
		var cell := Vector2i(floori(foot.x), floori(foot.y - 0.05))
		assert_eq(_plan.at(cell), "T", "%s : pied sur la forêt" % tree.name)
		var allowed := 0.5 if tree.scale.y < 0.41 else 0.36
		for y: int in range(floori(top), cell.y):
			if _plan.is_walkable(Vector2i(cell.x, y)):
				assert_gt(top, y + 1.0 - allowed, "%s : cime sur (%d, %d)" % [tree.name,
					cell.x, y])
	assert_gt(shrubs, 100, "le garnissage est fait de jeunes arbres")


func test_forest_is_darker_and_colder_than_neutral() -> void:
	var sum := Color(0, 0, 0)
	var trees := _forest_sprites()
	for tree: Node2D in trees:
		sum += tree.modulate
	sum /= float(trees.size())
	assert_lt(sum.g, 0.85, "forêt plus sombre que la Route 2 au sud")
	assert_lt(sum.r, sum.b, "et plus froide (bleu-vert)")


func test_painted_props_sit_on_blocked_cells_of_the_grid() -> void:
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if not child is WorldProp:
				continue
			if child.name == &"HikerBag":
				continue  # décor « bloque » posé sur la clairière (vérifié plus bas)
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				assert_false(_plan.is_walkable(cell), "%s sur %s praticable" % [child.name, cell])
	var marks := {"ForestGate": "P", "LeaningTrunk": "I", "BigStump": "S", "Roots": "r",
		"StumpForecourt": "s", "StumpHiker": "s"}
	for node_name: String in marks:
		var prop := _map.get_entities().get_node_or_null(NodePath(node_name)) as WorldProp
		assert_not_null(prop, node_name)
		if prop == null:
			continue
		var cells := prop.get_solid_cells()
		assert_eq(cells.size(), _plan.cells_of(marks[node_name]).size() if node_name in
			["ForestGate", "LeaningTrunk", "BigStump", "Roots"] else 1, node_name)
		for cell: Vector2i in cells:
			assert_eq(_plan.at(cell), marks[node_name], "%s sur « %s »" % [node_name,
				marks[node_name]])
	var bag := _map.get_entities().get_node_or_null(^"HikerBag") as WorldProp
	assert_not_null(bag, "sac de la randonneuse")
	if bag != null:
		assert_eq(bag.get_solid_cells(), [_plan.cell_of("hiker_bag")] as Array[Vector2i])


func test_one_big_stump_and_two_tufts_per_grass_cell() -> void:
	var stumps := 0
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp and _prop_id(child) == "prop_grande_souche_01":
			stumps += 1
	assert_eq(stumps, 1, "une seule grande souche (vue validée)")
	var counts: Dictionary = {}
	for child: Node in _map.get_entities().get_children():
		if child is Sprite2D and String(child.name).begins_with("Tuft"):
			var cell := Grid.world_to_cell((child as Node2D).position - Vector2(0, 1))
			counts[cell] = int(counts.get(cell, 0)) + 1
	for cell: Vector2i in _plan.cells_of("h"):
		assert_eq(counts.get(cell, 0), 2, "deux touffes en %s" % cell)


func test_node_budget() -> void:
	var map := (load(MAP_PATH) as PackedScene).instantiate()
	var total := _count(map)
	map.free()
	assert_lte(total, NODE_BUDGET, "nœuds de la scène")
	gut.p("viridian_forest : %d nœuds" % total)


## DAF.6 (reporté du J9 : « assombrir nettement la forêt hors des clairières ») : ombre de
## canopée sur la forêt et les bandes « . », en taches sur le sentier ; lumière chaude des
## clairières `C` / `L` seules ; deux [ForestFloor] translucides cuits avec le sol.
func _check_light_layers(ground: PaintedGround, floor_node: ForestFloor) -> void:
	var shade := _map.get_node_or_null(^"CanopyShade") as ForestFloor
	var light := _map.get_node_or_null(^"ClearingLight") as ForestFloor
	assert_not_null(shade, "ombre de canopée")
	assert_not_null(light, "lumière des clairières")
	if shade == null or light == null:
		return
	assert_eq(shade.get_index(), floor_node.get_index() + 1, "juste après le sous-bois")
	assert_eq(light.get_index(), shade.get_index() + 1)
	assert_eq(ground.forest_layers(), [floor_node, shade, light] as Array[CanvasItem],
		"cuits avec le sol : aucun coût par image")
	var shade_mask := shade.mask.get_image()
	var light_mask := light.mask.get_image()
	var strip := Vector2i(13, 23)
	var clearing := Vector2i(38, 82)
	var path := Vector2i(44, 85)
	assert_eq(_plan.at(strip), ".")
	assert_eq(_plan.at(clearing), "C")
	assert_eq(_plan.at(path), "=")
	assert_almost_eq(shade_mask.get_pixelv(strip).r, 1.0, 0.01, "bande « . » à l'ombre")
	assert_almost_eq(shade_mask.get_pixelv(clearing).r, 0.0, 0.01, "clairière éclairée")
	var dappled := shade_mask.get_pixelv(path).r
	assert_true(dappled > 0.1 and dappled < 0.9, "sentier en lumière tamisée : %s" % dappled)
	assert_almost_eq(light_mask.get_pixelv(clearing).r, 1.0, 0.01, "lumière dans la trouée")
	assert_almost_eq(light_mask.get_pixelv(strip).r, 0.0, 0.01, "aucune hors des trouées")
	for layer: ForestFloor in [shade, light]:
		var opacity := float(layer.get_shader_material().get_shader_parameter(&"opacity"))
		assert_true(opacity > 0.0 and opacity < 1.0, "%s translucide" % layer.name)
	var dark := shade.get_shader_material().get_shader_parameter(&"dark_color") as Color
	assert_true(dark.b >= dark.r and dark.get_luminance() < 0.15, "ombre bleu-vert sombre")
	var warm := light.get_shader_material().get_shader_parameter(&"dark_color") as Color
	assert_true(warm.r > warm.b, "lumière chaude")
