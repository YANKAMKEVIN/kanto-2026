extends GutTest
## Carte route_3 (jalon 12 T8, docs/tech/jalon-12.md §1.3, §2.1, §2.17, §2.18, §2.21 ;
## dossier 15 §3, §7) sur la vraie scène : métadonnées et lumière, sol rocheux peint, **grille de
## la scène = grille fonctionnelle** `tools/plans/route_3.txt` case par case (solide, hautes
## herbes, rebords), raccords (Argenta, Centre, Mont Sélénite, sortie de la Corde Sortie),
## critères de `tools/art/plan_check_route_3.py` refaits sur la vraie grille (positions `bloque`
## en plus ; portes terminales) : D1 / D2 inévitables par géométrie, D3–D6 évitables, deux
## itinéraires, rebords, hautes herbes, longueur du chemin principal ; cases réservées au T18
## libres de tout décor ; montagne qui passe à l'ardoise vers l'est ; budget de nœuds.
## Sans PNJ, sans rencontres, sans déclencheurs (T18).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_3.tscn"
const PLAN_PATH := "res://tools/plans/route_3.txt"
const SIZE := Vector2i(82, 38)
const WEST := [Vector2i(0, 25), Vector2i(0, 26), Vector2i(0, 27)]
const CENTER_DOOR := [Vector2i(61, 11), Vector2i(62, 11)]
const CAVE := [Vector2i(73, 9), Vector2i(74, 9)]
const NODE_BUDGET := 3000
## Bornes de `plan_check_route_3.py` (défauts du dossier).
const PATH_RANGE := Vector2i(85, 130)
const GRASS_RANGE := Vector2i(6, 10)
const INF := 1 << 30
const SLATE_PREFIX := "relief_paroi_ardoise_"
const SERIE_12 := ["relief_paroi_01", "relief_paroi_02", "relief_paroi_03", "relief_paroi_04"]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (Dresseurs, PNJ, objets, panneaux).
var _terrain: GridWorld
## Portes terminales (Centre, grotte) : on y entre, on ne les traverse pas.
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
	for cell: Vector2i in CENTER_DOOR + CAVE:
		_stops[cell] = true


func after_all() -> void:
	_map.free()


func _without(cells: Variant) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
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


## Ligne de vue d'un Dresseur de la grille (s'arrête au premier obstacle du relief).
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


## Zone d'herbes connexe qui contient la position `herbes_<name>`.
func _grass_zone(zone_name: String) -> Dictionary:
	var start := _plan.cell_of("herbes_" + zone_name)
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


func _all_grass() -> Dictionary:
	var cells: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		cells[cell] = true
	return cells


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_3")
	assert_eq(_map.display_name, "Route 3")
	assert_eq(_map.region, "Argenta — Mont Sélénite", "sous-titre de l'annexe A")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_3"), &"golden_hour", "au plan de lumière")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_3"), &"route_3")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		assert_eq(ground.get_textures()[1].resource_path,
			"res://assets/world/ground/ground_roche_01.png", "canal rouge = sol rocheux")
		var mask := ground.mask.get_image()
		assert_eq(GroundMask.kind_at(mask, Vector2i(0, 26)), GroundMask.Kind.PATH)
		assert_eq(GroundMask.kind_at(mask, Vector2i(65, 15)), GroundMask.Kind.PAVING,
			"parvis rocheux")
		assert_eq(GroundMask.kind_at(mask, Vector2i(8, 20)), GroundMask.Kind.GRASS)
	assert_not_null(_map.grass_front, "cache-jambes peint")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_battle_decor_is_the_rocky_route() -> void:
	var decors := BattleDecorCatalog.load_file()
	var decor := decors.pick(&"route_3", Vector2i(30, 30))
	assert_not_null(decor, "décor de combat de la Route 3")
	if decor != null:
		assert_eq(decor.id, &"route_3_roche")


func test_scene_grid_is_the_functional_grid() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ouest") + _plan.cells_at(
		"panneau_centre")
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
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_3.txt")
	assert_eq(_plan.walkable, ".=hvoDQ")


# --- Passages ----------------------------------------------------------------------------

func test_west_edge_leads_to_pewter_city() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in WEST.size():
		var cell: Vector2i = WEST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"pewter_city",
				StringName("from_route_3_" + suffixes[i]), Vector2i.LEFT])
		assert_eq(_map.get_spawn_cell(StringName("from_pewter_" + suffixes[i])), cell)


