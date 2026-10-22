extends GutTest
## Capacités de la Ligue dont l'effet manquait (jalon 30, Q30-3, décision de Kevin du
## 2026-10-22 : les coder) : Frénésie (RAGE), Mania / Danse Fleur (RAMPAGE), Mimique (MIRROR),
## Riposte (COUNTER), Pied Sauté / Pied Voltige (CRASH). Règles [D] : `jalon-30.md` §10.6 et
## l'en-tête du bloc « Jalon 30 » de `battle.gd`.
##
## Combats sauvages ([code]battle_kit_j12.gd[/code]) avec un vrai [GameRng] à graine fixe : les
## assertions ne dépendent pas des tirages (précision 100, cibles solides).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battle(mine: Pokemon, foe: Pokemon, rng_seed: int = 30) -> Battle:
	return Kit.battle(_data, GameRng.new(rng_seed), [mine], [foe])


func _after(events: Array[BattleEvent], kind: BattleEvent.Kind, side: int,
		from: int) -> BattleEvent:
	for i: int in range(from + 1, events.size()):
		if events[i].kind == kind and events[i].side == side:
			return events[i]
	return null


# --- Données ----------------------------------------------------------------------------------

func test_the_league_moves_carry_their_effects() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	var expected := {
		&"rage": MoveEffect.Kind.RAGE, &"thrash": MoveEffect.Kind.RAMPAGE,
		&"petal_dance": MoveEffect.Kind.RAMPAGE, &"mirror_move": MoveEffect.Kind.MIRROR,
		&"counter": MoveEffect.Kind.COUNTER, &"jump_kick": MoveEffect.Kind.CRASH,
		&"hi_jump_kick": MoveEffect.Kind.CRASH,
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_not_null(move.effect_of(expected[id]), String(id))
		assert_eq(move.pending_effects.size(), 0, String(id))
		assert_false(move.description.contains("Sans effet"), String(id))
	assert_eq(_data.get_move(&"jump_kick").effect_of(MoveEffect.Kind.CRASH).fraction, 0.5)


func test_crash_needs_a_fraction() -> void:
	var data := PokemonData.new()
	assert_false(data.add_moves_from_dict({"x": {"name": "X", "type": "fighting",
		"category": "physical", "power": 50, "accuracy": 100, "pp": 5, "description": "x",
		"effects": [{"kind": "crash"}]}}, "test"))
	assert_push_error("fraction")


# --- Frénésie ---------------------------------------------------------------------------------

func test_rage_raises_attack_when_hit_while_raging() -> void:
	var battle := _battle(Kit.mon(_data, &"rattata", 40, [&"rage", &"tail_whip"]),
		Kit.mon(_data, &"onix", 30, [&"tackle"]))
	var events := battle.submit(BattleAction.move(0))
	var hit := Kit.index_of(events, K.DAMAGE, P)
	assert_gt(hit, -1, "Onix frappe le Rattata en Frénésie")
	var rose := _after(events, K.STAT_CHANGED, P, hit)
	assert_not_null(rose, "la Frénésie monte")
	if rose != null:
		assert_eq([rose.stat, rose.stages, rose.stage], [&"atk", 1, 1])
	# Une autre capacité met fin à la Frénésie : le coup suivant ne monte plus rien.
	events = battle.submit(BattleAction.move(1))
	hit = Kit.index_of(events, K.DAMAGE, P)
	assert_gt(hit, -1)
	for i: int in range(hit, events.size()):
		assert_false(events[i].kind == K.STAT_CHANGED and events[i].stat == &"atk"
			and events[i].side == P, "plus de Frénésie")


# --- Mania ------------------------------------------------------------------------------------

func test_thrash_locks_two_or_three_turns_then_confuses() -> void:
	var battle := _battle(Kit.mon(_data, &"rattata", 40, [&"thrash", &"tackle"]),
		Kit.mon(_data, &"onix", 60, [&"harden"]))
	var mine := battle.get_player_side().active
	var events := battle.submit(BattleAction.move(0))
	assert_eq(battle.get_locked_move(), 0, "Mania imposée")
	var pp := mine.pokemon.moves[0].pp
	assert_eq(pp, mine.pokemon.moves[0].max_pp - 1, "un seul PP")
	assert_false(battle.is_legal(BattleAction.move(1)), "pas d'autre capacité")
	var turns := 1
	var confused: BattleEvent = null
	while battle.get_locked_move() != Battle.NO_LOCK and turns < 5:
		events = battle.submit(BattleAction.move(0))
		turns += 1
		assert_eq(Kit.count(events, K.MOVE_USED), 2, "Mania relancée, Onix aussi")
		confused = Kit.find(events, K.CONFUSED, P)
	assert_between(turns, 2, 3, "2 ou 3 tours")
	assert_eq(mine.pokemon.moves[0].pp, pp, "les tours imposés ne coûtent pas de PP")
	assert_not_null(confused, "fatigue : confus au dernier tour")
	assert_true(mine.is_confused())
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_an_interrupted_thrash_stops_without_confusion() -> void:
	var battle := _battle(Kit.mon(_data, &"rattata", 40, [&"thrash"]),
		Kit.mon(_data, &"onix", 60, [&"harden"]))
	var mine := battle.get_player_side().active
	battle.submit(BattleAction.move(0))
	mine.pokemon.status = StatusRules.FREEZE  # gelé : il ne peut plus agir
	var events := battle.submit(BattleAction.move(0))
	if Kit.find(events, K.STATUS_PREVENTED, P) != null:
		assert_false(mine.is_rampaging(), "Mania rompue")
		assert_null(Kit.find(events, K.CONFUSED, P))
		assert_false(mine.is_confused())


# --- Mimique ----------------------------------------------------------------------------------

func test_mirror_move_copies_the_last_move_of_the_target() -> void:
	var battle := _battle(Kit.mon(_data, &"pidgeot", 40, [&"mirror_move"]),
		Kit.mon(_data, &"onix", 40, [&"tackle"]))
	var events := battle.submit(BattleAction.move(0))
	var failed := Kit.find(events, K.FAILED, P)
	assert_not_null(failed, "rien à copier au premier tour")
	events = battle.submit(BattleAction.move(0))
	var first := Kit.index_of(events, K.MOVE_USED, P)
	assert_eq(events[first].move_id, &"mirror_move")
	var echo := _after(events, K.MOVE_USED, P, first)
	assert_not_null(echo)
	if echo != null:
		assert_eq(echo.move_id, &"tackle", "Charge copiée")
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_not_null(damage)
	if damage != null:
		assert_eq(damage.move_id, &"tackle")
	assert_eq(battle.get_player_side().active.pokemon.moves[0].pp,
		battle.get_player_side().active.pokemon.moves[0].max_pp - 2, "un PP par Mimique")


func test_mirror_move_refuses_a_charging_move() -> void:
	var battle := _battle(Kit.mon(_data, &"pidgeot", 40, [&"mirror_move"]),
		Kit.mon(_data, &"diglett", 40, [&"dig"]))
	battle.get_foe_side().active.last_move_id = &"dig"
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FAILED, P), "Tunnel ne se copie pas")


