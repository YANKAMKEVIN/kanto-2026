extends GutTest
## Interface de combat assemblée (jalon 4B, T7, jalon-04.md §14.11) : BattleHud. Cartes (nom,
## ♂/♀, « Nv. 5 », PV chiffrés du joueur seulement), 6 pastilles dont 1 pleine, grille
## (ATTAQUER mis en avant, SAC / ÉQUIPE / FUITE atténués et muets), un toucher = un signal,
## capacités et « ‹ », pression longue = fiche sans move_selected, message (tenue ou toucher),
## une seule zone visible à la fois, PV animés, hide_all, zones tactiles à 1920 et 2340.

const HUD_SCENE := "res://game/ui/battle/battle_hud.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
const FIRST_BATTLE: Dictionary[StringName, bool] = {&"attack": true}
const INTRO := "Le Rival envoie Carapuce !"
## Abscisse jusqu'où un toucher de test atteint l'interface (voir _reach).
const REACHABLE_X := 800.0

var _hud: BattleHud


func before_each() -> void:
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as BattleHud
	add_child_autofree(_hud)
	_hud.haptics_enabled = false
	_hud.speed_scale = 0.0
	_set_screen(SCREEN_WIDTHS[0])
	watch_signals(_hud)


func after_each() -> void:
	# Aucun doigt ne reste posé d'un test à l'autre.
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	get_viewport().push_input(mouse, true)


## Écran de [param width] × SCREEN_HEIGHT (le viewport headless n'a pas la taille du S24).
func _set_screen(width: float) -> void:
	var screen := _hud.get_screen()
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.position = Vector2.ZERO
	screen.size = Vector2(width, SCREEN_HEIGHT)


func _own() -> BattleCardView:
	return BattleCardView.new("Salamèche", BattleCardView.Gender.MALE, 5, 19, 19, true)


func _foe() -> BattleCardView:
	return BattleCardView.new("Carapuce", BattleCardView.Gender.FEMALE, 5, 20, 20, false)


func _moves() -> Array[BattleMoveView]:
	return [
		BattleMoveView.new("Griffe", &"normal", "Normal", BattleMoveView.Category.PHYSICAL,
			35, 35, 40, 100, "Lacère la cible avec des griffes acérées."),
		BattleMoveView.new("Rugissement", &"normal", "Normal", BattleMoveView.Category.STATUS,
			40, 40, 0, 100, "Baisse l'Attaque de la cible."),
	] as Array[BattleMoveView]


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


## Centre de [param control] une fois l'écran décalé pour l'amener à gauche : en test, le
## panneau de GUT couvre la droite du viewport et y avale les touchers.
func _reach(control: Control) -> Vector2:
	var screen := _hud.get_screen()
	screen.position.x = 0.0
	var center := control.get_global_rect().get_center()
	if center.x > REACHABLE_X:
		screen.position.x = REACHABLE_X - center.x
	return control.get_global_rect().get_center()


func _action_center(action: StringName) -> Vector2:
	return _reach(_hud.get_action_grid().get_button(action))


func _move_center(index: int) -> Vector2:
	return _reach(_hud.get_move_grid().get_card(index))


func _open_moves() -> void:
	_hud.show_moves(_moves())
	await wait_process_frames(2)


func _bottom_visible() -> Array[String]:
	var shown: Array[String] = []
	if _hud.get_action_grid().visible:
		shown.append("actions")
	if _hud.get_move_grid().visible:
		shown.append("moves")
	if _hud.get_message_banner().visible:
		shown.append("message")
	return shown


