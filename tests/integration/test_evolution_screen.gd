extends GutTest
## Écran d'évolution (jalon-09.md §2.3.3, T9) : durées au pas près (temps simulé, TweenClock),
## ARRÊTER visible et actif seulement pendant la transformation, annulation (bouton, retour
## Android) prise seulement à ce moment-là et aussitôt, révélation (flash, vibration au bon
## moment, nom, phrase, toucher), annulation (retour aux couleurs), « Réduire les animations »,
## silhouettes qui alternent en accélérant, placement tactile, et capacités apprises dans
## l'écran avec le vrai directeur (Armure pour Chrysacier, offre d'oubli).

const SCENE := preload("res://game/ui/evolution/evolution_screen.tscn")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const STEP := 1.0 / 60.0

var _screen: EvolutionScreen
var _haptics: Array[int] = []


func before_each() -> void:
	_haptics.clear()
	Haptics.sink = func(ms: int) -> void: _haptics.append(ms)
	_screen = SCENE.instantiate() as EvolutionScreen
	add_child_autofree(_screen)


func after_each() -> void:
	Haptics.reset()


func _view() -> EvolutionView:
	var view := EvolutionView.new()
	view.party_index = 0
	view.pokemon_name = "Chenipan"
	view.from_species = &"caterpie"
	view.into_species = &"metapod"
	view.from_name = "Chenipan"
	view.into_name = "Chrysacier"
	view.from_dex = 10
	view.into_dex = 11
	view.started_text = "Quoi ? Chenipan évolue !"
	view.finished_text = "Félicitations ! Chenipan a évolué en Chrysacier !"
	view.cancelled_text = "Hein ? Chenipan n'évolue plus."
	view.stop_label = "ARRÊTER"
	view.continue_text = "Touchez l'écran pour continuer"
	return view


## Lance la coroutine [param call] sans l'attendre : [fini, valeur rendue].
func _start(call: Callable) -> Array:
	var box: Array = [false, null]
	var runner := func() -> void:
		box[1] = await call.call()
		box[0] = true
	runner.call()
	return box


## Pas de 1/60 s jusqu'à la fin de [param box] ; rend le nombre de pas.
func _run(clock: RefCounted, box: Array, max_seconds: float = 20.0) -> int:
	return clock.call(&"run_until", func() -> bool: return box[0], max_seconds)


func _steps(seconds: float) -> int:
	return roundi(seconds / STEP)


## Pas près : pas fini avant la durée, au plus un pas de plus (une image par enchaînement).
func _assert_lasts(steps: int, seconds: float, what: String) -> void:
	var expected := _steps(seconds)
	assert_between(steps, expected, expected + 1, "%s : %d pas pour %.2f s" % [what, steps,
		seconds])


func _touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(960, 540)
	get_viewport().push_input(touch)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = touch.position
	get_viewport().push_input(release)


## L'écran ouvert, l'ancienne espèce présentée (à vitesse réelle, temps simulé).
func _opened(clock: RefCounted) -> void:
	_run(clock, _start(_screen.open))
	_run(clock, _start(_screen.present.bind(_view())))


func test_open_and_present_last_their_tokens_and_show_the_started_line() -> void:
	assert_false(_screen.visible, "caché au départ")
	var clock := TweenClock.new(get_tree())
	var opening := _start(_screen.open)
	assert_true(_screen.visible)
	assert_true(_screen.is_open())
	_assert_lasts(_run(clock, opening), UiTokens.EVOLUTION_OPEN, "ouverture")
	var presenting := _start(_screen.present.bind(_view()))
	assert_false(_screen.is_stop_active(), "pas d'ARRÊTER pendant la présentation")
	assert_true(_screen.handle_back(), "le retour est consommé…")
	_assert_lasts(_run(clock, presenting), UiTokens.EVOLUTION_PRESENT, "présentation")
	assert_eq(_screen.get_line_text(), "Quoi ? Chenipan évolue !")
	assert_false(_screen.is_showing_new_form())
	assert_eq(_screen.get_whiteness(), 0.0, "en couleurs")
	var transforming := _start(_screen.transform)
	_run(clock, transforming)
	assert_false(transforming[1], "…mais n'annule rien hors de la transformation")
	clock.release()


