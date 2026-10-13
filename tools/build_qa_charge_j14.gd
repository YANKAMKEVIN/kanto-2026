extends SceneTree
## Construit game/world/maps/qa_charge_j14.tscn : la carte de QA du jalon 14 (jalon-14.md §2.18,
## T10), 24 x 14 cases, tuiles provisoires (`OverworldTiles`), aucune lumière.
##
##   godot --headless --path . -s res://tools/build_qa_charge_j14.gd
##   godot --headless --path . --import
##
## Carte **inaccessible en jeu** (aucun warp n'y mène) : seulement par les départs de débogage
## `charge_qa` et `teleport_qa`. Retirée au T24 du J14 (avec les départs).
##
## Plan (x, y en cases ; le nord est en haut) : cadre de forêt, grande clairière d'herbe rase,
## sentier de terre (x 8..14), hautes herbes 6 x 4 à l'ouest (x 2..7, y 8..11 : table forcée
## Abra / Machoc par le départ), trois Dresseurs à l'est en x 15, tournés vers l'ouest, vision 4
## (voir TRAINER_SLOTS) ; sortie sud (10..12, 12) vers Jadielle, devant le Centre (soin).

const OUT_PATH: String = "res://game/world/maps/qa_charge_j14.tscn"
const SIZE := Vector2i(24, 14)
const TILE: int = 96

const EXIT_CELLS: Array[Vector2i] = [Vector2i(10, 12), Vector2i(11, 12), Vector2i(12, 12)]
const EXIT_TARGET: StringName = &"viridian_city"
const EXIT_SPAWN: StringName = &"from_center"
const PUSH: int = 1

## Points d'apparition des départs de débogage.
## `charge_start` : sur le sentier, vers l'est (le premier Dresseur voit le joueur au 2e pas) ;
## `teleport_start` : au bord des hautes herbes, tourné vers elles.
const SPAWNS: Dictionary = {
	"charge_start": Vector2i(8, 6),
	"teleport_start": Vector2i(5, 7),
}

const CLEARING := Rect2i(1, 1, 22, 11)
const PATH := Rect2i(8, 1, 7, 11)
const EXIT_PATH := Rect2i(10, 12, 3, 1)
const TALL := Rect2i(2, 8, 6, 4)

## Cases des Dresseurs [cellule, orientation] (data/npcs/qa_charge_j14.json), tous tournés vers
## l'ouest : leur ligne de vue (4 cases) coupe le sentier en x 11..14.
const TRAINER_SLOTS: Dictionary = {
	"trainer_dig": Vector2i(15, 3),
	"trainer_sleep": Vector2i(15, 6),
	"trainer_para": Vector2i(15, 9),
}

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _kinds: Array = []


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 1414
	var root := Node2D.new()
	root.name = "QaChargeJ14"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"qa_charge_j14")
	root.set(&"display_name", "QA : Charge (J14)")
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
	print("qa_charge_j14 : %s" % ("OK" if err == OK else "ERREUR %d" % err))
	root.free()
	quit(0 if err == OK else 1)


func _plan() -> void:
	_kinds.resize(SIZE.x * SIZE.y)
	_kinds.fill(_tiles.Kind["FOREST"])
	_fill(CLEARING, "GRASS")
	_fill(PATH, "DIRT")
	_fill(EXIT_PATH, "DIRT")
	_fill(TALL, "TALL_GRASS")


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
		point.name = "ExitViridian%d" % number
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
