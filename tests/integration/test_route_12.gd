extends GutTest
## Route 12 nord (jalon 21 T21, docs/tech/jalon-21.md §2.10, §2.11 ; dossier 24 §10.1, §19) sur la
## vraie scène : grille de la scène = `tools/plans/route_12.txt`, raccords (Lavanville, Route 11,
## bord sud « à venir », poste), Ronflex du croisement (M-3), Pêcheurs (le 1 inévitable, les 2 à 4
## évitables), aucune herbe ni rencontre, budget de nœuds ; la CT39 du poste (une seule fois, avec
## rechargement) sur la vraie Boot.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const MAP_PATH := "res://game/world/maps/route_12.tscn"
const PLAN_PATH := "res://tools/plans/route_12.txt"
const START := "res://tools/debug_start/route_12_qa.json"
const SAVE_PATH := "user://test_route_12_save.json"
const SIZE := Vector2i(39, 102)
const NODE_BUDGET := 3000
const INF := 1 << 30
const SNORLAX := [Vector2i(25, 93), Vector2i(26, 93), Vector2i(25, 94), Vector2i(26, 94)]
const NORTH := [Vector2i(21, 0), Vector2i(22, 0), Vector2i(23, 0)]
const WEST := [Vector2i(0, 93), Vector2i(0, 94)]
const SOUTH := [Vector2i(25, 101), Vector2i(26, 101)]
const FISHERS: Dictionary[StringName, Array] = {
	&"fisher_ned": ["route_12_fisher_1", true], &"fisher_elton": ["route_12_fisher_2", false],
	&"fisher_bastien": ["route_12_fisher_3", false], &"fisher_herve": ["route_12_fisher_4", false],
}
const TIMEOUT := 12.0

var _plan: PlanGrid
var _map: GameMap
var _grid: GridWorld
var _roster: NpcRoster
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_roster = NpcRoster.load_for_map(&"route_12")
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


## Relief seul, Ronflex présent ([param snorlax]) ou parti, positions `bloque` en plus.
func _terrain(snorlax: bool) -> GridWorld:
	var grid := GridPaths.relief(_grid, SIZE)
	for cell: Vector2i in _plan.blocking_cells():
		grid.set_solid(cell)
	for cell: Vector2i in _plan.cells_of("w"):
		grid.set_solid(cell)  # l'eau n'est jamais praticable (pas de Surf)
	# Le poste est traversé par l'intérieur (warps) : couloir équivalent dans la grille.
	for y: int in range(24, 33):
		for x: int in range(24, 27):
			grid.set_solid(Vector2i(x, y), false)
	for cell: Vector2i in SNORLAX:
		if snorlax:
			grid.set_solid(cell)
		else:
			grid.set_solid(cell, false)
	return grid


func _reach(grid: GridWorld, starts: Array) -> Dictionary:
	return GridPaths.distances(grid, starts, {})


func test_metadata_light_zone_and_battle_decor() -> void:
	assert_eq(_map.map_id, &"route_12")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"route_12"), &"route_12")
	assert_eq(zones.zone_of(&"route_12_gate_2f"), &"route_12")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_12"), &"golden_hour")


