extends GutTest
## Métronome (jalon 24, T13 ; dossier 27 §10.6) : [MetronomeRules] (candidates, tirage) et le
## combat (PP de Métronome dépensés, capacité tirée annoncée puis jouée).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func test_candidates_exclude_metronome_struggle_pending_and_multi_turn_moves() -> void:
	var pool := MetronomeRules.candidates(_data)
	assert_gt(pool.size(), 50)
	var ids: Array[StringName] = []
	for move: MoveData in pool:
		ids.append(move.id)
		assert_true(move.pending_effects.is_empty(), String(move.id))
		for kind: MoveEffect.Kind in MetronomeRules.EXCLUDED_KINDS:
			assert_null(move.effect_of(kind), "%s : %s" % [move.id, kind])
	for id: StringName in [&"metronome", &"struggle", &"dig", &"bide", &"hyper_beam", &"wrap"]:
		assert_false(ids.has(id), String(id))
	assert_true(ids.has(&"tackle"))


func test_pick_is_deterministic_with_the_injected_rng() -> void:
	var a := MetronomeRules.pick(_data, GameRng.new(42))
	var b := MetronomeRules.pick(_data, GameRng.new(42))
	assert_not_null(a)
	assert_eq(a.id, b.id)


func test_battle_plays_the_called_move_and_spends_metronome_pp() -> void:
	var party := Party.new()
	var mine := PokemonFactory.create(_data, &"clefairy", 30, ScriptedRng.new(IV_0))
	mine.moves.clear()
	mine.moves.append(MoveSlot.new(&"metronome", 10))
	party.add(mine)
	var player := BattleSide.new(party, true)
	var foe_party := Party.new()
	foe_party.add(PokemonFactory.create(_data, &"rattata", 5, ScriptedRng.new(IV_0)))
	var foe := BattleSide.new(foe_party, false, "", BattleAI.new())
	var battle := Battle.new(player, foe, _data, GameRng.new(9), BattleRules.for_wild())
	battle.start()
	var used: Array[StringName] = []
	for event: BattleEvent in battle.submit(BattleAction.move(0)):
		if event.kind == BattleEvent.Kind.MOVE_USED and event.side == BattleEvent.SideId.PLAYER:
			used.append(event.move_id)
	assert_eq(used.size(), 2, "Métronome, puis la capacité tirée")
	assert_eq(used[0], &"metronome")
	assert_ne(used[1], &"metronome")
	assert_eq(mine.moves[0].pp, 9, "PP de Métronome dépensés")
