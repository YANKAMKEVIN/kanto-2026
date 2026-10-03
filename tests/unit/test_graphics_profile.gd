extends GutTest
## GraphicsProfile (Q-17) : Auto → Élevée sur un appareil puissant (S24), Économie sur un
## petit ; Économie = 30 images/s, flou du menu coupé, effets réduits.

const S24 := {"processors": 8, "memory_mb": 7600}
const SMALL_CPU := {"processors": 4, "memory_mb": 8000}
const SMALL_RAM := {"processors": 8, "memory_mb": 3000}


func test_auto_on_s24_is_high() -> void:
	var profile := GraphicsProfile.resolve(GameSettings.Graphics.AUTO, S24)
	assert_true(profile.auto)
	assert_eq(profile.quality, GameSettings.Graphics.HIGH)
	assert_eq(profile.max_fps, 0, "pas de limite : comme avant le J6")
	assert_true(profile.menu_blur)
	assert_false(profile.reduced_effects)


func test_auto_on_small_device_is_eco() -> void:
	assert_eq(GraphicsProfile.auto_quality(SMALL_CPU), GameSettings.Graphics.ECO)
	assert_eq(GraphicsProfile.auto_quality(SMALL_RAM), GameSettings.Graphics.ECO)
	var profile := GraphicsProfile.resolve(GameSettings.Graphics.AUTO, SMALL_RAM)
	assert_true(profile.auto)
	assert_eq(profile.quality, GameSettings.Graphics.ECO)


func test_unknown_device_is_high() -> void:
	assert_eq(GraphicsProfile.auto_quality({}), GameSettings.Graphics.HIGH)
	assert_eq(GraphicsProfile.auto_quality({"processors": 0, "memory_mb": 0}),
		GameSettings.Graphics.HIGH)


func test_eco_profile() -> void:
	var profile := GraphicsProfile.resolve(GameSettings.Graphics.ECO, S24)
	assert_false(profile.auto)
	assert_eq(profile.quality, GameSettings.Graphics.ECO)
	assert_eq(profile.max_fps, 30)
	assert_false(profile.menu_blur)
	assert_true(profile.reduced_effects)


func test_high_forced_on_small_device() -> void:
	var profile := GraphicsProfile.resolve(GameSettings.Graphics.HIGH, SMALL_CPU)
	assert_eq(profile.quality, GameSettings.Graphics.HIGH)
	assert_eq(profile.max_fps, 0)
	assert_true(profile.menu_blur)


func test_current_device_shape() -> void:
	var device := GraphicsProfile.current_device()
	assert_true(device.get("processors") is int)
	assert_true(device.get("memory_mb") is int)
	assert_gt(int(device["processors"]), 0)
