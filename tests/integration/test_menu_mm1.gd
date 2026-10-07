extends GutTest
## Menu rapproché des maquettes (MM.1, docs/tech/menu-maquettes.md) : les écrans se construisent
## avec les images peintes et les artworks, bandeau d'état (heure cachée tant que l'horloge est
## inactive, argent seulement dans le Sac), « ‹ » compact à la place du × sur l'Équipe et le Sac,
## « Utiliser sur… » et l'équipe dans le panneau de l'objet du Sac.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080
const ORDER: Array[StringName] = [&"team", &"pokedex", &"bag", &"map", &"trainer", &"settings"]

var _data: PokemonData
var _zones: ZoneLibrary
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_items = ItemLibrary.new()
	_items.load_dir()


func _menu_in(width: int) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	return menu


func _dashboard_view(badges: String = "") -> DashboardView:
	var view := DashboardView.new()
	view.zone_name = "Route 1"
	view.player_name = "Kevin"
	view.player_title = "Dresseur Pokémon"
	view.play_time_text = "12 h 43"
	view.badges_text = badges
	var lead := TeamMemberView.new()
	lead.species_id = &"charmander"
	lead.dex_number = 4
	lead.display_name = "Salamèche"
	lead.level = 14
	lead.hp = 39
	lead.max_hp = 39
	view.lead = lead
	for screen: StringName in ORDER:
		var texts: Array = DashboardViews.CARD_TEXTS[screen]
		view.cards.append(MenuCardView.new(screen, texts[0], texts[1]))
	return view


func _team_view() -> TeamView:
	var state: Node = GameStateScript.new()
	state.new_game(7)
	for spec: Array in [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10]]:
		var pokemon := PokemonFactory.create(_data, spec[0], spec[1], state.rng)
		state.party.add(pokemon)
		state.stamp_meeting(pokemon, Pokemon.Origin.CAPTURE, &"route_1")
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var view := TeamViews.build(state.party, _data, _zones, state.pokedex, unlocks)
	state.free()
	return view


func _party() -> Party:
	var party := Party.new()
	var rng := GameRng.new(11)
	for spec: Array in [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10]]:
		party.add(PokemonFactory.create(_data, spec[0], spec[1], rng))
	party.get_at(0).hp = 5
	party.get_at(2).hp = 0
	return party


func _bag() -> Bag:
	var bag := Bag.new()
	bag.add(&"potion", 3)
	bag.add(&"poke_ball", 5)
	bag.add(&"oak_parcel", 1)
	return bag


func test_dashboard_cards_portrait_and_lead_use_the_painted_art() -> void:
	for width: int in WIDTHS:
		var menu := _menu_in(width)
		menu.show_dashboard(_dashboard_view())
		menu.open_animated()
		await wait_process_frames(3)
		for card: MenuCard in menu.get_dashboard().get_cards():
			assert_not_null(card.get_illustration(), "illustration de %s" % card.get_screen())
			assert_eq(card.get_illustration(), MenuArt.card_illustration(card.get_screen()))
			var rect := card.get_global_rect()
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN))
		var trainer := menu.get_dashboard().get_trainer_card()
		var portrait := trainer.get_portrait()
		assert_eq(portrait.texture, MenuArt.hero_bust(), "portrait peint du héros")
		assert_true(trainer.get_global_rect().grow(0.5).encloses(portrait.get_global_rect()),
			"le portrait reste dans la carte du Dresseur (%d)" % width)
		assert_eq(trainer.get_lead_card().get_thumb().texture, PokedexArt.thumbnail(4))


func test_badges_line_shown_only_with_a_badge() -> void:
	var menu := _menu_in(2340)
	menu.show_dashboard(_dashboard_view())
	menu.open_animated()
	await wait_process_frames(2)
	var trainer := menu.get_dashboard().get_trainer_card()
	assert_false(trainer.is_badges_shown(), "aucun badge : pas de ligne")
	menu.show_dashboard(_dashboard_view(DashboardViews.badges_text(2)))
	assert_true(trainer.is_badges_shown())


func test_clock_chip_hidden_while_the_clock_is_inactive() -> void:
	var menu := _menu_in(2340)
	menu.show_dashboard(_dashboard_view())
	menu.open_animated()
	await wait_process_frames(2)
	assert_false(menu.get_clock().is_active(), "pas de cycle jour/nuit avant la phase 10")
	assert_false(menu.get_clock_chip().visible, "aucune heure inventée")
	assert_eq(menu.get_clock_text(), "")
	assert_true(menu.get_zone_pill().visible, "le lieu est dans le bandeau d'état")
	assert_true(menu.get_status_bar().visible)
	menu.get_clock().start(10, 24)
	assert_true(menu.get_clock_chip().visible, "la phase 10 n'a qu'à activer l'horloge")
	assert_eq(menu.get_clock_text(), "10:24")
	var clock := WorldClock.new()
	menu.set_clock(clock)
	assert_false(menu.get_clock_chip().visible)


