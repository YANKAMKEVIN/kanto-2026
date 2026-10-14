extends GutTest
## La vraie Route 4, carte `route_4` (jalon 13 T8, docs/tech/jalon-13.md §2.1, §2.2, §2.18 ;
## dossier 16 §3) sur la vraie scène : métadonnées, **grille de la scène = grille fonctionnelle**
## `tools/plans/route_4.txt` case par case (solide, hautes herbes, rebord), bouche de la grotte vers
## B2F (carte du J12), point d'arrivée (3, 6) gardé, raccord est vers Azuria (`cerulean_city`, un
## spawn par rangée), rebord à sens unique vers le sud (unique descente, ne se monte pas), trois
## zones d'herbes (H1 et H3 évitables, H2 obligatoire sur 4 cases), Dresseuse et objet **absents**
## mais leurs cases réservées (T17), rebord et versant en roche ardoise, budget de nœuds.
## Vie du sas gardée (J12 T28) : panneau examinable et déclencheur `route_4_reached` (4, 5..9).
## La reprise du sas : `test_route_4_resume`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_4.tscn"
const PLAN_PATH := "res://tools/plans/route_4.txt"
const SIZE := Vector2i(64, 24)
const MOUTH := Vector2i(2, 6)
const ARRIVAL := Vector2i(3, 6)
const EAST: Array[Vector2i] = [Vector2i(63, 19), Vector2i(63, 20), Vector2i(63, 21)]
const NODE_BUDGET := 3000
const INF := 1 << 30

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief seul, plus les positions `bloque` de la grille (Dresseuse, objet, panneau).
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


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


func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_4", "même identifiant que le sas")
	assert_eq(_map.display_name, "Route 4")
	assert_eq(_map.region, "Mont Sélénite — Azuria", "sous-titre du J12, inchangé")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_4"), &"route_4")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_battle_decor_is_the_plain() -> void:
	var decor := BattleDecorCatalog.load_file().pick(&"route_4", Vector2i(40, 20))
	assert_not_null(decor, "décor de combat de la Route 4")
	if decor != null:
		assert_eq(decor.id, &"route_4_plaine")


