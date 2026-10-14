extends GutTest
## Route 24, carte `route_24` (jalon 13 T8, docs/tech/jalon-13.md §2.1, §2.3, §2.14, §2.18 ;
## dossier 16 §7, §11 à §13) sur la vraie scène : métadonnées, **grille de la scène = grille
## fonctionnelle** `tools/plans/route_24.txt`, eau jamais praticable, pont de 2 cases sur 25 rangées
## (tabliers alternés), berges naturelles et quais de pierre sans jamais couvrir une case
## praticable, raccords (Azuria au sud, « ROUTE 25 — À venir » à l'est), **vues du rival et des
## cinq Dresseurs lues sur la grille** (le rival couvre tout le goulet à ≥ 3 cases, chacun des
## Dresseurs du pont est inévitable et ne coince jamais le joueur), cases réservées libres, deux
## zones d'herbes évitables, nœuds. Sans PNJ, objet ni donnée (T17 / T19 / T22).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const Kit := preload("res://tools/cerulean_map_kit.gd")
const MAP_PATH := "res://game/world/maps/route_24.tscn"
const PLAN_PATH := "res://tools/plans/route_24.txt"
const SIZE := Vector2i(56, 62)
const SOUTH: Array[Vector2i] = [Vector2i(31, 61), Vector2i(32, 61), Vector2i(33, 61)]
const EAST: Array[Vector2i] = [Vector2i(55, 6), Vector2i(55, 7), Vector2i(55, 8)]
const NORTH_END := Vector2i(32, 19)
const TRAINERS: Array[String] = ["p1_timeo", "p2_alice", "p3_malo", "p4_romane", "p5_ethan",
	"recruteur"]
const NODE_BUDGET := 3000

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid
## Relief + toutes les positions `bloque` (rival, Ondine, Dresseurs, objets, panneau).
var _terrain: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridPaths.relief(_grid, SIZE)
	# `relief` ne copie pas l'eau : on la ferme ici (jamais praticable).
	for cell: Vector2i in _plan.cells_of("w"):
		_terrain.set_solid(cell)
	for cell: Vector2i in _plan.blocking_cells():
		_terrain.set_solid(cell)


func after_all() -> void:
	_map.free()


## Vue d'un Dresseur de la grille : [param sight] cases devant lui, jusqu'au premier obstacle du
## relief (les autres Dresseurs, déjà dans [member _terrain], ne comptent que comme obstacles).
func _view(id: String) -> Array[Vector2i]:
	var facing := Grid.direction_from_name(_plan.attr(id, "facing"))
	var origin := _plan.cell_of(id)
	var cells: Array[Vector2i] = []
	for k: int in range(1, int(_plan.attr(id, "sight")) + 1):
		var cell := origin + facing * k
		if not _grid.is_in_bounds(cell) or _terrain.is_solid(cell):
			break
		cells.append(cell)
	return cells


func _cell_set(cells: Array[Vector2i]) -> Dictionary:
	var set: Dictionary = {}
	for cell: Vector2i in cells:
		set[cell] = true
	return set


func test_metadata_light_zone_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_24")
	assert_eq(_map.display_name, "Route 24")
	assert_eq(_map.region, "Le Pont Pépite", "sous-titre de zone (§21 n° 56)")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_24"), &"golden_hour")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_24"), &"route_24")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_not_null(ground.shore_mask, "eau dans la passe du sol")
		assert_true(ground.square_shore, "eau à angles droits")
		assert_eq(ground.foam_strength, 0.0, "pas d'écume")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_battle_decor_is_the_bridge() -> void:
	var decors := BattleDecorCatalog.load_file()
	for cell: Vector2i in [Vector2i(32, 30), Vector2i(36, 50), Vector2i(30, 10)]:
		var decor := decors.pick(&"route_24", cell)
		assert_not_null(decor, "décor en %s" % cell)
		if decor != null:
			assert_eq(decor.id, &"route_24_pont")


