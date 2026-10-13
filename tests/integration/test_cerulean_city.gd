extends GutTest
## Carte cerulean_city (Azuria, jalon 13 T7, docs/tech/jalon-13.md §2.1, §2.3, §2.5 ; dossier 16
## §4–§6) : métadonnées et lumière, **grille de la scène = grille fonctionnelle**
## `tools/plans/azuria.txt` case par case, eau solide (et vue par `GridWorld.is_water`), ponts
## et quais praticables, raccords ouest (Route 4) et nord (Route 24), portes des cinq bâtiments
## ouverts, sorties est et sud fermées **sans warp**, Centre premier bâtiment de l'avenue, tous
## les lieux atteignables (les ponts sont nécessaires), cases réservées (PNJ, examens), objets
## peints sur des cases bloquées, quais hors des cases praticables, budget de nœuds.
## Vie (PNJ, examens, arrivée) : `test_cerulean_life`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/cerulean_city.tscn"
const PLAN_PATH := "res://tools/plans/azuria.txt"
const WALKABLE := ".=pqBD"
const SIZE := Vector2i(56, 41)
const WEST: Array[Vector2i] = [Vector2i(0, 19), Vector2i(0, 20), Vector2i(0, 21)]
const NORTH: Array[Vector2i] = [Vector2i(31, 0), Vector2i(32, 0), Vector2i(33, 0)]
const NODE_BUDGET := 3000
const VIEW := Vector2(2340.0, 1080.0)
## [position des portes, nœud, objet peint, intérieur, spawn devant la porte].
const BUILDINGS: Array = [
	["porte_centre", "PokemonCenter", "bldg_centre_01", &"cerulean_center", &"from_center"],
	["porte_boutique", "PokeMart", "bldg_boutique_01", &"cerulean_mart", &"from_mart"],
	["porte_arene", "Gym", "bldg_arene_azuria_01", &"cerulean_gym", &"from_gym"],
	["porte_velos", "BikeShop", "bldg_velos_01", &"cerulean_bike_shop", &"from_bike_shop"],
	["porte_maison", "HouseOpen", "bldg_maison_argenta_01", &"cerulean_house", &"from_house"],
]
const BRIDGES: Array[Rect2i] = [Rect2i(31, 15, 3, 4), Rect2i(40, 15, 2, 4), Rect2i(26, 8, 4, 2)]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
var _terrain: GridWorld
var _signs: Array[Vector2i] = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_plan.walkable = WALKABLE
	for id: String in ["panneau_ville", "panneau_arene"]:
		_signs.append(_plan.cell_of(id))
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)
	for cell: Vector2i in _plan.cells_of("w"):
		_terrain.set_solid(cell)  # l'eau ne se traverse pas (is_water, pas is_solid)


func after_all() -> void:
	_map.free()


func _doors() -> Dictionary:
	var doors: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("D"):
		doors[cell] = true
	return doors


