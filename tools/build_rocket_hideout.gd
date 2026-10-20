extends SceneTree
## Construit les cinq cartes du repaire Rocket sous le Casino : `rocket_hideout_b1f` à `b4f` et la
## cabine `rocket_hideout_elevator` (jalon 20 T20, docs/tech/jalon-20.md §2.1, §2.4, §2.7.1 ;
## dossier 23 §13), d'après les grilles `tools/plans/repaire_b1f..b4f.txt` et
## `repaire_ascenseur.txt` (géométrie de Rouge/Bleu case pour case, marges vides conservées).
## **Géométrie seulement** : Dresseurs, objets, Clé, Giovanni, Scope et leurs scènes sont au T21 ;
## leurs cases (`bloque`) sont libres dans la grille.
##
##   godot --headless --path . -s res://tools/build_rocket_hideout.gd [-- --only=rocket_hideout_b2f]
##   godot --headless --path . --import
##
## - **La grille fait foi** : sol de béton sans rencontre ; murs, caisses (`X`), conduites (`P`),
##   consoles (`M`) bloqués ; `<` `>` `^` `v` dalles tournantes et `o` cases d'arrêt praticables.
## - **Dalles** : nœud `SpinTiles` ([SpinTileField], §2.4.2) : flèches et arrêts lus de la grille ;
##   les images des flèches et des disques sont cuites dans l'enveloppe (aucun nœud par case).
##   Le directeur (T19) fait le reste.
## - **Passages** : escaliers `STEP_ON` sans direction vers l'arrivée de même paire de l'étage
##   voisin (`from_<paire>`) ; portes d'ascenseur (24..25, y) `STEP_ON` sans direction vers la
##   cabine (`entrance_w|e`) ; sortie de la cabine vers le B1F (`from_elevator`), que
##   l'`ElevatorDirector` réoriente vers l'étage courant.
## - **Porte du bureau** (B4F, (24..25, 11)) : praticable dans la grille de la scène, occupée par
##   le [FlagGate] `OfficeDoor` (`unless rocket_hideout_b4f_door_open`, comme l'arbuste du J16) ;
##   le T21 pose les gardes et le drapeau.
## - **Cabine** : un point d'examen `elevator_panel` (action `open_elevator`, T13) en (1, 1).
## - Lumière `hideout` ; cartes de « grotte » (`caves.json`, `interior = false`).
## - **Art provisoire** : `tools/art/placeholders_repaire.py` (enveloppes `ph_rocket_hideout_*`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const STEP_ON: int = 0
const SHELL_DIR: String = "res://assets/world/interiors/placeholder/"
const OUT_DIR: String = "res://game/world/maps/"
const DOOR_PATH: String = "res://assets/world/interiors/placeholder/ph_hideout_office_door.png"
const DISPLAY_NAME: String = "Céladopole"
const LIGHT_PROFILE: StringName = &"hideout"
const CAR_MAP: StringName = &"rocket_hideout_elevator"
const CAR_EXIT_MAP: StringName = &"rocket_hideout_b1f"
const ELEVATOR_SPAWN: StringName = &"from_elevator"
const OFFICE_DOOR_FLAG: StringName = &"rocket_hideout_b4f_door_open"
const OFFICE_DOOR_CELLS: Array[Vector2i] = [Vector2i(24, 11), Vector2i(25, 11)]
const PANEL_DIALOGUE: StringName = &"elevator_panel"
const ARROWS: Dictionary[String, Vector2i] = {
	"<": Vector2i.LEFT, ">": Vector2i.RIGHT, "^": Vector2i.UP, "v": Vector2i.DOWN,
}
## Carte → [nom du nœud racine, grille, taille]. `celadon_game_corner` : seulement pour retrouver
## le point d'apparition du retour de l'escalier.
const MAPS: Dictionary[StringName, Array] = {
	&"rocket_hideout_b1f": ["RocketHideoutB1F", "repaire_b1f", Vector2i(30, 28)],
	&"rocket_hideout_b2f": ["RocketHideoutB2F", "repaire_b2f", Vector2i(30, 28)],
	&"rocket_hideout_b3f": ["RocketHideoutB3F", "repaire_b3f", Vector2i(30, 28)],
	&"rocket_hideout_b4f": ["RocketHideoutB4F", "repaire_b4f", Vector2i(30, 24)],
	&"rocket_hideout_elevator": ["RocketHideoutElevator", "repaire_ascenseur", Vector2i(6, 8)],
	&"celadon_game_corner": ["", "casino", Vector2i(20, 18)],
}
## Grille → carte (cibles `vers=<grille>:x,y` dont le nom de grille n'est pas l'identifiant).
const PLAN_MAP: Dictionary[String, StringName] = {"game_corner": &"celadon_game_corner"}
## Noms des points d'apparition : [carte][identifiant de la grille]. Normalisation du plan §1.3
## (`from_<paire>`, `entrance_w|e`).
const SPAWN_NAMES: Dictionary[StringName, Dictionary] = {
	&"rocket_hideout_b1f": {
		"arrivee_casino": "from_casino", "arrivee_b2f_nord": "from_b2f_north",
		"arrivee_b2f_sud": "from_b2f_south", "arrivee_ascenseur": "from_elevator",
	},
	&"rocket_hideout_b2f": {
		"arrivee_b1f_nord": "from_b1f_north", "arrivee_b1f_sud": "from_b1f_south",
		"arrivee_b3f": "from_b3f", "arrivee_ascenseur": "from_elevator",
	},
	&"rocket_hideout_b3f": {"arrivee_b2f": "from_b2f", "arrivee_b4f": "from_b4f"},
	&"rocket_hideout_b4f": {"arrivee_b3f": "from_b3f", "arrivee_ascenseur": "from_elevator"},
	&"rocket_hideout_elevator": {"entree_gauche": "entrance_w", "entree_droite": "entrance_e"},
	&"celadon_game_corner": {"arrivee_b1f": "from_hideout"},
}

