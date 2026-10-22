extends SceneTree
## Construit game/world/maps/fuchsia_gym.tscn (l'Arène de Koga, 14 × 20 cases) d'après la grille
## fonctionnelle `tools/plans/parmanie_arene.txt` (jalon 23 T17, `docs/tech/jalon-23.md` §2.13 ;
## dossier 26 §10.1). **La grille fait foi.** Tuiles provisoires `InteriorTiles` (stratégie
## d'accélération : la vue peinte viendra avec le lot d'art), sur le modèle de
## `tools/build_j22_maps.gd`.
##
##   godot --headless --path . -s res://tools/build_fuchsia_gym.gd
##   godot --headless --path . --import
##
## - « K » mur ; « . » parquet ; « X » sortie (PUSH ↓ → `fuchsia_city` / `from_gym`, arrivée
##   tournée vers le bas : spawn posé à Parmanie par la session principale du J23).
## - « i » : **mur invisible** = case bloquée ordinaire ([member GameMap.blocked_cells]),
##   dessinée comme le parquet avec une **variante de lame différente** (indice au sol, N-15 [D] :
##   parquet ordinaire variante 0, sous un « i » variante 1) ; nœud `InvisibleWalls`
##   ([InvisibleWallHint]) pour l'indice au contact.
## - « S » statue : case bloquée (tuile RUG provisoire) + examen, texte 35 (le panneau de
##   l'Arène, comme les statues de RB ; aucun panneau dans la grille).
## - Koga, le Guide et les six Dresseurs : `data/npcs/fuchsia_gym.json` (cases de la grille).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const PLAN_PATH: String = "res://tools/plans/parmanie_arene.txt"
const OUT_PATH: String = "res://game/world/maps/fuchsia_gym.tscn"
const TILE: int = 96
const SIZE := Vector2i(14, 20)
const MAP_ID: StringName = &"fuchsia_gym"
## Titre = nom de la zone (règle de `test_zone_library`, comme les autres Arènes) ; le sous-titre
## (région) nomme l'Arène [D].
const DISPLAY_NAME: String = "Parmanie"
const REGION: String = "Arène de Parmanie"
const LIGHT_PROFILE: StringName = &"interior_warm"
## Warp.Trigger (valeurs).
const PUSH: int = 1
const EXIT_TARGET: StringName = &"fuchsia_city"
const EXIT_SPAWN: StringName = &"from_gym"
## Texte 35 (panneau de l'Arène) porté par les statues.
const STATUE_DIALOGUE: StringName = &"fuchsia_gym_statue"
## Variantes de parquet : ordinaire / sous un mur invisible (indice au sol).
const FLOOR_VARIANT: int = 0
const HINT_VARIANT: int = 1

var _inside: GDScript
var _errors: int = 0


func _init() -> void:
	_inside = load("res://game/world/interior_tiles.gd")
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH) or Vector2i(plan.width, plan.height) != SIZE:
		push_error("build_fuchsia_gym : grille illisible (%s)" % plan.error)
		quit(1)
		return
	_build(plan)
	print("build_fuchsia_gym : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build(plan: Object) -> void:
	var root := _new_map()
	var ground := root.get_node(^"Ground") as TileMapLayer
	var blocked: Array[Vector2i] = []
	var invisible: Array[Vector2i] = []
	var statue_index := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			var kind: int = _inside.Kind.FLOOR_WOOD
			var variant := FLOOR_VARIANT
			match mark:
				"K":
					kind = _inside.Kind.WALL_HOUSE
					variant = _inside.WALL_BASEBOARD if y == SIZE.y - 2 or y == 1 \
						else _inside.WALL_UPPER
				"X":
					kind = _inside.Kind.MAT
				"i":
					variant = HINT_VARIANT
					blocked.append(cell)
					invisible.append(cell)
				"S":
					kind = _inside.Kind.RUG
					blocked.append(cell)
					statue_index += 1
					_interact(root, "Statue%d" % statue_index, cell, STATUE_DIALOGUE)
				".":
					pass
				_:
					_fail("caractère inconnu « %s » en %s" % [mark, cell])
			ground.set_cell(cell, _inside.SOURCE_ID,
				_inside.atlas_coords(kind, mini(variant, _inside.VARIANTS[kind] - 1)))
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array = entry["cells"]
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp":
				for i: int in cells.size():
					_warp(root, "Exit%d" % i, cells[i])
	var hint := Node2D.new()
	hint.name = "InvisibleWalls"
	hint.set_script(load("res://game/world/invisible_walls/invisible_wall_hint.gd"))
	hint.set(&"cells", invisible)
	_attach(root, hint)
	root.set(&"blocked_cells", blocked)
	if invisible.size() != 36:
		_fail("%d murs invisibles (36 attendus)" % invisible.size())
	_save(root)


func _new_map() -> Node2D:
	var root := Node2D.new()
	root.name = "FuchsiaGym"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", MAP_ID)
	root.set(&"display_name", DISPLAY_NAME)
	root.set(&"region", REGION)
	root.set(&"size", SIZE)
	root.set(&"interior", true)
	root.set(&"light_profile", LIGHT_PROFILE)
	var tileset: TileSet = load(_inside.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, node)
	return root


func _spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
	_attach(root, marker, root.get_node(^"Spawns"))


func _warp(root: Node, warp_name: String, cell: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", PUSH)
	point.set(&"direction", Vector2i.DOWN)
	point.set(&"target_map", EXIT_TARGET)
	point.set(&"target_spawn", EXIT_SPAWN)
	point.set(&"arrival_facing", Vector2i.DOWN)
	_attach(root, point, root.get_node(^"Warps"))


func _interact(root: Node, node_name: String, cell: Vector2i, dialogue: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", Vector2i.ZERO)
	point.set(&"dialogue_id", dialogue)
	_attach(root, point, root.get_node(^"Interactables"))


func _save(root: Node) -> void:
	if _errors > 0:
		root.free()
		return
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("%s : %s" % [OUT_PATH, "OK" if err == OK else "ERREUR %d" % err])
	if err != OK:
		_errors += 1
	root.free()


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, child: Node, parent: Node = null) -> void:
	(parent if parent != null else root).add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, layer)
	return layer


func _fail(message: String) -> void:
	push_error("build_fuchsia_gym : " + message)
	_errors += 1
