extends GutTest
## BattleConclusion (jalon-04.md §14.5) : conséquences d'un combat, hors du moteur.
## Premier combat du rival (décisions de Kevin n° 6 et 15) : soin quelle que soit l'issue,
## ni argent, ni retour au point de soin.

var _rival: TrainerData


func before_all() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	_rival = trainers.get_trainer(&"rival_lab")


func test_rival_lab_heals_and_gives_nothing_whatever_the_outcome() -> void:
	assert_not_null(_rival)
	for outcome: int in [Battle.Outcome.WIN, Battle.Outcome.LOSS]:
		var result := BattleConclusion.resolve(_rival, outcome)
		assert_eq(result.outcome, outcome)
		assert_true(result.heal_party, "Chen soigne les deux Pokémon")
		assert_eq(result.prize_money, 0, "pas d'argent")
		assert_false(result.blackout, "pas de retour au point de soin")
	assert_false(_rival.gives_exp, "pas d'XP (décision n° 6)")


func test_trainer_money_only_on_victory_and_blackout_when_losing_counts() -> void:
	var trainer := TrainerData.new()
	trainer.prize_money = 120
	trainer.can_lose = false
	trainer.heal_after = false
	var win := BattleConclusion.resolve(trainer, Battle.Outcome.WIN)
	assert_eq(win.prize_money, 120)
	assert_false(win.blackout)
	assert_false(win.heal_party)
	var loss := BattleConclusion.resolve(trainer, Battle.Outcome.LOSS)
	assert_eq(loss.prize_money, 0)
	assert_true(loss.blackout)


func test_wild_battle() -> void:
	var win := BattleConclusion.resolve(null, Battle.Outcome.WIN)
	assert_false(win.heal_party)
	assert_eq(win.prize_money, 0)
	assert_false(win.blackout)
	assert_true(BattleConclusion.resolve(null, Battle.Outcome.LOSS).blackout)
