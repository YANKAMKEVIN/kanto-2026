extends GutTest
## Cartes du jalon 25 (T14, T15, T18, T20) construites par `tools/build_pokemon_mansion.gd`,
## `tools/build_j25_rooms.gd`, `tools/build_j24_sea.gd` (porte du Manoir, X-25) et
## `tools/build_pewter_city.gd` (porte arrière du Musée) : la grille fait foi (murs, grilles A / B
## de l'interrupteur, herses de l'Arène, escaliers, trous FALL, sorties, points d'examen).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MANSION: Dictionary = {&"pokemon_mansion_1f": "manoir_1f", &"pokemon_mansion_2f": "manoir_2f",
	&"pokemon_mansion_3f": "manoir_3f", &"pokemon_mansion_b1f": "manoir_b1f"}
const SWITCH := &"mansion_switch_on"


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _plan(name: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % name), plan.error)
	return plan


func _flags(list: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func _blocked(map: GameMap, cell: Vector2i) -> bool:
	return map.get_grid().is_solid(cell) or map.get_grid().is_occupied(cell)


func test_mansion_walls_and_switch_gates_follow_the_grid() -> void:
	for map_id: StringName in MANSION:
		var map := _map(map_id)
		var plan := _plan(MANSION[map_id])
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		map.apply_flag_gates(_flags())
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var c: String = plan.at(cell)
				if "#TP".contains(c):
					assert_true(_blocked(map, cell), "%s %s bloqué" % [map_id, cell])
				elif c == "a":
					assert_true(_blocked(map, cell), "%s %s : A fermée sur ARRÊT" % [map_id, cell])
				elif c == "b":
					assert_false(_blocked(map, cell), "%s %s : B ouverte sur ARRÊT" % [map_id, cell])
		map.apply_flag_gates(_flags([SWITCH]))
		for cell: Vector2i in plan.cells_of("a"):
			assert_false(_blocked(map, cell), "%s %s : A ouverte sur MARCHE" % [map_id, cell])
		for cell: Vector2i in plan.cells_of("b"):
			assert_true(_blocked(map, cell), "%s %s : B fermée sur MARCHE" % [map_id, cell])
	assert_push_error_count(0)


func test_mansion_stairs_holes_and_exits_lead_to_existing_spawns() -> void:
	var spawns: Dictionary = {}
	for map_id: StringName in MANSION:
		var map := _map(map_id)
		var plan := _plan(MANSION[map_id])
		for warp: Warp in map.get_warps().get_all():
			var key := "%s:%s" % [warp.target_map, warp.target_spawn]
			spawns[key] = String(map_id)
		var holes := plan.cells_of("O")
		for cell: Vector2i in holes:
			var found: Array[Warp] = map.get_warps().get_at(cell)
			assert_eq(found.size(), 1, "%s %s : un trou" % [map_id, cell])
			if found.size() == 1:
				assert_eq(found[0].trigger, Warp.Trigger.FALL, "Warp FALL du J24")
				assert_eq(found[0].target_spawn, &"chute")
		for cell: Vector2i in plan.cells_of("E"):
			var found: Array[Warp] = map.get_warps().get_at(cell)
			assert_eq(found.size(), 1, "%s %s : seuil" % [map_id, cell])
			if found.size() == 1:
				assert_eq([found[0].trigger, found[0].target_map, found[0].target_spawn],
					[Warp.Trigger.PUSH, &"cinnabar_island", &"from_manoir"])
	assert_eq(_plan("manoir_3f").cells_of("O").size(), 3, "trois trous au 3F")
	for key: String in spawns:
		var target := StringName(key.get_slice(":", 0))
		var spawn := StringName(key.get_slice(":", 1))
		assert_true(_map(target).has_spawn(spawn), "%s (depuis %s)" % [key, spawns[key]])
	assert_push_error_count(0)


func test_statues_are_read_facing_them_and_journals_anywhere() -> void:
	var statues := 0
	var journals := 0
	for map_id: StringName in MANSION:
		var map := _map(map_id)
		var plan := _plan(MANSION[map_id])
		for cell: Vector2i in plan.cells_of("T"):
			var points := map.get_interactions().get_at(cell)
			assert_eq(points.size(), 1, "%s %s statue" % [map_id, cell])
			if points.size() == 1:
				assert_eq(points[0].dialogue_id, &"mansion_statue")
				assert_eq(points[0].facing, Vector2i.UP, "Action face à elle (RB)")
			statues += 1
		for cell: Vector2i in plan.cells_of("P"):
			var points := map.get_interactions().get_at(cell)
			assert_eq(points.size(), 1, "%s %s pupitre" % [map_id, cell])
			if points.size() == 1:
				assert_string_starts_with(String(points[0].dialogue_id), "mansion_journal_")
			journals += 1
	assert_eq([statues, journals], [5, 4], "5 statues (1F, 2F, 3F, 2 au B1F), 4 journaux")


func test_cinnabar_island_opens_the_mansion_and_resets_the_switch() -> void:
	var island := _map(&"cinnabar_island")
	var plan := _plan("cinnabar_island")
	for cell: Vector2i in plan.cells_at("porte_manoir"):
		var found: Array[Warp] = island.get_warps().get_at(cell)
		assert_eq(found.size(), 1, "porte du Manoir %s" % cell)
		if found.size() == 1:
			assert_eq([found[0].target_map, found[0].target_spawn],
				[&"pokemon_mansion_1f", &"depuis_ile"])
	assert_true(island.has_spawn(&"from_manoir"))
	assert_true(island.has_spawn(&"from_arene"))
	assert_true(_map(&"pokemon_mansion_1f").has_spawn(&"depuis_ile"))
	var flags := _flags([SWITCH])
	island.apply_flag_gates(flags)
	assert_false(flags.has_flag(SWITCH), "interrupteur remis à ARRÊT sur l'île")
	assert_push_error_count(0)


func test_gym_gates_open_on_their_flag_or_their_trainer() -> void:
	var gym := _map(&"cinnabar_gym")
	var plan := _plan("cramois_arene")
	gym.apply_flag_gates(_flags())
	for cell: Vector2i in plan.cells_of("p"):
		assert_true(_blocked(gym, cell), "herse %s fermée" % cell)
	var quiz := GymQuiz.load_default()
	for id: int in quiz.ids():
		var herse: Array[Vector2i] = plan.cells_at("herse_%d" % id)
		gym.apply_flag_gates(_flags([quiz.gate_flag(id)]))
		assert_false(_blocked(gym, herse[0]), "herse %d : bonne réponse" % id)
		gym.apply_flag_gates(_flags([TrainerRules.beaten_flag(quiz.trainer_id(id))]))
		assert_false(_blocked(gym, herse[0]), "herse %d : Dresseur battu" % id)
		var points := gym.get_interactions().get_at(plan.cell_of("machine_%d" % id))
		assert_eq(points.size(), 1)
		if points.size() == 1:
			assert_eq([points[0].dialogue_id, points[0].facing],
				[StringName("cinnabar_gym_quiz_%d" % id), Vector2i.UP])
	var exits: Array[Warp] = gym.get_warps().get_at(plan.cell_of("entree"))
	assert_eq(exits.size(), 1)
	if exits.size() == 1:
		assert_eq([exits[0].target_map, exits[0].target_spawn], [&"cinnabar_island", &"from_arene"])
	assert_true(gym.has_spawn(&"depuis_ile"))
	assert_push_error_count(0)


func test_museum_reserve_is_behind_a_cut_tree() -> void:
	var city := _map(&"pewter_city")
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/argenta.txt"), plan.error)
	var tree := plan.cell_of("arbre_reserve")
	city.apply_flag_gates(_flags())
	assert_true(city.get_grid().is_occupied(tree), "l'arbre ferme la porte arrière")
	city.apply_flag_gates(_flags([&"cut_pewter_museum_tree"]))
	assert_false(city.get_grid().is_occupied(tree), "coupé : passage libre")
	var door: Warp = city.get_warps().find_on_push(tree, Vector2i.LEFT)
	assert_not_null(door, "porte poussée vers l'ouest")
	if door != null:
		assert_eq([door.target_map, door.target_spawn], [&"pewter_museum_reserve", &"entree"])
	assert_true(city.has_spawn(&"from_museum_reserve"))
	var reserve := _map(&"pewter_museum_reserve")
	assert_true(reserve.has_spawn(&"entree"))
	var exits: Array[Warp] = reserve.get_warps().get_at(Vector2i(7, 8))
	assert_eq(exits.size(), 1)
	if exits.size() == 1:
		assert_eq([exits[0].target_map, exits[0].target_spawn],
			[&"pewter_city", &"from_museum_reserve"])
	assert_push_error_count(0)
