extends GutTest
## DamageCalc : précision et dégâts modernes, valeurs calculées à la main avec des tirages
## imposés (jalon 4 §2.2).
##
## Bulbizarre N5 IV 0 : Atq ⌊98·0,05⌋ + 5 = 9. Salamèche N5 IV 0 : Déf 9.
## Carapuce N5 IV 0 : Déf ⌊130·0,05⌋ + 5 = 11. Niveau 5 : ⌊2·5/5⌋ + 2 = 4.
## Charge (40) : ⌊⌊4·40·9/9⌋/50⌋ + 2 = ⌊160/50⌋ + 2 = 5.
## Tirages : précision roll(100), critique roll(24) (1 = critique), aléatoire roll(16)
## (16 → 100 %, 1 → 85 %).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const NO_CRIT := 2
const CRIT := 1
const MAX_ROLL := 16
const MIN_ROLL := 1

var _data: PokemonData
var _chart: TypeChart


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_chart = _data.get_type_chart()


func _battler(species: StringName, level: int = 5) -> Battler:
	var pokemon := PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))
	return Battler.new(pokemon, _data.get_species(species).types)


func _compute(attacker: Battler, defender: Battler, move: StringName,
		draws: Array[int]) -> DamageResult:
	var rng := ScriptedRng.new(draws)
	var result := DamageCalc.compute(attacker, defender, _data.get_move(move), _chart, rng)
	assert_eq(rng.remaining(), 0, "tous les tirages prévus sont consommés")
	return result


func test_tackle_bulbasaur_on_charmander() -> void:
	var result := _compute(_battler(&"bulbasaur"), _battler(&"charmander"), &"tackle",
		[50, NO_CRIT, MAX_ROLL])
	assert_true(result.hit)
	assert_false(result.critical)
	assert_eq(result.effectiveness, 1.0)
	assert_eq(result.amount, 5)


func test_lowest_random_roll() -> void:
	var result := _compute(_battler(&"bulbasaur"), _battler(&"charmander"), &"tackle",
		[50, NO_CRIT, MIN_ROLL])
	assert_eq(result.amount, 4, "⌊5 × 85/100⌋")


func test_critical_hit() -> void:
	var result := _compute(_battler(&"bulbasaur"), _battler(&"charmander"), &"tackle",
		[50, CRIT, MAX_ROLL])
	assert_true(result.critical)
	assert_eq(result.amount, 7, "⌊5 × 1,5⌋")


func test_after_growl_and_critical_ignoring_the_drop() -> void:
	var bulbasaur := _battler(&"bulbasaur")
	bulbasaur.change_stage(&"atk", -1)
	# Atq ⌊9 × 2/3⌋ = 6 : ⌊⌊4·40·6/9⌋/50⌋ + 2 = ⌊106/50⌋ + 2 = 4.
	var charmander := _battler(&"charmander")
	assert_eq(_compute(bulbasaur, charmander, &"tackle", [50, NO_CRIT, MAX_ROLL]).amount, 4)
	assert_eq(_compute(bulbasaur, charmander, &"tackle", [50, CRIT, MAX_ROLL]).amount, 7,
		"le critique ignore la baisse d'attaque")


func test_critical_ignores_the_defense_boost() -> void:
	var charmander := _battler(&"charmander")
	charmander.change_stage(&"def", 1)
	# Déf ⌊9 × 1,5⌋ = 13 : ⌊⌊4·40·9/13⌋/50⌋ + 2 = ⌊110/50⌋ + 2 = 4.
	var bulbasaur := _battler(&"bulbasaur")
	assert_eq(_compute(bulbasaur, charmander, &"tackle", [50, NO_CRIT, MAX_ROLL]).amount, 4)
	assert_eq(_compute(bulbasaur, charmander, &"tackle", [50, CRIT, MAX_ROLL]).amount, 7)


func test_same_type_bonus_and_super_effective() -> void:
	# Fouet Lianes (45, Plante) de Bulbizarre sur Carapuce : ⌊⌊4·45·9/11⌋/50⌋ + 2 = 4 ;
	# bonus de type ⌊4 × 1,5⌋ = 6 ; super efficace ×2 = 12.
	var result := _compute(_battler(&"bulbasaur"), _battler(&"squirtle"), &"vine_whip",
		[50, NO_CRIT, MAX_ROLL])
	assert_eq(result.effectiveness, 2.0)
	assert_eq(result.amount, 12)


