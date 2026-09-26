extends GutTest
## BattleAI « random » : une capacité au hasard parmi celles qui ont des PP, Lutte sinon.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData
var _side: BattleSide


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"charmander", 30, ScriptedRng.new(IV_0)))
	_side = BattleSide.new(party, false, "", BattleAI.new())
	_side.send_out(party.get_lead(), _data)


func test_known_kinds() -> void:
	assert_true(BattleAI.is_known(&"random"))
	assert_false(BattleAI.is_known(&"smart"))
	assert_eq(BattleAI.new().kind, &"random")


func test_picks_among_usable_moves() -> void:
	var ai := BattleAI.new()
	assert_eq(ai.choose(_side, null, ScriptedRng.new([1])).move_index, 0)
	assert_eq(ai.choose(_side, null, ScriptedRng.new([4])).move_index, 3)
	_side.active.pokemon.moves[0].pp = 0
	_side.active.pokemon.moves[2].pp = 0
	assert_eq(ai.choose(_side, null, ScriptedRng.new([1])).move_index, 1)
	assert_eq(ai.choose(_side, null, ScriptedRng.new([2])).move_index, 3)


func test_struggles_without_pp_and_without_drawing() -> void:
	for slot: MoveSlot in _side.active.pokemon.moves:
		slot.pp = 0
	var rng := ScriptedRng.new([])
	var action := BattleAI.new().choose(_side, null, rng)
	assert_eq(action.kind, BattleAction.Kind.MOVE)
	assert_eq(action.move_index, BattleAction.STRUGGLE)
	assert_eq(rng.calls, 0)


func test_every_usable_move_gets_chosen() -> void:
	var rng := GameRng.new(11)
	var seen: Dictionary[int, int] = {}
	for i: int in 400:
		var index := BattleAI.new().choose(_side, null, rng).move_index
		seen[index] = seen.get(index, 0) + 1
	assert_eq(seen.keys().size(), 4)
	for index: int in seen:
		assert_between(seen[index], 60, 140, "à peu près uniforme")
