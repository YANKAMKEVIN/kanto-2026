extends GutTest
## Forêt serrée de production (DenseForest, docs/tech/integration-da-bourg-route1.md §3) :
## règle du couvert, espacement, repères dégagés, bandes étroites garnies, déterminisme.
## Jalon 8 (§1.2 B) : teinte selon la rangée et poids des essences au nord, neutres par défaut.

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


# --- Variation selon la rangée (jalon 8 §1.2 B) --------------------------------------------

## Réglage de la lisière de la Route 2 : × 1,00 jusqu'à la rangée 30, × 0,72 à la rangée 8 et
## au nord, plus froid (rouge × 0,97, bleu × 1,04) ; essences bleu-vert × 2 au nord de 20.
func _route_2_shade() -> DenseForest.Shade:
	var shade := DenseForest.Shade.new()
	shade.from_row = 30.0
	shade.full_row = 8.0
	shade.value = 0.72
	shade.red = 0.97
	shade.blue = 1.04
	shade.weights_row = 20.0
	shade.weights = {&"tree_foret_04": 2.0, &"tree_foret_05": 2.0, &"tree_foret_06": 2.0}
	return shade


## Forêt pleine (assez d'arbres au nord comme au sud).
func _full_forest(size: Vector2i) -> Dictionary:
	var forest := {}
	for y in size.y:
		for x in size.x:
			forest[Vector2i(x, y)] = true
	return forest


func test_neutral_shade_changes_nothing() -> void:
	assert_eq(DenseForest.plan(_forest, SIZE, _landmarks, SEED, DenseForest.Shade.new()),
		_plan, "réglage neutre : même forêt (Route 1, Bourg Palette inchangés)")
	assert_eq(DenseForest.plan(_forest, SIZE, _landmarks, SEED, null), _plan)
	assert_eq(DenseForest.row_tint(null, 3.0), Color.WHITE)
	assert_eq(DenseForest.row_tint(DenseForest.Shade.new(), 3.0), Color.WHITE)


func test_row_tint_darkens_and_cools_towards_the_north() -> void:
	var shade := _route_2_shade()
	assert_eq(DenseForest.row_tint(shade, 45.0), Color.WHITE, "au sud de la rangée 30")
	assert_eq(DenseForest.row_tint(shade, 30.0), Color.WHITE, "à la rangée 30")
	var north := DenseForest.row_tint(shade, 8.0)
	assert_almost_eq(north.g, 0.72, 0.0001, "× 0,72 à la rangée 8")
	assert_almost_eq(north.r, 0.72 * 0.97, 0.0001, "moins de rouge")
	assert_almost_eq(north.b, 0.72 * 1.04, 0.0001, "plus de bleu")
	assert_eq(DenseForest.row_tint(shade, 2.0), north, "au nord de la rangée 8 : pareil")
	assert_almost_eq(DenseForest.row_tint(shade, 19.0).g, 0.86, 0.0001, "linéaire entre")
	var previous := 2.0
	for row in range(31, 0, -1):
		var value := DenseForest.row_tint(shade, float(row)).g
		assert_true(value <= previous, "rangée %d : jamais plus clair en montant" % row)
		previous = value


func test_shade_tints_the_trees_by_their_foot_row() -> void:
	# Teinte seule (sans poids) : mêmes tirages, donc mêmes arbres ; seule la teinte change.
	var size := Vector2i(16, 40)
	var forest := _full_forest(size)
	var plain := DenseForest.plan(forest, size, [], SEED)
	var shade := _route_2_shade()
	shade.weights = {}
	var shaded := DenseForest.plan(forest, size, [], SEED, shade)
	assert_eq(shaded.size(), plain.size())
	var south := 0
	var north := 0
	for i in plain.size():
		var before: Dictionary = plain[i]
		var after: Dictionary = shaded[i]
		assert_eq(after["foot"], before["foot"])
		assert_eq(after["id"], before["id"])
		if before["kind"] != DenseForest.KIND_TREE:
			assert_eq(after["tint"], before["tint"], "buissons : inchangés (réglés au T5)")
			continue
		var foot: Vector2 = before["foot"]
		var expected: Color = (before["tint"] as Color) * DenseForest.row_tint(shade, foot.y)
		assert_eq(after["tint"], expected, "arbre en %s" % foot)
		if foot.y >= 30.0:
			assert_eq(after["tint"], before["tint"], "au sud : inchangé")
			south += 1
		elif foot.y <= 8.0:
			assert_lt((after["tint"] as Color).g, (before["tint"] as Color).g, "plus sombre")
			north += 1
	assert_gt(south, 5)
	assert_gt(north, 5)


