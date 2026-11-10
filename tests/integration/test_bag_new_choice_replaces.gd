extends GutTest
## Bogue signalé par Kevin sur S24 (0.36.0) : dans le Sac, un objet donné à un Pokémon (CT,
## potion…) laissait le choix du Pokémon ouvert ; toucher ensuite une AUTRE carte changeait
## l'aperçu, mais le choix gardait l'objet précédent, et c'est lui qui était appliqué. Un nouveau
## choix doit toujours remplacer le précédent, qu'il ait servi ou non.
##
## Le joueur est joué comme sur le téléphone : il touche la carte de l'objet, puis le Pokémon
## dans le choix s'il est encore ouvert, sinon UTILISER puis le Pokémon.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_bag_new_choice_save.json"
const TIMEOUT := 12.0

var _boot: Boot
var _menu: MenuDirector
var _screen: TrainerMenu
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_battle_director().get_move_learn_prompt().speed_scale = 0.0
	_menu = _boot.get_menu_director()
	_screen = _boot.get_trainer_menu()
	_screen.speed_scale = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(1)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"


func after_each() -> void:
	if _menu != null and _menu.is_open():
		_menu.close()
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _add(species: StringName, level: int) -> Pokemon:
	var pokemon := PokemonFactory.create(_boot.get_pokemon_data(), species, level,
		GameRng.new(7))
	GameState.party.add(pokemon)
	return pokemon


func _tap(tile: BagTile) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = tile.size * 0.5
		tile._gui_input(event)


func _open_bag(category: StringName) -> BagScreen:
	assert_true(_menu.open(MenuRoute.bag()))
	await wait_process_frames(3)
	var bag := _screen.get_bag()
	assert_not_null(bag)
	bag.get_tab(category).tapped.emit()
	await wait_process_frames(2)
	return bag


## Ce que fait le joueur : la carte de [param item_id], puis le Pokémon [param index] (UTILISER
## d'abord si le choix du Pokémon n'est plus ouvert).
func _use(bag: BagScreen, item_id: StringName, index: int) -> void:
	var card := bag.get_card(item_id)
	assert_not_null(card, "carte %s" % item_id)
	_tap(card)
	await wait_process_frames(2)
	assert_eq(bag.get_selected_id(), item_id)
	if not bag.is_picker_open():
		assert_true(bag.get_action_button().is_visible_in_tree(), "UTILISER visible")
		bag.get_action_button().pressed.emit()
		await wait_process_frames(3)
	assert_true(bag.is_picker_open())
	_tap(bag.get_picker().get_card(index))
	await wait_process_frames(2)


func test_second_potion_type_is_the_one_applied() -> void:
	_add(&"charmander", 40)
	var hurt := _add(&"pidgey", 40)
	hurt.hp = 10
	GameState.bag.add(&"potion", 3)
	GameState.bag.add(&"super_potion", 3)
	var bag := await _open_bag(&"heal")
	await _use(bag, &"potion", 1)
	assert_eq(hurt.hp, 30, "Potion : +20")
	assert_eq(GameState.bag.count_of(&"potion"), 2)
	await _use(bag, &"super_potion", 1)
	assert_eq(GameState.bag.count_of(&"potion"), 2, "la Potion n'est pas réutilisée")
	assert_eq(GameState.bag.count_of(&"super_potion"), 2, "c'est la Super Potion qui sert")
	assert_eq(hurt.hp, 80, "Super Potion : +50")


func test_second_tm_is_the_one_taught() -> void:
	var first := _add(&"charmander", 5)
	var second := _add(&"charmander", 5)
	assert_lt(first.moves.size(), 3)
	assert_lt(second.moves.size(), 3)
	GameState.bag.add(&"tm34", 1)
	GameState.bag.add(&"tm01", 1)
	watch_signals(_menu)
	var bag := await _open_bag(&"tm")
	await _use(bag, &"tm34", 0)
	await _finish_learning()
	assert_true(first.knows_move(&"bide"))
	await _use(bag, &"tm01", 1)
	assert_signal_emitted_with_parameters(_menu, "tm_learn_requested", [1, &"tm01"])
	await _finish_learning()
	assert_true(second.knows_move(&"mega_punch"), "la seconde CT est apprise")
	assert_false(second.knows_move(&"bide"), "jamais la CT précédente")
	assert_eq(GameState.bag.count_of(&"tm34"), 1)
	assert_eq(GameState.bag.count_of(&"tm01"), 1)


## Attend le bandeau « … apprend … ! », le passe, puis la fermeture du voile.
func _finish_learning() -> void:
	var overlay := _boot.get_tm_learn_overlay()
	assert_not_null(overlay)
	var banner := overlay.get_message_banner()
	await _frames_until(func() -> bool: return banner.is_waiting())
	assert_true(banner.is_waiting(), "le bandeau attend un toucher")
	banner.skip()
	await _frames_until(func() -> bool: return not overlay.is_open())
	assert_false(overlay.is_open(), "le voile se referme")
	await wait_process_frames(2)


## Le menu met l'arbre en pause : wait_until n'avance pas, on compte les images.
func _frames_until(condition: Callable) -> void:
	for i: int in 300:
		if condition.call():
			return
		await wait_process_frames(1)
