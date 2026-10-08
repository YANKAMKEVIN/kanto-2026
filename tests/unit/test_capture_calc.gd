extends GutTest
## CaptureCalc et CaptureResult (jalon 5 §2.4, Q33) : formule des 3e et 4e générations, a ≥ 255,
## secousses de 0 à 3, tirages imposés (ScriptedRng), taux d'une Poké Ball sur Roucool N3.
##
## Roucool N3 (IV 0) : 15 PV max ; taux 255 ; Poké Ball ×1. a = ⌊(45 − 2·PV)·255/45⌋ :
## 85 à PV pleins (b = 49 795, une chance sur 3), 175 à 7 PV (b = 59 648), 243 à 1 PV
## (b = 64 750). Un test réussit si roll(65536) − 1 < b, c'est-à-dire roll ≤ b.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const B_FULL := 49795


func test_catch_value_of_a_poke_ball_on_pidgey() -> void:
	assert_eq(CaptureCalc.catch_value(15, 15, 255, 1.0), 85)
	assert_eq(CaptureCalc.catch_value(15, 7, 255, 1.0), 175)
	assert_eq(CaptureCalc.catch_value(15, 1, 255, 1.0), 243)
	assert_eq(CaptureCalc.catch_value(45, 45, 45, 1.0), 15, "starter à PV pleins")


func test_shake_threshold() -> void:
	assert_eq(CaptureCalc.shake_threshold(85), B_FULL)
	assert_eq(CaptureCalc.shake_threshold(175), 59648)
	assert_eq(CaptureCalc.shake_threshold(243), 64750)
	assert_gte(CaptureCalc.shake_threshold(255), 65535, "a = 255 : tout passe")


func test_catch_value_never_falls_to_zero() -> void:
	assert_eq(CaptureCalc.catch_value(100, 100, 1, 0.1), 1, "au moins 1 (b reste défini)")
	assert_gt(CaptureCalc.shake_threshold(1), 0)


func test_a_of_255_or_more_is_caught_without_any_draw() -> void:
	var rng := ScriptedRng.new()
	var result := CaptureCalc.throw_ball(15, 1, 255, 2.0, rng)
	assert_true(result.caught)
	assert_eq(result.shakes, 3, "une capture montre toujours 3 secousses")
	assert_eq(rng.calls, 0, "aucun tirage")


func test_four_successful_tests_catch_with_three_shakes() -> void:
	var rng := ScriptedRng.new([1, B_FULL, 1000, B_FULL])
	var result := CaptureCalc.throw_ball(15, 15, 255, 1.0, rng)
	assert_true(result.caught)
	assert_eq(result.shakes, 3)
	assert_eq(rng.remaining(), 0, "4 tests")


func test_shakes_count_the_tests_passed_before_the_first_failure() -> void:
	for passed: int in 4:
		var draws: Array[int] = []
		for i: int in passed:
			draws.append(1)
		draws.append(B_FULL + 1)
		var rng := ScriptedRng.new(draws)
		var result := CaptureCalc.throw_ball(15, 15, 255, 1.0, rng)
		assert_false(result.caught, "%d tests réussis" % passed)
		assert_eq(result.shakes, passed, "%d secousses" % passed)
		assert_eq(rng.remaining(), 0, "arrêt au premier échec")


func test_one_hp_is_easier_than_half_than_full() -> void:
	var full := CaptureCalc.chance(15, 15, 255, 1.0)
	var half := CaptureCalc.chance(15, 7, 255, 1.0)
	var low := CaptureCalc.chance(15, 1, 255, 1.0)
	assert_lt(full, half)
	assert_lt(half, low)
	assert_almost_eq(full, 1.0 / 3.0, 0.001, "Roucool à PV pleins : une chance sur 3")
	assert_almost_eq(half, 0.686, 0.001)
	assert_almost_eq(low, 0.953, 0.001)
	# Le seuil de 1 PV laisse passer ce qu'il refuse à PV pleins.
	var rng := ScriptedRng.new([60000, 60000, 60000, 60000])
	assert_true(CaptureCalc.throw_ball(15, 1, 255, 1.0, rng).caught)
	assert_false(CaptureCalc.throw_ball(15, 15, 255, 1.0, ScriptedRng.new([60000])).caught)


func test_better_ball_and_status_raise_the_chance() -> void:
	var base := CaptureCalc.chance(20, 20, 45, 1.0)
	assert_gt(CaptureCalc.chance(20, 20, 45, 1.5), base, "bonus de Ball")
	assert_gt(CaptureCalc.chance(20, 20, 45, 1.0, 2.0), base, "bonus de statut (plus tard)")
	assert_eq(CaptureCalc.chance(15, 1, 255, 2.0), 1.0, "a ≥ 255")


func test_level_does_not_matter_only_the_hp_ratio() -> void:
	assert_eq(CaptureCalc.catch_value(16, 8, 255, 1.0), CaptureCalc.catch_value(14, 7, 255, 1.0))


func test_same_seed_same_results() -> void:
	var first: Array = []
	var second: Array = []
	for list: Array in [first, second]:
		var rng := GameRng.new(99)
		for i: int in 20:
			var result := CaptureCalc.throw_ball(15, 15, 255, 1.0, rng)
			list.append([result.caught, result.shakes])
	assert_eq(first, second)


func test_capture_result_defaults() -> void:
	var result := CaptureResult.new()
	assert_false(result.caught)
	assert_eq(result.shakes, 0)


## Jalon 9 (Q-6) : une cible empoisonnée vaut ×1,5 (bonus de statut, StatusRules).
func test_poison_status_bonus() -> void:
	var bonus := StatusRules.catch_bonus(StatusRules.POISON)
	assert_eq(bonus, 1.5)
	assert_eq(CaptureCalc.catch_value(15, 15, 255, 1.0, bonus), 127, "⌊85 × 1,5⌋")
	assert_gt(CaptureCalc.chance(15, 15, 255, 1.0, bonus), CaptureCalc.chance(15, 15, 255, 1.0))
	assert_eq(CaptureCalc.catch_value(15, 1, 255, 1.0, bonus), 364, "≥ 255 : assurée")
	assert_eq(CaptureCalc.chance(15, 1, 255, 1.0, bonus), 1.0)
	assert_eq(CaptureCalc.catch_value(15, 15, 255, 1.0, StatusRules.catch_bonus(&"")), 85)
