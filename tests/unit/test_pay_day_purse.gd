extends GutTest
## Bourse du Jackpot (jalon 15 §2.7.3) : règle pure, sans moteur de combat.


func test_empty_purse_collects_nothing() -> void:
	var purse := PayDayPurse.new()
	assert_eq(purse.total(), 0)
	assert_eq(purse.collected(Battle.Outcome.WIN), 0)


func test_each_use_scatters_twice_the_user_level() -> void:
	var purse := PayDayPurse.new()
	assert_eq(purse.add(17), 34, "Rouge/Bleu : 2 × niveau")
	assert_eq(purse.add(18, 2), 36)
	assert_eq(purse.total(), 70, "cumulé sur le combat")


func test_per_level_comes_from_the_data() -> void:
	var purse := PayDayPurse.new()
	assert_eq(purse.add(10, 5), 50)
	assert_eq(purse.total(), 50)


func test_foe_pay_day_brings_nothing() -> void:
	var purse := PayDayPurse.new()
	assert_eq(purse.add(20, 2, false), 0, "Jackpot d'un Miaouss adverse")
	purse.add(12)
	purse.add(30, 2, false)
	assert_eq(purse.total(), 24)


func test_invalid_values_add_nothing() -> void:
	var purse := PayDayPurse.new()
	assert_eq(purse.add(0), 0)
	assert_eq(purse.add(-3), 0)
	assert_eq(purse.add(10, 0), 0)
	assert_eq(purse.add(10, -2), 0)
	assert_eq(purse.total(), 0)


func test_coins_are_collected_after_a_win_or_a_capture_only() -> void:
	var purse := PayDayPurse.new()
	purse.add(15)
	assert_eq(purse.collected(Battle.Outcome.WIN), 30)
	assert_eq(purse.collected(Battle.Outcome.CAUGHT), 30)
	assert_eq(purse.collected(Battle.Outcome.FLED), 0, "fuite : rien")
	assert_eq(purse.collected(Battle.Outcome.LOSS), 0, "défaite : rien")
	assert_eq(purse.collected(Battle.Outcome.NONE), 0)
	assert_eq(purse.total(), 30, "lire l'issue ne vide pas la bourse")
