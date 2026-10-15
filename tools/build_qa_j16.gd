extends SceneTree
## Construit les trois cartes de QA du jalon 16 (`jalon-16.md` §2.14, T16), en tuiles provisoires
## (`OverworldTiles`), sans lumière :
##   - `qa_dock_j16`  (24 × 14) : quai, navire amarré (FlagGate `Ship`, polygones provisoires),
##     passerelle vers le navire, arbuste `qa_tree` devant la porte de l'Arène d'essai ;
##   - `qa_ship_j16`  (12 × 9)  : pièce du navire ; sortie sud (5..6, 8) : confirmation PARTIR /
##     PAS ENCORE après la CS01 (déclencheur `qa_ship_exit`), sortie libre avant ;
##   - `qa_gym_j16`   (17 × 15) : la géométrie de `tools/plans/carmin_arene.txt` (validée) : 15
##     objets à fouiller (puzzle `qa_vermilion_gym`), barrière (7..9, 5), Major Bob (8, 3).
##
##   godot --headless --path . -s res://tools/build_qa_j16.gd
##   godot --headless --path . --import
##
## Cartes **inaccessibles en jeu** (aucun warp du jeu n'y mène) : départs de débogage seulement.
## **Retirées au T20** avec `data/{npcs,dialogues,cutscenes}/qa_*j16*.json`, l'entrée
## `qa_vermilion_gym` de `data/world/switch_puzzles.json`, les objets `qa_*` et les départs.
##
## Plan du quai (x, y en cases ; le nord est en haut) :
##   y 0..5   mer ; navire (x 3..20, y 1..4) ; passerelle (11..12, 5), warps vers le navire ;
##   y 6..12  quai ; bloc de l'Arène x 18..22, y 6..9 (couloir x 20 : porte (20, 6), arbuste
##            (20, 9), on le coupe depuis (20, 10)) ;
##   y 13     sortie sud (11..12) vers le Centre de Jadielle (se soigner).

