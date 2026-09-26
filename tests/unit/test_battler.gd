extends GutTest
## Battler : niveaux de statistiques −6..+6 et multiplicateurs modernes (jalon 4 §2.2).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData
var _battler: Battler


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	var charmander := PokemonFactory.create(_data, &"charmander", 5, ScriptedRng.new(IV_0))
	_battler = Battler.new(charmander, [&"fire"] as Array[StringName])


func test_stages_start_at_zero() -> void:
	for stat: StringName in MoveEffect.STAGE_STATS:
		assert_eq(_battler.get_stage(stat), 0, String(stat))
	assert_eq(_battler.types, [&"fire"] as Array[StringName])


func test_change_stage_returns_the_applied_variation() -> void:
	assert_eq(_battler.change_stage(&"atk", -1), -1)
	assert_eq(_battler.change_stage(&"atk", -4), -4)
	assert_eq(_battler.change_stage(&"atk", -2), -1, "borné à −6")
	assert_eq(_battler.get_stage(&"atk"), -6)
	assert_eq(_battler.change_stage(&"atk", -1), 0, "déjà au bout")
	assert_eq(_battler.change_stage(&"spe", 8), 6)
	assert_eq(_battler.change_stage(&"spe", 1), 0)
	_battler.reset_stages()
	assert_eq(_battler.get_stage(&"atk"), 0)


func test_change_stage_of_hp_is_an_error() -> void:
	assert_eq(_battler.change_stage(&"hp", 1), 0)
	assert_push_error("sans niveau")


func test_stage_multipliers() -> void:
	assert_eq(Battler.stage_multiplier(0), 1.0)
	assert_eq(Battler.stage_multiplier(1), 1.5)
	assert_eq(Battler.stage_multiplier(2), 2.0)
	assert_eq(Battler.stage_multiplier(6), 4.0)
	assert_almost_eq(Battler.stage_multiplier(-1), 2.0 / 3.0, 0.0001)
	assert_eq(Battler.stage_multiplier(-2), 0.5)
	assert_eq(Battler.stage_multiplier(-6), 0.25)
	assert_almost_eq(Battler.accuracy_multiplier(-1), 0.75, 0.0001)
	assert_almost_eq(Battler.accuracy_multiplier(1), 4.0 / 3.0, 0.0001)
	assert_eq(Battler.accuracy_multiplier(9), 3.0, "borné à +6")


func test_effective_stat_rounds_down() -> void:
	# Salamèche N5, IV 0 : Atq 10, Déf 9.
	assert_eq(_battler.effective_stat(&"atk"), 10)
	_battler.change_stage(&"atk", -1)
	assert_eq(_battler.effective_stat(&"atk"), 6, "⌊10 × 2/3⌋")
	assert_eq(_battler.effective_stat(&"atk", true), 10, "baisse ignorée (critique)")
	_battler.change_stage(&"def", 1)
	assert_eq(_battler.effective_stat(&"def"), 13, "⌊9 × 1,5⌋")
	assert_eq(_battler.effective_stat(&"def", false, true), 9, "hausse ignorée (critique)")
	assert_eq(_battler.effective_stat(&"def", true), 13, "une hausse n'est pas une baisse")


func test_usable_moves_skip_empty_pp() -> void:
	assert_eq(_battler.usable_moves(), [0, 1] as Array[int])
	_battler.pokemon.moves[0].pp = 0
	assert_eq(_battler.usable_moves(), [1] as Array[int])
	_battler.pokemon.moves[1].pp = 0
	assert_eq(_battler.usable_moves(), [] as Array[int])
