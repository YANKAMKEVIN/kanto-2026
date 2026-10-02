extends GutTest
## Entrée provisoire vers Jadielle (jalon 5, dossier-07 §12) avec la vraie scène Boot, l'autoload
## SceneRouter (fondus raccourcis) et un [SaveSystem] en mémoire : le bord nord de la Route 1
## mène à « JADIELLE — À venir » (build de développement), puis ramène le joueur une case en
## retrait du bord, tourné vers le sud. Rien n'est sauvegardé pendant l'écran, aucun titre de
## zone « Jadielle », aucune carte « jadielle » découverte ; en release, le bord reste bloqué.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_coming_soon_save.json"
const FADE := 0.05
const HOLD := 0.3
const TIMEOUT := 12.0

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _player: Player
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration,
		SceneRouter.coming_soon_enabled]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-02T14:03:05")
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	SceneRouter.coming_soon_enabled = _saved_router[2]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


## Boot sur la Route 1, une case sous le haut du chemin, tourné vers le nord.
func _start_on_route_1(spawn: StringName = &"jadielle_soon_w") -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = &"route_1"
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_coming_soon_screen().hold_duration = HOLD
	_boot.get_coming_soon_screen().fade_duration = 0.05
	await wait_process_frames(3)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


## Pousse vers le haut jusqu'à ce que l'écran « à venir » soit montré.
func _walk_into_the_north_edge() -> void:
	var screen := _boot.get_coming_soon_screen()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return screen.is_showing(), TIMEOUT)
	Input.action_release(&"move_up")


func test_the_north_edge_shows_the_coming_soon_screen_then_returns_facing_south() -> void:
	await _start_on_route_1()
	var screen := _boot.get_coming_soon_screen()
	assert_eq(_player.get_cell(), Vector2i(23, 2))
	var zones: Array[String] = []
	_boot.zone_announced.connect(func(zone: String, _region: String) -> void:
		zones.append(zone))
	await _walk_into_the_north_edge()
	assert_eq(screen.get_label().text, "JADIELLE — À venir")
	assert_true(_boot.get_fade().is_opaque() or _boot.get_fade().get_alpha() > 0.5,
		"sous le rideau")
	assert_false(_player.is_input_enabled(), "joueur bloqué pendant l'écran")
	await wait_until(func() -> bool: return not screen.is_showing(), TIMEOUT)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"route_1", "retour sur la Route 1")
	assert_eq(_player.get_cell(), Vector2i(23, 2), "une case en retrait du bord nord")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "tourné vers le sud")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_boot.get_fade().is_opaque())
	assert_true(zones.is_empty(), "aucun titre de zone")
	assert_false(_boot.get_hud().get_caption().is_showing())
	assert_false(GameState.discovered_maps.has(&"jadielle"), "aucune carte Jadielle découverte")
	assert_push_error_count(0)


func test_the_east_column_works_too() -> void:
	await _start_on_route_1(&"jadielle_soon_e")
	var screen := _boot.get_coming_soon_screen()
	await _walk_into_the_north_edge()
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_false(screen.is_showing())
	assert_eq(_player.get_cell(), Vector2i(24, 2))
	assert_eq(_player.get_facing(), Vector2i.DOWN)


func test_nothing_is_saved_during_the_screen_then_the_normal_autosave_applies() -> void:
	await _start_on_route_1()
	var screen := _boot.get_coming_soon_screen()
	assert_eq(_writes(), 1, "autosave à l'arrivée sur la carte")
	await _walk_into_the_north_edge()
	# Un autosave demandé pendant l'écran (rien ne l'empêche d'être demandé) attend la fin.
	_boot.request_autosave("test")
	assert_false(_boot.is_stable(), "l'écran provisoire n'est jamais un état stable")
	while screen.is_showing() or SceneRouter.is_transitioning():
		assert_eq(_writes(), 1, "aucune écriture pendant la transition")
		await wait_process_frames(1)
	_boot.notification(NOTIFICATION_APPLICATION_PAUSED)
	await wait_process_frames(3)
	assert_eq(_writes(), 2, "écrit une fois la partie stable")
	var saved: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	assert_eq(saved.get("map"), "route_1")
	assert_eq(JsonFields.get_vector2i(saved, "cell"), Vector2i(23, 2), "case de retour")
	assert_false((saved.get("discovered_maps", {}) as Dictionary).has("jadielle"))


func test_a_tap_shortens_the_screen() -> void:
	await _start_on_route_1()
	var screen := _boot.get_coming_soon_screen()
	screen.hold_duration = 30.0
	await _walk_into_the_north_edge()
	await wait_seconds(screen.SKIP_DELAY + 0.1)
	assert_true(screen.is_showing())
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	Input.parse_input_event(tap)
	await wait_until(func() -> bool: return not screen.is_showing(), TIMEOUT)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_true(_player.is_input_enabled())


func test_in_a_release_build_the_north_edge_stays_blocked() -> void:
	SceneRouter.coming_soon_enabled = false
	await _start_on_route_1()
	Input.action_press(&"move_up")
	await wait_seconds(1.0)
	Input.action_release(&"move_up")
	assert_false(_boot.get_coming_soon_screen().is_showing())
	assert_false(SceneRouter.is_transitioning())
	assert_eq(_player.get_cell(), Vector2i(23, 1), "arrêté au haut du chemin")
	assert_true(_player.is_input_enabled())
	assert_eq(_boot.get_map().map_id, &"route_1")
