extends GutTest
## Carte de présentation du Champion (jalon 10, T5) : textes (nom en majuscules), entrée
## glissée, durée au pas près (TweenClock), toucher qui abrège la tenue, « Réduire les
## animations », signal émis une fois, entrées hors toucher ignorées, ExplorationHud.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const CARD_SCENE := "res://game/ui/components/champion_card.tscn"
const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"
const NAME := "Pierre"
const TITLE := "Champion d'Arène d'Argenta"

var _card: ChampionCard


func before_each() -> void:
	_card = (load(CARD_SCENE) as PackedScene).instantiate() as ChampionCard
	add_child_autofree(_card)
	watch_signals(_card)
	await wait_process_frames(2)


func _touch(pressed: bool = true) -> void:
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	_card._input(event)


func _total() -> float:
	return UiTokens.CHAMPION_CARD_SLIDE_IN + UiTokens.CHAMPION_CARD_HOLD \
		+ UiTokens.CHAMPION_CARD_SLIDE_OUT


func _run(clock: TweenClock) -> int:
	return clock.run_until(func() -> bool:
		return get_signal_emit_count(_card, "card_finished") > 0, _total() + 2.0)


func test_hidden_at_start() -> void:
	assert_false(_card.visible)
	assert_false(_card.is_showing())


func test_texts_name_uppercased_title_kept() -> void:
	_card.show_card(NAME, TITLE)
	assert_eq(_card.get_name_text(), "PIERRE")
	assert_eq(_card.get_title_text(), TITLE)
	assert_true(_card.visible)
	assert_true(_card.is_showing())


func test_style_from_tokens() -> void:
	var box := _card.get_body().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(box.bg_color, UiTokens.CHAMPION_CARD_BG)
	assert_lt(box.bg_color.a, 1.0, "verre translucide")
	assert_eq(box.border_color, UiTokens.ACCENT, "liseré ACCENT")
	assert_eq(box.border_width_left, UiTokens.CHAMPION_CARD_ACCENT_WIDTH)
	assert_eq(box.border_width_right, UiTokens.BORDER_WIDTH)
	var label := _card.find_child("NameLabel", true, false) as Label
	assert_eq(label.get_theme_font_size(&"font_size"), UiTokens.FONT_TITLE)


func test_slides_in_from_the_left_to_safe_margin() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	var body := _card.get_body()
	assert_lte(body.position.x + body.size.x, 0.0, "hors écran au départ")
	assert_eq(body.modulate.a, 0.0)
	clock.run_until(func() -> bool: return _card.get_phase() == ChampionCard.Phase.HOLDING)
	clock.release()
	assert_eq(body.position.x, float(UiTokens.SAFE_MARGIN))
	assert_eq(body.modulate.a, 1.0)
	assert_gte(body.position.y, 0.0)
	assert_lte(body.position.y + body.size.y, _card.size.y)


func test_total_duration_to_the_step() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	var steps := _run(clock)
	clock.release()
	assert_signal_emit_count(_card, "card_finished", 1)
	assert_false(_card.visible)
	assert_false(_card.is_showing())
	assert_between(steps * TweenClock.STEP, _total() - 0.0001,
		_total() + 3 * TweenClock.STEP + 0.0001, "entrée + tenue + sortie (%d pas)" % steps)


func test_still_holding_just_before_the_hold_ends() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	var hold_end := UiTokens.CHAMPION_CARD_SLIDE_IN + UiTokens.CHAMPION_CARD_HOLD
	for i in int(hold_end / TweenClock.STEP) - 2:
		clock.step()
	clock.release()
	assert_eq(_card.get_phase(), ChampionCard.Phase.HOLDING)
	assert_signal_not_emitted(_card, "card_finished")


func test_touch_during_hold_shortens_it() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	clock.run_until(func() -> bool: return _card.get_phase() == ChampionCard.Phase.HOLDING)
	_touch()
	assert_eq(_card.get_phase(), ChampionCard.Phase.SLIDING_OUT)
	var steps := _run(clock)
	clock.release()
	assert_signal_emit_count(_card, "card_finished", 1)
	assert_lte(steps * TweenClock.STEP, UiTokens.CHAMPION_CARD_SLIDE_OUT + 2 * TweenClock.STEP,
		"seule la sortie reste")


func test_touch_during_slide_in_skips_the_hold() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	clock.step()
	_touch()
	var steps := _run(clock)
	clock.release()
	assert_signal_emit_count(_card, "card_finished", 1)
	assert_lt(steps * TweenClock.STEP, UiTokens.CHAMPION_CARD_SLIDE_IN
		+ UiTokens.CHAMPION_CARD_SLIDE_OUT + 3 * TweenClock.STEP)


func test_touch_release_and_mouse_are_ignored() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	clock.run_until(func() -> bool: return _card.get_phase() == ChampionCard.Phase.HOLDING)
	_touch(false)
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	_card._input(click)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	_card._input(key)
	clock.release()
	assert_eq(_card.get_phase(), ChampionCard.Phase.HOLDING)


func test_reduce_motion_no_slide_only_short_fade() -> void:
	_card.reduce_motion = true
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	var body := _card.get_body()
	var x := body.position.x
	assert_eq(x, float(UiTokens.SAFE_MARGIN), "déjà en place, rien à glisser")
	var steps := 0
	while _card.get_phase() == ChampionCard.Phase.SLIDING_IN and steps < 60:
		clock.step()
		steps += 1
		assert_eq(body.position.x, x, "pas de glissé")
	assert_lte(steps * TweenClock.STEP, UiTokens.ANIM_MICRO + 2 * TweenClock.STEP)
	var total := _run(clock) + steps
	clock.release()
	var expected := 2.0 * UiTokens.ANIM_MICRO + UiTokens.CHAMPION_CARD_HOLD
	assert_between(total * TweenClock.STEP, expected - 0.0001,
		expected + 4 * TweenClock.STEP + 0.0001)
	assert_signal_emit_count(_card, "card_finished", 1)


func test_replay_restarts_and_finishes_once() -> void:
	var clock := TweenClock.new(get_tree())
	_card.show_card(NAME, TITLE)
	for i in 30:
		clock.step()
	_card.show_card("Ondine", "Championne d'Arène")
	assert_eq(_card.get_name_text(), "ONDINE")
	_run(clock)
	clock.release()
	assert_signal_emit_count(_card, "card_finished", 1)


func test_no_touch_intercepted() -> void:
	for node: Node in [_card] + _card.find_children("*", "Control", true, false):
		assert_eq((node as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, node.name)


func test_hud_relays_card_and_signal() -> void:
	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(hud)
	watch_signals(hud)
	await wait_process_frames(2)
	var clock := TweenClock.new(get_tree())
	hud.show_champion_card(NAME, TITLE)
	assert_eq(hud.get_champion_card().get_name_text(), "PIERRE")
	assert_true(hud.get_champion_card().visible)
	clock.run_until(func() -> bool:
		return get_signal_emit_count(hud, "champion_card_hidden") > 0, _total() + 2.0)
	clock.release()
	assert_signal_emit_count(hud, "champion_card_hidden", 1)
