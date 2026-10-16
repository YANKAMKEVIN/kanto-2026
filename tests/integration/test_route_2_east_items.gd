extends GutTest
## Objets du couloir de la Route 2 est (jalon-17.md §2.1, T20 ; dossier 20 §7) : la Pierre Lune
## (12, 26) et le Super Bonbon (3, 33), visibles au sol, ramassés **une seule fois** par les vraies
## entrées (`move_*`, `interact`), avec la vraie scène Boot ; absents après rechargement de la
## carte ; le Super Bonbon est utilisable (`rare_candy`, J14). Départ de débogage
## `route_2_east_south` (derrière l'arbuste, sans passer par la Coupe : `test_j17_bushes`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_2_east_south.json"
const SAVE_PATH := "user://test_route_2_east_items_save.json"
const MAP := &"route_2_east"
const TIMEOUT := 12.0
const WALK_STOP := &"test_walk_stop"
const FADE := 0.05

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = MAP
	_boot.start_spawn = &"debug_south"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, MAP)
	assert_eq(_player.get_cell(), Vector2i(6, 23))


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
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


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


## Prend l'objet devant le joueur (bouton d'interaction) et attend la fin de la scène.
func _take(facing: Vector2i) -> void:
	_player.face(facing)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	await wait_until(func() -> bool:
		return not director.is_running() and not _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await wait_process_frames(3)


func test_the_two_objects_are_taken_once_and_gone_after_a_reload() -> void:
	await _start()
	var moon := _boot.get_map().get_npc(&"route_2_east_item_1")
	var candy := _boot.get_map().get_npc(&"route_2_east_item_2")
	assert_not_null(moon, "Pierre Lune visible")
	assert_not_null(candy, "Super Bonbon visible")
	assert_eq(GameState.bag.count_of(&"moon_stone"), 0)
	assert_eq(GameState.bag.count_of(&"rare_candy"), 0)
	# Pierre Lune : par le chemin vers le sud puis l'est, depuis (11, 26) tourné vers l'est.
	await _walk(Vector2i.DOWN, Vector2i(6, 26))
	await _walk(Vector2i.RIGHT, Vector2i(11, 26))
	await _take(Vector2i.RIGHT)
	assert_eq(GameState.bag.count_of(&"moon_stone"), 1, "Pierre Lune au Sac")
	assert_true(GameState.flags.has_flag(&"got_route_2_east_item_1"))
	assert_null(_boot.get_map().get_npc(&"route_2_east_item_1"), "retirée du sol")
	# Redire « prendre » sur la case vide ne donne rien.
	await _take(Vector2i.RIGHT)
	assert_eq(GameState.bag.count_of(&"moon_stone"), 1, "une seule Pierre Lune")
	# Super Bonbon : retour au chemin, vers le sud puis l'ouest, depuis (4, 33) tourné vers l'ouest.
	await _walk(Vector2i.LEFT, Vector2i(6, 26))
	await _walk(Vector2i.DOWN, Vector2i(6, 33))
	await _walk(Vector2i.LEFT, Vector2i(4, 33))
	await _take(Vector2i.LEFT)
	assert_eq(GameState.bag.count_of(&"rare_candy"), 1, "Super Bonbon au Sac")
	assert_true(GameState.flags.has_flag(&"got_route_2_east_item_2"))
	assert_null(_boot.get_map().get_npc(&"route_2_east_item_2"))
	# Rechargement de la carte avec les drapeaux : les deux objets n'y sont plus.
	var reloaded := (load(MapCatalog.scene_path(MAP)) as PackedScene).instantiate() as GameMap
	add_child_autofree(reloaded)
	reloaded.refresh_npcs(GameState.flags)
	assert_null(reloaded.get_npc(&"route_2_east_item_1"), "absente après rechargement")
	assert_null(reloaded.get_npc(&"route_2_east_item_2"), "absent après rechargement")
	assert_push_error_count(0)


func test_the_objects_are_the_expected_items_and_flags() -> void:
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var expected := {&"route_2_east_item_1": [&"moon_stone", &"got_route_2_east_item_1"],
		&"route_2_east_item_2": [&"rare_candy", &"got_route_2_east_item_2"]}
	for id: StringName in expected:
		var scene := cutscenes.get_cutscene(id)
		assert_not_null(scene, String(id))
		if scene == null:
			continue
		var steps: Array = scene.variants[0].steps
		assert_eq(scene.variants[0].unless_flags, [expected[id][1]] as Array[StringName])
		assert_eq(steps.size(), 3, "retirer, donner, poser le drapeau")
		assert_eq(steps[1].item_id, expected[id][0])
		assert_eq(steps[1].count, 1)
		assert_true(steps[1].found, "objet trouvé dans le monde (bandeau)")
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	assert_true(items.has_item(&"moon_stone"))
	assert_true(items.has_item(&"rare_candy"))
