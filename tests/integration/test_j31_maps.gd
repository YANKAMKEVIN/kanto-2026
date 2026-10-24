extends GutTest
## Cartes du jalon 31 (T6 à T8, 31A) construites par `tools/build_cerulean_cave.gd` et
## `tools/build_cerulean_city.gd` : la grille fait foi (niveaux de sol, eau surfable et pêchable,
## roche), échelles appariées d'un étage à l'autre, bouche du 1F ↔ îlot d'Azuria (fermée sans le
## titre de Champion), objets visibles et cachés, Mewtwo présent puis absent, objets du 1F pris
## depuis l'eau, départs de débogage de la QA téléphone.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLOORS: Array[StringName] = [&"cerulean_cave_1f", &"cerulean_cave_2f", &"cerulean_cave_b1f"]
const CHAMPION: StringName = &"league_champion_defeated"
## Bouche de la Grotte Azurée sur la grille d'Azuria (`A`, îlot de la baie est).
const MOUTH: Array[Vector2i] = [Vector2i(52, 6), Vector2i(53, 6)]


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


func _ladders(map: GameMap) -> Dictionary:
	var by_pair := {}
	for node: Node in map.get_node(^"Warps").get_children():
		if String(node.name).begins_with("Echelle_"):
			by_pair[String(node.name).trim_prefix("Echelle_")] = node as WarpPoint
	return by_pair


