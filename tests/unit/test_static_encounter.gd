extends GutTest
## StaticEncounter (passe systèmes 2, T30 ; politique d'Artikodin du J24 §2.7) : présence,
## drapeaux selon l'issue, sauvegarde forcée.

const O := Battle.Outcome

var _bird: StaticEncounter


func before_each() -> void:
	_bird = StaticEncounter.new(&"articuno", &"articuno", 50, &"articuno_done", &"articuno_caught")


func test_present_until_done() -> void:
	var flags := StoryFlags.new()
	assert_true(_bird.is_present(flags))
	flags.set_flag(&"articuno_caught")
	assert_true(_bird.is_present(flags), "seul « done » fait disparaître")
	flags.set_flag(&"articuno_done")
	assert_false(_bird.is_present(flags))


func test_catch_consumes_and_records_the_capture() -> void:
	assert_eq(_bird.flags_for(O.CAUGHT),
		[&"articuno_done", &"articuno_caught"] as Array[StringName])
	assert_true(_bird.needs_forced_save(O.CAUGHT))


func test_knock_out_consumes_without_capture() -> void:
	assert_eq(_bird.flags_for(O.WIN), [&"articuno_done"] as Array[StringName])
	assert_true(_bird.needs_forced_save(O.WIN))


func test_flee_and_defeat_change_nothing() -> void:
	for outcome: int in [O.FLED, O.LOSS, O.FOE_FLED, O.NONE]:
		assert_eq(_bird.flags_for(outcome), [] as Array[StringName], str(outcome))
		assert_false(_bird.needs_forced_save(outcome))
