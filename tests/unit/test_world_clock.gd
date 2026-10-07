extends GutTest
## WorldClock (MM.1, préparé pour la phase 10) : inactive par défaut, aucune heure inventée.


func test_inactive_by_default_and_gives_no_time() -> void:
	var clock := WorldClock.new()
	assert_false(clock.is_active())
	assert_eq(clock.time_text(), "", "pas de cycle jour/nuit : rien à afficher")
	clock.advance(90.0)
	assert_eq(clock.get_hour(), 0, "une horloge arrêtée n'avance pas")


func test_start_formats_and_advances_over_midnight() -> void:
	var clock := WorldClock.new()
	var changes: Array[bool] = []
	clock.activity_changed.connect(func(active: bool) -> void: changes.append(active))
	clock.start(10, 24)
	assert_true(clock.is_active())
	assert_eq(clock.time_text(), "10:24")
	clock.advance(36.0)
	assert_eq(clock.time_text(), "11:00")
	clock.set_time(23, 50)
	clock.advance(20.0)
	assert_eq(clock.time_text(), "00:10", "minuit passé")
	clock.start(8)
	assert_eq(clock.time_text(), "08:00")
	clock.stop()
	assert_eq(clock.time_text(), "")
	assert_eq(changes, [true, false] as Array[bool], "un signal par changement d'état")


func test_set_time_wraps_out_of_range_values() -> void:
	var clock := WorldClock.new()
	clock.start(25, 70)
	assert_eq(clock.time_text(), "02:10")
	clock.set_time(-1, 0)
	assert_eq(clock.time_text(), "23:00")
