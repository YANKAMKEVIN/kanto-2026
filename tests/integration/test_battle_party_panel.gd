extends GutTest
## Panneau ÉQUIPE du combat (jalon 7, jalon-07.md §15.23 ; dossier 05 §14) : une carte par
## Pokémon (type, nom, Nv., PV, « ACTIF », « K.O. » et sa raison), la première carte envoyable
## sélectionnée, un toucher sélectionne sans rien envoyer, un refus tremble et écrit sa raison,
## UN seul pokemon_chosen avec ENVOYER, « ‹ » ferme sans rien choisir ; après un K.O. (forcé),
## ni « ‹ » ni Échap ; zones tactiles à 1920 et 2340 ; l'adversaire reste visible.

const PANEL_SCENE := "res://game/ui/battle/battle_party_panel.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
## Abscisse jusqu'où un toucher de test atteint l'interface (le panneau de GUT couvre la
## droite du viewport) : voir _reach.
const REACHABLE_X := 800.0
const FAINTED_REASON := "Ne peut plus combattre"
const ACTIVE_REASON := "Déjà au combat"

var _screen: Control
var _panel: BattlePartyPanel


func before_each() -> void:
	_screen = Control.new()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child_autofree(_screen)
	_panel = (load(PANEL_SCENE) as PackedScene).instantiate() as BattlePartyPanel
	_screen.add_child(_panel)
	BattleHudLayout.place(_panel, BattleHudLayout.Slot.PARTY)
	_panel.haptics_enabled = false
	_panel.speed_scale = 0.0
	_set_screen(SCREEN_WIDTHS[0])
	watch_signals(_panel)


func after_each() -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	get_viewport().push_input(mouse, true)


func _set_screen(width: float) -> void:
	_screen.position = Vector2.ZERO
	_screen.size = Vector2(width, SCREEN_HEIGHT)


func _view(index: int, name: String, types: Array[StringName], hp: int, max_hp: int,
		active: bool = false) -> BattlePartyView:
	var view := BattlePartyView.new()
	view.party_index = index
	view.display_name = name
	view.species_id = StringName(name.to_lower())
	view.level = 5 + index
	view.hp = hp
	view.max_hp = max_hp
	view.type_ids = types
	view.active = active
	view.status_text = "K.O." if hp == 0 else ""
	view.can_send = hp > 0 and not active
	if active:
		view.reason = ACTIVE_REASON
	elif hp == 0:
		view.reason = FAINTED_REASON
	return view


## Salamèche (actif), Roucool (K.O.), Carapuce, Bulbizarre.
func _team(active_fainted: bool = false) -> Array[BattlePartyView]:
	var lead := _view(0, "Salamèche", [&"fire"] as Array[StringName], 0 if active_fainted
		else 12, 20, not active_fainted)
	return [
		lead,
		_view(1, "Roucool", [&"normal", &"flying"] as Array[StringName], 0, 16),
		_view(2, "Carapuce", [&"water"] as Array[StringName], 19, 19),
		_view(3, "Bulbizarre", [&"grass", &"poison"] as Array[StringName], 7, 19),
	]


func _open(views: Array[BattlePartyView], forced: bool = false) -> void:
	_panel.show_party(views, forced, "Qui envoyer au combat ?")
	await wait_process_frames(2)


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
	assert_signal_not_emitted(_panel, "pokemon_chosen")
	assert_signal_not_emitted(_panel, "back_requested")


# --- Contenu ------------------------------------------------------------------------------

func test_hidden_at_start_and_slot_is_left_column() -> void:
	assert_false(_panel.visible)
	assert_false(_panel.is_shown())
	var rect := BattleHudLayout.rect(BattleHudLayout.Slot.PARTY, _screen.size)
	assert_eq(rect.position.x, float(UiTokens.BATTLE_EDGE), "colonne de gauche")
	assert_eq(rect.end.y, SCREEN_HEIGHT - UiTokens.BATTLE_EDGE, "posé sur le bord bas")