func test_cold_species_weigh_more_in_the_north_only() -> void:
	var size := Vector2i(30, 60)
	var forest := _full_forest(size)
	var cold: Array[StringName] = [&"tree_foret_04", &"tree_foret_05", &"tree_foret_06"]
	var shade := DenseForest.Shade.new()
	shade.weights_row = 30.0
	shade.weights = {&"tree_foret_04": 6.0, &"tree_foret_05": 6.0, &"tree_foret_06": 6.0}
	var counts := {"north": 0, "north_cold": 0, "south": 0, "south_cold": 0}
	for entry: Dictionary in DenseForest.plan(forest, size, [], SEED, shade):
		if entry["kind"] != DenseForest.KIND_TREE:
			continue
		var half := "north" if (entry["foot"] as Vector2).y < 30.0 else "south"
		counts[half] += 1
		if cold.has(entry["id"]):
			counts[half + "_cold"] += 1
	# Uniforme : 3 / 8 ≈ 0,38 ; poids × 6 : 18 / 23 ≈ 0,78.
	var north_share: float = float(counts["north_cold"]) / float(counts["north"])
	var south_share: float = float(counts["south_cold"]) / float(counts["south"])
	assert_gt(north_share, 0.65, "essences froides majoritaires au nord (%s)" % counts)
	assert_lt(south_share, 0.5, "tirage uniforme au sud (%s)" % counts)


# --- Tri de visibilité (jalon 9 T18, jalon-09.md §2.7.4) -------------------------------

## Grande carte 80 × 40, une seule case où se tenir.
const BIG := Vector2i(80, 40)


func _seen_cells(mask: PackedByteArray, map_size: Vector2i) -> Rect2i:
	var rect := Rect2i()
	var first := true
	for y: int in map_size.y:
		for x: int in map_size.x:
			if mask[y * map_size.x + x] != 1:
				continue
			if first:
				rect = Rect2i(x, y, 1, 1)
				first = false
			else:
				rect = rect.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return rect


func test_mask_is_the_camera_view_around_the_player_plus_a_margin() -> void:
	var mask := DenseForest.visibility_mask([Vector2i(40, 20)] as Array[Vector2i], BIG)
	# Caméra centrée sur (40,5 ; 20,5) : ± 12,2 + 1 cases, ± 5,625 + 1 rangées.
	assert_eq(_seen_cells(mask, BIG), Rect2i(27, 13, 27, 15))
	var both := DenseForest.visibility_mask([Vector2i(40, 20), Vector2i(41, 20)]
		as Array[Vector2i], BIG)
	assert_eq(_seen_cells(both, BIG), Rect2i(27, 13, 28, 15), "union de deux vues")


func test_mask_follows_the_camera_clamped_to_the_map() -> void:
	# Joueur dans un coin : la caméra reste dans la carte, elle montre plus loin à l'est.
	var mask := DenseForest.visibility_mask([Vector2i(1, 1)] as Array[Vector2i], BIG)
	assert_eq(_seen_cells(mask, BIG), Rect2i(0, 0, 26, 13))
	var far := DenseForest.visibility_mask([Vector2i(79, 39)] as Array[Vector2i], BIG)
	assert_eq(_seen_cells(far, BIG), Rect2i(54, 27, 26, 13))


func test_a_map_smaller_than_the_view_is_entirely_seen() -> void:
	var small := Vector2i(12, 8)
	var mask := DenseForest.visibility_mask([Vector2i(0, 0)] as Array[Vector2i], small)
	assert_eq(_seen_cells(mask, small), Rect2i(Vector2i.ZERO, small))
	var none := DenseForest.visibility_mask([] as Array[Vector2i], small)
	assert_eq(none.count(1), 0, "aucune case où se tenir : rien n'est vu")


func test_a_tree_is_seen_by_its_canopy_and_its_width() -> void:
	var mask := DenseForest.visibility_mask([Vector2i(40, 20)] as Array[Vector2i], BIG)
	# Rangées vues 13..27, colonnes 27..53.
	assert_true(DenseForest.is_seen(Vector2(40.5, 31.5), mask, BIG), "cime jusqu'à 27")
	assert_false(DenseForest.is_seen(Vector2(40.5, 32.5), mask, BIG), "cime en 28 : caché")
	assert_true(DenseForest.is_seen(Vector2(40.5, 13.2), mask, BIG), "pied en 13 : vu")
	assert_false(DenseForest.is_seen(Vector2(40.5, 12.9), mask, BIG), "pied en 12 : caché")
	assert_true(DenseForest.is_seen(Vector2(55.6, 20.0), mask, BIG), "53..57 : 53 vue")
	assert_false(DenseForest.is_seen(Vector2(56.5, 20.0), mask, BIG), "54..58 : caché")
	assert_true(DenseForest.is_seen(Vector2(25.0, 20.0), mask, BIG), "23..27 : 27 vue")
	assert_false(DenseForest.is_seen(Vector2(24.5, 20.0), mask, BIG), "22..26 : caché")


