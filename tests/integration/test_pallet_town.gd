extends GutTest
## Carte pallet_town : métadonnées, spawn et invariants d'accessibilité (jalon 1 §4.4),
## portes ouvertes, warps et spawns des bâtiments (jalon 2 §4.2, §4.8) ; hautes herbes
## et Pokémon de la prairie (jalon 3B §3.1, §3.6, T1) ; déclencheur de la Route 1 (T2) ;
## arrivée de Chen, retour vers le village et chemin du suiveur (T4).

const MAP_PATH := "res://game/world/maps/pallet_town.tscn"
const START := Vector2i(36, 10)
## Portes : nœud du bâtiment → [case de porte, warp, carte cible, spawn de sortie].
const DOORS: Dictionary = {
	&"PlayerHouse": [Vector2i(36, 9), &"DoorPlayerHouse", &"player_house_1f",
		&"player_house_door"],
	&"RivalHouse": [Vector2i(11, 9), &"DoorRivalHouse", &"rival_house", &"rival_house_door"],
	&"OakLab": [Vector2i(24, 22), &"DoorOakLab", &"oak_lab", &"oak_lab_door"],
}

## Hautes herbes : les 3 dernières rangées du chemin de la Route 1 (jalon 3B §3.1).
const TALL_GRASS_RECT := Rect2i(23, 0, 2, 3)
## Déclencheur « route1_grass » : la case juste avant les herbes, sur les deux colonnes.
const TRIGGER_CELLS: Array[Vector2i] = [Vector2i(23, 3), Vector2i(24, 3)]
## Pokémon d'ambiance de la prairie : id → [case, orientation, apparence].
const PRAIRIE: Dictionary = {
	&"prairie_pidgey": [Vector2i(20, 3), Vector2i.DOWN, &"pidgey"],
	&"prairie_rattata": [Vector2i(27, 2), Vector2i.LEFT, &"rattata"],
}

var _map: GameMap
var _grid: GridWorld
var _reachable: Dictionary[Vector2i, bool]


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_reachable = _grid.find_reachable(START)


func after_all() -> void:
	_map.free()


func test_metadata() -> void:
	assert_eq(_map.map_id, &"pallet_town")
	assert_eq(_map.size, Vector2i(48, 34))
	assert_eq(_grid.get_size(), Vector2i(48, 34))
	assert_eq(_map.display_name, "Bourg Palette")
	assert_eq(_map.region, "Kanto")
	assert_eq(_map.get_pixel_rect(), Rect2i(0, 0, 4608, 3264))


func test_scene_structure() -> void:
	for path: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		assert_true(_map.get_node(path) is TileMapLayer, path)
	for path: String in ["Warps", "Spawns", "Triggers"]:
		assert_not_null(_map.get_node_or_null(path), path)
	assert_true(_map.get_entities().y_sort_enabled)
	assert_eq((_map.get_node(^"Overhead") as TileMapLayer).z_index, 10)


func test_start_spawn() -> void:
	assert_eq(_map.get_spawn_cell(&"start"), START)
	assert_true(_grid.can_enter(START, Vector2i.DOWN))


func test_reaches_required_places() -> void:
	var required: Array[Vector2i] = [
		Vector2i(36, 11),  # portillon du joueur
		Vector2i(23, 1), Vector2i(24, 1),  # haut de la Route 1 (une case avant le bord)
		Vector2i(11, 10),  # devant la maison du rival
		Vector2i(24, 17),  # place
		Vector2i(24, 23),  # devant le labo
		Vector2i(24, 25),  # jardins de recherche
		Vector2i(30, 29), Vector2i(44, 29),  # sentier côtier
		Vector2i(8, 29),  # plage
		Vector2i(9, 33),  # bout du ponton (Haru est désormais sur la plage)
		Vector2i(4, 29),  # plage, devant Haru
	]
	for cell: Vector2i in required:
		assert_true(_reachable.has(cell), "atteignable : %s" % cell)