func test_floors_follow_the_grid() -> void:
	for map_id: StringName in FLOORS:
		var map := _map(map_id)
		var plan := _plan(map_id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		assert_eq(map.display_name, "Grotte Azurée")
		assert_false(map.interior, "grotte : compagnon visible, comme les Îles Écume")
		var grid := map.get_grid()
		var water: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var c: String = plan.at(cell)
				assert_eq(grid.is_surfable(cell), c == "w", "%s %s surfable" % [map_id, cell])
				if c == "w":
					water.append(cell)
				elif c == ":":
					assert_eq(grid.get_level(cell), GridWorld.Level.HIGH, "%s %s" % [map_id, cell])
				elif c == "=":
					assert_eq(grid.get_level(cell), GridWorld.Level.STAIRS, "%s %s" % [map_id, cell])
				elif c == ".":
					assert_eq(grid.get_level(cell), GridWorld.Level.LOW, "%s %s" % [map_id, cell])
				if "#x".contains(c):
					assert_true(grid.is_solid(cell), "%s %s roche" % [map_id, cell])
				elif plan.walkable.contains(c) and c != "w":
					assert_false(grid.is_solid(cell), "%s %s praticable" % [map_id, cell])
		assert_eq(map.fishable_cells, water, "%s : Super Canne sur toute l'eau" % map_id)
		assert_eq(map.forced_surf_cells, [] as Array[Vector2i], String(map_id))
	assert_push_error_count(0)


func test_ladders_are_paired_both_ways() -> void:
	var maps := {}
	for map_id: StringName in FLOORS:
		maps[map_id] = _map(map_id)
	var count := 0
	for map_id: StringName in FLOORS:
		var map: GameMap = maps[map_id]
		var ladders := _ladders(map)
		for pair: String in ladders:
			count += 1
			var warp: WarpPoint = ladders[pair]
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
			assert_true(maps.has(warp.target_map), "%s %s → %s" % [map_id, pair, warp.target_map])
			var other: GameMap = maps[warp.target_map]
			assert_eq(warp.target_spawn, StringName("arrivee_" + pair))
			assert_true(other.has_spawn(warp.target_spawn), "%s → %s" % [pair, warp.target_spawn])
			var back: WarpPoint = _ladders(other).get(pair)
			assert_not_null(back, "%s : échelle de retour" % pair)
			if back != null:
				assert_eq(back.target_map, map_id, "%s : retour" % pair)
			# On arrive à côté de l'échelle, sur une case praticable et non sur un passage.
			var landing := other.get_spawn_cell(warp.target_spawn)
			assert_false(other.get_grid().is_solid(landing), "%s %s" % [pair, landing])
			assert_eq(other.get_warps().get_at(landing).size(), 0, "%s %s" % [pair, landing])
	assert_eq(count, 14, "7 paires, deux sens (P1..P6 1F ↔ 2F, P7 1F ↔ B1F)")


func test_mouth_joins_the_first_floor_and_cerulean_bay() -> void:
	var cave := _map(&"cerulean_cave_1f")
	var city := _map(&"cerulean_city")
	var exits := 0
	for warp: Warp in cave.get_warps().get_all():
		if warp.target_map != &"cerulean_city":
			continue
		exits += 1
		assert_eq(warp.direction, Vector2i.DOWN)
		assert_eq(warp.target_spawn, &"from_cerulean_cave")
	assert_eq(exits, 2, "bouche (24..25, 17)")
	assert_true(city.has_spawn(&"from_cerulean_cave"))
	var arrival := city.get_spawn_cell(&"from_cerulean_cave")
	assert_eq(arrival, Vector2i(52, 7), "dans l'eau devant la bouche")
	assert_true(city.get_grid().is_surfable(arrival), "retour en Surf")
	var entries := 0
	for warp: Warp in city.get_warps().get_all():
		if warp.target_map != &"cerulean_cave_1f":
			continue
		entries += 1
		assert_true(MOUTH.has(warp.cell), "%s" % warp.cell)
		assert_eq(warp.target_spawn, &"entree")
		assert_true(cave.has_spawn(&"entree"))
	assert_eq(entries, 2)
	assert_push_error_count(0)


## 31A : la bouche est une case d'eau surfable de l'îlot, occupée tant que l'accès est refusé
## ([CeruleanCaveAccess]) ; face à elle, EXAMINER donne le refus du §4 (validé par Kevin).
func test_mouth_is_closed_until_the_champion_title() -> void:
	var city := _map(&"cerulean_city")
	var grid := city.get_grid()
	city.apply_flag_gates(_flags([&"badge_earth"]))
	for cell: Vector2i in MOUTH:
		assert_true(grid.is_surfable(cell), "%s" % cell)
		assert_true(grid.is_occupied(cell), "%s fermée" % cell)
		var target := city.get_interactions().find(cell, Vector2i.UP)
		assert_not_null(target, "%s : examen" % cell)
		if target != null:
			assert_eq(target.dialogue_id, CeruleanCaveAccess.REFUSAL_DIALOGUE)
			assert_eq(target.unless_flags, [CHAMPION] as Array[StringName])
	city.apply_flag_gates(_flags([CHAMPION]))
	for cell: Vector2i in MOUTH:
		assert_false(grid.is_occupied(cell), "%s ouverte" % cell)
		# QA A17 du 2026-10-24 : la bouche était peinte en paroi (solide), donc refusée au Surf.
		assert_false(grid.is_solid(cell), "%s : de l'eau, pas une paroi" % cell)
		assert_true(grid.can_enter_as(cell, Vector2i.UP, GridWorld.MoveMode.SURF),
			"%s : on y entre en Surf depuis la baie" % cell)
	# Le canal à l'est du pont de l'Arène et la baie se surfent ; le canal ouest reste du décor.
	assert_true(grid.is_surfable(Vector2i(49, 7)), "baie, au pied du quai est")
	assert_true(grid.is_surfable(Vector2i(42, 15)), "canal, à l'est du pont de l'Arène")
	assert_false(grid.is_surfable(Vector2i(36, 15)), "canal, entre les deux ponts")
	assert_false(grid.is_surfable(Vector2i(27, 5)), "canal vertical")


func test_items_and_mewtwo_follow_the_flags() -> void:
	var expected := {
		&"cerulean_cave_1f": [&"cerulean_cave_1f_item_1", &"cerulean_cave_1f_item_2",
			&"cerulean_cave_1f_item_3"],
		&"cerulean_cave_2f": [&"cerulean_cave_2f_item_1", &"cerulean_cave_2f_item_2",
			&"cerulean_cave_2f_item_3"],
		&"cerulean_cave_b1f": [&"cerulean_cave_b1f_item_1", &"cerulean_cave_b1f_item_2",
			&"mewtwo"],
	}
	for map_id: StringName in FLOORS:
		var map := _map(map_id)
		var plan := _plan(map_id)
		map.refresh_npcs(_flags())
		var taken: Array[StringName] = []
		for id: StringName in expected[map_id]:
			var npc := map.get_npc(id)
			assert_not_null(npc, "%s : %s" % [map_id, id])
			if npc != null and plan.positions.has(String(id)):
				assert_eq(npc.get_cell(), plan.cell_of(String(id)), "%s : case de la grille" % id)
			taken.append(&"mewtwo_encounter_resolved" if id == &"mewtwo"
				else StringName("got_" + String(id)))
		map.refresh_npcs(_flags(taken))
		for id: StringName in expected[map_id]:
			assert_null(map.get_npc(id), "%s : absent une fois résolu" % id)
	var b1f := _map(&"cerulean_cave_b1f")
	b1f.refresh_npcs(_flags([&"mewtwo_caught"]))
	assert_not_null(b1f.get_npc(&"mewtwo"), "seule la résolution le retire (fuite : il reste)")
	assert_eq(b1f.get_spawn_cell(&"mewtwo_front"), Vector2i(27, 12), "départ de débogage")
	assert_push_error_count(0)


## Objets cachés : point d'examen sur l'indice `x` (roche), visé depuis la case de la grille.
func test_hidden_items_are_examined_from_their_floor_cell() -> void:
	for entry: Array in [[&"cerulean_cave_1f", &"cerulean_cave_1f_hidden_1", Vector2i(14, 11)],
			[&"cerulean_cave_b1f", &"cerulean_cave_b1f_hidden_1", Vector2i(27, 3)]]:
		var map := _map(entry[0])
		var plan := _plan(entry[0])
		var stand: Vector2i = plan.cell_of(String(entry[1]))
		var clue: Vector2i = entry[2]
		assert_eq(plan.at(clue), "x")
		assert_false(map.get_grid().is_solid(stand), "%s praticable" % stand)
		var target := InteractionFinder.find(map.get_grid(), map.get_interactions(), stand,
			clue - stand)
		assert_not_null(target, String(entry[1]))
		if target != null:
			assert_eq(target.dialogue_id, entry[1])
			assert_eq(target.unless_flags, [StringName("got_" + String(entry[1]))]
				as Array[StringName])


## Constat du §10 : la Guérison (7, 13) et le Max Élixir (19, 3) du 1F ne se touchent qu'en Surf,
## face à l'objet ; aucune case de sol ne les borde.
func test_first_floor_items_are_taken_from_the_water() -> void:
	var map := _map(&"cerulean_cave_1f")
	map.refresh_npcs(_flags())
	var grid := map.get_grid()
	for entry: Array in [[&"cerulean_cave_1f_item_1", Vector2i(7, 13)],
			[&"cerulean_cave_1f_item_2", Vector2i(19, 3)]]:
		var item: Vector2i = entry[1]
		var from_water := 0
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var stand: Vector2i = item - step
			if grid.is_surfable(stand):
				from_water += 1
				var target := InteractionFinder.find(grid, map.get_interactions(), stand, step)
				assert_not_null(target, "%s depuis l'eau %s" % [entry[0], stand])
				if target != null:
					assert_eq(target.dialogue_id, entry[0])
			else:
				assert_true(grid.is_solid(stand), "%s : %s n'est pas un sol" % [entry[0], stand])
		assert_gt(from_water, 0, "%s : au moins une case d'eau voisine" % entry[0])


func test_world_data_knows_the_cave() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "zones")
	var lighting := LightingLibrary.new()
	assert_true(lighting.load_file(), "lumière")
	var data := PokemonData.new()
	data.load_dir()
	var encounters := EncounterLibrary.new(data)
	encounters.load_dir()
	for map_id: StringName in FLOORS:
		var map := _map(map_id)
		assert_eq(zones.zone_of(map_id), &"cerulean_cave", String(map_id))
		assert_eq(lighting.get_map_profile(map_id), map.light_profile, String(map_id))
		assert_ne(map.light_profile, &"", "grotte éclairée (RB) : lumière, pas de voile")
		assert_not_null(encounters.get_table(map_id, &"floor"), String(map_id))


## Départs de la QA téléphone : fichiers valides, cartes et points réels, case d'arrivée praticable.
func test_debug_starts_are_valid() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for name: String in ["cerulean_cave", "cerulean_cave_locked", "cerulean_cave_1f",
			"cerulean_cave_mewtwo", "cerulean_cave_mewtwo_capture", "cerulean_cave_p7"]:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, data, items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var map := _map(start.map)
		assert_true(map.has_spawn(start.spawn), "%s : %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		assert_eq(start.flags.has(CHAMPION), name != "cerulean_cave_locked", name)
		assert_true(start.bag.has(&"hm03"), "%s : CS03" % name)
