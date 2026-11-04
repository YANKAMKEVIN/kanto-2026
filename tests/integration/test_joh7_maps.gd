extends GutTest
## La mer du JOH7 (`jalon-joh7.md` §2.1, §2.4 à §2.7) sur les vraies scènes : grille de la scène =
## grille du plan (eau surfable, tourbillons et cascade bloqués), courants (permanents, et le
## courant violent du B1F qui s'apaise après Suicune), raccords des deux côtés (Oliville ↔ Route 40
## ↔ Route 41 ↔ 1F ↔ B1F ↔ B2F), déclencheurs, examens, rochers de Force, ombre de Lugia, Corde
## Sortie ; présence des légendaires et du Lokhlass du vendredi (horloge injectée), réapparition
## après la Ligue, Écaille Draco au terminal d'échange.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const PLANS: Dictionary = {&"route_40": "route_40", &"route_41": "route_41",
	&"whirl_islands_1f": "whirl_islands_1f", &"whirl_islands_b1f": "whirl_islands_b1f",
	&"whirl_islands_b2f": "whirl_islands_b2f"}
const WATER: String = "wd<>^v"
const ARROWS: Dictionary = {">": Vector2i.RIGHT, "v": Vector2i.DOWN, "<": Vector2i.LEFT,
	"^": Vector2i.UP}

var _maps: Dictionary = {}
var _plans: Dictionary = {}
var _olivine: GameMap


func before_all() -> void:
	for map_id: StringName in PLANS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % PLANS[map_id]), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map
	_olivine = (load(MapCatalog.scene_path(&"olivine_city")) as PackedScene).instantiate() as GameMap
	add_child(_olivine)


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()
	_olivine.free()


