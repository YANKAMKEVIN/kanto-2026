extends GutTest
## SurfRules (jalon 24, T6 ; dossier 27 §5, `jalon-24.md` §2.2) : montée, pas en mer, descente,
## reprise d'une partie et ses garde-fous, parcours à pied et en Surf. Les cas « Surf » des règles
## de `tools/art/plan_check_j24_seafoam.py` (b.) sont repris tels quels.

const READY := FieldMoves.State.READY

var _grid: GridWorld


## Une rangée de cases : « . » sol bas, « : » sol haut, « = » escalier, « w » eau surfable,
## « ~ » eau décor, « # » mur, « > » courant vers la droite (actif).
func _row(text: String) -> GridWorld:
	var grid := GridWorld.new(Vector2i(text.length(), 1))
	for x: int in text.length():
		var cell := Vector2i(x, 0)
		match text[x]:
			".":
				grid.set_level(cell, GridWorld.Level.LOW)
			":":
				grid.set_level(cell, GridWorld.Level.HIGH)
			"=":
				grid.set_level(cell, GridWorld.Level.STAIRS)
			"w", ">":
				grid.set_surfable(cell)
				grid.set_level(cell, GridWorld.Level.LOW)
				if text[x] == ">":
					grid.set_current(cell, Vector2i.RIGHT)
			"~":
				grid.set_water(cell)
			"#":
				grid.set_solid(cell)
	return grid


func before_each() -> void:
	# 8 × 3 : terre à gauche (x 0..2), mer (x 3..5), terre à droite (x 6..7).
	_grid = GridWorld.new(Vector2i(8, 3))
	for y: int in 3:
		for x: int in range(3, 6):
			_grid.set_surfable(Vector2i(x, y))


# --- Monter ----------------------------------------------------------------------

func test_can_mount_facing_free_surfable_water() -> void:
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT, READY),
		SurfRules.Mount.READY)


func test_can_mount_reports_the_missing_condition() -> void:
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT,
		FieldMoves.State.NO_HM), SurfRules.Mount.NO_HM)
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT,
		FieldMoves.State.NO_BADGE), SurfRules.Mount.NO_BADGE)
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT,
		FieldMoves.State.NO_POKEMON), SurfRules.Mount.NO_POKEMON)


func test_can_mount_not_water_already_surfing_or_decor() -> void:
	assert_eq(SurfRules.can_mount(_grid, Vector2i(1, 1), Vector2i.RIGHT, READY),
		SurfRules.Mount.NOT_WATER, "face à la terre (T-4)")
	assert_eq(SurfRules.can_mount(_grid, Vector2i(3, 1), Vector2i.RIGHT, READY),
		SurfRules.Mount.NOT_WATER, "déjà en mer")
	_grid.set_surfable(Vector2i(2, 0))
	_grid.set_surfable(Vector2i(2, 0), false)
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.UP, READY),
		SurfRules.Mount.NOT_WATER, "eau décor")
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i(1, 1), READY),
		SurfRules.Mount.NOT_WATER, "direction non cardinale")


func test_can_mount_blocked_by_occupant_even_without_conditions() -> void:
	var swimmer := RefCounted.new()
	_grid.occupy(Vector2i(3, 1), swimmer)
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT,
		FieldMoves.State.NO_HM), SurfRules.Mount.BLOCKED)


func test_can_mount_forbidden_while_current_active() -> void:
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT, READY, true),
		SurfRules.Mount.FORBIDDEN, "T-14")
	assert_eq(SurfRules.can_mount(_grid, Vector2i(2, 1), Vector2i.RIGHT,
		FieldMoves.State.NO_BADGE, true), SurfRules.Mount.NO_BADGE,
		"les conditions manquantes priment")


func test_mount_rules_by_ground_level() -> void:
	var grid := _row(".w")
	assert_eq(SurfRules.can_mount(grid, Vector2i(0, 0), Vector2i.RIGHT, READY),
		SurfRules.Mount.READY, "depuis le sol bas")
	grid = _row("=w")
	assert_eq(SurfRules.can_mount(grid, Vector2i(0, 0), Vector2i.RIGHT, READY),
		SurfRules.Mount.READY, "depuis un escalier")
	grid = _row(":w")
	assert_eq(SurfRules.can_mount(grid, Vector2i(0, 0), Vector2i.RIGHT, READY),
		SurfRules.Mount.BLOCKED, "jamais depuis le sol haut")


# --- En mer ----------------------------------------------------------------------