func test_scene_grid_is_the_functional_grid() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_route_4")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or sign.has(cell)
			var ledge := GridWorld.Ledge.DOWN if mark == "v" else GridWorld.Ledge.NONE
			var ok := _grid.is_solid(cell) == solid \
				and _grid.is_tall_grass(cell) == (mark == "h") and _grid.get_ledge(cell) == ledge
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, herbes %s, rebord %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_tall_grass(cell), _grid.get_ledge(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_4.txt")
	assert_eq(_plan.walkable, ".=hvDe")


func test_mouth_leads_to_b2f_and_the_arrival_is_kept() -> void:
	var warp := _map.get_warps().find_on_step(MOUTH, Vector2i.LEFT)
	assert_not_null(warp, "bouche de la grotte (STEP_ON ←)")
	if warp != null:
		assert_eq([warp.target_map, warp.target_spawn, warp.facing], [&"mt_moon_b2f",
			&"arrivee_s", Vector2i.DOWN])
	assert_eq(_map.get_spawn_cell(&"from_mt_moon"), ARRIVAL, "point d'arrivée (3, 6)")
	assert_eq(_plan.cell_of("from_mt_moon"), ARRIVAL)
	assert_false(_grid.is_solid(ARRIVAL))
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
		assert_true(_grid.is_solid(MOUTH + side), "paroi autour de la bouche (%s)" % side)


func test_east_edge_leads_to_azuria_one_spawn_per_row() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in EAST.size():
		var warp := _map.get_warps().find_on_push(EAST[i], Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % EAST[i])
		if warp == null:
			continue
		assert_false(warp.is_coming_soon(), "plus de « AZURIA — À venir »")
		assert_eq([warp.target_map, warp.target_spawn, warp.facing],
			[&"cerulean_city", StringName("from_route_4_" + suffixes[i]), Vector2i.RIGHT])
		assert_eq(_map.get_spawn_cell(StringName("from_cerulean_" + suffixes[i])), EAST[i],
			"retour sur la rangée")
	assert_eq(_map.get_warps().size(), 1 + EAST.size(), "bouche + trois cases de raccord")
	assert_eq(_plan.cells_at("raccord_est"), EAST)


func test_everything_walkable_is_reachable_and_closed() -> void:
	var dist := GridPaths.distances(_grid, [ARRIVAL])
	for cell: Vector2i in _plan.cells_of(_plan.walkable):
		if cell == _plan.cell_of("route_4_item_1") or cell == _plan.cell_of("clara"):
			# La Poké Ball et Clara (T17) occupent leur case ; on la ramasse depuis une case voisine.
			assert_true(dist.has(cell + Vector2i.UP), "Poké Ball : case voisine atteignable")
		elif not _plan.cells_at("panneau_route_4").has(cell) and _plan.at(cell) != "v":
			assert_true(dist.has(cell), "%s atteignable" % cell)
	for cell: Vector2i in dist:
		assert_true(_plan.is_walkable(cell), "%s fermé par la grille" % cell)


func test_the_ledge_is_the_only_way_down_and_never_climbs() -> void:
	var cells: Array[Vector2i] = _plan.cells_of("v")
	assert_eq(cells.size(), 6, "une seule bande de 6 cases (28..33, 12)")
	for cell: Vector2i in cells:
		assert_eq(cell.y, 12)
		assert_eq(_grid.get_step_target(cell + Vector2i.DOWN, Vector2i.UP),
			cell + Vector2i.DOWN, "rebord %s : ne se monte pas" % cell)
		assert_eq(_grid.get_step_target(cell + Vector2i.UP, Vector2i.DOWN),
			cell + Vector2i.DOWN, "rebord %s : sauté vers le sud (palier en rangée 13)" % cell)
	# Plateau → plaine : oui ; plaine → plateau : non (retour par le Mont Sélénite seulement).
	var down := GridPaths.distances(_grid, [ARRIVAL])
	assert_true(down.has(EAST[0]), "du plateau on rejoint la rue d'Azuria")
	var up := GridPaths.distances(_grid, [EAST[0]])
	assert_false(up.has(ARRIVAL), "de la plaine on ne remonte pas vers la grotte")
	assert_false(up.has(Vector2i(30, 11)), "ni sur le plateau")


func test_tall_grass_h2_is_mandatory_h1_h3_avoidable() -> void:
	var start: Array[Vector2i] = [ARRIVAL]
	var goal: Array[Vector2i] = [EAST[0], EAST[1], EAST[2]]
	var h2 := _grass_zone("h2")
	assert_eq(GridPaths.min_crossed(_terrain, start, goal, h2), 4, "H2 : 4 cases obligatoires")
	assert_eq(GridPaths.min_crossed(_terrain, start, goal, _grass_zone("h1")), 0, "H1 évitable")
	assert_eq(GridPaths.min_crossed(_terrain, start, goal, _grass_zone("h3")), 0, "H3 évitable")
	var all: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("h"):
		all[cell] = true
	assert_eq(all.size(), 18 + 12 + 18, "H1 (6 × 3), H2 (4 × 3), H3 (6 × 3)")


func test_clara_is_avoidable_by_rows_21_and_22_and_her_cell_is_reserved() -> void:
	var clara := _plan.cell_of("clara")
	assert_eq(clara, Vector2i(44, 17))
	assert_eq(_plan.attr("clara", "facing"), "down")
	var seen: Array[Vector2i] = []
	for k: int in range(1, int(_plan.attr("clara", "sight")) + 1):
		var cell := clara + Vector2i.DOWN * k
		if _terrain.is_solid(cell):
			break
		seen.append(cell)
	assert_eq(seen.size(), 3, "vue de 3 cases (44, 18..20)")
	var counted: Dictionary = {}
	for cell: Vector2i in seen:
		counted[cell] = true
	# La rue y 19..21 : les rangées 21 (et 22 hors rue) sont hors de sa vue ; la rue entière
	# n'est pas obligée de la croiser : on passe par la rangée 21.
	var goal: Array[Vector2i] = [EAST[0], EAST[1], EAST[2]]
	assert_eq(GridPaths.min_crossed(_terrain, [ARRIVAL], goal, counted), 0, "Clara évitable")
	assert_false(_grid.is_solid(clara), "carte seule : les PNJ (Clara, T17) se posent au jeu")
	assert_false(_grid.is_solid(_plan.cell_of("route_4_item_1")), "la Poké Ball est un PNJ-objet")


func test_nothing_lives_here_yet() -> void:
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 1, "route_4_reached (J12 T28)")
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 1, "panneau (J12 T28)")
	var roster := NpcRoster.load_for_map(&"route_4")
	var ids: Array[String] = []
	for spec: NpcSpec in roster.get_all():
		ids.append(String(spec.id))
	assert_eq(ids, ["route_4_ball_1", "route_4_clara"] as Array[String],
		"la Poké Ball et Clara (T17)")
	assert_not_null(_map.get_node_or_null(^"Entities/SignRoute4"), "panneau (décor)")
	assert_not_null(_map.get_node_or_null(^"GroundDecals/CaveMouth"), "bouche de la grotte")
	# Cases réservées : aucune forêt, aucun buisson, aucun décor solide sur Clara, la Poké Ball et
	# les herbes.
	for id: String in ["clara", "route_4_item_1"]:
		assert_true(_plan.is_walkable(_plan.cell_of(id)), "%s : case praticable libre" % id)


