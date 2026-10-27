extends SceneTree
## Construit les deux défis de Safrania du jalon 27 (T6, T7 ; `docs/tech/jalon-27.md` §2.1, §2.3) :
## `saffron_gym` (Arène de Morgane, 20 × 18) et `fighting_dojo` (Dojo de Combat, 10 × 12),
## d'après `tools/plans/safrania_arene.txt` et `safrania_dojo.txt` (géométrie de Rouge/Bleu case
## pour case ; la grille fait foi).
##
##   godot --headless --path . -s res://tools/build_saffron_gym.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_saffron_city.gd   (portes de Safrania ouvertes)
##
## Géométrie et passages seulement : Morgane, le guide, les Dresseurs, le maître et les deux Poké
## Balls sont des données (`data/npcs/`) ; leurs cases restent praticables dans la scène.
## - **Image en modules** (lot DAF.3, `tools/art/daf3.py`) : les deux salles sont bâties sur
##   `tools/cave_map_kit.gd` comme la Sylphe et le repaire (sol peint, masse sombre, murs aux rôles
##   de la Tour par `tools/module_walls.gd`, tapis de téléporteur `T` et paillasson `E` au sol) ;
##   couches logiques du kit retirées, collision = `blocked_cells`. Deux passes au premier lancement
##   (masque du sol écrit : importer puis relancer, code 2).
## - **Collision** : `blocked_cells` = cases non praticables de la grille (`PRATICABLES`).
## - `spawn` : Marker2D de `Spawns`, au nom de la grille (`entrance`, `tp_<k>`) ; `depart` et
##   `but` (repères des contrôles) : ignorés.
## - `teleporteur` (Arène) : [WarpPoint] STEP_ON sans direction, style TELEPORT
##   (`Teleporter_<k>`), vers `vers=` sur la même carte → `SceneRouter.relocate` (passe systèmes 2,
##   S2F) ; orientation conservée ; arriver sur un tapis ne le déclenche pas (le STEP_ON ne part
##   qu'en entrant sur la case).
## - `warp` : sortie PUSH ↓ (`Exit0`, `Exit1`) vers `saffron_city:from_gym` / `from_dojo`.
## - Intérieurs (`interior = true`, comme l'Arène d'Erika) ; lumière par `data/world/lighting.json`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const TILE: int = 96
const STEP_ON: int = 0
const PUSH: int = 1
const STYLE_TELEPORT: int = 1
const OUT_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_batiment_01.png"
const NO_RUBBLE_MARK: String = "~"
const WALL_MARK: String = "#"
const TELEPORTER: String = "decal_teleporteur_sylphe_01"
const DOORMAT: String = "int_paillasson_sylphe_01"
## Carte → [sol, préfixe des murs, frontière (sol un peu assombri) [D], graine].
const ART: Dictionary = {
	&"saffron_gym": ["res://assets/world/ground/ground_dalles_morgane_01.png", "relief_mur_morgane",
		Color(0.61, 0.57, 0.63), 2701],
	&"fighting_dojo": ["res://assets/world/ground/ground_parquet_dojo_01.png", "relief_mur_dojo",
		Color(0.71, 0.61, 0.50), 2711],
}
## Carte → [nœud racine, grille, nom affiché (celui de la zone, comme l'Arène d'Erika)].
const MAPS: Dictionary = {
	&"saffron_gym": ["SaffronGym", "safrania_arene", "Safrania"],
	&"fighting_dojo": ["FightingDojo", "safrania_dojo", "Safrania"],
}

var _root: Node2D
var _errors: int = 0
var _masks_written: int = 0
var _kit: Object


