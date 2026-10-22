extends SceneTree
## Construit les douze cartes de la Sylphe SARL (jalon 26, T7 ; `docs/tech/jalon-26.md` §2.1, §2.2 ;
## `docs/tech/systemes-2.md` §2.9, §2.10) : `silph_co_1f` à `silph_co_11f` et la cabine
## `silph_co_elevator`, d'après `tools/plans/sylphe_1f.txt` … `sylphe_11f.txt` et
## `sylphe_ascenseur.txt` (géométrie de Rouge/Bleu case pour case, marges conservées ; la grille
## fait foi).
##
##   python3 tools/art/placeholders_sylphe.py
##   godot --headless --path . -s res://tools/build_silph_co.gd
##   godot --headless --path . --import
##
## Géométrie et passages, plus (T9) les points EXAMINER des objets cachés (`objet_cache`) et des
## rapports (`examen`) ; Dresseurs, PNJ, objets visibles, rival et Giovanni sont des données
## (`data/npcs/`) ; leurs cases restent praticables dans la scène.
## - `declencheur` (T11, T12 : rival du 7F, Giovanni du 11F) : [EventTriggerPoint] de `Triggers`
##   au nom de la grille, scène `scene=` (les variantes de la scène décident).
##
## - **Image** : une enveloppe provisoire par carte (`Shell`, `ph_<carte>.png`).
## - **Collision** : `blocked_cells` = cases non praticables de la grille (`PRATICABLES`).
## - `spawn` : Marker2D de `Spawns`, au nom de la grille (noms finals : `from_<étage>`,
##   `from_elevator`, `from_city`, `tp_<k>`, `entrance`). `depart` (repère du contrôle) : ignoré.
## - `escalier` : [WarpPoint] STEP_ON sans direction (`Stairs_to_<étage>`) vers `vers=`, arrivée
##   tournée comme le point d'apparition cible (vers le bas).
## - `teleporteur` : [WarpPoint] STEP_ON sans direction, style TELEPORT (`Teleporter_<k>`), vers
##   `vers=` ; orientation conservée (§2.9). Même étage → `SceneRouter.relocate`, autre étage →
##   `change_map` (le routeur choisit).
## - `ascenseur` : porte de l'étage (`ElevatorDoor`) STEP_ON vers `silph_co_elevator:entrance`,
##   arrivée tournée vers le haut ; cabine : portes du bas (`CarDoor0`, `CarDoor1`) STEP_ON vers
##   `silph_co_1f:from_elevator` (réorientées vers l'étage courant par l'`ElevatorDirector`),
##   panneau `ElevatorPanel` (dialogue `elevator_panel`, lu tourné vers le haut).
## - `porte_carte` : un [KeyDoor] par `id=` (`KeyDoor_<id>`, deux cases bloquées, un drapeau
##   `door_<carte>_<id>_open`, clé `card_key`) dans `Entities`, battant `Panel` ; un
##   [InteractPoint] OUVRIR par case (`Open_<id>_a`, `Open_<id>_b`, dialogue `key_door_locked`),
##   retiré par le même drapeau.
## - `warp` (1F) : sortie PUSH ↓ (`Exit0`, `Exit1`) vers `saffron_city:from_silph`.
## - Cartes de « grotte » au sens de `caves.json` (`interior = false`, Corde Sortie vers Safrania)
##   comme le repaire Rocket [D] ; lumière `office` [D] ; titre « Sylphe SARL ».

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const STEP_ON: int = 0
const PUSH: int = 1
const STYLE_TELEPORT: int = 1
const KIND_EXAMINE: int = 1
const KIND_OPEN: int = 5
const SHELL_DIR: String = "res://assets/world/interiors/placeholder/"
const OUT_DIR: String = "res://game/world/maps/"
const DOOR_V_PATH: String = SHELL_DIR + "ph_silph_door_v.png"
const DOOR_H_PATH: String = SHELL_DIR + "ph_silph_door_h.png"
const DISPLAY_NAME: String = "Sylphe SARL"
const LIGHT_PROFILE: StringName = &"office"
const CAR_MAP: StringName = &"silph_co_elevator"
const CAR_ENTRANCE: StringName = &"entrance"
const CAR_EXIT_MAP: StringName = &"silph_co_1f"
const ELEVATOR_SPAWN: StringName = &"from_elevator"
const PANEL_DIALOGUE: StringName = &"elevator_panel"
const KEY_ITEM: StringName = &"card_key"
const EXIT_MAP: StringName = &"saffron_city"
const EXIT_SPAWN: StringName = &"from_silph"

