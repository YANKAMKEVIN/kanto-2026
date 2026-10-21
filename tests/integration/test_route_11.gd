extends GutTest
## Carte route_11 (jalon 17 T16, docs/tech/jalon-17.md §2.1 ; dossier 20 §3.2) sur la vraie
## scène : métadonnées, lumière et zone, mer peinte, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_11.txt` case par case (solide, eau, hautes herbes), raccords (Carmin,
## bouche de la Cave), puis les critères de `tools/art/plan_check_j17.py` refaits sur la vraie
## grille (positions `bloque` en plus, bouche terminale) : D2 inévitable ; D1 et D3 à D8
## évitables, un à un et ensemble ; trois parcours suffisants chacun ; goulet de l'est seul passage
## vers le bord est ; H2 (6 cases obligatoires sur le parcours nord) ; objets atteignables ; cases
## réservées libres de décor ; budget de nœuds. La vie (PNJ, objets) : `test_route_11_life`,
## `test_route_11_trainers`.
## J21 T9a (décision M-3 de Kevin, 2026-10-16, dossier 24 §10.3) : Ronflex quitte la Route 11 pour
## le croisement de la Route 12. Ses cases redeviennent du chemin et le bord est (75, 14..15) est
## un passage « ROUTE 12 — À venir » (`coming_soon`) jusqu'au J21 T21 (warp réel vers route_12).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_11.tscn"
const PLAN_PATH := "res://tools/plans/route_11.txt"
const SIZE := Vector2i(76, 36)
const WEST := [Vector2i(0, 11), Vector2i(0, 12), Vector2i(0, 13)]
const MOUTH := [Vector2i(15, 7), Vector2i(16, 7)]
const FRONT := [Vector2i(65, 14), Vector2i(65, 15)]
const EAST_EDGE := [Vector2i(75, 14), Vector2i(75, 15)]
## Goulet de l'est (cases de l'ancien Ronflex du J17, retiré par M-3).
const NARROWS := [Vector2i(66, 14), Vector2i(67, 14), Vector2i(66, 15), Vector2i(67, 15)]
const NODE_BUDGET := 3000
const INF := 1 << 30
const SHORE_PREFIX := "relief_rivage_"
## Rôle de la grille → identifiant de position.
const TRAINERS: Dictionary[String, String] = {
	"D1": "lucas", "D2": "arthur", "D3": "louis", "D4": "raphael", "D5": "marcel",
	"D6": "roger", "D7": "bruno", "D8": "victor",
}
const ROUTES: Array[String] = ["nord", "centre", "sud"]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (Dresseurs, Pokémon, objets, panneaux).
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
	for cell: Vector2i in MOUTH:
		_stops[cell] = true


func after_all() -> void:
	_map.free()


func _without(cells: Variant, base: GridWorld = null) -> GridWorld:
	var grid := GridPaths.relief(base if base != null else _terrain, SIZE)
	for cell: Vector2i in cells:
		grid.set_solid(cell)
	return grid


func _reach(grid: GridWorld) -> Dictionary:
	return GridPaths.distances(grid, WEST, _stops)


func _nearest(dist: Dictionary, cells: Array) -> int:
	var best := INF
	for cell: Vector2i in cells:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func _role(role: String) -> String:
	for id: String in _plan.positions:
		if _plan.attr(id, "role") == role:
			return id
	return ""


func _sight(role: String) -> Array[Vector2i]:
	var id: String = TRAINERS[role]
	var facing := Grid.direction_from_name(_plan.attr(id, "facing"))
	var origin := _plan.cell_of(id)
	var cells: Array[Vector2i] = []
	for k: int in range(1, int(_plan.attr(id, "sight")) + 1):
		var cell := origin + facing * k
		if not _grid.is_in_bounds(cell) or _terrain.is_solid(cell):
			break
		cells.append(cell)
	return cells


