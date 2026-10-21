extends GutTest
## Mise en scène de Coupe (jalon 16, `jalon-16.md` §2.3) : case du Pokémon qui coupe, ordre des
## étapes (compagnon ou non, réduction), durée bornée ; reprise du suivi du compagnon
## ([method CompanionTrail.place_at]) ; capacité par laquelle commence une scène.


func _free_except(blocked: Array[Vector2i]) -> Callable:
	return func(cell: Vector2i) -> bool: return not blocked.has(cell)


func test_cell_right_then_left_then_behind() -> void:
	var player := Vector2i(49, 11)
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.UP, _free_except([])), Vector2i(50, 11),
		"à droite du regard (haut)")
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.UP, _free_except([Vector2i(50, 11)])),
		Vector2i(48, 11), "puis à gauche")
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.UP,
		_free_except([Vector2i(50, 11), Vector2i(48, 11)])), Vector2i(49, 12), "puis derrière")
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.UP,
		_free_except([Vector2i(50, 11), Vector2i(48, 11), Vector2i(49, 12)])),
		FieldMoveStage.NONE, "aucune")


func test_cell_follows_the_facing() -> void:
	var player := Vector2i(5, 5)
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.RIGHT, _free_except([])), Vector2i(5, 6))
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.DOWN, _free_except([])), Vector2i(4, 5))
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.LEFT, _free_except([])), Vector2i(5, 4))
	assert_eq(FieldMoveStage.pick_cell(player, Vector2i.ZERO, _free_except([])),
		FieldMoveStage.NONE)


func test_stages_order() -> void:
	var a := FieldMoveStage.APPEAR
	var s := FieldMoveStage.SLASH
	var c := FieldMoveStage.CLEAR
	var w := FieldMoveStage.WITHDRAW
	assert_eq(FieldMoveStage.stages(false, true, false), [a, s, c, w] as Array[StringName],
		"Pokémon de l'équipe : il rentre à la fin")
	assert_eq(FieldMoveStage.stages(false, true, true), [a, s, c] as Array[StringName],
		"compagnon : il reste dehors")
	assert_eq(FieldMoveStage.stages(false, false, false), [s, c] as Array[StringName],
		"aucun Pokémon montrable : l'effet seul")
	assert_eq(FieldMoveStage.stages(true, true, true), [c] as Array[StringName],
		"réduire les animations : le fondu seul")


func test_stages_without_obstacle_strength() -> void:
	var a := FieldMoveStage.APPEAR
	var w := FieldMoveStage.WITHDRAW
	assert_eq(FieldMoveStage.stages(false, true, false, false), [a, w] as Array[StringName],
		"Force : le Pokémon apparaît puis rentre, ni effet ni fondu")
	assert_eq(FieldMoveStage.stages(false, true, true, false), [a] as Array[StringName],
		"Force par le compagnon : il reste dehors")
	assert_eq(FieldMoveStage.stages(false, false, false, false), [] as Array[StringName])
	assert_eq(FieldMoveStage.stages(true, true, false, false), [] as Array[StringName],
		"réduire les animations : rien à montrer")
	var team := Companion.BURST * 2.0 + FieldMoveStage.HOLD_DURATION
	assert_lte(team, FieldMoveStage.MAX_DURATION)


func test_durations_stay_under_two_seconds() -> void:
	var team := Companion.BURST * 2.0 + FieldMoveStage.SLASH_DURATION + FieldMoveStage.CLEAR_FADE
	var companion := Grid.WALK_STEP_DURATION + FieldMoveStage.SLASH_DURATION \
		+ FieldMoveStage.CLEAR_FADE
	assert_lte(team, FieldMoveStage.MAX_DURATION)
	assert_lte(companion, FieldMoveStage.MAX_DURATION)
	assert_almost_eq(FieldMoveStage.REDUCED_FADE, 0.3, 0.0001, "réduite : fondu 0,3 s")


func test_trail_resumes_from_the_cutting_cell() -> void:
	var trail := CompanionTrail.new()
	trail.place_at(Vector2i(50, 11))
	assert_true(trail.is_placed())
	var step := trail.on_player_step(Vector2i(49, 11), Vector2i(49, 10), CompanionTrail.WALK)
	assert_false(step.appear)
	assert_eq([step.from_cell, step.to_cell], [Vector2i(50, 11), Vector2i(49, 11)])


func test_leading_field_move() -> void:
	var library := CutsceneLibrary.new()
	library.add_from_dict({
		"cut": {"variants": [{"unless": ["done"], "steps": [
			{"field_move": "cut", "on": "Tree"}, {"set": ["done"]}]}]},
		"talk": {"steps": [{"wait": 0.1}, {"field_move": "cut", "on": "Tree"}]},
		"skip": {"steps": [{"wait": 0.1, "if": ["never"]}, {"field_move": "cut", "on": "Tree"}]},
	}, "test")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var flags := StoryFlags.new()
	assert_eq(library.get_cutscene(&"cut").leading_field_move(flags), &"cut")
	assert_eq(library.get_cutscene(&"talk").leading_field_move(flags), &"",
		"une autre étape d'abord")
	assert_eq(library.get_cutscene(&"skip").leading_field_move(flags), &"cut",
		"une étape sautée ne compte pas")
	flags.set_flag(&"done")
	assert_eq(library.get_cutscene(&"cut").leading_field_move(flags), &"", "aucune variante")
