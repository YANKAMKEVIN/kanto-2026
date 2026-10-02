extends SceneTree
## Simule la progression d'un starter sur la Route 1 (jalon 5 T9, critère d'acceptation) :
## pour chaque starter (N5, au sortir du labo), des combats sauvages à la suite tirés dans la
## vraie table `route_1` (`EncounterTable.pick`), avec le vrai moteur et ses règles sauvages
## (XP, Vampigraine). Deux cas : PV et PP gardés d'un combat à l'autre (comme en jeu : une
## défaite renvoie chez Maman, équipe soignée, et compte comme un combat), ou équipe soignée
## avant chaque combat (borne basse). Jamais de fuite.
## Affiche, sur 1 000 graines, le nombre de combats pour atteindre N7, N8 et N9 (moyenne,
## médiane, extrêmes) et les défaites. Information pour Kevin, pas un seuil.
##
##   godot --headless --path . -s res://tools/simulate_route_1_exp.gd
##
## Deux façons de jouer : « hasard » (capacité au hasard, comme l'IA) et « attaque » (la
## capacité offensive la plus puissante qui a des PP).

const SEEDS: int = 1000
const TARGETS: Array[int] = [7, 8, 9]
const MAX_BATTLES: int = 200
const MAX_TURNS: int = 100
## Battle.State.CHOOSING, Battle.Outcome.LOSS (les classes du jeu sont chargées par load()).
const CHOOSING: int = 1
const LOSS: int = 2

var _data: RefCounted
var _table: RefCounted
var _factory: GDScript
var _party_script: GDScript
var _side_script: GDScript
var _battle_script: GDScript
var _rules_script: GDScript
var _action_script: GDScript
var _ai: RefCounted


func _init() -> void:
	_data = load("res://game/pokemon/pokemon_data.gd").new()
	if not _data.load_dir():
		push_error("données invalides")
		quit(1)
		return
	var library: RefCounted = load("res://game/pokemon/encounters/encounter_library.gd").new(
		_data)
	library.load_dir()
	_table = library.get_table(&"route_1", &"grass")
	var offer: RefCounted = load("res://game/pokemon/starter_offer.gd").new()
	offer.load_file()
	_factory = load("res://game/pokemon/pokemon_factory.gd")
	_party_script = load("res://game/pokemon/party.gd")
	_side_script = load("res://game/battle/battle_side.gd")
	_battle_script = load("res://game/battle/battle.gd")
	_rules_script = load("res://game/battle/battle_rules.gd")
	_action_script = load("res://game/battle/battle_action.gd")
	_ai = load("res://game/battle/battle_ai.gd").new()
	print("Route 1 : combats sauvages pour atteindre N7, N8, N9 (%d graines, départ N%d)"
		% [SEEDS, offer.level])
	for heal: bool in [false, true]:
		for policy: String in ["hasard", "attaque"]:
			print("--- Joueur : %s ; %s" % [policy, "soigné avant chaque combat" if heal
				else "PV et PP gardés d'un combat à l'autre (comme en jeu)"])
			for starter: StringName in offer.get_species_ids():
				_report(starter, offer.level, policy, heal)
	quit()


func _report(starter: StringName, level: int, policy: String, heal: bool) -> void:
	var counts: Dictionary = {}
	for target: int in TARGETS:
		counts[target] = []
	var losses := 0
	for seed_value: int in SEEDS:
		var run := _run(starter, level, seed_value, policy, heal)
		for target: int in TARGETS:
			counts[target].append(run[0][target])
		losses += run[1]
	var parts: PackedStringArray = []
	for target: int in TARGETS:
		var values: Array = counts[target]
		values.sort()
		var total := 0
		for value: int in values:
			total += value
		parts.append("N%d : %.1f (médiane %d, %d–%d)" % [target, float(total) / SEEDS,
			values[values.size() >> 1], values[0], values[-1]])
	print("%s : %s ; défaites jusqu'au N%d : %.2f en moyenne" % [starter, " · ".join(parts),
		TARGETS[-1], float(losses) / SEEDS])


## Une partie : renvoie [{ niveau visé: combats pour l'atteindre }, défaites]. [param heal] :
## équipe soignée avant chaque combat (borne basse : seule l'XP compte).
func _run(starter: StringName, level: int, seed_value: int, policy: String,
		heal: bool) -> Array:
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(seed_value)
	var party: RefCounted = _party_script.new()
	party.add(_factory.create(_data, starter, level, rng))
	var pokemon: RefCounted = party.get_lead()
	var reached: Dictionary = {}
	var battles := 0
	var losses := 0
	while battles < MAX_BATTLES and pokemon.level < TARGETS[-1]:
		if heal:
			party.heal_all()
		var encounter: RefCounted = _table.pick(rng)
		var foes: RefCounted = _party_script.new()
		foes.add(_factory.create(_data, encounter.species, encounter.level, rng))
		var player: RefCounted = _side_script.new(party, true)
		var battle: RefCounted = _battle_script.new(player, _side_script.new(foes, false, ""),
			_data, rng, _rules_script.for_wild())
		battle.start()
		while battle.get_state() == CHOOSING and battle.get_turn() < MAX_TURNS:
			if battle.submit(_choose(battle, player, rng, policy)).is_empty():
				break
		battles += 1
		if battle.get_outcome() == LOSS:
			losses += 1
			party.heal_all()
		for target: int in TARGETS:
			if pokemon.level >= target and not reached.has(target):
				reached[target] = battles
	for target: int in TARGETS:
		if not reached.has(target):
			reached[target] = MAX_BATTLES
	return [reached, losses]


func _choose(battle: RefCounted, player: RefCounted, rng: RefCounted,
		policy: String) -> RefCounted:
	if policy == "hasard":
		return _ai.choose(player, null, rng)
	var usable: Array[int] = battle.get_usable_moves()
	if usable.is_empty():
		return _action_script.move(-1)
	var moves: Array = player.active.pokemon.moves
	var best := usable[0]
	var best_power := -1
	for index: int in usable:
		var move: RefCounted = _data.get_move(moves[index].move_id)
		if move.is_damaging() and move.power > best_power:
			best = index
			best_power = move.power
	return _action_script.move(best)
