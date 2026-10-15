extends GutTest
## ScreenFlash (jalon-14.md §2.7) dans la vraie ExplorationHud, en temps simulé (TweenClock) :
## durée d'un éclair, deux éclairs, version réduite, vibrations, toucher non bloqué.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const HUD_SCENE := preload("res://game/ui/hud/exploration_hud.tscn")
const STEP := 1.0 / 60.0

var _hud: ExplorationHud
var _flash: ScreenFlash
var _vibrations: Array[int] = []


func before_each() -> void:
	_vibrations = []
	Haptics.reset()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)
	_hud = HUD_SCENE.instantiate() as ExplorationHud
	add_child_autofree(_hud)
	_flash = _hud.get_screen_flash()


func after_each() -> void:
	Haptics.reset()


## Lance hud.flash(count) en temps simulé ; rend [nombre de pas jusqu'à la fin, opacité
## maximale vue].
func _run(count: int) -> Array:
	var state := {"done": false, "peak": 0.0}
	var clock := TweenClock.new(get_tree())
	var play := func() -> void:
		await _hud.flash(count)
		state["done"] = true
	play.call()
	var steps := 0
	while not state["done"] and steps < 600:
		clock.step()
		steps += 1
		state["peak"] = maxf(state["peak"], _flash.get_alpha())
	clock.release()
	return [steps, state["peak"]]


func _steps_for(seconds: float) -> int:
	return ceili(seconds / STEP - 0.001)


func test_hidden_and_click_through_at_rest() -> void:
	assert_false(_flash.visible)
	assert_eq(_flash.get_alpha(), 0.0)
	assert_eq(_flash.mouse_filter, Control.MOUSE_FILTER_IGNORE, "toucher jamais bloqué")
	assert_eq(_flash.color, UiTokens.FLASH_COLOR)
	assert_lt(_hud.layer, UiTokens.LAYER_TRANSITION, "sous le rideau de transition")


func test_one_flash_lasts_point_four_seconds() -> void:
	assert_almost_eq(ScreenFlash.duration_of(1, false), 0.4, 0.0001)
	var result := _run(1)
	var expected := _steps_for(0.4)
	assert_gte(result[0], expected, "pas fini avant 0,4 s")
	assert_lte(result[0], expected + 1, "au plus un pas de plus")
	assert_almost_eq(result[1], UiTokens.FLASH_ALPHA, 0.01, "opacité 0,9 au plus fort")
	assert_eq(_flash.get_alpha(), 0.0)
	assert_false(_flash.visible)
	assert_eq(_vibrations, [UiTokens.HAPTIC_FLASH_MS] as Array[int])


func test_two_flashes_with_a_gap() -> void:
	assert_almost_eq(ScreenFlash.duration_of(2, false), 1.0, 0.0001)
	var result := _run(2)
	var expected := _steps_for(1.0)
	assert_gte(result[0], expected)
	assert_lte(result[0], expected + 2, "une image par enchaînement")
	assert_eq(_vibrations.size(), 2, "une vibration par éclair")


func test_flash_is_visible_while_playing() -> void:
	var clock := TweenClock.new(get_tree())
	_hud.flash(1)
	for i: int in _steps_for(UiTokens.FLASH_RISE) + 1:
		clock.step()
	assert_true(_flash.visible)
	assert_true(_flash.is_playing())
	assert_gt(_flash.get_alpha(), 0.8)
	clock.run_until(func() -> bool: return not _flash.is_playing(), 2.0)
	clock.release()
	assert_false(_flash.visible)


func test_reduced_flash_is_a_soft_fade() -> void:
	_hud.set_flash_reduced(true)
	assert_almost_eq(ScreenFlash.duration_of(1, true), 0.6, 0.0001)
	var result := _run(1)
	var expected := _steps_for(0.6)
	assert_gte(result[0], expected, "pas fini avant 0,6 s")
	assert_lte(result[0], expected + 2)
	assert_lte(result[1], UiTokens.FLASH_REDUCED_ALPHA + 0.001, "opacité ≤ 0,35")
	assert_gt(result[1], 0.3)
	assert_eq(_vibrations.size(), 1, "vibration légère gardée")


func test_haptics_off_means_no_vibration() -> void:
	Haptics.enabled = false
	_run(2)
	assert_eq(_vibrations.size(), 0)


func test_new_flash_replaces_the_current_one() -> void:
	var state := {"first": false}
	var clock := TweenClock.new(get_tree())
	var first := func() -> void:
		await _hud.flash(1)
		state["first"] = true
	first.call()
	clock.step()
	_hud.flash(1)
	assert_true(state["first"], "l'appel remplacé rend la main")
	assert_true(_flash.is_playing())
	clock.run_until(func() -> bool: return not _flash.is_playing(), 2.0)
	clock.release()
	assert_false(_flash.visible)
