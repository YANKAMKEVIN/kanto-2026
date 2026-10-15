extends GutTest
## CaveLibrary (jalon 12 T7, docs/tech/jalon-12.md §2.3) : catégorie « grotte » en données,
## sortie de la Corde Sortie, `has_sky`. Classe pure ; les vraies scènes sont vérifiées par
## `test_map_catalog` (en attente tant que T8 / T9 n'ont pas construit les cartes).


func _cave(maps: Array, escape: Variant) -> Dictionary:
	return {"caves": {"grotte": {"maps": maps, "escape": escape}}}


func _escape(map: Variant = "dehors", spawn: Variant = "devant", facing: Variant = "down"
		) -> Dictionary:
	return {"map": map, "spawn": spawn, "facing": facing}


func _map(map_id: StringName, interior: bool) -> GameMap:
	var map := GameMap.new()
	map.map_id = map_id
	map.interior = interior
	return autofree(map)


# --- Vraies données -------------------------------------------------------------------

func test_real_data_mt_moon() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), "data/world/caves.json valide")
	assert_eq(caves.get_errors().size(), 0)
	assert_eq(caves.get_caves(), [&"mt_moon"] as Array[StringName])
	assert_eq(caves.get_maps(&"mt_moon"),
		[&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"] as Array[StringName])
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		assert_true(caves.is_cave(map_id), "%s : grotte" % map_id)
		assert_eq(caves.cave_of(map_id), &"mt_moon")
		var exit := caves.escape_target(map_id)
		assert_not_null(exit)
		# Dossier 15 §11 : devant l'entrée côté Route 3, tourné vers le sud, même depuis B2F.
		assert_eq(exit.map, &"route_3")
		assert_eq(exit.spawn, &"from_mt_moon_w")
		assert_eq(exit.facing, Vector2i.DOWN)
		assert_eq(exit.cave, &"mt_moon")


func test_outside_a_cave_nothing() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	for map_id: StringName in [&"route_3", &"pewter_city", &"mt_moon_center", &"route_4", &""]:
		assert_false(caves.is_cave(map_id), "%s : pas une grotte" % map_id)
		assert_eq(caves.cave_of(map_id), &"")
		assert_null(caves.escape_target(map_id))


# --- has_sky --------------------------------------------------------------------------

func test_has_sky_outdoor_only() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_true(CaveLibrary.has_sky(_map(&"route_3", false), caves), "extérieur")
	assert_false(CaveLibrary.has_sky(_map(&"mt_moon_1f", false), caves), "grotte")
	assert_false(CaveLibrary.has_sky(_map(&"mt_moon_center", true), caves), "bâtiment")
	assert_false(CaveLibrary.has_sky(null, caves), "pas de carte")
	assert_true(CaveLibrary.has_sky(_map(&"mt_moon_1f", false), null), "sans liste")
	assert_false(CaveLibrary.has_sky(_map(&"pewter_center", true), null))


# --- Lecture et erreurs ---------------------------------------------------------------

func test_valid_dict() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.add_from_dict(_cave(["a", "b"], _escape("dehors", "devant", "left"))))
	assert_eq(caves.size(), 1)
	assert_eq(caves.get_all_maps(), [&"a", &"b"] as Array[StringName])
	assert_eq(caves.escape_target(&"b").facing, Vector2i.LEFT)
	assert_eq(caves.get_maps(&"inconnue"), [] as Array[StringName])


func test_missing_file() -> void:
	var caves := CaveLibrary.new()
	assert_false(caves.load_file("res://does/not/exist.json"))
	assert_eq(caves.size(), 0)
	assert_push_error_count(1)


func test_unknown_keys_are_errors() -> void:
	var caves := CaveLibrary.new()
	var data := _cave(["a"], _escape())
	data["autre"] = 1
	(data["caves"]["grotte"] as Dictionary)["ciel"] = true
	(data["caves"]["grotte"]["escape"] as Dictionary)["soin"] = true
	assert_false(caves.add_from_dict(data))
	assert_eq(caves.get_errors().size(), 3)
	assert_push_error_count(3)


func test_doc_key_is_allowed() -> void:
	var caves := CaveLibrary.new()
	var data := _cave(["a"], _escape())
	data["_doc"] = "texte libre"
	assert_true(caves.add_from_dict(data))


func test_empty_or_bad_maps_reject_the_cave() -> void:
	for maps: Array in [[], ["a", ""], ["a", 3], ["a", "a"]]:
		var caves := CaveLibrary.new()
		assert_false(caves.add_from_dict(_cave(maps, _escape())), "maps %s" % [maps])
		assert_eq(caves.size(), 0)
		assert_false(caves.is_cave(&"a"), "grotte écartée : %s" % [maps])
	assert_push_error_count(4)


func test_bad_escape_rejects_the_cave() -> void:
	var cases: Array = [
		null,
		_escape("", "devant", "down"),
		_escape("dehors", "  ", "down"),
		_escape("dehors", "devant", "north"),
		_escape("dehors", "devant", 2),
		_escape("a", "devant", "down"),
	]
	for escape: Variant in cases:
		var caves := CaveLibrary.new()
		assert_false(caves.add_from_dict(_cave(["a"], escape)), "sortie %s" % [escape])
		assert_false(caves.is_cave(&"a"))
		assert_null(caves.escape_target(&"a"))
	assert_push_error_count(cases.size())


func test_a_map_belongs_to_one_cave_only() -> void:
	var caves := CaveLibrary.new()
	var data := {"caves": {
		"une": {"maps": ["a", "b"], "escape": _escape()},
		"deux": {"maps": ["b", "c"], "escape": _escape()},
	}}
	assert_false(caves.add_from_dict(data))
	assert_eq(caves.get_caves(), [&"une"] as Array[StringName], "la seconde est écartée")
	assert_eq(caves.cave_of(&"b"), &"une")
	assert_false(caves.is_cave(&"c"))
	assert_push_error_count(1)


func test_caves_must_be_an_object() -> void:
	var caves := CaveLibrary.new()
	assert_false(caves.add_from_dict({"caves": []}))
	assert_false(caves.add_from_dict({"caves": {"x": "texte"}}))
	assert_eq(caves.size(), 0)
	assert_push_error_count(2)


# --- Grottes obscures (J17 T9, clé « dark ») ---------------------------------------------------

func test_mt_moon_is_not_dark() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	# Dossier 21 §5.2 : le Mont Sélénite garde son rendu validé, sans voile.
	for map_id: StringName in caves.get_maps(&"mt_moon"):
		assert_false(caves.is_dark(map_id), "%s : pas de voile" % map_id)
	assert_false(caves.is_dark(&"route_3"), "hors grotte")
	assert_false(caves.is_dark(&""))


func test_dark_key() -> void:
	var caves := CaveLibrary.new()
	var data := {"caves": {
		"noire": {"maps": ["n1", "n2"], "escape": _escape(), "dark": true},
		"claire": {"maps": ["c1"], "escape": _escape(), "dark": false},
		"sans": {"maps": ["s1"], "escape": _escape()},
	}}
	assert_true(caves.add_from_dict(data))
	assert_true(caves.is_dark(&"n1"))
	assert_true(caves.is_dark(&"n2"), "toutes les cartes de la grotte")
	assert_false(caves.is_dark(&"c1"), "dark faux")
	assert_false(caves.is_dark(&"s1"), "dark absent : faux")
	assert_false(caves.is_dark(&"dehors"))


func test_dark_must_be_a_bool() -> void:
	var caves := CaveLibrary.new()
	var data := {"caves": {"g": {"maps": ["g1"], "escape": _escape(), "dark": "oui"}}}
	assert_false(caves.add_from_dict(data))
	assert_false(caves.is_cave(&"g1"), "grotte écartée")
	assert_false(caves.is_dark(&"g1"))
	assert_push_error("« dark » doit être un booléen")