func test_one_card_per_pokemon_with_types_tags_and_reasons() -> void:
	await _open(_team())
	assert_true(_panel.is_shown())
	assert_eq(_panel.get_title_text(), "ÉQUIPE")
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 4, "toute l'équipe, dans l'ordre")
	assert_eq(cards[0].get_name_text(), "Salamèche")
	assert_eq(cards[0].get_level_text(), "Nv. 5")
	assert_eq(cards[0].get_hp_text(), "12 / 20")
	assert_eq(cards[0].get_tag_text(), "ACTIF")
	assert_eq(cards[0].get_reason_text(), "", "« ACTIF » suffit")
	assert_eq(cards[0].get_type_count(), 1)
	assert_eq(cards[1].get_tag_text(), "K.O.")
	assert_eq(cards[1].get_reason_text(), FAINTED_REASON, "K.O. : la raison en toutes lettres")
	assert_eq(cards[1].get_type_count(), 2)
	assert_lt(cards[1].get_child(0).get_child(0).modulate.a, 1.0, "K.O. atténué")
	assert_eq(cards[2].get_tag_text(), "")
	assert_eq(cards[2].get_reason_text(), "")
	assert_eq(cards[3].get_hp_text(), "7 / 19")


func test_the_first_sendable_pokemon_is_selected_at_opening() -> void:
	await _open(_team())
	assert_eq(_panel.get_selected_index(), 2, "Carapuce : ni l'actif, ni le K.O.")
	assert_true(_panel.get_cards()[2].is_selected())
	assert_true(_panel.get_send_button().visible)
	assert_eq(_panel.get_send_button().text, "ENVOYER")
	assert_true(_panel.get_footer_text().begins_with("Carapuce"))
	_nothing_chosen()


# --- Gestes -------------------------------------------------------------------------------

func test_touching_a_card_selects_without_sending() -> void:
	await _open(_team())
	await _tap(_reach(_panel.get_cards()[3]))
	assert_eq(_panel.get_selected_index(), 3)
	assert_signal_emit_count(_panel, "pokemon_selected", 1)
	assert_signal_emitted_with_parameters(_panel, "pokemon_selected", [3])
	assert_true(_panel.get_footer_text().begins_with("Bulbizarre"))
	_nothing_chosen()


func test_touching_a_fainted_or_the_active_card_refuses_with_the_reason() -> void:
	await _open(_team())
	await _tap(_reach(_panel.get_cards()[1]))
	assert_signal_emitted_with_parameters(_panel, "pokemon_refused", [1, FAINTED_REASON])
	assert_eq(_panel.get_footer_text(), "Roucool : %s" % FAINTED_REASON)
	assert_eq(_panel.get_selected_index(), 2, "la sélection ne change pas")
	await _tap(_reach(_panel.get_cards()[0]))
	assert_signal_emitted_with_parameters(_panel, "pokemon_refused", [0, ACTIVE_REASON])
	assert_signal_not_emitted(_panel, "pokemon_selected")
	_nothing_chosen()


func test_send_emits_exactly_one_choice_then_closes() -> void:
	await _open(_team())
	_panel.select(3)
	_panel.get_send_button().pressed.emit()
	_panel.get_send_button().pressed.emit()
	await wait_process_frames(2)
	assert_signal_emit_count(_panel, "pokemon_chosen", 1)
	assert_signal_emitted_with_parameters(_panel, "pokemon_chosen", [3])
	assert_signal_not_emitted(_panel, "back_requested")
	assert_true(_panel.is_answered())
	assert_false(_panel.is_shown(), "le panneau se ferme")


func test_select_by_api_ignores_unsendable_and_emits_nothing() -> void:
	await _open(_team())
	_panel.select(1)
	_panel.select(0)
	assert_eq(_panel.get_selected_index(), 2)
	_panel.select(3)
	assert_eq(_panel.get_selected_index(), 3)
	assert_signal_not_emitted(_panel, "pokemon_selected")
	_nothing_chosen()


func test_back_closes_without_choosing() -> void:
	await _open(_team())
	assert_true(_panel.get_back_button().is_shown())
	await _tap(_reach(_panel.get_back_button().get_button()))
	await wait_process_frames(2)
	assert_signal_emit_count(_panel, "back_requested", 1)
	assert_signal_not_emitted(_panel, "pokemon_chosen")
	assert_false(_panel.is_shown())
	_panel.get_send_button().pressed.emit()
	assert_signal_not_emitted(_panel, "pokemon_chosen")


