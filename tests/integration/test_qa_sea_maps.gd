extends GutTest
## Cartes de QA du Surf (passe systèmes 2, T16, `systemes-2.md` §2.5, §2.6, §2.14) : `qa_sea` et
## `qa_sea_2`, construites d'après `tools/plans/qa_sea*.txt` par `tools/build_qa_sea.gd`, et le
## départ de débogage `s2_surf`. Retirées à la clôture de la passe (S2Z) avec ce test.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TOOL_STARTS := "res://tools/debug_start/"

var _sea_plan: PlanGrid
var _sea2_plan: PlanGrid


func before_all() -> void:
	_sea_plan = PlanGrid.new()
	assert_true(_sea_plan.load_file("res://tools/plans/qa_sea.txt"), _sea_plan.error)
	_sea2_plan = PlanGrid.new()
	assert_true(_sea2_plan.load_file("res://tools/plans/qa_sea_2.txt"), _sea2_plan.error)


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _check_sea(map: GameMap, plan: PlanGrid) -> void:
	var grid := map.get_grid()
	assert_eq(map.size, Vector2i(plan.width, plan.height))
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var char: String = plan.at(cell)
			assert_eq(grid.is_surfable(cell), "w>vs".contains(char), "surfable en %s" % cell)
			assert_eq(grid.is_water(cell), "w>vs~".contains(char), "eau en %s" % cell)
			assert_eq(grid.is_solid(cell), char == "#", "falaise en %s" % cell)
			var flow := Vector2i.RIGHT if char == ">" else (Vector2i.DOWN if char == "v" \
				else Vector2i.ZERO)
			assert_eq(grid.get_current(cell), flow, "courant en %s" % cell)
	var forced := plan.cells_of("s")
	assert_eq(map.forced_surf_cells.size(), forced.size())
	for cell: Vector2i in forced:
		assert_true(cell in map.forced_surf_cells, "Surf forcé en %s" % cell)


func test_qa_sea_matches_its_grid() -> void:
	var sea := _map(&"qa_sea")
	assert_eq([sea.map_id, sea.display_name, sea.interior], [&"qa_sea", "QA Surf", false])
	assert_true(MapCatalog.is_qa_map(&"qa_sea"))
	_check_sea(sea, _sea_plan)
	assert_eq(sea.current_cells.size(), 9 + 6, "9 flèches > et 6 flèches v (21, 4..9)")
	assert_eq(sea.current_cells[Vector2i(12, 4)], Vector2i.RIGHT)
	assert_eq(sea.current_cells[Vector2i(21, 4)], Vector2i.DOWN)
	assert_eq(sea.current_cells[Vector2i(21, 9)], Vector2i.DOWN)
	assert_false(sea.current_cells.has(Vector2i(21, 10)), "le passage n'est pas un courant")
	assert_push_error_count(0)


func test_qa_sea_2_matches_its_grid() -> void:
	var sea2 := _map(&"qa_sea_2")
	assert_eq([sea2.map_id, sea2.display_name], [&"qa_sea_2", "QA Surf 2"])
	_check_sea(sea2, _sea2_plan)
	assert_true(sea2.current_cells.is_empty())
	assert_push_error_count(0)


func test_the_island_and_the_beach_are_land() -> void:
	var grid := _map(&"qa_sea").get_grid()
	for cell: Vector2i in [Vector2i(1, 2), Vector2i(6, 16), Vector2i(16, 8), Vector2i(18, 9)]:
		assert_false(grid.is_water(cell), "terre en %s" % cell)
		assert_false(grid.is_solid(cell))
	assert_true(grid.is_water(Vector2i(0, 0)), "eau décor")
	assert_false(grid.is_surfable(Vector2i(0, 0)))
	assert_false(grid.is_surfable(Vector2i(25, 5)), "colonne 25 hors bande de sortie : décor")


func test_fishable_cells_are_the_water_column_along_the_beach() -> void:
	var sea := _map(&"qa_sea")
	var grid := sea.get_grid()
	assert_eq(sea.fishable_cells.size(), 15)
	for y: int in range(2, 17):
		var cell := Vector2i(7, y)
		assert_true(cell in sea.fishable_cells, "pêche en %s" % cell)
		assert_true(grid.is_surfable(cell))
	assert_true(_map(&"qa_sea_2").fishable_cells.is_empty())


