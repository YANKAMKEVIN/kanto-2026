extends GutTest
## Carte pewter_city (Argenta, jalon 10 T11, docs/tech/jalon-10.md §1.3, §2.1 ; dossier 12 §4–§9) :
## métadonnées et lumière, **grille de la scène = grille fonctionnelle** `tools/plans/argenta.txt`
## case par case, raccord avec la Route 2 nord, sortie est « ROUTE 3 — À venir », portes des
## bâtiments (intérieurs du T13, « à venir » tant qu'ils n'existent pas), déclencheurs de
## l'arrivée et du garde, panneaux, critères de `tools/art/plan_check_argenta.py` refaits sur la
## vraie scène (portes atteignables, Musée dans le cadre de l'arrivée, passage est), objets peints
## sur des cases bloquées, budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/pewter_city.tscn"
const PLAN_PATH := "res://tools/plans/argenta.txt"
const WALKABLE := ".=hvDp"
const SIZE := Vector2i(52, 44)
const SOUTH := [Vector2i(17, 43), Vector2i(18, 43), Vector2i(19, 43)]
const EAST := [Vector2i(51, 25), Vector2i(51, 26), Vector2i(51, 27)]
const NODE_BUDGET := 3000
## Vue du S24 en pixels monde (2340 × 1080 affichés, référence 1080 de haut, zoom 1).
const VIEW := Vector2(2340.0, 1080.0)
## Part minimale de l'emprise du Musée dans le cadre à l'arrivée (plan_check_argenta.py).
const MUSEUM_SHARE := 1.0 / 3.0
## [position des portes, nœud du bâtiment, objet peint, intérieur, spawn devant la porte,
## libellé « à venir »].
const BUILDINGS: Array = [
	["porte_musee", "Museum", "bldg_musee_argenta_01", &"pewter_museum", &"from_museum",
		"Musée d'Argenta"],
	["porte_arene", "Gym", "bldg_arene_argenta_01", &"pewter_gym", &"from_gym",
		"Arène d'Argenta"],
	["porte_centre", "PokemonCenter", "bldg_centre_01", &"pewter_center", &"from_center",
		"Centre Pokémon"],
	["porte_boutique", "PokeMart", "bldg_boutique_01", &"pewter_mart", &"from_mart", "Boutique"],
	["porte_tailleur", "HouseMason", "bldg_maison_argenta_01", &"pewter_house_mason",
		&"from_house_mason", "Maison"],
	["porte_chercheuse", "HouseResearcher", "bldg_maison_argenta_01",
		&"pewter_house_researcher", &"from_house_researcher", "Maison"],
]
const SIGNS: Array = [
	["panneau_ville", &"pewter_city_sign", Vector2i.LEFT],
	["panneau_arene", &"pewter_gym_sign", Vector2i.UP],
	["panneau_musee", &"pewter_museum_sign", Vector2i.UP],
]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
var _terrain: GridWorld
var _signs: Array[Vector2i] = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_plan.walkable = WALKABLE
	for entry: Array in SIGNS:
		_signs.append(_plan.cell_of(entry[0]))
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


func _doors() -> Dictionary:
	var doors: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("D"):
		doors[cell] = true
	return doors


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"pewter_city")
	assert_eq(_map.display_name, "Argenta")
	assert_eq(_map.region, "", "titre seul (arbitrage 10)")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_eq(_map.music, &"")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"pewter_city"), &"pewter_city")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		var mask := ground.mask.get_image()
		assert_eq(GroundMask.kind_at(mask, Vector2i(26, 14)), GroundMask.Kind.PAVING, "place")
		assert_eq(GroundMask.kind_at(mask, Vector2i(18, 30)), GroundMask.Kind.PATH, "avenue")
		assert_eq(GroundMask.kind_at(mask, Vector2i(26, 18)), GroundMask.Kind.GRASS,
			"îlot d'herbe sous le gros rocher")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell) or _signs.has(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/argenta.txt (aucune haute herbe)")


# --- Passages ----------------------------------------------------------------------------

func test_south_edge_leads_to_route_2_north() -> void:
	var suffixes := ["w", "c", "e"]
	for i: int in SOUTH.size():
		var cell: Vector2i = SOUTH[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie sud %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"route_2_north",
				StringName("from_pewter_" + suffixes[i]), Vector2i.DOWN])
		assert_eq(_map.get_spawn_cell(StringName("from_route_2_north_" + suffixes[i])), cell)


