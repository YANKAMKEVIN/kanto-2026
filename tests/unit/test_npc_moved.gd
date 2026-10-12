extends GutTest
## Clé « moved » d'une entrée de PNJ (jalon-14.md §2.8 : le Rocket qui attend au fond de
## l'impasse) : lecture par NpcRoster, refus, et NpcSpec.placed_for.

const ROCKET := {
	"cell": [13, 2], "facing": "up", "sprite": "sbire_h",
	"unless": ["cerulean_rocket_beaten"],
	"moved": {"if": ["cerulean_rocket_spotted"], "cell": [21, 3], "facing": "left"},
}


func _parse(entry: Dictionary) -> Array:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry(entry, errors)
	return [spec, errors]


func _with(changes: Dictionary) -> Dictionary:
	var entry := ROCKET.duplicate(true)
	for key: Variant in changes:
		if changes[key] == null:
			entry.erase(key)
		else:
			entry[key] = changes[key]
	return entry


func _moved(changes: Dictionary) -> Dictionary:
	var block: Dictionary = (ROCKET["moved"] as Dictionary).duplicate(true)
	for key: Variant in changes:
		if changes[key] == null:
			block.erase(key)
		else:
			block[key] = changes[key]
	return _with({"moved": block})


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func test_moved_is_read() -> void:
	var result := _parse(ROCKET)
	var spec: NpcSpec = result[0]
	assert_eq((result[1] as PackedStringArray).size(), 0, str(result[1]))
	assert_not_null(spec)
	assert_true(spec.has_moved_place())
	assert_eq(spec.moved_cell, Vector2i(21, 3))
	assert_eq(spec.moved_facing, Vector2i.LEFT)
	assert_eq(spec.moved_if_flags, [&"cerulean_rocket_spotted"] as Array[StringName])
	assert_eq(spec.cell, Vector2i(13, 2), "la case de départ ne change pas")


func test_entry_without_moved_has_no_other_place() -> void:
	var spec: NpcSpec = _parse(_with({"moved": null}))[0]
	assert_false(spec.has_moved_place())
	assert_same(spec.placed_for(_flags([&"cerulean_rocket_spotted"])), spec)


func test_facing_defaults_to_the_entry_facing() -> void:
	var spec: NpcSpec = _parse(_moved({"facing": null}))[0]
	assert_eq(spec.moved_facing, Vector2i.UP)


func test_unless_alone_is_accepted() -> void:
	var spec: NpcSpec = _parse(_moved({"if": null, "unless": ["calm"]}))[0]
	assert_not_null(spec)
	assert_eq(spec.moved_unless_flags, [&"calm"] as Array[StringName])


func test_invalid_moved_blocks_are_refused() -> void:
	var cases: Array[Array] = [
		[_with({"moved": "here"}), "doit être"],
		[_moved({"if": null}), "exige « if » ou « unless »"],
		[_moved({"cell": null}), "« moved.cell »"],
		[_moved({"cell": [13, 2]}), "est déjà « cell »"],
		[_moved({"cell": [-1, 3]}), "« moved.cell »"],
		[_moved({"facing": "north"}), "« moved.facing »"],
		[_moved({"if": []}), "liste non vide"],
		[_moved({"speed": 2}), "clé inconnue « speed »"],
	]
	for case: Array in cases:
		var result := _parse(case[0])
		assert_null(result[0], "refusé : %s" % case[1])
		assert_string_contains(", ".join(result[1] as PackedStringArray), case[1])


func test_moved_refused_with_trainer_and_route() -> void:
	var trainer := _with({"dialogue": "after",
		"trainer": {"id": "x", "sight": 3, "before": "before"}})
	var result := _parse(trainer)
	assert_null(result[0])
	assert_string_contains(", ".join(result[1] as PackedStringArray),
		"« moved » interdit avec « trainer »")
	var route := _with({"route": {"cells": [[13, 2], [14, 2]]}})
	result = _parse(route)
	assert_null(result[0])
	assert_string_contains(", ".join(result[1] as PackedStringArray),
		"« moved » interdit avec « route »")


func test_placed_for_copies_to_the_moved_cell_when_flags_match() -> void:
	var spec: NpcSpec = _parse(_with({"dialogue": "rocket"}))[0]
	spec.id = &"cerulean_rocket"
	assert_same(spec.placed_for(null), spec, "nouvelle partie : place de départ")
	assert_same(spec.placed_for(_flags([])), spec)
	var placed := spec.placed_for(_flags([&"cerulean_rocket_spotted"]))
	assert_ne(placed, spec, "une copie")
	assert_eq(placed.cell, Vector2i(21, 3))
	assert_eq(placed.facing, Vector2i.LEFT)
	assert_eq(placed.id, &"cerulean_rocket")
	assert_eq(placed.sprite, &"sbire_h")
	assert_eq(placed.dialogue, &"rocket")
	assert_eq(placed.unless_flags, [&"cerulean_rocket_beaten"] as Array[StringName])
	assert_false(placed.has_moved_place(), "la copie n'a plus d'autre place")
	assert_eq(spec.cell, Vector2i(13, 2), "l'original ne change pas")
	assert_true(spec.has_moved_place())


func test_roster_reads_moved_from_a_file_object() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({"cerulean_rocket": ROCKET}, "test"))
	var spec := roster.get_spec(&"cerulean_rocket")
	assert_eq(spec.placed_for(_flags([&"cerulean_rocket_spotted"])).cell, Vector2i(21, 3))


func test_spawn_step_refuses_moved() -> void:
	var library := CutsceneLibrary.new()
	var ok := library.add_from_dict({"s": {"steps": [
		{"spawn": "x", "sprite": "oak", "cell": [1, 1],
			"moved": {"if": ["a"], "cell": [2, 2]}},
	]}}, "test")
	assert_false(ok)
	assert_push_error("« moved » n'a pas de sens dans une étape")
