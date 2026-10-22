extends GutTest
## Lot d'effets de combat de la passe systèmes 2 (S2G, Q-7 ; règles modernes [D]) : Soin,
## Protection et Mur Lumière, Buée Noire, Lance-Soleil et Coud'Krâne (deux tours), Vague Psy.
##
## Tirages (voir `battle_kit_j12.gd`) : IA adverse (roll(n)), puis pour chaque Pokémon qui agit :
## précision, critique (2 = non), aléatoire (16 = 100 %) ; une capacité qui ne rate jamais
## (précision 0) ne tire rien. Le Rattata N30 du joueur agit toujours avant le Rattata N10.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _texts: BattleText
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _wild(moves: Array, draws: Array, foe_moves: Array = [&"tackle"]) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	var mine := Kit.mon(_data, &"rattata", 30, moves)
	var foe := Kit.mon(_data, &"rattata", 10, foe_moves)
	return Kit.battle(_data, _rng, [mine], [foe])


func _lines(events: Array[BattleEvent]) -> String:
	var lines: PackedStringArray = []
	for event: BattleEvent in events:
		lines.append_array(_texts.lines(event, _data))
	return "\n".join(lines)


# --- Données ----------------------------------------------------------------------------------

func test_the_lot_carries_its_effects_and_no_pending_one() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	assert_eq(_data.get_move(&"recover").effect_of(MoveEffect.Kind.HEAL).fraction, 0.5)
	assert_eq(_data.get_move(&"reflect").effect_of(MoveEffect.Kind.SCREEN).screen, &"reflect")
	assert_eq(_data.get_move(&"light_screen").effect_of(MoveEffect.Kind.SCREEN).screen,
		&"light_screen")
	assert_not_null(_data.get_move(&"haze").effect_of(MoveEffect.Kind.HAZE))
	var solar := _data.get_move(&"solar_beam").charge_effect()
	assert_eq([solar.texts, solar.invulnerable, solar.stat_up], [&"solar_beam", false, &""])
	var skull := _data.get_move(&"skull_bash").charge_effect()
	assert_eq([skull.texts, skull.stat_up], [&"skull_bash", &"def"])
	for id: StringName in [&"recover", &"reflect", &"light_screen", &"haze", &"solar_beam",
			&"skull_bash"]:
		var move := _data.get_move(id)
		assert_eq(move.pending_effects.size(), 0, String(id))
		assert_false(move.description.contains("Sans effet"), String(id))


func test_bad_values_are_refused() -> void:
	var data := PokemonData.new()
	assert_false(data.add_moves_from_dict({"x": {"name": "X", "type": "normal",
		"category": "status", "accuracy": 0, "pp": 5, "description": "x",
		"effects": [{"kind": "screen", "screen": "mist"}]}}, "test"))
	assert_push_error("screen")
	assert_false(data.add_moves_from_dict({"y": {"name": "Y", "type": "normal",
		"category": "physical", "power": 50, "accuracy": 100, "pp": 5, "description": "y",
		"effects": [{"kind": "charge", "texts": "y", "stat_up": "luck"}]}}, "test"))
	assert_push_error("stat_up")


# --- Soin ---------------------------------------------------------------------------------------

func test_recover_heals_half_the_max_hp() -> void:
	var battle := _wild([&"recover"], [1, Kit.HIT])
	var mine := battle.get_player_side().active.pokemon
	mine.hp = 1
	var events := battle.submit(BattleAction.move(0))
	var healed := Kit.find(events, K.HEALED, P)
	assert_not_null(healed)
	assert_eq(healed.amount, floori(mine.max_hp() / 2.0))
	assert_true(_lines(events).contains("récupère des PV !"))
	assert_eq(_rng.remaining(), 0)


func test_recover_fails_at_full_hp() -> void:
	var battle := _wild([&"recover"], [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FAILED, P))
	assert_null(Kit.find(events, K.HEALED))


# --- Protection, Mur Lumière -------------------------------------------------------------------

func test_reflect_halves_physical_damage() -> void:
	var plain := _wild([&"recover"], [1, Kit.HIT]).submit(BattleAction.move(0))
	var screened := _wild([&"reflect"], [1, Kit.HIT]).submit(BattleAction.move(0))
	assert_not_null(Kit.find(screened, K.SCREEN_STARTED, P))
	var before := Kit.find(plain, K.DAMAGE, P).amount
	assert_eq(Kit.find(screened, K.DAMAGE, P).amount, maxi(before / 2, 1))
	assert_true(_lines(screened).contains("Protection protège votre équipe !"))


