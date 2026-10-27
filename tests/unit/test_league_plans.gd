extends GutTest
## Grilles des salles de la Ligue (jalon 30 T2 ; `jalon-30.md` §2.1) lues comme les cartes les
## liront (`tests/helpers/plan_grid.gd`) et confrontées à [LeagueAttempt] : une salle par étape,
## portes conditionnées par ses drapeaux, dresseur de l'étape. Le contrôle complet
## (accessibilité, combats inévitables, chaîne) est `tools/art/plan_check_j30.py`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLANS_DIR := "res://tools/plans/"
## Salle (carte du jeu, LeagueAttempt.ROOMS) → grille ; le Panthéon à la fin.
const GRIDS := {
	&"league_lorelei": "ligue_olga.txt", &"league_bruno": "ligue_aldo.txt",
	&"league_agatha": "ligue_agatha.txt", &"league_lance": "ligue_peter.txt",
	&"league_champion": "ligue_champion.txt", &"hall_of_fame": "pantheon.txt",
}


func _plan(file: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(PLANS_DIR + file), plan.error)
	return plan


func test_one_room_per_stage_with_its_doors_and_member() -> void:
	for stage: int in LeagueAttempt.STAGE_COUNT:
		var room: StringName = LeagueAttempt.ROOMS[stage]
		var plan := _plan(GRIDS[room])
		assert_eq(plan.attr("porte_nord", "si"), String(LeagueAttempt.stage_flag(stage)),
			"%s : porte nord ouverte par la victoire" % room)
		assert_eq(plan.attr("porte_sud", "unless"), String(LeagueAttempt.ACTIVE),
			"%s : porte sud fermée pendant la tentative" % room)
		var next: StringName = LeagueAttempt.ROOMS[stage + 1] if stage + 1 < 5 else &"hall_of_fame"
		assert_eq(plan.attr("porte_nord", "vers"), "%s:from_south" % next, String(room))
		var trainer := String(LeagueAttempt.trainer_of_stage(stage))
		var found := false
		for id: String in plan.positions:
			if plan.attr(id, "trainer") == trainer:
				found = true
		assert_true(found, "%s : dresseur %s" % [room, trainer])
		for cell: Vector2i in plan.cells_at("porte_nord") + plan.cells_at("porte_sud"):
			assert_true(plan.is_walkable(cell), "%s : porte praticable %s" % [room, cell])
		assert_true(plan.is_walkable(plan.cell_of("from_south")), "%s : entrée" % room)


func test_the_hall_of_fame_has_no_door() -> void:
	var plan := _plan(GRIDS[&"hall_of_fame"])
	assert_eq(plan.cells_of("X").size(), 0, "la cérémonie enchaîne sur le générique")
	assert_true(plan.is_walkable(plan.cell_of("from_south")))
