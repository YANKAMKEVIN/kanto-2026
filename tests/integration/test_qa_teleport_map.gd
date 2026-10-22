extends GutTest
## Cartes de QA `qa_teleport` et `qa_teleport_2` (passe systèmes 2, T28, systemes-2.md §2.9,
## §2.10, §2.14), sur les vraies scènes : chaque téléporteur mène à un spawn qui existe, les
## portes à carte bloquent leur case sans le drapeau et la libèrent avec, le point OUVRIR est
## là, la Carte Magnétique est au sol. Retiré avec les cartes à la clôture de la passe (S2Z).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const DOORS: Dictionary[StringName, Vector2i] = {&"ab": Vector2i(9, 3), &"bd": Vector2i(15, 6)}

var _a: GameMap
var _b: GameMap
var _plan_a: PlanGrid
var _plan_b: PlanGrid


func before_each() -> void:
	_plan_a = PlanGrid.new()
	_plan_b = PlanGrid.new()
	assert_true(_plan_a.load_file("res://tools/plans/qa_teleport.txt"), _plan_a.error)
	assert_true(_plan_b.load_file("res://tools/plans/qa_teleport_2.txt"), _plan_b.error)
	_a = (load(MapCatalog.scene_path(&"qa_teleport")) as PackedScene).instantiate() as GameMap
	_b = (load(MapCatalog.scene_path(&"qa_teleport_2")) as PackedScene).instantiate() as GameMap
	add_child_autofree(_a)
	add_child_autofree(_b)


func test_metadata() -> void:
	assert_true(_a.interior)
	assert_true(_b.interior)
	assert_eq(_a.display_name, "QA Téléporteurs")
	assert_eq(_a.size, Vector2i(20, 13))
	assert_eq(_b.size, Vector2i(10, 8))
	assert_true(_a.has_spawn(&"start"))
	assert_eq(_a.get_spawn_cell(&"start"), Vector2i(4, 11))


func test_every_teleporter_targets_an_existing_spawn() -> void:
	var maps: Dictionary[StringName, GameMap] = {&"qa_teleport": _a, &"qa_teleport_2": _b}
	var count := 0
	for map: GameMap in maps.values():
		for warp: Warp in map.get_warps().get_all():
			if not warp.is_teleport():
				continue
			count += 1
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
			assert_true(maps.has(warp.target_map), "%s : carte cible" % warp.target_map)
			assert_true((maps[warp.target_map] as GameMap).has_spawn(warp.target_spawn),
				"%s:%s existe" % [warp.target_map, warp.target_spawn])
	assert_eq(count, 7 + 1, "7 téléporteurs dans qa_teleport, 1 dans qa_teleport_2")


func test_teleporters_match_the_plan() -> void:
	for id: String in _plan_a.positions:
		if _plan_a.positions[id]["kind"] != "teleporteur":
			continue
		var found := _a.get_warps().get_at(_plan_a.cell_of(id))
		assert_eq(found.size(), 1, id)
		var vers := _plan_a.attr(id, "vers")
		assert_eq(String(found[0].target_map), vers.get_slice(":", 0), id)
		assert_eq(String(found[0].target_spawn), vers.get_slice(":", 1), id)
		assert_true(found[0].is_teleport(), id)


func test_exits_lead_to_celadon() -> void:
	for cell: Vector2i in [Vector2i(4, 12), Vector2i(5, 12)]:
		var warp: Warp = _a.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, str(cell))
		assert_eq(warp.target_map, &"celadon_city")
		var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate()
		add_child_autofree(city)
		assert_true((city as GameMap).has_spawn(warp.target_spawn))


func test_key_doors_block_without_flag_and_free_with_it() -> void:
	var flags := StoryFlags.new()
	_a.apply_flag_gates(flags)
	for door_id: StringName in DOORS:
		var cell: Vector2i = DOORS[door_id]
		assert_true(_a.get_grid().is_occupied(cell), "%s fermée" % door_id)
		flags.set_flag(KeyDoor.open_flag(&"qa_teleport", door_id))
		_a.apply_flag_gates(flags)
		assert_false(_a.get_grid().is_occupied(cell), "%s ouverte" % door_id)
		assert_false(_a.get_grid().is_solid(cell), "%s praticable" % door_id)


func test_open_flag_name() -> void:
	assert_eq(KeyDoor.open_flag(&"qa_teleport", &"ab"), &"door_qa_teleport_ab_open")


func test_open_points_exist_and_vanish_with_the_flag() -> void:
	var flags := StoryFlags.new()
	for door_id: StringName in DOORS:
		var cell: Vector2i = DOORS[door_id]
		var found := _a.get_interactions().find(cell, Vector2i.DOWN)
		assert_not_null(found, "%s : point OUVRIR" % door_id)
		assert_eq(found.kind, Interaction.Kind.OPEN)
		assert_eq(found.dialogue_id, &"key_door_locked")
		assert_true(found.is_available(flags))
		flags.set_flag(KeyDoor.open_flag(&"qa_teleport", door_id))
		assert_false(found.is_available(flags))


func test_card_key_lies_on_the_floor() -> void:
	var npc := _b.get_npc(&"qa_teleport_2_card_key")
	assert_not_null(npc)
	assert_eq(npc.get_cell(), Vector2i(7, 5))


func test_goal_examine_point() -> void:
	var found := _a.get_interactions().find(Vector2i(14, 9), Vector2i.UP)
	assert_not_null(found)
	assert_eq(found.dialogue_id, &"qa_teleport_goal")


func test_blocked_cells_follow_the_grid() -> void:
	var grid := _a.get_grid()
	for y: int in _plan_a.height:
		for x: int in _plan_a.width:
			var cell := Vector2i(x, y)
			var walkable := _plan_a.is_walkable(cell)
			if _plan_a.at(cell) == "K":
				continue
			assert_eq(grid.is_solid(cell), not walkable, str(cell))


func test_debug_start_is_valid_and_lands_on_the_start_spawn() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/s2_teleport.json", data, items),
		"\n".join(start.get_errors()))
	assert_eq(start.map, &"qa_teleport")
	assert_true(_a.has_spawn(start.spawn))
	assert_true(start.flags.is_empty())
	assert_false(start.bag.has(&"card_key"), "pas de Carte Magnétique au départ")
