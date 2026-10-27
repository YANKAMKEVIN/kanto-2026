extends SceneTree
## Construit les trois étages de la Grotte Azurée (jalon 31, T6 à T8 ; `docs/tech/jalon-31.md`
## §2.2, §10), en tuiles provisoires (`OverworldTiles`), d'après les grilles
## `tools/plans/cerulean_cave_1f.txt`, `_2f.txt`, `_b1f.txt` (la grille fait foi ; contrôle
## `tools/art/plan_check_cerulean_cave.py`). Même méthode que les Îles Écume du J24
## (`tools/build_j24_seafoam.gd`), sans rochers, trous ni courants.
##
## Par étage :
##   - sol : roche `#` et indice `x` (falaise), sol bas `. U V E` (terre), sol haut `:` (pavé),
##     escalier `=` (planches), eau surfable `w` ;
##   - eau : `surf_cells` et `fishable_cells` (Super Canne, groupe 9 de RB :
##     `super_rod_cerulean_cave` de `data/fishing/water_rod.json`) ;
##   - [CaveLevelGate] `NiveauxDeSol` : niveaux de sol (collisions par paires de RB) ;
##   - échelles : [WarpPoint] STEP_ON vers `arrivee_<paire>` de l'autre étage ; bouche du 1F :
##     STEP_ON ↓ vers Azuria (`cerulean_city:from_cerulean_cave`, entrée 31A) ;
##   - objets cachés : point d'examen sur l'indice `x` voisin de la case `objet_cache`
##     (`data/cutscenes/cerulean_cave.json`), jusqu'au drapeau `got_<id>`.
## Objets visibles et Mewtwo (B1F) sont des PNJ de `data/npcs/cerulean_cave_*.json` (scène
## `mewtwo` : rencontre fixe, absente une fois `mewtwo_encounter_resolved` posé). Pas de voile :
## la grotte est éclairée (RB) ; lumière par étage dans `data/world/lighting.json`.
##
##   godot --headless --path . -s res://tools/build_cerulean_cave.gd
##   godot --headless --path . --import
## Puis les passes d'image (lot DAF.4), sans quoi l'art peint est perdu : `build_route_22_west.gd`,
## `build_daf4_caves.gd`, `build_daf4_facades.gd` (dans cet ordre, après `build_j29.gd` et
## `build_cerulean_cave.gd`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const FLOORS: Array[String] = ["cerulean_cave_1f", "cerulean_cave_2f", "cerulean_cave_b1f"]
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const SOLID_CHARS: String = "#x"
const LOW_CHARS: String = ".w"
## Lumière par étage (`data/world/lighting.json`) : profils des grottes du J12 [D], comme les
## Îles Écume (le 2F et le 1F au même profil, le B1F plus sombre).
const LIGHTS: Dictionary = {"cerulean_cave_1f": &"cave_1f", "cerulean_cave_2f": &"cave_1f",
	"cerulean_cave_b1f": &"cave_b1f"}
