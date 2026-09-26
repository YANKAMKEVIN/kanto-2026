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
