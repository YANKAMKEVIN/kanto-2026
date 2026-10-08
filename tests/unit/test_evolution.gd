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


# --- Candidats de fin de combat (jalon-09.md §2.3.1) -------------------------------------

func _party(members: Array) -> Party:
	var party := Party.new()
	for m: Array in members:
		party.add(_create(_real, m[0], m[1]))
	return party


func _indices(entries: Array) -> Array[int]:
	var result: Array[int] = []
	result.assign(entries)
	return result


func test_candidates_are_the_standing_members_that_gained_a_level() -> void:
	var party := _party([[&"caterpie", 7], [&"weedle", 7], [&"pidgey", 9], [&"charmander", 16],
		[&"metapod", 10]])
	party.get_at(3).hp = 0
	# Chenipan et Roucool ont gagné un niveau ; Aspicot et Chrysacier non ; Salamèche est K.O.
	var found := Evolution.candidates(party, _indices([0, 2, 3]), _real)
	assert_eq(found.size(), 1, "seul Chenipan : niveau gagné, debout, une règle satisfaite")
	assert_eq([found[0].party_index, found[0].from_species, found[0].into],
		[0, &"caterpie", &"metapod"])


func test_candidates_follow_the_party_order_whatever_the_leveled_order() -> void:
	var party := _party([[&"pidgey", 18], [&"caterpie", 8], [&"weedle", 7]])
	var found := Evolution.candidates(party, _indices([2, 0, 1]), _real)
	var order: Array = found.map(func(c: EvolutionCandidate) -> Array:
		return [c.party_index, c.into])
	assert_eq(order, [[0, &"pidgeotto"], [1, &"metapod"], [2, &"kakuna"]])


func test_one_evolution_per_pokemon_and_per_battle() -> void:
	# Un Chenipan passé de 6 à 10 devient Chrysacier ; Papilusion au prochain niveau gagné.
	var party := _party([[&"caterpie", 10]])
	var found := Evolution.candidates(party, _indices([0]), _real)
	assert_eq(found.size(), 1)
	assert_eq(found[0].into, &"metapod")


func test_no_candidate_without_a_level_gained_or_with_bad_input() -> void:
	var party := _party([[&"caterpie", 7]])
	assert_eq(Evolution.candidates(party, _indices([]), _real).size(), 0, "aucun niveau gagné")
	assert_eq(Evolution.candidates(party, _indices([4]), _real).size(), 0, "place absente")
	assert_eq(Evolution.candidates(null, _indices([0]), _real).size(), 0)
	assert_eq(Evolution.candidates(_party([[&"pikachu", 30]]), _indices([0]), _real).size(), 0,
		"Pikachu : jamais par niveau")


## Défaite ou fuite : le directeur de combat ne demande jamais les candidats (même condition
## que le bilan).
func test_only_a_win_or_a_capture_lets_evolutions_happen() -> void:
	assert_true(BattleDirector.shows_progress(Battle.Outcome.WIN))
	assert_true(BattleDirector.shows_progress(Battle.Outcome.CAUGHT))
	assert_false(BattleDirector.shows_progress(Battle.Outcome.LOSS))
	assert_false(BattleDirector.shows_progress(Battle.Outcome.FLED))


func test_exp_summary_lists_the_members_that_gained_a_level() -> void:
	var summary := ExpSummary.new()
	for spec: Array in [[2, 0], [0, 1], [1, 2]]:
		var gained := BattleEvent.new(BattleEvent.Kind.EXP_GAINED, BattleEvent.SideId.PLAYER)
		gained.party_index = spec[0]
		gained.amount = 10
		summary.add(gained)
		for i: int in spec[1]:
			var up := BattleEvent.new(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER)
			up.party_index = spec[0]
			up.level = 5 + i
			summary.add(up)
	assert_eq(summary.leveled_indices(), [0, 1] as Array[int], "ordre de l'équipe, sans 2")


# --- Ce qui change (jalon-09.md §2.3.2) --------------------------------------------------

func test_evolve_keeps_the_individual_and_returns_the_new_moves() -> void:
	var caterpie := _create(_real, &"caterpie", 7)
	caterpie.nickname = "Chenille"
	caterpie.favorite = true
	caterpie.hp = caterpie.max_hp() - 3
	caterpie.moves[0].pp = 10
	var ivs := caterpie.ivs.duplicate()
	var gender := caterpie.gender
	var experience := caterpie.experience
	var moves := Evolution.evolve(caterpie, &"metapod", _real)
	assert_eq(moves, [&"harden"] as Array[StringName], "Armure à l'évolution (Q-5)")
	assert_eq(caterpie.species_id, &"metapod")
	assert_false(caterpie.knows_move(&"harden"), "rien n'est appris ici")
	assert_eq(caterpie.nickname, "Chenille", "surnom gardé")
	assert_eq(caterpie.display_name(_real), "Chenille")
	assert_true(caterpie.favorite)
	assert_eq(caterpie.gender, gender)
	assert_eq(caterpie.ivs, ivs)
	assert_eq(caterpie.experience, experience)
	assert_eq(caterpie.level, 7)
	assert_eq(caterpie.max_hp() - caterpie.hp, 3, "PV perdus gardés")
	assert_eq(caterpie.moves[0].pp, 10, "PP gardés")
	assert_eq(caterpie.moves.size(), 2, "capacités gardées")


func test_a_late_evolution_learns_what_an_on_time_one_would_have() -> void:
	# Annulée au niveau 7 puis faite au niveau 8, ou passée de 6 à 10 d'un coup : Armure quand
	# même (même résultat qu'une évolution au niveau de la règle).
	for level: int in [8, 10]:
		var caterpie := _create(_real, &"caterpie", level)
		assert_eq(Evolution.evolve(caterpie, &"metapod", _real), [&"harden"] as Array[StringName],
			"Nv. %d" % level)
	# Une capacité déjà connue n'est jamais rendue ; aucun doublon.
	var weedle := _create(_real, &"weedle", 7)
	weedle.learn_move(&"harden", _real)
	assert_eq(Evolution.evolve(weedle, &"kakuna", _real), [] as Array[StringName])


func test_evolve_gives_no_move_learned_below_the_rule_level() -> void:
	# Herbizarre apprend Fouet Lianes au niveau 13 : un Bulbizarre qui évolue au niveau 16 ne le
	# reçoit pas de l'évolution (il l'a, ou l'a refusé, à son propre niveau).
	var bulbasaur := _create(_real, &"bulbasaur", 16)
	bulbasaur.moves.clear()
	bulbasaur.learn_move(&"tackle", _real)
	assert_eq(Evolution.evolve(bulbasaur, &"ivysaur", _real), [] as Array[StringName])
	assert_eq(bulbasaur.species_id, &"ivysaur")
	var metapod := _create(_real, &"metapod", 10)
	assert_eq(Evolution.evolve(metapod, &"butterfree", _real), [] as Array[StringName],
		"Choc Mental au niveau 12, pas à l'évolution (Rouge/Bleu)")


func test_evolve_into_an_unknown_species_changes_nothing() -> void:
	var caterpie := _create(_real, &"caterpie", 7)
	var moves := Evolution.evolve(caterpie, &"nobody", _real)
	assert_push_error("espèce inconnue")
	assert_eq(moves, [] as Array[StringName])
	assert_eq(caterpie.species_id, &"caterpie")
