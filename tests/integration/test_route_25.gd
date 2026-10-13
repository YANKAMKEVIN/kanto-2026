extends GutTest
## Carte route_25 (jalon 14 T14, docs/tech/jalon-14.md §1.3, §2.1, §2.2, §2.17 ; dossier 17) sur
## la vraie scène : métadonnées et lumière, mer et sable peints, **grille de la scène = grille
## fonctionnelle** `tools/plans/route_25.txt` case par case (solide, eau, hautes herbes, rebord),
## raccords (Route 24 provisoire « à venir », maison de Léo), critères de
## `tools/art/plan_check_route_25.py` refaits sur la vraie grille (positions `bloque` en plus,
## porte terminale) : D1 / D2 inévitables par géométrie, D3 à D6 évitables, H3 incontournable,
## rebord, chemin ; cases réservées (T16, T17) libres de tout décor ; rivage rocheux ; budget de
## nœuds. Sans déclencheurs ; la vie (PNJ, objets, rencontres) : `test_route_25_trainers`,
## `test_route_25_life`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_25.tscn"
const PLAN_PATH := "res://tools/plans/route_25.txt"
const SIZE := Vector2i(80, 28)
const WEST := [Vector2i(0, 13), Vector2i(0, 14), Vector2i(0, 15)]
const DOORS := [Vector2i(71, 11), Vector2i(72, 11)]
const NODE_BUDGET := 3000
const INF := 1 << 30
const SHORE_PREFIX := "relief_rivage_"

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (Dresseurs, PNJ, objets, panneaux).
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
	for cell: Vector2i in DOORS:
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

func test_metadata_light_zone_and_painted_coast() -> void:
	assert_eq(_map.map_id, &"route_25")
	assert_eq(_map.display_name, "Route 25")
	assert_eq(_map.region, "Azuria — Cap d'Azuria")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_25"), &"golden_hour", "au plan de lumière")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_25"), &"route_25")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
		assert_not_null(ground.shore_mask, "rivage (sable et mer)")
		assert_true(ground.square_shore, "mer à angles droits")
		assert_null(ground.water_texture, "la mer de Bourg Palette (texture par défaut)")
		assert_eq(ground.foam_strength, PaintedGround.DEFAULT_FOAM_STRENGTH,
			"écume de Bourg Palette")
		var shore := ground.shore_mask.get_image()
		assert_eq(GroundMask.shore_at(shore, Vector2i(10, 23)), GroundMask.Kind.WATER)
		assert_eq(GroundMask.shore_at(shore, Vector2i(38, 18)), GroundMask.Kind.SAND)
		assert_eq(GroundMask.shore_at(shore, Vector2i(10, 14)), GroundMask.Kind.GRASS)
		assert_eq(GroundMask.kind_at(ground.mask.get_image(), Vector2i(10, 14)),
			GroundMask.Kind.PATH)
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


# --- Grille ------------------------------------------------------------------------------

func test_scene_grid_is_the_functional_grid() -> void:
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ouest") + _plan.cells_at(
		"panneau_cap")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			# L'eau n'est pas « solide » : un drapeau à part (`is_water`) qui ferme la case (un
			# rocher posé dans l'eau la rend aussi solide : non comparé).
			var solid := not _plan.is_walkable(cell) or signs.has(cell)
			var ledge := GridWorld.Ledge.DOWN if mark == "v" else GridWorld.Ledge.NONE
			var ok := (mark == "w" or _grid.is_solid(cell) == solid) \
				and _grid.is_tall_grass(cell) == (mark == "h") \
				and _grid.is_water(cell) == (mark == "w") and _grid.get_ledge(cell) == ledge
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s, herbes %s, rebord %s" % [
						cell, mark, _grid.is_solid(cell), _grid.is_water(cell),
						_grid.is_tall_grass(cell), _grid.get_ledge(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_25.txt")
	assert_eq(_plan.walkable, ".=hvsD")


func test_sand_is_walkable_and_sea_is_not() -> void:
	for cell: Vector2i in _plan.cells_of("s"):
		assert_false(_grid.is_solid(cell), "sable %s praticable" % cell)
	for cell: Vector2i in _plan.cells_of("w"):
		assert_true(_grid.is_water(cell), "mer %s : eau" % cell)
		for side: Vector2i in GridPaths.DIRECTIONS:
			var from := cell - side
			if _grid.is_in_bounds(from) and not _grid.is_solid(from):
				assert_false(_grid.can_enter(from, side), "mer %s fermée depuis %s" % [cell, from])


# --- Passages ----------------------------------------------------------------------------

func test_west_edge_is_a_provisional_coming_soon_to_route_24() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in WEST.size():
		var cell: Vector2i = WEST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "raccord ouest %s" % cell)
		if warp != null:
			assert_true(warp.is_coming_soon(), "« Route 24 — À venir » tant que T15 n'est pas là")
			assert_eq(warp.coming_soon, "Route 24")
			assert_eq(warp.target_spawn, StringName("from_route_24_" + suffixes[i]))
		assert_eq(_map.get_spawn_cell(StringName("from_route_24_" + suffixes[i])), cell)
		assert_false(_grid.is_solid(cell))


