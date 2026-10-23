extends SceneTree
## Construit la mer du jalon 24 (T8, T11, T12 ; dossier 27 §9, §10.1) : `route_19`, `route_20`,
## `route_21` et `cinnabar_island`, en tuiles provisoires (`OverworldTiles`), sans lumière,
## d'après les grilles `tools/plans/route_19.txt`, `route_20.txt`, `route_21.txt`,
## `cinnabar_island.txt` (la grille fait foi ; contrôle `tools/art/plan_check_j24_mer.py`).
##
## - Sol : sable `y`, herbe `.`, hautes herbes `h`, rebord de sable `v` (sauté vers le sud), bois `T`,
##   récifs et falaises `R K X`, eau surfable `w` (posée avec `surf_cells`), eau décor `~`, porte ou
##   entrée de grotte `D` (terre), bâtiments de Cramois'Île `M Z L C O` (falaise, aplat de couleur
##   provisoire par-dessus).
## - Bords de carte : un [WarpPoint] PUSH par case, vers le spawn de même rang de la carte voisine
##   (`<spawn>_<i>`, i = rang dans la liste de cases de la grille ; `<spawn>` seul = première case).
##   Bord nord de la Route 19 ↔ bord sud de Parmanie (`fuchsia_city`, J22, `tools/build_j22_maps.gd`) :
##   ses arrivées suivent la règle du J22 (`from_route_19`, puis `from_route_19_1`… dans l'ordre de
##   sa grille : terrasse puis couloir), d'où le rang de départ du couloir (5e élément du bord).
##   La côte sud de Bourg Palette n'est pas encore jointe : « à venir », retour sur la case voisine
##   (contrat dans `docs/tech/jalon-24.md`).
## - Portes : STEP_ON ↑ (grottes des Îles Écume, Labo, Centre, Boutique de Cramois'Île).
## - Panneaux, gravats du Manoir (EXAMINER), porte fermée de l'Arène (déclencheur : T-42 et recul).
## Les PNJ, Dresseurs et objets visibles sont dans `data/npcs/<carte>.json`.
##
##   godot --headless --path . -s res://tools/build_j24_sea.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const STEP_ON: int = 0
const PUSH: int = 1
## Sol : caractère → type de tuile ([enum OverworldTiles.Kind], par nom).
const KINDS: Dictionary = {"y": "SAND", ".": "GRASS", "h": "TALL_GRASS", "v": "LEDGE_DOWN",
	"T": "FOREST", "R": "CLIFF", "K": "CLIFF", "X": "CLIFF", "w": "WATER", "~": "WATER",
	"D": "DIRT", "M": "CLIFF", "Z": "CLIFF", "L": "CLIFF", "C": "CLIFF", "O": "CLIFF"}
## Bâtiments provisoires de Cramois'Île : caractère → couleur de l'aplat.
const BUILDINGS: Dictionary = {"M": Color(0.32, 0.24, 0.22), "Z": Color(0.72, 0.3, 0.18),
	"L": Color(0.86, 0.88, 0.9), "C": Color(0.85, 0.32, 0.3), "O": Color(0.3, 0.45, 0.8)}