const TILE: int = 96
const PUSH: int = 1
const STEP_ON: int = 0
const QA_PUZZLE: StringName = &"qa_vermilion_gym"

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 1616
	_build_dock()
	_build_ship()
	_build_gym()
	print("build_qa_j16 : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


# --- Quai -----------------------------------------------------------------------------------

func _build_dock() -> void:
	var size := Vector2i(24, 14)
	var kinds := _grid(size, "FOREST")
	_fill(kinds, size, Rect2i(0, 0, 24, 6), "WATER")
	_fill(kinds, size, Rect2i(1, 6, 22, 7), "BOARDWALK")
	_fill(kinds, size, Rect2i(11, 5, 2, 1), "BOARDWALK")
	_fill(kinds, size, Rect2i(18, 6, 5, 4), "FOREST")
	_fill(kinds, size, Rect2i(20, 6, 1, 4), "DIRT")
	_fill(kinds, size, Rect2i(11, 13, 2, 1), "DIRT")
	var root := _new_map("QaDockJ16", &"qa_dock_j16", "QA : quai du S.S. Anne (J16)", size, kinds)
	var ship := FlagGate.new()
	ship.name = "Ship"
	ship.unless_flags = [&"ss_anne_departed"] as Array[StringName]
	_attach(root, root, ship)
	root.move_child(ship, root.get_node(^"Entities").get_index())
	_ship_shapes(root, ship)
	_spawns(root, {
		"dock_start": Vector2i(12, 9), "from_ss_anne": Vector2i(12, 6),
		"cut_start": Vector2i(20, 10), "from_gym": Vector2i(20, 7),
	})
	for x: int in [11, 12]:
		_warp(root, "ToShip%d" % x, Vector2i(x, 5), STEP_ON, Vector2i.UP, &"qa_ship_j16",
			&"from_dock", Vector2i.UP)
		_warp(root, "ExitViridian%d" % x, Vector2i(x, 13), PUSH, Vector2i.DOWN, &"viridian_city",
			&"from_center", Vector2i.DOWN)
	_warp(root, "ToGym", Vector2i(20, 6), STEP_ON, Vector2i.UP, &"qa_gym_j16", &"entrance",
		Vector2i.UP)
	_save(root, "res://game/world/maps/qa_dock_j16.tscn")


## Navire provisoire : coque sombre, superstructure claire, cheminée ; cases x 3..20, y 1..4.
func _ship_shapes(root: Node, ship: Node2D) -> void:
	var parts: Array = [
		[Color(0.13, 0.17, 0.3), [Vector2(3, 3), Vector2(21, 3), Vector2(20, 5), Vector2(4, 5)]],
		[Color(0.93, 0.93, 0.9), [Vector2(6, 1.6), Vector2(17, 1.6), Vector2(17, 3), Vector2(6, 3)]],
		[Color(0.75, 0.2, 0.18), [Vector2(9, 0.6), Vector2(10.4, 0.6), Vector2(10.4, 1.6),
			Vector2(9, 1.6)]],
		[Color(0.75, 0.2, 0.18), [Vector2(13, 0.6), Vector2(14.4, 0.6), Vector2(14.4, 1.6),
			Vector2(13, 1.6)]],
	]
	var index := 0
	for part: Array in parts:
		var polygon := Polygon2D.new()
		polygon.name = "Part%d" % index
		index += 1
		polygon.color = part[0]
		var points := PackedVector2Array()
		for p: Vector2 in part[1]:
			points.append(p * TILE)
		polygon.polygon = points
		_attach(root, ship, polygon)


# --- Navire ---------------------------------------------------------------------------------

func _build_ship() -> void:
	var size := Vector2i(12, 9)
	var kinds := _grid(size, "FOREST")
	_fill(kinds, size, Rect2i(1, 1, 10, 7), "BOARDWALK")
	_fill(kinds, size, Rect2i(5, 8, 2, 1), "BOARDWALK")
	var root := _new_map("QaShipJ16", &"qa_ship_j16", "QA : S.S. Anne (J16)", size, kinds)
	_spawns(root, {"from_dock": Vector2i(5, 7), "exit_start": Vector2i(5, 5)})
	var triggers := root.get_node(^"Triggers")
	var trigger := EventTriggerPoint.new()
	trigger.name = "ShipExit"
	trigger.position = _world(Vector2i(5, 8))
	trigger.cutscene_id = &"qa_ship_exit"
	trigger.size = Vector2i(2, 1)
	trigger.direction = Vector2i.DOWN
	_attach(root, triggers, trigger)
	for x: int in [5, 6]:
		_warp(root, "ToDock%d" % x, Vector2i(x, 8), PUSH, Vector2i.DOWN, &"qa_dock_j16",
			&"from_ss_anne", Vector2i.DOWN)
	_save(root, "res://game/world/maps/qa_ship_j16.tscn")


# --- Arène ----------------------------------------------------------------------------------

func _build_gym() -> void:
	var size := Vector2i(17, 15)
	var kinds := _grid(size, "FOREST")
	_fill(kinds, size, Rect2i(2, 2, 13, 11), "COBBLE")
	_fill(kinds, size, Rect2i(2, 5, 13, 1), "CLIFF")
	_fill(kinds, size, Rect2i(7, 5, 3, 1), "COBBLE")
	_fill(kinds, size, Rect2i(7, 13, 3, 1), "COBBLE")
	var slots: Array[Vector2i] = []
	for y: int in [7, 9, 11]:
		for x: int in [2, 5, 8, 11, 14]:
			slots.append(Vector2i(x, y))
			_fill(kinds, size, Rect2i(x, y, 1, 1), "CROP")
	var root := _new_map("QaGymJ16", &"qa_gym_j16", "QA : Arène de Carmin (J16)", size, kinds)
	_spawns(root, {"entrance": Vector2i(8, 12)})
	var interactables := root.get_node(^"Interactables")
	for i: int in slots.size():
		var point := InteractPoint.new()
		point.name = "Bin%02d" % (i + 1)
		point.position = _world(slots[i])
		point.dialogue_id = &"qa_gym_trash"
		point.puzzle = QA_PUZZLE
		point.puzzle_slot = i + 1
		_attach(root, interactables, point)
	for x: int in [7, 8, 9]:
		_warp(root, "ExitDock%d" % x, Vector2i(x, 13), PUSH, Vector2i.DOWN, &"qa_dock_j16",
			&"from_gym", Vector2i.DOWN)
	_save(root, "res://game/world/maps/qa_gym_j16.tscn")


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