var _root: Node2D
var _plans: Dictionary[StringName, PlanGrid] = {}
var _map_id: StringName
var _errors: int = 0


func _init() -> void:
	var only: StringName = &""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = StringName(arg.get_slice("=", 1))
	for map_id: StringName in MAPS:
		var plan := PlanGrid.new()
		var path := "res://tools/plans/%s.txt" % MAPS[map_id][1]
		if not plan.load_file(path) or Vector2i(plan.width, plan.height) != MAPS[map_id][2]:
			push_error("build_rocket_hideout : grille %s illisible ou ≠ %s (%s)" % [
				path, MAPS[map_id][2], plan.error])
			quit(1)
			return
		_plans[map_id] = plan
	for map_id: StringName in MAPS:
		if map_id == &"celadon_game_corner" or (only != &"" and only != map_id):
			continue
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	_map_id = map_id
	var plan: PlanGrid = _plans[map_id]
	var size: Vector2i = MAPS[map_id][2]
	_root = Node2D.new()
	_root.name = MAPS[map_id][0]
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
	if shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : enveloppe %s ≠ %s cases" % [map_id, shell.texture.get_size(), size])
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
	_add_spawns(plan)
	_add_stairs(plan)
	_add_elevator_doors(plan)
	if map_id == CAR_MAP:
		_add_car(plan)
	if plan.cells_of("<>^v").size() > 0 or plan.cells_of("o").size() > 0:
		_add_spin_tiles(plan)
	var door := plan.cells_of("B").size() > 0
	if door:
		_add_office_door(entities)
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var open := plan.walkable.contains(plan.at(cell)) or (door and plan.at(cell) == "B")
			if not open:
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées par la grille, %d nœuds)" % [map_id, error_string(err),
		blocked.size(), _count(_root)])
	if err != OK:
		_errors += 1
	_root.free()


func _add_spawns(plan: PlanGrid) -> void:
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "spawn":
			continue
		var marker := Marker2D.new()
		marker.name = _spawn_name(_map_id, id)
		marker.position = _world(plan.cell_of(id))
		_attach(_root.get_node(^"Spawns"), marker)


func _spawn_name(map_id: StringName, id: String) -> String:
	var names: Dictionary = SPAWN_NAMES[map_id]
	if not names.has(id):
		push_error("%s : point d'apparition « %s » sans nom" % [map_id, id])
		_errors += 1
		return id
	return names[id]


