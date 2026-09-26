extends GutTest
## CameraFraming : limites de caméra, pièces plus petites que l'écran centrées.

## Zone visible du S24 en unités monde (2340×1080 à zoom 1) et référence 1920×1080.
const S24 := Vector2(2340, 1080)
const REFERENCE := Vector2(1920, 1080)


func test_big_map_keeps_its_own_limits() -> void:
	var map := Rect2i(0, 0, 4608, 3264)
	assert_eq(CameraFraming.limits_for(map, S24), map)
	assert_false(CameraFraming.is_static(map, S24))


func test_small_room_is_centered_on_both_axes() -> void:
	var room := Rect2i(0, 0, 10 * 96, 8 * 96)  # 960 × 768
	var limits := CameraFraming.limits_for(room, S24)
	assert_eq(limits.size, Vector2i(2340, 1080))
	assert_eq(limits.position, Vector2i(-690, -156))
	assert_eq(limits.get_center(), room.get_center())
	assert_true(CameraFraming.is_static(room, S24))


func test_tall_room_scrolls_vertically_and_is_centered_horizontally() -> void:
	# Pièce hypothétique plus haute que l'écran (ancien labo 15 × 14) : aucune carte
	# du jalon 2 ne défile, mais le cas reste couvert.
	var lab := Rect2i(0, 0, 15 * 96, 14 * 96)  # 1440 × 1344
	var limits := CameraFraming.limits_for(lab, S24)
	assert_eq(limits.position.y, 0)
	assert_eq(limits.size.y, 1344)
	assert_eq(limits.size.x, 2340)
	assert_eq(limits.position.x, -450)
	assert_false(CameraFraming.is_static(lab, S24))


func test_odd_extra_space_still_fills_the_view() -> void:
	var room := Rect2i(0, 0, 960, 768)
	var limits := CameraFraming.limits_for(room, Vector2(1921, 1081))
	assert_eq(limits.size, Vector2i(1921, 1081))
	assert_eq(limits.position, Vector2i(-480, -156))
	assert_true(limits.encloses(room))


func test_fractional_view_size_is_rounded_up() -> void:
	var limits := CameraFraming.limits_for(Rect2i(0, 0, 960, 768), Vector2(1919.5, 1080))
	assert_eq(limits.size.x, 1920)


func test_map_exactly_the_view_size_is_unchanged() -> void:
	var map := Rect2i(0, 0, 1920, 1080)
	assert_eq(CameraFraming.limits_for(map, REFERENCE), map)
	assert_true(CameraFraming.is_static(map, REFERENCE))


func test_offset_map_rect_is_respected() -> void:
	var room := Rect2i(96, 192, 960, 768)
	var limits := CameraFraming.limits_for(room, REFERENCE)
	assert_eq(limits.get_center(), room.get_center())
	assert_true(limits.encloses(room))


func test_lab_16_by_11_is_static_and_centered() -> void:
	var lab := Rect2i(0, 0, 16 * 96, 11 * 96)  # 1536 × 1056
	var limits := CameraFraming.limits_for(lab, S24)
	assert_true(CameraFraming.is_static(lab, S24))
	assert_eq(limits.size, Vector2i(2340, 1080))
	assert_eq(limits.get_center(), lab.get_center())
