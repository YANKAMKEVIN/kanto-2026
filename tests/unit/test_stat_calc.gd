extends GutTest
## StatCalc : formules modernes, valeurs calculées à la main (jalon 4 §2.1).

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _all(value: int) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for stat: StringName in SpeciesData.STATS:
		result[stat] = value
	return result


func test_charmander_level_5_with_iv_0() -> void:
	# PV : ⌊(2·39 + 0)·5/100⌋ + 5 + 10 = ⌊3,9⌋ + 15 = 18 ; Atq : ⌊104·5/100⌋ + 5 = 10 ;
	# Déf : ⌊86·0,05⌋ + 5 = 9 ; Atq. Spé : ⌊120·0,05⌋ + 5 = 11 ; Déf. Spé : 10 ;
	# Vit : ⌊130·0,05⌋ + 5 = 11.
	var stats := StatCalc.compute(_data.get_species(&"charmander"), 5, _all(0), _all(0))
	assert_eq(stats, {&"hp": 18, &"atk": 10, &"def": 9, &"spa": 11, &"spd": 10, &"spe": 11}
		as Dictionary[StringName, int])


func test_charmander_level_5_with_iv_31() -> void:
	# PV : ⌊109·0,05⌋ + 15 = 20 ; Atq : ⌊135·0,05⌋ + 5 = 11 ; Déf : ⌊117·0,05⌋ + 5 = 10 ;
	# Atq. Spé : ⌊151·0,05⌋ + 5 = 12 ; Déf. Spé : ⌊131·0,05⌋ + 5 = 11 ;
	# Vit : ⌊161·0,05⌋ + 5 = 13.
	var stats := StatCalc.compute(_data.get_species(&"charmander"), 5, _all(31), _all(0))
	assert_eq(stats, {&"hp": 20, &"atk": 11, &"def": 10, &"spa": 12, &"spd": 11, &"spe": 13}
		as Dictionary[StringName, int])


func test_evs_count_by_quarter() -> void:
	# Salamèche N100, IV 31, EV 252 en PV : ⌊(78 + 31 + 63)·100/100⌋ + 110 = 282.
	assert_eq(StatCalc.value(&"hp", 39, 31, 252, 100), 282)
	assert_eq(StatCalc.value(&"atk", 52, 31, 3, 100), 140, "3 EV ne comptent pas")
	assert_eq(StatCalc.value(&"atk", 52, 31, 4, 100), 141)


func test_missing_ivs_count_as_zero() -> void:
	var empty: Dictionary[StringName, int] = {}
	assert_eq(StatCalc.compute(_data.get_species(&"charmander"), 5, empty, empty)[&"hp"], 18)
