extends GutTest
## Capacités de la Ligue dont l'effet manquait (jalon 30, Q30-3, décision de Kevin du
## 2026-10-22 : les coder) : Frénésie (RAGE), Mania / Danse Fleur (RAMPAGE), Mimique (MIRROR).
## Riposte, Pied Sauté et Pied Voltige : codés par le J27 (test_battle_crash_counter.gd là-bas).
## Règles [D] : `jalon-30.md` §10.6 et l'en-tête du bloc « Jalon 30 » de `battle.gd`.
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
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_not_null(move.effect_of(expected[id]), String(id))
		assert_eq(move.pending_effects.size(), 0, String(id))
		assert_false(move.description.contains("Sans effet"), String(id))


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
	assert_true(mine.is_rampaging())
	mine.flinched = true  # apeuré : il ne peut pas agir ce tour-ci
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FLINCHED, P))
	assert_false(mine.is_rampaging(), "Mania rompue")
	assert_null(Kit.find(events, K.CONFUSED, P))
	assert_false(mine.is_confused())
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


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
