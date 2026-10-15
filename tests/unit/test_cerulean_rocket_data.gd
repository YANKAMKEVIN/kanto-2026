extends GutTest
## Dresseur du Rocket d'Azuria (jalon 14, dossier 17 §9.1, jalon-14.md §2.12) : posé en données
## au T23 (Nosferapti du J12 fusionné) ; sa scène, son PNJ et ses répliques arrivent au T20b.

var _trainers: TrainerLibrary


func before_all() -> void:
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	assert_true(_trainers.load_dir(), "\n".join(_trainers.get_errors()))


func test_cerulean_rocket_team_prize_and_ai() -> void:
	var trainer := _trainers.get_trainer(&"cerulean_rocket")
	assert_not_null(trainer)
	if trainer == null:
		return
	assert_eq([trainer.name, trainer.prize_money, trainer.ai],
		["Sbire Rocket", 510, BattleAI.SMART], "510 ₽ (base 30 × 17), IA smart")
	var team: Array = []
	for slot: TrainerSlot in trainer.team:
		team.append([slot.species, slot.level])
	assert_eq(team, [[&"machop", 17], [&"zubat", 17]], "Machoc 17, Nosferapti 17")
	assert_false(trainer.can_lose, "défaite : réveil au Centre (scène du T20b)")
