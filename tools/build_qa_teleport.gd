extends SceneTree
## Construit les deux cartes de QA « téléporteurs et portes à carte » (passe systèmes 2, T28,
## docs/tech/systemes-2.md §2.9, §2.10, §2.14) : `qa_teleport` (4 salles) et `qa_teleport_2`
## (annexe), d'après `tools/plans/qa_teleport.txt` et `qa_teleport_2.txt`. Retirées à la clôture
## de la passe (S2Z).
##
##   python3 tools/art/placeholders_qa_teleport.py
##   godot --headless --path . -s res://tools/build_qa_teleport.gd
##   godot --headless --path . --import
##
## - `teleporteur` : [WarpPoint] STEP_ON, style TELEPORT, `vers=carte:spawn`.
## - `spawn` / `depart` : Marker2D de `Spawns` (`depart` → `start`).
## - `warp` : sorties vers `celadon_city` (`from_center_w`) [D : `qa_mount` n'existe pas ici],
##   PUSH vers le bas.
## - `porte_carte` : [KeyDoor] dans `Entities` (case praticable dans la grille de la scène,
##   occupée par la porte) + [InteractPoint] OUVRIR sur la même case.
## - `objet` : PNJ objet au sol (`data/npcs/qa_teleport_2.json`) ; sa case reste praticable dans la
##   scène (le PNJ l'occupe tant qu'il est là) [D].
## - `but` : point d'examen `qa_teleport_goal`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const STEP_ON: int = 0
const PUSH: int = 1
const STYLE_TELEPORT: int = 1
const KIND_OPEN: int = 5
const SHELL_DIR: String = "res://assets/world/interiors/placeholder/"
const OUT_DIR: String = "res://game/world/maps/"
const DOOR_PATH: String = "res://assets/world/interiors/placeholder/ph_qa_key_door.png"
const DISPLAY_NAME: String = "QA Téléporteurs"
const EXIT_MAP: StringName = &"celadon_city"
const EXIT_SPAWN: StringName = &"from_center_w"
const MAPS: Dictionary[StringName, Array] = {
	&"qa_teleport": ["QaTeleport", Vector2i(20, 13)],
	&"qa_teleport_2": ["QaTeleport2", Vector2i(10, 8)],
}

var _root: Node2D
var _errors: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	var plan := PlanGrid.new()
	var size: Vector2i = MAPS[map_id][1]
	if not plan.load_file("res://tools/plans/%s.txt" % map_id) \
			or Vector2i(plan.width, plan.height) != size:
		push_error("build_qa_teleport : grille %s illisible ou ≠ %s (%s)" % [map_id, size,
			plan.error])
		_errors += 1
		return
	_root = Node2D.new()
	_root.name = MAPS[map_id][0]
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", map_id)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", size)
	_root.set(&"interior", true)
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(SHELL_DIR + "ph_%s.png" % map_id)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : enveloppe %s ≠ %s cases" % [map_id, shell.texture.get_size(), size])
		_errors += 1
		_root.free()
		return
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
	for id: String in plan.positions:
		var cell: Vector2i = plan.cell_of(id)
		match String(plan.positions[id]["kind"]):
			"teleporteur":
				_add_teleporter(id, cell, plan.attr(id, "vers"))
			"spawn", "depart":
				var marker := Marker2D.new()
				marker.name = "start" if plan.positions[id]["kind"] == "depart" else id
				marker.position = _world(cell)
				_attach(_root.get_node(^"Spawns"), marker)
			"warp":
				_add_exit(id, cell)
			"porte_carte":
				_add_key_door(entities, id, cell)
			"but":
				_add_point("Goal", cell, Vector2i.ZERO, &"qa_teleport_goal", 0, [])
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if not (plan.walkable + "oBK").contains(plan.at(cell)) :
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées par la grille)" % [map_id, error_string(err),
		blocked.size()])
	if err != OK:
		_errors += 1
	_root.free()


func _add_teleporter(id: String, cell: Vector2i, vers: String) -> void:
	var point := _warp_marker(id.to_pascal_case(), cell)
	point.set(&"trigger", STEP_ON)
	point.set(&"direction", Vector2i.ZERO)
	point.set(&"style", STYLE_TELEPORT)
	point.set(&"target_map", StringName(vers.get_slice(":", 0)))
	point.set(&"target_spawn", StringName(vers.get_slice(":", 1)))
	point.set(&"arrival_facing", Vector2i.ZERO)


func _add_exit(id: String, cell: Vector2i) -> void:
	var point := _warp_marker(id.to_pascal_case(), cell)
	point.set(&"trigger", PUSH)
	point.set(&"direction", Vector2i.DOWN)
	point.set(&"target_map", EXIT_MAP)
	point.set(&"target_spawn", EXIT_SPAWN)
	point.set(&"arrival_facing", Vector2i.DOWN)


func _warp_marker(node_name: String, cell: Vector2i) -> Marker2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	_attach(_root.get_node(^"Warps"), point)
	return point


func _add_key_door(entities: Node2D, id: String, cell: Vector2i) -> void:
	var door_id := id.trim_prefix("porte_")
	var key_door: GDScript = load("res://game/world/key_door/key_door.gd")
	var flag: StringName = key_door.call(&"open_flag", _root.get(&"map_id"), StringName(door_id))
	var gate := Node2D.new()
	gate.set_script(key_door)
	gate.name = "KeyDoor_%s" % door_id
	gate.position = Vector2(cell.x * TILE, cell.y * TILE)
	gate.set(&"door_id", StringName(door_id))
	gate.set(&"key_item", &"card_key")
	var unless: Array[StringName] = [flag]
	gate.set(&"unless_flags", unless)
	var cells: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", cells)
	_attach(entities, gate)
	var panel := Sprite2D.new()
	panel.name = "Panel"
	panel.texture = load(DOOR_PATH)
	panel.centered = false
	panel.z_index = -2
	_attach(gate, panel)
	_add_point("Open_%s" % door_id, cell, Vector2i.ZERO, &"key_door_locked", KIND_OPEN, [flag])


func _add_point(node_name: String, cell: Vector2i, facing: Vector2i, dialogue: StringName,
		kind: int, unless: Array) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	point.set(&"kind", kind)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", facing)
	var flags: Array[StringName] = []
	flags.assign(unless)
	point.set(&"unless_flags", flags)
	_attach(_root.get_node(^"Interactables"), point)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
