extends SceneTree
## Simule le premier combat contre le rival (jalon 4 T5) : pour chaque starter, 1 000
## graines (0..999), le joueur choisit au hasard parmi ses capacités (ou attaque toujours
## avec sa première capacité offensive). Affiche le taux de victoire et la durée des
## combats. Information pour Kevin, pas un seuil.
##
##   godot --headless --path . -s res://tools/simulate_first_battle.gd

const SEEDS: int = 1000
const MAX_TURNS: int = 200


func _init() -> void:
	var data_script: GDScript = load("res://game/pokemon/pokemon_data.gd")
	var data: RefCounted = data_script.new()
	if not data.load_dir():
		push_error("données invalides")
		quit(1)
		return
	var offer: RefCounted = load("res://game/pokemon/starter_offer.gd").new()
	offer.load_file()
	for policy: String in ["random", "attack"]:
		print("--- Joueur : %s" % ("capacité au hasard" if policy == "random"
			else "première capacité offensive"))
		for starter: StringName in offer.get_species_ids():
			var wins := 0
			var turns := 0
			var longest := 0
			var unfinished := 0
			for seed_value: int in SEEDS:
				var result := _simulate(data, offer, starter, seed_value, policy)
				if result[0] == 1:
					wins += 1
				elif result[0] == 0:
					unfinished += 1
				turns += result[1]
				longest = maxi(longest, result[1])
			print(("%s contre %s : %d victoires / %d (%.1f %%), %.1f tours en moyenne, "
				+ "%d au plus, %d non terminés") % [starter, offer.rival_pick(starter, data),
				wins, SEEDS, 100.0 * wins / SEEDS, float(turns) / SEEDS, longest, unfinished])
	quit()


func _simulate(data: RefCounted, offer: RefCounted, starter: StringName, seed_value: int,
		policy: String) -> Array[int]:
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(seed_value)
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var party_script: GDScript = load("res://game/pokemon/party.gd")
	var side_script: GDScript = load("res://game/battle/battle_side.gd")
	var ai: RefCounted = load("res://game/battle/battle_ai.gd").new()
	var action_script: GDScript = load("res://game/battle/battle_action.gd")
	var player_party: RefCounted = party_script.new()
	player_party.add(factory.create(data, starter, offer.level, rng))
	var foe_party: RefCounted = party_script.new()
	foe_party.add(factory.create(data, offer.rival_pick(starter, data), offer.level, rng))
	var player: RefCounted = side_script.new(player_party, true)
	var foe: RefCounted = side_script.new(foe_party, false, "Le Rival", ai)
	var battle: RefCounted = load("res://game/battle/battle.gd").new(player, foe, data, rng)
	battle.start()
	while battle.get_state() == 1 and battle.get_turn() < MAX_TURNS:
		var action: RefCounted
		if policy == "random":
			action = ai.choose(player, null, rng)
		else:
			action = action_script.move(_first_attack(data, battle))
		if battle.submit(action).is_empty():
			break
	return [battle.get_outcome(), battle.get_turn()]


## Première capacité offensive qui a des PP, sinon une capacité avec des PP, sinon Lutte.
func _first_attack(data: RefCounted, battle: RefCounted) -> int:
	var usable: Array[int] = battle.get_usable_moves()
	if usable.is_empty():
		return -1
	var moves: Array = battle.get_player_side().active.pokemon.moves
	for index: int in usable:
		if data.get_move(moves[index].move_id).is_damaging():
			return index
	return usable[0]
