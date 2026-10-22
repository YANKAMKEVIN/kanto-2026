extends GutTest
## Carte celadon_city (Céladopole, jalon 20 T16, docs/tech/jalon-20.md §1.3, §2.1, §2.8, §2.15 ;
## dossier 23 §7, §19) sur la vraie scène : métadonnées et lumière, **grille de la scène = grille
## fonctionnelle** `tools/plans/celadopole.txt` case par case, eau solide, raccord est (Route 7),
## portes des neuf bâtiments (arrivées `from_<lieu>_w|e`), sorties nord et sud fermées sans
## warp (ouest : raccord Route 16 depuis le jalon 21, T22), **Arène fermée sans Coupe et ville entière ouverte sans Coupe** (arbuste de l'enclos :
## [FlagGate] du J16), cases réservées aux 14 PNJ hors des cases de coupure et qui ne coupent rien,
## objets peints sur des cases bloquées, budget de nœuds.
## Vie (PNJ, Rocket en civil, objet caché, scènes) : T17, `test_celadon_life`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/celadon_city.tscn"
const PLAN_PATH := "res://tools/plans/celadopole.txt"
const SIZE := Vector2i(70, 46)
const WALKABLE := ".=pqD"
const BUSH := Vector2i(19, 37)
const BUSH_FLAG := &"cut_celadon_gym_bush"
const EAST: Array[Vector2i] = [Vector2i(69, 21), Vector2i(69, 22), Vector2i(69, 23)]
const NODE_BUDGET := 3000
## [position de la grille des portes, nœud, objet peint, intérieur, arrivées].
const BUILDINGS: Array = [
	["porte_magasin", "DepartmentStore", "bldg_grand_magasin_01", &"celadon_dept_gf", "dept"],
	["porte_residence", "Mansion", "bldg_residence_01", &"celadon_mansion_gf", "mansion"],
	["porte_service", "ServiceStairs", "bldg_escalier_service_01", &"celadon_mansion_roof",
		"service"],
	["porte_centre", "PokemonCenter", "bldg_centre_01", &"celadon_center", "center"],
	["porte_casino", "Casino", "bldg_casino_01", &"celadon_game_corner", "casino"],
	["porte_arene", "Gym", "bldg_arene_celadopole_01", &"celadon_gym", "gym"],
	["porte_chef", "ChiefHouse", "bldg_maison_chef_01", &"celadon_chief_house", "chief"],
	["porte_restaurant", "Restaurant", "bldg_restaurant_01", &"celadon_restaurant",
		"restaurant"],
	["porte_hotel", "Hotel", "bldg_hotel_01", &"celadon_hotel", "hotel"],
]
## Cases bloquées par un objet posé sur une case praticable de la grille (panneaux, indice).
const PROP_CELLS := ["panneau_ville", "panneau_arene", "celadon_hidden_1"]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = _relief(true)


func after_all() -> void:
	_map.free()


## Relief de la scène avec les cases bloquées de la grille ; [param bush_standing] : l'arbuste
## de l'enclos est debout (case solide).
func _relief(bush_standing: bool) -> GridWorld:
	var terrain := GridPaths.relief(_grid, SIZE)
	for id: String in PROP_CELLS:
		for cell: Vector2i in _plan.cells_at(id):
			terrain.set_solid(cell)
	for cell: Vector2i in _plan.cells_of("w"):
		terrain.set_solid(cell)  # l'eau ne se traverse pas (is_water, pas is_solid)
	terrain.set_solid(BUSH, bush_standing)
	return terrain


func _prop_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for id: String in PROP_CELLS:
		cells.append_array(_plan.cells_at(id))
	return cells


func _doors() -> Dictionary:
	var doors: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("D"):
		doors[cell] = true
	return doors


## Cases praticables de l'enclos de l'Arène (haies x 3..19, y 26..40), dont l'arbuste.
func _enclosure() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(26, 41):
		for x: int in range(3, 20):
			var cell := Vector2i(x, y)
			if _plan.is_walkable(cell) or cell == BUSH:
				cells.append(cell)
	return cells


