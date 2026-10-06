extends GutTest
## ExpSummaryCard (bilan de fin de combat, demande n° 1) avec de vraies durées : les barres
## partent ensemble ; un toucher accélère, un second termine ; la consigne n'apparaît qu'à la
## fin ; un toucher ferme ; deux niveaux d'un coup : chaque passage est montré (« Nv. 9 » puis
## « Nv. 10 »), gains cumulés, une vibration par niveau ; retour ferme à tout moment ; une vue
## invalide est refusée. Placement : centré, dans l'écran de la HUD (sans débord).

const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const CARD_SCENE := preload("res://game/ui/battle/exp_summary_card.tscn")
const SCREEN := Vector2(2340, 1080)

var _hud: BattleHud
var _card: ExpSummaryCard
var _haptics: Array[int] = []


func before_each() -> void:
	_hud = HUD_SCENE.instantiate() as BattleHud
	_hud.haptics_enabled = false
	add_child_autofree(_hud)
	_hud.get_screen().size = SCREEN
	_card = CARD_SCENE.instantiate() as ExpSummaryCard
	_hud.get_screen().add_child(_card)
	BattleHudLayout.place(_card, BattleHudLayout.Slot.SUMMARY)
	_card.haptics_enabled = false
	_haptics.clear()
	_card.haptic_played.connect(func(ms: int) -> void: _haptics.append(ms))
	await wait_process_frames(2)


func _row(name: String, segments: Array[Vector2], points: Array[Vector3i],
		levels: PackedStringArray = PackedStringArray(),
		stats: PackedStringArray = PackedStringArray()) -> ExpSummaryRowView:
	var view := ExpSummaryRowView.new()
	view.display_name = name
	view.gain_text = "+28 XP"
	view.start_level_text = "Nv. 8"
	view.segments = segments
	view.points = points
	view.level_texts = levels
	view.stat_texts = stats
	return view


func _plain(name: String) -> ExpSummaryRowView:
	return _row(name, [Vector2(0.2, 0.6)] as Array[Vector2],
		[Vector3i(20, 60, 100)] as Array[Vector3i])


func _two_levels() -> ExpSummaryRowView:
	return _row("Salamèche", [Vector2(0.5, 1.0), Vector2(0.0, 1.0), Vector2(0.0, 0.3)]
		as Array[Vector2], [Vector3i(50, 100, 100), Vector3i(0, 120, 120), Vector3i(0, 42, 140)]
		as Array[Vector3i], PackedStringArray(["Nv. 9", "Nv. 10"]),
		PackedStringArray(["PV +2 · Attaque +1", "PV +5 · Attaque +2"]))


func _touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = SCREEN * 0.5
	get_viewport().push_input(touch)


func _views(list: Array) -> Array[ExpSummaryRowView]:
	var views: Array[ExpSummaryRowView] = []
	views.assign(list)
	return views


func test_bars_fill_together_then_hint_then_a_touch_closes() -> void:
	var done: Array[bool] = [false, false]
	var runner := func() -> void:
		await _card.show_summary(_views([_plain("Roucool"), _plain("Rattata")]), "Touchez")
		done[0] = true
		await _card.wait_closed()
		done[1] = true
	runner.call()
	await wait_seconds(UiTokens.ANIM_PANEL + UiTokens.SUMMARY_START_DELAY
		+ UiTokens.SUMMARY_FILL * 0.5)
	var rows := _card.get_rows()
	assert_eq(rows.size(), 2)
	var a := rows[0].get_bar().get_fraction()
	var b := rows[1].get_bar().get_fraction()
	assert_true(a > 0.2 and a < 0.6, "barre en route (%f)" % a)
	assert_almost_eq(a, b, 0.05, "les barres progressent ensemble")
	assert_false(_card.is_hint_shown(), "pas de consigne pendant le remplissage")
	await wait_until(func() -> bool: return done[0], 3.0)
	assert_true(_card.is_filled())
	assert_almost_eq(rows[0].get_bar().get_fraction(), 0.6, 0.0001, "barre à sa valeur finale")
	assert_eq(rows[0].get_points_text(), "60 / 100")
	assert_eq(rows[0].get_level_text(), "Nv. 8", "pas de niveau gagné")
	assert_eq(rows[0].get_stats_text(), "")
	assert_false(rows[0].is_lit())
	await wait_seconds(UiTokens.SUMMARY_HINT_FADE + 0.05)
	assert_true(_card.is_hint_shown(), "la consigne apparaît à la fin")
	assert_eq(_card.get_hint_text(), "Touchez")
	assert_false(done[1], "rien ne se ferme tout seul")
	_touch()
	await wait_until(func() -> bool: return done[1], 2.0)
	assert_true(done[1], "un toucher ferme")
	assert_false(_card.visible)
	assert_push_error_count(0)


func test_first_touch_accelerates_second_finishes() -> void:
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _card.show_summary(_views([_two_levels()]), "Touchez")
		done[0] = true
	runner.call()
	await wait_seconds(UiTokens.SUMMARY_TOUCH_LOCK + 0.05)
	_touch()
	await wait_process_frames(2)
	assert_true(_card.is_accelerated(), "premier toucher : accéléré")
	assert_false(done[0], "pas encore fini")
	_touch()
	await wait_process_frames(2)
	assert_true(done[0], "second toucher : tout est arrivé")
	var row := _card.get_rows()[0]
	assert_eq(row.get_level_text(), "Nv. 10")
	assert_eq(row.get_stats_text(), "PV +5 · Attaque +2", "gains cumulés")
	assert_eq(row.get_points_text(), "42 / 140", "nombres du dernier niveau")
	assert_almost_eq(row.get_bar().get_fraction(), 0.3, 0.0001)
	assert_true(row.is_lit())
	assert_push_error_count(0)


