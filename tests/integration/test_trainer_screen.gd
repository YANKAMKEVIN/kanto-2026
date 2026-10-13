extends GutTest
## Écran Dresseur du menu (jalon 6, T24 ; §6.11) : 8 badges toujours, muets et non touchables,
## jamais de « 0/8 » ni de « ??? » ; vus / capturés absents si vides ; liens émis tels que la vue
## les donne ; frise vide ; zones tactiles et marges à 1920 et 2340 ; animation à speed_scale = 0.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _routes: Array[MenuRoute] = []
var _backs: int = 0
var _menu: TrainerMenu


func before_each() -> void:
	_routes.clear()
	_backs = 0


func _moment(title: String, route: MenuRoute = null) -> MomentView:
	var moment := MomentView.new()
	moment.kind = MomentLibrary.STARTER
	moment.title = title
	moment.detail = "Détail"
	moment.place = "Bourg Palette"
	moment.date_text = "2 octobre 2026"
	moment.route = route
	return moment


func _view(with_dex: bool = true, moments: int = 3) -> TrainerView:
	var view := TrainerView.new()
	view.player_name = "Kevin"
	view.player_title = "Dresseur Pokémon"
	view.play_time_text = "0 h 26"
	view.started_text = "2 octobre 2026"
	if with_dex:
		view.seen_text = "4 vus"
		view.caught_text = "3 capturés"
		view.seen_route = MenuRoute.pokedex(MenuRoute.DEX_FILTER_SEEN)
		view.caught_route = MenuRoute.pokedex(MenuRoute.DEX_FILTER_CAUGHT)
	for i: int in TrainerView.BADGE_COUNT:
		view.badges.append(BadgeSlotView.new(i))
	for i: int in moments:
		var route: MenuRoute = MenuRoute.team(0) if i == 0 else null
		view.moments.append(_moment("Moment %d" % i, route))
	view.stats.append(TrainerStatView.new(TrainerSummary.STAT_PLAY_TIME, "Temps de jeu", "0 h 26"))
	view.stats.append(TrainerStatView.new(TrainerSummary.STAT_ZONES, "Zones découvertes", "2"))
	return view


func _screen_in(width: int, view: TrainerView) -> TrainerScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	_menu.speed_scale = 0.0
	viewport.add_child(_menu)
	_menu.show_trainer(view)
	_menu.open_animated()
	await wait_process_frames(3)
	var screen := _menu.get_trainer()
	screen.route_requested.connect(func(r: MenuRoute) -> void: _routes.append(r))
	screen.back_requested.connect(func() -> void: _backs += 1)
	return screen


func test_always_eight_silhouette_untouchable_badges() -> void:
	var view := _view()
	view.badges.clear()
	var screen := await _screen_in(2340, view)
	assert_eq(screen.get_badge_slots().size(), 8)
	var emblem: Texture2D = null
	for slot: BadgeSlot in screen.get_badge_slots():
		assert_true(slot.is_muted())
		assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		# MM.2 (décision de Kevin) : silhouette commune et « ??? », ni nom ni apparence du badge.
		assert_eq(slot.get_text(), "???")
		assert_eq(slot.get_emblem().modulate, UiTokens.TRAINER_BADGE_UNKNOWN)
		if emblem == null:
			emblem = slot.get_emblem().texture
		assert_eq(slot.get_emblem().texture, emblem, "la même silhouette pour les huit")
	var texts := screen.get_texts()
	for text: String in texts:
		assert_false(text.contains("Badge "), "aucun nom de badge : %s" % text)
		assert_false(text.contains("/ 8") or text.contains("/8"), text)
	assert_true(texts.has(TrainerView.BADGES_TITLE))
	for control: Control in screen.get_touch_controls():
		for slot: BadgeSlot in screen.get_badge_slots():
			assert_false(slot.is_ancestor_of(control), "aucun toucher dans un badge")


