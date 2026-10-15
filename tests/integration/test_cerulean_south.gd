extends GutTest
## Le barrage sud d'Azuria (jalon 14 T20b, dossier 17 §3.3, §6.3 ; jalon-14.md §2.12 ; textes
## n° 38 à 41) avec la vraie scène Boot et la vraie carte :
## - avant la victoire : policier (31, 38) et barrières (32..33, 38), aucun passage, n° 40 en lui
##   parlant ;
## - après la victoire (même visite ou suivantes) : la bande (31..33, 37) joue n° 41, le policier
##   part, les barrières aussi, `cerulean_south_guard_left` est levé, le bord sud mène à la Route 5
##   (« ROUTE 5 — À venir » au J14, la vraie carte depuis le J15 T21) ; plus de policier ensuite ;
## - victoire sans être passé au sud (partie quittée) : le policier est encore là, annonce la
##   réouverture et part ;
## - habitants (n° 38, 39) : réagissent à la victoire.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/cerulean_after.json"
const SAVE_PATH := "user://test_cerulean_south_save.json"
const FADE := 0.05
const TIMEOUT := 20.0
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const GUARD := &"cerulean_south_guard"
const BARRIERS: Array[StringName] = [&"cerulean_barrier_w", &"cerulean_barrier_e"]
const BEFORE: String = "On recherche un voleur. Personne ne sort par le sud tant qu'il court."
const LEAVING: String = "Le voleur a filé ? Alors ma garde est finie. La route du sud est libre."

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _started: Array[StringName] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration,
		SceneRouter.coming_soon_enabled]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	SceneRouter.coming_soon_enabled = true
	GameState.clock = FixedClock.new("2026-10-14T11:00:00")
	_pages.clear()
	_started.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	SceneRouter.coming_soon_enabled = _saved_router[2]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


## Boot à Azuria, au bas de la rue (31..33, 36), avec les drapeaux de la partie « après »
## ([param beaten] : Rocket battu) plus [param extra].
func _start(beaten: bool, extra: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"from_mart"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	if not beaten:
		for flag: StringName in [&"cerulean_rocket_beaten", &"got_tm28"]:
			GameState.flags.set_flag(flag, false)
	for flag: StringName in extra:
		GameState.flags.set_flag(flag)
	await wait_process_frames(2)
	await SceneRouter.change_map(&"cerulean_city", &"from_mart", Vector2i.DOWN)
	await wait_process_frames(3)
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _started.append(id))
	_boot.get_map().spawn_player_at(_player, Vector2i(32, 36), Vector2i.DOWN)
	await wait_process_frames(3)


func _busy() -> bool:
	return _boot.get_cutscene_director().is_running() \
			or _boot.get_dialogue_runner().is_running() or SceneRouter.is_transitioning()


func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + 60000
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)


func _step(direction: Vector2i) -> void:
	var action: StringName = DIRECTIONS[direction]
	var target := _player.get_cell() + direction
	Input.action_press(action)
	var deadline := Time.get_ticks_msec() + 8000
	while _player.get_cell() != target and not _busy() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving() or _busy(), 3.0)


func _talk_to_the_guard() -> void:
	var map := _boot.get_map()
	map.spawn_player_at(_player, Vector2i(31, 37), Vector2i.DOWN)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _busy(), TIMEOUT)
	await _play_through()


func test_before_the_victory_nothing_passes_and_the_guard_gives_line_40() -> void:
	await _start(false)
	var map := _boot.get_map()
	var guard := map.get_npc(GUARD)
	assert_not_null(guard)
	assert_eq(guard.get_cell(), Vector2i(31, 38))
	assert_eq(guard.get_facing(), Vector2i.UP)
	for id: StringName in BARRIERS:
		assert_not_null(map.get_npc(id), "%s posée" % id)
	assert_eq(map.get_npc(BARRIERS[0]).get_cell(), Vector2i(32, 38))
	assert_eq(map.get_npc(BARRIERS[1]).get_cell(), Vector2i(33, 38))
	var reach := map.get_grid().find_reachable(Vector2i(32, 36), _player)
	for x: int in [31, 32, 33]:
		assert_true(reach.has(Vector2i(x, 37)), "la bande est atteignable (%d)" % x)
		assert_false(reach.has(Vector2i(x, 38)), "(%d, 38) : aucun passage" % x)
		assert_false(reach.has(Vector2i(x, 40)), "(%d, 40) : aucun passage" % x)
	await _talk_to_the_guard()
	assert_eq(_pages, [BEFORE] as Array[String], "n° 40")
	assert_eq(_started.size(), 0, "aucune scène avant la victoire")
	assert_eq(GameState.flags.has_flag(&"cerulean_south_guard_left"), false)
	assert_push_error_count(0)


