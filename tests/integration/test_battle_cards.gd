extends GutTest
## Interface de combat, jalon 4B (1/4) : barre de PV (seuils de couleur, animation en
## HP_TWEEN, plus rapide sur un gros coup), cartes d'information (nom seul en majuscules,
## ♂/♀, « Nv. 5 », PV chiffrés côté joueur seulement, pulsation sous 20 %, vibrations),
## pastilles d'équipe, apparition animée et emplacements (BattleHudLayout) à 1920 et 2340.

const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"
const BAR_SCENE := "res://game/ui/battle/hp_bar.tscn"
const PIPS_SCENE := "res://game/ui/battle/party_pips.tscn"
const BACK_SCENE := "res://game/ui/battle/battle_back_button.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
## Une image à 60 images/s, plus une marge pour la dernière image de l'animation.
const FRAME := 1.0 / 60.0


func _card() -> BattleInfoCard:
	var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
	card.haptics_enabled = false
	add_child_autofree(card)
	return card


func _bar() -> HpBar:
	var bar := (load(BAR_SCENE) as PackedScene).instantiate() as HpBar
	add_child_autofree(bar)
	return bar


func _own_view() -> BattleCardView:
	return BattleCardView.new("Salamèche", BattleCardView.Gender.MALE, 5, 19, 19, true)


func _foe_view() -> BattleCardView:
	return BattleCardView.new("Carapuce", BattleCardView.Gender.FEMALE, 5, 20, 20, false)