## Escaliers (`escalier`) : STEP_ON sans direction vers l'arrivée de même paire de la carte cible
## (orientation = celle de la grille de la cible).
func _add_stairs(plan: PlanGrid) -> void:
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "escalier":
			continue
		var pair: String = plan.attr(id, "paire")
		var target_plan_name := plan.attr(id, "vers").get_slice(":", 0)
		var target: StringName = PLAN_MAP.get(target_plan_name, StringName(target_plan_name))
		var target_plan: PlanGrid = _plans.get(target)
		var arrival := ""
		if target_plan != null:
			for other: String in target_plan.positions:
				if target_plan.positions[other]["kind"] == "spawn" \
						and target_plan.attr(other, "paire") == pair:
					arrival = other
		if arrival.is_empty():
			push_error("%s : escalier %s sans arrivée de paire %s dans %s" % [_map_id, id, pair,
				target])
			_errors += 1
			continue
		_add_warp("Stairs_%s" % id, plan.cell_of(id), target,
			StringName(_spawn_name(target, arrival)), _facing(target_plan.attr(arrival, "facing")))


## Portes d'ascenseur (`ascenseur`, deux cases) : la porte de gauche mène à `entrance_w`, celle
## de droite à `entrance_e` de la cabine ; arrivée tournée vers le bas.
func _add_elevator_doors(plan: PlanGrid) -> void:
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "ascenseur":
			continue
		var cells: Array[Vector2i] = plan.cells_at(id)
		cells.sort()
		for index: int in cells.size():
			_add_warp("ElevatorDoor%d" % index, cells[index], CAR_MAP,
				&"entrance_w" if index == 0 else &"entrance_e", Vector2i.DOWN)


## Cabine : portes (2..3, 1) vers le B1F (réorientées par l'ascenseur) et point d'examen du
## panneau d'étages (1, 1), lu depuis (1, 2) tourné vers le nord.
func _add_car(plan: PlanGrid) -> void:
	var doors: Array[Vector2i] = plan.cells_at("portes_cabine")
	doors.sort()
	for index: int in doors.size():
		_add_warp("CarDoor%d" % index, doors[index], CAR_EXIT_MAP, ELEVATOR_SPAWN, Vector2i.UP)
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "ElevatorPanel"
	point.position = _world(plan.cell_of("panneau"))
	point.set(&"dialogue_id", PANEL_DIALOGUE)
	point.set(&"facing", Vector2i.UP)
	_attach(_root.get_node(^"Interactables"), point)


## `SpinTiles` (§2.4.2) : flèches et cases d'arrêt de la grille.
func _add_spin_tiles(plan: PlanGrid) -> void:
	var field := Node2D.new()
	field.set_script(load("res://game/world/spin/spin_tile_field.gd"))
	field.name = "SpinTiles"
	var arrows: Dictionary[Vector2i, Vector2i] = {}
	for character: String in ARROWS:
		for cell: Vector2i in plan.cells_of(character):
			arrows[cell] = ARROWS[character]
	var stops: Array[Vector2i] = []
	stops.assign(plan.cells_of("o"))
	field.set(&"arrows", arrows)
	field.set(&"stops", stops)
	_attach(_root, field)


## Porte du bureau : [FlagGate] occupant (24..25, 11) tant que `rocket_hideout_b4f_door_open`
## n'est pas levé ; le battant est l'image `ph_hideout_office_door.png`.
func _add_office_door(entities: Node2D) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "OfficeDoor"
	gate.position = Vector2(OFFICE_DOOR_CELLS[0].x * TILE, OFFICE_DOOR_CELLS[0].y * TILE)
	var unless: Array[StringName] = [OFFICE_DOOR_FLAG]
	gate.set(&"unless_flags", unless)
	gate.set(&"blocking_cells", OFFICE_DOOR_CELLS.duplicate())
	_attach(entities, gate)
	var panel := Sprite2D.new()
	panel.name = "Panel"
	panel.texture = load(DOOR_PATH)
	panel.centered = false
	panel.z_index = -2
	_attach(gate, panel)


func _add_warp(node_name: String, cell: Vector2i, target: StringName, spawn: StringName,
		facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"trigger", STEP_ON)
	point.set(&"direction", Vector2i.ZERO)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(_root.get_node(^"Warps"), point)


func _facing(word: String) -> Vector2i:
	return {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
		"right": Vector2i.RIGHT}.get(word, Vector2i.DOWN)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