func test_the_transformation_lasts_its_token_with_stop_visible_only_meanwhile() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	var transforming := _start(_screen.transform)
	assert_true(_screen.is_transforming())
	assert_true(_screen.is_stop_active(), "ARRÊTER visible et actif")
	assert_eq(_screen.get_stop_button().text, "ARRÊTER")
	clock.call(&"step")
	assert_true(_screen.get_stop_button().modulate.a > 0.0, "il apparaît en fondu")
	_assert_lasts(_run(clock, transforming), UiTokens.EVOLUTION_TRANSFORM, "transformation")
	assert_false(transforming[1], "arrivée au terme : pas annulée")
	assert_false(_screen.is_transforming())
	assert_false(_screen.is_stop_active(), "ARRÊTER désactivé aussitôt")
	assert_true(_screen.is_showing_new_form(), "la nouvelle silhouette au terme")
	assert_eq(_screen.get_whiteness(), 1.0, "silhouette blanche")
	clock.call(&"run_until", func() -> bool: return not _screen.get_stop_button().visible, 1.0)
	assert_false(_screen.get_stop_button().visible, "puis caché")
	_screen.get_stop_button().pressed.emit()
	assert_eq(_haptics, [] as Array[int], "hors transformation, le bouton ne fait rien")
	clock.release()


func test_stop_cancels_at_once_during_the_transformation() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	var transforming := _start(_screen.transform)
	for i: int in _steps(2.0):
		clock.call(&"step")
	assert_false(transforming[0])
	_screen.get_stop_button().pressed.emit()
	assert_true(transforming[0], "rend la main aussitôt (dans l'appui)")
	assert_true(transforming[1], "annulée")
	assert_eq(_haptics, [UiTokens.HAPTIC_TAP_MS] as Array[int], "petite vibration à l'appui")
	assert_false(_screen.is_stop_active())
	clock.release()


func test_back_cancels_during_the_transformation_only() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	var transforming := _start(_screen.transform)
	for i: int in _steps(1.5):
		clock.call(&"step")
	assert_true(_screen.handle_back(), "consommé")
	assert_true(transforming[0], "aussitôt")
	assert_true(transforming[1], "annulée")
	var reverting := _start(_screen.revert)
	_run(clock, reverting, 3.0)
	assert_false(reverting[0], "attend un toucher")
	assert_true(_screen.handle_back(), "consommé pendant l'attente…")
	assert_true(_screen.is_waiting_touch(), "…sans rien changer")
	assert_eq(_screen.get_line_text(), "Hein ? Chenipan n'évolue plus.")
	assert_false(_screen.is_showing_new_form(), "l'ancienne espèce")
	assert_eq(_screen.get_whiteness(), 0.0, "en couleurs")
	_touch()
	assert_true(reverting[0])
	var closing := _start(_screen.close)
	_assert_lasts(_run(clock, closing), UiTokens.EVOLUTION_CLOSE, "fermeture")
	assert_false(_screen.visible)
	assert_false(_screen.handle_back(), "écran fermé : le retour passe")
	clock.release()


