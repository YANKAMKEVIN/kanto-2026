extends GutTest
## Sac de combat (jalon 5D, T14, jalon-05.md §3.10 et §3.12 ; langage visuel du Sac du dossier 08
## §3) : onglets de catégories (CAPTURE ouverte d'abord), cartes d'objets, aperçu au toucher
## sans rien choisir, UN seul item_chosen avec LANCER, « ‹ » ferme sans rien émettre, catégorie
## vide ou objet inutilisable jamais affichés, zones tactiles à 1920 et 2340.

const PANEL_SCENE := "res://game/ui/battle/battle_bag_panel.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
## Abscisse jusqu'où un toucher de test atteint l'interface (le panneau de GUT couvre la
## droite du viewport et y avale les touchers) : voir _reach.
const REACHABLE_X := 800.0

var _screen: Control
var _panel: BattleBagPanel


func before_each() -> void:
	_screen = Control.new()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child_autofree(_screen)
	_panel = (load(PANEL_SCENE) as PackedScene).instantiate() as BattleBagPanel
	_screen.add_child(_panel)
	BattleHudLayout.place(_panel, BattleHudLayout.Slot.BAG)
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


func _ball(count: int = 5) -> BagEntryView:
	return BagEntryView.new(&"poke_ball", "Poké Ball", count,
		"Permet de capturer un Pokémon sauvage.", &"ball")


func _super_ball() -> BagEntryView:
	return BagEntryView.new(&"super_ball", "Super Ball", 3,
		"Une Ball plus efficace.", &"ball")


func _potion(usable: bool = true) -> BagEntryView:
	return BagEntryView.new(&"potion", "Potion", 2, "Restaure les PV.", &"heal", usable)


func _open(entries: Array[BagEntryView], start: StringName = &"ball") -> void:
	_panel.show_bag(entries, start)
	await wait_process_frames(2)


func _ball_only() -> Array[BagEntryView]:
	return [_ball()] as Array[BagEntryView]


func _three_balls() -> Array[BagEntryView]:
	return [_ball(12), _super_ball(), BagEntryView.new(&"ultra_ball", "Hyper Ball", 1,
		"Très efficace.", &"ball")] as Array[BagEntryView]


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


func _nothing_chosen() -> void:
	assert_signal_not_emitted(_panel, "item_chosen")
	assert_signal_not_emitted(_panel, "back_requested")


# --- Vues ---------------------------------------------------------------------------------


func test_entry_view_displayable_and_texts() -> void:
	assert_true(_ball().is_displayable())
	assert_eq(_ball(12).quantity_text(), "×12")
	assert_false(_ball(0).is_displayable(), "aucun exemplaire")
	assert_false(_potion(false).is_displayable(), "inutilisable")
	assert_false(BagEntryView.new().is_displayable())
	assert_eq(_ball().action_label, "LANCER", "une Ball se lance")
	assert_eq(_potion().action_label, "UTILISER")
	assert_eq(BagEntryView.category_label(&"ball"), "CAPTURE")
	assert_eq(BagEntryView.category_label(&"heal"), "SOINS")
	assert_eq(BagEntryView.icon_for(&"poke_ball"), load("res://assets/ui/items/poke_ball.webp"),
		"icône peinte (MM.1)")
	assert_eq(BagEntryView.icon_for(&"inconnu"), BagEntryView.GENERIC_ICON)


# --- Ouverture, onglets, cartes ------------------------------------------------------------


func test_hidden_at_start_and_slot_is_left_column() -> void:
	assert_false(_panel.visible)
	assert_false(_panel.is_shown())
	_set_screen(SCREEN_WIDTHS[1])
	await _open(_ball_only())
	assert_eq(_panel.get_global_rect(), BattleHudLayout.rect(BattleHudLayout.Slot.BAG,
		_screen.size))
	assert_eq(_panel.get_global_rect().position.x, float(UiTokens.SAFE_MARGIN), "colonne gauche")
	assert_true(_panel.visible)
	assert_true(_panel.get_back_button().is_shown(), "« ‹ » entre avec le panneau")


