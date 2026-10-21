extends GutTest
## Surf de bout en bout sur la carte de QA `qa_sea` (passe systèmes 2, §2.5, §2.6, T14, T15) :
## départ `s2_surf`, montée depuis la plage, nage, courant joué jusqu'au passage (→ `qa_sea_2`,
## toujours en Surf), bord de carte en mer (monture transmise), descente sur la rive, sauvegarde
## en mer puis reprise.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/s2_surf.json"
const SAVE_PATH := "user://test_qa_sea_flow_save.json"
const TIMEOUT := 15.0

var _fs := MemoryFs.new()
var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fs = MemoryFs.new()
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.02
	SceneRouter.fade_in_duration = 0.02
	await _start()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


func _start(saved: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	if not saved:
		_boot.start_map = &"qa_sea"
		_boot.start_spawn = &"depart"
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if not saved:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_encounter_director().enabled = false


func _walk(direction: Vector2i, count: int) -> void:
	for i: int in count:
		await wait_until(func() -> bool: return not _player.is_moving() \
			and _player.is_input_enabled(), TIMEOUT)
		assert_true(_player.script_step(direction), "pas %s depuis %s" % [direction,
			_player.get_cell()])
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func _surf_east_from_the_beach() -> void:
	await _walk(Vector2i.UP, 12)
	await _walk(Vector2i.RIGHT, 4)
	assert_eq(_player.get_cell(), Vector2i(6, 4))
	assert_eq(_boot.get_interaction_controller().get_target().kind, Interaction.Kind.SURF,
		"SURFER face à l'eau, conditions réunies")
	assert_eq(_boot.get_mount_director().start_surf(), SurfRules.MountCheck.READY)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_mount(), Mount.Kind.SURF)


func test_the_current_carries_the_player_to_qa_sea_2_still_surfing() -> void:
	await _surf_east_from_the_beach()
	# Le cinquième pas pose le joueur sur le premier courant (12, 4) : la glissade part.
	await _walk(Vector2i.RIGHT, 5)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_sea_2" \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(5, 3), "arrivée en Surf forcé")
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
	assert_true(_player.is_input_enabled())


func test_the_sea_edge_keeps_the_mount_and_the_shore_dismounts() -> void:
	await _surf_east_from_the_beach()
	await _walk(Vector2i.DOWN, 8)
	await _walk(Vector2i.RIGHT, 18)
	assert_eq(_player.get_cell(), Vector2i(25, 12))
	_player.face(Vector2i.RIGHT)
	_player.bumped.emit(Vector2i.RIGHT)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_sea_2" \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(0, 12))
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "bord de carte : Surf gardé")
	await _walk(Vector2i.RIGHT, 9)
	assert_eq(_player.get_cell(), Vector2i(9, 12))
	assert_eq(_player.get_mount(), Mount.Kind.NONE, "rive : à pied")


func test_a_save_at_sea_resumes_surfing() -> void:
	await _surf_east_from_the_beach()
	await _walk(Vector2i.DOWN, 6)
	assert_eq(_player.get_cell(), Vector2i(7, 10))
	GameState.set_player_location(&"qa_sea", _player.get_cell(), Vector2i.DOWN)
	assert_eq(GameState.player_mount, Mount.Kind.SURF)
	assert_eq(SaveSystem.new(_fs, SAVE_PATH).write(GameState.to_dict()), OK)
	remove_child(_boot)
	_boot.free()
	await _start(true)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, &"qa_sea")
	assert_eq(_player.get_cell(), Vector2i(7, 10), "reprise sur l'eau")
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