# --- Riposte ----------------------------------------------------------------------------------

func test_counter_returns_twice_the_physical_damage() -> void:
	var battle := _battle(Kit.mon(_data, &"hitmonchan", 40, [&"counter"]),
		Kit.mon(_data, &"onix", 40, [&"tackle"]))
	var foe := battle.get_foe_side().active.pokemon
	var hp_before := foe.hp
	var events := battle.submit(BattleAction.move(0))
	var taken := Kit.find(events, K.DAMAGE, P)
	assert_not_null(taken, "Onix frappe d'abord (priorité de Riposte)")
	var back := Kit.find(events, K.DAMAGE, F)
	assert_not_null(back)
	if taken != null and back != null:
		assert_eq(back.move_id, &"counter")
		assert_eq(back.amount, mini(2 * taken.amount, hp_before))


func test_counter_fails_against_a_special_move() -> void:
	var battle := _battle(Kit.mon(_data, &"hitmonchan", 40, [&"counter"]),
		Kit.mon(_data, &"charmander", 40, [&"ember"]))
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.DAMAGE, P), "Flammèche touche")
	assert_not_null(Kit.find(events, K.FAILED, P), "Riposte échoue sur un coup spécial")
	assert_null(Kit.find(events, K.DAMAGE, F))


func test_counter_fails_when_not_hit() -> void:
	var battle := _battle(Kit.mon(_data, &"hitmonchan", 40, [&"counter"]),
		Kit.mon(_data, &"onix", 40, [&"harden"]))
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FAILED, P))


# --- Pied Sauté, Pied Voltige -----------------------------------------------------------------

func test_jump_kick_crashes_on_a_ghost() -> void:
	for id: StringName in [&"jump_kick", &"hi_jump_kick"]:
		var battle := _battle(Kit.mon(_data, &"hitmonlee", 40, [id]),
			Kit.mon(_data, &"gastly", 40, [&"lick"]))
		var mine := battle.get_player_side().active.pokemon
		var events := battle.submit(BattleAction.move(0))
		var immune := Kit.index_of(events, K.NO_EFFECT, F)
		assert_gt(immune, -1, "%s : sans effet sur Fantominus" % id)
		var crash := _after(events, K.RECOIL, P, immune)
		assert_not_null(crash, "%s : le lanceur se blesse" % id)
		if crash != null:
			assert_eq(crash.amount, floori(mine.max_hp() * 0.5))


func test_a_landed_jump_kick_does_not_crash() -> void:
	var battle := _battle(Kit.mon(_data, &"hitmonlee", 40, [&"jump_kick"]),
		Kit.mon(_data, &"onix", 60, [&"harden"]), 7)
	var events := battle.submit(BattleAction.move(0))
	if Kit.find(events, K.DAMAGE, F) != null:
		assert_null(Kit.find(events, K.RECOIL, P))
