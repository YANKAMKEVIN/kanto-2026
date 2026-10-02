extends GutTest
## HUD d'exploration : calque, titre de zone (texte, placement, cycle d'animation),
## placement du bouton courir, câblage dans Boot.

const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"
const TITLE_SCENE := "res://game/ui/components/zone_title.tscn"
## Largeurs d'écran visées par l'aspect expand (1080 de haut) : 16:9 et S24.
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0

var _hud: ExplorationHud


func before_each() -> void:
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(_hud)


func test_is_hud_canvas_layer() -> void:
	assert_eq(_hud.layer, UiTokens.LAYER_HUD)
	assert_eq(UiTokens.LAYER_HUD, 10)


func test_zone_title_hidden_before_arrival() -> void:
	assert_false(_hud.get_zone_title().is_showing())


func test_show_zone_title_texts() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	var title := _hud.get_zone_title()
	assert_true(title.is_showing())
	assert_eq(title.get_zone_name_text(), "BOURG PALETTE")
	assert_eq(title.get_region_text(), "Kanto")


func test_zone_title_top_left_inside_safe_margin() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	var title := _hud.get_zone_title()
	var rest := title.get_rest_position()
	assert_eq(rest, Vector2.ONE * UiTokens.SAFE_MARGIN)
	assert_true(rest.x >= 48.0 and rest.y >= 48.0)
	assert_true(title.size.x > 0.0 and title.size.y > 0.0)
	assert_true(rest.y + title.size.y < SCREEN_HEIGHT * 0.5, "reste en haut de l'écran")
	assert_true(rest.x + title.size.x < SCREEN_WIDTHS[0] * 0.5, "reste à gauche")


func test_zone_title_styles() -> void:
	var title := _hud.get_zone_title()
	var name_label := title.get_node(^"%NameLabel") as Label
	var region_label := title.get_node(^"%RegionLabel") as Label
	assert_eq(name_label.get_theme_font_size(&"font_size"), UiTokens.FONT_TITLE)
	assert_eq(region_label.get_theme_font_size(&"font_size"), UiTokens.FONT_CAPTION)
	assert_eq(region_label.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED)
	assert_eq(name_label.get_theme_color(&"font_color"), UiTokens.TEXT)
	var bold := name_label.get_theme_font(&"font") as FontVariation
	assert_not_null(bold, "nom de zone en gras")


func test_zone_title_animation_cycle() -> void:
	var title := (load(TITLE_SCENE) as PackedScene).instantiate() as ZoneTitle
	title.slide_duration = 0.05
	title.hold_duration = 0.1
	add_child_autofree(title)
	watch_signals(title)
	# État relevé à l'émission même de title_shown : une image longue (chargement d'une
	# autre scène) peut faire parcourir tout le Tween en une seule étape.
	var at_shown := {}
	title.title_shown.connect(func() -> void:
		at_shown["position"] = title.position
		at_shown["alpha"] = title.modulate.a)
	title.show_title("Route 1", "Kanto")
	assert_eq(title.position.x, UiTokens.SAFE_MARGIN - UiTokens.PANEL_SLIDE, "part décalé")
	await wait_for_signal(title.title_hidden, 1.0)
	assert_signal_emitted(title, "title_shown")
	assert_eq(at_shown.get("position"), title.get_rest_position())
	assert_almost_eq(at_shown.get("alpha", 0.0) as float, 1.0, 0.01)
	assert_signal_emitted(title, "title_hidden")
	assert_false(title.is_showing())


func test_hide_zone_title_during_display() -> void:
	watch_signals(_hud)
	_hud.show_zone_title("Bourg Palette", "Kanto")
	await wait_process_frames(2)
	var title := _hud.get_zone_title()
	assert_true(title.is_showing())
	_hud.hide_zone_title()
	# Temps de jeu écoulé (somme des delta, comme le Tween) avant l'image où le titre est
	# vu caché : au plus ANIM_MICRO + une image.
	var elapsed := 0.0
	var last_delta := 0.0
	while title.is_showing() and elapsed < 1.0:
		await get_tree().process_frame
		last_delta = get_process_delta_time()
		elapsed += last_delta
	assert_false(title.is_showing())
	assert_true(elapsed - last_delta <= UiTokens.ANIM_MICRO + last_delta + 0.001,
		"caché en %f s (≤ ANIM_MICRO + 1 image)" % elapsed)
	await wait_process_frames(1)
	assert_signal_emit_count(_hud, "title_hidden", 1)


