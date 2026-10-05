extends GutTest
## Règle de déblocage du Menu Dresseur appliquée avec le vrai Boot (jalon-06.md §4), partie T4 :
## cartes du tableau de bord selon l'équipe et le Pokédex, route Pokédex refusée sans
## déblocage, déblocage de débogage sans drapeau d'histoire ni sauvegarde.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t4_unlock_save.json"

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _menu: MenuDirector


func after_each() -> void:
	get_tree().paused = false


func _start(debug_unlock: bool = false) -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	if debug_unlock:
		_boot.force_debug_unlocks = true
		_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_boot.get_trainer_menu().speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)


func _cards() -> Array[StringName]:
	var screens: Array[StringName] = []
	for card: MenuCardView in _menu.build_dashboard().cards:
		screens.append(card.screen)
	return screens


func _give_starter() -> void:
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameRng.new(1)))


func test_new_game_has_four_cards_and_no_dex_line() -> void:
	await _start()
	assert_eq(_cards(), [&"bag", &"map", &"trainer", &"settings"] as Array[StringName])
	assert_eq(_menu.build_dashboard().dex_text, "", "pas de ligne vus · capturés")
	assert_null(_menu.build_dashboard().lead, "pas de Pokémon de tête")


func test_with_a_team_but_without_the_dex_five_cards() -> void:
	await _start()
	_give_starter()
	assert_eq(_cards(), [&"team", &"bag", &"map", &"trainer", &"settings"] as Array[StringName])
	assert_eq(_menu.build_dashboard().dex_text, "")
	assert_not_null(_menu.build_dashboard().lead)


func test_seen_and_caught_data_keeps_filling_silently() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_caught(&"charmander", &"oak_lab")
	assert_eq(GameState.pokedex.seen_count(), 2, "les données continuent")
	assert_eq(_menu.build_dashboard().dex_text, "", "mais rien n'est montré")
	assert_eq(_cards().size(), 5)


func test_the_dex_route_is_refused_without_unlock() -> void:
	await _start()
	_give_starter()
	assert_true(_menu.open())
	assert_false(_menu.go(MenuRoute.pokedex()), "aucun lien ne peut y mener")
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.DASHBOARD)
	_menu.close()


func test_with_the_story_flag_six_cards_and_the_route_opens() -> void:
	await _start()
	_give_starter()
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(_cards().size(), 6)
	assert_ne(_menu.build_dashboard().dex_text, "")
	assert_true(_menu.open())
	assert_true(_menu.go(MenuRoute.pokedex()))
	_menu.close()


func test_debug_unlock_shows_the_dex_without_the_story_flag_nor_in_the_save() -> void:
	await _start(true)
	_give_starter()
	assert_eq(_cards().size(), 6, "carte Pokédex débloquée par le débogage")
	assert_true(_menu.open())
	assert_true(_menu.go(MenuRoute.pokedex()), "l'écran s'ouvre")
	assert_false(GameState.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED),
		"jamais un drapeau d'histoire")
	var flags: Array = GameState.to_dict().get("flags", [])
	assert_false(flags.has(String(StoryFlags.POKEDEX_ACTIVATED)), "pas dans la sauvegarde")
	_menu.close()


func test_the_map_panel_has_no_observed_pokemon_before_the_activation() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"pallet_town")
	var panels: Array[ZonePanelView] = []
	_menu.map_zone_shown.connect(panels.append)
	assert_true(_menu.open(MenuRoute.map()))
	assert_eq(panels.size(), 1)
	assert_eq(panels[0].zone_id, &"pallet_town")
	assert_eq(panels[0].pokemon.size(), 0, "ni section, ni titre « Pokémon observés »")
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	_menu.open_zone(&"pallet_town")
	assert_eq(panels.size(), 2)
	assert_eq(panels[1].pokemon.size(), 1, "visible après l'activation")
	_menu.close()


# --- Vrais écrans (§4) --------------------------------------------------------------------

const FORBIDDEN: Array[String] = ["pokédex", "vus", "capturés", "habitat"]


## Texte de tous les Label visibles sous [param node].
func _visible_texts(node: Node, out: Array[String] = []) -> Array[String]:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return out
	if node is Label and not (node as Label).text.is_empty():
		out.append((node as Label).text)
	if node is Button and not (node as Button).text.is_empty():
		out.append((node as Button).text)
	for child: Node in node.get_children():
		_visible_texts(child, out)
	return out


