extends GutTest
## CutsceneDirector : étape « flash » (jalon-14.md §2.7) avec la vraie ExplorationHud ; la scène
## attend la fin des éclairs, signal flash_started (son de la machine). Ni carte ni joueur.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const HUD_SCENE := preload("res://game/ui/hud/exploration_hud.tscn")
const TIMEOUT := 6.0
const SCENES := {
	"machine": {"steps": [
		{"set": ["before"]}, {"flash": 2}, {"set": ["after"]},
	]},
}

var _director: CutsceneDirector
var _flags: StoryFlags


func before_each() -> void:
	Haptics.reset()
	Haptics.sink = func(_ms: int) -> void: pass
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)


func after_each() -> void:
	Haptics.reset()


func test_scene_waits_for_the_end_of_the_flashes() -> void:
	var hud := HUD_SCENE.instantiate() as ExplorationHud
	add_child_autofree(hud)
	_director.set_hud(hud)
	watch_signals(_director)
	var clock := TweenClock.new(get_tree())
	assert_true(_director.play(&"machine"))
	await wait_process_frames(2)
	assert_true(_flags.has_flag(&"before"))
	assert_signal_emitted_with_parameters(_director, "flash_started", [2])
	assert_true(hud.get_screen_flash().is_playing(), "éclairs en cours")
	assert_true(_director.is_running(), "la scène attend")
	assert_false(_flags.has_flag(&"after"))
	var steps := clock.run_until(func() -> bool: return not hud.get_screen_flash().is_playing())
	clock.release()
	assert_lte(steps, ceili(ScreenFlash.duration_of(2, false) * 60.0) + 2)
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)
	assert_true(_flags.has_flag(&"after"), "reprise après le dernier éclair")
	assert_push_error_count(0)


func test_flash_without_hud_is_skipped_with_error() -> void:
	watch_signals(_director)
	_director.play(&"machine")
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)
	assert_push_error("pas de HUD pour l'étape « flash »")
	assert_signal_not_emitted(_director, "flash_started")
	assert_true(_flags.has_flag(&"after"))
