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
## Combat sauvage (jalon 5B) : ATTAQUER et FUITE actifs, SAC et ÉQUIPE atténués.
const WILD_BATTLE: Dictionary[StringName, bool] = {&"attack": true, &"run": true}
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


## Un sauvage : nom, sexe, « Nv. 3 », PV sans chiffres, aucune équipe.
func _wild_foe() -> BattleCardView:
	return BattleCardView.new("Rattata", BattleCardView.Gender.MALE, 3, 14, 14, false)


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


func test_wild_actions_attack_dominant_run_active() -> void:
	_hud.show_actions(WILD_BATTLE)
	var grid := _hud.get_action_grid()
	assert_true(grid.visible)
	assert_eq(_hud.get_zone(), BattleHud.Zone.ACTIONS)
	assert_true(grid.is_action_enabled(&"attack"))
	assert_true(grid.is_attack_glowing(), "ATTAQUER reste mis en avant en sauvage")
	assert_true(grid.is_action_enabled(&"run"), "FUITE active en sauvage")
	for action: StringName in [&"bag", &"team"]:
		assert_false(grid.is_action_enabled(action), "%s atténué" % action)
		assert_true(grid.get_button(action).disabled)


func test_wild_run_tap_emits_once() -> void:
	_hud.show_actions(WILD_BATTLE)
	await wait_process_frames(2)
	await _tap(_action_center(&"run"))
	await _tap(_action_center(&"run"))
	assert_signal_emit_count(_hud, "action_selected", 1)
	assert_signal_emitted_with_parameters(_hud, "action_selected", [&"run"])
	assert_signal_emitted_with_parameters(_hud, "haptic_played", [UiTokens.HAPTIC_TAP_MS])


func test_wild_bag_and_team_stay_mute() -> void:
	_hud.show_actions(WILD_BATTLE)
	await wait_process_frames(2)
	for action: StringName in [&"bag", &"team"]:
		await _tap(_action_center(action))
	assert_signal_not_emitted(_hud, "action_selected")
	assert_signal_not_emitted(_hud, "haptic_played", "ni vibration")


## Un Pokémon sauvage n'a pas d'équipe visible : la carte adverse ne porte aucune pastille,
## la carte joueur garde ses 6 (une seule PartyPips dans la HUD, rattachée au joueur).
func test_wild_foe_card_has_no_party_pips() -> void:
	_hud.set_party(6)
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.set_card(BattleHud.Side.FOE, _wild_foe())
	var pips := _hud.get_party_pips()
	assert_true(pips.visible, "les pastilles accompagnent la carte joueur")
	assert_eq(pips.get_party_count(), 6)
	var foe := _hud.get_card(BattleHud.Side.FOE)
	assert_eq(foe.find_children("*", "PartyPips", true, false).size(), 0,
		"aucune pastille sous la carte adverse")
	assert_false(foe.is_hp_numbers_visible(), "pas de PV chiffrés non plus (adversaire)")


func test_wild_touch_zones_min_size_inside_safe_margin() -> void:
	for width: float in SCREEN_WIDTHS:
		var size := Vector2(width, SCREEN_HEIGHT)
		_set_screen(width)
		_hud.show_actions(WILD_BATTLE)
		await wait_process_frames(2)
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		for action: StringName in ActionGrid.ACTIONS:
			var rect := _hud.get_action_grid().get_button(action).get_global_rect()
			assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
				"%s ≥ TOUCH_MIN à %d (%s)" % [action, width, rect.size])
			assert_true(safe.encloses(rect), "%s dans SAFE_MARGIN à %d" % [action, width])
		await _hud.hide_all()


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


# --- XP et niveau (jalon 5C, T10) ------------------------------------------------------------


func _own_card() -> BattleInfoCard:
	return _hud.get_card(BattleHud.Side.PLAYER)


## Carte du joueur affichée, durées réelles (speed_scale 1).
func _real_time_card() -> BattleInfoCard:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.speed_scale = 1.0
	return _own_card()


func test_exp_bar_hidden_at_start() -> void:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	assert_false(_own_card().is_exp_bar_visible(), "pas de barre d'XP permanente (bible §11)")
	assert_false(_own_card().is_exp_gain_visible())


func test_animate_exp_fills_from_to_in_exp_tween_then_hides() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	var start := Time.get_ticks_msec()
	_hud.animate_exp(0.2, 0.8)
	await wait_process_frames(2)
	assert_true(card.is_exp_bar_visible(), "la barre apparaît")
	assert_between(card.get_exp_bar().get_fraction(), 0.2, 0.5, "elle part de from")
	await wait_seconds(UiTokens.EXP_TWEEN * 0.5)
	assert_between(card.get_exp_bar().get_fraction(), 0.3, 0.79, "elle monte")
	await wait_seconds(UiTokens.EXP_TWEEN)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_gt(elapsed, UiTokens.EXP_TWEEN, "plus de EXP_TWEEN écoulés")
	assert_almost_eq(card.get_exp_bar().get_fraction(), 0.8, 0.0001, "elle arrive à to")
	assert_true(card.is_exp_bar_visible(), "elle reste un instant")
	await wait_seconds(UiTokens.EXP_BAR_LINGER + UiTokens.EXP_BAR_FADE + 0.15)
	assert_false(card.is_exp_bar_visible(), "puis elle est cachée")