## Jalon 12 T8 (jalon-12.md §2.1, §2.17) : la sortie est mène à la vraie Route 3 (jusqu'au J11 :
## « ROUTE 3 — À venir ») ; les spawns d'arrivée depuis la Route 3 sont sur les mêmes cases.
func test_east_exit_leads_to_route_3() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in EAST.size():
		var cell: Vector2i = EAST[i]
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "sortie est %s" % cell)
		if warp == null:
			continue
		assert_false(warp.is_coming_soon())
		assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"route_3",
			StringName("from_pewter_" + suffixes[i]), Vector2i.RIGHT])
		assert_eq(_map.get_spawn_cell(StringName("from_route_3_" + suffixes[i])), cell,
			"arrivée de la Route 3 sur la case de sortie")


func test_building_doors_lead_inside_or_to_coming_soon() -> void:
	var count := 0
	for entry: Array in BUILDINGS:
		var doors := _plan.cells_at(entry[0])
		var front: Vector2i = doors[-1] + Vector2i.DOWN
		assert_eq(_map.get_spawn_cell(entry[4]), front, "%s : devant la porte" % entry[4])
		for door: Vector2i in doors:
			count += 1
			assert_false(_grid.is_solid(door), "porte %s franchissable" % door)
			var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
			assert_not_null(warp, "porte %s (STEP_ON ↑)" % door)
			if warp == null:
				continue
			if MapCatalog.has_map(entry[3]):
				assert_eq([warp.target_map, warp.target_spawn], [entry[3], &"entrance"])
			else:
				assert_eq([warp.coming_soon, warp.target_spawn, warp.facing],
					[entry[5], entry[4], Vector2i.DOWN], "« à venir » jusqu'au T13")
		var building := _map.get_node_or_null(NodePath("Entities/" + entry[1])) as WorldProp
		assert_not_null(building, entry[1])
		if building != null:
			assert_eq(building.scene_file_path.get_file().get_basename(), entry[2])
	assert_eq(count, _plan.cells_of("D").size(), "toutes les portes de la grille")
	assert_eq(_map.get_warps().size(), count + 7,
		"portes, raccord sud, sortie est, porte arrière du Musée (J25)")


func test_arrival_and_guard_triggers() -> void:
	for cell: Vector2i in _plan.cells_at("arrivee"):
		var trigger := _map.get_triggers().find_on_step(cell, Vector2i.UP)
		assert_not_null(trigger, "arrivée %s" % cell)
		if trigger != null:
			assert_eq(trigger.cutscene_id, &"pewter_arrival")
	for cell: Vector2i in _plan.cells_at("verrou_route_3"):
		for direction: Vector2i in GridPaths.DIRECTIONS:
			var trigger := _map.get_triggers().find_on_step(cell, direction)
			assert_not_null(trigger, "verrou %s %s" % [cell, direction])
			if trigger != null:
				assert_eq(trigger.cutscene_id, &"route_3_guard")
	assert_null(_map.get_triggers().find_on_step(Vector2i(17, 42), Vector2i.DOWN),
		"l'arrivée ne se déclenche pas en repartant")


func test_signs() -> void:
	for entry: Array in SIGNS:
		var cell := _plan.cell_of(entry[0])
		assert_true(_grid.is_solid(cell), "panneau %s bloqué" % cell)
		var point := _map.get_interactions().find(cell, entry[2])
		assert_not_null(point, "panneau %s lu %s" % [cell, entry[2]])
		if point != null:
			assert_eq(point.dialogue_id, entry[1])


# --- Critères (plan_check_argenta.py) ----------------------------------------------------

func test_every_door_is_reachable_from_the_south_entrance() -> void:
	var dist := GridPaths.distances(_terrain, SOUTH, _doors())
	for door: Vector2i in _plan.cells_of("D"):
		assert_true(dist.has(door), "porte %s atteignable" % door)
	for cell: Vector2i in _plan.cells_at("verrou_route_3"):
		assert_true(dist.has(cell), "passage est %s atteignable" % cell)