func test_opens_on_capture_with_balls_and_quantities() -> void:
	await _open(_three_balls())
	assert_eq(_panel.get_categories(), [&"ball"] as Array[StringName])
	assert_eq(_panel.get_open_category(), &"ball")
	assert_eq(_panel.get_tab(&"ball").get_name_text(), "CAPTURE")
	assert_true(_panel.get_tab(&"ball").is_selected())
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 3)
	assert_eq(cards[0].get_name_text(), "Poké Ball")
	assert_eq(cards[0].get_quantity_text(), "× 12")
	assert_eq(cards[1].get_name_text(), "Super Ball")
	assert_eq(cards[1].get_quantity_text(), "× 3")
	assert_eq(cards[0].get_icon(), BagEntryView.icon_for(&"poke_ball"), "illustration")


func test_first_card_is_previewed_at_opening() -> void:
	await _open(_three_balls())
	assert_eq(_panel.get_selected_id(), &"poke_ball")
	assert_true(_panel.get_cards()[0].is_selected())
	assert_false(_panel.get_cards()[1].is_selected())
	assert_eq(_panel.get_detail_name(), "Poké Ball")
	assert_eq(_panel.get_detail_quantity(), "×12")
	assert_eq(_panel.get_detail_text(), "Permet de capturer un Pokémon sauvage.")
	assert_eq(_panel.get_action_button().text, "LANCER")
	assert_true(_panel.get_detail().visible)
	_nothing_chosen()


## Correctif QA A17 du J30 : la description de la Guérison s'arrêtait à « d'un » (deux lignes
## au plus) ; elle s'affiche en entier, aux deux largeurs d'écran.
func test_long_heal_description_is_shown_in_full() -> void:
	var full_restore := BagEntryView.new(&"full_restore", "Guérison", 6,
		"Rend tous les PV et soigne le statut d'un Pokémon.", &"heal")
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open([full_restore] as Array[BagEntryView], &"heal")
		assert_gt(_panel.get_detail_line_count(), 2, "trois lignes à cette largeur")
		assert_eq(_panel.get_detail_visible_line_count(), _panel.get_detail_line_count(),
			"aucune ligne coupée à %d" % width)


## QA A17 du J31 : la description de l'Hyper Ball (la plus longue des Balls) s'arrêtait à
## « Elle » ; elle s'affiche en entier, aux deux largeurs d'écran.
func test_ultra_ball_description_is_shown_in_full() -> void:
	var ultra_ball := BagEntryView.new(&"ultra_ball", "Hyper Ball", 30,
		"Une Ball très performante. Elle capture mieux qu'une Super Ball.", &"ball")
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open([ultra_ball] as Array[BagEntryView], &"ball")
		assert_eq(_panel.get_detail_visible_line_count(), _panel.get_detail_line_count(),
			"aucune ligne coupée à %d" % width)


func test_empty_category_and_unusable_items_are_not_shown() -> void:
	# Potion inutilisable (jalon 5) : ni carte ni onglet SOINS ; une Ball à 0 non plus.
	await _open([_ball(), _potion(false), _ball(0)] as Array[BagEntryView])
	assert_eq(_panel.get_categories(), [&"ball"] as Array[StringName], "pas d'onglet SOINS")
	assert_null(_panel.get_tab(&"heal"))
	assert_eq(_panel.get_cards().size(), 1)
	assert_eq(_panel.get_tabs_count(), 1)


func test_two_usable_categories_give_two_tabs_and_open_on_the_asked_one() -> void:
	var entries: Array[BagEntryView] = [_potion(), _ball()]
	await _open(entries, &"ball")
	assert_eq(_panel.get_categories(), [&"heal", &"ball"] as Array[StringName])
	assert_eq(_panel.get_open_category(), &"ball", "s'ouvre sur CAPTURE")
	assert_true(_panel.get_tab(&"ball").is_selected())
	assert_false(_panel.get_tab(&"heal").is_selected())
	await _open(entries, &"absente")
	assert_eq(_panel.get_open_category(), &"heal", "catégorie inconnue : la première")


func test_nothing_usable_shows_a_sentence_and_no_button() -> void:
	await _open([_potion(false)] as Array[BagEntryView])
	assert_eq(_panel.get_open_category(), &"")
	assert_true(_panel.get_empty_label().visible)
	assert_eq(_panel.get_empty_label().text, BattleBagPanel.EMPTY_TEXT)
	assert_false(_panel.get_detail().visible, "pas d'action")
	assert_false(_panel.get_scroll().visible)
	assert_true(_panel.get_back_button().is_shown(), "« ‹ » reste")
	_panel.get_action_button().pressed.emit()
	_nothing_chosen()