func test_leo_door_leads_into_the_house() -> void:
	var fronts := ["from_bill_house_w", "from_bill_house_e"]
	for i: int in DOORS.size():
		var cell: Vector2i = DOORS[i]
		assert_false(_grid.is_solid(cell), "%s praticable" % cell)
		var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "passage STEP_ON ↑ en %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"bill_house", &"from_route_25", Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName(fronts[i])), cell + Vector2i.DOWN)
	assert_eq(_map.get_warps().size(), 5, "trois raccords ouest et deux portes")


func test_no_trigger_and_three_examine_points() -> void:
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0, "aucun déclencheur")
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 3,
		"deux panneaux et le rocher au coquillage (T16)")


# --- Critères (plan_check_route_25.py) ---------------------------------------------------

func test_entrance_reaches_leo_in_range() -> void:
	var dist := _reach(_terrain)
	var door := _nearest(dist, DOORS)
	assert_lt(door, INF, "porte de la maison atteignable")
	gut.p("route_25 : chemin principal %d pas" % door)
	assert_between(door, 70, 110, "longueur du chemin principal")


func test_d1_and_d2_cannot_be_avoided() -> void:
	for id: String in ["d1", "d2"]:
		var sight := _sight(id)
		assert_eq(sight.size(), int(_plan.attr(id, "sight")), "%s : vue dégagée" % id)
		assert_eq(_nearest(_reach(_without(sight)), DOORS), INF, "%s inévitable" % id)


func test_other_trainers_can_be_avoided_together() -> void:
	var seen: Array[Vector2i] = []
	for id: String in ["d3", "d4", "d5", "d6"]:
		var sight := _sight(id)
		assert_gt(sight.size(), 0, "%s voit devant lui" % id)
		assert_lt(_nearest(_reach(_without(sight)), DOORS), INF, "%s évitable" % id)
		seen.append_array(sight)
	assert_lt(_nearest(_reach(_without(seen)), DOORS), INF, "D3 à D6 évitables ensemble")


func test_ledge_jumps_south_and_never_climbs() -> void:
	for cell: Vector2i in _plan.cells_of("v"):
		assert_eq(_grid.get_step_target(cell + Vector2i.DOWN, Vector2i.UP),
			cell + Vector2i.DOWN, "rebord %s : ne se monte pas" % cell)
		if not _grid.is_solid(cell + Vector2i.UP):
			assert_eq(_grid.get_step_target(cell + Vector2i.UP, Vector2i.DOWN),
				cell + Vector2i.DOWN, "rebord %s : sauté vers le sud" % cell)


func test_tall_grass_h3_is_mandatory_others_avoidable() -> void:
	var door := DOORS
	assert_gt(GridPaths.min_crossed(_terrain, WEST, door, _grass_zone("h3")), 0, "H3 incontournable")
	for zone: String in ["h1", "h2", "h4"]:
		assert_eq(GridPaths.min_crossed(_terrain, WEST, door, _grass_zone(zone)), 0,
			"%s évitable" % zone)
	var crossed := GridPaths.min_crossed(_terrain, WEST, door, _all_grass())
	assert_between(crossed, 3, 6, "cases d'herbes obligatoires")


func test_hidden_item_clue_is_examinable_from_the_north() -> void:
	var clue := _plan.cell_of("route_25_hidden_1")
	assert_eq(clue, Vector2i(64, 20))
	assert_true(_reach(_terrain).has(clue + Vector2i.UP), "indice examinable depuis (64, 19)")


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
		"panneau_cap")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(not _plan.is_walkable(cell) or signs.has(cell),
				"%s bloque la case praticable %s" % [prop.name, cell])


