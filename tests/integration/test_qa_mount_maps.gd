extends GutTest
## Cartes de QA de la monture (passe systèmes 2, T9, `systemes-2.md` §2.14) : `qa_mount`
## (extérieur, rebord, dormeur de la Flûte), `qa_mount_interieur` (refus du Vélo) et `qa_mount_piste`
## (`cycling_road`, pente, Dresseur), construites d'après `tools/plans/qa_mount*.txt` par
## `tools/build_qa_mount.gd`. Retirées à la clôture de la passe (S2Z) avec ce test.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TOOL_STARTS := "res://tools/debug_start/"

var _mount_plan: PlanGrid
var _piste_plan: PlanGrid


func before_all() -> void:
	_mount_plan = PlanGrid.new()
	assert_true(_mount_plan.load_file("res://tools/plans/qa_mount.txt"), _mount_plan.error)
	_piste_plan = PlanGrid.new()
	assert_true(_piste_plan.load_file("res://tools/plans/qa_mount_piste.txt"), _piste_plan.error)


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func test_the_three_maps_load_with_their_traits() -> void:
	var mount := _map(&"qa_mount")
	var inside := _map(&"qa_mount_interieur")
	var piste := _map(&"qa_mount_piste")
	assert_eq([mount.map_id, inside.map_id, piste.map_id],
		[&"qa_mount", &"qa_mount_interieur", &"qa_mount_piste"])
	assert_eq([mount.display_name, inside.display_name, piste.display_name],
		["QA Monture", "QA Maison", "QA Piste"])
	assert_false(mount.interior)
	assert_false(mount.cycling_road)
	assert_true(inside.interior)
	assert_false(inside.cycling_road)
	assert_false(piste.interior)
	assert_true(piste.cycling_road)
	assert_true(MapCatalog.is_qa_map(&"qa_mount_piste"))
	assert_true(piste.mount_traits().cycling_road)
	assert_true(inside.mount_traits().interior)
	assert_eq(mount.size, Vector2i(_mount_plan.width, _mount_plan.height))
	assert_eq(piste.size, Vector2i(_piste_plan.width, _piste_plan.height))
	assert_push_error_count(0)


func test_the_piste_slopes_are_exactly_the_slash_cells() -> void:
	var piste := _map(&"qa_mount_piste")
	var grid := piste.get_grid()
	var slashes := _piste_plan.cells_of("/")
	assert_eq(slashes.size(), 80)
	assert_eq(piste.slope_cells.size(), slashes.size())
	for y: int in _piste_plan.height:
		for x: int in _piste_plan.width:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_slope(cell), _piste_plan.at(cell) == "/", "pente en %s" % cell)
	for cell: Vector2i in [Vector2i(1, 8), Vector2i(8, 8), Vector2i(1, 2), Vector2i(4, 14),
			Vector2i(0, 8), Vector2i(0, 16)]:
		assert_false(grid.is_slope(cell), "palier en %s" % cell)
	assert_true(grid.is_slope(Vector2i(4, 3)))
	assert_true(grid.is_slope(Vector2i(4, 13)))


func test_the_piste_walls_and_the_trainer_alcove_match_the_grid() -> void:
	var grid := _map(&"qa_mount_piste").get_grid()
	for y: int in _piste_plan.height:
		for x: int in _piste_plan.width:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_solid(cell), _piste_plan.at(cell) == "#", "mur en %s" % cell)


func test_the_trainer_sees_the_slope_from_its_alcove() -> void:
	var piste := _map(&"qa_mount_piste")
	var trainer: Npc = null
	for npc: Npc in piste.get_npcs():
		if npc.get_spec().trainer_id == &"qa_mount_youngster":
			trainer = npc
	assert_not_null(trainer, "le Dresseur de la pente est là")
	assert_eq(trainer.get_cell(), _piste_plan.cell_of("dresseur_pente"))
	assert_eq(trainer.get_facing(), Vector2i.LEFT)
	assert_eq(trainer.get_spec().sight, 8)


