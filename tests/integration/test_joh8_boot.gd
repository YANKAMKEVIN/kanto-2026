extends GutTest
## Chapitre Johto, JOH8 (`jalon-joh8.md` §4, dossier joh-09 §12 et §13) : le **vrai Boot** sur
## les départs de débogage du sommet, combats remplacés par un faux directeur (issue imposée) :
## - `johto_bell_tower_roof` : aube forcée à midi réel ; deux pas vers le sud jouent la scène du
##   palier jusqu'au bout (Dante battu, cloche, refus, fuite, Entei capturé, Ho-Oh K.O., plume) ;
##   drapeaux du §11, Dante et Entei partis, cage brûlée ; redescendre au 2F rend l'heure réelle ;
## - défaite contre Dante : réveil au Centre de Rosalia, `johto_dante_lost_1`, Dante reste ; au
##   retour, H-17 (« Tu reviens déjà ? ») au lieu de H-14 à H-16 ;
## - `johto_bell_tower_entei` (application coupée après la fuite de Dante) : Entei libre devant le
##   joueur, lui parler lance son combat puis Ho-Oh.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_joh8_boot_save.json"
const SETTINGS_PATH := "user://test_joh8_boot_settings.json"
const ABSENT := "user://test_joh8_boot_absent.json"
const FADE := 0.05
const TIMEOUT := 60.0


## Faux combats : issue imposée par Dresseur ou par espèce, ordre noté.
class StubBattles extends BattleDirector:
	var trainer_outcome: int = Battle.Outcome.WIN
	var wild_outcomes: Dictionary = {}
	var log: Array[String] = []

	func run(trainer_id: StringName, _map: GameMap,
			_actors: Dictionary[StringName, StringName]) -> int:
		log.append("trainer:" + String(trainer_id))
		await get_tree().process_frame
		return trainer_outcome

	func run_wild(encounter: WildEncounter, _map: GameMap, _origin: Vector2i) -> int:
		log.append("wild:" + String(encounter.species))
		await get_tree().process_frame
		return wild_outcomes.get(encounter.species, Battle.Outcome.WIN)


var _boot: Boot
var _stub: StubBattles
var _saved_router: Array = []
var _previous_scene: Node


func before_all() -> void:
	if not ResourceLoader.exists("res://game/world/maps/ecruteak_city.tscn"):
		gut.p("Rosalia (JOH2) absente : tests en attente de la fusion.")


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-04T12:00:00") # le jour


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	if is_instance_valid(_stub):
		_stub.free()
	_stub = null
	GameState.clock = DeviceClock.new()


func _ready_to_run() -> bool:
	if ResourceLoader.exists("res://game/world/maps/ecruteak_city.tscn"):
		return true
	pending("Rosalia (JOH2) pas encore fusionnée : point de repos et départs indisponibles")
	return false


func _launch(start: String) -> void:
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
	_stub = StubBattles.new()
	get_tree().root.add_child(_stub)
	_boot.get_cutscene_director().set_battle_runner(_stub)


func _play_scene_to_the_end() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_running() and box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "la scène s'est terminée")


func _walk_to_the_landing_exit() -> void:
	var director := _boot.get_cutscene_director()
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	Input.action_release(&"move_down")


