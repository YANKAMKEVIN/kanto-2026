extends GutTest
## JsonFields : lecture tolérante des champs JSON de la sauvegarde (jalon 5 §16.1).


func _round_trip(dict: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(dict))


func test_ints_survive_json_as_floats() -> void:
	var dict := _round_trip({"n": 42, "f": 2.5, "s": "7"})
	assert_true(dict["n"] is float, "JSON ne connaît que les flottants")
	assert_eq(JsonFields.get_int(dict, "n"), 42)
	assert_eq(JsonFields.get_int(dict, "f", -1), -1, "2.5 n'est pas un entier")
	assert_eq(JsonFields.get_int(dict, "s", -1), -1, "une chaîne n'est pas un entier")
	assert_eq(JsonFields.get_int(dict, "absent", 9), 9)
	assert_eq(JsonFields.get_float(dict, "f"), 2.5)
	assert_eq(JsonFields.get_float(dict, "n"), 42.0)
	assert_eq(JsonFields.get_float(dict, "s", 1.5), 1.5)


func test_strings_names_and_bools() -> void:
	var dict := _round_trip({"s": "route_1", "b": true, "n": 3, "empty": ""})
	assert_eq(JsonFields.get_string(dict, "s"), "route_1")
	assert_eq(JsonFields.get_string(dict, "n", "d"), "d")
	assert_eq(JsonFields.get_id(dict, "s"), &"route_1")
	assert_eq(JsonFields.get_id(dict, "n", &"d"), &"d")
	assert_eq(JsonFields.get_id(dict, "empty"), &"")
	assert_true(JsonFields.get_bool(dict, "b"))
	assert_false(JsonFields.get_bool(dict, "n", false))
	assert_true(JsonFields.get_bool(dict, "absent", true))


func test_vector2i_round_trip_and_fallbacks() -> void:
	var dict := _round_trip({"v": JsonFields.vector2i_to_array(Vector2i(23, -1)),
		"short": [1], "bad": [1.5, 2], "nope": "x"})
	assert_eq(JsonFields.get_vector2i(dict, "v"), Vector2i(23, -1))
	assert_eq(JsonFields.get_vector2i(dict, "short", Vector2i.UP), Vector2i.UP)
	assert_eq(JsonFields.get_vector2i(dict, "bad", Vector2i.UP), Vector2i.UP)
	assert_eq(JsonFields.get_vector2i(dict, "nope"), Vector2i.ZERO)


func test_arrays_dicts_and_names_are_copies_or_empty() -> void:
	var dict := {"list": [1, 2], "map": {"a": 1}, "names": ["pidgey", "", 3, "rattata"]}
	var list := JsonFields.get_array(dict, "list")
	list.append(3)
	assert_eq(dict["list"], [1, 2], "copie")
	assert_eq(JsonFields.get_array(dict, "map"), [])
	assert_eq(JsonFields.get_dict(dict, "map"), {"a": 1})
	assert_eq(JsonFields.get_dict(dict, "list"), {})
	assert_eq(JsonFields.get_ids(dict, "names"), [&"pidgey", &"rattata"] as Array[StringName])
	assert_eq(JsonFields.ids_to_array([&"a", &"b"] as Array[StringName]), ["a", "b"])
