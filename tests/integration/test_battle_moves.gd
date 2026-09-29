extends GutTest
## Interface de combat, jalon 4B (3/4) : cartes de capacités (nom, pastille, PP, « Puissance
## 40 » ou « Statut », teinte du type, emplacement vide, carte sans PP inerte), sélection
## (liseré ACCENT + ▶), un toucher = un move_selected, pression longue = fiche SANS
## move_selected (même au relâchement), clavier, bouton « ‹ », placement à 1920 et 2340.

const GRID_SCENE := "res://game/ui/battle/move_grid.tscn"
const BACK_SCENE := "res://game/ui/battle/battle_back_button.tscn"
const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0

var _grid: MoveGrid


func before_each() -> void:
	_grid = (load(GRID_SCENE) as PackedScene).instantiate() as MoveGrid
	_grid.haptics_enabled = false
	_grid.speed_scale = 0.0
	add_child_autofree(_grid)


func after_each() -> void:
	# Aucun doigt ne reste posé d'un test à l'autre.
	_release_all()


func _scratch(pp: int = 35) -> BattleMoveView:
	return BattleMoveView.new("Griffe", &"normal", "Normal", BattleMoveView.Category.PHYSICAL,
		pp, 35, 40, 100, "Lacère la cible avec des griffes acérées.")


func _growl() -> BattleMoveView:
	return BattleMoveView.new("Rugissement", &"normal", "Normal",
		BattleMoveView.Category.STATUS, 40, 40, 0, 100, "Baisse l'Attaque de la cible.")


func _ember() -> BattleMoveView:
	return BattleMoveView.new("Flammèche", &"fire", "Feu", BattleMoveView.Category.SPECIAL,
		25, 25, 40, 100, "")


func _bite() -> BattleMoveView:
	return BattleMoveView.new("Morsure", &"dark", "Ténèbres", BattleMoveView.Category.PHYSICAL,
		25, 25, 60, 100, "")


func _show(views: Array[BattleMoveView]) -> void:
	_grid.show_moves(views)
	await wait_process_frames(2)


func _charmander_moves() -> Array[BattleMoveView]:
	return [_scratch(), _growl()] as Array[BattleMoveView]


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


func _release_all() -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	get_viewport().push_input(mouse, true)


func _center(index: int) -> Vector2:
	return _grid.get_card(index).get_global_rect().get_center()


func _key(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
	await wait_process_frames(1)


# --- Cartes --------------------------------------------------------------------------------

func test_card_shows_name_badge_pp_and_power() -> void:
	await _show(_charmander_moves())
	var card := _grid.get_card(0)
	assert_eq(card.get_name_text(), "GRIFFE")
	assert_eq(card.get_badge().get_type_text(), "NORMAL")
	assert_eq(card.get_badge().get_color(), UiTokens.TYPE_COLORS[&"normal"])
	assert_eq(card.get_pp_text(), "35/35")
	assert_eq((card.get_node(^"%PpTag") as Label).text, "PP")
	assert_eq(card.get_power_text(), "Puissance 40")
	assert_not_null(card.get_icon(), "icône du type")


func test_status_move_shows_statut() -> void:
	await _show(_charmander_moves())
	assert_eq(_grid.get_card(1).get_name_text(), "RUGISSEMENT")
	assert_eq(_grid.get_card(1).get_power_text(), "Statut")
	assert_eq(_grid.get_card(1).get_pp_text(), "40/40")


func test_missing_moves_leave_empty_slots() -> void:
	await _show(_charmander_moves())
	assert_false(_grid.get_card(0).is_empty())
	assert_false(_grid.get_card(1).is_empty())
	for i: int in [2, 3]:
		var card := _grid.get_card(i)
		assert_true(card.is_empty(), "emplacement %d vide" % i)
		assert_eq(card.theme_type_variation, &"MoveCardEmpty")
		assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE, "inerte")


func test_card_tinted_by_type() -> void:
	await _show([_scratch(), _ember()] as Array[BattleMoveView])
	var normal := _grid.get_card(0).get_style().bg_color
	var fire := _grid.get_card(1).get_style().bg_color
	assert_eq(fire, UiTokens.PANEL_BG.lerp(UiTokens.TYPE_COLORS[&"fire"], UiTokens.MOVE_CARD_TINT))
	assert_ne(normal, fire)
	assert_lt(fire.a, 1.0, "translucide")


