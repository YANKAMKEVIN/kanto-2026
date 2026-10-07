extends GutTest
## Route 1 peinte (DA.1, docs/tech/integration-da-bourg-route1.md) : lumière, sol peint et
## sous-bois, aucune tuile visible, arbres repères aux cases du jalon 5, forêt serrée dont le
## feuillage ne couvre aucune case praticable, souche du recoin de la Potion, touffes
## jaune-vert, objets solides hors des cases utiles, PNJ peints, cache-jambes peint.
## La géométrie logique est vérifiée par test_route_1 (inchangé).

const MAP_PATH := "res://game/world/maps/route_1.tscn"
const SIZE := Vector2i(48, 44)
const POTION_CELL := Vector2i(9, 20)
const PROPS_DIR := "res://game/world/props/painted/"
const TALL_GRASS_ID := "ground_hautes_herbes_jaune_01"
## Arbres repères : [nom, objet peint, case] (cases des arbres du jalon 5).
const LANDMARKS: Array = [
	["PotionTree", "tree_c_01", Vector2i(9, 19)],
	["TreeNW", "tree_b_01", Vector2i(7, 10)],
	["TreeNE", "tree_c_01", Vector2i(40, 10)],
	["TreeMidW", "tree_automne_01", Vector2i(16, 21)],
	["TreeMidE", "tree_a_01", Vector2i(33, 21)],
	["TreeSouthW", "tree_d_01", Vector2i(19, 30)],
	["TreeMidC", "tree_b_01", Vector2i(30, 20)],
]

var _map: GameMap
var _grid: GridWorld
var _reachable: Dictionary[Vector2i, bool]


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_reachable = _grid.find_reachable(_map.get_spawn_cell(&"from_pallet_w"))


func after_all() -> void:
	_map.free()


func _prop_id(node: Node) -> String:
	return node.scene_file_path.get_file().get_basename()


func _entities_of(prefix: String) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for child: Node in _map.get_entities().get_children():
		if child is Node2D and _prop_id(child).begins_with(prefix):
			found.append(child as Node2D)
	return found


func test_light_profile_is_golden_hour() -> void:
	assert_eq(_map.light_profile, &"golden_hour")


func test_no_tile_layer_is_visible() -> void:
	var layers := _map.find_children("*", "TileMapLayer", true, false)
	assert_eq(layers.size(), 4, "Ground, Detail, Obstacles, Overhead gardés (source logique)")
	for layer: Node in layers:
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_painted_ground_then_forest_floor() -> void:
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	var floor_node := _map.get_node_or_null(^"ForestFloor") as ForestFloor
	assert_not_null(ground, "sol peint")
	assert_not_null(floor_node, "sous-bois")
	if ground == null or floor_node == null:
		return
	assert_eq(ground.size, SIZE)
	assert_eq(floor_node.size, SIZE)
	assert_lt(ground.get_index(), floor_node.get_index(), "sous-bois au-dessus du sol peint")
	# Le chemin est dans le masque (G), la forêt dans celui du sous-bois.
	var mask := ground.mask.get_image()
	assert_eq(GroundMask.kind_at(mask, Vector2i(23, 40)), GroundMask.Kind.PATH)
	assert_eq(GroundMask.kind_at(mask, Vector2i(22, 40)), GroundMask.Kind.GRASS)
	assert_true(floor_node.is_forest(Vector2i(0, 0)))
	assert_true(floor_node.is_forest(Vector2i(9, 19)) == false, "case d'herbe du recoin")
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if floor_node.is_forest(cell):
				assert_false(_reachable.has(cell), "sous-bois sur une case praticable %s" % cell)


func test_landmark_trees_on_the_jalon_5_cells() -> void:
	for spec: Array in LANDMARKS:
		var tree := _map.get_entities().get_node_or_null(NodePath(spec[0])) as WorldProp
		assert_not_null(tree, String(spec[0]))
		if tree == null:
			continue
		assert_eq(_prop_id(tree), spec[1], "%s : essence" % spec[0])
		assert_eq(tree.get_anchor_cell(), spec[2], "%s : case" % spec[0])
		assert_true(_grid.is_solid(spec[2]), "%s : case bloquée" % spec[0])
	var autumn := _entities_of("tree_automne_01")
	assert_eq(autumn.size(), 1, "un seul arbre d'automne")


func test_forest_canopy_never_covers_a_walkable_cell() -> void:
	var trees := _entities_of("tree_foret_")
	assert_gt(trees.size(), 300, "forêt serrée")
	for tree: Node2D in trees:
		var foot := tree.position / float(Grid.TILE_SIZE)
		for cell: Vector2i in DenseForest.canopy_cells(foot):
			if not _grid.is_in_bounds(cell):
				continue
			assert_false(_reachable.has(cell), "%s : feuillage sur %s" % [tree.name, cell])
			assert_true(_grid.is_solid(cell), "%s : %s est de la forêt" % [tree.name, cell])
		assert_true((tree as WorldProp).get_footprint().is_empty(),
			"%s sans emprise (cases de forêt déjà solides)" % tree.name)
	# Aucun arbre de forêt près d'un repère.
	for spec: Array in LANDMARKS:
		var landmark := Grid.cell_to_world(spec[2]) / float(Grid.TILE_SIZE)
		for tree: Node2D in trees:
			assert_gte((tree.position / float(Grid.TILE_SIZE)).distance_to(landmark),
				DenseForest.LANDMARK_CLEARANCE - 0.01, "%s dégagé" % spec[0])


func test_forest_trees_have_no_shadow_by_default() -> void:
	for tree: Node2D in _entities_of("tree_foret_"):
		assert_null(tree.get_node_or_null(^"ContactShadow"), "%s sans ombre" % tree.name)


