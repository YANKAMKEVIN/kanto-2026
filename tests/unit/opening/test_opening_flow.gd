extends GutTest
## OpeningFlow (dossier 13 §3.1, §3.2, §3.7, §5.2) : toutes les transitions, les quatre
## états de la sauvegarde, les effets et l'autosave.

const S := OpeningFlow.SaveStatus
const SC := OpeningFlow.Screen
const A := OpeningFlow.Action
const E := OpeningFlow.Effect
const ALL_STATUSES: Array[OpeningFlow.SaveStatus] = [S.NONE, S.VALID, S.CORRUPT, S.NEWER]
const ALL_ACTIONS: Array[OpeningFlow.Action] = [
	A.CONTINUE, A.NEW_GAME, A.SETTINGS, A.BACK, A.CONFIRM, A.CANCEL, A.ABANDON,
	A.INTRO_FINISHED, A.COMMIT_SUCCEEDED, A.COMMIT_FAILED,
]


func _flow(status: OpeningFlow.SaveStatus) -> OpeningFlow:
	return OpeningFlow.new(status)


## Mène [param flow] jusqu'à l'introduction (confirmation comprise si besoin).
func _to_intro(flow: OpeningFlow) -> void:
	assert_true(flow.handle(A.NEW_GAME))
	if flow.screen() == SC.CONFIRM_OVERWRITE:
		assert_true(flow.handle(A.CONFIRM))
	assert_eq(flow.screen(), SC.INTRO)
	assert_eq(flow.take_effects(), [] as Array[OpeningFlow.Effect], "aucun effet avant la fin")


func test_starts_on_title_without_effects() -> void:
	for status: OpeningFlow.SaveStatus in ALL_STATUSES:
		var flow := _flow(status)
		assert_eq(flow.screen(), SC.TITLE)
		assert_eq(flow.take_effects().size(), 0)
		assert_false(flow.autosave_allowed(), "titre : pas d'autosave (%d)" % status)


func test_status_from_read() -> void:
	assert_eq(OpeningFlow.status_from_read(OK), S.VALID)
	assert_eq(OpeningFlow.status_from_read(ERR_FILE_NOT_FOUND), S.NONE)
	assert_eq(OpeningFlow.status_from_read(ERR_FILE_CORRUPT), S.CORRUPT)
	assert_eq(OpeningFlow.status_from_read(ERR_INVALID_DATA), S.NEWER)
	assert_eq(OpeningFlow.status_from_read(ERR_FILE_CANT_READ), S.CORRUPT, "autre erreur")


func test_continue_only_with_valid_save() -> void:
	for status: OpeningFlow.SaveStatus in ALL_STATUSES:
		var flow := _flow(status)
		var accepted := flow.handle(A.CONTINUE)
		assert_eq(accepted, status == S.VALID, "statut %d" % status)
		if accepted:
			assert_eq(flow.screen(), SC.CONTINUE)
			assert_eq(flow.take_effects(), [E.RESUME_SAVE] as Array[OpeningFlow.Effect])
			assert_true(flow.autosave_allowed())
		else:
			assert_eq(flow.screen(), SC.TITLE)
			assert_eq(flow.take_effects().size(), 0)


func test_settings_round_trip() -> void:
	for status: OpeningFlow.SaveStatus in ALL_STATUSES:
		var flow := _flow(status)
		assert_true(flow.handle(A.SETTINGS))
		assert_eq(flow.screen(), SC.SETTINGS)
		assert_false(flow.autosave_allowed())
		assert_true(flow.handle(A.BACK))
		assert_eq(flow.screen(), SC.TITLE)
		assert_eq(flow.take_effects().size(), 0, "les réglages n'écrivent pas la partie")


func test_settings_accepts_only_back() -> void:
	var flow := _flow(S.VALID)
	flow.handle(A.SETTINGS)
	for action: OpeningFlow.Action in ALL_ACTIONS:
		if action != A.BACK:
			assert_false(flow.handle(action), "action %d" % action)
	assert_eq(flow.screen(), SC.SETTINGS)