func test_hide_zone_title_while_holding() -> void:
	var title := (load(TITLE_SCENE) as PackedScene).instantiate() as ZoneTitle
	title.slide_duration = 0.05
	title.hold_duration = 5.0
	add_child_autofree(title)
	watch_signals(title)
	title.show_title("Route 1", "Kanto")
	await wait_for_signal(title.title_shown, 1.0)
	title.hide_now()
	assert_true(await wait_for_signal(title.title_hidden, 1.0), "caché sans attendre le maintien")
	assert_false(title.is_showing())
	assert_signal_emit_count(title, "title_hidden", 1)
	assert_eq(title.modulate.a, 0.0)


func test_hide_now_is_a_fade_not_a_cut() -> void:
	var title := _hud.get_zone_title()
	_hud.show_zone_title("Bourg Palette", "Kanto")
	await wait_process_frames(1)
	var alpha_before := title.modulate.a
	_hud.hide_zone_title()
	assert_true(title.is_showing(), "pas de disparition sèche")
	assert_eq(title.modulate.a, alpha_before, "le fondu part de l'opacité courante")
	await wait_for_signal(_hud.title_hidden, 1.0)
	assert_false(title.is_showing())


func test_hide_zone_title_when_hidden_does_nothing() -> void:
	watch_signals(_hud)
	_hud.hide_zone_title()
	await wait_process_frames(2)
	assert_false(_hud.get_zone_title().is_showing())
	assert_signal_not_emitted(_hud, "title_hidden")


func test_show_after_hide_restarts_title() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	_hud.hide_zone_title()
	await wait_for_signal(_hud.title_hidden, 1.0)
	var title := _hud.get_zone_title()
	watch_signals(title)
	_hud.show_zone_title("Route 1", "Kanto")
	assert_true(title.is_showing())
	assert_eq(title.get_zone_name_text(), "ROUTE 1")
	assert_true(await wait_for_signal(title.title_shown, 1.0), "le nouveau titre s'affiche")
	assert_signal_not_emitted(title, "title_hidden")


func test_title_hidden_relayed_at_natural_end() -> void:
	var title := _hud.get_zone_title()
	title.slide_duration = 0.02
	title.hold_duration = 0.02
	watch_signals(_hud)
	_hud.show_zone_title("Bourg Palette", "Kanto")
	await wait_for_signal(_hud.title_hidden, 1.0)
	assert_signal_emit_count(_hud, "title_hidden", 1)


func test_zone_title_default_timing_from_tokens() -> void:
	var title := _hud.get_zone_title()
	assert_eq(title.slide_duration, 0.3)
	assert_eq(title.hold_duration, 2.5)


func test_run_button_in_right_half_inside_safe_margin() -> void:
	var button := _hud.get_run_button()
	assert_eq(button.action, "run")
	var radius := UiTokens.ROUND_BUTTON * 0.5
	var from_corner := -button.position
	for width: float in SCREEN_WIDTHS:
		var center := Vector2(width, SCREEN_HEIGHT) - from_corner
		assert_true(center.x - radius >= width * 0.5, "moitié droite (%d)" % width)
		assert_true(center.x + radius <= width - UiTokens.SAFE_MARGIN, "bord droit")
		assert_true(center.y + radius <= SCREEN_HEIGHT - UiTokens.SAFE_MARGIN, "bord bas")
		assert_true(center.y - radius >= UiTokens.SAFE_MARGIN, "bord haut")


func test_run_button_anchored_bottom_right() -> void:
	var anchor := _hud.get_run_button().get_parent() as Control
	assert_eq(Vector4(anchor.anchor_left, anchor.anchor_top, anchor.anchor_right,
		anchor.anchor_bottom), Vector4.ONE)


func test_focus_out_releases_run() -> void:
	Input.action_press(&"run")
	_hud.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(Input.is_action_pressed(&"run"))


func test_paused_releases_run() -> void:
	Input.action_press(&"run")
	_hud.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_false(Input.is_action_pressed(&"run"))


