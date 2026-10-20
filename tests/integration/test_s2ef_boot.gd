extends GutTest
## Passe systèmes 2, S2E et S2F sur la vraie scène Boot (`systemes-2.md` §2.8 à §2.10) :
## départ `s2_teleport` (téléporteur de la même carte, porte à carte refusée puis ouverte) et
## départ `s2_fly` (bouton « S'ENVOLER » de la Carte, envol, arrivée devant le Centre).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START_TELEPORT := "res://tools/debug_start/s2_teleport.json"
const START_FLY := "res://tools/debug_start/s2_fly.json"
const FADE := 0.05
const TIMEOUT := 12.0
const DOOR_AB := Vector2i(9, 3)
const DOOR_FLAG: StringName = &"door_qa_teleport_ab_open"

var _boot: Boot
var _fades: Array[float] = []
var _pages: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration,
		SceneRouter.teleport_fade_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	SceneRouter.teleport_fade_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T10:00:00")
	_pages.clear()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	SceneRouter.teleport_fade_duration = _fades[2]
	GameState.clock = DeviceClock.new()


func _start(start_path: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_s2ef_boot.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = start_path
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_runner().get_session().get_text()))
	await wait_process_frames(3)
	await _settle()


func _settle() -> void:
	await wait_until(func() -> bool:
		return _boot.is_stable() or _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await wait_process_frames(2)


## Fait défiler les dialogues en cours jusqu'à la fin.
func _finish_dialogues() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while runner.is_running() and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(3)


func _place(cell: Vector2i, facing: Vector2i) -> void:
	var map := _boot.get_map()
	map.spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)


func _step(direction: Vector2i) -> void:
	var player := _boot.get_player()
	assert_true(player.script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not player.is_moving(), TIMEOUT)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)


# --- S2F -------------------------------------------------------------------------------------

func test_teleporter_on_the_same_map_keeps_the_map_and_frees_the_player() -> void:
	await _start(START_TELEPORT)
	var map := _boot.get_map()
	assert_eq(map.map_id, &"qa_teleport")
	# Salle C : téléporteur (1, 7) → salle A, arrivée sur (1, 5).
	await _place(Vector2i(1, 8), Vector2i.UP)
	await _step(Vector2i.UP)
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_map(), map, "même carte, pas de rechargement")
	assert_eq(_boot.get_player().get_cell(), Vector2i(1, 5))
	assert_true(_boot.get_player().is_input_enabled())


func test_key_door_refuses_without_the_card_then_opens_for_good() -> void:
	await _start(START_TELEPORT)
	await _place(DOOR_AB + Vector2i.LEFT, Vector2i.RIGHT)
	var grid := _boot.get_map().get_grid()
	assert_false(grid.is_free(DOOR_AB), "porte fermée")
	await _press_interact()
	await _finish_dialogues()
	assert_eq(_pages, ["Il faut une carte."] as Array[String])
	assert_false(GameState.flags.has_flag(DOOR_FLAG))
	GameState.bag.add(&"card_key")
	await _press_interact()
	await wait_for_signal(_boot.get_key_door_director().door_opened, TIMEOUT)
	await wait_process_frames(3)
	assert_true(GameState.flags.has_flag(DOOR_FLAG))
	assert_true(grid.is_free(DOOR_AB), "porte ouverte")
	await _step(Vector2i.RIGHT)
	assert_eq(_boot.get_player().get_cell(), DOOR_AB, "on passe")


# --- S2E -------------------------------------------------------------------------------------

func test_fly_start_is_valid() -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	assert_true(data.load_all())
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	assert_true(start.load_file(START_FLY, data, items), "\n".join(start.get_errors()))
	assert_eq(start.discovered.size(), 7)


func test_fly_from_the_map_screen_lands_in_front_of_the_center() -> void:
	await _start(START_FLY)
	assert_eq(_boot.get_map().map_id, &"celadon_city")
	var fly := _boot.get_fly_director()
	assert_true(fly.can_fly_to(&"pewter_city"), "ville visitée")
	assert_false(fly.can_fly_to(&"fuchsia_city"), "pas encore visitée")
	var shown: Array[ZonePanelView] = []
	var menu := _boot.get_menu_director()
	menu.map_zone_shown.connect(func(view: ZonePanelView) -> void: shown.append(view))
	menu.open_zone(&"pewter_city")
	assert_true(shown[-1].fly_available, "bouton « S'ENVOLER »")
	menu.request_fly(&"pewter_city")
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_dialogues()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"pewter_city", TIMEOUT)
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running() \
		or not fly.is_flying(), TIMEOUT)
	await _finish_dialogues()
	await wait_until(func() -> bool: return not fly.is_flying(), TIMEOUT)
	var map := _boot.get_map()
	assert_eq(map.map_id, &"pewter_city")
	assert_eq(_boot.get_player().get_cell(), map.get_spawn_cell(&"from_center"))
	assert_true(_pages[0].ends_with("s'envole très haut !"), _pages[0])
	assert_true(_pages[-1].ends_with("redescend."), _pages[-1])
	await _settle()
	assert_true(_boot.get_player().is_input_enabled())