func test_battle_hud_layer_and_hidden_at_start() -> void:
	assert_eq(_hud.layer, UiTokens.LAYER_BATTLE_HUD)
	assert_false(_hud.is_shown())
	assert_eq(_hud.get_zone(), BattleHud.Zone.NONE)
	for control: Control in [_hud.get_card(BattleHud.Side.PLAYER),
			_hud.get_card(BattleHud.Side.FOE), _hud.get_party_pips(), _hud.get_action_grid(),
			_hud.get_move_grid(), _hud.get_back_button(), _hud.get_message_banner()]:
		assert_false(control.visible, control.name)
	assert_eq(_hud.get_screen().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_cards_show_name_gender_level_and_player_numbers_only() -> void:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.set_card(BattleHud.Side.FOE, _foe())
	var own := _hud.get_card(BattleHud.Side.PLAYER)
	var foe := _hud.get_card(BattleHud.Side.FOE)
	assert_true(own.visible and foe.visible)
	assert_eq(own.get_name_text(), "SALAMÈCHE")
	assert_eq(foe.get_name_text(), "CARAPUCE")
	assert_eq(own.get_gender(), BattleCardView.Gender.MALE)
	assert_eq(foe.get_gender(), BattleCardView.Gender.FEMALE)
	assert_eq(own.get_level_text(), "Nv. 5")
	assert_eq(foe.get_level_text(), "Nv. 5")
	assert_true(own.is_hp_numbers_visible())
	assert_eq(own.get_hp_text(), "19 / 19")
	assert_false(foe.is_hp_numbers_visible(), "pas de PV chiffrés pour l'adversaire")
	assert_true(_hud.is_shown())


func test_cards_placed_at_their_corners_and_slide_from_their_edge() -> void:
	_set_screen(SCREEN_WIDTHS[1])
	await wait_process_frames(2)
	var own := _hud.get_card(BattleHud.Side.PLAYER)
	var foe := _hud.get_card(BattleHud.Side.FOE)
	var size := _hud.get_screen().size
	assert_eq(foe.get_global_rect(), BattleHudLayout.rect(BattleHudLayout.Slot.FOE_CARD, size))
	assert_eq(own.get_global_rect(), BattleHudLayout.rect(BattleHudLayout.Slot.OWN_CARD, size))
	assert_eq(foe.slide_direction, Vector2.RIGHT)
	assert_eq(own.slide_direction, Vector2.LEFT)
	_hud.speed_scale = 1.0
	_hud.set_card(BattleHud.Side.FOE, _foe())
	assert_eq(foe.get_body().position, Vector2.RIGHT * UiTokens.PANEL_SLIDE, "glisse en place")
	assert_eq(foe.modulate.a, 0.0, "en fondu")
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_eq(foe.get_body().position, Vector2.ZERO)


func test_six_pips_one_filled_with_player_card() -> void:
	_hud.set_party(1)
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	var pips := _hud.get_party_pips()
	assert_true(pips.visible, "les pastilles accompagnent la carte joueur")
	assert_eq(pips.get_slot_count(), 6)
	assert_eq(pips.get_party_count(), 1)
	assert_true(pips.is_slot_filled(0))
	for i: int in range(1, 6):
		assert_false(pips.is_slot_filled(i), "pastille %d vide" % i)


func test_hide_card_player_takes_pips_foe_does_not() -> void:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.set_card(BattleHud.Side.FOE, _foe())
	_hud.hide_card(BattleHud.Side.FOE)
	assert_false(_hud.get_card(BattleHud.Side.FOE).visible)
	assert_true(_hud.get_party_pips().visible)
	_hud.hide_card(BattleHud.Side.PLAYER)
	assert_false(_hud.get_card(BattleHud.Side.PLAYER).visible)
	assert_false(_hud.get_party_pips().visible)
	_hud.set_card(BattleHud.Side.FOE, _foe())
	assert_true(_hud.get_card(BattleHud.Side.FOE).visible, "un nouveau Pokémon revient")


func test_invalid_card_view_refused() -> void:
	_hud.set_card(BattleHud.Side.FOE, BattleCardView.new())
	assert_push_error("vue de carte invalide")
	assert_false(_hud.get_card(BattleHud.Side.FOE).visible)


func test_first_battle_actions_attack_dominant_others_dimmed() -> void:
	_hud.show_actions(FIRST_BATTLE)
	var grid := _hud.get_action_grid()
	assert_true(grid.visible)
	assert_eq(_hud.get_zone(), BattleHud.Zone.ACTIONS)
	assert_true(grid.is_action_enabled(&"attack"))
	assert_true(grid.is_attack_glowing(), "ATTAQUER mis en avant")
	for action: StringName in [&"bag", &"team", &"run"]:
		assert_false(grid.is_action_enabled(action), "%s atténué" % action)
		assert_true(grid.get_button(action).disabled)


func test_dimmed_actions_are_mute() -> void:
	_hud.show_actions(FIRST_BATTLE)
	await wait_process_frames(2)
	for action: StringName in [&"bag", &"team", &"run"]:
		await _tap(_action_center(action))
	assert_signal_not_emitted(_hud, "action_selected")
	assert_signal_not_emitted(_hud, "haptic_played", "ni vibration")


func test_attack_tap_emits_once() -> void:
	_hud.show_actions(FIRST_BATTLE)
	await wait_process_frames(2)
	await _tap(_action_center(&"attack"))
	await _tap(_action_center(&"attack"))
	assert_signal_emit_count(_hud, "action_selected", 1)
	assert_signal_emitted_with_parameters(_hud, "action_selected", [&"attack"])
	assert_signal_emitted_with_parameters(_hud, "haptic_played", [UiTokens.HAPTIC_TAP_MS])


func test_show_moves_replaces_grid_and_shows_back() -> void:
	_hud.show_actions(FIRST_BATTLE)
	await _open_moves()
	assert_eq(_hud.get_zone(), BattleHud.Zone.MOVES)
	assert_false(_hud.get_action_grid().visible, "la grille est sortie")
	assert_true(_hud.get_move_grid().visible)
	assert_true(_hud.get_back_button().visible, "« ‹ » visible")
	var grid := _hud.get_move_grid()
	assert_eq(grid.get_card(0).get_name_text(), "GRIFFE")
	assert_eq(grid.get_card(1).get_name_text(), "RUGISSEMENT")
	assert_true(grid.get_card(2).is_empty())
	assert_true(grid.get_card(3).is_empty())


func test_move_tap_emits_once() -> void:
	await _open_moves()
	await _tap(_move_center(0))
	await _tap(_move_center(1))
	assert_signal_emit_count(_hud, "move_selected", 1)
	assert_signal_emitted_with_parameters(_hud, "move_selected", [0])


func test_long_press_opens_sheet_without_move_selected() -> void:
	await _open_moves()
	var center := _move_center(1)
	await _press(center, true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	assert_true(_hud.get_move_grid().is_details_open(), "fiche ouverte")
	assert_true(_hud.get_move_grid().get_detail_sheet().visible)
	await _press(center, false)
	await wait_process_frames(2)
	assert_false(_hud.get_move_grid().is_details_open(), "fermée au relâchement")
	assert_signal_not_emitted(_hud, "move_selected")
	await _tap(_move_center(0))
	assert_signal_emitted_with_parameters(_hud, "move_selected", [0])


func test_back_returns_to_actions_with_same_availability() -> void:
	_hud.show_actions(FIRST_BATTLE)
	await _open_moves()
	var back := _reach(_hud.get_back_button().get_button())
	await _tap(back)
	await wait_process_frames(2)
	assert_signal_emit_count(_hud, "back_requested", 1)
	assert_eq(_hud.get_zone(), BattleHud.Zone.ACTIONS)
	assert_true(_hud.get_action_grid().visible)
	assert_false(_hud.get_move_grid().visible)
	assert_false(_hud.get_back_button().visible)
	assert_true(_hud.get_action_grid().is_action_enabled(&"attack"))
	assert_false(_hud.get_action_grid().is_action_enabled(&"bag"))
	await _tap(_action_center(&"attack"))
	assert_signal_emit_count(_hud, "action_selected", 1, "la grille est réarmée")


func test_back_ignored_outside_moves() -> void:
	_hud.show_actions(FIRST_BATTLE)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_signal_not_emitted(_hud, "back_requested")


func test_message_ends_after_hold() -> void:
	_hud.speed_scale = 1.0
	await wait_process_frames(2)
	var start := Time.get_ticks_msec()
	await _hud.show_message(INTRO)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_eq(_hud.get_message_banner().get_text(), INTRO)
	assert_almost_eq(elapsed, UiTokens.BATTLE_MESSAGE_HOLD, 0.1, "BATTLE_MESSAGE_HOLD")
	assert_true(_hud.get_message_banner().visible, "reste jusqu'à la zone suivante")


func test_message_ends_on_touch() -> void:
	_hud.speed_scale = 1.0
	var state := {"done": false}
	var show := func() -> void:
		await _hud.show_message(INTRO)
		state["done"] = true
	show.call()
	await wait_seconds(0.2)
	assert_false(state["done"])
	await _press(Vector2(900, 500), true)
	assert_true(state["done"], "le toucher fait avancer")
	await _press(Vector2(900, 500), false)


func test_message_and_grid_never_visible_together() -> void:
	_hud.speed_scale = 1.0
	_hud.show_actions(FIRST_BATTLE)
	var seen: Array[String] = []
	var watch := func() -> void:
		var shown := _bottom_visible()
		if shown.size() > 1:
			seen.append(",".join(shown))
	get_tree().process_frame.connect(watch)
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	_hud.show_message(INTRO)
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + UiTokens.BATTLE_MESSAGE_HOLD + 0.1)
	_hud.show_moves(_moves())
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + UiTokens.ANIM_PANEL + 0.1)
	_hud.show_message("Salamèche utilise Griffe !")
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + 0.1)
	_hud.show_actions(FIRST_BATTLE)
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + UiTokens.ANIM_PANEL + 0.1)
	get_tree().process_frame.disconnect(watch)
	assert_eq(seen, [] as Array[String], "une seule zone visible à chaque image")
	assert_eq(_bottom_visible(), ["actions"] as Array[String])
	assert_false(_hud.get_back_button().visible)