func test_the_east_passage_is_the_only_way_to_the_east_exit() -> void:
	var open := GridPaths.distances(_terrain, SOUTH, _doors())
	for cell: Vector2i in EAST:
		assert_true(open.has(cell), "sortie est %s atteignable" % cell)
	var closed := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in _plan.cells_at("verrou_route_3"):
		closed.set_solid(cell)
	var cut := GridPaths.distances(closed, SOUTH, _doors())
	for cell: Vector2i in EAST:
		assert_false(cut.has(cell), "sans le passage (48, 25..27), %s inaccessible" % cell)


func test_the_museum_is_in_the_arrival_frame() -> void:
	# Caméra centrée sur le joueur (pied au bas de sa case, comme CameraFraming) puis bornée.
	var rect := Rect2(_map.get_pixel_rect())
	var museum := Rect2(Vector2(3, 31) * Grid.TILE_SIZE, Vector2(12, 9) * Grid.TILE_SIZE)
	for start: Vector2i in [_map.get_spawn_cell(&"from_route_2_north_c"), Vector2i(18, 42)]:
		var centre := Vector2(start.x + 0.5, start.y + 0.5) * Grid.TILE_SIZE
		centre.x = clampf(centre.x, rect.position.x + VIEW.x / 2.0, rect.end.x - VIEW.x / 2.0)
		centre.y = clampf(centre.y, rect.position.y + VIEW.y / 2.0, rect.end.y - VIEW.y / 2.0)
		var frame := Rect2(centre - VIEW / 2.0, VIEW)
		var share := frame.intersection(museum).get_area() / museum.get_area()
		gut.p("Musée dans le cadre depuis %s : %d %%" % [start, roundi(share * 100.0)])
		assert_gte(share, MUSEUM_SHARE, "Musée visible dès le premier écran (%s)" % start)
		var door := Vector2(8.5, 39.5) * Grid.TILE_SIZE
		assert_true(frame.has_point(door), "porte du Musée à l'écran")


func test_routines_stay_off_doors_and_signs() -> void:
	var forbidden: Dictionary = {}
	for door: Vector2i in _plan.cells_of("D"):
		forbidden[door] = true
		forbidden[door + Vector2i.DOWN] = true
	for cell: Vector2i in _signs:
		forbidden[cell] = true
	for spec: NpcSpec in NpcRoster.load_for_map(&"pewter_city").get_all():
		var cells: Array[Vector2i] = spec.route_cells.duplicate()
		cells.append(spec.cell)
		for cell: Vector2i in cells:
			assert_false(forbidden.has(cell), "%s : %s sur une porte ou un panneau" % [spec.id,
				cell])


# --- Objets peints et budget -------------------------------------------------------------

func test_props_never_block_a_walkable_cell() -> void:
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or _signs.has(cell),
					"%s bloque la case praticable %s" % [prop.name, cell])


func test_town_trees_never_repeat_side_by_side() -> void:
	var trees: Dictionary = {}
	for child: Node in _map.get_node(^"Entities").get_children():
		if String(child.name).begins_with("Tree"):
			trees[(child as WorldProp).get_anchor_cell()] = child.scene_file_path
	assert_eq(trees.size(), _plan.cells_of("G").size(), "un arbre par case G")
	for cell: Vector2i in trees:
		assert_eq(_plan.at(cell), "G", "arbre sur une case G (%s)" % cell)
		for side: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if trees.has(cell + side):
				assert_ne(trees[cell], trees[cell + side], "deux fois le même arbre en %s" % cell)


func test_inhabitants_are_placed() -> void:
	for id: StringName in [&"stonemason", &"stonemason_geodude", &"kid", &"visitor", &"old_man",
			&"lass", &"museum_clerk", &"route_3_guard"]:
		assert_not_null(_map.get_npc(id), String(id))
	assert_null(_map.get_npc(&"route_3_guard_aside"), "garde décalé seulement après le badge")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("pewter_city : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds (budget du J9)")
