extends GutTest
## Destruction et Explosion (jalon 12 ; `jalon-12.md` §2.10, dossier 15 C-3, §20 n° 45) : le
## lanceur tombe K.O. après sa capacité, même ratée ; pas s'il n'a pas pu agir ; si les deux
## derniers Pokémon tombent dans le même coup, le camp du lanceur perd ; aucune XP au lanceur K.O.
##
## IV 0. Vit : Racaillou N30 17 > Racaillou N21 13 > Bulbizarre N5 9. Tirages : IA (roll(1)),
## puis Destruction (précision, critique, aléatoire) ; Boul'Armure ne tire rien.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _geodude(level: int = 21, move: StringName = &"self_destruct") -> Pokemon:
	return Kit.mon(_data, &"geodude", level, [move])


func _bulbasaur() -> Pokemon:
	return Kit.mon(_data, &"bulbasaur", 5, [&"defense_curl"])


func _charmander() -> Pokemon:
	return Kit.mon(_data, &"charmander", 10, [&"defense_curl"])


func _battle(mine: Array, foes: Array, draws: Array, trainer: String = "") -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	return Kit.battle(_data, _rng, mine, foes, trainer,
		BattleRules.for_trainer() if not trainer.is_empty() else null)


func test_both_faint_and_the_user_gets_no_exp() -> void:
	var battle := _battle([_geodude(), _charmander()], [_bulbasaur()], [1, Kit.HIT])
	var geodude := battle.get_player_side().active.pokemon
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.kinds(events), [["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"],
		["SELF_KO", "PLAYER"], ["FAINTED", "FOE"], ["FAINTED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]], "aucune XP : le lanceur est K.O.")
	var self_ko := Kit.find(events, K.SELF_KO)
	assert_eq([self_ko.hp, self_ko.amount], [0, geodude.max_hp()])
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN, "le joueur a encore Salamèche")
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(texts.lines(self_ko, _data).size(), 0, "pas de phrase : celle du FAINTED suit")


func test_final_double_ko_is_lost_by_the_user_side() -> void:
	var battle := _battle([_geodude()], [_bulbasaur()], [1, Kit.HIT])
	battle.submit(BattleAction.move(0))
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS, "le joueur a lancé Destruction")
	var foe_battle := _battle([_bulbasaur()], [_geodude()], [1, Kit.HIT])
	var events := foe_battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.kinds(events).slice(0, 5), [["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"],
		["SELF_KO", "FOE"], ["FAINTED", "PLAYER"], ["FAINTED", "FOE"]])
	assert_eq(foe_battle.get_outcome(), Battle.Outcome.WIN, "l'adversaire a lancé Explosion")


func test_explosion_also_knocks_out_its_user() -> void:
	var battle := _battle([_geodude(36, &"explosion")], [_bulbasaur()], [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.SELF_KO, P))
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)


func test_the_user_faints_even_when_it_misses() -> void:
	var battle := _battle([_geodude(), _charmander()], [_bulbasaur()], [1, 50])
	battle.get_foe_side().active.change_stage(&"eva", 6)
	var foe := battle.get_foe_side().active.pokemon
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.kinds(events).slice(0, 4), [["MOVE_USED", "PLAYER"], ["MOVE_MISSED", "PLAYER"],
		["SELF_KO", "PLAYER"], ["FAINTED", "PLAYER"]])
	assert_eq(foe.hp, foe.max_hp())
	assert_true(battle.needs_replacement())


func test_the_user_faints_when_the_target_survives() -> void:
	var battle := _battle([_geodude(), _charmander()], [_geodude(30, &"defense_curl")],
		[1, Kit.HIT])
	var foe := battle.get_foe_side().active.pokemon
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_gt(foe.hp, 0)
	assert_lt(foe.hp, foe.max_hp())
	assert_null(Kit.find(events, K.FAINTED, F))
	assert_not_null(Kit.find(events, K.FAINTED, P))
	assert_true(battle.needs_replacement())


func test_no_self_ko_when_it_cannot_act() -> void:
	var battle := _battle([_geodude(), _charmander()], [_bulbasaur()], [1])
	var geodude := battle.get_player_side().active.pokemon
	geodude.status = StatusRules.SLEEP
	geodude.status_turns = 2
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.STATUS_PREVENTED, P))
	assert_null(Kit.find(events, K.SELF_KO))
	assert_eq(geodude.hp, geodude.max_hp())
	assert_eq(geodude.moves[0].pp, _data.get_move(&"self_destruct").pp, "aucun PP")


func test_a_double_ko_mid_battle_sends_both_next() -> void:
	var battle := _battle([_geodude(), _charmander()], [_bulbasaur(),
		Kit.mon(_data, &"rattata", 5, [&"defense_curl"])], [1, Kit.HIT], "Sbire")
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_null(Kit.find(events, K.EXP_GAINED), "aucun participant debout")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)
	assert_true(battle.needs_replacement())
	assert_eq(battle.get_foe_side().active.pokemon.species_id, &"rattata")
