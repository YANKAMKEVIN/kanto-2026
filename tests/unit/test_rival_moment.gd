extends GutTest
## RivalMoment : Grand moment « combat contre le rival », un par Dresseur, à la victoire
## seulement pour un combat rejouable (jalon-13.md §2.8, T16).

var _data: PokemonData
var _trainers: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()


func _moment(trainer_id: StringName, outcome: int) -> Dictionary:
	return {"type": "rival_battle", "date": "", "map": "route_24",
		"details": RivalMoment.details(trainer_id, outcome)}


## Simule les fins de combat [param outcomes] contre [param trainer] (règle de Boot).
func _play(trainer: TrainerData, outcomes: Array[int]) -> Array[Dictionary]:
	var moments: Array[Dictionary] = []
	for outcome: int in outcomes:
		if RivalMoment.should_record(trainer, outcome, moments):
			moments.append(_moment(trainer.id, outcome))
	return moments


func test_type_is_the_game_state_one() -> void:
	assert_eq(RivalMoment.TYPE, GameState.MOMENT_RIVAL_BATTLE)


func test_details_keep_the_trainer_and_the_outcome() -> void:
	assert_eq(RivalMoment.details(&"rival_route22", Battle.Outcome.WIN),
		{"trainer": "rival_route22", "outcome": "win"})
	assert_eq(RivalMoment.details(&"rival_lab", Battle.Outcome.LOSS),
		{"trainer": "rival_lab", "outcome": "loss"})


func test_rivals_one_and_two_record_on_win_or_loss() -> void:
	for id: StringName in [&"rival_lab", &"rival_route22"]:
		var trainer := _trainers.get_trainer(id)
		assert_false(trainer.moment_on_win, String(id))
		for outcome: int in [Battle.Outcome.WIN, Battle.Outcome.LOSS]:
			assert_true(RivalMoment.should_record(trainer, outcome, []),
				"%s : issue %d" % [id, outcome])


func test_rival_three_records_only_the_win() -> void:
	var trainer := _trainers.get_trainer(&"rival_cerulean")
	assert_true(trainer.moment_on_win)
	assert_false(RivalMoment.should_record(trainer, Battle.Outcome.LOSS, []), "défaite : rien")
	assert_true(RivalMoment.should_record(trainer, Battle.Outcome.WIN, []), "victoire : un")


func test_two_losses_then_a_win_give_exactly_one_win_moment() -> void:
	var trainer := _trainers.get_trainer(&"rival_cerulean")
	var moments := _play(trainer, [Battle.Outcome.LOSS, Battle.Outcome.LOSS,
		Battle.Outcome.WIN, Battle.Outcome.WIN] as Array[int])
	assert_eq(moments.size(), 1)
	assert_eq(moments[0]["details"], {"trainer": "rival_cerulean", "outcome": "win"})


func test_never_twice_for_the_same_rival() -> void:
	var trainer := _trainers.get_trainer(&"rival_route22")
	var moments := _play(trainer, [Battle.Outcome.LOSS, Battle.Outcome.WIN] as Array[int])
	assert_eq(moments.size(), 1, "doublon refusé pour tous les rivaux")
	assert_eq(moments[0]["details"]["outcome"], "loss", "le premier reste")


func test_one_moment_per_rival_not_per_type() -> void:
	var moments: Array[Dictionary] = [_moment(&"rival_lab", Battle.Outcome.LOSS),
		_moment(&"rival_route22", Battle.Outcome.WIN)]
	assert_true(RivalMoment.has_rival_moment(moments, &"rival_lab"))
	assert_true(RivalMoment.has_rival_moment(moments, &"rival_route22"))
	assert_false(RivalMoment.has_rival_moment(moments, &"rival_cerulean"))
	assert_true(RivalMoment.should_record(_trainers.get_trainer(&"rival_cerulean"),
		Battle.Outcome.WIN, moments), "les moments des autres rivaux ne comptent pas")


func test_other_moment_types_and_bad_entries_are_ignored() -> void:
	var moments: Array = [
		{"type": "badge", "details": {"trainer": "rival_cerulean"}},
		{"type": "rival_battle", "details": "rival_cerulean"},
		{"type": "rival_battle"},
		"rival_cerulean",
	]
	assert_false(RivalMoment.has_rival_moment(moments, &"rival_cerulean"))
	assert_false(RivalMoment.has_rival_moment(moments, &""))


func test_not_a_rival_never_records() -> void:
	assert_false(RivalMoment.should_record(null, Battle.Outcome.WIN, []))
	var brock := _trainers.get_trainer(&"pewter_gym_brock")
	assert_not_null(brock)
	assert_true(brock.team_by_starter.is_empty(), "équipe fixe")
	assert_false(RivalMoment.should_record(brock, Battle.Outcome.WIN, []))
