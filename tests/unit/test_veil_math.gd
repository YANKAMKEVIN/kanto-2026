extends GutTest
## VeilMath (J17 T9 / J18 §2.4, §2.13) : miroir du shader du voile (opacité en un point), trous
## des halos fixes, centre du corps du joueur. Dossier 21 I-7, I-8 : le joueur n'est jamais voilé,
## jamais de noir total, Flash éclaire loin.

const TILE := 96.0

var _profile: DarknessProfile


func before_each() -> void:
	_profile = DarknessProfile.new()
	assert_true(_profile.load_file())


func _glow(type: StringName, at: Vector2) -> LightGlow:
	var glow := LightGlow.new()
	glow.glow_type = type
	glow.position = at
	add_child_autofree(glow)
	return glow


func test_player_never_veiled() -> void:
	var feet := Vector2(1000.0, 800.0)
	var center := VeilMath.body_center(feet, _profile.center_offset)
	assert_eq(center, Vector2(1000.0, 800.0 + _profile.center_offset))
	var params := _profile.params_at(0.0)
	var none := PackedVector4Array()
	assert_eq(VeilMath.alpha_at(center, center, params, none), 0.0, "centre du corps")
	assert_eq(VeilMath.alpha_at(feet, center, params, none), 0.0, "pieds")
	assert_eq(VeilMath.alpha_at(feet + Vector2(0.0, -128.0), center, params, none), 0.0,
		"tête (sprite de 128 px)")
	# Compagnon adjacent (une case à côté) : dans le halo net.
	assert_eq(VeilMath.alpha_at(feet + Vector2(TILE, 0.0), center, params, none), 0.0)


func test_outside_the_halo_never_black() -> void:
	var center := Vector2(500.0, 500.0)
	var params := _profile.params_at(0.0)
	var far := center + Vector2(10.0 * TILE, 0.0)
	assert_almost_eq(VeilMath.alpha_at(far, center, params, PackedVector4Array()),
		params.outside, 0.0001)
	assert_lt(params.outside, 1.0, "jamais de noir total")
	var middle := center + Vector2(3.25 * TILE, 0.0)
	var alpha := VeilMath.alpha_at(middle, center, params, PackedVector4Array())
	assert_between(alpha, 0.01, params.outside - 0.01, "fondu entre 2,5 et 4 cases")


func test_flash_lights_far() -> void:
	var center := Vector2.ZERO
	var dark := _profile.params_at(0.0)
	var lit := _profile.params_at(1.0)
	var six := Vector2(6.0 * TILE, 0.0)
	assert_lt(VeilMath.alpha_at(six, center, lit, PackedVector4Array()), 0.1,
		"Flash : alpha < 0,1 à 6 cases")
	assert_almost_eq(VeilMath.alpha_at(six, center, dark, PackedVector4Array()), dark.outside,
		0.0001, "sans Flash : voilé à 6 cases")


func test_breath_scales_the_player_hole() -> void:
	var params := _profile.params_at(0.0)
	var edge := Vector2(params.fade_px + 5.0, 0.0)
	assert_almost_eq(VeilMath.alpha_at(edge, Vector2.ZERO, params, PackedVector4Array(), 1.0),
		params.outside, 0.0001)
	assert_lt(VeilMath.alpha_at(edge, Vector2.ZERO, params, PackedVector4Array(), 1.1),
		params.outside, "halo élargi au plus fort du battement")


func test_glow_holes() -> void:
	var lamp := _glow(&"lamp", Vector2(2000.0, 300.0))
	var glows: Array[LightGlow] = [lamp]
	var sources := VeilMath.sources_of(glows, LightGlow.library(), 1.0)
	assert_eq(sources.size(), 1)
	var radius := LightGlow.library().get_type(&"lamp").radius * TILE
	assert_eq(sources[0], Vector4(2000.0, 300.0, radius, 1.0))
	var params := _profile.params_at(0.0)
	var player := Vector2.ZERO
	assert_eq(VeilMath.alpha_at(Vector2(2000.0, 300.0), player, params, sources), 0.0,
		"une lampe perce le voile")
	assert_almost_eq(VeilMath.alpha_at(Vector2(2000.0 + radius + 1.0, 300.0), player, params,
		sources), params.outside, 0.0001, "au-delà de son rayon : voilé")
	var half := VeilMath.sources_of(glows, LightGlow.library(), 0.5)
	assert_almost_eq(half[0].z, radius * 0.5, 0.001, "échelle des trous")


func test_unknown_glow_type_ignored() -> void:
	var glows: Array[LightGlow] = [_glow(&"lamp", Vector2.ZERO)]
	var empty := LightGlowLibrary.new()
	assert_eq(VeilMath.sources_of(glows, empty, 1.0).size(), 0, "type absent de la liste")


func test_at_most_sixteen_sources() -> void:
	var glows: Array[LightGlow] = []
	for i: int in 17:
		glows.append(_glow(&"shaft", Vector2(i * 100.0, 0.0)))
	var sources := VeilMath.sources_of(glows, LightGlow.library(), 1.0)
	assert_eq(sources.size(), VeilMath.MAX_SOURCES, "16 gardées")
	assert_eq(sources[0].x, 0.0, "les premières")
	assert_push_error("plus de 16 halos")


func test_cover_rect() -> void:
	var view := Rect2(100.0, 50.0, 1920.0, 1080.0)
	var cover := VeilMath.cover_rect(view, 96.0)
	assert_true(cover.encloses(view))
	assert_eq(cover.position, Vector2(4.0, -46.0))
