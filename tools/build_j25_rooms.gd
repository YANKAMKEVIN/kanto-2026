extends SceneTree
## Construit les deux salles du jalon 25 qui ne sont pas le Manoir (T18, T20 ; dossier 28 §7, §8 ;
## `jalon-25.md` §2.3, §2.6), en tuiles provisoires (`OverworldTiles`), d'après les grilles
## `tools/plans/cramois_arene.txt` et `argenta_musee_reserve.txt` (la grille fait foi ; contrôle
## `tools/art/plan_check_cramois.py`). L'art de la série 28 n'est pas encore intégré : aplats.
##
## `cinnabar_gym` (Arène d'Auguste) :
##   - herses `p` : un [FlagGate] bloquant par case, fermé tant qu'aucun de `cinnabar_gym_gate_<n>`
##     (bonne réponse) et `beaten_<Dresseur lié>` (victoire) n'est levé ;
##   - machines `Q` : décor bloquant + point d'examen `cinnabar_gym_quiz_<n>` (face à elle) ;
##   - statue de l'Arène : décor bloquant ; seuil `E` : PUSH ↓ vers `cinnabar_island` / `from_arene`.
## `pewter_museum_reserve` (réserve du Musée d'Argenta) : comptoir, caisses, vitrine de l'ambre
##   (point d'examen `pewter_museum_reserve_showcase`), paillasson PUSH ↓ vers `pewter_city` /
##   `from_museum_reserve`.
## PNJ (Auguste, guide, Dresseurs, scientifiques) : `data/npcs/<carte>.json`
## (`tools/gen_j25_world_data.py`).
##
##   godot --headless --path . -s res://tools/build_j25_rooms.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const STEP_ON: int = 0
const PUSH: int = 1

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2526
	_build_gym()
	_build_reserve()
	print("build_j25_rooms : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_gym() -> void:
	var plan := _plan("cramois_arene")
	var root := _new_map("CinnabarGym", &"cinnabar_gym", "Cramois'Île",
		Vector2i(plan.width, plan.height))
	var entities: Node = root.get_node(^"Entities")
	_paint(root, plan, "#Q", _over.Kind.COBBLE)
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	var index := 0
	for cell: Vector2i in plan.cells_at("entree"):
		index += 1
		_warp(root, "Entree_%d" % index, cell, PUSH, Vector2i.DOWN, &"cinnabar_island",
			&"from_arene", Vector2i.DOWN, [])
	# Herses : machine n → herse n, Dresseur lié.
	var trainer_of: Dictionary = {}
	for id: String in _ids(plan, "quiz"):
		trainer_of[plan.attr(id, "herse")] = plan.attr(id, "dresseur")
		var cell: Vector2i = plan.cell_of(id)
		var gate := _gate(root, entities, "Machine_%s" % plan.attr(id, "herse"), cell, [], [])
		var blocking: Array[Vector2i] = [cell]
		gate.set(&"blocking_cells", blocking)
		_rect(root, gate, Rect2(-34, -96, 68, 92), Color(0.3, 0.32, 0.36))
		_rect(root, gate, Rect2(-24, -84, 48, 30), Color(0.4, 0.8, 0.95))
		var point := _point(root, "MachinePoint_%s" % plan.attr(id, "herse"), cell,
			StringName("cinnabar_gym_quiz_" + plan.attr(id, "herse")))
		point.set(&"facing", Vector2i.UP)
	for id: String in _ids(plan, "herse"):
		var n := id.trim_prefix("herse_")
		var unless: Array = [StringName(plan.attr(id, "drapeau")),
			StringName("beaten_" + String(trainer_of[n]))]
		for cell: Vector2i in plan.cells_at(id):
			var gate := _gate(root, entities, "Herse%s_%d_%d" % [n, cell.x, cell.y], cell, [],
				unless)
			var blocking: Array[Vector2i] = [cell]
			gate.set(&"blocking_cells", blocking)
			_rect(root, gate, Rect2(-46, -100, 92, 10), Color(0.35, 0.12, 0.08))
			for x: int in [-38, -18, 2, 22]:
				_rect(root, gate, Rect2(x, -96, 10, 92), Color(0.62, 0.3, 0.16))
	var statue: Vector2i = plan.cell_of("statue_arene")
	var deco := _gate(root, entities, "StatueArene", statue, [], [])
	var cells: Array[Vector2i] = [statue]
	deco.set(&"blocking_cells", cells)
	_rect(root, deco, Rect2(-36, -30, 72, 26), Color(0.3, 0.26, 0.24))
	_rect(root, deco, Rect2(-24, -110, 48, 82), Color(0.6, 0.36, 0.22))
	_save(root, MAPS_DIR + "cinnabar_gym.tscn")


func _build_reserve() -> void:
	var plan := _plan("argenta_musee_reserve")
	var root := _new_map("PewterMuseumReserve", &"pewter_museum_reserve", "Argenta",
		Vector2i(plan.width, plan.height))
	var entities: Node = root.get_node(^"Entities")
	_paint(root, plan, "Ktvr", _over.Kind.BOARDWALK)
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	var index := 0
	for cell: Vector2i in plan.cells_at("sortie"):
		index += 1
		_warp(root, "Sortie_%d" % index, cell, PUSH, Vector2i.DOWN, &"pewter_city",
			&"from_museum_reserve", Vector2i.RIGHT, [])
	for cell: Vector2i in plan.cells_of("t"):
		_block(root, entities, cell, Color(0.5, 0.34, 0.2))
	for cell: Vector2i in plan.cells_of("r"):
		_block(root, entities, cell, Color(0.62, 0.5, 0.32))
	var showcase: Vector2i = plan.cell_of("vitrine_ambre")
	var full := _gate(root, entities, "VitrinePleine", showcase, [],
		[&"pewter_museum_got_old_amber"])
	_rect(root, full, Rect2(-20, -70, 40, 30), Color(0.95, 0.66, 0.2))
	_block(root, entities, showcase, Color(0.7, 0.84, 0.9, 0.6))
	_point(root, "VitrinePoint", showcase, &"pewter_museum_reserve_showcase")
	_save(root, MAPS_DIR + "pewter_museum_reserve.tscn")


func _paint(root: Node, plan: Object, solid: String, floor_kind: int) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = floor_kind
			if solid.contains(plan.at(cell)):
				kind = _over.Kind.CLIFF
			elif plan.at(cell) in ["E", "X"]:
				kind = _over.Kind.DIRT
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Meuble provisoire bloquant (aplat).
func _block(root: Node, entities: Node, cell: Vector2i, color: Color) -> void:
	var gate := _gate(root, entities, "Meuble_%d_%d" % [cell.x, cell.y], cell, [], [])
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-46, -76, 92, 72), color)