func test_after_the_victory_the_band_plays_line_41_and_the_guard_leaves() -> void:
	await _start(true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(GUARD), "le policier garde encore la sortie")
	await _step(Vector2i.DOWN)  # (32, 37) : la bande
	await wait_until(func() -> bool: return _busy(), TIMEOUT)
	await _play_through()
	assert_eq(_started, [&"cerulean_south_guard"] as Array[StringName])
	assert_eq(_pages, [LEAVING] as Array[String], "n° 41")
	assert_true(GameState.flags.has_flag(&"cerulean_south_guard_left"))
	assert_null(map.get_npc(GUARD), "le policier est parti")
	for id: StringName in BARRIERS:
		assert_null(map.get_npc(id), "%s retirée" % id)
	assert_true(_player.is_input_enabled(), "joueur libre")
	var reach := map.get_grid().find_reachable(_player.get_cell(), _player)
	for x: int in [31, 32, 33]:
		assert_true(reach.has(Vector2i(x, 40)), "le bord sud est libre (%d)" % x)
	# Rechargé : absent, aucune scène, le bord sud mène à la Route 5 (J15 T21).
	_started.clear()
	await SceneRouter.change_map(&"cerulean_city", &"from_mart", Vector2i.DOWN)
	await wait_process_frames(3)
	var again := _boot.get_map()
	assert_null(again.get_npc(GUARD))
	assert_null(again.get_npc(BARRIERS[0]))
	again.spawn_player_at(_player, Vector2i(32, 36), Vector2i.DOWN)
	await wait_process_frames(3)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await wait_process_frames(5)
	assert_eq(_started.size(), 0, "la bande ne rejoue rien")
	var cell := Vector2i(32, 40)
	again.spawn_player_at(_player, cell, Vector2i.DOWN)
	await wait_process_frames(3)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_5", TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"route_5", "le bord sud mène à la Route 5")
	assert_false(_boot.get_coming_soon_screen().is_showing())
	assert_push_error_count(0)


func test_the_victory_without_passing_south_keeps_the_guard_who_announces_and_leaves() -> void:
	await _start(true)
	# Partie quittée avant le sud : au retour, le policier est là ; lui parler joue la même scène.
	await _talk_to_the_guard()
	assert_eq(_pages, [LEAVING] as Array[String], "n° 41 en lui parlant")
	assert_null(_boot.get_map().get_npc(GUARD))
	assert_true(GameState.flags.has_flag(&"cerulean_south_guard_left"))
	assert_push_error_count(0)


func test_residents_react_to_the_victory() -> void:
	await _start(true)
	var fisher: DialogueLibrary = _boot.get_dialogue_library()
	var flags := GameState.flags
	assert_eq(fisher.get_dialogue(&"cerulean_h1_fisher").pick(flags).pages[0].text,
		"Le voleur s'est enfui par le jardin, paraît-il. On n'a plus revu personne en noir.",
		"n° 38")
	assert_eq(fisher.get_dialogue(&"cerulean_h3_neighbor").pick(flags).pages[0].text,
		"La police est partie. On peut de nouveau aller vers le sud !", "n° 39")
	var before := StoryFlags.new()
	assert_eq(fisher.get_dialogue(&"cerulean_h1_fisher").pick(before).pages[0].text,
		"Pas de canne aujourd'hui.")
	assert_push_error_count(0)
