extends SceneTree
## Construit les cinq cartes du repaire Rocket sous le Casino : `rocket_hideout_b1f` à `b4f` et la
## cabine `rocket_hideout_elevator` (jalon 20 T20, docs/tech/jalon-20.md §2.1, §2.4, §2.7.1 ;
## dossier 23 §13), d'après les grilles `tools/plans/repaire_b1f..b4f.txt` et
## `repaire_ascenseur.txt` (géométrie de Rouge/Bleu case pour case, marges vides conservées).
## Dresseurs, objets, Clé, Giovanni et Scope : `data/npcs/rocket_hideout_b*.json` (T21) ; leurs
## cases (`bloque`) sont libres dans la grille. L'outil pose seulement les points d'examen (T21).
##
##   godot --headless --path . -s res://tools/build_rocket_hideout.gd [-- --only=rocket_hideout_b2f]
##   godot --headless --path . --import
##
## - **La grille fait foi** : sol de béton sans rencontre ; murs, caisses (`X`), conduites (`P`),
##   consoles (`M`) bloqués ; `<` `>` `^` `v` dalles tournantes et `o` cases d'arrêt praticables.
## - **Dalles** : nœud `SpinTiles` ([SpinTileField], §2.4.2) : flèches et arrêts lus de la grille ;
##   le directeur (T19) fait le reste. Image : une décalcomanie par case (flèche orientée comme
##   `< > ^ v`, disque sur `o`), couche du sol, sans emprise.
## - **Passages** : escaliers `STEP_ON` sans direction vers l'arrivée de même paire de l'étage
##   voisin (`from_<paire>`) ; portes d'ascenseur (24..25, y) `STEP_ON` sans direction vers la
##   cabine (`entrance_w|e`) ; sortie de la cabine vers le B1F (`from_elevator`), que
##   l'`ElevatorDirector` réoriente vers l'étage courant.
## - **Porte du bureau** (B4F, (24..25, 11)) : praticable dans la grille de la scène, occupée par
##   le [FlagGate] `OfficeDoor` (`unless rocket_hideout_b4f_door_open`, comme l'arbuste du J16) ;
##   le T21 pose les gardes et le drapeau.
## - **Objets cachés** (T21) : un point EXAMINER par cache ([constant HIDDEN], orientation exigée
##   = celle de la grille, `depuis=… face=…`), retiré quand `got_<id>` est levé ; porte du bureau
##   fermée examinable depuis le sud (`rocket_hideout_b4f_office_door`, texte 153).
## - **Cabine** : un point d'examen `elevator_panel` (action `open_elevator`, T13) en (1, 1).
## - Lumière `hideout` ; cartes de « grotte » (`caves.json`, `interior = false`).
## - **Art en modules** (série 22 bis, fiche `serie-22bis-celadopole.md` §B, Q-2 : seule dérogation
##   à la règle de remplacement) : les quatre étages sont bâtis sur `tools/cave_map_kit.gd` comme la
##   Tour (sol de béton peint, masse sombre sur les murs et les marges vides, murs
##   `relief_mur_repaire_*` aux rôles de la Tour par `tools/module_walls.gd`, caisses `X`,
##   conduites `P`, consoles `M`, bureau de Giovanni sur le bloc 4 × 2 du B4F, escaliers `U` / `D`
##   et portes d'ascenseur `L` au sol). Le kit ne sert qu'à l'image : ses couches logiques
##   (`Ground`…) sont retirées, la collision reste `blocked_cells` d'après la grille (la porte `B`
##   y est praticable, sa FlagGate l'occupe). La cabine reste une **coque peinte** (`Shell`).
##   Deux passes au premier lancement (masque du sol écrit : importer puis relancer, code 2).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const TILE: int = 96
const STEP_ON: int = 0
const OUT_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const CAR_SHELL_PATH: String = "res://assets/world/interiors/int_rocket_hideout_elevator_coque.png"
const DOOR_PATH: String = "res://assets/world/interiors/hideout_office_door.png"
## Sol de béton (canal de base) et masse sombre des murs et des marges vides (canal G), comme la
## Tour ; frontière bruitée gris anthracite [D].
const GROUND_FLOOR: String = "res://assets/world/ground/ground_beton_repaire_01.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_roche_01.png"
const BORDER_COLOR := Color(0.17, 0.18, 0.21)
## Caractère sans cellule : pas de gravats dans le repaire (canal R inutilisé).
const NO_RUBBLE_MARK: String = "~"
const WALL_MARK: String = "#"
const WALL_PREFIX: String = "relief_mur_repaire"
const CRATE: String = "int_caisse_repaire_01"
const PIPE: String = "int_conduite_repaire_01"
const CONSOLE: String = "int_console_repaire_01"
const DESK: String = "int_bureau_giovanni_01"
## Bureau de Giovanni : bloc `M` de 4 × 2 du bureau du B4F (24..27, 4..5), ancré sur la 3e case
## de la rangée du bas (module pair, pied sur le bord).
const DESK_MAP: StringName = &"rocket_hideout_b4f"
const DESK_RECT := Rect2i(24, 4, 4, 2)
const DESK_ANCHOR := Vector2i(26, 5)
const STAIRS_UP: String = "int_escalier_repaire_monte_01"
const STAIRS_DOWN: String = "int_escalier_repaire_descend_01"
const ELEVATOR_DOOR: String = "int_porte_ascenseur_repaire_01"
const ARROW_DECALS: Dictionary[String, String] = {
	"<": "decal_fleche_repaire_01_gauche", ">": "decal_fleche_repaire_01",
	"^": "decal_fleche_repaire_01_haut", "v": "decal_fleche_repaire_01_bas",
}
const STOP_DECAL: String = "decal_arret_repaire_01"
## Graines des étages : [logique, décor, murs].
const SEEDS: Dictionary[StringName, Array] = {
	&"rocket_hideout_b1f": [2201, 2202, 2203], &"rocket_hideout_b2f": [2211, 2212, 2213],
	&"rocket_hideout_b3f": [2221, 2222, 2223], &"rocket_hideout_b4f": [2231, 2232, 2233],
}
const DISPLAY_NAME: String = "Céladopole"
const LIGHT_PROFILE: StringName = &"hideout"
const CAR_MAP: StringName = &"rocket_hideout_elevator"
const CAR_EXIT_MAP: StringName = &"rocket_hideout_b1f"
const ELEVATOR_SPAWN: StringName = &"from_elevator"
const OFFICE_DOOR_FLAG: StringName = &"rocket_hideout_b4f_door_open"
const OFFICE_DOOR_CELLS: Array[Vector2i] = [Vector2i(24, 11), Vector2i(25, 11)]
const PANEL_DIALOGUE: StringName = &"elevator_panel"
const OFFICE_DOOR_DIALOGUE: StringName = &"rocket_hideout_b4f_office_door"
## Objets cachés (T21) : carte → [[identifiant (dialogue, scène, `got_<id>`), case, orientation
## exigée du joueur]] (grilles : `pp_plus_cache`, `pepite_cachee`, `super_potion_cachee`).
const HIDDEN: Dictionary[StringName, Array] = {
	&"rocket_hideout_b1f": [["rocket_hideout_b1f_hidden_1", Vector2i(21, 15), Vector2i.RIGHT]],
	&"rocket_hideout_b3f": [["rocket_hideout_b3f_hidden_1", Vector2i(27, 17), Vector2i.DOWN]],
	&"rocket_hideout_b4f": [["rocket_hideout_b4f_hidden_1", Vector2i(25, 1), Vector2i.UP]],
}
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
var _masks_written: int = 0
var _kit: Object


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
	if _errors > 0:
		quit(1)
	elif _masks_written > 0:
		print("build_rocket_hideout : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks_written)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	_map_id = map_id
	var plan: PlanGrid = _plans[map_id]
	var size: Vector2i = MAPS[map_id][2]
	var entities: Node2D
	if map_id == CAR_MAP:
		entities = _make_car_root(size)
	else:
		entities = _make_floor_root(map_id, plan, size)
	if entities == null:
		return
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
		_add_point("OfficeDoorExamine", OFFICE_DOOR_CELLS[0], Vector2i(2, 1), Vector2i.UP,
			OFFICE_DOOR_DIALOGUE, [OFFICE_DOOR_FLAG])
	for entry: Array in HIDDEN.get(map_id, []):
		var hidden_id := StringName(entry[0])
		_add_point("Hidden_%s" % hidden_id, entry[1], Vector2i.ONE, entry[2], hidden_id,
			[StringName("got_%s" % hidden_id)])
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var open := plan.walkable.contains(plan.at(cell)) or (door and plan.at(cell) == "B")
			if not open:
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	if _kit != null and not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		_root.free()
		return
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées par la grille, %d nœuds)" % [map_id, error_string(err),
		blocked.size(), _count(_root)])
	if err != OK:
		_errors += 1
	_root.free()


