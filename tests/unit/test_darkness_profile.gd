extends GutTest
## DarknessProfile (J17 T9, brique commune avec le J18 : docs/tech/jalon-18.md §2.4, §2.13 ;
## dossier 21 I-7) : lecture de `data/world/darkness.json`, garde-fous (jamais de noir total,
## clear < fade, durée > 0), cases → pixels, interpolation sans Flash → Flash, battement.


func _valid() -> Dictionary:
	return {
		"color": "#04060c",
		"dark": {"clear": 2.5, "fade": 4.0, "outside": 0.6},
		"lit": {"clear": 7.0, "fade": 9.0, "outside": 0.3},
		"center_offset": -48, "breath": 0.03, "breath_period": 3.5,
		"open_duration": 0.6, "glow_hole_scale": 1.0, "dither": 0.004,
	}


var _expected_errors: int = 0


func _rejects(data: Dictionary, why: String) -> void:
	var profile := DarknessProfile.new()
	assert_false(profile.load_dict(data, "test"), why)
	assert_gt(profile.get_errors().size(), 0, why + " : erreur signalée")
	# Rien n'est gardé : les défauts restent.
	assert_almost_eq(profile.dark.x, 2.5, 0.0001, why + " : défauts gardés")
	_expected_errors += profile.get_errors().size()


func test_real_data() -> void:
	var profile := DarknessProfile.new()
	assert_true(profile.load_file(), "data/world/darkness.json valide")
	assert_eq(profile.get_errors().size(), 0)
	# Dossier 21 I-7 : ≈ 2,5 cases sans Flash, ≈ 7 avec ; jamais de noir total.
	assert_almost_eq(profile.dark.x, 2.5, 0.0001)
	assert_almost_eq(profile.lit.x, 7.0, 0.0001)
	assert_lt(profile.dark.z, 1.0)
	assert_lte(profile.dark.z, DarknessProfile.MAX_OUTSIDE)
	assert_lte(profile.lit.z, profile.dark.z, "Flash éclaircit aussi le pourtour")
	assert_gt(profile.open_duration, 0.0)
	assert_lt(profile.center_offset, 0.0, "centre du trou au-dessus des pieds")


func test_tiles_to_pixels_and_states() -> void:
	var profile := DarknessProfile.new()
	assert_true(profile.load_dict(_valid()))
	var dark := profile.params_at(0.0)
	assert_almost_eq(dark.clear_px, 2.5 * 96.0, 0.001)
	assert_almost_eq(dark.fade_px, 4.0 * 96.0, 0.001)
	assert_almost_eq(dark.outside, 0.6, 0.0001)
	var lit := profile.params_at(1.0)
	assert_almost_eq(lit.clear_px, 7.0 * 96.0, 0.001)
	assert_almost_eq(lit.fade_px, 9.0 * 96.0, 0.001)
	assert_almost_eq(lit.outside, 0.3, 0.0001)
	var half := profile.params_at(0.5)
	assert_almost_eq(half.clear_px, 4.75 * 96.0, 0.001, "milieu interpolé")
	assert_almost_eq(half.outside, 0.45, 0.0001)
	assert_true(profile.params_at(-1.0).is_equal_to(dark), "borné à 0")
	assert_true(profile.params_at(3.0).is_equal_to(lit), "borné à 1")


func test_fill_params_reuses_the_object() -> void:
	var profile := DarknessProfile.new()
	var params := VeilParams.new()
	profile.fill_params(params, 1.0)
	assert_almost_eq(params.clear_px, profile.lit.x * 96.0, 0.001)


func test_breath_cut_by_reduce_motion() -> void:
	var profile := DarknessProfile.new()
	assert_true(profile.load_dict(_valid()))
	assert_almost_eq(profile.breath(false), 0.03, 0.0001)
	assert_eq(profile.breath(true), 0.0)


func test_errors() -> void:
	_expected_errors = 0
	var unknown := _valid()
	unknown["glow"] = 1
	_rejects(unknown, "clé inconnue")
	var missing := _valid()
	missing.erase("open_duration")
	_rejects(missing, "clé manquante")
	var black := _valid()
	black["dark"] = {"clear": 2.5, "fade": 4.0, "outside": 1.0}
	_rejects(black, "noir total")
	var too_dark := _valid()
	too_dark["dark"] = {"clear": 2.5, "fade": 4.0, "outside": 0.9}
	_rejects(too_dark, "au-delà de MAX_OUTSIDE")
	var inverted := _valid()
	inverted["lit"] = {"clear": 9.0, "fade": 7.0, "outside": 0.3}
	_rejects(inverted, "clear ≥ fade")
	var equal := _valid()
	equal["lit"] = {"clear": 7.0, "fade": 7.0, "outside": 0.3}
	_rejects(equal, "clear = fade")
	var zero := _valid()
	zero["open_duration"] = 0
	_rejects(zero, "durée nulle")
	var color := _valid()
	color["color"] = "noir"
	_rejects(color, "couleur invalide")
	var state_key := _valid()
	state_key["dark"] = {"clear": 2.5, "fade": 4.0, "outside": 0.6, "size": 1}
	_rejects(state_key, "clé inconnue dans un état")
	var text := _valid()
	text["breath"] = "0.03"
	_rejects(text, "nombre attendu")
	assert_push_error_count(_expected_errors, "une erreur signalée par cas")


func test_missing_file() -> void:
	var profile := DarknessProfile.new()
	assert_false(profile.load_file("res://does/not/exist.json"))
	assert_eq(profile.get_errors().size(), 1)
	assert_push_error("fichier introuvable")
