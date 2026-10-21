extends GutTest
## Cartes de QA de la Force (passe systèmes 2, S2D, `systemes-2.md` §2.7, §2.14) : `qa_strength` et
## `qa_strength_b1`, construites d'après `tools/plans/qa_strength*.txt` par
## `tools/build_qa_strength.gd`, et le départ de débogage `s2_strength`. Retirées à la clôture de la
## passe (S2Z) avec ce test.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TOOL_STARTS := "res://tools/debug_start/"

var _plan: PlanGrid
var _plan_b1: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file("res://tools/plans/qa_strength.txt"), _plan.error)
	_plan_b1 = PlanGrid.new()
	assert_true(_plan_b1.load_file("res://tools/plans/qa_strength_b1.txt"), _plan_b1.error)


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _flags(list: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func _setup(map: GameMap) -> BoulderSetup:
	var setup := map.get_node_or_null(NodePath(BoulderSetup.NODE_NAME)) as BoulderSetup
	assert_not_null(setup, "nœud Boulders")
	return setup


func test_qa_strength_matches_its_grid() -> void:
	var map := _map(&"qa_strength")
	assert_eq([map.map_id, map.display_name, map.interior], [&"qa_strength", "QA Force", false])
	assert_true(MapCatalog.is_qa_map(&"qa_strength"))
	assert_eq(map.size, Vector2i(_plan.width, _plan.height))
	var grid := map.get_grid()
	for y: int in _plan.height:
		for x: int in _plan.width:
			var cell := Vector2i(x, y)
			var char: String = _plan.at(cell)
			assert_eq(grid.is_solid(cell), char == "#", "mur en %s" % cell)
			assert_eq(grid.is_water(cell), char == "w", "eau en %s" % cell)
			assert_false(grid.is_surfable(cell), "eau décor, non surfable en %s" % cell)
	assert_push_error_count(0)


func test_the_boulder_setup_follows_the_grid() -> void:
	var setup := _setup(_map(&"qa_strength"))
	assert_eq(setup.get_parent().name, &"QaStrength", "enfant direct de la racine")
	assert_eq(setup.boulder_cells.size(), 4)
	for id: String in ["rocher_1", "rocher_2", "rocher_3", "rocher_4"]:
		var index := setup.boulder_cells.find(_plan.cell_of(id))
		assert_gt(index, -1, id)
		assert_eq(setup.boulder_holes[index], int(_plan.attr(id, "trou")), "trou de %s" % id)
	assert_eq(setup.hole_cells, [Vector2i(4, 4), Vector2i(8, 14)] as Array[Vector2i])
	assert_eq(setup.hole_numbers, [1, 2] as Array[int])
	assert_eq(setup.hole_flags,
		[&"qa_strength_hole_1_filled", &"qa_strength_hole_2_filled"] as Array[StringName])
	assert_eq(setup.switch_cells, [Vector2i(19, 4)] as Array[Vector2i])
	assert_eq(setup.switch_flags, [&"qa_strength_switch_1"] as Array[StringName])
	assert_eq(setup.switch_ids.size(), 1)
	assert_eq(setup.no_push_cells, [Vector2i(11, 6)] as Array[Vector2i])
	var field := setup.to_field()
	assert_not_null(field)
	assert_push_error_count(0)


func test_holes_make_the_player_fall_until_filled() -> void:
	var map := _map(&"qa_strength")
	var maps := {&"qa_strength": map, &"qa_strength_b1": _map(&"qa_strength_b1")}
	for number: int in [1, 2]:
		var cell: Vector2i = _plan.cell_of("trou_%d" % number)
		var falls: Array[Warp] = []
		for warp: Warp in map.get_warps().get_at(cell):
			if warp.trigger == Warp.Trigger.FALL:
				falls.append(warp)
		assert_eq(falls.size(), 1, "un WarpPoint FALL en %s" % cell)
		var fall := falls[0]
		assert_eq([fall.target_map, fall.target_spawn],
			[&"qa_strength_b1", StringName("chute_joueur_%d" % number)])
		assert_eq(fall.direction, Vector2i.ZERO)
		assert_eq(fall.unless_flags,
			[StringName("qa_strength_hole_%d_filled" % number)] as Array[StringName])
		assert_true((maps[fall.target_map] as GameMap).has_spawn(fall.target_spawn))
		assert_false(map.get_grid().is_solid(cell), "le trou est praticable")
	assert_push_error_count(0)


func test_hole_drawings_follow_their_flag() -> void:
	var map := _map(&"qa_strength")
	map.apply_flag_gates(_flags())
	assert_true(map.get_node(^"Entities/TrouOuvert1").visible)
	assert_false(map.get_node(^"Entities/TrouBouche1").visible)
	assert_true(map.get_node(^"Entities/InterrupteurReleve").visible)
	assert_false(map.get_node(^"Entities/InterrupteurEnfonce").visible)
	map.apply_flag_gates(_flags([&"qa_strength_hole_1_filled", &"qa_strength_switch_1"]))
	assert_false(map.get_node(^"Entities/TrouOuvert1").visible)
	assert_true(map.get_node(^"Entities/TrouBouche1").visible)
	assert_true(map.get_node(^"Entities/TrouOuvert2").visible, "l'autre trou reste ouvert")
	assert_false(map.get_node(^"Entities/InterrupteurReleve").visible)
	assert_true(map.get_node(^"Entities/InterrupteurEnfonce").visible)
	assert_push_error_count(0)


func test_the_barrier_blocks_until_the_switch_flag() -> void:
	var map := _map(&"qa_strength")
	var grid := map.get_grid()
	var cells := _plan.cells_at("barriere_1")
	assert_eq(cells.size(), 4)
	for cell: Vector2i in cells:
		assert_false(grid.is_solid(cell), "la grille ne la compte pas comme un mur en %s" % cell)
	map.apply_flag_gates(_flags())
	for cell: Vector2i in cells:
		assert_true(grid.is_occupied(cell), "barrière fermée en %s" % cell)
		assert_false(grid.can_enter(cell, Vector2i.UP), "bloquée en %s" % cell)
	map.apply_flag_gates(_flags([&"qa_strength_switch_1"]))
	for cell: Vector2i in cells:
		assert_false(grid.is_occupied(cell), "barrière ouverte en %s" % cell)
		assert_true(grid.can_enter(cell, Vector2i.UP), "libre en %s" % cell)
	assert_push_error_count(0)


func test_sign_exits_and_spawns() -> void:
	var map := _map(&"qa_strength")
	var mount := _map(&"qa_mount")
	map.apply_flag_gates(_flags())
	var sign_cell := _plan.cell_of("panneau")
	assert_true(map.get_grid().is_occupied(sign_cell), "panneau bloquant")
	var found := map.get_interactions().get_at(sign_cell)
	assert_eq(found.size(), 1)
	assert_eq(found[0].dialogue_id, &"qa_strength_sign")
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	assert_true(dialogues.has_dialogue(&"qa_strength_sign"))
	assert_eq(map.get_spawn_cell(&"depart"), Vector2i(11, 14))
	assert_eq(map.get_spawn_cell(&"from_b1"), Vector2i(4, 9))
	for x: int in [11, 12]:
		var exit := map.get_warps().find_on_push(Vector2i(x, 15), Vector2i.DOWN)
		assert_not_null(exit, "sortie sud (%d, 15)" % x)
		assert_eq([exit.target_map, exit.target_spawn], [&"qa_mount", &"depart"])
		assert_false(map.get_grid().is_solid(Vector2i(x, 15)))
	assert_true(mount.has_spawn(&"depart"))
	assert_push_error_count(0)


func test_the_lower_floor() -> void:
	var map := _map(&"qa_strength_b1")
	var upper := _map(&"qa_strength")
	assert_eq([map.map_id, map.display_name], [&"qa_strength_b1", "QA Force B1"])
	assert_eq(map.size, Vector2i(_plan_b1.width, _plan_b1.height))
	for y: int in _plan_b1.height:
		for x: int in _plan_b1.width:
			assert_eq(map.get_grid().is_solid(Vector2i(x, y)), _plan_b1.at(Vector2i(x, y)) == "#")
	assert_eq(map.get_spawn_cell(&"chute_joueur_1"), Vector2i(4, 3))
	assert_eq(map.get_spawn_cell(&"chute_joueur_2"), Vector2i(8, 4))
	assert_eq(map.get_spawn_cell(&"from_strength"), Vector2i(9, 4))
	var ladder := map.get_warps().find_on_step(Vector2i(9, 5), Vector2i.UP)
	assert_not_null(ladder, "échelle")
	assert_eq([ladder.target_map, ladder.target_spawn], [&"qa_strength", &"from_b1"])
	assert_true(upper.has_spawn(ladder.target_spawn))
	# Rochers tombés : visibles et bloquants seulement une fois le trou bouché.
	var grid := map.get_grid()
	map.apply_flag_gates(_flags())
	assert_false(grid.is_occupied(Vector2i(4, 2)))
	assert_false(grid.is_occupied(Vector2i(8, 3)))
	map.apply_flag_gates(_flags([&"qa_strength_hole_1_filled"]))
	assert_true(grid.is_occupied(Vector2i(4, 2)))
	assert_false(grid.is_occupied(Vector2i(8, 3)))
	assert_true(grid.is_occupied(Vector2i(4, 2)) and not grid.is_solid(Vector2i(4, 2)))
	assert_false(grid.is_occupied(map.get_spawn_cell(&"chute_joueur_1")))
	assert_push_error_count(0)


func test_the_s2_strength_start_loads_and_strength_is_ready() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "s2_strength.json", data, items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"qa_strength", &"depart", Vector2i.UP])
	assert_eq(start.party.size(), 2)
	assert_eq(int(start.bag[&"hm04"]), 1)
	assert_true(&"badge_rainbow" in start.flags)
	var map := _map(start.map)
	assert_true(map.has_spawn(start.spawn))
	var rules := FieldMoves.new()
	assert_true(rules.load_file(), "\n".join(rules.get_errors()))
	var party := Party.new()
	for member: Dictionary in start.party:
		var pokemon := PokemonFactory.create(data, member["species"], int(member["level"]),
			GameRng.new(5))
		party.add(pokemon)
	assert_true(&"strength" in (start.party[0]["moves"] as Array[StringName]), "Force connue")
	assert_true(data.has_move(&"strength"))
	assert_eq(data.get_move(&"strength").type, &"normal")
	var bag := Bag.new()
	for item: StringName in start.bag:
		bag.add(item, start.bag[item])
	var flags := _flags(start.flags)
	var result := rules.check(&"strength", party, bag, flags, items, data)
	assert_eq(result.state, FieldMoves.State.READY)
	assert_eq(result.pokemon_index, 0, "Carapuce, compatible CS04")
