extends GutTest
## Battle : changement de Pokémon de l'adversaire (jalon 13 §2.11, dossier 16 §14). Ordre
## WITHDRAWN puis SENT_OUT avant les capacités, tour consommé, coup du joueur sur le nouveau, PV
## et statut gardés, niveaux et confusion perdus, retour par first_able, XP, une fois au plus,
## jamais en Patience ni en combat sauvage.
##
## Nv. 10, IV 0. Joueur : Carapuce (Charge en place 0), Vitesse +6 pour agir le premier. Ondine
## (IA « smart », « switch ») : Salamèche (craint l'Eau), Roucool, Rattata. Tirages imposés de
## Charge : précision, critique (2 = non), aléatoire (16).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const TACKLE: Array[int] = [50, 2, 16]

var _data: PokemonData
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int = 10) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func _battle(team: Array[Pokemon], foes: Array[Pokemon], draws: Array[int],
		can_switch: bool = true, trainer: String = "Ondine",
		rules: BattleRules = BattleRules.for_trainer(TrainerData.new())) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var foe_party := Party.new()
	for pokemon: Pokemon in foes:
		foe_party.add(pokemon)
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foe_party, false, trainer, BattleAI.new(BattleAI.SMART, can_switch)),
		_data, _rng, rules)
	battle.start()
	battle.get_player_side().active.change_stage(&"spe", 6)
	return battle


func _kinds(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append([K.find_key(event.kind), BattleEvent.SideId.find_key(event.side)])
	return result


func _has(events: Array[BattleEvent], kind: BattleEvent.Kind) -> bool:
	for event: BattleEvent in events:
		if event.kind == kind:
			return true
	return false


func test_foe_switch_goes_first_and_consumes_the_turn() -> void:
	var charmander := _mon(&"charmander")
	var pidgey := _mon(&"pidgey")
	var battle := _battle([_mon(&"squirtle")], [charmander, pidgey], TACKLE)
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "seule la Charge du joueur tire")
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["WITHDRAWN", "FOE"],
		["SENT_OUT", "FOE"], ["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"]])
	assert_eq([events[1].pokemon_name, events[1].party_index, events[1].trainer_name],
		["Salamèche", 0, "Ondine"])
	assert_eq([events[2].pokemon_name, events[2].party_index], ["Roucool", 1])
	assert_eq(events[4].pokemon_name, "Roucool", "le joueur frappe le nouveau")
	assert_eq(battle.get_foe_side().active.pokemon, pidgey)
	assert_eq(charmander.hp, charmander.max_hp())
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_eq(battle.get_foe_side().party.get_all(), [charmander, pidgey] as Array[Pokemon],
		"l'ordre de l'équipe adverse ne change pas")


func test_recalled_keeps_hp_and_status_loses_battler_state_and_switches_once() -> void:
	var charmander := _mon(&"charmander")
	var pidgey := _mon(&"pidgey")
	var rattata := _mon(&"rattata")
	var squirtle := _mon(&"squirtle")
	var battle := _battle([squirtle], [charmander, pidgey, rattata], TACKLE)
	charmander.hp = charmander.max_hp() - 3
	charmander.status = StatusRules.POISON
	var before := battle.get_foe_side().active
	before.change_stage(&"atk", 2)
	before.confusion_turns = 3
	battle.submit(BattleAction.move(0))
	assert_eq(charmander.hp, charmander.max_hp() - 3, "PV gardés (pas de poison hors terrain)")
	assert_eq(charmander.status, StatusRules.POISON, "statut gardé")
	assert_eq(battle.get_participants(), [squirtle] as Array[Pokemon])
	# Roucool tombe ; Salamèche revient par first_able, sans niveaux ni confusion.
	pidgey.hp = 1
	_rng.push(TACKLE)
	var events := battle.submit(BattleAction.move(0))
	assert_true(pidgey.is_fainted())
	var back := battle.get_foe_side().active
	assert_eq(back.pokemon, charmander)
	assert_ne(back, before, "nouveau Battler")
	assert_eq(back.get_stage(&"atk"), 0)
	assert_false(back.is_confused())
	assert_eq(charmander.status, StatusRules.POISON)
	assert_false(_has(events, K.WITHDRAWN))
	# Salamèche craint toujours l'Eau et Rattata est en forme : déjà changé, il reste.
	# Rugissement pas encore joué : tirage de statut manqué (2), puis Griffe et Rugissement à
	# égalité : un tirage de l'IA (1 = Griffe), puis les deux attaques.
	_rng.push([2, 1, 50, 2, 16, 50, 2, 16])
	events = battle.submit(BattleAction.move(0))
	assert_false(_has(events, K.WITHDRAWN), "au plus un changement par combat")
	assert_eq(battle.get_foe_side().active.pokemon, charmander)
	assert_eq(_rng.remaining(), 0)


func test_foe_switches_after_the_player_switch_against_the_new_pokemon() -> void:
	var battle := _battle([_mon(&"rattata"), _mon(&"squirtle")],
		[_mon(&"charmander"), _mon(&"pidgey")], [])
	var events := battle.submit(BattleAction.switch_to(1))
	assert_eq(_rng.calls, 0, "aucun tirage")
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["WITHDRAWN", "PLAYER"],
		["SENT_OUT", "PLAYER"], ["WITHDRAWN", "FOE"], ["SENT_OUT", "FOE"]])
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_no_switch_without_the_option() -> void:
	var battle := _battle([_mon(&"squirtle")], [_mon(&"charmander"), _mon(&"pidgey")],
		[1, 50, 2, 16, 50, 2, 16], false)
	var events := battle.submit(BattleAction.move(0))
	assert_false(_has(events, K.WITHDRAWN))


func test_no_switch_during_foe_bide() -> void:
	var battle := _battle([_mon(&"squirtle")], [_mon(&"charmander"), _mon(&"pidgey")], TACKLE)
	var foe := battle.get_foe_side().active
	foe.bide_stage = 1
	foe.bide_slot = 0
	var events := battle.submit(BattleAction.move(0))
	assert_false(_has(events, K.WITHDRAWN))
	assert_true(_has(events, K.BIDE_STORING))
	assert_false(battle.get_foe_side().ai.has_switched())


func test_engine_refuses_a_switch_in_a_wild_battle() -> void:
	var battle := _battle([_mon(&"squirtle")], [_mon(&"charmander"), _mon(&"pidgey")],
		[1, 50, 2, 16, 50, 2, 16], true, "", BattleRules.for_wild())
	var events := battle.submit(BattleAction.move(0))
	assert_push_error("changement adverse refusé")
	assert_false(_has(events, K.WITHDRAWN))