func test_step_kind_swim_dismount_blocked() -> void:
	assert_eq(SurfRules.step_kind(_grid, Vector2i(3, 1), Vector2i.RIGHT), SurfRules.StepKind.SWIM)
	assert_eq(SurfRules.step_kind(_grid, Vector2i(5, 1), Vector2i.RIGHT),
		SurfRules.StepKind.DISMOUNT)
	assert_eq(SurfRules.step_kind(_grid, Vector2i(3, 0), Vector2i.UP), SurfRules.StepKind.BLOCKED,
		"hors carte")
	_grid.set_solid(Vector2i(6, 1))
	assert_eq(SurfRules.step_kind(_grid, Vector2i(5, 1), Vector2i.RIGHT),
		SurfRules.StepKind.BLOCKED, "rocher, récif")
	_grid.occupy(Vector2i(4, 1), RefCounted.new())
	assert_eq(SurfRules.step_kind(_grid, Vector2i(3, 1), Vector2i.RIGHT),
		SurfRules.StepKind.BLOCKED, "Nageur")


func test_dismount_rules_by_ground_level() -> void:
	assert_eq(SurfRules.step_kind(_row("w."), Vector2i(0, 0), Vector2i.RIGHT),
		SurfRules.StepKind.DISMOUNT, "sur le sol bas")
	assert_eq(SurfRules.step_kind(_row("w="), Vector2i(0, 0), Vector2i.RIGHT),
		SurfRules.StepKind.DISMOUNT, "sur un escalier")
	assert_eq(SurfRules.step_kind(_row("w:"), Vector2i(0, 0), Vector2i.RIGHT),
		SurfRules.StepKind.BLOCKED, "jamais sur le sol haut")
	assert_eq(SurfRules.step_kind(_row("ww"), Vector2i(0, 0), Vector2i.RIGHT),
		SurfRules.StepKind.SWIM)
	assert_eq(SurfRules.step_kind(_row("w~"), Vector2i(0, 0), Vector2i.RIGHT),
		SurfRules.StepKind.BLOCKED, "eau décor")


func test_next_cell_walk_and_level_rules() -> void:
	assert_eq(SurfRules.next_cell(_row(".#"), Vector2i(0, 0), Vector2i.RIGHT, true),
		Vector2i(0, 0), "mur")
	assert_eq(SurfRules.next_cell(_row(".:"), Vector2i(0, 0), Vector2i.RIGHT, true),
		Vector2i(0, 0), "bas → haut à pied")
	var stairs := _row(".=:")
	assert_eq(SurfRules.next_cell(stairs, Vector2i(0, 0), Vector2i.RIGHT, true), Vector2i(1, 0))
	assert_eq(SurfRules.next_cell(stairs, Vector2i(1, 0), Vector2i.RIGHT, true), Vector2i(2, 0))
	assert_eq(SurfRules.next_cell(_row(".w"), Vector2i(0, 0), Vector2i.RIGHT, false),
		Vector2i(0, 0), "sans Surf, on ne monte pas")
	var no_mount := {Vector2i(0, 0): true}
	assert_eq(SurfRules.next_cell(_row("=w"), Vector2i(0, 0), Vector2i.RIGHT, true, no_mount),
		Vector2i(0, 0), "escalier interdit au Surf (courant actif)")


# --- Parcours et courants -----------------------------------------------------------

func test_find_reachable_walks_mounts_and_dismounts() -> void:
	var reached := SurfRules.find_reachable(_grid, Vector2i(0, 0), true)
	assert_eq(reached.size(), 24, "toute la carte")
	var on_foot := SurfRules.find_reachable(_grid, Vector2i(0, 0), false)
	assert_eq(on_foot.size(), 9, "à pied : la rive ouest seule")


func test_find_reachable_rides_active_currents() -> void:
	var grid := _row(".>>w")
	var reached := SurfRules.find_reachable(grid, Vector2i(0, 0), true)
	assert_false(reached.has(Vector2i(1, 0)), "on ne s'arrête pas sur un courant actif")
	assert_true(reached.has(Vector2i(3, 0)), "emporté jusqu'à l'eau calme")
	grid.set_current(Vector2i(1, 0), Vector2i.ZERO)
	grid.set_current(Vector2i(2, 0), Vector2i.ZERO)
	reached = SurfRules.find_reachable(grid, Vector2i(0, 0), true)
	assert_true(reached.has(Vector2i(1, 0)), "courant coupé : eau ordinaire")


func test_current_ride_ends_on_the_shore() -> void:
	var grid := _row("w>=:")
	var reached := SurfRules.find_reachable(grid, Vector2i(0, 0), true)
	assert_true(reached.has(Vector2i(2, 0)), "débarque sur l'escalier")
	assert_true(reached.has(Vector2i(3, 0)))
	assert_false(reached.has(Vector2i(1, 0)))


