extends GutTest
## Dalles tournantes (jalon 20 T4, docs/tech/jalon-20.md §2.4.3, dossier 23 §13.3) : règle pure
## [SpinTileRules], trajet [SpinSlide], nœud de données [SpinTileField]. Cas synthétiques, puis
## **les grilles réelles** du repaire (`tools/plans/repaire_b2f.txt`, `repaire_b3f.txt`) rejouées
## contre les 59 trajets Rouge/Bleu recopiés dans leurs POSITIONS (`trajet=`, `arret=`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLANS_DIR := "res://tools/plans/"
## Grille → nombre de dalles de Rouge/Bleu (43 au B2F, 16 au B3F).
const RB_TILES: Dictionary[String, int] = {"repaire_b2f": 43, "repaire_b3f": 16}


## Monde synthétique : toute case de [param size] est praticable, sauf [param walls].
func _walkable(size: Vector2i, walls: Array[Vector2i] = []) -> Callable:
	return func(cell: Vector2i) -> bool:
		return Rect2i(Vector2i.ZERO, size).has_point(cell) and not walls.has(cell)


func _stops(cells: Array) -> Array[Vector2i]:
	var stops: Array[Vector2i] = []
	stops.assign(cells)
	return stops


func _load_plan(grid_name: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(PLANS_DIR + grid_name + ".txt"), plan.error)
	return plan


## Dalles et arrêts lus dans les caractères de la grille.
func _arrows_of(plan: PlanGrid) -> Dictionary:
	var arrows: Dictionary = {}
	for cell: Vector2i in plan.cells_of(SpinTileRules.ARROW_CHARS):
		arrows[cell] = SpinTileRules.direction_of_char(plan.at(cell))
	return arrows


## Praticable dans la grille et hors des positions bloquantes (objets, Dresseurs).
func _plan_walkable(plan: PlanGrid) -> Callable:
	var blocked := plan.blocking_cells()
	return func(cell: Vector2i) -> bool:
		return plan.is_walkable(cell) and not blocked.has(cell)


## « O4,S2,E1 » → une direction par pas.
func _expand(path: String) -> Array[Vector2i]:
	var facings: Array[Vector2i] = []
	for part: String in path.split(","):
		var direction := SpinTileRules.compass_direction(part.left(1))
		assert_ne(direction, Vector2i.ZERO, "lettre de trajet « %s »" % part)
		for i: int in int(part.substr(1)):
			facings.append(direction)
	return facings


func _cell_of(text: String) -> Vector2i:
	return Vector2i(int(text.get_slice(",", 0)), int(text.get_slice(",", 1)))


# --- Cas synthétiques -------------------------------------------------------------------

func test_straight_line_to_the_stop() -> void:
	var arrows := {Vector2i(1, 2): Vector2i.RIGHT}
	var slide := SpinTileRules.slide(Vector2i(1, 2), arrows, _stops([Vector2i(5, 2)]),
		_walkable(Vector2i(8, 5)))
	assert_eq(slide.status, SpinSlide.Status.OK)
	assert_eq(slide.cells, [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]
		as Array[Vector2i], "sans la dalle de départ")
	assert_eq(slide.facings, [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT]
		as Array[Vector2i])
	assert_eq(slide.end, Vector2i(5, 2))
	assert_eq(slide.path_text(), "E4")


func test_an_arrow_on_the_way_turns_the_slide() -> void:
	var arrows := {Vector2i(0, 0): Vector2i.RIGHT, Vector2i(3, 0): Vector2i.DOWN}
	var slide := SpinTileRules.slide(Vector2i(0, 0), arrows, _stops([Vector2i(3, 2)]),
		_walkable(Vector2i(5, 5)))
	assert_eq(slide.status, SpinSlide.Status.OK)
	assert_eq(slide.path_text(), "E3,S2")
	assert_eq(slide.end, Vector2i(3, 2))
	assert_eq(slide.facings[2], Vector2i.RIGHT, "on entre sur la flèche dans l'ancien sens")
	assert_eq(slide.facings[3], Vector2i.DOWN, "puis on repart dans le sien")


