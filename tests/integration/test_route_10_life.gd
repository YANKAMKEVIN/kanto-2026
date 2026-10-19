extends GutTest
## La vie de la Route 10 sud (jalon 18 T24, jalon-18.md §4.3, §4.13 ; dossier 21 §4.3, §12, §15.5
## n° 49 et 50) avec la vraie scène Boot et une sauvegarde en mémoire :
## - Hector et Paul : placés, équipes du dossier, facultatifs (le chemin de l'ouest ne croise pas leur
##   vue), l'un appelle dès qu'on entre dans sa vue, textes « après » une fois battus ;
## - la Super Potion : PRENDRE, une seule fois, absente au rechargement ;
## - la sortie sud de la grotte pose `dark_cave_crossed` (« Rejoindre Lavanville, au sud. ») en
##   silence, sans rencontre forcée ;
## - la sortie sud mène à Lavanville ; le titre d'arrivée est testé dans `test_lavender_town`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PLAN_PATH := "res://tools/plans/route_10.txt"
const SAVE_NAME := "test_route_10_life"
const START := "route_10_south"
const SPAWN := &"from_dark_cave_s_w"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _titles: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-16T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()
	_titles.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map_id] / [param spawn] ; [param start] = départ de débogage appliqué si
## [param fresh] ; joueur reposé sur [param cell] (le départ lui-même n'est pas une arrivée).
func _start(map_id: StringName, spawn: StringName, start: String, cell: Vector2i,
		facing: Vector2i, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
	_connect_signals()
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _connect_signals() -> void:
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.zone_announced.connect(func(zone: String, region: String) -> void:
		_titles.append("%s / %s" % [zone, region]))


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _called() -> bool:
	for id: StringName in _scenes:
		if String(id).begins_with("trainer_"):
			return true
	return false


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


## Marche vers [param direction] jusqu'à [param until] (ou jusqu'à un appel de Dresseur).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or _called(), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Examine ce qui est devant [param facing] depuis [param cell] (pages dans `_pages`).
func _read_from(cell: Vector2i, facing: Vector2i) -> void:
	_pages.clear()
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)
	await _press_interact()
	await wait_process_frames(4)
	if _runner.is_running():
		await _finish_scene()


## Case praticable voisine de [param cell] (hors hautes herbes) et la direction qui mène de
## cette case à [param cell].
func _neighbour(cell: Vector2i) -> Array:
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if _plan.is_walkable(from) and _plan.at(from) != "h":
			return [from, -direction]
	return []


func _bag(item: StringName) -> int:
	return GameState.bag.count_of(item)


func _begin(cell: Vector2i = Vector2i(8, 48), facing: Vector2i = Vector2i.DOWN,
		fresh: bool = true) -> void:
	await _start(&"route_10", SPAWN, START, cell, facing, fresh)


# --- Dresseurs -------------------------------------------------------------------------------

func test_hector_and_paul_are_placed_with_their_teams() -> void:
	await _begin()
	var map := _boot.get_map()
	var trainers := TrainerLibrary.new(_boot.get_pokemon_data())
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	var expected := {
		&"hector": [&"route_10_maniac_hector", 4, 1300, [&"nidorino", &"jigglypuff"], 26],
		&"paul": [&"route_10_hiker_paul", 5, 665, [&"geodude", &"onix"], 19],
	}
	for id: StringName in expected:
		var npc := map.get_npc(id)
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var info: Array = expected[id]
		assert_eq(npc.get_cell(), _plan.cell_of(String(id)), "%s : case de la grille" % id)
		assert_eq(npc.get_spec().trainer_id, info[0])
		assert_eq(npc.get_spec().sight, info[1])
		var trainer := trainers.get_trainer(info[0])
		assert_eq(trainer.prize_money, info[2])
		var team: Array[StringName] = []
		for slot: TrainerSlot in trainer.team:
			team.append(slot.species)
			assert_eq(slot.level, info[4])
		assert_eq(team, info[3] as Array[StringName])
	assert_eq(map.get_npcs().size(), 4, "Hector, Paul, le randonneur du nord, la Super Potion")