func test_back_on_title_does_nothing() -> void:
	var flow := _flow(S.VALID)
	assert_false(flow.handle(A.BACK))
	assert_eq(flow.screen(), SC.TITLE)


func test_new_game_asks_confirmation_only_with_valid_save() -> void:
	for status: OpeningFlow.SaveStatus in ALL_STATUSES:
		var flow := _flow(status)
		flow.handle(A.NEW_GAME)
		var expected := SC.CONFIRM_OVERWRITE if status == S.VALID else SC.INTRO
		assert_eq(flow.screen(), expected, "statut %d" % status)
		assert_eq(flow.needs_confirmation(), status == S.VALID)


func test_confirmation_cancel_and_back_return_to_title() -> void:
	for action: OpeningFlow.Action in [A.CANCEL, A.BACK]:
		var flow := _flow(S.VALID)
		flow.handle(A.NEW_GAME)
		assert_true(flow.handle(action))
		assert_eq(flow.screen(), SC.TITLE)
		assert_eq(flow.take_effects().size(), 0)


func test_confirmation_refuses_other_actions() -> void:
	var flow := _flow(S.VALID)
	flow.handle(A.NEW_GAME)
	for action: OpeningFlow.Action in [A.CONTINUE, A.NEW_GAME, A.SETTINGS, A.ABANDON,
			A.INTRO_FINISHED, A.COMMIT_SUCCEEDED, A.COMMIT_FAILED]:
		assert_false(flow.handle(action), "action %d" % action)
	assert_eq(flow.screen(), SC.CONFIRM_OVERWRITE)


func test_intro_ignores_back_and_title_actions() -> void:
	var flow := _flow(S.VALID)
	_to_intro(flow)
	for action: OpeningFlow.Action in [A.BACK, A.CONTINUE, A.NEW_GAME, A.SETTINGS, A.CONFIRM,
			A.CANCEL, A.COMMIT_SUCCEEDED, A.COMMIT_FAILED]:
		assert_false(flow.handle(action), "action %d" % action)
	assert_eq(flow.screen(), SC.INTRO)
	assert_false(flow.autosave_allowed())


func test_abandon_returns_to_title_without_effect() -> void:
	for status: OpeningFlow.SaveStatus in ALL_STATUSES:
		var flow := _flow(status)
		_to_intro(flow)
		assert_true(flow.handle(A.ABANDON))
		assert_eq(flow.screen(), SC.TITLE)
		assert_eq(flow.take_effects().size(), 0, "statut %d : aucun effet disque" % status)
		assert_false(flow.autosave_allowed())


func test_new_game_after_abandon_asks_confirmation_again() -> void:
	var flow := _flow(S.VALID)
	_to_intro(flow)
	flow.handle(A.ABANDON)
	flow.handle(A.NEW_GAME)
	assert_eq(flow.screen(), SC.CONFIRM_OVERWRITE)
	assert_true(flow.can_continue(), "l'ancienne partie se reprend toujours")


func test_intro_finished_with_valid_save_backs_up_then_writes() -> void:
	var flow := _flow(S.VALID)
	_to_intro(flow)
	flow.handle(A.INTRO_FINISHED)
	assert_eq(flow.screen(), SC.COMMIT)
	assert_eq(flow.take_effects(),
		[E.BACKUP_PREVIOUS, E.WRITE_NEW_GAME] as Array[OpeningFlow.Effect])
	assert_false(flow.autosave_allowed(), "pas d'autosave pendant le commit")


func test_intro_finished_without_save_writes_without_backup() -> void:
	for status: OpeningFlow.SaveStatus in [S.NONE, S.CORRUPT]:
		var flow := _flow(status)
		_to_intro(flow)
		flow.handle(A.INTRO_FINISHED)
		assert_eq(flow.screen(), SC.COMMIT)
		assert_eq(flow.take_effects(), [E.WRITE_NEW_GAME] as Array[OpeningFlow.Effect])


