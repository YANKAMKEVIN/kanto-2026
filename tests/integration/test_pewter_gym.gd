extends GutTest
## L'Arène d'Argenta sur la vraie carte (jalon 10 T17, jalon-10.md §2.5, §2.6, §3 ; dossier 12
## §10) avec la vraie scène Boot, ses PNJ (data/npcs/pewter_gym.json), les vraies entrées
## `move_*` / `interact`, le combat instantané et une sauvegarde en mémoire :
## - chemin direct (x = 7) : le Campeur Liam repère le joueur en (7, 6), « ! », approche jusqu'à
##   la case voisine, réplique « avant », combat (graine cherchée), « D'accord… Tu es prêt. »,
##   `beaten_pewter_gym_liam` ; son approche ne ferme rien : Pierre reste atteignable ;
## - détour par l'est (x = 10) : 12 pas jusqu'à Pierre, Liam ne voit rien ;
## - Liam battu : il ne défie plus, sa réplique « après » est permanente ;
## - guide : accueil avant le badge, réaction après ;
## - caméra immobile pendant toute la traversée (salle entière à l'écran).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const TrainerSeed := preload("res://tests/helpers/trainer_seed.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
## Départ « Carapuce » du T16 (Carapuce N12 : Charge, Mimi-Queue, Écume ; Roucool N10).
const SQUIRTLE_START := "res://tools/debug_start/brock_squirtle.json"
const SAVE_PATH := "user://test_pewter_gym_save.json"
const MAP_ID := &"pewter_gym"
const DATE := "2026-10-09T17:00:00"
const FADE := 0.05
const TIMEOUT := 12.0
const WALK_STOP := &"test_walk_stop"
const SCENE_TIMEOUT_MS := 60000
## Écume, 3e capacité de Carapuce N12.
const BUBBLE := 2
const ENTRANCE := Vector2i(7, 9)
const TALK_CELL := Vector2i(7, 3)
const LIAM := Vector2i(2, 6)
const SPOTTED_CELL := Vector2i(7, 6)
const LIAM_FLAG := &"beaten_pewter_gym_liam"
const LIAM_BEFORE := "Pour atteindre Pierre, il faudra\nd'abord passer par moi !"
const LIAM_DEFEATED := "D'accord… Tu es prêt."
const LIAM_AFTER := "Pierre est encore plus solide."
const GUIDE_BEFORE := "Bienvenue à l'Arène d'Argenta.\nIci, chacun vient avec sa propre stratégie."
const GUIDE_AFTER := "Ton premier Badge…\nTu t'en souviendras longtemps."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _saved_router: Array = []
var _pages: Array[String] = []
var _spotted: Array[StringName] = []
var _steps := 0
## Case où [method _walk] arrête le joueur : dans [signal Player.moved], la direction est
## relâchée et le joueur bloqué un instant (le pas suivant ne s'enchaîne pas, comme une porte).
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_pages.clear()
	_spotted.clear()
	_steps = 0


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot dans l'Arène, joueur à l'entrée tourné ↑, partie du départ `brock_squirtle` ;
## [param flags] : drapeaux levés en plus.
func _start(flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = MAP_ID
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(SQUIRTLE_START, _boot.get_pokemon_data(),
		_boot.get_item_library()), "\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_boot.get_battle_director().speed_scale = 0.0
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text()))
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(npc_id: StringName, _trainer: StringName) -> void: _spotted.append(npc_id))
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, MAP_ID)
	assert_eq(_player.get_cell(), ENTRANCE)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	_steps += 1
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Maintient la direction jusqu'à [param until] (relâchée à l'arrivée sur la case, dans le
## signal du pas) ou jusqu'à ce qu'une scène bloque le joueur.
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


## Déroule la scène en cours : pages avancées, combat piloté (ATTAQUER puis Écume).
func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or _runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(BUBBLE)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_false(director.is_running(), "scène finie")


func _seed_against(trainer_id: StringName) -> int:
	return TrainerSeed.find(trainer_id, GameState.party, GameState.starter_species,
		_boot.get_pokemon_data(), _boot.get_item_library(), BUBBLE)


