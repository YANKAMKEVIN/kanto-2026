extends GutTest
## Îles Écume dans la vraie partie (jalon 24, T15 ; points ouverts de la passe systèmes 2,
## `systemes-2.md` §7) : la vraie scène Boot sur le B2F, courant 1 actif. Le joueur saute dans le
## trou 1 du B2F : il atterrit au B3F dans l'eau, **en Surf forcé**, sur le courant, qui l'emporte
## jusqu'au passage W1 → B4F, mer est, toujours en Surf.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_j24_seafoam_flow_save.json"
const FADE := 0.05
const FRAME := 1.0 / 60.0
const TIMEOUT := 20.0
const HOLE := Vector2i(19, 6)

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
	_boot.start_map = &"seafoam_b2f"
	_boot.start_spawn = &"arrivee_p6"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_player = _boot.get_player()


func after_each() -> void:
	Input.action_release(&"move_up")
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _started() -> bool:
	return _player.is_moving() or SceneRouter.is_transitioning()


func _on_map(map_id: StringName) -> bool:
	return SceneRouter.get_current_map().map_id == map_id and _boot.is_stable()


func test_falling_into_b2f_hole_lands_surfing_on_current_1_and_rides_to_b4f() -> void:
	SceneRouter.get_current_map().spawn_player_at(_player, HOLE + Vector2i.DOWN, Vector2i.UP)
	Input.action_press(&"move_up")
	await wait_until(_started, TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(_on_map.bind(&"seafoam_b4f"), TIMEOUT)
	assert_eq(SceneRouter.get_current_map().map_id, &"seafoam_b4f", "emporté au B4F")
	assert_eq(_player.get_cell(), Vector2i(20, 16), "arrivée W1, mer est")
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "toujours en Surf")


func test_with_both_b2f_holes_plugged_the_b3f_pool_is_calm() -> void:
	GameState.flags.set_flag(&"seafoam_b2f_hole_1_filled")
	GameState.flags.set_flag(&"seafoam_b2f_hole_2_filled")
	SceneRouter.change_map(&"seafoam_b3f", &"arrivee_p8", Vector2i.DOWN)
	await wait_until(_on_map.bind(&"seafoam_b3f"), TIMEOUT)
	var grid := SceneRouter.get_current_map().get_grid()
	assert_eq(grid.get_current(Vector2i(15, 8)), Vector2i.ZERO, "eau calme")
	assert_true(grid.is_occupied(Vector2i(18, 6)), "rocher tombé dans le chenal")