func test_spawns_match_the_positions() -> void:
	var sea := _map(&"qa_sea")
	assert_eq(sea.get_spawn_cell(&"depart"), _sea_plan.cell_of("depart"))
	assert_eq(sea.get_spawn_cell(&"from_east"), Vector2i(24, 12))
	assert_true(sea.get_grid().is_surfable(sea.get_spawn_cell(&"from_east")))
	assert_false(sea.get_grid().is_water(sea.get_spawn_cell(&"depart")))
	var sea2 := _map(&"qa_sea_2")
	assert_eq(sea2.get_spawn_cell(&"from_current"), Vector2i(5, 3))
	assert_eq(sea2.get_spawn_cell(&"from_west"), Vector2i(0, 12))
	assert_eq(sea2.get_spawn_cell(&"depart"), Vector2i(0, 12))
	for cell: Vector2i in [Vector2i(5, 3), Vector2i(0, 12)]:
		assert_true(sea2.get_grid().is_surfable(cell))


func test_warps_edges_current_end_and_exits() -> void:
	var sea := _map(&"qa_sea")
	var sea2 := _map(&"qa_sea_2")
	var maps := {&"qa_sea": sea, &"qa_sea_2": sea2}
	var mount := _map(&"qa_mount")
	assert_eq(sea.get_warps().get_all().size(), 7, "2 sorties, le passage, 4 cases du bord est")
	assert_eq(sea2.get_warps().get_all().size(), 4, "4 cases du bord ouest")
	for y: int in range(11, 15):
		var east := sea.get_warps().find_on_push(Vector2i(25, y), Vector2i.RIGHT)
		assert_not_null(east, "bord est (25, %d)" % y)
		assert_eq([east.target_map, east.target_spawn], [&"qa_sea_2", &"from_west"])
		assert_eq(east.facing, Vector2i.RIGHT)
		assert_null(sea.get_warps().find_on_push(Vector2i(25, y), Vector2i.UP))
		var west := sea2.get_warps().find_on_push(Vector2i(0, y), Vector2i.LEFT)
		assert_not_null(west, "bord ouest (0, %d)" % y)
		assert_eq([west.target_map, west.target_spawn], [&"qa_sea", &"from_east"])
	assert_null(sea.get_warps().find_on_push(Vector2i(25, 10), Vector2i.RIGHT))
	var end := sea.get_warps().find_on_step(Vector2i(21, 10), Vector2i.DOWN)
	assert_not_null(end, "fin du courant")
	assert_eq([end.target_map, end.target_spawn], [&"qa_sea_2", &"from_current"])
	for x: int in [2, 3]:
		var exit := sea.get_warps().find_on_push(Vector2i(x, 17), Vector2i.DOWN)
		assert_not_null(exit, "sortie sud (%d, 17)" % x)
		assert_eq([exit.target_map, exit.target_spawn], [&"qa_mount", &"depart"])
		assert_false(sea.get_grid().is_solid(Vector2i(x, 17)), "case de sortie praticable")
	maps[&"qa_mount"] = mount
	for id: StringName in [&"qa_sea", &"qa_sea_2"]:
		for warp: Warp in (maps[id] as GameMap).get_warps().get_all():
			assert_true(maps.has(warp.target_map), "carte %s" % warp.target_map)
			assert_true((maps[warp.target_map] as GameMap).has_spawn(warp.target_spawn),
				"%s → %s:%s" % [id, warp.target_map, warp.target_spawn])
	assert_push_error_count(0)


func test_the_s2_surf_start_loads_and_surf_is_ready() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "s2_surf.json", data, items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"qa_sea", &"depart", Vector2i.UP])
	assert_eq(start.party.size(), 2)
	assert_eq(start.companion, 0)
	assert_eq(int(start.bag[&"hm03"]), 1)
	assert_true(&"badge_soul" in start.flags)
	var sea := _map(start.map)
	assert_true(sea.has_spawn(start.spawn))
	assert_false(sea.get_grid().is_water(sea.get_spawn_cell(start.spawn)))
	var rules := FieldMoves.new()
	assert_true(rules.load_file(), "\n".join(rules.get_errors()))
	var party := Party.new()
	for member: Dictionary in start.party:
		party.add(PokemonFactory.create(data, member["species"], int(member["level"]),
			GameRng.new(5)))
	var bag := Bag.new()
	for item: StringName in start.bag:
		bag.add(item, start.bag[item])
	var flags := StoryFlags.new()
	for flag: StringName in start.flags:
		flags.set_flag(flag)
	var result := rules.check(&"surf", party, bag, flags, items, data)
	assert_eq(result.state, FieldMoves.State.READY)
	assert_eq(result.pokemon_index, 0, "Carapuce, compatible CS03")
	assert_true(data.has_move(&"surf"))
	assert_eq(data.get_move(&"surf").type, &"water")