func test_animate_exp_ends_after_exp_tween() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	var start := Time.get_ticks_msec()
	await _hud.animate_exp(0.0, 0.5)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_almost_eq(elapsed, UiTokens.EXP_TWEEN, 0.1, "EXP_TWEEN")
	assert_almost_eq(card.get_exp_bar().get_fraction(), 0.5, 0.0001)


## Fait avancer les tweens de « +N XP » de [param seconds] (temps de jeu, pas de temps réel).
func _step_gain(tweens: Array[Tween], seconds: float) -> void:
	for tween: Tween in tweens:
		if tween.is_valid():
			tween.custom_step(seconds)


## Déterministe : les tweens de « +N XP » sont mis en pause puis avancés à la main, donc le
## résultat ne dépend ni de la charge de la machine ni de l'horloge.
func test_gain_text_shown_then_erased() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	assert_false(card.is_exp_gain_visible())
	var gain := card.get_exp_gain_label()
	_hud.animate_exp(0.1, 0.5, 21)
	var tweens := card.get_exp_gain_tweens()
	assert_eq(tweens.size(), 2, "fondus et montée")
	for tween: Tween in tweens:
		tween.pause()
	assert_true(card.is_exp_gain_visible(), "« +N XP » affiché")
	assert_eq(card.get_exp_gain_text(), "+21 XP")
	assert_almost_eq(gain.modulate.a, 0.0, 0.001, "il part de la transparence")
	var first_y := gain.position.y
	_step_gain(tweens, UiTokens.EXP_GAIN_HOLD * 0.6)
	assert_true(card.is_exp_gain_visible(), "il reste pendant EXP_GAIN_HOLD")
	assert_almost_eq(gain.modulate.a, 1.0, 0.001, "pleinement visible au milieu")
	assert_lt(gain.position.y, first_y, "il monte")
	_step_gain(tweens, UiTokens.EXP_GAIN_HOLD * 0.4 + 0.1)
	assert_false(card.is_exp_gain_visible(), "puis il est effacé")
	assert_almost_eq(first_y - gain.position.y, UiTokens.EXP_GAIN_RISE, 0.001,
		"montée de EXP_GAIN_RISE")


func test_animate_exp_waits_for_the_gain_text_too() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	var start := Time.get_ticks_msec()
	await _hud.animate_exp(0.1, 0.5, 21)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_almost_eq(elapsed, UiTokens.EXP_GAIN_HOLD, 0.1, "EXP_GAIN_HOLD")
	assert_false(card.is_exp_gain_visible(), "effacé au retour")


func test_no_gain_text_when_nothing_gained() -> void:
	var card := _real_time_card()
	_hud.animate_exp(0.0, 0.3, 0)
	await wait_process_frames(3)
	assert_false(card.is_exp_gain_visible(), "tranche sans XP gagnée : pas de « +N XP »")
	await wait_seconds(UiTokens.EXP_TWEEN + 0.1)


func test_several_slices_chain_without_hiding_the_bar() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	var state := {"hidden_between": false, "done": false}
	var run := func() -> void:
		await _hud.animate_exp(0.7, 1.0, 30)
		await _hud.pulse_level(BattleHud.Side.PLAYER, 6)
		await _hud.animate_exp(0.0, 0.25)
		await _hud.pulse_level(BattleHud.Side.PLAYER, 7)
		await _hud.animate_exp(0.0, 0.6)
		state["done"] = true
	var watch := func() -> void:
		if not state["done"] and not card.is_exp_bar_visible():
			state["hidden_between"] = true
	get_tree().process_frame.connect(watch)
	run.call()
	await wait_seconds(UiTokens.EXP_GAIN_HOLD + 2.0 * UiTokens.EXP_TWEEN
		+ 2.0 * (UiTokens.LEVEL_PULSE_UP + UiTokens.LEVEL_PULSE_DOWN) + 0.5)
	get_tree().process_frame.disconnect(watch)
	assert_true(state["done"], "les trois tranches sont jouées")
	assert_false(state["hidden_between"], "la barre reste entre deux tranches")
	assert_almost_eq(card.get_exp_bar().get_fraction(), 0.6, 0.0001, "dernière tranche")
	assert_eq(card.get_level_text(), "Nv. 7")
	await wait_seconds(UiTokens.EXP_BAR_LINGER + UiTokens.EXP_BAR_FADE + 0.15)
	assert_false(card.is_exp_bar_visible(), "cachée après la dernière")


