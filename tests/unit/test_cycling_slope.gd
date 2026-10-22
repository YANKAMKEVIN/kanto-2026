extends GutTest
## Dérive sur la pente de la Piste Cyclable (J22 T2, docs/tech/jalon-22.md §2.3).


func test_drifts_without_input_on_slope_when_free_and_unseen() -> void:
	assert_true(CyclingSlope.should_drift(Vector2i.ZERO, true, true, false))


func test_no_drift_while_a_direction_is_held() -> void:
	for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		assert_false(CyclingSlope.should_drift(dir, true, true, false), str(dir))


func test_no_drift_on_landing() -> void:
	assert_false(CyclingSlope.should_drift(Vector2i.ZERO, false, true, false))


func test_no_drift_when_player_busy() -> void:
	assert_false(CyclingSlope.should_drift(Vector2i.ZERO, true, false, false))


func test_no_drift_when_seen_by_trainer() -> void:
	assert_false(CyclingSlope.should_drift(Vector2i.ZERO, true, true, true))