func test_money_only_in_the_bag_status_bar() -> void:
	var menu := _menu_in(2340)
	menu.show_dashboard(_dashboard_view())
	menu.open_animated()
	await wait_process_frames(2)
	assert_eq(menu.get_money_text(), "", "jamais d'argent au tableau de bord (dossier 09 §10)")
	menu.show_bag(BagQuery.view(_bag(), _items, BagQuery.CONTEXT_FIELD, BagQuery.Sort.RELEVANCE,
		&"heal", null, -1, null, 1234))
	await wait_process_frames(2)
	assert_eq(menu.get_money_text(), MenuFormat.money(1234))
	menu.show_team(_team_view(), 0)
	await wait_process_frames(2)
	assert_eq(menu.get_money_text(), "", "ni dans l'Équipe")


func test_team_and_bag_put_a_compact_back_in_place_of_the_close_button() -> void:
	for width: int in WIDTHS:
		var menu := _menu_in(width)
		menu.show_dashboard(_dashboard_view())
		menu.open_animated()
		await wait_process_frames(2)
		assert_true(menu.get_close_button().visible, "× sur le tableau de bord")
		var backs: Array[int] = []
		menu.back_requested.connect(func() -> void: backs.append(1))
		menu.show_team(_team_view(), 0)
		await wait_process_frames(2)
		assert_false(menu.get_close_button().visible, "l'Équipe pose son « ‹ »")
		var back := menu.get_team().get_back_button()
		var rect := back.get_global_rect()
		assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN))
		assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN))
		assert_almost_eq(rect.position, menu.get_close_button().get_global_rect().position,
			Vector2.ONE, "à la place du ×")
		back.pressed.emit()
		assert_eq(backs.size(), 1, "un retour par toucher")
		menu.show_bag(BagQuery.view(_bag(), _items, BagQuery.CONTEXT_FIELD))
		await wait_process_frames(2)
		assert_false(menu.get_close_button().visible, "le Sac pose son « ‹ »")
		menu.show_dashboard(_dashboard_view())
		await wait_process_frames(2)
		assert_true(menu.get_close_button().visible)


func test_bag_icons_are_painted_and_targets_live_in_the_item_panel() -> void:
	for width: int in WIDTHS:
		var menu := _menu_in(width)
		var party := _party()
		var bag := _bag()
		menu.show_bag(BagQuery.view(bag, _items, BagQuery.CONTEXT_FIELD, BagQuery.Sort.RELEVANCE,
			&"heal", party, -1, _data))
		menu.open_animated()
		await wait_process_frames(3)
		var screen := menu.get_bag()
		assert_eq(screen.get_card(&"potion").get_icon(), MenuArt.item_icon(&"potion"))
		assert_eq(screen.get_tab(&"heal").get_icon(), MenuArt.item_icon(&"potion"))
		menu.show_bag_targets(BagQuery.targets(party, bag, _items.get_item(&"potion"),
			BagQuery.CONTEXT_FIELD, _data))
		await wait_process_frames(3)
		var picker := screen.get_picker()
		assert_true(screen.is_picker_open())
		assert_true(picker.is_compact())
		assert_true(screen.get_detail_panel().is_ancestor_of(picker),
			"« Utiliser sur… » est dans le panneau de l'objet")
		assert_true(screen.get_cards()[0].is_visible_in_tree(), "les objets restent visibles")
		assert_eq(picker.get_title_text(), PartyPicker.COMPACT_TITLE)
		assert_eq(picker.get_card(0).get_thumb_texture(), PokedexArt.thumbnail(4))
		var panel := screen.get_detail_panel().get_global_rect()
		for card: PartyTargetCard in picker.get_cards():
			var rect := card.get_global_rect()
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, "ligne ≥ TOUCH_MIN")
			assert_lte(rect.end.x, panel.end.x + 0.5, "dans le panneau (%d)" % width)
		var cancel := picker.get_cancel_button().get_global_rect()
		assert_gte(cancel.size.y, float(UiTokens.TOUCH_MIN) - 0.5)
		assert_lte(cancel.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5)