func test_joystick_covers_screen() -> void:
	var joystick := _hud.get_joystick()
	assert_eq(Vector4(joystick.anchor_left, joystick.anchor_top, joystick.anchor_right,
		joystick.anchor_bottom), Vector4(0, 0, 1, 1))
	assert_false(joystick.is_active())


func test_boot_shows_no_zone_title_in_bedroom() -> void:
	# Jalon 2 : départ dans la chambre, sans titre (il vient à la première sortie).
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	var hud := boot.get_node(^"%ExplorationHud") as ExplorationHud
	assert_not_null(hud)
	assert_false(hud.get_zone_title().is_showing())


# --- Bouton contextuel (jalon 3A, T2) ---------------------------------------------------------

const VERB_LABELS: Dictionary[StringName, String] = {
	&"talk": "PARLER", &"examine": "EXAMINER", &"observe": "OBSERVER", &"take": "PRENDRE",
	&"meet": "RENCONTRER",
}
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]


func after_each() -> void:
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	get_viewport().push_input(event, true)


## Temps de jeu (somme des delta) avant l'image où [param node] est vu caché.
func _time_until_hidden(node: CanvasItem) -> Array[float]:
	var elapsed := 0.0
	var last_delta := 0.0
	while node.visible and elapsed < 1.0:
		await get_tree().process_frame
		last_delta = get_process_delta_time()
		elapsed += last_delta
	return [elapsed, last_delta]


func test_interact_button_hidden_at_start() -> void:
	var button := _hud.get_interact_button()
	assert_false(button.visible)
	assert_eq(button.get_verb(), &"")


func test_show_interact_talk_shows_parler() -> void:
	_hud.show_interact(&"talk")
	var button := _hud.get_interact_button()
	assert_true(button.visible)
	assert_eq(button.get_label_text(), "PARLER")
	assert_eq(button.get_verb(), &"talk")
	assert_not_null(button.get_icon())
	await wait_seconds(UiTokens.ANIM_MICRO + 0.05)
	assert_almost_eq(button.modulate.a, 1.0, 0.001, "apparu en fondu")


func test_each_verb_has_label_and_own_icon() -> void:
	var button := _hud.get_interact_button()
	var icons: Array[Texture2D] = []
	for verb: StringName in VERB_LABELS:
		_hud.show_interact(verb)
		assert_eq(button.get_label_text(), VERB_LABELS[verb], String(verb))
		assert_not_null(button.get_icon(), String(verb))
		assert_false(button.get_icon() in icons, "icône propre à %s" % verb)
		icons.append(button.get_icon())


func test_show_interact_fades_in() -> void:
	_hud.show_interact(&"examine")
	var button := _hud.get_interact_button()
	assert_true(button.modulate.a < 1.0, "pas d'apparition sèche")


func test_hide_interact_within_anim_micro_plus_one_frame() -> void:
	_hud.show_interact(&"talk")
	await wait_seconds(UiTokens.ANIM_MICRO + 0.05)
	var button := _hud.get_interact_button()
	_hud.hide_interact()
	assert_eq(button.get_verb(), &"")
	var timing := await _time_until_hidden(button)
	assert_false(button.visible)
	assert_true(timing[0] - timing[1] <= UiTokens.ANIM_MICRO + timing[1] + 0.001,
		"caché en %f s (≤ ANIM_MICRO + 1 image)" % timing[0])


func test_show_again_during_hide_keeps_button() -> void:
	_hud.show_interact(&"talk")
	await wait_seconds(UiTokens.ANIM_MICRO + 0.05)
	_hud.hide_interact()
	await wait_process_frames(1)
	_hud.show_interact(&"observe")
	await wait_seconds(UiTokens.ANIM_MICRO + 0.05)
	var button := _hud.get_interact_button()
	assert_true(button.visible)
	assert_eq(button.get_label_text(), "OBSERVER")
	assert_almost_eq(button.modulate.a, 1.0, 0.001)


