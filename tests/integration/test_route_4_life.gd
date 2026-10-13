extends GutTest
## La vie de la Route 4 (jalon 13 T17, jalon-13.md §2.2, §2.14 ; dossier 16 §3.2) avec la vraie scène :
## - Poké Ball au sol (fond de la poche ouest) : Sac + 1, journal, drapeau, absente au rechargement ;
## - rencontres branchées : `route_4_grass` sur la carte (sans Abo : espèce du J12), hautes
##   herbes de la grille ;
## - rebord : un seul sens (vers le sud), jamais de retour par la route ;
## - Clara : case réservée, **absente** (Paras et Rondoudou, espèces du J12, n'existent pas encore).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_NAME := "test_route_4_life"
const FADE := 0.05
const TIMEOUT := 14.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T14:03:05")
	_fs = MemoryFs.new()
	_pages.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map_id] (départ de débogage [param start], drapeaux en plus [param flags]),
## joueur posé sur [param cell].
func _start(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i,
		start: String, flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if not start.is_empty():
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
		for flag: StringName in flags:
			GameState.flags.set_flag(flag)
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Parle à [param npc_id] depuis une case voisine libre (routines tenues).
func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
	var cell := npc.get_cell()
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


## Examine ce que fait face à [param facing] depuis [param cell] ; renvoie les pages dites.
func _examine(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i,
		start: String = "cerulean_city") -> Array[String]:
	_pages.clear()
	await _start(map_id, spawn, cell, facing, start)
	await _press_interact()
	await wait_process_frames(4)
	if _runner.is_running():
		await _finish_scene()
	var said := _pages.duplicate()
	_boot.queue_free()
	await wait_process_frames(3)
	return said


## Première page dite par [param npc_id] (partie « cerulean_city » + [param flags]).
func _says(map_id: StringName, spawn: StringName, cell: Vector2i, npc_id: StringName,
		flags: Array[StringName] = []) -> Array[String]:
	_pages.clear()
	await _start(map_id, spawn, cell, Vector2i.UP, "cerulean_city", flags)
	await _talk_to(npc_id)
	var said := _pages.duplicate()
	_boot.queue_free()
	await wait_process_frames(3)
	return said

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const BALL := Vector2i(21, 20)


func test_the_poke_ball_goes_to_the_bag_and_stays_gone_after_a_reload() -> void:
	await _start(&"route_4", &"from_mt_moon", Vector2i(21, 19), Vector2i.DOWN, "route_4")
	var map := _boot.get_map()
	var npc := map.get_npc(&"route_4_ball_1")
	assert_not_null(npc, "Poké Ball posée")
	assert_eq(npc.get_cell(), BALL)
	var before := GameState.bag.count_of(&"poke_ball")
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(&"route_4_ball_1") == null, TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"poke_ball"), before + 1, "Sac + 1")
	var found := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == "poke_ball" and entry["map"] == "route_4":
			found += 1
	assert_eq(found, 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(&"got_route_4_poke_ball"))
	assert_eq(_pages, [] as Array[String], "aucune bulle")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"route_4", &"from_mt_moon", Vector2i(21, 19), Vector2i.DOWN, "")
	assert_null(_boot.get_map().get_npc(&"route_4_ball_1"), "absente au rechargement")
	assert_eq(GameState.bag.count_of(&"poke_ball"), before + 1, "Sac inchangé")


func test_the_ball_is_in_the_plan_and_reachable() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_4.txt"), plan.error)
	assert_eq(plan.cell_of("route_4_item_1"), BALL)
	assert_eq(plan.attr("route_4_item_1", "item"), "poke_ball")


func test_the_wild_table_is_wired_to_the_map() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(&"route_4", &"grass"))
	var table := library.get_table(&"route_4")
	var species: Array[StringName] = []
	for slot: Variant in table.slots:
		species.append(slot.species)
	assert_eq(species, [&"rattata", &"spearow", &"sandshrew", &"mankey"] as Array[StringName],
		"Abo (J12 T12) rejoindra la table avec l'espèce")
	assert_eq(table.rate, 25)
	await _start(&"route_4", &"from_mt_moon", Vector2i(38, 15), Vector2i.DOWN, "route_4")
	assert_true(_boot.get_map().get_grid().is_tall_grass(Vector2i(38, 15)), "hautes herbes (H1)")


func test_the_ledge_is_crossed_one_way_only() -> void:
	await _start(&"route_4", &"from_mt_moon", Vector2i(30, 11), Vector2i.DOWN, "route_4")
	var grid := _boot.get_map().get_grid()
	for x: int in range(28, 34):
		var top := Vector2i(x, 11)
		var landing := grid.get_step_target(top, Vector2i.DOWN)
		assert_gt(landing.y, 12, "saut vers le sud en x = %d" % x)
		assert_eq(grid.get_step_target(landing, Vector2i.UP), landing, "on ne remonte pas")
	# Aucune autre descente : le versant est une falaise.
	for x: int in range(3, 28):
		assert_eq(grid.get_step_target(Vector2i(x, 11), Vector2i.DOWN), Vector2i(x, 11),
			"versant fermé en x = %d" % x)


func test_clara_waits_for_the_species_of_the_j12() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_4.txt"), plan.error)
	assert_eq(plan.cell_of("clara"), Vector2i(44, 17), "case réservée")
	await _start(&"route_4", &"from_mt_moon", Vector2i(44, 20), Vector2i.UP, "route_4")
	var map := _boot.get_map()
	assert_null(map.get_npc(&"clara"), "Clara n'est pas posée (Paras, Rondoudou : J12)")
	assert_false(_boot.get_pokemon_data().has_species(&"paras"), "espèce du J12 absente")
	var trainers := TrainerLibrary.new(_boot.get_pokemon_data())
	assert_true(trainers.load_dir())
	assert_false(trainers.has_trainer(&"route_4_lass_clara"), "Dresseuse à créer avec le J12")
	assert_eq(map.get_npcs().size(), 1, "la Poké Ball seule")
	_player.set_input_enabled(true, &"test")
	# La rue (rangées 19..21) se traverse sans combat.
	_boot.get_map().spawn_player_at(_player, Vector2i(40, 21), Vector2i.RIGHT)
	await wait_process_frames(2)
	await _walk(Vector2i.RIGHT, Vector2i(50, 21))
	assert_false(_boot.get_cutscene_director().is_running())
