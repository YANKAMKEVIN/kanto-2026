extends GutTest
## Écran Boutique (jalon 7, T11 ; jalon-07.md §6.10) avec les vraies vues de ShopViews : onglets,
## quantité bornée, TOTAL à chaque cran, CONFIRMER = un seul signal, refus visible sans signal,
## glisser la liste n'achète ni ne sélectionne rien, confirmation d'un favori, retour, argent,
## zones tactiles et marges à 1920 et 2340.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const GameStateScript := preload("res://game/autoload/game_state.gd")
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _items: ItemLibrary
var _mart: ShopData
var _state: Node
var _modes: Array[StringName] = []
var _buys: Array = []
var _sells: Array = []
var _backs: int = 0


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()
	var shops := ShopLibrary.new()
	shops.load_dir()
	shops.check_references(_items)
	_mart = shops.get_shop(&"viridian_mart")


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	_state.bag.add(&"potion", 4)
	_state.bag.add(&"poke_ball", 3)
	_modes.clear()
	_buys.clear()
	_sells.clear()
	_backs = 0


func after_each() -> void:
	_state.free()


func _view(mode: StringName = ShopViews.MODE_BUY) -> ShopView:
	return ShopViews.build(_state, _mart, _items, mode)


func _menu_in(width: int, view: ShopView) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_shop(view)
	menu.open_animated()
	await wait_frames(3)
	menu.shop_mode_changed.connect(func(m: StringName) -> void: _modes.append(m))
	menu.shop_buy_requested.connect(func(i: StringName, q: int) -> void: _buys.append([i, q]))
	menu.shop_sell_requested.connect(
		func(i: StringName, q: int, c: bool) -> void: _sells.append([i, q, c]))
	menu.back_requested.connect(func() -> void: _backs += 1)
	return menu


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	return event


func _tap(tile: BagTile) -> void:
	var pos := tile.size * 0.5
	tile._gui_input(_mouse(true, pos))
	tile._gui_input(_mouse(false, pos))


func test_buy_view_texts_and_money() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	assert_eq(screen.get_mode(), ShopViews.MODE_BUY)
	assert_eq(screen.get_title_text(), "ACHETER")
	assert_eq(screen.get_money_text(), MenuFormat.money(3000))
	assert_eq(screen.get_cards().size(), 5, "Poké Ball, Potion et les trois remèdes du J11")
	assert_eq(screen.get_selected_id(), &"poke_ball", "première carte sélectionnée")
	assert_eq(screen.get_detail_owned(), "DANS LE SAC : 3")
	assert_eq(screen.get_card_price_text(&"potion"), MenuFormat.money(300))
	assert_eq(screen.get_total_text(), MenuFormat.money(200))
	assert_eq(menu.get_zone_pill().visible, false, "pas de pastille de zone")
	assert_true(_buys.is_empty() and _sells.is_empty(), "l'ouverture n'achète rien")


func test_tabs_emit_once_and_only_for_the_other_tab() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	_tap(screen.get_tab(ShopViews.MODE_BUY))
	assert_true(_modes.is_empty(), "l'onglet déjà ouvert ne dit rien")
	_tap(screen.get_tab(ShopViews.MODE_SELL))
	assert_eq(_modes, [ShopViews.MODE_SELL] as Array[StringName])
	menu.show_shop(_view(ShopViews.MODE_SELL))
	assert_eq(screen.get_title_text(), "VENDRE")
	assert_eq(screen.get_card_price_text(&"potion"), MenuFormat.money(150))


func test_quantity_is_bounded_and_total_follows_each_step() -> void:
	_state.money = 700
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	var stepper := screen.get_stepper()
	assert_eq(stepper.get_maximum(), 3, "700 ₽ = 3 Poké Balls")
	stepper.step(1)
	assert_eq(screen.get_quantity(), 2)
	assert_eq(screen.get_total_text(), MenuFormat.money(400))
	stepper.step(1)
	assert_eq(screen.get_total_text(), MenuFormat.money(600))
	assert_false(stepper.step(1), "au maximum, rien ne bouge")
	assert_eq(screen.get_quantity(), 3)
	stepper.step(-5)
	assert_eq(screen.get_quantity(), 1)
	assert_false(stepper.step(-1), "jamais sous 1")


func test_long_press_repeats_and_accelerates() -> void:
	var menu := await _menu_in(2340, _view())
	var stepper := menu.get_shop().get_stepper()
	stepper.press(1)
	assert_eq(stepper.get_value(), 2, "un cran tout de suite")
	stepper.advance(UiTokens.SHOP_REPEAT_DELAY - 0.01)
	assert_eq(stepper.get_value(), 2, "pas de répétition avant le délai")
	stepper.advance(0.02)
	assert_eq(stepper.get_value(), 3, "premier cran répété")
	stepper.advance(UiTokens.SHOP_REPEAT_FAST_AFTER)
	assert_gt(stepper.get_value(), 8, "ensuite par pas rapides")
	stepper.stop()
	var kept := stepper.get_value()
	stepper.advance(2.0)
	assert_eq(stepper.get_value(), kept, "relâché : plus rien")
	assert_gt(QuantityStepper.step_for(5.0), QuantityStepper.step_for(0.0))
	assert_lt(QuantityStepper.interval_for(5.0), QuantityStepper.interval_for(0.0))


