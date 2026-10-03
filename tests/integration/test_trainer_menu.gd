extends GutTest
## TrainerMenu (jalon 6, T3) : calque, ouverture/fermeture animées (speed_scale 0 et réel),
## × et RETOUR (un signal chacun), écran provisoire, pause de l'arbre.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"

var _menu: TrainerMenu


func before_each() -> void:
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	_menu.speed_scale = 0.0
	add_child_autofree(_menu)


func _view() -> DashboardView:
	var view := DashboardView.new()
	view.zone_name = "Bourg Palette"
	view.player_name = "Kevin"
	view.play_time_text = "0 h 00"
	view.cards.append(MenuCardView.new(&"team", "Équipe", "x"))
	view.cards.append(MenuCardView.new(&"settings", "Paramètres", "y"))
	return view


func test_layer_and_process_mode() -> void:
	assert_eq(_menu.layer, UiTokens.LAYER_MENU)
	assert_eq(_menu.layer, 20)
	assert_eq(_menu.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_closed_at_start_and_invisible() -> void:
	assert_false(_menu.is_open())
	assert_false(_menu.get_root().visible)


func test_open_shows_dashboard_and_zone_name() -> void:
	_menu.show_dashboard(_view())
	await _menu.open_animated()
	assert_true(_menu.is_open())
	assert_true(_menu.get_root().visible)
	assert_eq(_menu.get_amount(), 1.0)
	assert_eq(_menu.get_current_screen(), _menu.get_dashboard())
	assert_true(_menu.get_dashboard().visible)
	assert_eq(_menu.get_dashboard().modulate.a, 1.0)
	assert_eq(_menu.get_zone_label().text, "Bourg Palette")
	assert_true(_menu.get_zone_pill().visible)


func test_open_before_dashboard_view_arrives() -> void:
	await _menu.open_animated()
	_menu.show_dashboard(_view())
	assert_true(_menu.get_dashboard().visible)
	assert_eq(_menu.get_dashboard().modulate.a, 1.0)


func test_empty_zone_hides_the_pill() -> void:
	var view := _view()
	view.zone_name = ""
	_menu.show_dashboard(view)
	assert_false(_menu.get_zone_pill().visible)


func test_close_animated_hides_everything() -> void:
	_menu.show_dashboard(_view())
	await _menu.open_animated()
	await _menu.close_animated()
	assert_false(_menu.is_open())
	assert_false(_menu.get_root().visible)
	assert_false(_menu.get_dashboard().visible)
	assert_eq(_menu.get_amount(), 0.0)


func test_is_open_false_from_start_of_close() -> void:
	_menu.speed_scale = 1.0
	_menu.show_dashboard(_view())
	_menu.open_animated()
	_menu.close_animated()
	assert_false(_menu.is_open())
	await wait_seconds(UiTokens.MENU_CLOSE + 0.2)
	assert_false(_menu.get_root().visible)


func test_animated_open_reaches_full_amount() -> void:
	_menu.speed_scale = 1.0
	_menu.show_dashboard(_view())
	_menu.open_animated()
	assert_lt(_menu.get_amount(), 1.0)
	await wait_seconds(UiTokens.MENU_OPEN + 0.25)
	assert_eq(_menu.get_amount(), 1.0)
	assert_almost_eq(_menu.get_dashboard().modulate.a, 1.0, 0.001)


func test_open_cuts_a_closing_fade() -> void:
	_menu.show_dashboard(_view())
	await _menu.open_animated()
	_menu.speed_scale = 1.0
	_menu.close_animated()
	await wait_seconds(UiTokens.MENU_CLOSE * 0.5)
	_menu.show_dashboard(_view())
	_menu.open_animated()
	await wait_seconds(UiTokens.MENU_OPEN + 0.25)
	assert_true(_menu.is_open())
	assert_true(_menu.get_root().visible)
	assert_eq(_menu.get_amount(), 1.0)


func test_close_button_emits_one_close_requested() -> void:
	_menu.show_dashboard(_view())
	await _menu.open_animated()
	watch_signals(_menu)
	_menu.get_close_button().pressed.emit()
	assert_signal_emit_count(_menu, "close_requested", 1)
	assert_signal_emit_count(_menu, "back_requested", 0)


func test_close_button_ignored_when_closed() -> void:
	watch_signals(_menu)
	_menu.get_close_button().pressed.emit()
	assert_signal_emit_count(_menu, "close_requested", 0)


func test_placeholder_and_back() -> void:
	_menu.show_dashboard(_view())
	await _menu.open_animated()
	_menu.show_placeholder(MenuRoute.TEAM)
	assert_eq(_menu.get_current_screen(), _menu.get_placeholder())
	assert_eq(_menu.get_placeholder().get_title_text(), "ÉQUIPE — À venir")
	assert_true(_menu.get_placeholder().visible)
	assert_false(_menu.get_dashboard().visible)
	var back := _menu.get_placeholder().get_back_button()
	assert_gte(back.custom_minimum_size.y, float(UiTokens.TOUCH_MIN))
	watch_signals(_menu)
	back.pressed.emit()
	assert_signal_emit_count(_menu, "back_requested", 1)
	assert_signal_emit_count(_menu, "close_requested", 0)
	_menu.show_dashboard(_view())
	assert_true(_menu.get_dashboard().visible)
	assert_false(_menu.get_placeholder().visible)


func _team_view() -> TeamView:
	var view := TeamView.new()
	for i: int in 2:
		var member := TeamMemberView.new()
		member.party_index = i
		member.species_id = &"charmander"
		member.display_name = "Salamèche"
		member.level = 5
		member.hp = 19
		member.max_hp = 19
		var sheet := PokemonSheetView.new()
		sheet.member = member
		sheet.history = HistoryView.new()
		view.members.append(member)
		view.sheets.append(sheet)
	return view


func test_show_team_relays_signals_and_keeps_screen() -> void:
	var moved: Array = []
	var routes: Array[MenuRoute] = []
	_menu.team_member_moved.connect(func(a: int, b: int) -> void: moved.append([a, b]))
	_menu.route_requested.connect(func(r: MenuRoute) -> void: routes.append(r))
	_menu.show_team(_team_view(), 0)
	await _menu.open_animated()
	var team := _menu.get_team()
	assert_not_null(team)
	assert_eq(_menu.get_current_screen(), team)
	team.member_moved.emit(0, 1)
	assert_eq(moved, [[0, 1]])
	team.use_item_requested.emit(1)
	assert_eq(routes.size(), 1)
	assert_eq(routes[0].screen, MenuRoute.BAG)
	assert_eq(routes[0].params["context"], MenuRoute.BAG_CONTEXT_TEAM)
	assert_eq(routes[0].params["target"], 1)
	_menu.show_team(_team_view(), 1)
	assert_eq(_menu.get_team(), team, "gardé, pas ré-instancié")
	assert_eq(team.modulate.a, 1.0)


func test_show_pokedex_relays_signals_and_back_closes_sheet_first() -> void:
	var filters: Array = []
	var opened: Array[StringName] = []
	var backs: Array = [0]
	_menu.pokedex_filter_changed.connect(func(f: int, z: StringName, t: StringName,
		x: String) -> void: filters.append([f, z, t, x]))
	_menu.pokedex_species_opened.connect(func(s: StringName) -> void: opened.append(s))
	_menu.back_requested.connect(func() -> void: backs[0] += 1)
	var view := PokedexGridView.new()
	view.title = "POKÉDEX — KANTO"
	view.filter_labels = PackedStringArray(["TOUS", "VUS", "CAPTURÉS", "HABITATS"])
	view.slots.append(PokedexSlotView.new(4, &"charmander", "Salamèche",
		PokedexQuery.State.CAUGHT))
	_menu.show_pokedex(view)
	await _menu.open_animated()
	var dex := _menu.get_pokedex()
	assert_not_null(dex)
	assert_eq(_menu.get_current_screen(), dex)
	dex.filter_changed.emit(1, &"", &"", "")
	dex.species_opened.emit(&"charmander")
	assert_eq(filters, [[1, &"", &"", ""]])
	assert_eq(opened, [&"charmander"])
	assert_false(_menu.pokedex_back(), "pas de fiche : rien à fermer")
	var sheet := PokedexSheetView.new()
	sheet.species_id = &"charmander"
	sheet.name = "Salamèche"
	_menu.show_pokedex_sheet(sheet)
	assert_true(dex.is_sheet_open())
	assert_true(_menu.pokedex_back())
	assert_false(dex.is_sheet_open())
	assert_eq(backs[0], 0)
	_menu.show_pokedex(view)
	assert_eq(_menu.get_pokedex(), dex, "gardé, pas ré-instancié")


func test_show_map_relays_signals_and_keeps_screen() -> void:
	var touched: Array[StringName] = []
	var routes: Array[MenuRoute] = []
	var backs := [0]
	_menu.map_zone_touched.connect(func(z: StringName) -> void: touched.append(z))
	_menu.route_requested.connect(func(r: MenuRoute) -> void: routes.append(r))
	_menu.back_requested.connect(func() -> void: backs[0] += 1)
	var view := MapView.new()
	view.title = "CARTE — KANTO"
	_menu.show_map(view)
	await _menu.open_animated()
	var map := _menu.get_map()
	assert_not_null(map)
	assert_eq(_menu.get_current_screen(), map)
	map.zone_touched.emit(&"route_1")
	assert_eq(touched, [&"route_1"])
	map.route_requested.emit(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, &"pidgey"))
	assert_eq(routes.size(), 1, "le lien Pokémon observé → Pokédex est relayé")
	map.get_back_button().pressed.emit()
	assert_eq(backs[0], 1)
	var panel := ZonePanelView.new()
	panel.zone_id = &"route_1"
	panel.name = "Route 1"
	_menu.show_map_zone(panel)
	assert_eq(_menu.get_current_screen(), map, "le panneau ne change pas d'écran")
	_menu.show_map(view)
	assert_eq(_menu.get_map(), map, "gardé, pas ré-instancié")
