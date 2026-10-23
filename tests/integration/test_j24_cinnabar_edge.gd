extends GutTest
## Bord est de Cramois'Île (jalon 24, défaut D4 de la QA A17) : SURFER depuis la grève saute sur
## la colonne 33, dernière case de la carte, qui porte le passage PUSH vers la Route 20. La mise à
## l'eau enchaîne sur le passage sans demander une poussée de plus, comme les autres bords.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const START := "res://tools/debug_start/j24_cinnabar.json"
const SAVE_PATH := "user://test_j24_cinnabar_edge_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const BEACH := Vector2i(32, 10)

var _boot: Boot
var _fades: Array[float] = []
var _player: Player


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"cinnabar_island"
	_boot.start_spawn = &"from_labo"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_encounter_director().enabled = false


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _surf_from_the_beach(first_ride_seen: bool) -> void:
	if first_ride_seen:
		GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	SceneRouter.get_current_map().spawn_player_at(_player, BEACH, Vector2i.RIGHT)
	await wait_process_frames(2)
	assert_eq(SceneRouter.get_current_map().map_id, &"cinnabar_island")
	assert_eq(_boot.get_mount_director().start_surf(), SurfRules.MountCheck.READY)


func _on_route_20() -> bool:
	return SceneRouter.get_current_map().map_id == &"route_20" and _boot.is_stable()


func test_surf_from_the_east_beach_chains_to_route_20() -> void:
	await _surf_from_the_beach(true)
	await wait_until(_on_route_20, TIMEOUT)
	assert_eq(SceneRouter.get_current_map().map_id, &"route_20", "un seul SURFER suffit")
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "Surf gardé sur la Route 20")


func test_first_ride_text_comes_before_the_crossing() -> void:
	await _surf_from_the_beach(false)
	var runner := _boot.get_dialogue_runner()
	await wait_until(func() -> bool: return runner.is_running(), TIMEOUT)
	await wait_process_frames(10)
	assert_eq(SceneRouter.get_current_map().map_id, &"cinnabar_island",
		"le texte T-3 est lu avant le passage")
	while runner.is_running():
		runner._on_advance_requested()
		await wait_process_frames(2)
	await wait_until(_on_route_20, TIMEOUT)
	assert_eq(SceneRouter.get_current_map().map_id, &"route_20")
