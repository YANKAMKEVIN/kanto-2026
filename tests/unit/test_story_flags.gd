extends GutTest
## StoryFlags : drapeaux d'histoire de la session (jalon 3 §2.6).

var _flags: StoryFlags


func before_each() -> void:
	_flags = StoryFlags.new()


func test_absent_flag_is_false() -> void:
	assert_false(_flags.has_flag(&"mom_greeted"))
	assert_eq(_flags.size(), 0)


func test_set_and_clear_a_flag() -> void:
	_flags.set_flag(&"mom_greeted")
	assert_true(_flags.has_flag(&"mom_greeted"))
	_flags.set_flag(&"mom_greeted", false)
	assert_false(_flags.has_flag(&"mom_greeted"))
	assert_eq(_flags.size(), 0)


func test_changed_is_emitted_only_on_a_real_change() -> void:
	watch_signals(_flags)
	_flags.set_flag(&"mom_greeted")
	_flags.set_flag(&"mom_greeted")
	assert_signal_emit_count(_flags, "flag_changed", 1)
	assert_signal_emitted_with_parameters(_flags, "flag_changed", [&"mom_greeted", true])
	_flags.set_flag(&"never_set", false)
	assert_signal_emit_count(_flags, "flag_changed", 1, "baisser un drapeau absent : rien")


func test_empty_name_is_ignored() -> void:
	_flags.set_flag(&"")
	assert_eq(_flags.size(), 0)


func test_has_all_and_has_none() -> void:
	_flags.set_flag(&"a")
	_flags.set_flag(&"b")
	var ab: Array[StringName] = [&"a", &"b"]
	var ac: Array[StringName] = [&"a", &"c"]
	var c: Array[StringName] = [&"c"]
	var empty: Array[StringName] = []
	assert_true(_flags.has_all(ab))
	assert_false(_flags.has_all(ac))
	assert_true(_flags.has_none(c))
	assert_false(_flags.has_none(ac))
	assert_true(_flags.has_all(empty), "liste vide : vrai")
	assert_true(_flags.has_none(empty), "liste vide : vrai")


func test_to_array_is_sorted_and_load_array_restores() -> void:
	_flags.set_flag(&"rival_met")
	_flags.set_flag(&"mom_greeted")
	var saved := _flags.to_array()
	assert_eq(saved, [&"mom_greeted", &"rival_met"] as Array[StringName])
	var other := StoryFlags.new()
	watch_signals(other)
	other.set_flag(&"stale")
	other.load_array(saved)
	assert_eq(other.to_array(), saved, "l'état est remplacé")
	assert_signal_emit_count(other, "flag_changed", 1, "load_array n'émet rien")


func test_clear_forgets_everything() -> void:
	_flags.set_flag(&"a")
	_flags.clear()
	assert_false(_flags.has_flag(&"a"))