func _grass_zone(role: String) -> Dictionary:
	var start := _plan.cell_of(_role(role))
	var zone := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		for side: Vector2i in GridPaths.DIRECTIONS:
			if not zone.has(cell + side) and _plan.at(cell + side) == "h":
				zone[cell + side] = true
				stack.append(cell + side)
	return zone


func _all_grass() -> Dictionary:
	var cells: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		cells[cell] = true
	return cells


func _cuts() -> Dictionary:
	var cuts: Dictionary = {}
	for route: String in ROUTES:
		cuts[route] = _plan.cells_at("itineraire_" + route)
	return cuts


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_painted_coast() -> void:
	assert_eq(_map.map_id, &"route_11")
	assert_eq(_map.display_name, "Route 11")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_11"), &"golden_hour", "au plan de lumière")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_11"), &"route_11")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		assert_not_null(ground.shore_mask, "rivage (mer)")
		assert_true(ground.square_shore, "mer à angles droits")
		assert_eq(ground.r_texture.resource_path, "res://assets/world/ground/ground_digue_01.png",
			"la digue est le sol « pavé » de la carte")
		var shore := ground.shore_mask.get_image()
		assert_eq(GroundMask.shore_at(shore, Vector2i(10, 30)), GroundMask.Kind.WATER)
		assert_eq(GroundMask.shore_at(shore, Vector2i(10, 14)), GroundMask.Kind.GRASS)
		assert_eq(GroundMask.kind_at(ground.mask.get_image(), Vector2i(5, 12)),
			GroundMask.Kind.PATH)
		assert_eq(GroundMask.kind_at(ground.mask.get_image(), Vector2i(40, 22)),
			GroundMask.Kind.PAVING, "digue")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


# --- Grille ------------------------------------------------------------------------------

func test_scene_grid_is_the_functional_grid() -> void:
	# Cases solides en plus de la grille : panneaux et pierre-indice (props à emprise 1 × 1).
	var props: Array[Vector2i] = _plan.cells_at("panneau_ouest") + _plan.cells_at(
		"panneau_cave") + _plan.cells_at("route_11_hidden_1")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or props.has(cell)
			var ok := (mark == "W" or _grid.is_solid(cell) == solid) \
				and _grid.is_tall_grass(cell) == (mark == "h") \
				and _grid.is_water(cell) == (mark == "W") \
				and _grid.get_ledge(cell) == GridWorld.Ledge.NONE
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_water(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_11.txt")
	assert_eq(_plan.walkable, ".=hoqQ")


func test_sea_is_closed() -> void:
	for cell: Vector2i in _plan.cells_of("W"):
		assert_true(_grid.is_water(cell), "mer %s : eau" % cell)
		for side: Vector2i in GridPaths.DIRECTIONS:
			var from := cell - side
			if _grid.is_in_bounds(from) and not _grid.is_solid(from):
				assert_false(_grid.can_enter(from, side), "mer %s fermée depuis %s" % [cell, from])


# --- Passages ----------------------------------------------------------------------------

## Raccord ouest : (0, 11..13) → Carmin (63, 11..13), rangée pour rangée, tournés vers l'ouest
## au départ (poussée), vers l'est à l'arrivée.
func test_west_edge_leads_to_vermilion_row_by_row() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in WEST.size():
		var cell: Vector2i = WEST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[&"vermilion_city", StringName("from_route_11_" + suffixes[i])])
		assert_eq(_map.get_spawn_cell(StringName("from_vermilion_" + suffixes[i])), cell)
		assert_false(_grid.is_solid(cell))


func test_cave_mouth_warps_into_the_cave() -> void:
	var suffixes := ["w", "e"]
	for i: int in MOUTH.size():
		var cell: Vector2i = MOUTH[i]
		assert_false(_grid.is_solid(cell), "%s praticable" % cell)
		var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "bouche STEP_ON ↑ en %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"digletts_cave", StringName("from_route_11_" + suffixes[i]), Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName("from_cave_" + suffixes[i])),
			cell + Vector2i.DOWN)
	assert_eq(_map.get_warps().size(), 7, "trois raccords ouest, deux bouches, deux cases à l'est")