func _point(root: Node, point_name: String, cell: Vector2i, dialogue_id: StringName) -> Marker2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = point_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue_id)
	_attach(root, root.get_node(^"Interactables"), point)
	return point


func _hidden(root: Node, cell: Vector2i, dialogue_id: StringName) -> void:
	var point := _point(root, "Cache_%d_%d" % [cell.x, cell.y], cell, dialogue_id)
	var unless: Array[StringName] = [StringName("got_" + String(dialogue_id))]
	point.set(&"unless_flags", unless)


func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array,
		unless: Array) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	var typed_if: Array[StringName] = []
	typed_if.assign(if_flags)
	var typed_unless: Array[StringName] = []
	typed_unless.assign(unless)
	gate.set(&"if_flags", typed_if)
	gate.set(&"unless_flags", typed_unless)
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_j25_rooms : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String,
		size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"size", size)
	root.set(&"interior", true)
	root.set(&"light_profile", &"interior_warm")
	var tileset: TileSet = load(_over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	return root


func _spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
	_attach(root, root.get_node(^"Spawns"), marker)


func _warp(root: Node, warp_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i, unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Warps"), point)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s" % [path, "OK" if err == OK else "ERREUR %d" % err])
	if err != OK:
		_errors += 1
	root.free()


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer
