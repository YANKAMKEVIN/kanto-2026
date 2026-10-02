extends GutTest
## Carte de capture (jalon 5D, T14, case 9 de combat-capture-v1, dossier 05 §17) : titre en
## capitales, vignette, ligne « Nouvelle entrée Pokédex » seulement si demandée, ligne d'équipe,
## ▼ ; fin au toucher (après le délai de garde), centrée, dans les marges à 1920 et 2340.

const CARD_SCENE := "res://game/ui/battle/capture_card.tscn"
const PORTRAIT := "res://assets/sprites/pokemon/placeholder/pidgey_front.png"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
const POKEDEX := "Nouvelle entrée Pokédex"
const JOINED := "Roucool rejoint ton équipe."
const STORED := "Roucool a été confié au système de recherche de Chen."

var _screen: Control
var _card: CaptureCard
var _done: bool = false


func before_each() -> void:
	_done = false
	_screen = Control.new()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child_autofree(_screen)
	_card = (load(CARD_SCENE) as PackedScene).instantiate() as CaptureCard
	_screen.add_child(_card)
	BattleHudLayout.place(_card, BattleHudLayout.Slot.CAPTURE)
	_card.haptics_enabled = false
	_card.speed_scale = 0.0
	_set_screen(SCREEN_WIDTHS[0])
	watch_signals(_card)


func after_each() -> void:
	# Libère une carte restée en attente (sa coroutine ne reste pas suspendue).
	_card.skip()


func _set_screen(width: float) -> void:
	_screen.position = Vector2.ZERO
	_screen.size = Vector2(width, SCREEN_HEIGHT)


func _view(new_entry: bool = true, line: String = JOINED) -> CaptureCardView:
	return CaptureCardView.new("Roucool CAPTURÉ !", load(PORTRAIT) as Texture2D, new_entry,
		POKEDEX if new_entry else "", line)


## Lance show_capture et note sa fin.
func _show(view: CaptureCardView) -> void:
	_run(view)
	await wait_process_frames(2)


func _run(view: CaptureCardView) -> void:
	await _card.show_capture(view)
	_done = true


func _touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(500, 500)
	touch.pressed = true
	get_viewport().push_input(touch, false)
	await wait_process_frames(3)


func test_hidden_at_start_and_not_waiting() -> void:
	assert_false(_card.visible)
	assert_false(_card.is_waiting())


func test_title_in_capitals_and_portrait() -> void:
	await _show(CaptureCardView.new("Roucool capturé !", load(PORTRAIT) as Texture2D, false,
		"", JOINED))
	assert_true(_card.visible)
	assert_eq(_card.get_title_text(), "ROUCOOL CAPTURÉ !")
	assert_eq(_card.get_portrait().texture, load(PORTRAIT))
	assert_eq(_card.get_portrait().texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST,
		"sprite pixel art net")
	assert_true(_card.is_waiting())


func test_pokedex_line_only_when_requested() -> void:
	await _show(_view(true))
	assert_true(_card.is_pokedex_line_shown())
	assert_eq(_card.get_pokedex_text(), POKEDEX)
	_card.skip()
	await wait_process_frames(2)
	await _show(_view(false))
	assert_false(_card.is_pokedex_line_shown(), "pas une nouvelle entrée : pas de ligne")
	assert_false(_card.get_pokedex_row().visible)


func test_pokedex_line_not_shown_if_text_is_missing() -> void:
	var view := CaptureCardView.new("X CAPTURÉ !", null, true, "", JOINED)
	assert_false(view.is_valid(), "une nouvelle entrée sans texte est refusée")
	assert_false(view.shows_pokedex_line())


func test_team_line_joined_or_stored() -> void:
	await _show(_view(true, JOINED))
	assert_eq(_card.get_result_text(), JOINED)
	_card.skip()
	await wait_process_frames(2)
	await _show(_view(false, STORED))
	assert_eq(_card.get_result_text(), STORED)


func test_invalid_view_is_refused() -> void:
	await _show(CaptureCardView.new("", null, false, "", JOINED))
	assert_push_error("vue invalide")
	assert_false(_card.is_waiting())
	assert_false(_card.visible)
	await _show(CaptureCardView.new("X CAPTURÉ !", null, false, "", ""))
	assert_push_error("vue invalide")
	assert_false(_card.is_waiting())


