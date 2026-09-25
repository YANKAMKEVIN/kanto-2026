extends GutTest
## Carte pallet_town : métadonnées, spawn et invariants d'accessibilité (jalon 1 §4.4).

const MAP_PATH := "res://game/world/maps/pallet_town.tscn"
const START := Vector2i(36, 10)

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
		Vector2i(9, 33),  # bout du ponton
	]
	for cell: Vector2i in required:
		assert_true(_reachable.has(cell), "atteignable : %s" % cell)


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
