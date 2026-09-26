extends GutTest
## Warp et WarpTable : déclenchement par pas ou par poussée, orientation d'arrivée,
## validité des données, conflits.

const DOOR := Vector2i(36, 9)
const MAT := Vector2i(5, 7)
const STAIRS := Vector2i(9, 2)


func _door() -> Warp:
	return Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"player_house_1f", &"entrance")


func _mat() -> Warp:
	return Warp.new(MAT, Warp.Trigger.PUSH, Vector2i.DOWN, &"pallet_town", &"player_house_door")


func _stairs() -> Warp:
	return Warp.new(STAIRS, Warp.Trigger.STEP_ON, Vector2i.ZERO, &"player_house_2f", &"stairs")


# --- Warp -------------------------------------------------------------------------

func test_step_on_with_required_direction() -> void:
	var door := _door()
	assert_true(door.matches_step(DOOR, Vector2i.UP))
	assert_false(door.matches_step(DOOR, Vector2i.LEFT), "mauvaise direction")
	assert_false(door.matches_step(DOOR + Vector2i.DOWN, Vector2i.UP), "autre case")
	assert_false(door.matches_push(DOOR, Vector2i.UP), "une porte ne se pousse pas")


func test_step_on_any_direction() -> void:
	var stairs := _stairs()
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		assert_true(stairs.matches_step(STAIRS, direction), str(direction))


func test_push_only_in_its_direction() -> void:
	var mat := _mat()
	assert_true(mat.matches_push(MAT, Vector2i.DOWN))
	assert_false(mat.matches_push(MAT, Vector2i.LEFT))
	assert_false(mat.matches_push(MAT + Vector2i.UP, Vector2i.DOWN))
	assert_false(mat.matches_step(MAT, Vector2i.DOWN), "marcher sur le tapis ne sort pas")


func test_arrival_facing_kept_or_forced() -> void:
	assert_eq(_door().get_arrival_facing(Vector2i.UP), Vector2i.UP)
	var forced := Warp.new(STAIRS, Warp.Trigger.STEP_ON, Vector2i.ZERO, &"m", &"s",
		Vector2i.LEFT)
	assert_eq(forced.get_arrival_facing(Vector2i.UP), Vector2i.LEFT)


func test_validity() -> void:
	assert_true(_door().is_valid())
	assert_true(_mat().is_valid())
	assert_true(_stairs().is_valid())
	assert_false(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"", &"s").is_valid(),
		"carte cible vide")
	assert_false(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"m", &"").is_valid(),
		"spawn cible vide")
	assert_false(Warp.new(MAT, Warp.Trigger.PUSH, Vector2i.ZERO, &"m", &"s").is_valid(),
		"une poussée exige une direction")
	assert_false(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i(1, 1), &"m", &"s").is_valid(),
		"diagonale")
	assert_false(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"m", &"s",
		Vector2i(2, 0)).is_valid(), "orientation d'arrivée non cardinale")


# --- WarpTable --------------------------------------------------------------------

func test_empty_table_finds_nothing() -> void:
	var table := WarpTable.new()
	assert_true(table.is_empty())
	assert_null(table.find_on_step(DOOR, Vector2i.UP))
	assert_null(table.find_on_push(MAT, Vector2i.DOWN))


func test_table_finds_each_warp_by_its_trigger() -> void:
	var table := WarpTable.new()
	var door := _door()
	var mat := _mat()
	var stairs := _stairs()
	assert_true(table.add(door))
	assert_true(table.add(mat))
	assert_true(table.add(stairs))
	assert_eq(table.size(), 3)
	assert_eq(table.find_on_step(DOOR, Vector2i.UP), door)
	assert_null(table.find_on_step(DOOR, Vector2i.RIGHT))
	assert_eq(table.find_on_push(MAT, Vector2i.DOWN), mat)
	assert_null(table.find_on_step(MAT, Vector2i.DOWN))
	assert_eq(table.find_on_step(STAIRS, Vector2i.RIGHT), stairs)
	assert_null(table.find_on_push(STAIRS, Vector2i.RIGHT))
	assert_eq(table.get_at(MAT), [mat] as Array[Warp])
	assert_eq(table.get_all().size(), 3)


func test_table_refuses_invalid_and_conflicting_warps() -> void:
	var table := WarpTable.new()
	assert_false(table.add(null))
	assert_false(table.add(Warp.new(MAT, Warp.Trigger.PUSH, Vector2i.ZERO, &"m", &"s")))
	assert_true(table.add(_door()))
	assert_false(table.add(_door()), "même case, même direction")
	assert_false(table.add(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.ZERO, &"m", &"s")),
		"toute direction recouvre UP")
	assert_true(table.add(Warp.new(DOOR, Warp.Trigger.STEP_ON, Vector2i.LEFT, &"m", &"s")),
		"autre direction : pas de conflit")
	assert_true(table.add(Warp.new(DOOR, Warp.Trigger.PUSH, Vector2i.UP, &"m", &"s")),
		"autre déclenchement : pas de conflit")
	assert_false(table.add(Warp.new(DOOR, Warp.Trigger.PUSH, Vector2i.UP, &"n", &"t")))
	assert_eq(table.size(), 3)
