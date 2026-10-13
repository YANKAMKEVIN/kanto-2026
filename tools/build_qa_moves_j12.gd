extends SceneTree
## Construit game/world/maps/qa_moves_j12.tscn : la carte de QA du jalon 12 (jalon-12.md §2.22,
## T15), 24 × 16 cases, tuiles provisoires (`OverworldTiles`), aucune lumière. Copie de
## `tools/build_qa_switch_j13.gd` (J13 T14, `3d58fe6`).
##
##   godot --headless --path . -s res://tools/build_qa_moves_j12.gd
##   godot --headless --path . --import
##
## Carte **inaccessible en jeu** (aucun warp n'y mène) : seulement par les départs de débogage
## `moves_qa` et `moves_qa_solo`. **Retirée au T28** (avec `data/npcs/qa_moves_j12.json`,
## `data/dialogues/qa_moves_j12.json`, `data/trainers/qa_moves_j12.json`, les deux départs, le
## test `test_qa_moves_j12`, l'outil de capture et l'exception de `test_no_qa_map_is_shipped`).
##
## Plan (x, y en cases ; le nord est en haut) :
##   y 3      Dresseur d'essai `smart` (11, 3), tourné vers le bas, vision 5 (couloir x 11,
##            y 4..8, aucun obstacle) : Racaillou (Destruction) puis Rondoudou (Repos) ;
##   y 9      point d'apparition `lane_smart` au pied du couloir ;
##   y 10..13 hautes herbes x 1..6 (table forcée par le départ : Nosferapti, Abo, Rondoudou,
##            Racaillou, Voltorbe ; aucune table en données) ;
##   y 14     sortie sud (10..12) vers le Centre d'Argenta (`from_center`). Pas de gravats.

const OUT_PATH: String = "res://game/world/maps/qa_moves_j12.tscn"
const SIZE := Vector2i(24, 16)
const TILE: int = 96

const EXIT_CELLS: Array[Vector2i] = [Vector2i(10, 14), Vector2i(11, 14), Vector2i(12, 14)]
const EXIT_TARGET: StringName = &"pewter_city"
const EXIT_SPAWN: StringName = &"from_center"
const PUSH: int = 1

## Points d'apparition : `moves_start` (départ, tourné vers le haut), `lane_smart` au pied du
## couloir de vue du Dresseur.
const SPAWNS: Dictionary = {
	"moves_start": Vector2i(11, 12),
	"lane_smart": Vector2i(11, 9),
}

const FIELD := Rect2i(1, 1, 22, 14)
const GRASS_PATCH := Rect2i(1, 10, 6, 4)
const DIRT_RECTS: Array[Rect2i] = [Rect2i(10, 12, 3, 3), Rect2i(7, 9, 9, 1)]

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _kinds: Array = []


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 1212
	var root := Node2D.new()
	root.name = "QaMovesJ12"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"qa_moves_j12")
	root.set(&"display_name", "QA : capacités du J12")
	root.set(&"region", "QA")
	root.set(&"size", SIZE)

	_plan()
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	_paint(ground)
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
	_add_spawns(root)
	_add_warps(root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("qa_moves_j12 : %s" % ("OK" if err == OK else "ERREUR %d" % err))
	root.free()
	quit(0 if err == OK else 1)


func _plan() -> void:
	_kinds.resize(SIZE.x * SIZE.y)
	_kinds.fill(_tiles.Kind["FOREST"])
	_fill(FIELD, "GRASS")
	for rect: Rect2i in DIRT_RECTS:
		_fill(rect, "DIRT")
	_fill(GRASS_PATCH, "TALL_GRASS")


func _fill(rect: Rect2i, kind_name: String) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_kinds[y * SIZE.x + x] = _tiles.Kind[kind_name]


func _paint(layer: TileMapLayer) -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var kind: int = _kinds[y * SIZE.x + x]
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


func _add_spawns(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	var number := 0
	for cell: Vector2i in EXIT_CELLS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "ExitPewter%d" % number
		number += 1
		point.position = _world(cell)
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", EXIT_TARGET)
		point.set(&"target_spawn", EXIT_SPAWN)
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)


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
