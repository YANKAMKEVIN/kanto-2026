extends GutTest
## Forêt serrée de production (DenseForest, docs/tech/integration-da-bourg-route1.md §3) :
## règle du couvert, espacement, repères dégagés, bandes étroites garnies, déterminisme.

const SEED := 1

## Carte d'essai 20 × 16 : forêt partout sauf un chemin vertical (x 9..10), une clairière
## (3..6 × 3..6) et, au sud, une bande de forêt de 2 rangées (y 12..13) entre deux prairies.
const SIZE := Vector2i(20, 16)

var _forest: Dictionary = {}
var _landmarks: Array[Vector2] = [Vector2(15.5, 6.0)]
var _plan: Array[Dictionary] = []


func before_all() -> void:
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if x == 9 or x == 10:
				continue
			if Rect2i(3, 3, 4, 4).has_point(cell):
				continue
			if y == 11 or y >= 14:
				continue
			_forest[cell] = true
	_plan = DenseForest.plan(_forest, SIZE, _landmarks, SEED)


func _of_kind(kind: StringName) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in _plan:
		if entry["kind"] == kind:
			entries.append(entry)
	return entries


func test_plan_has_trees_and_bushes() -> void:
	assert_gt(_of_kind(DenseForest.KIND_TREE).size(), 40, "forêt dense")
	assert_gt(_of_kind(DenseForest.KIND_BUSH).size(), 0, "bandes étroites garnies")


func test_no_tree_canopy_covers_a_non_forest_cell() -> void:
	for entry: Dictionary in _of_kind(DenseForest.KIND_TREE):
		var foot: Vector2 = entry["foot"]
		for cell: Vector2i in DenseForest.canopy_cells(foot):
			var inside := cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y
			assert_true(not inside or _forest.has(cell),
				"arbre en %s : la case %s sous son feuillage est de la forêt" % [foot, cell])


func test_canopy_is_the_foot_column_three_rows_up() -> void:
	assert_eq(DenseForest.canopy_cells(Vector2(4.6, 7.3)),
		[Vector2i(4, 7), Vector2i(4, 6), Vector2i(4, 5)] as Array[Vector2i])
	# Hors carte : la forêt continue (cimes des arbres dont le pied est sous le bord).
	var forest := {Vector2i(0, 1): true}
	assert_true(DenseForest.is_under_canopy(forest, Vector2i(1, 2), Vector2(0.5, 3.4)),
		"pied sous le bord : seule la case (0, 1) est dans la carte")
	assert_false(DenseForest.is_under_canopy(forest, Vector2i(1, 2), Vector2(0.5, 2.4)),
		"la case (0, 0) n'est pas de la forêt")


func test_trees_are_spaced() -> void:
	var trees := _of_kind(DenseForest.KIND_TREE)
	for i in trees.size():
		for j in range(i + 1, trees.size()):
			var a: Vector2 = trees[i]["foot"]
			var b: Vector2 = trees[j]["foot"]
			assert_true(a.distance_to(b) >= DenseForest.SPACING, "%s et %s espacés" % [a, b])


func test_landmarks_stay_clear() -> void:
	for entry: Dictionary in _of_kind(DenseForest.KIND_TREE):
		for landmark: Vector2 in _landmarks:
			assert_true((entry["foot"] as Vector2).distance_to(landmark)
				>= DenseForest.LANDMARK_CLEARANCE, "repère %s dégagé" % landmark)


func test_every_forest_cell_is_garnished() -> void:
	var feet: Array[Vector2] = _landmarks.duplicate()
	for entry: Dictionary in _plan:
		feet.append(entry["foot"])
	for cell: Vector2i in _forest:
		assert_true(DenseForest.is_covered(cell, feet), "case de forêt %s garnie" % cell)


