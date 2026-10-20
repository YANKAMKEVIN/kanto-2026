extends SceneTree
## Construit les cartes de QA du jalon 20 (`jalon-20.md` T12, T13), en tuiles provisoires
## (`OverworldTiles`), sans lumière :
##   - `qa_gift_j20` (8 × 6) : une pièce, la Poké Ball d'Évoli (`data/npcs/qa_gift_j20.json`,
##     dialogue et scène réels `celadon_eevee_ball` / `celadon_eevee_gift`) en (3, 1) ; départ
##     `start` (3, 2), tourné ↑.
##
##   godot --headless --path . -s res://tools/build_qa_j20.gd
##   godot --headless --path . --import
##
## Cartes **inaccessibles en jeu** (aucun warp du jeu n'y mène) : tests seulement. **Retirées au
## T24** avec `data/npcs/qa_*j20*.json` (et ce script).

const TILE: int = 96

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2020
	_build_gift_room()
	print("build_qa_j20 : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


# --- Don d'Évoli (T12) ------------------------------------------------------------------------

func _build_gift_room() -> void:
	var size := Vector2i(8, 6)
	var kinds := _grid(size, "FOREST")
	_fill(kinds, size, Rect2i(1, 1, 6, 4), "BOARDWALK")
	var root := _new_map("QaGiftJ20", &"qa_gift_j20", "QA : don d'Évoli (J20)", size, kinds)
	_spawns(root, {"start": Vector2i(3, 2)})
	_save(root, "res://game/world/maps/qa_gift_j20.tscn")


# --- Outils ---------------------------------------------------------------------------------

func _grid(size: Vector2i, kind_name: String) -> Array:
	var kinds: Array = []
	kinds.resize(size.x * size.y)
	kinds.fill(_tiles.Kind[kind_name])
	return kinds


func _fill(kinds: Array, size: Vector2i, rect: Rect2i, kind_name: String) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			kinds[y * size.x + x] = _tiles.Kind[kind_name]


func _new_map(node_name: String, map_id: StringName, display_name: String, size: Vector2i,
		kinds: Array) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", "QA")
	root.set(&"size", size)
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	for y: int in size.y:
		for x: int in size.x:
			var kind: int = kinds[y * size.x + x]
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			ground.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))
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


func _spawns(root: Node, spawns: Dictionary) -> void:
	for spawn_name: String in spawns:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(spawns[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)


func _warp(root: Node, warp_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, point_name: String, cell: Vector2i, dialogue: StringName,
		facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = point_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	point.set(&"facing", facing)
	_attach(root, root.get_node(^"Interactables"), point)


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