func test_chain_of_arrows() -> void:
	var arrows := {
		Vector2i(0, 4): Vector2i.UP, Vector2i(0, 1): Vector2i.RIGHT,
		Vector2i(4, 1): Vector2i.DOWN, Vector2i(4, 3): Vector2i.LEFT,
	}
	var slide := SpinTileRules.slide(Vector2i(0, 4), arrows, _stops([Vector2i(2, 3)]),
		_walkable(Vector2i(6, 6)))
	assert_eq(slide.status, SpinSlide.Status.OK)
	assert_eq(slide.path_text(), "N3,E4,S2,O2")


func test_same_arrow_same_path() -> void:
	var arrows := {Vector2i(0, 0): Vector2i.RIGHT, Vector2i(2, 0): Vector2i.DOWN}
	var stops := _stops([Vector2i(2, 3)])
	var a := SpinTileRules.slide(Vector2i(0, 0), arrows, stops, _walkable(Vector2i(4, 4)))
	var b := SpinTileRules.slide(Vector2i(0, 0), arrows, stops, _walkable(Vector2i(4, 4)))
	assert_eq(a.cells, b.cells, "déterministe")
	assert_eq(a.facings, b.facings)


func test_start_must_be_an_arrow() -> void:
	var slide := SpinTileRules.slide(Vector2i(1, 1), {}, _stops([]), _walkable(Vector2i(3, 3)))
	assert_eq(slide.status, SpinSlide.Status.NOT_AN_ARROW)
	assert_eq(slide.size(), 0)
	assert_eq(slide.end, Vector2i(1, 1))
	assert_false(slide.is_sliding(), "pas de glisse : on peut sauver")


func test_wall_blocks_the_slide() -> void:
	var walls: Array[Vector2i] = [Vector2i(3, 0)]
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.RIGHT},
		_stops([Vector2i(5, 0)]), _walkable(Vector2i(6, 1), walls))
	assert_eq(slide.status, SpinSlide.Status.BLOCKED)
	assert_eq(slide.end, Vector2i(2, 0), "dernière case atteinte")
	assert_false(slide.is_ok())


func test_edge_of_the_map_blocks_the_slide() -> void:
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.LEFT},
		_stops([]), _walkable(Vector2i(3, 3)))
	assert_eq(slide.status, SpinSlide.Status.BLOCKED)
	assert_eq(slide.size(), 0)


func test_loop_is_detected() -> void:
	var arrows := {
		Vector2i(0, 0): Vector2i.RIGHT, Vector2i(2, 0): Vector2i.DOWN,
		Vector2i(2, 2): Vector2i.LEFT, Vector2i(0, 2): Vector2i.UP,
	}
	var slide := SpinTileRules.slide(Vector2i(0, 0), arrows, _stops([Vector2i(5, 5)]),
		_walkable(Vector2i(6, 6)))
	assert_eq(slide.status, SpinSlide.Status.LOOP)
	assert_eq(slide.size(), 8, "un tour complet, puis arrêt")


func test_max_steps_stops_a_too_long_slide() -> void:
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.RIGHT},
		_stops([Vector2i(9, 0)]), _walkable(Vector2i(10, 1)), 4)
	assert_eq(slide.status, SpinSlide.Status.TOO_LONG)
	assert_eq(slide.size(), 4)
	var ok := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.RIGHT},
		_stops([Vector2i(4, 0)]), _walkable(Vector2i(10, 1)), 4)
	assert_eq(ok.status, SpinSlide.Status.OK, "exactement la limite : permis")


func test_check_field_reports_each_bad_arrow() -> void:
	var walls: Array[Vector2i] = [Vector2i(3, 2)]
	var arrows := {
		Vector2i(0, 0): Vector2i.RIGHT, Vector2i(0, 2): Vector2i.RIGHT,
		Vector2i(0, 4): Vector2i(1, 1),
	}
	var errors := SpinTileRules.check_field(arrows, _stops([Vector2i(5, 0), Vector2i(5, 2)]),
		_walkable(Vector2i(6, 5), walls))
	assert_eq(errors.size(), 2, "\n".join(errors))
	assert_string_contains(errors[0] + errors[1], "BLOCKED")
	assert_string_contains(errors[0] + errors[1], "non cardinale")


