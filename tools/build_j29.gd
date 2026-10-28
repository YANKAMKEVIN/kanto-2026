extends SceneTree
## Construit les cartes extérieures et la Route Victoire du jalon 29 (`docs/tech/jalon-29.md` §2.1),
## en tuiles provisoires (`OverworldTiles`, Q29-4 : sol peint plus tard), d'après les grilles de
## `tools/plans/` (la grille fait foi ; contrôle : `tools/art/plan_check_j29.py`) :
##   - `route_22_west` (route_22_ouest.txt) : partie ouest de la Route 22, rival n° 7, poste ;
##   - `route_23` (route_23.txt) : sept contrôles de Badge, eau surfable, Route Victoire ;
##   - `victory_road_1f`, `_2f`, `_3f` (route_victoire_*.txt) : niveaux de sol, rochers de Force,
##     interrupteurs, barrières, trou, échelles, Sulfura (2F) ;
##   - `indigo_plateau` (plateau_indigo.txt) : extérieur, porte du hall.
## Le poste de la Ligue et le hall sont des intérieurs peints (`build_painted_interiors.gd --j29`).
## PNJ, objets, Dresseurs : `data/npcs/<carte>.json` ; scènes : `data/cutscenes/j29.json`.
##
##   godot --headless --path . -s res://tools/build_j29.gd
##   godot --headless --path . --import
## Puis les passes d'image (lot DAF.4), sans quoi l'art peint est perdu : `build_route_22_west.gd`,
## `build_daf4_caves.gd`, `build_daf4_facades.gd`, `build_daf4_exterieurs.gd` (sol de la Route 23
## et du Plateau Indigo) (dans cet ordre, après `build_j29.gd` et `build_cerulean_cave.gd`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
const FALL: int = 2
const OUTDOOR_LIGHT: StringName = &"golden_hour"
## Grotte (profil du Mont Sélénite, `data/world/lighting.json`).
const CAVE_LIGHT: StringName = &"cave_1f"
const ROUTE_22_REGION := "Jadielle — Plateau Indigo"

## Passages par carte : identifiant de position → [déclenchement, direction, orientation à
## l'arrivée]. La cible (carte:spawn) vient de l'attribut `vers=` de la grille.
const WARPS: Dictionary = {
	"route_22_west": {
		"sortie_est": [PUSH, Vector2i.RIGHT, Vector2i.RIGHT],
		"porte_poste": [STEP_ON, Vector2i.UP, Vector2i.UP],
	},
	"route_23": {
		"depuis_poste": [STEP_ON, Vector2i.DOWN, Vector2i.DOWN],
		"entree_victoire": [STEP_ON, Vector2i.UP, Vector2i.UP],
		"sortie_victoire": [STEP_ON, Vector2i.UP, Vector2i.LEFT],
		"vers_plateau": [PUSH, Vector2i.UP, Vector2i.UP],
	},
	"victory_road_1f": {
		"entree": [PUSH, Vector2i.DOWN, Vector2i.DOWN],
		"echelle_2f": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
	},
	"victory_road_2f": {
		"echelle_1f": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
		"sortie": [PUSH, Vector2i.RIGHT, Vector2i.DOWN],
		"echelle_3f_a": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
		"echelle_3f_b": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
		"echelle_3f_c": [STEP_ON, Vector2i.ZERO, Vector2i.LEFT],
		"echelle_3f_d": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
	},
	"victory_road_3f": {
		"echelle_2f_a": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
		"echelle_2f_b": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
		"echelle_2f_c": [STEP_ON, Vector2i.ZERO, Vector2i.LEFT],
		"echelle_2f_d": [STEP_ON, Vector2i.ZERO, Vector2i.DOWN],
	},
	"indigo_plateau": {
		"porte_hall": [STEP_ON, Vector2i.UP, Vector2i.UP],
		"vers_route_23": [PUSH, Vector2i.DOWN, Vector2i.DOWN],
	},
}