func test_zone_switch_superseded_by_newer_one() -> void:
	_hud.speed_scale = 1.0
	_hud.show_actions(FIRST_BATTLE)
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	_hud.show_moves(_moves())
	_hud.show_actions(FIRST_BATTLE)
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + UiTokens.ANIM_PANEL + 0.1)
	assert_eq(_bottom_visible(), ["actions"] as Array[String], "la dernière demande gagne")
	assert_false(_hud.get_back_button().visible)


func test_animate_hp_reaches_value_faster_when_big() -> void:
	_hud.set_card(BattleHud.Side.FOE, _foe())
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.speed_scale = 1.0
	await wait_process_frames(2)
	var start := Time.get_ticks_msec()
	await _hud.animate_hp(BattleHud.Side.FOE, 14, 20, false)
	var normal := (Time.get_ticks_msec() - start) / 1000.0
	assert_eq(_hud.get_card(BattleHud.Side.FOE).get_hp_bar().get_shown_hp(), 14)
	start = Time.get_ticks_msec()
	await _hud.animate_hp(BattleHud.Side.PLAYER, 3, 19, true)
	var big := (Time.get_ticks_msec() - start) / 1000.0
	var own := _hud.get_card(BattleHud.Side.PLAYER)
	assert_eq(own.get_hp_bar().get_shown_hp(), 3)
	assert_eq(own.get_hp_text(), "3 / 19")
	assert_almost_eq(normal, UiTokens.HP_TWEEN, 0.08)
	assert_almost_eq(big, UiTokens.HP_TWEEN_FAST, 0.08)
	assert_lt(big, normal, "gros coup plus rapide")
	assert_eq(own.get_hp_bar().get_color(), UiTokens.HP_LOW)