func test_stump_beside_the_potion_trigger() -> void:
	var stump := _map.get_entities().get_node_or_null(^"PotionStump") as WorldProp
	assert_not_null(stump, "souche du recoin")
	if stump == null:
		return
	assert_eq(_prop_id(stump), "prop_souche_01")
	var cell := stump.get_anchor_cell()
	assert_lte(absi(cell.x - POTION_CELL.x) + absi(cell.y - POTION_CELL.y), 1,
		"souche sur ou à côté de la case de la Potion")
	assert_true(stump.get_footprint().is_empty(), "la souche ne bloque rien")
	assert_false(_grid.is_solid(POTION_CELL), "Potion toujours praticable")
	assert_not_null(_map.get_node_or_null(^"Triggers/Route1Potion"))


func test_two_yellow_green_tufts_per_tall_grass_cell() -> void:
	var counts: Dictionary[Vector2i, int] = {}
	for tuft: Node2D in _entities_of("ground_hautes_herbes"):
		assert_eq(_prop_id(tuft), TALL_GRASS_ID, "touffes jaune-vert")
		var cell := Grid.world_to_cell(tuft.position - Vector2(0, 1))
		counts[cell] = counts.get(cell, 0) + 1
	var cells := 0
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if _grid.is_tall_grass(cell):
				cells += 1
				assert_eq(counts.get(cell, 0), 2, "deux touffes en %s" % cell)
	assert_gt(cells, 0)


func test_ledge_painted_in_ground_decals() -> void:
	var cells: Array[Vector2i] = []
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if child is WorldProp and _prop_id(child) == "relief_rebord_01":
			cells.append((child as WorldProp).get_anchor_cell())
	cells.sort()
	assert_eq(cells, [Vector2i(26, 30), Vector2i(27, 30), Vector2i(28, 30)] as Array[Vector2i])


func test_solid_props_keep_useful_cells_free() -> void:
	var useful: Dictionary[Vector2i, String] = {POTION_CELL: "Potion"}
	for warp: Warp in _map.get_warps().get_all():
		useful[warp.cell] = "warp"
	for spawn: Node in _map.get_node(^"Spawns").get_children():
		useful[Grid.world_to_cell((spawn as Node2D).position)] = "spawn"
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_1").get_all():
		useful[spec.cell] = String(spec.id)
		for cell: Vector2i in spec.route_cells:
			useful[cell] = String(spec.id)
	for child: Node in _map.get_entities().get_children():
		# Forêt : cases de forêt ; repères : cases des arbres du jalon 5 (l'arbre du recoin
		# est sur une case de hautes herbes depuis le jalon 5, test_route_1).
		if not child is WorldProp or _prop_id(child).begins_with("tree_foret_") \
				or LANDMARKS.any(func(spec: Array) -> bool: return spec[0] == child.name):
			continue
		for cell: Vector2i in (child as WorldProp).get_solid_cells():
			assert_false(useful.has(cell), "%s sur %s (%s)" % [child.name, cell,
				useful.get(cell, "")])
			assert_false(_grid.is_tall_grass(cell), "%s sur les hautes herbes" % child.name)


func test_meadow_has_sign_fences_and_bench() -> void:
	for node_name: String in ["SignNorth", "FenceMeadowW", "FenceMeadowE", "BenchNorth",
			"FenceShortW", "FenceShortE"]:
		assert_not_null(_map.get_entities().get_node_or_null(NodePath(node_name)), node_name)


func test_npcs_are_painted() -> void:
	for id: StringName in [&"traveler", &"route_pidgey", &"route_rattata"]:
		var npc := _map.get_npc(id)
		assert_not_null(npc, String(id))
		if npc == null:
			continue
		var look := CharacterLook.resolve(npc.get_spec().sprite)
		assert_true(look.painted, "%s peint" % id)


func test_player_grass_front_is_the_painted_lower_half() -> void:
	assert_not_null(_map.grass_front)
	assert_true(_map.grass_front.resource_path.ends_with(TALL_GRASS_ID + "_bas.png"))
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	_map.spawn_player_at(player, Vector2i(9, 22), Vector2i.UP)
	assert_eq(player.get_grass_front_texture(), _map.grass_front)
	var band := player.get_node(^"%GrassFront") as Sprite2D
	assert_eq(band.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	assert_true(player.is_grass_front_visible(), "jambes cachées dans les hautes herbes")
	# Carte non peinte : la bande provisoire revient.
	player.set_grass_front(null)
	assert_ne(player.get_grass_front_texture(), _map.grass_front)
	assert_eq(band.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	_map.get_entities().remove_child(player)
	_grid.release(Vector2i(9, 22), player)
	player.free()


func test_dense_forest_contact_shadow_option() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var entries: Array[Dictionary] = [{
		"kind": DenseForest.KIND_TREE, "id": &"tree_foret_03", "foot": Vector2(2, 3),
		"position": Vector2(192, 288), "scale": 1.0, "flip_h": false, "tint": Color.WHITE}]
	var off := DenseForest.place(entries, parent)
	assert_null(off[0].get_node_or_null(^"ContactShadow"), "désactivée par défaut")
	var on := DenseForest.place(entries, parent, null, true)
	var shadow := on[0].get_node_or_null(^"ContactShadow") as Sprite2D
	assert_not_null(shadow, "ombre de contact sur demande")
	if shadow != null:
		assert_true(shadow.is_in_group(WorldLighting.GROUP_CONTACT_SHADOWS))
		assert_eq(shadow.z_index, WorldLighting.Z_SHADOWS)
		assert_false(shadow.z_as_relative)