func test_hector_calls_as_soon_as_the_player_enters_his_sight() -> void:
	var hector := _plan.cell_of("hector")
	await _begin(Vector2i(9, hector.y), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, hector + Vector2i.LEFT)
	await wait_until(func() -> bool: return _called(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_route_10_maniac_hector"] as Array[StringName])
	assert_false(GameState.flags.has_flag(&"beaten_route_10_maniac_hector"))


func test_paul_calls_from_the_terrace_edge() -> void:
	var paul := _plan.cell_of("paul")
	await _begin(paul + Vector2i(5, -3), Vector2i.DOWN)
	await _walk(Vector2i.DOWN, paul + Vector2i(5, 0))
	await wait_until(func() -> bool: return _called(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_route_10_hiker_paul"] as Array[StringName])


func test_the_west_side_path_meets_neither_trainer() -> void:
	await _begin()
	await _walk(Vector2i.DOWN, Vector2i(8, 50))  # rangée 49 : scène silencieuse de la grotte
	await _finish_scene()
	await _walk(Vector2i.DOWN, Vector2i(8, 57))
	await wait_process_frames(20)
	assert_eq(_player.get_cell(), Vector2i(8, 57), "on descend jusqu'au carrefour sans combat")
	assert_eq(_scenes.filter(func(id: StringName) -> bool:
		return String(id).begins_with("trainer_")), [] as Array)
	assert_false(GameState.flags.has_flag(&"beaten_route_10_maniac_hector"))


func test_beaten_trainers_say_their_last_line() -> void:
	var texts := {
		&"hector": ["Pokémaniac Hector", "Un jour, j'aurai un Pokémon\nque personne n'a jamais vu."],
		&"paul": ["Montagnard Paul", "Tu vois la tour, là-bas ?\nLavanville est juste en dessous."],
	}
	for id: StringName in texts:
		var npc_cell := _plan.cell_of(String(id))
		await _begin(Vector2i(8, 48), Vector2i.DOWN)
		GameState.flags.set_flag(StringName("beaten_" + String(
			_boot.get_map().get_npc(id).get_spec().trainer_id)))
		for other: Npc in _boot.get_map().get_npcs():
			other.set_routine_held(true)
		var near := _neighbour(npc_cell)
		assert_false(near.is_empty(), "%s : case d'accès" % id)
		await _read_from(near[0], near[1])
		assert_eq(_pages, [texts[id][1]] as Array[String], String(id))
		assert_eq(_speakers, [texts[id][0]] as Array[String])
		_boot.queue_free()
		await wait_process_frames(3)
		_pages.clear()
		_speakers.clear()


# --- Objet -----------------------------------------------------------------------------------

func test_the_super_potion_is_taken_once_and_stays_gone() -> void:
	var cell := _plan.cell_of("route_10_item_1")
	assert_eq(cell, Vector2i(3, 66))
	var near := _neighbour(cell)
	assert_false(near.is_empty())
	await _begin(near[0], near[1])
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"route_10_item_1"), "la balle est au sol")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target)
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE)
	var before := _bag(&"super_potion")
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(&"route_10_item_1") == null, TIMEOUT)
	await _finish_scene()
	assert_eq(_bag(&"super_potion"), before + 1)
	assert_true(GameState.flags.has_flag(&"got_route_10_item_1"))
	assert_eq(_toasts.size(), 1, "un toast")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var after := _bag(&"super_potion")
	_boot.queue_free()
	await wait_process_frames(3)
	await _begin(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(&"route_10_item_1"), "absente au rechargement")
	assert_eq(_bag(&"super_potion"), after)
	assert_push_error_count(0)


# --- Objectif ----------------------------------------------------------------------------------

func test_leaving_the_cave_sets_the_objective_silently_and_once() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	await _begin()
	assert_eq(library.current_id(GameState.flags), &"cross_dark_cave", "dans la grotte")
	assert_false(GameState.flags.has_flag(&"dark_cave_crossed"))
	await _walk(Vector2i.DOWN, Vector2i(8, 50))
	await wait_process_frames(10)
	assert_eq(_scenes, [&"dark_cave_crossed"] as Array[StringName])
	assert_true(GameState.flags.has_flag(&"dark_cave_crossed"))
	assert_eq(library.current_id(GameState.flags), &"reach_lavender")
	assert_eq(library.current(GameState.flags), "rejoindre Lavanville, au sud.")
	assert_eq(_pages.size(), 0, "silencieuse : aucune page")
	assert_eq(_toasts.size(), 0)
	# La rangée est franchie de toute case : Lavanville atteinte, l'objectif change (T24).
	GameState.flags.set_flag(&"lavender_reached")
	assert_eq(library.current_id(GameState.flags), &"visit_tower")


func test_no_trigger_before_the_cave_exit_row() -> void:
	await _begin()
	var triggers := _boot.get_map().get_node(^"Triggers")
	var cells: Array[Vector2i] = []
	for point: Node in triggers.get_children():
		if point.get(&"cutscene_id") == &"dark_cave_crossed":
			cells.append_array(point.call(&"get_cells"))
	assert_eq(cells.size(), 13, "13 cases, rangée 49")
	for cell: Vector2i in cells:
		assert_eq(cell.y, 49)
		assert_true(cell.x >= 3 and cell.x <= 15)