func test_check_field_rejects_bad_stops() -> void:
	var walls: Array[Vector2i] = [Vector2i(4, 4)]
	var arrows := {Vector2i(0, 0): Vector2i.RIGHT}
	var errors := SpinTileRules.check_field(arrows, _stops([Vector2i(2, 0), Vector2i(4, 4)]),
		_walkable(Vector2i(6, 6), walls))
	assert_eq(errors.size(), 1, "\n".join(errors))
	assert_string_contains(errors[0], "arrêt (4, 4)")


func test_safe_cell() -> void:
	var arrows := {Vector2i(0, 0): Vector2i.RIGHT, Vector2i(0, 3): Vector2i.LEFT}
	var stops := _stops([Vector2i(3, 0)])
	var walkable := _walkable(Vector2i(5, 5))
	assert_eq(SpinTileRules.safe_cell(Vector2i(2, 2), arrows, stops, walkable), Vector2i(2, 2),
		"case ordinaire : elle-même")
	assert_eq(SpinTileRules.safe_cell(Vector2i(0, 0), arrows, stops, walkable), Vector2i(3, 0),
		"dalle : la fin de sa glisse")
	assert_eq(SpinTileRules.safe_cell(Vector2i(0, 3), arrows, stops, walkable), Vector2i(0, 3),
		"dalle en erreur : elle-même (jamais hors carte)")


func test_sliding_state_forbids_saving_until_the_last_step() -> void:
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.DOWN},
		_stops([Vector2i(0, 2)]), _walkable(Vector2i(3, 3)))
	assert_true(slide.is_sliding(), "en glisse dès que le trajet est calculé")
	assert_false(slide.can_save())
	assert_eq(slide.next_direction(), Vector2i.DOWN)
	assert_eq(slide.next_cell(), Vector2i(0, 1))
	slide.step_done()
	assert_true(slide.is_sliding(), "un pas reste")
	assert_false(slide.can_save())
	slide.step_done()
	assert_false(slide.is_sliding(), "fin de la glisse")
	assert_true(slide.can_save())
	assert_eq(slide.next_direction(), Vector2i.ZERO)
	assert_eq(slide.next_cell(), Vector2i(0, 2))
	slide.step_done()
	assert_eq(slide.steps_done, 2, "un pas de trop est ignoré")


func test_invalid_slide_is_never_sliding() -> void:
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.LEFT},
		_stops([]), _walkable(Vector2i(3, 3)))
	assert_false(slide.is_sliding())
	assert_true(slide.can_save())


func test_abort_stops_on_the_last_cell_reached() -> void:
	var slide := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.RIGHT},
		_stops([Vector2i(4, 0)]), _walkable(Vector2i(5, 1)))
	slide.step_done()
	slide.abort()
	assert_false(slide.is_sliding())
	assert_eq(slide.end, Vector2i(1, 0))
	assert_eq(slide.size(), 1)
	var early := SpinTileRules.slide(Vector2i(0, 0), {Vector2i(0, 0): Vector2i.RIGHT},
		_stops([Vector2i(4, 0)]), _walkable(Vector2i(5, 1)))
	early.abort()
	assert_eq(early.end, Vector2i(0, 0), "aucun pas joué : sur la dalle de départ")


func test_grid_characters_and_compass() -> void:
	assert_eq(SpinTileRules.direction_of_char("<"), Vector2i.LEFT)
	assert_eq(SpinTileRules.direction_of_char(">"), Vector2i.RIGHT)
	assert_eq(SpinTileRules.direction_of_char("^"), Vector2i.UP)
	assert_eq(SpinTileRules.direction_of_char("v"), Vector2i.DOWN)
	assert_eq(SpinTileRules.direction_of_char("o"), Vector2i.ZERO)
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		assert_eq(SpinTileRules.compass_direction(SpinTileRules.compass_letter(direction)),
			direction)
	assert_eq(SpinTileRules.compass_direction("X"), Vector2i.ZERO)


# --- Nœud de données ----------------------------------------------------------------------

