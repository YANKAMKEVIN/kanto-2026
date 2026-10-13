extends GutTest
## Interface de combat du jalon 12 (T14, `jalon-12.md` §2.10, annexe A.4) : carte de capacité
## bloquée par Entrave (grisée, cadenas, « BLOQUÉE », inerte au toucher, à la pression longue et
## au clavier) ; icône du type Fée dans TypeBadge (pastille, carte de capacité, équipe).

const GRID_SCENE := "res://game/ui/battle/move_grid.tscn"
const BADGE_SCENE := "res://game/ui/components/type_badge.tscn"
const FAIRY_ICON := "res://assets/ui/icons/types/fairy.svg"

var _grid: MoveGrid


func before_each() -> void:
	_grid = (load(GRID_SCENE) as PackedScene).instantiate() as MoveGrid
	_grid.haptics_enabled = false
	_grid.speed_scale = 0.0
	add_child_autofree(_grid)


func after_each() -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	get_viewport().push_input(mouse, true)


func _move(name: String, type: StringName, shown: String, blocked: bool = false) -> BattleMoveView:
	var view := BattleMoveView.new(name, type, shown, BattleMoveView.Category.PHYSICAL,
		20, 20, 40, 100, "")
	view.blocked = blocked
	view.blocked_text = "BLOQUÉE" if blocked else ""
	return view


func _moves() -> Array[BattleMoveView]:
	return [_move("Écras'Face", &"normal", "Normal"), _move("Ligotage", &"normal", "Normal", true),
		_move("Charme", &"fairy", "Fée")] as Array[BattleMoveView]


func _show() -> void:
	_grid.show_moves(_moves())
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


func _center(index: int) -> Vector2:
	return _grid.get_card(index).get_global_rect().get_center()


func _key(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
	await wait_process_frames(1)


# --- Capacité bloquée ------------------------------------------------------------------------

func test_blocked_card_is_grey_with_lock_and_label() -> void:
	await _show()
	var card := _grid.get_card(1)
	assert_true(card.is_blocked())
	assert_false(card.is_usable())
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE, "non touchable")
	assert_eq(card.modulate, UiTokens.MOVE_CARD_DISABLED, "atténuée")
	assert_eq(card.get_power_text(), "BLOQUÉE")
	assert_eq(card.get_icon(), MoveCard.BLOCKED_ICON, "cadenas à la place du type")
	assert_eq(card.get_style().bg_color, UiTokens.MOVE_CARD_BLOCKED_BG, "fond gris, sans teinte")
	assert_eq(card.get_style().border_color, UiTokens.MOVE_CARD_BLOCKED_BORDER)
	assert_eq(card.get_name_text(), "LIGOTAGE", "le nom reste lisible")
	assert_eq(card.get_pp_text(), "20/20", "les PP restent lisibles")
	assert_false((card.get_node(^"%PpValue") as Label).has_theme_color_override(&"font_color"),
		"PP restants : pas en rouge (ce n'est pas une carte vide)")
	assert_eq(card.get_badge().get_type_text(), "NORMAL", "le type reste lisible")
	# Les autres cartes ne changent pas.
	var free := _grid.get_card(0)
	assert_false(free.is_blocked())
	assert_true(free.is_usable())
	assert_eq(free.get_power_text(), "Puissance 40")
	assert_eq(free.modulate, UiTokens.MODULATE_FULL)


func test_blocked_card_ignores_tap_and_long_press() -> void:
	await _show()
	watch_signals(_grid)
	await _press(_center(1), true)
	await _press(_center(1), false)
	await _press(_center(1), true)
	await wait_seconds(UiTokens.LONG_PRESS + 0.1)
	await _press(_center(1), false)
	assert_signal_not_emitted(_grid, "move_selected")
	assert_signal_not_emitted(_grid, "details_opened")
	assert_signal_not_emitted(_grid, "haptic_played")
	assert_eq(_grid.get_selected(), -1)
	_grid.select(1)
	assert_eq(_grid.get_selected(), -1, "jamais sélectionnée")


func test_keyboard_skips_the_blocked_card() -> void:
	await _show()
	await _key(&"ui_right")
	assert_eq(_grid.get_selected(), 0)
	await _key(&"ui_right")
	assert_eq(_grid.get_selected(), 0, "la carte bloquée (à droite) est sautée")
	await _key(&"ui_down")
	assert_eq(_grid.get_selected(), 2)


func test_a_card_unblocked_on_the_next_show_is_usable_again() -> void:
	await _show()
	var views := _moves()
	views[1].blocked = false
	_grid.show_moves(views)
	await wait_process_frames(2)
	var card := _grid.get_card(1)
	assert_false(card.is_blocked())
	assert_true(card.is_usable())
	assert_eq(card.get_power_text(), "Puissance 40")
	assert_eq(card.theme_type_variation, &"MoveCard")
	assert_eq(card.get_style().bg_color,
		UiTokens.PANEL_BG.lerp(UiTokens.TYPE_COLORS[&"normal"], UiTokens.MOVE_CARD_TINT))
	assert_eq(card.get_icon(), TypeBadge.ICONS[&"normal"])
	watch_signals(_grid)
	await _press(_center(1), true)
	await _press(_center(1), false)
	assert_signal_emitted_with_parameters(_grid, "move_selected", [1])


# --- Type Fée ----------------------------------------------------------------------------------

func test_fairy_has_its_own_icon() -> void:
	assert_true(TypeBadge.ICONS.has(&"fairy"))
	assert_eq(TypeBadge.ICONS[&"fairy"], load(FAIRY_ICON))
	assert_ne(TypeBadge.ICONS[&"fairy"], MoveCard.GENERIC_ICON, "pas l'anneau neutre")


func test_fairy_badge_shows_icon_name_and_colour() -> void:
	var badge := (load(BADGE_SCENE) as PackedScene).instantiate() as TypeBadge
	add_child_autofree(badge)
	badge.set_type(&"fairy", "Fée")
	assert_eq(badge.get_type_text(), "FÉE")
	assert_eq(badge.get_color(), UiTokens.TYPE_COLORS[&"fairy"])
	assert_eq(badge.get_icon(), TypeBadge.ICONS[&"fairy"])


func test_fairy_move_card_uses_the_fairy_icon() -> void:
	await _show()
	var card := _grid.get_card(2)
	assert_eq(card.get_icon(), TypeBadge.ICONS[&"fairy"])
	assert_eq(card.get_badge().get_type_text(), "FÉE")


func test_every_type_of_the_j12_species_has_an_icon() -> void:
	var data := PokemonData.new()
	data.load_dir()
	for id: StringName in [&"clefairy", &"clefable", &"jigglypuff", &"wigglytuff", &"zubat",
			&"ekans", &"paras", &"geodude", &"voltorb", &"koffing"]:
		var species := data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		for type: StringName in species.types:
			assert_true(TypeBadge.ICONS.has(type), "%s : %s" % [id, type])
