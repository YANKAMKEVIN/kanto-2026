extends GutTest
## Drapeaux de la semaine (JOH7, `jalon-joh7.md` §2.6) : `WeeklyFlags` baisse un drapeau dès qu'une
## carte se charge un autre jour que le sien ; le jour même, il reste ; les données du jeu
## déclarent le Lokhlass du vendredi.


func _flags(raised: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func test_game_data_declares_the_friday_lapras() -> void:
	var weekly := WeeklyFlags.new()
	assert_true(weekly.load_file(), str(weekly.get_errors()))
	assert_eq(weekly.days, {&"week_friday_lapras": &"friday"} as Dictionary[StringName, StringName])


func test_flag_kept_on_its_day_and_cleared_on_another() -> void:
	var weekly := WeeklyFlags.shared()
	var flags := _flags([&"week_friday_lapras", &"johto_lapras_caught"])
	assert_eq(weekly.apply(flags, &"friday"), [] as Array[StringName])
	assert_true(flags.has_flag(&"week_friday_lapras"), "le vendredi même, le K.O. compte encore")
	assert_eq(weekly.apply(flags, &"saturday"), [&"week_friday_lapras"] as Array[StringName])
	assert_false(flags.has_flag(&"week_friday_lapras"), "baissé le samedi")
	assert_true(flags.has_flag(&"johto_lapras_caught"), "la capture ne se remet jamais à zéro")


func test_unknown_clock_changes_nothing() -> void:
	var flags := _flags([&"week_friday_lapras"])
	assert_eq(WeeklyFlags.shared().apply(flags, &""), [] as Array[StringName])
	assert_true(flags.has_flag(&"week_friday_lapras"))
	assert_eq(WeeklyFlags.shared().apply(null, &"monday"), [] as Array[StringName])


func test_unknown_day_is_an_error() -> void:
	var path := "user://weekly_flags_test.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"_doc": "x", "a": "friday", "b": "vendredi"}')
	file.close()
	var weekly := WeeklyFlags.new()
	assert_false(weekly.load_file(path))
	assert_eq(weekly.get_errors().size(), 1)
	assert_eq(weekly.days, {&"a": &"friday"} as Dictionary[StringName, StringName])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
