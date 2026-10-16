extends GutTest
## Jackpot dans le moteur (jalon 15 T17, `jalon-15.md` §2.7.3) : effet COINS lu dans les données,
## 2 × niveau du lanceur par utilisation réussie du joueur (cumulé sur le combat), rien pour un
## Jackpot adverse ni pour un Jackpot raté ; pièces ramassées par [BattleConclusion] après une
## victoire ou une capture (sauvage comme Dresseur), jamais à la fuite ni à la défaite. Phrases :
## annexe A.1 (validée par Kevin le 2026-10-14), branchées sur les modèles « coins_scattered » et
## « coins_collected ».

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


# --- Données ------------------------------------------------------------------------------

func test_coins_effect_is_read_from_the_data() -> void:
	assert_eq(MoveEffect.KIND_NAMES["coins"], MoveEffect.Kind.COINS)
	assert_eq(MoveEffect.Kind.COINS, MoveEffect.Kind.size() - 1, "en fin d'enum")
	assert_eq(BattleEvent.Kind.COINS_SCATTERED, BattleEvent.Kind.size() - 1, "en fin d'enum")
	var effect := _data.get_move(&"pay_day").effect_of(MoveEffect.Kind.COINS)
	assert_not_null(effect)
	if effect != null:
		assert_eq(effect.per_level, 2)


func test_invalid_coins_effects_are_rejected() -> void:
	assert_true(PokemonData.new().add_moves_from_dict(
		_move({ "kind": "coins", "per_level": 2 }), "ok"))
	var cases: Dictionary = {
		"a": [{ "kind": "coins" }, "« per_level » est obligatoire"],
		"b": [{ "kind": "coins", "per_level": 0 }, "per_level : entier de 1 à 10"],
		"c": [{ "kind": "coins", "per_level": 11 }, "per_level : entier de 1 à 10"],
		"d": [{ "kind": "coins", "per_level": 2, "chance": 50 }, "clé inconnue « chance »"],
	}
	for source: String in cases:
		var data := PokemonData.new()
		assert_false(data.add_moves_from_dict(_move(cases[source][0]), source), source)
		assert_string_contains("\n".join(data.get_errors()), cases[source][1])
	assert_push_error_count(cases.size())


# --- Moteur -------------------------------------------------------------------------------

func test_each_player_pay_day_scatters_twice_the_level_and_adds_up() -> void:
	var foe := Kit.mon(_data, &"onix", 50, [&"defense_curl"])
	var battle := Kit.battle(_data, GameRng.new(3),
		[Kit.mon(_data, &"meowth", 17, [&"pay_day"])], [foe])
	var first := battle.submit(BattleAction.move(0))
	var scattered := Kit.find(first, K.COINS_SCATTERED)
	assert_not_null(scattered, "Jackpot réussi : des pièces")
	if scattered == null:
		return
	assert_eq(scattered.side, P, "camp du lanceur")
	assert_eq(scattered.amount, 34, "2 × Nv. 17")
	assert_eq(scattered.pokemon_name, "Miaouss")
	assert_lt(Kit.index_of(first, K.DAMAGE, F), Kit.index_of(first, K.COINS_SCATTERED),
		"après les dégâts")
	assert_eq(battle.get_pay_day_coins(), 34)
	var second := battle.submit(BattleAction.move(0))
	assert_eq(Kit.count(second, K.COINS_SCATTERED), 1)
	assert_eq(battle.get_pay_day_coins(), 68, "cumulé sur le combat")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE, "le combat continue")


func test_coins_are_scattered_even_when_the_foe_faints() -> void:
	var battle := Kit.battle(_data, GameRng.new(5),
		[Kit.mon(_data, &"meowth", 40, [&"pay_day"])], [Kit.mon(_data, &"rattata", 2, [&"growl"])])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_lt(Kit.index_of(events, K.COINS_SCATTERED, P), Kit.index_of(events, K.FAINTED, F),
		"les pièces, puis le K.O.")
	assert_eq(battle.get_pay_day_coins(), 80)