func test_scene_grid_is_the_functional_grid() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_pont") \
		+ _plan.cells_at("route_24_hidden_1")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := not _plan.is_walkable(cell) or sign.has(cell)
			var ok := _grid.is_water(cell) == (mark == "w") \
				and (mark == "w" or _grid.is_solid(cell) == solid) \
				and _grid.is_tall_grass(cell) == (mark == "h")
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s, herbes %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_water(cell), _grid.is_tall_grass(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_24.txt")
	assert_eq(_plan.walkable, ".=hpBe")


func test_water_is_never_walkable() -> void:
	for cell: Vector2i in _plan.cells_of("w"):
		assert_true(_grid.is_water(cell) or _grid.is_solid(cell), "eau %s" % cell)
		for side: Vector2i in GridPaths.DIRECTIONS:
			assert_false(_grid.can_enter(cell, side), "on n'entre pas dans l'eau %s" % cell)


func test_the_bridge_is_two_cells_wide_and_25_rows_long() -> void:
	var bridge: Array[Vector2i] = _plan.cells_of("B")
	assert_eq(bridge.size(), 50, "tablier de 2 × 25")
	for y: int in range(20, 45):
		for x: int in [32, 33]:
			assert_false(_grid.is_solid(Vector2i(x, y)), "tablier (%d, %d) praticable" % [x, y])
		for x: int in [31, 34]:
			assert_true(_grid.is_water(Vector2i(x, y)), "eau à côté du tablier (%d, %d)" % [x, y])
	# Tablier : 5 modules de 5 rangées qui alternent les trois variantes (pas 25 rangées
	# identiques), à la largeur exacte du pont (2 cases = 192 px).
	var decks: Array[Sprite2D] = []
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if child.name.begins_with("Pont"):
			decks.append(child as Sprite2D)
	assert_eq(decks.size(), 5, "5 modules")
	var names: Dictionary = {}
	for deck: Sprite2D in decks:
		names[deck.texture.resource_path.get_file()] = true
		assert_almost_eq(deck.texture.get_width() * deck.scale.x, 192.0, 0.01, "2 cases de large")
		assert_between(deck.texture.get_height() * deck.scale.y, 479.9, 490.1,
			"5 rangées (+ recouvrement de 10 px sur le module précédent)")
	assert_eq(names.size(), 3, "trois tabliers en alternance")
	assert_eq(decks[0].texture, decks[3].texture, "01, 02, 03, 01, 02")
	assert_ne(decks[0].texture, decks[1].texture)


func test_banks_and_quays_never_cover_a_walkable_cell() -> void:
	var banks := 0
	var quays := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.centered:
			continue
		var file := sprite.texture.resource_path.get_file()
		if not (file.begins_with("relief_berge_") or file.begins_with("relief_quai_")):
			continue
		if file.begins_with("relief_berge_"):
			banks += 1
		else:
			quays += 1
		var rect := Rect2(sprite.position, Vector2(sprite.texture.get_size()) * sprite.scale)
		for cell: Vector2i in Kit.cells_of_rect(rect):
			assert_false(_plan.is_walkable(cell), "%s couvre la case praticable %s"
				% [child.name, cell])
	assert_gt(banks, 40, "berges naturelles le long des rives")
	assert_gt(quays, 8, "quais de pierre au pied du pont (place pavée)")


func test_the_whole_map_is_reachable_and_closed_from_azuria() -> void:
	var dist := GridPaths.distances(_grid, SOUTH)
	var sign: Array[Vector2i] = _plan.cells_at("panneau_pont")
	# T19 : le rival n° 3 et Ondine occupent leur case (PNJ) ; on les atteint par le voisinage.
	var people: Array[Vector2i] = [_plan.cell_of("rival"), _plan.cell_of("ondine")]
	# T22 : les cinq Dresseurs et le recruteur occupent aussi leur case.
	for id: String in TRAINERS:
		people.append(_plan.cell_of(id))
	for cell: Vector2i in _plan.cells_of(_plan.walkable):
		if people.has(cell):
			continue
		if cell == _plan.cell_of("route_24_item_1"):
			# La Potion (T17) occupe sa case ; on la ramasse depuis une case voisine.
			assert_true(dist.has(cell + Vector2i.DOWN), "Potion : case voisine atteignable")
		elif cell == _plan.cell_of("route_24_hidden_1"):
			# L'indice (T22) bloque sa case ; on l'examine depuis une case voisine.
			assert_true(dist.has(cell + Vector2i.DOWN), "indice : case voisine atteignable")
		elif not sign.has(cell):
			assert_true(dist.has(cell), "%s atteignable" % cell)
	for cell: Vector2i in dist:
		assert_true(_plan.is_walkable(cell), "%s fermé par la grille" % cell)
	# Avec tous les Dresseurs en place, le bout nord reste atteignable.
	var blocked := GridPaths.distances(_terrain, SOUTH)
	assert_true(blocked.has(NORTH_END), "le bout nord du pont reste atteignable")
	assert_true(blocked.has(EAST[1]), "et la prairie jusqu'à la Route 25")


func test_south_edge_leads_to_azuria_east_edge_is_route_25_coming_soon() -> void:
	var suffixes := ["w", "c", "e"]
	for i: int in SOUTH.size():
		var warp := _map.get_warps().find_on_push(SOUTH[i], Vector2i.DOWN)
		assert_not_null(warp, "sortie sud %s" % SOUTH[i])
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"cerulean_city", StringName("from_route_24_" + suffixes[i]), Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName("from_cerulean_" + suffixes[i])), SOUTH[i])
	var rows := ["n", "c", "s"]
	for i: int in EAST.size():
		var warp := _map.get_warps().find_on_push(EAST[i], Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % EAST[i])
		if warp == null:
			continue
		assert_true(warp.is_coming_soon())
		assert_eq(warp.coming_soon, "Route 25")
		assert_eq(warp.target_spawn, StringName("from_route_25_" + rows[i]))
		assert_eq(_map.get_spawn_cell(warp.target_spawn), EAST[i], "retour sur la case")
		assert_eq(warp.facing, Vector2i.LEFT)
	assert_eq(_map.get_warps().size(), 6)
	assert_eq(_plan.cells_at("warp_sud"), SOUTH)
	assert_eq(_plan.cells_at("raccord_est"), EAST)


