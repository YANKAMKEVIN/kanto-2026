extends GutTest
## Tableau de bord (jalon 6, T3) : cartes (5 ou 6, jamais d'emplacement vide), signaux, lignes
## absentes quand la vue les laisse vides, zones tactiles et marges à 1920 et 2340 de large.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080
const ORDER: Array[StringName] = [&"team", &"pokedex", &"bag", &"map", &"trainer", &"settings"]


func _view(card_count: int, with_lead: bool = true, dex: String = "",
		objective: String = "Objectif : rejoindre Jadielle.") -> DashboardView:
	var view := DashboardView.new()
	view.zone_name = "Route 1"
	view.player_name = "Kevin"
	view.player_title = "Dresseur Pokémon"
	view.play_time_text = "0 h 07"
	view.dex_text = dex
	view.objective_text = objective
	if with_lead:
		var lead := TeamMemberView.new()
		lead.species_id = &"charmander"
		lead.display_name = "Salamèche"
		lead.level = 5
		lead.hp = 19
		lead.max_hp = 19
		view.lead = lead
	for screen: StringName in ORDER:
		if card_count == 5 and screen == &"pokedex":
			continue
		view.cards.append(MenuCardView.new(screen, String(screen).capitalize(), "Une ligne."))
	return view


## Menu ouvert (instantanément) dans une fenêtre virtuelle de [param width] × 1080.
func _menu_in(width: int, view: DashboardView) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_dashboard(view)
	menu.open_animated()
	await wait_frames(3)
	return menu


func test_five_and_six_cards_no_empty_slot() -> void:
	for width: int in WIDTHS:
		for count: int in [5, 6]:
			var menu := await _menu_in(width, _view(count))
			var cards := menu.get_dashboard().get_cards()
			assert_eq(cards.size(), count)
			for card: MenuCard in cards:
				assert_gt(card.size.x, 0.0)
				assert_gt(card.size.y, 0.0)
				assert_false(card.get_title_text().is_empty())
			var rows := cards[0].get_parent().get_parent().get_children()
			assert_eq(rows.size(), 2, "deux lignes")
			var total := 0
			for row: Node in rows:
				total += row.get_child_count()
				var last := row.get_child(row.get_child_count() - 1) as Control
				var right := (row as Control).get_global_rect().end.x
				assert_almost_eq(last.get_global_rect().end.x, right, 1.0,
					"la ligne est pleine (pas de trou)")
			assert_eq(total, count)


func test_card_touched_emits_one_card_chosen() -> void:
	var menu := await _menu_in(2340, _view(6))
	var chosen: Array = []
	menu.get_dashboard().card_chosen.connect(func(screen: StringName) -> void:
		chosen.append(screen))
	var routes: Array[MenuRoute] = []
	menu.route_requested.connect(func(route: MenuRoute) -> void: routes.append(route))
	menu.get_dashboard().get_card(&"bag").pressed.emit()
	assert_eq(chosen, [&"bag"])
	assert_eq(routes.size(), 1)
	assert_eq(routes[0].screen, MenuRoute.BAG)


func test_lead_touched_opens_team_zero() -> void:
	var menu := await _menu_in(2340, _view(6))
	var routes: Array[MenuRoute] = []
	menu.route_requested.connect(func(route: MenuRoute) -> void: routes.append(route))
	menu.get_dashboard().get_trainer_card().get_lead_card().pressed.emit()
	assert_eq(routes.size(), 1)
	assert_eq(routes[0].screen, MenuRoute.TEAM)
	assert_eq(routes[0].params["index"], 0)


func test_empty_texts_hide_their_lines() -> void:
	var menu := await _menu_in(2340, _view(5, false, "", ""))
	var dash := menu.get_dashboard()
	var trainer := dash.get_trainer_card()
	assert_false(trainer.is_dex_shown(), "pas de vus · capturés")
	assert_false(trainer.is_badges_shown(), "pas de badges")
	assert_true(trainer.is_play_time_shown())
	assert_false(trainer.get_lead_card().visible, "pas d'équipe, pas de carte de tête")
	assert_false(dash.get_objective_label().visible, "pas d'objectif")
	dash.show_dashboard(_view(6, true, "27 vus · 14 capturés"))
	assert_true(trainer.is_dex_shown())
	assert_eq(trainer.get_lead_card().get_hp_text(), "19 / 19")
	assert_eq(trainer.get_lead_card().get_level_text(), "Nv. 5")
	assert_true(dash.get_objective_label().visible)
	assert_eq(dash.get_objective_label().text, "Objectif : rejoindre Jadielle.")


func test_touch_zones_and_safe_margin() -> void:
	for width: int in WIDTHS:
		var menu := await _menu_in(width, _view(6))
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			Vector2(width, HEIGHT) - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		var buttons: Array[BaseButton] = []
		_collect(menu.get_root(), buttons)
		assert_gte(buttons.size(), 8, "× + 6 cartes + Pokémon de tête")
		for button: BaseButton in buttons:
			var rect := button.get_global_rect()
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "%s large" % button.name)
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN), "%s haut" % button.name)
			assert_true(safe.encloses(rect.grow(-0.5)),
				"%s dans la marge (%s à %d)" % [button.name, rect, width])


func test_nothing_clipped_inside_the_screen() -> void:
	for width: int in WIDTHS:
		var menu := await _menu_in(width, _view(6, true, "27 vus · 14 capturés"))
		var screen := Rect2(Vector2.ZERO, Vector2(width, HEIGHT))
		var labels: Array[Control] = []
		_collect_controls(menu.get_root(), labels)
		for control: Control in labels:
			assert_true(screen.encloses(control.get_global_rect().grow(-0.5)),
				"%s dans l'écran" % control.name)


func _collect(node: Node, out: Array[BaseButton]) -> void:
	for child: Node in node.get_children():
		var button := child as BaseButton
		if button != null and button.is_visible_in_tree():
			out.append(button)
		_collect(child, out)


func _collect_controls(node: Node, out: Array[Control]) -> void:
	for child: Node in node.get_children():
		var control := child as Control
		if control != null and control.is_visible_in_tree() and (control is Label
				or control is BaseButton):
			out.append(control)
		_collect_controls(child, out)