## Cartes : [grille, nœud racine, nom affiché, région, lumière, sol par caractère, sol par défaut].
const MAPS: Dictionary = {
	"route_22_west": ["route_22_ouest", "Route22West", "Route 22", ROUTE_22_REGION, OUTDOOR_LIGHT,
		{"T": "FOREST", "P": "CLIFF", "n": "GRASS", "=": "DIRT", "D": "DIRT", "h": "TALL_GRASS"},
		"GRASS"],
	"route_23": ["route_23", "Route23", "Route 23", "Poste de la Ligue — Plateau Indigo",
		OUTDOOR_LIGHT, {"#": "CLIFF", "h": "TALL_GRASS", "w": "WATER"}, "GRASS"],
	"victory_road_1f": ["route_victoire_1f", "VictoryRoad1F", "Route Victoire", "Route 23",
		CAVE_LIGHT, {"#": "CLIFF", "=": "DIRT", "L": "DIRT", "E": "DIRT"}, "RUBBLE"],
	"victory_road_2f": ["route_victoire_2f", "VictoryRoad2F", "Route Victoire", "Route 23",
		CAVE_LIGHT, {"#": "CLIFF", "=": "DIRT", "L": "DIRT", "E": "DIRT"}, "RUBBLE"],
	"victory_road_3f": ["route_victoire_3f", "VictoryRoad3F", "Route Victoire", "Route 23",
		CAVE_LIGHT, {"#": "CLIFF", "=": "DIRT", "L": "DIRT", "E": "DIRT"}, "RUBBLE"],
	"indigo_plateau": ["plateau_indigo", "IndigoPlateau", "Plateau Indigo", "", OUTDOOR_LIGHT,
		{"#": "CLIFF"}, "GRASS"],
}

## Couleurs des dessins provisoires.
const COLOR_HIGH := Color(1.0, 0.95, 0.85, 0.22)
const COLOR_STAIRS := Color(0.55, 0.42, 0.28)
const COLOR_LADDER := Color(0.55, 0.38, 0.2)
const COLOR_LADDER_RUNG := Color(0.3, 0.2, 0.1)
const COLOR_BUILDING := Color(0.62, 0.36, 0.3)
const COLOR_ROOF := Color(0.36, 0.38, 0.5)
const COLOR_DOOR := Color(0.18, 0.13, 0.1)

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2929
	for map_id: String in MAPS:
		_build(StringName(map_id))
	print("build_j29 : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan := _plan(spec[0])
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec[1], map_id, spec[2], spec[3], size, spec[4])
	_paint(root, plan, spec[5], spec[6])
	var entities: Node = root.get_node(^"Entities")
	var decals: Node = root.get_node(^"GroundDecals")
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	for id: String in _ids(plan, "chute_joueur"):
		_spawn(root, id, plan.cell_of(id))
	var warps: Dictionary = WARPS[String(map_id)]
	for id: String in warps:
		var target: String = plan.attr(id, "vers")
		if target.is_empty():
			push_error("%s : passage %s sans vers=" % [map_id, id])
			_errors += 1
			continue
		var w: Array = warps[id]
		var index := 0
		for cell: Vector2i in plan.cells_at(id):
			_warp(root, "%s%d" % [id.to_pascal_case(), index], cell, w[0], w[1],
				StringName(target.get_slice(":", 0)), StringName(target.get_slice(":", 1)), w[2],
				[])
			index += 1
		if plan.positions[id]["kind"] == "echelle":
			_ladder(root, entities, plan.cell_of(id))
	if String(map_id).begins_with("victory_road"):
		_levels(root, decals, plan)
		_boulders(root, entities, plan)
	if map_id == &"route_23":
		var surf: Array[Vector2i] = []
		surf.assign(plan.cells_of("w"))
		root.set(&"surf_cells", surf)
		_controls(root, plan)
	if map_id == &"route_22_west":
		_building(root, entities, plan.cells_of("P"), plan.cells_of("D"))
		for cell: Vector2i in plan.cells_at("declencheur_rival"):
			_trigger(root, "RivalFinal%d_%d" % [cell.x, cell.y], cell, Vector2i.ZERO,
				StringName(plan.attr("declencheur_rival", "scene")))
	if map_id == &"indigo_plateau":
		var no_walls: Array[Vector2i] = []
		_building(root, entities, no_walls, plan.cells_at("porte_hall"))
	var blocked: Array[Vector2i] = []
	for id: String in _ids(plan, "panneau"):
		_add_sign(root, entities, plan.cell_of(id), StringName(plan.attr(id, "texte")))
		blocked.append(plan.cell_of(id))
	root.set(&"blocked_cells", blocked)
	var hidden := 0
	for id: String in _ids(plan, "objet_cache"):
		hidden += 1
		var dialogue := StringName("%s_hidden_%d" % [map_id, hidden])
		var point := _interactable(root, "Cache%d" % hidden, plan.cell_of(id), dialogue)
		var unless: Array[StringName] = [StringName("got_%s" % dialogue)]
		point.set(&"unless_flags", unless)
	_save(root, MAPS_DIR + String(map_id) + ".tscn")


