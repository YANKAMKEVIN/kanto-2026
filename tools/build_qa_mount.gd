extends SceneTree
## Construit les cartes de QA de la monture (passe systèmes 2, `systemes-2.md` §2.2 à §2.4, §2.14,
## T9), en tuiles provisoires (`OverworldTiles`, `InteriorTiles`), sans lumière, d'après les
## grilles `tools/plans/qa_mount*.txt` (la grille fait foi) :
##   - `qa_mount` (20 × 20, extérieur) : rebord (rangée 14), maison (porte → `qa_mount_interieur`),
##     dormeur 2 × 1 (10..11, 4) qui ferme le nord, entrées de la Piste (19, 8) et (19, 16) ;
##   - `qa_mount_interieur` (8 × 6, `interior`) : on y entre à pied, tapis de sortie (3..4, 5) ;
##   - `qa_mount_piste` (11 × 20, `cycling_road`) : pente « / » (`slope_cells`), paliers, Dresseur
##     de l'alcôve (9, 11) (`data/npcs/qa_mount_piste.json`).
## Écart [D] : `cycling_road` est un booléen par carte, la Piste est donc une carte à part.
## Le dormeur : `FlagGate` bloquant (drapeau `qa_mount_sleeper_woken`) + `InteractPoint` 2 × 1 dont
## `flute_cutscene` = `qa_mount_sleeper` (données : `data/cutscenes/qa_mount.json`).
##
##   godot --headless --path . -s res://tools/build_qa_mount.gd
##   godot --headless --path . --import
##
## Cartes **inaccessibles en jeu** (aucun warp du jeu n'y mène) : départ de débogage `s2_bike`
## seulement. **Retirées à la clôture de la passe (S2Z)** avec leurs données `qa_mount*` et ce script.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const SLEEPER_FLAG: StringName = &"qa_mount_sleeper_woken"
const SLEEPER_FRAMES: String = "res://assets/sprites/pokemon/painted/snorlax_frames.tres"
const SHADOW_TEXTURE: String = "res://assets/sprites/characters/placeholder/shadow.png"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1

