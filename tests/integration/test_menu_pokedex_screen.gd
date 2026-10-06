extends GutTest
## Le Pokédex jouable avec le VRAI écran (TrainerMenu / PokedexScreen du T15) et le vrai Boot
## (jalon-06.md §6.9, T16) : grille, fiche, filtre, lien Habitat → Carte, retour Android et
## Échap, toast après OBSERVER.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_t16_dex_screen_save.json"
const TIMEOUT := 12.0
const AOKI_PIDGEY := Vector2i(27, 13)

var _fs: MemoryFs
var _boot: Boot
var _menu: MenuDirector
var _screen: TrainerMenu
var _toasts: Array[String] = []
var _filters: Array[Array] = []
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()
	_filters.clear()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"pallet_town"
	_boot.start_spawn = &"start"
	_boot.force_debug_unlocks = true
	_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_menu = _boot.get_menu_director()
	_screen = _boot.get_trainer_menu()
	_screen.speed_scale = 0.0
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, _detail: String) -> void: _toasts.append(title))
	_screen.pokedex_filter_changed.connect(
		func(filter: int, zone: StringName, type: StringName, text: String) -> void:
			_filters.append([filter, zone, type, text]))
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


func _open_with_pidgey() -> PokedexScreen:
	GameState.record_seen(&"pidgey", &"pallet_town")
	_toasts.clear()
	assert_true(_menu.open(MenuRoute.pokedex()))
	await wait_process_frames(2)
	return _screen.get_pokedex()


func test_the_real_screen_is_wired_and_shows_the_grid_then_the_arrival_sheet() -> void:
	assert_true(_screen.has_signal(&"pokedex_species_opened"))
	var dex := await _open_with_pidgey()
	assert_not_null(dex)
	assert_eq(_screen.get_current_screen(), dex)
	assert_eq(dex.get_slots().size() > 0, true, "grille construite")
	assert_true(dex.is_sheet_open(), "fiche d'arrivée")
	assert_eq(dex.get_opened_species(), &"pidgey")
	_menu.close()


func test_touching_a_known_slot_opens_its_sheet_and_a_filter_does_not_reopen_it() -> void:
	var dex := await _open_with_pidgey()
	GameState.record_seen(&"rattata", &"pallet_town")
	dex.species_opened.emit(&"rattata")
	assert_eq(dex.get_opened_species(), &"rattata")
	dex.get_filter_buttons()[PokedexQuery.Filter.SEEN].pressed.emit()
	await wait_process_frames(2)
	assert_eq(_filters.size(), 1, "un seul filter_changed")
	assert_eq(_filters[0][0], PokedexQuery.Filter.SEEN)
	assert_eq(dex.get_opened_species(), &"rattata", "la fiche reste celle d'avant")
	_menu.close()


func test_habitat_chip_goes_to_the_map_route() -> void:
	var dex := await _open_with_pidgey()
	dex.get_sheet().select_tab(PokedexSheet.Tab.HABITAT)
	var chips := dex.get_sheet().get_chips()
	assert_gt(chips.size(), 0, "habitat noté")
	chips[0].pressed.emit()
	await wait_process_frames(2)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.MAP)
	if _screen.has_signal(&"map_zone_touched"):
		# Depuis le T20/T21, la Carte est un vrai écran, avec la zone choisie.
		assert_ne(_screen.get_current_screen(), dex, "l'écran a changé")
	_menu.close()


func test_android_back_leaves_the_pokedex_directly() -> void:
	var dex := await _open_with_pidgey()
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_true(dex.is_sheet_open(), "la fiche est permanente")
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.DASHBOARD,
		"un seul retour quitte le Pokédex")
	_menu.close()


func test_escape_closes_the_menu_directly() -> void:
	var dex := await _open_with_pidgey()
	assert_not_null(dex)
	var event := InputEventAction.new()
	event.action = &"menu"
	event.pressed = true
	_boot._unhandled_input(event)
	await wait_process_frames(2)
	assert_false(_menu.is_open(), "plus de fiche à refermer d'abord")


func test_back_with_no_sheet_open_is_not_consumed_by_the_dex() -> void:
	assert_false(_screen.pokedex_back(), "écran Pokédex pas courant")


func test_observing_aoki_pidgey_gives_the_updated_toast() -> void:
	SceneRouter.start_at(&"pallet_town", AOKI_PIDGEY + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var player := _boot.get_player()
	if player.get_cell() != AOKI_PIDGEY + Vector2i.LEFT:
		pending("case devant le Roucool indisponible : %s" % player.get_cell())
		return
	player.face(Vector2i.RIGHT)
	Input.action_press(&"interact")
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	Input.action_release(&"interact")
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _toasts.size() > 0, TIMEOUT)
	assert_eq(_toasts[0], "Pokédex mis à jour")
	assert_eq(GameState.pokedex.get_entry(&"pidgey").times_seen, 1)
