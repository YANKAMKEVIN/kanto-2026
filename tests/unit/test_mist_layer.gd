extends GutTest
## Brume de la Tour Pokémon (MistLayer, jalon 19 T19) : alpha plafonné, cachée par « Réduire les
## animations », aucun traitement par image, aucune Light2D, shader sans additif.


func after_each() -> void:
	MistLayer.set_reduce_motion(false)


func _mist(alpha: float = 0.12) -> MistLayer:
	var mist := MistLayer.new()
	mist.alpha = alpha
	add_child_autofree(mist)
	return mist


func test_mist_is_displayed_under_the_characters_and_covers_the_map() -> void:
	var mist := _mist()
	mist.area = Vector2i(1920, 1728)
	assert_true(mist.is_misting())
	assert_not_null(mist.texture)
	assert_eq(mist.region_rect, Rect2(0, 0, 1920, 1728))
	assert_lt(mist.z_index, 0, "sous Entities (z 0)")
	assert_eq(mist.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED)
	assert_true(mist.material is ShaderMaterial)


func test_alpha_is_capped() -> void:
	assert_lte(MistLayer.ALPHA_MAX, 0.2)
	var mist := _mist(0.9)
	assert_lte(mist.alpha, MistLayer.ALPHA_MAX)
	assert_lte(mist.self_modulate.a, MistLayer.ALPHA_MAX + 0.0001)
	mist.alpha = 0.05
	assert_almost_eq(mist.self_modulate.a, 0.05, 0.0001)


func test_reduce_motion_hides_and_restores_every_mist() -> void:
	var a := _mist()
	var b := _mist()
	MistLayer.set_reduce_motion(true)
	assert_true(MistLayer.is_reduce_motion())
	assert_false(a.is_misting())
	assert_false(b.is_misting())
	MistLayer.set_reduce_motion(false)
	assert_true(a.is_misting())
	assert_true(b.is_misting())


func test_mist_created_while_reduced_is_hidden() -> void:
	MistLayer.set_reduce_motion(true)
	assert_false(_mist().is_misting())


func test_freed_mist_is_forgotten() -> void:
	var mist := MistLayer.new()
	add_child(mist)
	mist.free()
	MistLayer.set_reduce_motion(true)
	assert_true(MistLayer.is_reduce_motion(), "aucune référence morte")


func test_no_processing_and_no_light2d() -> void:
	var mist := _mist()
	assert_false(mist.is_processing())
	assert_false(mist.is_physics_processing())
	assert_false((mist as Node) is Light2D)
	assert_eq(mist.find_children("*", "Light2D", true, false).size(), 0)


func test_shader_scrolls_with_time_and_never_adds() -> void:
	var code := MistLayer.SHADER.code
	assert_true(code.contains("TIME"), "le mouvement vient du shader")
	assert_false(code.contains("blend_add"), "la brume voile, elle n'éclaire pas")
	assert_true(code.contains("repeat_enable"))