func test_interact_button_action_and_placement() -> void:
	var button := _hud.get_interact_button()
	assert_eq(button.action, "interact")
	assert_eq(-button.position, UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER)
	assert_eq(button.get_parent(), _hud.get_run_button().get_parent(), "même ancre bas-droite")
	var shape := button.shape as CircleShape2D
	assert_not_null(shape)
	assert_true(shape.radius * 2.0 >= UiTokens.TOUCH_MIN, "zone touchable ≥ TOUCH_MIN")
	var radius := shape.radius
	var run_radius := UiTokens.ROUND_BUTTON * 0.5
	for width: float in SCREEN_WIDTHS:
		var corner := Vector2(width, SCREEN_HEIGHT)
		var center := corner - UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER
		assert_true(center.x + radius <= width - UiTokens.SAFE_MARGIN, "bord droit (%d)" % width)
		assert_true(center.y + radius <= SCREEN_HEIGHT - UiTokens.SAFE_MARGIN, "bord bas")
		assert_true(center.x - radius >= width * 0.5, "moitié droite (%d)" % width)
		assert_true(center.y > SCREEN_HEIGHT * 0.5, "moitié basse")
		var run_center := corner - UiTokens.RUN_BUTTON_CENTER_FROM_CORNER
		assert_true(center.distance_to(run_center) >= radius + run_radius + UiTokens.GAP,
			"ne chevauche pas le bouton courir (%d)" % width)


func test_interact_label_left_of_button_clear_of_run() -> void:
	for verb: StringName in VERB_LABELS:
		_hud.show_interact(verb)
		await wait_process_frames(1)
		var button := _hud.get_interact_button()
		var tag_rect := button.get_tag().get_global_rect()
		var center := button.global_position
		assert_true(tag_rect.end.x <= center.x - UiTokens.ROUND_BUTTON * 0.5,
			"pastille à gauche (%s)" % verb)
		assert_almost_eq(tag_rect.get_center().y, center.y, 1.0, "centrée verticalement")
		var run := _hud.get_run_button().global_position
		var run_rect := Rect2(run - Vector2.ONE * UiTokens.ROUND_BUTTON * 0.5,
			Vector2.ONE * UiTokens.ROUND_BUTTON)
		assert_false(tag_rect.intersects(run_rect), "pastille hors du bouton courir (%s)" % verb)


func test_touching_interact_button_presses_interact() -> void:
	_hud.show_interact(&"talk")
	await wait_process_frames(1)
	var center := _hud.get_interact_button().global_position
	_touch(1, center, true)
	assert_true(Input.is_action_pressed(&"interact"))
	_touch(1, center, false)
	assert_false(Input.is_action_pressed(&"interact"))


func test_hidden_interact_button_ignores_touch() -> void:
	await wait_process_frames(1)
	var center := _hud.get_interact_button().global_position
	_touch(1, center, true)
	assert_false(Input.is_action_pressed(&"interact"))
	_touch(1, center, false)


func test_set_controls_visible_false_hides_and_releases() -> void:
	_hud.show_interact(&"talk")
	await wait_process_frames(1)
	var interact := _hud.get_interact_button()
	_touch(1, interact.global_position, true)
	Input.action_press(&"run")
	Input.action_press(&"move_left")
	assert_true(Input.is_action_pressed(&"interact"))
	_hud.set_controls_visible(false)
	assert_false(_hud.are_controls_visible())
	assert_false(_hud.get_joystick().visible, "joystick caché")
	assert_false(_hud.get_run_button().visible, "courir caché")
	assert_false(interact.visible, "contextuel caché")
	for action: StringName in MOVE_ACTIONS + [&"run", &"interact"] as Array[StringName]:
		assert_false(Input.is_action_pressed(action), "%s relâchée" % action)
	_touch(1, interact.global_position, false)


func test_show_interact_while_controls_hidden_waits() -> void:
	_hud.set_controls_visible(false)
	_hud.show_interact(&"examine")
	assert_false(_hud.get_interact_button().visible, "pas pendant un dialogue")
	_hud.set_controls_visible(true)
	var button := _hud.get_interact_button()
	assert_true(button.visible, "réapparaît avec les contrôles")
	assert_eq(button.get_label_text(), "EXAMINER")
	assert_true(_hud.get_run_button().visible)
	assert_true(_hud.get_joystick().visible)


func test_controls_back_without_target_keep_interact_hidden() -> void:
	_hud.show_interact(&"talk")
	_hud.set_controls_visible(false)
	_hud.hide_interact()
	_hud.set_controls_visible(true)
	assert_false(_hud.get_interact_button().visible)