func test_haru_stands_on_the_beach_facing_the_sea() -> void:
	# Retouche de Kevin (jalon 3A §6) : sur la plage, au bord de l'eau, assez haut pour
	# que la boîte de dialogue ne le cache pas.
	var haru := _grid.get_occupant(Vector2i(3, 29)) as Npc
	assert_not_null(haru, "Haru sur la plage")
	if haru != null:
		assert_eq(haru.get_id(), &"haru")
		assert_eq(haru.get_facing(), Vector2i.LEFT, "tourné vers la mer")
	assert_true(_grid.is_water(Vector2i(2, 29)), "la mer juste à l'ouest")


func test_does_not_reach_forbidden_places() -> void:
	var forbidden: Array[Vector2i] = [
		Vector2i(38, 1),  # champ
		Vector2i(23, 0), Vector2i(24, 0),  # bord nord : la tête du joueur resterait coupée
		Vector2i(43, 26), Vector2i(44, 26), Vector2i(45, 26), Vector2i(46, 26),  # sentier secret
		Vector2i(46, 29), Vector2i(47, 30),  # Route 21
		Vector2i(1, 10), Vector2i(45, 10),  # lisières
	]
	for cell: Vector2i in forbidden:
		assert_false(_reachable.has(cell), "inaccessible : %s" % cell)


func test_no_water_cell_is_reachable() -> void:
	var water_count := 0
	for y: int in _map.size.y:
		for x: int in _map.size.x:
			var cell := Vector2i(x, y)
			if _grid.is_water(cell):
				water_count += 1
				assert_false(_reachable.has(cell), "eau atteinte : %s" % cell)
	assert_true(water_count > 48, "la mer existe (%d cases)" % water_count)


func test_no_building_footprint_is_reachable() -> void:
	var buildings := [&"RivalHouse", &"PlayerHouse", &"OakLab", &"GreenhouseLarge",
		&"GreenhouseSmall"]
	for building: StringName in buildings:
		var prop := _map.get_entities().get_node(NodePath(building)) as WorldProp
		assert_not_null(prop, building)
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(_grid.is_solid(cell), "%s solide en %s" % [building, cell])
			assert_false(_reachable.has(cell), "%s atteint en %s" % [building, cell])


func test_building_anchors_match_plan() -> void:
	var anchors := {
		&"RivalHouse": Vector2i(11, 9),
		&"PlayerHouse": Vector2i(36, 9),
		&"OakLab": Vector2i(24, 22),
		&"PlazaTree": Vector2i(24, 16),
		&"BenchWest": Vector2i(19, 15),  # hors du toit du labo (rangées 16–17)
		&"BenchEast": Vector2i(28, 15),
		&"GreenhouseLarge": Vector2i(20, 27),
		&"GreenhouseSmall": Vector2i(33, 27),
		&"Van": Vector2i(15, 22),
		&"SecretBrambles": Vector2i(42, 26),
		&"BarrierRoute21": Vector2i(45, 30),
	}
	for prop_name: StringName in anchors:
		var prop := _map.get_entities().get_node(NodePath(prop_name)) as WorldProp
		assert_eq(prop.get_anchor_cell(), anchors[prop_name], prop_name)


func test_pier_is_walkable_over_water() -> void:
	assert_false(_grid.is_water(Vector2i(9, 32)))
	assert_false(_grid.is_water(Vector2i(9, 33)))
	assert_true(_grid.is_water(Vector2i(8, 33)))
	assert_true(_grid.is_water(Vector2i(10, 33)))


func test_gates_are_open() -> void:
	for gate: Vector2i in [Vector2i(11, 11), Vector2i(36, 11), Vector2i(24, 24)]:
		assert_true(_reachable.has(gate), "portillon %s" % gate)
		assert_true(_grid.is_solid(gate + Vector2i.LEFT), "clôture à l'ouest de %s" % gate)
		assert_true(_grid.is_solid(gate + Vector2i.RIGHT), "clôture à l'est de %s" % gate)


# --- Portes (jalon 2 §4.2) ---------------------------------------------------------

func test_door_cells_are_reachable_and_enclosed() -> void:
	for building: StringName in DOORS:
		var door: Vector2i = DOORS[building][0]
		assert_true(_reachable.has(door), "porte atteignable : %s" % door)
		assert_false(_grid.is_solid(door), "porte praticable : %s" % door)
		for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			assert_eq(_grid.get_step_target(door, direction), door,
				"depuis la porte %s, %s bloqué" % [door, direction])
		assert_ne(_grid.get_step_target(door, Vector2i.DOWN), door, "on ressort vers le bas")


