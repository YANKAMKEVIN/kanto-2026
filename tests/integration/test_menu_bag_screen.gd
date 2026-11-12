extends GutTest
## Le Sac jouable avec le VRAI écran (TrainerMenu / BagScreen du T11) et le vrai Boot
## (jalon-06.md §6.8, T12) : menu → Sac → UTILISER → Pokémon → résultat → UTILISER À NOUVEAU,
## et le retour Android / Échap qui referme d'abord le choix du Pokémon.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_t12b_save.json"
const TIMEOUT := 12.0

var _fs: MemoryFs
var _boot: Boot
var _menu: MenuDirector
var _screen: TrainerMenu
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")
	_fs = MemoryFs.new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_menu = _boot.get_menu_director()
	_screen = _boot.get_trainer_menu()
	_screen.speed_scale = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(1)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	var data := _boot.get_pokemon_data()
	for species: StringName in [&"charmander", &"pidgey"]:
		GameState.party.add(PokemonFactory.create(data, species, 40, GameRng.new(7)))
	var hurt: Pokemon = GameState.party.get_at(1)
	hurt.hp = hurt.max_hp() - 50
	GameState.bag.add(&"potion", 3)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _tap(tile: BagTile) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = tile.size * 0.5
		tile._gui_input(event)


func _open_picker() -> BagScreen:
	assert_true(_menu.open(MenuRoute.bag()))
	await wait_process_frames(3)
	var bag := _screen.get_bag()
	assert_not_null(bag)
	bag.get_action_button().pressed.emit()
	await wait_process_frames(3)
	return bag


func test_real_screen_is_wired_and_potion_flow_works() -> void:
	var bag := await _open_picker()
	var hurt: Pokemon = GameState.party.get_at(1)
	var start := hurt.hp
	assert_true(bag.is_picker_open(), "UTILISER ouvre le choix du Pokémon")
	_tap(bag.get_picker().get_card(1))
	await wait_process_frames(2)
	assert_eq(hurt.hp, start + 20)
	assert_eq(GameState.bag.count_of(&"potion"), 2)
	assert_true(bag.get_result_bar().get_text().begins_with("+"),
		bag.get_result_bar().get_text())
	assert_true(bag.get_result_bar().is_repeat_shown())
	bag.get_result_bar().get_repeat_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(hurt.hp, start + 40, "UTILISER À NOUVEAU : même Pokémon")
	assert_eq(GameState.bag.count_of(&"potion"), 1)
	_menu.close()


func test_back_closes_the_picker_first_then_leaves_the_bag() -> void:
	var bag := await _open_picker()
	assert_true(bag.is_picker_open())
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(bag.is_picker_open(), "le choix se referme")
	assert_true(_menu.is_open())
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.BAG, "toujours dans le Sac")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.DASHBOARD)
	_menu.close()


func test_escape_action_closes_the_picker_first() -> void:
	var bag := await _open_picker()
	var event := InputEventAction.new()
	event.action = &"menu"
	event.pressed = true
	_boot._unhandled_input(event)
	await wait_process_frames(2)
	assert_false(bag.is_picker_open())
	assert_true(_menu.is_open(), "le menu reste ouvert")
	_boot._unhandled_input(event)
	assert_false(_menu.is_open(), "puis Échap ferme le menu")


func test_cards_never_turn_favorite_by_themselves() -> void:
	assert_true(_menu.open(MenuRoute.bag()))
	# Rien ne doit se produire pendant 1,2 s : attente, pas une mesure de durée.
	var end := Time.get_ticks_msec() + 1200  # temps réel : attente où rien ne doit arriver
	while Time.get_ticks_msec() < end:  # temps réel : attente où rien ne doit arriver
		await wait_process_frames(1)
	assert_false(GameState.bag.is_favorite(&"potion"), "aucun appui long sans doigt")
	_menu.close()


# --- Ergonomie (QA du Sac du 2026-11-12) ------------------------------------------------

## Sept catégories (favoris compris) tiennent dans la colonne sans défiler ; les cartes sont
## plus petites, le nom tient sur deux lignes au lieu d'être coupé.
func test_all_categories_fit_and_cards_show_whole_names() -> void:
	for id: StringName in [&"poke_ball", &"x_attack", &"nugget", &"tm11", &"oak_parcel"]:
		GameState.bag.add(id, 1)
	GameState.bag.set_favorite(&"potion", true)
	assert_true(_menu.open(MenuRoute.bag()))
	await wait_process_frames(4)
	var bag := _screen.get_bag()
	var tabs := bag.get_tabs()
	assert_eq(tabs.size(), 7, "favoris et six catégories")
	var column := bag.get_left_panel().get_global_rect()
	for id: StringName in tabs:
		var tab := tabs[id]
		assert_true(column.encloses(tab.get_global_rect()), "%s visible sans défiler" % id)
		assert_gte(tab.size.y, float(UiTokens.BAG_TAB_FIT_MIN), String(id))
	bag.open_category(&"tm")
	await wait_process_frames(3)
	var card := bag.get_card(&"tm11")
	assert_eq(card.custom_minimum_size, UiTokens.BAG_MENU_CARD_SIZE)
	assert_gte(card.custom_minimum_size.y, float(UiTokens.TOUCH_MIN))
	var label := card.get_node("%NameLabel") as Label
	assert_gt(label.get_line_count(), 1, "nom long : deux lignes")
	assert_lte(label.get_line_count(), UiTokens.BAG_MENU_CARD_NAME_LINES, "nom entier, pas coupé")


## Le résultat d'un usage ne réduit plus le panneau du choix du Pokémon.
func test_the_result_bar_does_not_shrink_the_picker() -> void:
	var bag := await _open_picker()
	await wait_process_frames(2)
	var before := bag.get_detail_panel().size.y
	_tap(bag.get_picker().get_card(1))
	await wait_process_frames(3)
	assert_false(bag.get_result_bar().get_text().is_empty(), "résultat affiché")
	assert_eq(bag.get_detail_panel().size.y, before, "le panneau de droite garde sa hauteur")
