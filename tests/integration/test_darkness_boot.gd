extends GutTest
## Voile d'obscurité dans le vrai Boot (J17 T9 / T10, repris au T28 quand la carte de QA
## `qa_flash` est retirée) : sur la Cave Taupiqueur rendue obscure en mémoire
## (`tests/helpers/dark_cave.gd`), le voile se pose en entrant depuis la Route 2 est, le trou
## suit le joueur au bord de la carte (caméra bornée) et le voile se retire en ressortant. La
## vraie Cave reste éclairée (`test_cave_library`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const DarkCave := preload("res://tests/helpers/dark_cave.gd")
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")


func after_each() -> void:
	Input.action_release(&"interact")
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	DarkCave.cleanup()


func test_entering_the_dark_cave_lays_the_veil_and_leaving_lifts_it() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_darkness_boot_save.json")
	_boot.caves_path = DarkCave.write_caves()
	_boot.start_map = DarkCave.OUTSIDE
	_boot.start_spawn = &"from_cave_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_true(_boot.get_caves().is_dark(DarkCave.CAVE), "Cave rendue obscure (test)")
	var darkness := _boot.get_darkness()
	assert_false(darkness.is_dark(), "dehors : aucun voile")
	assert_false(darkness.get_veil().visible)
	var player := _boot.get_player()
	assert_true(player.script_step(Vector2i.UP), "pas vers la bouche nord")
	var runner := _boot.get_dialogue_runner()
	await wait_until(func() -> bool: return _boot.get_map().map_id == DarkCave.CAVE \
		and runner.is_running(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, DarkCave.CAVE)
	assert_eq(runner.get_dialogue_id(), FlashDirector.WARN_DIALOGUE, "sans CS05 : avertissement")
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_true(darkness.is_dark(), "grotte obscure : voile posé")
	assert_true(darkness.get_veil().visible)
	assert_false(darkness.is_lit(), "Flash éteinte (partie neuve : pas de CS05)")
	await wait_process_frames(2)
	var body := VeilMath.body_center(player.global_position,
		darkness.get_profile().center_offset)
	assert_eq(darkness.get_veil().get_center(), body, "trou centré sur le joueur")
	# Joueur au bord nord de la carte : la caméra est bornée, le trou ne suit pas l'écran.
	var viewport := get_viewport()
	var view := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	assert_true(darkness.get_veil().get_view_rect().encloses(view), "la vue entière est voilée")
	assert_ne(view.get_center().round(), body.round(), "trou décentré à l'écran (bord)")
	# Sortie par la bouche nord : voile retiré.
	await DarkCave.leave_north(self, _boot, TIMEOUT)
	await wait_until(func() -> bool: return _boot.get_map().map_id == DarkCave.OUTSIDE \
		and _boot.is_stable(), TIMEOUT)
	assert_false(darkness.is_dark())
	assert_false(darkness.get_veil().visible)
	assert_false(darkness.is_processing())


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
