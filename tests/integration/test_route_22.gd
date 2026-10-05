extends GutTest
## Carte route_22 (jalon 7, T22, dossier 09 §12–§13) : métadonnées et lumière, sortie est
## (warps PUSH vers Jadielle, spawn d'arrivée), **aucun passage vers l'ouest**, falaise continue
## dont l'escalier est le **seul** passage vers le niveau supérieur, trois champs de hautes
## herbes branchés sur la table `route_22`, habitants sur des cases libres.

const MAP_PATH := "res://game/world/maps/route_22.tscn"
const SIZE := Vector2i(46, 27)
const FROM_VIRIDIAN := Vector2i(44, 18)
const VISTA := Vector2i(11, 13)
## Cases de l'escalier (rangée de la falaise) : seul passage entre les deux niveaux.
const STAIR_CELLS: Array[Vector2i] = [Vector2i(15, 14), Vector2i(16, 14)]
## Champs de hautes herbes (x, y, largeur, hauteur).
const FIELDS: Array[Rect2i] = [Rect2i(20, 20, 8, 4), Rect2i(32, 10, 7, 4), Rect2i(5, 20, 6, 4)]

var _map: GameMap
var _grid: GridWorld
var _reachable: Dictionary[Vector2i, bool]


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_reachable = _grid.find_reachable(FROM_VIRIDIAN)


func after_all() -> void:
	_map.free()


func test_metadata_and_light() -> void:
	assert_eq(_map.map_id, &"route_22")
	assert_eq(_map.size, SIZE)
	assert_eq(_grid.get_size(), SIZE)
	assert_eq(_map.display_name, "Route 22")
	assert_eq(_map.light_profile, &"golden_hour")
	var library := LightingLibrary.new()
	library.load_file()
	assert_true(library.has_profile(_map.light_profile))
	assert_false(_map.interior)


func test_zone_lists_the_map() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_true(zones.has_zone(&"route_22"))
	assert_true((zones.get_zone(&"route_22").maps as Array).has(&"route_22"))


func test_east_exit_is_a_push_warp_to_viridian() -> void:
	assert_eq(_map.get_spawn_cell(&"from_viridian"), FROM_VIRIDIAN)
	assert_true(_reachable.has(FROM_VIRIDIAN))
	for y: int in [17, 18, 19]:
		var cell := Vector2i(44, y)
		assert_true(_reachable.has(cell), "bord est atteignable %s" % cell)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "sortie PUSH vers l'est en %s" % cell)
		if warp != null:
			assert_eq(warp.target_map, &"viridian_city")
			assert_eq(warp.target_spawn, &"from_route_22")
		assert_true(_grid.is_solid(cell + Vector2i.RIGHT), "bord est solide après %s" % cell)
	assert_eq(_map.get_warps().size(), 3, "aucun autre passage")
	# Raccord : si la carte de Jadielle existe, le spawn d'arrivée y existe aussi.
	if MapCatalog.has_map(&"viridian_city"):
		var viridian := (load(MapCatalog.scene_path(&"viridian_city")) as PackedScene) \
			.instantiate() as GameMap
		add_child(viridian)
		assert_true(viridian.has_spawn(&"from_route_22"), "spawn from_route_22 de Jadielle")
		viridian.free()
	else:
		pending("viridian_city absente : raccord vérifié à la fusion de T4")


func test_west_edge_is_closed() -> void:
	for y: int in SIZE.y:
		assert_true(_grid.is_solid(Vector2i(0, y)), "colonne 0 solide en %d" % y)
	for cell: Vector2i in _reachable:
		assert_gt(cell.x, 0, "rien d'atteignable sur le bord ouest : %s" % cell)
	for warp: Warp in _map.get_warps().get_all():
		assert_gt(warp.cell.x, SIZE.x / 2, "aucun passage à l'ouest : %s" % warp.cell)


func test_stair_is_the_only_way_to_the_upper_level() -> void:
	assert_true(_reachable.has(VISTA), "le point de vue est atteignable")
	for cell: Vector2i in STAIR_CELLS:
		assert_true(_reachable.has(cell), "escalier praticable %s" % cell)
	# Falaise continue : bas (y 14) et haut (y 11) solides, hors escalier.
	for x: int in range(0, 15):
		assert_true(_grid.is_solid(Vector2i(x, 14)), "falaise basse %d" % x)
		assert_true(_grid.is_solid(Vector2i(x, 11)), "falaise haute %d" % x)
	for x: int in range(17, 29):
		assert_true(_grid.is_solid(Vector2i(x, 14)), "falaise basse %d" % x)
	# Escalier fermé : plus aucune case du niveau supérieur n'est atteignable.
	for cell: Vector2i in STAIR_CELLS:
		_grid.set_solid(cell)
	var without := _grid.find_reachable(FROM_VIRIDIAN)
	for cell: Vector2i in STAIR_CELLS:
		_grid.set_solid(cell, false)
	for cell: Vector2i in without:
		assert_false(cell.y <= 13 and cell.x <= 16, "niveau supérieur fermé : %s" % cell)
	assert_false(without.has(VISTA))