func test_ends_at_first_touch() -> void:
	await _show(_view())
	assert_false(_done, "elle attend")
	await _touch()
	assert_true(_done, "le toucher la termine")
	assert_false(_card.is_waiting())
	assert_false(_card.is_shown(), "la carte ressort")


func test_ends_only_once_for_several_touches() -> void:
	await _show(_view())
	await _touch()
	await _touch()
	assert_true(_done)
	assert_false(_card.is_waiting())


func test_touch_before_the_guard_delay_is_ignored() -> void:
	_card.speed_scale = 1.0
	await _show(_view())
	await _touch()
	assert_false(_done, "le toucher du lancer ne ferme pas la carte")
	assert_true(_card.is_waiting())
	await wait_seconds(UiTokens.CAPTURE_TOUCH_LOCK + 0.1)
	await _touch()
	assert_false(_card.is_waiting(), "le toucher après le délai la termine")
	await wait_seconds(UiTokens.BATTLE_PANEL_CLOSE + 0.2)
	assert_true(_done)


func test_skip_ends_without_touch() -> void:
	await _show(_view())
	_card.skip()
	await wait_process_frames(2)
	assert_true(_done)


func test_lines_reveal_one_after_the_other() -> void:
	_card.speed_scale = 1.0
	await _show(_view(true))
	assert_eq(_card.get_pokedex_row().modulate.a, 0.0, "d'abord le titre et la vignette")
	assert_eq(_card.get_result_label().modulate.a, 0.0)
	await wait_seconds(UiTokens.CAPTURE_LINE_DELAY + UiTokens.CAPTURE_LINE_FADE + 0.1)
	assert_eq(_card.get_pokedex_row().modulate.a, 1.0, "puis la ligne Pokédex")
	assert_lt(_card.get_result_label().modulate.a, 1.0, "avant la ligne d'équipe")
	await wait_seconds((UiTokens.CAPTURE_LINE_DELAY + UiTokens.CAPTURE_LINE_FADE) * 2.0 + 0.2)
	assert_eq(_card.get_result_label().modulate.a, 1.0)
	assert_eq(_card.get_continue().modulate.a, 1.0, "▼")


func test_instant_with_speed_scale_zero() -> void:
	await _show(_view(true))
	assert_eq(_card.get_pokedex_row().modulate.a, 1.0)
	assert_eq(_card.get_result_label().modulate.a, 1.0)
	assert_true(_card.get_continue().visible)


func test_centered_and_inside_margins_at_both_widths() -> void:
	for width: float in SCREEN_WIDTHS:
		_set_screen(width)
		await _show(_view(true, STORED))
		var rect := _card.get_frame().get_global_rect()
		assert_almost_eq(rect.get_center().x, width * 0.5, 1.0, "%s : centrée" % width)
		assert_almost_eq(rect.get_center().y, SCREEN_HEIGHT * 0.5, 1.0)
		assert_true(Rect2(Vector2.ZERO, _screen.size).grow(-float(UiTokens.SAFE_MARGIN))
			.encloses(rect), "%s : dans les marges (%s)" % [width, rect])
		assert_eq(rect.size.x, float(UiTokens.CAPTURE_CARD_WIDTH))
		assert_lte(rect.size.y, float(UiTokens.CAPTURE_CARD_MAX_HEIGHT))
		_card.skip()
		await wait_process_frames(2)


func test_continue_arrow_uses_accent_and_blinks() -> void:
	await _show(_view())
	var tint := _card.get_continue().self_modulate
	assert_eq([tint.r, tint.g, tint.b], [UiTokens.ACCENT.r, UiTokens.ACCENT.g, UiTokens.ACCENT.b])
	await wait_seconds(UiTokens.DIALOG_CONTINUE_BLINK * 0.9)
	assert_lt(_card.get_continue().self_modulate.a, 1.0, "▼ clignote doucement")


func test_card_does_not_intercept_mouse() -> void:
	await _show(_view())
	var stack: Array[Node] = [_card]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var control := node as Control
		if control is PanelContainer or control is Label or control is TextureRect \
				or control is BoxContainer:
			assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, str(control.get_path()))
		stack.append_array(node.get_children())


func test_view_is_valid_and_pokedex_flag() -> void:
	assert_true(_view(true).is_valid())
	assert_true(_view(false).is_valid())
	assert_true(_view(true).shows_pokedex_line())
	assert_false(_view(false).shows_pokedex_line())
