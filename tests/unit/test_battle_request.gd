extends GutTest
## BattleRequest et BattleRules : la description pure d'un combat (jalon 5 §2.2, §3.8).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_wild_rules() -> void:
	var rules := BattleRules.for_wild()
	assert_true(rules.wild)
	assert_true(rules.can_flee)
	assert_true(rules.gives_exp)
	assert_almost_eq(rules.exp_multiplier, 1.0, 0.0001)
	assert_true(rules.allow_balls)


func test_trainer_rules() -> void:
	var rules := BattleRules.for_trainer()
	assert_false(rules.wild)
	assert_false(rules.can_flee, "pas de fuite contre un dresseur")
	assert_true(rules.gives_exp)
	assert_almost_eq(rules.exp_multiplier, 1.5, 0.0001)
	assert_false(rules.allow_balls)


func test_wild_request_builds_the_foe() -> void:
	var encounter := WildEncounter.new(&"rattata", 3, &"route_1_grass")
	var request := BattleRequest.wild(encounter, _data, ScriptedRng.new(IV_0), Vector2i(23, 2))
	assert_true(request.is_wild())
	assert_eq(request.intro, BattleRequest.Intro.WILD)
	assert_null(request.trainer)
	assert_eq(request.foe_name, "", "un sauvage n'a pas de dresseur")
	assert_eq(request.origin_cell, Vector2i(23, 2))
	assert_not_null(request.rules)
	assert_true(request.rules.can_flee)
	assert_eq(request.foe_party.size(), 1)
	var foe := request.foe_party.get_lead()
	assert_eq(foe.species_id, &"rattata")
	assert_eq(foe.level, 3)
	assert_eq(foe.hp, foe.max_hp(), "le sauvage entre en pleine forme")


func test_trainer_request_carries_the_party_and_actors() -> void:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"squirtle", 5, ScriptedRng.new(IV_0)))
	var actors: Dictionary[StringName, StringName] = { &"foe": &"rival_npc" }
	var request := BattleRequest.trainer_battle(null, party, actors)
	assert_false(request.is_wild())
	assert_eq(request.intro, BattleRequest.Intro.TRAINER)
	assert_eq(request.foe_party.size(), 1)
	assert_false(request.rules.can_flee)
	assert_eq(request.world_actors.get(&"foe"), &"rival_npc")