func test_animate_hp_instant_with_speed_zero() -> void:
	_hud.set_card(BattleHud.Side.FOE, _foe())
	await _hud.animate_hp(BattleHud.Side.FOE, 0, 20, true)
	assert_eq(_hud.get_card(BattleHud.Side.FOE).get_hp_bar().get_shown_hp(), 0)


func test_play_hit_vibrates_more_on_critical() -> void:
	_hud.set_card(BattleHud.Side.FOE, _foe())
	_hud.play_hit(BattleHud.Side.FOE, false)
	_hud.play_hit(BattleHud.Side.PLAYER, true)
	assert_signal_emit_count(_hud, "haptic_played", 2)
	var first: Array = get_signal_parameters(_hud, "haptic_played", 0)
	var second: Array = get_signal_parameters(_hud, "haptic_played", 1)
	assert_eq(first, [UiTokens.HAPTIC_HIT_MS])
	assert_eq(second, [UiTokens.HAPTIC_CRIT_MS])


func test_hide_all_hides_everything() -> void:
	_hud.speed_scale = 1.0
	_hud.set_party(1)
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.set_card(BattleHud.Side.FOE, _foe())
	_hud.show_moves(_moves())
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_true(_hud.is_shown())
	await _hud.hide_all()
	assert_false(_hud.is_shown())
	for control: Control in [_hud.get_card(BattleHud.Side.PLAYER),
			_hud.get_card(BattleHud.Side.FOE), _hud.get_party_pips(), _hud.get_action_grid(),
			_hud.get_move_grid(), _hud.get_back_button(), _hud.get_message_banner()]:
		assert_false(control.visible, "%s caché" % control.name)
	assert_eq(_hud.get_zone(), BattleHud.Zone.NONE)


