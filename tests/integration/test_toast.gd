extends GutTest
## Toast (bible UI/UX §6, jalon 4B T7) : « Poké Balls ×5 » / « Ajoutées au Sac » en haut au
## centre, icône Poké Ball, caché après TOAST_FADE_IN + TOAST_HOLD + TOAST_FADE_OUT (± 1 image),
## n'intercepte aucun toucher, une vibration « tic » ; ExplorationHud.show_toast, affiché
## aussi quand les contrôles sont cachés (scène).

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const TOAST_SCENE := "res://game/ui/components/toast.tscn"
const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"
const TITLE := "Poké Balls ×5"
const DETAIL := "Ajoutées au Sac"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0

var _toast: Toast


func before_each() -> void:
	_toast = (load(TOAST_SCENE) as PackedScene).instantiate() as Toast
	_toast.haptics_enabled = false
	add_child_autofree(_toast)
	watch_signals(_toast)


func _total() -> float:
	return UiTokens.TOAST_FADE_IN + UiTokens.TOAST_HOLD + UiTokens.TOAST_FADE_OUT


func test_hidden_at_start() -> void:
	assert_false(_toast.visible)
	assert_false(_toast.is_showing())


func test_title_detail_and_icon_shown() -> void:
	_toast.show_toast(TITLE, DETAIL)
	assert_true(_toast.visible)
	assert_true(_toast.is_showing())
	assert_eq(_toast.get_title_text(), TITLE)
	assert_eq(_toast.get_detail_text(), DETAIL)
	assert_eq(_toast.get_icon(), Toast.DEFAULT_ICON, "icône Poké Ball")
	assert_signal_emitted_with_parameters(_toast, "toast_shown", [TITLE, DETAIL])


func test_styles_from_theme() -> void:
	var box := _toast.get_body().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(box.bg_color, UiTokens.TOAST_BG)
	assert_lt(box.bg_color.a, 1.0, "translucide")
	var title := _toast.find_child("Title", true, false) as Label
	var detail := _toast.find_child("Detail", true, false) as Label
	assert_eq(title.get_theme_font_size(&"font_size"), UiTokens.TOAST_TITLE_FONT)
	assert_eq(detail.get_theme_font_size(&"font_size"), UiTokens.TOAST_DETAIL_FONT)
	assert_eq(detail.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED)


func test_one_tick_vibration() -> void:
	_toast.show_toast(TITLE, DETAIL)
	assert_signal_emit_count(_toast, "haptic_played", 1)
	assert_signal_emitted_with_parameters(_toast, "haptic_played", [UiTokens.HAPTIC_TICK_MS])
	assert_lt(UiTokens.HAPTIC_TICK_MS, UiTokens.HAPTIC_TAP_MS + 1, "« tic » léger")


func test_fades_in_from_above() -> void:
	_toast.show_toast(TITLE, DETAIL)
	assert_eq(_toast.modulate.a, 0.0, "fondu, pas d'apparition sèche")
	assert_eq(_toast.get_body().position, Vector2.UP * UiTokens.TOAST_SLIDE)
	await wait_seconds(UiTokens.TOAST_FADE_IN + 0.05)
	assert_eq(_toast.modulate.a, 1.0)
	assert_eq(_toast.get_body().position, Vector2.ZERO)


func test_hidden_after_hold_and_fades() -> void:
	await wait_process_frames(2)
	# Temps simulé (TweenClock) : la durée se compte en pas, quelle que soit la charge.
	var clock := TweenClock.new(get_tree())
	_toast.show_toast(TITLE, DETAIL)
	var steps := clock.run_until(func() -> bool:
		return get_signal_emit_count(_toast, "toast_hidden") > 0, _total() + 1.0)
	clock.release()
	assert_signal_emit_count(_toast, "toast_hidden", 1)
	assert_false(_toast.visible)
	assert_false(_toast.is_showing())
	assert_between(steps * TweenClock.STEP, _total() - 0.0001, _total() + TweenClock.STEP + 0.0001,
		"TOAST_HOLD + fondus, à une image près (%d pas)" % steps)


func test_still_visible_during_hold() -> void:
	_toast.show_toast(TITLE, DETAIL)
	await wait_seconds(UiTokens.TOAST_FADE_IN + UiTokens.TOAST_HOLD - 0.2)
	assert_true(_toast.visible)
	assert_eq(_toast.modulate.a, 1.0, "pleinement visible pendant la tenue")


