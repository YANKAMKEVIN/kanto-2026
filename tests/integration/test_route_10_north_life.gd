extends GutTest
## La vie de la Route 10 nord et du Centre de la Route 10 (jalon 18 T18, jalon-18.md §4.1, §4.13 ;
## dossier 21 §4.1, §12) avec la vraie scène Boot et une sauvegarde en mémoire :
## - panneau de la grotte lu de face ; randonneur devant la grotte (T-7) ;
## - premier pas sur la colonne 1 → `route_10_reached` (silencieux) → objectif « traverser la
##   Grotte Sombre. » ;
## - rencontres : table de `data/encounters/route_10.json` (Voltorbe), hautes herbes de la scène ;
## - Hector et Paul (secteur sud, T24) posés avec leur vue de la grille ;
## - Centre : infirmière, Stockage, soin → toast « Point de repos enregistré — Route 10 »,
##   point de repos enregistré, défaite → réveil au Centre (`DefeatRecovery`), sortie sur la
##   Route 10 devant la porte ; départ de débogage `route_10_center`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START_ROUTE_9 := "res://tools/debug_start/route_9.json"
const START_CENTER := "res://tools/debug_start/route_10_center.json"
const PLAN_PATH := "res://tools/plans/route_10.txt"
const SAVE_PATH := "user://test_route_10_north_life_save.json"
const FADE := 0.05
const TIMEOUT := 12.0

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T15:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
	_pages.clear()
	_speakers.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map] / [param spawn] avec le départ de débogage [param start_path] ; le joueur
## est ensuite posé sur [param cell] s'il est donné.
func _start(cell: Variant, facing: Vector2i, map: StringName, spawn: StringName,
		start_path: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_runner.choice_requested.connect(_on_choice_requested)
	await wait_process_frames(3)
	if cell is Vector2i:
		_boot.get_map().spawn_player_at(_player, cell, facing)
		await wait_process_frames(3)


## Le soin du Centre : SOIGNER.
func _on_choice_requested(_view: ChoiceView) -> void:
	await wait_process_frames(3)
	_boot.get_dialogue_box().get_choice_cards().get_confirm_button().pressed.emit()


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
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_right"
	match direction:
		Vector2i.UP:
			action = &"move_up"
		Vector2i.DOWN:
			action = &"move_down"
		Vector2i.LEFT:
			action = &"move_left"
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)

# --- Panneau et randonneur --------------------------------------------------------------------

func _read(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


func test_cave_sign_is_read_from_the_front() -> void:
	var sign_cell := _plan.cell_of("panneau_grotte")
	await _start(null, Vector2i.UP, &"route_10", &"from_center", START_CENTER)
	await _read(sign_cell + Vector2i.DOWN, Vector2i.UP)
	assert_eq(_pages, ["GROTTE SOMBRE\nRoute 10 — Lavanville"] as Array[String], "T-5")
	_boot.get_map().spawn_player_at(_player, sign_cell + Vector2i.RIGHT, Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(), "de côté : rien")


func test_hiker_stands_in_front_of_the_cave() -> void:
	var cell := _plan.cell_of("randonneur")
	await _start(null, Vector2i.UP, &"route_10", &"from_center", START_CENTER)
	var hiker := _boot.get_map().get_npc(&"randonneur")
	assert_not_null(hiker, "randonneur posé")
	if hiker != null:
		assert_eq(hiker.get_cell(), cell)
		assert_eq(hiker.get_spec().facing, Vector2i.LEFT, "regarde l'entrée")
	await _read(cell + Vector2i.LEFT, Vector2i.RIGHT)
	assert_eq(_pages, ["Là-dedans, on n'y voit pas à trois pas.",
		"Moi, je garde la paroi à main droite…\nou à main gauche, je ne sais plus."]
		as Array[String], "T-7")
	assert_eq(_speakers, ["Randonneur", "Randonneur"] as Array[String])


func test_the_two_south_trainers_are_placed_with_their_sight() -> void:
	await _start(null, Vector2i.UP, &"route_10", &"from_center", START_CENTER)
	var map := _boot.get_map()
	for id: String in ["hector", "paul"]:
		var npc := map.get_npc(StringName(id))
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_true(spec.is_trainer())
		assert_eq(spec.cell, _plan.cell_of(id))
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(id, "facing")))
		assert_eq(spec.sight, int(_plan.attr(id, "sight")))
		assert_eq(String(spec.trainer_id), String(_plan.attr(id, "trainer")))


# --- Déclencheur et objectif ----------------------------------------------------------------

func test_first_step_on_route_10_sets_the_objective_silently() -> void:
	await _start(null, Vector2i.RIGHT, &"route_10", &"from_route_9", START_ROUTE_9)
	assert_eq(_player.get_cell(), Vector2i(0, 13), "arrivée de la Route 9")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	GameState.flags.set_flag(&"route_9_entered")
	await _walk(Vector2i.RIGHT, Vector2i(1, 13))
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_10_reached"),
		TIMEOUT)
	assert_true(GameState.flags.has_flag(&"route_10_reached"))
	assert_eq(objectives.current(GameState.flags), "traverser la Grotte Sombre.",
		"dossier 21 §12")
	await wait_process_frames(5)
	assert_eq(_events, [] as Array[String], "en silence")
	assert_true(_player.is_input_enabled(), "le joueur garde la main")
	assert_push_error_count(0)