func test_narrow_strip_is_filled_with_bushes() -> void:
	# La bande de 2 rangées (y 12..13) est trop étroite pour un arbre (3 rangées) : rien que
	# des buissons, posés dans la bande.
	var strip := 0
	for entry: Dictionary in _plan:
		var foot: Vector2 = entry["foot"]
		var cell := Vector2i(floori(foot.x), floori(foot.y))
		if cell.y < 12 or cell.y > 13:
			continue
		assert_eq(entry["kind"], DenseForest.KIND_BUSH, "pied en %s : un buisson" % foot)
		strip += 1
	assert_gt(strip, 0)
	# Un buisson pose son pied sur la case de forêt qu'il garnit (même case, même pas hors).
	for entry: Dictionary in _of_kind(DenseForest.KIND_BUSH):
		var foot: Vector2 = entry["foot"]
		assert_true(_forest.has(Vector2i(floori(foot.x), floori(foot.y))),
			"buisson %s sur la forêt" % foot)
		assert_true(DenseForest.BUSH_IDS.has(entry["id"]))


func test_only_a_bush_strip_gets_no_tree() -> void:
	var forest := {}
	for x in 12:
		forest[Vector2i(x, 3)] = true
	var entries := DenseForest.plan(forest, Vector2i(12, 8), [], 7)
	assert_eq(entries.size(), 12, "une rangée de forêt : un buisson par case")
	for entry: Dictionary in entries:
		assert_eq(entry["kind"], DenseForest.KIND_BUSH)


func test_variation_is_baked_within_bounds() -> void:
	for entry: Dictionary in _of_kind(DenseForest.KIND_TREE):
		assert_true(DenseForest.TREE_IDS.has(entry["id"]))
		var scale: float = entry["scale"]
		assert_between(scale, DenseForest.SCALE_MIN, DenseForest.SCALE_MAX)
		var tint: Color = entry["tint"]
		assert_between(tint.g, DenseForest.VALUE_MIN, DenseForest.VALUE_MAX)
		assert_eq(entry["position"], (entry["foot"] as Vector2) * Grid.TILE_SIZE)
	var flips := 0
	var ids := {}
	for entry: Dictionary in _of_kind(DenseForest.KIND_TREE):
		flips += 1 if entry["flip_h"] else 0
		ids[entry["id"]] = true
	assert_gt(flips, 0, "des arbres en miroir")
	assert_lt(flips, _of_kind(DenseForest.KIND_TREE).size(), "et d'autres non")
	assert_gt(ids.size(), 4, "plusieurs essences")


func test_same_seed_gives_the_same_forest() -> void:
	var again := DenseForest.plan(_forest, SIZE, _landmarks, SEED)
	assert_eq(again.size(), _plan.size())
	assert_eq(again, _plan, "graine fixe : même forêt")
	var other := DenseForest.plan(_forest, SIZE, _landmarks, SEED + 1)
	assert_ne(other, _plan, "autre graine : autre forêt")


func test_place_bakes_trees_into_the_scene() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var entries: Array[Dictionary] = [_of_kind(DenseForest.KIND_TREE)[0],
		_of_kind(DenseForest.KIND_BUSH)[0]]
	var nodes := DenseForest.place(entries, root, root)
	assert_eq(nodes.size(), 2)
	var tree := nodes[0] as WorldProp
	assert_not_null(tree, "une scène WorldProp")
	assert_eq(String(tree.name), "Forest000")
	assert_eq(tree.owner, root)
	assert_eq(tree.position, entries[0]["position"])
	assert_eq(tree.scale, Vector2.ONE * float(entries[0]["scale"]))
	assert_eq(tree.modulate, entries[0]["tint"])
	assert_eq((tree.get_node(^"%Sprite") as Sprite2D).flip_h, entries[0]["flip_h"])
	assert_true(tree.get_footprint().is_empty(), "la case de forêt bloque, pas l'arbre")
	assert_false(tree.fade_when_covering, "aucun _process par arbre")
	assert_null(tree.get_node_or_null(^"ContactShadow"), "ombres réservées aux bâtiments")
	var bush := nodes[1] as WorldProp
	assert_eq(String(bush.name), "ForestBush000")
	assert_eq(bush.position, entries[1]["position"])
