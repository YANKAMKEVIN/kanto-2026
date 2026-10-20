extends GutTest
## Sauvegarde à la mise en arrière-plan (passe systèmes 2, S2A, `systemes-2.md` §2.12) avec la
## vraie scène Boot, un [SaveSystem] sur un système de fichiers en mémoire et une horloge du point
## de reprise imposée :
## - pause pendant un dialogue, une scène, un combat → le point de reprise (état d'avant) est
##   écrit, jamais l'état courant ; relancée, la partie reprend juste avant ;
## - pause après une écriture immédiate de la scène → rien (jamais plus ancien que le disque) ;
## - `FOCUS_OUT` puis `FOCUS_IN` en moins de 1 s → rien ; `FOCUS_OUT` qui dure → écriture ;
## - jamais deux écritures d'arrière-plan en moins de 2 s ;
## - écriture qui échoue → nouvelle tentative.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_s2a_save.json"
const DATE := "2026-10-20T10:00:00"
const FADE := 0.05
const TIMEOUT := 12.0

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _fades: Array[float] = []
## Horloge du point de reprise (s), avancée à la main.
var _now: Array[float] = [100.0]


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_now[0] = 100.0


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _start_boot(map: StringName = &"player_house_2f", spawn: StringName = &"start",
		facing: Vector2i = Vector2i.DOWN) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	_boot.background_clock = func() -> float: return _now[0]
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	await wait_process_frames(2)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le dialogue s'est terminé")


## Dialogue lancé puis une image : le point de reprise est capturé.
func _start_dialogue() -> void:
	assert_true(_boot.get_dialogue_runner().play(&"mom_wakeup", null, _boot.get_map()))
	await wait_process_frames(2)
	assert_false(_boot.is_stable())


# --- Point de reprise -------------------------------------------------------------------

func test_pause_during_a_dialogue_writes_the_state_from_before_it() -> void:
	await _start_boot()
	var money := GameState.money
	var writes := _writes()
	await _start_dialogue()
	GameState.add_money(500)  # ce qui se passe pendant le dialogue
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "point de reprise écrit")
	assert_eq(int(_saved().get("money", -1)), money, "état d'avant le dialogue")
	assert_eq(_saved().get("map"), "player_house_2f")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "déjà sur le disque : rien de plus")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _finish_dialogue()
	await wait_process_frames(2)
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(int(_saved().get("money", -1)), money + 500, "stable : état courant")
	assert_push_error_count(0)


func test_a_scene_interrupted_resumes_just_before_it() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	GameState.flags.set_flag(&"starter_chosen")
	var cell := _boot.get_player().get_cell()
	var money := GameState.money
	var cutscenes := _boot.get_cutscene_director()
	assert_true(cutscenes.play(&"route_1_potion"), "scène de la Potion")
	await wait_process_frames(3)
	assert_true(cutscenes.is_running())
	GameState.add_money(500)  # ce qui se passe pendant la scène
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := _saved()
	assert_eq(int(saved.get("money", -1)), money, "état d'avant la scène")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), cell, "à la case d'avant la scène")
	# Android tue l'application : relancée, la partie reprend juste avant la scène.
	_boot.queue_free()
	await wait_process_frames(2)
	await _start_boot()
	assert_eq(_boot.get_map().map_id, &"route_1")
	assert_eq(_boot.get_player().get_cell(), cell)
	assert_eq(GameState.money, money)
	assert_false(GameState.flags.has_flag(&"got_potion_route_1"), "scène à rejouer")
	assert_eq(GameState.bag.count_of(&"potion"), 0, "aucune Potion dupliquée ni perdue")
	assert_push_error_count(0)


func test_an_immediate_write_during_the_scene_is_never_overwritten_by_older() -> void:
	await _start_boot()
	await _start_dialogue()
	GameState.add_money(700)
	assert_eq(_boot._write_save("don"), OK, "écriture immédiate pendant la scène")
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes, "le disque a dépassé le point de reprise : rien")
	assert_eq(int(_saved().get("money", -1)), GameState.money)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _finish_dialogue()
	assert_push_error_count(0)


func test_pause_during_a_wild_battle_writes_the_team_from_before_it() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var data := _boot.get_pokemon_data()
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)  # stable : équipe écrite
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var hp := GameState.party.get_lead().hp
	assert_true(_boot.get_encounter_director().start_encounter(
		WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	GameState.party.get_lead().hp = 1  # dégâts du combat
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var party: Array = _saved().get("party", [])
	assert_eq(party.size(), 1)
	if party.size() == 1:
		assert_eq(int((party[0] as Dictionary).get("hp", 0)), hp, "PV d'avant le combat")
	assert_eq(_saved().get("map"), "route_1")


# --- FOCUS_OUT ---------------------------------------------------------------------------

func test_focus_out_then_in_within_a_second_writes_nothing() -> void:
	await _start_boot()
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_now[0] += 0.5
	await wait_process_frames(2)
	_boot.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_now[0] += 5.0
	await wait_process_frames(2)
	assert_eq(_writes(), writes, "bandeau refermé tout de suite : rien")


func test_a_lasting_focus_out_writes_once() -> void:
	await _start_boot()
	await _start_dialogue()
	GameState.add_money(500)
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_now[0] += 0.9
	await wait_process_frames(2)
	assert_eq(_writes(), writes, "pas avant le délai de garde")
	_now[0] += 0.1
	await wait_process_frames(2)
	assert_eq(_writes(), writes + 1, "point de reprise écrit après 1 s")
	assert_ne(int(_saved().get("money", -1)), GameState.money, "état d'avant le dialogue")
	# Puis Android met l'application en pause dans la foulée : pas de seconde écriture.
	_now[0] += 0.5
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _finish_dialogue()


func test_never_two_background_writes_within_two_seconds() -> void:
	await _start_boot()
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_now[0] += 1.9
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(_writes(), writes + 1)
	_now[0] += 0.1
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 2)


# --- Échec -------------------------------------------------------------------------------

func test_a_failed_checkpoint_write_is_retried() -> void:
	await _start_boot()
	var money := GameState.money
	await _start_dialogue()
	GameState.add_money(500)
	var writes := _writes()
	_fs.fail_writes = true
	_boot.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_now[0] += 1.0
	_boot._process(0.0)
	assert_eq(_writes(), writes, "panne : rien d'écrit")
	_fs.fail_writes = false
	_boot._process(SaveCoordinator.RETRY_DELAY - 1.0)
	assert_eq(_writes(), writes, "pas avant le délai")
	_boot._process(1.0)
	assert_eq(_writes(), writes + 1, "nouvelle tentative")
	assert_eq(int(_saved().get("money", -1)), money, "toujours le point de reprise")
	_boot.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _finish_dialogue()


# --- Départ de la session S2A ------------------------------------------------------------

func test_the_s2_save_start_replaces_the_save() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/s2_save.json", data, items),
		"\n".join(start.get_errors()))
	assert_true(start.autosave, "le départ devient la partie sauvegardée")
