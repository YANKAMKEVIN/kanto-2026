extends GutTest
## Motifs de vibration (jalon 5D, T14) : le « toc » de la Ball et le motif de la capture réussie,
## alternance vibration / pause, que le T15 joue au moment de l'événement.

var _played: Array[int] = []


func _spy(duration_ms: int) -> void:
	_played.append(duration_ms)


func before_each() -> void:
	_played.clear()


func test_pattern_tokens() -> void:
	assert_eq(UiTokens.HAPTIC_CAPTURE.size() % 2, 1, "finit par une vibration")
	assert_gt(UiTokens.HAPTIC_CAPTURE[-1], UiTokens.HAPTIC_CAPTURE[0], "le dernier « clic » est long")
	assert_gt(UiTokens.HAPTIC_BALL_SHAKE_MS, UiTokens.HAPTIC_TAP_MS, "plus marqué qu'un appui")


func test_ball_shake_vibrates_once() -> void:
	HapticPattern.ball_shake(_spy)
	assert_eq(_played, [UiTokens.HAPTIC_BALL_SHAKE_MS] as Array[int])


func test_capture_pattern_plays_only_the_vibrations_in_order() -> void:
	await HapticPattern.capture(get_tree(), _spy, 0.0)
	assert_eq(_played, [30, 30, 120] as Array[int], "les pauses ne vibrent pas")


func test_pauses_are_waited() -> void:
	HapticPattern.play(get_tree(), [10, 400, 10] as Array[int], _spy, 1.0)
	await wait_seconds(0.15)
	assert_eq(_played, [10] as Array[int], "la pause n'est pas finie")
	await wait_seconds(0.6)
	assert_eq(_played, [10, 10] as Array[int])


func test_empty_pattern_does_nothing() -> void:
	await HapticPattern.play(get_tree(), [] as Array[int], _spy, 0.0)
	assert_eq(_played.size(), 0)