func test_center_door_and_cave_entrance() -> void:
	var specs := [[CENTER_DOOR, &"mt_moon_center", ["entrance", "entrance"], Vector2i.ZERO,
		"from_center"], [CAVE, &"mt_moon_1f", ["from_route_3_w", "from_route_3_e"], Vector2i.UP,
		"from_mt_moon"]]
	for spec: Array in specs:
		var cells: Array = spec[0]
		for i: int in cells.size():
			var cell: Vector2i = cells[i]
			assert_false(_grid.is_solid(cell), "%s praticable" % cell)
			var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
			assert_not_null(warp, "passage STEP_ON ↑ en %s" % cell)
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn, warp.facing], [spec[1],
					StringName(spec[2][i]), spec[3]])
			var front := "%s_%s" % [spec[4], ["w", "e"][i]]
			assert_eq(_map.get_spawn_cell(StringName(front)), cell + Vector2i.DOWN,
				"%s devant le passage" % front)
	assert_eq(_map.get_warps().size(), 7, "trois raccords ouest, deux portes, deux entrées")


func test_escape_rope_lands_in_front_of_the_cave() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var exit := caves.escape_target(&"mt_moon_1f")
	assert_not_null(exit)
	if exit == null:
		return
	assert_eq(exit.map, &"route_3")
	assert_true(_map.has_spawn(exit.spawn), "spawn de la Corde Sortie")
	assert_eq(_map.get_spawn_cell(exit.spawn), Vector2i(73, 10))
	assert_false(_grid.is_solid(_map.get_spawn_cell(exit.spawn)))


func test_no_life_yet() -> void:
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0, "déclencheurs au T18")
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 0, "points d'examen au T18")


# --- Critères (plan_check_route_3.py) ----------------------------------------------------

func test_entrance_reaches_the_center_then_the_cave() -> void:
	var dist := _reach(_terrain)
	var center := _nearest(dist, CENTER_DOOR)
	var cave := _nearest(dist, CAVE)
	assert_lt(center, INF, "porte du Centre atteignable")
	assert_lt(cave, INF, "entrée de la grotte atteignable")
	assert_lt(center, cave, "le Centre avant la grotte")
	gut.p("route_3 : chemin principal %d pas" % cave)
	assert_between(cave, PATH_RANGE.x, PATH_RANGE.y, "longueur du chemin principal")


func test_hugo_and_lea_cannot_be_avoided() -> void:
	for id: String in ["hugo", "lea"]:
		var sight := _sight(id)
		assert_eq(sight.size(), int(_plan.attr(id, "sight")), "%s : vue dégagée" % id)
		var dist := _reach(_without(sight))
		assert_eq(_nearest(dist, CAVE), INF, "%s inévitable (grotte)" % id)
		assert_eq(_nearest(dist, CENTER_DOOR), INF, "%s inévitable (Centre)" % id)


func test_other_trainers_can_be_avoided_together() -> void:
	var seen: Array[Vector2i] = []
	for id: String in ["sacha", "enzo", "ines", "nolan"]:
		var sight := _sight(id)
		assert_gt(sight.size(), 0, "%s voit devant lui" % id)
		assert_lt(_nearest(_reach(_without(sight)), CAVE), INF, "%s évitable" % id)
		seen.append_array(sight)
	assert_lt(_nearest(_reach(_without(seen)), CAVE), INF, "D3 à D6 évitables ensemble")


func test_two_itineraries_each_suffice() -> void:
	var north := _plan.cells_at("itineraire_nord")
	var south := _plan.cells_at("itineraire_sud")
	assert_lt(_nearest(_reach(_without(north)), CAVE), INF, "le sud suffit")
	assert_lt(_nearest(_reach(_without(south)), CAVE), INF, "le nord suffit")
	assert_eq(_nearest(_reach(_without(north + south)), CAVE), INF, "couper les deux ferme")
	var sacha := _plan.cell_of("sacha")
	var enzo := _plan.cell_of("enzo")
	assert_true(_box_of(north).grow(1).has_point(sacha), "Sacha sur le chemin nord")
	assert_true(_box_of(south).grow(1).has_point(enzo), "Enzo sur le chemin sud")


func _box_of(cells: Array[Vector2i]) -> Rect2i:
	var box := Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		box = box.expand(cell).expand(cell + Vector2i.ONE)
	return box


func test_ledges_jump_south_and_never_climb() -> void:
	for cell: Vector2i in _plan.cells_of("v"):
		assert_eq(_grid.get_step_target(cell + Vector2i.DOWN, Vector2i.UP),
			cell + Vector2i.DOWN, "rebord %s : ne se monte pas" % cell)
		if not _grid.is_solid(cell + Vector2i.UP):
			assert_eq(_grid.get_step_target(cell + Vector2i.UP, Vector2i.DOWN),
				cell + Vector2i.DOWN, "rebord %s : sauté vers le sud" % cell)


