extends GutTest
## CutsceneLibrary, CutsceneStep : étapes « caption » et « take » (jalon-07.md §3.6, T18) —
## la légende POKÉDEX ACTIVÉ et le colis remis à Chen. (Fichier à part de
## test_cutscene_library.gd : l'étape « scare » du T2 y est ajoutée en parallèle.)

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _one_step(step: Dictionary, id: String) -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


func test_type_keys() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.CAPTION), &"caption")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.TAKE), &"take")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size(), "une clé par type")


func test_caption_step() -> void:
	var step := _one_step({"caption": "POKÉDEX ACTIVÉ"}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.CAPTION)
	assert_eq(step.text, "POKÉDEX ACTIVÉ")
	assert_eq(step.copy().text, "POKÉDEX ACTIVÉ", "copiée")
	var conditional := _one_step({"caption": "X", "if": ["ready"]}, "b")
	assert_eq(conditional.if_flags, [&"ready"] as Array[StringName], "conditions d'étape")


func test_take_step() -> void:
	var step := _one_step({"take": "oak_parcel"}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.TAKE)
	assert_eq(step.item_id, &"oak_parcel")
	assert_eq(step.count, 1, "un par défaut")
	var several := _one_step({"take": "potion", "count": 3, "unless": ["gone"]}, "b")
	assert_eq(several.count, 3)
	assert_eq(several.unless_flags, [&"gone"] as Array[StringName])
	assert_eq(several.copy().count, 3)
	assert_eq(several.copy().item_id, &"potion")


func test_taken_items_are_listed_with_the_given_ones() -> void:
	assert_true(_library.add_from_dict({"s": {"steps": [
		{"give": "poke_ball", "count": 5}, {"take": "oak_parcel"},
	]}}, "test"))
	assert_eq(_library.get_item_ids(), [&"oak_parcel", &"poke_ball"] as Array[StringName])


func test_invalid_caption_and_take_steps() -> void:
	var bad: Array[Dictionary] = [
		{"caption": ""},
		{"caption": "   "},
		{"caption": 3},
		{"caption": "X", "to": "player"},
		{"take": ""},
		{"take": 7},
		{"take": "potion", "count": 0},
		{"take": "potion", "count": 1.5},
		{"take": "potion", "found": true},
		{"take": "potion", "caption": "X"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« caption » doit être un texte non vide",
			"take : identifiant attendu", "« count » doit être un entier ≥ 1",
			"clé inconnue « found »", "clé inconnue « to »", "exactement un type"]:
		assert_string_contains(errors, expected)
