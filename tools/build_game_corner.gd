extends SceneTree
## Construit game/world/maps/celadon_game_corner.tscn (le Casino de Céladopole, 20 × 18 cases)
## d'après la grille fonctionnelle `tools/plans/casino.txt` (jalon 20 T20, docs/tech/jalon-20.md
## §2.1, §2.2, §2.6 ; dossier 23 §12). Le Rocket de l'affiche et les cinq PNJ sont dans
## `data/npcs/celadon_game_corner.json` (T21) ; leurs cases (`bloque`) sont libres dans la grille.
##
##   godot --headless --path . -s res://tools/build_game_corner.gd
##   godot --headless --path . --import
##
## - **La grille fait foi** : quatre rangées de machines (décor), trois allées, l'ancien comptoir
##   fermé, la coursive de la rangée y = 5 qui mène à l'escalier du repaire (17, 4).
## - **Mur coulissant** : [FlagGate] `SlidingWall` (`unless game_corner_switch`) qui occupe la
##   case (17, 4) tant que l'interrupteur de l'affiche n'est pas levé (§2.6) ; l'escalier
##   (warp STEP_ON sans direction vers `rocket_hideout_b1f` / `from_casino`) est dessous.
## - **Machines** : 56 en décor (bloquées par la grille), examinables depuis les allées (texte
##   39, dialogue `game_corner_machine`) : un point d'examen (2 × 7 cases) par bloc de machines,
##   posé sur les machines, lu de tout côté.
## - Passages : sortie (15..16, 17) PUSH ↓ → `celadon_city` / `from_casino_w|e` ; arrivées
##   `entrance` (15, 16) et `from_hideout` (17, 5).
## - **Affiche** (T21) : point d'examen `game_corner_poster` sur (9, 4), lu depuis (9, 5) tourné
##   vers le nord (case libérée par le départ du Rocket de l'affiche) ; scène `game_corner_switch`.
## - Halos `neon` (magenta et or) au-dessus des quatre rangées de machines.
## - **Art provisoire** : `tools/art/placeholders_repaire.py`.

const PLAN_PATH: String = "res://tools/plans/casino.txt"
const OUT_PATH: String = "res://game/world/maps/celadon_game_corner.tscn"
const SHELL_PATH: String = "res://assets/world/interiors/placeholder/ph_celadon_game_corner.png"
const WALL_PATH: String = "res://assets/world/interiors/placeholder/ph_game_corner_wall.png"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const SIZE := Vector2i(20, 18)
const MAP_ID: StringName = &"celadon_game_corner"
const DISPLAY_NAME: String = "Céladopole"
## Cases praticables : sol, tabourets (RB), sortie, escalier (condamné par le mur coulissant).
const WALKABLE: String = ".tES"
const PUSH: int = 1
const STEP_ON: int = 0
const STAIRS := Vector2i(17, 4)
const SWITCH_FLAG: StringName = &"game_corner_switch"
const MACHINE_DIALOGUE: StringName = &"game_corner_machine"
const POSTER_DIALOGUE: StringName = &"game_corner_poster"
const POSTER := Vector2i(9, 4)
const EXIT_CELLS: Array[Vector2i] = [Vector2i(15, 17), Vector2i(16, 17)]
const EXIT_SPAWNS: Array[StringName] = [&"from_casino_w", &"from_casino_e"]
const ENTRANCE := Vector2i(15, 16)
const FROM_HIDEOUT := Vector2i(17, 5)
const HIDEOUT_MAP: StringName = &"rocket_hideout_b1f"
const HIDEOUT_SPAWN: StringName = &"from_casino"
## Bandes de machines (colonnes de départ ; deux colonnes chacune, rangées 9 à 15).
const MACHINE_X: Array[int] = [0, 6, 12, 18]
const MACHINE_ROWS := Vector2i(9, 15)

var _root: Node2D
var _plan := PlanGrid.new()