func test_tall_grass_h4_is_mandatory_h1_avoidable() -> void:
	var h4 := _grass_zone("h4")
	var h1 := _grass_zone("h1")
	assert_gt(GridPaths.min_crossed(_terrain, WEST, CAVE, h4), 0, "H4 incontournable")
	assert_eq(GridPaths.min_crossed(_terrain, WEST, CAVE, h1), 0, "H1 évitable")
	var crossed := GridPaths.min_crossed(_terrain, WEST, CAVE, _all_grass())
	gut.p("route_3 : %d cases d'herbes obligatoires" % crossed)
	assert_between(crossed, GRASS_RANGE.x, GRASS_RANGE.y, "cases d'herbes obligatoires")


func test_hidden_item_clue_is_reachable_from_three_sides() -> void:
	var clue := _plan.cell_of("route_3_hidden_1")
	assert_eq(clue, Vector2i(36, 18))
	var dist := _reach(_terrain)
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		assert_true(dist.has(clue + side), "indice examinable depuis %s" % (clue + side))


# --- Décor ---------------------------------------------------------------------------------

func _props() -> Array[WorldProp]:
	var props: Array[WorldProp] = []
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				props.append(child as WorldProp)
	return props


func test_props_never_block_a_walkable_cell() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ouest") + _plan.cells_at(
		"panneau_centre")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(not _plan.is_walkable(cell) or signs.has(cell),
				"%s bloque la case praticable %s" % [prop.name, cell])


func test_reserved_cells_stay_free_for_the_t18() -> void:
	var kinds := ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
	var reserved: Dictionary = {}
	for id: String in _plan.positions:
		if kinds.has(_plan.positions[id]["kind"]):
			for cell: Vector2i in _plan.cells_at(id):
				reserved[cell] = true
	assert_eq(reserved.size(), 15, "6 Dresseurs, 2 PNJ, 3 Pokémon, 3 objets, 1 caché")
	# Les Piafabec d'ambiance se posent sur leur rocher (« sur l'affleurement ») : seuls les
	# Dresseurs, PNJ et objets veulent une case sans décor.
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			var perch := _plan.at(cell) in ["R", "K"]
			assert_false(reserved.has(cell) and not perch,
				"%s sur la case réservée %s" % [prop.name, cell])
	# Aucun arbre de la forêt serrée n'a son pied sur une case réservée (il cacherait le PNJ).
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Forest"):
			var foot := Vector2i(((child as Node2D).position - Vector2(0, 1)) / Grid.TILE_SIZE)
			assert_false(reserved.has(foot), "%s sur la case réservée %s" % [child.name, foot])


func test_center_and_cave_entrance_are_placed() -> void:
	var center := _map.get_node_or_null(^"Entities/PokemonCenter") as WorldProp
	assert_not_null(center, "Centre Pokémon")
	if center != null:
		var solid := center.get_solid_cells()
		assert_false(solid.has(Vector2i(61, 11)) or solid.has(Vector2i(62, 11)), "porte libre")
		for cell: Vector2i in solid:
			assert_eq(_plan.at(cell), "C", "emprise du Centre sur les cases C (%s)" % cell)
	var cave := _map.get_node_or_null(^"Entities/MtMoonEntrance") as WorldProp
	assert_not_null(cave, "entrée du Mont Sélénite")
	if cave != null:
		for cell: Vector2i in cave.get_solid_cells():
			assert_eq(_plan.at(cell), "K", "entrée dans la paroi (%s)" % cell)


func test_mountain_turns_to_slate_eastwards() -> void:
	var slate := 0
	var west := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		var id := child.scene_file_path.get_file().get_basename()
		var column := (child as Node2D).position.x / Grid.TILE_SIZE
		if id.begins_with(SLATE_PREFIX):
			slate += 1
			assert_gt(column, 40.0, "%s : ardoise à l'est (%.1f)" % [child.name, column])
		elif SERIE_12.has(id):
			west += 1
			assert_lt(column, 48.0, "%s : paroi beige à l'ouest (%.1f)" % [child.name, column])
	assert_gt(slate, 40, "la masse de l'est est d'ardoise")
	assert_gt(west, 0, "la paroi de la série 12 garde l'ouest")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_3 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds (budget du J9)")
