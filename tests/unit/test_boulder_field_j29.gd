extends GutTest
## Rocher conditionnel de BoulderField (jalon 29 : rocher du 3F de la Route Victoire tombé au 2F,
## grille `si=`) : absent sans son drapeau, présent avec, remis à son origine à chaque entrée.


func test_conditional_boulder_needs_its_flag() -> void:
	var field := BoulderField.new()
	field.add_boulder(Vector2i(1, 1))
	field.add_boulder(Vector2i(3, 3), 0, &"fell_from_above")
	var flags := StoryFlags.new()
	assert_eq(field.boulders_at_load(flags), [Vector2i(1, 1)] as Array[Vector2i])
	flags.set_flag(&"fell_from_above")
	assert_eq(field.boulders_at_load(flags), [Vector2i(1, 1), Vector2i(3, 3)] as Array[Vector2i])


func test_from_positions_reads_si() -> void:
	var field := BoulderField.from_positions({
		"rocher_1": {"kind": "rocher", "cells": [Vector2i(2, 2)], "attrs": {"si": "f"}},
	})
	assert_true(field.boulders_at_load(StoryFlags.new()).is_empty())
	var flags := StoryFlags.new()
	flags.set_flag(&"f")
	assert_eq(field.boulders_at_load(flags), [Vector2i(2, 2)] as Array[Vector2i])


func test_setup_carries_the_condition() -> void:
	var setup := BoulderSetup.new()
	setup.boulder_cells = [Vector2i(0, 0), Vector2i(5, 5)] as Array[Vector2i]
	setup.boulder_holes = [0, 0] as Array[int]
	setup.boulder_requires = [&"", &"f"] as Array[StringName]
	var field := setup.to_field()
	setup.free()
	assert_eq(field.boulders_at_load(StoryFlags.new()), [Vector2i(0, 0)] as Array[Vector2i])
