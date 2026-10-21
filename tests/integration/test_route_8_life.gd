extends GutTest
## La vie de la Route 8, de la Route 7 et du souterrain (jalon 20 T17, jalon-20.md §3 T17 ; dossier
## 23 §3.4, §4, §5, §20.1, texte 10) sur les **vraies cartes et leurs PNJ** :
## - la Super Potion visible de la terrasse (PNJ « objet », PRENDRE) : Sac + 1, journal des objets
##   trouvés, drapeau, plus de Poké Ball au rechargement ;
## - l'arrivée par l'est : un pas vers l'ouest sur la 2e colonne lève `route_8_reached` (une fois,
##   dans ce sens seulement) et l'objectif devient « rejoindre Céladopole. » ;
## - les Roucool d'ambiance s'envolent (Route 7 et Route 8) ; l'habitant des deux bâtiments d'entrée
##   du souterrain dit le texte 10 ; le souterrain n'a aucun PNJ ni Dresseur.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_route_8_life_save.json"
const START := "res://tools/debug_start/route_8.json"
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_left", &"move_right"]:
		Input.action_release(action)


func _load_map(id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


# --- Cartes seules --------------------------------------------------------------------------

func test_ambient_roucool_and_the_unmoved_super_potion_on_route_8() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_8.txt"), plan.error)
	var map := _load_map(&"route_8")
	var bird := map.get_npc(&"roucool_1")
	assert_not_null(bird)
	assert_eq(bird.get_cell(), plan.cell_of("roucool_1"))
	assert_eq(bird.get_spec().shy_action, &"fly")
	assert_false(bird.get_spec().is_interactive(), "un Pokémon qui fuit ne se parle pas")
	var ball := map.get_npc(&"route_8_item_1")
	assert_not_null(ball)
	assert_eq(ball.get_cell(), plan.cell_of("route_8_item_1"))
	assert_eq(ball.get_spec().verb, Interaction.Kind.TAKE)
	assert_eq(ball.get_spec().unless_flags, [&"got_route_8_item_1"] as Array[StringName])
	# Les deux sauvages de la grille : Sabelette (Route 8) et Mystherbe (Route 7) n'ont pas encore
	# de planche peinte (série 22 bis) ; seuls les Roucool sont posés.
	assert_null(map.get_npc(&"sabelette_1"))


func test_route_7_has_no_trainer_and_only_the_roucool() -> void:
	var map := _load_map(&"route_7")
	assert_eq(map.get_npcs().size(), 1, "aucun Dresseur (RB)")
	var bird := map.get_npc(&"roucool_1")
	assert_eq(bird.get_spec().shy_action, &"fly")
	assert_eq(bird.get_cell(), Vector2i(12, 7), "prairie du nord")


func test_the_underground_has_no_npc_and_the_entrance_buildings_a_resident() -> void:
	var map := _load_map(&"underground_path_7_8")
	assert_eq(map.get_npcs().size(), 0, "ni PNJ ni Dresseur dans le souterrain (RB)")
	for id: StringName in [&"route_7_underground_gate", &"route_8_underground_gate"]:
		var gate := _load_map(id)
		assert_eq(gate.get_npcs().size(), 1, "%s : un habitant" % id)
		var resident := gate.get_npc(&"resident")
		assert_true(gate.get_grid().is_occupied(resident.get_cell()), "il occupe sa case")
		var dialogues := DialogueLibrary.new()
		assert_true(dialogues.load_dir())
		var dialogue := dialogues.get_dialogue(resident.get_spec().dialogue)
		assert_eq(dialogue.speaker, "Habitant")
		assert_eq(dialogue.variants[0].pages[0].text.replace("\n", " "),
			"Le souterrain passe sous Safrania. Plus court, et plus calme.", "texte 10")


# --- Boot réel ------------------------------------------------------------------------------

func _start(map: StringName, spawn: StringName, facing: Vector2i, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text().replace("\n", " ")))
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _talk() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func test_the_super_potion_is_taken_once_and_stays_gone() -> void:
	await _start(&"route_8", &"from_lavender_c", Vector2i.LEFT)
	var ball_cell := Vector2i(37, 5)
	_boot.get_map().spawn_player_at(_player, ball_cell + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(3)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "face à la Poké Ball")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(&"super_potion")
	await _talk()
	assert_eq(GameState.bag.count_of(&"super_potion"), before + 1, "Super Potion au Sac")
	assert_true(GameState.flags.has_flag(&"got_route_8_item_1"))
	var found := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == "super_potion" and entry["map"] == "route_8":
			found += 1
	assert_eq(found, 1, "journal des objets trouvés")
	assert_null(_boot.get_map().get_npc(&"route_8_item_1"), "la Poké Ball a disparu")
	assert_null(_boot.get_interaction_controller().get_target(), "plus de cible")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"route_8", &"from_lavender_c", Vector2i.LEFT, false)
	assert_true(GameState.flags.has_flag(&"got_route_8_item_1"), "drapeau relu")
	assert_null(_boot.get_map().get_npc(&"route_8_item_1"), "toujours absente après rechargement")
	assert_eq(GameState.bag.count_of(&"super_potion"), before + 1)


func test_the_east_arrival_raises_the_flag_and_changes_the_objective() -> void:
	await _start(&"route_8", &"from_lavender_c", Vector2i.LEFT)
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	assert_false(GameState.flags.has_flag(&"route_8_reached"))
	assert_eq(objectives.current(GameState.flags), "monter dans la Tour Pokémon.",
		"avant la Route 8 : la Tour (J19)")
	# Un pas vers l'ouest depuis le raccord : 2e colonne, drapeau et objectif (texte 56).
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_8_reached"), TIMEOUT)
	Input.action_release(&"move_left")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell().x, 78, "2e colonne")
	assert_eq(objectives.current(GameState.flags), "rejoindre Céladopole.", "texte 56")


func test_walking_east_over_the_second_column_raises_nothing() -> void:
	await _start(&"route_8", &"from_lavender_c", Vector2i.LEFT)
	_boot.get_map().spawn_player_at(_player, Vector2i(77, 11), Vector2i.RIGHT)
	await wait_process_frames(3)
	var target := Vector2i(78, 11)
	Input.action_press(&"move_right")
	# Relâcher pendant le pas : la touche encore enfoncée enchaînerait un pas de trop (le raccord).
	await wait_until(func() -> bool: return _player.get_cell() == target \
		or (_player.is_moving() and _player.get_cell() + Vector2i.RIGHT == target), TIMEOUT)
	Input.action_release(&"move_right")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	await wait_process_frames(10)
	assert_eq(_player.get_cell(), Vector2i(78, 11))
	assert_false(GameState.flags.has_flag(&"route_8_reached"), "pas dans ce sens")