func test_two_levels_show_each_level_and_vibrate_twice() -> void:
	var levels: Array[String] = []
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _card.show_summary(_views([_two_levels(), _plain("Roucool")]), "Touchez")
		done[0] = true
	runner.call()
	var row: ExpSummaryRow = null
	while not done[0]:
		if row == null and not _card.get_rows().is_empty():
			row = _card.get_rows()[0]
		if row != null:
			var text := row.get_level_text()
			if levels.is_empty() or levels[-1] != text:
				levels.append(text)
		await wait_process_frames(1)
	assert_eq(levels, ["Nv. 8", "Nv. 9", "Nv. 10"] as Array[String], "chaque passage montré")
	assert_eq(_haptics.count(UiTokens.HAPTIC_LEVEL_UP_MS), 2, "une vibration par niveau")
	assert_false(_card.get_rows()[1].is_lit(), "seule la ligne qui monte est mise en valeur")
	assert_push_error_count(0)


func test_back_closes_at_any_time() -> void:
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _card.show_summary(_views([_two_levels()]), "Touchez")
		await _card.wait_closed()
		done[0] = true
	runner.call()
	await wait_process_frames(3)
	assert_true(_card.handle_back(), "retour : le bilan s'en sert")
	await wait_until(func() -> bool: return done[0], 2.0)
	assert_true(done[0], "fermé")
	assert_false(_card.handle_back(), "fermé : retour ne sert plus")
	assert_push_error_count(0)


func test_card_is_centered_inside_the_screen() -> void:
	var views: Array[ExpSummaryRowView] = []
	for i: int in 6:
		views.append(_two_levels())
	_card.speed_scale = 0.0
	await _card.show_summary(views, "Touchez")
	await wait_process_frames(2)
	var frame := _card.get_frame().get_global_rect()
	var hint := _card.get_hint().get_global_rect()
	var screen := Rect2(Vector2.ZERO, SCREEN).grow(-UiTokens.SAFE_MARGIN)
	assert_true(screen.encloses(frame.merge(hint)), "six lignes et la consigne tiennent (%s)"
		% frame.merge(hint))
	assert_almost_eq(frame.get_center().x, SCREEN.x * 0.5, 1.0, "centrée")


func _luminance(c: Color) -> float:
	var lin := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)


func _ratio(fg: Color, bg: Color) -> float:
	var a := _luminance(fg)
	var b := _luminance(bg)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


func test_texts_are_readable_sizes_and_contrasted() -> void:
	_card.speed_scale = 0.0
	await _card.show_summary(_views([_two_levels()]), "Touchez")
	await wait_process_frames(2)
	var row := _card.get_rows()[0]
	var theme := _card.get_theme()
	if theme == null:
		theme = ThemeDB.get_project_theme()
	for variation: StringName in [&"SummaryName", &"SummaryLevel", &"SummaryLevelUp",
			&"SummaryPoints", &"SummaryGain", &"SummaryStatName", &"SummaryStatValue",
			&"SummaryHintText"]:
		var minimum := UiTokens.FONT_CAPTION if variation == &"SummaryHintText" \
			else UiTokens.FONT_BODY
		assert_gte(theme.get_font_size(&"font_size", variation), minimum,
			"taille lisible : %s" % variation)
	# Fond réel d'un texte : la carte composée sur un décor clair (pire cas).
	var bg := UiTokens.SUMMARY_CARD_BG
	assert_gte(bg.a, 0.95, "carte quasi opaque")
	var worst := Color(1, 1, 1).lerp(Color(bg.r, bg.g, bg.b), bg.a)
	for fg: Color in [UiTokens.SUMMARY_SECONDARY, UiTokens.TEXT, UiTokens.ACCENT]:
		assert_gte(_ratio(fg, worst), 7.0, "contraste %s sur %s" % [fg, worst])
	assert_gte(_ratio(UiTokens.SUMMARY_SECONDARY, Color(0.06, 0.09, 0.13)), 9.0)
	assert_eq(row.get_stats_text(), "PV +5 · Attaque +2")


func test_stats_are_a_grid_with_reserved_space() -> void:
	var view := _row("Salamèche", [Vector2(0.5, 1.0), Vector2(0.0, 0.3)] as Array[Vector2],
		[Vector3i(50, 100, 100), Vector3i(0, 30, 100)] as Array[Vector3i],
		PackedStringArray(["Nv. 9"]), PackedStringArray([
			"PV +2 · Attaque +1 · Défense +1 · Atq. Spé. +2 · Déf. Spé. +1 · Vitesse +1"]))
	_card.speed_scale = 0.0
	await _card.show_summary(_views([view]), "Touchez")
	await wait_process_frames(2)
	var grid := _card.find_children("*", "GridContainer", true, false)[0] as GridContainer
	assert_eq(grid.columns, 2)
	assert_eq(grid.get_child_count(), 6, "six gains : 2 colonnes × 3 lignes")
	assert_eq(_card.get_rows()[0].get_stats_text().split(" · ").size(), 6)


func test_invalid_views_are_refused() -> void:
	var bad := _plain("")
	await _card.show_summary(_views([bad]), "Touchez")
	assert_push_error("vues invalides")
	assert_false(_card.visible)
	await _card.show_summary([] as Array[ExpSummaryRowView], "Touchez")
	assert_push_error_count(2)
