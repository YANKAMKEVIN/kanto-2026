extends GutTest
## Dalles tournantes dans le moteur (jalon 20 T19, `docs/tech/jalon-20.md` §2.4.4, §2.13 ; dossier
## 23 §13.3, §19). Vraie scène Boot sur la carte de QA `qa_spin_j20` (retirée au T24 ; les tests
## sur `rocket_hideout_b2f` viendront avec ses cartes, T20) : départ (2, 6) tourné ↑, dalle →
## (2, 5), dalle ↑ (5, 5), arrêt (5, 2), trajet « E3,N3 » ; Dresseur `guetteur` (8, 4) qui voit
## (5, 4), au milieu de la glisse ; Dresseur `gardien` (8, 2) qui voit la case d'arrêt.
## - glisse au pas près (`FrameSim`), en courant, pivot à chaque dalle ;
## - entrées ignorées, menu et retour Android refusés pendant la glisse ;
## - aucune autosave (ni demandée, ni à l'arrière-plan) pendant la glisse ;
## - compagnon rentré puis revenu ;
## - le Dresseur qui voit la case d'arrêt réagit, pas celui qui voit le milieu du trajet ;
## - application coupée en pleine glisse : reprise sur la dernière case stable ; sauvegarde posée
##   sur une dalle : reprise sur la case d'arrêt ;
## - pas refusé : glisse arrêtée sur place ; hors repaire : directeur en veille.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_spin_slide_save.json"
const MAP := &"qa_spin_j20"
const START := Vector2i(2, 6)
const ARROW := Vector2i(2, 5)
const STOP := Vector2i(5, 2)
const PATH: Array[Vector2i] = [Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4),
	Vector2i(5, 3), Vector2i(5, 2)]
const FACINGS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.UP,
	Vector2i.UP, Vector2i.UP]
const BEATEN: Array[StringName] = [&"beaten_mt_moon_rocket_1", &"beaten_mt_moon_rocket_3"]
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _player: Player
var _spin: SpinTileDirector
var _fs: MemoryFs
var _saved_router: Array = []
## Cases des `moved` du joueur, et l'image simulée de chacun.
var _moves: Array[Vector2i] = []
var _move_frames: Array[int] = []
var _facings: Array[Vector2i] = []
var _events: Array[String] = []
var _sim: FrameSim


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_moves.clear()
	_move_frames.clear()
	_facings.clear()
	_events.clear()
	_sim = null


func after_each() -> void:
	if _sim != null:
		_sim.finish()
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	get_tree().paused = false
	for action: StringName in [&"interact", &"run", &"menu", &"move_up", &"move_down",
			&"move_left", &"move_right"]:
		Input.action_release(action)


# --- Glisse ------------------------------------------------------------------------------------