func test_reveal_flash_silence_vibration_then_waits_a_touch() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	_run(clock, _start(_screen.transform))
	var revealing := _start(_screen.reveal)
	var peak := 0.0
	var steps := 0
	while _haptics.is_empty() and steps < 600:
		clock.call(&"step")
		steps += 1
		peak = maxf(peak, _screen.get_flash_alpha())
		if not _haptics.is_empty():
			assert_eq(_screen.get_whiteness(), 1.0, "silence : la silhouette, encore blanche")
	_assert_lasts(steps, UiTokens.EVOLUTION_FLASH + UiTokens.EVOLUTION_SILENCE,
		"flash et silence avant la vibration")
	assert_eq(_haptics, [UiTokens.EVOLUTION_HAPTIC_MS] as Array[int], "une vibration courte")
	assert_almost_eq(peak, UiTokens.EVOLUTION_FLASH_ALPHA, 0.05, "le flash")
	assert_true(_screen.is_showing_new_form())
	# Un toucher avant la fin de la phrase ne compte pas.
	_touch()
	var armed := clock.call(&"run_until", _screen.is_waiting_touch, 5.0) as int
	_assert_lasts(steps + armed, UiTokens.EVOLUTION_FLASH + UiTokens.EVOLUTION_SILENCE
		+ UiTokens.EVOLUTION_REVEAL, "révélation jusqu'au toucher")
	assert_false(revealing[0])
	assert_eq(_screen.get_whiteness(), 0.0, "en couleurs")
	assert_eq(_screen.get_name_text(), "CHRYSACIER")
	assert_eq(_screen.get_line_text(), "Félicitations ! Chenipan a évolué en Chrysacier !")
	assert_eq(_screen.get_hint_text(), "Touchez l'écran pour continuer")
	for i: int in _steps(30.0):
		clock.call(&"step")
	assert_false(revealing[0], "attend le toucher, sans limite")
	_touch()
	assert_true(revealing[0], "le toucher continue")
	assert_eq(_screen.get_hint_text(), "", "consigne retirée")
	clock.release()


func test_reduced_flashes_dim_the_flash() -> void:
	_screen.reduce_flashes = true
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	_run(clock, _start(_screen.transform))
	_start(_screen.reveal)
	var peak := 0.0
	for i: int in _steps(UiTokens.EVOLUTION_FLASH):
		clock.call(&"step")
		peak = maxf(peak, _screen.get_flash_alpha())
	assert_almost_eq(peak, UiTokens.EVOLUTION_FLASH_REDUCED_ALPHA, 0.05)
	_touch()
	clock.release()


func test_reduced_motion_divides_the_durations() -> void:
	var scale := GameSettings.REDUCED_BATTLE_SPEED
	_screen.speed_scale = scale
	var clock := TweenClock.new(get_tree())
	_run(clock, _start(_screen.open))
	var presenting := _start(_screen.present.bind(_view()))
	_assert_lasts(_run(clock, presenting), UiTokens.EVOLUTION_PRESENT * scale, "présentation")
	var transforming := _start(_screen.transform)
	_assert_lasts(_run(clock, transforming), UiTokens.EVOLUTION_TRANSFORM * scale,
		"transformation")
	assert_true(_screen.is_showing_new_form())
	clock.release()


## Jalon 11 (dossier 14 §7, évolution courte) : ≈ 6 s au lieu de 8 à 12 s (J9).
func test_total_duration_is_about_6_seconds_without_reading() -> void:
	var total := UiTokens.EVOLUTION_OPEN + UiTokens.EVOLUTION_PRESENT \
		+ UiTokens.EVOLUTION_TRANSFORM + UiTokens.EVOLUTION_FLASH + UiTokens.EVOLUTION_SILENCE \
		+ UiTokens.EVOLUTION_REVEAL
	assert_between(total, 5.5, 6.5)
	assert_lt(UiTokens.EVOLUTION_FLASH_RISE, UiTokens.EVOLUTION_FLASH)
	assert_lte(UiTokens.EVOLUTION_LINE_DELAY + UiTokens.EVOLUTION_TEXT_IN,
		UiTokens.EVOLUTION_REVEAL, "la phrase est posée avant le toucher")
	assert_lte(UiTokens.EVOLUTION_TEXT_OUT + UiTokens.EVOLUTION_TEXT_IN,
		UiTokens.EVOLUTION_REVERT)
	assert_lte(UiTokens.EVOLUTION_ENTER, UiTokens.EVOLUTION_PRESENT)