func test_new_toast_restarts_hold_without_new_fade() -> void:
	_toast.show_toast(TITLE, DETAIL)
	await wait_seconds(UiTokens.TOAST_FADE_IN + 1.0)
	_toast.show_toast("Potion ×1", "Ajoutée au Sac")
	assert_eq(_toast.modulate.a, 1.0, "pas de nouveau fondu d'apparition")
	assert_eq(_toast.get_title_text(), "Potion ×1")
	await wait_seconds(UiTokens.TOAST_HOLD - 0.5)
	assert_true(_toast.visible, "la tenue est repartie de zéro")
	assert_signal_emit_count(_toast, "haptic_played", 2)


func test_hide_now_fades_quickly() -> void:
	_toast.show_toast(TITLE, DETAIL)
	await wait_process_frames(2)
	_toast.hide_now()
	assert_true(_toast.visible, "fondu, pas de coupure")
	await wait_seconds(UiTokens.ANIM_MICRO + 0.05)
	assert_false(_toast.visible)
	assert_signal_emit_count(_toast, "toast_hidden", 1)


func test_instant_with_speed_scale_zero() -> void:
	_toast.speed_scale = 0.0
	_toast.show_toast(TITLE, DETAIL)
	await wait_process_frames(3)
	assert_false(_toast.visible)
	assert_signal_emit_count(_toast, "toast_hidden", 1)


func test_no_touch_intercepted() -> void:
	for node: Node in [_toast] + _toast.find_children("*", "Control", true, false):
		assert_eq((node as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, node.name)
	# Un bouton sous le toast reçoit le toucher.
	var screen := Control.new()
	screen.size = Vector2(1200, SCREEN_HEIGHT)
	add_child_autofree(screen)
	var button := Button.new()
	screen.add_child(button)
	var toast := (load(TOAST_SCENE) as PackedScene).instantiate() as Toast
	toast.haptics_enabled = false
	screen.add_child(toast)
	toast.show_toast(TITLE, DETAIL)
	await wait_seconds(UiTokens.TOAST_FADE_IN + 0.05)
	var rect := toast.get_body().get_global_rect()
	button.position = rect.position
	button.size = rect.size
	watch_signals(button)
	for pressed: bool in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = rect.get_center()
		mouse.global_position = rect.get_center()
		mouse.pressed = pressed
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		get_viewport().push_input(mouse, true)
		await wait_process_frames(1)
	assert_signal_emitted(button, "pressed", "le toucher traverse le toast")


func test_top_center_inside_safe_margin() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := Control.new()
		screen.size = Vector2(width, SCREEN_HEIGHT)
		add_child_autofree(screen)
		var toast := (load(TOAST_SCENE) as PackedScene).instantiate() as Toast
		toast.haptics_enabled = false
		toast.speed_scale = 0.0
		screen.add_child(toast)
		toast.show_toast(TITLE, DETAIL)
		await wait_process_frames(2)
		var rect := toast.get_global_rect()
		assert_almost_eq(rect.get_center().x, width * 0.5, 1.0, "centré à %d" % width)
		assert_eq(rect.position.y, float(UiTokens.TOAST_TOP), "en haut à %d" % width)
		assert_true(rect.position.y >= UiTokens.SAFE_MARGIN)
		assert_true(rect.size.y < SCREEN_HEIGHT * 0.15, "discret")
		var caption_top := float(UiTokens.CAPTION_TOP)
		assert_lt(rect.end.y, caption_top, "au-dessus de la légende sur le monde")


func test_exploration_hud_shows_toast_even_with_controls_hidden() -> void:
	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(hud)
	hud.get_toast().haptics_enabled = false
	hud.set_controls_visible(false)
	hud.show_toast(TITLE, DETAIL)
	var toast := hud.get_toast()
	assert_true(toast.visible, "visible pendant une scène")
	assert_eq(toast.get_title_text(), TITLE)
	assert_eq(toast.get_detail_text(), DETAIL)
	assert_false(hud.are_controls_visible(), "les contrôles restent cachés")
	assert_false(hud.get_run_button().visible)


# --- Taille du texte et contraste (UiPrefs, T28) -----------------------------------------------


func test_large_text_and_contrast_apply_at_each_display() -> void:
	var title := _toast.get_node(^"%Title") as Label
	var base := title.get_theme_font_size(&"font_size")
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	settings.high_contrast = true
	UiPrefs.apply(settings)
	_toast.show_toast(TITLE, DETAIL)
	assert_eq(title.get_theme_font_size(&"font_size"), roundi(base * UiTokens.TEXT_SCALE_LARGE))
	var box := _toast.get_body().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_gte(box.bg_color.a, UiTokens.CONTRAST_PANEL_ALPHA - 0.001)
	var detail := _toast.get_node(^"%Detail") as Label
	assert_eq(detail.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED_CONTRAST)
	UiPrefs.reset()
	_toast.show_toast(TITLE, DETAIL)
	assert_eq(title.get_theme_font_size(&"font_size"), base, "retour à la normale")
	assert_eq(detail.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED)
