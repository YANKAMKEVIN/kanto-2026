extends GutTest
## ExpCalc : XP gagnée (⌊b × N × m / 7⌋, au moins 1), partage, barre d'XP (jalon 5 §2.3,
## Q23, Q24). XP de base modernes : Roucool 50, Rattata 51 ; courbe moyenne-lente des
## starters : N5 = 135, N6 = 179, N7 = 236.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func test_pidgey_level_3_gives_21_exp() -> void:
	# ⌊50 × 3 / 7⌋ = ⌊21,4⌋ = 21 (jalon 5 Q23).
	assert_eq(ExpCalc.amount(_mon(&"pidgey", 3), _data), 21)
	assert_eq(ExpCalc.amount(_mon(&"rattata", 2), _data), 14, "⌊51 × 2 / 7⌋")
	assert_eq(ExpCalc.amount(_mon(&"pidgey", 5), _data), 35, "⌊250 / 7⌋")


func test_trainer_multiplier() -> void:
	# ×1,5 contre un dresseur : ⌊50 × 3 × 1,5 / 7⌋ = ⌊32,1⌋ = 32.
	assert_eq(ExpCalc.amount(_mon(&"pidgey", 3), _data, 1.5), 32)
	assert_eq(ExpCalc.amount(_mon(&"pidgey", 3), _data, BattleRules.for_trainer().exp_multiplier),
		32)


func test_floor_of_one() -> void:
	# Une XP de base très faible donne quand même 1 point.
	var fixture := PokemonData.new()
	fixture.load_dir("res://tests/fixtures/pokemon/valid/")
	var tiny := Pokemon.new()
	tiny.species_id = fixture.get_species_ids()[0]
	tiny.level = 1
	fixture.get_species(tiny.species_id).base_exp = 1
	assert_eq(ExpCalc.amount(tiny, fixture), 1, "⌊1 × 1 / 7⌋ = 0 → 1")
	assert_eq(ExpCalc.amount(tiny, fixture, 0.0), 1, "même avec un multiplicateur nul")


func test_unknown_species_gives_nothing() -> void:
	var ghost := Pokemon.new()
	ghost.species_id = &"missingno"
	assert_eq(ExpCalc.amount(ghost, _data), 0)
	assert_eq(ExpCalc.amount(null, _data), 0)
	assert_eq(ExpCalc.progress(ghost, _data), 0.0)


func test_split_gives_the_remainder_to_the_first() -> void:
	assert_eq(ExpCalc.split(21, 1), [21] as Array[int])
	assert_eq(ExpCalc.split(21, 2), [11, 10] as Array[int])
	assert_eq(ExpCalc.split(21, 3), [7, 7, 7] as Array[int])
	assert_eq(ExpCalc.split(22, 3), [8, 7, 7] as Array[int])
	assert_eq(ExpCalc.split(1, 2), [1, 0] as Array[int])
	assert_eq(ExpCalc.split(21, 0), [] as Array[int])
	for count: int in range(1, 7):
		var total := 0
		for share: int in ExpCalc.split(35, count):
			total += share
		assert_eq(total, 35, "la somme des parts vaut le total (%d parts)" % count)


func test_progress_in_the_current_level() -> void:
	var charmander := _mon(&"charmander", 5)
	assert_eq(charmander.experience, 135)
	assert_eq(ExpCalc.progress(charmander, _data), 0.0, "début du niveau 5")
	charmander.experience = 135 + 22
	assert_almost_eq(ExpCalc.progress(charmander, _data), 0.5, 0.0001, "22 / 44")
	charmander.experience = 178
	assert_almost_eq(ExpCalc.progress(charmander, _data), 43.0 / 44.0, 0.0001)


func test_progress_is_full_at_level_100() -> void:
	var top := _mon(&"rattata", 100)
	assert_eq(ExpCalc.progress(top, _data), 1.0)


func test_level_span_in_the_current_level() -> void:
	var charmander := _mon(&"charmander", 5)
	assert_eq(ExpCalc.level_span(charmander, _data), Vector2i(0, 44), "N5 = 135, N6 = 179")
	charmander.experience = 135 + 30
	assert_eq(ExpCalc.level_span(charmander, _data), Vector2i(30, 44))
	charmander.experience = 10
	assert_eq(ExpCalc.level_span(charmander, _data), Vector2i(0, 44), "jamais négatif")


func test_level_span_is_zero_at_level_100_or_unknown_species() -> void:
	assert_eq(ExpCalc.level_span(_mon(&"rattata", 100), _data), Vector2i.ZERO)
	var unknown := _mon(&"rattata", 5)
	unknown.species_id = &"missingno"
	assert_eq(ExpCalc.level_span(unknown, _data), Vector2i.ZERO)
	assert_eq(ExpCalc.level_span(null, _data), Vector2i.ZERO)
