extends GutTest
## StatusAura, CV.3 : aura de poison et de Toxik, givre, pose du statut, respiration (état et
## « Réduire les animations »). Aucun tirage : les motifs sont fixes.

var _sprite: Sprite2D
var _aura: StatusAura


func before_each() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	_sprite = Sprite2D.new()
	_sprite.name = &"PlayerSprite"
	_sprite.centered = false
	_sprite.texture = ImageTexture.create_from_image(Image.create_empty(100, 100, false,
		Image.FORMAT_RGBA8))
	_sprite.position = Vector2(300, 400)
	_sprite.scale = Vector2(2, 2)
	parent.add_child(_sprite)
	_aura = StatusAura.new()
	_aura.name = &"PlayerStatusAura"
	_aura.setup(_sprite)
	_aura.set_box(Rect2(0, 0, 100, 100))
	parent.add_child(_aura)


func test_breath_amount_is_neutral_at_start_and_bounded() -> void:
	assert_eq(StatusAura.breath_amount(StatusRules.NONE, 0.0), 0.0)
	assert_almost_eq(StatusAura.breath_amount(StatusRules.NONE, 1.5), 0.01, 0.0001)
	assert_almost_eq(StatusAura.breath_amount(StatusRules.SLEEP, 1.2), 0.02, 0.0001)
	for i: int in 100:
		var t := i * 0.07
		assert_between(StatusAura.breath_amount(StatusRules.NONE, t, 0.5), 0.0, 0.01 + 1e-6)
		assert_between(StatusAura.breath_amount(StatusRules.SLEEP, t), 0.0, 0.02 + 1e-6)


func test_breath_is_shifted_between_the_two_sides() -> void:
	assert_eq(_aura.breath_phase, 0.0)
	var foe := StatusAura.new()
	foe.name = &"FoeStatusAura"
	foe.setup(_sprite)
	add_child_autofree(foe)
	assert_eq(foe.breath_phase, 0.5)
	assert_ne(StatusAura.breath_amount(StatusRules.NONE, 0.5, 0.0),
		StatusAura.breath_amount(StatusRules.NONE, 0.5, 0.5))


func test_sleep_breath_stretches_vertically_with_feet_fixed_then_restores() -> void:
	_aura.set_status(StatusRules.SLEEP)
	var feet_before := _sprite.position.y + 100.0 * _sprite.scale.y
	_aura._breath_time = 1.2  # sommet de l'inspiration
	_aura._process(0.0)
	assert_almost_eq(_sprite.scale.y, 2.0 * 1.02, 0.0001)
	assert_eq(_sprite.scale.x, 2.0, "l'échelle horizontale ne bouge pas")
	assert_almost_eq(_sprite.position.y + 100.0 * _sprite.scale.y, feet_before, 0.001)
	_aura.breath_enabled = false
	_aura._process(0.0)
	assert_eq(_sprite.scale, Vector2(2, 2))
	assert_eq(_sprite.position, Vector2(300, 400))


func test_breath_survives_reduced_motion() -> void:
	_aura.reduce_motion = true
	_aura.set_status(StatusRules.SLEEP)
	_aura._breath_time = 1.2
	_aura._process(0.0)
	assert_gt(_sprite.scale.y, 2.0, "la respiration reste")


func test_breath_is_frozen_at_speed_zero() -> void:
	_aura.speed_scale = 0.0
	for i: int in 10:
		_aura._process(0.1)
	assert_eq(_sprite.scale, Vector2(2, 2))


func test_breath_gives_way_to_a_change_made_by_the_scene() -> void:
	_aura._breath_time = 1.5
	_aura._process(0.0)
	assert_gt(_sprite.scale.y, 2.0)
	_sprite.scale = Vector2(3, 3)  # la scène prend la main (bond, retrait)
	_aura.breath_enabled = false
	_aura._process(0.0)
	assert_eq(_sprite.scale, Vector2(3, 3), "le réglage de la scène n'est pas écrasé")


func test_poison_and_toxic_state_and_density() -> void:
	_aura.set_status(StatusRules.POISON)
	assert_eq(_aura.get_status(), StatusRules.POISON)
	assert_gt(StatusAura.BUBBLE_COUNT_TOXIC, StatusAura.BUBBLE_COUNT)
	assert_between(StatusAura.BUBBLE_COUNT, 3, 5)
	assert_lt(StatusAura.TOXIC_COLOR.v, StatusAura.POISON_COLOR.v, "Toxik est plus foncé")
	_aura.set_status(StatusRules.TOXIC)
	assert_eq(_aura.get_status(), StatusRules.TOXIC)


func test_effects_draw_without_error_for_every_status_and_reduced_motion() -> void:
	for reduced: bool in [false, true]:
		_aura.reduce_motion = reduced
		for status: StringName in [StatusRules.POISON, StatusRules.TOXIC, StatusRules.FREEZE,
				StatusRules.SLEEP, StatusRules.BURN, StatusRules.PARALYSIS]:
			_aura.set_status(status)
			for t: float in [0.0, 0.4, 0.9, 1.3]:
				_aura.set_time(t)
				await wait_process_frames(1)
	assert_true(true)


func test_apply_effect_lasts_a_third_of_a_second_and_respects_reduction() -> void:
	_aura.set_status(StatusRules.POISON)
	assert_true(_aura.is_apply_shown())
	_aura._process(0.2)
	assert_true(_aura.is_apply_shown())
	_aura._process(0.15)
	assert_false(_aura.is_apply_shown(), "0,3 s")
	_aura.set_status(StatusRules.NONE)
	_aura.reduce_motion = true
	_aura.set_status(StatusRules.BURN)
	assert_false(_aura.is_apply_shown(), "« Réduire les animations » coupe la pose")
	_aura.reduce_motion = false
	_aura.set_status(StatusRules.NONE)
	_aura.speed_scale = 0.0
	_aura.set_status(StatusRules.BURN)
	assert_false(_aura.is_apply_shown(), "rien à vitesse 0")


func test_frost_keeps_its_tint_with_reduced_motion() -> void:
	_aura.reduce_motion = true
	_aura.set_status(StatusRules.FREEZE)
	_aura._process(0.016)
	assert_true(_aura.is_ice_shown())


func test_no_game_random_is_drawn() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var state := rng.state
	_aura.set_status(StatusRules.TOXIC)
	_aura.set_time(0.7)
	await wait_process_frames(1)
	assert_eq(rng.state, state)
