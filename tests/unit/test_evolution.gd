extends GutTest
## Evolution : cible d'évolution par niveau et par objet ; l'échange n'est jamais déclenché.

var _real: PokemonData
var _fixture: PokemonData


func before_all() -> void:
	_real = PokemonData.new()
	_real.load_dir()
	_fixture = PokemonData.new()
	_fixture.load_dir("res://tests/fixtures/pokemon/valid/")


func _create(data: PokemonData, species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(data, species, level, GameRng.new(1))


func test_level_targets_of_the_three_lines() -> void:
	assert_eq(Evolution.level_up_target(_create(_real, &"bulbasaur", 15), _real), &"")
	assert_eq(Evolution.level_up_target(_create(_real, &"bulbasaur", 16), _real), &"ivysaur")
	assert_eq(Evolution.level_up_target(_create(_real, &"ivysaur", 31), _real), &"")
	assert_eq(Evolution.level_up_target(_create(_real, &"ivysaur", 32), _real), &"venusaur")
	assert_eq(Evolution.level_up_target(_create(_real, &"charmander", 16), _real),
		&"charmeleon")
	assert_eq(Evolution.level_up_target(_create(_real, &"charmeleon", 35), _real), &"")
	assert_eq(Evolution.level_up_target(_create(_real, &"charmeleon", 36), _real),
		&"charizard")
	assert_eq(Evolution.level_up_target(_create(_real, &"squirtle", 20), _real), &"wartortle")
	assert_eq(Evolution.level_up_target(_create(_real, &"wartortle", 36), _real), &"blastoise")
	assert_eq(Evolution.level_up_target(_create(_real, &"blastoise", 100), _real), &"",
		"forme finale")


func test_forest_lines_evolve_at_7_and_10() -> void:
	# Dossier 10 §6 (jalon-09.md §2.5) : Chenipan → Chrysacier Nv. 7 → Papilusion Nv. 10,
	# Aspicot → Coconfort Nv. 7 → Dardargnan Nv. 10.
	var cases := [
		[&"caterpie", &"metapod", 7], [&"metapod", &"butterfree", 10],
		[&"weedle", &"kakuna", 7], [&"kakuna", &"beedrill", 10],
	]
	for c: Array in cases:
		assert_eq(Evolution.level_up_target(_create(_real, c[0], c[2] - 1), _real), &"",
			"%s Nv. %d" % [c[0], c[2] - 1])
		assert_eq(Evolution.level_up_target(_create(_real, c[0], c[2]), _real), c[1],
			"%s Nv. %d" % [c[0], c[2]])
	assert_eq(Evolution.level_up_target(_create(_real, &"butterfree", 100), _real), &"")
	assert_eq(Evolution.level_up_target(_create(_real, &"beedrill", 100), _real), &"")


func test_pikachu_never_evolves_by_level() -> void:
	# Raichu par la Pierre Foudre (objet absent au jalon 9) : jamais par niveau.
	for level: int in [5, 9, 30, 100]:
		assert_eq(Evolution.level_up_target(_create(_real, &"pikachu", level), _real), &"",
			"Pikachu Nv. %d" % level)
	var pikachu := _create(_real, &"pikachu", 5)
	assert_eq(Evolution.item_target(pikachu, &"thunder_stone", _real), &"raichu")
	assert_eq(Evolution.item_target(pikachu, &"moon_stone", _real), &"")


func test_item_target() -> void:
	var sprout := _create(_fixture, &"sprout", 5)
	assert_eq(Evolution.item_target(sprout, &"leaf_stone", _fixture), &"flower")
	assert_eq(Evolution.item_target(sprout, &"fire_stone", _fixture), &"")
	assert_eq(Evolution.item_target(sprout, &"", _fixture), &"")


func test_trade_rules_are_never_triggered() -> void:
	var sprout := _create(_fixture, &"sprout", 100)
	assert_eq(Evolution.level_up_target(sprout, _fixture), &"tree",
		"la règle « trade » vers vine est ignorée")
	var vine_rule := _fixture.get_species(&"sprout").evolutions[2]
	assert_eq(vine_rule.method, EvolutionRule.Method.TRADE)


func test_unknown_species_has_no_target() -> void:
	var ghost := Pokemon.new()
	ghost.species_id = &"nobody"
	assert_eq(Evolution.level_up_target(ghost, _real), &"")
	assert_eq(Evolution.item_target(ghost, &"moon_stone", _real), &"")
