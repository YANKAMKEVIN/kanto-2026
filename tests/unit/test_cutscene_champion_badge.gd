extends GutTest
## CutsceneLibrary, CutsceneStep : étapes « champion_card » et « badge » (jalon-10.md §2.7, §2.8,
## T9) — la carte de présentation de Pierre et la remise du Badge Roche.

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _one_step(step: Dictionary, id: String) -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


func test_new_kinds_at_the_end_of_the_enum() -> void:
	assert_eq(CutsceneStep.Kind.CHAMPION_CARD, CutsceneStep.Kind.EMOTE + 1, "après EMOTE (J9)")
	assert_eq(CutsceneStep.Kind.BADGE, CutsceneStep.Kind.EMOTE + 2)
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.CHAMPION_CARD), &"champion_card")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.BADGE), &"badge")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size(), "une clé par type")


func test_champion_card_step() -> void:
	var step := _one_step({"champion_card": "pewter_gym_brock"}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.CHAMPION_CARD)
	assert_eq(step.trainer_id, &"pewter_gym_brock")
	assert_eq(step.copy().trainer_id, &"pewter_gym_brock", "copiée")
	var conditional := _one_step({"champion_card": "x", "unless": ["met"]}, "b")
	assert_eq(conditional.unless_flags, [&"met"] as Array[StringName], "conditions d'étape")


func test_badge_step() -> void:
	var step := _one_step({"badge": "boulder", "if": ["badge_boulder"]}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.BADGE)
	assert_eq(step.badge_id, &"boulder")
	assert_eq(step.if_flags, [&"badge_boulder"] as Array[StringName])
	assert_eq(step.copy().badge_id, &"boulder", "copiée")


func test_card_trainers_and_badges_are_listed() -> void:
	assert_true(_library.add_from_dict({"s": {"steps": [
		{"champion_card": "pewter_gym_brock"}, {"battle": "pewter_gym_brock"},
		{"badge": "boulder"}, {"badge": "cascade"},
	]}}, "test"), str(_library.get_errors()))
	assert_eq(_library.get_card_trainer_ids(), [&"pewter_gym_brock"] as Array[StringName])
	assert_eq(_library.get_badge_ids(), [&"boulder", &"cascade"] as Array[StringName])
	assert_eq(_library.get_trainer_ids(), [&"pewter_gym_brock"] as Array[StringName],
		"les combats seulement")


func test_invalid_steps() -> void:
	var bad: Array[Dictionary] = [
		{"champion_card": ""},
		{"champion_card": 3},
		{"champion_card": "x", "hold": 2},
		{"badge": ""},
		{"badge": ["boulder"]},
		{"badge": "boulder", "to": "player"},
		{"badge": "boulder", "champion_card": "x"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["champion_card : identifiant attendu", "badge : identifiant attendu",
			"clé inconnue « hold »", "clé inconnue « to »", "exactement un type"]:
		assert_string_contains(errors, expected)
