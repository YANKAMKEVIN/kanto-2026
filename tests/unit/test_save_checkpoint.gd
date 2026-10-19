extends GutTest
## SaveCheckpoint (passe systèmes 2, `systemes-2.md` §2.12) : point de reprise, révisions,
## décision à la mise en arrière-plan, délai de garde de `FOCUS_OUT`. Le branchement dans
## `Boot` (avec `MemoryFs`) viendra après la fusion du J20.

const D := SaveCheckpoint.Decision

var _cp: SaveCheckpoint


func before_each() -> void:
	_cp = SaveCheckpoint.new()


func test_nothing_to_write_without_checkpoint() -> void:
	assert_false(_cp.is_newer_than_disk())
	assert_eq(_cp.decide(false, 100.0), D.NOTHING)
	assert_eq(_cp.get_snapshot(), {})


func test_stable_game_writes_the_current_state() -> void:
	assert_eq(_cp.decide(true, 100.0), D.WRITE_CURRENT)


func test_pause_during_a_dialogue_writes_the_checkpoint() -> void:
	_cp.note_written({"map": "a"}, 10.0)
	_cp.capture({"map": "b"})
	assert_true(_cp.is_newer_than_disk())
	assert_eq(_cp.decide(false, 20.0), D.WRITE_CHECKPOINT)
	assert_eq(_cp.get_snapshot(), {"map": "b"})


func test_an_immediate_write_during_the_scene_overtakes_the_checkpoint() -> void:
	_cp.capture({"map": "b", "gift": false})
	_cp.note_written({"map": "b", "gift": true}, 30.0)
	assert_false(_cp.is_newer_than_disk(), "jamais un point de reprise plus ancien que le disque")
	assert_eq(_cp.decide(false, 40.0), D.NOTHING)
	assert_eq(_cp.get_snapshot(), {"map": "b", "gift": true})


func test_checkpoint_is_a_frozen_copy() -> void:
	var state := {"party": [1, 2]}
	_cp.capture(state)
	(state["party"] as Array).append(3)
	assert_eq(_cp.get_snapshot(), {"party": [1, 2]})
	var copy := _cp.get_snapshot()
	(copy["party"] as Array).clear()
	assert_eq(_cp.get_snapshot(), {"party": [1, 2]})


func test_never_two_writes_within_two_seconds() -> void:
	_cp.note_written({"map": "a"}, 50.0)
	_cp.capture({"map": "b"})
	assert_eq(_cp.decide(false, 51.9), D.NOTHING)
	assert_eq(_cp.decide(true, 51.9), D.NOTHING)
	assert_eq(_cp.decide(false, 52.0), D.WRITE_CHECKPOINT)


func test_capture_after_capture_keeps_the_latest() -> void:
	_cp.capture({"map": "b"})
	_cp.capture({"map": "c"})
	assert_eq(_cp.get_snapshot(), {"map": "c"})
	assert_true(_cp.is_newer_than_disk())


func test_focus_out_then_in_within_a_second_does_nothing() -> void:
	_cp.focus_out(10.0)
	assert_false(_cp.focus_due(10.5))
	_cp.focus_in()
	assert_false(_cp.focus_due(12.0))


func test_focus_out_is_due_once_after_the_grace_delay() -> void:
	_cp.focus_out(10.0)
	_cp.focus_out(10.8)
	assert_false(_cp.focus_due(10.9), "un second FOCUS_OUT ne repousse pas le délai")
	assert_true(_cp.focus_due(11.0))
	assert_false(_cp.focus_due(12.0), "une seule fois")