## Cartes : identifiant → [nom affiché, noeud racine, bords, portes, panneaux].
## Bord : [position de la grille, carte cible, spawn cible, direction] ; spawn cible `<spawn>_<i>`.
## 5e élément facultatif (cartes construites par le J22) : rang de la première case dans les
## arrivées de la carte cible, nommées `<spawn>` (rang 0) puis `<spawn>_<rang>`.
## « À venir » : [position, libellé, direction], retour sur la case du dessous ou du dessus.
const MAPS: Dictionary = {
	"route_19": {
		"name": "Route 19", "node": "Route19",
		"edges": [["warp_ouest", "route_20", "from_route_19", Vector2i.LEFT],
			["warp_nord_terrasse", "fuchsia_city", "from_route_19", Vector2i.UP, 0],
			["warp_nord_couloir", "fuchsia_city", "from_route_19", Vector2i.UP, 9]],
		"coming_soon": [],
		"doors": [],
		"signs": {"panneau_route": &"route_19_sign"},
	},
	"route_20": {
		"name": "Route 20", "node": "Route20",
		"edges": [["warp_ouest", "cinnabar_island", "from_route_20", Vector2i.LEFT],
			["warp_est", "route_19", "from_route_20", Vector2i.RIGHT]],
		"coming_soon": [],
		"doors": [["porte_ouest", "seafoam_1f", "arrivee_entree_ouest"],
			["porte_est", "seafoam_1f", "arrivee_entree_est"]],
		"signs": {"panneau_ouest": &"route_20_sign", "panneau_est": &"route_20_sign"},
	},
	"route_21": {
		"name": "Route 21", "node": "Route21",
		"edges": [["warp_sud_eau", "cinnabar_island", "from_route_21_eau", Vector2i.DOWN],
			["warp_sud_terre", "cinnabar_island", "from_route_21_terre", Vector2i.DOWN]],
		"coming_soon": [["warp_nord", "BOURG PALETTE", Vector2i.UP]],
		"doors": [],
		"signs": {},
	},
	"cinnabar_island": {
		"name": "Cramois'Île", "node": "CinnabarIsland",
		"edges": [["warp_nord_eau", "route_21", "from_cinnabar_island_eau", Vector2i.UP],
			["warp_nord_terre", "route_21", "from_cinnabar_island_terre", Vector2i.UP],
			["warp_est", "route_20", "from_cinnabar_island", Vector2i.RIGHT]],
		"coming_soon": [],
		"doors": [["porte_labo", "cinnabar_lab", "entrance"],
			["porte_centre", "cinnabar_center", "entrance"],
			["porte_boutique", "cinnabar_mart", "entrance"]],
		"signs": {"panneau_ville": &"cinnabar_sign", "panneau_arene": &"cinnabar_gym_sign"},
	},
}

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2420
	for map_id: String in MAPS:
		_build(map_id)
	print("build_j24_sea : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build(map_id: String) -> void:
	var spec: Dictionary = MAPS[map_id]
	var plan := _plan(map_id)
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec["node"], StringName(map_id), spec["name"], size)
	var entities: Node = root.get_node(^"Entities")
	_paint(root, plan)
	var surf: Array[Vector2i] = []
	surf.assign(plan.cells_of("w"))
	root.set(&"surf_cells", surf)
	# Spawns : la première case sous le nom de la position, chaque case sous `<nom>_<i>`.
	for id: String in _ids(plan, "spawn"):
		var cells: Array[Vector2i] = plan.cells_at(id)
		_spawn(root, id, cells[0])
		if cells.size() > 1:
			for i: int in cells.size():
				_spawn(root, "%s_%d" % [id, i], cells[i])
	for edge: Array in spec["edges"]:
		var cells: Array[Vector2i] = plan.cells_at(edge[0])
		for i: int in cells.size():
			var arrival := "%s_%d" % [edge[2], i]
			if edge.size() > 4:
				var rank: int = edge[4] + i
				arrival = edge[2] if rank == 0 else "%s_%d" % [edge[2], rank]
			_warp(root, "%s_%d" % [String(edge[0]).capitalize().replace(" ", ""), i], cells[i],
				PUSH, edge[3], StringName(edge[1]), StringName(arrival), edge[3])
	for entry: Array in spec["coming_soon"]:
		var cells: Array[Vector2i] = plan.cells_at(entry[0])
		var back: Vector2i = -(entry[2] as Vector2i)
		for i: int in cells.size():
			var spawn_name := "retour_%s_%d" % [entry[0], i]
			_spawn(root, spawn_name, cells[i] + back)
			var point := _warp(root, "%s_%d" % [String(entry[0]).capitalize().replace(" ", ""),
				i], cells[i], PUSH, entry[2], &"", StringName(spawn_name), back)
			point.set(&"coming_soon", entry[1])
	for door: Array in spec["doors"]:
		var index := 0
		for cell: Vector2i in plan.cells_at(door[0]):
			index += 1
			_warp(root, "%s_%d" % [String(door[0]).capitalize().replace(" ", ""), index], cell,
				STEP_ON, Vector2i.UP, StringName(door[1]), StringName(door[2]), Vector2i.UP)
			_door(root, entities, cell)
	var signs: Dictionary = spec["signs"]
	for id: String in signs:
		_add_sign(root, entities, plan.cell_of(id), signs[id])
	if map_id == "cinnabar_island":
		_cinnabar(root, entities, plan)
		# Arrivée du Vol (`data/world/fly_points.json`) : devant le Centre.
		_spawn(root, "from_center", plan.cell_of("from_centre"))
	_save(root, MAPS_DIR + map_id + ".tscn")


