extends GutTest
## Scène de l'introduction (OUV.2, dossier 13 §4, §7, §9.0) : portraits aux trois emplacements,
## pieds au-dessus de la boîte de dialogue, entrée en fondu et montée, glissement, sortie de Poké
## Ball, « Réduire les animations », flou du fond. Durées en temps simulé (TweenClock).

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const SCENE := preload("res://game/ui/opening/intro_stage.tscn")

var _stage: IntroStage


func _make(speed: float = 1.0, reduce: bool = false) -> void:
	_stage = SCENE.instantiate() as IntroStage
	_stage.speed_scale = speed
	_stage.reduce_motion = reduce
	add_child_autofree(_stage)


func test_portraits_are_the_validated_assets() -> void:
	for id: StringName in IntroScript.PORTRAITS:
		assert_true(IntroStage.TEXTURES.has(id), "portrait « %s »" % id)
		assert_true(IntroStage.HEIGHTS.has(id))
	assert_eq(IntroStage.TEXTURES[&"chen"].get_height(), 768, "portrait peint, 768 px")
	assert_eq(IntroStage.TEXTURES[&"rival"].get_height(), 768)
	assert_eq(IntroStage.TEXTURES[&"nidorino"].resource_path,
		"res://assets/sprites/pokemon/official/033.png", "artwork officiel (A8)")


func test_the_feet_stand_above_the_dialogue_box() -> void:
	var box_top := 1080.0 - UiTokens.DIALOG_BOTTOM_MARGIN - UiTokens.DIALOG_BOX_MIN_HEIGHT
	assert_lte(UiTokens.INTRO_FEET_Y, box_top)
	assert_gte(UiTokens.INTRO_FEET_Y - UiTokens.INTRO_HEIGHT_ADULT, 0.0, "Chen entier à l'écran")


func test_show_enter_move_and_hide() -> void:
	_make()
	var clock := TweenClock.new(get_tree())
	var time := _stage.show_portrait(&"chen", &"center")
	assert_almost_eq(time, UiTokens.INTRO_PORTRAIT_IN, 0.001)
	var holder := _stage.get_holder(&"chen")
	var picture := holder.get_node(^"Picture") as TextureRect
	assert_eq(holder.anchor_left, 0.5)
	assert_eq(holder.modulate.a, 0.0, "entre en fondu")
	assert_eq(picture.position.y, -UiTokens.INTRO_HEIGHT_ADULT + UiTokens.INTRO_PORTRAIT_RISE,
		"légère montée")
	clock.run_until(func() -> bool: return not _stage.is_animating(), 2.0)
	assert_eq(holder.modulate.a, 1.0)
	assert_eq(picture.position.y, -UiTokens.INTRO_HEIGHT_ADULT)
	assert_almost_eq(_stage.show_portrait(&"chen", &"left"), UiTokens.INTRO_PORTRAIT_MOVE, 0.001)
	clock.step(UiTokens.INTRO_PORTRAIT_MOVE * 0.5)
	assert_between(holder.anchor_left, 0.27, 0.5, "glisse")
	clock.run_until(func() -> bool: return not _stage.is_animating(), 2.0)
	assert_almost_eq(holder.anchor_left, 0.27, 0.0001)
	assert_eq(_stage.get_on_stage(), {&"chen": &"left"} as Dictionary[StringName, StringName])
	assert_almost_eq(_stage.hide_portrait(&"chen"), UiTokens.INTRO_PORTRAIT_OUT, 0.001)
	assert_true(_stage.get_on_stage().is_empty())
	clock.run_until(func() -> bool: return not is_instance_valid(holder) \
		or holder.is_queued_for_deletion(), 2.0)
	assert_true(not is_instance_valid(holder) or holder.is_queued_for_deletion(), "retiré")
	clock.release()


func test_pokeball_flash_comes_before_the_pokemon() -> void:
	_make()
	var clock := TweenClock.new(get_tree())
	var time := _stage.show_portrait(&"nidorino", &"right", &"pokeball")
	assert_almost_eq(time, UiTokens.INTRO_FLASH + UiTokens.INTRO_PORTRAIT_IN, 0.001)
	var holder := _stage.get_holder(&"nidorino")
	assert_gt(_stage.get_node(^"Root/Effects").get_child_count(), 0,
		"éclair et étincelles, sur le calque des effets (le portrait est encore transparent)")
	clock.step(UiTokens.INTRO_FLASH * 0.9)
	assert_eq(holder.modulate.a, 0.0, "le Pokémon n'est pas encore là")
	clock.run_until(func() -> bool: return holder.modulate.a >= 1.0, 2.0)
	assert_eq(holder.modulate.a, 1.0)
	assert_almost_eq(holder.anchor_left, 0.72, 0.0001)
	clock.release()


func test_reduced_motion_shortens_without_rise_or_slide() -> void:
	_make(1.0, true)
	var clock := TweenClock.new(get_tree())
	var time := _stage.show_portrait(&"player", &"center")
	assert_almost_eq(time, UiTokens.INTRO_PORTRAIT_IN * UiTokens.INTRO_REDUCED, 0.001)
	var holder := _stage.get_holder(&"player")
	assert_eq((holder.get_node(^"Picture") as TextureRect).position.y,
		-UiTokens.INTRO_HEIGHT_CHILD, "pas de montée")
	clock.run_until(func() -> bool: return not _stage.is_animating(), 2.0)
	_stage.show_portrait(&"player", &"left")
	clock.step(UiTokens.INTRO_PORTRAIT_MOVE * UiTokens.INTRO_REDUCED * 0.25)
	assert_eq(holder.anchor_left, 0.5, "pas de glissement : fondu sur place")
	assert_lt(holder.modulate.a, 1.0)
	clock.run_until(func() -> bool: return not _stage.is_animating(), 2.0)
	assert_almost_eq(holder.anchor_left, 0.27, 0.0001)
	assert_eq(holder.modulate.a, 1.0)
	clock.release()


func test_instant_stage_for_tests() -> void:
	_make(0.0)
	assert_eq(_stage.show_portrait(&"rival", &"center"), 0.0)
	assert_eq(_stage.get_holder(&"rival").modulate.a, 1.0)
	assert_eq(_stage.hide_portrait(&"rival"), 0.0)
	assert_null(_stage.get_holder(&"rival"))


func test_backdrop_blur_follows_the_graphics_profile() -> void:
	_make()
	var material := _stage.get_backdrop().material as ShaderMaterial
	assert_true(material.get_shader_parameter(&"blur_on"))
	assert_eq(material.get_shader_parameter(&"blur_lod"), UiTokens.INTRO_BLUR_LOD)
	_stage.set_backdrop_blur(false)
	assert_false(material.get_shader_parameter(&"blur_on"), "Économie : voile seul")