func test_light_screen_does_not_stop_physical_damage() -> void:
	var plain := _wild([&"recover"], [1, Kit.HIT]).submit(BattleAction.move(0))
	var screened := _wild([&"light_screen"], [1, Kit.HIT]).submit(BattleAction.move(0))
	assert_eq(Kit.find(screened, K.DAMAGE, P).amount, Kit.find(plain, K.DAMAGE, P).amount)


func test_a_critical_hit_ignores_the_screen() -> void:
	var crit: Array[int] = [50, 1, 16]
	var plain := _wild([&"recover"], [1, crit]).submit(BattleAction.move(0))
	var screened := _wild([&"reflect"], [1, crit]).submit(BattleAction.move(0))
	assert_true(Kit.find(screened, K.DAMAGE, P).critical)
	assert_eq(Kit.find(screened, K.DAMAGE, P).amount, Kit.find(plain, K.DAMAGE, P).amount)


func test_screen_lasts_five_turns_and_cannot_stack() -> void:
	var battle := _wild([&"reflect", &"recover"], [1, Kit.HIT, 1, Kit.HIT, 1, Kit.HIT, 1, Kit.HIT,
		1, Kit.HIT, 1, Kit.HIT])
	battle.submit(BattleAction.move(0))
	var again := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(again, K.FAILED, P), "déjà levé")
	for turn: int in range(3, 5):
		assert_null(Kit.find(battle.submit(BattleAction.move(1)), K.SCREEN_ENDED), str(turn))
	var fifth := battle.submit(BattleAction.move(1))
	var ended := Kit.find(fifth, K.SCREEN_ENDED, P)
	assert_not_null(ended, "fin du 5e tour")
	assert_eq(ended.move_id, &"reflect")
	assert_true(_lines(fifth).contains("L'effet de Protection prend fin pour votre équipe."))
	assert_eq(battle.get_player_side().screen_turns(&"reflect"), 0)


# --- Buée Noire ---------------------------------------------------------------------------------

func test_haze_resets_every_stage() -> void:
	var battle := _wild([&"haze"], [1, Kit.HIT])
	battle.get_player_side().active.change_stage(&"atk", -2)
	battle.get_foe_side().active.change_stage(&"def", 3)
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.STATS_RESET, P))
	assert_eq(battle.get_player_side().active.get_stage(&"atk"), 0)
	assert_eq(battle.get_foe_side().active.get_stage(&"def"), 0)
	assert_true(_lines(events).contains("Toutes les statistiques reviennent à la normale !"))


# --- Deux tours ---------------------------------------------------------------------------------

func test_skull_bash_raises_defense_while_charging() -> void:
	var battle := _wild([&"skull_bash"], [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.CHARGE_STARTED, P))
	var raised := Kit.find(events, K.STAT_CHANGED, P)
	assert_not_null(raised)
	assert_eq([raised.stat, raised.stages], [&"def", 1])
	assert_gt(Kit.index_of(events, K.STAT_CHANGED), Kit.index_of(events, K.CHARGE_STARTED))
	assert_null(Kit.find(events, K.DAMAGE, F), "aucun dégât au tour de charge")
	assert_true(_lines(events).contains("baisse la tête !"))


func test_solar_beam_charges_without_dodging() -> void:
	var battle := _wild([&"solar_beam"], [1, Kit.HIT, 1, Kit.HIT, Kit.HIT])
	var first := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(first, K.CHARGE_STARTED, P))
	assert_not_null(Kit.find(first, K.DAMAGE, P), "pas invulnérable : il est touché")
	assert_true(_lines(first).contains("absorbe la lumière !"))
	var second := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(second, K.DAMAGE, F), "frappe au second tour")


# --- Vague Psy ----------------------------------------------------------------------------------

func test_psywave_deals_half_to_one_and_a_half_level() -> void:
	var data := PokemonData.new()
	data.load_dir()
	assert_true(data.add_moves_from_dict({"test_psywave": {"name": "Vague Psy",
		"type": "psychic", "category": "status", "accuracy": 100, "pp": 15,
		"description": "x", "effects": [{"kind": "fixed_damage", "mode": "psywave"}]}}, "test"))
	for case: Array in [[1, 15], [51, 30], [101, 45]]:
		_rng = Kit.ScriptedRng.new(Kit.draws([1, 50, case[0], Kit.HIT]))
		var mine := Kit.mon(data, &"rattata", 30, [&"test_psywave"])
		var foe := Kit.mon(data, &"onix", 25, [&"tackle"])
		var battle := Kit.battle(data, _rng, [mine], [foe])
		var events := battle.submit(BattleAction.move(0))
		assert_eq(Kit.find(events, K.DAMAGE, F).amount, case[1], "tirage %d" % case[0])
