extends GutTest
## Placement de la bulle « ! » dans la vue (EmotePlacement, logique pure).

const VIEW := Vector2(2340.0, 1080.0)
const EXTENT := Rect2(Vector2(27.0, 67.0), Vector2(27.0, 0.0))
const MARGIN := 48.0


func test_no_shift_when_it_fits() -> void:
	assert_eq(EmotePlacement.shift(Vector2(1000.0, 500.0), VIEW, EXTENT, MARGIN), Vector2.ZERO)


func test_shifts_down_just_enough_at_the_top() -> void:
	var s := EmotePlacement.shift(Vector2(1170.0, 38.0), VIEW, EXTENT, MARGIN)
	assert_eq(s.x, 0.0)
	assert_almost_eq(38.0 + s.y - EXTENT.position.y, MARGIN, 0.001, "haut de la bulle à la marge")


func test_shifts_inward_at_side_edges() -> void:
	var l := EmotePlacement.shift(Vector2(30.0, 500.0), VIEW, EXTENT, MARGIN)
	assert_almost_eq(30.0 + l.x - 27.0, MARGIN, 0.001)
	var r := EmotePlacement.shift(Vector2(2330.0, 500.0), VIEW, EXTENT, MARGIN)
	assert_almost_eq(2330.0 + r.x + 27.0, VIEW.x - MARGIN, 0.001)


func test_shifts_up_at_the_bottom() -> void:
	var s := EmotePlacement.shift(Vector2(1000.0, 1075.0), VIEW, EXTENT, MARGIN)
	assert_almost_eq(1075.0 + s.y, VIEW.y - MARGIN, 0.001)