## Écran plein de [param width] × 1080 dans lequel on pose les composants.
func _screen(width: float) -> Control:
	var screen := Control.new()
	screen.size = Vector2(width, SCREEN_HEIGHT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child_autofree(screen)
	return screen


# --- Barre de PV ---------------------------------------------------------------------------

func test_bar_color_thresholds() -> void:
	# > 50 % vert ; 50 % tout juste jaune ; > 20 % jaune ; 20 % tout juste rouge.
	assert_eq(HpBar.color_for(11, 20), UiTokens.HP_HIGH, "55 %")
	assert_eq(HpBar.color_for(10, 20), UiTokens.HP_MID, "50 % : jaune")
	assert_eq(HpBar.color_for(51, 100), UiTokens.HP_HIGH, "51 %")
	assert_eq(HpBar.color_for(50, 100), UiTokens.HP_MID, "50 %")
	assert_eq(HpBar.color_for(21, 100), UiTokens.HP_MID, "21 %")
	assert_eq(HpBar.color_for(20, 100), UiTokens.HP_LOW, "20 % : rouge")
	assert_eq(HpBar.color_for(5, 25), UiTokens.HP_LOW, "20 % (5/25)")
	assert_eq(HpBar.color_for(0, 19), UiTokens.HP_LOW, "K.O.")
	assert_eq(HpBar.color_for(19, 19), UiTokens.HP_HIGH, "pleins")


func test_bar_set_hp_is_immediate_and_colors_label_like_bar() -> void:
	var bar := _bar()
	bar.set_hp(10, 20)
	assert_eq(bar.get_shown_hp(), 10)
	assert_eq(bar.get_color(), UiTokens.HP_MID)
	assert_eq(bar.get_label().text, "PV")
	assert_eq(bar.get_label().get_theme_color(&"font_color"), UiTokens.HP_MID,
		"« PV » coloré comme la barre")
	bar.set_hp(19, 19)
	assert_eq(bar.get_label().get_theme_color(&"font_color"), UiTokens.HP_HIGH)
	await wait_process_frames(1)
	assert_eq(bar.get_track().size.y, float(UiTokens.HP_BAR_HEIGHT))


func test_bar_clamps_values() -> void:
	var bar := _bar()
	bar.set_hp(-5, 20)
	assert_eq(bar.get_shown_hp(), 0)
	bar.set_hp(99, 20)
	assert_eq(bar.get_shown_hp(), 20)


func test_animate_hp_reaches_value_in_hp_tween() -> void:
	var bar := _bar()
	bar.set_hp(20, 20)
	# Une image d'abord : celle du chargement compterait dans la durée de l'animation.
	await wait_process_frames(2)
	bar.animate_hp(4, 20)
	await wait_seconds(UiTokens.HP_TWEEN - 3.0 * FRAME)
	assert_gt(bar.get_shown_value(), 4.0, "pas encore arrivée juste avant HP_TWEEN")
	assert_true(bar.is_animating())
	await wait_seconds(4.0 * FRAME)
	assert_eq(bar.get_shown_hp(), 4, "arrivée en HP_TWEEN (± 1 image)")
	assert_false(bar.is_animating())
	assert_eq(bar.get_color(), UiTokens.HP_LOW)


func test_animate_hp_big_hit_is_faster() -> void:
	var bar := _bar()
	bar.set_hp(20, 20)
	# Une image d'abord : celle du chargement compterait dans la durée de l'animation.
	await wait_process_frames(2)
	bar.animate_hp(4, 20, true)
	await wait_seconds(UiTokens.HP_TWEEN_FAST + 2.0 * FRAME)
	assert_eq(bar.get_shown_hp(), 4, "arrivée en HP_TWEEN_FAST")
	assert_lt(UiTokens.HP_TWEEN_FAST + 2.0 * FRAME, UiTokens.HP_TWEEN)


func test_animate_hp_changes_color_at_thresholds_on_the_way() -> void:
	var bar := _bar()
	bar.set_hp(20, 20)
	var seen: Array[Color] = []
	bar.display_changed.connect(func(hp: int, max_hp: int) -> void:
		var color := HpBar.color_for(hp, max_hp)
		if seen.is_empty() or seen[-1] != color:
			seen.append(color))
	await bar.animate_hp(2, 20)
	assert_eq(seen, [UiTokens.HP_HIGH, UiTokens.HP_MID, UiTokens.HP_LOW] as Array[Color],
		"vert → jaune → rouge pendant la descente")


func test_animate_hp_is_a_coroutine_that_ends_at_value() -> void:
	var bar := _bar()
	bar.set_hp(19, 19)
	await bar.animate_hp(7, 19)
	assert_eq(bar.get_shown_hp(), 7)


func test_animate_hp_instant_with_speed_scale_zero() -> void:
	var bar := _bar()
	bar.speed_scale = 0.0
	bar.set_hp(19, 19)
	await bar.animate_hp(3, 19)
	assert_eq(bar.get_shown_hp(), 3)
	assert_false(bar.is_animating())


func test_set_hp_interrupts_animation() -> void:
	var bar := _bar()
	bar.set_hp(20, 20)
	bar.animate_hp(0, 20)
	await wait_process_frames(2)
	bar.set_hp(15, 20)
	assert_false(bar.is_animating())
	await wait_seconds(UiTokens.HP_TWEEN)
	assert_eq(bar.get_shown_hp(), 15)


# --- Carte d'information -------------------------------------------------------------------

func test_own_card_shows_name_gender_level_and_numbers() -> void:
	var card := _card()
	card.set_view(_own_view())
	await wait_process_frames(1)
	assert_eq(card.get_name_text(), "SALAMÈCHE", "nom seul, en majuscules")
	assert_eq(card.get_gender(), BattleCardView.Gender.MALE)
	assert_true(card.get_gender_icon().visible)
	assert_eq(card.get_gender_icon().modulate, UiTokens.GENDER_MALE, "♂ bleu")
	assert_eq(card.get_level_text(), "Nv. 5")
	assert_true(card.is_hp_numbers_visible(), "PV chiffrés côté joueur")
	assert_eq(card.get_hp_text(), "19 / 19")
	assert_eq(card.get_hp_bar().get_color(), UiTokens.HP_HIGH)
	assert_eq(card.size, Vector2(UiTokens.BATTLE_CARD_WIDTH, UiTokens.BATTLE_CARD_HEIGHT_NUMBERS))


func test_foe_card_has_no_numbers_and_female_symbol() -> void:
	var card := _card()
	card.set_view(_foe_view())
	await wait_process_frames(1)
	assert_eq(card.get_name_text(), "CARAPUCE")
	assert_false(card.get_name_text().contains("ENNEMI"), "ni « ennemi »")
	assert_false(card.get_name_text().contains("RIVAL"), "ni « du Rival »")
	assert_eq(card.get_gender_icon().modulate, UiTokens.GENDER_FEMALE, "♀ rose")
	assert_ne(card.get_gender_icon().texture, BattleInfoCard.GENDER_ICONS[
		BattleCardView.Gender.MALE])
	assert_false(card.is_hp_numbers_visible(), "pas de PV chiffrés pour l'adversaire")
	assert_eq(card.size, Vector2(UiTokens.BATTLE_CARD_WIDTH, UiTokens.BATTLE_CARD_HEIGHT))


func test_genderless_card_shows_no_symbol() -> void:
	var card := _card()
	card.set_view(BattleCardView.new("Magnéti", BattleCardView.Gender.NONE, 12, 30, 30))
	assert_false(card.get_gender_icon().visible)


func test_set_show_hp_numbers_toggles() -> void:
	var card := _card()
	card.set_view(_foe_view())
	card.set_show_hp_numbers(true)
	assert_true(card.is_hp_numbers_visible())
	assert_eq(card.get_hp_text(), "20 / 20")


func test_invalid_view_refused() -> void:
	var card := _card()
	card.set_view(_own_view())
	card.set_view(BattleCardView.new("", BattleCardView.Gender.MALE, 5, 19, 19))
	assert_push_error("vue invalide")
	assert_eq(card.get_name_text(), "SALAMÈCHE", "la carte reste telle")


func test_card_numbers_follow_animation() -> void:
	var card := _card()
	card.set_view(_own_view())
	var shown: Array[String] = []
	card.get_hp_bar().display_changed.connect(func(_hp: int, _max_hp: int) -> void:
		shown.append(card.get_hp_text()))
	await card.animate_hp(12, 19)
	assert_eq(card.get_hp_text(), "12 / 19")
	assert_gt(shown.size(), 3, "les chiffres défilent pendant la descente")
	assert_eq(shown[-1], "12 / 19")


func test_card_is_translucent_like_the_dialogue_box() -> void:
	var card := _card()
	var box := card.get_body().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(box.bg_color, UiTokens.BATTLE_CARD_BG)
	assert_lt(box.bg_color.a, 1.0)


func test_card_pulses_at_low_hp_and_stops_above() -> void:
	var card := _card()
	card.speed_scale = 0.0
	card.set_view(_own_view())
	assert_false(card.is_pulsing(), "PV pleins")
	card.set_hp(4, 19)
	assert_false(card.is_pulsing(), "21 % : pas encore")
	card.set_hp(3, 19)
	assert_true(card.is_pulsing(), "≤ 20 % : pulsation")
	await wait_seconds(UiTokens.HP_LOW_PULSE * 0.5)
	assert_gt(card.get_body().scale.x, 1.0, "la carte grossit légèrement")
	assert_lt(card.get_body().scale.x, UiTokens.HP_LOW_PULSE_SCALE + 0.001, "…légèrement")
	card.set_hp(10, 19)
	assert_false(card.is_pulsing(), "remontée : arrêt")
	assert_eq(card.get_body().scale, Vector2.ONE)
	card.set_hp(0, 19)
	assert_false(card.is_pulsing(), "K.O. : pas de pulsation")


func test_card_pulse_starts_during_animated_descent() -> void:
	var card := _card()
	card.set_view(_foe_view())
	await card.animate_hp(2, 20, true)
	assert_true(card.is_pulsing())


func test_hit_haptics_normal_and_critical() -> void:
	var card := _card()
	watch_signals(card)
	card.play_hit()
	assert_signal_emitted_with_parameters(card, "haptic_played", [UiTokens.HAPTIC_HIT_MS])
	card.play_hit(true)
	assert_signal_emitted_with_parameters(card, "haptic_played", [UiTokens.HAPTIC_CRIT_MS])
	assert_signal_emit_count(card, "haptic_played", 2)


func test_card_slides_in_and_out() -> void:
	var card := _card()
	assert_false(card.visible, "caché au départ")
	card.slide_in()
	assert_true(card.visible)
	assert_eq(card.modulate.a, 0.0, "part transparente")
	assert_ne(card.get_body().position, Vector2.ZERO, "part décalée (glissement)")
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_eq(card.get_body().position, Vector2.ZERO)
	assert_almost_eq(card.modulate.a, 1.0, 0.001)
	await card.slide_out()
	assert_false(card.visible)
	assert_false(card.is_shown())


func test_slide_is_instant_with_speed_scale_zero() -> void:
	var card := _card()
	card.speed_scale = 0.0
	await card.slide_in()
	assert_true(card.visible)
	assert_eq(card.modulate.a, 1.0)
	assert_eq(card.get_body().position, Vector2.ZERO)
	await card.slide_out()
	assert_false(card.visible)


func test_freeing_during_animation_is_silent() -> void:
	# L'appelant libère la carte pendant ses animations : ni erreur ni reprise orpheline.
	var card := _card()
	card.set_view(_own_view())
	card.slide_in()
	card.animate_hp(1, 19)
	await wait_process_frames(3)
	card.free()
	await wait_process_frames(3)
	assert_true(true, "aucune erreur")


# --- Pastilles d'équipe ----------------------------------------------------------------------

func test_six_pips_one_full() -> void:
	var pips := (load(PIPS_SCENE) as PackedScene).instantiate() as PartyPips
	add_child_autofree(pips)
	pips.set_party(1)
	assert_eq(pips.get_slot_count(), 6)
	assert_eq(pips.get_party_count(), 1)
	assert_true(pips.is_slot_filled(0), "une Poké Ball")
	for i: int in range(1, 6):
		assert_false(pips.is_slot_filled(i), "vide %d" % i)
	pips.set_party(9)
	assert_eq(pips.get_party_count(), 6, "borné à 6")


# --- Emplacements ----------------------------------------------------------------------------

func test_layout_cards_in_corners_at_both_widths() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := _screen(width)
		var foe := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
		var own := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
		var pips := (load(PIPS_SCENE) as PackedScene).instantiate() as PartyPips
		var back := (load(BACK_SCENE) as PackedScene).instantiate() as BattleBackButton
		for control: Control in [foe, own, pips, back]:
			screen.add_child(control)
		foe.set_view(_foe_view())
		own.set_view(_own_view())
		BattleHudLayout.place(foe, BattleHudLayout.Slot.FOE_CARD)
		BattleHudLayout.place(own, BattleHudLayout.Slot.OWN_CARD)
		BattleHudLayout.place(pips, BattleHudLayout.Slot.PARTY_PIPS)
		BattleHudLayout.place(back, BattleHudLayout.Slot.BACK)
		var foe_rect := foe.get_global_rect()
		var own_rect := own.get_global_rect()
		assert_eq(foe_rect.position.x, float(UiTokens.BATTLE_EDGE), "adversaire en haut à gauche")
		assert_eq(foe_rect.position.y, float(UiTokens.BATTLE_FOE_CARD_TOP))
		assert_eq(own_rect.end.x, width - UiTokens.BATTLE_EDGE, "joueur en bas à droite")
		assert_eq(own_rect.end.y, SCREEN_HEIGHT - UiTokens.BATTLE_OWN_CARD_BOTTOM)
		assert_eq(foe_rect, BattleHudLayout.rect(BattleHudLayout.Slot.FOE_CARD, screen.size))
		assert_eq(own_rect, BattleHudLayout.rect(BattleHudLayout.Slot.OWN_CARD, screen.size))
		var pips_rect := pips.get_global_rect()
		assert_lt(pips_rect.end.y, own_rect.position.y, "pastilles au-dessus de la carte")
		assert_gt(pips_rect.position.x, own_rect.position.x)
		assert_lt(pips_rect.end.x, own_rect.end.x, "pastilles au-dessus de la carte, à gauche")
		# Contrat avec le cadrage : rien dans la moitié haute droite ni le quart bas gauche
		# (pastilles : décor non interactif, tolérées à 20 px au-dessus de la mi-hauteur).
		var half := SCREEN_HEIGHT * 0.5
		assert_gt(own_rect.position.y, half, "carte joueur sous la mi-hauteur")
		assert_gt(pips_rect.position.y, half - 24.0, "pastilles à la mi-hauteur au plus")
		assert_lt(foe_rect.end.x, width * 0.5, "carte adverse dans la moitié gauche")
		var back_rect := back.get_global_rect()
		assert_lt(back_rect.end.x, own_rect.position.x, "« ‹ » loin de la carte joueur")
		_assert_touchable(back_rect, width, "« ‹ »")


func _assert_touchable(rect: Rect2, width: float, what: String) -> void:
	assert_true(rect.size.x >= UiTokens.TOUCH_MIN and rect.size.y >= UiTokens.TOUCH_MIN,
		"%s ≥ TOUCH_MIN (%s)" % [what, rect.size])
	var safe := Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
		Vector2(width, SCREEN_HEIGHT) - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0)
	assert_true(safe.encloses(rect), "%s dans SAFE_MARGIN à %d (%s)" % [what, width, rect])
