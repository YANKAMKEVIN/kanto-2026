extends GutTest
## Issue d'une attaque lue dans le journal (chantier Combat vivant, CV.0 T2 ; §2.3, §2.4) :
## touché, raté, sans effet, esquive, échec, coups multiples, deux tours, Métronome.

const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const K := BattleEvent.Kind


func _ev(kind: BattleEvent.Kind, side: BattleEvent.SideId, fields: Dictionary = {}) -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	for key: String in fields:
		event.set(key, fields[key])
	return event


func _used(move_id: StringName, side: BattleEvent.SideId = P) -> BattleEvent:
	return _ev(K.MOVE_USED, side, {"move_id": move_id})


func _hit(amount: int, side: BattleEvent.SideId = F, extra: Dictionary = {}) -> BattleEvent:
	var fields := {"amount": amount, "max_hp": 100, "hp": 50}
	fields.merge(extra, true)
	return _ev(K.DAMAGE, side, fields)


func test_not_a_move_used_gives_null() -> void:
	var events: Array[BattleEvent] = [_ev(K.TURN_STARTED, P)]
	assert_null(MoveFxOutcome.read(events, 0))
	assert_null(MoveFxOutcome.read(events, 5))


func test_hit_reads_damage_until_the_next_move() -> void:
	var events: Array[BattleEvent] = [_ev(K.TURN_STARTED, P), _used(&"tackle"),
		_hit(30, F, {"effectiveness": 2.0, "critical": true}), _used(&"gust", F), _hit(10, P)]
	var outcome := MoveFxOutcome.read(events, 1)
	assert_eq(outcome.result, MoveFxOutcome.Result.HIT)
	assert_eq(outcome.move_id, &"tackle")
	assert_eq(outcome.user_side, P)
	assert_eq(outcome.hits, 1)
	assert_eq(outcome.damage, 30, "le coup de l'adversaire n'est pas compté")
	assert_true(outcome.critical)
	assert_eq(outcome.effectiveness, 2.0)
	assert_almost_eq(outcome.max_hit_fraction, 0.3, 0.001)
	assert_eq(outcome.end_index, 3)
	assert_true(outcome.lands())


func test_stops_at_turn_started() -> void:
	var events: Array[BattleEvent] = [_used(&"tackle"), _ev(K.TURN_STARTED, P), _hit(5)]
	var outcome := MoveFxOutcome.read(events, 0)
	assert_eq(outcome.hits, 0)
	assert_eq(outcome.end_index, 1)


func test_missed_no_effect_dodged_failed() -> void:
	var cases := [[K.MOVE_MISSED, P, MoveFxOutcome.Result.MISSED],
		[K.NO_EFFECT, F, MoveFxOutcome.Result.NO_EFFECT],
		[K.DODGED, F, MoveFxOutcome.Result.DODGED],
		[K.FAILED, P, MoveFxOutcome.Result.FAILED]]
	for case: Array in cases:
		var events: Array[BattleEvent] = [_used(&"tackle"), _ev(case[0], case[1])]
		var outcome := MoveFxOutcome.read(events, 0)
		assert_eq(outcome.result, case[2], str(case))
		assert_false(outcome.lands(), str(case))


func test_multi_hit_counts_every_damage() -> void:
	var events: Array[BattleEvent] = [_used(&"double_kick"), _hit(10), _hit(12),
		_ev(K.MULTI_HIT, F, {"amount": 2})]
	var outcome := MoveFxOutcome.read(events, 0)
	assert_eq(outcome.hits, 2)
	assert_eq(outcome.damage, 22)


func test_status_move_affects_or_changes_nothing() -> void:
	var growl: Array[BattleEvent] = [_used(&"growl"), _ev(K.STAT_CHANGED, F, {"stages": -1})]
	assert_eq(MoveFxOutcome.read(growl, 0).result, MoveFxOutcome.Result.AFFECTED)
	var capped: Array[BattleEvent] = [_used(&"growl"), _ev(K.STAT_UNCHANGED, F)]
	assert_eq(MoveFxOutcome.read(capped, 0).result, MoveFxOutcome.Result.FAILED)
	var poison: Array[BattleEvent] = [_used(&"poison_powder"),
		_ev(K.STATUS_INFLICTED, F, {"status": &"poison"})]
	var outcome := MoveFxOutcome.read(poison, 0)
	assert_eq(outcome.result, MoveFxOutcome.Result.AFFECTED)
	assert_eq(outcome.status_inflicted, &"poison")
	var splash: Array[BattleEvent] = [_used(&"splash")]
	assert_eq(MoveFxOutcome.read(splash, 0).result, MoveFxOutcome.Result.AFFECTED,
		"rien dans le journal : l'effet se joue quand même (Trempette)")


func test_fainted_target_drain_recoil_self_ko_ohko() -> void:
	var events: Array[BattleEvent] = [_used(&"explosion"), _hit(100),
		_ev(K.DRAINED_HP, P), _ev(K.RECOIL, P), _ev(K.SELF_KO, P), _ev(K.OHKO, F),
		_ev(K.FAINTED, F), _ev(K.FAINTED, P)]
	var outcome := MoveFxOutcome.read(events, 0)
	assert_true(outcome.target_fainted)
	assert_true(outcome.drained)
	assert_true(outcome.recoil)
	assert_true(outcome.self_ko)
	assert_true(outcome.ohko)


func test_two_turn_moves() -> void:
	var events: Array[BattleEvent] = [_used(&"dig"), _ev(K.CHARGE_STARTED, P, {"move_id": &"dig"}),
		_ev(K.TURN_STARTED, P), _ev(K.CHARGE_RELEASED, P), _used(&"dig"), _hit(40)]
	var first := MoveFxOutcome.read(events, 0)
	assert_eq(first.result, MoveFxOutcome.Result.CHARGING)
	assert_false(first.charge_released)
	var second := MoveFxOutcome.read(events, 4)
	assert_eq(second.result, MoveFxOutcome.Result.HIT)
	assert_true(second.charge_released)


func test_metronome_calls_a_move_that_has_its_own_outcome() -> void:
	var events: Array[BattleEvent] = [_used(&"metronome"), _used(&"ember"), _hit(20)]
	var metronome := MoveFxOutcome.read(events, 0)
	assert_eq(metronome.result, MoveFxOutcome.Result.CALLED)
	assert_eq(metronome.called_move_id, &"ember")
	var called := MoveFxOutcome.read(events, 1)
	assert_eq(called.result, MoveFxOutcome.Result.HIT)
	assert_eq(called.move_id, &"ember")
	assert_eq(MoveFxOutcome.move_starts(events), [0, 1] as Array[int])


func test_next_move_of_the_other_side_is_not_a_call() -> void:
	var events: Array[BattleEvent] = [_used(&"growl"), _used(&"tackle", F)]
	assert_eq(MoveFxOutcome.read(events, 0).called_move_id, &"")
