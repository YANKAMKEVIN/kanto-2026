extends SceneTree
## Lot DAF.10a (`tools/art/daf10a.py`, fiche `docs/design/fiches-assets/daf-10a/fiche.md`, RP-270) :
## repeint les quatre zones du Parc Safari (`safari_zone_center|north|east|west`), écrites en tuiles
## provisoires par le J23. Même méthode que `build_daf10a_parmanie.gd` : **la logique ne change pas**
## (gel du J33), couches de tuiles seulement masquées, cabanes de repos en objets peints à l'emprise
## déjà solide (porte libre), herbes hautes peintes sur les cases `h` (la donnée reste dans `Ground`),
## eau peinte sur `W`, îlot (`n` au bord de l'eau) en herbe, bords de carte (`n`) en forêt.
##
##   godot --headless --path . -s res://tools/build_daf10a_safari.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                                importer puis relancer)

const Kit := preload("res://tools/pewter_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const OWN_ROOT: Array[String] = ["PaintedGround", "ForestFloor"]
const OWN_PREFIX: String = "Daf10a"
const TILE: int = 96
## Carte → [grille, graine].
const MAPS: Dictionary = {
	&"safari_zone_center": ["safari_centre", 5311],
	&"safari_zone_north": ["safari_nord", 5321],
	&"safari_zone_east": ["safari_est", 5331],
	&"safari_zone_west": ["safari_ouest", 5341],
}
const HUT_ID: String = "bldg_cabane_safari_01"
const MEADOW_PER_CELL: float = 0.30
const MEADOW_FLOWER_CHANCE: float = 0.2
const FLOWERS: Array[int] = [1, 3, 5]
const ISLET_DECOR: Array[String] = ["prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg"]
const POND_DECOR: Array[String] = ["prop_nenuphars_01", "prop_nenuphars_02", "prop_nenuphars_03",
	"prop_roseaux_01"]
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_daf10a_safari : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan_path := "res://tools/plans/%s.txt" % spec[0]
	var plan := PlanGrid.new()
	if not plan.load_file(plan_path):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var seed_value: int = spec[1]
	var kit: Object = Kit.new(plan_path, size, seed_value, seed_value + 1)
	kit.call(&"set_marks", ".hDe", "", "")
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", "", &"golden_hour", "")
	kit.call(&"make_shade", 1.0, 1.0, 1.0)
	var forest: Dictionary = kit.get(&"forest_cells")
	var islet: Dictionary = {}
	for cell: Vector2i in plan.cells_of("n"):
		var wet := false
		for side: Vector2i in SIDES:
			wet = wet or plan.at(cell + side) == "W" or islet.has(cell + side)
		if wet:
			islet[cell] = true
		else:
			forest[cell] = true
	# Les îlots de plus d'une case se propagent (cases `n` voisines d'un îlot).
	var grew := true
	while grew:
		grew = false
		for cell: Vector2i in forest.keys():
			if plan.at(cell) != "n":
				continue
			for side: Vector2i in SIDES:
				if islet.has(cell + side):
					islet[cell] = true
					forest.erase(cell)
					grew = true
					break
	var water: Dictionary = {}
	for cell: Vector2i in plan.cells_of("W"):
		water[cell] = true
	if not kit.call(&"add_ground", MASK_PATH % map_id, kit.call(&"forest_undergrowth")):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			_masks += 1
		else:
			push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
			_errors += 1
		kit.call(&"discard")
		return
	var painted := kit_root.get_node(^"PaintedGround")
	var shore: Image = (load("res://game/world/ground/ground_mask.gd") as GDScript).call(
		&"build_water", size, water)
	painted.set(&"shore_mask", ImageTexture.create_from_image(shore))
	painted.set(&"water_texture", load("res://assets/world/ground/ground_eau_01.png"))

	var entities: Node2D = kit.get(&"entities")
	var rules: GDScript = kit.get(&"rules")
	var taken: Dictionary = {}
	var hut_index := 0
	for hut: Array in _huts(plan):
		kit.call(&"add_prop_at", entities, HUT_ID, hut[0], "Cabane%d" % hut_index)
		for offset: Vector2i in rules.call(&"footprint", StringName(HUT_ID)):
			taken[(hut[0] as Vector2i) + offset] = true
		hut_index += 1
	for cell: Vector2i in plan.cells_of("B"):
		taken[cell] = true
	_place_decor(kit, entities, plan, islet, water, seed_value)
	kit.call(&"place_border_decals", seed_value)
	kit.call(&"place_meadow", int(size.x * size.y * MEADOW_PER_CELL), MEADOW_FLOWER_CHANCE,
		FLOWERS)
	kit.call(&"place_tall_grass")
	kit.call(&"place_forest", seed_value + 2, [] as Array[Vector2], taken)
	var errors: PackedStringArray = kit.get(&"errors")
	if not errors.is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(errors)])
		_errors += 1
		kit.call(&"discard")
		return

	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		(root.get_node(NodePath(layer_name)) as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	for node_name: String in OWN_ROOT:
		var node: Node = kit_root.get_node(NodePath(node_name))
		_adopt(node, root, root, kit_root)
		root.move_child(node, index)
		index += 1
	# Les zones n'ont pas de nœud de décalcomanies : un nœud « Daf… » (ignoré par `dump_map_nodes`).
	var decals_node := Node2D.new()
	decals_node.name = "Daf10aGroundDecals"
	decals_node.z_index = -1
	root.add_child(decals_node)
	decals_node.owner = root
	root.move_child(decals_node, index)
	for pair: Array in [[kit_root.get_node(^"GroundDecals"), decals_node],
			[kit_root.get_node(^"Entities"), root.get_node(^"Entities")]]:
		for child: Node in (pair[0] as Node).get_children():
			child.name = OWN_PREFIX + String(child.name)
			_adopt(child, pair[1], root, kit_root)
	root.set(&"grass_front", load(Kit.GRASS_FRONT))
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d cabane(s), %d cases d'îlot)" % [map_id, error_string(err), hut_index,
		islet.size()])
	if err != OK:
		_errors += 1
	root.free()


