extends GutTest
## LightProfile : valeurs par défaut (aucune lumière) et lecture des blocs présents
## (docs/tech/jalon-07.md §3.2, T2).


func test_defaults_mean_no_world_light() -> void:
	var profile := LightProfile.new()
	assert_eq(profile.id, &"")
	assert_false(profile.has_grade(), "calque d'étalonnage caché")
	assert_false(profile.has_rim())
	assert_false(profile.has_cast_shadow())
	assert_false(profile.has_contact_shadow())
	assert_false(profile.has_wind())
	assert_eq(profile.grade_shadows, Vector3.ONE, "gains neutres")
	assert_eq(profile.grade_midtones, Vector3.ONE)
	assert_eq(profile.grade_highlights, Vector3.ONE)
	assert_eq(profile.sun_direction, Vector2(-0.7, -0.7), "soleil en haut à gauche")


func test_each_block_is_seen_only_when_it_shows() -> void:
	var profile := LightProfile.new()
	profile.grade_strength = 0.5
	assert_true(profile.has_grade())
	profile.rim_strength = 1.0
	assert_false(profile.has_rim(), "largeur nulle : aucun liseré")
	profile.rim_width = 5.0
	assert_true(profile.has_rim())
	profile.cast_shadow_color = Color(0.1, 0.1, 0.2, 0.34)
	assert_false(profile.has_cast_shadow(), "longueur nulle : aucune ombre portée")
	profile.cast_shadow_length = 0.26
	assert_true(profile.has_cast_shadow())
	profile.cast_shadow_color.a = 0.0
	assert_false(profile.has_cast_shadow(), "alpha nul : aucune ombre portée")
	profile.contact_color = Color(0.1, 0.1, 0.2, 0.62)
	assert_true(profile.has_contact_shadow())
	profile.wind_strength = 5.0
	assert_true(profile.has_wind())