# --- Route Victoire -----------------------------------------------------------------------------


## Niveaux de sol (GameMap.low_cells, high_cells, stairs_cells) et voile clair sur le sol haut
## (lisibilité des deux niveaux, provisoire).
func _levels(root: Node, decals: Node, plan: Object) -> void:
	var low: Array[Vector2i] = []
	var high: Array[Vector2i] = []
	var stairs: Array[Vector2i] = []
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			match plan.at(cell):
				".", "E":
					low.append(cell)
				":":
					high.append(cell)
					_rect(root, decals, _cell_rect(cell), COLOR_HIGH)
				"=":
					stairs.append(cell)
					for k: int in 3:
						_rect(root, decals, Rect2(cell.x * TILE + 10, cell.y * TILE + 14 + k * 28,
							TILE - 20, 10), COLOR_STAIRS)
	root.set(&"low_cells", low)
	root.set(&"high_cells", high)
	root.set(&"stairs_cells", stairs)


## Rochers, trous, interrupteurs, barrières (modèle `build_qa_strength.gd`).
func _boulders(root: Node, entities: Node, plan: Object) -> void:
	var setup := Node.new()
	setup.set_script(load("res://game/world/boulders/boulder_setup.gd"))
	setup.name = "Boulders"
	var boulder_cells: Array[Vector2i] = []
	var boulder_holes: Array[int] = []
	var boulder_requires: Array[StringName] = []
	var hole_cells: Array[Vector2i] = []
	var hole_numbers: Array[int] = []
	var hole_flags: Array[StringName] = []
	var switch_cells: Array[Vector2i] = []
	var switch_ids: Array[StringName] = []
	var switch_flags: Array[StringName] = []
	for id: String in _ids(plan, "rocher"):
		boulder_cells.append(plan.cell_of(id))
		boulder_holes.append(int(plan.attr(id, "trou")))
		boulder_requires.append(StringName(plan.attr(id, "si")))
	for id: String in _ids(plan, "trou"):
		var cell: Vector2i = plan.cell_of(id)
		var number: int = int(plan.attr(id, "n"))
		var flag: StringName = StringName(plan.attr(id, "drapeau"))
		hole_cells.append(cell)
		hole_numbers.append(number)
		hole_flags.append(flag)
		_warp(root, "Trou%d" % number, cell, FALL, Vector2i.ZERO,
			StringName(plan.attr(id, "chute")), StringName("chute_joueur_%d" % number),
			Vector2i.DOWN, [flag])
		var open := _gate(root, entities, "TrouOuvert%d" % number, cell, [], [flag])
		_rect(root, open, Rect2(-40, -88, 80, 80), Color(0.05, 0.04, 0.06))
		_rect(root, open, Rect2(-28, -76, 56, 56), Color(0.0, 0.0, 0.0))
		var filled := _gate(root, entities, "TrouBouche%d" % number, cell, [flag], [])
		_rect(root, filled, Rect2(-44, -92, 88, 88), Color(0.42, 0.40, 0.36))
		_rect(root, filled, Rect2(-28, -76, 56, 56), Color(0.58, 0.56, 0.5))
	for id: String in _ids(plan, "interrupteur"):
		var cell: Vector2i = plan.cell_of(id)
		var flag: StringName = StringName(plan.attr(id, "drapeau"))
		switch_cells.append(cell)
		switch_ids.append(StringName(id))
		switch_flags.append(flag)
		var raised := _gate(root, entities, "InterrupteurReleve_" + id, cell, [], [flag])
		_rect(root, raised, Rect2(-34, -82, 68, 68), Color(0.85, 0.7, 0.2))
		var pressed := _gate(root, entities, "InterrupteurEnfonce_" + id, cell, [flag], [])
		_rect(root, pressed, Rect2(-34, -82, 68, 68), Color(0.4, 0.34, 0.12))
	for id: String in _ids(plan, "barriere"):
		var flag: StringName = StringName(plan.attr(id, "ouverte_si"))
		var cells: Array[Vector2i] = plan.cells_at(id)
		var gate := _gate(root, entities, "Barriere_" + id, cells[0], [], [flag])
		var blocking: Array[Vector2i] = []
		blocking.assign(cells)
		gate.set(&"blocking_cells", blocking)
		for cell: Vector2i in cells:
			var offset := Vector2((cell - cells[0]) * TILE)
			_rect(root, gate, Rect2(offset + Vector2(-44, -88), Vector2(88, 80)),
				Color(0.55, 0.15, 0.15))
			_rect(root, gate, Rect2(offset + Vector2(-30, -74), Vector2(60, 12)),
				Color(0.85, 0.75, 0.3))
	setup.set(&"boulder_cells", boulder_cells)
	setup.set(&"boulder_holes", boulder_holes)
	setup.set(&"boulder_requires", boulder_requires)
	setup.set(&"hole_cells", hole_cells)
	setup.set(&"hole_numbers", hole_numbers)
	setup.set(&"hole_flags", hole_flags)
	setup.set(&"switch_cells", switch_cells)
	setup.set(&"switch_ids", switch_ids)
	setup.set(&"switch_flags", switch_flags)
	_attach(root, root, setup)


