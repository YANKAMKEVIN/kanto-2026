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


# --- Chapitre Johto (JOH0, jalon-joh0.md §2.3) : heure réelle, moments, jours, forçage --------

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")


func test_periods_follow_gold_and_silver_bounds() -> void:
	var expected := {
		0: WorldClock.Period.NIGHT, 3: WorldClock.Period.NIGHT, 4: WorldClock.Period.MORNING,
		9: WorldClock.Period.MORNING, 10: WorldClock.Period.DAY, 17: WorldClock.Period.DAY,
		18: WorldClock.Period.NIGHT, 23: WorldClock.Period.NIGHT,
	}
	for hour: int in expected:
		assert_eq(WorldClock.period_of(hour), expected[hour], "%d h" % hour)
	assert_eq(WorldClock.PERIOD_NAMES.keys(), ["morning", "day", "night"])


func test_start_on_device_reads_hour_minute_and_weekday() -> void:
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-03T21:15:00")  # un mardi
	clock.start_on_device(device)
	assert_true(clock.is_active())
	assert_eq(clock.time_text(), "21:15")
	assert_eq(clock.period(), WorldClock.Period.NIGHT)
	assert_eq(clock.period_name(), &"night")
	assert_eq(clock.weekday(), 1, "mardi = 1 (0 = lundi)")
	assert_eq(clock.weekday_name(), &"tuesday")
	device.iso = "2026-11-08T05:00:00"  # un dimanche
	clock.sync()
	assert_eq(clock.weekday_name(), &"sunday")
	assert_eq(clock.period(), WorldClock.Period.MORNING)


func test_sync_announces_a_period_change_only_once() -> void:
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-03T09:59:00")
	var seen: Array[int] = []
	clock.period_changed.connect(func(period: WorldClock.Period) -> void: seen.append(period))
	clock.start_on_device(device)
	assert_eq(seen, [] as Array[int], "le démarrage n'annonce rien")
	assert_false(clock.sync(), "même moment : rien")
	device.iso = "2026-11-03T10:00:00"
	assert_true(clock.sync())
	assert_false(clock.sync())
	device.iso = "2026-11-03T18:00:00"
	assert_true(clock.sync())
	assert_eq(seen, [WorldClock.Period.DAY, WorldClock.Period.NIGHT] as Array[int])
	assert_false(WorldClock.new().sync(), "inactive : rien à relire")


func test_forcing_a_period_hides_the_real_one_until_released() -> void:
	var clock := WorldClock.new()
	var seen: Array[int] = []
	clock.period_changed.connect(func(period: WorldClock.Period) -> void: seen.append(period))
	clock.start(14)
	clock.force_period(WorldClock.Period.NIGHT)
	assert_true(clock.is_period_forced())
	assert_eq(clock.period(), WorldClock.Period.NIGHT)
	assert_eq(clock.time_text(), "14:00", "l'heure affichée reste la vraie")
	clock.force_period(WorldClock.Period.NIGHT)
	clock.release_period()
	assert_false(clock.is_period_forced())
	assert_eq(clock.period(), WorldClock.Period.DAY)
	assert_eq(seen, [WorldClock.Period.NIGHT, WorldClock.Period.DAY] as Array[int],
		"un signal par changement vu, pas pour un forçage identique")
	clock.force_period(WorldClock.Period.MORNING)
	clock.stop()
	assert_false(clock.is_period_forced(), "stop libère le forçage")


func test_advance_crosses_midnight_into_the_next_weekday() -> void:
	var clock := WorldClock.new()
	var seen: Array[int] = []
	clock.period_changed.connect(func(period: WorldClock.Period) -> void: seen.append(period))
	clock.start(23, 30)
	clock.set_weekday(6)
	clock.advance(60.0)
	assert_eq(clock.time_text(), "00:30")
	assert_eq(clock.weekday_name(), &"monday", "dimanche → lundi")
	assert_eq(seen, [] as Array[int], "toujours la nuit")
	clock.advance(4 * 60.0)
	assert_eq(seen, [WorldClock.Period.MORNING] as Array[int])
	clock.advance(3 * 24 * 60.0)
	assert_eq(clock.weekday_name(), &"thursday")
