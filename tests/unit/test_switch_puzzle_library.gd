extends GutTest
## Règles des puzzles d'interrupteurs (jalon 16, `jalon-16.md` §2.6) et objets à fouiller
## ([InteractPoint] → [Interaction] : `puzzle`, `puzzle_slot`).

const RULE := {
	"columns": 5, "rows": 3, "solved_flag": "gym_solved", "nothing": "trash",
	"first": "first", "reset": "reset", "solved_cutscene": "open",
}


func test_rule_is_read() -> void:
	var library := SwitchPuzzleLibrary.new()
	assert_true(library.add_from_dict({"_doc": "x", "gym": RULE}, "test"))
	var spec := library.get_spec(&"gym")
	assert_eq([spec.columns, spec.rows, spec.solved_flag], [5, 3, &"gym_solved"])
	assert_eq(spec.dialogue_for(SwitchPuzzle.Result.NOTHING), &"trash")
	assert_eq(spec.dialogue_for(SwitchPuzzle.Result.FIRST_FOUND), &"first")
	assert_eq(spec.dialogue_for(SwitchPuzzle.Result.RESET), &"reset")
	assert_eq(spec.dialogue_for(SwitchPuzzle.Result.SOLVED), &"", "la scène parle")
	assert_eq(library.get_ids(), [&"gym"] as Array[StringName])


func test_bad_rules_are_refused() -> void:
	var bad: Array[Dictionary] = []
	for key: String in ["columns", "nothing", "solved_cutscene"]:
		var rule := RULE.duplicate()
		rule.erase(key)
		bad.append(rule)
	var zero := RULE.duplicate()
	zero["rows"] = 0
	bad.append(zero)
	var unknown := RULE.duplicate()
	unknown["extra"] = 1
	bad.append(unknown)
	for rule: Dictionary in bad:
		var library := SwitchPuzzleLibrary.new()
		assert_false(library.add_from_dict({"gym": rule}, "test"), str(rule))
		assert_false(library.has_puzzle(&"gym"))
	assert_push_error_count(bad.size())


func test_shipped_file_loads() -> void:
	var library := SwitchPuzzleLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))


func test_interact_point_copies_its_puzzle_slot() -> void:
	var point: InteractPoint = autofree(InteractPoint.new())
	point.dialogue_id = &"trash"
	point.puzzle = &"gym"
	point.puzzle_slot = 7
	var interaction := point.to_interactions()[0]
	assert_true(interaction.is_puzzle_slot())
	assert_eq([interaction.puzzle, interaction.puzzle_slot], [&"gym", 7])
	var plain: InteractPoint = autofree(InteractPoint.new())
	plain.dialogue_id = &"sign"
	assert_false(plain.to_interactions()[0].is_puzzle_slot())
