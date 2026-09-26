extends GutTest
## Interface de combat, jalon 4B (2/4) : grille des 4 actions. Libellés et couleurs,
## ATTAQUER mis en avant (lueur qui pulse), actions indisponibles atténuées et sans signal ni
## vibration, un toucher = un action_selected, zones ≥ TOUCH_MIN dans SAFE_MARGIN à 1920 et
## 2340, apparition animée.

const GRID_SCENE := "res://game/ui/battle/action_grid.tscn"
const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
const FIRST_BATTLE: Dictionary[StringName, bool] = {
	&"attack": true, &"bag": false, &"team": false, &"run": false,
}

var _grid: ActionGrid


func before_each() -> void:
	_grid = (load(GRID_SCENE) as PackedScene).instantiate() as ActionGrid
	_grid.haptics_enabled = false
	_grid.speed_scale = 0.0
	add_child_autofree(_grid)


## Un toucher sur le téléphone : l'écran tactile, puis la souris émulée (voir
## test_starter_sheet) ; les deux arrivent à l'interface.
func _tap(position: Vector2) -> void:
	for pressed: bool in [true, false]:
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


func _center(action: StringName) -> Vector2:
	return _grid.get_button(action).get_global_rect().get_center()


func _show_first_battle() -> void:
	_grid.show_actions(FIRST_BATTLE)
	await wait_process_frames(2)


func test_hidden_at_start() -> void:
	assert_false(_grid.visible)
	assert_false(_grid.is_shown())


func test_labels_icons_and_colors() -> void:
	var expected := {
		&"attack": ["ATTAQUER", &"ActionButtonAttack", UiTokens.ACTION_ATTACK],
		&"bag": ["SAC", &"ActionButtonBag", UiTokens.ACTION_BAG],
		&"team": ["ÉQUIPE", &"ActionButtonTeam", UiTokens.ACTION_TEAM],
		&"run": ["FUITE", &"ActionButtonRun", UiTokens.ACTION_RUN],
	}
	for action: StringName in expected:
		var button := _grid.get_button(action)
		assert_eq(button.text, expected[action][0])
		assert_eq(button.theme_type_variation, expected[action][1])
		assert_not_null(button.icon, "icône %s" % action)
		var box := button.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_eq(box.bg_color, expected[action][2], "couleur %s" % action)
		assert_eq(button.focus_mode, Control.FOCUS_NONE)


func test_grid_order_two_by_two() -> void:
	await _show_first_battle()
	var attack := _grid.get_button(&"attack").get_global_rect()
	var bag := _grid.get_button(&"bag").get_global_rect()
	var team := _grid.get_button(&"team").get_global_rect()
	var run := _grid.get_button(&"run").get_global_rect()
	assert_lt(attack.position.x, bag.position.x, "ATTAQUER à gauche de SAC")
	assert_eq(attack.position.y, bag.position.y)
	assert_lt(attack.position.y, team.position.y, "ÉQUIPE sous ATTAQUER")
	assert_eq(team.position.y, run.position.y)


func test_first_battle_attack_highlighted_others_dimmed() -> void:
	await _show_first_battle()
	assert_true(_grid.visible)
	assert_true(_grid.is_action_enabled(&"attack"))
	assert_true(_grid.is_attack_glowing(), "ATTAQUER mis en avant")
	for action: StringName in [&"bag", &"team", &"run"]:
		var button := _grid.get_button(action)
		assert_false(_grid.is_action_enabled(action), String(action))
		assert_true(button.disabled)
		var dim := button.get_theme_stylebox(&"disabled") as StyleBoxFlat
		var normal := button.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_ne(dim.bg_color, normal.bg_color, "%s atténué" % action)
		assert_eq(button.get_theme_color(&"font_disabled_color"), UiTokens.TEXT_DISABLED)


