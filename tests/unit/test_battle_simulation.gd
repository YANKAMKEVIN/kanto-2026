extends GutTest
## Simulation du premier combat (jalon 4 T5) : pour chaque starter contre celui que prend
## le rival, le combat se termine toujours (≤ 200 tours), sans erreur. Le taux de victoire
## du joueur (choix au hasard) est affiché pour information, ce n'est pas un seuil.
## Graines 0..999. Même chose avec deux façons de jouer : `tools/simulate_first_battle.gd`.

const SEEDS: int = 1000
const MAX_TURNS: int = 200

var _data: PokemonData
var _offer: StarterOffer


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()


## Joue un combat complet ; renvoie [issue, tours].
func _simulate(player_species: StringName, seed_value: int) -> Array[int]:
	var rng := GameRng.new(seed_value)
	var rival_species := _offer.rival_pick(player_species, _data)
	var player_party := Party.new()
	player_party.add(PokemonFactory.create(_data, player_species, _offer.level, rng))
	var foe_party := Party.new()
	foe_party.add(PokemonFactory.create(_data, rival_species, _offer.level, rng))
	var player := BattleSide.new(player_party, true)
	var battle := Battle.new(player, BattleSide.new(foe_party, false, "Le Rival"), _data, rng)
	battle.start()
	var chooser := BattleAI.new()
	while battle.get_state() == Battle.State.CHOOSING and battle.get_turn() < MAX_TURNS:
		if battle.submit(chooser.choose(player, null, rng)).is_empty():
			break
	return [battle.get_outcome(), battle.get_turn()]


func test_every_first_battle_ends() -> void:
	for starter: StringName in _offer.get_species_ids():
		var wins := 0
		var longest := 0
		var ended := 0
		for seed_value: int in SEEDS:
			var result := _simulate(starter, seed_value)
			if result[0] != Battle.Outcome.NONE:
				ended += 1
			if result[0] == Battle.Outcome.WIN:
				wins += 1
			longest = maxi(longest, result[1])
		assert_eq(ended, SEEDS, "%s : tous les combats se terminent" % starter)
		assert_lte(longest, MAX_TURNS)
		gut.p("%s contre %s : %d victoires sur %d (%.1f %%), %d tours au plus" % [starter,
			_offer.rival_pick(starter, _data), wins, SEEDS, 100.0 * wins / SEEDS, longest])


# --- Combats sauvages de la Route 1 (jalon 5 §4, T4) ------------------------------------

const WILD_SEEDS: int = 100
const WILD_MAX_TURNS: int = 50


## Combat sauvage : un starter Nv. [param level] (choix au hasard) contre un sauvage donné.
func _simulate_wild(starter: StringName, level: int, foe_species: StringName, foe_level: int,
		seed_value: int) -> Array[int]:
	var rng := GameRng.new(seed_value)
	var player_party := Party.new()
	player_party.add(PokemonFactory.create(_data, starter, level, rng))
	var foe_party := Party.new()
	foe_party.add(PokemonFactory.create(_data, foe_species, foe_level, rng))
	var player := BattleSide.new(player_party, true)
	var battle := Battle.new(player, BattleSide.new(foe_party, false, ""), _data, rng,
		BattleRules.for_wild())
	battle.start()
	var chooser := BattleAI.new()
	# On ne fuit jamais dans la simulation : on veut mesurer la durée d'un combat mené à terme.
	while battle.get_state() == Battle.State.CHOOSING and battle.get_turn() < WILD_MAX_TURNS:
		if battle.submit(chooser.choose(player, null, rng)).is_empty():
			break
	return [battle.get_outcome(), battle.get_turn()]


## Chaque starter Nv. [param level] contre chaque emplacement distinct (espèce, niveau max) de
## la table d'herbe de [param map_id] : tous les combats se terminent.
func _check_wild_table(map_id: StringName, level: int) -> void:
	var library := EncounterLibrary.new(_data)
	library.load_dir()
	assert_eq(library.get_errors().size(), 0)
	var table := library.get_table(map_id, &"grass")
	assert_not_null(table, "la table %s existe" % map_id)
	if table == null:
		return
	var cases: Array = []
	for slot: EncounterSlot in table.slots:
		var key := [slot.species, slot.max_level]
		if not cases.has(key):
			cases.append(key)
	for starter: StringName in _offer.get_species_ids():
		var wins := 0
		var total_turns := 0
		var runs := 0
		var longest := 0
		for case: Array in cases:
			for seed_value: int in WILD_SEEDS:
				var result := _simulate_wild(starter, level, case[0], case[1], seed_value)
				assert_ne(result[0], Battle.Outcome.NONE,
					"%s vs %s Nv.%d graine %d : le combat se termine"
					% [starter, case[0], case[1], seed_value])
				runs += 1
				total_turns += result[1]
				longest = maxi(longest, result[1])
				if result[0] == Battle.Outcome.WIN:
					wins += 1
		gut.p("%s, %s Nv. %d : %d victoires sur %d (%.1f %%), %.1f tours en moyenne, %d au plus"
			% [map_id, starter, level, wins, runs, 100.0 * wins / runs,
				float(total_turns) / runs, longest])
		assert_lte(longest, WILD_MAX_TURNS)


func test_every_wild_battle_of_route_1_ends() -> void:
	_check_wild_table(&"route_1", 5)


# --- Combats sauvages de la Route 22 (jalon 7, T21) -------------------------------------

func test_every_wild_battle_of_route_22_ends() -> void:
	# Équipe du départ de débogage « route_22 » (jalon-07.md §5.5) : starter Nv. 8.
	_check_wild_table(&"route_22", 8)