func test_hide_all_ends_a_waiting_message() -> void:
	_hud.speed_scale = 1.0
	var state := {"done": false}
	var show := func() -> void:
		await _hud.show_message(INTRO)
		state["done"] = true
	show.call()
	await wait_process_frames(2)
	await _hud.hide_all()
	assert_true(state["done"], "celui qui attendait le message reprend")
	assert_false(_hud.get_message_banner().visible)


func test_speed_and_haptics_relayed_to_components() -> void:
	_hud.speed_scale = 0.5
	_hud.haptics_enabled = false
	for widget: BattleWidget in [_hud.get_card(BattleHud.Side.PLAYER),
			_hud.get_card(BattleHud.Side.FOE), _hud.get_party_pips(), _hud.get_action_grid(),
			_hud.get_move_grid(), _hud.get_back_button(), _hud.get_message_banner()]:
		assert_eq(widget.speed_scale, 0.5, widget.name)
		assert_false(widget.haptics_enabled, widget.name)


func test_touch_zones_min_size_inside_safe_margin() -> void:
	for width: float in SCREEN_WIDTHS:
		var size := Vector2(width, SCREEN_HEIGHT)
		_set_screen(width)
		_hud.set_card(BattleHud.Side.PLAYER, _own())
		_hud.set_card(BattleHud.Side.FOE, _foe())
		_hud.set_party(1)
		_hud.show_actions(FIRST_BATTLE)
		await wait_process_frames(2)
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		var zones: Array[Control] = []
		var rects: Array[Rect2] = []
		for action: StringName in ActionGrid.ACTIONS:
			zones.append(_hud.get_action_grid().get_button(action))
			rects.append(zones[-1].get_global_rect())
		_hud.show_moves(_moves())
		await wait_process_frames(2)
		for i: int in MoveGrid.SLOTS:
			zones.append(_hud.get_move_grid().get_card(i))
			rects.append(zones[-1].get_global_rect())
		zones.append(_hud.get_back_button().get_button())
		rects.append(zones[-1].get_global_rect())
		for i: int in zones.size():
			var zone := zones[i]
			var rect := rects[i]
			assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
				"%s ≥ TOUCH_MIN à %d (%s)" % [zone.name, width, rect.size])
			assert_true(safe.encloses(rect), "%s dans SAFE_MARGIN à %d" % [zone.name, width])
		# Rien ne chevauche les cartes d'information.
		var own := _hud.get_card(BattleHud.Side.PLAYER).get_global_rect()
		var foe := _hud.get_card(BattleHud.Side.FOE).get_global_rect()
		for i: int in zones.size():
			var zone := zones[i]
			assert_false(rects[i].intersects(own),
				"%s sur la carte joueur à %d" % [zone.name, width])
			assert_false(rects[i].intersects(foe),
				"%s sur la carte adverse à %d" % [zone.name, width])
		await _hud.hide_all()
