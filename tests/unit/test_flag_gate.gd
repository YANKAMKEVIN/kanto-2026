extends GutTest
## FlagGate (jalon-14.md §2.8) : décor affiché selon les drapeaux d'histoire, comme la présence
## d'un PNJ ; groupe « flag_gate ».


func _gate(if_flags: Array[StringName], unless_flags: Array[StringName]) -> FlagGate:
	var gate := FlagGate.new()
	gate.if_flags = if_flags
	gate.unless_flags = unless_flags
	autofree(gate)
	return gate


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func test_without_conditions_always_open() -> void:
	var gate := _gate([], [])
	assert_true(gate.is_open(null))
	assert_true(gate.is_open(_flags([&"x"])))


func test_if_flags_must_all_be_raised() -> void:
	var gate := _gate([&"bill_met"], [])
	assert_false(gate.is_open(null), "nouvelle partie : aucun drapeau")
	assert_false(gate.is_open(_flags([])))
	assert_true(gate.is_open(_flags([&"bill_met"])))
	var both := _gate([&"a", &"b"], [])
	assert_false(both.is_open(_flags([&"a"])))
	assert_true(both.is_open(_flags([&"a", &"b"])))


func test_unless_flags_close_the_gate() -> void:
	var gate := _gate([&"bill_met"], [&"bill_screen_checked"])
	assert_true(gate.is_open(_flags([&"bill_met"])))
	assert_false(gate.is_open(_flags([&"bill_met", &"bill_screen_checked"])))
	var only_unless := _gate([], [&"done"])
	assert_true(only_unless.is_open(null), "sans drapeau : ouvert")
	assert_false(only_unless.is_open(_flags([&"done"])))


func test_apply_sets_visibility() -> void:
	var gate := _gate([&"on"], [])
	gate.apply(_flags([]))
	assert_false(gate.visible)
	gate.apply(_flags([&"on"]))
	assert_true(gate.visible)


func test_gate_is_in_its_group() -> void:
	assert_true(_gate([], []).is_in_group(FlagGate.GROUP))
	assert_eq(FlagGate.GROUP, &"flag_gate")
