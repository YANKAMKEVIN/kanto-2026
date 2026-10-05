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


# --- Jalon 7 : argent par niveau (Rouge/Bleu), rival n° 2 -----------------------------

func test_prize_per_level_uses_the_last_foe_level() -> void:
	var trainer := TrainerData.new()
	trainer.prize_per_level = 35
	assert_eq(BattleConclusion.resolve(trainer, Battle.Outcome.WIN, 8).prize_money, 280)
	assert_eq(BattleConclusion.resolve(trainer, Battle.Outcome.WIN, 12).prize_money, 420)
	assert_eq(BattleConclusion.resolve(trainer, Battle.Outcome.WIN).prize_money, 0,
		"sans niveau : rien")
	assert_eq(BattleConclusion.resolve(trainer, Battle.Outcome.WIN, -3).prize_money, 0,
		"jamais négatif")


func test_fixed_prize_wins_over_the_level() -> void:
	var trainer := TrainerData.new()
	trainer.prize_money = 120
	assert_eq(BattleConclusion.resolve(trainer, Battle.Outcome.WIN, 8).prize_money, 120)
	assert_eq(trainer.prize_for(50), 120)


func test_defeat_never_gives_nor_takes_money() -> void:
	var trainer := TrainerData.new()
	trainer.prize_per_level = 35
	trainer.can_lose = false
	for outcome: int in [Battle.Outcome.LOSS, Battle.Outcome.FLED, Battle.Outcome.NONE]:
		var result := BattleConclusion.resolve(trainer, outcome, 8)
		assert_eq(result.prize_money, 0, "issue %d : rien" % outcome)


func test_rival_route22_conclusion() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var rival := trainers.get_trainer(&"rival_route22")
	assert_not_null(rival)
	var win := BattleConclusion.resolve(rival, Battle.Outcome.WIN, 8)
	assert_eq(win.prize_money, 280, "35 × Nv. 8")
	assert_false(win.heal_party, "pas de soin")
	assert_false(win.blackout)
	var loss := BattleConclusion.resolve(rival, Battle.Outcome.LOSS, 8)
	assert_eq(loss.prize_money, 0)
	assert_true(loss.blackout, "can_lose faux : retour au point de repos")