func test_terminals_are_reached_but_not_crossed() -> void:
	var grid := _row("....")
	var reached := SurfRules.find_reachable(grid, Vector2i(0, 0), true, {Vector2i(2, 0): true})
	assert_true(reached.has(Vector2i(2, 0)))
	assert_false(reached.has(Vector2i(3, 0)))
	assert_true(SurfRules.reaches_any(grid, Vector2i(0, 0), {Vector2i(3, 0): true}, true))
	assert_false(SurfRules.reaches_any(grid, Vector2i(0, 0), {Vector2i(3, 0): true}, true,
		{Vector2i(2, 0): true}), "un trou ouvert n'est pas une sortie")


# --- Reprise (dossier §5.7, cas limites 1 et 2) -------------------------------------

func test_resume_on_water_with_conditions() -> void:
	var r := SurfRules.resume(_grid, Vector2i(4, 1), true, Vector2i(2, 1), Vector2i(0, 0), READY)
	assert_eq(r.cell, Vector2i(4, 1))
	assert_true(r.surfing)
	assert_eq(r.reason, SurfRules.ResumeReason.AS_SAVED)
	assert_false(r.ride_current)


func test_resume_on_land_walks_even_if_surfing_was_saved() -> void:
	var r := SurfRules.resume(_grid, Vector2i(1, 1), true, Vector2i(2, 1), Vector2i(0, 0), READY)
	assert_eq(r.cell, Vector2i(1, 1))
	assert_false(r.surfing)


func test_resume_guard_last_land_when_surf_pokemon_is_gone() -> void:
	var r := SurfRules.resume(_grid, Vector2i(4, 1), true, Vector2i(2, 1), Vector2i(0, 0),
		FieldMoves.State.NO_POKEMON)
	assert_eq(r.cell, Vector2i(2, 1))
	assert_false(r.surfing)
	assert_eq(r.reason, SurfRules.ResumeReason.LAST_LAND)


func test_resume_guard_spawn_when_last_land_is_unusable() -> void:
	_grid.occupy(Vector2i(2, 1), RefCounted.new())
	var r := SurfRules.resume(_grid, Vector2i(4, 1), true, Vector2i(2, 1), Vector2i(0, 0),
		FieldMoves.State.NO_HM)
	assert_eq(r.cell, Vector2i(0, 0))
	assert_eq(r.reason, SurfRules.ResumeReason.SPAWN)
	assert_false(r.surfing)
	r = SurfRules.resume(_grid, Vector2i(4, 1), true, Vector2i(40, 1), Vector2i(3, 0),
		FieldMoves.State.NO_HM)
	assert_eq(r.cell, Vector2i(3, 0))
	assert_true(r.surfing, "arrivée de la carte dans l'eau : Surf forcé")


func test_resume_walking_on_water_is_impossible_so_guarded() -> void:
	var r := SurfRules.resume(_grid, Vector2i(4, 1), false, Vector2i(2, 2), Vector2i(0, 0), READY)
	assert_eq(r.cell, Vector2i(2, 2))
	assert_false(r.surfing)


func test_resume_on_a_current_starts_the_ride() -> void:
	_grid.set_current(Vector2i(4, 1), Vector2i.DOWN)
	var r := SurfRules.resume(_grid, Vector2i(4, 1), true, Vector2i(2, 1), Vector2i(0, 0), READY)
	assert_eq(r.cell, Vector2i(4, 1))
	assert_true(r.ride_current, "la glissade part dès l'arrivée (cas limite 2)")


func test_resume_generic_guard_without_exit_goes_to_spawn() -> void:
	# Poche (7, 0..2) fermée par deux rochers : aucune sortie n'est atteignable.
	_grid.occupy(Vector2i(6, 0), RefCounted.new())
	_grid.occupy(Vector2i(6, 1), RefCounted.new())
	_grid.occupy(Vector2i(6, 2), RefCounted.new())
	var exits := {Vector2i(0, 0): true}
	var has_exit := func(cell: Vector2i) -> bool:
		return SurfRules.reaches_any(_grid, cell, exits, false)
	var r := SurfRules.resume(_grid, Vector2i(7, 1), false, Vector2i(7, 1), Vector2i(1, 2), READY,
		has_exit)
	assert_eq(r.cell, Vector2i(1, 2))
	assert_eq(r.reason, SurfRules.ResumeReason.NO_EXIT)
	r = SurfRules.resume(_grid, Vector2i(1, 1), false, Vector2i(1, 1), Vector2i(1, 2), READY,
		has_exit)
	assert_eq(r.reason, SurfRules.ResumeReason.AS_SAVED, "une sortie : rien ne change")
