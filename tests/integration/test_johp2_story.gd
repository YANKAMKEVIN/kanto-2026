extends GutTest
## Arc des Pierres, JOHP2 (`jalon-joh-pierres.md` §4.2, critères) : le **vrai Boot** sur les départs
## de débogage, sans téléphone :
## - `johto_johp2_olivine_stranger` / `johto_johp2_olivine` : P-11, puis P-12, le don, la montée ;
## - `johto_johp2_deck` : P-13 et la traversée ; `johto_johp2_return` : P-19b au retour ;
## - `johto_johp2_tide_b1f` : les vannes dans l'ordre ; `johto_johp2_socle` : le revers ;
## - `johto_johp2_south_sea` : A-13, la mer fermée au sud d'Oliville.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_johp2_story_save.json"
const SETTINGS_PATH := "user://test_johp2_story_settings.json"
const ABSENT := "user://test_johp2_story_absent.json"
const FADE := 0.05
const TIMEOUT := 40.0

var _boot: Boot
var _saved_router: Array = []
var _previous_scene: Node


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-04T12:00:00") # un mercredi, le jour


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	GameState.clock = DeviceClock.new()


func _launch(start: String, map_id: StringName) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.settings_store = SettingsStore.new(MemoryFs.new(), SETTINGS_PATH)
	_boot.debug_start_path = STARTS + start + ".json"
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = true
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, map_id, start)


func _said() -> Array[StringName]:
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	return said


## Avance dialogues et choix (premier bouton si [param confirm]) tant que quelque chose tourne.
func _drive(confirm: bool = true) -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	var quiet := 0
	while quiet < 10 and Time.get_ticks_msec() < deadline:
		if director.is_running() or runner.is_running() or SceneRouter.is_transitioning():
			quiet = 0
		else:
			quiet += 1
		if runner.is_running() and box.is_open():
			if box.is_choice_showing():
				var cards := box.get_choice_cards()
				(cards.get_confirm_button() if confirm else cards.get_cancel_button()).pressed.emit()
			elif not runner.is_awaiting_choice():
				box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "la scène s'est terminée")


func _talk(dialogue: StringName) -> void:
	_boot.get_dialogue_runner().play(dialogue)


func _step(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)


func test_goulven_refuses_a_stranger() -> void:
	await _launch("johto_johp2_olivine_stranger", &"olivine_city")
	assert_not_null(_boot.get_map().get_npc(&"goulven"), "Goulven au ponton est")
	var said := _said()
	_talk(&"olivine_goulven")
	await _drive()
	assert_eq(said, [&"olivine_goulven"] as Array[StringName], "P-11")
	assert_false(GameState.flags.has_flag(&"johto_ferry_open"))
	assert_eq(_boot.get_map().map_id, &"olivine_city", "le Goéland reste à quai")


func test_goulven_gives_ultra_balls_and_boards() -> void:
	await _launch("johto_johp2_olivine", &"olivine_city")
	var before := GameState.bag.count_of(&"ultra_ball")
	_talk(&"olivine_goulven")
	await _drive(true)
	assert_eq(GameState.bag.count_of(&"ultra_ball"), before + 3, "Ultra Ball ×3")
	assert_true(GameState.flags.has_flag(&"johto_ferry_open"))
	assert_true(GameState.flags.has_flag(&"johto_goeland_outbound"))
	assert_eq(_boot.get_map().map_id, &"goeland_deck", "à bord")
	assert_eq(_boot.get_player().get_cell(), Vector2i(2, 4))
	assert_true(_boot.get_player().is_input_enabled(), "contrôles rendus")


func test_the_player_may_stay_ashore_and_board_later() -> void:
	await _launch("johto_johp2_olivine", &"olivine_city")
	var before := GameState.bag.count_of(&"ultra_ball")
	_talk(&"olivine_goulven")
	await _drive(false)
	assert_eq(_boot.get_map().map_id, &"olivine_city", "il reste à quai")
	assert_true(GameState.flags.has_flag(&"johto_ferry_open"))
	assert_false(GameState.flags.has_flag(&"johto_goeland_outbound"))
	_talk(&"olivine_goulven")
	await _drive(true)
	assert_eq(_boot.get_map().map_id, &"goeland_deck", "P-55 puis à bord")
	assert_eq(GameState.bag.count_of(&"ultra_ball"), before + 3, "don une seule fois")


func test_crossing_says_p13_and_lands_at_cianwood() -> void:
	await _launch("johto_johp2_deck", &"goeland_deck")
	var said := _said()
	_talk(&"goeland_goulven")
	await _drive()
	assert_eq(said, [&"goeland_goulven"] as Array[StringName], "P-13")
	assert_eq(_boot.get_map().map_id, &"cianwood_city", "fondu vers Irisia")
	assert_eq(_boot.get_player().get_cell(), Vector2i(28, 14))
	await _step(&"move_left")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"johto_cianwood_arrived"), 3.0)
	assert_true(GameState.flags.has_flag(&"johto_cianwood_arrived"), "arrivée notée en marchant")


