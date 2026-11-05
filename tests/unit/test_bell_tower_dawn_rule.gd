extends GutTest
## JOH8 (JH-55, `jalon-joh8.md` §2.6) : aube forcée au sommet de la Tour Carillon tant que Ho-Oh
## n'a pas été affronté ; heure réelle partout ailleurs et après Ho-Oh.


func _flags(raised: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func test_roof_is_forced_to_morning_until_ho_oh() -> void:
	assert_eq(BellTowerDawnRule.forced_period(&"bell_tower_roof", _flags()), &"morning")
	assert_eq(BellTowerDawnRule.forced_period(&"bell_tower_roof", null), &"morning")
	assert_eq(BellTowerDawnRule.forced_period(&"bell_tower_roof",
		_flags([&"johto_dante_defeated_1", &"johto_entei_done"])), &"morning")
	assert_eq(BellTowerDawnRule.forced_period(&"bell_tower_roof",
		_flags([&"johto_ho_oh_done"])), &"")


func test_other_maps_keep_real_time() -> void:
	for map_id: StringName in [&"bell_tower_2f", &"bell_tower_woods", &"ecruteak_city", &""]:
		assert_eq(BellTowerDawnRule.forced_period(map_id, _flags()), &"", String(map_id))


func test_morning_is_a_clock_period_name() -> void:
	assert_true(WorldClock.PERIOD_NAMES.has(String(BellTowerDawnRule.MORNING)))