# --- Vues lues sur la grille ---------------------------------------------------------------

func test_the_rival_sees_the_whole_goulet_from_at_least_three_cells() -> void:
	var rival := _plan.cell_of("rival")
	assert_eq(rival, Vector2i(36, 55))
	var view := _view("rival")
	assert_eq(view.size(), 5, "vue de 5 cases (35..31, 55)")
	for x: int in [31, 32, 33]:
		assert_true(view.has(Vector2i(x, 55)), "goulet (%d, 55) dans la vue" % x)
		assert_gte(rival.x - x, 3, "à au moins 3 cases")
	# Tout passage du couloir vers le pont traverse sa vue : inévitable.
	assert_gt(GridPaths.min_crossed(_terrain, SOUTH, [Vector2i(32, 52)], _cell_set(view)), 0,
		"le rival est inévitable")
	# La niche est en retrait : (34..36, 55), un seul accès par l'ouest.
	for x: int in [34, 35, 36]:
		assert_true(_plan.is_walkable(Vector2i(x, 55)))
		assert_true(_grid.is_solid(Vector2i(x, 54)) and _grid.is_solid(Vector2i(x, 56)),
			"niche fermée au nord et au sud")
	# Ondine est au-delà du rival et inaccessible tant qu'il barre le goulet.
	var cut := GridPaths.relief(_terrain, SIZE)
	for cell: Vector2i in view:
		cut.set_solid(cell)
	assert_false(GridPaths.distances(cut, SOUTH).has(_plan.cell_of("ondine")),
		"Ondine inaccessible avant le rival")


func test_each_bridge_trainer_is_unavoidable_and_never_traps_the_player() -> void:
	var seen_before: Dictionary = {}
	for id: String in TRAINERS:
		var origin := _plan.cell_of(id)
		assert_eq(_plan.attr(id, "facing"), "down", "%s tourné vers le sud" % id)
		assert_eq(_plan.attr(id, "sight"), "3", "%s : vue de 3 cases" % id)
		var view := _view(id)
		assert_eq(view.size(), 3, "%s voit 3 cases" % id)
		assert_true(origin.x in [32, 33] and origin.y in range(20, 45), "%s sur le pont" % id)
		# Inévitable : depuis le pied du pont jusqu'au bout nord, une case de sa vue est traversée,
		# les Dresseurs déjà passés étant ignorés (battus : on les laisse comme obstacles).
		assert_gt(GridPaths.min_crossed(_terrain, [Vector2i(32, 45)], [NORTH_END], _cell_set(view)),
			0, "%s inévitable" % id)
		# Ne coince jamais : la case voisine de l'autre file est libre et praticable.
		var other := Vector2i(65 - origin.x, origin.y)
		assert_true(_plan.is_walkable(other) and not _terrain.is_solid(other),
			"%s : file libre ouverte en %s" % [id, other])
		# Le Dresseur suivant (au nord) n'est pas dans sa vue, et on le voit à 3 cases en entrant.
		for cell: Vector2i in view:
			assert_false(seen_before.has(cell), "vues disjointes (%s)" % cell)
			seen_before[cell] = true
	# La première case vue à 3 cases : on ne commence jamais dans la vue (le pied du pont est libre).
	assert_false(seen_before.has(Vector2i(32, 45)))
	# Quinconce : files ouest / est alternées, une rangée sur quatre.
	var files: Array[int] = []
	for id: String in TRAINERS:
		files.append(_plan.cell_of(id).x)
	assert_eq(files, [32, 33, 32, 33, 32, 33], "files alternées")
	assert_eq(_plan.cell_of("p1_timeo").y - _plan.cell_of("p2_alice").y, 4)
	assert_eq(_plan.cell_of("p5_ethan").y - _plan.cell_of("recruteur").y, 4)


