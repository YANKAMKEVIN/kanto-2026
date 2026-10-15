extends GutTest
## Le Rocket d'Azuria (jalon 14 T20b, dossier 17 §6, §14 ; jalon-14.md §2.12 ; textes n° 29 à 37)
## avec la vraie scène Boot, la vraie carte `cerulean_city` (départ `cerulean_garden`) et le combat
## instantané :
## - poursuite : « ! », n° 30, le Rocket court par le trou jusqu'à (21, 3) ; **une seule fois** ;
## - combat : n° 31, victoire → n° 33, CT28 **une seule fois**, n° 34, n° 35, départ par le trou,
##   `cerulean_rocket_beaten`, policier et ruban partis ;
## - défaite : réveil au Centre, le Rocket attend à son point d'arrêt, n° 32 puis le même combat ;
## - repéré puis rechargé : le Rocket est au point d'arrêt (aucune seconde poursuite) ;
## - Léo aidé ou non : aucune incidence.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/cerulean_garden.json"
const SAVE_PATH := "user://test_cerulean_rocket_save.json"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const ROCKET := &"cerulean_rocket"
const STOP := Vector2i(21, 3)
const SPOTTED: Array[String] = ["Hein ?! Un gamin ? Pas question que tu me suives !"]
const BEFORE: Array[String] = ["Bon. Tu l'auras voulu. Je ne vais pas me laisser coincer par un môme !"]
const RESUME: Array[String] = ["Encore toi ? Tu ne lâches jamais, hein."]
const BEATEN: Array[String] = [
	"Pfff… Je ne suis pas payé pour ça. Tiens, reprends ce truc, il ne vaut rien pour moi.",
]
const LEAVING: Array[String] = ["Les ordres viennent d'en haut. Moi, je fais ce qu'on me dit."]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _started: Array[StringName] = []
var _battles := 0


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T11:00:00")
	_fs = MemoryFs.new()
	_reset_log()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


func _reset_log() -> void:
	_pages.clear()
	_started.clear()
	_battles = 0


func _start(strong: bool, extra_flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"garden_start"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	GameState.heal_map = &"cerulean_center"
	GameState.heal_spawn = &"heal"
	for flag: StringName in extra_flags:
		GameState.flags.set_flag(flag)
	_set_team(strong)
	await wait_process_frames(2)
	await SceneRouter.change_map(&"cerulean_city", &"garden_start", Vector2i.RIGHT)
	await wait_process_frames(3)
	_hook()


func _hook() -> void:
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _started.append(id))
	_boot.get_battle_director().battle_started.connect(func(_trainer: StringName) -> void:
		_battles += 1)


func _set_team(strong: bool) -> void:
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander",
		60 if strong else 2, GameState.rng)
	lead.moves.clear()
	lead.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(lead)


func _busy() -> bool:
	return _boot.get_cutscene_director().is_running() \
			or _boot.get_dialogue_runner().is_running() or SceneRouter.is_transitioning()


func _distances(grid: GridWorld, goal: Vector2i) -> Dictionary:
	var dist: Dictionary = {goal: 0}
	var queue: Array[Vector2i] = [goal]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if not dist.has(next) and grid.get_step_target(next, -direction, _player) == cell:
				dist[next] = int(dist[cell]) + 1
				queue.append(next)
	return dist


func _goto(goal: Vector2i) -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline and not _busy():
		var cell := _player.get_cell()
		if cell == goal and not _player.is_moving():
			return
		var grid := _boot.get_map().get_grid()
		var dist := _distances(grid, goal)
		var step := Vector2i.ZERO
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if dist.has(next) and int(dist[next]) < int(dist.get(cell, 1 << 30)) \
					and grid.get_step_target(cell, direction) == next:
				step = direction
				break
		if step == Vector2i.ZERO:
			assert_true(false, "aucun chemin de %s vers %s" % [cell, goal])
			return
		var action: StringName = DIRECTIONS[step]
		Input.action_press(action)
		var target := cell + step
		var step_deadline := Time.get_ticks_msec() + 8000
		while _player.get_cell() != target and not _busy() and Time.get_ticks_msec() < step_deadline:
			await wait_process_frames(1)
		Input.action_release(action)
		await wait_until(func() -> bool: return not _player.is_moving() or _busy(), 3.0)


func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()
			or battle_director.is_running()) and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)


func _has_all(lines: Array[String]) -> bool:
	for line: String in lines:
		if not _pages.has(line):
			return false
	return true


## Entre dans le jardin : la bande (7, 2..3) lance la poursuite, jouée en entier.
func _chase() -> void:
	await _goto(Vector2i(7, 2))
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"cerulean_rocket_chase",
		"la bande de la poursuite lance la scène")
	await _play_through()


func _fight() -> void:
	await _goto(Vector2i(17, 3))
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"cerulean_rocket_fight",
		"la bande du combat lance la scène")
	await _play_through()