var _root: Node2D
var _map_id: StringName
var _plans: Dictionary[StringName, PlanGrid] = {}
var _maps: Dictionary[StringName, Array] = {}
var _errors: int = 0


func _init() -> void:
	for n: int in range(1, 12):
		_maps[StringName("silph_co_%df" % n)] = ["SilphCo%dF" % n, "sylphe_%df" % n]
	_maps[CAR_MAP] = ["SilphCoElevator", "sylphe_ascenseur"]
	for map_id: StringName in _maps:
		var plan := PlanGrid.new()
		var path := "res://tools/plans/%s.txt" % _maps[map_id][1]
		if not plan.load_file(path):
			push_error("build_silph_co : grille %s illisible (%s)" % [path, plan.error])
			quit(1)
			return
		_plans[map_id] = plan
	for map_id: StringName in _maps:
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	_map_id = map_id
	var plan: PlanGrid = _plans[map_id]
	var size := Vector2i(plan.width, plan.height)
	_root = Node2D.new()
	_root.name = _maps[map_id][0]
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", map_id)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", size)
	_root.set(&"interior", false)
	_root.set(&"light_profile", LIGHT_PROFILE)
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
	var doors: Dictionary[String, Array] = {}
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
			"escalier":
				_add_stairs(plan, id, cell)
			"teleporteur":
				var vers := plan.attr(id, "vers")
				var point := _warp("Teleporter_%s" % id.trim_prefix("teleporteur_"), cell, STEP_ON,
					Vector2i.ZERO, StringName(vers.get_slice(":", 0)),
					StringName(vers.get_slice(":", 1)), Vector2i.ZERO)
				point.set(&"style", STYLE_TELEPORT)
			"ascenseur":
				_warp("ElevatorDoor", cell, STEP_ON, Vector2i.ZERO, CAR_MAP, CAR_ENTRANCE,
					Vector2i.UP)
			"sortie":
				var cells := plan.cells_at(id)
				cells.sort()
				for index: int in cells.size():
					_warp("CarDoor%d" % index, cells[index], STEP_ON, Vector2i.ZERO, CAR_EXIT_MAP,
						ELEVATOR_SPAWN, Vector2i.DOWN)
			"panneau":
				_add_point("ElevatorPanel", cell, Vector2i.UP, PANEL_DIALOGUE, KIND_EXAMINE, [])
			"warp":
				var cells := plan.cells_at(id)
				cells.sort()
				for index: int in cells.size():
					_warp("Exit%d" % index, cells[index], PUSH, Vector2i.DOWN, EXIT_MAP, EXIT_SPAWN,
						Vector2i.DOWN)
			"declencheur":
				var trigger := Marker2D.new()
				trigger.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
				trigger.name = id
				trigger.position = _world(cell)
				trigger.set(&"cutscene_id", StringName(plan.attr(id, "scene")))
				_attach(_root.get_node(^"Triggers"), trigger)
			"objet_cache":
				# Objet caché (T9) : EXAMINER depuis la case `depuis`, tourné vers `face`, tant que
				# `got_<id>` est bas ; la scène de même nom (data/cutscenes/silph_co_life.json).
				_add_point("Hidden_%s" % id, cell, _facing_letter(plan.attr(id, "face")), StringName(id),
					KIND_EXAMINE, [StringName("got_%s" % id)])
			"examen":
				# Rapport posé sur un bureau (T9) : lu de n'importe quel côté, texte `texte`.
				_add_point("Report_%s" % id, cell, Vector2i.ZERO, StringName(plan.attr(id, "texte")),
					KIND_EXAMINE, [])
			"porte_carte":
				var door_id := plan.attr(id, "id")
				if not doors.has(door_id):
					doors[door_id] = []
				doors[door_id].append([id, cell])
	for door_id: String in doors:
		_add_key_door(entities, door_id, doors[door_id])
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
	print("%s : %s (%d cases bloquées, %d portes à carte, %d passages)" % [map_id,
		error_string(err), blocked.size(), doors.size(),
		_root.get_node(^"Warps").get_child_count()])
	if err != OK:
		_errors += 1
	_root.free()


