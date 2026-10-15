extends GutTest
## Variantes « field » des dialogues (jalon 16, T6 ; `jalon-16.md` §2.2) : une variante ne
## s'applique que dans l'état de capacité de terrain qu'elle nomme ; sans source d'état, elle est
## sautée ; formats invalides refusés.


func _result(state: FieldMoves.State, name: String = "Sabelette") -> FieldMoves.Result:
	var result := FieldMoves.Result.new(state, 0)
	result.pokemon_name = name
	return result


func _library() -> DialogueLibrary:
	var lib := DialogueLibrary.new()
	assert_true(lib.add_from_dict({"tree": {"narration": true, "variants": [
		{"field": "cut:no_hm", "pages": ["Un arbuste barre le passage."]},
		{"field": "cut:no_badge", "pages": ["Sans le Badge Cascade, {pokemon} n'ose pas."]},
		{"field": "cut:no_pokemon", "pages": ["Aucun Pokémon."]},
		{"field": "cut:ready", "pages": ["{pokemon} peut couper cet arbuste.", "Utiliser Coupe ?"],
			"choice": {"confirm": "COUPER", "cancel": "LAISSER", "confirm_cutscene": "cut_x",
				"cancel_pages": []}},
		{"pages": ["(repli)"]},
	]}}, "test"), "\n".join(lib.get_errors()))
	return lib


func test_variant_follows_the_field_state() -> void:
	var tree := _library().get_dialogue(&"tree")
	var expected := {
		FieldMoves.State.NO_HM: "Un arbuste barre le passage.",
		FieldMoves.State.NO_BADGE: "Sans le Badge Cascade, {pokemon} n'ose pas.",
		FieldMoves.State.NO_POKEMON: "Aucun Pokémon.",
		FieldMoves.State.READY: "{pokemon} peut couper cet arbuste.",
	}
	for state: FieldMoves.State in expected:
		var source := func(_move: StringName) -> FieldMoves.Result: return _result(state)
		var variant := tree.pick(StoryFlags.new(), null, source)
		assert_eq(variant.pages[0].text, expected[state], FieldMoves.STATE_NAMES[state])
	var ready := tree.pick(StoryFlags.new(), null,
		func(_m: StringName) -> FieldMoves.Result: return _result(FieldMoves.State.READY))
	assert_not_null(ready.choice, "COUPER / LAISSER")


func test_without_source_field_variants_are_skipped() -> void:
	var variant := _library().get_dialogue(&"tree").pick(StoryFlags.new())
	assert_eq(variant.pages[0].text, "(repli)")


func test_bad_field_values_rejected() -> void:
	var lib := DialogueLibrary.new()
	assert_false(lib.add_from_dict({"a": {"variants": [{"field": "cut", "pages": ["x"]}]}}, "t"))
	assert_false(lib.add_from_dict({"b": {"variants": [{"field": "cut:maybe", "pages": ["x"]}]}},
		"t"))
	assert_false(lib.add_from_dict({"c": {"variants": [{"field": "cut:ready", "auto": true,
		"pages": ["x"]}]}}, "t"))
	assert_push_error_count(3)
