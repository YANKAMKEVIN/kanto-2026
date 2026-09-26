extends GutTest
## PokemonFactory : IV tirés, EV à 0, sexe, capacités de départ, PV pleins, déterminisme.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_starter_at_level_5_with_scripted_draws() -> void:
	var rng := ScriptedRng.new([32, 32, 32, 32, 32, 32, 875])
	var charmander := PokemonFactory.create(_data, &"charmander", 5, rng)
	assert_eq(rng.remaining(), 0, "six IV puis le sexe")
	assert_eq(charmander.species_id, &"charmander")
	assert_eq(charmander.level, 5)
	assert_eq(charmander.ivs[&"spe"], 31)
	assert_eq(charmander.evs[&"spe"], 0)
	assert_eq(charmander.gender, Pokemon.Gender.MALE, "875 ≤ 875 : mâle")
	assert_eq(charmander.stats[&"spe"], 13)
	assert_eq(charmander.hp, 20, "PV pleins")
	assert_eq(charmander.moves.size(), 2)
	assert_eq(charmander.moves[0].move_id, &"scratch")
	assert_eq(charmander.moves[1].pp, 40)
	assert_eq(charmander.nickname, "")


func test_gender_roll_above_the_ratio_is_female() -> void:
	var rng := ScriptedRng.new([1, 1, 1, 1, 1, 1, 876])
	assert_eq(PokemonFactory.create(_data, &"squirtle", 5, rng).gender, Pokemon.Gender.FEMALE)


func test_same_seed_gives_the_same_pokemon() -> void:
	var first := PokemonFactory.create(_data, &"bulbasaur", 5, GameRng.new(123))
	var second := PokemonFactory.create(_data, &"bulbasaur", 5, GameRng.new(123))
	assert_eq(first.to_dict(), second.to_dict())


func test_ivs_stay_in_range() -> void:
	var rng := GameRng.new(9)
	for i: int in 200:
		var pokemon := PokemonFactory.create(_data, &"squirtle", 5, rng)
		for stat: StringName in SpeciesData.STATS:
			assert_between(pokemon.ivs[stat], 0, 31)


func test_gender_ratio_over_1000_draws() -> void:
	var rng := GameRng.new(2026)
	var males := 0
	for i: int in 1000:
		if PokemonFactory.create(_data, &"charmander", 5, rng).gender == Pokemon.Gender.MALE:
			males += 1
	assert_between(males, 835, 915, "7 mâles pour 1 femelle")


func test_single_gender_and_genderless_species_do_not_roll() -> void:
	var fixture := PokemonData.new()
	fixture.load_dir("res://tests/fixtures/pokemon/valid/")
	var six: Array[int] = [1, 1, 1, 1, 1, 1]
	var wisp := PokemonFactory.create(fixture, &"wisp", 5, ScriptedRng.new(six))
	assert_eq(wisp.gender, Pokemon.Gender.NONE)
	assert_eq(PokemonFactory.create(fixture, &"flower", 5, ScriptedRng.new(six)).gender,
		Pokemon.Gender.FEMALE)
	assert_eq(PokemonFactory.create(fixture, &"vine", 5, ScriptedRng.new(six)).gender,
		Pokemon.Gender.MALE)


func test_unknown_species_is_an_error() -> void:
	assert_null(PokemonFactory.create(_data, &"missingno", 5, GameRng.new(1)))
	assert_push_error("espèce inconnue")
