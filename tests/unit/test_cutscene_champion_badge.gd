extends GutTest
## CutsceneLibrary, CutsceneStep : étape « badge » (jalon-10.md §2.8, T9), la remise du Badge
## Roche. L'étape « champion_card » (carte de présentation, jalon 10 §2.7) est retirée le
## 2026-11-02 : la séquence « VS » du combat la remplace (dossier 05 §3, [TrainerIntro]).

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _one_step(step: Dictionary, id: String) -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


func test_badge_kind_follows_emote() -> void:
	assert_eq(CutsceneStep.Kind.BADGE, CutsceneStep.Kind.EMOTE + 1, "après EMOTE (J9)")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.BADGE), &"badge")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size(), "une clé par type")
	assert_false(CutsceneStep.TYPE_KEYS.has("champion_card"), "carte de Champion retirée")


func test_badge_step() -> void:
	var step := _one_step({"badge": "boulder", "if": ["badge_boulder"]}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.BADGE)
	assert_eq(step.badge_id, &"boulder")
	assert_eq(step.if_flags, [&"badge_boulder"] as Array[StringName])
	assert_eq(step.copy().badge_id, &"boulder", "copiée")


func test_badges_are_listed() -> void:
	assert_true(_library.add_from_dict({"s": {"steps": [
		{"battle": "pewter_gym_brock"}, {"badge": "boulder"}, {"badge": "cascade"},
	]}}, "test"), str(_library.get_errors()))
	assert_eq(_library.get_badge_ids(), [&"boulder", &"cascade"] as Array[StringName])
	assert_eq(_library.get_trainer_ids(), [&"pewter_gym_brock"] as Array[StringName],
		"les combats seulement")


func test_invalid_steps() -> void:
	var bad: Array[Dictionary] = [
		{"champion_card": "pewter_gym_brock"},
		{"badge": ""},
		{"badge": ["boulder"]},
		{"badge": "boulder", "to": "player"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["badge : identifiant attendu", "clé inconnue « to »"]:
		assert_string_contains(errors, expected)