func test_door_is_the_only_reachable_cell_of_a_building() -> void:
	for building: StringName in DOORS:
		var prop := _map.get_entities().get_node(NodePath(building)) as WorldProp
		var door: Vector2i = DOORS[building][0]
		assert_eq(prop.get_anchor_cell(), door, "ancre = porte de %s" % building)
		var rect := Rect2i(door, Vector2i.ONE)
		for cell: Vector2i in prop.get_solid_cells():
			rect = rect.expand(cell).expand(cell + Vector2i.ONE)
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				assert_eq(_reachable.has(cell), cell == door, "%s en %s" % [building, cell])


func test_door_warps() -> void:
	var warps := _map.get_warps()
	assert_eq(warps.size(), DOORS.size())
	for building: StringName in DOORS:
		var spec: Array = DOORS[building]
		var point := _map.get_node(NodePath("Warps/" + String(spec[1]))) as WarpPoint
		assert_not_null(point, String(spec[1]))
		if point == null:
			continue
		assert_eq(point.get_cell(), spec[0])
		assert_eq(point.trigger, Warp.Trigger.STEP_ON)
		assert_eq(point.direction, Vector2i.UP)
		assert_eq(point.target_map, spec[2])
		assert_eq(point.target_spawn, &"entrance")
		var warp := warps.find_on_step(spec[0], Vector2i.UP)
		assert_not_null(warp, "porte déclenchée en montant : %s" % spec[0])
		assert_null(warps.find_on_step(spec[0], Vector2i.DOWN), "pas en sortant")


func test_door_spawns() -> void:
	for building: StringName in DOORS:
		var spec: Array = DOORS[building]
		assert_true(_map.has_spawn(spec[3]), String(spec[3]))
		assert_eq(_map.get_spawn_cell(spec[3]), spec[0], String(spec[3]))
	assert_true(_map.has_spawn(&"start"), "start conservé")
	assert_false(_map.interior)


# --- Hautes herbes et prairie (jalon 3B, T1) ----------------------------------------

func _ground_kind(cell: Vector2i) -> int:
	var ground := _map.get_node(^"Ground") as TileMapLayer
	if ground.get_cell_source_id(cell) < 0:
		return -1
	return ground.get_cell_atlas_coords(cell).y


func test_tall_grass_cells_are_exactly_the_top_of_route_1() -> void:
	var found: Array[Vector2i] = []
	for y: int in _map.size.y:
		for x: int in _map.size.x:
			var cell := Vector2i(x, y)
			if _ground_kind(cell) == OverworldTiles.Kind.TALL_GRASS:
				found.append(cell)
				var data := (_map.get_node(^"Ground") as TileMapLayer).get_cell_tile_data(cell)
				assert_true(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS),
					"donnée tall_grass en %s" % cell)
	var expected: Array[Vector2i] = []
	for y: int in range(TALL_GRASS_RECT.position.y, TALL_GRASS_RECT.end.y):
		for x: int in range(TALL_GRASS_RECT.position.x, TALL_GRASS_RECT.end.x):
			expected.append(Vector2i(x, y))
	found.sort()
	expected.sort()
	assert_eq(found, expected)


func test_grid_tall_grass_matches_the_top_of_route_1() -> void:
	# Jalon 5 : GameMap lit enfin la donnée tall_grass des tuiles dans la grille. Vrai
	# exactement sur (23..24, 0..2), y compris les deux cases bloquées du bord nord.
	for y: int in _map.size.y:
		for x: int in _map.size.x:
			var cell := Vector2i(x, y)
			assert_eq(_grid.is_tall_grass(cell), TALL_GRASS_RECT.has_point(cell),
				"is_tall_grass en %s" % cell)
	# Les cases bloquées du bord nord sont à la fois solides et en herbe.
	assert_true(_grid.is_tall_grass(Vector2i(23, 0)) and _grid.is_solid(Vector2i(23, 0)))
	assert_true(_grid.is_tall_grass(Vector2i(24, 0)) and _grid.is_solid(Vector2i(24, 0)))