func _assert_no_dex_text(context: String) -> void:
	for text: String in _visible_texts(_boot.get_trainer_menu().get_root()):
		for word: String in FORBIDDEN:
			assert_false(text.to_lower().contains(word), "%s : « %s »" % [context, text])


func test_without_unlock_no_screen_shows_anything_about_the_dex() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_caught(&"charmander", &"oak_lab")
	assert_true(_menu.open())
	await wait_process_frames(2)
	_assert_no_dex_text("tableau de bord")
	for screen: StringName in [MenuRoute.TEAM, MenuRoute.BAG, MenuRoute.MAP, MenuRoute.TRAINER,
			MenuRoute.SETTINGS]:
		assert_true(_menu.go(MenuRoute.for_screen(screen)), String(screen))
		await wait_process_frames(2)
		_assert_no_dex_text(String(screen))
	assert_false(_boot.get_hud().get_toast().visible, "aucun toast Pokédex")
	_menu.close()


func test_with_the_debug_unlock_the_dex_card_is_shown() -> void:
	await _start(true)
	_give_starter()
	assert_true(_menu.open())
	await wait_process_frames(2)
	var found := false
	for text: String in _visible_texts(_boot.get_trainer_menu().get_root()):
		found = found or text.to_lower().contains("pokédex")
	assert_true(found, "la carte Pokédex est visible")
	_menu.close()


# --- Jalon 7 (T12, jalon-07.md §4) : la Boutique ----------------------------------------------

## La Boutique est un écran seul ouvert par le marchand : jamais une carte du tableau de bord ni
## un lien ; sans Pokédex, rien ne le mentionne à l'écran ; l'argent n'apparaît que dans la
## Boutique, le Sac et l'écran Dresseur (dossier 09 §10), jamais au tableau de bord.
func test_the_shop_is_never_a_card_and_shows_no_trace_of_the_dex() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.bag.add(&"oak_parcel", 1)
	GameState.bag.add(&"potion", 2)
	assert_false(_cards().has(MenuRoute.SHOP), "pas une carte du tableau de bord")
	assert_true(_menu.open())
	assert_false(_menu.go(MenuRoute.shop(&"viridian_mart")), "jamais par un lien")
	await wait_process_frames(2)
	var money := MenuFormat.money(GameState.money)
	for text: String in _visible_texts(_boot.get_trainer_menu().get_root()):
		assert_false(text.contains("₽"), "tableau de bord sans argent : « %s »" % text)
	_menu.close()
	await wait_process_frames(2)
	for mode: StringName in [MenuRoute.SHOP_MODE_BUY, MenuRoute.SHOP_MODE_SELL]:
		assert_true(_menu.open(MenuRoute.shop(&"viridian_mart", mode), true), String(mode))
		await wait_process_frames(2)
		_assert_no_dex_text("Boutique (%s)" % mode)
		var texts := _visible_texts(_boot.get_trainer_menu().get_root())
		var shown := false
		for text: String in texts:
			shown = shown or text.contains(money)
		assert_true(shown, "argent affiché dans la Boutique (%s)" % mode)
		_menu.close()
		await wait_process_frames(2)
	assert_false(GameState.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED))


func _texts_of(view: TrainerView) -> Array[String]:
	var texts: Array[String] = [view.player_name, view.player_title, view.play_time_text,
		view.started_text, view.seen_text, view.caught_text]
	for moment: MomentView in view.moments:
		texts.append_array([moment.title, moment.detail, moment.place])
	for stat: TrainerStatView in view.stats:
		texts.append_array([stat.label, stat.value_text])
	return texts


func test_the_trainer_view_has_no_trace_of_the_dex_before_the_activation() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_caught(&"charmander", &"oak_lab")
	GameState.record_moment(&"first_capture", &"route_1", {"species": "pidgey"})
	var views: Array[TrainerView] = []
	_menu.trainer_shown.connect(views.append)
	assert_true(_menu.open(MenuRoute.trainer()))
	assert_eq(views.size(), 1)
	var view := views[0]
	assert_null(view.seen_route)
	assert_null(view.caught_route)
	for text: String in _texts_of(view):
		for word: String in FORBIDDEN:
			assert_false(text.to_lower().contains(word), "« %s »" % text)
	for moment: MomentView in view.moments:
		if moment.route != null:
			assert_ne(moment.route.screen, MenuRoute.POKEDEX, "aucun lien vers le Pokédex")
	_menu.close()
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_true(_menu.open(MenuRoute.trainer()))
	assert_eq(views.size(), 2)
	assert_ne(views.back().seen_text, "", "présent après l'activation")
	_menu.close()
