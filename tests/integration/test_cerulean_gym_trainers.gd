extends GutTest
## Les Dresseurs de l'Arène d'Azuria (jalon 13 T17, jalon-13.md §2.6 ; dossier 16 §9.2, §9.3, §21 n° 21
## à 27) sur la vraie carte `cerulean_gym` :
## - Nageur Lucas et Jeune Dresseuse Diane à leur case, blocs `trainer` (vue de 3 cases), équipes
##   des données ; aucune condition de présence : combattables dès l'arrivée (avant l'invitation) ;
## - évitables : un chemin de l'entrée à la case d'Ondine hors de leur vue ; chacun repère le
##   joueur qui entre dans sa file (« ! » puis scène de Dresseur) ;
## - répliques « avant » et « après » ; battus, ils ne défient plus ;
## - guide : trois états (avant l'invitation, invitation, badge) ; Ondine absente jusqu'au T19.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_NAME := "test_cerulean_gym_trainers"
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

const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GYM := &"cerulean_gym"
const PLAN_PATH := "res://tools/plans/azuria_arene.txt"
const SIZE := Vector2i(17, 13)
const ENTRANCE := Vector2i(8, 11)
const LUCAS := Vector2i(2, 5)
const DIANE := Vector2i(14, 7)
const TALK_ONDINE := Vector2i(7, 3)

var _spotted: Array[StringName] = []


func _start_gym(flags: Array[StringName] = []) -> void:
	_spotted.clear()
	await _start(GYM, &"entrance", ENTRANCE, Vector2i.UP, "cerulean_city", flags)
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(npc_id: StringName, _trainer: StringName) -> void: _spotted.append(npc_id))


func _specs() -> Dictionary:
	var roster := NpcRoster.load_for_map(GYM)
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	var found: Dictionary = {}
	for spec: NpcSpec in roster.get_all():
		found[spec.id] = spec
	return found


func test_data_places_the_trainers_from_the_grid() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(PLAN_PATH), plan.error)
	var specs := _specs()
	var lucas: NpcSpec = specs[&"swimmer_lucas"]
	var diane: NpcSpec = specs[&"lass_diane"]
	assert_eq(lucas.cell, plan.cell_of("lucas"))
	assert_eq(lucas.cell, LUCAS)
	assert_eq(diane.cell, plan.cell_of("diane"))
	assert_eq(diane.cell, DIANE)
	assert_eq(lucas.facing, Vector2i.DOWN)
	assert_eq(diane.facing, Vector2i.UP)
	assert_eq(lucas.trainer_id, &"cerulean_gym_lucas")
	assert_eq(diane.trainer_id, &"cerulean_gym_diane")
	assert_eq(lucas.sight, 3)
	assert_eq(diane.sight, 3)
	assert_eq(specs[&"gym_guide"].cell, plan.cell_of("guide"))
	for id: StringName in [&"swimmer_lucas", &"lass_diane"]:
		var spec: NpcSpec = specs[id]
		assert_true(spec.if_flags.is_empty() and spec.unless_flags.is_empty(),
			"%s : aucune condition (combattable dès l'arrivée, avant l'invitation)" % id)


func test_trainer_teams_and_prizes() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var lucas := library.get_trainer(&"cerulean_gym_lucas")
	var diane := library.get_trainer(&"cerulean_gym_diane")
	assert_eq(lucas.name, "Nageur Lucas")
	assert_eq(lucas.prize_money, 80)
	assert_eq(lucas.team.size(), 2)
	assert_eq(lucas.team[0].species, &"horsea")
	assert_eq(lucas.team[0].level, 16)
	assert_eq(lucas.team[1].species, &"shellder")
	assert_eq(diane.name, "Jeune Dresseuse Diane")
	assert_eq(diane.prize_money, 285)
	assert_eq(diane.team[0].species, &"goldeen")
	assert_eq(diane.team[0].level, 19)


func test_both_are_avoidable_on_the_real_scene() -> void:
	await _start_gym()
	var map := _boot.get_map()
	var terrain := GridPaths.relief(map.get_grid(), SIZE)
	for npc: Npc in map.get_npcs():
		terrain.set_solid(npc.get_cell())
	var counted: Dictionary = {}
	for pair: Array in [[LUCAS, Vector2i.DOWN], [DIANE, Vector2i.UP]]:
		for k: int in range(1, 4):
			var cell: Vector2i = (pair[0] as Vector2i) + (pair[1] as Vector2i) * k
			if terrain.is_solid(cell):
				break
			counted[cell] = true
	assert_eq(counted.size(), 6, "deux vues de 3 cases")
	assert_eq(GridPaths.min_crossed(terrain, [ENTRANCE], [TALK_ONDINE], counted), 0,
		"on atteint Ondine sans entrer dans aucune vue")
	# Chacun est aussi évitable seul.
	for pair: Array in [[LUCAS, Vector2i.DOWN], [DIANE, Vector2i.UP]]:
		var one: Dictionary = {}
		for k: int in range(1, 4):
			one[(pair[0] as Vector2i) + (pair[1] as Vector2i) * k] = true
		assert_eq(GridPaths.min_crossed(terrain, [ENTRANCE], [TALK_ONDINE], one), 0)