func test_reserved_cells_stay_free_for_t16_t17() -> void:
	var kinds := ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
	var reserved: Dictionary = {}
	for id: String in _plan.positions:
		if kinds.has(_plan.positions[id]["kind"]):
			for cell: Vector2i in _plan.cells_at(id):
				reserved[cell] = true
	assert_eq(reserved.size(), 14, "6 Dresseurs, 2 PNJ, 2 Pokémon, 3 objets, 1 caché")
	for prop: WorldProp in _props():
		for cell: Vector2i in prop.get_solid_cells():
			var perch := _plan.at(cell) in ["R", "x"]
			assert_false(reserved.has(cell) and not perch,
				"%s sur la case réservée %s" % [prop.name, cell])
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("Forest"):
			var foot := Vector2i(((child as Node2D).position - Vector2(0, 1)) / Grid.TILE_SIZE)
			assert_false(reserved.has(foot), "%s sur la case réservée %s" % [child.name, foot])


func test_house_stands_between_two_flower_beds() -> void:
	var house := _map.get_node_or_null(^"Entities/LeoHouse") as WorldProp
	assert_not_null(house, "maison de Léo")
	if house != null:
		var solid := house.get_solid_cells()
		assert_eq(solid.size(), 8 * 6 - 2, "8 × 6 moins la porte")
		assert_false(solid.has(Vector2i(71, 11)) or solid.has(Vector2i(72, 11)), "porte libre")
		for cell: Vector2i in solid:
			assert_eq(_plan.at(cell), "M", "emprise sur les cases M (%s)" % cell)
	var beds := 0
	for child: Node in _map.get_entities().get_children():
		if String(child.name).begins_with("FlowerBed"):
			beds += 1
	assert_eq(beds, _plan.cells_of("f").size(), "un massif par case f")


func test_shore_modules_only_on_rock_cells_touching_the_sea() -> void:
	var count := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		var id := child.scene_file_path.get_file().get_basename()
		if child is Sprite2D and String((child as Sprite2D).texture.resource_path).contains(
				SHORE_PREFIX):
			count += 1
			var sprite := child as Sprite2D
			var rect := Rect2(sprite.position, sprite.texture.get_size() * sprite.scale)
			# Le haut peut déborder d'un cinquième de case sur la case du nord (roche qui chevauche).
			var inner := rect.grow_individual(0.0, -Grid.TILE_SIZE * 0.2, 0.0, 0.0)
			var first := Vector2i((inner.position / Grid.TILE_SIZE).floor())
			var last := Vector2i(((inner.end - Vector2.ONE * 0.5) / Grid.TILE_SIZE).floor())
			for y: int in range(first.y, last.y + 1):
				for x: int in range(first.x, last.x + 1):
					assert_eq(_plan.at(Vector2i(x, y)), "R",
						"%s : module du rivage sur une case R (%d, %d) %s" % [child.name, x, y, id])
	assert_gt(count, 60, "rivage rocheux posé")


func test_sand_has_no_shore_module() -> void:
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if child is Sprite2D and String((child as Sprite2D).texture.resource_path).contains(
				SHORE_PREFIX):
			var sprite := child as Sprite2D
			var rect := Rect2(sprite.position, sprite.texture.get_size() * sprite.scale)
			for cell: Vector2i in _plan.cells_of("s"):
				var cell_rect := Rect2(Vector2(cell * Grid.TILE_SIZE), Vector2.ONE * Grid.TILE_SIZE)
				# Le haut d'un module peut déborder d'un cinquième de case (roche qui chevauche).
				assert_false(rect.grow_individual(-4.0, -Grid.TILE_SIZE * 0.2, -4.0,
					-4.0).intersects(cell_rect),
					"%s recouvre le sable %s" % [child.name, cell])


func test_cliff_and_pillars_are_series_12_walls() -> void:
	var walls := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		var id := child.scene_file_path.get_file().get_basename()
		if id.begins_with("relief_paroi_0"):
			walls += 1
	assert_gt(walls, 40, "falaise du nord et piliers en modules de paroi")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_25 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds (budget du J9)")
