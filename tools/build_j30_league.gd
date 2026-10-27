extends SceneTree
## Construit les six salles de la Ligue du jalon 30 (`docs/tech/jalon-30.md` §2.1, T9), en tuiles
## provisoires d'intérieur (`InteriorTiles`, lot d'art plus tard, §2.9), d'après les grilles de
## `tools/plans/` (la grille fait foi ; contrôle : `tools/art/plan_check_j30.py`) :
##   - `league_lorelei` (ligue_olga.txt), `league_bruno` (ligue_aldo.txt), `league_agatha`
##     (ligue_agatha.txt), `league_lance` (ligue_peter.txt), `league_champion`
##     (ligue_champion.txt) : porte sud, membre, déclencheur d'appel, porte nord ;
##   - `hall_of_fame` (pantheon.txt) : salle de la cérémonie, sans porte.
## Modèle : `tools/build_j29.gd` (Route 23, Plateau ; branche `jalon-29`).
##
## Portes (§2.2, [LeagueDirector]) :
##   - porte sud : warp `unless league_attempt_active` + [FlagGate] bloquante `if
##     league_attempt_active` (battant fermé dessiné) : pas de retour pendant la tentative ;
##   - porte nord : warp toujours actif derrière une [FlagGate] bloquante `unless
##     league_stage_<k>_cleared` (la grille : `si=league_stage_<k>_cleared`) ;
##   - déclencheur d'appel (`appel_<membre>`) : scène `<dresseur>_call` (`data/cutscenes/league.json`).
## Toutes les salles : intérieur, `no_fly`, `no_teleport`. PNJ (membres, Chen) :
## `data/npcs/<carte>.json`.
##
##   godot --headless --path . -s res://tools/build_j30_league.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const LIGHT: StringName = &"interior_warm"
## Nom affiché : la zone du Plateau Indigo (`data/world/zones.json`).
const DISPLAY_NAME := "Plateau Indigo"
const ATTEMPT_FLAG: StringName = &"league_attempt_active"

## Cartes : [grille, nœud racine].
const MAPS: Dictionary = {
	"league_lorelei": ["ligue_olga", "LeagueLorelei"],
	"league_bruno": ["ligue_aldo", "LeagueBruno"],
	"league_agatha": ["ligue_agatha", "LeagueAgatha"],
	"league_lance": ["ligue_peter", "LeagueLance"],
	"league_champion": ["ligue_champion", "LeagueChampion"],
	"hall_of_fame": ["pantheon", "HallOfFame"],
}