func _init() -> void:
	for map_id: StringName in MAPS:
		var plan := PlanGrid.new()
		var path := "res://tools/plans/%s.txt" % MAPS[map_id][1]
		if not plan.load_file(path):
			push_error("build_saffron_gym : grille %s illisible (%s)" % [path, plan.error])
			quit(1)
			return
		_build(map_id, plan)
	if _errors > 0:
		quit(1)
	elif _masks_written > 0:
		print("build_saffron_gym : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks_written)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName, plan: PlanGrid) -> void:
	var size := Vector2i(plan.width, plan.height)
	if _make_root(map_id, plan, size) == null:
		return
	var ids: Array = plan.positions.keys()
	ids.sort()
	for id: String in ids:
		var cell: Vector2i = plan.cell_of(id)
		match String(plan.positions[id]["kind"]):
			"spawn":
				var marker := Marker2D.new()
				marker.name = id
				marker.position = _world(cell)
				_attach(_root.get_node(^"Spawns"), marker)
			"teleporteur":
				var vers := plan.attr(id, "vers")
				var point := _warp("Teleporter_%s" % id.trim_prefix("teleporteur_"), cell, STEP_ON,
					Vector2i.ZERO, StringName(vers.get_slice(":", 0)),
					StringName(vers.get_slice(":", 1)), Vector2i.ZERO)
				point.set(&"style", STYLE_TELEPORT)
			"warp":
				var vers := plan.attr(id, "vers")
				var cells := plan.cells_at(id)
				cells.sort()
				for index: int in cells.size():
					_warp("Exit%d" % index, cells[index], PUSH, Vector2i.DOWN,
						StringName(vers.get_slice(":", 0)), StringName(vers.get_slice(":", 1)),
						Vector2i.DOWN)
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			if not plan.is_walkable(Vector2i(x, y)):
				blocked.append(Vector2i(x, y))
	_root.set(&"blocked_cells", blocked)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		_root.free()
		return
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées, %d passages)" % [map_id, error_string(err), blocked.size(),
		_root.get_node(^"Warps").get_child_count()])
	if err != OK:
		_errors += 1
	_root.free()


## Salle en modules sur le kit : sol peint (masque), murs, tapis et paillasson ; couches logiques
## retirées. Null si le masque vient d'être écrit ou en cas d'erreur.
func _make_root(map_id: StringName, plan: PlanGrid, size: Vector2i) -> Node2D:
	var art: Array = ART[map_id]
	_kit = Kit.new("res://tools/plans/%s.txt" % MAPS[map_id][1], size, art[3], art[3] + 1,
		plan.walkable)
	_kit.set(&"floor_texture_path", art[0])
	_kit.set(&"rubble_texture_path", art[0])
	_kit.set(&"mass_texture_path", GROUND_MASS)
	_kit.set(&"border_color", art[2])
	_kit.set(&"rubble_mark", NO_RUBBLE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_kit.set(&"wall_marks", WALL_MARK)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		return null
	_root = _kit.call(&"make_root", MAPS[map_id][0], map_id, MAPS[map_id][2], &"")
	_root.set(&"interior", true)
	if not _kit.call(&"add_ground", MASK_PATH % map_id):
		if not (_kit.get(&"errors") as PackedStringArray).is_empty():
			push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
			_errors += 1
		else:
			_masks_written += 1
		_kit.call(&"discard")
		return null
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := _root.get_node(layer_name)
		_root.remove_child(layer)
		layer.free()
	ModuleWalls.new(_kit, art[1], WALL_MARK, WALL_MARK, art[3] + 2).place()
	for cell: Vector2i in plan.cells_of("T"):
		_kit.call(&"add_floor_prop", TELEPORTER, cell, "Pad%02d_%02d" % [cell.x, cell.y])
	var exits: Array[Vector2i] = plan.cells_of("E")
	exits.sort()
	for index: int in range(1, exits.size(), 2):
		_kit.call(&"add_floor_prop", DOORMAT, exits[index], "Doormat%d" % index)
	return _kit.get(&"entities")


func _warp(node_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i) -> Marker2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(_root.get_node(^"Warps"), point)
	return point


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
