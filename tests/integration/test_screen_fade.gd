extends GutTest
## Rideau de transition : calque, rideau plein écran qui ignore le toucher, fondus
## awaitables et leurs signaux, durée nulle, fondu remplacé sans saut d'opacité.

const FADE_SCENE := "res://game/ui/components/screen_fade.tscn"
const SHORT := 0.05

var _fade: ScreenFade


func before_each() -> void:
	_fade = (load(FADE_SCENE) as PackedScene).instantiate() as ScreenFade
	add_child_autofree(_fade)


func test_is_transition_canvas_layer() -> void:
	assert_eq(_fade.layer, UiTokens.LAYER_TRANSITION)
	assert_eq(UiTokens.LAYER_TRANSITION, 100)


func test_curtain_full_screen_ignores_touch() -> void:
	var curtain := _fade.get_curtain()
	assert_eq(Vector4(curtain.anchor_left, curtain.anchor_top, curtain.anchor_right,
		curtain.anchor_bottom), Vector4(0, 0, 1, 1))
	assert_eq(curtain.position, Vector2.ZERO)
	assert_eq(curtain.size, _fade.get_viewport().get_visible_rect().size)
	assert_eq(curtain.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_curtain_color_from_tokens() -> void:
	assert_eq(_fade.get_curtain().color, UiTokens.FADE_COLOR)
	assert_eq(UiTokens.FADE_COLOR, Color(0.02, 0.03, 0.05))


func test_transparent_at_rest() -> void:
	assert_eq(_fade.get_alpha(), 0.0)
	assert_false(_fade.is_opaque())
	assert_false(_fade.get_curtain().visible, "rien à dessiner au repos")


func test_default_durations_from_tokens() -> void:
	assert_eq(UiTokens.ANIM_FADE_OUT, 0.2)
	assert_eq(UiTokens.ANIM_FADE_IN, 0.25)


func test_fade_out_makes_curtain_opaque() -> void:
	watch_signals(_fade)
	await _fade.fade_out(SHORT)
	assert_eq(_fade.get_alpha(), 1.0)
	assert_true(_fade.is_opaque())
	assert_true(_fade.get_curtain().visible)
	assert_signal_emit_count(_fade, "faded_out", 1)
	assert_signal_not_emitted(_fade, "faded_in")


func test_fade_in_clears_curtain() -> void:
	await _fade.fade_out(SHORT)
	watch_signals(_fade)
	await _fade.fade_in(SHORT)
	assert_eq(_fade.get_alpha(), 0.0)
	assert_false(_fade.is_opaque())
	assert_false(_fade.get_curtain().visible)
	assert_signal_emit_count(_fade, "faded_in", 1)
	assert_signal_not_emitted(_fade, "faded_out")


func test_fade_out_is_gradual() -> void:
	_fade.fade_out(2.0)
	await wait_process_frames(3)
	var alpha := _fade.get_alpha()
	assert_true(alpha > 0.0 and alpha < 1.0, "à mi-course : %f" % alpha)
	assert_false(_fade.is_opaque())


func test_zero_duration_returns_after_one_frame() -> void:
	watch_signals(_fade)
	var start := Engine.get_process_frames()
	await _fade.fade_out(0.0)
	assert_eq(Engine.get_process_frames() - start, 1, "fade_out(0) : une image")
	assert_true(_fade.is_opaque())
	start = Engine.get_process_frames()
	await _fade.fade_in(0.0)
	assert_eq(Engine.get_process_frames() - start, 1, "fade_in(0) : une image")
	assert_eq(_fade.get_alpha(), 0.0)
	assert_signal_emit_count(_fade, "faded_out", 1)
	assert_signal_emit_count(_fade, "faded_in", 1)


func test_zero_duration_sets_alpha_immediately() -> void:
	_fade.fade_out(0.0)
	assert_true(_fade.is_opaque(), "opaque avant même l'image suivante")
	await wait_process_frames(2)


func test_fade_in_during_fade_out_starts_from_current_alpha() -> void:
	watch_signals(_fade)
	_fade.fade_out(2.0)
	await wait_process_frames(4)
	var reached := _fade.get_alpha()
	assert_true(reached > 0.0 and reached < 1.0, "fondu en cours : %f" % reached)
	_fade.fade_in(SHORT)
	assert_eq(_fade.get_alpha(), reached, "aucun saut au remplacement")
	var previous := reached
	while _fade.get_alpha() > 0.0:
		await get_tree().process_frame
		assert_true(_fade.get_alpha() <= previous, "ne remonte pas")
		previous = _fade.get_alpha()
	await wait_process_frames(2)
	assert_signal_not_emitted(_fade, "faded_out", "fondu remplacé : pas de faded_out")
	assert_signal_emit_count(_fade, "faded_in", 1)


func test_replaced_fade_returns() -> void:
	var state := {"returned": false}
	var run_out := func() -> void:
		await _fade.fade_out(0.3)
		state["returned"] = true
	run_out.call()
	await wait_process_frames(2)
	await _fade.fade_in(SHORT)
	await wait_process_frames(1)
	assert_true(state["returned"], "l'appel interrompu rend la main")
	assert_eq(_fade.get_alpha(), 0.0)


func test_set_opaque_is_immediate_and_cancels_fade() -> void:
	watch_signals(_fade)
	_fade.fade_in(0.3)
	_fade.set_opaque(true)
	assert_true(_fade.is_opaque())
	await wait_process_frames(3)
	assert_true(_fade.is_opaque(), "le fondu annulé ne bouge plus le rideau")
	_fade.set_opaque(false)
	assert_eq(_fade.get_alpha(), 0.0)
	assert_signal_not_emitted(_fade, "faded_in")


func test_freed_during_fade_does_not_resume() -> void:
	var fade := (load(FADE_SCENE) as PackedScene).instantiate() as ScreenFade
	add_child(fade)
	fade.fade_out(0.3)
	await wait_process_frames(2)
	fade.free()
	await wait_process_frames(3)
	assert_engine_error_count(0, "aucune reprise sur une instance libérée")


## OUV.3 : rideau blanc chaud à la fin de l'introduction ; le fondu suivant (les portes) repart
## du noir par défaut, fade_in et set_opaque gardent la teinte.
func test_fade_out_sets_its_color_and_doors_go_back_to_black() -> void:
	await _fade.fade_out(0.0, UiTokens.INTRO_WHITE)
	assert_eq(_fade.get_color(), UiTokens.INTRO_WHITE)
	_fade.set_opaque(true)
	await _fade.fade_in(0.0)
	assert_eq(_fade.get_color(), UiTokens.INTRO_WHITE, "fade_in garde la teinte")
	await _fade.fade_out(0.0)
	assert_eq(_fade.get_color(), UiTokens.FADE_COLOR, "les portes : noir")
