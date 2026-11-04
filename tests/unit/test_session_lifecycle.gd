extends GutTest
## Notifications et temps de jeu : aucun délai réel.


func test_play_time_is_capped_and_never_negative() -> void:
	var lifecycle := SessionLifecycle.new()
	assert_eq(lifecycle.play_time_step(0.1, false), 0.1)
	assert_eq(lifecycle.play_time_step(20.0, false), SessionLifecycle.MAX_PLAY_TIME_STEP)
	assert_eq(lifecycle.play_time_step(-1.0, false), 0.0)


func test_opening_does_not_count_play_time() -> void:
	assert_eq(SessionLifecycle.new().play_time_step(0.1, true), 0.0)


func test_focus_loss_stops_time_until_focus_returns() -> void:
	var lifecycle := SessionLifecycle.new()
	assert_false(lifecycle.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT))
	assert_eq(lifecycle.play_time_step(0.1, false), 0.0)
	assert_false(lifecycle.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN))
	assert_eq(lifecycle.play_time_step(0.1, false), 0.1)


func test_pause_requests_a_save_and_resume_restores_time() -> void:
	var lifecycle := SessionLifecycle.new()
	assert_true(lifecycle.handle_notification(Node.NOTIFICATION_APPLICATION_PAUSED))
	assert_eq(lifecycle.play_time_step(0.1, false), 0.0)
	assert_false(lifecycle.handle_notification(Node.NOTIFICATION_APPLICATION_RESUMED))
	assert_eq(lifecycle.play_time_step(0.1, false), 0.1)


func test_window_close_requests_a_save_without_changing_focus() -> void:
	var lifecycle := SessionLifecycle.new()
	assert_true(lifecycle.handle_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST))
	assert_true(lifecycle.in_foreground)
	assert_false(lifecycle.handle_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST))


func test_focus_changes_for_the_save_grace_delay() -> void:
	assert_eq(SessionLifecycle.focus_change(Node.NOTIFICATION_APPLICATION_FOCUS_OUT),
		SessionLifecycle.Focus.LOST)
	assert_eq(SessionLifecycle.focus_change(Node.NOTIFICATION_APPLICATION_FOCUS_IN),
		SessionLifecycle.Focus.REGAINED)
	assert_eq(SessionLifecycle.focus_change(Node.NOTIFICATION_APPLICATION_RESUMED),
		SessionLifecycle.Focus.REGAINED)
	assert_eq(SessionLifecycle.focus_change(Node.NOTIFICATION_APPLICATION_PAUSED),
		SessionLifecycle.Focus.NONE)


func test_a_memory_warning_requests_a_save_but_keeps_the_foreground() -> void:
	var lifecycle := SessionLifecycle.new()
	assert_true(lifecycle.handle_notification(Node.NOTIFICATION_OS_MEMORY_WARNING))
	assert_true(lifecycle.in_foreground, "le jeu reste au premier plan : le temps de jeu continue")
	assert_eq(lifecycle.play_time_step(0.1, false), 0.1)
	assert_eq(SessionLifecycle.audio_change(Node.NOTIFICATION_OS_MEMORY_WARNING),
		SessionLifecycle.AudioChange.NONE, "le son n'y touche pas")
	assert_eq(SessionLifecycle.focus_change(Node.NOTIFICATION_OS_MEMORY_WARNING),
		SessionLifecycle.Focus.NONE)


func test_save_reasons_name_the_notification() -> void:
	assert_eq(SessionLifecycle.save_reason(Node.NOTIFICATION_APPLICATION_PAUSED), "arrière-plan")
	assert_eq(SessionLifecycle.save_reason(Node.NOTIFICATION_WM_CLOSE_REQUEST), "fermeture")
	assert_eq(SessionLifecycle.save_reason(Node.NOTIFICATION_OS_MEMORY_WARNING), "mémoire basse")
