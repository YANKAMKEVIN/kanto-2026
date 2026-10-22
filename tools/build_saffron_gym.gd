extends SceneTree
## Construit les deux défis de Safrania du jalon 27 (T6, T7 ; `docs/tech/jalon-27.md` §2.1, §2.3) :
## `saffron_gym` (Arène de Morgane, 20 × 18) et `fighting_dojo` (Dojo de Combat, 10 × 12),
## d'après `tools/plans/safrania_arene.txt` et `safrania_dojo.txt` (géométrie de Rouge/Bleu case
## pour case ; la grille fait foi).
##
##   python3 tools/art/placeholders_safrania_arene.py
##   godot --headless --path . -s res://tools/build_saffron_gym.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_saffron_city.gd   (portes de Safrania ouvertes)
##
## Géométrie et passages seulement : Morgane, le guide, les Dresseurs, le maître et les deux Poké
## Balls sont des données (`data/npcs/`) ; leurs cases restent praticables dans la scène.
## - **Image** : une enveloppe provisoire par carte (`Shell`, `ph_<carte>.png`).
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
const TILE: int = 96
const STEP_ON: int = 0
const PUSH: int = 1
const STYLE_TELEPORT: int = 1
const SHELL_DIR: String = "res://assets/world/interiors/placeholder/"
const OUT_DIR: String = "res://game/world/maps/"
## Carte → [nœud racine, grille, nom affiché].
const MAPS: Dictionary = {
	&"saffron_gym": ["SaffronGym", "safrania_arene", "Arène de Safrania"],
	&"fighting_dojo": ["FightingDojo", "safrania_dojo", "Dojo de Combat"],
}

var _root: Node2D
var _errors: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		var plan := PlanGrid.new()
		var path := "res://tools/plans/%s.txt" % MAPS[map_id][1]
		if not plan.load_file(path):
			push_error("build_saffron_gym : grille %s illisible (%s)" % [path, plan.error])
			quit(1)
			return
		_build(map_id, plan)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName, plan: PlanGrid) -> void:
	var size := Vector2i(plan.width, plan.height)
	_root = Node2D.new()
	_root.name = MAPS[map_id][0]
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", map_id)
	_root.set(&"display_name", MAPS[map_id][2])
	_root.set(&"size", size)
	_root.set(&"interior", true)
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(SHELL_DIR + "ph_%s.png" % map_id)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture == null or shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : enveloppe absente ou ≠ %s cases" % [map_id, size])
		_errors += 1
		_root.free()
		return
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
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
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées, %d passages)" % [map_id, error_string(err), blocked.size(),
		_root.get_node(^"Warps").get_child_count()])
	if err != OK:
		_errors += 1
	_root.free()


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