var _over: GDScript
var _inside: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_inside = load("res://game/world/interior_tiles.gd")
	_rng.seed = 2902
	_build_mount()
	_build_interior()
	_build_piste()
	print("build_qa_mount : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


# --- qa_mount : extérieur ---------------------------------------------------------------------

func _build_mount() -> void:
	var plan := _plan("qa_mount")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaMount", &"qa_mount", "QA Monture", size, false)
	_paint_overworld(root, plan, {
		"#": "FOREST", "H": "CLIFF", "v": "LEDGE_DOWN", "=": "COBBLE", "D": "BOARDWALK",
		".": "GRASS",
	})
	_spawn(root, "depart", plan.cell_of("depart"))
	_spawn(root, "from_interieur", plan.cell_of("from_interieur"))
	_spawn(root, "from_piste_n", plan.cell_of("from_piste_n"))
	_spawn(root, "from_piste_s", plan.cell_of("from_piste_s"))
	_warp(root, "PorteMaison", plan.cell_of("porte_maison"), STEP_ON, Vector2i.UP,
		&"qa_mount_interieur", &"entree", Vector2i.UP)
	_warp(root, "EntreePisteN", plan.cell_of("entree_piste_n"), PUSH, Vector2i.RIGHT,
		&"qa_mount_piste", &"from_mount_n", Vector2i.RIGHT)
	_warp(root, "EntreePisteS", plan.cell_of("entree_piste_s"), PUSH, Vector2i.RIGHT,
		&"qa_mount_piste", &"from_mount_s", Vector2i.RIGHT)
	_add_sleeper(root, plan.cells_at("dormeur"))
	_save(root, MAPS_DIR + "qa_mount.tscn")


## Dormeur 2 × 1 : décor bloquant tant que le drapeau n'est pas levé, point d'examen et cible de
## la Poké Flûte (`flute_cutscene`).
func _add_sleeper(root: Node, cells: Array[Vector2i]) -> void:
	var left := cells[0]
	var right := cells[-1]
	var entities: Node = root.get_node(^"Entities")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "Sleeper"
	gate.position = Vector2(float((right.x + 1) * TILE - TILE), float((right.y + 1) * TILE))
	var unless: Array[StringName] = [SLEEPER_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_attach(root, entities, gate)
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = load(SHADOW_TEXTURE)
	shadow.position = Vector2(0.0, -8.0)
	shadow.scale = Vector2(3.0, 2.0)
	_attach(root, gate, shadow)
	var frames := load(SLEEPER_FRAMES) as SpriteFrames
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.animation = &"idle_down"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(0.75, 0.75)
	sprite.offset = Vector2(0.0, -frames.get_frame_texture(&"idle_down", 0).get_size().y / 2.0)
	_attach(root, gate, sprite)
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "SleeperPoint"
	point.position = _world(left)
	point.set(&"size", Vector2i(cells.size(), 1))
	point.set(&"dialogue_id", &"qa_mount_sleeper_examine")
	point.set(&"unless_flags", unless)
	point.set(&"flute_cutscene", &"qa_mount_sleeper")
	_attach(root, root.get_node(^"Interactables"), point)


# --- qa_mount_interieur -----------------------------------------------------------------------

func _build_interior() -> void:
	var plan := _plan("qa_mount_interieur")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaMountInterieur", &"qa_mount_interieur", "QA Maison", size, true)
	var tileset: TileSet = load(_inside.TILESET_PATH)
	for node: Node in root.get_children():
		if node is TileMapLayer:
			(node as TileMapLayer).tile_set = tileset
	var ground := root.get_node(^"Ground") as TileMapLayer
	var obstacles := root.get_node(^"Obstacles") as TileMapLayer
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var char: String = plan.at(cell)
			var kind: int = _inside.Kind.FLOOR_WOOD
			if char == "E":
				kind = _inside.Kind.MAT
			elif char == "#":
				kind = _inside.Kind.WALL_HOUSE
			var variant := _rng.randi_range(0, _inside.VARIANTS[kind] - 1)
			if char == "#":
				variant = _inside.WALL_UPPER
				obstacles.set_cell(cell, _inside.SOURCE_ID, _inside.atlas_coords(kind, variant))
			else:
				ground.set_cell(cell, _inside.SOURCE_ID, _inside.atlas_coords(kind, variant))
	_spawn(root, "entree", plan.cell_of("entree"))
	_warp(root, "SortieO", plan.cell_of("sortie_o"), PUSH, Vector2i.DOWN, &"qa_mount",
		&"from_interieur", Vector2i.DOWN)
	_warp(root, "SortieE", plan.cell_of("sortie_e"), PUSH, Vector2i.DOWN, &"qa_mount",
		&"from_interieur", Vector2i.DOWN)
	_save(root, MAPS_DIR + "qa_mount_interieur.tscn")


# --- qa_mount_piste ---------------------------------------------------------------------------

func _build_piste() -> void:
	var plan := _plan("qa_mount_piste")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaMountPiste", &"qa_mount_piste", "QA Piste", size, false)
	root.set(&"cycling_road", true)
	var slopes: Array[Vector2i] = []
	slopes.assign(plan.cells_of("/"))
	root.set(&"slope_cells", slopes)
	_paint_overworld(root, plan, {
		"#": "FOREST", "/": "SAND", "=": "COBBLE", ".": "DIRT",
	})
	_spawn(root, "from_mount_n", plan.cell_of("from_mount_n"))
	_spawn(root, "from_mount_s", plan.cell_of("from_mount_s"))
	_warp(root, "SortieN", plan.cell_of("sortie_n"), PUSH, Vector2i.LEFT, &"qa_mount",
		&"from_piste_n", Vector2i.LEFT)
	_warp(root, "SortieS", plan.cell_of("sortie_s"), PUSH, Vector2i.LEFT, &"qa_mount",
		&"from_piste_s", Vector2i.LEFT)
	_save(root, MAPS_DIR + "qa_mount_piste.tscn")


# --- Outils -----------------------------------------------------------------------------------

func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_qa_mount : %s" % plan.error)
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