func test_metadata_light_and_painted_water_ground() -> void:
	assert_eq(_map.map_id, &"cerulean_city")
	assert_eq(_map.display_name, "Azuria")
	assert_eq(_map.region, "La ville aux eaux claires")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"cerulean_city"), &"cerulean_city")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		var mask := ground.mask.get_image()
		assert_eq(GroundMask.kind_at(mask, Vector2i(30, 22)), GroundMask.Kind.PAVING, "place")
		assert_eq(GroundMask.kind_at(mask, Vector2i(24, 10)), GroundMask.Kind.PAVING, "quai")
		assert_eq(GroundMask.kind_at(mask, Vector2i(10, 10)), GroundMask.Kind.PATH, "ruelle")
		assert_eq(GroundMask.kind_at(mask, Vector2i(10, 2)), GroundMask.Kind.PATH, "jardin clos")
		assert_not_null(ground.shore_mask, "eau")
		assert_eq(GroundMask.shore_at(ground.shore_mask.get_image(), Vector2i(27, 5)),
			GroundMask.Kind.WATER)
		assert_true(ground.square_shore, "angles droits")
		assert_eq(ground.foam_strength, 0.0, "pas d'écume contre un quai")
		assert_not_null(ground.water_texture)
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			# L'eau n'est pas « solide » : `is_water` (test suivant), jamais praticable.
			var solid := (not _plan.is_walkable(cell) and _plan.at(cell) != "w") \
				or _signs.has(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/azuria.txt")


func test_water_is_solid_and_seen_by_the_companion_bridges_are_walkable() -> void:
	var water := 0
	for cell: Vector2i in _plan.cells_of("w"):
		water += 1
		assert_true(_grid.is_water(cell), "eau %s" % cell)
		for side: Vector2i in GridPaths.DIRECTIONS:
			assert_false(_grid.can_enter(cell, side), "eau %s jamais praticable" % cell)
	assert_gt(water, 200)
	for cell: Vector2i in _plan.cells_of("B"):
		# Le terrain est praticable ; l'enfant H2 (T17) occupe une case du pont central.
		assert_true(_grid.can_enter(cell, Vector2i.UP) or cell == _plan.cell_of("h2_enfant"),
			"pont %s" % cell)
		assert_false(_grid.is_water(cell))
	for cell: Vector2i in _plan.cells_of("q"):
		assert_false(_grid.is_solid(cell), "quai %s" % cell)


func test_three_bridges_with_their_own_decks() -> void:
	var found: Dictionary = {}
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		var name := String(child.name)
		if name.begins_with("Pont"):
			var index := int(name.substr(4, 2))
			found[index] = int(found.get(index, 0)) + 1
			var sprite := child as Sprite2D
			var rect := Rect2(sprite.position, sprite.texture.get_size() * sprite.scale)
			var inside := false
			for bridge: Rect2i in BRIDGES:
				if Rect2(Vector2(bridge.position * 96), Vector2(bridge.size * 96)).encloses(
						rect.grow(-0.5)):
					inside = true
			assert_true(inside, "%s dans un pont" % name)
	assert_eq(found.size(), 3, "trois ponts")
	var widths: Array[int] = []
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if String(child.name).ends_with("_00") and String(child.name).begins_with("Pont"):
			var sprite := child as Sprite2D
			widths.append(roundi(sprite.texture.get_size().x * sprite.scale.x / 96.0))
	widths.sort()
	assert_eq(widths, [2, 3, 4] as Array[int], "pont central 3, Arène 2, ouest 4 de long")


func test_west_and_north_edges_lead_to_the_routes() -> void:
	for i: int in 3:
		var west := _map.get_warps().find_on_push(WEST[i], Vector2i.LEFT)
		assert_not_null(west, "raccord ouest %s" % WEST[i])
		if west != null:
			assert_false(west.is_coming_soon())
			assert_eq([west.target_map, west.target_spawn, west.facing],
				[&"route_4", StringName("from_cerulean_" + ["n", "c", "s"][i]), Vector2i.LEFT])
		assert_eq(_map.get_spawn_cell(StringName("from_route_4_" + ["n", "c", "s"][i])), WEST[i])
		var north := _map.get_warps().find_on_push(NORTH[i], Vector2i.UP)
		assert_not_null(north, "raccord nord %s" % NORTH[i])
		if north != null:
			assert_eq([north.target_map, north.target_spawn, north.facing],
				[&"route_24", StringName("from_cerulean_" + ["w", "c", "e"][i]), Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName("from_route_24_" + ["w", "c", "e"][i])),
			NORTH[i])


func test_building_doors_lead_inside() -> void:
	var count := 0
	for entry: Array in BUILDINGS:
		var doors := _plan.cells_at(entry[0])
		assert_eq(_map.get_spawn_cell(entry[4]), doors[-1] + Vector2i.DOWN, String(entry[4]))
		for door: Vector2i in doors:
			count += 1
			assert_false(_grid.is_solid(door), "porte %s franchissable" % door)
			var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
			assert_not_null(warp, "porte %s (STEP_ON ↑)" % door)
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], [entry[3], &"entrance"])
		var building := _map.get_node_or_null(NodePath("Entities/" + entry[1])) as WorldProp
		assert_not_null(building, entry[1])
		if building != null:
			assert_eq(building.scene_file_path.get_file().get_basename(), entry[2])
	assert_eq(count, _plan.cells_of("D").size(), "toutes les portes de la grille")
	assert_eq(_map.get_warps().size(), count + 6, "portes + raccords ouest et nord, rien d'autre")


func test_east_and_south_are_closed_without_any_warp() -> void:
	for cell: Vector2i in _plan.cells_at("barriere_est") + _plan.cells_at("barriere_sud"):
		assert_true(_grid.is_solid(cell), "barrière %s" % cell)
		for direction: Vector2i in GridPaths.DIRECTIONS:
			assert_null(_map.get_warps().find_on_push(cell, direction))
			assert_null(_map.get_warps().find_on_step(cell, direction))
	for y: int in SIZE.y:
		assert_false(_plan.is_walkable(Vector2i(SIZE.x - 1, y)), "bord est fermé (%d)" % y)
	for x: int in SIZE.x:
		assert_false(_plan.is_walkable(Vector2i(x, SIZE.y - 1)), "bord sud fermé (%d)" % x)
	for warp: Warp in _map.get_warps().get_all():
		assert_true(warp.cell.x < SIZE.x - 1 and warp.cell.y < SIZE.y - 2,
			"aucun warp à l'est ni au sud (%s)" % warp.cell)
	# T17 : deux déclencheurs d'arrivée (ouest 3 cases, nord 3 cases) ; deux panneaux et quatre
	# examens (porte, clôture, barrière est × 3, barrière sud × 5).
	assert_eq(_map.get_triggers().size(), 6, "arrivée : 3 cases à l'ouest, 3 au nord")
	assert_eq(_map.get_interactions().size(), 2 + 1 + 1 + 3 + 5, "panneaux et examens")