func test_the_slide_plays_step_by_step_at_running_speed() -> void:
	await _start()
	_remove_trainers()
	assert_eq(_spin.get_field(), _boot.get_map().get_node(^"SpinTiles"), "SpinTiles trouvé")
	await _walk_onto_the_arrow()
	assert_true(_spin.is_running(), "la glisse part dans le pas qui pose sur la dalle")
	assert_true(_player.is_blocked_by(SpinTileDirector.LOCK_REASON), "verrou « spin »")
	assert_false(_boot.is_stable(), "partie pas stable pendant la glisse")
	assert_false(_boot.get_hud().are_controls_visible(), "contrôles cachés")
	assert_true(_player.is_running(), "pas de course")
	await _run_slide()
	assert_eq(_moves, [ARROW] + PATH, "un pas par case du trajet, dans l'ordre")
	assert_eq(_facings, FACINGS, "le joueur pivote dans le sens de chaque dalle")
	assert_eq(_events, ["started:%s" % ARROW, "finished:%s" % STOP] as Array[String])
	assert_eq(_player.get_cell(), STOP)
	assert_eq(_player.get_facing(), Vector2i.UP)
	# Au pas près : chaque pas de la glisse dure le temps d'un pas de course (pas fini avant la
	# durée, au plus une image de plus), sans image d'arrêt entre deux pas.
	var per_step := ceili(Grid.RUN_STEP_DURATION / FrameSim.STEP - 0.001)
	for i: int in range(1, _move_frames.size()):
		var frames := _move_frames[i] - _move_frames[i - 1]
		assert_between(frames, per_step, per_step + 1, "pas %d : %d images" % [i, frames])
	assert_false(_spin.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre à l'arrêt")
	assert_true(_boot.is_stable())
	assert_true(_boot.get_hud().are_controls_visible(), "contrôles revenus")
	assert_eq(_boot.get_map().map_id, MAP, "aucun passage")
	assert_push_error_count(0)


func test_inputs_menu_and_back_are_refused_during_the_slide() -> void:
	await _start()
	_remove_trainers()
	await _walk_onto_the_arrow()
	assert_true(_spin.is_running())
	Input.action_press(&"move_down")
	Input.action_press(&"move_left")
	await _sim.frame()
	assert_false(_boot.get_menu_director().open(), "menu refusé")
	_boot.get_hud().menu_requested.emit()
	assert_false(_boot.get_menu_director().is_open(), "bouton MENU sans effet")
	_boot._on_go_back()
	assert_false(_boot.get_menu_director().is_open(), "retour Android ignoré")
	await _run_slide()
	Input.action_release(&"move_down")
	Input.action_release(&"move_left")
	assert_eq(_moves, [ARROW] + PATH, "trajet inchangé par les directions tenues")
	assert_eq(_player.get_cell(), STOP)
	assert_true(_boot.get_menu_director().open(), "menu de nouveau permis à l'arrêt")
	_boot.get_menu_director().close()


func test_no_autosave_is_written_during_the_slide() -> void:
	await _start()
	_remove_trainers()
	await wait_until(func() -> bool: return not _boot._save_coordinator.has_pending(), TIMEOUT)
	await _walk_onto_the_arrow()
	var writes := _writes()
	_boot.request_autosave("test")
	_boot._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var during: Array[int] = []
	_spin.slide_finished.connect(func(_cell: Vector2i) -> void: during.append(_writes()))
	await _run_slide()
	assert_eq(during, [writes] as Array[int], "aucune écriture pendant la glisse")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	assert_gt(_writes(), writes, "la demande est écrite une fois arrêté")
	assert_eq(_saved_cell(), STOP, "sauvée sur la case d'arrêt")


func test_the_companion_retracts_then_returns() -> void:
	await _start()
	_remove_trainers()
	var companion := _boot.get_companion_controller()
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 15, GameRng.new(7))
	GameState.party.add(lead)
	GameState.set_companion(lead)
	# Tourné ←, la case derrière le joueur (3, 6) est libre (sous lui, c'est le mur).
	_player.face(Vector2i.LEFT)
	companion.refresh()
	await wait_until(func() -> bool: return companion.is_shown(), TIMEOUT)
	assert_true(companion.is_shown(), "compagnon dehors avant la glisse")
	assert_true(companion.get_trail().is_placed(), "il suit")
	# Boot (branché avant le test) le rappelle dans le signal même du début de la glisse.
	var followed_at_start: Array[bool] = []
	_spin.slide_started.connect(func(_slide: SpinSlide) -> void:
		followed_at_start.append(companion.get_trail().is_placed()))
	await _walk_onto_the_arrow()
	assert_eq(followed_at_start, [false] as Array[bool], "rappelé dès le début de la glisse")
	# L'éclat de rappel (Companion.BURST) finit bien avant la glisse (6 pas de course).
	var burst_frames := ceili(Companion.BURST / FrameSim.STEP) + 1
	for i: int in burst_frames:
		await _sim.frame()
	assert_true(_spin.is_running(), "toujours en glisse")
	assert_false(companion.is_shown(), "rentré pendant la glisse")
	await _run_slide()
	_sim.finish()
	_sim = null
	await wait_until(func() -> bool: return companion.is_shown(), TIMEOUT)
	assert_true(companion.is_shown(), "revenu à l'arrêt")
	assert_ne(companion.get_node_2d().get_cell(), STOP, "pas sur la case du joueur")


func test_the_trainer_who_sees_the_stop_reacts() -> void:
	await _start()
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 15, GameRng.new(7))
	GameState.party.add(lead)
	var spotted: Array[StringName] = []
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(_npc: StringName, trainer: StringName) -> void: spotted.append(trainer))
	await _walk_onto_the_arrow()
	await _run_slide()
	assert_eq(spotted, [&"mt_moon_rocket_3"] as Array[StringName],
		"le gardien voit la case d'arrêt ; le guetteur n'a pas vu le milieu du trajet")
	assert_true(_boot.get_cutscene_director().is_running(), "sa séquence est partie")
	assert_false(_boot.is_stable())
	# Laisser la séquence (« ! », approche, réplique) aller jusqu'au combat avant de libérer Boot.
	_sim.finish()
	_sim = null
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not _boot.get_battle_director().is_running() and Time.get_ticks_msec() < deadline:
		if runner.is_running() and box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(_boot.get_battle_director().is_running(), "combat contre le gardien")


# --- Reprise -----------------------------------------------------------------------------------

func test_an_app_killed_mid_slide_resumes_on_the_last_stable_save() -> void:
	await _start()
	_remove_trainers()
	assert_eq(_boot._write_save("test"), OK)
	assert_eq(_saved_cell(), START)
	await _walk_onto_the_arrow()
	for i: int in 15:
		await _sim.frame()
	assert_true(_spin.is_running(), "en pleine glisse")
	assert_ne(_player.get_cell(), ARROW, "déjà parti de la dalle")
	_boot._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_saved_cell(), START, "rien d'écrit à l'arrière-plan")
	_sim.finish()
	_sim = null
	_boot.queue_free()
	await wait_process_frames(2)
	await _boot_on(&"")
	assert_eq(_boot.get_map().map_id, MAP)
	assert_eq(_player.get_cell(), START, "reprise sur la dernière case stable")
	assert_false(_spin.is_running())
	assert_true(_boot.is_stable())


