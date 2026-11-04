extends GutTest
## JohtoPeriodRule (JOH1, `jalon-joh1.md` §2.4) : nuit de la lettre au vol, matin du vol au
## départ d'Orme, heure réelle sinon ; les drapeaux lus sont ceux de la règle.


func _flags(raised: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func test_nothing_forced_before_the_letter_and_after_orme() -> void:
	assert_eq(JohtoPeriodRule.forced_period(null), &"")
	assert_eq(JohtoPeriodRule.forced_period(_flags([])), &"")
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_arrived", &"johto_act1"])), &"",
		"les autres drapeaux de Johto ne comptent pas")
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_letter_read", &"johto_team_stolen",
		&"johto_orme_left"])), &"", "heure réelle une fois Orme reparti")


func test_night_from_the_letter_to_the_theft() -> void:
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_letter_read"])), &"night")
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_letter_read", &"johto_lugia_shadow",
		&"johto_arrived", &"johto_slept"])), &"night", "nuit encore dans la chambre du Centre")


func test_morning_from_the_theft_to_orme_leaving() -> void:
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_letter_read", &"johto_team_stolen"])),
		&"morning")
	assert_eq(JohtoPeriodRule.forced_period(_flags([&"johto_team_stolen",
		&"johto_starter_chosen"])), &"morning", "jusqu'au départ d'Orme, pas seulement au choix")


func test_period_names_are_those_of_the_clock() -> void:
	for name: StringName in [JohtoPeriodRule.NIGHT, JohtoPeriodRule.MORNING]:
		assert_true(WorldClock.PERIOD_NAMES.has(String(name)), String(name))
	assert_eq(JohtoPeriodRule.FLAGS, [&"johto_letter_read", &"johto_team_stolen",
		&"johto_orme_left"] as Array[StringName])