func test_reserved_cells_are_free_or_blocked_as_planned() -> void:
	for id: String in _plan.positions:
		var kind: String = _plan.positions[id]["kind"]
		for cell: Vector2i in _plan.cells_at(id):
			match kind:
				"pnj":
					assert_false(_grid.is_solid(cell), "%s : case de l'habitant libre" % id)
				"examen", "indice", "decor", "repere":
					assert_true(_grid.is_solid(cell) or _grid.is_water(cell),
						"%s : case bloquée" % id)


func test_the_center_is_the_first_building_of_the_avenue() -> void:
	var dist := GridPaths.distances(_terrain, WEST, _doors())
	var center: int = mini(int(dist[Vector2i(8, 18)]), int(dist[Vector2i(9, 18)]))
	for entry: Array in BUILDINGS:
		if entry[0] == "porte_centre":
			continue
		for door: Vector2i in _plan.cells_at(entry[0]):
			assert_lt(center, int(dist[door]), "Centre avant %s" % entry[0])
	# Le Centre est dans le premier écran (arrivée en (1, 20)).
	var rect := Rect2(_map.get_pixel_rect())
	var centre := Vector2(1.5, 20.5) * 96.0
	centre.x = clampf(centre.x, rect.position.x + VIEW.x / 2.0, rect.end.x - VIEW.x / 2.0)
	centre.y = clampf(centre.y, rect.position.y + VIEW.y / 2.0, rect.end.y - VIEW.y / 2.0)
	assert_true(Rect2(centre - VIEW / 2.0, VIEW).has_point(Vector2(9.0, 18.5) * 96.0),
		"porte du Centre à l'écran dès l'arrivée")
	# Avenue : la première rue ne part qu'en x 14..16.
	for x: int in range(0, 14):
		assert_false(_terrain.is_solid(Vector2i(x, 20)))
	for y: int in range(12, 19):
		assert_true(_terrain.is_solid(Vector2i(13, y)), "pas de rue avant x 14 (%d)" % y)


func test_every_place_is_reachable_and_the_bridges_matter() -> void:
	var open := GridPaths.distances(_terrain, WEST, _doors())
	for door: Vector2i in _plan.cells_of("D"):
		assert_true(open.has(door), "porte %s atteignable" % door)
	for cell: Vector2i in NORTH:
		assert_true(open.has(cell), "sortie nord %s atteignable" % cell)
	for cell: Vector2i in _plan.cells_of("KAfjyaMmCOZVws"):
		assert_false(open.has(cell), "%s inatteignable" % cell)
	var cut := GridPaths.relief(_terrain, SIZE)
	for bridge: Rect2i in BRIDGES:
		for y: int in range(bridge.position.y, bridge.end.y):
			for x: int in range(bridge.position.x, bridge.end.x):
				cut.set_solid(Vector2i(x, y))
	var without := GridPaths.distances(cut, WEST, _doors())
	assert_false(without.has(Vector2i(40, 9)), "sans pont, l'Arène est de l'autre côté")
	for cell: Vector2i in NORTH:
		assert_false(without.has(cell), "sans pont, la sortie nord est coupée")
	# Un seul pont suffit à l'Arène : le central ou celui de l'Arène (deux routes).
	for kept: Rect2i in [BRIDGES[0], BRIDGES[1]]:
		var one := GridPaths.relief(cut, SIZE)
		for y: int in range(kept.position.y, kept.end.y):
			for x: int in range(kept.position.x, kept.end.x):
				one.set_solid(Vector2i(x, y), false)
		assert_true(GridPaths.distances(one, WEST, _doors()).has(Vector2i(40, 9)))


func test_props_never_block_a_walkable_cell() -> void:
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or _signs.has(cell),
					"%s bloque la case praticable %s" % [prop.name, cell])


func test_quay_modules_never_cover_a_walkable_cell() -> void:
	var count := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if not String(child.name).begins_with("Quai"):
			continue
		count += 1
		var sprite := child as Sprite2D
		var rect := Rect2(sprite.position, sprite.texture.get_size() * sprite.scale)
		var first := Vector2i((rect.position / 96.0).floor())
		var last := Vector2i(((rect.end - Vector2.ONE * 0.5) / 96.0).floor())
		for y: int in range(first.y, last.y + 1):
			for x: int in range(first.x, last.x + 1):
				assert_false(_plan.is_walkable(Vector2i(x, y)), "%s sur %s" % [child.name,
					Vector2i(x, y)])
	assert_gt(count, 40, "quais posés")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("cerulean_city : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds")
