extends GutTest
## EventTrigger et TriggerTable : déclencheurs de scène posés sur une case, déclenchés par un
## pas terminé (jalon 3B §2.2), calqués sur les warps STEP_ON.

const CELL := Vector2i(23, 3)


func test_valid_trigger() -> void:
	var trigger := EventTrigger.new(CELL, Vector2i.ZERO, &"route1_grass")
	assert_true(trigger.is_valid())
	assert_eq(trigger.cell, CELL)
	assert_eq(trigger.cutscene_id, &"route1_grass")
	assert_true(EventTrigger.new(CELL, Vector2i.UP, &"x").is_valid())


func test_invalid_trigger() -> void:
	assert_false(EventTrigger.new(CELL, Vector2i.ZERO, &"").is_valid(), "sans scène")
	assert_false(EventTrigger.new(CELL, Vector2i(1, 1), &"x").is_valid(), "diagonale")
	assert_false(EventTrigger.new(CELL, Vector2i(0, 2), &"x").is_valid())


func test_matches_step_any_direction() -> void:
	var trigger := EventTrigger.new(CELL, Vector2i.ZERO, &"x")
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		assert_true(trigger.matches_step(CELL, direction), str(direction))
	assert_false(trigger.matches_step(CELL + Vector2i.UP, Vector2i.UP), "autre case")


func test_matches_step_with_direction() -> void:
	var trigger := EventTrigger.new(CELL, Vector2i.UP, &"x")
	assert_true(trigger.matches_step(CELL, Vector2i.UP))
	assert_false(trigger.matches_step(CELL, Vector2i.LEFT))
	assert_false(trigger.matches_step(CELL, Vector2i.DOWN))


func test_table_add_and_find() -> void:
	var table := TriggerTable.new()
	assert_true(table.is_empty())
	var a := EventTrigger.new(Vector2i(23, 3), Vector2i.ZERO, &"route1_grass")
	var b := EventTrigger.new(Vector2i(24, 3), Vector2i.ZERO, &"route1_grass")
	assert_true(table.add(a))
	assert_true(table.add(b))
	assert_eq(table.size(), 2)
	assert_eq(table.find_on_step(Vector2i(23, 3), Vector2i.UP), a)
	assert_eq(table.find_on_step(Vector2i(24, 3), Vector2i.RIGHT), b)
	assert_null(table.find_on_step(Vector2i(24, 4), Vector2i.UP))
	assert_eq(table.get_at(Vector2i(23, 3)), [a] as Array[EventTrigger])
	assert_true(table.get_at(Vector2i(0, 0)).is_empty())
	assert_eq(table.get_all().size(), 2)


func test_table_refuses_invalid_and_ambiguous_triggers() -> void:
	var table := TriggerTable.new()
	assert_false(table.add(null))
	assert_false(table.add(EventTrigger.new(CELL, Vector2i.ZERO, &"")))
	assert_true(table.add(EventTrigger.new(CELL, Vector2i.UP, &"a")))
	assert_false(table.add(EventTrigger.new(CELL, Vector2i.UP, &"b")), "même direction")
	assert_false(table.add(EventTrigger.new(CELL, Vector2i.ZERO, &"b")), "toutes directions")
	assert_true(table.add(EventTrigger.new(CELL, Vector2i.DOWN, &"b")), "autre direction")
	assert_eq(table.size(), 2)
	assert_eq(table.find_on_step(CELL, Vector2i.DOWN).cutscene_id, &"b")
	assert_null(table.find_on_step(CELL, Vector2i.LEFT))
	var any := TriggerTable.new()
	assert_true(any.add(EventTrigger.new(CELL, Vector2i.ZERO, &"a")))
	assert_false(any.add(EventTrigger.new(CELL, Vector2i.LEFT, &"b")), "recouvre « toutes »")