func test_cull_keeps_order_and_only_drops_unseen_entries() -> void:
	var forest: Dictionary = {}
	for y: int in BIG.y:
		for x: int in BIG.x:
			if not Rect2i(4, 4, 3, 3).has_point(Vector2i(x, y)):
				forest[Vector2i(x, y)] = true
	var walkable: Array[Vector2i] = []
	for y: int in range(4, 7):
		for x: int in range(4, 7):
			walkable.append(Vector2i(x, y))
	var plan := DenseForest.plan(forest, BIG, [] as Array[Vector2], SEED)
	var kept := DenseForest.cull_hidden(plan, walkable, BIG)
	assert_gt(plan.size(), kept.size() * 3, "la plupart des arbres ne sont jamais à l'écran")
	assert_gt(kept.size(), 50, "le voisinage reste garni")
	var mask := DenseForest.visibility_mask(walkable, BIG)
	var index := 0
	for entry: Dictionary in plan:
		var seen := DenseForest.is_seen(entry["foot"], mask, BIG)
		if index < kept.size() and kept[index] == entry:
			index += 1
			assert_true(seen)
		else:
			assert_false(seen, "retiré seulement s'il n'est jamais vu : %s" % entry["foot"])
	assert_eq(index, kept.size(), "même ordre (noms des nœuds stables)")
	assert_eq(DenseForest.cull_hidden(plan, walkable, BIG), kept, "reproductible")


func test_cull_changes_nothing_on_a_small_map() -> void:
	var walkable: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if not _forest.has(Vector2i(x, y)):
				walkable.append(Vector2i(x, y))
	assert_eq(DenseForest.cull_hidden(_plan, walkable, SIZE), _plan,
		"20 × 16 tient dans la vue : rien n'est retiré")


## Forêt de Jade (grille du T14) : ordre de grandeur pour le budget du T19 (≤ 3 000 nœuds).
func test_viridian_forest_grid_keeps_a_fraction_of_its_trees() -> void:
	var grid := preload("res://tests/helpers/plan_grid.gd").new()
	assert_true(grid.load_file("res://tools/plans/viridian_forest.txt"), grid.error)
	var map_size := Vector2i(grid.width, grid.height)
	var forest: Dictionary = {}
	for cell: Vector2i in grid.cells_of("T"):
		forest[cell] = true
	var walkable: Array[Vector2i] = []
	for y: int in grid.height:
		for x: int in grid.width:
			if grid.is_walkable(Vector2i(x, y)):
				walkable.append(Vector2i(x, y))
	var plan := DenseForest.plan(forest, map_size, [] as Array[Vector2], SEED)
	var kept := DenseForest.cull_hidden(plan, walkable, map_size)
	gut.p("Forêt de Jade : %d entrées au plan, %d gardées par le tri de visibilité"
		% [plan.size(), kept.size()])
	assert_lte(kept.size(), plan.size())
	assert_gt(float(kept.size()), plan.size() / 3.0, "la forêt reste presque partout à l'écran")


## Repli du budget de nœuds (jalon 9 T19) : un `Sprite2D` par entrée, même image, même décalage,
## même matériau que le sprite de la scène peinte, taille / miroir / teinte cuits.
func test_place_sprites_makes_one_sprite_per_entry_like_the_painted_scene() -> void:
	var entries: Array[Dictionary] = [
		{"kind": DenseForest.KIND_TREE, "id": &"tree_foret_03", "foot": Vector2(2, 3),
			"position": Vector2(192, 288), "scale": 0.9, "flip_h": true,
			"tint": Color(0.8, 0.7, 0.9)},
		{"kind": DenseForest.KIND_BUSH, "id": &"tree_foret_05", "foot": Vector2(4, 3),
			"position": Vector2(384, 288), "scale": 0.5, "flip_h": false, "tint": Color.WHITE},
	]
	var parent := Node2D.new()
	add_child_autofree(parent)
	var nodes := DenseForest.place_sprites(entries, parent)
	assert_eq(nodes.size(), 2)
	assert_eq(parent.get_child_count(), 2, "un nœud par entrée")
	var model := (load("res://game/world/props/painted/tree_foret_03.tscn") as PackedScene) \
		.instantiate()
	var source := model.get_node(^"Sprite") as Sprite2D
	var tree := nodes[0]
	assert_eq(tree.name, &"Forest000")
	assert_eq(tree.get_child_count(), 0)
	assert_eq(tree.texture, source.texture)
	assert_eq(tree.offset, source.offset)
	assert_eq(tree.centered, source.centered)
	assert_eq(tree.material, source.material, "vent")
	assert_eq(tree.position, Vector2(192, 288))
	assert_eq(tree.scale, Vector2(0.9, 0.9))
	assert_true(tree.flip_h)
	assert_eq(tree.modulate, Color(0.8, 0.7, 0.9))
	assert_eq(nodes[1].name, &"ForestBush000")
	model.free()