func test_type_without_icon_uses_neutral_ring() -> void:
	await _show([_bite()] as Array[BattleMoveView])
	assert_false(TypeBadge.ICONS.has(&"dark"), "pas d'icône Ténèbres (volontaire)")
	assert_eq(_grid.get_card(0).get_icon(), MoveCard.GENERIC_ICON)
	assert_eq(_grid.get_card(0).get_badge().get_color(), UiTokens.TYPE_COLORS[&"dark"])


func test_card_without_pp_dimmed_and_inert() -> void:
	await _show([_scratch(0), _growl()] as Array[BattleMoveView])
	var card := _grid.get_card(0)
	assert_false(card.is_usable())
	assert_eq(card.modulate, UiTokens.MOVE_CARD_DISABLED, "atténuée")
	assert_eq(card.get_pp_text(), "0/35")
	assert_eq((card.get_node(^"%PpValue") as Label).get_theme_color(&"font_color"),
		UiTokens.MOVE_PP_EMPTY)
	watch_signals(_grid)
	await _tap(_center(0))
	await _press(_center(0), true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	await _press(_center(0), false)
	assert_signal_not_emitted(_grid, "move_selected")
	assert_signal_not_emitted(_grid, "details_opened")
	assert_signal_not_emitted(_grid, "haptic_played")
	assert_eq(_grid.get_selected(), -1)


func test_cards_at_least_touch_min() -> void:
	await _show(_charmander_moves())
	for i: int in MoveGrid.SLOTS:
		var size := _grid.get_card(i).size
		assert_true(size.x >= UiTokens.TOUCH_MIN and size.y >= UiTokens.TOUCH_MIN, str(size))
		assert_eq(size, UiTokens.MOVE_CARD_SIZE)


# --- Toucher -------------------------------------------------------------------------------

func test_one_tap_one_move_selected() -> void:
	await _show(_charmander_moves())
	watch_signals(_grid)
	await _tap(_center(0))
	assert_signal_emit_count(_grid, "move_selected", 1)
	assert_signal_emitted_with_parameters(_grid, "move_selected", [0])
	assert_signal_emitted_with_parameters(_grid, "haptic_played", [UiTokens.HAPTIC_TAP_MS])
	await _tap(_center(1))
	await _tap(_center(0))
	assert_signal_emit_count(_grid, "move_selected", 1, "une seule fois jusqu'au show_moves")
	assert_signal_not_emitted(_grid, "details_opened")


func test_show_moves_rearms() -> void:
	await _show(_charmander_moves())
	watch_signals(_grid)
	await _tap(_center(1))
	await _show(_charmander_moves())
	await _tap(_center(1))
	assert_signal_emit_count(_grid, "move_selected", 2)


func test_press_selects_with_accent_border_and_arrow() -> void:
	await _show(_charmander_moves())
	await _press(_center(1), true)
	await wait_process_frames(1)
	assert_eq(_grid.get_selected(), 1)
	var card := _grid.get_card(1)
	assert_true(card.is_selected())
	assert_eq(card.theme_type_variation, &"MoveCardSelected")
	assert_eq(card.get_style().border_color, UiTokens.ACCENT)
	var arrow := _grid.get_arrow()
	assert_true(arrow.visible, "▶ affichée")
	var arrow_rect := arrow.get_global_rect()
	var card_rect := card.get_global_rect()
	assert_lt(arrow_rect.end.x, card_rect.position.x, "▶ à gauche de la carte")
	assert_almost_eq(arrow_rect.get_center().y, card_rect.get_center().y, 1.0)
	assert_false(_grid.get_card(0).is_selected())
	await _press(_center(1), false)


func test_release_outside_cancels() -> void:
	await _show(_charmander_moves())
	watch_signals(_grid)
	await _press(_center(0), true)
	await _press(Vector2(-500, -500), false)
	assert_signal_not_emitted(_grid, "move_selected")
	assert_eq(_grid.get_selected(), -1)
	assert_false(_grid.get_arrow().visible)


func test_long_press_opens_sheet_without_move_selected() -> void:
	await _show(_charmander_moves())
	watch_signals(_grid)
	await _press(_center(0), true)
	await wait_seconds(UiTokens.LONG_PRESS * 0.5)
	assert_signal_not_emitted(_grid, "details_opened", "pas avant LONG_PRESS")
	await wait_seconds(UiTokens.LONG_PRESS * 0.5 + 0.1)
	assert_signal_emitted_with_parameters(_grid, "details_opened", [0])
	assert_true(_grid.is_details_open())
	var sheet := _grid.get_detail_sheet()
	assert_true(sheet.visible, "fiche affichée")
	assert_eq(_grid.get_selected(), 0, "carte sélectionnée pendant la pression")
	assert_signal_not_emitted(_grid, "move_selected")
	await _press(_center(0), false)
	assert_signal_not_emitted(_grid, "move_selected", "le relâchement ne lance rien")
	assert_signal_emit_count(_grid, "details_closed", 1)
	assert_false(_grid.is_details_open())
	await wait_process_frames(2)
	assert_false(sheet.visible, "fiche fermée au relâchement")
	await _tap(_center(0))
	assert_signal_emit_count(_grid, "move_selected", 1, "un toucher ensuite lance bien")


func test_detail_sheet_content() -> void:
	await _show(_charmander_moves())
	await _press(_center(0), true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	var sheet := _grid.get_detail_sheet()
	assert_eq(sheet.get_name_text(), "GRIFFE")
	assert_eq(sheet.get_badge().get_type_text(), "NORMAL")
	assert_eq(sheet.get_category_text(), "Physique")
	assert_eq(sheet.get_power_text(), "40")
	assert_eq(sheet.get_accuracy_text(), "100")
	assert_eq(sheet.get_pp_text(), "35/35")
	assert_eq(sheet.get_description_text(), "Lacère la cible avec des griffes acérées.")
	await _press(_center(0), false)


func test_detail_sheet_dashes_and_categories() -> void:
	var sheet := _grid.get_detail_sheet()
	sheet.speed_scale = 0.0
	sheet.open(BattleMoveView.new("Rugissement", &"normal", "Normal",
		BattleMoveView.Category.STATUS, 40, 40, 0, 0, ""))
	assert_eq(sheet.get_category_text(), "Statut")
	assert_eq(sheet.get_power_text(), "—", "aucune puissance")
	assert_eq(sheet.get_accuracy_text(), "—", "touche toujours")
	sheet.open(_ember())
	assert_eq(sheet.get_category_text(), "Spéciale")


func test_detail_sheet_slides_and_fades_in() -> void:
	var sheet := _grid.get_detail_sheet()
	sheet.speed_scale = 1.0
	sheet.open(_scratch())
	assert_eq(sheet.modulate.a, 0.0)
	assert_eq(sheet.get_body().position, Vector2.DOWN * UiTokens.MOVE_DETAIL_SLIDE)
	await wait_seconds(UiTokens.MOVE_DETAIL_OPEN + 0.05)
	assert_eq(sheet.get_body().position, Vector2.ZERO)
	assert_almost_eq(sheet.modulate.a, 1.0, 0.001)


func test_detail_sheet_above_cards_and_on_screen() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := Control.new()
		screen.size = Vector2(width, SCREEN_HEIGHT)
		add_child_autofree(screen)
		var grid := (load(GRID_SCENE) as PackedScene).instantiate() as MoveGrid
		screen.add_child(grid)
		BattleHudLayout.place(grid, BattleHudLayout.Slot.MOVES)
		grid.speed_scale = 0.0
		grid.show_moves(_charmander_moves())
		grid.get_detail_sheet().speed_scale = 0.0
		grid.get_detail_sheet().open(_scratch())
		await wait_process_frames(2)
		var sheet := grid.get_detail_sheet().get_global_rect()
		assert_lt(sheet.end.y, grid.get_card(0).get_global_rect().position.y, "au-dessus")
		assert_true(Rect2(Vector2.ZERO, screen.size).encloses(sheet), "à l'écran à %d" % width)


# --- Clavier (Mac) --------------------------------------------------------------------------

func test_keyboard_select_and_confirm() -> void:
	await _show([_scratch(), _growl(), _ember()] as Array[BattleMoveView])
	watch_signals(_grid)
	await _key(&"ui_right")
	assert_eq(_grid.get_selected(), 0, "première flèche : première carte")
	await _key(&"ui_right")
	assert_eq(_grid.get_selected(), 1)
	await _key(&"ui_down")
	assert_eq(_grid.get_selected(), 1, "vide en dessous : on reste")
	await _key(&"ui_left")
	await _key(&"ui_down")
	assert_eq(_grid.get_selected(), 2)
	await _key(&"ui_accept")
	assert_signal_emitted_with_parameters(_grid, "move_selected", [2])


func test_select_skips_unusable() -> void:
	await _show([_scratch(0), _growl()] as Array[BattleMoveView])
	_grid.select(0)
	assert_eq(_grid.get_selected(), -1, "sans PP : pas sélectionnable")
	_grid.select(3)
	assert_eq(_grid.get_selected(), -1, "vide")
	_grid.select(1)
	assert_eq(_grid.get_selected(), 1)


func test_invalid_view_becomes_empty_slot() -> void:
	await _show([BattleMoveView.new("", &"normal", "Normal")] as Array[BattleMoveView])
	assert_push_error("vue invalide")
	assert_true(_grid.get_card(0).is_empty())


# --- « ‹ » et placement ----------------------------------------------------------------------

func test_back_button_emits_back_requested() -> void:
	var back := (load(BACK_SCENE) as PackedScene).instantiate() as BattleBackButton
	back.haptics_enabled = false
	back.speed_scale = 0.0
	add_child_autofree(back)
	watch_signals(back)
	var center := back.get_button().get_global_rect().get_center()
	await _tap(center)
	assert_signal_not_emitted(back, "back_requested", "caché : rien")
	await back.slide_in()
	await wait_process_frames(1)
	center = back.get_button().get_global_rect().get_center()
	await _tap(center)
	assert_signal_emit_count(back, "back_requested", 1)
	assert_signal_emitted_with_parameters(back, "haptic_played", [UiTokens.HAPTIC_TAP_MS])
	await _key(&"ui_cancel")
	assert_signal_emit_count(back, "back_requested", 2, "Échap sur Mac")
	assert_eq(back.get_button().size, Vector2.ONE * UiTokens.BATTLE_BACK_SIZE)
	assert_eq(back.get_button().icon, BattleBackButton.ICON)


func test_moves_layout_touchable_in_safe_margin() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := Control.new()
		screen.size = Vector2(width, SCREEN_HEIGHT)
		add_child_autofree(screen)
		var grid := (load(GRID_SCENE) as PackedScene).instantiate() as MoveGrid
		var back := (load(BACK_SCENE) as PackedScene).instantiate() as BattleBackButton
		var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
		for control: Control in [grid, back, card]:
			screen.add_child(control)
		BattleHudLayout.place(grid, BattleHudLayout.Slot.MOVES)
		BattleHudLayout.place(back, BattleHudLayout.Slot.BACK)
		BattleHudLayout.place(card, BattleHudLayout.Slot.OWN_CARD)
		grid.speed_scale = 0.0
		grid.show_moves([_scratch(), _growl(), _ember(), _bite()] as Array[BattleMoveView])
		grid.select(0)
		await wait_process_frames(3)
		var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			screen.size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
		var own := card.get_global_rect()
		for i: int in MoveGrid.SLOTS:
			var rect := grid.get_card(i).get_global_rect()
			assert_true(safe.encloses(rect), "carte %d dans SAFE_MARGIN à %d (%s)" % [
				i, width, rect])
			assert_false(rect.intersects(own), "carte %d pas sur la carte joueur" % i)
		assert_false(grid.get_arrow().get_global_rect().intersects(own), "▶ libre")
		var back_rect := back.get_global_rect()
		assert_true(safe.encloses(back_rect), "« ‹ » dans SAFE_MARGIN à %d" % width)
		assert_gt(back_rect.position.y, own.end.y, "« ‹ » sous la carte joueur")
		assert_lt(back_rect.get_center().x, own.get_center().x, "…à gauche")
