extends GutTest
## Panneau d'oubli d'une capacité (jalon 5C, T10, jalon-05.md §3.9 et §3.12, Q29 et Q30) :
## 5 cartes (la nouvelle en haut, les 4 connues en dessous), un toucher SÉLECTIONNE sans rien
## émettre, OUBLIER inactif tant que rien n'est choisi puis un seul forget_chosen(slot), NE PAS
## APPRENDRE un seul skip_chosen, pression longue = fiche sans sélection, zones tactiles à
## 1920 et 2340.

const PANEL_SCENE := "res://game/ui/battle/move_forget_panel.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
## Abscisse jusqu'où un toucher de test atteint l'interface (le panneau de GUT couvre la
## droite du viewport et y avale les touchers) : voir _reach.
const REACHABLE_X := 800.0

var _screen: Control
var _panel: MoveForgetPanel


func before_each() -> void:
	_screen = Control.new()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child_autofree(_screen)
	_panel = (load(PANEL_SCENE) as PackedScene).instantiate() as MoveForgetPanel
	_screen.add_child(_panel)
	BattleHudLayout.place(_panel, BattleHudLayout.Slot.FORGET)
	_panel.haptics_enabled = false
	_panel.speed_scale = 0.0
	_set_screen(SCREEN_WIDTHS[0])
	watch_signals(_panel)


func after_each() -> void:
	# Aucun doigt ne reste posé d'un test à l'autre.
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	get_viewport().push_input(mouse, true)


func _set_screen(width: float) -> void:
	_screen.position = Vector2.ZERO
	_screen.size = Vector2(width, SCREEN_HEIGHT)


func _new_move() -> BattleMoveView:
	return BattleMoveView.new("Frénésie", &"normal", "Normal", BattleMoveView.Category.PHYSICAL,
		20, 20, 20, 100, "Une attaque sauvage qui devient plus forte à chaque tour.")


func _known() -> Array[BattleMoveView]:
	return [
		BattleMoveView.new("Griffe", &"normal", "Normal", BattleMoveView.Category.PHYSICAL,
			35, 35, 40, 100, "Lacère la cible avec des griffes acérées."),
		BattleMoveView.new("Rugissement", &"normal", "Normal", BattleMoveView.Category.STATUS,
			40, 40, 0, 100, "Baisse l'Attaque de la cible."),
		BattleMoveView.new("Flammèche", &"fire", "Feu", BattleMoveView.Category.SPECIAL,
			25, 25, 40, 100, "Une petite flamme qui peut brûler."),
		# Sans PP : on peut tout de même l'oublier.
		BattleMoveView.new("Mimi-Queue", &"normal", "Normal", BattleMoveView.Category.STATUS,
			0, 30, 0, 100, "Baisse la Défense de la cible."),
	] as Array[BattleMoveView]


func _open() -> void:
	_panel.show_offer(_new_move(), _known())
	await wait_process_frames(2)