func test_field_node_is_data_only() -> void:
	var field := SpinTileField.new()
	field.arrows = {Vector2i(0, 0): Vector2i.RIGHT}
	field.stops = [Vector2i(2, 0)]
	add_child_autofree(field)
	assert_true(field.is_in_group(SpinTileField.GROUP))
	assert_true(field.is_arrow(Vector2i(0, 0)))
	assert_false(field.is_arrow(Vector2i(1, 0)))
	var walkable := _walkable(Vector2i(3, 1))
	assert_eq(field.slide_from(Vector2i(0, 0), walkable).end, Vector2i(2, 0))
	assert_eq(field.safe_cell(Vector2i(0, 0), walkable), Vector2i(2, 0))
	assert_eq(field.check(walkable).size(), 0)
	assert_false(field.is_processing(), "aucun coût par image")


# --- Grilles réelles du repaire (Rouge/Bleu) ---------------------------------------------

func test_real_grids_replay_the_59_rb_paths() -> void:
	var total := 0
	for grid_name: String in RB_TILES:
		var plan := _load_plan(grid_name)
		var arrows := _arrows_of(plan)
		var stops := plan.cells_of(SpinTileRules.STOP_CHAR)
		var walkable := _plan_walkable(plan)
		var declared := 0
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "dalle":
				continue
			declared += 1
			var start := plan.cell_of(id)
			var where := "%s %s" % [grid_name, id]
			assert_true(arrows.has(start), "%s : flèche dans la grille" % where)
			var expected := _expand(plan.attr(id, "trajet"))
			var stop := _cell_of(plan.attr(id, "arret"))
			assert_eq(SpinTileRules.compass_direction(plan.attr(id, "dir")), arrows.get(start),
				"%s : sens de la flèche = dir=" % where)
			var slide := SpinTileRules.slide(start, arrows, stops, walkable)
			assert_eq(slide.status, SpinSlide.Status.OK, "%s : finit sur un arrêt" % where)
			assert_eq(slide.path_text(), plan.attr(id, "trajet"), "%s : trajet RB" % where)
			assert_eq(slide.facings, expected, "%s : directions pas à pas" % where)
			assert_eq(slide.end, stop, "%s : case d'arrêt RB" % where)
			assert_eq(plan.at(stop), SpinTileRules.STOP_CHAR, "%s : disque d'arrêt" % where)
			for cell: Vector2i in slide.cells:
				assert_true(walkable.call(cell), "%s : %s praticable" % [where, cell])
			if slide.is_ok():
				total += 1
		assert_eq(declared, RB_TILES[grid_name], "%s : dalles déclarées = RB" % grid_name)
		assert_eq(arrows.size(), RB_TILES[grid_name], "%s : flèches de la grille = RB" % grid_name)
	assert_eq(total, 59, "les 59 trajets de Rouge/Bleu")


func test_real_grids_have_no_bad_field() -> void:
	for grid_name: String in RB_TILES:
		var plan := _load_plan(grid_name)
		var errors := SpinTileRules.check_field(_arrows_of(plan),
			plan.cells_of(SpinTileRules.STOP_CHAR), _plan_walkable(plan))
		assert_eq(errors.size(), 0, "%s :\n%s" % [grid_name, "\n".join(errors)])


func test_every_stop_is_reached_and_stable() -> void:
	for grid_name: String in RB_TILES:
		var plan := _load_plan(grid_name)
		var arrows := _arrows_of(plan)
		var stops := plan.cells_of(SpinTileRules.STOP_CHAR)
		var walkable := _plan_walkable(plan)
		var reached: Dictionary[Vector2i, bool] = {}
		for cell: Vector2i in arrows:
			var safe := SpinTileRules.safe_cell(cell, arrows, stops, walkable)
			assert_false(arrows.has(safe), "%s %s : reprise hors dalle" % [grid_name, cell])
			reached[safe] = true
		for stop: Vector2i in stops:
			assert_true(reached.has(stop), "%s : l'arrêt %s sert à une dalle" % [grid_name, stop])


func test_no_spin_tiles_on_b1f_and_b4f() -> void:
	for grid_name: String in ["repaire_b1f", "repaire_b4f"]:
		var plan := _load_plan(grid_name)
		assert_eq(plan.cells_of(SpinTileRules.ARROW_CHARS + SpinTileRules.STOP_CHAR).size(), 0,
			"%s : ni dalle ni arrêt" % grid_name)