## Couleurs des dessins provisoires.
const COLOR_DOOR := Color(0.16, 0.12, 0.2)
const COLOR_DOOR_TRIM := Color(0.78, 0.66, 0.3)

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_tiles = load("res://game/world/interior_tiles.gd")
	_rng.seed = 3030
	for map_id: String in MAPS:
		_build(StringName(map_id))
	print("build_j30_league : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan := _plan(spec[0])
	var root := _new_map(spec[1], map_id, Vector2i(plan.width, plan.height))
	_paint(root, plan)
	var entities: Node = root.get_node(^"Entities")
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	if plan.positions.has("porte_sud"):
		_south_door(root, entities, plan)
	if plan.positions.has("porte_nord"):
		_north_door(root, entities, plan)
	for id: String in _ids(plan, "declencheur"):
		var cutscene := StringName(plan.attr(id, "combat") + "_call")
		for cell: Vector2i in plan.cells_at(id):
			_trigger(root, "%s_%d_%d" % [id.to_pascal_case(), cell.x, cell.y], cell, cutscene)
	_save(root, MAPS_DIR + String(map_id) + ".tscn")


## Porte sud : retour vers la salle d'avant (ou le hall), fermée pendant la tentative.
func _south_door(root: Node, entities: Node, plan: Object) -> void:
	var target: String = plan.attr("porte_sud", "vers")
	var cells: Array[Vector2i] = plan.cells_at("porte_sud")
	var unless: Array[StringName] = [StringName(plan.attr("porte_sud", "unless"))]
	# Sortie dans le sens du mur : vers le bas (salles 0 à 2, Champion), vers l'est (Peter).
	var out := Vector2i.RIGHT if cells[0].x == plan.width - 2 else Vector2i.DOWN
	var index := 0
	for cell: Vector2i in cells:
		_warp(root, "PorteSud%d" % index, cell, out, StringName(target.get_slice(":", 0)),
			StringName(target.get_slice(":", 1)), Vector2i.DOWN, unless)
		index += 1
	var flags: Array[StringName] = [ATTEMPT_FLAG]
	var none: Array[StringName] = []
	_door_gate(root, entities, "PorteSudFermee", cells, flags, none)


## Porte nord : vers la salle suivante, ouverte quand le membre est battu dans la tentative.
func _north_door(root: Node, entities: Node, plan: Object) -> void:
	var target: String = plan.attr("porte_nord", "vers")
	var cells: Array[Vector2i] = plan.cells_at("porte_nord")
	var none: Array[StringName] = []
	var index := 0
	for cell: Vector2i in cells:
		_warp(root, "PorteNord%d" % index, cell, Vector2i.UP,
			StringName(target.get_slice(":", 0)), StringName(target.get_slice(":", 1)),
			Vector2i.UP, none)
		index += 1
	var cleared: Array[StringName] = [StringName(plan.attr("porte_nord", "si"))]
	_door_gate(root, entities, "PorteNordFermee", cells, none, cleared)


## Battant fermé (FlagGate bloquante) sur les cases [param cells] de la porte.
func _door_gate(root: Node, entities: Node, gate_name: String, cells: Array[Vector2i],
		if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cells[0])
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_attach(root, entities, gate)
	for cell: Vector2i in cells:
		var offset := Vector2((cell - cells[0]) * TILE)
		_rect(root, gate, Rect2(offset + Vector2(-48, -96), Vector2(96, 92)), COLOR_DOOR)
		_rect(root, gate, Rect2(offset + Vector2(-40, -60), Vector2(80, 8)), COLOR_DOOR_TRIM)


func _trigger(root: Node, trigger_name: String, cell: Vector2i, cutscene: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = trigger_name
	point.position = _world(cell)
	point.set(&"size", Vector2i.ONE)
	point.set(&"direction", Vector2i.ZERO)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


# --- Outils (modèle de build_j29.gd) -------------------------------------------------------------


func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


## Sol du laboratoire, tapis sur les portes ; murs (rangée basse avec plinthe au-dessus d'un sol).
func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	var obstacles := root.get_node(^"Obstacles") as TileMapLayer
	var floor_kind: int = _tiles.Kind.FLOOR_LAB
	var wall_kind: int = _tiles.Kind.WALL_LAB
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			match plan.at(cell):
				"#":
					var below := cell + Vector2i.DOWN
					var base: bool = below.y < plan.height and plan.at(below) != "#"
					obstacles.set_cell(cell, _tiles.SOURCE_ID, _tiles.atlas_coords(wall_kind,
						_tiles.WALL_BASEBOARD if base else _tiles.WALL_UPPER))
				"X":
					ground.set_cell(cell, _tiles.SOURCE_ID, _tiles.atlas_coords(_tiles.Kind.MAT, 0))
				_:
					var variant := _rng.randi_range(0, _tiles.variant_count(floor_kind) - 1)
					ground.set_cell(cell, _tiles.SOURCE_ID, _tiles.atlas_coords(floor_kind, variant))


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_j30_league : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", DISPLAY_NAME)
	root.set(&"region", "")
	root.set(&"size", size)
	root.set(&"interior", true)
	root.set(&"no_fly", true)
	root.set(&"no_teleport", true)
	root.set(&"light_profile", LIGHT)
	var tileset: TileSet = load(_tiles.TILESET_PATH)
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


func _warp(root: Node, warp_name: String, cell: Vector2i, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i, unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", STEP_ON)
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