func test_confirm_buy_emits_one_signal_with_quantity() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	_tap(screen.get_card(&"potion"))
	assert_eq(screen.get_quantity(), 1)
	screen.get_stepper().step(1)
	screen.get_stepper().step(1)
	screen.get_confirm_button().pressed.emit()
	assert_eq(_buys, [[&"potion", 3]])
	assert_true(_sells.is_empty())


func test_confirm_sell_asks_without_confirmation_flag() -> void:
	var menu := await _menu_in(2340, _view(ShopViews.MODE_SELL))
	var screen := menu.get_shop()
	screen.select_item(&"poke_ball")
	screen.set_quantity(2)
	screen.get_confirm_button().pressed.emit()
	assert_eq(_sells, [[&"poke_ball", 2, false]])
	assert_true(_buys.is_empty())


func test_no_money_is_visible_and_emits_nothing() -> void:
	_state.money = 50
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	assert_false(screen.is_confirm_active())
	assert_eq(screen.get_note_text(), ShopViews.TEXT_NO_MONEY)
	assert_false(screen.get_stepper().is_active())
	screen.get_confirm_button().pressed.emit()
	assert_true(_buys.is_empty(), "aucun achat")
	assert_eq(screen.get_result_bar().get_text(), ShopViews.TEXT_NO_MONEY)
	assert_true(screen.get_result_bar().visible)


func test_result_thanks_and_refusal() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	menu.show_shop_result("Merci !", true)
	assert_eq(screen.get_result_bar().get_text(), "Merci !")
	assert_eq(screen.get_result_bar().theme_type_variation, &"ResultBar", "succès sans « + »")
	menu.show_shop_result("Tu n'as pas assez d'argent.", false)
	assert_eq(screen.get_result_bar().theme_type_variation, &"ResultBarRefused")
	menu.show_shop_result("", true)
	assert_eq(screen.get_result_bar().get_text(), "Tu n'as pas assez d'argent.",
		"un texte vide n'affiche rien")


func test_refresh_keeps_selection_and_quantity_and_result() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	screen.select_item(&"potion")
	screen.set_quantity(4)
	menu.show_shop_result("Merci !", true)
	_state.money = 1800
	menu.show_shop(_view())
	assert_eq(screen.get_selected_id(), &"potion")
	assert_eq(screen.get_quantity(), 4)
	assert_eq(screen.get_money_text(), MenuFormat.money(1800))
	assert_true(screen.get_result_bar().visible, "« Merci ! » reste après le rafraîchissement")
	_state.money = 700
	menu.show_shop(_view())
	assert_eq(screen.get_quantity(), 2, "quantité reprise dans ses nouvelles bornes (700 / 300)")


func test_sell_tab_lists_only_sellable_and_empty_text() -> void:
	var menu := await _menu_in(2340, _view(ShopViews.MODE_SELL))
	assert_eq(menu.get_shop().get_cards().size(), 2)
	var empty := GameStateScript.new()
	empty.new_game(7)
	menu.show_shop(ShopViews.build(empty, _mart, _items, ShopViews.MODE_SELL))
	assert_true(menu.get_shop().get_empty_label().visible)
	assert_eq(menu.get_shop().get_empty_label().text, ShopViews.TEXT_NOTHING_TO_SELL)
	assert_false(menu.get_shop().is_detail_shown())
	empty.free()


func test_favorite_shows_star_and_text() -> void:
	_state.bag.set_favorite(&"potion", true)
	var menu := await _menu_in(2340, _view(ShopViews.MODE_SELL))
	var screen := menu.get_shop()
	screen.select_item(&"potion")
	assert_true(screen.is_favorite_pill_shown())
	assert_true(screen.get_card(&"potion").is_favorite_shown())
	assert_true("FAVORI" in screen.get_texts())


