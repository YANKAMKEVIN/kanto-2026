extends GutTest
## Étapes de scène du jalon 16 (`jalon-16.md` §2.3 à §2.5) : « field_move » (capacité de terrain
## sur un PNJ objet), « save » (écriture immédiate, raison), « animate » (nœud, décalage en cases,
## durée, masquage) ; lecture, copie et refus.


func _parse(step: Dictionary) -> CutsceneLibrary:
	var library := CutsceneLibrary.new()
	library.add_from_dict({"s": {"steps": [step]}}, "test")
	return library


func _step(library: CutsceneLibrary) -> CutsceneStep:
	return library.get_cutscene(&"s").variants[0].steps[0]


func test_field_move_is_read() -> void:
	var library := _parse({"field_move": "cut", "on": "vermilion_gym_tree"})
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_eq([step.kind, step.field_move, step.actor],
		[CutsceneStep.Kind.FIELD_MOVE, &"cut", &"vermilion_gym_tree"])
	assert_eq(step.copy().field_move, &"cut")


func test_save_is_read() -> void:
	var step := _step(_parse({"save": "départ du S.S. Anne"}))
	assert_eq([step.kind, step.text], [CutsceneStep.Kind.SAVE, "départ du S.S. Anne"])


func test_animate_is_read() -> void:
	var library := _parse({"animate": "SsAnne", "offset": [12, 0], "duration": 6, "fade": true})
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_eq([step.kind, step.target, step.offset, step.seconds, step.fade],
		[CutsceneStep.Kind.ANIMATE, &"SsAnne", Vector2i(12, 0), 6.0, true])
	var copy := step.copy()
	assert_eq([copy.offset, copy.fade], [Vector2i(12, 0), true])


func test_invalid_steps_are_refused() -> void:
	var bad: Array[Dictionary] = [
		{"field_move": "cut"},
		{"save": ""},
		{"save": true},
		{"animate": "SsAnne", "offset": [1.5, 0], "duration": 2},
		{"animate": "SsAnne", "offset": [1, 0], "duration": 0},
		{"animate": "SsAnne", "offset": [1, 0], "duration": 2, "fade": "oui"},
	]
	var errors := 0
	for entry: Dictionary in bad:
		var library := _parse(entry)
		assert_false(library.has_cutscene(&"s"), "refusé : %s" % [entry])
		errors += library.get_errors().size()
	assert_push_error_count(errors)
