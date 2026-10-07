extends GutTest
## Carte route_2 (jalon 8 T5, docs/tech/jalon-08.md §1.1, §2 ; dossier 11) : métadonnées et
## lumière, **grille de la scène = grille fonctionnelle** `tools/plans/route_2.txt` case par case,
## raccord avec Jadielle, porte du poste « à venir », points d'examen, objets cachés sur l'herbe
## rase, critères du T0 (`tools/art/plan_check.py`) refaits par recherche de chemin sur la
## **vraie grille** de la scène, forêt serrée dont le feuillage ne couvre aucune case praticable,
## objets peints posés sur les cases bloquées de la grille, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_PATH := "res://game/world/maps/route_2.tscn"
const PLAN_PATH := "res://tools/plans/route_2.txt"
const SIZE := Vector2i(42, 60)
const SOUTH := [Vector2i(19, 59), Vector2i(20, 59), Vector2i(21, 59)]
const GATE := Vector2i(20, 8)
const GATE_FRONT := Vector2i(20, 9)
const NODE_BUDGET := 3000
## Mesures du T0 (plan_check.py) : la scène doit les reproduire exactement.
const SHORTEST := 88
const SAFE_PATH := 98
const MANDATORY_GRASS := 6
const H2_ACROSS := 19
const H2_AROUND := 29
const BACK_WITH_LEDGE := 78
const BACK_WITHOUT_LEDGE := 89
const LEDGE_LOCAL := 12
const LEDGE_LOCAL_WITHOUT := 21
const INF := 1 << 30
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Points d'examen : [nœud, case, orientation exigée, dialogue].
const EXAMINE: Array = [
	["SignRoute", Vector2i(22, 56), Vector2i.UP, &"route_2_sign"],
	["SignForest", Vector2i(23, 9), Vector2i.UP, &"route_2_forest_sign"],
	["DenseTree", Vector2i(4, 19), Vector2i.LEFT, &"route_2_dense_tree"],
	["SignClosed", Vector2i(33, 42), Vector2i.UP, &"route_2_closed_sign"],
	["ClosedGate", Vector2i(34, 44), Vector2i.RIGHT, &"route_2_closed_gate"],
	["ClosedGate", Vector2i(34, 43), Vector2i.RIGHT, &"route_2_closed_gate"],
]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul (sans PNJ), plus les positions `bloque` de la grille (obstacles de plan_check).
var _terrain: GridWorld
var _h1: Dictionary = {}
var _h2: Dictionary = {}
var _h3: Dictionary = {}


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = _relief(_grid)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)
	for cell: Vector2i in _plan.cells_of("h"):
		if cell.y > 50:
			_h1[cell] = true
		elif cell.y > 20:
			_h2[cell] = true
		else:
			_h3[cell] = true


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
			grid.set_ledge(cell, source.get_ledge(cell))
	return grid


## Copie de [member _terrain] avec [param cells] bloquées en plus.
func _without(cells: Dictionary) -> GridWorld:
	var grid := _relief(_terrain)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


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


## Nombre minimal de cases de [param counted] traversées de [param starts] à [param goal]
## (0-1 BFS, comme plan_check.py).
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


