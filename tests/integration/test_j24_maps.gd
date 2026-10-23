extends GutTest
## Cartes du jalon 24 (T8, T11, T12, T15) construites par `tools/build_j24_seafoam.gd`,
## `tools/build_j24_sea.gd` et `build_painted_interiors.gd --cinnabar` : la grille fait foi
## (eau surfable, niveaux de sol, courants coupés par les drapeaux, rochers de [SeafoamState],
## chutes FALL vers l'étage du dessous, Surf forcé à l'atterrissage dans l'eau).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLOORS: Array[StringName] = [&"seafoam_1f", &"seafoam_b1f", &"seafoam_b2f", &"seafoam_b3f",
	&"seafoam_b4f"]
const SEA: Array[StringName] = [&"route_19", &"route_20", &"route_21", &"cinnabar_island"]


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _plan(map_id: StringName) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % map_id), plan.error)
	return plan


func _flags(list: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func test_sea_maps_surfable_water_is_the_grid_w() -> void:
	for map_id: StringName in SEA:
		var map := _map(map_id)
		var plan := _plan(map_id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		var grid := map.get_grid()
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(grid.is_surfable(cell), plan.at(cell) == "w",
					"%s %s surfable" % [map_id, cell])
	assert_push_error_count(0)


## Fusion du J24 dans `main` (2026-10-23) : bord nord de la Route 19 ↔ bord sud de Parmanie
## (J22), case pour case (colonne Parmanie = colonne Route 19 + 15), dans les deux sens.
func test_route_19_and_fuchsia_city_are_joined_cell_for_cell() -> void:
	var route := _map(&"route_19")
	var town := _map(&"fuchsia_city")
	var ways := [[route, town, Vector2i.UP, 15, town.size.y - 1],
		[town, route, Vector2i.DOWN, -15, 0]]
	for way: Array in ways:
		var from: GameMap = way[0]
		var to: GameMap = way[1]
		var count := 0
		for warp: Warp in from.get_warps().get_all():
			if warp.target_map != to.map_id:
				continue
			count += 1
			assert_false(warp.is_coming_soon(), "%s %s" % [from.map_id, warp.cell])
			assert_eq(warp.direction, way[2] as Vector2i, "%s %s" % [from.map_id, warp.cell])
			assert_true(to.has_spawn(warp.target_spawn), "%s" % warp.target_spawn)
			assert_eq(to.get_spawn_cell(warp.target_spawn),
				Vector2i(warp.cell.x + (way[3] as int), way[4] as int),
				"%s %s → %s" % [from.map_id, warp.cell, warp.target_spawn])
		assert_eq(count, 11, "%s → %s : terrasse (9 cases) et couloir (2)" % [from.map_id,
			to.map_id])


func test_seafoam_levels_and_water_follow_the_grid() -> void:
	for map_id: StringName in FLOORS:
		var map := _map(map_id)
		map.apply_flag_gates(_flags())
		var plan := _plan(map_id)
		var grid := map.get_grid()
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var c: String = plan.at(cell)
				if c == ":":
					assert_eq(grid.get_level(cell), GridWorld.Level.HIGH, "%s %s" % [map_id, cell])
				elif c == "=":
					assert_eq(grid.get_level(cell), GridWorld.Level.STAIRS, "%s %s" % [map_id, cell])
				elif c == ".":
					assert_eq(grid.get_level(cell), GridWorld.Level.LOW, "%s %s" % [map_id, cell])
				if "ws^v<>".contains(c):
					assert_true(grid.is_surfable(cell), "%s %s surfable" % [map_id, cell])
				if "#|ox".contains(c):
					assert_true(grid.is_solid(cell), "%s %s paroi" % [map_id, cell])


func test_current_1_is_cut_by_the_two_b2f_holes() -> void:
	var map := _map(&"seafoam_b3f")
	var grid := map.get_grid()
	map.apply_flag_gates(_flags())
	assert_ne(grid.get_current(Vector2i(15, 8)), Vector2i.ZERO, "courant 1 actif")
	map.apply_flag_gates(_flags([&"seafoam_b2f_hole_1_filled", &"seafoam_b2f_hole_2_filled"]))
	assert_eq(grid.get_current(Vector2i(15, 8)), Vector2i.ZERO, "eau calme")
	assert_true(grid.is_occupied(Vector2i(18, 6)), "rocher tombé en travers du chenal")


func test_holes_fall_to_a_landing_of_the_floor_below() -> void:
	for i: int in FLOORS.size() - 1:
		var map := _map(FLOORS[i])
		var below := _map(FLOORS[i + 1])
		var falls := 0
		for warp: Node in map.get_node(^"Warps").get_children():
			var point := warp as WarpPoint
			if point.trigger != Warp.Trigger.FALL:
				continue
			falls += 1
			assert_eq(point.target_map, FLOORS[i + 1])
			assert_not_null(below.get_node(^"Spawns").get_node_or_null(String(point.target_spawn)),
				"%s → %s" % [FLOORS[i], point.target_spawn])
			assert_eq(point.unless_flags.size(), 1, "trou bouché : plus de chute")
		assert_eq(falls, 2, String(FLOORS[i]))
	# Atterrissages dans l'eau (B3F, B4F) : Surf forcé.
	assert_true(_map(&"seafoam_b3f").forced_surf_cells.has(Vector2i(18, 7)))
	assert_true(_map(&"seafoam_b4f").forced_surf_cells.has(Vector2i(4, 14)))


func test_boulders_come_from_the_seafoam_state() -> void:
	var setup := _map(&"seafoam_b1f").get_node(^"Boulders") as BoulderSetup
	assert_true(setup is SeafoamBoulderSetup)
	var field := setup.to_field()
	assert_eq(field.boulders_at_load(_flags()), [] as Array[Vector2i], "rien n'est tombé du 1F")
	var fallen := field.boulders_at_load(_flags([&"seafoam_1f_hole_1_filled"]))
	assert_eq(fallen.size(), 1, "le rocher tombé du trou 1 du 1F")
	var b4f := (_map(&"seafoam_b4f").get_node(^"Boulders") as BoulderSetup).to_field()
	assert_eq(b4f.boulders_at_load(_flags([&"seafoam_b3f_hole_1_filled"])),
		[] as Array[Vector2i], "rocher tombé dans l'eau : dessin bloquant, pas un Boulder")
	var first := (_map(&"seafoam_1f").get_node(^"Boulders") as BoulderSetup).to_field()
	assert_eq(first.boulders_at_load(_flags()).size(), 2)
	assert_eq(first.boulders_at_load(_flags([&"seafoam_1f_hole_1_filled"])).size(), 1,
		"rocher désigné du trou 1 retiré")


func test_fossil_ready_gate_sets_and_tidies_the_flags() -> void:
	var map := _map(&"cinnabar_island")
	var flags := _flags([&"fossil_reviving_kabuto"])
	map.apply_flag_gates(flags)
	assert_true(flags.has_flag(&"fossil_ready"), "sortie sur la ville : prêt")
	flags.set_flag(&"fossil_revived_kabuto")
	map.apply_flag_gates(flags)
	assert_false(flags.has_flag(&"fossil_reviving_kabuto"))
	assert_false(flags.has_flag(&"fossil_ready"))
	var idle := _flags()
	map.apply_flag_gates(idle)
	assert_false(idle.has_flag(&"fossil_ready"))


## Départs de débogage du J24 (QA de Kevin) : fichiers valides, cartes et points réels, case
## d'arrivée praticable.
func test_debug_starts_are_valid() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for name: String in ["j24_surf", "j24_seafoam", "j24_seafoam_b3f", "j24_articuno",
			"j24_cinnabar"]:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, data, items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var map := _map(start.map)
		assert_true(map.has_spawn(start.spawn), "%s : %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		assert_true(start.flags.has(&"badge_soul") and start.flags.has(&"badge_rainbow"), name)