## Jalon 21 (T21) : le bord est est le raccord réel vers la Route 12 (`route_12` / `from_route_11_n|s`),
## les retours `from_route_12_n|s` (74, 14..15) tournés ← sont gardés (avant : « ROUTE 12 — À venir »).
func test_east_edge_leads_to_route_12() -> void:
	var suffixes := ["n", "s"]
	for i: int in EAST_EDGE.size():
		var cell: Vector2i = EAST_EDGE[i]
		assert_false(_grid.is_solid(cell), "%s praticable" % cell)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "bord est PUSH → en %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[&"route_12", StringName("from_route_11_" + suffixes[i])])
		assert_eq(_map.get_spawn_cell(StringName("from_route_12_" + suffixes[i])),
			cell + Vector2i.LEFT)


# --- Critères (plan_check_j17.py) ---------------------------------------------------------

func test_main_path_lengths() -> void:
	var dist := _reach(_terrain)
	var cave := _nearest(dist, MOUTH)
	var narrows := _nearest(dist, FRONT)
	var east := _nearest(dist, EAST_EDGE)
	gut.p("route_11 : Carmin → Cave %d pas, → goulet de l'est %d pas, → bord est %d pas"
		% [cave, narrows, east])
	assert_eq(cave, 20, "entrée → bouche de la Cave")
	assert_eq(narrows, 71, "entrée → devant le goulet de l'est")
	assert_eq(east, 81, "entrée → bord est (M-3 : plus de Ronflex)")
	var back := GridPaths.distances(_terrain, [Vector2i(15, 8), Vector2i(16, 8)])
	assert_between(_nearest(back, WEST), 1, 25, "retour Cave → Carmin")


## M-3 : plus de Ronflex ; le goulet de 2 cases reste le seul passage vers l'est.
func test_east_narrows_are_the_only_way_east() -> void:
	var dist := _reach(_terrain)
	for cell: Vector2i in NARROWS:
		assert_false(_terrain.is_solid(cell), "goulet libre en %s (Ronflex retiré)" % cell)
		assert_eq(_plan.at(cell), "=", "chemin en %s" % cell)
	assert_lt(_nearest(dist, EAST_EDGE), INF, "bord est atteint")
	assert_eq(_nearest(_reach(_without(NARROWS)), EAST_EDGE), INF,
		"sans le goulet, le bord est est coupé : il est le seul passage")
	for x: int in [66, 67]:
		for y: int in range(6, 24):
			var free := not _terrain.is_solid(Vector2i(x, y))
			assert_eq(free, y == 14 or y == 15, "goulet (%d, %d)" % [x, y])


func test_no_snorlax_left_on_route_11() -> void:
	assert_false(_plan.positions.has("ronflex"), "position ronflex retirée de la grille")
	assert_null(_map.get_entities().get_node_or_null(^"Snorlax"), "plus de FlagGate Ronflex")
	assert_null(_map.find_child("SnorlaxPoint", true, false), "plus de point d'examen")


func test_east_narrows_are_seen_from_afar() -> void:
	for x: int in range(46, 66):
		assert_eq(_plan.at(Vector2i(x, 14)), "=", "ligne droite (%d, 14)" % x)
		assert_false(_grid.is_solid(Vector2i(x, 14)))


func test_d2_cannot_be_avoided() -> void:
	var sight := _sight("D2")
	assert_eq(sight.size(), 4, "D2 : vue dégagée")
	assert_eq(_nearest(_reach(_without(sight)), MOUTH), INF, "D2 inévitable vers la Cave")
	assert_eq(_nearest(_reach(_without(sight)), FRONT), INF, "D2 inévitable vers l'est")
	# Première case vue à au moins 3 cases de l'entrée (le joueur voit Arthur arriver).
	var seen: Dictionary = {}
	for cell: Vector2i in sight:
		seen[cell] = true
	var dist := _reach(_terrain)
	var first := INF
	for cell: Vector2i in sight:
		first = mini(first, int(dist.get(cell, INF)))
	assert_gte(first, 3, "première case vue à 3 cases ou plus de l'entrée")