func _flags(raised: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


## Cases atteignables (à pied et en Surf) depuis [param from], un courant ne laissant passer que
## dans son sens et poussant jusqu'à la première case sans courant.
func _reachable(map: GameMap, from: Vector2i) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var current := grid.get_current(cell)
		var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		if current != Vector2i.ZERO:
			directions = [current]
		for direction: Vector2i in directions:
			var next := cell + direction
			if not grid.is_in_bounds(next) or grid.is_solid(next) or seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_metadata_light_and_zones() -> void:
	var lights := LightingLibrary.new()
	assert_true(lights.load_file())
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var expected := {&"route_40": [&"johto_auto", false, &"route_40"],
		&"route_41": [&"johto_auto", false, &"route_41"],
		&"whirl_islands_1f": [&"sea_cave", false, &"whirl_islands"],
		&"whirl_islands_b1f": [&"sea_cave", false, &"whirl_islands"],
		&"whirl_islands_b2f": [&"whirl_islands_b2f", false, &"whirl_islands"]}
	for map_id: StringName in expected:
		var map: GameMap = _maps[map_id]
		var plan: PlanGrid = _plans[map_id]
		assert_eq(map.map_id, map_id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		assert_eq(map.light_profile, expected[map_id][0], String(map_id))
		assert_eq(lights.get_map_profile(map_id), expected[map_id][0], String(map_id))
		assert_eq(map.interior, expected[map_id][1], String(map_id))
		assert_eq(zones.zone_of(map_id), expected[map_id][2], String(map_id))
		assert_true(zones.is_johto(map_id), String(map_id))
	assert_not_null(lights.get_profile(&"whirl_islands_b2f"))
	# Corde Sortie : Route 41, en Surf devant l'entrée.
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	for map_id: StringName in [&"whirl_islands_1f", &"whirl_islands_b1f", &"whirl_islands_b2f"]:
		var exit := FieldItemRules.escape_target(map_id, caves, Vector2i(2, 2))
		assert_not_null(exit, String(map_id))
		if exit != null:
			assert_eq([exit.map, exit.spawn], [&"route_41", &"from_whirl"])
	assert_true((_maps[&"route_41"] as GameMap).forced_surf_cells.has(Vector2i(21, 24)))


func test_scene_grid_matches_the_plan() -> void:
	for map_id: StringName in PLANS:
		var map: GameMap = _maps[map_id]
		var plan: PlanGrid = _plans[map_id]
		var grid := map.get_grid()
		var wrong: Array[String] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var c := plan.at(cell)
				var solid := not plan.walkable.contains(c) or (y == 0 and plan.walkable.contains(c))
				# Panneaux et examens bloqués (piquets dans l'eau, cascade).
				if grid.is_solid(cell) != solid and not _is_sign(map_id, cell):
					wrong.append("%s solide=%s (%s)" % [cell, grid.is_solid(cell), c])
				var water := WATER.contains(c)
				if grid.is_surfable(cell) != water:
					wrong.append("%s surfable=%s (%s)" % [cell, grid.is_surfable(cell), c])
		assert_eq(wrong, [] as Array[String], String(map_id))


func _is_sign(map_id: StringName, cell: Vector2i) -> bool:
	return {&"route_40": [Vector2i(17, 2)], &"route_41": [Vector2i(27, 3), Vector2i(21, 22)]}.get(
		map_id, []).has(cell)


func test_whirlpools_block_and_are_examined() -> void:
	var map: GameMap = _maps[&"route_41"]
	var plan: PlanGrid = _plans[&"route_41"]
	var field := map.get_node(^"Decor/Tourbillons") as WhirlpoolField
	assert_not_null(field)
	var cells := plan.cells_of("@")
	assert_eq(field.cells.size(), cells.size())
	for cell: Vector2i in cells:
		assert_true(map.get_grid().is_solid(cell), str(cell))
		var points := map.get_interactions().get_at(cell)
		assert_eq(points.size(), 1, "examen M-4 en %s" % cell)
		if points.size() == 1:
			assert_eq(points[0].dialogue_id, &"whirlpool_examine")
	# La passe de Noé reste ouverte ; la mer est pêchable.
	assert_false(map.get_grid().is_solid(Vector2i(15, 10)))
	assert_true(map.fishable_cells.has(Vector2i(15, 10)))
	var b2f: GameMap = _maps[&"whirl_islands_b2f"]
	assert_not_null(b2f.get_node(^"Decor/Cascade") as WaterfallDecor)
	assert_true(b2f.get_grid().is_solid(Vector2i(11, 2)), "cascade bloquée")
	assert_false(b2f.get_grid().is_solid(Vector2i(13, 2)), "passage sous la cascade")


func test_currents_and_the_violent_current() -> void:
	var map: GameMap = _maps[&"whirl_islands_b1f"]
	var plan: PlanGrid = _plans[&"whirl_islands_b1f"]
	for c: String in ARROWS:
		for cell: Vector2i in plan.cells_of(c):
			if cell.x == 2 and cell.y in [4, 5]:
				continue
			assert_eq(map.get_grid().get_current(cell), ARROWS[c], str(cell))
	var gate := map.get_node(^"Entities/CourantB2f") as CurrentGate
	assert_not_null(gate)
	map.apply_flag_gates(_flags())
	assert_eq(map.get_grid().get_current(Vector2i(2, 4)), Vector2i.DOWN, "violent avant Suicune")
	assert_eq(map.get_grid().get_current(Vector2i(2, 5)), Vector2i.DOWN)
	var start := map.get_spawn_cell(&"from_1f")
	var before := _reachable(map, start)
	assert_false(before.has(Vector2i(2, 2)), "escalier du B2F fermé")
	for cell: Vector2i in [Vector2i(11, 6), Vector2i(4, 13), Vector2i(3, 23), Vector2i(33, 24)]:
		assert_true(before.has(cell), "atteint : %s" % cell)
	map.apply_flag_gates(_flags([&"johto_suicune_done"]))
	assert_eq(map.get_grid().get_current(Vector2i(2, 4)), Vector2i.ZERO, "apaisé après Suicune")
	var after := _reachable(map, start)
	assert_true(after.has(Vector2i(2, 2)), "escalier du B2F ouvert")
	# Retour possible de partout vers l'échelle (aucun cul-de-sac).
	for cell: Vector2i in after:
		assert_true(_reachable(map, cell).has(start), "retour depuis %s" % cell)
		if not _reachable(map, cell).has(start):
			break
	map.apply_flag_gates(_flags())
	# Examens des courants (M-11) et du courant violent (M-20 / M-21).
	assert_eq(map.get_interactions().get_at(Vector2i(16, 9))[0].dialogue_id, &"whirl_current")
	assert_eq(map.get_interactions().get_at(Vector2i(2, 5))[0].dialogue_id,
		&"whirl_b2f_current_examine")


func test_links_on_both_sides() -> void:
	var r40: GameMap = _maps[&"route_40"]
	var r41: GameMap = _maps[&"route_41"]
	var f1: GameMap = _maps[&"whirl_islands_1f"]
	var b1: GameMap = _maps[&"whirl_islands_b1f"]
	var b2: GameMap = _maps[&"whirl_islands_b2f"]
	# Oliville (20..29, 39) ↔ Route 40 (7..16, 0 → rangée 1).
	for i: int in 10:
		var down := _warp_at(_olivine, Vector2i(20 + i, 39))
		assert_not_null(down, "Oliville sud %d" % i)
		if down == null:
			continue
		var spawn := StringName("from_olivine" if i == 0 else "from_olivine_%d" % i)
		assert_eq([down.target_map, down.target_spawn], [&"route_40", spawn])
		assert_eq(r40.get_spawn_cell(spawn), Vector2i(7 + i, 1))
		assert_true(r40.forced_surf_cells.has(Vector2i(7 + i, 1)), "arrivée en Surf")
		var up := _warp_at(r40, Vector2i(7 + i, 1))
		var back := StringName("from_route_40" if i == 0 else "from_route_40_%d" % i)
		assert_eq([up.target_map, up.target_spawn, up.direction], [&"olivine_city", back, Vector2i.UP])
		assert_eq(_olivine.get_spawn_cell(back), Vector2i(20 + i, 39))
	# Route 40 (10..12, 39) ↔ Route 41 (28..30, 0 → rangée 1).
	for i: int in 3:
		var down := _warp_at(r40, Vector2i(10 + i, 39))
		var spawn := StringName("from_route_40" if i == 0 else "from_route_40_%d" % i)
		assert_eq([down.target_map, down.target_spawn], [&"route_41", spawn])
		assert_eq(r41.get_spawn_cell(spawn), Vector2i(28 + i, 1))
		var up := _warp_at(r41, Vector2i(28 + i, 1))
		var back := StringName("from_route_41" if i == 0 else "from_route_41_%d" % i)
		assert_eq([up.target_map, up.target_spawn], [&"route_40", back])
		assert_eq(r40.get_spawn_cell(back), Vector2i(10 + i, 39))
	# Route 41 ↔ 1F.
	var enter := _warp_at(r41, Vector2i(22, 24))
	assert_eq([enter.trigger, enter.direction, enter.target_map, enter.target_spawn],
		[Warp.Trigger.STEP_ON, Vector2i.RIGHT, &"whirl_islands_1f", &"from_route_41"])
	assert_eq(f1.get_spawn_cell(&"from_route_41"), Vector2i(1, 12))
	var leave := _warp_at(f1, Vector2i(0, 12))
	assert_eq([leave.target_map, leave.target_spawn], [&"route_41", &"from_whirl"])
	assert_eq(r41.get_spawn_cell(&"from_whirl"), Vector2i(21, 24))
	# Échelles.
	for link: Array in [[f1, Vector2i(27, 20), &"whirl_islands_b1f", &"from_1f", b1, Vector2i(27, 21)],
			[b1, Vector2i(27, 20), &"whirl_islands_1f", &"from_b1f", f1, Vector2i(27, 21)],
			[b1, Vector2i(2, 2), &"whirl_islands_b2f", &"from_b1f", b2, Vector2i(2, 3)],
			[b2, Vector2i(2, 2), &"whirl_islands_b1f", &"from_b2f", b1, Vector2i(2, 3)]]:
		var warp := _warp_at(link[0], link[1])
		assert_not_null(warp, str(link[1]))
		if warp == null:
			continue
		assert_eq([warp.target_map, warp.target_spawn], [link[2], link[3]])
		assert_eq((link[4] as GameMap).get_spawn_cell(link[3]), link[5])


func test_triggers_boulders_and_lugia_shadow() -> void:
	var b1: GameMap = _maps[&"whirl_islands_b1f"]
	var expected := [[b1, Vector2i(8, 6), Vector2i.UP, &"whirl_suicune_seen"],
		[b1, Vector2i(14, 4), Vector2i.UP, &"whirl_cenere"],
		[b1, Vector2i(7, 22), Vector2i.LEFT, &"whirl_cove"],
		[b1, Vector2i(3, 25), Vector2i.UP, &"whirl_cove"],
		[b1, Vector2i(2, 6), Vector2i.UP, &"whirl_b2f_current"],
		[_maps[&"whirl_islands_b2f"], Vector2i(12, 17), Vector2i.UP, &"whirl_lugia_rise"],
		[_maps[&"whirl_islands_b2f"], Vector2i(2, 4), Vector2i.DOWN, &"whirl_b2f_heart"]]
	for entry: Array in expected:
		var trigger := (entry[0] as GameMap).get_triggers().find_on_step(entry[1], entry[2])
		assert_not_null(trigger, "%s %s" % [entry[1], entry[3]])
		if trigger != null:
			assert_eq(trigger.cutscene_id, entry[3])
	assert_null(b1.get_triggers().find_on_step(Vector2i(7, 22), Vector2i.RIGHT), "crique : en entrant")
	var setup := (_maps[&"whirl_islands_1f"] as GameMap).get_node(^"Boulders") as BoulderSetup
	assert_not_null(setup)
	assert_eq(setup.boulder_cells, [Vector2i(16, 8), Vector2i(24, 12)] as Array[Vector2i])
	var b2: GameMap = _maps[&"whirl_islands_b2f"]
	var shadow := b2.get_node(^"LugiaShadow") as FlagGate
	assert_not_null(shadow)
	assert_eq(shadow.if_flags, [&"johto_whirl_lugia_passing"] as Array[StringName])
	assert_eq(Grid.world_to_cell(shadow.position), Vector2i(7, 11))
	assert_true(shadow.get_index() < b2.get_node(^"Entities").get_index(), "sous le joueur")


## Suicune sur son rocher jusqu'à la fin de sa rencontre, Lugia après son émergence ; après la
## Ligue (StaticRespawn), Lugia revient au B2F, Suicune pas au B1F (Tour Cendrée, JOH8+).
func test_legendaries_presence_and_respawn() -> void:
	var suicune := NpcRoster.load_for_map(&"whirl_islands_b1f").get_spec(&"suicune")
	var lugia := NpcRoster.load_for_map(&"whirl_islands_b2f").get_spec(&"lugia")
	assert_true(suicune.is_present(_flags()))
	assert_false(lugia.is_present(_flags()), "Lugia sous l'eau avant la scène")
	assert_true(lugia.is_present(_flags([&"johto_lugia_emerged"])))
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var flags := _flags([&"johto_lugia_emerged", &"johto_lugia_resolved", &"johto_lugia_done",
		&"johto_suicune_resolved", &"johto_suicune_done", &"johto_cenere_defeated_2"])
	assert_false(suicune.is_present(flags))
	assert_false(lugia.is_present(flags))
	StaticRespawn.on_league_won(cutscenes.get_static_encounters(), flags)
	assert_true(lugia.is_present(flags), "Lugia revient au B2F")
	assert_false(suicune.is_present(flags), "Suicune ne revient pas sur son rocher")
	assert_true(flags.has_flag(&"johto_suicune_done"), "la progression reste")
	# Capturés : jamais de retour.
	var caught := _flags([&"johto_lugia_emerged", &"johto_lugia_resolved", &"johto_lugia_caught"])
	StaticRespawn.on_league_won(cutscenes.get_static_encounters(), caught)
	assert_false(lugia.is_present(caught))


## JH-50 : le Lokhlass le vendredi seulement ; mis K.O. un vendredi, absent jusqu'à ce que le jeu
## tourne un autre jour (WeeklyFlags), de retour le vendredi suivant ; capturé, plus jamais.
func test_friday_lapras_with_an_injected_clock() -> void:
	var lapras := NpcRoster.load_for_map(&"whirl_islands_b1f").get_spec(&"lokhlass")
	assert_eq(lapras.if_weekdays, [&"friday"] as Array[StringName])
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-06T15:00:00") # un vendredi
	clock.start_on_device(device)
	assert_eq(clock.weekday_name(), &"friday")
	var flags := _flags()
	assert_true(lapras.is_present(flags, clock.period_name(), clock.weekday_name()))
	flags.set_flag(&"week_friday_lapras") # K.O.
	WeeklyFlags.shared().apply(flags, clock.weekday_name())
	assert_false(lapras.is_present(flags, clock.period_name(), clock.weekday_name()), "K.O. ce vendredi")
	device.iso = "2026-11-07T10:00:00" # samedi
	clock.sync()
	assert_false(lapras.is_present(flags, clock.period_name(), clock.weekday_name()), "samedi")
	WeeklyFlags.shared().apply(flags, clock.weekday_name())
	device.iso = "2026-11-13T10:00:00" # vendredi suivant
	clock.sync()
	assert_true(lapras.is_present(flags, clock.period_name(), clock.weekday_name()), "de retour")
	flags.set_flag(&"johto_lapras_caught")
	assert_false(lapras.is_present(flags, clock.period_name(), clock.weekday_name()), "capturé")
	# Textes de la crique selon le jour.
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var cove := dialogues.get_dialogue(&"whirl_cove")
	var friday := cove.pick(_flags(), null, 0, Callable(), Callable(), Callable(), &"day", &"friday")
	assert_eq(friday.pages[0].text, "Un Lokhlass nage dans la crique.")
	var monday := cove.pick(_flags(), null, 0, Callable(), Callable(), Callable(), &"day", &"monday")
	assert_eq(monday.pages[0].text, "La crique est calme.")


## Dossier §14 : Écaille Draco et Hypocéan au terminal d'échange local → Hyporoi.
func test_dragon_scale_evolves_seadra_at_the_trade_terminal() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var seadra := PokemonFactory.create(data, &"seadra", 50, GameRng.new())
	var bag := Bag.new()
	assert_eq(LocalTrade.trade_target(seadra, data, bag), &"", "sans l'Écaille")
	bag.add(&"dragon_scale", 1)
	assert_eq(LocalTrade.trade_target(seadra, data, bag), &"kingdra")
	assert_eq(LocalTrade.trade_item(seadra, data, bag), &"dragon_scale")