func test_the_chase_runs_once_and_the_rocket_waits_at_the_stop() -> void:
	await _start(true)
	var rocket := _boot.get_map().get_npc(ROCKET)
	assert_not_null(rocket)
	assert_eq(rocket.get_cell(), Vector2i(13, 2), "il fouille près du trou")
	assert_false(GameState.flags.has_flag(&"cerulean_rocket_spotted"))
	await _chase()
	assert_true(_has_all(SPOTTED), "n° 30")
	assert_true(GameState.flags.has_flag(&"cerulean_rocket_spotted"))
	assert_eq(rocket.get_cell(), STOP, "il s'est arrêté au fond de l'impasse")
	assert_eq(rocket.get_facing(), Vector2i.LEFT)
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_eq(_started, [&"cerulean_rocket_chase"] as Array[StringName])
	# Retour dans la rue, puis dans le jardin : aucune seconde poursuite.
	await _goto(Vector2i(5, 2))
	await _goto(Vector2i(8, 3))
	await wait_process_frames(5)
	assert_eq(_started, [&"cerulean_rocket_chase"] as Array[StringName], "une seule poursuite")
	assert_eq(_battles, 0)
	# Rechargé : le Rocket est au point d'arrêt (l'autosave n'a lieu qu'aux changements de carte).
	await SceneRouter.change_map(&"cerulean_city", &"garden_start", Vector2i.RIGHT)
	await wait_process_frames(3)
	var again := _boot.get_map().get_npc(ROCKET)
	assert_eq(again.get_cell(), STOP, "au retour, au point d'arrêt")
	assert_eq(again.get_facing(), Vector2i.LEFT)
	assert_push_error_count(0)


func test_victory_gives_the_tm_once_and_opens_the_house() -> void:
	await _start(true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"h4_policeman"))
	assert_not_null(map.get_npc(&"cerulean_police_tape"))
	await _chase()
	_reset_log()
	await _fight()
	assert_true(_has_all(BEFORE), "n° 31")
	assert_false(_pages.has(RESUME[0]))
	assert_eq(_battles, 1)
	assert_true(GameState.flags.has_flag(&"cerulean_rocket_beaten"))
	assert_true(_has_all(BEATEN), "n° 33")
	assert_true(_pages.has("%s reçoit la CT28 !" % GameState.player_name), "n° 34 : %s" % [_pages])
	assert_true(_has_all(LEAVING), "n° 35")
	assert_lt(_pages.find(BEATEN[0]), _pages.find(LEAVING[0]))
	assert_eq(GameState.bag.count_of(&"tm28"), 1, "CT28 une fois")
	assert_true(GameState.flags.has_flag(&"got_tm28"))
	assert_null(map.get_npc(ROCKET), "parti par le trou")
	assert_null(map.get_npc(&"h4_policeman"), "le policier de la maison est parti")
	assert_null(map.get_npc(&"cerulean_police_tape"), "le ruban est enlevé")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Rechargé : même état, aucune scène, aucune seconde CT28 ; la porte s'ouvre.
	_reset_log()
	await SceneRouter.change_map(&"cerulean_city", &"from_burgled_house", Vector2i.UP)
	await wait_process_frames(3)
	_hook()
	var after := _boot.get_map()
	assert_null(after.get_npc(ROCKET))
	assert_null(after.get_npc(&"h4_policeman"))
	assert_null(after.get_npc(&"cerulean_police_tape"))
	await _goto(Vector2i(17, 3))
	await _goto(Vector2i(14, 3))
	await wait_process_frames(5)
	assert_eq(_started.size(), 0, "plus aucune scène dans l'impasse")
	assert_eq(GameState.bag.count_of(&"tm28"), 1)
	await _goto(Vector2i(10, 10))
	_player.face(Vector2i.UP)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"cerulean_burgled_house",
		20.0)
	Input.action_release(&"move_up")
	assert_eq(_boot.get_map().map_id, &"cerulean_burgled_house", "la maison est ouverte")
	assert_push_error_count(0)


func test_a_defeat_wakes_at_the_center_and_the_rocket_waits_with_the_short_line() -> void:
	await _start(false)
	await _chase()
	_reset_log()
	await _fight()
	assert_true(_has_all(BEFORE), "n° 31")
	assert_true(GameState.flags.has_flag(&"lost_cerulean_rocket"))
	assert_false(GameState.flags.has_flag(&"cerulean_rocket_beaten"))
	assert_eq(GameState.bag.count_of(&"tm28"), 0)
	assert_eq(_boot.get_map().map_id, &"cerulean_center", "réveil au Centre")
	# Retour, plus fort : le Rocket est au point d'arrêt, n° 32 puis le même combat.
	_set_team(true)
	_reset_log()
	await SceneRouter.change_map(&"cerulean_city", &"impasse_start", Vector2i.RIGHT)
	await wait_process_frames(3)
	_hook()
	var rocket := _boot.get_map().get_npc(ROCKET)
	assert_eq(rocket.get_cell(), STOP, "il attend à son point d'arrêt")
	await _fight()
	assert_true(_has_all(RESUME), "n° 32")
	assert_false(_pages.has(BEFORE[0]), "pas n° 31")
	assert_true(GameState.flags.has_flag(&"cerulean_rocket_beaten"))
	assert_eq(GameState.bag.count_of(&"tm28"), 1, "CT28 une fois")
	assert_push_error_count(0)


func test_helping_leo_first_changes_nothing() -> void:
	await _start(true, [&"bill_met", &"bill_screen_checked", &"bill_module_checked",
		&"bill_in_cabin", &"bill_restored", &"got_ss_ticket", &"got_bill_rare_candy"])
	await _chase()
	assert_true(_has_all(SPOTTED))
	await _fight()
	assert_true(GameState.flags.has_flag(&"cerulean_rocket_beaten"))
	assert_eq(GameState.bag.count_of(&"tm28"), 1)
	assert_push_error_count(0)