func test_tab_touch_opens_category_without_choosing() -> void:
	await _open([_ball(), _potion()] as Array[BagEntryView])
	await _tap(_reach(_panel.get_tab(&"heal")))
	assert_eq(_panel.get_open_category(), &"heal")
	assert_eq(_panel.get_cards().size(), 1)
	assert_eq(_panel.get_selected_id(), &"potion", "première carte de la catégorie aperçue")
	assert_eq(_panel.get_action_button().text, "UTILISER")
	assert_signal_emitted_with_parameters(_panel, "category_opened", [&"heal"])
	_nothing_chosen()


# --- Aperçu et choix -----------------------------------------------------------------------


func test_card_touch_previews_without_emitting_a_choice() -> void:
	await _open(_three_balls())
	await _tap(_reach(_panel.get_cards()[1]))
	assert_eq(_panel.get_selected_id(), &"super_ball")
	assert_true(_panel.get_cards()[1].is_selected())
	assert_false(_panel.get_cards()[0].is_selected())
	assert_eq(_panel.get_detail_name(), "Super Ball")
	assert_eq(_panel.get_detail_quantity(), "×3")
	assert_signal_emit_count(_panel, "item_previewed", 1)
	assert_signal_emitted_with_parameters(_panel, "item_previewed", [&"super_ball"])
	_nothing_chosen()
	assert_false(_panel.is_answered())


func test_touching_a_card_twice_still_does_not_choose() -> void:
	await _open(_three_balls())
	var card := _panel.get_cards()[1]
	await _tap(_reach(card))
	await _tap(_reach(card))
	_nothing_chosen()
	assert_eq(_panel.get_selected_id(), &"super_ball")


func test_sliding_finger_is_not_a_touch() -> void:
	await _open(_three_balls())
	var center := _reach(_panel.get_cards()[1])
	await _press(center, true)
	await _press(center + Vector2(0, UiTokens.BAG_TAP_SLOP * 3.0), false)
	assert_eq(_panel.get_selected_id(), &"poke_ball", "défilement, pas un toucher")
	assert_signal_not_emitted(_panel, "item_previewed")


func test_action_emits_exactly_one_item_chosen_then_closes() -> void:
	await _open(_three_balls())
	_panel.select_item(&"super_ball")
	_panel.get_action_button().pressed.emit()
	_panel.get_action_button().pressed.emit()
	await wait_process_frames(2)
	assert_signal_emit_count(_panel, "item_chosen", 1)
	assert_signal_emitted_with_parameters(_panel, "item_chosen", [&"super_ball"])
	assert_signal_not_emitted(_panel, "back_requested")
	assert_true(_panel.is_answered())
	assert_false(_panel.is_shown(), "le panneau se ferme")
	assert_false(_panel.visible)
	# Fermé et muet : ni carte ni « ‹ » n'émettent plus rien.
	_panel.get_back_button().get_button().pressed.emit()
	assert_signal_not_emitted(_panel, "back_requested")


func test_selection_by_api_emits_nothing() -> void:
	await _open(_three_balls())
	_panel.select_item(&"super_ball")
	_panel.open_category(&"ball")
	assert_signal_not_emitted(_panel, "item_previewed")
	assert_signal_not_emitted(_panel, "category_opened")
	_nothing_chosen()


func test_back_closes_without_choosing() -> void:
	await _open(_three_balls())
	_panel.get_back_button().get_button().pressed.emit()
	await wait_process_frames(2)
	assert_signal_emit_count(_panel, "back_requested", 1)
	assert_signal_not_emitted(_panel, "item_chosen")
	assert_true(_panel.is_answered())
	assert_false(_panel.is_shown())
	# Après « ‹ », LANCER ne répond plus.
	_panel.get_action_button().pressed.emit()
	assert_signal_not_emitted(_panel, "item_chosen")


func test_back_by_touch_on_the_round_button() -> void:
	await _open(_ball_only())
	await _tap(_reach(_panel.get_back_button().get_button()))
	assert_signal_emit_count(_panel, "back_requested", 1)
	assert_signal_not_emitted(_panel, "item_chosen")


func test_cancel_key_acts_as_back() -> void:
	await _open(_ball_only())
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_signal_emit_count(_panel, "back_requested", 1)
	assert_signal_not_emitted(_panel, "item_chosen")


func test_reopening_rearms_the_panel() -> void:
	await _open(_ball_only())
	_panel.get_action_button().pressed.emit()
	await wait_process_frames(2)
	await _open(_ball_only())
	assert_false(_panel.is_answered())
	assert_true(_panel.is_shown())
	_panel.get_action_button().pressed.emit()
	assert_signal_emit_count(_panel, "item_chosen", 2)


