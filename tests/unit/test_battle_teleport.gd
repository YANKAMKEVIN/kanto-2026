extends GutTest
## Téléport et fuite adverse (jalon 14 T8, `jalon-14.md` §2.5, dossier 17 §8.1) : le sauvage
## qui se téléporte met fin au combat (FOE_FLED, ni XP ni capture), le joueur qui se téléporte
## fuit (FLED), « Mais rien ne se passe ! » contre un Dresseur ; une Ball, le sommeil ou la
## paralysie passent avant.
##
## IV 0 : Salamèche N5 Vit 11 ; Roucool N3 Vit 8 (plus lent) ; Rattata N5 Vit 12 (plus
## rapide) ; Racaillou N10 Vit 9. Le « sauvage qui se téléporte » est l'un d'eux réduit à
## Téléport (Abra arrive avec T5). Tirages comme `test_battle_charge.gd` ; Téléport ne tire rien
## (précision 0) ; capture : roll(65536) par secousse (1 = réussie, 65536 = ratée).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const J14Moves := preload("res://tests/helpers/j14_moves.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const HIT: Array[int] = [50, 2, 16]

var _data: PokemonData
var _items: ItemLibrary
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	J14Moves.ensure(_data)
	_items = ItemLibrary.new()
	_items.load_dir()


func _with_moves(species: StringName, level: int, move_ids: Array[StringName]) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	for move_id: StringName in move_ids:
		pokemon.moves.append(MoveSlot.new(move_id, _data.get_move(move_id).pp))
	return pokemon


func _battle(mine: Pokemon, foe: Pokemon, draws: Array[int], rules: BattleRules = null) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	party.add(mine)
	var foes := Party.new()
	foes.add(foe)
	var wild := rules == null or rules.wild
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foes, false, "" if wild else "Gamin Jules"), _data, _rng,
		rules if rules != null else BattleRules.for_wild(_items))
	battle.start()
	return battle


func _draws(parts: Array) -> Array[int]:
	var result: Array[int] = []
	for part: Variant in parts:
		if part is Array:
			for value: int in part:
				result.append(value)
		else:
			result.append(int(part))
	return result


func _find(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: BattleEvent.SideId = P) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind and event.side == side:
			return event
	return null


func _has_kind(events: Array[BattleEvent], kind: BattleEvent.Kind) -> bool:
	for event: BattleEvent in events:
		if event.kind == kind:
			return true
	return false


func _line(event: BattleEvent) -> Array:
	var texts := BattleText.new()
	texts.load_file()
	return Array(texts.lines(event, _data))


func test_teleport_reads_its_effect() -> void:
	var teleport := _data.get_move(&"teleport")
	assert_not_null(teleport)
	assert_eq(teleport.effects.size(), 1, "teleport sans effet : remplacer pending_effects (T5)")
	assert_eq(teleport.effects[0].kind, MoveEffect.Kind.TELEPORT)
	assert_true(teleport.never_misses())


func test_slower_wild_foe_flees_after_the_player_acts() -> void:
	var charmander := _with_moves(&"charmander", 5, [&"scratch"])
	var pidgey := _with_moves(&"pidgey", 3, [&"teleport"])
	var battle := _battle(charmander, pidgey, _draws([1, HIT]))
	var exp_before := charmander.experience
	var turn := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(turn, K.DAMAGE, F), "le joueur agit d'abord")
	var teleported := _find(turn, K.TELEPORTED, F)
	assert_not_null(teleported)
	var ended := turn[turn.size() - 1]
	assert_eq(ended.kind, K.BATTLE_ENDED)
	assert_eq(ended.outcome, Battle.Outcome.FOE_FLED)
	assert_eq(battle.get_outcome(), Battle.Outcome.FOE_FLED)
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_false(_has_kind(turn, K.EXP_GAINED), "ni XP")
	assert_false(_has_kind(turn, K.CAUGHT), "ni capture")
	assert_eq(charmander.experience, exp_before)
	assert_eq(_line(ended), [], "pas de « Tu as battu… »")
	teleported.gender = Pokemon.Gender.MALE
	assert_eq(_line(teleported), ["Roucool s'est téléporté !"], "n° 56")
	teleported.gender = Pokemon.Gender.FEMALE
	assert_eq(_line(teleported), ["Roucool s'est téléportée !"], "n° 56 au féminin")


func test_faster_wild_foe_flees_before_the_player_acts() -> void:
	var battle := _battle(_with_moves(&"charmander", 5, [&"scratch"]),
		_with_moves(&"rattata", 5, [&"teleport"]), _draws([1]))
	var turn := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "Griffe n'est jamais lancée")
	assert_null(_find(turn, K.MOVE_USED, P))
	assert_not_null(_find(turn, K.MOVE_USED, F))
	assert_not_null(_find(turn, K.TELEPORTED, F))
	assert_eq(battle.get_outcome(), Battle.Outcome.FOE_FLED)


