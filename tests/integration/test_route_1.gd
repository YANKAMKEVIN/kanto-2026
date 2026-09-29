extends GutTest
## Carte route_1 (jalon 5 §15.4, dossier-07) : métadonnées, raccord sud vers Bourg Palette,
## sortie nord (bord bloqué en attendant Jadielle), 3 zones de hautes herbes lues par la
## grille, rebord LEDGE_DOWN franchissable vers le sud, chemins praticables, Potion cachée,
## Voyageur et Pokémon d'ambiance ; invariants d'accessibilité du §4.

const MAP_PATH := "res://game/world/maps/route_1.tscn"
const SIZE := Vector2i(48, 44)
const FROM_PALLET_W := Vector2i(23, 42)
const FROM_PALLET_E := Vector2i(24, 42)
const NORTH_W := Vector2i(23, 1)
const NORTH_E := Vector2i(24, 1)
## Zones de hautes herbes (rectangles inclusifs) et clairière de la Potion (herbe rase).
const GRASS_ZONES: Array = [
	[27, 32, 30, 34],  # Zone 1 initiation (contournable)
	[8, 18, 11, 27],   # Zone 2 exploration (recoin/Potion)
	[23, 8, 24, 9],    # Zone 3 bande obligatoire
]
const POTION_CLEARING := Vector2i(9, 20)
const POTION_CELL := Vector2i(9, 20)
const LEDGE_CELLS: Array[Vector2i] = [Vector2i(26, 30), Vector2i(27, 30), Vector2i(28, 30)]

var _map: GameMap
var _grid: GridWorld
var _reachable: Dictionary[Vector2i, bool]


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_reachable = _grid.find_reachable(FROM_PALLET_W)


func after_all() -> void:
	_map.free()


func _expected_grass() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for z: Array in GRASS_ZONES:
		for y: int in range(z[1], z[3] + 1):
			for x: int in range(z[0], z[2] + 1):
				var cell := Vector2i(x, y)
				if cell != POTION_CLEARING:
					cells.append(cell)
	return cells


func test_metadata() -> void:
	assert_eq(_map.map_id, &"route_1")
	assert_eq(_map.size, SIZE)
	assert_eq(_grid.get_size(), SIZE)
	assert_eq(_map.display_name, "Route 1")
	assert_eq(_map.region, "Bourg Palette — Jadielle")
	assert_false(_map.interior)


func test_scene_structure() -> void:
	for path: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		assert_true(_map.get_node(path) is TileMapLayer, path)
	for path: String in ["Warps", "Spawns", "Triggers"]:
		assert_not_null(_map.get_node_or_null(path), path)
	assert_true(_map.get_entities().y_sort_enabled)


func test_south_connection_to_pallet_town() -> void:
	assert_eq(_map.get_spawn_cell(&"from_pallet_w"), FROM_PALLET_W)
	assert_eq(_map.get_spawn_cell(&"from_pallet_e"), FROM_PALLET_E)
	for spec: Array in [[FROM_PALLET_W, &"from_route_1_w"], [FROM_PALLET_E, &"from_route_1_e"]]:
		var cell: Vector2i = spec[0]
		assert_false(_grid.is_solid(cell), "arrivée praticable %s" % cell)
		assert_true(_reachable.has(cell), "arrivée atteignable %s" % cell)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie PUSH bas en %s" % cell)
		if warp != null:
			assert_eq(warp.target_map, &"pallet_town")
			assert_eq(warp.target_spawn, spec[1])
			assert_eq(warp.facing, Vector2i.DOWN)
		# Bord sud bloqué sous l'arrivée (la poussée déclenche le warp).
		assert_true(_grid.is_solid(cell + Vector2i.DOWN), "bord sud bloqué sous %s" % cell)


func test_north_edge_is_reachable_but_blocked() -> void:
	# La sortie nord vers Jadielle : le chemin atteint le bord, la rangée y 0 est bloquée.
	for cell: Vector2i in [NORTH_W, NORTH_E]:
		assert_true(_reachable.has(cell), "haut du chemin atteignable %s" % cell)
	for cell: Vector2i in [Vector2i(23, 0), Vector2i(24, 0)]:
		assert_false(_reachable.has(cell), "bord nord bloqué %s" % cell)