func test_metadata_light_and_zone() -> void:
	assert_eq(_map.map_id, &"celadon_city")
	assert_eq(_map.display_name, "Céladopole")
	assert_eq(_map.region, "La cité aux mille couleurs", "texte 13")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"celadon_city"), &"golden_hour")
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"celadon_city"), &"celadon_city")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		var mask := ground.mask.get_image()
		assert_eq(GroundMask.kind_at(mask, Vector2i(40, 22)), GroundMask.Kind.PAVING, "avenue")
		assert_eq(GroundMask.kind_at(mask, Vector2i(38, 5)), GroundMask.Kind.PAVING, "quai")
		assert_not_null(ground.shore_mask, "étang")
		assert_true(ground.square_shore, "angles droits")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var blocked: Array[Vector2i] = []
	for id: String in PROP_CELLS:
		blocked.append_array(_plan.cells_at(id))
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			# L'eau n'est pas « solide » (`is_water`) ; l'arbuste (W) est praticable dans `Ground`
			# (contrat du J16 : sa FlagGate occupe la case).
			var solid := (not _plan.is_walkable(cell) and mark != "w" and mark != "W") \
				or blocked.has(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, mark, _grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/celadopole.txt")
	assert_eq(_plan.walkable, WALKABLE)


func test_pond_is_water_and_never_walkable() -> void:
	var count := 0
	for cell: Vector2i in _plan.cells_of("w"):
		count += 1
		assert_true(_grid.is_water(cell), "eau en %s" % cell)
		assert_false(_grid.can_enter(cell, Vector2i.UP), "pas d'accès à l'eau %s" % cell)
	assert_eq(count, 11 * 7, "étang 11 × 7")
	for cell: Vector2i in _plan.cells_of("q"):
		assert_false(_grid.is_solid(cell), "quai praticable %s" % cell)


func test_east_edge_leads_to_route_7_row_by_row() -> void:
	var suffixes := ["n", "c", "s"]
	var road := MapCatalog.has_map(&"route_7")
	for i: int in EAST.size():
		var warp := _map.get_warps().find_on_push(EAST[i], Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % EAST[i])
		if warp != null and road:
			assert_eq([warp.target_map, warp.target_spawn],
				[&"route_7", StringName("from_celadon_" + suffixes[i])])
		assert_eq(_map.get_spawn_cell(StringName("from_route_7_" + suffixes[i])), EAST[i])
	# Avenue de trois cases au raccord : rien au-dessus ni au-dessous de x 62 à 69.
	for x: int in range(62, 70):
		assert_true(_grid.is_solid(Vector2i(x, 20)), "mur au nord de l'avenue (%d)" % x)
		assert_true(_grid.is_solid(Vector2i(x, 24)), "mur au sud de l'avenue (%d)" % x)
		assert_false(_grid.is_solid(Vector2i(x, 22)))


func test_building_doors_lead_inside_with_two_arrivals() -> void:
	var count := 0
	for entry: Array in BUILDINGS:
		var doors := _plan.cells_at(entry[0])
		var built := MapCatalog.has_map(entry[3])
		for i: int in doors.size():
			count += 1
			var name: StringName = StringName("from_%s" % entry[4]) if doors.size() == 1 \
				else StringName("from_%s_%s" % [entry[4], "w" if i == 0 else "e"])
			assert_eq(_map.get_spawn_cell(name), doors[i] + Vector2i.DOWN, String(name))
			assert_false(_grid.is_solid(doors[i]), "porte %s franchissable" % doors[i])
			var warp := _map.get_warps().find_on_step(doors[i], Vector2i.UP)
			assert_not_null(warp, "porte %s (STEP_ON ↑)" % doors[i])
			if warp != null and built:
				var spawn: StringName = &"from_service" if entry[4] == "service" else &"entrance"
				assert_eq([warp.target_map, warp.target_spawn], [entry[3], spawn])
			elif warp != null:
				assert_true(warp.is_coming_soon(), "%s : « à venir »" % entry[3])
		var building := _map.get_node_or_null(NodePath("Entities/" + entry[1])) as WorldProp
		assert_not_null(building, entry[1])
		if building != null:
			assert_eq(building.scene_file_path.get_file().get_basename(), entry[2])
	assert_eq(count, _plan.cells_of("D").size(), "toutes les portes de la grille")
	# Jalon 21 (T22) : + 3 cases de raccord ouest (Route 16).
	assert_eq(_map.get_warps().size(), count + 6, "portes + raccord est + raccord ouest, rien d'autre")
	# L'ancien Coin à lots : façade sans porte.
	for cell: Vector2i in _plan.cells_at("facade_lots"):
		assert_true(_grid.is_solid(cell), "façade des lots %s" % cell)
		assert_null(_map.get_warps().find_on_step(cell, Vector2i.UP))


## Jalon 21 (T22) : la sortie ouest s'ouvre sur la Route 16 (elle était fermée au J20 : haie,
## talus et examen « Des arbres serrés et un talus. On ne passe pas. », retirés).
func test_north_and_south_are_closed_and_west_opens_on_route_16() -> void:
	for warp: Warp in _map.get_warps().get_all():
		assert_true(warp.cell.x == 69 or warp.cell.x == 0 or _plan.at(warp.cell) == "D",
			"seuls l'est, l'ouest et les portes : %s" % warp.cell)
	for y: int in [21, 22, 23]:
		var warp := _map.get_warps().find_on_push(Vector2i(0, y), Vector2i.LEFT)
		assert_not_null(warp, "warp_ouest (0, %d) PUSH ←" % y)
		if warp != null:
			assert_eq(warp.target_map, &"route_16")
			assert_true(String(warp.target_spawn).begins_with("from_celadon"))
		for x: int in range(0, 4):
			assert_false(_grid.is_solid(Vector2i(x, y)), "chemin (%d, %d)" % [x, y])
		assert_true(_map.has_spawn(&"from_route_16" if y == 22 else (
			&"from_route_16_n" if y == 21 else &"from_route_16_s")))
	assert_eq(_map.get_spawn_cell(&"from_route_16"), Vector2i(1, 22))
	assert_true(_grid.is_solid(Vector2i(3, 20)) and _grid.is_solid(Vector2i(3, 24)),
		"haie au nord et au sud du passage")
	for point: Node in _map.get_node(^"Interactables").get_children():
		assert_ne((point as InteractPoint).dialogue_id, &"celadon_west_block", "examen retiré")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_false(dialogues.has_dialogue(&"celadon_west_block"), "texte 21 retiré")


func test_signs_read_their_texts_from_the_planned_side() -> void:
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Interactables").get_children():
		found[(point as InteractPoint).dialogue_id] = point
	var city := found.get(&"celadon_city_sign") as InteractPoint
	var gym := found.get(&"celadon_gym_sign") as InteractPoint
	assert_not_null(city)
	assert_not_null(gym)
	if city != null:
		assert_eq([city.get_cell(), city.facing], [Vector2i(61, 24), Vector2i.DOWN],
			"lu depuis (61, 23) ↓")
	if gym != null:
		assert_eq([gym.get_cell(), gym.facing], [Vector2i(20, 35), Vector2i.LEFT],
			"lu depuis (21, 35) ←")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_eq(dialogues.get_dialogue(&"celadon_city_sign").variants[0].pages[0].text,
		"CÉLADOPOLE\nVille des fleurs et du commerce", "texte 14")
	assert_eq(dialogues.get_dialogue(&"celadon_gym_sign").variants[0].pages[0].text,
		"ARÈNE DE CÉLADOPOLE\nChampion : Erika — la beauté des plantes", "texte 31")


func test_gym_is_closed_without_cut_and_the_whole_town_stays_open() -> void:
	# L'arbuste est une FlagGate (contrat du J16) : debout (sans drapeau), il occupe sa case.
	var gate := _map.get_node_or_null(^"Entities/GymBush") as FlagGate
	assert_not_null(gate, "arbuste de l'enclos")
	if gate == null:
		return
	assert_eq(gate.unless_flags, [BUSH_FLAG] as Array[StringName])
	assert_eq(gate.blocking_cells, [BUSH] as Array[Vector2i])
	_map.apply_flag_gates(null)
	assert_true(_grid.is_occupied(BUSH), "arbuste debout : case occupée")
	var open := GridPaths.distances(_relief(true), EAST, _doors())
	var enclosure := _enclosure()
	for cell: Vector2i in enclosure:
		assert_false(open.has(cell), "%s : enclos inatteignable sans Coupe" % cell)
	assert_false(open.has(_plan.cells_at("porte_arene")[0]), "porte de l'Arène fermée")
	# Tout le reste est ouvert : chaque case praticable hors de l'enclos est atteignable.
	var missing := 0
	for cell: Vector2i in _plan.cells_of(WALKABLE):
		if enclosure.has(cell) or _prop_cells().has(cell):
			continue
		if not open.has(cell):
			missing += 1
			if missing <= 5:
				fail_test("%s inatteignable sans Coupe" % cell)
	assert_eq(missing, 0, "ville entière ouverte sans Coupe")
	for door: Vector2i in _plan.cells_of("D"):
		if not _plan.cells_at("porte_arene").has(door):
			assert_true(open.has(door), "porte %s atteignable" % door)
	# Coupé : l'enclos et l'Arène s'ouvrent par l'unique porte-haie.
	var flags := StoryFlags.new()
	flags.set_flag(BUSH_FLAG)
	_map.apply_flag_gates(flags)
	assert_false(_grid.is_occupied(BUSH), "arbuste coupé : case libre")
	var cut := GridPaths.distances(_relief(false), EAST, _doors())
	for cell: Vector2i in enclosure:
		assert_true(cut.has(cell), "%s : enclos ouvert après la Coupe" % cell)
	assert_true(cut.has(_plan.cells_at("porte_arene")[0]), "porte de l'Arène atteignable")
	# La haie n'a qu'une ouverture : sans l'arbuste, l'enclos est inatteignable.
	_map.apply_flag_gates(null)


func test_planned_gate_bush_examine_stops_with_the_bush() -> void:
	var point: InteractPoint = null
	for child: Node in _map.get_node(^"Interactables").get_children():
		if (child as InteractPoint).dialogue_id == &"celadon_gym_bush":
			point = child as InteractPoint
	assert_not_null(point)
	if point != null:
		assert_eq(point.get_cell(), BUSH)
		assert_eq(point.unless_flags, [BUSH_FLAG] as Array[StringName])


func test_reserved_cells_for_the_14_npcs_are_free_and_off_the_cut_cells() -> void:
	var cells: Array[Vector2i] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "pnj":
			cells.append_array(_plan.cells_at(id))
	assert_eq(cells.size(), 14, "12 habitants et 2 Rocket en civil")
	var open := GridPaths.distances(_terrain, EAST, _doors())
	for cell: Vector2i in cells:
		assert_false(_grid.is_solid(cell), "%s : case libre" % cell)
		assert_ne(cell, BUSH, "pas sur la case de coupure")
		assert_true(open.has(cell), "%s atteignable sans Coupe" % cell)
		assert_ne(_plan.at(cell), "W")
	# Aucun habitant ne coupe la ville : portes et cases praticables restent reliées.
	var blocked := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in cells:
		blocked.set_solid(cell)
	var reach := GridPaths.distances(blocked, EAST, _doors())
	for door: Vector2i in _plan.cells_of("D"):
		if not _plan.cells_at("porte_arene").has(door):
			assert_true(reach.has(door), "porte %s joignable avec les 14 habitants" % door)
	var lost := 0
	for cell: Vector2i in _plan.cells_of(WALKABLE):
		if _enclosure().has(cell) or cells.has(cell) or _prop_cells().has(cell):
			continue
		if not reach.has(cell):
			lost += 1
	assert_eq(lost, 0, "aucune case coupée du reste par les habitants")


func test_props_never_block_a_walkable_cell() -> void:
	var allowed: Array[Vector2i] = []
	for id: String in PROP_CELLS:
		allowed.append_array(_plan.cells_at(id))
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(not _plan.is_walkable(cell) or allowed.has(cell),
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
	assert_gt(count, 10, "quais posés")


func test_hidden_item_cell_is_a_decorated_blocked_cell() -> void:
	var cell := _plan.cell_of("celadon_hidden_1")
	assert_eq(cell, Vector2i(46, 27))
	assert_true(_grid.is_solid(cell), "case-indice bloquée")
	assert_false(_grid.is_solid(Vector2i(46, 28)), "lu depuis (46, 28) ↑")
	assert_true(_terrain.is_solid(cell))
	assert_not_null(_map.get_node_or_null(^"Entities/HiddenClue"), "décor de l'indice")


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("celadon_city : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)
