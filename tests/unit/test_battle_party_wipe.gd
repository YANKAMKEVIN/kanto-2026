extends GutTest
## J15 T24 (`jalon-15.md` §3 T24, Rouge/Bleu) : le joueur dont toute l'équipe est K.O. **perd
## toujours**, même si l'adversaire tombe dans le même coup ([method Battle._check_end]). Lutte
## (contrecoup), Destruction des deux côtés (`test_battle_self_ko`), fin de tour (poison,
## brûlure), dernier Pokémon du joueur qui tombe quand l'adversaire en a encore ; et les
## conséquences d'une telle défaite ([BattleConclusion]) : ni prix, ni pièces du Jackpot, réveil.
##
## IV 0. Vit : Salamèche N5 11 > Carapuce N5 9 = Bulbizarre N5 9. Tirages : IA (roll(1) avec
## une seule capacité), puis précision / critique / aléatoire de chaque action qui en tire ;
## Boul'Armure ne tire rien ; Lutte ne tire pas de précision.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
## Lutte qui touche : critique (2 = non), aléatoire (16 = 100 %).
const STRUGGLE_HIT: Array[int] = [2, 16]

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, moves: Array = [&"defense_curl"], level: int = 5) -> Pokemon:
	return Kit.mon(_data, species, level, moves)


func _battle(mine: Array, foes: Array, draws: Array, trainer: String = "") -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	return Kit.battle(_data, _rng, mine, foes, trainer,
		BattleRules.for_trainer() if not trainer.is_empty() else null)


## Pokémon sans PP (Lutte seule) à [param hp] PV.
func _out_of_pp(species: StringName, hp: int) -> Pokemon:
	var pokemon := _mon(species, [&"scratch"])
	pokemon.moves[0].pp = 0
	pokemon.hp = hp
	return pokemon


func _assert_lost(battle: Battle, events: Array[BattleEvent]) -> void:
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)
	assert_eq(battle.get_state(), Battle.State.OVER)
	var ended := Kit.find(events, K.BATTLE_ENDED)
	assert_not_null(ended)
	if ended != null:
		assert_eq(ended.outcome, Battle.Outcome.LOSS)
	assert_eq(Kit.kinds(events)[-1], ["BATTLE_ENDED", "PLAYER"], "rien après la fin")


# --- Lutte -------------------------------------------------------------------------------

