extends GutTest
## MapIllustration : l'illustration de Kanto et les rectangles des zones sur cette image
## (jalon-06.md §3.6). La géométrie appartient à l'illustration, l'identité des zones à
## zones.json : mêmes identifiants des deux côtés.

var _art: MapIllustration


func before_each() -> void:
	_art = MapIllustration.new()


func test_real_illustration_loads_without_error() -> void:
	assert_true(_art.load_file(), "\n".join(_art.get_errors()))
	assert_eq(_art.get_image_path(), "res://assets/ui/map/kanto_placeholder.webp")
	assert_true(ResourceLoader.exists(_art.get_image_path()))
	assert_eq(_art.get_image_size(), Vector2i(1586, 992))
	assert_eq(_art.area_of(&"pallet_town"), Rect2i(715, 595, 200, 110))
	assert_eq(_art.area_of(&"route_1"), Rect2i(775, 445, 50, 150))
	assert_false(_art.has_area(&"route_16"), "Route 16 retirée (décision de Kevin)")
	assert_eq(_art.area_of(&"nowhere"), Rect2i())


func test_every_zone_has_an_area_and_every_area_a_zone() -> void:
	_art.load_file()
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_true(_art.check_references(zones), "\n".join(_art.get_errors()))
	for id: StringName in zones.get_ids():
		assert_true(_art.has_area(id), "%s : rectangle sur l'illustration" % id)
	assert_eq(_art.get_zone_ids().size(), zones.size())


func test_unknown_zone_reference_is_reported() -> void:
	assert_true(_art.add_from_dict({"image": "res://x.webp", "image_size": [10, 10],
		"zones": {"atlantis": {"area": [0, 0, 1, 1]}}}, "t"))
	var zones := ZoneLibrary.new()
	assert_false(_art.check_references(zones))
	assert_push_error("« atlantis » : zone absente")


func test_invalid_geometry_is_rejected() -> void:
	assert_false(_art.add_from_dict({"image": "res://x.webp", "image_size": [100, 50],
		"extra": 1,
		"zones": {
			"ok": {"area": [0, 0, 100, 50]},
			"outside": {"area": [90, 0, 20, 10]},
			"flat": {"area": [0, 0, 0, 10]},
			"short": {"area": [0, 0, 10]},
			"decimal": {"area": [0.5, 0, 10, 10]},
			"typo": {"area": [0, 0, 1, 1], "name": "X"},
			"not_object": 3,
		}}, "t"))
	assert_eq(_art.get_zone_ids(), [&"ok"] as Array[StringName])
	assert_eq(_art.area_of(&"outside"), Rect2i(), "écartée : pas touchable")
	var errors := "\n".join(_art.get_errors())
	assert_string_contains(errors, "clé inconnue « extra »")
	assert_string_contains(errors, "« outside » : « area » sort de l'image")
	assert_string_contains(errors, "clé inconnue « name »")
	assert_push_error_count(7)


func test_image_fields_are_required() -> void:
	assert_false(_art.add_from_dict({"image": "x.webp", "image_size": [0, 10], "zones": {}},
		"t"))
	assert_push_error_count(2)


func test_missing_file() -> void:
	assert_false(_art.load_file("res://tests/fixtures/absent_map.json"))
	assert_push_error("fichier introuvable")