func test_tall_grass_grid_matches_the_three_zones() -> void:
	var expected := _expected_grass()
	var found: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_tall_grass(Vector2i(x, y)):
				found.append(Vector2i(x, y))
	found.sort()
	expected.sort()
	assert_eq(found, expected, "hautes herbes lues par la grille")


func test_mandatory_band_cannot_be_bypassed() -> void:
	# Zone 3 rendue solide : le nord n'est plus atteignable (bande obligatoire, dossier-07 §2).
	var band: Array[Vector2i] = []
	for y: int in range(8, 10):
		for x: int in range(23, 25):
			band.append(Vector2i(x, y))
	for cell: Vector2i in band:
		assert_true(_grid.is_tall_grass(cell), "bande obligatoire en herbe %s" % cell)
		_grid.set_solid(cell)
	var reachable := _grid.find_reachable(FROM_PALLET_W)
	for cell: Vector2i in band:
		_grid.set_solid(cell, false)
	assert_false(reachable.has(NORTH_W), "nord bloqué si la bande est fermée")


func test_first_zone_is_avoidable() -> void:
	# Zone 1 rendue solide : le nord reste atteignable (contournable, dossier-07 §2).
	var zone: Array[Vector2i] = []
	for y: int in range(32, 35):
		for x: int in range(27, 31):
			zone.append(Vector2i(x, y))
	for cell: Vector2i in zone:
		_grid.set_solid(cell)
	var reachable := _grid.find_reachable(FROM_PALLET_W)
	for cell: Vector2i in zone:
		_grid.set_solid(cell, false)
	assert_true(reachable.has(NORTH_W), "Zone 1 contournable : le nord reste atteignable")


func test_ledge_is_a_one_way_southward_shortcut() -> void:
	for cell: Vector2i in LEDGE_CELLS:
		assert_eq(_grid.get_ledge(cell), GridWorld.Ledge.DOWN, "rebord bas en %s" % cell)
		assert_false(_grid.is_solid(cell), "rebord praticable %s" % cell)
	# Saut de deux cases vers le sud depuis la case au-dessus du rebord.
	var above := LEDGE_CELLS[1] + Vector2i.UP
	var landing := LEDGE_CELLS[1] + Vector2i.DOWN
	assert_eq(_grid.get_step_target(above, Vector2i.DOWN), landing, "saut de 2 cases vers le bas")
	# On ne remonte pas le rebord.
	assert_eq(_grid.get_step_target(landing, Vector2i.UP), landing, "pas de remontée du rebord")


func test_path_and_zones_are_reachable() -> void:
	var required: Array[Vector2i] = [
		Vector2i(23, 40), Vector2i(30, 35), Vector2i(33, 30), Vector2i(20, 25),
		Vector2i(12, 20), Vector2i(20, 15), Vector2i(23, 5), Vector2i(23, 8),
		POTION_CELL, Vector2i(28, 33), Vector2i(9, 22),
	]
	for cell: Vector2i in required:
		assert_true(_reachable.has(cell), "atteignable : %s" % cell)


func test_return_to_pallet_is_always_possible() -> void:
	# Invariant §4 : depuis toute case atteignable, le retour vers Bourg Palette l'est aussi
	# (aucun piège sous un rebord). Reverse-BFS depuis l'arrivée sud sur les arêtes de pas.
	var can_reach_start := _cells_that_reach(FROM_PALLET_W)
	for cell: Vector2i in _reachable:
		assert_true(can_reach_start.has(cell), "retour possible depuis %s" % cell)