func test_reached_trigger_covers_the_three_west_rows() -> void:
	var map := (load("res://game/world/maps/route_10.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var points := map.get_node(^"Triggers").get_children()
	assert_eq(points.size(), 1, "T24 ajoutera dark_cave_crossed")
	var trigger := points[0] as EventTriggerPoint
	assert_eq(trigger.cutscene_id, &"route_10_reached")
	var cells := trigger.get_cells()
	cells.sort()
	assert_eq(cells, [Vector2i(1, 12), Vector2i(1, 13), Vector2i(1, 14)] as Array[Vector2i])
	assert_eq(trigger.direction, Vector2i.ZERO, "toute direction")


# --- Rencontres -------------------------------------------------------------------------------

func test_encounter_table_matches_dossier_21() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(&"route_10"))
	var table := library.get_table(&"route_10")
	assert_eq(table.rate, 25)
	assert_eq(table.total_weight(), 100)
	assert_almost_eq(table.chance_of(&"voltorb"), 0.30, 0.0001)
	assert_almost_eq(table.chance_of(&"spearow"), 0.35, 0.0001)
	assert_almost_eq(table.chance_of(&"ekans"), 0.18, 0.0001)
	assert_almost_eq(table.chance_of(&"sandshrew"), 0.17, 0.0001)


func test_north_pocket_h1_is_tall_grass_and_starts_a_battle() -> void:
	await _start(null, Vector2i.RIGHT, &"route_10", &"from_route_9", START_ROUTE_9)
	var grass := _plan.cell_of("herbes_h1")
	var map := _boot.get_map()
	assert_true(map.get_grid().is_tall_grass(grass), "H1 de la grille")
	assert_true(_boot.get_encounter_library().override_table(&"route_10", &"grass",
		{"rate": 255, "slots": [{"species": "voltorb", "levels": [14, 14], "weight": 1}]},
		"test"))
	var started: Array[StringName] = []
	_boot.get_encounter_director().encounter_started.connect(
		func(species: StringName, _level: int) -> void: started.append(species))
	map.spawn_player_at(_player, grass + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return not started.is_empty(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(started, [&"voltorb"] as Array[StringName], "rencontre de Voltorbe")


# --- Centre de la Route 10 --------------------------------------------------------------------

func test_debug_start_is_in_the_center_with_a_hurt_team() -> void:
	await _start(null, Vector2i.UP, &"route_10_center", &"entrance", START_CENTER)
	assert_eq(_boot.get_map().map_id, &"route_10_center")
	assert_eq(_player.get_cell(), Vector2i(7, 8))
	assert_eq(GameState.party.get_at(1).hp, 0, "un K.O. avant le soin")
	assert_true(GameState.flags.has_flag(&"route_10_reached"))
	assert_push_error_count(0)


func test_center_nurse_heals_and_registers_route_10() -> void:
	await _start(null, Vector2i.UP, &"route_10_center", &"heal", START_CENTER)
	var map := _boot.get_map()
	var nurse := map.get_npc(&"nurse")
	assert_not_null(nurse, "infirmière")
	if nurse != null:
		assert_eq(nurse.get_cell(), Vector2i(7, 3))
	var terminal := map.get_node_or_null(^"Interactables/StorageTerminalScreen") as InteractPoint
	assert_not_null(terminal, "terminal de Stockage")
	if terminal != null:
		assert_eq(terminal.dialogue_id, &"storage_terminal")
	assert_eq(GameState.party.get_at(1).hp, 0, "un K.O. avant le soin")
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "%s soigné" % pokemon.species_id)
	assert_eq(GameState.heal_map, &"route_10_center", "point de repos")
	assert_eq(_toasts, [PackedStringArray(["Point de repos enregistré", "Route 10"])]
		as Array[PackedStringArray])
	assert_push_error_count(0)


## Une défaite après ce soin : réveil devant le comptoir du Centre de la Route 10, tourné vers
## l'infirmière, et non plus chez Maman ni au Centre d'Azuria.
func test_a_defeat_wakes_at_this_center() -> void:
	await _start(null, Vector2i.RIGHT, &"route_10", &"from_route_9", START_ROUTE_9)
	RestPointLibrary.register(GameState, _boot.get_rest_points().get_point(&"route_10_center"))
	GameState.party.get_lead().hp = 0
	_boot.get_defeat_recovery().recover()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_10_center", TIMEOUT)
	var map := _boot.get_map()
	await wait_process_frames(5)
	assert_eq(_player.get_cell(), map.get_spawn_cell(&"heal"), "devant le comptoir")
	assert_eq(_player.get_facing(), Vector2i.UP, "face à l'infirmière")
	assert_eq(GameState.party.get_lead().hp, GameState.party.get_lead().max_hp(), "soigné")
	await _finish_scene()
	assert_push_error_count(0)


func test_leaving_the_center_arrives_in_front_of_the_door() -> void:
	await _start(null, Vector2i.UP, &"route_10_center", &"entrance", START_CENTER)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_10", TIMEOUT)
	Input.action_release(&"move_down")
	await wait_process_frames(5)
	assert_eq(_player.get_cell(), Vector2i(7, 12), "devant la porte")
