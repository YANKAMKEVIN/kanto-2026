extends GutTest
## OpeningNames (dossier 13, A5, A7) : `data/opening/names.json` et sa validation.

const GameStateScript := preload("res://game/autoload/game_state.gd")


func _valid() -> Dictionary:
	return {
		"max_length": 10,
		"player": {"default": "Kevin", "suggestions": ["Red", "Sacha", "Kevin"]},
		"rival": {"default": "Régis", "suggestions": ["Régis", "Blue", "Gary"]},
	}


func _load(data: Dictionary) -> OpeningNames:
	var names := OpeningNames.new()
	names.add_from_dict(data, "test")
	return names


func test_real_file_loads() -> void:
	var names := OpeningNames.new()
	assert_true(names.load_file(), str(names.get_errors()))
	assert_eq(names.max_length(), 10)
	assert_eq(names.suggestions(OpeningNames.ROLE_PLAYER),
		PackedStringArray(["Red", "Sacha", "Kevin"]))
	assert_eq(names.suggestions(OpeningNames.ROLE_RIVAL),
		PackedStringArray(["Régis", "Blue", "Gary"]))
	assert_eq(names.default_name(OpeningNames.ROLE_RIVAL), "Régis")


func test_player_default_matches_game_state() -> void:
	var names := OpeningNames.new()
	names.load_file()
	assert_eq(names.default_name(OpeningNames.ROLE_PLAYER), GameStateScript.DEFAULT_PLAYER_NAME)


func test_valid_dict_applies() -> void:
	var names := _load(_valid())
	assert_true(names.is_loaded())
	assert_eq(names.get_errors().size(), 0)


func test_note_key_is_allowed() -> void:
	var data := _valid()
	data["_note"] = "commentaire"
	assert_true(_load(data).is_loaded())


func test_unknown_root_key_rejects_everything() -> void:
	var data := _valid()
	data["maxlength"] = 8
	var names := _load(data)
	assert_false(names.is_loaded())
	assert_eq(names.max_length(), 0)
	assert_eq(names.default_name(OpeningNames.ROLE_PLAYER), "")


func test_unknown_role_key_is_an_error() -> void:
	var data := _valid()
	data["rival"]["suggestion"] = ["Gary"]
	assert_false(_load(data).is_loaded())


func test_bad_max_length() -> void:
	for value: Variant in [0, -3, 2.5, "10", null]:
		var data := _valid()
		data["max_length"] = value
		assert_false(_load(data).is_loaded(), str(value))


func test_float_integer_max_length_is_accepted() -> void:
	var data := _valid()
	data["max_length"] = 10.0  # JSON rend des flottants
	assert_eq(_load(data).max_length(), 10)


func test_missing_role() -> void:
	var data := _valid()
	data.erase("rival")
	assert_false(_load(data).is_loaded())


func test_invalid_suggestion() -> void:
	for bad: Variant in ["R2", "", "Maximilienne", 42, "😀"]:
		var data := _valid()
		data["player"]["suggestions"] = ["Red", bad]
		assert_false(_load(data).is_loaded(), str(bad))


func test_suggestion_must_be_normalized() -> void:
	for bad: String in ["red", " Red", "Jean  Luc", "D'Arc"]:
		var data := _valid()
		data["player"]["suggestions"] = [bad]
		assert_false(_load(data).is_loaded(), bad)


func test_suggestion_count_and_duplicates() -> void:
	var data := _valid()
	data["player"]["suggestions"] = []
	assert_false(_load(data).is_loaded(), "aucune")
	data["player"]["suggestions"] = ["Red", "Sacha", "Kevin", "Ash"]
	assert_false(_load(data).is_loaded(), "quatre")
	data["player"]["suggestions"] = ["Red", "Red"]
	assert_false(_load(data).is_loaded(), "doublon")


func test_invalid_default() -> void:
	var data := _valid()
	data["rival"]["default"] = "  "
	assert_false(_load(data).is_loaded())
	data["rival"]["default"] = "régis"
	assert_false(_load(data).is_loaded(), "non normalisé")


func test_default_longer_than_max_length() -> void:
	var data := _valid()
	data["max_length"] = 4
	assert_false(_load(data).is_loaded(), "« Kevin » et « Sacha » dépassent 4")


func test_missing_file() -> void:
	var names := OpeningNames.new()
	assert_false(names.load_file("res://data/opening/absent.json"))
	assert_gt(names.get_errors().size(), 0)