func test_glow_pulses() -> void:
	await _show_first_battle()
	var glow := _grid.get_node(^"%Glow") as Panel
	var alphas: Array[float] = []
	for i: int in 4:
		await wait_seconds(UiTokens.ACTION_GLOW_PULSE * 0.5)
		alphas.append(glow.modulate.a)
	assert_lt(alphas.min(), 0.95, "la lueur baisse…")
	assert_between(alphas.min(), UiTokens.ACTION_GLOW_MIN - 0.01, 1.0, "…doucement")


func test_no_glow_when_attack_unavailable() -> void:
	_grid.show_actions({&"attack": false, &"bag": true})
	assert_false(_grid.is_attack_glowing())


func test_one_tap_one_signal() -> void:
	await _show_first_battle()
	watch_signals(_grid)
	await _tap(_center(&"attack"))
	assert_signal_emit_count(_grid, "action_selected", 1)
	assert_signal_emitted_with_parameters(_grid, "action_selected", [&"attack"])
	assert_signal_emitted_with_parameters(_grid, "haptic_played", [UiTokens.HAPTIC_TAP_MS])
	await _tap(_center(&"attack"))
	assert_signal_emit_count(_grid, "action_selected", 1, "pas de double choix")


func test_disabled_actions_emit_nothing_nor_vibrate() -> void:
	await _show_first_battle()
	watch_signals(_grid)
	for action: StringName in [&"bag", &"team", &"run"]:
		await _tap(_center(action))
	assert_signal_not_emitted(_grid, "action_selected")
	assert_signal_not_emitted(_grid, "haptic_played")
	await _tap(_center(&"attack"))
	assert_signal_emit_count(_grid, "action_selected", 1, "ATTAQUER reste disponible")


func test_show_actions_rearms_after_choice() -> void:
	await _show_first_battle()
	watch_signals(_grid)
	await _tap(_center(&"attack"))
	_grid.show_actions(FIRST_BATTLE)
	await _tap(_center(&"attack"))
	assert_signal_emit_count(_grid, "action_selected", 2)


func test_all_actions_when_available() -> void:
	_grid.show_actions({&"attack": true, &"bag": true, &"team": true, &"run": true})
	await wait_process_frames(2)
	watch_signals(_grid)
	await _tap(_center(&"run"))
	assert_signal_emitted_with_parameters(_grid, "action_selected", [&"run"])


func test_hidden_grid_ignores_taps() -> void:
	await _show_first_battle()
	var center := _center(&"attack")
	await _grid.slide_out()
	watch_signals(_grid)
	await _tap(center)
	assert_signal_not_emitted(_grid, "action_selected")


func test_slides_in_from_below_with_fade() -> void:
	_grid.speed_scale = 1.0
	_grid.show_actions(FIRST_BATTLE)
	assert_eq(_grid.modulate.a, 0.0)
	assert_eq(_grid.get_body().position, Vector2.DOWN * UiTokens.PANEL_SLIDE)
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_eq(_grid.get_body().position, Vector2.ZERO)
	assert_almost_eq(_grid.modulate.a, 1.0, 0.001)


func test_buttons_touchable_in_safe_margin_right_of_own_card() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := Control.new()
		screen.size = Vector2(width, SCREEN_HEIGHT)
		add_child_autofree(screen)
		var grid := (load(GRID_SCENE) as PackedScene).instantiate() as ActionGrid
		var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
		screen.add_child(grid)
		screen.add_child(card)
		BattleHudLayout.place(grid, BattleHudLayout.Slot.ACTIONS)
		BattleHudLayout.place(card, BattleHudLayout.Slot.OWN_CARD)
		grid.speed_scale = 0.0
		grid.show_actions(FIRST_BATTLE)
		await wait_process_frames(2)
		assert_eq(grid.get_global_rect(),
			BattleHudLayout.rect(BattleHudLayout.Slot.ACTIONS, screen.size))
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			screen.size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		for action: StringName in ActionGrid.ACTIONS:
			var rect := grid.get_button(action).get_global_rect()
			assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
				"%s ≥ TOUCH_MIN" % action)
			assert_true(safe.encloses(rect), "%s dans SAFE_MARGIN à %d" % [action, width])
			assert_false(rect.intersects(card.get_global_rect()), "pas sur la carte joueur")