func test_foe_pay_day_brings_nothing() -> void:
	var battle := Kit.battle(_data, GameRng.new(8),
		[Kit.mon(_data, &"onix", 50, [&"defense_curl"])],
		[Kit.mon(_data, &"meowth", 17, [&"pay_day"])], "Gamin")
	var used := 0
	for turn: int in 3:
		var events := battle.submit(BattleAction.move(0))
		used += Kit.count(events, K.MOVE_USED) - 1
		assert_eq(Kit.count(events, K.COINS_SCATTERED), 0, "Jackpot adverse : pas de pièces")
	assert_eq(used, 3, "le Miaouss adverse a bien lancé Jackpot")
	assert_eq(battle.get_pay_day_coins(), 0)


func test_a_missed_pay_day_scatters_nothing() -> void:
	var foe := Kit.mon(_data, &"onix", 50, [&"defense_curl"])
	var battle := Kit.battle(_data, GameRng.new(11),
		[Kit.mon(_data, &"meowth", 17, [&"pay_day"])], [foe])
	battle.get_foe_side().active.change_stage(&"eva", 6)
	var hits := 0
	var missed := false
	for turn: int in 15:
		var events := battle.submit(BattleAction.move(0))
		if Kit.find(events, K.MOVE_MISSED, P) != null:
			missed = true
			assert_eq(Kit.count(events, K.COINS_SCATTERED), 0, "raté : pas de pièces")
		else:
			hits += Kit.count(events, K.COINS_SCATTERED)
	assert_true(missed, "au moins un raté (esquive +6)")
	assert_eq(battle.get_pay_day_coins(), 34 * hits, "seuls les coups réussis comptent")


# --- Conclusion ---------------------------------------------------------------------------

func test_coins_are_collected_on_victory_or_capture_only() -> void:
	var trainer := TrainerData.new()
	trainer.prize_per_level = 35
	for case: Array in [
			[null, Battle.Outcome.WIN, 34], [null, Battle.Outcome.CAUGHT, 34],
			[null, Battle.Outcome.FLED, 0], [null, Battle.Outcome.LOSS, 0],
			[trainer, Battle.Outcome.WIN, 34], [trainer, Battle.Outcome.LOSS, 0]]:
		var result := BattleConclusion.resolve(case[0], case[1], 8, 34)
		assert_eq(result.pay_day_money, case[2],
			"%s, %s" % ["Dresseur" if case[0] != null else "sauvage",
				Battle.Outcome.find_key(case[1])])
	var win := BattleConclusion.resolve(trainer, Battle.Outcome.WIN, 8, 34)
	assert_eq(win.prize_money, 280, "l'argent du Dresseur ne change pas")
	assert_eq(BattleConclusion.resolve(null, Battle.Outcome.WIN).pay_day_money, 0,
		"sans Jackpot : rien")
	assert_eq(BattleConclusion.resolve(null, Battle.Outcome.WIN, 0, -5).pay_day_money, 0,
		"jamais négatif")


func test_money_cap_is_the_game_state_one() -> void:
	var state: Node = load("res://game/autoload/game_state.gd").new()
	state.money = GameState.MONEY_MAX - 10
	assert_eq(state.add_money(BattleConclusion.resolve(null, Battle.Outcome.WIN, 0, 80)
		.pay_day_money), 10, "plafonné")
	assert_eq(state.money, GameState.MONEY_MAX)
	state.free()


# --- Textes (annexe A.1, validés) ---------------------------------------------------------

func test_texts_are_the_annex_a_texts() -> void:
	var event := BattleEvent.new(K.COINS_SCATTERED, P)
	event.pokemon_name = "Miaouss"
	event.amount = 34
	assert_eq(_texts.lines(event, _data), PackedStringArray(["Des pièces s'éparpillent partout !"]))
	assert_eq(_texts.coins_line(34), "Tu ramasses %s." % MenuFormat.money(34))
	for id: StringName in [&"coins_scattered", &"coins_collected"]:
		assert_false(_texts.is_draft(id), "%s : validé le 2026-10-14" % id)
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(beats.size(), 1, "le message seulement")
	assert_eq(beats[0].kind, BattleBeat.Kind.MESSAGE)


func _move(effect: Dictionary) -> Dictionary:
	return { "testy": { "name": "Essai", "type": "normal", "category": "physical",
		"power": 20, "accuracy": 100, "pp": 10, "description": "…", "effects": [effect] } }