func test_a_save_on_an_arrow_resumes_on_its_stop() -> void:
	await _start()
	_remove_trainers()
	# Partie posée sur une dalle (sauvegarde ancienne ou abîmée : le verrou l'empêche en jeu).
	GameState.set_player_location(MAP, ARROW, Vector2i.RIGHT)
	assert_eq(_boot.save_system.write(GameState.to_dict()), OK)
	assert_eq(_saved_cell(), ARROW)
	_boot.queue_free()
	await wait_process_frames(2)
	await _boot_on(&"")
	assert_eq(_boot.get_map().map_id, MAP)
	assert_eq(_player.get_cell(), STOP, "posé sur la case d'arrêt de la dalle")
	assert_false(_spin.is_running(), "aucune glisse jouée")
	assert_true(_boot.is_stable())
	assert_eq(_spin.stable_cell(ARROW), STOP)
	assert_eq(_spin.stable_cell(START), START)


# --- Cas limites -------------------------------------------------------------------------------

func test_a_refused_step_stops_the_slide_in_place() -> void:
	await _start()
	_remove_trainers()
	var spec := NpcSpec.new()
	spec.id = &"qa_blocker"
	spec.cell = Vector2i(5, 4)
	spec.facing = Vector2i.DOWN
	_boot.get_map().add_npc(spec)
	await _walk_onto_the_arrow()
	await _run_slide()
	assert_push_error("pas refusé")
	assert_eq(_events.back(), "finished:%s" % Vector2i(5, 5), "arrêtée sur la dernière case")
	assert_eq(_player.get_cell(), Vector2i(5, 5))
	assert_false(_spin.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre")


func test_the_director_sleeps_outside_the_hideout() -> void:
	await _boot_on(&"qa_gift_j20", &"start")
	assert_null(_spin.get_field(), "aucun SpinTiles")
	assert_false(_spin.is_processing(), "aucun traitement par image")
	assert_false(_spin.is_running())
	assert_eq(_spin.stable_cell(Vector2i(3, 2)), Vector2i(3, 2))
	assert_eq(_spin.process_mode, Node.PROCESS_MODE_PAUSABLE)


# --- Outils ------------------------------------------------------------------------------------

func _start() -> void:
	await _boot_on(MAP, &"start")
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	_boot.get_map().refresh_npcs(GameState.flags)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _boot_on(map: StringName, spawn: StringName = &"") -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	if not map.is_empty():
		_boot.start_map = map
		_boot.start_spawn = spawn
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_spin = _boot.get_spin_director()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player.moved.connect(func(cell: Vector2i) -> void:
		_moves.append(cell)
		_move_frames.append(_sim.frames if _sim != null else -1))
	_player.step_started.connect(func(_from: Vector2i, _to: Vector2i, _kind: StringName) -> void:
		if _spin.is_running():
			_facings.append(_player.get_facing()))
	_spin.slide_started.connect(func(slide: SpinSlide) -> void:
		_events.append("started:%s" % slide.start))
	_spin.slide_finished.connect(func(cell: Vector2i) -> void:
		_events.append("finished:%s" % cell))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Dresseurs de QA battus et retirés (leurs PNJ sont conditionnés par « battu »).
func _remove_trainers() -> void:
	for flag: StringName in BEATEN:
		GameState.flags.set_flag(flag)
	_boot.get_map().refresh_npcs(GameState.flags)


## Un pas **libre** (entrée tenue) de (2, 6) vers la dalle (2, 5), en images simulées ; rend la
## main dès que la glisse est partie (ou après le pas).
func _walk_onto_the_arrow() -> void:
	assert_eq(_player.get_cell(), START, "au départ")
	_player.face(Vector2i.UP)
	_moves.clear()
	_move_frames.clear()
	_sim = FrameSim.new(get_tree(), [_player])
	Input.action_press(&"move_up")
	await _sim.frame()
	Input.action_release(&"move_up")
	assert_true(_player.is_moving(), "le pas libre est parti")
	await _sim.run_until(func() -> bool: return _spin.is_running() or not _player.is_moving(),
		TIMEOUT)


## Images simulées jusqu'à la fin de la glisse (signal différé compris).
func _run_slide() -> void:
	await _sim.run_until(func() -> bool:
		return not _spin.is_running() and not _player.is_moving(), TIMEOUT)


func _writes() -> int:
	return _fs.journal.filter(func(line: String) -> bool: return line.begins_with("write")).size()


func _saved_cell() -> Vector2i:
	var saved: Dictionary = JSON.parse_string(_fs.read_text(SAVE_PATH))
	var cell: Array = saved.get("cell", [])
	return Vector2i(int(cell[0]), int(cell[1]))
