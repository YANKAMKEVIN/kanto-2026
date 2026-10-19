extends GutTest
## BoulderRules (jalon 24, T9 ; dossier 27 §6.3, `jalon-24.md` §2.5) : poussée d'un rocher de
## Force (MOVED, FELL, REFUSED et ses raisons). Les cas reprennent ceux de
## `tools/art/plan_check_j24_seafoam.py` (b.), sur des rangées où le joueur est en x 1 et le
## rocher en x 2, poussé vers la droite.

const RIGHT := Vector2i.RIGHT

var _boulder := RefCounted.new()


## Une rangée : « . » sol bas, « : » sol haut, « = » escalier, « w » eau, « > » courant,
## « # » mur, « | » arête (solide), « n » panneau (solide), « B » rocher (sol bas, occupant),
## « U » échelle et « E » entrée (niveau ANY), « O » trou (sol bas), « v » rebord vers le bas.
func _row(text: String) -> GridWorld:
	var grid := GridWorld.new(Vector2i(text.length(), 1))
	for x: int in text.length():
		var cell := Vector2i(x, 0)
		match text[x]:
			".", "O":
				grid.set_level(cell, GridWorld.Level.LOW)
			"B":
				grid.set_level(cell, GridWorld.Level.LOW)
				grid.occupy(cell, _boulder if x == 2 else RefCounted.new())
			":":
				grid.set_level(cell, GridWorld.Level.HIGH)
			"=":
				grid.set_level(cell, GridWorld.Level.STAIRS)
			"w", ">":
				grid.set_surfable(cell)
				grid.set_level(cell, GridWorld.Level.LOW)
				if text[x] == ">":
					grid.set_current(cell, RIGHT)
			"#", "|", "n":
				grid.set_solid(cell)
			"v":
				grid.set_level(cell, GridWorld.Level.LOW)
				grid.set_ledge(cell, GridWorld.Ledge.DOWN)
	return grid


func _push(text: String, holes: Dictionary = {}, no_push: Dictionary = {}) -> BoulderRules.Push:
	return BoulderRules.push(_row(text), Vector2i(2, 0), RIGHT, holes, no_push)


func test_moves_onto_free_floor() -> void:
	var push := _push("#.B.#")
	assert_eq(push.outcome, BoulderRules.Outcome.MOVED)
	assert_eq(push.target, Vector2i(3, 0))
	assert_false(push.is_refused())


func test_refusals_of_the_dossier() -> void:
	var cases := {
		"#.B#": BoulderRules.Refusal.WALL, # mur
		"#.B|": BoulderRules.Refusal.WALL, # arête
		"#.Bn.": BoulderRules.Refusal.WALL, # panneau
		"#.B": BoulderRules.Refusal.WALL, # bord de la carte
		"#.Bw#": BoulderRules.Refusal.WATER, # eau
		"#.B>#": BoulderRules.Refusal.WATER, # courant
		"#.B=.": BoulderRules.Refusal.LEVEL, # escalier
		"#.BU.": BoulderRules.Refusal.LEVEL, # échelle (niveau ANY)
		"#.BE.": BoulderRules.Refusal.LEVEL, # entrée (niveau ANY)
		"#.B:.": BoulderRules.Refusal.LEVEL, # changement de niveau
		"#.BB.": BoulderRules.Refusal.OCCUPIED, # autre rocher
		"#.Bv.": BoulderRules.Refusal.LEDGE, # rebord
		":.B..": BoulderRules.Refusal.NONE, # contrôle : un pas normal
	}
	for text: String in cases:
		var push := _push(text)
		var refusal: BoulderRules.Refusal = cases[text]
		if refusal == BoulderRules.Refusal.NONE:
			assert_eq(push.outcome, BoulderRules.Outcome.MOVED, text)
		else:
			assert_eq(push.outcome, BoulderRules.Outcome.REFUSED, text)
			assert_eq(push.refusal, refusal, text)


func test_hidden_item_cell_is_refused() -> void:
	var push := _push("#.B..", {}, {Vector2i(3, 0): true})
	assert_eq(push.refusal, BoulderRules.Refusal.NO_PUSH)


func test_occupant_like_articuno_or_npc_is_refused() -> void:
	var grid := _row("#.B:.")
	grid.set_level(Vector2i(3, 0), GridWorld.Level.LOW)
	grid.occupy(Vector2i(3, 0), RefCounted.new())
	assert_eq(BoulderRules.push(grid, Vector2i(2, 0), RIGHT).refusal,
		BoulderRules.Refusal.OCCUPIED)


func test_falls_into_an_open_hole() -> void:
	var push := _push("#.BO.", {Vector2i(3, 0): 1})
	assert_eq(push.outcome, BoulderRules.Outcome.FELL)
	assert_eq(push.hole, 1)
	assert_eq(push.target, Vector2i(3, 0))


func test_plugged_hole_is_floor() -> void:
	assert_eq(_push("#.BO.").outcome, BoulderRules.Outcome.MOVED)


func test_pusher_rules() -> void:
	assert_eq(_push(":.B..").outcome, BoulderRules.Outcome.MOVED)
	var grid := _row("..B..")
	grid.set_level(Vector2i(1, 0), GridWorld.Level.HIGH)
	assert_eq(BoulderRules.push(grid, Vector2i(2, 0), RIGHT).refusal,
		BoulderRules.Refusal.PUSHER, "joueur sur le sol haut, rocher sur le sol bas")
	grid.set_level(Vector2i(1, 0), GridWorld.Level.STAIRS)
	assert_eq(BoulderRules.push(grid, Vector2i(2, 0), RIGHT).outcome,
		BoulderRules.Outcome.MOVED, "joueur sur un escalier")
	grid.set_surfable(Vector2i(1, 0))
	assert_eq(BoulderRules.push(grid, Vector2i(2, 0), RIGHT).refusal,
		BoulderRules.Refusal.PUSHER, "joueur dans l'eau")
	assert_eq(BoulderRules.push(grid, Vector2i(2, 0), Vector2i(1, 1)).refusal,
		BoulderRules.Refusal.BAD_DIRECTION)


func test_map_without_levels_pushes_freely() -> void:
	# Parmanie (rocher du Gardien) : aucune donnée de niveau, tout est ANY.
	var grid := GridWorld.new(Vector2i(5, 1))
	grid.occupy(Vector2i(2, 0), _boulder)
	var push := BoulderRules.push(grid, Vector2i(2, 0), RIGHT)
	assert_eq(push.outcome, BoulderRules.Outcome.MOVED)
	assert_true(grid.move_occupant(_boulder, Vector2i(2, 0), push.target), "l'appelant déplace")
	assert_eq(grid.get_occupant(Vector2i(3, 0)), _boulder)


func test_push_does_not_modify_the_grid() -> void:
	var grid := _row("#.BO.")
	BoulderRules.push(grid, Vector2i(2, 0), RIGHT, {Vector2i(3, 0): 1})
	assert_eq(grid.get_occupant(Vector2i(2, 0)), _boulder)
	assert_false(grid.is_occupied(Vector2i(3, 0)))