func test_a_ball_goes_before_teleport() -> void:
	var caught := _battle(_with_moves(&"charmander", 5, [&"scratch"]),
		_with_moves(&"rattata", 5, [&"teleport"]), _draws([1, 1, 1, 1]))
	var turn := caught.submit(BattleAction.ball(&"poke_ball"))
	assert_true(_has_kind(turn, K.CAUGHT), "capturé d'entrée")
	assert_false(_has_kind(turn, K.TELEPORTED))
	assert_eq(caught.get_outcome(), Battle.Outcome.CAUGHT)
	var free := _battle(_with_moves(&"charmander", 5, [&"scratch"]),
		_with_moves(&"rattata", 5, [&"teleport"]), _draws([65536, 1]))
	var missed := free.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(_rng.remaining(), 0)
	assert_true(_has_kind(missed, K.BROKE_FREE))
	assert_not_null(_find(missed, K.TELEPORTED, F), "libéré, il se téléporte")
	assert_eq(free.get_outcome(), Battle.Outcome.FOE_FLED)


func test_asleep_or_paralysed_foe_cannot_teleport() -> void:
	var cases := {
		"endormi": [func(p: Pokemon) -> void:
			p.status = StatusRules.SLEEP
			p.status_turns = 3, _draws([1, HIT])],
		# Paralysé : Vitesse ÷ 2, Salamèche d'abord ; paralysie totale (10 ≤ 25).
		"paralysé": [func(p: Pokemon) -> void: p.status = StatusRules.PARALYSIS,
			_draws([1, HIT, 10])],
	}
	for name: String in cases:
		var rattata := _with_moves(&"rattata", 5, [&"teleport"])
		(cases[name][0] as Callable).call(rattata)
		var battle := _battle(_with_moves(&"charmander", 5, [&"scratch"]), rattata,
			cases[name][1])
		var turn := battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0, name)
		assert_not_null(_find(turn, K.STATUS_PREVENTED, F), name)
		assert_false(_has_kind(turn, K.TELEPORTED), name)
		assert_eq(battle.get_state(), Battle.State.CHOOSING, "%s : il reste" % name)
	# Endormi, il se capture : la Ball passe, il ne fuit pas.
	var sleeper := _with_moves(&"rattata", 5, [&"teleport"])
	sleeper.status = StatusRules.SLEEP
	sleeper.status_turns = 3
	var battle := _battle(_with_moves(&"charmander", 5, [&"scratch"]), sleeper,
		_draws([65536, 1]))
	var turn := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_true(_has_kind(turn, K.BROKE_FREE))
	assert_false(_has_kind(turn, K.TELEPORTED), "libéré mais endormi : il reste")


func test_player_teleport_flees_a_wild_battle() -> void:
	var battle := _battle(_with_moves(&"charmander", 5, [&"teleport"]),
		_with_moves(&"geodude", 10, [&"tackle"]), _draws([1]))
	var turn := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn, K.TELEPORTED, P))
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED, "comme FUITE")
	assert_null(_find(turn, K.MOVE_USED, F), "l'adversaire ne joue plus")


func test_nothing_happens_in_a_trainer_battle() -> void:
	var rules := BattleRules.for_trainer(null, _items)
	var battle := _battle(_with_moves(&"charmander", 5, [&"teleport"]),
		_with_moves(&"pidgey", 3, [&"teleport"]), _draws([1]), rules)
	var turn := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var mine := _find(turn, K.NOTHING_HAPPENED, P)
	assert_not_null(mine, "Téléport du joueur")
	assert_not_null(_find(turn, K.NOTHING_HAPPENED, F), "Téléport du Dresseur")
	assert_eq(_line(mine), ["Mais rien ne se passe !"], "n° 57")
	assert_false(_has_kind(turn, K.TELEPORTED))
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_wild_foe_flees_while_the_player_is_underground() -> void:
	var charmander := _with_moves(&"charmander", 5, [&"dig"])
	var battle := _battle(charmander, _with_moves(&"pidgey", 3, [&"teleport"]), _draws([1]))
	var turn := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn, K.CHARGE_STARTED))
	assert_not_null(_find(turn, K.TELEPORTED, F), "Téléport ne vise pas : pas esquivé")
	assert_eq(battle.get_outcome(), Battle.Outcome.FOE_FLED, "rien n'est gardé")
	assert_eq(charmander.moves[0].pp, 9)


func test_smart_ai_never_picks_teleport_over_an_attack() -> void:
	var own := Battler.new(_with_moves(&"rattata", 5, [&"teleport", &"tackle"]),
		_data.get_species(&"rattata").types)
	var foe := Battler.new(_with_moves(&"charmander", 5, [&"scratch"]),
		_data.get_species(&"charmander").types)
	assert_eq(BattleAI.score_move(_data.get_move(&"teleport"), own, foe,
		_data.get_type_chart(), 0), 0.0)
	var own_side := BattleSide.new(Party.new(), false, "Gamin Jules")
	own_side.active = own
	var foe_side := BattleSide.new(Party.new(), true)
	foe_side.active = foe
	var ai := BattleAI.new(BattleAI.SMART)
	assert_eq(ai.choose(own_side, foe_side, ScriptedRng.new([]), _data).move_index, 1)
