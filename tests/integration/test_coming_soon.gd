extends GutTest
## Destination provisoire (jalon 5, dossier-07 §12) avec la vraie scène Boot, l'autoload
## SceneRouter (fondus raccourcis) et un [SaveSystem] en mémoire. Jalon 14 (T20b) : le raccord
## sud d'Azuria (PUSH ↓, (31..33, 40)) menait à « ROUTE 5 — À venir » (build de développement,
## libellé en majuscules), puis ramenait le joueur sur la case de sortie, tourné vers le nord.
## Jalon 17 (T17) : le bord est de Carmin mène à la vraie Route 11 ; le test remet ses trois cases
## « à venir » dans la carte chargée (`tests/helpers/coming_soon_gate.gd`).
## Jalon 15 (T21) : la vraie Route 5 l'a remplacé ; depuis le T14, c'est le bord est de
## Carmin-sur-Mer (PUSH →, (63, 11..13)) qui mène à « ROUTE 11 — À venir », retour sur la case
## de sortie, tourné vers l'ouest. (Jalons 12 et 13 : bord est de la Route 24, « ROUTE 25 »,
## devenu un vrai raccord au T15 du J14.) Rien n'est sauvegardé pendant l'écran, aucun titre de zone, aucune
## nouvelle carte découverte ; en release, la sortie est inerte.
## (Jalon 5 : bord nord de la Route 1 ; jalon 7 : sortie nord de Jadielle ; jalon 8 : porte du
## poste de la Route 2 ; jalon 9 : porte nord du poste nord, devenue le passage vers la Route 2
## nord ; jalon 10 : sortie est d'Argenta, devenue le passage vers la Route 3.)

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const ComingSoonGate := preload("res://tests/helpers/coming_soon_gate.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_coming_soon_save.json"
const FADE := 0.05
const HOLD := 0.3
const TIMEOUT := 12.0
## Raccord est de Carmin-sur-Mer (jalon 15 T14) : case de sortie = case de retour (spawn
## `from_route_11_c`).
const MAP := &"vermilion_city"
const GATE := Vector2i(63, 12)
const GATE_FRONT := Vector2i(63, 12)
const RETURN_SPAWN := &"from_route_11_c"

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


## Boot sur Carmin, sur la case du raccord est, tourné vers l'est.
func _start_at_the_gate() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = MAP
	_boot.start_spawn = RETURN_SPAWN
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_coming_soon_screen().hold_duration = HOLD
	_boot.get_coming_soon_screen().fade_duration = 0.05
	await wait_process_frames(3)
	ComingSoonGate.apply(_boot.get_map())


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


## Pousse vers l'est (bord de la carte) jusqu'à ce que l'écran « à venir » soit montré.
func _walk_into_the_gate() -> void:
	var screen := _boot.get_coming_soon_screen()
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return screen.is_showing(), TIMEOUT)
	Input.action_release(&"move_right")


func test_the_exit_shows_the_coming_soon_screen_then_returns_facing_north() -> void:
	await _start_at_the_gate()
	var screen := _boot.get_coming_soon_screen()
	assert_eq(_player.get_cell(), GATE_FRONT)
	var zones: Array[String] = []
	_boot.zone_announced.connect(func(zone: String, _region: String) -> void:
		zones.append(zone))
	await _walk_into_the_gate()
	assert_eq(screen.get_label().text, "ROUTE 11 — À venir")
	assert_true(_boot.get_fade().is_opaque() or _boot.get_fade().get_alpha() > 0.5,
		"sous le rideau")
	assert_false(_player.is_input_enabled(), "joueur bloqué pendant l'écran")
	await wait_until(func() -> bool: return not screen.is_showing(), TIMEOUT)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, MAP, "retour à Carmin")
	assert_eq(_player.get_cell(), GATE_FRONT, "sur la case de sortie")
	assert_eq(_player.get_facing(), Vector2i.LEFT, "tourné vers l'ouest")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_boot.get_fade().is_opaque())
	assert_true(zones.is_empty(), "aucun titre de zone")
	assert_false(_boot.get_hud().get_caption().is_showing())
	assert_false(GameState.discovered_maps.has(&"route_11"), "aucune carte découverte")
	assert_push_error_count(0)


func test_the_gate_works_again_after_the_return() -> void:
	await _start_at_the_gate()
	var screen := _boot.get_coming_soon_screen()
	for visit: int in 2:
		await _walk_into_the_gate()
		await wait_until(func() -> bool: return not screen.is_showing(), TIMEOUT)
		await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
		assert_eq(_player.get_cell(), GATE_FRONT, "visite %d : sur la case de sortie" % visit)
		assert_eq(_player.get_facing(), Vector2i.LEFT)
		_player.face(Vector2i.RIGHT)


func test_nothing_is_saved_during_the_screen_then_the_normal_autosave_applies() -> void:
	await _start_at_the_gate()
	var screen := _boot.get_coming_soon_screen()
	assert_eq(_writes(), 1, "autosave à l'arrivée sur la carte")
	await _walk_into_the_gate()
	# Un autosave demandé pendant l'écran (rien ne l'empêche d'être demandé) attend la fin.
	_boot.request_autosave("test")
	assert_false(_boot.is_stable(), "l'écran provisoire n'est jamais un état stable")
	while screen.is_showing() or SceneRouter.is_transitioning():
		assert_eq(_writes(), 1, "aucune écriture pendant la transition")
		await wait_process_frames(1)
	# L'autosave en attente s'écrit à la première image stable (sans simuler d'arrière-plan :
	# une notification envoyée à cet instant écrivait parfois une seconde fois, selon l'image).
	await wait_until(func() -> bool: return _writes() >= 2, TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_writes(), 2, "écrit une fois la partie stable")
	var saved: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	assert_eq(saved.get("map"), String(MAP))
	assert_eq(JsonFields.get_vector2i(saved, "cell"), GATE_FRONT, "case de retour")
	assert_false((saved.get("discovered_maps", {}) as Dictionary).has("route_11"))


func test_a_tap_shortens_the_screen() -> void:
	await _start_at_the_gate()
	var screen := _boot.get_coming_soon_screen()
	screen.hold_duration = 30.0
	await _walk_into_the_gate()
	await wait_seconds(screen.SKIP_DELAY + 0.1)
	assert_true(screen.is_showing())
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	Input.parse_input_event(tap)
	await wait_until(func() -> bool: return not screen.is_showing(), TIMEOUT)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_true(_player.is_input_enabled())


func test_in_a_release_build_the_gate_is_inert() -> void:
	SceneRouter.coming_soon_enabled = false
	await _start_at_the_gate()
	Input.action_press(&"move_right")
	await wait_seconds(1.0)
	Input.action_release(&"move_right")
	assert_false(_boot.get_coming_soon_screen().is_showing())
	assert_false(SceneRouter.is_transitioning())
	assert_eq(_player.get_cell(), GATE, "au bord de la carte, rien ne se passe")
	assert_true(_player.is_input_enabled())
	assert_eq(_boot.get_map().map_id, MAP)


## (Jalon 18 : le bord ouest de la Route 9 mène désormais à la vraie Azuria, variante J18 —
## `test_route_9`, `test_azuria_cut_tree` ; l'ancien test « AZURIA — À venir » est retiré.)
