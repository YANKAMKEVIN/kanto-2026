extends GutTest
## UiPrefs (Q-19) : taille du texte (Normale, Grande ≈ ×1,15) et contraste renforcé.


func before_each() -> void:
	UiPrefs.reset()


func after_each() -> void:
	UiPrefs.reset()


func test_defaults_leave_tokens_unchanged() -> void:
	assert_eq(UiPrefs.font(UiTokens.FONT_BODY), UiTokens.FONT_BODY)
	assert_eq(UiPrefs.panel_bg(), UiTokens.PANEL_BG)
	assert_eq(UiPrefs.text_muted(), UiTokens.TEXT_MUTED)


func test_large_text() -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	assert_true(UiPrefs.apply(settings))
	assert_eq(UiPrefs.text_scale, UiTokens.TEXT_SCALE_LARGE)
	assert_eq(UiPrefs.font(32), roundi(32 * UiTokens.TEXT_SCALE_LARGE))
	assert_gt(UiPrefs.font(UiTokens.FONT_BODY), UiTokens.FONT_BODY)


func test_high_contrast() -> void:
	var settings := GameSettings.new()
	settings.high_contrast = true
	UiPrefs.apply(settings)
	assert_almost_eq(UiPrefs.panel_bg().a, UiTokens.CONTRAST_PANEL_ALPHA, 0.001)
	assert_almost_eq(UiPrefs.panel_bg(UiTokens.MENU_PANEL_BG).a, UiTokens.CONTRAST_PANEL_ALPHA,
		0.001)
	var opaque := Color(0, 0, 0, 1)
	assert_eq(UiPrefs.panel_bg(opaque), opaque, "jamais moins opaque")
	assert_eq(UiPrefs.text_muted(), UiTokens.TEXT_MUTED_CONTRAST)
	assert_gt(UiPrefs.text_muted().get_luminance(), UiTokens.TEXT_MUTED.get_luminance())


func test_revision_changes_only_on_change() -> void:
	var start := UiPrefs.revision
	assert_false(UiPrefs.apply(GameSettings.new()), "déjà aux défauts")
	assert_eq(UiPrefs.revision, start)
	var settings := GameSettings.new()
	settings.high_contrast = true
	assert_true(UiPrefs.apply(settings))
	assert_eq(UiPrefs.revision, start + 1)
	assert_false(UiPrefs.apply(settings))
	assert_eq(UiPrefs.revision, start + 1)