func test_controls_back_after_touch_release_not_stuck_pressed() -> void:
	_hud.show_interact(&"talk")
	await wait_process_frames(1)
	var interact := _hud.get_interact_button()
	_touch(1, interact.global_position, true)
	_hud.set_controls_visible(false)
	_touch(1, interact.global_position, false)
	_hud.set_controls_visible(true)
	await wait_process_frames(1)
	assert_false(interact.is_pressed(), "bouton relâché")
	assert_false((interact.get_node(^"%Visual") as RoundButtonVisual).is_pressed(),
		"visuel relâché")
	assert_false(Input.is_action_pressed(&"interact"))


func test_focus_out_releases_interact() -> void:
	Input.action_press(&"interact")
	_hud.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(Input.is_action_pressed(&"interact"))


func test_boot_has_no_interact_button_in_bedroom() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	var hud := boot.get_node(^"%ExplorationHud") as ExplorationHud
	assert_false(hud.get_interact_button().visible, "aucun bouton sans cible")


# --- RENCONTRER et légende sur le monde (jalon 4A, T2) -----------------------------------------

const CAPTION_TEXT := "Choisis ton premier partenaire"


func test_show_interact_meet_shows_rencontrer_with_meet_icon() -> void:
	_hud.show_interact(&"meet")
	var button := _hud.get_interact_button()
	assert_true(button.visible)
	assert_eq(button.get_verb(), &"meet")
	assert_eq(button.get_label_text(), "RENCONTRER")
	assert_eq(button.get_icon().resource_path, "res://assets/ui/icons/meet.svg")


func test_meet_tag_inside_safe_margin_at_1920_and_2340() -> void:
	for verb: StringName in VERB_LABELS:
		_hud.show_interact(verb)
		await wait_process_frames(1)
		var button := _hud.get_interact_button()
		var tag := button.get_tag()
		# Pastille relative au centre du bouton, lui-même relatif au coin bas-droit.
		var local := Rect2(tag.position, tag.size)
		for width: float in SCREEN_WIDTHS:
			var corner := Vector2(width, SCREEN_HEIGHT)
			var center := corner - UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER
			var rect := Rect2(center + local.position, local.size)
			var inside := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
				Vector2(width, SCREEN_HEIGHT) - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
			assert_true(inside.encloses(rect),
				"%s dans SAFE_MARGIN à %d (%s)" % [verb, width, rect])
			assert_true(rect.position.x >= width * 0.5, "%s dans la moitié droite" % verb)


func test_caption_hidden_at_start() -> void:
	assert_false(_hud.get_caption().is_showing())