func test_keyboard_selection_then_accept() -> void:
	await _open(_three_balls())
	var right := InputEventAction.new()
	right.action = &"ui_down"
	right.pressed = true
	Input.parse_input_event(right)
	await wait_process_frames(2)
	assert_eq(_panel.get_selected_id(), &"super_ball")
	_nothing_chosen()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(_panel, "item_chosen", [&"super_ball"])


# --- Haptique, tailles, placement ------------------------------------------------------------


func test_haptics_tick_on_selection_and_tap_on_action() -> void:
	watch_signals(_panel)
	await _open(_three_balls())
	_panel.get_cards()[1].tapped.emit()
	assert_signal_emitted_with_parameters(_panel, "haptic_played", [UiTokens.HAPTIC_TICK_MS])
	_panel.get_action_button().pressed.emit()
	assert_signal_emitted_with_parameters(_panel, "haptic_played", [UiTokens.HAPTIC_TAP_MS])


func test_touch_zones_at_least_touch_min_and_inside_margins() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open([_ball(), _super_ball(), _potion()] as Array[BagEntryView])
		var view := Rect2(Vector2.ZERO, _screen.size)
		var safe := view.grow(-float(UiTokens.SAFE_MARGIN))
		var zones: Array[Control] = [_panel.get_action_button(), _panel.get_back_button().get_button()]
		for card: BattleBagRow in _panel.get_cards():
			zones.append(card)
		for id: StringName in _panel.get_categories():
			zones.append(_panel.get_tab(id))
		for zone: Control in zones:
			var rect := zone.get_global_rect()
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "%s : largeur de %s" % [width, zone.name])
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN), "%s : hauteur de %s" % [width, zone.name])
			assert_true(safe.encloses(rect), "%s : %s dans les marges (%s)" % [width, zone.name, rect])
		assert_true(safe.encloses(_panel.get_frame_rect()), "%s : cadre dans les marges" % width)


func test_panel_leaves_the_foe_visible() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open(_three_balls())
		var foe := BattleLayout.max_rect(false, _screen.size)
		assert_false(_panel.get_frame_rect().intersects(foe), "%s : l'adversaire reste visible" % width)


func test_many_items_make_the_list_scroll_within_the_cap() -> void:
	var many: Array[BagEntryView] = []
	for i: int in 12:
		many.append(BagEntryView.new(StringName("ball_%d" % i), "Ball %d" % i, 1, "x", &"ball"))
	await _open(many)
	assert_lte(_panel.get_scroll().custom_minimum_size.y,
		UiTokens.BAG_GRID_MAX_HEIGHT + UiTokens.BAG_SCROLL_PAD * 2.0)
	assert_eq(_panel.get_cards().size(), 12)
	assert_lte(_panel.get_frame_rect().size.y, float(UiTokens.BAG_FRAME_MAX_HEIGHT))


func test_styles_come_from_the_theme() -> void:
	await _open(_three_balls())
	var selected := _panel.get_cards()[0].get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(selected.border_color, UiTokens.ACCENT, "carte sélectionnée : liseré d'accent")
	assert_eq(selected.border_width_left, UiTokens.MOVE_CARD_SELECTED_BORDER)
	var other := _panel.get_cards()[1].get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(other.border_color, UiTokens.PANEL_BORDER)
	await wait_seconds(UiTokens.ANIM_MICRO + 0.15)
	assert_almost_eq(_panel.get_cards()[0].scale.x, 1.0, 0.01, "rangée : pas de grossissement")
	assert_almost_eq(_panel.get_cards()[1].scale.x, 1.0, 0.01)


func test_rows_show_arrow_only_on_the_selected_one_and_fill_the_width() -> void:
	await _open(_three_balls())
	var rows := _panel.get_cards()
	assert_eq(rows.size(), 3)
	for i: int in rows.size():
		assert_eq(rows[i].is_selected(), i == 0)
	assert_gt(rows[0].size.x, rows[0].size.y * 4.0, "une rangée, pas une tuile")
	assert_almost_eq(rows[0].size.x, rows[1].size.x, 0.5)
	assert_gt(rows[1].global_position.y, rows[0].global_position.y, "empilées")
	assert_eq(rows[0].global_position.x, rows[1].global_position.x)