func test_ledge_and_cliff_are_slate_and_clean() -> void:
	var decals := _map.get_node(^"GroundDecals")
	var ledge := 0
	var cliff := 0
	for child: Node in decals.get_children():
		var texture := _texture_name(child)
		if child.name.begins_with("Ledge"):
			ledge += 1
			assert_eq(texture, "relief_rebord_ardoise_01", "rebord en roche ardoise, sans planche")
		elif child.name.begins_with("Cliff"):
			cliff += 1
			assert_true(texture.begins_with("relief_falaise_ardoise_"), texture)
	assert_eq(ledge, 4, "4 modules bout à bout sur les 6 cases du rebord")
	assert_eq(cliff, 7, "versant (3..27, 12..13)")
	# Aucune planche : aucun module de bois ni de falaise brune dans la couche du sol.
	for child: Node in decals.get_children():
		assert_ne(_texture_name(child), "relief_falaise_01", "pas de falaise brune")
		assert_ne(_texture_name(child), "relief_rebord_01", "pas de rebord de terre")


func _texture_name(node: Node) -> String:
	var sprite := node as Sprite2D
	if sprite == null:
		sprite = node.get_node_or_null(^"Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path.get_file().get_basename()


func test_props_never_block_a_walkable_cell() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_route_4")
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or sign.has(cell),
					"%s bloque la case praticable %s" % [prop.name, cell])


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("route_4 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)


## T28 (§2.15, dossier 15 §20 n° 36) : panneau lu de face, depuis la case au sud.
func test_sign_is_read_from_the_south() -> void:
	var point := _map.get_node(^"Interactables").get_child(0) as InteractPoint
	assert_not_null(point)
	if point == null:
		return
	assert_eq(point.get_cells(), _plan.cells_at("panneau_route_4"))
	assert_eq(point.dialogue_id, &"route_4_sign")
	assert_eq(point.facing, Vector2i.UP)
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_true(dialogues.has_dialogue(&"route_4_sign"))


## T28 (§1.3 n° 5) : `route_4_reached` couvre toute la largeur du sas (colonne 4, rangées 5..9),
## toute direction ; au nord et au sud, la paroi.
func test_reached_trigger_spans_the_whole_sas() -> void:
	var trigger := _map.get_node(^"Triggers").get_child(0) as EventTriggerPoint
	assert_not_null(trigger)
	if trigger == null:
		return
	assert_eq(trigger.cutscene_id, &"route_4_reached")
	assert_eq(trigger.direction, Vector2i.ZERO, "toute direction")
	var cells := trigger.get_cells()
	assert_eq(cells.size(), 5)
	for y: int in range(5, 10):
		assert_true(cells.has(Vector2i(4, y)), "(4, %d) couverte" % y)
		assert_false(_grid.is_solid(Vector2i(4, y)), "(4, %d) praticable" % y)
	assert_true(_grid.is_solid(Vector2i(4, 4)), "paroi au nord")
	assert_true(_grid.is_solid(Vector2i(4, 10)), "paroi au sud")
	assert_false(cells.has(ARRIVAL), "l'arrivée n'est pas couverte : un pas vers l'est")
