extends GutTest
## Séquence « hors combat » partagée par la Pension (J15) et le Super Bonbon (J14) :
## OffBattleLevelUp (jalon-15.md §2.5.4), ici **sans écran** (le déroulé avec écran est vérifié
## par test_daycare_flow) : capacités apprises s'il reste une place, aucune décision à la place
## du joueur sinon ; évolution appliquée par un EvolutionDirector sans écran ; rien sans espèce.

var _data: PokemonData
var _evolutions: EvolutionDirector


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_evolutions = EvolutionDirector.new()
	add_child_autofree(_evolutions)
	_evolutions.setup(null, _data, null, null)


func _party_with(species: StringName, level: int) -> Party:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, species, level, GameRng.new(4)))
	return party


func test_without_screen_free_slots_learn_and_the_evolution_happens() -> void:
	var party := _party_with(&"charmander", 8)
	var charmander := party.get_at(0)
	assert_eq(charmander.moves.size(), 2, "Griffe, Rugissement")
	var moves: Array[StringName] = [&"ember", &"leer"]
	var evolved: bool = await OffBattleLevelUp.play(charmander, 0, moves, &"charmeleon", null,
		null, null, _evolutions, party, _data)
	assert_true(charmander.knows_move(&"ember"))
	assert_true(charmander.knows_move(&"leer"))
	assert_true(evolved)
	assert_eq(charmander.species_id, &"charmeleon")


func test_without_screen_four_moves_change_nothing() -> void:
	var party := _party_with(&"charmander", 8)
	var charmander := party.get_at(0)
	for move_id: StringName in [&"tackle", &"tail_whip"]:
		charmander.learn_move(move_id, _data)
	var before := charmander.moves.duplicate()
	var learned := await OffBattleLevelUp.teach_moves(charmander, 0,
		[&"ember"] as Array[StringName], null, null, null, _data)
	assert_eq(learned.size(), 0, "aucun oubli automatique")
	assert_eq(charmander.moves, before)


func test_no_species_no_evolution() -> void:
	var party := _party_with(&"rattata", 10)
	assert_false(await OffBattleLevelUp.offer_evolution(party.get_at(0), 0, &"", _evolutions,
		party))
	assert_eq(party.get_at(0).species_id, &"rattata")