func test_struggle_double_ko_against_a_trainer_is_a_loss() -> void:
	var battle := _battle([_out_of_pp(&"charmander", 1)], [_mon(&"squirtle")],
		[1, STRUGGLE_HIT], "Scout")
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.kinds(events).slice(-3), [["FAINTED", "FOE"], ["FAINTED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]])
	_assert_lost(battle, events)
	assert_null(Kit.find(events, K.EXP_GAINED), "aucune XP : le lanceur est K.O.")


func test_struggle_double_ko_against_a_wild_pokemon_is_a_loss() -> void:
	var battle := _battle([_out_of_pp(&"charmander", 1)], [_mon(&"squirtle")],
		[1, STRUGGLE_HIT])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	_assert_lost(battle, events)


## Le dernier Pokémon du joueur tombe sur le contrecoup en mettant K.O. un adversaire qui a
## encore un Pokémon : défaite tout de suite, l'adversaire n'envoie personne.
func test_last_pokemon_falls_while_the_trainer_still_has_one() -> void:
	var battle := _battle([_out_of_pp(&"charmander", 1)], [_mon(&"squirtle"),
		_mon(&"bulbasaur")], [1, STRUGGLE_HIT], "Scout")
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	_assert_lost(battle, events)
	assert_null(Kit.find(events, K.SENT_OUT, F), "pas de remplaçant adverse")
	assert_false(battle.needs_replacement())


## Le joueur a encore un Pokémon valide : le double K.O. ne termine pas le combat (inchangé).
func test_struggle_double_ko_with_a_second_pokemon_goes_on() -> void:
	var battle := _battle([_out_of_pp(&"charmander", 1), _mon(&"bulbasaur")],
		[_mon(&"squirtle"), _mon(&"bulbasaur")], [1, STRUGGLE_HIT], "Scout")
	battle.get_foe_side().active.pokemon.hp = 1
	battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)
	assert_true(battle.needs_replacement())


## Lutte qui met K.O. le dernier adversaire, contrecoup encaissé : victoire (inchangé).
func test_struggle_win_when_the_user_survives_the_recoil() -> void:
	var battle := _battle([_out_of_pp(&"charmander", 18)], [_mon(&"squirtle")],
		[1, STRUGGLE_HIT])
	battle.get_foe_side().active.pokemon.hp = 1
	battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_false(battle.get_player_side().active.pokemon.is_fainted())


# --- Fin de tour -------------------------------------------------------------------------

## Poison et brûlure à 1 PV des deux côtés : le joueur passe en premier en fin de tour, tombe,
## le combat s'arrête sur une défaite avant les dégâts de l'adversaire.
func test_end_of_turn_status_on_both_last_pokemon_is_a_loss() -> void:
	for statuses: Array in [[StatusRules.POISON, StatusRules.BURN],
			[StatusRules.BURN, StatusRules.POISON]]:
		var battle := _battle([_mon(&"charmander")], [_mon(&"bulbasaur")], [1], "Scout")
		var mine := battle.get_player_side().active.pokemon
		var foe := battle.get_foe_side().active.pokemon
		mine.status = statuses[0]
		mine.hp = 1
		foe.status = statuses[1]
		foe.hp = 1
		var events := battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0)
		_assert_lost(battle, events)
		assert_eq(foe.hp, 1, "l'adversaire ne subit rien : le combat est fini")
		assert_null(Kit.find(events, K.FAINTED, F))


## Seul l'adversaire tombe en fin de tour : victoire (inchangé).
func test_end_of_turn_poison_on_the_foe_alone_is_a_win() -> void:
	var battle := _battle([_mon(&"charmander")], [_mon(&"bulbasaur")], [1], "Scout")
	var foe := battle.get_foe_side().active.pokemon
	foe.status = StatusRules.POISON
	foe.hp = 1
	battle.submit(BattleAction.move(0))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


# --- Conséquences ----------------------------------------------------------------------

## Jackpot lancé plus tôt, puis double K.O. par Lutte : défaite, aucune pièce ramassée, aucun
## prix, réveil au point de repos (Dresseur ordinaire).
func test_a_double_ko_after_pay_day_collects_nothing() -> void:
	var meowth := Kit.mon(_data, &"meowth", 17, [&"pay_day"])
	var onix := Kit.mon(_data, &"onix", 50, [&"defense_curl"])
	var battle := Kit.battle(_data, GameRng.new(3), [meowth], [onix], "Scout",
		BattleRules.for_trainer())
	battle.submit(BattleAction.move(0))
	var coins := battle.get_pay_day_coins()
	assert_gt(coins, 0, "Jackpot réussi au premier tour")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)
	meowth.moves[0].pp = 0
	meowth.hp = 1
	onix.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_not_null(Kit.find(events, K.FAINTED, F))
	assert_not_null(Kit.find(events, K.FAINTED, P))
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)
	var trainer := TrainerData.new()
	trainer.prize_money = 120
	trainer.can_lose = false
	trainer.heal_after = false
	var conclusion := BattleConclusion.resolve(trainer, battle.get_outcome(), 50,
		battle.get_pay_day_coins())
	assert_eq(conclusion.prize_money, 0, "pas de prix sur une défaite")
	assert_eq(conclusion.pay_day_money, 0, "pièces perdues à la défaite")
	assert_true(conclusion.blackout, "réveil au point de repos")
	var wild := BattleConclusion.resolve(null, battle.get_outcome(), 0, coins)
	assert_eq(wild.pay_day_money, 0)
	assert_true(wild.blackout)
