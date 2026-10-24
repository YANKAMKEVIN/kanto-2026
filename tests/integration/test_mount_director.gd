extends GutTest
## Monture dans la vraie partie (passe systèmes 2, `systemes-2.md` §2.2 à §2.4, T7, T8, T10) :
## la vraie scène Boot sur la Route 1. Vélo par le bouton du HUD et par le Sac, état tenu dans
## GameState, compagnon rentré puis ressorti, descente d'office en intérieur, refus avec son texte,
## Poké Flûte jouée « ailleurs ».

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_mount_director_save.json"
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _fades: Array[float] = []
var _mount: MountDirector
var _player: Player


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.flags.set_flag(&"starter_chosen")
	_mount = _boot.get_mount_director()
	_player = _boot.get_player()


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _give_bike() -> void:
	GameState.bag.add(&"bicycle", 1)


func test_without_the_bicycle_no_button_and_no_bike() -> void:
	await wait_process_frames(2)
	assert_false(_boot.get_hud().get_bike_button().visible, "pas de Bicyclette : pas de bouton")
	assert_eq(_mount.toggle_bike(), BikeRules.Check.NO_BIKE)
	assert_eq(_player.get_mount(), Mount.Kind.NONE)


func test_the_hud_button_mounts_and_dismounts() -> void:
	_give_bike()
	await wait_process_frames(2)
	var hud := _boot.get_hud()
	assert_true(hud.get_bike_button().visible, "Bicyclette au Sac : bouton visible")
	assert_false(hud.is_bike_button_dimmed(), "dehors : actif")
	hud.get_bike_button().pressed.emit()
	assert_eq(_player.get_mount(), Mount.Kind.BIKE)
	assert_eq(GameState.player_mount, Mount.Kind.BIKE, "GameState suit")
	hud.get_bike_button().pressed.emit()
	assert_eq(_player.get_mount(), Mount.Kind.NONE)
	assert_eq(GameState.player_mount, Mount.Kind.NONE)


func test_the_bag_uses_the_bicycle() -> void:
	_give_bike()
	var menu := _boot.get_menu_director()
	assert_true(menu.open())
	menu.request_item_use(&"bicycle")
	await wait_process_frames(2)
	assert_false(menu.is_open(), "le menu se ferme")
	assert_eq(_player.get_mount(), Mount.Kind.BIKE)
	assert_true(GameState.bag.has(&"bicycle"), "rien n'est consommé")


func test_the_companion_goes_back_in_its_ball_on_the_bike() -> void:
	_give_bike()
	var data := _boot.get_pokemon_data()
	GameState.party.add(PokemonFactory.create(data, &"charmander", 9, GameRng.new(7)))
	var companion := _boot.get_companion_controller()
	assert_true(_boot.get_menu_director().toggle_companion(0), "FAIRE SORTIR")
	companion.refresh()
	assert_true(_player.script_step(Vector2i.UP))
	await wait_until(func() -> bool: return not _player.is_moving() and companion.is_shown() \
		and not companion.get_node_2d().is_moving(), TIMEOUT)
	_mount.toggle_bike()
	await wait_until(func() -> bool: return not companion.is_shown(), TIMEOUT)
	assert_false(companion.is_shown(), "rentré en selle")
	assert_true(_player.script_step(Vector2i.UP))
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_false(companion.is_shown(), "il ne suit pas le Vélo")
	_mount.toggle_bike()
	await wait_until(func() -> bool: return companion.is_shown(), TIMEOUT)
	assert_true(companion.is_shown(), "ressorti à pied")


func test_an_interior_dismounts_on_arrival_and_refuses_with_its_text() -> void:
	_give_bike()
	_mount.toggle_bike()
	SceneRouter.change_map(&"oak_lab", &"entrance", Vector2i.UP)
	await wait_until(func() -> bool: return SceneRouter.get_current_map() != null \
		and SceneRouter.get_current_map().map_id == &"oak_lab", TIMEOUT)
	assert_eq(_player.get_mount(), Mount.Kind.NONE, "on descend à l'entrée d'un intérieur")
	assert_eq(GameState.player_mount, Mount.Kind.NONE)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	assert_true(_boot.get_hud().is_bike_button_dimmed(), "grisé en intérieur")
	watch_signals(_mount)
	assert_eq(_mount.toggle_bike(), BikeRules.Check.INDOORS)
	assert_signal_emitted(_mount, "bike_refused")
	assert_true(_boot.get_dialogue_runner().is_running(), "« Ce n'est pas le moment de pédaler ! »")


func test_a_saved_bike_is_restored_on_arrival_outside() -> void:
	_give_bike()
	GameState.player_mount = Mount.Kind.BIKE
	SceneRouter.change_map(&"pallet_town", &"from_route_1_w", Vector2i.DOWN)
	await wait_until(func() -> bool: return SceneRouter.get_current_map().map_id \
		== &"pallet_town", TIMEOUT)
	assert_eq(_player.get_mount(), Mount.Kind.BIKE, "monture sauvegardée gardée dehors")


func test_the_flute_plays_elsewhere_without_a_sleeper() -> void:
	GameState.bag.add(&"poke_flute", 1)
	var keys := _boot.get_key_item_director()
	watch_signals(keys)
	assert_true(keys.use(&"poke_flute"))
	assert_signal_emitted_with_parameters(keys, "flute_played", [&""])
	assert_true(_boot.get_dialogue_runner().is_running(), "« … Quel air entraînant ! »")
	assert_true(GameState.bag.has(&"poke_flute"), "rien n'est consommé")


func test_a_key_item_not_in_the_bag_does_nothing() -> void:
	assert_false(_boot.get_key_item_director().use(&"poke_flute"))
	assert_false(_boot.get_key_item_director().use(&"potion"))