func test_seen_and_caught_absent_when_empty() -> void:
	var screen := await _screen_in(2340, _view(false))
	assert_false(screen.get_seen_button().visible)
	assert_false(screen.get_caught_button().visible)
	var texts := screen.get_texts()
	assert_false(texts.has("4 vus"))


func test_seen_and_caught_emit_one_route_each() -> void:
	var screen := await _screen_in(2340, _view())
	assert_true(screen.get_seen_button().visible)
	screen.get_seen_button().pressed.emit()
	assert_eq(_routes.size(), 1)
	assert_eq(_routes[0].screen, MenuRoute.POKEDEX)
	assert_eq(_routes[0].params["filter"], MenuRoute.DEX_FILTER_SEEN)
	screen.get_caught_button().pressed.emit()
	assert_eq(_routes.size(), 2)
	assert_eq(_routes[1].params["filter"], MenuRoute.DEX_FILTER_CAUGHT)


func test_moment_with_route_emits_one_signal_without_route_nothing() -> void:
	var screen := await _screen_in(2340, _view())
	var rows := screen.get_moment_rows()
	assert_eq(rows.size(), 3)
	assert_true(rows[0].is_linked())
	assert_false(rows[1].is_linked())
	rows[1].get_hit().pressed.emit()
	assert_true(_routes.is_empty())
	assert_true(rows[1].get_hit().disabled)
	rows[0].get_hit().pressed.emit()
	assert_eq(_routes.size(), 1)
	assert_eq(_routes[0].screen, MenuRoute.TEAM)


func test_moments_keep_view_order_and_texts() -> void:
	var screen := await _screen_in(2340, _view())
	var rows := screen.get_moment_rows()
	assert_eq(rows[0].get_texts()[0], "Moment 0")
	assert_eq(rows[2].get_texts()[0], "Moment 2")
	assert_eq(rows[0].get_texts()[2], "Bourg Palette · 2 octobre 2026")


func test_empty_moments_show_the_phrase() -> void:
	var screen := await _screen_in(2340, _view(true, 0))
	assert_not_null(screen.get_empty_label())
	assert_eq(screen.get_empty_label().text, "Ton aventure ne fait que commencer.")
	assert_true(screen.get_moment_rows().is_empty())


func test_second_call_updates_without_replaying_entry() -> void:
	var screen := await _screen_in(2340, _view())
	assert_eq(screen.modulate.a, 1.0)
	var view := _view(true, 1)
	view.player_name = "Léa"
	_menu.show_trainer(view)
	await wait_process_frames(2)
	assert_eq(screen.get_name_label().text, "Léa")
	assert_eq(screen.get_moment_rows().size(), 1)
	assert_eq(screen.modulate.a, 1.0)
	assert_eq(screen.position, Vector2.ZERO)
	assert_eq(_menu.get_current_screen(), screen)


func test_back_emits_one_signal() -> void:
	var screen := await _screen_in(2340, _view())
	screen.get_back_button().pressed.emit()
	assert_eq(_backs, 1)


func test_stats_panel_absent_without_stats() -> void:
	var view := _view()
	view.stats.clear()
	var screen := await _screen_in(2340, view)
	assert_false(screen.get_stats_panel().visible)


func test_touch_zones_and_safe_margin_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _view())
		var controls := screen.get_touch_controls()
		assert_gt(controls.size(), 3)
		for control: Control in controls:
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, "%s à %d" % [control.name,
				width])
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5)
			assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5)
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5)
			assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5)


func test_enter_is_instant_at_speed_zero() -> void:
	var screen := await _screen_in(2340, _view())
	assert_true(screen.visible)
	assert_eq(screen.modulate.a, 1.0)


# --- Toucher ou défilement (retour S24 de la validation J6) -------------------------------------

