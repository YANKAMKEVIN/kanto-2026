extends GutTest
## MenuArt, MM.2 : aperçus des zones (captures floutées de leurs cartes peintes) et recadrage de
## l'illustration de Kanto pour une zone qui n'en a pas (16:9, autour de la zone, dans l'image).

const SIZE := Vector2(1586, 992)


func test_painted_previews_exist_for_the_zones_with_maps() -> void:
	for zone: StringName in [&"pallet_town", &"route_1", &"viridian_city", &"route_22"]:
		var preview := MenuArt.zone_preview(zone)
		assert_not_null(preview, String(zone))
		assert_almost_eq(preview.get_width() / float(preview.get_height()), 16.0 / 9.0, 0.01)
		assert_eq(MenuArt.zone_preview(zone), preview, "même objet partagé")
	assert_null(MenuArt.zone_preview(&"mt_moon"), "pas encore de carte peinte")


func test_crop_surrounds_the_zone_inside_the_image_at_16_9() -> void:
	for area: Rect2 in [Rect2(945, 210, 190, 130), Rect2(300, 25, 160, 55),
			Rect2(690, 760, 300, 190), Rect2(775, 445, 50, 150), Rect2(0, 0, 10, 10)]:
		var crop := MenuArt.zone_crop(area, SIZE)
		assert_true(Rect2(Vector2.ZERO, SIZE).encloses(crop.grow(-0.01)), "dans l'image %s" % area)
		assert_almost_eq(crop.size.x / crop.size.y, 16.0 / 9.0, 0.01)
		assert_true(crop.encloses(area) or crop.size.y >= SIZE.y - 0.5, "autour de %s" % area)
		assert_gte(crop.size.y, MenuArt.ZONE_CROP_MIN_HEIGHT - 0.5)


func test_crop_of_nothing_is_empty() -> void:
	assert_false(MenuArt.zone_crop(Rect2(), SIZE).has_area())
	assert_false(MenuArt.zone_crop(Rect2(1, 1, 5, 5), Vector2.ZERO).has_area())