func test_walking_into_lucas_file_starts_his_scene_before_any_invitation() -> void:
	await _start_gym()
	assert_false(GameState.flags.has_flag(&"misty_invited"), "avant l'invitation")
	_boot.get_map().spawn_player_at(_player, Vector2i(2, 10), Vector2i.UP)
	await wait_process_frames(2)
	await _walk(Vector2i.UP, Vector2i(2, 8))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	assert_eq(_spotted, [&"swimmer_lucas"] as Array[StringName], "Lucas voit le joueur")
	assert_eq(_scenes, [&"trainer_cerulean_gym_lucas"] as Array[StringName])
	assert_false(GameState.flags.has_flag(&"beaten_cerulean_gym_lucas"), "pas encore battu")


func test_walking_into_diane_file_starts_her_scene() -> void:
	await _start_gym()
	# Diane regarde vers le nord : sa vue couvre (14, 4..6).
	_boot.get_map().spawn_player_at(_player, Vector2i(14, 3), Vector2i.DOWN)
	await wait_process_frames(2)
	await _walk(Vector2i.DOWN, Vector2i(14, 4))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	assert_eq(_spotted, [&"lass_diane"] as Array[StringName])
	assert_eq(_scenes, [&"trainer_cerulean_gym_diane"] as Array[StringName])


func test_the_free_files_cost_nothing() -> void:
	await _start_gym()
	_boot.get_map().spawn_player_at(_player, Vector2i(4, 10), Vector2i.UP)
	await wait_process_frames(2)
	await _walk(Vector2i.UP, Vector2i(4, 3))
	_boot.get_map().spawn_player_at(_player, Vector2i(12, 10), Vector2i.UP)
	await wait_process_frames(2)
	await _walk(Vector2i.UP, Vector2i(12, 3))
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName], "aucun des deux ne voit le joueur")
	assert_false(_boot.get_cutscene_director().is_running())


func test_lines_before_and_after() -> void:
	var beaten: Array[StringName] = [&"beaten_cerulean_gym_lucas", &"beaten_cerulean_gym_diane"]
	await _start_gym(beaten)
	await _talk_to(&"swimmer_lucas")
	await _talk_to(&"lass_diane")
	assert_eq(_pages, ["Bon… Je retourne faire des longueurs.", "…Sauf aujourd'hui."]
		as Array[String], "répliques « après » (n° 25 et 27)")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogues/cerulean_city.json"))
	assert_eq((data["cerulean_gym_lucas_before"] as Dictionary)["pages"],
		["On s'entraîne même quand Ondine n'est pas là !"], "n° 24")
	assert_eq((data["cerulean_gym_diane_before"] as Dictionary)["pages"],
		["Ondine m'a appris une chose : ne jamais reculer."], "n° 26")


func test_beaten_trainers_no_longer_challenge() -> void:
	var beaten: Array[StringName] = [&"beaten_cerulean_gym_lucas", &"beaten_cerulean_gym_diane"]
	await _start_gym(beaten)
	_boot.get_map().spawn_player_at(_player, Vector2i(2, 10), Vector2i.UP)
	await wait_process_frames(2)
	await _walk(Vector2i.UP, Vector2i(2, 7))
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName])


func test_the_guide_has_three_states() -> void:
	var none: Array[StringName] = []
	var invited: Array[StringName] = [&"misty_invited"]
	var badge: Array[StringName] = [&"misty_invited", &"badge_cascade"]
	var texts: Array = [
		[none, ["Bienvenue à l'Arène d'Azuria !",
			"Ondine ? Elle est partie voir les défis du pont, au nord.",
			"Elle aime repérer les Dresseurs avant qu'ils viennent frapper à sa porte."]],
		[invited, ["Ondine t'attend au fond du bassin. Bonne chance !"]],
		[badge, ["Le Badge Cascade ! Je savais qu'elle t'apprécierait."]],
	]
	for entry: Array in texts:
		var said: Array[String] = await _says(GYM, &"entrance", Vector2i(6, 9), &"gym_guide",
			entry[0] as Array[StringName])
		assert_eq(said, entry[1] as Array[String])


func test_ondine_is_not_there_yet() -> void:
	await _start_gym([&"misty_invited"])
	assert_null(_boot.get_map().get_npc(&"misty"), "Ondine : T19")
