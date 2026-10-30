extends SceneTree
## Lot DAF.10c (`tools/art/daf10c.py`, fiche `docs/design/fiches-assets/daf-10c/fiche.md`, RP-276) :
## repeint la Centrale (`power_plant`, J32), écrite en tuiles provisoires par `build_power_plant.gd`.
##
## Seconde passe d'image (gel du J33), comme `build_daf10c_seafoam.gd` ; idempotente. **La logique
## ne change pas** : portes, objets cachés (indices `x` et leur dessin), Électhor, fausses Poké Balls
## et objets (PNJ de `data/npcs/power_plant.json`) sont gardés ; les couches de tuiles sont masquées.
## L'image vient de `tools/cave_map_kit.gd` (racine jetable, nœuds adoptés, préfixe `Daf10c`) :
## - sol peint : dalles de béton de l'usine (base), dessus des machines (canal G) sur `#` et `x` ;
## - machines et cloisons `#` en modules `relief_mur_centrale_*` aux rôles du repaire Rocket
##   (`tools/module_walls.gd` : faces, couronnements, bords latéraux) ;
## - machines peintes posées sur le dessus des grands blocs (cases `#` entourées de `#`, loin des
##   faces), une case sur deux au plus [D].
##
##   godot --headless --path . -s res://tools/build_daf10c_centrale.gd   (code 2 : masque écrit,
##   godot --headless --path . --import                                 importer puis relancer)

const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_ID: StringName = &"power_plant"
const MAP_PATH: String = "res://game/world/maps/power_plant.tscn"
const PLAN_PATH: String = "res://tools/plans/power_plant.txt"
const MASK_PATH: String = "res://assets/world/maps/power_plant_ground.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const PAINTED: String = "res://game/world/props/painted/%s.tscn"
const SEED: int = 3271
const OWN_ROOT: Array[String] = ["PaintedGround", "Daf10cSol"]
const OWN_PREFIX: String = "Daf10c"
const WALL_MARK: String = "#"
const WALL_LIKE: String = "#x"
const WALL_PREFIX: String = "relief_mur_centrale"
## Frontière bruitée entre le sol et les machines [D].
const BORDER := Color(0.16, 0.19, 0.2)
## Machines (posées seulement si leur scène existe : les images Codex s'ajoutent à l'identique).
const MACHINES: Array[String] = ["int_transformateur_centrale_01", "int_bobine_centrale_01",
	"int_pupitre_centrale_01", "int_generateur_centrale_01", "int_condensateurs_centrale_01",
	"int_touret_centrale_01"]
## Part des cases admissibles qui reçoivent une machine [D].
const MACHINE_CHANCE: float = 0.5

var _errors: int = 0


func _init() -> void:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH):
		push_error(plan.error)
		quit(1)
		return
	var size := Vector2i(plan.width, plan.height)
	var kit: Object = Kit.new(PLAN_PATH, size, SEED, SEED + 1, plan.walkable)
	kit.set(&"floor_texture_path", GROUND % "ground_centrale_01")
	kit.set(&"rubble_texture_path", GROUND % "ground_centrale_01")
	kit.set(&"mass_texture_path", GROUND % "ground_masse_centrale_01")
	kit.set(&"border_color", BORDER)
	kit.set(&"rubble_mark", "-")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", WALL_LIKE)
	if not (kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("\n".join(kit.get(&"errors")))
		quit(1)
		return
	var kit_root: Node2D = kit.call(&"make_root", "Kit", MAP_ID, "", &"")
	if not kit.call(&"add_ground", MASK_PATH):
		var errors: PackedStringArray = kit.get(&"errors")
		kit.call(&"discard")
		if errors.is_empty():
			print("build_daf10c_centrale : masque écrit ; importer (--import) puis relancer")
			quit(2)
		else:
			push_error("\n".join(errors))
			quit(1)
		return
	var walls: Vector3i = ModuleWalls.new(kit, WALL_PREFIX, WALL_MARK, WALL_LIKE, SEED + 2).place()
	var machines := _place_machines(kit, plan)
	if not (kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("\n".join(kit.get(&"errors")))
		kit.call(&"discard")
		quit(1)
		return
	var root := (load(MAP_PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var painted: Node = kit_root.get_node(^"PaintedGround")
	_adopt(painted, root, root, kit_root)
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var decals := Node2D.new()
	decals.name = "Daf10cSol"
	decals.z_index = Kit.Z_DECALS
	root.add_child(decals)
	decals.owner = root
	root.move_child(decals, root.get_node(^"Entities").get_index())
	for pair: Array in [[kit_root.get_node(^"GroundDecals"), decals],
			[kit_root.get_node(^"Entities"), root.get_node(^"Entities")]]:
		for child: Node in (pair[0] as Node).get_children():
			child.name = OWN_PREFIX + String(child.name)
			_adopt(child, pair[1], root, kit_root)
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	root.free()
	print("power_plant : %s (murs %d faces / %d côtés / %d couronnes, %d machines)" % [
		error_string(err), walls.x, walls.y, walls.z, machines])
	quit(0 if err == OK else 1)


## Machines sur le dessus des grands blocs : case `#` dont les quatre voisines sont `#` et dont la
## voisine sud n'est pas une face (le module d'une face déborde d'une case vers le haut) ; jamais
## deux machines voisines. Renvoie le nombre de machines.
func _place_machines(kit: Object, plan: PlanGrid) -> int:
	var available: Array[String] = []
	for id: String in MACHINES:
		if ResourceLoader.exists(PAINTED % id):
			available.append(id)
	if available.is_empty():
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 3
	var taken: Dictionary = {}
	var count := 0
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if not _deep(plan, cell) or rng.randf() >= MACHINE_CHANCE:
				continue
			var id: String = available[rng.randi_range(0, available.size() - 1)]
			var cells: Array[Vector2i] = [cell]
			if id.begins_with("int_generateur") or id.begins_with("int_condensateurs"):
				cells.append(cell + Vector2i.RIGHT)
			var free := true
			for c: Vector2i in cells:
				free = free and _deep(plan, c)
				for dx: int in [-1, 0, 1]:
					for dy: int in [-1, 0, 1]:
						free = free and not taken.has(c + Vector2i(dx, dy))
			if not free:
				continue
			for c: Vector2i in cells:
				taken[c] = true
			kit.call(&"add_prop_at", kit.get(&"entities"), id, cell, "Machine%03d" % count)
			count += 1
	return count


func _wall(plan: PlanGrid, cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height \
		or plan.at(cell) == WALL_MARK


func _deep(plan: PlanGrid, cell: Vector2i) -> bool:
	if cell.x <= 0 or cell.y <= 0 or cell.x >= plan.width - 1 or cell.y >= plan.height - 2:
		return false
	for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN,
			Vector2i(0, 2)]:
		if not _wall(plan, cell + offset):
			return false
	return true


func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir `build_daf4_caves.gd`).
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
