extends GutTest
## LightingLibrary : data/world/lighting.json (valeurs C2 mesurées au prototype
## `proto/da-jadielle` : etalonnage.gdshader, objet.gdshader, ombre.gdshader,
## contact.gdshader, proto_da_jadielle.gd) et validation stricte (jalon-07.md §3.2, T2).

const EPS := 0.0001

var _library: LightingLibrary


func before_each() -> void:
	_library = LightingLibrary.new()


## Profil minimal valide, complété par [param extra].
func _profile(extra: Dictionary = {}) -> Dictionary:
	var entry := {
		"grade": {"shadows": [1, 1, 1], "midtones": [1, 1, 1], "highlights": [1, 1, 1],
			"strength": 1},
		"sun_direction": [-1, -1],
	}
	entry.merge(extra, true)
	return entry


func _add(entry: Variant, id: String = "p") -> LightProfile:
	if not _library.add_from_dict({"profiles": {id: entry}}, "test"):
		return null
	return _library.get_profile(StringName(id))


# --- Données réelles ------------------------------------------------------------------

func test_real_file_loads_without_error() -> void:
	assert_true(_library.load_file(), str(_library.get_errors()))
	# Jalon 12 (T9) : les trois profils de grotte du Mont Sélénite.
	assert_eq(_library.get_ids(), [&"golden_hour", &"interior_warm", &"forest", &"cave_1f",
		&"cave_b1f", &"cave_b2f"] as Array[StringName])
	assert_eq(LightingLibrary.DATA_PATH, "res://data/world/lighting.json")


func test_golden_hour_has_the_values_measured_on_the_prototype() -> void:
	_library.load_file()
	var gh := _library.get_profile(&"golden_hour")
	assert_not_null(gh)
	if gh == null:
		return
	assert_eq(gh.id, &"golden_hour")
	# etalonnage.gdshader : gains par zone de luminance, intensité 1.
	assert_almost_eq(gh.grade_shadows, Vector3(1.16, 1.07, 0.97), Vector3.ONE * EPS)
	assert_almost_eq(gh.grade_midtones, Vector3(1.06, 1.01, 0.91), Vector3.ONE * EPS)
	assert_almost_eq(gh.grade_highlights, Vector3(1.01, 0.97, 0.85), Vector3.ONE * EPS)
	assert_eq(gh.grade_strength, 1.0)
	# objet.gdshader : liseré (1.0, 0.82, 0.48), largeur 5 px, plein en C2 ; soleil haut-gauche.
	assert_eq(gh.rim_color.to_html(false), "ffd17a")
	assert_almost_eq(gh.rim_color.g, 0.82, 0.002)
	assert_almost_eq(gh.rim_color.b, 0.48, 0.002)
	assert_eq(gh.rim_strength, 1.0)
	assert_eq(gh.rim_width, 5.0)
	assert_almost_eq(gh.sun_direction, Vector2(-0.7, -0.7), Vector2.ONE * EPS)
	# ombre.gdshader + _ombre() : (0.10, 0.09, 0.22, 0.34), écrasement 0,26, −45°.
	assert_eq(gh.cast_shadow_color.to_html(false), "1a1738")
	assert_almost_eq(gh.cast_shadow_color.a, 0.34, EPS)
	assert_almost_eq(gh.cast_shadow_length, 0.26, EPS)
	assert_eq(gh.cast_shadow_skew_deg, -45.0)
	# contact.gdshader : (0.12, 0.10, 0.20, 0.62).
	assert_eq(gh.contact_color.to_html(false), "1f1a33")
	assert_almost_eq(gh.contact_color.a, 0.62, EPS)
	# _poser_objet() : force_vent 5 sur les arbres.
	assert_eq(gh.wind_strength, 5.0)
	assert_true(gh.has_grade() and gh.has_rim() and gh.has_cast_shadow()
		and gh.has_contact_shadow() and gh.has_wind())


func test_interior_warm_is_almost_neutral_without_rim_nor_cast_shadow() -> void:
	_library.load_file()
	var warm := _library.get_profile(&"interior_warm")
	assert_not_null(warm)
	if warm == null:
		return
	assert_true(warm.has_grade())
	for gains: Vector3 in [warm.grade_shadows, warm.grade_midtones, warm.grade_highlights]:
		assert_true(gains.x >= gains.y and gains.y >= gains.z, "chaud : %s" % gains)
		assert_almost_eq(gains, Vector3.ONE, Vector3.ONE * 0.06, "presque neutre")
	assert_false(warm.has_rim(), "pas de liseré")
	assert_false(warm.has_cast_shadow(), "pas d'ombre portée")
	assert_false(warm.has_wind())
	assert_true(warm.has_contact_shadow(), "contact gardé")
	var gh := _library.get_profile(&"golden_hour")
	assert_eq(warm.contact_color, gh.contact_color, "même contact que dehors")