func _init() -> void:
	if not _plan.load_file(PLAN_PATH) or Vector2i(_plan.width, _plan.height) != SIZE:
		push_error("build_game_corner : grille illisible (%s)" % _plan.error)
		quit(1)
		return
	_root = Node2D.new()
	_root.name = "CeladonGameCorner"
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", MAP_ID)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", SIZE)
	_root.set(&"interior", true)
	_root.set(&"light_profile", &"interior_warm")
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(SHELL_PATH)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture.get_size() != Vector2(SIZE * TILE):
		push_error("build_game_corner : enveloppe %s ≠ %s cases" % [shell.texture.get_size(), SIZE])
		quit(1)
		return
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers", "Glows"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
	_place_sliding_wall(entities)
	_add_passages()
	_add_machine_points()
	_add_poster_point()
	_add_neon()
	var blocked: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if not WALKABLE.contains(_plan.at(cell)):
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("celadon_game_corner : %s (%d cases bloquées par la grille, %d nœuds)" % [
		error_string(err), blocked.size(), _count(_root)])
	_root.free()
	quit(0 if err == OK else 1)


## Mur coulissant : occupe (17, 4) tant que `game_corner_switch` n'est pas levé. La case est
## praticable dans la grille (escalier) ; le décor du mur la recouvre.
func _place_sliding_wall(entities: Node2D) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "SlidingWall"
	gate.position = Vector2(STAIRS.x * TILE, STAIRS.y * TILE)
	var unless: Array[StringName] = [SWITCH_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = [STAIRS]
	gate.set(&"blocking_cells", blocking)
	_attach(entities, gate)
	var panel := Sprite2D.new()
	panel.name = "Panel"
	panel.texture = load(WALL_PATH)
	panel.centered = false
	panel.z_index = -2
	_attach(gate, panel)


func _add_passages() -> void:
	var spawns: Node = _root.get_node(^"Spawns")
	_add_spawn(spawns, "entrance", ENTRANCE)
	_add_spawn(spawns, "from_hideout", FROM_HIDEOUT)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for index: int in EXIT_CELLS.size():
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "Exit%d" % index
		point.position = _world(EXIT_CELLS[index])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", &"celadon_city")
		point.set(&"target_spawn", EXIT_SPAWNS[index])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(_root.get_node(^"Warps"), point)
	var stairs := Marker2D.new()
	stairs.set_script(warp_script)
	stairs.name = "StairsHideoutWarp"
	stairs.position = _world(STAIRS)
	stairs.set(&"trigger", STEP_ON)
	stairs.set(&"direction", Vector2i.ZERO)
	stairs.set(&"target_map", HIDEOUT_MAP)
	stairs.set(&"target_spawn", HIDEOUT_SPAWN)
	stairs.set(&"arrival_facing", Vector2i.DOWN)
	_attach(_root.get_node(^"Warps"), stairs)


func _add_spawn(parent: Node, spawn_name: String, cell: Vector2i) -> void:
	var spawn := Marker2D.new()
	spawn.name = spawn_name
	spawn.position = _world(cell)
	_attach(parent, spawn)


## Examen des machines (texte 39) : un point par bloc de machines (2 × 7 cases, posé sur les
## cases des machines elles-mêmes, comme le panneau d'une cabine) ; `facing` nul : on les lit
## de toutes les cases d'allée qui leur font face (tabourets compris).
func _add_machine_points() -> void:
	var script: GDScript = load("res://game/world/interactions/interact_point.gd")
	var parent: Node = _root.get_node(^"Interactables")
	var rows := MACHINE_ROWS.y - MACHINE_ROWS.x + 1
	for start: int in MACHINE_X:
		var point := Marker2D.new()
		point.set_script(script)
		point.name = "Machines%d" % start
		point.position = _world(Vector2i(start, MACHINE_ROWS.y))
		point.set(&"dialogue_id", MACHINE_DIALOGUE)
		point.set(&"size", Vector2i(2, rows))
		_attach(parent, point)


## Affiche (T21, §2.6) : examinée depuis (9, 5), tournée vers le nord.
func _add_poster_point() -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "Poster"
	point.position = _world(POSTER)
	point.set(&"dialogue_id", POSTER_DIALOGUE)
	point.set(&"facing", Vector2i.UP)
	_attach(_root.get_node(^"Interactables"), point)


## Halos néon au-dessus des quatre blocs de machines (magenta et or).
func _add_neon() -> void:
	var glow_script: GDScript = load("res://game/world/lighting/light_glow.gd")
	for index: int in MACHINE_X.size():
		var glow := Sprite2D.new()
		glow.set_script(glow_script)
		glow.name = "Neon%d" % index
		glow.set(&"glow_type", &"neon")
		glow.position = Vector2((MACHINE_X[index] + 1) * TILE, (MACHINE_ROWS.x + 1) * TILE)
		_attach(_root.get_node(^"Glows"), glow)


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
