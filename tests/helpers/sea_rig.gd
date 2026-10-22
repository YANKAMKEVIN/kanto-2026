extends RefCounted
## Mer d'essai (passe systèmes 2, Surf) : les cartes de QA `qa_sea` et `qa_sea_2` sont retirées en
## S2Z (T33) ; leurs grilles restent comme fixtures (`tests/fixtures/plans/essai_mer*.txt`) et ce
## banc en construit les cartes **en mémoire**, comme le faisait l'outil de construction retiré
## (tuiles provisoires pour le sol : falaise `#`, sable `.` `E`, eau partout ailleurs, donc l'eau
## décor `~` est de l'eau non surfable). Rien n'est livré.
##
## - `essai_mer` (26 × 18) : plage (x 1..6), mer surfable, îlot (16..18, 8..9), courant `>` (12..20, 4)
##   puis `v` (21, 4..9) jusqu'au passage (21, 10) → `essai_mer_2:from_current` ; bord est
##   (25, 11..14) → `essai_mer_2:from_west` ; cases pêchables : colonne 7, rangées 2..9 ;
##   points `depart` (2, 16), `from_east` (24, 12) en Surf forcé ; Nageur (15, 13) tourné vers
##   l'ouest, vue 4 (`tests/fixtures/npcs_sea/essai_mer.json`) si demandé ;
## - `essai_mer_2` (12 × 18) : mer, rive est (9..10), arrivées en Surf forcé `from_current` (5, 3)
##   et `from_west` (0, 12), bord ouest (0, 11..14) → `essai_mer:from_east`.
##
## Avec Boot : `SceneRouter.map_factory = SeaRig.factory()` (à remettre à `Callable()` après).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const SEA: StringName = &"essai_mer"
const SEA_2: StringName = &"essai_mer_2"
const PLANS_DIR := "res://tests/fixtures/plans/"
const NPCS_DIR := "res://tests/fixtures/npcs_sea"
const NO_NPCS_DIR := "res://tests/fixtures/none"
const FISHABLE_COLUMN := 7
const STEP_ON := Warp.Trigger.STEP_ON
const PUSH := Warp.Trigger.PUSH


## Fabrique pour [member SceneRouter.map_factory] (sans le Nageur : aucun Dresseur dans Boot).
static func factory(with_swimmer: bool = false) -> Callable:
	return func(map_id: StringName) -> GameMap: return make_map(map_id, with_swimmer)


## La carte [param map_id] (`essai_mer` ou `essai_mer_2`), hors de l'arbre ; null sinon.
static func make_map(map_id: StringName, with_swimmer: bool = false) -> GameMap:
	if map_id != SEA and map_id != SEA_2:
		return null
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + String(map_id) + ".txt"):
		push_error("SeaRig : %s" % plan.error)
		return null
	var map := GameMap.new()
	map.name = String(map_id).to_pascal_case()
	map.map_id = map_id
	map.display_name = "Mer d'essai"
	map.size = Vector2i(plan.width, plan.height)
	map.npcs_dir = NPCS_DIR if with_swimmer and map_id == SEA else NO_NPCS_DIR
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = load(OverworldTiles.TILESET_PATH)
	map.add_child(ground)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	_paint(ground, plan)
	map.surf_cells.assign(plan.cells_of("w>vs"))
	for cell: Vector2i in plan.cells_of(">"):
		map.current_cells[cell] = Vector2i.RIGHT
	for cell: Vector2i in plan.cells_of("v"):
		map.current_cells[cell] = Vector2i.DOWN
	map.forced_surf_cells.assign(plan.cells_of("s"))
	if map_id == SEA:
		for y: int in range(2, 10):
			map.fishable_cells.append(Vector2i(FISHABLE_COLUMN, y))
		_spawn(map, &"depart", plan.cell_of("depart"))
		_spawn(map, &"from_east", plan.cell_of("from_east"))
		_warp(map, plan.cell_of("passage_courant"), STEP_ON, Vector2i.DOWN, SEA_2,
			&"from_current")
		for cell: Vector2i in plan.cells_at("bord_est"):
			_warp(map, cell, PUSH, Vector2i.RIGHT, SEA_2, &"from_west")
	else:
		for spawn: String in ["depart", "from_current", "from_west"]:
			_spawn(map, StringName(spawn), plan.cell_of(spawn))
		for cell: Vector2i in plan.cells_at("bord_ouest"):
			_warp(map, cell, PUSH, Vector2i.LEFT, SEA, &"from_east")
	return map


static func _paint(ground: TileMapLayer, plan: PlanGrid) -> void:
	for y: int in plan.height:
		for x: int in plan.width:
			var kind := OverworldTiles.Kind.WATER
			match plan.at(Vector2i(x, y)):
				"#":
					kind = OverworldTiles.Kind.CLIFF
				".", "E":
					kind = OverworldTiles.Kind.SAND
			ground.set_cell(Vector2i(x, y), OverworldTiles.SOURCE_ID,
				OverworldTiles.atlas_coords(kind, 0))


static func _spawn(map: GameMap, spawn_name: StringName, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = Grid.cell_to_world(cell)
	map.get_node(^"Spawns").add_child(marker)


static func _warp(map: GameMap, cell: Vector2i, trigger: Warp.Trigger, direction: Vector2i,
		target: StringName, spawn: StringName) -> void:
	var point := WarpPoint.new()
	point.name = "Warp%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.trigger = trigger
	point.direction = direction
	point.target_map = target
	point.target_spawn = spawn
	point.arrival_facing = direction
	map.get_node(^"Warps").add_child(point)