func test_tall_grass_is_walkable_except_the_blocked_edge() -> void:
	for cell: Vector2i in [Vector2i(23, 1), Vector2i(24, 1), Vector2i(23, 2), Vector2i(24, 2)]:
		assert_false(_grid.is_solid(cell), "praticable : %s" % cell)
		assert_true(_reachable.has(cell), "atteignable : %s" % cell)
	for cell: Vector2i in [Vector2i(23, 0), Vector2i(24, 0)]:
		assert_false(_reachable.has(cell), "bord nord toujours bloqué : %s" % cell)


func test_path_below_the_tall_grass_is_still_dirt_between_fences() -> void:
	for y: int in range(3, 12):
		for x: int in [23, 24]:
			assert_eq(_ground_kind(Vector2i(x, y)), OverworldTiles.Kind.DIRT,
				"chemin en (%d, %d)" % [x, y])
	# Clôtures intactes de part et d'autre des herbes et du haut du chemin.
	for y: int in range(0, 4):
		assert_true(_grid.is_solid(Vector2i(22, y)), "clôture ouest en y %d" % y)
		assert_true(_grid.is_solid(Vector2i(25, y)), "clôture est en y %d" % y)


func test_prairie_pokemon_stand_on_grass_in_view_of_the_route() -> void:
	for id: StringName in PRAIRIE:
		var row: Array = PRAIRIE[id]
		var npc := _map.get_npc(id)
		assert_not_null(npc, String(id))
		if npc == null:
			continue
		var cell: Vector2i = row[0]
		assert_eq(npc.get_cell(), cell, "%s case" % id)
		assert_eq(npc.get_facing(), row[1], "%s orientation" % id)
		assert_eq(npc.get_spec().sprite, row[2], "%s apparence" % id)
		assert_null(npc.get_interaction(), "%s non interactif (Q4)" % id)
		assert_eq(_grid.get_occupant(cell), npc, "%s occupe sa case" % id)
		assert_eq(_ground_kind(cell), OverworldTiles.Kind.GRASS, "%s dans l'herbe rase" % id)
		assert_false(TALL_GRASS_RECT.has_point(cell), "%s hors des hautes herbes" % id)
		# Visible depuis le bas des herbes (joueur en (23, 4) : ≈ 24 × 11 cases à l'écran).
		assert_lt(absi(cell.x - 23), 11, "%s dans le champ horizontal" % id)
		var free_neighbours := 0
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _reachable.has(cell + direction):
				free_neighbours += 1
		assert_gt(free_neighbours, 0, "%s au bord d'une case atteignable" % id)


func test_route1_trigger_covers_the_cells_just_before_the_grass() -> void:
	var triggers := _map.get_triggers()
	assert_eq(triggers.size(), TRIGGER_CELLS.size())
	var point := _map.get_node_or_null(^"Triggers/Route1Grass") as EventTriggerPoint
	assert_not_null(point, "Triggers/Route1Grass")
	for cell: Vector2i in TRIGGER_CELLS:
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var trigger := triggers.find_on_step(cell, direction)
			assert_not_null(trigger, "%s, pas vers %s" % [cell, direction])
			if trigger != null:
				assert_eq(trigger.cutscene_id, &"route1_grass")


func test_route1_trigger_cells_are_walkable_reachable_and_clear() -> void:
	var spawn_cells: Array[Vector2i] = []
	for marker: Node in _map.get_node(^"Spawns").get_children():
		spawn_cells.append(Grid.world_to_cell((marker as Node2D).position))
	var warp_cells: Array[Vector2i] = []
	for warp: Warp in _map.get_warps().get_all():
		warp_cells.append(warp.cell)
	var npc_cells: Array[Vector2i] = []
	for spec: NpcSpec in NpcRoster.load_for_map(&"pallet_town").get_all():
		npc_cells.append(spec.cell)
	for cell: Vector2i in TRIGGER_CELLS:
		assert_false(_grid.is_solid(cell), "praticable : %s" % cell)
		assert_true(_reachable.has(cell), "atteignable : %s" % cell)
		assert_false(warp_cells.has(cell), "pas un warp : %s" % cell)
		assert_false(spawn_cells.has(cell), "pas un spawn : %s" % cell)
		assert_false(npc_cells.has(cell), "pas la case d'un PNJ : %s" % cell)
		var below := cell + Vector2i.DOWN
		assert_true(_grid.is_free(below), "case de recul libre : %s" % below)
		assert_false(npc_cells.has(below), "case de recul sans PNJ : %s" % below)