func _prop_id(node: Node) -> String:
	return node.scene_file_path.get_file().get_basename()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_2")
	assert_eq(_map.display_name, "Route 2")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_eq(_map.music, &"", "musique : intention seulement (dossier 11)")
	assert_false(_map.interior)
	assert_true(_map.level_rows.is_empty())
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"route_2"), &"route_2")
	assert_eq(_map.region, zones.get_zone(&"route_2").subtitle, "sous-titre = celui de la zone")
	assert_eq(_map.region, "Jadielle — Forêt de Jade")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	var floor_node := _map.get_node_or_null(^"ForestFloor") as ForestFloor
	assert_not_null(ground, "sol peint")
	assert_not_null(floor_node, "sous-bois")
	if ground == null or floor_node == null:
		return
	assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	var mask := ground.mask.get_image()
	assert_eq(GroundMask.kind_at(mask, Vector2i(20, 50)), GroundMask.Kind.PATH)
	assert_eq(GroundMask.kind_at(mask, Vector2i(20, 59)), GroundMask.Kind.PAVING,
		"pavés déchaussés de la rue nord de Jadielle")
	assert_eq(GroundMask.kind_at(mask, Vector2i(2, 19)), GroundMask.Kind.PATH, "sentier A peint")
	assert_eq(GroundMask.kind_at(mask, Vector2i(38, 43)), GroundMask.Kind.PATH, "sentier B peint")
	assert_not_null(_map.grass_front, "cache-jambes peint")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var ok := _grid.is_solid(cell) == not _plan.is_walkable(cell) \
				and _grid.is_tall_grass(cell) == (mark == "h") \
				and (_grid.get_ledge(cell) == GridWorld.Ledge.DOWN) == (mark == "v")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s, rebord %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell), _grid.get_ledge(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_2.txt")


# --- Passages ----------------------------------------------------------------------------

func test_south_exit_leads_back_to_viridian() -> void:
	var sides := ["w", "c", "e"]
	var entrance: Array[Vector2i] = []
	for x: int in SIZE.x:
		if not _grid.is_solid(Vector2i(x, SIZE.y - 1)):
			entrance.append(Vector2i(x, SIZE.y - 1))
	assert_eq(entrance, SOUTH as Array[Vector2i], "entrée sud = 3 cases en x 19–21")
	for i: int in SOUTH.size():
		var cell: Vector2i = SOUTH[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie sud %s" % cell)
		if warp != null:
			assert_eq(warp.target_map, &"viridian_city")
			assert_eq(warp.target_spawn, StringName("from_route_2_" + sides[i]))
			assert_eq(warp.facing, Vector2i.DOWN)
		assert_eq(_map.get_spawn_cell(StringName("from_viridian_" + sides[i])), cell)
	var viridian := (load(MapCatalog.scene_path(&"viridian_city")) as PackedScene) \
		.instantiate() as GameMap
	for i: int in SOUTH.size():
		assert_true(viridian.has_spawn(StringName("from_route_2_" + sides[i])))
	viridian.free()


func test_the_gate_door_is_coming_soon() -> void:
	var door := _map.get_warps().find_on_step(GATE, Vector2i.UP)
	assert_not_null(door, "porte du poste, STEP_ON ↑")
	if door == null:
		return
	assert_eq(door.trigger, Warp.Trigger.STEP_ON)
	assert_true(door.is_coming_soon())
	assert_eq(door.coming_soon, "Forêt de Jade")
	assert_eq(door.coming_soon.to_upper(), "FORÊT DE JADE", "majuscules, « Ê » compris")
	assert_eq(door.target_spawn, &"from_forest_gate")
	assert_eq(door.facing, Vector2i.DOWN)
	assert_eq(_map.get_spawn_cell(&"from_forest_gate"), GATE_FRONT)
	assert_false(_grid.is_solid(GATE), "la porte s'ouvre dans l'emprise du poste")
	var gate := _map.get_entities().get_node_or_null(^"ForestGate") as WorldProp
	assert_not_null(gate, "façade du poste")
	if gate != null:
		assert_eq(_prop_id(gate), "bldg_poste_foret_01")
		for cell: Vector2i in gate.get_solid_cells():
			assert_eq(_plan.at(cell), "P", "emprise du poste sur « P » : %s" % cell)
		assert_eq(gate.get_solid_cells().size(), _plan.cells_of("P").size())


# --- Critères du T0 sur la vraie grille ---------------------------------------------------

func test_the_gate_is_reachable_with_the_t0_distances() -> void:
	assert_eq(_distance(_terrain, SOUTH, GATE), SHORTEST, "trajet le plus court")
	var safe := _without(_h1.merged(_h2))
	assert_eq(_distance(safe, SOUTH, GATE), SAFE_PATH, "chemin sûr (sans H1 ni H2)")
	# Avec les PNJ et les objets réels à leur place, la porte reste atteignable.
	assert_lt(_distance(_grid, SOUTH, GATE), INF, "porte atteignable avec les PNJ en place")


func test_mandatory_grass_is_six_cells_all_in_h3() -> void:
	var all_grass := _h1.merged(_h2).merged(_h3)
	assert_eq(_min_crossed(_terrain, SOUTH, GATE, all_grass), MANDATORY_GRASS)
	assert_eq(_min_crossed(_terrain, SOUTH, GATE, _h1.merged(_h2)), 0, "H1 et H2 évitables")
	assert_eq(_distance(_without(_h3), SOUTH, GATE), INF, "H3 incontournable")
	assert_lt(_distance(_without(_h1), SOUTH, GATE), INF, "H1 évitable")
	assert_lt(_distance(_without(_h2), SOUTH, GATE), INF, "H2 évitable")


func test_h2_is_shorter_than_the_safe_path() -> void:
	var from := _plan.cell_of("h2_sud")
	var to := _plan.cell_of("h2_nord")
	assert_eq(_distance(_terrain, [from], to), H2_ACROSS, "traversée de H2")
	assert_eq(_distance(_without(_h2), [from], to), H2_AROUND, "chemin sûr")


func test_the_ledge_is_a_one_way_shortcut() -> void:
	var ledges := _plan.cells_of("v")
	assert_eq(ledges, [Vector2i(12, 36), Vector2i(13, 36), Vector2i(14, 36)] as Array[Vector2i])
	for cell: Vector2i in ledges:
		var below := cell + Vector2i.DOWN
		assert_eq(_terrain.get_step_target(below, Vector2i.UP), below, "ne se monte pas %s" % cell)
	var no_ledge: Dictionary = {}
	for cell: Vector2i in ledges:
		no_ledge[cell] = true
	assert_eq(_distance(_terrain, [GATE], SOUTH[1]), BACK_WITH_LEDGE, "retour par le rebord")
	assert_eq(_distance(_without(no_ledge), [GATE], SOUTH[1]), BACK_WITHOUT_LEDGE)
	var top := _plan.cell_of("rebord_haut")
	var bottom := _plan.cell_of("rebord_bas")
	assert_eq(_distance(_terrain, [top], bottom), LEDGE_LOCAL)
	assert_eq(_distance(_without(no_ledge), [top], bottom), LEDGE_LOCAL_WITHOUT)
	assert_eq(_distance(_without(no_ledge), SOUTH, GATE), SHORTEST, "aller inchangé")
	var painted: Array[Vector2i] = []
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if child is WorldProp and _prop_id(child) == "relief_rebord_01":
			painted.append((child as WorldProp).get_anchor_cell())
	painted.sort()
	assert_eq(painted, ledges, "rebord peint sur ses trois cases")


# --- Points d'examen, objets cachés, PNJ --------------------------------------------------

func test_signs_and_futur_points_are_examined_from_the_right_side() -> void:
	var interactions := _map.get_interactions()
	for spec: Array in EXAMINE:
		var cell: Vector2i = spec[1]
		var facing: Vector2i = spec[2]
		var from := cell - facing
		assert_false(_terrain.is_solid(from), "%s lu depuis %s (praticable)" % [spec[0], from])
		var found := InteractionFinder.find(_grid, interactions, from, facing)
		assert_not_null(found, "%s examiné depuis %s" % [spec[0], from])
		if found != null:
			assert_eq(found.kind, Interaction.Kind.EXAMINE)
			assert_eq(found.dialogue_id, spec[3])
		assert_true(_grid.is_solid(cell), "%s : case bloquée" % spec[0])
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for spec: Array in EXAMINE:
		assert_true(dialogues.has_dialogue(spec[3]), String(spec[3]))
	var tree := _map.get_entities().get_node_or_null(^"DenseTreeFuturA") as WorldProp
	assert_not_null(tree, "FUTUR A : arbre dense")
	if tree != null:
		assert_eq(_prop_id(tree), "tree_foret_08")
		assert_eq(tree.get_anchor_cell(), Vector2i(4, 19))
		assert_lt(tree.scale.x, 1.0, "réduit")


func test_hidden_items_on_short_grass() -> void:
	var expected := {&"route_2_item_3": Vector2i(13, 42), &"route_2_item_4": Vector2i(16, 9)}
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Triggers").get_children():
		var trigger := point as EventTriggerPoint
		found[trigger.cutscene_id] = trigger.get_cell()
		assert_eq(trigger.size, Vector2i.ONE)
		assert_eq(trigger.direction, Vector2i.ZERO)
	assert_eq(found, expected)
	var reach := _grid.find_reachable(SOUTH[1])
	for id: StringName in expected:
		var cell: Vector2i = expected[id]
		assert_eq(_plan.at(cell), ".", "%s sur l'herbe rase" % id)
		assert_false(_grid.is_tall_grass(cell))
		assert_true(reach.has(cell), "%s atteignable" % id)
		assert_eq(_plan.cell_of(String(id)), cell, "position de la grille")


func test_npc_cells_are_free_and_match_the_grid_positions() -> void:
	var roster := NpcRoster.load_for_map(&"route_2")
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	for spec: NpcSpec in roster.get_all():
		assert_true(_plan.positions.has(String(spec.id)), "%s dans la grille" % spec.id)
		assert_has(_plan.cells_at(String(spec.id)), spec.cell, "%s : case de la grille" % spec.id)
		for cell: Vector2i in spec.route_cells:
			assert_has(_plan.cells_at(String(spec.id)), cell, "%s : routine dans la grille" % spec.id)
		assert_true(_plan.is_walkable(spec.cell), "%s sur une case praticable" % spec.id)
		assert_not_null(_map.get_npc(spec.id), "%s posé sur la carte" % spec.id)


# --- Vie de la route (T7) ------------------------------------------------------------------

func test_the_youngster_starts_no_fight_and_has_no_trigger_nearby() -> void:
	var roster := NpcRoster.load_for_map(&"route_2")
	var youngster := roster.get_spec(&"youngster")
	assert_not_null(youngster)
	if youngster == null:
		return
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for variant: Variant in dialogues.get_dialogue(youngster.dialogue).variants:
		assert_eq(variant.cutscene, &"", "P2 : aucune scène derrière sa réplique")
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	for id: StringName in cutscenes.get_ids():
		if not String(id).begins_with("route_2"):
			continue
		for variant: Variant in cutscenes.get_cutscene(id).variants:
			for step: Variant in variant.steps:
				assert_ne(step.kind, CutsceneStep.Kind.BATTLE, "%s : aucun combat" % id)
	for point: Node in _map.get_node(^"Triggers").get_children():
		var cell := (point as EventTriggerPoint).get_cell()
		assert_gt(absi(cell.x - youngster.cell.x) + absi(cell.y - youngster.cell.y), 5,
			"%s loin de P2" % point.name)
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 2, "seulement les deux objets cachés")
	assert_eq(youngster.shy_action, &"", "P2 ne fuit pas et n'a pas de champ de vision")


func test_routines_stay_off_tall_grass_and_the_main_path() -> void:
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_2").get_all():
		var cells: Array[Vector2i] = [spec.cell]
		cells.append_array(spec.route_cells)
		for cell: Vector2i in cells:
			var mark := _plan.at(cell)
			assert_false(mark == "h", "%s en %s : pas dans les hautes herbes" % [spec.id, cell])
			assert_false(mark == "=" or mark == "D",
				"%s en %s : hors du chemin principal" % [spec.id, cell])


func test_nidoran_is_unreachable_in_its_pen() -> void:
	var reach := _terrain.find_reachable(SOUTH[1])
	var cell: Vector2i = NpcRoster.load_for_map(&"route_2").get_spec(&"nidoran").cell
	assert_false(reach.has(cell))
	for direction: Vector2i in DIRECTIONS:
		assert_false(reach.has(cell + direction), "voisine %s inatteignable" % (cell + direction))


func test_ground_objects_are_takeable_from_a_reachable_cell() -> void:
	var reach := _terrain.find_reachable(SOUTH[1])
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_2").get_all():
		if spec.verb != Interaction.Kind.TAKE:
			continue
		var found := false
		for direction: Vector2i in DIRECTIONS:
			var from := spec.cell + direction
			if not reach.has(from):
				continue
			var target := InteractionFinder.find(_grid, _map.get_interactions(), from, -direction)
			if target != null and target.kind == Interaction.Kind.TAKE:
				found = true
		assert_true(found, "%s : PRENDRE possible depuis une case atteignable" % spec.id)


# --- Image -------------------------------------------------------------------------------

func test_forest_canopy_never_covers_a_walkable_cell() -> void:
	var reach := _terrain.find_reachable(SOUTH[1])
	var trees: Array[Node2D] = []
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp and _prop_id(child).begins_with("tree_foret_") \
				and child.name != "DenseTreeFuturA":
			trees.append(child as Node2D)
	assert_gt(trees.size(), 400, "forêt serrée")
	for tree: Node2D in trees:
		var foot := tree.position / float(Grid.TILE_SIZE)
		for cell: Vector2i in DenseForest.canopy_cells(foot):
			if not _grid.is_in_bounds(cell):
				continue
			assert_false(reach.has(cell), "%s : feuillage sur %s" % [tree.name, cell])
			assert_eq(_plan.at(cell), "T", "%s : %s est de la forêt" % [tree.name, cell])
		assert_true((tree as WorldProp).get_footprint().is_empty(), "%s sans emprise" % tree.name)
		assert_false((tree as WorldProp).fade_when_covering, "%s sans fondu" % tree.name)


func test_the_north_is_darker_and_colder() -> void:
	var south := Color(0, 0, 0)
	var north := Color(0, 0, 0)
	var counts := [0, 0]
	for child: Node in _map.get_entities().get_children():
		if not (child is WorldProp and _prop_id(child).begins_with("tree_foret_")):
			continue
		var row := (child as Node2D).position.y / Grid.TILE_SIZE
		if row > 32.0:
			south += (child as Node2D).modulate
			counts[0] += 1
		elif row < 10.0:
			north += (child as Node2D).modulate
			counts[1] += 1
	assert_gt(counts[0], 0)
	assert_gt(counts[1], 0)
	south /= float(counts[0])
	north /= float(counts[1])
	assert_lt(north.g, south.g * 0.85, "forêt plus sombre au nord")
	assert_lt(north.r / north.b, south.r / south.b, "et plus froide")
	var floor_node := _map.get_node(^"ForestFloor") as ForestFloor
	var image := floor_node.mask.get_image()
	assert_almost_eq(image.get_pixelv(Vector2i(4, 8)).r, 0.55, 0.01, "sous-bois de C3")
	assert_almost_eq(image.get_pixelv(Vector2i(25, 50)).r, 0.0, 0.01, "rien dans C1")


func test_painted_props_sit_on_blocked_cells_of_the_grid() -> void:
	var npc_cells: Dictionary = {}
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_2").get_all():
		npc_cells[spec.cell] = spec.id
		for cell: Vector2i in spec.route_cells:
			npc_cells[cell] = spec.id
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if not child is WorldProp:
				continue
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				assert_false(_plan.is_walkable(cell), "%s sur %s praticable" % [child.name, cell])
				assert_false(npc_cells.has(cell), "%s sur la case de %s" % [child.name,
					npc_cells.get(cell)])
	for spec: Array in [["BigStone", "R"], ["Stump", "S"], ["TreeStartW", "G"],
			["TreeStartE", "G"], ["FenceStartW", "c"], ["FenceStartE", "c"]]:
		var prop := _map.get_entities().get_node_or_null(NodePath(spec[0])) as WorldProp
		assert_not_null(prop, spec[0])
		if prop != null:
			for cell: Vector2i in prop.get_solid_cells():
				assert_eq(_plan.at(cell), spec[1], "%s sur « %s »" % [spec[0], spec[1]])


func test_two_tufts_per_tall_grass_cell() -> void:
	var counts: Dictionary = {}
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp and _prop_id(child) == "ground_hautes_herbes_jaune_01":
			var cell := Grid.world_to_cell((child as Node2D).position - Vector2(0, 1))
			counts[cell] = int(counts.get(cell, 0)) + 1
	for cell: Vector2i in _plan.cells_of("h"):
		assert_eq(counts.get(cell, 0), 2, "deux touffes en %s" % cell)


func test_node_budget() -> void:
	var map := (load(MAP_PATH) as PackedScene).instantiate()
	var total := _count(map)
	map.free()
	assert_lte(total, NODE_BUDGET, "nœuds de la scène")
	gut.p("route_2 : %d nœuds" % total)
