extends GutTest
## Le Sac jouable en exploration (jalon-06.md §6.8, T12) avec la vraie scène Boot, un
## SaveSystem en mémoire et l'écran factice : Potion sur un Pokémon blessé, refus sur un K.O.,
## UTILISER À NOUVEAU, autosave à la fermeture.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const SAVE_PATH := "user://test_t12_save.json"
const DATE := "2026-10-03T10:00:00"
const FADE := 0.05
const TIMEOUT := 12.0

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _menu: MenuDirector
var _screen: Node
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_new_game()


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _new_game() -> void:
	GameState.new_game(1)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	var data := _boot.get_pokemon_data()
	for species: StringName in [&"charmander", &"pidgey"]:
		GameState.party.add(PokemonFactory.create(data, species, 5, GameRng.new(7)))
	GameState.bag.add(&"potion", 3)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _open_bag() -> void:
	assert_true(_menu.open(MenuRoute.bag()))
	await wait_process_frames(1)


func test_the_bag_route_sends_the_bag_view_and_not_a_placeholder() -> void:
	await _open_bag()
	assert_eq(_screen.bags.size(), 1)
	assert_true(_screen.placeholders.is_empty())
	assert_not_null(_screen.bags[0].entry(&"potion"))
	_menu.close()


func test_use_requested_opens_the_party_choice() -> void:
	await _open_bag()
	_screen.bag_use_requested.emit(&"potion")
	assert_eq(_screen.bag_targets.size(), 1)
	assert_eq(_screen.bag_targets[0].targets.size(), 2)
	_menu.close()


func test_potion_heals_a_hurt_member_spends_one_and_autosaves() -> void:
	var hurt: Pokemon = GameState.party.get_at(1)
	hurt.hp = 3
	var before := _writes()
	await _open_bag()
	_screen.bag_target_chosen.emit(&"potion", 1)
	assert_eq(hurt.hp, mini(23, hurt.max_hp()))
	assert_eq(GameState.bag.count_of(&"potion"), 2)
	assert_string_contains(_screen.bag_results[-1], "+")
	assert_true(_screen.bag_repeats[-1])
	_menu.close()
	await wait_until(func() -> bool: return _writes() > before, TIMEOUT)
	assert_gt(_writes(), before, "autosave demandé")


func test_potion_on_a_fainted_member_is_refused_and_nothing_is_spent() -> void:
	var down: Pokemon = GameState.party.get_at(1)
	down.hp = 0
	await _open_bag()
	_screen.bag_target_chosen.emit(&"potion", 1)
	assert_eq(_screen.bag_results[-1], "Ce Pokémon est K.O.")
	assert_eq(down.hp, 0)
	assert_eq(GameState.bag.count_of(&"potion"), 3)
	var before := _writes()
	_menu.close()
	await wait_process_frames(10)
	assert_eq(_writes(), before, "rien n'a changé : pas d'autosave")


func test_use_again_repeats_on_the_same_member_then_gives_the_reason_when_full() -> void:
	var hurt := PokemonFactory.create(_boot.get_pokemon_data(), &"pidgey", 40, GameRng.new(7))
	GameState.party.add(hurt)
	hurt.hp = hurt.max_hp() - 50
	await _open_bag()
	_screen.bag_target_chosen.emit(&"potion", GameState.party.size() - 1)
	_screen.bag_repeat_requested.emit()
	assert_eq(hurt.hp, hurt.max_hp() - 10)
	_screen.bag_repeat_requested.emit()
	assert_eq(hurt.hp, hurt.max_hp())
	assert_eq(GameState.bag.count_of(&"potion"), 0)
	assert_false(_screen.bag_repeats[-1], "plus d'exemplaire")
	_menu.close()


func test_full_hp_gives_the_reason_without_spending() -> void:
	await _open_bag()
	_screen.bag_target_chosen.emit(&"potion", 0)
	assert_eq(_screen.bag_results[-1], "PV déjà au maximum")
	assert_eq(GameState.bag.count_of(&"potion"), 3)
	_menu.close()


func test_favorite_and_category_are_kept_in_the_session() -> void:
	await _open_bag()
	_screen.bag_category_opened.emit(&"heal")
	_screen.bag_favorite_toggled.emit(&"potion")
	assert_true(GameState.bag.is_favorite(&"potion"))
	assert_true(_screen.bags[-1].entry(&"potion").favorite)
	_menu.close()
