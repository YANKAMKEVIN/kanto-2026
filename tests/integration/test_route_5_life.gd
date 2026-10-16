extends GutTest
## La Route 5 jouée (jalon 15 T13, T21 ; docs/tech/jalon-15.md §2.1, §2.4, §5) sur la vraie scène
## Boot, l'autoload SceneRouter (fondus raccourcis) et une sauvegarde en mémoire :
## - raccord réel Azuria ↔ Route 5 sur les trois colonnes (w, c, e), **sans puis avec** la Passe
##   Bateau (rien ne suppose `got_ss_ticket`, §1.2) ;
## - partie sauvegardée sur la case du raccord « ROUTE 5 — À venir » du J14 : la reprise retombe
##   sur la case d'Azuria, et le bord mène désormais à la Route 5 (cas limite §5) ;
## - poste nord : le pas vers le nord sur la rangée 3 → T-15 (première fois) puis T-16, et le
##   joueur recule d'une case ; `route_5_gate_warned` ;
## - entrée sur la Route 5 : `route_5_entered` posé en silence (objectif « rejoindre Carmin »).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_route_5_life_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const SUFFIXES: Array[String] = ["w", "c", "e"]
const T15: Array[String] = ["Halte ! La route de Safrania est fermée.",
	"Ordre de la ville. Je n'en sais pas plus, désolé."]
const T16 := "Toujours fermé. Si tu vas vers Carmin-sur-Mer, prends le passage souterrain."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


## Boot sur [param map] / [param spawn] ; [param fresh] : départ de débogage `route_5` (équipe,
## drapeaux du barrage levé) ; sinon la partie relue de la sauvegarde.
func _start(map: StringName, spawn: StringName, facing: Vector2i, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/route_5.json",
			_boot.get_pokemon_data(), _boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Pousse vers [param direction] jusqu'au changement de carte vers [param target], puis attend
## la fin de la transition.
func _push_until(direction: StringName, target: StringName) -> void:
	Input.action_press(direction)
	await wait_until(func() -> bool: return _boot.get_map().map_id == target, TIMEOUT)
	Input.action_release(direction)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning() \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


## Fait défiler les dialogues et les scènes en cours jusqu'à leur fin.
func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _round_trip(suffix: String) -> void:
	await _start(&"cerulean_city", StringName("from_route_5_" + suffix), Vector2i.DOWN)
	var gate := _player.get_cell()
	await _push_until(&"move_down", &"route_5")
	var arrival := _boot.get_map().get_spawn_cell(StringName("from_cerulean_" + suffix))
	assert_eq(_player.get_cell(), arrival, "%s : arrivée sur la Route 5" % suffix)
	assert_eq(_player.get_facing(), Vector2i.DOWN, "tourné vers le sud")
	_player.face(Vector2i.UP)
	await _push_until(&"move_up", &"cerulean_city")
	assert_eq(_player.get_cell(), gate, "%s : retour sur la même case d'Azuria" % suffix)
	assert_eq(_player.get_facing(), Vector2i.UP, "tourné vers le nord")
	assert_push_error_count(0)


func test_cerulean_route_5_round_trip_west() -> void:
	await _round_trip("w")


func test_cerulean_route_5_round_trip_centre() -> void:
	await _round_trip("c")


func test_cerulean_route_5_round_trip_east_with_the_ss_ticket() -> void:
	await _start(&"cerulean_city", &"from_route_5_e", Vector2i.DOWN)
	GameState.flags.set_flag(&"got_ss_ticket")
	GameState.bag.add(&"ss_ticket", 1)
	await _push_until(&"move_down", &"route_5")
	assert_eq(_player.get_cell(), Vector2i(21, 0), "même raccord avec la Passe Bateau")
	_player.face(Vector2i.UP)
	await _push_until(&"move_up", &"cerulean_city")
	assert_eq(_player.get_cell(), Vector2i(33, 40))


func test_walking_in_sets_route_5_entered_silently() -> void:
	await _start(&"route_5", &"from_cerulean_c", Vector2i.DOWN)
	assert_false(GameState.flags.has_flag(&"route_5_entered"))
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_5_entered"),
		TIMEOUT)
	Input.action_release(&"move_down")
	assert_true(GameState.flags.has_flag(&"route_5_entered"), "drapeau de l'objectif")
	assert_true(_pages.is_empty(), "aucune bulle")