func test_other_trainers_can_be_avoided_alone_and_together() -> void:
	var seen: Array[Vector2i] = []
	for role: String in TRAINERS:
		if role == "D2":
			continue
		var sight := _sight(role)
		assert_gt(sight.size(), 0, "%s voit devant lui" % role)
		for target: Array in [MOUTH, FRONT]:
			assert_lt(_nearest(_reach(_without(sight)), target), INF, "%s évitable" % role)
		seen.append_array(sight)
	for target: Array in [MOUTH, FRONT]:
		assert_lt(_nearest(_reach(_without(seen)), target), INF,
			"D1 et D3 à D8 évitables ensemble")


func test_three_routes_each_suffice_and_cutting_all_closes_the_road() -> void:
	var cuts := _cuts()
	var all: Array[Vector2i] = []
	for route: String in ROUTES:
		all.append_array(cuts[route])
	for route: String in ROUTES:
		var others: Array[Vector2i] = []
		for other: String in ROUTES:
			if other != route:
				others.append_array(cuts[other])
		var d := _nearest(_reach(_without(others)), FRONT)
		assert_lt(d, INF, "le parcours « %s » suffit seul" % route)
		gut.p("route_11 : parcours %s %d pas" % [route, d])
	assert_eq(_nearest(_reach(_without(all)), FRONT), INF, "les trois coupés : fermé")


func test_tall_grass_h2_is_mandatory_on_the_north_route_only() -> void:
	var cuts := _cuts()
	var not_north: Array[Vector2i] = cuts["centre"] + cuts["sud"]
	var north := _without(not_north)
	var crossed := GridPaths.min_crossed(north, WEST, FRONT, _all_grass())
	assert_between(crossed, 6, 10, "cases d'herbes obligatoires sur le parcours nord")
	assert_eq(GridPaths.min_crossed(north, WEST, FRONT, _grass_zone("H2")), crossed,
		"toutes dans H2")
	assert_eq(GridPaths.min_crossed(_terrain, WEST, FRONT, _all_grass()), 0,
		"aucune herbe obligatoire sur la route")
	assert_eq(GridPaths.min_crossed(_terrain, WEST, MOUTH, _all_grass()), 0,
		"aucune herbe vers la Cave")
	for role: String in ["H1", "H3"]:
		assert_eq(GridPaths.min_crossed(_terrain, WEST, FRONT, _grass_zone(role)), 0,
			"%s évitable" % role)


func test_south_route_is_the_dike_behind_a_row_of_fences() -> void:
	for cell: Vector2i in _cuts()["sud"]:
		assert_eq(_plan.at(cell), "q", "digue")
		assert_eq(_plan.at(cell + Vector2i.UP * (1 if cell.y == 22 else 2)), "c", "clôture au nord")


func test_items_are_reachable_outside_trainer_sight() -> void:
	var dist := _reach(_terrain)
	var lines: Dictionary = {}
	for role: String in TRAINERS:
		for cell: Vector2i in _sight(role):
			lines[cell] = true
	for id: String in ["route_11_item_1", "route_11_item_2", "route_11_hidden_1"]:
		var cell := _plan.cell_of(id)
		assert_false(lines.has(cell), "%s hors des lignes de vue" % id)
		var best := INF
		for side: Vector2i in GridPaths.DIRECTIONS:
			best = mini(best, int(dist.get(cell + side, INF)))
		assert_lt(best, INF, "%s atteignable" % id)