## Bouche du 1F : point d'arrivée sur la carte d'Azuria (entrée 31A).
const EXIT_MAP: StringName = &"cerulean_city"
const EXIT_SPAWN: StringName = &"from_cerulean_cave"
## Arrivée de débogage (départ `cerulean_cave_mewtwo`) : devant Mewtwo, au nord de sa case, comme
## `moltres_front` du J29.
const DEBUG_SPAWNS: Dictionary = {"cerulean_cave_b1f": {"mewtwo_front": Vector2i(27, 12)}}

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 3131
	for id: String in FLOORS:
		_build_floor(id)
	print("build_cerulean_cave : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_floor(map_id: String) -> void:
	var plan := _plan(map_id)
	if plan == null:
		return
	var size := Vector2i(plan.width, plan.height)
	var node_name := "CeruleanCave" + map_id.trim_prefix("cerulean_cave_").to_upper()
	var root := _new_map(node_name, StringName(map_id), "Grotte Azurée", size)
	_paint(root, plan)
	var entities: Node = root.get_node(^"Entities")
	var water: Array[Vector2i] = []
	water.assign(plan.cells_of("w"))
	root.set(&"surf_cells", water)
	root.set(&"fishable_cells", water.duplicate())
	_levels(root, entities, plan)
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	var debug: Dictionary = DEBUG_SPAWNS.get(map_id, {})
	for spawn_name: String in debug:
		_spawn(root, spawn_name, debug[spawn_name])
	for id: String in _ids(plan, "echelle"):
		var cell: Vector2i = plan.cell_of(id)
		var pair: String = plan.attr(id, "paire").to_lower()
		_warp(root, "Echelle_" + pair, cell, Vector2i.ZERO, StringName(plan.attr(id, "vers")),
			StringName("arrivee_" + pair), Vector2i.DOWN)
		_ladder(root, entities, cell, plan.attr(id, "sens") == "monte")
	for id: String in _ids(plan, "warp"):
		var index := 0
		for cell: Vector2i in plan.cells_at(id):
			index += 1
			_warp(root, "Sortie_%d" % index, cell, Vector2i.DOWN, EXIT_MAP, EXIT_SPAWN,
				Vector2i.DOWN)
	for id: String in _ids(plan, "objet_cache"):
		var clue := _clue_of(plan, plan.cell_of(id))
		if clue == Vector2i(-1, -1):
			push_error("build_cerulean_cave : %s sans indice x voisin" % id)
			_errors += 1
			continue
		_hidden(root, entities, clue, StringName(id))
	_save(root, MAPS_DIR + map_id + ".tscn")


## Sol provisoire : un type de tuile par caractère.
func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var c: String = plan.at(cell)
			var kind: int = _over.Kind.DIRT
			if SOLID_CHARS.contains(c):
				kind = _over.Kind.CLIFF
			elif c == "w":
				kind = _over.Kind.WATER
			elif c == ":":
				kind = _over.Kind.COBBLE
			elif c == "=":
				kind = _over.Kind.BOARDWALK
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Niveaux de sol : [CaveLevelGate]. Échelles et bouche n'ont pas de niveau (praticables
## depuis les deux).
func _levels(root: Node, entities: Node, plan: Object) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/caves/cave_level_gate.gd"))
	gate.name = "NiveauxDeSol"
	var low: Array[Vector2i] = []
	var high: Array[Vector2i] = []
	var stairs: Array[Vector2i] = []
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var c: String = plan.at(cell)
			if c == ":":
				high.append(cell)
			elif c == "=":
				stairs.append(cell)
			elif LOW_CHARS.contains(c):
				low.append(cell)
	gate.set(&"low_cells", low)
	gate.set(&"high_cells", high)
	gate.set(&"stairs_cells", stairs)
	_attach(root, entities, gate)


## Indice `x` voisin de la case d'où l'on fouille (Vector2i(-1, -1) : aucun).
func _clue_of(plan: Object, stand: Vector2i) -> Vector2i:
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell := stand + step
		if cell.x >= 0 and cell.y >= 0 and cell.x < plan.width and cell.y < plan.height \
				and plan.at(cell) == "x":
			return cell
	return Vector2i(-1, -1)


## Échelle provisoire (bois ; plus claire si elle monte), comme aux Îles Écume.
func _ladder(root: Node, entities: Node, cell: Vector2i, up: bool) -> void:
	var ladder := _gate(root, entities, "EchelleDessin_%d_%d" % [cell.x, cell.y], cell, [], [])
	var wood := Color(0.62, 0.46, 0.26) if up else Color(0.4, 0.28, 0.16)
	_rect(root, ladder, Rect2(-30, -88, 60, 80), wood)
	for y: int in [-80, -56, -32]:
		_rect(root, ladder, Rect2(-22, y, 44, 8), wood.darkened(0.45))


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
		push_error("build_cerulean_cave : %s" % plan.error)
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
	root.set(&"light_profile", LIGHTS[String(map_id)])
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