## Cabine : coque peinte (`Shell`, 576 × 768), comme les autres cabines.
func _make_car_root(size: Vector2i) -> Node2D:
	_kit = null
	_root = Node2D.new()
	_root.name = MAPS[CAR_MAP][0]
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", CAR_MAP)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", size)
	_root.set(&"interior", false)
	_root.set(&"light_profile", LIGHT_PROFILE)
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(CAR_SHELL_PATH)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : coque %s ≠ %s cases" % [CAR_MAP, shell.texture.get_size(), size])
		_errors += 1
		_root.free()
		return null
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
	return entities


## Étage en modules sur le kit : racine, sol peint (masque), murs, mobilier, décalcomanies des
## dalles. Les couches logiques du kit sont retirées (collision = `blocked_cells`). Null si le
## masque vient d'être écrit ou en cas d'erreur.
func _make_floor_root(map_id: StringName, plan: PlanGrid, size: Vector2i) -> Node2D:
	var seeds: Array = SEEDS[map_id]
	_kit = Kit.new("res://tools/plans/%s.txt" % MAPS[map_id][1], size, seeds[0], seeds[1],
		plan.walkable)
	_kit.set(&"floor_texture_path", GROUND_FLOOR)
	_kit.set(&"rubble_texture_path", GROUND_FLOOR)
	_kit.set(&"mass_texture_path", GROUND_MASS)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_mark", NO_RUBBLE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_kit.set(&"wall_marks", WALL_MARK)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		return null
	_root = _kit.call(&"make_root", MAPS[map_id][0], map_id, DISPLAY_NAME, LIGHT_PROFILE)
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
	var walls: Vector3i = ModuleWalls.new(_kit, WALL_PREFIX, WALL_MARK, WALL_MARK,
		seeds[2]).place()
	var props := _place_furniture(map_id, plan)
	var decals := _place_floor_marks(plan)
	print("%s : murs %d faces / %d côtés / %d couronnes, %d meubles, %d marques au sol" % [
		map_id, walls.x, walls.y, walls.z, props, decals])
	return _kit.get(&"entities")