func test_scene_grid_is_the_functional_grid() -> void:
	var extra: Array[Vector2i] = _plan.cells_at("panneau_route_12") + _plan.cells_at(
		"panneau_ponton")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var solid := (not _plan.is_walkable(cell) and mark != "w") or extra.has(cell)
			if SNORLAX.has(cell):
				continue
			var ok := _grid.is_solid(cell) == solid or (extra.has(cell) and not solid)
			ok = ok and _grid.is_water(cell) == (mark == "w") and not _grid.is_tall_grass(cell)
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_water(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_12.txt")


func test_no_tall_grass_and_no_encounter_table() -> void:
	assert_eq(_plan.cells_of("h").size(), 0)
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_null(library.get_table(&"route_12"), "aucune table de rencontres")
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			assert_false(_grid.is_tall_grass(Vector2i(x, y)))


func test_north_west_and_south_edges() -> void:
	var suffixes := ["w", "c", "e"]
	for i: int in NORTH.size():
		var warp := _map.get_warps().find_on_push(NORTH[i], Vector2i.UP)
		assert_not_null(warp)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn],
				[&"lavender_town", StringName("from_route_12_" + suffixes[i])])
		assert_eq(_map.get_spawn_cell(StringName("from_lavender_" + suffixes[i])), NORTH[i])
	for i: int in WEST.size():
		var warp := _map.get_warps().find_on_push(WEST[i], Vector2i.LEFT)
		assert_not_null(warp)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn],
				[&"route_11", StringName("from_route_12_" + ["n", "s"][i])])
		assert_eq(_map.get_spawn_cell(StringName("from_route_11_" + ["n", "s"][i])), WEST[i])
	for cell: Vector2i in SOUTH:
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp)
		if warp != null:
			assert_true(warp.is_coming_soon(), "bord sud à venir")
			assert_eq(warp.coming_soon, "Route 12")
			assert_false(_grid.is_solid(_map.get_spawn_cell(warp.target_spawn)))