func _ladder(root: Node, entities: Node, cell: Vector2i) -> void:
	var ladder := _gate(root, entities, "Echelle%d_%d" % [cell.x, cell.y], cell, [], [])
	_rect(root, ladder, Rect2(-30, -88, 60, 80), COLOR_LADDER)
	for k: int in 3:
		_rect(root, ladder, Rect2(-22, -80 + k * 24, 44, 8), COLOR_LADDER_RUNG)


# --- Route 23 : contrôles des Badges --------------------------------------------------------------


## Un déclencheur par case de chaque rangée de contrôle (`controle_N`), pas vers le nord seulement :
## scène `route_23_check_N` (data/cutscenes/j29.json).
func _controls(root: Node, plan: Object) -> void:
	for id: String in _ids(plan, "controle"):
		var number := id.trim_prefix("controle_")
		for cell: Vector2i in plan.cells_at(id):
			_trigger(root, "Controle%s_%d" % [number, cell.x], cell, Vector2i.UP,
				StringName("route_23_check_" + number))


# --- Dessins provisoires ------------------------------------------------------------------------


## Bâtiment provisoire (poste de la Ligue, hall du Plateau) : murs sur [param walls], porte sombre
## sur [param doors].
func _building(root: Node, entities: Node, walls: Array[Vector2i], doors: Array[Vector2i]) -> void:
	if not walls.is_empty():
		var min_cell := walls[0]
		var max_cell := walls[0]
		for cell: Vector2i in walls:
			min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
			max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
		var base := _gate(root, entities, "Batiment", Vector2i(min_cell.x, max_cell.y), [], [])
		var width := (max_cell.x - min_cell.x + 1) * TILE
		var height := (max_cell.y - min_cell.y + 1) * TILE
		_rect(root, base, Rect2(-TILE / 2.0, -height, width, height), COLOR_BUILDING)
		_rect(root, base, Rect2(-TILE / 2.0 - 8, -height - 24, width + 16, TILE * 0.9), COLOR_ROOF)
	for cell: Vector2i in doors:
		var door := _gate(root, entities, "Porte%d_%d" % [cell.x, cell.y], cell, [], [])
		_rect(root, door, Rect2(-36, -96, 72, 30), COLOR_DOOR)


## Panneau : décor bloquant + point d'examen (modèle `build_qa_strength.gd`).
func _add_sign(root: Node, entities: Node, cell: Vector2i, text_id: StringName) -> void:
	var gate := _gate(root, entities, "Panneau%d_%d" % [cell.x, cell.y], cell, [], [])
	_rect(root, gate, Rect2(-6, -60, 12, 56), Color(0.4, 0.28, 0.14))
	_rect(root, gate, Rect2(-34, -90, 68, 40), Color(0.72, 0.56, 0.32))
	_interactable(root, "PanneauPoint%d_%d" % [cell.x, cell.y], cell, text_id)


func _interactable(root: Node, point_name: String, cell: Vector2i, dialogue: StringName) -> Node:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = point_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	_attach(root, root.get_node(^"Interactables"), point)
	return point


func _trigger(root: Node, trigger_name: String, cell: Vector2i, direction: Vector2i,
		cutscene: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = trigger_name
	point.position = _world(cell)
	point.set(&"size", Vector2i.ONE)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


## FlagGate de dessin posé sur la case [param cell] (origine = pied de la case).
func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array[StringName],
		unless: Array[StringName]) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless)
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)


# --- Outils (modèle de build_qa_strength.gd) ----------------------------------------------------


func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _paint(root: Node, plan: Object, kinds: Dictionary, fallback: String) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind[kinds.get(plan.at(cell), fallback)]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_j29 : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String, region: String,
		size: Vector2i, light: StringName) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", region)
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", light)
	var tileset: TileSet = load(_over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = -1
	_attach(root, root, decals)
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
		target: StringName, spawn: StringName, facing: Vector2i, unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"unless_flags", unless)
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