func test_swipe_over_cards_selects_nothing_and_buys_nothing() -> void:
	var menu := await _menu_in(2340, _view())
	var screen := menu.get_shop()
	var card := screen.get_cards()[1]
	var from := card.get_global_rect().get_center()
	var finger := TouchFinger.new(screen.get_viewport())
	finger.swipe(from, Vector2(0.0, -150.0))
	finger.swipe(from, Vector2(80.0, 0.0))
	await wait_process_frames(2)
	assert_eq(screen.get_selected_id(), &"poke_ball", "un glissement ne sélectionne rien")
	assert_true(_buys.is_empty() and _sells.is_empty(), "un glissement n'achète rien")
	finger.tap(card.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(screen.get_selected_id(), &"potion", "un toucher court sélectionne")
	assert_true(_buys.is_empty(), "sélectionner n'achète pas")
	assert_eq(screen.get_scroll().scroll_deadzone, roundi(UiTokens.TAP_SLOP))


func test_back_button_and_android_back() -> void:
	var menu := await _menu_in(2340, _view())
	menu.get_shop().get_back_button().pressed.emit()
	assert_eq(_backs, 1)
	assert_false(menu.shop_back(), "sans confirmation ouverte, le retour suit son cours")


func test_confirm_cards_sell_and_cancel() -> void:
	_state.bag.set_favorite(&"potion", true)
	var menu := await _menu_in(2340, _view(ShopViews.MODE_SELL))
	var view := _view(ShopViews.MODE_SELL)
	menu.show_shop_confirm(ShopViews.sell_confirm_view(view.entry(&"potion"), 2), &"potion", 2)
	var choice := menu.get_shop_choice()
	assert_true(choice.is_showing())
	assert_true(menu.shop_back(), "le retour ferme la confirmation")
	assert_false(choice.is_showing())
	assert_true(_sells.is_empty(), "retour = rien vendu")
	menu.show_shop_confirm(ShopViews.sell_confirm_view(view.entry(&"potion"), 2), &"potion", 2)
	choice.get_cancel_button().pressed.emit()
	assert_true(_sells.is_empty(), "ANNULER = rien vendu")
	menu.show_shop_confirm(ShopViews.sell_confirm_view(view.entry(&"potion"), 2), &"potion", 2)
	choice.get_confirm_button().pressed.emit()
	assert_eq(_sells, [[&"potion", 2, true]])


func test_touch_targets_and_margins() -> void:
	for width: int in WIDTHS:
		var menu := await _menu_in(width, _view())
		var screen := menu.get_shop()
		var controls := screen.get_touch_controls()
		assert_gt(controls.size(), 6)
		var scroll := screen.get_scroll()
		var scroll_rect := scroll.get_global_rect()
		assert_lte(scroll_rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5, "liste dans la marge")
		for control: Control in controls:
			var rect := control.get_global_rect()
			if scroll.is_ancestor_of(control):
				# Carte de la liste : coupée par le défilement (J11 : 5 articles), on ne
				# touche que sa partie visible.
				rect = rect.intersection(scroll_rect)
				if rect.size.y < UiTokens.TOUCH_MIN - 0.5:
					continue
			assert_gte(rect.size.y, UiTokens.TOUCH_MIN - 0.5, "zone ≥ 128 (%s)" % control.name)
			assert_gte(rect.position.x, UiTokens.SAFE_MARGIN - 0.5)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN + 0.5)
			assert_lte(rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5)
		var stepper := screen.get_stepper()
		assert_gte(stepper.get_minus_button().size.x, UiTokens.TOUCH_MIN - 0.5)
		assert_gte(stepper.get_plus_button().size.x, UiTokens.TOUCH_MIN - 0.5)


func test_large_text_and_contrast_apply_without_error() -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	settings.high_contrast = true
	UiPrefs.apply(settings)
	var menu := await _menu_in(2340, _view())
	assert_true(menu.get_shop().get_confirm_button().is_visible_in_tree())
	UiPrefs.reset()


func test_bag_and_trainer_show_money() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2340, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	var bag_view := BagQuery.view(_state.bag, _items, BagQuery.CONTEXT_FIELD,
		BagQuery.Sort.RELEVANCE, &"heal", _state.party, -1, null, 1234)
	menu.show_bag(bag_view)
	menu.open_animated()
	await wait_frames(2)
	assert_eq(menu.get_bag().get_money_text(), MenuFormat.money(1234))
	var trainer := TrainerView.new()
	trainer.player_name = "Kevin"
	trainer.money_text = MenuFormat.money(3000)
	menu.show_trainer(trainer)
	await wait_frames(2)
	var texts := menu.get_trainer().get_texts()
	assert_true("Argent : %s" % MenuFormat.money(3000) in texts, str(texts))
	trainer.money_text = ""
	menu.show_trainer(trainer)
	assert_false("Argent" in " ".join(menu.get_trainer().get_texts()), "absent sans texte")


func test_owned_permanent_item_hides_quantity_and_total() -> void:
	var shops := ShopLibrary.new()
	shops.load_dir()
	_state.bag.add(&"tm01")
	var view := ShopViews.build(_state, shops.get_shop(&"celadon_dept_2f_tm"), _items,
		ShopViews.MODE_BUY)
	var menu := await _menu_in(2340, view)
	var screen := menu.get_shop()
	assert_eq(screen.get_detail_price(), "Déjà dans le Sac")
	assert_false(screen.get_stepper().visible, "pas de sélecteur de quantité")
	assert_eq(screen.get_note_text(), "", "la ligne de prix suffit, pas de doublon")
