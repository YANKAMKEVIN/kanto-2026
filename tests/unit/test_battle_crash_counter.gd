extends GutTest
## Jalon 27 : Pied Sauté, Pied Voltige (effet « crash ») et Riposte (effet « counter »), règles de
## Rouge/Bleu (`pret/pokered`, `PrintMoveFailureText`, `HandleCounterMove`).
##
## Tirages (voir `battle_kit_j12.gd`) : IA adverse (roll(n)), puis pour chaque Pokémon qui agit :
## précision, critique (2 = non), aléatoire (16 = 100 %). Le Rattata N30 du joueur agit avant le
## Rattata N10 (ou le Fantominus N10), sauf Riposte (priorité −1).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const MISS: int = 99

var _data: PokemonData
var _texts: BattleText
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _wild(moves: Array, draws: Array, foe_moves: Array = [&"tackle"],
		foe_species: StringName = &"rattata") -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	var mine := Kit.mon(_data, &"rattata", 30, moves)
	var foe := Kit.mon(_data, foe_species, 10, foe_moves)
	return Kit.battle(_data, _rng, [mine], [foe])


func _index(events: Array[BattleEvent], kind: BattleEvent.Kind, side: int) -> int:
	for i: int in events.size():
		if events[i].kind == kind and events[i].side == side:
			return i
	return -1


# --- Données ----------------------------------------------------------------------------------

func test_the_three_moves_carry_their_effects_and_no_pending_one() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in [&"jump_kick", &"hi_jump_kick"]:
		var crash := _data.get_move(id).effect_of(MoveEffect.Kind.CRASH)
		assert_not_null(crash, String(id))
		assert_eq(crash.amount, 1, "%s : 1 PV en Rouge/Bleu" % id)
	var counter := _data.get_move(&"counter")
	assert_not_null(counter.effect_of(MoveEffect.Kind.COUNTER))
	assert_eq(counter.priority, -1)
	for id: StringName in [&"jump_kick", &"hi_jump_kick", &"counter"]:
		var move := _data.get_move(id)
		assert_eq(move.pending_effects.size(), 0, String(id))
		assert_false(move.description.contains("Sans effet"), String(id))


func test_crash_amount_defaults_to_one_and_is_bounded() -> void:
	var data := PokemonData.new()
	assert_true(data.add_moves_from_dict({"x": {"name": "X", "type": "fighting",
		"category": "physical", "power": 50, "accuracy": 90, "pp": 5, "description": "x",
		"effects": [{"kind": "crash"}]}}, "test"))
	assert_eq(data.get_move(&"x").effect_of(MoveEffect.Kind.CRASH).amount, 1)
	assert_false(data.add_moves_from_dict({"y": {"name": "Y", "type": "fighting",
		"category": "physical", "power": 50, "accuracy": 90, "pp": 5, "description": "y",
		"effects": [{"kind": "crash", "amount": 0}]}}, "test"))
	assert_push_error("amount")
	assert_false(data.add_moves_from_dict({"z": {"name": "Z", "type": "fighting",
		"category": "status", "accuracy": 100, "pp": 5, "description": "z",
		"effects": [{"kind": "counter", "amount": 2}]}}, "test"))
	assert_push_error("amount")


# --- Pied Sauté, Pied Voltige -----------------------------------------------------------------

func test_jump_kick_that_hits_does_not_crash() -> void:
	var events := _wild([&"jump_kick"], [1, Kit.HIT]).submit(BattleAction.move(0))
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_not_null(damage)
	assert_eq(damage.move_id, &"jump_kick")
	assert_null(Kit.find(events, K.CRASHED))
	assert_eq(_rng.remaining(), 0)


func test_jump_kick_that_misses_crashes_for_one_hp() -> void:
	var battle := _wild([&"jump_kick"], [1, MISS, Kit.HIT])
	var mine := battle.get_player_side().active.pokemon
	var before := mine.hp
	var events := battle.submit(BattleAction.move(0))
	var missed := _index(events, K.MOVE_MISSED, P)
	var crashed := _index(events, K.CRASHED, P)
	assert_true(missed >= 0 and crashed == missed + 1, "le raté, puis la chute")
	assert_eq(events[crashed].amount, 1)
	assert_eq(events[crashed].hp, before - 1)
	assert_eq(events[crashed].move_id, &"jump_kick")
	assert_eq(_texts.lines(events[crashed], _data), PackedStringArray(["Rattata s'écrase au sol !"]))
	assert_eq(_rng.remaining(), 0)


