extends GutTest
## Étape de scène « flash » (jalon-14.md §2.7) : lecture par CutsceneLibrary (nombre d'éclairs
## entier ≥ 1), place en fin d'enum. (Fichier à part de test_cutscene_library.gd : le J12 y
## ajoute l'étape « moment ».)


func _parse(step: Dictionary) -> CutsceneLibrary:
	var library := CutsceneLibrary.new()
	library.add_from_dict({"s": {"steps": [step]}}, "test")
	return library


func test_flash_is_read_with_its_count() -> void:
	var library := _parse({"flash": 2})
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := library.get_cutscene(&"s").variants[0].steps[0]
	assert_eq(step.kind, CutsceneStep.Kind.FLASH)
	assert_eq(step.count, 2)
	assert_eq(CutsceneStep.kind_name(step.kind), &"flash")
	assert_eq(step.copy().count, 2)


func test_flash_accepts_conditions() -> void:
	var library := _parse({"flash": 1, "if": ["bill_in_cabin"]})
	var step := library.get_cutscene(&"s").variants[0].steps[0]
	assert_eq(step.if_flags, [&"bill_in_cabin"] as Array[StringName])


func test_invalid_flash_is_refused() -> void:
	for value: Variant in [0, -1, 1.5, "1", true]:
		var library := _parse({"flash": value})
		assert_false(library.has_cutscene(&"s"), "refusé : %s" % [value])
		assert_string_contains(", ".join(library.get_errors()), "nombre entier d'éclairs")
	var extra := _parse({"flash": 1, "count": 2})
	assert_false(extra.has_cutscene(&"s"))
	assert_string_contains(", ".join(extra.get_errors()), "clé inconnue « count »")
	assert_push_error_count(6)


func test_flash_is_the_last_kind() -> void:
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())
	assert_eq(CutsceneStep.TYPE_KEYS.back(), "flash")
	assert_eq(CutsceneStep.Kind.FLASH, CutsceneStep.Kind.size() - 1)