## Caisses `X`, conduites `P`, consoles `M` (le bloc 4 × 2 du bureau du B4F reçoit le bureau de
## Giovanni), une par case. Renvoie le nombre d'objets.
func _place_furniture(map_id: StringName, plan: PlanGrid) -> int:
	var entities: Node2D = _kit.get(&"entities")
	var count := 0
	for entry: Array in [["X", CRATE, "Crate"], ["P", PIPE, "Pipe"], ["M", CONSOLE, "Console"]]:
		for cell: Vector2i in plan.cells_of(entry[0]):
			if map_id == DESK_MAP and DESK_RECT.has_point(cell):
				continue
			_kit.call(&"add_prop_at", entities, entry[1], cell, "%s%03d" % [entry[2], count])
			count += 1
	if map_id == DESK_MAP:
		_kit.call(&"add_prop_at", entities, DESK, DESK_ANCHOR, "GiovanniDesk")
		count += 1
	return count


## Au sol, sans emprise : escaliers `U` / `D`, portes d'ascenseur `L` (un module de 2 cases par
## paire, ancré sur la case de droite), flèches des dalles orientées comme la grille, disques
## d'arrêt `o`. Renvoie le nombre de marques.
func _place_floor_marks(plan: PlanGrid) -> int:
	var count := 0
	for cell: Vector2i in plan.cells_of("U"):
		_kit.call(&"add_floor_prop", STAIRS_UP, cell, "StairsUp%d" % count)
		count += 1
	for cell: Vector2i in plan.cells_of("D"):
		_kit.call(&"add_floor_prop", STAIRS_DOWN, cell, "StairsDown%d" % count)
		count += 1
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "ascenseur":
			continue
		var cells: Array[Vector2i] = plan.cells_at(id)
		cells.sort()
		_kit.call(&"add_floor_prop", ELEVATOR_DOOR, cells[1], "ElevatorDoorPanel")
		count += 1
	for character: String in ARROW_DECALS:
		for cell: Vector2i in plan.cells_of(character):
			_kit.call(&"add_floor_prop", ARROW_DECALS[character], cell, "Arrow%03d" % count)
			count += 1
	for cell: Vector2i in plan.cells_of("o"):
		_kit.call(&"add_floor_prop", STOP_DECAL, cell, "Stop%03d" % count)
		count += 1
	return count


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
## n'est pas levé ; le battant est l'image peinte `hideout_office_door.png` (192 × 96).
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


## Point d'examen (T21) : [param unless] = drapeaux qui le retirent (`got_<id>`, porte ouverte).
func _add_point(node_name: String, cell: Vector2i, size: Vector2i, facing: Vector2i,
		dialogue: StringName, unless: Array) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	point.set(&"size", size)
	point.set(&"facing", facing)
	var flags: Array[StringName] = []
	flags.assign(unless)
	point.set(&"unless_flags", flags)
	_attach(_root.get_node(^"Interactables"), point)


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
