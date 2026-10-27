extends SceneTree
## Construit la Centrale (jalon 32, lot 32G, N-11 ; grille `tools/plans/power_plant.txt`, relevé
## 1:1 de Rouge/Bleu validé par Kevin le 2026-10-27 ; contrôle `tools/art/plan_check_power_plant.py`),
## en tuiles provisoires (`OverworldTiles`), même méthode que la Grotte Azurée
## (`tools/build_cerulean_cave.gd`), sans eau ni niveaux de sol :
##   - sol : mur ou machine `#` et indice `x` (falaise), sol de l'usine `. E O` (pavé) ;
##   - portes : sud (4..5, 35) STEP_ON ↓ et ouest (0, 11) STEP_ON ←, vers
##     `route_10:from_power_plant` (RB : les deux mènent au même point) ;
##   - objets cachés : point d'examen sur l'indice `x` voisin de la case `objet_cache`
##     (`data/cutscenes/j32_power_plant.json`), jusqu'au drapeau `got_<id>` ;
##   - Électhor, objets visibles et fausses Poké Balls : PNJ de `data/npcs/power_plant.json`.
## Lumière `power_plant` [D] (profil `office`), zone « Centrale ».
##
##   godot --headless --path . -s res://tools/build_power_plant.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const MAP_ID: String = "power_plant"
const STEP_ON: int = 0
const SOLID_CHARS: String = "#x"
const LIGHT: StringName = &"office"
const EXIT_MAP: StringName = &"route_10"
const EXIT_SPAWN: StringName = &"from_power_plant"

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 3232
	_build()
	print("build_power_plant : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build() -> void:
	var plan := _plan(MAP_ID)
	if plan == null:
		return
	var root := _new_map("PowerPlant", StringName(MAP_ID), "Centrale",
		Vector2i(plan.width, plan.height))
	_paint(root, plan)
	var entities: Node = root.get_node(^"Entities")
	_spawn(root, "from_route_10", plan.cells_at("from_route_10")[0])
	var index := 0
	for cell: Vector2i in plan.cells_at("sortie_sud"):
		index += 1
		_warp(root, "SortieSud_%d" % index, cell, Vector2i.DOWN, EXIT_MAP, EXIT_SPAWN, Vector2i.DOWN)
	_warp(root, "SortieOuest", plan.cell_of("porte_ouest"), Vector2i.LEFT, EXIT_MAP, EXIT_SPAWN,
		Vector2i.DOWN)
	for id: String in _ids(plan, "objet_cache"):
		var clue := _clue_of(plan, plan.cell_of(id))
		if clue == Vector2i(-1, -1):
			push_error("build_power_plant : %s sans indice x voisin" % id)
			_errors += 1
			continue
		_hidden(root, entities, clue, StringName(id))
	_save(root, MAPS_DIR + MAP_ID + ".tscn")


## Sol provisoire : murs et machines en falaise, sol de l'usine en pavé.
func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind.CLIFF if SOLID_CHARS.contains(plan.at(cell)) \
				else _over.Kind.COBBLE
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Indice `x` voisin de la case d'où l'on fouille (Vector2i(-1, -1) : aucun).
func _clue_of(plan: Object, stand: Vector2i) -> Vector2i:
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell := stand + step
		if cell.x >= 0 and cell.y >= 0 and cell.x < plan.width and cell.y < plan.height \
				and plan.at(cell) == "x":
			return cell
	return Vector2i(-1, -1)


## Objet caché : caillou clair sur l'indice (toujours visible, comme dans RB) et point
## d'examen jusqu'au drapeau `got_<dialogue>`.
func _hidden(root: Node, entities: Node, clue: Vector2i, dialogue_id: StringName) -> void:
	var pebble := _gate(root, entities, "Indice_%d_%d" % [clue.x, clue.y], clue, [], [])
	_rect(root, pebble, Rect2(-14, -30, 28, 18), Color(0.74, 0.78, 0.84))
	_rect(root, pebble, Rect2(-8, -28, 12, 6), Color(0.88, 0.91, 0.95))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "Cache_%d_%d" % [clue.x, clue.y]
	point.position = _world(clue)
	point.set(&"dialogue_id", dialogue_id)
	var unless: Array[StringName] = [StringName("got_" + String(dialogue_id))]
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Interactables"), point)


## Identifiants des positions de type [param kind], dans l'ordre du fichier.
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
		push_error("build_power_plant : %s" % plan.error)
		_errors += 1
		return null
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String,
		size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", LIGHT)
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


func _warp(root: Node, warp_name: String, cell: Vector2i, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", STEP_ON)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
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