func test_the_sign_closes_the_east_file_at_the_bridge_head() -> void:
	var sign := _plan.cell_of("panneau_pont")
	assert_eq(sign, Vector2i(33, 45))
	assert_eq(_plan.cells_at("panneau_pont"), [Vector2i(33, 45), Vector2i(34, 45)] as Array[Vector2i])
	assert_true(_grid.is_solid(sign), "borne solide")
	assert_true(_grid.is_solid(Vector2i(34, 45)), "panneau solide")
	# T17 : le panneau est de taille normale, à côté de la tête du pont (jamais sur le tablier).
	var board := _map.get_node(^"Entities/SignPont") as Node2D
	assert_lt(board.scale.x, 1.0, "panneau réduit")
	assert_eq(Grid.world_to_cell(board.position + Vector2(0.0, -1.0)), Vector2i(34, 45))
	assert_not_null(_map.get_node_or_null(^"Entities/BridgePost"), "borne de la file est")
	assert_false(_grid.is_solid(Vector2i(32, 45)), "on entre par la file ouest (32, 44)")


func test_the_pre_bridge_places_are_reserved_free_of_props() -> void:
	for id: String in ["rival", "ondine", "route_24_item_1", "route_24_hidden_1"] + TRAINERS:
		var cell := _plan.cell_of(id)
		assert_true(_plan.is_walkable(cell), "%s : case praticable de la grille" % id)
		if id == "route_24_hidden_1":
			assert_true(_grid.is_solid(cell), "T22 : la souche de l'Antidote bloque sa case")
		else:
			assert_false(_grid.is_solid(cell), "%s : libre (les PNJ se posent au jeu)" % id)
	# T19 : vue du rival, reprise d'Ondine ; T22 : le recruteur.
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 3)
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 2,
		"le panneau du pont (T17) et l'indice de l'Antidote (T22)")
	var ids: Array[String] = []
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_24").get_all():
		ids.append(String(spec.id))
	assert_eq(ids, ["route_24_ball_1", "rival_cerulean", "misty_bridge", "route_24_timeo",
		"route_24_alice", "route_24_malo", "route_24_romane", "route_24_ethan", "nugget_rocket"]
		as Array[String], "la Potion, le rival, Ondine (T19), les cinq Dresseurs et le recruteur (T22)")


func test_north_tall_grass_is_avoidable() -> void:
	for id: String in ["herbes_h1", "herbes_h2"]:
		var zone := {_plan.cell_of(id): true}
		var stack: Array[Vector2i] = [_plan.cell_of(id)]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in GridPaths.DIRECTIONS:
				var next := cell + side
				if not zone.has(next) and _plan.at(next) == "h":
					zone[next] = true
					stack.append(next)
		assert_eq(GridPaths.min_crossed(_terrain, [NORTH_END], [EAST[1]], zone), 0,
			"%s évitable" % id)
	assert_eq(_plan.cells_of("h").size(), 2 * 7 * 5, "deux prairies de 7 × 5")


func test_props_never_block_a_walkable_cell() -> void:
	var sign: Array[Vector2i] = _plan.cells_at("panneau_pont") \
		+ _plan.cells_at("route_24_hidden_1")
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
	gut.p("route_24 : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)
