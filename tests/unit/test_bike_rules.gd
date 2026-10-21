extends GutTest
## Règles pures de la Bicyclette (J22 T2, docs/tech/jalon-22.md §2.1).


func test_mount_ok_outdoors_with_bike() -> void:
	assert_eq(BikeRules.can_mount(true, false, false), BikeRules.Check.OK)


func test_mount_refused_without_bike() -> void:
	assert_eq(BikeRules.can_mount(false, false, false), BikeRules.Check.NO_BIKE)
	assert_eq(BikeRules.can_mount(false, true, false), BikeRules.Check.NO_BIKE)


func test_mount_refused_indoors() -> void:
	assert_eq(BikeRules.can_mount(true, true, false), BikeRules.Check.INDOORS)


func test_mount_refused_when_busy() -> void:
	assert_eq(BikeRules.can_mount(true, false, true), BikeRules.Check.BUSY)
	assert_eq(BikeRules.can_mount(false, true, true), BikeRules.Check.BUSY)


func test_dismount_ok_off_cycling_road() -> void:
	assert_eq(BikeRules.can_dismount(false, false), BikeRules.Check.OK)


func test_dismount_refused_on_cycling_road() -> void:
	assert_eq(BikeRules.can_dismount(true, false), BikeRules.Check.ON_CYCLING_ROAD)


func test_dismount_refused_when_busy() -> void:
	assert_eq(BikeRules.can_dismount(false, true), BikeRules.Check.BUSY)
	assert_eq(BikeRules.can_dismount(true, true), BikeRules.Check.BUSY)


func test_bike_faster_than_run_faster_than_walk() -> void:
	var bike := BikeRules.step_duration(true, false)
	var run := BikeRules.step_duration(false, true)
	var walk := BikeRules.step_duration(false, false)
	assert_gt(bike, 0.0)
	assert_lt(bike, run)
	assert_lt(run, walk)
	assert_eq(run, Grid.RUN_STEP_DURATION)
	assert_eq(walk, Grid.WALK_STEP_DURATION)
	assert_eq(bike, BikeRules.BIKE_STEP_DURATION)
	assert_almost_eq(bike, 0.12, 0.0001)


func test_run_ignored_while_riding() -> void:
	assert_eq(BikeRules.step_duration(true, true), BikeRules.step_duration(true, false))


func test_entering_interior_while_riding_dismounts() -> void:
	assert_eq(BikeRules.on_map_entered(true, true, false, true), BikeRules.ENTER_DISMOUNT)
	assert_eq(BikeRules.on_map_entered(true, true, false, true), &"dismount")


func test_entering_cycling_road_on_foot_with_bike_mounts() -> void:
	assert_eq(BikeRules.on_map_entered(false, false, true, true), BikeRules.ENTER_MOUNT)
	assert_eq(BikeRules.on_map_entered(false, false, true, true), &"mount")


func test_entering_cycling_road_without_bike_does_nothing() -> void:
	assert_eq(BikeRules.on_map_entered(false, false, true, false), &"")


func test_entering_cycling_road_already_riding_does_nothing() -> void:
	assert_eq(BikeRules.on_map_entered(true, false, true, true), &"")


func test_entering_ordinary_map_does_nothing() -> void:
	assert_eq(BikeRules.on_map_entered(true, false, false, true), &"")
	assert_eq(BikeRules.on_map_entered(false, false, false, true), &"")
	assert_eq(BikeRules.on_map_entered(false, true, false, true), &"")
	assert_eq(BikeRules.on_map_entered(false, false, false, false), &"")
