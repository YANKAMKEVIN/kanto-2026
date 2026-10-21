extends SceneTree
## Construit les cartes de QA du Surf (passe systèmes 2, `systemes-2.md` §2.5, §2.6, §2.14, T16),
## en tuiles provisoires (`OverworldTiles`), sans lumière, d'après les grilles
## `tools/plans/qa_sea.txt` et `qa_sea_2.txt` (la grille fait foi) :
##   - `qa_sea` (26 × 18) : plage (x 1..6), mer surfable (`w`), eau décor (`~`, jamais atteinte),
##     îlot (16..18, 8..9), courant `>` puis `v` qui finit sur le passage (21, 10) → `qa_sea_2`,
##     Nageur (15, 13) (`data/npcs/qa_sea.json`), bord est (25, 11..14) → `qa_sea_2`, sorties sud
##     (2..3, 17) → `qa_mount:depart` ;
##   - `qa_sea_2` (12 × 18) : mer, rive est (9..10), arrivées en Surf forcé `s`, bord ouest
##     (0, 11..14) → `qa_sea`.
## L'eau surfable (`w > v s`) est posée avec `surf_cells` ; `>` `v` remplissent `current_cells` (sens
## du flux) ; `s` remplit `forced_surf_cells`. `fishable_cells` [D] : colonne x = 7 de `qa_sea`,
## rangées 2..16 (le long de la plage).
##
##   godot --headless --path . -s res://tools/build_qa_sea.gd
##   godot --headless --path . --import
##
## Cartes **inaccessibles en jeu** : départ de débogage `s2_surf` seulement. **Retirées à la clôture
## de la passe (S2Z)** avec leurs données `qa_sea*` et ce script.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
const FISHABLE_COLUMN: int = 7

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2905
	_build_sea()
	_build_sea_2()
	print("build_qa_sea : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_sea() -> void:
	var plan := _plan("qa_sea")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaSea", &"qa_sea", "QA Surf", size, false)
	_paint(root, plan)
	_sea_data(root, plan)
	var fishable: Array[Vector2i] = []
	for y: int in range(2, 17):
		fishable.append(Vector2i(FISHABLE_COLUMN, y))
	root.set(&"fishable_cells", fishable)
	_spawn(root, "depart", plan.cell_of("depart"))
	_spawn(root, "from_east", plan.cell_of("from_east"))
	_warp(root, "SortieO", plan.cell_of("sortie_o"), PUSH, Vector2i.DOWN, &"qa_mount",
		&"depart", Vector2i.DOWN)
	_warp(root, "SortieE", plan.cell_of("sortie_e"), PUSH, Vector2i.DOWN, &"qa_mount",
		&"depart", Vector2i.DOWN)
	_warp(root, "PassageCourant", plan.cell_of("passage_courant"), STEP_ON, Vector2i.DOWN,
		&"qa_sea_2", &"from_current", Vector2i.DOWN)
	var index := 0
	for cell: Vector2i in plan.cells_at("bord_est"):
		index += 1
		_warp(root, "BordEst%d" % index, cell, PUSH, Vector2i.RIGHT, &"qa_sea_2", &"from_west",
			Vector2i.RIGHT)
	_save(root, MAPS_DIR + "qa_sea.tscn")


func _build_sea_2() -> void:
	var plan := _plan("qa_sea_2")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaSea2", &"qa_sea_2", "QA Surf 2", size, false)
	_paint(root, plan)
	_sea_data(root, plan)
	_spawn(root, "depart", plan.cell_of("depart"))
	_spawn(root, "from_current", plan.cell_of("from_current"))
	_spawn(root, "from_west", plan.cell_of("from_west"))
	var index := 0
	for cell: Vector2i in plan.cells_at("bord_ouest"):
		index += 1
		_warp(root, "BordOuest%d" % index, cell, PUSH, Vector2i.LEFT, &"qa_sea", &"from_east",
			Vector2i.LEFT)
	_save(root, MAPS_DIR + "qa_sea_2.tscn")


## Sol : falaise `#`, sable `.` et `E`, eau pour tout le reste (surfable ou décor).
func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind.WATER
			match plan.at(cell):
				"#":
					kind = _over.Kind.CLIFF
				".", "E":
					kind = _over.Kind.SAND
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Données de la mer : eau surfable, courants (sens du flux), arrivées en Surf forcé.
func _sea_data(root: Node, plan: Object) -> void:
	var surf: Array[Vector2i] = []
	surf.assign(plan.cells_of("w>vs"))
	root.set(&"surf_cells", surf)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	for cell: Vector2i in plan.cells_of(">"):
		currents[cell] = Vector2i.RIGHT
	for cell: Vector2i in plan.cells_of("v"):
		currents[cell] = Vector2i.DOWN
	root.set(&"current_cells", currents)
	var forced: Array[Vector2i] = []
	forced.assign(plan.cells_of("s"))
	root.set(&"forced_surf_cells", forced)


# --- Outils -----------------------------------------------------------------------------------

func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_qa_sea : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String, size: Vector2i,
		interior: bool) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", "QA")
	root.set(&"size", size)
	root.set(&"interior", interior)
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


## Peint le sol de la carte : un type de tuile par caractère de la grille.
func _paint_overworld(root: Node, plan: Object, kinds: Dictionary) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind_name: String = kinds[plan.at(cell)]
			var kind: int = _over.Kind[kind_name]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


func _spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
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