func test_hi_jump_kick_on_a_ghost_crashes_without_any_draw() -> void:
	var events := _wild([&"hi_jump_kick"], [1, Kit.HIT], [&"tackle"], &"gastly") \
		.submit(BattleAction.move(0))
	var immune := _index(events, K.NO_EFFECT, F)
	var crashed := _index(events, K.CRASHED, P)
	assert_true(immune >= 0 and crashed == immune + 1, "l'immunité, puis la chute")
	assert_eq(events[crashed].amount, 1)
	assert_eq(_rng.remaining(), 0, "aucun tirage pour Pied Voltige (seule l'attaque adverse)")


func test_jump_kick_dodged_by_an_invulnerable_target_crashes() -> void:
	var battle := _wild([&"jump_kick"], [1, Kit.HIT])
	battle.get_foe_side().active.invulnerable = true
	var events := battle.submit(BattleAction.move(0))
	var dodged := _index(events, K.DODGED, F)
	assert_true(dodged >= 0 and _index(events, K.CRASHED, P) == dodged + 1)


func test_the_crash_can_knock_out_the_user() -> void:
	var battle := _wild([&"jump_kick"], [1, MISS])
	battle.get_player_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	var crashed := _index(events, K.CRASHED, P)
	assert_eq(events[crashed].hp, 0)
	assert_eq(_index(events, K.FAINTED, P), crashed + 1)
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)
	assert_null(Kit.find(events, K.DAMAGE, P), "l'adversaire n'agit plus")


# --- Riposte --------------------------------------------------------------------------------------

func test_counter_returns_double_a_normal_physical_hit_and_goes_last() -> void:
	var events := _wild([&"counter"], [1, Kit.HIT, 50]).submit(BattleAction.move(0))
	var taken := Kit.find(events, K.DAMAGE, P)
	var dealt := Kit.find(events, K.DAMAGE, F)
	assert_not_null(taken)
	assert_not_null(dealt)
	assert_true(_index(events, K.DAMAGE, P) < _index(events, K.DAMAGE, F), "priorité −1")
	assert_eq(dealt.move_id, &"counter")
	assert_eq(dealt.amount, mini(2 * taken.amount, dealt.max_hp))
	assert_eq(_rng.remaining(), 0)


func test_counter_hits_a_ghost_like_red_and_blue() -> void:
	var events := _wild([&"counter"], [1, Kit.HIT, 50], [&"tackle"], &"gastly") \
		.submit(BattleAction.move(0))
	var taken := Kit.find(events, K.DAMAGE, P)
	assert_eq(Kit.find(events, K.DAMAGE, F).amount, 2 * taken.amount)


func test_counter_misses_after_a_special_water_hit_without_a_draw() -> void:
	var events := _wild([&"counter"], [1, Kit.HIT], [&"water_gun"]).submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.DAMAGE, P), "Pistolet à O touche")
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.DAMAGE, F))
	assert_eq(_rng.remaining(), 0)


func test_counter_follows_the_type_not_the_category() -> void:
	# Météores : Normal spéciale (ne rate jamais) ; Rouge/Bleu regarde le type.
	var events := _wild([&"counter"], [1, 2, 16, 50], [&"swift"]).submit(BattleAction.move(0))
	var taken := Kit.find(events, K.DAMAGE, P)
	assert_not_null(taken)
	assert_eq(Kit.find(events, K.DAMAGE, F).amount, 2 * taken.amount)


func test_counter_misses_without_damage_received() -> void:
	var events := _wild([&"counter"], [1, 50], [&"growl"]).submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.DAMAGE, F))
	assert_eq(_rng.remaining(), 0)


func test_counter_misses_when_the_foe_attack_missed() -> void:
	var battle := _wild([&"counter"], [1, MISS])
	battle.get_foe_side().active.change_stage(&"acc", -6)
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, F), "Charge rate (précision −6)")
	assert_null(Kit.find(events, K.DAMAGE, P))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.DAMAGE, F))


func test_only_the_latest_foe_move_counts() -> void:
	# Tour 1 : Charge reçue (le joueur lance Rugissement) ; tour 2 : Rugissement adverse, Riposte rate.
	var battle := _wild([&"growl", &"counter"], [1, 50, Kit.HIT])
	battle.submit(BattleAction.move(0))
	assert_gt(battle.get_player_side().active.counter_damage, 0)
	battle.get_foe_side().active.pokemon.moves[0] = MoveSlot.new(&"growl", 40)
	_rng.push(Kit.draws([1, 50]))
	var events := battle.submit(BattleAction.move(1))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.DAMAGE, F))