func test_summit_scene_from_dawn_to_the_rainbow_wing() -> void:
	if not _ready_to_run():
		return
	await _launch("johto_bell_tower_roof")
	assert_eq(_boot.get_map().map_id, &"bell_tower_roof")
	assert_eq(_boot.get_world_clock().period_name(), &"morning", "aube forcée (JH-55) à midi réel")
	assert_eq(_boot.get_world_lighting().get_profile().id, &"johto_morning")
	_stub.wild_outcomes = {&"entei": Battle.Outcome.CAUGHT, &"ho_oh": Battle.Outcome.WIN}
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	await _walk_to_the_landing_exit()
	await _play_scene_to_the_end()
	assert_eq(_stub.log, ["trainer:bell_tower_dante_1", "wild:entei", "wild:ho_oh"]
		as Array[String])
	for flag: StringName in [&"johto_dante_met", &"johto_dante_defeated_1", &"johto_ho_oh_seen",
			&"johto_dante_fled_1", &"johto_entei_done", &"johto_entei_caught",
			&"johto_ho_oh_done", &"got_rainbow_wing"]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_false(GameState.flags.has_flag(&"johto_ho_oh_caught"))
	assert_true(said.has(&"bell_tower_dante_welcome"), "H-14")
	assert_false(said.has(&"bell_tower_dante_resume"), "pas de H-17 la première fois")
	assert_true(said.has(&"bell_tower_entei_calm"), "H-28 : Entei capturé")
	assert_true(said.has(&"bell_tower_ho_oh_gone"), "H-31 : Ho-Oh K.O.")
	assert_true(said.find(&"bell_tower_dante_promise") < said.find(&"bell_tower_entei_turns"))
	assert_eq(GameState.bag.count_of(&"rainbow_wing"), 1, "Plume Arc-en-ciel (H-33)")
	var map := _boot.get_map()
	assert_null(map.get_npc(&"dante"), "Dante est parti sur son Arcanin")
	assert_null(map.get_npc(&"entei"))
	var cage := map.find_child("CageDeFeu", true, false) as CanvasItem
	assert_false(cage.visible, "la cage a volé en éclats")
	assert_true(_boot.get_player().is_input_enabled())
	# Toujours l'aube sur le toit ; la trappe du 2F rend l'heure réelle.
	assert_eq(_boot.get_world_clock().period_name(), &"morning")
	SceneRouter.change_map(&"bell_tower_2f", &"from_sommet", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"bell_tower_2f", TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_boot.get_world_clock().period_name(), &"day", "heure réelle hors du sommet")
	assert_false(_boot.get_world_clock().is_period_forced())


func test_defeat_against_dante_wakes_up_in_rosalia_and_resumes_with_h17() -> void:
	if not _ready_to_run():
		return
	await _launch("johto_bell_tower_roof")
	_stub.trainer_outcome = Battle.Outcome.LOSS
	await _walk_to_the_landing_exit()
	await _play_scene_to_the_end()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"ecruteak_center", TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"ecruteak_center", "réveil au Centre de Rosalia")
	assert_true(GameState.flags.has_flag(&"johto_dante_lost_1"))
	assert_true(GameState.flags.has_flag(&"johto_dante_met"))
	assert_false(GameState.flags.has_flag(&"johto_dante_defeated_1"))
	assert_false(_boot.get_world_clock().is_period_forced(), "heure réelle à Rosalia")
	# Retour au sommet : la scène reprend avec H-17.
	SceneRouter.change_map(&"bell_tower_roof", &"from_2f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"bell_tower_roof", TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_boot.get_world_clock().period_name(), &"morning")
	assert_not_null(_boot.get_map().get_npc(&"dante"), "Dante attend toujours")
	_stub.trainer_outcome = Battle.Outcome.WIN
	_stub.wild_outcomes = {&"entei": Battle.Outcome.WIN, &"ho_oh": Battle.Outcome.CAUGHT}
	var said: Array[StringName] = []
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		said.append(id))
	await _walk_to_the_landing_exit()
	await _play_scene_to_the_end()
	assert_true(said.has(&"bell_tower_dante_resume"), "H-17")
	assert_false(said.has(&"bell_tower_dante_before"))
	assert_false(said.has(&"bell_tower_arrival"), "H-13 une seule fois")
	assert_true(GameState.flags.has_flag(&"johto_ho_oh_caught"))
	assert_true(said.has(&"bell_tower_entei_gone"), "H-27 : Entei K.O.")


func test_entei_waits_free_after_an_interruption() -> void:
	if not _ready_to_run():
		return
	await _launch("johto_bell_tower_entei")
	var map := _boot.get_map()
	assert_null(map.get_npc(&"dante"))
	assert_not_null(map.get_npc(&"entei"), "Entei libre devant le joueur")
	assert_null(map.get_npc(&"ho_oh"))
	_stub.wild_outcomes = {&"entei": Battle.Outcome.FLED, &"ho_oh": Battle.Outcome.FLED}
	_boot.get_cutscene_director().play(&"bell_tower_entei")
	await _play_scene_to_the_end()
	assert_eq(_stub.log, ["wild:entei", "wild:ho_oh"] as Array[String])
	assert_true(GameState.flags.has_flag(&"johto_entei_done"), "fuite : Entei disparaît (§6)")
	assert_true(GameState.flags.has_flag(&"johto_ho_oh_done"))
	assert_true(GameState.flags.has_flag(&"got_rainbow_wing"), "la plume tombe aussi")
	assert_null(map.get_npc(&"entei"))
