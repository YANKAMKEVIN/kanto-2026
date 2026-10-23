extends GutTest
## [LeagueDirector] (jalon 30 T8, `jalon-30.md` §2.2) sur un état de partie de test, sans Boot :
## entrée dans la salle d'Olga, victoires, défaite, point de repos du Plateau (présent ou non :
## le hall est une carte du J29), relais de carte hors Ligue.

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _state: Node
var _director: LeagueDirector
var _started: int = 0
var _cleared: Array[int] = []
var _lost: int = 0


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game()
	_state.heal_map = &"viridian_center"
	_state.heal_spawn = &"heal"
	_director = LeagueDirector.new()
	_director.setup(_state)
	_director.has_map = func(_id: StringName) -> bool: return true
	_started = 0
	_cleared.clear()
	_lost = 0
	_director.attempt_started.connect(func() -> void: _started += 1)
	_director.stage_cleared.connect(func(stage: int) -> void: _cleared.append(stage))
	_director.attempt_lost.connect(func() -> void: _lost += 1)


func after_each() -> void:
	_director.free()
	_state.free()


func _flags() -> StoryFlags:
	return _state.flags


## Carte minimale (hors arbre) d'identifiant [param map_id].
func _map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.map_id = map_id
	return autofree(map)


func test_entering_lorelei_starts_an_attempt_and_moves_the_rest_point() -> void:
	_flags().set_flag(&"beaten_league_lorelei")
	_flags().set_flag(&"league_stage_0_cleared")
	_director.on_map_changed(_map(&"league_lorelei"))
	assert_true(LeagueAttempt.is_active(_flags()))
	assert_eq(LeagueAttempt.current_stage(_flags()), 0, "depuis Olga")
	assert_false(_flags().has_flag(&"beaten_league_lorelei"), "Olga redevient à battre")
	assert_eq(_state.heal_map, LeagueDirector.REST_MAP)
	assert_eq(_state.heal_spawn, LeagueDirector.REST_SPAWN)
	assert_eq(_started, 1)


func test_without_the_plateau_hall_the_rest_point_is_kept() -> void:
	_director.has_map = func(_id: StringName) -> bool: return false
	_director.on_map_changed(_map(&"league_lorelei"))
	assert_true(LeagueAttempt.is_active(_flags()), "la tentative commence quand même")
	assert_eq(_state.heal_map, &"viridian_center", "écart J29 : point de repos inchangé")


func test_reentering_or_reloading_never_resets_the_attempt() -> void:
	_director.on_map_changed(_map(&"league_lorelei"))
	_director.on_battle_finished(&"league_lorelei", Battle.Outcome.WIN)
	_flags().set_flag(&"beaten_league_lorelei")
	_director.on_map_changed(_map(&"league_lorelei"))
	_director.on_map_changed(_map(&"league_bruno"))
	assert_eq(LeagueAttempt.current_stage(_flags()), 1)
	assert_true(_flags().has_flag(&"beaten_league_lorelei"))
	assert_eq(_started, 1)


func test_other_rooms_do_not_start_an_attempt() -> void:
	for map_id: StringName in [&"league_bruno", &"league_champion", &"hall_of_fame",
			&"viridian_city"]:
		_director.on_map_changed(_map(map_id))
	assert_false(LeagueAttempt.is_active(_flags()))
	assert_eq(_state.heal_map, &"viridian_center")


func test_a_room_during_the_attempt_forces_the_plateau_rest_point() -> void:
	# Départ de débogage `league_agatha` : tentative déjà en cours, Jadielle en point de repos.
	_flags().set_flag(LeagueAttempt.ACTIVE)
	_director.on_map_changed(_map(&"league_agatha"))
	assert_eq(_state.heal_map, LeagueDirector.REST_MAP)
	assert_eq(_started, 0)


func test_victories_clear_stages_in_order_only() -> void:
	_director.start_attempt()
	_director.on_battle_finished(&"league_bruno", Battle.Outcome.WIN)
	assert_eq(_cleared, [] as Array[int], "Aldo avant Olga : rien")
	for trainer_id: StringName in LeagueAttempt.TRAINERS:
		_director.on_battle_finished(trainer_id, Battle.Outcome.WIN)
	assert_eq(_cleared, [0, 1, 2, 3, 4] as Array[int])
	assert_eq(LeagueAttempt.current_stage(_flags()), LeagueAttempt.STAGE_DONE)
	assert_true(_flags().has_flag(&"league_stage_4_cleared"))
	assert_false(LeagueAttempt.is_champion(_flags()), "cérémonie au T17 : pas de titre ici")
	_director.on_battle_finished(&"rival_route22", Battle.Outcome.WIN)
	assert_eq(_cleared.size(), 5, "un dresseur hors Ligue ne change rien")


func test_defeat_clears_the_attempt_and_the_beaten_flags() -> void:
	_director.start_attempt()
	for stage: int in 2:
		_director.on_battle_finished(LeagueAttempt.trainer_of_stage(stage), Battle.Outcome.WIN)
		_flags().set_flag(TrainerRules.beaten_flag(LeagueAttempt.trainer_of_stage(stage)))
	_flags().set_flag(&"badge_earth")
	_director.on_battle_finished(&"league_agatha", Battle.Outcome.LOSS)
	assert_eq(_lost, 1)
	for flag: StringName in LeagueAttempt.temporary_flags() + LeagueDirector.beaten_flags():
		assert_false(_flags().has_flag(flag), "%s effacé" % flag)
	assert_true(_flags().has_flag(&"badge_earth"), "les faits permanents restent")
	assert_eq(_state.heal_map, LeagueDirector.REST_MAP, "réveil au Plateau")
	_director.on_map_changed(_map(&"league_lorelei"))
	assert_eq(LeagueAttempt.current_stage(_flags()), 0, "nouvelle tentative depuis Olga")
	assert_eq(_started, 2)


func test_beaten_flags_cover_the_five_trainers() -> void:
	assert_eq(LeagueDirector.beaten_flags(), [&"beaten_league_lorelei", &"beaten_league_bruno",
		&"beaten_league_agatha", &"beaten_league_lance", &"beaten_rival_champion"]
		as Array[StringName])
	for map_id: StringName in LeagueAttempt.ROOMS + [&"hall_of_fame"]:
		assert_true(LeagueDirector.is_league_map(map_id), map_id)
	assert_false(LeagueDirector.is_league_map(&"indigo_plateau_lobby"))
