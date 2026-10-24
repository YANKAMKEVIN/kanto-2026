extends GutTest
## BoulderField (passe systèmes 2, `systemes-2.md` §2.7.2, §2.7.4) : rochers d'origine, trous et
## interrupteurs par drapeaux, cases interdites ; puis les puzzles de la grille d'essai
## `tests/fixtures/plans/essai_force.txt` (ancienne grille de la carte de QA de la Force, retirée en
## S2Z) joués poussée par poussée.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const UP := Vector2i.UP
const LEFT := Vector2i.LEFT

var _plan: PlanGrid
var _field: BoulderField
var _flags: StoryFlags
var _grid: GridWorld
## Rocher → case actuelle (les occupants de la grille).
var _rocks: Dictionary[Object, Vector2i] = {}


func before_each() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file("res://tests/fixtures/plans/essai_force.txt"), _plan.error)
	_field = BoulderField.from_positions(_plan.positions)
	_flags = StoryFlags.new()
	_load_map()


## Entrée sur la carte : grille d'après les caractères, barrière fermée sans son drapeau, rochers
## à leur origine.
func _load_map() -> void:
	_grid = GridWorld.new(Vector2i(_plan.width, _plan.height))
	_rocks.clear()
	for y: int in _plan.height:
		for x: int in _plan.width:
			var cell := Vector2i(x, y)
			match _plan.at(cell):
				"#":
					_grid.set_solid(cell)
				"w":
					_grid.set_surfable(cell)
				"|":
					_grid.set_solid(cell, not _flags.has_flag(&"essai_force_switch_1"))
	for cell: Vector2i in _field.boulders_at_load(_flags):
		var rock := RefCounted.new()
		_grid.occupy(cell, rock)
		_rocks[rock] = cell


## Pousse le rocher de [param cell] vers [param direction] comme le joueur le fera (T18) ; rend
## le résultat.
func _push(cell: Vector2i, direction: Vector2i) -> BoulderRules.Push:
	var result := _field.push(_grid, cell, direction, _flags)
	var rock := _grid.get_occupant(cell)
	match result.outcome:
		BoulderRules.Outcome.MOVED, BoulderRules.Outcome.ON_SWITCH:
			_grid.move_occupant(rock, cell, result.target)
			_rocks[rock] = result.target
		BoulderRules.Outcome.FELL:
			_grid.release(cell, rock)
			_rocks.erase(rock)
	var flag := _field.flag_to_set(result, _flags)
	if flag != &"":
		_flags.set_flag(flag)
	return result


func test_built_from_the_grid_positions() -> void:
	assert_eq(_field.boulders_at_load(_flags).size(), 4)
	assert_eq(_field.open_holes(_flags), {Vector2i(4, 4): 1, Vector2i(8, 14): 2})
	assert_eq(_field.switch_cells(), {Vector2i(19, 4): &"interrupteur_1"})
	assert_eq(_field.hole_flag(1), &"essai_force_hole_1_filled")
	assert_eq(_field.switch_flag(&"interrupteur_1"), &"essai_force_switch_1")


func test_west_lane_rock_falls_into_its_hole_for_good() -> void:
	for i: int in 3:
		assert_eq(_push(Vector2i(4, 8 - i), UP).outcome, BoulderRules.Outcome.MOVED)
	var fell := _push(Vector2i(4, 5), UP)
	assert_eq(fell.outcome, BoulderRules.Outcome.FELL)
	assert_eq(fell.hole, 1)
	assert_true(_flags.has_flag(&"essai_force_hole_1_filled"), "drapeau du trou : sauvegarde forcée")
	assert_false(_field.open_holes(_flags).has(Vector2i(4, 4)), "le trou bouché est du sol")
	_load_map()
	assert_false(_field.boulders_at_load(_flags).has(Vector2i(4, 8)),
		"le rocher désigné reste dans le trou")
	assert_eq(_field.boulders_at_load(_flags).size(), 3)


func test_east_lane_rock_presses_the_switch_and_opens_the_barrier() -> void:
	for i: int in 3:
		assert_eq(_push(Vector2i(19, 8 - i), UP).outcome, BoulderRules.Outcome.MOVED)
	var on_switch := _push(Vector2i(19, 5), UP)
	assert_eq(on_switch.outcome, BoulderRules.Outcome.ON_SWITCH)
	assert_true(_flags.has_flag(&"essai_force_switch_1"))
	assert_true(_field.is_switch_pressed(Vector2i(19, 4), _flags))
	assert_eq(_field.flag_to_set(on_switch, _flags), &"", "déjà posé : pas de seconde sauvegarde")
	_load_map()
	assert_true(_field.boulders_at_load(_flags).has(Vector2i(19, 8)),
		"le rocher revient à son origine")
	assert_true(_field.is_switch_pressed(Vector2i(19, 4), _flags), "l'interrupteur reste enfoncé")
	assert_false(_grid.is_solid(Vector2i(11, 3)), "la barrière reste ouverte")


func test_forbidden_cell_and_water_refuse_the_rock() -> void:
	assert_eq(_push(Vector2i(12, 8), UP).outcome, BoulderRules.Outcome.MOVED)
	assert_eq(_push(Vector2i(12, 7), UP).outcome, BoulderRules.Outcome.MOVED)
	var forbidden := _push(Vector2i(12, 6), LEFT)
	assert_eq(forbidden.refusal, BoulderRules.Refusal.NO_PUSH, "case d'objet caché (11, 6)")
	assert_eq(_push(Vector2i(4, 12), LEFT).outcome, BoulderRules.Outcome.MOVED)
	assert_eq(_push(Vector2i(3, 12), LEFT).refusal, BoulderRules.Refusal.WATER)


func test_closed_barrier_refuses_the_rock() -> void:
	for i: int in 4:
		_push(Vector2i(12, 8 - i), UP)
	assert_eq(_push(Vector2i(12, 4), UP).refusal, BoulderRules.Refusal.WALL)


func test_no_flag_without_a_hole_or_switch() -> void:
	var moved := _push(Vector2i(12, 8), UP)
	assert_eq(_field.flag_to_set(moved, _flags), &"")
	assert_eq(_field.hole_flag(9), &"")
	assert_eq(_field.switch_flag(&"x"), &"")