func test_new_slice_cancels_the_pending_hide() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	await _hud.animate_exp(0.0, 1.0)
	await wait_seconds(UiTokens.EXP_BAR_LINGER * 0.5)
	_hud.animate_exp(0.0, 0.5)
	await wait_seconds(UiTokens.EXP_BAR_LINGER + UiTokens.EXP_BAR_FADE)
	assert_true(card.is_exp_bar_visible(), "le masquage annoncé est annulé")
	assert_eq(card.get_exp_bar().modulate.a, 1.0)
	await wait_seconds(UiTokens.EXP_TWEEN + UiTokens.EXP_BAR_LINGER + UiTokens.EXP_BAR_FADE)
	assert_false(card.is_exp_bar_visible())


func test_overlapping_slices_never_leave_a_caller_hanging() -> void:
	_real_time_card()
	await wait_process_frames(2)
	var state := {"first": false, "second": false}
	var first := func() -> void:
		await _hud.animate_exp(0.0, 0.5, 10)
		state["first"] = true
	var second := func() -> void:
		await _hud.animate_exp(0.0, 0.9, 12)
		state["second"] = true
	first.call()
	await wait_seconds(0.1)
	second.call()
	await wait_seconds(UiTokens.EXP_GAIN_HOLD + 0.2)
	assert_true(state["first"], "la tranche interrompue se termine")
	assert_true(state["second"])
	assert_almost_eq(_own_card().get_exp_bar().get_fraction(), 0.9, 0.0001)


func test_animate_exp_instant_and_hidden_with_speed_zero() -> void:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	await _hud.animate_exp(0.0, 0.7, 21)
	var card := _own_card()
	assert_almost_eq(card.get_exp_bar().get_fraction(), 0.7, 0.0001)
	assert_false(card.is_exp_bar_visible())
	assert_false(card.is_exp_gain_visible())


func test_exp_bar_inside_card_and_does_not_move_it() -> void:
	_set_screen(SCREEN_WIDTHS[1])
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.speed_scale = 1.0
	await wait_process_frames(2)
	var card := _own_card()
	var before := card.get_global_rect()
	_hud.animate_exp(0.0, 0.5, 21)
	await wait_process_frames(3)
	assert_eq(card.get_global_rect(), before, "la carte ne change pas de taille")
	var bar := card.get_exp_bar().get_global_rect()
	assert_true(before.encloses(bar), "la barre est dans la carte")
	assert_almost_eq(bar.size.y, float(UiTokens.EXP_BAR_HEIGHT), 0.01)
	assert_false(bar.intersects(card.get_hp_numbers_label().get_global_rect()),
		"elle ne couvre pas « 19 / 19 »")
	assert_false(bar.intersects(card.get_hp_bar().get_global_rect()), "ni la barre de PV")
	await wait_seconds(UiTokens.EXP_GAIN_HOLD + 0.1)


func test_pulse_level_updates_text_and_pulses() -> void:
	var card := _real_time_card()
	await wait_process_frames(2)
	assert_eq(card.get_level_text(), "Nv. 5")
	var start := Time.get_ticks_msec()
	_hud.pulse_level(BattleHud.Side.PLAYER, 6)
	assert_eq(card.get_level_text(), "Nv. 6", "mis à jour tout de suite")
	assert_eq(card.get_level_label().text, "6")
	await wait_seconds(UiTokens.LEVEL_PULSE_UP + 0.03)
	assert_gt(card.get_level_label().scale.x, 1.2, "il pulse")
	assert_ne(card.get_level_label().modulate, UiTokens.MODULATE_FULL, "il s'illumine")
	await wait_seconds(UiTokens.LEVEL_PULSE_DOWN + 0.1)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_gt(elapsed, UiTokens.LEVEL_PULSE_UP + UiTokens.LEVEL_PULSE_DOWN)
	assert_eq(card.get_level_label().scale, Vector2.ONE, "puis revient")
	assert_eq(card.get_level_label().modulate, UiTokens.MODULATE_FULL)
	assert_signal_emitted_with_parameters(_hud, "haptic_played", [UiTokens.HAPTIC_LEVEL_UP_MS])


func test_pulse_level_ends_after_the_pulse_and_is_instant_at_speed_zero() -> void:
	var card := _real_time_card()
	var start := Time.get_ticks_msec()
	await _hud.pulse_level(BattleHud.Side.PLAYER, 6)
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_almost_eq(elapsed, UiTokens.LEVEL_PULSE_UP + UiTokens.LEVEL_PULSE_DOWN, 0.1)
	_hud.speed_scale = 0.0
	await _hud.pulse_level(BattleHud.Side.PLAYER, 7)
	assert_eq(card.get_level_text(), "Nv. 7")
	assert_eq(card.get_level_label().scale, Vector2.ONE)


func test_pulse_level_shows_no_window_and_changes_no_other_zone() -> void:
	_hud.set_card(BattleHud.Side.PLAYER, _own())
	_hud.show_actions(FIRST_BATTLE)
	await wait_process_frames(2)
	await _hud.pulse_level(BattleHud.Side.PLAYER, 6)
	assert_eq(_hud.get_zone(), BattleHud.Zone.ACTIONS, "aucune fenêtre, aucune zone changée")
	assert_true(_hud.get_action_grid().visible)