func test_swipe_from_a_linked_moment_scrolls_and_emits_nothing() -> void:
	var screen := await _screen_in(2340, _view(true, 10))
	var scroll := screen.get_scroll()
	var hit := screen.get_moment_rows()[0].get_hit()
	var from := hit.get_global_rect().get_center()
	assert_true(scroll.get_global_rect().has_point(from), "la ligne liée est visible")
	var finger := TouchFinger.new(screen.get_viewport())
	finger.swipe(from, Vector2(0.0, -200.0))
	await wait_process_frames(2)
	assert_true(_routes.is_empty(), "aucun lien suivi")
	var overflow := scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
	if overflow > 20.0:
		assert_gt(scroll.scroll_vertical, 0, "la frise a défilé")


func test_short_tap_on_a_linked_moment_emits_one_route() -> void:
	var screen := await _screen_in(2340, _view(true, 10))
	var hit := screen.get_moment_rows()[0].get_hit()
	TouchFinger.new(screen.get_viewport()).tap(hit.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(_routes.size(), 1)
	assert_eq(_routes[0].screen, MenuRoute.TEAM)


func test_sideways_swipe_from_a_linked_moment_emits_nothing() -> void:
	var screen := await _screen_in(2340, _view(true, 10))
	var hit := screen.get_moment_rows()[0].get_hit()
	var from := hit.get_global_rect().get_center()
	# Le doigt reste sur la ligne : sans garde, le relâchement l'activerait.
	TouchFinger.new(screen.get_viewport()).swipe(from, Vector2(120.0, 0.0))
	await wait_process_frames(2)
	assert_true(_routes.is_empty(), "un glissement n'est pas un toucher")


# --- Badge obtenu (jalon 10, T6) : touchable, bulle de détail, moment dans la frise -------------

func _roche_view() -> TrainerView:
	var view := _view()
	var badges := BadgeLibrary.new()
	badges.load_file()
	var flags := StoryFlags.new()
	flags.set_flag(&"badge_boulder")
	view.badges = badges.slots(flags)
	var moment := MomentView.new()
	moment.kind = MomentLibrary.BADGE
	moment.title = "Badge Roche"
	moment.detail = "Obtenu à Argenta contre Pierre."
	moment.place = "Argenta"
	moment.date_text = "9 octobre 2026"
	moment.zone_id = &"pewter_city"
	view.moments.append(moment)
	return view


func test_obtained_badge_is_touchable_others_stay_inert() -> void:
	var screen := await _screen_in(2340, _roche_view())
	var slots := screen.get_badge_slots()
	assert_true(slots[0].is_touchable())
	assert_gte(slots[0].get_hit().get_global_rect().size.y, float(UiTokens.TOUCH_MIN) - 0.5)
	for i: int in range(1, 8):
		assert_false(slots[i].is_touchable(), "badge %d muet = inerte" % i)
		assert_eq(slots[i].get_text(), "???")
	screen.open_badge_detail(slots[1])
	assert_null(screen.get_open_bubble(), "un badge muet n'ouvre rien")


func test_touching_obtained_badge_opens_detail_then_closes() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _roche_view())
		var slot := screen.get_badge_slots()[0]
		TouchFinger.new(screen.get_viewport()).tap(slot.get_hit().get_global_rect().get_center())
		await wait_process_frames(2)
		var bubble := screen.get_open_bubble()
		assert_not_null(bubble, "bulle ouverte à %d" % width)
		assert_eq(bubble.get_name_label().text, "Badge Roche")
		assert_eq(bubble.get_detail_label().text, "Argenta — Pierre")
		var rect := bubble.get_global_rect()
		assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5)
		assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5)
		assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5)
		assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5)
		assert_eq(screen.get_open_bubble().get_global_rect().intersects(
			slot.get_global_rect()), false, "la bulle ne couvre pas l'emplacement")
		# Second toucher sur le même badge : fermée.
		TouchFinger.new(screen.get_viewport()).tap(slot.get_hit().get_global_rect().get_center())
		await wait_process_frames(2)
		assert_null(screen.get_open_bubble(), "fermée au second toucher")
		assert_true(_routes.is_empty() and _backs == 0)


