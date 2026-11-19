extends GutTest
## Haptics (jalon-06.md §3.8) : porte unique des vibrations, coupée par le réglage ; aucun
## appel direct au moteur ailleurs dans game/.

var _played: Array[int] = []


func before_each() -> void:
	Haptics.reset()
	_played.clear()
	Haptics.sink = _spy


func after_each() -> void:
	Haptics.reset()


func _spy(duration_ms: int) -> void:
	_played.append(duration_ms)


func test_vibrate_reaches_the_sink() -> void:
	Haptics.vibrate(15)
	Haptics.vibrate(40)
	assert_eq(_played, [15, 40] as Array[int])


func test_disabled_means_no_vibration() -> void:
	Haptics.enabled = false
	Haptics.vibrate(15)
	assert_true(_played.is_empty())
	Haptics.enabled = true
	Haptics.vibrate(15)
	assert_eq(_played.size(), 1)


func test_zero_duration_does_nothing() -> void:
	Haptics.vibrate(0)
	Haptics.vibrate(-5)
	assert_true(_played.is_empty())


func test_reset_restores_defaults() -> void:
	Haptics.enabled = false
	Haptics.reset()
	assert_true(Haptics.enabled)
	assert_false(Haptics.sink.is_valid())


# --- Force (bible UI/UX §12) --------------------------------------------------------------

func test_amplitude_grows_with_the_family_of_the_vibration() -> void:
	var light := UiTokens.HAPTIC_AMPLITUDE_LIGHT
	var medium := UiTokens.HAPTIC_AMPLITUDE_MEDIUM
	var strong := UiTokens.HAPTIC_AMPLITUDE_STRONG
	assert_lt(light, medium)
	assert_lt(medium, strong)
	assert_between(light, 0.05, 1.0, "jamais nulle : une vibration permise se sent")
	assert_lte(strong, 1.0)
	for duration: int in [UiTokens.HAPTIC_TICK_MS, UiTokens.HAPTIC_TAP_MS,
			UiTokens.HAPTIC_MENU_MS, UiTokens.HAPTIC_STATUS_MS]:
		assert_eq(Haptics.amplitude_for(duration), light, "%d ms : légère" % duration)
	for duration: int in [UiTokens.HAPTIC_HIT_MS, UiTokens.HAPTIC_BIG_HIT_MS,
			UiTokens.HAPTIC_BALL_SHAKE_MS]:
		assert_eq(Haptics.amplitude_for(duration), medium, "%d ms : moyenne" % duration)
	assert_eq(Haptics.amplitude_for(UiTokens.HAPTIC_CRIT_MS), strong, "coup critique")
	assert_eq(Haptics.amplitude_for(UiTokens.HAPTIC_CAPTURE[-1]), strong, "fin de la capture")


func test_each_vibration_carries_its_amplitude() -> void:
	var amplitudes: Array[float] = []
	Haptics.amplitude_sink = func(amplitude: float) -> void: amplitudes.append(amplitude)
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	Haptics.vibrate(UiTokens.HAPTIC_CRIT_MS)
	assert_eq(amplitudes, [UiTokens.HAPTIC_AMPLITUDE_LIGHT, UiTokens.HAPTIC_AMPLITUDE_STRONG]
		as Array[float])
	assert_eq(_played, [UiTokens.HAPTIC_TICK_MS, UiTokens.HAPTIC_CRIT_MS] as Array[int],
		"la durée ne change pas")
	Haptics.enabled = false
	Haptics.vibrate(UiTokens.HAPTIC_CRIT_MS)
	assert_eq(amplitudes.size(), 2, "réglage coupé : rien")


func test_haptic_pattern_goes_through_haptics() -> void:
	HapticPattern.ball_shake()
	assert_eq(_played, [UiTokens.HAPTIC_BALL_SHAKE_MS] as Array[int])
	Haptics.enabled = false
	await HapticPattern.capture(get_tree(), Callable(), 0.0)
	assert_eq(_played.size(), 1, "motif de capture coupé avec le réglage")


func test_no_direct_engine_call_left_in_game() -> void:
	var offenders: Array[String] = []
	_scan("res://game", offenders)
	assert_eq(offenders, [] as Array[String],
		"Input.vibrate_handheld seulement dans game/systems/settings/haptics.gd")


func _scan(dir_path: String, offenders: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	assert_not_null(dir, dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_scan(dir_path.path_join(sub), offenders)
	for file: String in dir.get_files():
		if not file.ends_with(".gd"):
			continue
		var path := dir_path.path_join(file)
		if path == "res://game/systems/settings/haptics.gd":
			continue
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			if line.contains("Input.vibrate_handheld("):
				offenders.append(path)
				break
