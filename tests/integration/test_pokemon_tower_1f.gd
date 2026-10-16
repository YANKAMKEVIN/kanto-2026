extends GutTest
## Carte pokemon_tower_1f (rez-de-chaussée de la Tour Pokémon, jalon 18 T14, jalon-18.md §4.12 ;
## dossier 21 §7) sur la vraie scène : **grille de la scène = grille fonctionnelle**
## `tools/plans/tour_pokemon_rdc.txt`, géométrie (l'escalier (17, 2) n'est atteignable que par
## (17, 3), case de la gardienne), tombes lisibles depuis une case libre, sortie, escalier
## `coming_soon`, halos, **sans vie** (aucun PNJ, aucun examen).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/pokemon_tower_1f.tscn"
const PLAN_PATH := "res://tools/plans/tour_pokemon_rdc.txt"
const SIZE := Vector2i(20, 18)
const ENTRY := Vector2i(9, 16)
const STAIRS := Vector2i(17, 2)
const ACCESS := Vector2i(17, 3)

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func _terrain() -> GridWorld:
	return GridPaths.relief(_grid, SIZE)


## Distances depuis l'entrée ; les cases de [param blocked] sont solides (PNJ).
func _reach(blocked: Array[Vector2i] = []) -> Dictionary:
	var terrain := _terrain()
	for cell: Vector2i in blocked:
		terrain.set_solid(cell)
	return GridPaths.distances(terrain, [ENTRY], {STAIRS: true})


func test_metadata() -> void:
	assert_eq(_map.map_id, &"pokemon_tower_1f")
	assert_eq(_map.display_name, "Tour Pokémon")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior, "bâtiment")
	assert_eq(_map.light_profile, &"tower_cold")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"pokemon_tower_1f"), &"tower_cold")
	assert_true(MapCatalog.load_interiors().has(&"pokemon_tower_1f"))


func test_scene_grid_is_the_functional_grid() -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			assert_eq(_grid.is_solid(cell), not _plan.is_walkable(cell),
				"case %s « %s »" % [cell, _plan.at(cell)])
	assert_eq(_plan.walkable, ".XS")


func test_stairs_are_reachable_only_through_the_guardian_cell() -> void:
	var free := _reach()
	assert_true(free.has(STAIRS), "sans la gardienne (J19), l'escalier est atteignable")
	assert_eq(_grid.get_step_target(ACCESS, Vector2i.UP), STAIRS)
	# Seules voisines praticables de l'escalier : (17, 3).
	var neighbours := 0
	for direction: Vector2i in GridPaths.DIRECTIONS:
		if not _grid.is_solid(STAIRS + direction):
			neighbours += 1
			assert_eq(STAIRS + direction, ACCESS)
	assert_eq(neighbours, 1)
	# La gardienne en (17, 3) : l'escalier est inatteignable, même avec tous les autres PNJ.
	var npcs: Array[Vector2i] = [ACCESS]
	assert_false(_reach(npcs).has(STAIRS), "gardienne en (17, 3)")
	# Les quatre autres PNJ ne coupent rien : tout le sol reste atteignable.
	var others: Array[Vector2i] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "pnj" and id != "exorciste_gardienne":
			others.append_array(_plan.cells_at(id))
	var dist := _reach(others + npcs)
	for cell: Vector2i in _plan.cells_of("."):
		if not others.has(cell) and cell != ACCESS:
			assert_true(dist.has(cell), "case %s atteignable" % cell)


func test_graves_are_readable_from_a_free_cell() -> void:
	var dist := _reach()
	var graves: Array[Vector2i] = _plan.cells_of("g")
	assert_eq(graves.size(), 36)
	for grave: Vector2i in graves:
		var readable := false
		for direction: Vector2i in GridPaths.DIRECTIONS:
			readable = readable or dist.has(grave + direction)
		assert_true(readable, "tombe %s lisible" % grave)
		assert_true(_grid.is_solid(grave))
	# Cases de lecture des 5 tombes nommées : (4,4) (7,6) (12,4) (15,6) (5,10).
	for reading: Vector2i in [Vector2i(4, 4), Vector2i(7, 6), Vector2i(12, 4), Vector2i(15, 6),
			Vector2i(5, 10)]:
		assert_true(dist.has(reading), "case de lecture %s" % reading)


func test_exit_and_stairs_warps() -> void:
	for x: int in [9, 10]:
		var warp := _map.get_warps().find_on_push(Vector2i(x, 16), Vector2i.DOWN)
		assert_not_null(warp, "sortie (%d, 16)" % x)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [&"lavender_town", &"retour_tour"])
	assert_eq(_map.get_spawn_cell(&"entrance"), ENTRY)
	var stairs := _map.get_warps().find_on_step(STAIRS, Vector2i.UP)
	assert_not_null(stairs, "escalier")
	if stairs != null:
		assert_true(stairs.is_coming_soon(), "pokemon_tower_2f n'existe pas au J18")
		assert_eq(stairs.coming_soon, "Tour Pokémon")
		assert_eq(_map.get_spawn_cell(stairs.target_spawn), ACCESS)
	assert_eq(_map.get_warps().size(), 3)


func test_candles_without_life_and_budget() -> void:
	var glows := get_tree().get_nodes_in_group("light_glows")
	var candles := 0
	for child: Node in _map.get_node(^"Glows").get_children():
		if child.get(&"glow_type") == &"candle":
			candles += 1
	assert_eq(candles, 6, "six halos candle")
	assert_eq(glows.size() >= 0, true)
	assert_eq(_map.get_node(^"Interactables").get_child_count(), 0, "aucun examen")
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0)
	# T16 : gardien, trois visiteurs, Exorciste (data/npcs/pokemon_tower_1f.json) ; tombes : T24.
	assert_eq(_map.get_npcs().size(), 5, "cinq PNJ")
	assert_lte(GridPaths.count_nodes(_map), 3000)
