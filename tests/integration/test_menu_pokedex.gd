extends GutTest
## Le Pokédex jouable avec le vrai Boot (jalon-06.md §6.9, T16) : route refusée sans activation,
## OBSERVER (une fois par individu et par visite), toasts différés, notes, sauvegarde. L'écran
## est un faux ([FakeMenu]) : le vrai PokedexScreen (T15) est relié par Boot s'il existe.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t16_dex_save.json"
const TIMEOUT := 12.0
const LEO_RATTATA := Vector2i(17, 9)

var _fs: MemoryFs
var _boot: Boot
var _menu: MenuDirector
var _screen: Node
var _player: Player
var _toasts: Array[String] = []


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


func _start(debug_unlock: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"pallet_town"
	_boot.start_spawn = &"start"
	if debug_unlock:
		_boot.force_debug_unlocks = true
		_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	_boot.get_trainer_menu().speed_scale = 0.0
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, _detail: String) -> void: _toasts.append(title))
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Se place devant le Rattata de Léo et fait OBSERVER ; attend la fin du dialogue.
func _observe_rattata(new_visit: bool = true) -> void:
	if new_visit:
		SceneRouter.start_at(&"pallet_town", LEO_RATTATA + Vector2i.DOWN, Vector2i.UP)
		await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell(), LEO_RATTATA + Vector2i.DOWN, "devant le Rattata")
	_player.face(Vector2i.UP)
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
	await wait_process_frames(3)


func test_without_activation_the_route_is_refused_but_observing_still_records_silently() -> void:
	await _start()
	_menu.open()
	assert_false(_menu.go(MenuRoute.pokedex()), "route refusée")
	_menu.close()
	await _observe_rattata()
	assert_eq(GameState.pokedex.get_entry(&"rattata").times_seen, 1, "enregistré quand même")
	assert_true(GameState.pokedex.get_entry(&"rattata").notes.has(&"rattata_hops"),
		"note débloquée en silence")
	await wait_process_frames(4)
	assert_eq(_toasts.size(), 0, "aucun toast")
	assert_eq(_screen.pokedex_grids.size(), 0, "aucune grille")
	assert_eq(_screen.pokedex_sheets.size(), 0, "aucun texte")


func test_with_the_debug_flag_the_grid_and_the_sheet_are_sent() -> void:
	await _start(true)
	GameState.record_seen(&"pidgey", &"route_1")
	_menu.open(MenuRoute.pokedex())
	assert_eq(_screen.pokedex_grids.size(), 1)
	assert_eq(_screen.pokedex_grids[0].filter, PokedexQuery.Filter.ALL)
	assert_eq(_screen.pokedex_sheets.size(), 1, "fiche d'arrivée : première espèce connue")
	assert_eq(_screen.pokedex_sheets[0].species_id, &"pidgey")
	_menu.open_species(&"pidgey")
	assert_eq(_screen.pokedex_sheets.size(), 2)
	_menu.open_species(&"mew")
	assert_eq(_screen.pokedex_sheets.size(), 2, "espèce inconnue : rien")
	_screen.pokedex_filter_changed.emit(PokedexQuery.Filter.SEEN, &"", &"", "")
	assert_eq(_screen.pokedex_grids.size(), 2)
	assert_eq(_screen.pokedex_grids[1].filter, PokedexQuery.Filter.SEEN)
	assert_eq(_screen.pokedex_sheets.size(), 2, "un changement de filtre n'ouvre pas de fiche")
	_menu.close()


func test_observing_gives_a_toast_and_only_once_per_individual_and_visit() -> void:
	await _start(true)
	await _observe_rattata()
	assert_eq(GameState.pokedex.get_entry(&"rattata").times_seen, 1)
	assert_eq(_toasts, [PokedexUpdates.TITLES[PokedexUpdates.Kind.NEW_SPECIES]] as Array[String])
	await _observe_rattata(false)
	assert_eq(GameState.pokedex.get_entry(&"rattata").times_seen, 1, "même individu, même visite")
	# Autre visite de la carte : l'individu compte à nouveau.
	await _observe_rattata()
	assert_eq(GameState.pokedex.get_entry(&"rattata").times_seen, 2)


func test_toasts_wait_for_a_stable_game_and_come_one_at_a_time() -> void:
	await _start(true)
	_player.set_input_enabled(false, &"test")
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_seen(&"rattata", &"route_1")
	await wait_process_frames(5)
	assert_eq(_toasts.size(), 0, "jamais pendant une rencontre ou une scène")
	_player.set_input_enabled(true, &"test")
	await wait_until(func() -> bool: return _toasts.size() >= 1, TIMEOUT)
	assert_eq(_toasts.size(), 1, "un à la fois")
	await wait_until(func() -> bool: return _toasts.size() == 2, TIMEOUT)


func test_wild_seen_and_capture_are_recorded_and_saved_back() -> void:
	await _start(true)
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_caught(&"rattata", &"route_1")
	assert_eq(PokedexQuery.state_of(GameState.pokedex, &"pidgey"), PokedexQuery.State.SEEN)
	assert_eq(PokedexQuery.state_of(GameState.pokedex, &"rattata"), PokedexQuery.State.CAUGHT)
	var dict := GameState.to_dict()
	GameState.new_game()
	assert_true(GameState.load_dict(dict, _boot.get_pokemon_data()))
	var entry := GameState.pokedex.get_entry(&"pidgey")
	assert_eq(entry.times_seen, 1)
	assert_true(entry.notes.has(&"pidgey_paths"), "notes relues")


func test_the_activation_flag_gives_no_burst_of_toasts() -> void:
	await _start()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	await wait_process_frames(6)
	assert_eq(_toasts.size(), 0)