func _camera_position() -> Vector2:
	return _player.get_camera().get_screen_center_position()


func test_direct_path_liam_spots_the_player_and_his_approach_closes_nothing() -> void:
	await _start()
	var seed := _seed_against(&"pewter_gym_liam")
	assert_gt(seed, -1, "une victoire de Carapuce contre Liam")
	GameState.rng = GameRng.new(seed)
	var camera := _camera_position()
	await _walk(Vector2i.UP, TALK_CELL)
	assert_eq(_spotted, [&"camper_liam"] as Array[StringName], "Liam voit le joueur")
	assert_eq(_player.get_cell(), SPOTTED_CELL, "repéré en (7, 6), dans sa vision")
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"trainer_pewter_gym_liam")
	await _finish_scene()
	assert_eq(_boot.get_map().get_npc(&"camper_liam").get_cell(), SPOTTED_CELL + Vector2i.LEFT,
		"approche jusqu'à la case voisine")
	assert_eq(_pages, [LIAM_BEFORE, LIAM_DEFEATED] as Array[String], "avant, puis « vaincu »")
	assert_true(GameState.flags.has_flag(LIAM_FLAG), "Liam battu")
	assert_eq(GameState.money, 3000 + 200, "200 ₽")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# L'approche ne ferme rien : on monte jusqu'à Pierre par le même chemin.
	await _walk(Vector2i.UP, TALK_CELL)
	assert_eq(_player.get_cell(), TALK_CELL, "Pierre atteignable après Liam")
	assert_eq(_steps, 6, "chemin direct : 6 pas")
	assert_eq(_camera_position(), camera, "caméra immobile")
	assert_push_error_count(0)


func test_east_detour_avoids_liam_in_twelve_steps() -> void:
	await _start()
	var camera := _camera_position()
	await _walk(Vector2i.UP, Vector2i(7, 8))
	await _walk(Vector2i.RIGHT, Vector2i(10, 8))
	await _walk(Vector2i.UP, Vector2i(10, 3))
	await _walk(Vector2i.LEFT, TALK_CELL)
	assert_eq(_player.get_cell(), TALK_CELL, "devant Pierre")
	assert_eq(_steps, 12, "détour : 12 pas")
	assert_eq(_spotted, [] as Array[StringName], "Liam ne voit rien")
	assert_false(_boot.get_cutscene_director().is_running())
	assert_false(GameState.flags.has_flag(LIAM_FLAG), "Liam pas battu (évité)")
	assert_eq(_boot.get_map().get_npc(&"camper_liam").get_cell(), LIAM, "Liam n'a pas bougé")
	assert_eq(_camera_position(), camera, "caméra immobile")
	assert_push_error_count(0)


func test_beaten_liam_no_longer_challenges_and_keeps_his_after_line() -> void:
	await _start([LIAM_FLAG])
	await _walk(Vector2i.UP, SPOTTED_CELL)
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName], "battu : plus de défi")
	assert_false(_boot.get_cutscene_director().is_running())
	# Lui parler depuis la case voisine (Liam en (2, 6) tourné → : on se met en (3, 6), ←).
	await _walk(Vector2i.LEFT, LIAM + Vector2i.RIGHT)
	_player.face(Vector2i.LEFT)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, [LIAM_AFTER] as Array[String], "réplique « après », sans combat")
	assert_push_error_count(0)


func _talk_to_guide() -> void:
	# Guide en (5, 8) : on lui parle depuis (6, 8), tourné ←.
	await _walk(Vector2i.UP, Vector2i(7, 8))
	await _walk(Vector2i.LEFT, Vector2i(6, 8))
	_player.face(Vector2i.LEFT)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


func test_guide_welcomes_before_the_badge() -> void:
	await _start()
	await _talk_to_guide()
	assert_eq(_pages, [GUIDE_BEFORE] as Array[String])


func test_guide_reacts_after_the_badge() -> void:
	await _start([LIAM_FLAG, &"brock_met", &"badge_boulder"])
	await _talk_to_guide()
	assert_eq(_pages, [GUIDE_AFTER] as Array[String])
