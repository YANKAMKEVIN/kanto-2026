extends SceneTree
## Retouches de Kanto du jalon JOH9 (`docs/tech/jalon-joh9.md` §2.1, §2.4), posées sur les scènes
## existantes **sans les reconstruire** (art peint du DAF.4 et du labo gardé) :
## - `route_22_west` : la **variante `JOH9`** de `tools/plans/route_22_ouest.txt` (JH-8, seule
##   retouche de Kanto) : poste de la Route 28 en aplats provisoires (`FlagGate` Joh9Poste, cases Q
##   **occupées** et non solides : la grille de base du J29 reste exacte, `test_j29_maps`), porte
##   neuve (2, 10) STEP_ON ← vers `route_28_gate` / `from_route_22`, arrivée `from_route_28_gate`
##   (3, 10) ; tout n'existe qu'**avec `johto_arrived`** [D] (le Chapitre Johto commencé) ;
## - `oak_lab` : déclencheur de l'épilogue (7, 8), en montant depuis la porte → `johto_epilogue`
##   (JH-60 ; la scène ne se joue qu'avec `johto_giovanni_seen` + `johto_rival_final_done`, une fois).
## Idempotent : les nœuds `Joh9*` déjà présents sont remplacés.
##
##   godot --headless --path . -s res://tools/build_joh9_route22.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const TILE: int = 96
const STEP_ON: int = 0
## Drapeau d'activation de la variante [D].
const VARIANT_FLAG: StringName = &"johto_arrived"
const COLOR_WALL := Color(0.58, 0.52, 0.46)
const COLOR_ROOF := Color(0.3, 0.36, 0.48)
const COLOR_DOOR := Color(0.18, 0.13, 0.1)

var _errors: int = 0


func _init() -> void:
	_route_22_west()
	_oak_lab()
	print("build_joh9_route22 : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _route_22_west() -> void:
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/route_22_ouest.txt", "JOH9"):
		_fail("variante JOH9 illisible : %s" % plan.error)
		return
	var root := _open(&"route_22_west")
	if root == null:
		return
	for path: NodePath in [^"Entities/Joh9Poste", ^"Warps/Joh9PorteRoute28",
			^"Spawns/from_route_28_gate"]:
		var old := root.get_node_or_null(path)
		if old != null:
			old.get_parent().remove_child(old)
			old.free()
	var walls: Array[Vector2i] = plan.cells_of("Q")
	var door: Vector2i = plan.cell_of("porte_route_28")
	var arrival: Vector2i = plan.cell_of("from_route_28_gate")
	# Cases Q praticables dans la grille de base : occupées par le poste (variante active).
	var base := PlanGrid.new()
	base.load_file("res://tools/plans/route_22_ouest.txt")
	var blocking: Array[Vector2i] = []
	for cell: Vector2i in walls:
		if base.is_walkable(cell):
			blocking.append(cell)
	var min_cell := walls[0]
	var max_cell := walls[0]
	for cell: Vector2i in walls + [door]:
		min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "Joh9Poste"
	gate.position = Vector2(min_cell.x * TILE, (max_cell.y + 1) * TILE)
	var if_flags: Array[StringName] = [VARIANT_FLAG]
	var none: Array[StringName] = []
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", none)
	gate.set(&"blocking_cells", blocking)
	_attach(root, root.get_node(^"Entities"), gate)
	var width := float((max_cell.x - min_cell.x + 1) * TILE)
	var height := float((max_cell.y - min_cell.y + 1) * TILE)
	_rect(root, gate, Rect2(0, -height, width, height), COLOR_WALL)
	_rect(root, gate, Rect2(-8, -height - 30, width + 16, TILE * 0.8), COLOR_ROOF)
	var door_x := float((door.x - min_cell.x) * TILE)
	var door_y := float((door.y - max_cell.y) * TILE)
	_rect(root, gate, Rect2(door_x + TILE - 26, door_y - 84, 22, 76), COLOR_DOOR)
	var warp := Marker2D.new()
	warp.set_script(load("res://game/world/warp_point.gd"))
	warp.name = "Joh9PorteRoute28"
	warp.position = _world(door)
	warp.set(&"trigger", STEP_ON)
	warp.set(&"direction", Vector2i.LEFT)
	warp.set(&"target_map", &"route_28_gate")
	warp.set(&"target_spawn", &"from_route_22")
	warp.set(&"arrival_facing", Vector2i.UP)
	warp.set(&"coming_soon", "")
	warp.set(&"if_flags", if_flags)
	warp.set(&"unless_flags", none)
	_attach(root, root.get_node(^"Warps"), warp)
	var spawn := Marker2D.new()
	spawn.name = "from_route_28_gate"
	spawn.position = _world(arrival)
	_attach(root, root.get_node(^"Spawns"), spawn)
	_save(root, &"route_22_west")


func _oak_lab() -> void:
	var root := _open(&"oak_lab")
	if root == null:
		return
	var old := root.get_node_or_null(^"Triggers/Joh9Epilogue")
	if old != null:
		old.get_parent().remove_child(old)
		old.free()
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = "Joh9Epilogue"
	point.position = _world(Vector2i(7, 8))
	point.set(&"size", Vector2i.ONE)
	point.set(&"direction", Vector2i.UP)
	point.set(&"cutscene_id", &"johto_epilogue")
	_attach(root, root.get_node(^"Triggers"), point)
	_save(root, &"oak_lab")


func _open(map_id: StringName) -> Node:
	var scene := load(MAPS_DIR + "%s.tscn" % map_id) as PackedScene
	if scene == null:
		_fail("carte introuvable : %s" % map_id)
		return null
	return scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)


func _save(root: Node, map_id: StringName) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAPS_DIR + "%s.tscn" % map_id)
	print("%s : %s" % [map_id, "OK" if err == OK else "ERREUR %d" % err])
	if err != OK:
		_errors += 1
	root.free()


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _fail(message: String) -> void:
	push_error("build_joh9_route22 : " + message)
	_errors += 1
