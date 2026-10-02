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
