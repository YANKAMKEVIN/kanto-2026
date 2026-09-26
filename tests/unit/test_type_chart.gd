extends GutTest
## TypeChart : table moderne des 18 types de data/pokemon/types.json (jalon 4 §2.1).

var _chart: TypeChart


func before_each() -> void:
	_chart = TypeChart.new()


func _types(ids: Array[StringName]) -> Array[StringName]:
	return ids


func test_real_table_loads_without_error_with_18_types() -> void:
	assert_true(_chart.load_file())
	assert_eq(_chart.get_errors().size(), 0)
	assert_eq(_chart.get_type_ids().size(), 18)
	for id: StringName in [&"normal", &"fire", &"water", &"electric", &"grass", &"ice",
			&"fighting", &"poison", &"ground", &"flying", &"psychic", &"bug", &"rock",
			&"ghost", &"dragon", &"dark", &"steel", &"fairy"]:
		assert_true(_chart.has_type(id), String(id))
	assert_eq(_chart.get_type_name(&"fire"), "Feu")
	assert_eq(_chart.get_type_name(&"dark"), "Ténèbres")
	assert_eq(_chart.get_type_name(&"nothing"), "")


func test_known_matchups() -> void:
	_chart.load_file()
	assert_eq(_chart.multiplier(&"fire", _types([&"grass", &"poison"])), 2.0)
	assert_eq(_chart.multiplier(&"water", _types([&"fire"])), 2.0)
	assert_eq(_chart.multiplier(&"grass", _types([&"water"])), 2.0)
	assert_eq(_chart.multiplier(&"normal", _types([&"ghost"])), 0.0)
	assert_eq(_chart.multiplier(&"grass", _types([&"fire"])), 0.5)
	assert_eq(_chart.multiplier(&"ice", _types([&"grass", &"flying"])), 4.0, "double faiblesse")
	assert_eq(_chart.multiplier(&"fire", _types([&"water", &"dragon"])), 0.25)
	assert_eq(_chart.multiplier(&"dark", _types([&"psychic"])), 2.0)
	assert_eq(_chart.multiplier(&"dragon", _types([&"fairy"])), 0.0)
	assert_eq(_chart.multiplier(&"normal", _types([&"fire"])), 1.0, "1 par défaut")


func test_typeless_attack_is_neutral() -> void:
	_chart.load_file()
	assert_eq(_chart.multiplier(&"", _types([&"ghost"])), 1.0)


func test_table_totals_match_the_modern_chart() -> void:
	_chart.load_file()
	var counts: Dictionary[float, int] = {0.0: 0, 0.5: 0, 2.0: 0}
	for attacker: StringName in _chart.get_type_ids():
		for defender: StringName in _chart.get_type_ids():
			var factor := _chart.single(attacker, defender)
			assert_true([0.0, 0.5, 1.0, 2.0].has(factor))
			if factor != 1.0:
				counts[factor] += 1
	assert_eq(counts[2.0], 51, "super efficace")
	assert_eq(counts[0.5], 61, "pas très efficace")
	assert_eq(counts[0.0], 8, "sans effet")


func test_broken_json_reports_the_line() -> void:
	assert_false(_chart.load_file("res://tests/fixtures/pokemon/bad_json/types_broken.json"))
	assert_push_error("ligne 5")


func test_missing_file_is_an_error() -> void:
	assert_false(_chart.load_file("res://tests/fixtures/pokemon/nothing.json"))
	assert_push_error("fichier introuvable")


func test_unknown_keys_types_and_values_are_rejected() -> void:
	var ok := _chart.add_from_dict({
		"types": {
			"fire": { "name": "Feu" }, "water": { "name": "Eau" },
			"ice": { "name": "Glace", "color": "blue" },
		},
		"chart": {
			"fire": { "water": 0.5, "grass": 2 },
			"water": { "fire": 3 },
			"ghost": { "fire": 1 },
		},
		"extra": true,
	}, "test")
	assert_false(ok)
	assert_push_error_count(5)
	var errors := "\n".join(_chart.get_errors())
	assert_string_contains(errors, "clé inconnue « extra »")
	assert_string_contains(errors, "clé inconnue « color »")
	assert_string_contains(errors, "type défenseur inconnu « grass »")
	assert_string_contains(errors, "0, 0.5 ou 2")
	assert_string_contains(errors, "type attaquant inconnu")
	assert_false(_chart.has_type(&"ice"), "type invalide écarté")
	assert_eq(_chart.single(&"fire", &"water"), 0.5, "valeurs valides gardées")
	assert_eq(_chart.single(&"water", &"fire"), 1.0, "valeur invalide ignorée")


func test_missing_or_empty_name_is_rejected() -> void:
	assert_false(_chart.add_from_dict({ "types": { "fire": {}, "ice": { "name": " " } } }, "t"))
	assert_push_error_count(2)
	assert_eq(_chart.get_type_ids().size(), 0)