func test_silhouettes_alternate_faster_and_faster() -> void:
	var swaps: Array[float] = []
	var shown := false
	var frames := _steps(UiTokens.EVOLUTION_TRANSFORM)
	for i: int in frames + 1:
		var p := float(i) / float(frames)
		var now := EvolutionScreen.shows_new_form(p)
		if now != shown:
			swaps.append(p * UiTokens.EVOLUTION_TRANSFORM)
			shown = now
	assert_gt(swaps.size(), 15, "beaucoup de bascules (transformation de 2,5 s, J11)")
	assert_almost_eq(swaps[0], UiTokens.EVOLUTION_SWAP_START, 0.05, "première bascule")
	assert_gte(swaps[0], UiTokens.EVOLUTION_TO_SILHOUETTE, "une fois devenue silhouette")
	var first := swaps[1] - swaps[0]
	var last := swaps[swaps.size() - 1] - swaps[swaps.size() - 2]
	assert_gt(first, last * 4.0, "de plus en plus vite")
	var in_first_second := swaps.filter(func(t: float) -> bool: return t < 1.0).size()
	var in_last_second := swaps.filter(func(t: float) -> bool:
		return t >= UiTokens.EVOLUTION_TRANSFORM - 1.0).size()
	assert_gt(in_last_second, in_first_second * 3)
	assert_true(EvolutionScreen.shows_new_form(1.0), "la nouvelle au terme")
	assert_false(EvolutionScreen.shows_new_form(0.0))


func test_stop_button_respects_touch_rules_from_1920_to_2340() -> void:
	var stop := _screen.get_stop_button()
	assert_gte(UiTokens.EVOLUTION_STOP_SIZE.y, float(UiTokens.TOUCH_MIN))
	assert_gte(UiTokens.EVOLUTION_STOP_SIZE.x, float(UiTokens.TOUCH_MIN))
	assert_eq([stop.anchor_left, stop.anchor_top], [1.0, 1.0], "ancré au coin bas droit")
	assert_gte(-stop.offset_right, float(UiTokens.SAFE_MARGIN))
	assert_gte(-stop.offset_bottom, float(UiTokens.SAFE_MARGIN))
	assert_eq(_screen.layer, UiTokens.LAYER_EVOLUTION)
	assert_gt(UiTokens.LAYER_EVOLUTION, UiTokens.LAYER_BATTLE_HUD, "au-dessus du combat")
	assert_lt(UiTokens.LAYER_EVOLUTION, UiTokens.LAYER_TRANSITION)
	var banner := _screen.get_message_banner()
	assert_gte(-banner.offset_bottom, float(UiTokens.SAFE_MARGIN))
	assert_eq(banner.get_parent().get_parent(), _screen, "le bandeau est celui de l'écran")


func test_speed_zero_is_instant_without_waiting_a_touch() -> void:
	_screen.speed_scale = 0.0
	await _screen.open()
	await _screen.present(_view())
	assert_false(await _screen.transform())
	await _screen.reveal()
	assert_eq(_screen.get_name_text(), "CHRYSACIER")
	await _screen.close()
	assert_false(_screen.visible)
	assert_false(_screen.is_open())