func test_special_moves_use_special_stats() -> void:
	# Écume (40, spéciale, Eau) de Carapuce N5 (Atq. Spé ⌊100·0,05⌋ + 5 = 10) sur
	# Salamèche (Déf. Spé 10) : ⌊⌊4·40·10/10⌋/50⌋ + 2 = 5 ; bonus ⌊7,5⌋ = 7 ; ×2 = 14.
	var squirtle := _battler(&"squirtle")
	squirtle.change_stage(&"atk", -6)
	var result := _compute(squirtle, _battler(&"charmander"), &"bubble",
		[50, NO_CRIT, MAX_ROLL])
	assert_eq(result.amount, 14, "l'Attaque physique ne compte pas")


func test_minimum_one_damage() -> void:
	# Bulbizarre N1 sur Salamèche N100 : base 2, aléatoire ⌊2 × 0,85⌋ = 1,
	# bonus ⌊1,5⌋ = 1, pas très efficace ⌊0,5⌋ = 0 → 1.
	var result := _compute(_battler(&"bulbasaur", 1), _battler(&"charmander", 100),
		&"vine_whip", [50, NO_CRIT, MIN_ROLL])
	assert_eq(result.effectiveness, 0.5)
	assert_eq(result.amount, 1)


func test_immune_target_takes_nothing_and_draws_nothing() -> void:
	var ghost := Battler.new(_battler(&"charmander").pokemon, [&"ghost"] as Array[StringName])
	var result := _compute(_battler(&"bulbasaur"), ghost, &"tackle", [])
	assert_true(result.hit)
	assert_eq(result.effectiveness, 0.0)
	assert_eq(result.amount, 0)


func test_accuracy_roll_misses_above_the_accuracy() -> void:
	var squirtle := _battler(&"squirtle")
	var charmander := _battler(&"charmander")
	var missed := _compute(squirtle, charmander, &"hydro_pump", [81])
	assert_false(missed.hit)
	assert_eq(missed.amount, 0)
	assert_true(_compute(squirtle, charmander, &"hydro_pump", [80, NO_CRIT, MAX_ROLL]).hit)


func test_high_critical_stage_rolls_one_in_eight() -> void:
	var rng := ScriptedRng.new([1, 8, MAX_ROLL])
	var result := DamageCalc.compute(_battler(&"bulbasaur"), _battler(&"squirtle"),
		_data.get_move(&"razor_leaf"), _chart, rng)
	assert_false(result.critical, "8 sur 8 : pas de critique")
	rng = ScriptedRng.new([1, 1, MAX_ROLL])
	assert_true(DamageCalc.compute(_battler(&"bulbasaur"), _battler(&"squirtle"),
		_data.get_move(&"razor_leaf"), _chart, rng).critical)


func test_struggle_never_misses_and_is_typeless() -> void:
	# Lutte (50) de Salamèche (Atq 10) sur un Spectre (Déf 9) : sans type, donc touché ;
	# ⌊⌊4·50·10/9⌋/50⌋ + 2 = ⌊222/50⌋ + 2 = 6 ; aucun bonus de type.
	var ghost := Battler.new(_battler(&"charmander").pokemon, [&"ghost"] as Array[StringName])
	var result := _compute(_battler(&"charmander"), ghost, &"struggle", [NO_CRIT, MAX_ROLL])
	assert_eq(result.effectiveness, 1.0)
	assert_eq(result.amount, 6)


func test_status_accuracy_check() -> void:
	var growl := _data.get_move(&"growl")
	var a := _battler(&"charmander")
	var b := _battler(&"squirtle")
	assert_true(DamageCalc.accuracy_check(a, b, growl, ScriptedRng.new([100])))
	var growth := _data.get_move(&"growth")
	var rng := ScriptedRng.new([])
	assert_true(DamageCalc.accuracy_check(a, b, growth, rng), "ne rate jamais, sans tirage")
	assert_eq(rng.calls, 0)
	b.change_stage(&"eva", 1)
	assert_false(DamageCalc.accuracy_check(a, b, growl, ScriptedRng.new([76])), "×0,75 → 75")