func test_tall_grass_cannot_be_reached_without_the_trigger() -> void:
	for cell: Vector2i in TRIGGER_CELLS:
		_grid.set_solid(cell)
	var reachable := _grid.find_reachable(START)
	for cell: Vector2i in TRIGGER_CELLS:
		_grid.set_solid(cell, false)
	for y: int in range(TALL_GRASS_RECT.position.y, TALL_GRASS_RECT.end.y):
		for x: int in range(TALL_GRASS_RECT.position.x, TALL_GRASS_RECT.end.x):
			assert_false(reachable.has(Vector2i(x, y)), "herbes (%d, %d) hors d'atteinte" % [x, y])


# --- Arrivée de Chen et retour (jalon 3B §3.6, T4) ---------------------------------------

## Case d'apparition de Chen (étape « spawn » de route1_grass).
const OAK_SPAWN := Vector2i(24, 13)
## Décalages de l'étape « move » de Chen vers le joueur.
const OAK_OFFSETS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
const DOWN_8: Array[Vector2i] = [
	Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN,
	Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN,
]


## Cases interdites à un pas scripté : warps, déclencheurs, PNJ du fichier.
func _forbidden_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for warp: Warp in _map.get_warps().get_all():
		cells.append(warp.cell)
	for trigger: EventTrigger in _map.get_triggers().get_all():
		cells.append(trigger.cell)
	for spec: NpcSpec in NpcRoster.load_for_map(&"pallet_town").get_all():
		cells.append(spec.cell)
	return cells


func test_oak_spawn_cell_is_walkable_and_free() -> void:
	assert_true(_grid.is_free(OAK_SPAWN), "praticable et libre")
	assert_false(_forbidden_cells().has(OAK_SPAWN))
	assert_true(_reachable.has(OAK_SPAWN))


func test_oak_reaches_the_cell_next_to_the_player_on_both_columns() -> void:
	var expected: Dictionary[Vector2i, Vector2i] = {
		Vector2i(23, 3): Vector2i(24, 3), Vector2i(24, 3): Vector2i(23, 3),
	}
	var player := RefCounted.new()
	for player_cell: Vector2i in expected:
		_grid.occupy(player_cell, player)
		var goal := CutsceneMoves.resolve_near(_grid, player_cell, OAK_OFFSETS)
		assert_eq(goal, expected[player_cell], "joueur en %s" % player_cell)
		var path := _grid.find_path(OAK_SPAWN, goal)
		assert_false(path.is_empty(), "chemin de %s à %s" % [OAK_SPAWN, goal])
		assert_eq(CutsceneMoves.path_cells(OAK_SPAWN, path).back(), goal)
		_grid.release(player_cell, player)


func test_the_walk_back_and_the_follower_path_are_clear() -> void:
	var forbidden := _forbidden_cells()
	for player_cell: Vector2i in TRIGGER_CELLS:
		var oak_cell := Vector2i(47 - player_cell.x, player_cell.y)  # autre colonne
		var leader := CutsceneMoves.path_cells(oak_cell, DOWN_8)
		var follow := CutsceneMoves.follow_path(player_cell, oak_cell, DOWN_8)
		assert_eq(follow.size(), DOWN_8.size())
		var follower := CutsceneMoves.path_cells(player_cell, follow)
		assert_eq(follower.back(), leader[leader.size() - 2], "avant-dernière case de Chen")
		for cell: Vector2i in leader + follower:
			if cell == oak_cell:
				continue  # la case que Chen vient de quitter
			assert_true(_grid.is_free(cell), "libre : %s" % cell)
			assert_false(forbidden.has(cell), "ni warp, ni déclencheur, ni PNJ : %s" % cell)