## Jalon 9 (T18, dossier 10 §14, jalon-09.md §2.7.5) : la Forêt de Jade, plus sombre et plus
## froide que la Route 2 (verts profonds, ombres bleu-vert), lumière chaude seulement dans les
## ouvertures (hautes lumières), **sans filtre vert uniforme** ; soleil du jeu (haut-gauche,
## comme les rais de lumière, décision de Kevin) ; liseré, ombre portée et vent atténués sous la
## canopée. Valeurs par défaut, réglées sur capture au T19.
func test_forest_is_darker_and_cooler_without_a_green_filter() -> void:
	_library.load_file()
	var forest := _library.get_profile(&"forest")
	var gh := _library.get_profile(&"golden_hour")
	assert_not_null(forest)
	if forest == null or gh == null:
		return
	for zone: Array in [[forest.grade_shadows, gh.grade_shadows],
			[forest.grade_midtones, gh.grade_midtones]]:
		var gains: Vector3 = zone[0]
		var sum_forest := gains.x + gains.y + gains.z
		var sum_gh := (zone[1] as Vector3).x + (zone[1] as Vector3).y + (zone[1] as Vector3).z
		assert_lt(sum_forest, sum_gh, "plus sombre que la Route 2 : %s" % gains)
		assert_lt(gains.x, 1.0, "assombri : %s" % gains)
	assert_true(forest.grade_shadows.z > forest.grade_shadows.x
		and forest.grade_shadows.y > forest.grade_shadows.x, "ombres bleu-vert")
	assert_true(forest.grade_highlights.x > forest.grade_highlights.z,
		"lumière chaude dans les ouvertures")
	assert_true(forest.grade_midtones.y <= forest.grade_midtones.z + 0.001,
		"pas de filtre vert uniforme sur les tons moyens")
	assert_almost_eq(forest.sun_direction, Vector2(-0.7, -0.7), Vector2.ONE * EPS,
		"lumière du jeu : haut-gauche")
	assert_true(forest.has_rim() and forest.rim_strength < gh.rim_strength, "liseré atténué")
	assert_true(forest.has_cast_shadow()
		and forest.cast_shadow_color.a < gh.cast_shadow_color.a, "ombres portées diffuses")
	assert_true(forest.has_wind() and forest.wind_strength < gh.wind_strength, "vent filtré")
	assert_true(forest.has_contact_shadow())


func test_unknown_or_empty_profile_is_null() -> void:
	_library.load_file()
	assert_null(_library.get_profile(&"midnight"))
	assert_null(_library.get_profile(&""), "carte sans profil : aucune lumière du monde")
	assert_false(_library.has_profile(&""))


# --- Validation -----------------------------------------------------------------------

func test_minimal_profile_and_optional_blocks() -> void:
	var p := _add(_profile())
	assert_not_null(p, str(_library.get_errors()))
	assert_false(p.has_rim())
	assert_false(p.has_cast_shadow())
	assert_false(p.has_contact_shadow())
	assert_eq(p.wind_strength, 0.0)
	assert_eq(p.sun_direction, Vector2(-1, -1), "telle que donnée")