func test_tall_grass_is_the_three_fields_and_all_reachable() -> void:
	var expected: Array[Vector2i] = []
	for field: Rect2i in FIELDS:
		for y: int in range(field.position.y, field.end.y):
			for x: int in range(field.position.x, field.end.x):
				expected.append(Vector2i(x, y))
	var found: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_tall_grass(Vector2i(x, y)):
				found.append(Vector2i(x, y))
	found.sort()
	expected.sort()
	assert_eq(found, expected, "hautes herbes lues par la grille")
	for cell: Vector2i in expected:
		assert_true(_reachable.has(cell), "champ atteignable %s" % cell)
		assert_false(_grid.is_solid(cell))


func test_encounter_table_is_wired_to_the_map() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	library.load_dir()
	assert_true(library.has_table(_map.map_id, &"grass"))


func test_no_warp_trigger_or_npc_on_tall_grass_and_spawns_are_free() -> void:
	for warp: Warp in _map.get_warps().get_all():
		assert_false(_grid.is_tall_grass(warp.cell))
	for spawn: StringName in [&"from_viridian", &"vista", &"stair_foot"]:
		var cell := _map.get_spawn_cell(spawn)
		assert_false(_grid.is_solid(cell), String(spawn))
		assert_false(_grid.is_tall_grass(cell), String(spawn))
		assert_true(_reachable.has(cell), String(spawn))


func test_residents_stand_on_free_cells() -> void:
	var roster := NpcRoster.load_for_map(&"route_22")
	assert_gt(roster.get_all().size(), 0)
	for spec: NpcSpec in roster.get_all():
		var label := String(spec.id)
		assert_false(_grid.is_solid(spec.cell), "%s : case libre %s" % [label, spec.cell])
		assert_false(_grid.is_tall_grass(spec.cell), "%s : hors herbes" % label)
		assert_true(_reachable.has(spec.cell) or _has_reachable_neighbour(spec.cell),
			"%s : au bord d'une case atteignable" % label)
		for cell: Vector2i in spec.route_cells:
			assert_false(_grid.is_solid(cell), "%s : routine %s" % [label, cell])
			assert_false(_grid.is_tall_grass(cell))
			assert_true(cell.y != 17 and cell.y != 18 and cell.y != 19, "hors du chemin")
	assert_push_error_count(0)
	var traveler := _map.get_npc(&"traveler")
	assert_not_null(traveler)
	if traveler != null:
		assert_eq(traveler.get_spec().dialogue, &"route_22_traveler")
		assert_true(traveler.get_spec().is_interactive())
	# Pokémon d'ambiance peints (opt-in) et non interactifs.
	for id: StringName in [&"route22_rattata", &"route22_spearow", &"route22_mankey"]:
		var npc := _map.get_npc(id)
		assert_not_null(npc, String(id))
		if npc != null:
			assert_true(String(npc.get_spec().sprite).begins_with("pokemon/"))
			assert_true(npc.get_spec().is_shy())
			assert_false(npc.get_spec().is_interactive())
			assert_true(Npc.has_frames(npc.get_spec().sprite), "%s : planche peinte" % id)


## Le voyageur n'a aucun déclencheur ; le seul déclencheur de la carte est la scène du rival
## n° 2 (T25) : en haut de l'escalier, un pas vers l'ouest sur les deux rangées du sentier.
func test_traveler_has_no_trigger_only_a_line_when_spoken_to() -> void:
	var triggers := _map.get_triggers().get_all()
	assert_eq(triggers.size(), 2, "le seul déclencheur : la scène du rival")
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in triggers:
		assert_eq(trigger.cutscene_id, &"rival_route22")
		assert_eq(trigger.direction, Vector2i.LEFT)
		cells.append(trigger.cell)
	cells.sort()
	assert_eq(cells, [Vector2i(14, 12), Vector2i(14, 13)] as Array[Vector2i])
	for cell: Vector2i in cells:
		assert_true(_reachable.has(cell), "déclencheur atteignable %s" % cell)
	# Aucun autre accès au point de vue que par ces deux cases (falaise, escalier) : fermées,
	# le point de vue n'est plus atteignable.
	for cell: Vector2i in cells:
		_grid.set_solid(cell)
	var without := _grid.find_reachable(FROM_VIRIDIAN)
	for cell: Vector2i in cells:
		_grid.set_solid(cell, false)
	assert_false(without.has(VISTA), "le déclencheur barre tout le sentier")
	assert_true(_map.has_spawn(&"stair_foot"), "départ de débogage rival_2_weak")
	assert_true(_reachable.has(_map.get_spawn_cell(&"stair_foot")))


func _has_reachable_neighbour(cell: Vector2i) -> bool:
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _reachable.has(cell + dir):
			return true
	return false