func test_round_trips_with_lavender_and_route_11() -> void:
	var lavender := (load("res://game/world/maps/lavender_town.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(lavender)
	for i: int in 3:
		var warp := lavender.get_warps().find_on_push(Vector2i(21 + i, 35), Vector2i.DOWN)
		assert_not_null(warp)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[&"route_12", StringName("from_lavender_" + ["w", "c", "e"][i])])
		assert_eq(lavender.get_spawn_cell(StringName("from_route_12_" + ["w", "c", "e"][i])),
			Vector2i(21 + i, 34))
	var route_11 := (load("res://game/world/maps/route_11.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(route_11)
	for i: int in 2:
		var warp := route_11.get_warps().find_on_push(Vector2i(75, 14 + i), Vector2i.RIGHT)
		assert_not_null(warp)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[&"route_12", StringName("from_route_11_" + ["n", "s"][i])])
		assert_eq(route_11.get_spawn_cell(StringName("from_route_12_" + ["n", "s"][i])),
			Vector2i(74, 14 + i))


func test_post_is_crossed_both_ways() -> void:
	var gate := (load("res://game/world/maps/route_12_gate.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(gate)
	for entry: Array in [["porte_poste_nord", &"entrance_nord", Vector2i.DOWN, "from_poste_nord"],
			["porte_poste_sud", &"entrance_sud", Vector2i.UP, "from_poste_sud"]]:
		for cell: Vector2i in _plan.cells_at(entry[0]):
			var warp := _map.get_warps().find_on_step(cell, entry[2])
			assert_not_null(warp, "porte %s" % cell)
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], [&"route_12_gate", entry[1]])
		assert_true(gate.has_spawn(entry[1]))
	# Chaque ouverture intérieure ramène à la sortie correspondante de la Route 12.
	for cell: Vector2i in [Vector2i(4, 1), Vector2i(5, 1)]:
		var warp := gate.get_warps().find_on_step(cell, Vector2i.UP)
		assert_eq(warp.target_spawn, &"from_poste_nord")
	for cell: Vector2i in [Vector2i(4, 7), Vector2i(5, 7)]:
		var warp := gate.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_eq(warp.target_spawn, &"from_poste_sud")
	assert_true(_map.has_spawn(&"from_poste_nord") and _map.has_spawn(&"from_poste_sud"))
	# Le seul chemin vers le sud passe par le poste : sans les portes, le sud est coupé.
	var dist := GridPaths.distances(_terrain(false), NORTH, {})
	var south := INF
	for cell: Vector2i in SOUTH:
		south = mini(south, int(dist.get(cell, INF)))
	assert_lt(south, INF, "le sud est atteint en traversant le poste (portes praticables)")
	var closed := _terrain(false)
	for cell: Vector2i in _plan.cells_at("porte_poste_nord"):
		closed.set_solid(cell)
	var cut := GridPaths.distances(closed, NORTH, {})
	for cell: Vector2i in SOUTH:
		assert_false(cut.has(cell), "porte nord fermée : sud coupé")


func test_snorlax_closes_the_crossing_until_done() -> void:
	var gate := _map.get_entities().get_node_or_null(^"Ronflex") as FlagGate
	assert_not_null(gate)
	assert_eq(gate.unless_flags, [&"snorlax_route_12_done"] as Array[StringName])
	var blocking: Array[Vector2i] = []
	blocking.assign(SNORLAX)
	assert_eq(gate.blocking_cells, blocking)
	assert_not_null(gate.get_node_or_null(^"Snorlax"))
	assert_true(gate.get_node(^"Snorlax").is_in_group(&"scene_props"))
	# Avant `_done` : depuis Lavanville ni Route 11 ni sud ; depuis la Route 11 ni Lavanville ni sud.
	var closed := _terrain(true)
	var from_north := _reach(closed, NORTH)
	for cell: Vector2i in WEST + SOUTH:
		assert_false(from_north.has(cell), "Lavanville ne mène pas à %s" % cell)
	var from_west := _reach(closed, WEST)
	for cell: Vector2i in NORTH + SOUTH:
		assert_false(from_west.has(cell), "la Route 11 ne mène pas à %s" % cell)
	for face: Array in [[Vector2i(25, 92), Vector2i.DOWN], [Vector2i(24, 93), Vector2i.RIGHT],
			[Vector2i(25, 95), Vector2i.UP]]:
		assert_true(from_north.has(face[0]) or from_west.has(face[0]) or _reach(closed,
			SOUTH).has(face[0]), "case face_ronflex %s accessible" % face[0])
	# Après `_done` : les quatre cases sont libres, les trois bras reliés.
	var open := _reach(_terrain(false), NORTH)
	for cell: Vector2i in SNORLAX + WEST + SOUTH:
		assert_true(open.has(cell), "ouvert : %s" % cell)
	# La FlagGate se cache avec le drapeau et libère les cases.
	var flags := StoryFlags.new()
	flags.set_flag(&"snorlax_route_12_done", true)
	_map.apply_flag_gates(flags)
	for cell: Vector2i in SNORLAX:
		assert_false(_grid.is_occupied(cell), "libre : %s" % cell)
	_map.apply_flag_gates(StoryFlags.new())
	for cell: Vector2i in SNORLAX:
		assert_true(_grid.is_occupied(cell), "occupé : %s" % cell)
	var point := _map.find_child("SnorlaxPoint", true, false) as InteractPoint
	assert_eq(point.dialogue_id, &"snorlax_route_12")
	assert_eq(point.size, Vector2i(2, 2))
	assert_eq(point.flute_cutscene, &"snorlax_route_12_wake")
	assert_eq(point.unless_flags, [&"snorlax_route_12_done"] as Array[StringName])


func test_fishers_follow_the_grid_and_the_annex() -> void:
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	assert_eq(_roster.get_all().size(), 4)
	var terrain := _terrain(true)
	for key: StringName in FISHERS:
		var spec := _roster.get_spec(key)
		assert_not_null(spec, String(key))
		var id: String = FISHERS[key][0]
		assert_eq(spec.cell, _plan.cell_of(id), "%s : case" % key)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(id, "facing")))
		assert_eq(spec.sight, 6)
		assert_eq(String(spec.trainer_id), id)
		assert_eq(spec.sprite, &"haru")
		assert_true(Npc.has_frames(spec.sprite))
	# Inévitable : tout chemin entre le nord et la sortie du bras coupe la vue du Pêcheur 1 ;
	# évitables : on passe sans entrer dans la vue du Pêcheur.
	for key: StringName in FISHERS:
		var spec := _roster.get_spec(key)
		var sight: Array[Vector2i] = []
		for k: int in range(1, spec.sight + 1):
			var cell := spec.cell + spec.facing * k
			if terrain.is_solid(cell):
				break
			sight.append(cell)
		var grid := GridPaths.relief(_terrain(false), SIZE)
		for cell: Vector2i in sight:
			grid.set_solid(cell)
		for other: NpcSpec in _roster.get_all():
			grid.set_solid(other.cell)
		var reached := _reach(grid, NORTH)
		var any := false
		for cell: Vector2i in WEST + [Vector2i(25, 92), Vector2i(25, 95), Vector2i(25, 100)]:
			any = any or reached.has(cell)
		if FISHERS[key][1]:
			assert_false(reached.has(Vector2i(25, 92)), "Pêcheur 1 inévitable")
		else:
			assert_true(not sight.is_empty() and sight.size() > 0, "%s voit devant lui" % key)
	# 2 à 4 évitables ensemble, 1 neutralisé.
	var grid := GridPaths.relief(_terrain(false), SIZE)
	for key: StringName in [&"fisher_elton", &"fisher_bastien", &"fisher_herve"]:
		var spec := _roster.get_spec(key)
		for k: int in range(1, spec.sight + 1):
			var cell := spec.cell + spec.facing * k
			if terrain.is_solid(cell):
				break
			grid.set_solid(cell)
	for other: NpcSpec in _roster.get_all():
		grid.set_solid(other.cell)
	var one := _roster.get_spec(&"fisher_ned")
	# Pêcheur 1 : on le contourne seulement en entrant dans sa vue (la case (27, 47) du coude).
	var seen_by_one := false
	for k: int in range(1, 7):
		seen_by_one = seen_by_one or (one.cell + one.facing * k).y == 47
	assert_true(seen_by_one)
	var through := _reach(grid, NORTH)
	assert_true(through.has(Vector2i(25, 92)), "2, 3 et 4 évitables ensemble")