func test_the_trainer_team_has_a_sleep_move() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"qa_mount_youngster")
	assert_not_null(trainer)
	assert_eq(trainer.team.size(), 1)
	assert_eq(trainer.team[0].species, &"drowzee")
	assert_between(trainer.team[0].level, 6, 10)
	assert_true(&"hypnosis" in trainer.team[0].moves)
	assert_true(data.has_move(&"hypnosis"))


func test_warps_link_the_three_maps_and_land_on_real_spawns() -> void:
	var maps := {}
	for id: StringName in [&"qa_mount", &"qa_mount_interieur", &"qa_mount_piste"]:
		maps[id] = _map(id)
	var count := 0
	for id: StringName in maps:
		for warp: Warp in (maps[id] as GameMap).get_warps().get_all():
			count += 1
			assert_true(maps.has(warp.target_map), "%s : carte %s" % [id, warp.target_map])
			var target := maps[warp.target_map] as GameMap
			assert_true(target.has_spawn(warp.target_spawn),
				"%s → %s:%s" % [id, warp.target_map, warp.target_spawn])
			var cell := target.get_spawn_cell(warp.target_spawn)
			assert_false(target.get_grid().is_solid(cell), "arrivée libre en %s" % cell)
			var back := false
			for other: Warp in target.get_warps().get_all():
				back = back or other.target_map == id
			assert_true(back, "%s a un retour vers %s" % [warp.target_map, id])
	assert_eq(count, 7, "porte, deux entrées de la Piste, deux sorties de la Piste, deux tapis")
	var mount := maps[&"qa_mount"] as GameMap
	var door := mount.get_warps().find_on_step(_mount_plan.cell_of("porte_maison"), Vector2i.UP)
	assert_not_null(door)
	assert_eq(door.target_map, &"qa_mount_interieur")
	for name: String in ["entree_piste_n", "entree_piste_s"]:
		var edge := mount.get_warps().find_on_push(_mount_plan.cell_of(name), Vector2i.RIGHT)
		assert_not_null(edge, name)
		assert_eq(edge.target_map, &"qa_mount_piste")
	assert_push_error_count(0)


func test_the_house_is_solid_and_the_ledge_is_a_ledge() -> void:
	var grid := _map(&"qa_mount").get_grid()
	assert_true(grid.is_solid(Vector2i(3, 8)))
	assert_true(grid.is_solid(Vector2i(7, 10)))
	assert_false(grid.is_solid(_mount_plan.cell_of("porte_maison")))
	assert_eq(grid.get_ledge(Vector2i(4, 14)), GridWorld.Ledge.DOWN)


func test_the_sleeper_closes_the_north_until_the_flag_is_raised() -> void:
	var mount := _map(&"qa_mount")
	var grid := mount.get_grid()
	var behind := _mount_plan.cell_of("derriere")
	var start := _mount_plan.cell_of("depart")
	for cell: Vector2i in _mount_plan.cells_at("dormeur"):
		assert_true(grid.is_occupied(cell), "le dormeur occupe %s" % cell)
	assert_false(grid.find_reachable(start, null).has(behind), "le nord est fermé")
	var targets := mount.flute_targets()
	assert_eq(targets.size(), 1)
	assert_eq(targets[0].cutscene_id, &"qa_mount_sleeper")
	assert_eq(targets[0].cells, _mount_plan.cells_at("dormeur"))
	assert_eq(targets[0].unless_flags, [&"qa_mount_sleeper_woken"] as Array[StringName])
	var south := Vector2i(10, 5)
	assert_true(targets[0].touches(south), "la Flûte joue juste au sud")
	var flags := StoryFlags.new()
	assert_eq(PokeFluteRules.field_target(targets, south, flags), &"qa_mount_sleeper")
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(5, 5), flags), &"",
		"trop loin : la Flûte joue ailleurs")
	flags.set_flag(&"qa_mount_sleeper_woken")
	mount.apply_flag_gates(flags)
	for cell: Vector2i in _mount_plan.cells_at("dormeur"):
		assert_false(grid.is_occupied(cell), "%s libérée" % cell)
	assert_true(grid.find_reachable(start, null).has(behind), "le nord est ouvert")
	assert_eq(PokeFluteRules.field_target(targets, south, flags), &"", "plus de dormeur")