func test_hidden_item_clue_is_a_stone_on_the_meadow() -> void:
	var clue := _plan.cell_of("route_11_hidden_1")
	assert_eq(clue, Vector2i(62, 9))
	assert_true(_grid.is_solid(clue), "case de l'indice bloquée")
	assert_true(_map.get_node_or_null(^"GroundDecals/StoneClue") != null, "indice « caillou »")
	assert_true(_reach(_terrain).has(clue + Vector2i.DOWN), "examinable depuis (62, 10)")


# --- Décor ---------------------------------------------------------------------------------

func _props() -> Array[WorldProp]:
	var props: Array[WorldProp] = []
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				props.append(child as WorldProp)
	return props


func test_props_never_block_a_walkable_cell() -> void:
	var allowed: Array[Vector2i] = _plan.cells_at("panneau_ouest") + _plan.cells_at(
		"panneau_cave") + _plan.cells_at("route_11_hidden_1")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(not _plan.is_walkable(cell) or allowed.has(cell),
				"%s bloque la case praticable %s" % [prop.name, cell])


func test_reserved_cells_stay_free_of_decor() -> void:
	var kinds := ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
	var reserved: Dictionary = {}
	for id: String in _plan.positions:
		if kinds.has(_plan.positions[id]["kind"]):
			for cell: Vector2i in _plan.cells_at(id):
				reserved[cell] = true
	assert_eq(reserved.size(), 8 + 3 + 2 + 1,
		"8 Dresseurs, 3 Pokémon, 2 objets, 1 caché (Ronflex retiré : M-3)")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			# La pierre-indice se pose sur la case cachée elle-même.
			assert_false(reserved.has(cell) and _plan.at(cell) != "x"
				and prop.name != &"StoneClue",
				"%s sur la case réservée %s" % [prop.name, cell])
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Forest"):
			var foot := Vector2i(((child as Node2D).position - Vector2(0, 1)) / Grid.TILE_SIZE)
			assert_false(reserved.has(foot), "%s sur la case réservée %s" % [child.name, foot])


func test_cave_mouth_is_the_talus_with_two_open_cells() -> void:
	var mouth := _map.get_node_or_null(^"Entities/CaveMouth") as WorldProp
	assert_not_null(mouth, "bouche de la Cave")
	if mouth != null:
		var solid := mouth.get_solid_cells()
		assert_eq(solid.size(), 4 * 3 - 2, "4 × 3 moins l'ouverture")
		for cell: Vector2i in MOUTH:
			assert_false(solid.has(cell), "ouverture %s libre" % cell)
		for cell: Vector2i in solid:
			assert_eq(_plan.at(cell), "K", "emprise sur le talus (%s)" % cell)


func test_fences_and_dike_edges() -> void:
	var fences := 0
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Fence"):
			fences += 1
	assert_eq(fences, 7, "26 cases de clôture : 6 modules et un de rattrapage")
	var edges := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if String(child.name).begins_with("DikeEdge"):
			edges += 1
	assert_eq(edges, 15, "bord sud de la digue : 2 × (8 + 6 modules) sauf la poche, +1")


func test_shore_modules_only_on_rock_cells_touching_the_sea() -> void:
	var count := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if child is Sprite2D and String((child as Sprite2D).texture.resource_path).contains(
				SHORE_PREFIX):
			count += 1
			var sprite := child as Sprite2D
			var rect := Rect2(sprite.position, sprite.texture.get_size() * sprite.scale)
			var inner := rect.grow_individual(0.0, -Grid.TILE_SIZE * 0.2, 0.0, 0.0)
			var first := Vector2i((inner.position / Grid.TILE_SIZE).floor())
			var last := Vector2i(((inner.end - Vector2.ONE * 0.5) / Grid.TILE_SIZE).floor())
			for y: int in range(first.y, last.y + 1):
				for x: int in range(first.x, last.x + 1):
					assert_eq(_plan.at(Vector2i(x, y)), "R",
						"%s : module du rivage sur une case R (%d, %d)" % [child.name, x, y])
	assert_gt(count, 0, "rivage rocheux posé hors de la digue")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_11 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds (budget du J9)")
