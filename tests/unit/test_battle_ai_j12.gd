extends GutTest
## IA « smart » et capacités du jalon 12 (`jalon-12.md` §2.10) : Repos jamais à PV pleins,
## Entrave jamais si elle échouerait, Ligotage jamais sur une cible déjà piégée, Destruction et
## Explosion seulement à ¼ de ses PV ou moins ; l'IA « random » ne choisit pas une capacité bloquée.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battler(species: StringName, level: int, moves: Array) -> Battler:
	var pokemon := Kit.mon(_data, species, level, moves)
	return Battler.new(pokemon, _data.get_species(species).types)


func _score(move_id: StringName, own: Battler, foe: Battler) -> float:
	return BattleAI.score_move(_data.get_move(move_id), own, foe, _data.get_type_chart(), 0)


func test_rest_only_when_hurt_and_awake() -> void:
	var own := _battler(&"jigglypuff", 30, [&"rest"])
	var foe := _battler(&"rattata", 10, [&"tackle"])
	assert_eq(_score(&"rest", own, foe), 0.0, "PV pleins")
	own.pokemon.hp = own.pokemon.max_hp() - 1
	assert_gt(_score(&"rest", own, foe), 0.0)
	own.pokemon.status = StatusRules.SLEEP
	assert_eq(_score(&"rest", own, foe), 0.0, "déjà endormi")


func test_disable_only_when_it_would_work() -> void:
	var own := _battler(&"jigglypuff", 30, [&"disable"])
	var foe := _battler(&"rattata", 10, [&"tackle", &"tail_whip"])
	assert_eq(_score(&"disable", own, foe), 0.0, "la cible n'a encore rien lancé")
	foe.last_move_slot = 0
	assert_gt(_score(&"disable", own, foe), 0.0)
	foe.disabled_slot = 1
	assert_eq(_score(&"disable", own, foe), 0.0, "déjà une capacité bloquée")
	foe.clear_disable()
	foe.bide_stage = 1
	assert_eq(_score(&"disable", own, foe), 0.0, "en pleine Patience")


func test_wrap_never_on_a_trapped_target() -> void:
	var own := _battler(&"ekans", 10, [&"wrap"])
	var foe := _battler(&"rattata", 10, [&"tackle"])
	assert_gt(_score(&"wrap", own, foe), 0.0)
	foe.trap_turns = 3
	assert_eq(_score(&"wrap", own, foe), 0.0, "déjà piégée")


func test_self_destruct_only_at_a_quarter_hp_or_less() -> void:
	var own := _battler(&"geodude", 21, [&"self_destruct", &"tackle"])
	var foe := _battler(&"rattata", 10, [&"tackle"])
	assert_eq(_score(&"self_destruct", own, foe), 0.0, "PV pleins")
	assert_eq(_score(&"explosion", own, foe), 0.0)
	var max_hp := own.pokemon.max_hp()
	own.pokemon.hp = floori(max_hp * 0.25) + 1
	assert_eq(_score(&"self_destruct", own, foe), 0.0, "juste au-dessus d'¼")
	own.pokemon.hp = floori(max_hp * 0.25)
	assert_gt(_score(&"self_destruct", own, foe), 0.0)
	assert_gt(_score(&"self_destruct", own, foe), _score(&"tackle", own, foe),
		"à ¼, elle l'emporte sur Charge")


func test_smart_picks_tackle_over_self_destruct_at_full_hp() -> void:
	var ai := BattleAI.new(BattleAI.SMART)
	var own := BattleSide.new(Party.new(), false, "Sbire", ai)
	own.party.add(Kit.mon(_data, &"geodude", 21, [&"self_destruct", &"tackle"]))
	own.send_out(own.party.get_at(0), _data)
	var foe := BattleSide.new(Party.new(), true)
	foe.party.add(Kit.mon(_data, &"rattata", 10, [&"tackle"]))
	foe.send_out(foe.party.get_at(0), _data)
	var rng := Kit.ScriptedRng.new([])
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, "Charge, sans tirage")
	assert_eq(rng.calls, 0)
	own.active.pokemon.hp = 1
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 0, "Destruction à 1 PV")


func test_ais_never_choose_a_disabled_move() -> void:
	for kind: StringName in BattleAI.KINDS:
		var ai := BattleAI.new(kind)
		var own := BattleSide.new(Party.new(), false, "", ai)
		own.party.add(Kit.mon(_data, &"rattata", 10, [&"tackle", &"quick_attack"]))
		own.send_out(own.party.get_at(0), _data)
		var foe := BattleSide.new(Party.new(), true)
		foe.party.add(Kit.mon(_data, &"pidgey", 5, [&"tackle"]))
		foe.send_out(foe.party.get_at(0), _data)
		own.active.disabled_slot = 0
		var rng := Kit.ScriptedRng.new([1])
		assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, String(kind))
		own.active.disabled_slot = 1
		own.active.pokemon.moves[0].pp = 0
		assert_eq(ai.choose(own, foe, rng, _data).move_index, BattleAction.STRUGGLE,
			"%s : plus rien → Lutte" % kind)