func test_trainer_data_and_texts() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for key: StringName in FISHERS:
		var spec := _roster.get_spec(key)
		assert_not_null(trainers.get_trainer(spec.trainer_id))
		for suffix: String in ["_before", "_defeated", "_after"]:
			assert_true(dialogues.has_dialogue(StringName(String(spec.trainer_id) + suffix)))
	assert_eq(TrainerRules.beaten_flag(&"route_12_fisher_1"), &"beaten_route_12_fisher_1")


func test_node_budget() -> void:
	assert_lte(GridPaths.count_nodes(_map), NODE_BUDGET)
	assert_eq(_map.find_children("*", "Light2D", true, false).size(), 0, "aucune Light2D")
	assert_lte(_map.find_children("*", "LightGlow", true, false).size(), 16)


# --- CT39 au poste (vraie Boot) ---------------------------------------------------------------

func _start(fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_12_gate_2f"
	_boot.start_spawn = &"from_1f"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, Vector2i(10, 5), Vector2i.LEFT)
	await wait_process_frames(3)


func _talk_and_finish() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	await wait_process_frames(3)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(5)


func test_tm39_is_given_once_and_survives_a_reload() -> void:
	GameState.clock = FixedClock.new("2026-10-15T14:03:05")
	_fs = MemoryFs.new()
	await _start(true)
	assert_false(GameState.flags.has_flag(&"got_tm39"))
	assert_eq(GameState.bag.count_of(&"tm39"), 0)
	await _talk_and_finish()
	assert_eq(GameState.bag.count_of(&"tm39"), 1, "CT39 donnée")
	assert_true(GameState.flags.has_flag(&"got_tm39"))
	await _talk_and_finish()
	assert_eq(GameState.bag.count_of(&"tm39"), 1, "une seule fois")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(false)
	await _talk_and_finish()
	assert_eq(GameState.bag.count_of(&"tm39"), 1, "toujours une seule après rechargement")
	GameState.clock = DeviceClock.new()
