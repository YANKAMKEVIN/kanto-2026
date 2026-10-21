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
## - **Art en modules** (série 22 bis, fiche `serie-22bis-celadopole.md` §B, Q-2) sur
##   `tools/cave_map_kit.gd` comme la Tour : moquette peinte, murs `relief_mur_casino_*` aux rôles
##   de la Tour (`tools/module_walls.gd`), machines `M` (deux variantes à la graine), tabourets `t`
##   au sol (praticables, sans emprise), comptoir `C` juxtaposé case par case, affiche `A` posée
##   devant la face du mur, escalier `S` (descente du repaire) sous le mur coulissant. Le kit ne
##   sert qu'à l'image : ses couches logiques sont retirées, la collision reste `blocked_cells`.
## - **Mur du fond de cinq rangées** (y 0..4) [D] : la face (rangée 4, ≈ 2 cases de haut) déborde
##   sur la rangée 3 ; les rangées 0 à 2 montrent la masse sombre du sol peint (canal G, même
##   texture que la Tour), comme le haut des murs de la Tour. L'escalier `S` fait une niche dans
##   la face (la face s'arrête de part et d'autre) ; l'affiche est posée sur la face continue.
##   Deux passes au premier lancement (masque du sol écrit : importer puis relancer, code 2).

const PLAN_PATH: String = "res://tools/plans/casino.txt"
const OUT_PATH: String = "res://game/world/maps/celadon_game_corner.tscn"
const MASK_PATH: String = "res://assets/world/maps/celadon_game_corner_ground.png"
const WALL_PATH: String = "res://assets/world/interiors/game_corner_wall.png"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const SEED: int = 2241
const DECOR_SEED: int = 2242
const WALL_SEED: int = 2243
const MACHINE_SEED: int = 2244
const GROUND_FLOOR: String = "res://assets/world/ground/ground_moquette_casino_01.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_roche_01.png"
## Frontière bruitée moquette / masse : prune sombre [D].
const BORDER_COLOR := Color(0.16, 0.08, 0.11)
const NO_RUBBLE_MARK: String = "~"
const WALL_PREFIX: String = "relief_mur_casino"
## Maçonnerie qui reçoit les modules (`#`, et l'affiche `A` posée sur la face) ; l'escalier `S`
## compte comme paroi sans module (niche de l'escalier).
const MASONRY: String = "#A"
const WALL_LIKE: String = "#AS"
const MACHINES: Array[String] = ["int_machine_casino_01", "int_machine_casino_02"]
const STOOL: String = "int_tabouret_casino_01"
const COUNTER: String = "int_comptoir_casino_01"
const POSTER_PROP: String = "int_affiche_casino_01"
const STAIRS_PROP: String = "int_escalier_repaire_descend_01"
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
var _kit: Object


func _init() -> void:
	if not _plan.load_file(PLAN_PATH) or Vector2i(_plan.width, _plan.height) != SIZE:
		push_error("build_game_corner : grille illisible (%s)" % _plan.error)
		quit(1)
		return
	quit(_build())


## 0 : enregistré ; 2 : masque écrit, importer puis relancer ; 1 : erreur.
func _build() -> int:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, _plan.walkable)
	_kit.set(&"floor_texture_path", GROUND_FLOOR)
	_kit.set(&"rubble_texture_path", GROUND_FLOOR)
	_kit.set(&"mass_texture_path", GROUND_MASS)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_mark", NO_RUBBLE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_kit.set(&"wall_marks", "#")
	if not _errors().is_empty():
		push_error("build_game_corner :\n%s" % "\n".join(_errors()))
		return 1
	_root = _kit.call(&"make_root", "CeladonGameCorner", MAP_ID, DISPLAY_NAME, &"interior_warm")
	_root.set(&"interior", true)
	if not _kit.call(&"add_ground", MASK_PATH):
		_kit.call(&"discard")
		if not _errors().is_empty():
			push_error("build_game_corner :\n%s" % "\n".join(_errors()))
			return 1
		print("build_game_corner : masque écrit ; importer (--import) puis relancer")
		return 2
	# Image seulement : la collision reste `blocked_cells` (l'escalier `S` n'est pas praticable
	# dans la grille mais l'est dans la scène, sous le mur coulissant).
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := _root.get_node(layer_name)
		_root.remove_child(layer)
		layer.free()
	var entities: Node2D = _kit.get(&"entities")
	var walls: Vector3i = ModuleWalls.new(_kit, WALL_PREFIX, MASONRY, WALL_LIKE,
		WALL_SEED).place()
	var props := _place_furniture(entities)
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
	if not _errors().is_empty():
		push_error("build_game_corner :\n%s" % "\n".join(_errors()))
		_kit.call(&"discard")
		return 1
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("celadon_game_corner : %s (%d cases bloquées par la grille, murs %d faces / %d côtés / "
		% [error_string(result.x), blocked.size(), walls.x, walls.y]
		+ "%d couronnes, %d meubles, %d nœuds)" % [walls.z, props, result.y])
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


## Machines `M` (deux variantes à la graine), comptoir `C` case par case, tabourets `t` au sol
## (praticables : sans emprise, sous les personnages), affiche `A` devant la face du mur,
## escalier `S` au sol (caché par le mur coulissant tant que l'interrupteur n'est pas levé).
## Renvoie le nombre d'objets.
func _place_furniture(entities: Node2D) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = MACHINE_SEED
	var count := 0
	for cell: Vector2i in _plan.cells_of("M"):
		_kit.call(&"add_prop_at", entities, MACHINES[rng.randi_range(0, MACHINES.size() - 1)],
			cell, "Machine%02d" % count)
		count += 1
	for cell: Vector2i in _plan.cells_of("C"):
		_kit.call(&"add_prop_at", entities, COUNTER, cell, "Counter%02d" % count)
		count += 1
	for cell: Vector2i in _plan.cells_of("t"):
		_kit.call(&"add_floor_prop", STOOL, cell, "Stool%02d" % count)
		count += 1
	_kit.call(&"add_prop_at", entities, POSTER_PROP, POSTER, "PosterProp")
	_kit.call(&"add_floor_prop", STAIRS_PROP, STAIRS, "StairsProp")
	_add_stairs_lintel(entities)
	return count + 2


## Linteau de la niche de l'escalier : le haut d'une face (ce qui déborde au-dessus de la rangée
## 4) sur la case (17, 3), pour que la face du mur reste continue au-dessus du mur coulissant et
## de l'escalier (le haut de l'image de l'escalier passe dessous).
func _add_stairs_lintel(entities: Node2D) -> void:
	var id := WALL_PREFIX + "_01"
	var foot := Vector2((STAIRS.x + 0.5) * TILE, STAIRS.y * TILE)
	var sprite: Sprite2D = _kit.call(&"add_sprite", entities, id, foot, "StairsLintel")
	var size := sprite.texture.get_size()
	var height := size.y - TILE
	sprite.position = foot
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2((size.x - TILE) / 2.0, 0.0, TILE, height)
	sprite.offset = Vector2(-TILE / 2.0, -height)


## Mur coulissant : occupe (17, 4) tant que `game_corner_switch` n'est pas levé. La case est
## praticable dans la scène (escalier) ; le pan de mur peint (`game_corner_wall.png`, 96 × 96)
## la recouvre, au-dessus de l'image de l'escalier (couche du sol) : z 0 dans `Entities`.
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