## Cas limite §5 : une partie du J14 sauvegardée sur la case du raccord « ROUTE 5 — À venir »
## (cellule (32, 40) d'Azuria) reprend sur cette case ; pousser vers le sud mène à la Route 5.
func test_a_save_on_the_old_coming_soon_gate_resumes_and_leads_to_route_5() -> void:
	await _start(&"cerulean_city", &"from_route_5_c", Vector2i.UP)
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _fs.files.has(SAVE_PATH), TIMEOUT)
	await wait_process_frames(3)
	var saved: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	assert_eq(saved.get("map"), "cerulean_city")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), Vector2i(32, 40))
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"route_5", &"from_cerulean_c", Vector2i.DOWN, false)
	assert_eq(_boot.get_map().map_id, &"cerulean_city", "la sauvegarde l'emporte")
	assert_eq(_player.get_cell(), Vector2i(32, 40), "reprise sur la case du raccord")
	_player.face(Vector2i.DOWN)
	await _push_until(&"move_down", &"route_5")
	assert_eq(_player.get_cell(), Vector2i(20, 0))


func test_saffron_gate_guard_warns_then_points_to_the_underground() -> void:
	await _start(&"route_5_gate", &"from_route_5", Vector2i.UP)
	assert_eq(_player.get_cell(), Vector2i(4, 6))
	for visit: int in 2:
		_pages.clear()
		Input.action_press(&"move_up")
		await wait_until(func() -> bool: return _boot.get_cutscene_director().is_running(),
			TIMEOUT)
		Input.action_release(&"move_up")
		await _finish_scene()
		if visit == 0:
			assert_eq(_pages, T15, "T-15 la première fois")
			assert_true(GameState.flags.has_flag(&"route_5_gate_warned"))
		else:
			assert_eq(_pages, [T16] as Array[String], "T-16 ensuite")
		assert_eq(_player.get_cell(), Vector2i(4, 4), "recul d'une case")
		assert_eq(_player.get_facing(), Vector2i.UP, "toujours tourné vers le garde")
		assert_eq(_boot.get_map().map_id, &"route_5_gate", "Safrania reste fermée")
	assert_push_error_count(0)


# --- T15 / T16 : objectif, objet visible, Miaouss vu (jalon-15.md §2.7.9, §2.8, §3 T16) ---------

func _objective() -> String:
	return _boot.get_menu_director().build_dashboard().objective_text


## T-42 : l'entrée sur la Route 5 affiche « rejoindre Carmin-sur-Mer, au sud. » au tableau de bord.
func test_entering_shows_the_go_vermilion_objective() -> void:
	await _start(&"route_5", &"from_cerulean_c", Vector2i.DOWN)
	assert_ne(_objective(), "Objectif : rejoindre Carmin-sur-Mer, au sud.", "pas encore")
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_5_entered"),
		TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_objective(), "Objectif : rejoindre Carmin-sur-Mer, au sud.")


## Super Potion visible (11, 15) : PRENDRE depuis la case voisine, Sac + 1, absente ensuite.
func test_visible_super_potion_is_taken_once() -> void:
	await _start(&"route_5", &"from_cerulean_c", Vector2i.DOWN)
	var map := _boot.get_map()
	var ball := map.get_npc(&"route_5_item_1")
	assert_not_null(ball, "Super Potion posée")
	if ball == null:
		return
	var cell := ball.get_cell()
	assert_eq(cell, Vector2i(11, 15))
	var from := Vector2i(-1, -1)
	for side: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]:
		if from.x < 0 and map.get_grid().is_free(cell + side):
			from = cell + side
	assert_gt(from.x, -1, "une case voisine libre")
	map.spawn_player_at(_player, from, cell - from)
	await wait_process_frames(3)
	var before := GameState.bag.count_of(&"super_potion")
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"got_route_5_item_1"),
		TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"super_potion"), before + 1, "Sac + 1")
	assert_null(_boot.get_map().get_npc(&"route_5_item_1"), "plus d'objet au sol")
	assert_push_error_count(0)


## Miaouss vu sur la vraie Route 5 (T16) : table des herbes réduite à Miaouss (taux maximal),
## un pas dans H1 → combat sauvage contre Miaouss, marqué « vu » au Pokédex.
func test_meowth_is_seen_in_the_real_tall_grass() -> void:
	await _start(&"route_5", &"from_cerulean_c", Vector2i.DOWN)
	var grass := Vector2i(24, 9)
	var map := _boot.get_map()
	assert_true(map.get_grid().is_tall_grass(grass), "H1 de la grille")
	assert_true(_boot.get_encounter_library().override_table(&"route_5", &"grass",
		{"rate": 255, "slots": [{"species": "meowth", "levels": [12, 12], "weight": 1}]},
		"test"))
	assert_false(GameState.pokedex.is_seen(&"meowth"), "pas encore vu")
	var started: Array[StringName] = []
	_boot.get_encounter_director().encounter_started.connect(
		func(species: StringName, _level: int) -> void: started.append(species))
	map.spawn_player_at(_player, grass + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return not started.is_empty(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(started, [&"meowth"] as Array[StringName], "rencontre de Miaouss")
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	assert_true(GameState.pokedex.is_seen(&"meowth"), "Miaouss vu")
