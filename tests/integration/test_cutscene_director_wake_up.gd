extends GutTest
## CutsceneDirector : étape « wake_up » (jalon-07.md §3.8, T25). Elle attend
## [method DefeatRecovery.recover] (réveil au point de repos) puis **arrête la scène** : les
## étapes suivantes ne sont pas jouées. Sans réveil branché : push_error, la scène s'arrête quand
## même. Une étape « wake_up » conditionnelle non remplie est sautée et la scène continue.
## Ni carte ni joueur : un faux réveil compte les appels.

const TIMEOUT := 6.0
const SCENES := {
	"lost": {"steps": [
		{"set": ["before"]}, {"wake_up": true}, {"set": ["after"]},
	]},
	"won": {"steps": [
		{"set": ["before"]}, {"wake_up": true, "if": ["lost"]}, {"set": ["after"]},
	]},
}


## Faux réveil : compte les appels et dure deux images (comme le fondu du routeur).
class FakeRecovery:
	extends DefeatRecovery
	var calls: int = 0

	func recover() -> void:
		calls += 1
		await get_tree().process_frame
		await get_tree().process_frame
		woke_up.emit(&"player_house_1f")


var _director: CutsceneDirector
var _flags: StoryFlags


func before_each() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)


func _await_scene_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func test_wake_up_calls_the_recovery_then_ends_the_scene() -> void:
	var recovery := FakeRecovery.new()
	add_child_autofree(recovery)
	_director.set_recovery(recovery)
	watch_signals(_director)
	watch_signals(recovery)
	assert_true(_director.play(&"lost"))
	await wait_process_frames(1)
	assert_true(_director.is_running(), "la scène attend le réveil")
	await _await_scene_end()
	assert_eq(recovery.calls, 1, "un seul réveil")
	assert_signal_emitted(recovery, "woke_up")
	assert_true(_flags.has_flag(&"before"))
	assert_false(_flags.has_flag(&"after"), "la scène s'arrête au réveil")
	assert_signal_emitted_with_parameters(_director, "cutscene_finished", [&"lost"])
	assert_push_error_count(0)


func test_unmet_wake_up_is_skipped_and_the_scene_goes_on() -> void:
	var recovery := FakeRecovery.new()
	add_child_autofree(recovery)
	_director.set_recovery(recovery)
	_director.play(&"won")
	await _await_scene_end()
	assert_eq(recovery.calls, 0)
	assert_true(_flags.has_flag(&"after"))


func test_wake_up_without_recovery_is_an_error_and_still_ends_the_scene() -> void:
	_director.play(&"lost")
	await _await_scene_end()
	assert_push_error("pas de réveil branché")
	assert_false(_flags.has_flag(&"after"))