func test_commit_succeeded_enters_bedroom_and_allows_autosave() -> void:
	for status: OpeningFlow.SaveStatus in [S.NONE, S.VALID, S.CORRUPT]:
		var flow := _flow(status)
		_to_intro(flow)
		flow.handle(A.INTRO_FINISHED)
		flow.take_effects()
		assert_true(flow.handle(A.COMMIT_SUCCEEDED))
		assert_eq(flow.screen(), SC.DONE)
		assert_eq(flow.take_effects(), [E.ENTER_BEDROOM] as Array[OpeningFlow.Effect])
		assert_true(flow.autosave_allowed(), "statut %d" % status)


func test_commit_failed_enters_bedroom_without_saving() -> void:
	var flow := _flow(S.VALID)
	_to_intro(flow)
	flow.handle(A.INTRO_FINISHED)
	flow.take_effects()
	assert_true(flow.handle(A.COMMIT_FAILED))
	assert_eq(flow.screen(), SC.DONE)
	assert_eq(flow.take_effects(),
		[E.ENTER_BEDROOM, E.WARN_UNSAVED] as Array[OpeningFlow.Effect])
	assert_false(flow.writes_allowed())
	assert_false(flow.autosave_allowed(), "l'ancienne partie ne sera pas écrasée sans copie")


func test_newer_save_new_game_never_writes() -> void:
	var flow := _flow(S.NEWER)
	assert_false(flow.writes_allowed())
	_to_intro(flow)
	flow.handle(A.INTRO_FINISHED)
	assert_eq(flow.screen(), SC.DONE, "pas de commit")
	assert_eq(flow.take_effects(), [E.ENTER_BEDROOM] as Array[OpeningFlow.Effect])
	assert_false(flow.autosave_allowed(), "on joue sans écrire")


func test_commit_screen_accepts_only_commit_results() -> void:
	var flow := _flow(S.NONE)
	_to_intro(flow)
	flow.handle(A.INTRO_FINISHED)
	for action: OpeningFlow.Action in ALL_ACTIONS:
		if action != A.COMMIT_SUCCEEDED and action != A.COMMIT_FAILED:
			assert_false(flow.handle(action), "action %d" % action)
	assert_eq(flow.screen(), SC.COMMIT)


func test_done_and_continue_are_terminal() -> void:
	var done := _flow(S.NONE)
	_to_intro(done)
	done.handle(A.INTRO_FINISHED)
	done.handle(A.COMMIT_SUCCEEDED)
	var resumed := _flow(S.VALID)
	resumed.handle(A.CONTINUE)
	for flow: OpeningFlow in [done, resumed]:
		var screen := flow.screen()
		flow.take_effects()
		for action: OpeningFlow.Action in ALL_ACTIONS:
			assert_false(flow.handle(action), "action %d" % action)
		assert_eq(flow.screen(), screen)
		assert_eq(flow.take_effects().size(), 0)


func test_refused_action_adds_no_effect() -> void:
	var flow := _flow(S.NONE)
	flow.handle(A.CONTINUE)
	flow.handle(A.INTRO_FINISHED)
	flow.handle(A.COMMIT_SUCCEEDED)
	assert_eq(flow.take_effects().size(), 0)
	assert_eq(flow.screen(), SC.TITLE)


func test_take_effects_empties_the_queue() -> void:
	var flow := _flow(S.VALID)
	flow.handle(A.CONTINUE)
	assert_eq(flow.take_effects().size(), 1)
	assert_eq(flow.take_effects().size(), 0)


func test_autosave_forbidden_everywhere_before_done() -> void:
	var flow := _flow(S.VALID)
	var seen: Array[OpeningFlow.Screen] = []
	seen.append(flow.screen())
	assert_false(flow.autosave_allowed())
	flow.handle(A.SETTINGS)
	seen.append(flow.screen())
	assert_false(flow.autosave_allowed())
	flow.handle(A.BACK)
	flow.handle(A.NEW_GAME)
	seen.append(flow.screen())
	assert_false(flow.autosave_allowed())
	flow.handle(A.CONFIRM)
	seen.append(flow.screen())
	assert_false(flow.autosave_allowed())
	flow.handle(A.INTRO_FINISHED)
	seen.append(flow.screen())
	assert_false(flow.autosave_allowed())
	assert_eq(seen, [SC.TITLE, SC.SETTINGS, SC.CONFIRM_OVERWRITE, SC.INTRO, SC.COMMIT])
