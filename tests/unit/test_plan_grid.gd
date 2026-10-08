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
