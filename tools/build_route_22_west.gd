extends SceneTree
## Jalon 29, Q29-4 (décision de Kevin, 2026-10-22) : repeint le sol de la Route 22 étendue
## (`route_22_west`, 20 × 14 cases) avec la chaîne du sol peint de la Route 22 du J7
## (`build_route_22.gd`) : masque `route_22_west_ground.png` (G = chemin de
## terre), `PaintedGround` (mêmes textures d'herbe et de chemin, même échelle de 96 px par case,
## même profil `golden_hour`), décalcomanies de bord, touffes de hautes herbes peintes, forêt
## d'arbres peints sur les cases solides. Aucune nouvelle image : le sol est fait des textures
## communes (raccord sans couture avec la partie J7 par construction).
##
## Passe APRÈS `build_j29.gd` (qui écrit la scène en tuiles provisoires) ; idempotente (elle
## retire d'abord ses propres nœuds). La logique ne change pas : la couche `Ground` (source
## logique : solide, hautes herbes), `blocked_cells`, les passages, les points d'apparition, les
## déclencheurs et les nœuds de `Entities` (bâtiment du poste provisoire, panneau) sont gardés ;
## les couches de tuiles sont seulement masquées. Les arbres et touffes sont décoratifs.
##
##   godot --headless --path . -s res://tools/build_j29.gd
##   godot --headless --path . -s res://tools/build_route_22_west.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const SCENE_PATH: String = "res://game/world/maps/route_22_west.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_22_west_ground.png"
const PLAN_PATH: String = "res://tools/plans/route_22_ouest.txt"
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const SEED: int = 2222
const TILE: int = 96
## Nœuds posés par cette passe (retirés avant de recommencer).
const OWN_NODES: Array[String] = ["PaintedGround"]

var _rng := RandomNumberGenerator.new()
var _plan: Object
var _size: Vector2i
var _scenes: Dictionary = {}
var _path_cells: Dictionary = {}
var _poses: Array[Vector2] = []


func _init() -> void:
	_rng.seed = SEED
	_plan = PlanGrid.new()
	if not _plan.load_file(PLAN_PATH):
		push_error("build_route_22_west : %s" % _plan.error)
		quit(1)
		return
	_size = Vector2i(_plan.width, _plan.height)
	for cell: Vector2i in _plan.cells_of("="):
		_path_cells[cell] = true
	var mask := _write_mask()
	if mask == null:
		print("build_route_22_west : masque écrit ; importer (--import) puis relancer l'outil")
		quit(2)
		return
	var root := (load(SCENE_PATH) as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	for node_name: String in OWN_NODES:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var decals := root.get_node(^"GroundDecals")
	var entities := root.get_node(^"Entities")
	for child: Node in decals.get_children():
		decals.remove_child(child)
		child.free()
	for child: Node in entities.get_children():
		if String(child.name).begins_with("Tree") or String(child.name).begins_with("Tuft"):
			entities.remove_child(child)
			child.free()
	# Source logique seulement : l'image est le sol peint.
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		(root.get_node(NodePath(layer_name)) as TileMapLayer).visible = false
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", _size)
	painted.set(&"mask", mask)
	root.add_child(painted)
	painted.owner = root
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	_border_decals(root, decals)
	_tall_grass(root, entities)
	_trees(root, entities)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, SCENE_PATH)
	print("route_22_west : %s (%d arbres)" % [error_string(err), _poses.size()])
	root.free()
	quit(0 if err == OK else 1)


func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", _size, [], _path_cells)
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS + id + ".tscn")
	return _scenes[id]


func _add_prop(root: Node, parent: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = (foot * TILE).round()
	parent.add_child(prop)
	prop.owner = root
	return prop


## Décalcomanies du bord du chemin (terre et touffes ; pas de pavés sur une route de terre).
func _border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var plan: Array = script.call(&"plan", _path_cells, _size, SEED)
	var kept: Array[Dictionary] = []
	for decal: Dictionary in plan:
		if not String(decal["texture"]).contains("decal_pave"):
			kept.append(decal)
	script.call(&"place", kept, decals, root)


## Deux touffes par case de haute herbe (même tirage que la Route 22 du J7).
func _tall_grass(root: Node, entities: Node2D) -> void:
	var wind: Material = load(WIND_MATERIAL)
	var index := 0
	for cell: Vector2i in _plan.cells_of("h"):
		for k: int in 2:
			var foot := Vector2(cell) + Vector2(_rng.randf_range(0.25, 0.75), 0.55 + 0.45 * k)
			var tuft := _add_prop(root, entities, "ground_hautes_herbes_01", foot,
				"Tuft%03d" % index)
			index += 1
			var scale := _rng.randf_range(1.0, 1.3)
			tuft.scale = Vector2(scale, scale)
			var sprite := tuft.get_node(^"Sprite")
			sprite.set(&"material", wind)
			sprite.set(&"flip_h", _rng.randf() < 0.5)


func _is_forest(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _size.x or cell.y >= _size.y:
		return true
	return _plan.at(cell) == "T"


## Praticable pour le joueur = ni forêt ni bâtiment.
func _walkable_near(p: Vector2, radius: float) -> bool:
	var reach := ceili(radius)
	var cell := Vector2i(p)
	for dx: int in range(-reach, reach + 1):
		for dy: int in range(-reach, reach + 1):
			var other := cell + Vector2i(dx, dy)
			if other.x < 0 or other.y < 0 or other.x >= _size.x or other.y >= _size.y:
				continue
			if _plan.at(other) != "T" and _plan.at(other) != "P":
				var center := Vector2(other) + Vector2(0.5, 0.5)
				if center.distance_to(p) < radius + 0.5:
					return true
	return false


func _too_close(p: Vector2, distance: float) -> bool:
	for other: Vector2 in _poses:
		if other.distance_to(p) < distance:
			return true
	return false


## Forêt dense sur les cases solides « T », à bonne distance des cases praticables (la cime
## déborde de 1,4 case) et du bâtiment du poste (qui garde son dessin provisoire).
func _trees(root: Node, entities: Node2D) -> void:
	for attempt: int in 6000:
		var p := Vector2(_rng.randf_range(0.5, _size.x - 0.5),
			_rng.randf_range(0.5, _size.y - 0.2))
		var cell := Vector2i(p)
		if not _is_forest(cell) or _walkable_near(p, 1.5) or _too_close(p, 1.55):
			continue
		_poses.append(p)
		var id := "tree_b_01" if _rng.randf() < 0.6 else "tree_a_01"
		_add_prop(root, entities, id, p, "Tree%03d" % (_poses.size() - 1))
