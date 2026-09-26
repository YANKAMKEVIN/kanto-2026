extends GutTest
## SpeciesData : capacités au niveau (création) et apprises à un niveau (montée de niveau).

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir("res://tests/fixtures/pokemon/valid/")


func _moves(ids: Array[StringName]) -> Array[StringName]:
	return ids


func test_moves_at_level_1_and_in_learning_order() -> void:
	var sprout := _data.get_species(&"sprout")
	assert_eq(sprout.moves_at(1), _moves([&"tackle", &"growl"]))
	assert_eq(sprout.moves_at(2), _moves([&"tackle", &"growl"]))
	assert_eq(sprout.moves_at(3), _moves([&"tackle", &"growl", &"growth"]))
	assert_eq(sprout.moves_at(5), _moves([&"tackle", &"growl", &"growth", &"razor_leaf"]))


func test_moves_at_keeps_the_last_four_without_duplicates() -> void:
	var sprout := _data.get_species(&"sprout")
	assert_eq(sprout.moves_at(7), _moves([&"tackle", &"growl", &"razor_leaf", &"growth"]),
		"une capacité réapprise compte à son dernier niveau")
	assert_eq(sprout.moves_at(9), _moves([&"razor_leaf", &"growth", &"bubble", &"ember"]))
	assert_eq(sprout.moves_at(100).size(), SpeciesData.MAX_MOVES)


func test_moves_learned_at_exact_level() -> void:
	var sprout := _data.get_species(&"sprout")
	assert_eq(sprout.moves_learned_at(1), _moves([&"tackle", &"growl"]))
	assert_eq(sprout.moves_learned_at(2), _moves([]))
	assert_eq(sprout.moves_learned_at(7), _moves([&"growth"]))
	assert_eq(sprout.moves_learned_at(9), _moves([&"bubble", &"ember"]))


func test_learnset_moves_are_distinct() -> void:
	assert_eq(_data.get_species(&"sprout").learnset_moves(),
		_moves([&"tackle", &"growl", &"growth", &"razor_leaf", &"bubble", &"ember"]))


func test_real_learnsets_after_evolution_levels() -> void:
	var real := PokemonData.new()
	real.load_dir()
	assert_eq(real.get_species(&"ivysaur").moves_at(16),
		_moves([&"tackle", &"growl", &"leech_seed", &"vine_whip"]))
	assert_eq(real.get_species(&"venusaur").moves_at(1),
		_moves([&"tackle", &"growl", &"leech_seed", &"vine_whip"]))
	assert_eq(real.get_species(&"charmander").moves_learned_at(9), _moves([&"ember"]))
	assert_eq(real.get_species(&"squirtle").moves_learned_at(8), _moves([&"bubble"]))
	assert_eq(real.get_species(&"charmander").moves_at(30),
		_moves([&"ember", &"leer", &"rage", &"slash"]))
