extends GutTest
## Illustration provisoire de Kanto (T19) : image, rectangles de zones, géographie.

const AREAS_PATH := "res://assets/ui/map/kanto_placeholder_areas.json"
const IMAGE_PATH := "res://assets/ui/map/kanto_placeholder.webp"
const PORTRAIT_PATH := "res://assets/ui/map/player_portrait.png"

var _doc: Dictionary
var _zones: Dictionary


func before_each() -> void:
	var f := FileAccess.open(AREAS_PATH, FileAccess.READ)
	_doc = JSON.parse_string(f.get_as_text())
	_zones = _doc["zones"]


func _rect(id: String) -> Rect2i:
	var a: Array = _zones[id]["area"]
	return Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))


func test_image_exists_with_expected_size() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(IMAGE_PATH))
	assert_not_null(img)
	assert_eq(img.get_size(), Vector2i(1586, 992))
	var size: Array = _doc["image_size"]
	assert_eq(Vector2i(int(size[0]), int(size[1])), img.get_size())


func test_portrait_exists() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(PORTRAIT_PATH))
	assert_not_null(img)
	assert_eq(img.get_size(), Vector2i(256, 512))


func test_required_zones_present() -> void:
	for id in ["pallet_town", "route_1", "viridian_city", "route_2", "viridian_forest",
			"pewter_city", "route_22", "cerulean_city", "vermilion_city", "lavender_town",
			"celadon_city", "saffron_city", "fuchsia_city", "cinnabar_island"]:
		assert_true(_zones.has(id), id)


func test_every_rect_inside_image() -> void:
	var bounds := Rect2i(0, 0, 1586, 992)
	for id: String in _zones:
		assert_true(bounds.encloses(_rect(id)), id)


func test_no_overlap_between_any_zones() -> void:
	var ids: Array = _zones.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			assert_false(_rect(ids[i]).intersects(_rect(ids[j])),
					"%s chevauche %s" % [ids[i], ids[j]])


func test_pallet_south_of_viridian_with_route_1_between() -> void:
	var pallet := _rect("pallet_town")
	var viridian := _rect("viridian_city")
	var route := _rect("route_1")
	assert_gt(pallet.get_center().y, viridian.get_center().y)
	assert_gt(route.get_center().y, viridian.get_center().y)
	assert_lt(route.get_center().y, pallet.get_center().y)
	assert_gte(route.position.y, viridian.end.y)
	assert_lte(route.end.y, pallet.position.y)
	assert_true(route.position.x >= pallet.position.x and route.end.x <= pallet.end.x)


func test_route_22_west_and_route_2_forest_north_of_viridian() -> void:
	var viridian := _rect("viridian_city")
	var r22 := _rect("route_22")
	assert_lt(r22.get_center().x, viridian.get_center().x)
	assert_eq(r22.end.x, viridian.position.x, "Route 22 touche Jadielle")
	assert_eq(r22.position.x, _rect("celadon_city").end.x, "Route 22 touche Céladopole")
	# Jalon 22 : la Route 16 revient avec sa carte (retirée au jalon 6).
	assert_true(_zones.has("route_16"))
	assert_lt(_rect("route_2").get_center().y, viridian.get_center().y)
	assert_lt(_rect("viridian_forest").get_center().y, viridian.get_center().y)
	assert_lt(_rect("pewter_city").get_center().y, _rect("viridian_forest").get_center().y)
