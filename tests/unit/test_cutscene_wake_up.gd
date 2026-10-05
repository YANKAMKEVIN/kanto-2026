extends GutTest
## CutsceneLibrary, CutsceneStep : étape « wake_up » (jalon-07.md §3.8, T25) — réveil au point
## de repos après une défaite contre un Dresseur (le rival de la Route 22).

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _one_step(step: Dictionary, id: String) -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


func test_type_key_at_the_end_of_the_enum() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.WAKE_UP), &"wake_up")
	# Ajoutée en fin d'enum au T25 ; « react » (retours T5, §15.21) vient après elle.
	assert_eq(CutsceneStep.Kind.WAKE_UP, CutsceneStep.Kind.REACT - 1, "fin d'enum au T25")
	assert_eq(CutsceneStep.Kind.REACT, CutsceneStep.Kind.size() - 1, "react en dernier")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size(), "une clé par type")


func test_wake_up_step() -> void:
	var step := _one_step({"wake_up": true}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.WAKE_UP)
	var conditional := _one_step({"wake_up": true, "if": ["rival_route22_lost"]}, "b")
	assert_eq(conditional.if_flags, [&"rival_route22_lost"] as Array[StringName])
	assert_eq(conditional.copy().kind, CutsceneStep.Kind.WAKE_UP, "copiée")
	assert_false(conditional.applies(StoryFlags.new()), "sautée sans la défaite")


func test_invalid_wake_up_steps() -> void:
	var bad: Array[Dictionary] = [
		{"wake_up": false},
		{"wake_up": "player_house_1f"},
		{"wake_up": 1},
		{"wake_up": true, "at": "heal"},
		{"wake_up": true, "wait": 1.0},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« wake_up » vaut true")
	assert_string_contains(errors, "clé inconnue « at »")
	assert_string_contains(errors, "exactement un type")
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size())