func test_show_caption_uppercase_top_center_without_panel() -> void:
	_hud.show_caption(CAPTION_TEXT)
	var caption := _hud.get_caption()
	assert_true(caption.is_showing())
	assert_eq(caption.text, "CHOISIS TON PREMIER PARTENAIRE")
	assert_true(caption.modulate.a < 1.0, "apparaît en fondu")
	assert_eq(caption.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	# Sans rectangle : aucun fond de panneau (Label, stylebox normal vide ou transparent).
	assert_true(caption is Label)
	var box := caption.get_theme_stylebox(&"normal")
	assert_true(box == null or box is StyleBoxEmpty
		or (box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a == 0.0), "sans fond")
	assert_eq(caption.get_child_count(), 0, "aucun panneau enfant")
	assert_eq(caption.get_theme_font_size(&"font_size"), UiTokens.FONT_TITLE)
	assert_eq(caption.get_theme_color(&"font_shadow_color"), UiTokens.TEXT_SHADOW)
	assert_eq(Vector2(caption.anchor_left, caption.anchor_right), Vector2(0.5, 0.5))
	await wait_process_frames(1)
	var rect := caption.get_global_rect()
	var width := (_hud.get_node(^"Root") as Control).size.x
	assert_almost_eq(rect.get_center().x, width * 0.5, 1.0, "centrée")
	assert_true(rect.position.y >= UiTokens.SAFE_MARGIN, "sous la marge haute")
	assert_true(rect.end.y < SCREEN_HEIGHT * 0.3, "en haut")


func test_caption_clear_of_zone_title_at_1920_and_2340() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	_hud.show_caption(CAPTION_TEXT)
	await wait_process_frames(1)
	var title := _hud.get_zone_title()
	var title_rect := Rect2(title.get_rest_position(), title.size)
	var caption := _hud.get_caption()
	for width: float in SCREEN_WIDTHS:
		var caption_rect := Rect2(Vector2(width * 0.5 - caption.size.x * 0.5,
			caption.offset_top), caption.size)
		assert_false(caption_rect.intersects(title_rect), "pas de chevauchement (%d)" % width)
		assert_true(caption_rect.position.x >= UiTokens.SAFE_MARGIN, "dans l'écran (%d)" % width)


func test_caption_fades_holds_and_fades_out() -> void:
	var caption := _hud.get_caption()
	watch_signals(_hud)
	var shown_alpha := {}
	caption.caption_shown.connect(func() -> void: shown_alpha["a"] = caption.modulate.a)
	_hud.show_caption(CAPTION_TEXT)
	var elapsed := 0.0
	var last_delta := 0.0
	var seen_full := false
	while caption.is_showing() and elapsed < 10.0:
		await get_tree().process_frame
		last_delta = get_process_delta_time()
		elapsed += last_delta
		if caption.modulate.a >= 0.999:
			seen_full = true
	assert_false(caption.is_showing(), "jamais permanente")
	assert_true(seen_full, "pleinement visible pendant la tenue")
	assert_almost_eq(shown_alpha.get("a", 0.0) as float, 1.0, 0.01)
	var expected := UiTokens.CAPTION_FADE * 2.0 + UiTokens.CAPTION_HOLD
	assert_almost_eq(elapsed, expected, last_delta * 1.5 + 0.001,
		"caché après fondu + CAPTION_HOLD + fondu (%f s)" % elapsed)
	assert_signal_emit_count(_hud, "caption_hidden", 1)


func test_caption_timing_from_tokens() -> void:
	var caption := _hud.get_caption()
	assert_eq(caption.fade_duration, UiTokens.ANIM_PANEL)
	assert_eq(caption.hold_duration, UiTokens.CAPTION_HOLD)
	assert_almost_eq(UiTokens.CAPTION_HOLD, 3.0, 0.5, "≈ 3 s")


func test_hide_caption_fades_quickly() -> void:
	_hud.show_caption(CAPTION_TEXT)
	await wait_process_frames(2)
	watch_signals(_hud)
	_hud.hide_caption()
	assert_true(_hud.get_caption().is_showing(), "pas de disparition sèche")
	var timing := await _time_until_hidden(_hud.get_caption())
	assert_false(_hud.get_caption().is_showing())
	assert_true(timing[0] - timing[1] <= UiTokens.ANIM_MICRO + timing[1] + 0.001)
	await wait_process_frames(1)
	assert_signal_emit_count(_hud, "caption_hidden", 1)


func test_caption_independent_of_controls() -> void:
	_hud.set_controls_visible(false)
	_hud.show_caption(CAPTION_TEXT)
	assert_true(_hud.get_caption().is_showing())


func test_menu_button_top_right_inside_safe_margin() -> void:
	var button := _hud.get_menu_button()
	var radius := UiTokens.ROUND_BUTTON * 0.5
	for width: float in SCREEN_WIDTHS:
		var center := Vector2(width + button.position.x, button.position.y)
		assert_gte(center.x + radius, 0.0)
		assert_lte(center.x + radius, width - UiTokens.SAFE_MARGIN + 0.01, "marge droite")
		assert_gte(center.y - radius, UiTokens.SAFE_MARGIN - 0.01, "marge haute")
		assert_gt(center.x, width * 0.5, "moitié droite")
	assert_eq(UiTokens.ROUND_BUTTON, 128, "zone tactile 128 px")
	var shape := button.shape as CircleShape2D
	assert_not_null(shape)
	assert_eq(shape.radius * 2.0, float(UiTokens.TOUCH_MIN))


func test_menu_button_emits_menu_requested_once() -> void:
	watch_signals(_hud)
	_hud.get_menu_button().pressed.emit()
	assert_signal_emit_count(_hud, "menu_requested", 1)


func test_menu_button_is_translucent_and_follows_controls() -> void:
	var visual := _hud.get_menu_button().get_node(^"Visual") as Node2D
	assert_almost_eq(visual.modulate.a, UiTokens.MENU_BUTTON_ALPHA, 0.001)
	_hud.set_controls_visible(false)
	assert_false(_hud.get_menu_button().visible)
	_hud.set_controls_visible(true)
	assert_true(_hud.get_menu_button().visible)