## Appui ou relâchement comme sur le téléphone : écran tactile puis souris émulée.
func _press(position: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = position
	touch.pressed = pressed
	get_viewport().push_input(touch, true)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = position
	mouse.global_position = position
	mouse.pressed = pressed
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(mouse, true)
	await wait_process_frames(1)


func _tap(position: Vector2) -> void:
	await _press(position, true)
	await _press(position, false)


## Centre de [param control] une fois l'écran décalé pour l'amener à gauche.
func _reach(control: Control) -> Vector2:
	_screen.position.x = 0.0
	var center := control.get_global_rect().get_center()
	if center.x > REACHABLE_X:
		_screen.position.x = REACHABLE_X - center.x
	return control.get_global_rect().get_center()


func _card_center(slot: int) -> Vector2:
	return _reach(_panel.get_card(slot))


func _no_choice_emitted() -> void:
	assert_signal_not_emitted(_panel, "forget_chosen")
	assert_signal_not_emitted(_panel, "skip_chosen")


func test_hidden_at_start_and_layer_slot_is_bottom_right() -> void:
	assert_false(_panel.visible)
	assert_false(_panel.is_shown())
	_set_screen(SCREEN_WIDTHS[1])
	await _open()
	assert_eq(_panel.get_global_rect(),
		BattleHudLayout.rect(BattleHudLayout.Slot.FORGET, _screen.size))
	assert_eq(_panel.get_global_rect().size, BattleHudLayout.forget_size())


func test_five_cards_new_one_on_top_four_below() -> void:
	await _open()
	assert_eq(_panel.find_children("*", "MoveCard", true, false).size(), 5, "5 cartes")
	assert_eq(_panel.get_new_card().get_name_text(), "FRÉNÉSIE")
	var names: Array[String] = []
	for slot: int in MoveForgetPanel.SLOTS:
		names.append(_panel.get_card(slot).get_name_text())
	assert_eq(names, ["GRIFFE", "RUGISSEMENT", "FLAMMÈCHE", "MIMI-QUEUE"] as Array[String])
	var top := _panel.get_new_card().get_global_rect()
	for slot: int in MoveForgetPanel.SLOTS:
		var rect := _panel.get_card(slot).get_global_rect()
		assert_gte(rect.position.y, top.end.y, "carte %d sous la nouvelle capacité" % slot)
	var cards: Array[Rect2] = []
	for slot: int in MoveForgetPanel.SLOTS:
		cards.append(_panel.get_card(slot).get_global_rect())
	assert_eq(cards[0].position.y, cards[1].position.y, "2 × 2 : ligne du haut")
	assert_eq(cards[2].position.y, cards[3].position.y, "2 × 2 : ligne du bas")
	assert_gt(cards[2].position.y, cards[0].end.y)
	assert_gt(cards[1].position.x, cards[0].end.x)


func test_nothing_selected_and_confirm_disabled_at_opening() -> void:
	await _open()
	assert_eq(_panel.get_selected(), -1)
	assert_true(_panel.get_confirm_button().disabled, "OUBLIER inactif")
	assert_false(_panel.get_skip_button().disabled, "NE PAS APPRENDRE actif")
	assert_eq(_panel.get_confirm_button().text, "OUBLIER")
	assert_eq(_panel.get_skip_button().text, "NE PAS APPRENDRE")
	for slot: int in MoveForgetPanel.SLOTS:
		assert_false(_panel.get_card(slot).is_selected())


func test_confirm_with_nothing_selected_is_mute() -> void:
	await _open()
	await _tap(_reach(_panel.get_confirm_button()))
	_no_choice_emitted()
	assert_true(_panel.is_shown(), "le panneau reste ouvert")


func test_tap_selects_without_emitting_anything() -> void:
	await _open()
	await _tap(_card_center(1))
	assert_eq(_panel.get_selected(), 1)
	assert_true(_panel.get_card(1).is_selected(), "liseré d'accent")
	assert_false(_panel.get_confirm_button().disabled, "OUBLIER s'active")
	_no_choice_emitted()
	assert_true(_panel.is_shown(), "pas de fenêtre de confirmation ni de fermeture")


func test_tap_on_another_card_moves_the_selection() -> void:
	await _open()
	await _tap(_card_center(0))
	await _tap(_card_center(2))
	assert_eq(_panel.get_selected(), 2)
	assert_false(_panel.get_card(0).is_selected())
	assert_true(_panel.get_card(2).is_selected())
	_no_choice_emitted()


func test_card_without_pp_can_be_selected() -> void:
	await _open()
	assert_true(_panel.get_card(3).is_usable())
	await _tap(_card_center(3))
	assert_eq(_panel.get_selected(), 3)
	assert_eq(_panel.get_card(3).modulate, UiTokens.MODULATE_FULL, "pas atténuée")


func test_tap_on_the_new_move_does_nothing() -> void:
	await _open()
	await _tap(_reach(_panel.get_new_card()))
	assert_eq(_panel.get_selected(), -1)
	assert_false(_panel.get_new_card().is_selected())
	_no_choice_emitted()
	await _tap(_card_center(0))
	await _tap(_reach(_panel.get_new_card()))
	assert_eq(_panel.get_selected(), 0, "la sélection reste")


func test_forget_emits_exactly_one_forget_chosen_with_the_slot() -> void:
	await _open()
	await _tap(_card_center(2))
	await _tap(_reach(_panel.get_confirm_button()))
	assert_signal_emit_count(_panel, "forget_chosen", 1)
	assert_signal_emitted_with_parameters(_panel, "forget_chosen", [2])
	assert_signal_not_emitted(_panel, "skip_chosen")
	assert_true(_panel.is_answered())
	# Rien de plus, même en retouchant partout.
	await _tap(_reach(_panel.get_confirm_button()))
	await _tap(_card_center(2))
	await _tap(_reach(_panel.get_skip_button()))
	assert_signal_emit_count(_panel, "forget_chosen", 1)
	assert_signal_not_emitted(_panel, "skip_chosen")
	assert_signal_emitted_with_parameters(_panel, "haptic_played", [UiTokens.HAPTIC_TAP_MS])


func test_skip_emits_exactly_one_skip_chosen() -> void:
	await _open()
	await _tap(_reach(_panel.get_skip_button()))
	await _tap(_reach(_panel.get_skip_button()))
	assert_signal_emit_count(_panel, "skip_chosen", 1)
	assert_signal_not_emitted(_panel, "forget_chosen")
	assert_true(_panel.is_answered())


func test_skip_works_even_with_a_selection() -> void:
	await _open()
	await _tap(_card_center(0))
	await _tap(_reach(_panel.get_skip_button()))
	assert_signal_emit_count(_panel, "skip_chosen", 1)
	assert_signal_not_emitted(_panel, "forget_chosen")


func test_panel_closes_after_a_choice_and_is_rearmed_by_show_offer() -> void:
	await _open()
	await _tap(_card_center(1))
	await _tap(_reach(_panel.get_confirm_button()))
	await wait_process_frames(2)
	assert_false(_panel.visible, "il se ferme")
	await _open()
	assert_eq(_panel.get_selected(), -1, "sélection effacée")
	assert_true(_panel.get_confirm_button().disabled)
	assert_false(_panel.is_answered())
	await _tap(_reach(_panel.get_skip_button()))
	assert_signal_emit_count(_panel, "skip_chosen", 1, "il répond de nouveau")


func test_long_press_opens_the_sheet_without_selecting_or_emitting() -> void:
	await _open()
	var center := _card_center(2)
	await _press(center, true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	assert_true(_panel.is_details_open(), "fiche ouverte")
	assert_true(_panel.get_detail_sheet().visible)
	assert_eq(_panel.get_detail_sheet().get_name_text(), "FLAMMÈCHE")
	assert_signal_emitted_with_parameters(_panel, "details_opened", [2])
	assert_eq(_panel.get_selected(), -1, "pas sélectionnée")
	await _press(center, false)
	await wait_process_frames(2)
	assert_false(_panel.is_details_open(), "fermée au relâchement")
	assert_signal_emit_count(_panel, "details_closed", 1)
	assert_eq(_panel.get_selected(), -1, "toujours rien de choisi")
	assert_true(_panel.get_confirm_button().disabled)
	_no_choice_emitted()


func test_long_press_keeps_the_current_selection() -> void:
	await _open()
	await _tap(_card_center(0))
	var center := _card_center(3)
	await _press(center, true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	await _press(center, false)
	await wait_process_frames(2)
	assert_eq(_panel.get_selected(), 0, "la sélection n'a pas bougé")
	_no_choice_emitted()


func test_long_press_on_the_new_move_opens_its_sheet() -> void:
	await _open()
	var center := _reach(_panel.get_new_card())
	await _press(center, true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	assert_true(_panel.is_details_open())
	assert_eq(_panel.get_detail_sheet().get_name_text(), "FRÉNÉSIE")
	assert_signal_emitted_with_parameters(_panel, "details_opened", [MoveForgetPanel.NEW_SLOT])
	await _press(center, false)
	assert_eq(_panel.get_selected(), -1)
	_no_choice_emitted()


func test_keyboard_selects_then_confirms() -> void:
	await _open()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await wait_process_frames(2)
	_no_choice_emitted()
	_panel.select(1)
	assert_eq(_panel.get_selected(), 1)
	Input.parse_input_event(accept)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(_panel, "forget_chosen", [1])


func test_invalid_offer_refused() -> void:
	_panel.show_offer(BattleMoveView.new(), _known())
	assert_push_error("offre invalide")
	assert_false(_panel.visible)
	_panel.show_offer(_new_move(), [] as Array[BattleMoveView])
	assert_push_error("offre invalide")
	var broken: Array[BattleMoveView] = [BattleMoveView.new()]
	_panel.show_offer(_new_move(), broken)
	assert_push_error("capacité connue invalide")
	assert_false(_panel.visible)


func test_touch_zones_min_size_inside_safe_margin() -> void:
	for width: float in SCREEN_WIDTHS:
		var size := Vector2(width, SCREEN_HEIGHT)
		_set_screen(width)
		await _open()
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		var zones: Array[Control] = [_panel.get_new_card(), _panel.get_confirm_button(),
			_panel.get_skip_button()]
		for slot: int in MoveForgetPanel.SLOTS:
			zones.append(_panel.get_card(slot))
		for zone: Control in zones:
			var rect := zone.get_global_rect()
			assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
				"%s ≥ TOUCH_MIN à %d (%s)" % [zone.name, width, rect.size])
			assert_true(safe.encloses(rect), "%s dans SAFE_MARGIN à %d" % [zone.name, width])
		# Les zones ne se chevauchent pas.
		for i: int in zones.size():
			for j: int in range(i + 1, zones.size()):
				assert_false(zones[i].get_global_rect().intersects(zones[j].get_global_rect()),
					"%s / %s se chevauchent à %d" % [zones[i].name, zones[j].name, width])
		# Le contenu tient dans le panneau, qui ne touche ni la carte joueur ni l'adversaire.
		var panel := _panel.get_global_rect()
		for zone: Control in zones:
			assert_true(panel.encloses(zone.get_global_rect()), "%s dans le panneau" % zone.name)
		for slot: BattleHudLayout.Slot in [BattleHudLayout.Slot.OWN_CARD,
				BattleHudLayout.Slot.FOE_CARD, BattleHudLayout.Slot.BACK]:
			assert_false(panel.intersects(BattleHudLayout.rect(slot, size)),
				"panneau sur l'emplacement %d à %d" % [slot, width])
		_panel.get_detail_sheet().speed_scale = 0.0
		await _panel.slide_out()


func test_sheet_stays_inside_the_panel_horizontally() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open()
		_panel.get_detail_sheet().open(_new_move())
		await wait_process_frames(2)
		var sheet := _panel.get_detail_sheet().get_global_rect()
		var panel := _panel.get_global_rect()
		assert_true(sheet.position.x >= panel.position.x and sheet.end.x <= panel.end.x,
			"fiche dans le panneau à %d" % width)
		assert_gte(sheet.position.y, panel.position.y)
		await _panel.slide_out()