func test_touch_elsewhere_closes_detail_without_acting() -> void:
	var screen := await _screen_in(2340, _roche_view())
	screen.open_badge_detail(screen.get_badge_slots()[0])
	assert_not_null(screen.get_open_bubble())
	# Sur la ligne de la frise liée : ferme la bulle, ne suit pas le lien.
	var hit := screen.get_moment_rows()[0].get_hit()
	TouchFinger.new(screen.get_viewport()).tap(hit.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_null(screen.get_open_bubble())
	assert_true(_routes.is_empty(), "le toucher n'a fait que fermer")


func test_refresh_closes_the_detail() -> void:
	var screen := await _screen_in(2340, _roche_view())
	screen.open_badge_detail(screen.get_badge_slots()[0])
	screen.show_trainer(_roche_view())
	assert_null(screen.get_open_bubble())


func test_badge_moment_shows_in_the_timeline_with_emblem() -> void:
	var screen := await _screen_in(2340, _roche_view())
	var texts := screen.get_texts()
	assert_true(texts.has("Badge Roche"))
	assert_true(texts.has("Obtenu à Argenta contre Pierre."))
	assert_true(texts.has("Argenta · 9 octobre 2026"))
	var rows := screen.get_moment_rows()
	assert_eq(rows[rows.size() - 1].get_view().kind, MomentLibrary.BADGE)


func test_portrait_never_under_identity_text_with_long_money() -> void:
	for width: int in WIDTHS:
		var view := _view()
		view.money_text = "999 999 ₽"
		var screen := await _screen_in(width, view)
		await wait_process_frames(3)
		var portrait := screen.get_portrait().get_global_rect()
		for row: Control in [screen._started_row, screen._money_row]:
			var rect := row.get_global_rect()
			assert_lte(rect.end.y, portrait.position.y + 0.5,
				"la ligne d'identité reste au-dessus du portrait (%d)" % width)


# --- Jalon 12 (T24) : ligne « fossile » de la frise ----------------------------------------

func _fossil_view(zone: StringName, item: StringName = &"") -> TrainerView:
	var view := _view(true, 0)
	var moment := MomentView.new()
	moment.kind = MomentLibrary.FOSSIL
	moment.title = "La Team Rocket repoussée"
	moment.detail = "Fossile Dôme obtenu."
	moment.place = "Mont Sélénite"
	moment.date_text = "13 octobre 2026"
	moment.zone_id = zone
	moment.item_id = item
	view.moments.append(moment)
	return view


func test_fossil_moment_uses_the_painted_icon_of_the_item() -> void:
	for item: StringName in [&"dome_fossil", &"helix_fossil"]:
		var painted: Texture2D = load("res://assets/ui/items/%s.webp" % item)
		for zone: StringName in [&"mt_moon", &""]:
			var screen := await _screen_in(2340, _fossil_view(zone, item))
			assert_eq(screen.get_moment_rows()[0].get_icon(), painted,
				"%s (zone « %s »)" % [item, zone])
	var key: Texture2D = load("res://assets/ui/icons/bag/key.svg")
	var fallback := await _screen_in(2340, _fossil_view(&"", &"objet_sans_icone"))
	assert_eq(fallback.get_moment_rows()[0].get_icon(), key, "repli : objets clés")


func test_fossil_moment_shows_validated_texts_and_the_key_item_icon() -> void:
	var key: Texture2D = load("res://assets/ui/icons/bag/key.svg")
	for zone: StringName in [&"mt_moon", &""]:
		var screen := await _screen_in(2340, _fossil_view(zone))
		var texts := screen.get_texts()
		assert_true(texts.has("La Team Rocket repoussée"))
		assert_true(texts.has("Fossile Dôme obtenu."))
		assert_true(texts.has("Mont Sélénite · 13 octobre 2026"))
		var rows := screen.get_moment_rows()
		assert_eq(rows.size(), 1)
		assert_eq(rows[0].get_view().kind, MomentLibrary.FOSSIL)
		assert_eq(rows[0].get_icon(), key, "icône des objets clés (zone « %s »)" % zone)
		assert_false(rows[0].is_linked(), "sans lien")
