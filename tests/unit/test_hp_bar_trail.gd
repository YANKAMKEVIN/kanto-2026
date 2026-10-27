extends GutTest
## Trace des PV perdus (CV.3, CV-9) : le segment clair reste après la descente, puis rattrape.
## Les durées de la barre ne changent pas.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const HpBarScene := preload("res://game/ui/battle/hp_bar.tscn")

var _bar: HpBar


func before_each() -> void:
	_bar = HpBarScene.instantiate()
	add_child_autofree(_bar)
	_bar.set_hp(100, 100)


func _finished_after(big: bool) -> int:
	var done: Array[bool] = [false]
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await _bar.animate_hp(40, 100, big)
		done[0] = true
	runner.call()
	var steps := clock.run_until(func() -> bool: return done[0], 3.0)
	clock.release()
	return steps


func test_trail_stays_then_catches_up_to_the_final_value() -> void:
	var done: Array[bool] = [false]
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await _bar.animate_hp(40, 100)
		done[0] = true
	runner.call()
	clock.run_until(func() -> bool: return done[0], 3.0)
	assert_eq(_bar.get_shown_hp(), 40)
	assert_true(_bar.is_trail_shown(), "la trace reste derrière la barre")
	assert_gt(_bar.get_trail_value(), 40.0)
	for i: int in 12:  # 0,2 s : elle tient encore
		clock.step()
	assert_true(_bar.is_trail_shown())
	for i: int in 6:  # 0,3 s passées
		clock.step()
	clock.run_until(func() -> bool: return not _bar.is_trail_shown(), 1.0)
	clock.release()
	assert_false(_bar.is_trail_shown())
	assert_almost_eq(_bar.get_trail_value(), 40.0, 0.01)
	assert_almost_eq(_bar.get_shown_value(), 40.0, 0.01)


func test_durations_are_the_same_with_and_without_trail_in_steps() -> void:
	var normal := _finished_after(false)
	assert_between(normal, int(UiTokens.HP_TWEEN * 60.0) - 1, int(UiTokens.HP_TWEEN * 60.0) + 2)
	_bar.set_hp(100, 100)
	var fast := _finished_after(true)
	assert_between(fast, int(UiTokens.HP_TWEEN_FAST * 60.0) - 1,
		int(UiTokens.HP_TWEEN_FAST * 60.0) + 2)


func test_no_trail_at_speed_zero_or_when_healing() -> void:
	_bar.speed_scale = 0.0
	await _bar.animate_hp(30, 100)
	assert_eq(_bar.get_shown_hp(), 30)
	assert_false(_bar.is_trail_shown())
	_bar.speed_scale = 1.0
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _bar.animate_hp(80, 100)
		done[0] = true
	runner.call()
	clock.run_until(func() -> bool: return done[0], 3.0)
	clock.release()
	assert_eq(_bar.get_shown_hp(), 80)
	assert_false(_bar.is_trail_shown(), "pas de trace quand ça monte")


func test_set_hp_clears_the_trail() -> void:
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await _bar.animate_hp(10, 100)
	runner.call()
	clock.run_until(func() -> bool: return not _bar.is_animating(), 3.0)
	assert_true(_bar.is_trail_shown())
	_bar.set_hp(55, 100)
	clock.release()
	assert_false(_bar.is_trail_shown())
	assert_eq(_bar.get_trail_value(), 55.0)
