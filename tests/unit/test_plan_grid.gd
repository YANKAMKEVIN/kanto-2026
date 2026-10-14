extends GutTest
## Lecteur des grilles fonctionnelles (`tests/helpers/plan_grid.gd`) : légende par grille
## (ligne `PRATICABLES`) et attributs « cle=valeur » des positions (jalon 9, T14). Les critères
## de level design de la Forêt de Jade sont vérifiés par `tools/art/plan_check.py` (T14), puis
## par `test_viridian_forest` sur la vraie scène (T19, T21).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const ROUTE_2 := "res://tools/plans/route_2.txt"
const FOREST := "res://tools/plans/viridian_forest.txt"


func _load(path: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(path), plan.error)
	return plan


func test_route_2_keeps_the_default_legend() -> void:
	var plan := _load(ROUTE_2)
	assert_eq(plan.walkable, PlanGrid.WALKABLE)
	assert_true(plan.is_walkable(Vector2i(20, 8)), "porte du poste")
	assert_true(plan.attr("hiker", "role").is_empty(), "aucun attribut à la Route 2")


func test_forest_has_its_own_legend_and_envelope() -> void:
	var plan := _load(FOREST)
	assert_eq(Vector2i(plan.width, plan.height), Vector2i(70, 90),
		"forêt agrandie (décision de Kevin, 2026-10-08)")
	assert_eq(plan.walkable, ".=hCLgD")
	assert_eq(plan.cells_of("D").size(), 1, "une porte : le poste nord")
	for cell: Vector2i in plan.cells_of("CLg"):
		assert_true(plan.is_walkable(cell), "clairière, rai, sortie praticables : %s" % cell)
	for cell: Vector2i in plan.cells_of("ISsrP"):
		assert_false(plan.is_walkable(cell), "repères et poste bloqués : %s" % cell)


func test_forest_trainers_carry_their_vision() -> void:
	var plan := _load(FOREST)
	var sights := {"D1": "4", "D2": "5", "D3": "4", "D4": "5", "D5": "5"}
	var seen := {}
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "dresseur":
			continue
		var role := plan.attr(id, "role")
		seen[role] = true
		assert_eq(plan.attr(id, "sight"), sights.get(role, ""), "vision de %s" % id)
		assert_true(plan.attr(id, "facing") in ["up", "down", "left", "right"], id)
		assert_true(plan.attr(id, "trainer").begins_with("forest_"), id)
		assert_true(plan.is_walkable(plan.cell_of(id)), "%s sur une case praticable" % id)
	assert_eq(seen.size(), 5, "cinq Dresseurs")


func test_forest_objects_are_the_six_of_the_dossier() -> void:
	var plan := _load(FOREST)
	var kinds := {}
	for id: String in plan.positions:
		var kind: String = plan.positions[id]["kind"]
		if kind in ["objet_visible", "objet_cache"]:
			kinds[plan.attr(id, "role")] = kind
			assert_true(id.begins_with("viridian_forest_item_"), id)
	assert_eq(kinds, {"O1": "objet_visible", "O2": "objet_visible", "O3": "objet_cache",
		"O4": "objet_cache", "O5": "objet_visible", "O6": "objet_cache"})


func test_attribute_without_equal_sign_is_refused() -> void:
	var path := "user://plan_grid_bad_attr.txt"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("GRILLE 1 1\n00 .\nFIN\nPOSITIONS\na pnj 0,0 libre role\nFIN\n")
	file.close()
	var plan := PlanGrid.new()
	assert_false(plan.load_file(path))
	assert_string_contains(plan.error, "attribut")
	DirAccess.remove_absolute(path)


# Jalon 14 T20a : variante « J14 » d'Azuria, la base du J13 intacte.
const AZURIA := "res://tools/plans/azuria.txt"


func test_azuria_base_ignores_the_j14_variant() -> void:
	var plan := _load(AZURIA)
	assert_eq(plan.walkable, ".=pqBD")
	assert_eq(plan.at(Vector2i(14, 3)), "y", "trou impraticable au J13")
	assert_eq(plan.at(Vector2i(10, 9)), "f", "porte fermée au J13")
	assert_false(plan.positions.has("rocket_arret"), "aucune position du J14 dans la base")
	assert_eq(plan.positions["porte_cambriolee"]["kind"], "examen")


func test_azuria_j14_variant_opens_garden_dead_end_and_south() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(AZURIA, "J14"), plan.error)
	assert_eq(Vector2i(plan.width, plan.height), Vector2i(56, 41))
	for x: int in range(6, 22):
		for y: int in [2, 3]:
			var cell := Vector2i(x, y)
			if cell != Vector2i(14, 2):
				assert_true(plan.is_walkable(cell), "jardin, trou, impasse : %s" % cell)
	assert_false(plan.is_walkable(Vector2i(22, 3)), "impasse fermée à l'est")
	assert_false(plan.is_walkable(Vector2i(14, 2)), "clôture à côté du trou")
	for x: int in range(31, 34):
		assert_true(plan.is_walkable(Vector2i(x, 40)), "sortie sud")
	assert_eq(plan.positions["porte_cambriolee"]["kind"], "warp", "remplacée par la variante")
	assert_eq(plan.cell_of("rocket_arret"), Vector2i(21, 3))
	assert_eq(plan.attr("rocket_arret", "unless"), "cerulean_rocket_beaten")
	assert_eq(plan.cell_of("h4_policier"), Vector2i(11, 10), "identifiant stable")
	assert_true(plan.positions.has("pot_renverse"), "positions de base gardées")


func test_missing_variant_is_an_error() -> void:
	var plan := PlanGrid.new()
	assert_false(plan.load_file(AZURIA, "J99"))
	assert_string_contains(plan.error, "J99")
