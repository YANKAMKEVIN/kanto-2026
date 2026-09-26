extends GutTest
## ExpCurve : XP totale par niveau des six courbes modernes (valeurs connues des jeux).


func test_medium_slow_known_values() -> void:
	var rate := ExpCurve.Rate.MEDIUM_SLOW
	assert_eq(ExpCurve.exp_for_level(rate, 1), 0, "la formule donnerait −54")
	assert_eq(ExpCurve.exp_for_level(rate, 2), 9)
	assert_eq(ExpCurve.exp_for_level(rate, 5), 135)
	assert_eq(ExpCurve.exp_for_level(rate, 6), 179)
	assert_eq(ExpCurve.exp_for_level(rate, 16), 2535)
	assert_eq(ExpCurve.exp_for_level(rate, 36), 40007)
	assert_eq(ExpCurve.exp_for_level(rate, 100), 1059860)


func test_other_curves_at_level_100() -> void:
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.FAST, 100), 800000)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.MEDIUM_FAST, 100), 1000000)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.SLOW, 100), 1250000)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.ERRATIC, 100), 600000)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.FLUCTUATING, 100), 1640000)


func test_piecewise_curves_at_their_joints() -> void:
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.ERRATIC, 50), 125000)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.FLUCTUATING, 15), 1957)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.FLUCTUATING, 36), 46656)
	assert_eq(ExpCurve.exp_for_level(ExpCurve.Rate.MEDIUM_FAST, 10), 1000)


func test_every_curve_increases_strictly() -> void:
	for rate: ExpCurve.Rate in ExpCurve.RATE_NAMES.values():
		for level: int in range(1, ExpCurve.MAX_LEVEL):
			assert_lt(ExpCurve.exp_for_level(rate, level), ExpCurve.exp_for_level(rate, level + 1),
				"courbe %d, niveau %d" % [rate, level])


func test_level_for_exp() -> void:
	var rate := ExpCurve.Rate.MEDIUM_SLOW
	assert_eq(ExpCurve.level_for_exp(rate, 0), 1)
	assert_eq(ExpCurve.level_for_exp(rate, 134), 4)
	assert_eq(ExpCurve.level_for_exp(rate, 135), 5)
	assert_eq(ExpCurve.level_for_exp(rate, 2535), 16)
	assert_eq(ExpCurve.level_for_exp(rate, 99999999), 100, "plafond")
	assert_eq(ExpCurve.exp_for_level(rate, 150), ExpCurve.exp_for_level(rate, 100), "borné")