## Ensemble des cases d'où [param goal] est atteignable (BFS sur le graphe des pas inversé).
func _cells_that_reach(goal: Vector2i) -> Dictionary[Vector2i, bool]:
	var reverse: Dictionary[Vector2i, Array] = {}
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var from := Vector2i(x, y)
			for d: Vector2i in dirs:
				var to := _grid.get_step_target(from, d)
				if to != from:
					if not reverse.has(to):
						reverse[to] = []
					reverse[to].append(from)
	var seen: Dictionary[Vector2i, bool] = {goal: true}
	var queue: Array[Vector2i] = [goal]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for prev: Vector2i in reverse.get(cell, []):
			if not seen.has(prev):
				seen[prev] = true
				queue.append(prev)
	return seen


func test_hidden_potion_trigger() -> void:
	var triggers := _map.get_triggers()
	var point := _map.get_node_or_null(^"Triggers/Route1Potion") as EventTriggerPoint
	assert_not_null(point, "Triggers/Route1Potion")
	assert_false(_grid.is_tall_grass(POTION_CELL), "sur herbe rase, pas de rencontre")
	assert_false(_grid.is_solid(POTION_CELL), "praticable")
	assert_true(_reachable.has(POTION_CELL), "atteignable")
	var trigger := triggers.find_on_step(POTION_CELL, Vector2i.UP)
	assert_not_null(trigger, "déclencheur sur la case")
	if trigger != null:
		assert_eq(trigger.cutscene_id, &"route_1_potion")


func test_no_tall_grass_cell_carries_a_trigger_warp_or_npc() -> void:
	# Invariant §4 (les rencontres arrivent au 5B) : aucune case d'herbe ne porte de warp
	# STEP_ON, de déclencheur ni de PNJ. Les warps du raccord sont PUSH, hors herbe.
	var grass: Array[Vector2i] = _expected_grass()
	for warp: Warp in _map.get_warps().get_all():
		assert_false(grass.has(warp.cell), "warp hors herbe : %s" % warp.cell)
	for trigger: EventTrigger in _map.get_triggers().get_all():
		assert_false(grass.has(trigger.cell), "déclencheur hors herbe : %s" % trigger.cell)
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_1").get_all():
		assert_false(grass.has(spec.cell), "PNJ hors herbe : %s" % spec.cell)


func test_traveler_walks_beside_the_path_without_blocking_it() -> void:
	var traveler := _map.get_npc(&"traveler")
	assert_not_null(traveler, "le Voyageur")
	if traveler == null:
		return
	var spec := traveler.get_spec()
	assert_true(spec.is_interactive(), "on peut lui parler")
	assert_true(spec.has_route(), "il a une routine de marche")
	assert_eq(spec.dialogue, &"route_1_traveler")
	for cell: Vector2i in spec.route_cells:
		assert_false(_grid.is_tall_grass(cell), "jamais dans les herbes : %s" % cell)
		# Ne bloque pas le chemin d'arrivée (colonnes 23–24).
		assert_true(cell.x < 23 or cell.x > 24, "hors du passage principal : %s" % cell)


func test_ambient_pokemon_are_shy_and_can_flee() -> void:
	for spec_row: Array in [[&"route_pidgey", &"fly"], [&"route_rattata", &"flee"]]:
		var npc := _map.get_npc(spec_row[0])
		assert_not_null(npc, String(spec_row[0]))
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq(spec.shy_action, spec_row[1])
		assert_null(npc.get_interaction(), "non interactif : %s" % spec_row[0])
		assert_false(_grid.is_tall_grass(spec.cell), "hors herbe : %s" % spec.cell)
		assert_true(_reachable.has(spec.cell) or _has_reachable_neighbour(spec.cell),
			"au bord d'une case atteignable : %s" % spec.cell)
	# Le Rattata peut fuir un joueur venant du chemin.
	var rattata := _map.get_npc(&"route_rattata")
	if rattata != null:
		var player_cell := rattata.get_cell() + Vector2i.DOWN
		var path := AmbientRules.flee_path(_grid, rattata.get_cell(), player_cell, 3, rattata)
		assert_false(path.is_empty(), "le Rattata a où fuir")


func _has_reachable_neighbour(cell: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _reachable.has(cell + d):
			return true
	return false