## Escalier : vers le point d'apparition de la carte cible, tourné comme lui.
func _add_stairs(plan: PlanGrid, id: String, cell: Vector2i) -> void:
	var vers := plan.attr(id, "vers")
	var target := StringName(vers.get_slice(":", 0))
	var spawn := vers.get_slice(":", 1)
	var target_plan: PlanGrid = _plans.get(target)
	if target_plan == null or not target_plan.positions.has(spawn):
		push_error("%s : escalier %s → %s introuvable" % [_map_id, id, vers])
		_errors += 1
		return
	_warp("Stairs_%s" % id.replace("vers_", "to_"), cell, STEP_ON, Vector2i.ZERO, target,
		StringName(spawn), _facing(target_plan.attr(spawn, "facing")))


## Porte électronique : un [KeyDoor] sur ses deux cases, un point OUVRIR par case.
func _add_key_door(entities: Node2D, door_id: String, parts: Array) -> void:
	var cells: Array[Vector2i] = []
	for part: Array in parts:
		cells.append(part[1])
	cells.sort()
	if cells.size() != 2 or not Grid.is_cardinal(cells[1] - cells[0]):
		push_error("%s : porte %s sur %s (deux cases voisines attendues)" % [_map_id, door_id,
			cells])
		_errors += 1
		return
	var key_door: GDScript = load("res://game/world/key_door/key_door.gd")
	var flag: StringName = key_door.call(&"open_flag", _map_id, StringName(door_id))
	var gate := Node2D.new()
	gate.set_script(key_door)
	gate.name = "KeyDoor_%s" % door_id
	gate.position = Vector2(cells[0].x * TILE, cells[0].y * TILE)
	gate.set(&"door_id", StringName(door_id))
	gate.set(&"key_item", KEY_ITEM)
	var unless: Array[StringName] = [flag]
	gate.set(&"unless_flags", unless)
	gate.set(&"blocking_cells", cells)
	_attach(entities, gate)
	var panel := Sprite2D.new()
	panel.name = "Panel"
	panel.texture = load(DOOR_V_PATH if cells[1].x == cells[0].x else DOOR_H_PATH)
	panel.centered = false
	panel.z_index = -2
	_attach(gate, panel)
	for part: Array in parts:
		var suffix := String(part[0]).get_slice("_", String(part[0]).get_slice_count("_") - 1)
		_add_point("Open_%s_%s" % [door_id, suffix], part[1], Vector2i.ZERO,
			KeyDoor.LOCKED_DIALOGUE, KIND_OPEN, [flag])


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


func _add_point(node_name: String, cell: Vector2i, facing: Vector2i, dialogue: StringName,
		kind: int, unless: Array) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	point.set(&"kind", kind)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", facing)
	var flags: Array[StringName] = []
	flags.assign(unless)
	point.set(&"unless_flags", flags)
	_attach(_root.get_node(^"Interactables"), point)


func _facing_letter(letter: String) -> Vector2i:
	return {"N": Vector2i.UP, "S": Vector2i.DOWN, "W": Vector2i.LEFT, "E": Vector2i.RIGHT}.get(
		letter, Vector2i.UP)


func _facing(word: String) -> Vector2i:
	return {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
		"right": Vector2i.RIGHT}.get(word, Vector2i.DOWN)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