func test_round_trip_is_free_before_the_setback() -> void:
	await _launch("johto_johp2_cianwood", &"cianwood_city")
	GameState.flags.set_flag(&"johto_goeland_outbound")
	_talk(&"cianwood_goulven")
	await _drive(true)
	assert_eq(_boot.get_map().map_id, &"goeland_deck")
	assert_false(GameState.flags.has_flag(&"johto_goeland_outbound"), "sens du retour")
	var said := _said()
	_talk(&"goeland_goulven")
	await _drive()
	assert_eq(_boot.get_map().map_id, &"olivine_city", "retour à Oliville")
	assert_eq(_boot.get_player().get_cell(), Vector2i(41, 34))
	assert_false(said.has(&"olivine_goulven_rosalia"), "P-19b seulement après le revers")


func test_valves_are_turned_in_order_and_open_the_fords() -> void:
	await _launch("johto_johp2_tide_b1f", &"tide_cave_b1f")
	var map := _boot.get_map()
	var grid := map.get_grid()
	assert_false(grid.can_enter(Vector2i(9, 4), Vector2i.DOWN), "gué a sous l'eau")
	assert_false(grid.can_enter(Vector2i(14, 8), Vector2i.DOWN), "gué b sous l'eau")
	_talk(&"tide_cave_b1f_vanne_1")
	await _drive()
	assert_true(GameState.flags.has_flag(&"johto_tide_valve_1"))
	assert_true(grid.can_enter(Vector2i(9, 4), Vector2i.DOWN), "le gué a s'ouvre sans quitter la carte")
	assert_false(grid.can_enter(Vector2i(14, 8), Vector2i.DOWN))
	_talk(&"tide_cave_b1f_vanne_2")
	await _drive()
	assert_true(GameState.flags.has_flag(&"johto_tide_valves_done"))
	assert_true(grid.can_enter(Vector2i(14, 8), Vector2i.DOWN), "le gué b s'ouvre")


func test_the_setback_cenere_leaves_with_the_stone() -> void:
	await _launch("johto_johp2_socle", &"tide_cave_b1f")
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"cenere"), "Cenere devant la mer")
	var director := _boot.get_cutscene_director()
	var said := _said()
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_left")
	await _drive()
	assert_eq(said, [&"tide_cave_b1f_socle", &"tide_cave_cenere_late", &"tide_cave_cenere_leaves",
		&"tide_cave_cenere_gone"] as Array[StringName], "P-17 à P-19")
	assert_true(GameState.flags.has_flag(&"johto_stone_tide_lost"))
	assert_null(map.get_npc(&"cenere"), "partie par la mer")
	assert_eq(GameState.bag.count_of(&"stone_tide"), 0, "JH-62 : jamais dans le Sac")
	assert_false((map.get_node(^"Decor/BateauNoir") as FlagGate).visible, "bateau noir parti")
	assert_true(_boot.get_player().is_input_enabled(), "contrôles rendus")


func test_goulven_sends_the_player_to_rosalia_once() -> void:
	await _launch("johto_johp2_return", &"goeland_deck")
	var said := _said()
	_talk(&"goeland_goulven")
	await _drive()
	assert_eq(_boot.get_map().map_id, &"olivine_city")
	assert_true(said.has(&"olivine_goulven_rosalia"), "P-19b")
	assert_true(GameState.flags.has_flag(&"johto_goulven_rosalia_told"))


## A-13 : le joueur en Surf touche la rangée 38 : P-59 et un pas vers le nord, quel que soit le sens.
func test_south_sea_is_closed_before_act_2() -> void:
	await _launch("johto_johp2_south_sea", &"olivine_city")
	var said := _said()
	var player := _boot.get_player()
	assert_eq(player.get_cell(), Vector2i(23, 39))
	var director := _boot.get_cutscene_director()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_up")
	await _drive()
	assert_eq(said, [&"olivine_south_sea_block"] as Array[StringName], "P-59")
	assert_eq(player.get_cell(), Vector2i(23, 37), "repoussé au nord de la rangée")
	assert_eq(player.get_mount(), Mount.Kind.SURF, "toujours en Surf")
	said.clear()
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_down")
	await _drive()
	assert_eq(said, [&"olivine_south_sea_block"] as Array[StringName], "refusé en descendant")
	assert_eq(player.get_cell(), Vector2i(23, 37))


## JOH7 inchangé : avec l'acte 2, la mer reste ouverte.
func test_south_sea_is_open_with_act_2() -> void:
	await _launch("johto_johp2_south_sea", &"olivine_city")
	GameState.flags.set_flag(&"johto_act2")
	var said := _said()
	var player := _boot.get_player()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return player.get_cell().y == 38, 5.0)
	Input.action_release(&"move_up")
	await wait_process_frames(30)
	assert_eq(said.size(), 0, "aucun refus")