func test_the_sleeper_examine_dialogue_and_the_wake_scene_exist() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	assert_true(cutscenes.has_cutscene(&"qa_mount_sleeper"))
	assert_true(&"qa_mount_sleeper_woken" in cutscenes.get_set_flags())
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	for id: StringName in [&"qa_mount_sleeper_examine", &"qa_mount_sleeper_wakes"]:
		assert_true(dialogues.has_dialogue(id), String(id))
	var mount := _map(&"qa_mount")
	var points := mount.get_interactions().get_at(Vector2i(10, 4))
	assert_eq(points.size(), 1)
	assert_eq(points[0].dialogue_id, &"qa_mount_sleeper_examine")


func test_the_s2_bike_start_loads_on_a_real_spawn() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "s2_bike.json", data, items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"qa_mount", &"depart", Vector2i.UP])
	assert_eq(int(start.bag[&"bicycle"]), 1)
	assert_eq(int(start.bag[&"poke_flute"]), 1)
	assert_eq(start.party.size(), 2)
	assert_eq(start.party[1]["status"], &"sleep", "un Pokémon endormi")
	assert_eq(start.companion, 0)
	var mount := _map(start.map)
	assert_true(mount.has_spawn(start.spawn))
	assert_false(mount.get_grid().is_solid(mount.get_spawn_cell(start.spawn)))
	assert_eq(mount.get_spawn_cell(start.spawn), _mount_plan.cell_of("depart"))


# --- Dans le vrai Boot : départ s2_bike, portes et Piste ----------------------------------------

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _fades: Array[float] = []


func _boot_s2_bike() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_qa_mount_save.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = TOOL_STARTS + "s2_bike.json"
	add_child_autofree(_boot)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)
	if not _fades.is_empty():
		_restore_router()
		_fades.clear()


func _restore_router() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _step(direction: Vector2i) -> void:
	assert_true(_boot.get_player().script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not _boot.get_player().is_moving() \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(2)


## Pousse vers [param action] (warp PUSH : le joueur bute contre le bord) jusqu'à la carte [param map_id].
func _push_to(action: StringName, map_id: StringName) -> void:
	Input.action_press(action)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await wait_process_frames(3)


func test_boot_from_s2_bike_walks_through_the_door_and_the_piste() -> void:
	await _boot_s2_bike()
	assert_eq(_boot.get_map().map_id, &"qa_mount")
	assert_eq(_boot.get_player().get_cell(), Vector2i(9, 18))
	assert_eq(GameState.bag.count_of(&"bicycle"), 1)
	assert_eq(GameState.party.size(), 2)
	# Maison : un pas dans la porte (STEP_ON ↑), puis le tapis de sortie (PUSH ↓).
	_boot.get_map().spawn_player_at(_boot.get_player(), Vector2i(5, 11), Vector2i.UP)
	await _step(Vector2i.UP)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_mount_interieur",
		TIMEOUT)
	assert_true(_boot.get_map().interior)
	assert_eq(_boot.get_player().get_mount(), Mount.Kind.NONE, "à pied dans la maison")
	_boot.get_map().spawn_player_at(_boot.get_player(), Vector2i(3, 5), Vector2i.DOWN)
	await _push_to(&"move_down", &"qa_mount")
	assert_eq(_boot.get_player().get_cell(), Vector2i(5, 11))
	# Piste : poussée vers l'est depuis la case de bord, arrivée en Vélo d'office.
	_boot.get_map().spawn_player_at(_boot.get_player(), Vector2i(19, 8), Vector2i.RIGHT)
	await _push_to(&"move_right", &"qa_mount_piste")
	assert_true(_boot.get_map().cycling_road)
	assert_eq(_boot.get_player().get_cell(), Vector2i(0, 8))
	assert_eq(_boot.get_player().get_mount(), Mount.Kind.BIKE, "monté d'office avec la Bicyclette")
	# Retour par la sortie de la Piste.
	await _push_to(&"move_left", &"qa_mount")
	assert_eq(_boot.get_player().get_cell(), Vector2i(19, 8))