func test_forced_choice_after_a_knock_out_has_no_way_back() -> void:
	await _open(_team(true), true)
	assert_true(_panel.is_forced())
	assert_eq(_panel.get_title_text(), "Qui envoyer au combat ?")
	assert_false(_panel.get_back_button().is_shown(), "pas de « ‹ » après un K.O.")
	assert_eq(_panel.get_cards()[0].get_tag_text(), "K.O.", "l'actif K.O. n'est plus ACTIF")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await wait_process_frames(2)
	_panel.get_back_button().back_requested.emit()
	assert_signal_not_emitted(_panel, "back_requested")
	assert_true(_panel.is_shown())
	_panel.get_send_button().pressed.emit()
	assert_signal_emitted_with_parameters(_panel, "pokemon_chosen", [2])


func test_reopening_rearms_the_panel() -> void:
	await _open(_team())
	_panel.get_send_button().pressed.emit()
	await wait_process_frames(2)
	await _open(_team())
	assert_false(_panel.is_answered())
	assert_true(_panel.is_shown())
	_panel.get_send_button().pressed.emit()
	assert_signal_emit_count(_panel, "pokemon_chosen", 2)


func test_keyboard_selection_then_accept() -> void:
	await _open(_team())
	var down := InputEventAction.new()
	down.action = &"ui_right"
	down.pressed = true
	Input.parse_input_event(down)
	await wait_process_frames(2)
	assert_eq(_panel.get_selected_index(), 3)
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(_panel, "pokemon_chosen", [3])


# --- Mise en page -------------------------------------------------------------------------

func test_touch_zones_at_least_touch_min_and_inside_margins() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open(_team())
		var view := Rect2(Vector2.ZERO, _screen.size)
		var safe := view.grow(-float(UiTokens.SAFE_MARGIN))
		var zones: Array[Control] = [_panel.get_send_button(),
			_panel.get_back_button().get_button()]
		for card: BattlePartyCard in _panel.get_cards():
			zones.append(card)
		for zone: Control in zones:
			var rect := zone.get_global_rect()
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "%s : largeur" % width)
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN), "%s : hauteur" % width)
			assert_true(safe.encloses(rect), "%s : dans les marges (%s)" % [width, rect])
		var frame := _panel.get_frame_rect()
		assert_true(safe.encloses(frame), "%s : cadre dans les marges (%s)" % [width, frame])
		var slot := BattleHudLayout.rect(BattleHudLayout.Slot.PARTY, _screen.size)
		assert_true(slot.grow(1.0).encloses(frame), "%s : cadre dans son emplacement" % width)


func test_six_pokemon_fit_without_scrolling() -> void:
	var six: Array[BattlePartyView] = []
	for i: int in 6:
		six.append(_view(i, "Pokémon %d" % i, [&"normal"] as Array[StringName], 10, 20, i == 0))
	await _open(six)
	assert_eq(_panel.get_cards().size(), 6)
	var frame := _panel.get_frame_rect()
	for card: BattlePartyCard in _panel.get_cards():
		assert_true(frame.encloses(card.get_global_rect()), "carte dans le cadre")
	assert_lte(frame.size.y, float(UiTokens.BAG_FRAME_MAX_HEIGHT))


func test_panel_leaves_the_foe_visible() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _open(_team())
		# Cadrage B (2026-10-25) : la boîte maximale de l'adversaire s'élargit (0,70) ; à 1920 de
		# large (plus étroit que le S24), le panneau peut en couvrir le bord gauche, jamais plus
		# de 15 % ni ses pieds ; au format du S24, rien.
		var foe := BattleLayout.max_rect(false, _screen.size)
		var frame := _panel.get_frame_rect()
		var covered := frame.intersection(foe).size.x if frame.intersects(foe) else 0.0
		assert_lte(covered, foe.size.x * (0.15 if width < 2340.0 else 0.0),
			"%s : l'adversaire reste visible" % width)
		assert_false(frame.has_point(BattleLayout.anchors(_screen.size)["foe_feet"]),
			"%s : pieds de l'adversaire visibles" % width)