func test_invalid_profiles_are_rejected() -> void:
	var rim := {"color": "#ffd17a", "strength": 1, "width": 5}
	var cast := {"color": "#1a1738", "alpha": 0.34, "length": 0.26, "skew_deg": -45}
	var bad: Array = [
		"golden",
		{"sun_direction": [-1, -1]},
		_profile({"sky": 1}),
		_profile({"grade": {"shadows": [1, 1], "midtones": [1, 1, 1],
			"highlights": [1, 1, 1], "strength": 1}}),
		_profile({"grade": {"shadows": [0, 1, 1], "midtones": [1, 1, 1],
			"highlights": [1, 1, 1], "strength": 1}}),
		_profile({"grade": {"shadows": [1, 1, 2.5], "midtones": [1, 1, 1],
			"highlights": [1, 1, 1], "strength": 1}}),
		_profile({"grade": {"shadows": [1, 1, 1], "midtones": [1, 1, 1],
			"highlights": [1, 1, 1], "strength": 1.5}}),
		_profile({"grade": {"shadows": [1, 1, 1], "midtones": [1, 1, 1],
			"highlights": [1, 1, 1]}}),
		_profile({"sun_direction": [0, 0]}),
		_profile({"sun_direction": "up"}),
		_profile({"rim": rim.merged({"color": "gold"}, true)}),
		_profile({"rim": rim.merged({"color": "#ffd17aff"}, true)}),
		_profile({"rim": rim.merged({"width": 0}, true)}),
		_profile({"rim": rim.merged({"width": 17}, true)}),
		_profile({"rim": rim.merged({"glow": 1}, true)}),
		_profile({"cast_shadow": cast.merged({"alpha": 0}, true)}),
		_profile({"cast_shadow": cast.merged({"length": 1.2}, true)}),
		_profile({"cast_shadow": cast.merged({"skew_deg": 90}, true)}),
		_profile({"cast_shadow": {"color": "#1a1738", "alpha": 0.34}}),
		_profile({"contact": {"color": "#1f1a33", "alpha": 1.5}}),
		_profile({"contact": "dark"}),
		_profile({"wind": -1}),
		_profile({"wind": 25}),
	]
	for i: int in bad.size():
		assert_null(_add(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_gte(_library.get_errors().size(), bad.size(), "au moins une erreur par profil")
	assert_push_error_count(_library.get_errors().size(), "chaque erreur est signalée")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["un objet est attendu", "« grade » est obligatoire",
			"clé inconnue « sky »", "« grade.shadows » doit être [r, g, b]",
			"« grade.strength » doit être un nombre", "« grade.strength » est obligatoire",
			"« sun_direction » doit être [x, y], non nulle", "« rim.color » doit être",
			"« rim.width »", "clé inconnue dans « rim » : « glow »", "« cast_shadow.alpha »",
			"« cast_shadow.length »", "« cast_shadow.skew_deg »",
			"« cast_shadow.length » est obligatoire", "« contact.alpha »",
			"« contact » doit être un objet", "« wind »"]:
		assert_string_contains(errors, expected)


func test_duplicate_profile_and_root_errors() -> void:
	assert_true(_library.add_from_dict({"profiles": {"a": _profile()}}, "one"))
	assert_false(_library.add_from_dict({"profiles": {"a": _profile()}}, "two"))
	assert_eq(_library.size(), 1)
	assert_false(_library.add_from_dict({"profiles": [], "extra": 1}, "three"))
	assert_push_error_count(3)
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "two « a » : profil déjà défini")
	assert_string_contains(errors, "clé inconnue « extra »")
	assert_string_contains(errors, "« profiles » doit être un objet")


func test_missing_file_and_bad_json_report_the_line() -> void:
	assert_false(_library.load_file("res://tests/fixtures/no_such_lighting.json"))
	assert_string_contains("\n".join(_library.get_errors()), "fichier introuvable")
	var path := "user://test_lighting_bad.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\n\t\"profiles\": {\n\t\t\"a\": ,\n\t}\n}\n")
	file.close()
	assert_false(_library.load_file(path))
	assert_string_contains("\n".join(_library.get_errors()), "ligne 3")
	assert_push_error_count(2)
	DirAccess.remove_absolute(path)


# --- Profils prévus par carte (« maps », intégration du monde peint DA.0) ---------------

func test_real_file_plans_the_profiles_of_the_painted_maps() -> void:
	assert_true(_library.load_file(), str(_library.get_errors()))
	# Les 6 cartes du chantier DA (Bourg Palette, ses intérieurs, Route 1).
	for map_id: StringName in [&"pallet_town", &"route_1"]:
		assert_eq(_library.get_map_profile(map_id), &"golden_hour", String(map_id))
	for map_id: StringName in [&"player_house_2f", &"player_house_1f", &"rival_house",
			&"oak_lab"]:
		assert_eq(_library.get_map_profile(map_id), &"interior_warm", String(map_id))
	assert_eq(_library.get_map_profile(&"no_such_map"), &"", "carte sans profil prévu")
	for map_id: StringName in _library.get_planned_maps():
		assert_true(_library.has_profile(_library.get_map_profile(map_id)), String(map_id))


func test_maps_must_name_a_known_profile() -> void:
	assert_true(_library.add_from_dict({"profiles": {"a": _profile()},
		"maps": {"town": "a"}}, "one"))
	assert_eq(_library.get_map_profile(&"town"), &"a")
	assert_eq(_library.get_planned_maps(), [&"town"] as Array[StringName])
	assert_false(_library.add_from_dict({"profiles": {}, "maps": {"cave": "dark"}}, "two"))
	assert_false(_library.add_from_dict({"profiles": {}, "maps": {"town": "a"}}, "three"))
	assert_false(_library.add_from_dict({"profiles": {}, "maps": ["town"]}, "four"))
	assert_false(_library.add_from_dict({"profiles": {}, "maps": {"x": 3}}, "five"))
	assert_push_error_count(4)
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« cave » : profil inconnu « dark »")
	assert_string_contains(errors, "« town » : carte déjà définie")
	assert_string_contains(errors, "« maps » doit être un objet")
	assert_string_contains(errors, "entrée invalide « x »")
	assert_eq(_library.get_map_profile(&"cave"), &"")