## Cabanes : composantes de cases `B` → [case d'ancrage]. Largeur 4 : ancre = colonne la plus à gauche + 2,
## rangée du bas.
func _huts(plan: Object) -> Array[Array]:
	var left: Dictionary = {}
	for cell: Vector2i in plan.call(&"cells_of", "B"):
		left[cell] = true
	var out: Array[Array] = []
	var keys: Array = left.keys()
	keys.sort()
	for start: Vector2i in keys:
		if not left.has(start):
			continue
		var stack: Array[Vector2i] = [start]
		left.erase(start)
		var min_x := start.x
		var max_y := start.y
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			min_x = mini(min_x, cell.x)
			max_y = maxi(max_y, cell.y)
			for side: Vector2i in SIDES:
				if left.has(cell + side):
					left.erase(cell + side)
					stack.append(cell + side)
		out.append([Vector2i(min_x + 2, max_y)])
	return out


## Buissons sur l'îlot, nénuphars et roseaux dans l'eau (sans emprise).
func _place_decor(kit: Object, entities: Node2D, plan: Object, islet: Dictionary,
		water: Dictionary, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 9
	var index := 0
	for cell: Vector2i in islet:
		if rng.randf() < 0.3:
			var foot := Vector2(cell.x + rng.randf_range(0.4, 0.6), cell.y + 0.9) * TILE
			var prop: Node2D = kit.call(&"add_prop", entities,
				ISLET_DECOR[rng.randi_range(0, ISLET_DECOR.size() - 1)], foot,
				"Islet%03d" % index)
			kit.call(&"clear_footprint", prop)
			index += 1
	var cells: Array = water.keys()
	cells.sort()
	for cell: Vector2i in cells:
		if rng.randf() < 0.06:
			var foot := Vector2(cell.x + rng.randf_range(0.3, 0.7), cell.y + rng.randf_range(0.4, 0.9)) * TILE
			var prop: Node2D = kit.call(&"add_prop", entities,
				POND_DECOR[rng.randi_range(0, POND_DECOR.size() - 1)], foot, "Pond%03d" % index)
			kit.call(&"clear_footprint", prop)
			index += 1


func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var own_decals := root.get_node_or_null(^"Daf10aGroundDecals")
	if own_decals != null:
		root.remove_child(own_decals)
		own_decals.free()
	for parent_name: String in ["Entities"]:
		var parent := root.get_node(NodePath(parent_name))
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()


func _adopt(node: Node, parent: Node, root: Node, kit_root: Node) -> void:
	var owned: Array[Node] = []
	_collect(node, kit_root, owned)
	for n: Node in owned:
		n.owner = null
	node.get_parent().remove_child(node)
	parent.add_child(node)
	for n: Node in owned:
		n.owner = root


func _collect(node: Node, kit_root: Node, into: Array[Node]) -> void:
	if node.owner == kit_root:
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, kit_root, into)