## Cramois'Île : aplats des bâtiments, gravats du Manoir (EXAMINER, T-43), porte fermée de
## l'Arène (déclencheur : T-42 et recul, scène `cinnabar_gym_locked`).
func _cinnabar(root: Node, entities: Node, plan: Object) -> void:
	for c: String in BUILDINGS:
		var rect := _block_of(plan, c)
		var gate := _gate(root, entities, "Batiment_" + c, rect.position + Vector2i(0, rect.size.y - 1))
		_rect(root, gate, Rect2(-TILE / 2.0, -rect.size.y * TILE, rect.size.x * TILE,
			rect.size.y * TILE), BUILDINGS[c])
	var rubble := Marker2D.new()
	rubble.set_script(load("res://game/world/interactions/interact_point.gd"))
	rubble.name = "ManoirGravats"
	rubble.position = _world(plan.cell_of("examen_manoir"))
	rubble.set(&"dialogue_id", &"cinnabar_mansion_rubble")
	rubble.set(&"size", Vector2i(2, 1))
	_attach(root, root.get_node(^"Interactables"), rubble)
	var trigger := Marker2D.new()
	trigger.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	trigger.name = "PorteArene"
	trigger.position = _world(plan.cell_of("porte_arene"))
	trigger.set(&"cutscene_id", &"cinnabar_gym_locked")
	trigger.set(&"size", Vector2i(2, 1))
	trigger.set(&"direction", Vector2i.UP)
	_attach(root, root.get_node(^"Triggers"), trigger)
	var fossils := Node2D.new()
	fossils.set_script(load("res://game/world/fossils/fossil_ready_gate.gd"))
	fossils.name = "Fossiles"
	_attach(root, entities, fossils)


## Rectangle englobant des cases [param c] (bâtiment ; ses portes et gravats y sont inclus).
func _block_of(plan: Object, c: String) -> Rect2i:
	var cells: Array[Vector2i] = plan.cells_of(c)
	var rect := Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect


func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind[KINDS.get(plan.at(cell), "SAND")]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Porte ou entrée de grotte provisoire (aplat sombre).
func _door(root: Node, entities: Node, cell: Vector2i) -> void:
	var gate := _gate(root, entities, "Porte_%d_%d" % [cell.x, cell.y], cell)
	_rect(root, gate, Rect2(-40, -84, 80, 80), Color(0.12, 0.1, 0.1))


func _add_sign(root: Node, entities: Node, cell: Vector2i, text_id: StringName) -> void:
	var gate := _gate(root, entities, "Panneau_%d_%d" % [cell.x, cell.y], cell)
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-6, -60, 12, 56), Color(0.4, 0.28, 0.14))
	_rect(root, gate, Rect2(-34, -90, 68, 40), Color(0.72, 0.56, 0.32))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "PanneauPoint_%d_%d" % [cell.x, cell.y]
	point.position = _world(cell)
	point.set(&"dialogue_id", text_id)
	_attach(root, root.get_node(^"Interactables"), point)


func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
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
		push_error("build_j24_sea : %s" % plan.error)
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
	root.set(&"interior", false)
	root.set(&"light_profile", &"golden_hour")
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
		target: StringName, spawn: StringName, facing: Vector2i) -> Marker2D:
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
	return point


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