## Le vrai directeur et le vrai écran : Chenipan N7 → Chrysacier, Armure apprise dans le
## bandeau de l'écran (Q-5) ; puis, capacités pleines, l'offre d'oubli dans l'écran.
func test_moves_learned_at_evolution_show_in_the_screen() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var texts := BattleText.new()
	texts.load_file()
	var state: Node = GAME_STATE.new()
	add_child_autofree(state)
	var learn := MoveLearnPrompt.new()
	learn.speed_scale = 0.0
	learn.haptics_enabled = false
	add_child_autofree(learn)
	learn.setup(data, texts)
	var director := EvolutionDirector.new()
	director.speed_scale = 0.0
	add_child_autofree(director)
	director.setup(state, data, texts, learn)
	director.set_screen(_screen)
	var messages: Array[String] = []
	_screen.get_message_banner().message_shown.connect(func(text: String, _w: bool) -> void:
		messages.append(text))
	var party := Party.new()
	party.add(PokemonFactory.create(data, &"caterpie", 7, GameRng.new(7)))
	var leveled: Array[int] = [0]
	await director.play(Evolution.candidates(party, leveled, data), party)
	assert_eq(party.get_lead().species_id, &"metapod")
	assert_eq(messages, ["Chrysacier apprend Armure !"] as Array[String])
	assert_false(_screen.visible, "refermé")
	# Capacités pleines : l'offre d'oubli s'ouvre dans l'écran (refus).
	messages.clear()
	var second := Party.new()
	var caterpie := PokemonFactory.create(data, &"caterpie", 7, GameRng.new(3))
	for move_id: StringName in [&"growl", &"scratch"]:
		caterpie.learn_move(move_id, data)
	second.add(caterpie)
	var seen: Dictionary = {}
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await director.play(Evolution.candidates(second, leveled, data), second)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 10000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var panel := learn.get_forget_panel()
		if panel != null and panel.is_shown() and not panel.is_answered():
			seen["parent"] = panel.get_parent() == _screen.get_prompt_host()
			await wait_process_frames(2)
			panel.get_skip_button().pressed.emit()
		await wait_process_frames(1)
	assert_true(done[0])
	assert_true(seen.get("parent", false), "panneau d'oubli dans l'écran d'évolution")
	assert_eq(messages, ["Chrysacier veut apprendre Armure, mais connaît déjà quatre capacités.",
		"Chrysacier n'apprend pas Armure."] as Array[String])


# --- Jalon 11 (T15) : évolution courte, toucher = ×2 ------------------------------------------

func test_a_touch_during_the_transformation_plays_the_rest_twice_as_fast() -> void:
	var clock := TweenClock.new(get_tree())
	clock.speed_of = _screen.tween_speed
	_opened(clock)
	var transforming := _start(_screen.transform)
	var half := _steps(UiTokens.EVOLUTION_TRANSFORM / 2.0)
	for i: int in half:
		clock.call(&"step")
	assert_false(_screen.is_rushed())
	_touch()
	assert_true(_screen.is_rushed(), "toucher pendant la séquence : ×2")
	assert_true(_screen.is_stop_active(), "ARRÊTER reste là")
	var rest := _run(clock, transforming)
	assert_false(transforming[1], "pas annulée : le toucher accélère, il n'arrête pas")
	_assert_lasts(rest, UiTokens.EVOLUTION_TRANSFORM / 2.0 / UiTokens.EVOLUTION_RUSH,
		"seconde moitié à ×2")
	# La révélation reste accélérée, puis la consigne attend un toucher à vitesse normale.
	var revealing := _start(_screen.reveal)
	var armed := clock.call(&"run_until", _screen.is_waiting_touch, 5.0) as int
	_assert_lasts(armed, (UiTokens.EVOLUTION_FLASH + UiTokens.EVOLUTION_SILENCE
		+ UiTokens.EVOLUTION_REVEAL) / UiTokens.EVOLUTION_RUSH, "révélation à ×2")
	assert_false(_screen.is_rushed(), "vitesse normale une fois la consigne posée")
	_touch()
	assert_true(revealing[0], "le toucher continue")
	clock.release()


func test_a_touch_on_stop_cancels_without_rushing() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	var transforming := _start(_screen.transform)
	for i: int in _steps(1.0):
		clock.call(&"step")
	var stop := _screen.get_stop_button()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = stop.get_global_rect().get_center()
	_screen._input(touch)
	assert_false(_screen.is_rushed(), "un toucher sur ARRÊTER n'accélère pas")
	stop.pressed.emit()
	assert_true(transforming[1], "annulée")
	clock.release()


func test_the_rush_is_reset_for_the_next_evolution() -> void:
	var clock := TweenClock.new(get_tree())
	_opened(clock)
	_screen.rush()
	assert_true(_screen.is_rushed())
	_run(clock, _start(_screen.transform))
	var revealing := _start(_screen.reveal)
	clock.call(&"run_until", _screen.is_waiting_touch, 5.0)
	_touch()
	assert_true(revealing[0])
	_run(clock, _start(_screen.present.bind(_view())))
	assert_false(_screen.is_rushed(), "deuxième évolution : vitesse normale")
	clock.release()
