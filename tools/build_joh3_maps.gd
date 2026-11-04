extends SceneTree
## Construit les cinq cartes du jalon JOH3 (Chapitre Johto, `docs/tech/jalon-joh3.md` §2.1 à
## §2.3) d'après leurs grilles fonctionnelles (`tools/plans/route_37.txt`, `route_36.txt`,
## `route_35.txt`, `doublonville.txt`, `souterrain.txt` : **la grille fait foi**), en **tuiles
## provisoires** (`OverworldTiles`, modèle du JOH2 : le code ne bloque jamais sur l'art) :
##   route_37, route_36, route_35, goldenrod_city (Doublonville), goldenrod_underground.
##
##   godot --headless --path . -s res://tools/build_joh3_maps.gd [-- --maps=route_37,route_35]
##   godot --headless --path . --import
##
## Données lues ailleurs (`tools/gen_joh3_data.py`) : PNJ, Dresseurs, objets visibles, textes,
## scènes. Ici : sol et cases bloquées, eau surfable et pêchable de l'étang de la Route 35,
## passages (bord = PUSH, porte = STEP_ON ↑, escaliers du Souterrain = STEP_ON dans le sens de
## la marche ; destination absente = « À venir »), arrivées (une par case), panneaux, examens,
## caches, déclencheurs, bâtiments du kit peint posés sur leur emprise [D], aplats provisoires
## (Tour Radio, gare, grille du Parc, poste de garde) [D], lampes de nuit (`night_lights`).
## Relancer `build_joh2_maps.gd --maps=ecruteak_city` après ce script : la sortie sud de
## Rosalia cesse d'être « À venir ».

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
const LIGHT_PROFILE: StringName = &"johto_auto"
const NIGHT_LIGHTS: StringName = &"night_lights"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1

## Cartes : grille, identifiant, nom, sous-titre (champ « region » de la carte), graine ;
## « light » : profil fixe (Souterrain : `underground`, comme les passages souterrains de Kanto ;
## sinon `johto_auto`).
const MAPS: Array[Dictionary] = [
	{"plan": "route_37", "id": &"route_37", "name": "Route 37", "region": "Rosalia — Route 36",
		"seed": 3701},
	{"plan": "route_36", "id": &"route_36", "name": "Route 36", "region": "Route 37 — Route 35",
		"seed": 3601},
	{"plan": "route_35", "id": &"route_35", "name": "Route 35",
		"region": "Doublonville — Route 36", "seed": 3501},
	{"plan": "doublonville", "id": &"goldenrod_city", "name": "Doublonville", "region": "Johto",
		"seed": 3401},
	{"plan": "souterrain", "id": &"goldenrod_underground", "name": "Souterrain",
		"region": "Doublonville", "seed": 3402, "light": &"underground"},
]

## Caractère d'une grille → type de tuile (nom de [enum OverworldTiles.Kind]), commun aux
## cartes ; [constant MAP_KINDS] remplace les caractères qui changent de sens d'une grille à
## l'autre. Les cases non praticables de la grille dont la tuile ne l'est pas sont bloquées par
## `blocked_cells`.
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "p": "COBBLE", "D": "COBBLE", "E": "COBBLE",
	"T": "FOREST", "x": "FOREST", "G": "FOREST", "a": "FOREST", "W": "WATER", "w": "WATER",
	"b": "BOARDWALK", "X": "CLIFF", "P": "CLIFF", "r": "CLIFF", "y": "GRASS", "n": "CROP",
	"U": "CLIFF", "A": "CLIFF", "L": "CLIFF", "C": "CLIFF", "m": "CLIFF", "N": "CLIFF",
	"F": "CLIFF", "k": "CROP",
}
const MAP_KINDS: Dictionary = {
	# Souterrain : dalles, murs, boutiques fermées (rideaux baissés).
	"goldenrod_underground": {".": "COBBLE", "b": "CLIFF"},
}
## Massifs de fleurs (bloqués) : herbe + fleurs peintes de Kanto, une par case (la tuile FLOWERS
## a un fond noir) [D].
const FLOWER_MARK: String = "y"
const FLOWER_PROP: String = "prop_fleurs_pales_01"
## Eau surfable (JH-36) : caractère par carte ; les cases qui touchent la berge sont pêchables.
const SURF_MARKS: Dictionary = {"route_35": "w"}

## Passages : (carte, position) → carte cible, arrivée, libellé « À venir » si la cible manque.
## « dir » : sens du pas d'un passage hors bord (défaut ↑) ; « facing » : orientation à l'arrivée
## (défaut : attribut de la grille cible, sinon le sens du passage).
const WARPS: Dictionary = {
	# Cartes d'autres jalons : « per_cell », une arrivée par case (`<nom>`, `<nom>_1`, `<nom>_2`).
	"route_37/warp_nord": {"to": &"ecruteak_city", "spawn": "from_route_37", "label": "Rosalia",
		"per_cell": true},
	"route_37/warp_sud": {"to": &"route_36", "spawn": "from_route_37"},
	"route_36/warp_nord": {"to": &"route_37", "spawn": "from_route_36"},
	"route_36/warp_sud": {"to": &"route_35", "spawn": "from_route_36"},
	"route_35/warp_nord": {"to": &"route_36", "spawn": "from_route_35"},
	"route_35/warp_sud": {"to": &"goldenrod_city", "spawn": "from_route_35"},
	"goldenrod_city/warp_nord": {"to": &"route_35", "spawn": "from_goldenrod"},
	"goldenrod_city/warp_sud": {"to": &"route_34", "spawn": "from_goldenrod", "label": "Route 34",
		"per_cell": true},
	# JOH5 : le hall de la Tour Radio (faux employé, D-18, D-19).
	"goldenrod_city/porte_tour_radio": {"to": &"goldenrod_radio_tower_1f", "spawn": "from_city",
		"label": "Tour Radio"},
	"goldenrod_city/porte_lien": {"to": &"goldenrod_bond_house", "spawn": "entrance"},
	"goldenrod_city/porte_centre": {"to": &"goldenrod_center", "spawn": "entrance"},
	"goldenrod_city/porte_maison_1": {"to": &"goldenrod_house_1", "spawn": "entrance"},
	"goldenrod_city/porte_maison_2": {"to": &"goldenrod_house_2", "spawn": "entrance"},
	"goldenrod_city/porte_magasin": {"to": &"goldenrod_dept_store_1f", "spawn": "entrance"},
	"goldenrod_city/escalier_ouest": {"to": &"goldenrod_underground",
		"spawn": "from_goldenrod_west", "dir": Vector2i.ZERO, "facing": Vector2i.RIGHT},
	"goldenrod_city/escalier_est": {"to": &"goldenrod_underground",
		"spawn": "from_goldenrod_east", "dir": Vector2i.ZERO, "facing": Vector2i.LEFT},
	"goldenrod_underground/escalier_ouest": {"to": &"goldenrod_city", "spawn": "from_underground_w",
		"dir": Vector2i.LEFT, "facing": Vector2i.DOWN},
	"goldenrod_underground/escalier_est": {"to": &"goldenrod_city", "spawn": "from_underground_e",
		"dir": Vector2i.RIGHT, "facing": Vector2i.UP},
}
## Déclencheurs : (carte, position) → scène, sens du pas (vide = toutes directions).
const TRIGGERS: Dictionary = {
	"goldenrod_city/arrivee_titre": {"scene": &"goldenrod_arrival", "dir": Vector2i.ZERO},
	"goldenrod_city/barriere_sud": {"scene": &"goldenrod_south_guard", "dir": Vector2i.DOWN},
}
## Décors examinables (bloqués) : (carte, position) → dialogue.
const DECOR_TEXTS: Dictionary = {
	"goldenrod_city/haut_parleur": &"goldenrod_speaker",
}
## Arrivées supplémentaires (alias) : (carte) → nom → case.
const EXTRA_SPAWNS: Dictionary = {
	# Point de Vol « Doublonville » (`fly_points.json` : `from_center`) = devant le Centre.
	"goldenrod_city": {"from_center": Vector2i(9, 28)},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte de droite ; la porte pour
## une porte d'une case), nœud].
const BUILDINGS: Dictionary = {
	"goldenrod_city": [
		["bldg_centre_01", Vector2i(10, 27), "Centre"],
		["bldg_maison_argenta_01", Vector2i(23, 15), "MaisonLien"],
		["bldg_maison_argenta_01", Vector2i(23, 27), "Maison1"],
		["bldg_maison_argenta_01", Vector2i(47, 15), "Maison2"],
	],
}
## Aplats provisoires [D] : (carte) → [nœud, rectangle de cases, couleur].
const TOWERS: Dictionary = {
	"route_36": [["GrilleParc", Rect2i(30, 1, 8, 6), Color(0.33, 0.36, 0.3)]],
	"route_35": [["PosteGarde", Rect2i(13, 35, 6, 5), Color(0.45, 0.36, 0.28)]],
	"goldenrod_city": [
		["TourRadio", Rect2i(6, 4, 10, 12), Color(0.55, 0.2, 0.18)],
		# Le Grand Magasin peint de Céladopole (14 cases) déborde de l'emprise de 12 : aplat.
		["GrandMagasin", Rect2i(44, 19, 12, 9), Color(0.62, 0.5, 0.32)],
		["Gare", Rect2i(52, 38, 14, 8), Color(0.38, 0.33, 0.3)],
		["HautParleur", Rect2i(43, 24, 1, 1), Color(0.25, 0.25, 0.28)],
	],
}
## Lampes de nuit [D] : (carte) → cases (centre du halo au milieu de la case).
const NIGHT_GLOWS: Dictionary = {
	"route_35": [Vector2i(12, 40), Vector2i(19, 40)],
	"goldenrod_city": [Vector2i(33, 6), Vector2i(37, 6), Vector2i(33, 13), Vector2i(37, 13),
		Vector2i(28, 23), Vector2i(42, 23), Vector2i(28, 35), Vector2i(42, 35), Vector2i(33, 41),
		Vector2i(37, 41), Vector2i(33, 51), Vector2i(37, 51), Vector2i(8, 28), Vector2i(11, 28),
		Vector2i(48, 28), Vector2i(51, 28), Vector2i(10, 16), Vector2i(11, 16), Vector2i(43, 23)],
}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}

var _over: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases (relues sur toutes les grilles avant de construire).
var _spawns: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_collect_spawns(spec)
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	print("build_joh3_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _wanted() -> Array:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			return Array(arg.trim_prefix("--maps=").split(","))
	return []


func _plan(spec: Dictionary) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + String(spec["plan"]) + ".txt"):
		_fail("%s : %s" % [spec["id"], plan.error])
	return plan


func _collect_spawns(spec: Dictionary) -> void:
	var plan := _plan(spec)
	var spawns: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			spawns[id] = entry["cells"]
	var extra: Dictionary = EXTRA_SPAWNS.get(String(spec["id"]), {})
	for name: String in extra:
		spawns[name] = [extra[name]]
	_spawns[spec["id"]] = spawns


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec, size)
	var blocked: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			var kinds: Dictionary = OUTDOOR_KINDS.merged(MAP_KINDS.get(String(spec["id"]), {}), true)
			if not kinds.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [spec["id"], mark, cell])
				continue
			var kind: int = _over.Kind[kinds[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if mark == FLOWER_MARK:
				_add_prop(root, FLOWER_PROP, cell, "Fleurs_%d_%d" % [x, y])
			if not plan.walkable.contains(mark) and not _over.is_solid_kind(kind):
				blocked.append(cell)
	_add_water(spec, plan, root, size)
	_add_positions(spec, plan, root, blocked)
	_add_buildings(spec, root)
	_add_towers(spec, root)
	_add_night_glows(spec, root)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


## Étang (JH-36) : toutes ses cases sont surfables ; celles qui touchent une case non-eau sont
## pêchables [D].
func _add_water(spec: Dictionary, plan: Object, root: Node2D, size: Vector2i) -> void:
	var mark: String = SURF_MARKS.get(String(spec["id"]), "")
	if mark.is_empty():
		return
	var surf: Array[Vector2i] = []
	var fishable: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if plan.at(cell) != mark:
				continue
			surf.append(cell)
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := cell + step
				if next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y \
						and plan.at(next) != mark:
					fishable.append(cell)
					break
	root.set(&"surf_cells", surf)
	root.set(&"fishable_cells", fishable)


func _add_positions(spec: Dictionary, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var map_id: StringName = spec["id"]
	var size := size_of(root)
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		var attrs: Dictionary = entry["attrs"]
		var key := "%s/%s" % [map_id, id]
		var unless := _flags(attrs.get("actif_sans", ""))
		var if_flags := _flags(attrs.get("actif_avec", ""))
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp":
				if not WARPS.has(key):
					_fail("%s : passage sans destination" % key)
					continue
				_add_warp(root, id, cells, WARPS[key], size, if_flags, unless)
			"panneau":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), [], [])
				_add_sign(root, cells[0], _node_name(id))
			"examen":
				var anchor := cells[0]
				var span := Vector2i(cells.size(), 1)
				_interact(root, _node_name(id), anchor, span, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), if_flags, unless)
			"decor":
				if DECOR_TEXTS.has(key):
					_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO,
						DECOR_TEXTS[key], [], [])
				for cell: Vector2i in cells:
					if not blocked.has(cell):
						blocked.append(cell)
			"cache":
				# Identifiants déjà pris par le souterrain de Kanto : préfixe de la carte.
				var item_id := "goldenrod_underground_" + id.trim_prefix("souterrain_") \
					if id.begins_with("souterrain_") else id
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO,
					StringName(item_id), [], [StringName("got_" + item_id)])
			"declencheur":
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])
	var extra: Dictionary = EXTRA_SPAWNS.get(String(map_id), {})
	for name: String in extra:
		_spawn(root, name, extra[name])


func size_of(root: Node2D) -> Vector2i:
	return root.get(&"size")


func _flags(text: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for flag: String in text.split(",", false):
		out.append(StringName(flag))
	return out


## Passage : un warp par case, chacun vers l'arrivée de même rang de la carte cible si elle en a
## autant (bords de 2 ou 3 cases), sinon vers la première. Bord = PUSH vers l'extérieur ; porte
## = STEP_ON ↑. Cible absente (autre jalon) : « À venir », retour sur l'arrivée de la case.
func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary,
		size: Vector2i, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var on_edge := _on_edge(cells[0], size)
	var trigger := PUSH if on_edge else STEP_ON
	var direction: Vector2i = _edge_direction(cells[0], size) if on_edge \
		else dest.get("dir", Vector2i.UP)
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var exists := _spawns.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		if not exists:
			_warp(root, name, cells[i], trigger, direction, &"",
				StringName(_back_spawn(root, cells[i])), -direction,
				dest.get("label", String(target)), if_flags, unless)
			continue
		var arrival := spawn
		if (target_cells.size() == cells.size() or dest.get("per_cell", false)) and i > 0:
			arrival = "%s_%d" % [spawn, i]
		var facing: Vector2i = dest["facing"] if dest.has("facing") \
			else _arrival_facing(target, spawn, direction)
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival), facing, "",
			if_flags, unless)


## Arrivée « tournée » de la carte cible (attribut facing de sa grille, sinon le sens du passage).
func _arrival_facing(target: StringName, spawn: String, direction: Vector2i) -> Vector2i:
	for spec: Dictionary in MAPS:
		if spec["id"] != target:
			continue
		var plan := _plan(spec)
		var entry: Dictionary = plan.positions.get(spawn, {})
		var facing: String = (entry.get("attrs", {}) as Dictionary).get("facing", "")
		if FACINGS.has(facing):
			return FACINGS[facing]
	return direction


## Arrivée de la carte qui se trouve sur la case [param cell] (retour d'un « À venir »).
func _back_spawn(root: Node2D, cell: Vector2i) -> String:
	var spawns: Dictionary = _spawns.get(root.get(&"map_id"), {})
	for name: String in spawns:
		var cells: Array = spawns[name]
		for i: int in cells.size():
			if cells[i] == cell:
				return name if i == 0 else "%s_%d" % [name, i]
	for name: String in spawns:
		return name
	return ""


func _on_edge(cell: Vector2i, size: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == size.x - 1 or cell.y == size.y - 1


func _edge_direction(cell: Vector2i, size: Vector2i) -> Vector2i:
	if cell.x == 0:
		return Vector2i.LEFT
	if cell.x == size.x - 1:
		return Vector2i.RIGHT
	if cell.y == 0:
		return Vector2i.UP
	return Vector2i.DOWN


func _node_name(id: String) -> String:
	return id.to_pascal_case()


# --- Nœuds ------------------------------------------------------------------------------------

func _new_map(spec: Dictionary, size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = String(spec["id"]).to_pascal_case()
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", spec["id"])
	root.set(&"display_name", spec["name"])
	root.set(&"region", spec["region"])
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", spec.get("light", LIGHT_PROFILE))
	# Tableaux typés posés explicitement : sans les autoloads, map.gd ne compile pas dans l'outil
	# et un tableau laissé par défaut serait enregistré « Array[int] ».
	for property: StringName in [&"calm_cells", &"slope_cells", &"surf_cells", &"forced_surf_cells",
			&"fishable_cells", &"low_cells", &"high_cells", &"stairs_cells", &"cycling_road_cells"]:
		var empty: Array[Vector2i] = []
		root.set(property, empty)
	var rows: Array[int] = []
	root.set(&"level_rows", rows)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	root.set(&"current_cells", currents)
	var tileset: TileSet = load(_over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var decor := Node2D.new()
	decor.name = "Decor"
	_attach(root, root, decor)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers", "NightLights"]:
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
		target: StringName, spawn: StringName, facing: Vector2i, coming_soon: String,
		if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"coming_soon", coming_soon)
	point.set(&"if_flags", if_flags)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, span: Vector2i, facing: Vector2i,
		dialogue: StringName, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", span)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	point.set(&"if_flags", if_flags)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Interactables"), point)


func _trigger(root: Node, node_name: String, cells: Array[Vector2i], direction: Vector2i,
		cutscene: StringName) -> void:
	var top_left := cells[0]
	var bottom_right := cells[0]
	for cell: Vector2i in cells:
		top_left = Vector2i(mini(top_left.x, cell.x), mini(top_left.y, cell.y))
		bottom_right = Vector2i(maxi(bottom_right.x, cell.x), maxi(bottom_right.y, cell.y))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = node_name
	# Ancre en bas à gauche (EventTriggerPoint : y -(size.y-1)..0).
	point.position = _world(Vector2i(top_left.x, bottom_right.y))
	point.set(&"size", bottom_right - top_left + Vector2i.ONE)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


## Panneau peint (son emprise bloque sa case).
func _add_sign(root: Node, cell: Vector2i, node_name: String) -> void:
	_add_prop(root, SIGN_PROP, cell, node_name + "Sign")


func _add_buildings(spec: Dictionary, root: Node) -> void:
	for entry: Array in BUILDINGS.get(String(spec["id"]), []):
		_add_prop(root, entry[0], entry[1], "Bat_" + String(entry[2]))


func _add_prop(root: Node, id: String, anchor: Vector2i, node_name: String) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", StringName(id), anchor)
	_attach(root, root.get_node(^"Entities"), prop)


## Tours en façade : aplats provisoires (corps sombre, toit plus clair) sur l'emprise bloquée de
## la grille [D] ; l'art du lot suivant les remplace.
func _add_towers(spec: Dictionary, root: Node) -> void:
	for entry: Array in TOWERS.get(String(spec["id"]), []):
		var rect: Rect2i = entry[1]
		var color: Color = entry[2]
		var body := Polygon2D.new()
		body.name = entry[0]
		var top_left := Vector2(rect.position) * TILE
		var size := Vector2(rect.size) * TILE
		var inset := TILE * 0.5
		body.polygon = PackedVector2Array([
			top_left + Vector2(inset, size.y * 0.25), top_left + Vector2(size.x - inset, size.y * 0.25),
			top_left + Vector2(size.x - inset, size.y), top_left + Vector2(inset, size.y)])
		body.color = color
		_attach(root, root.get_node(^"Decor"), body)
		var roof := Polygon2D.new()
		roof.name = entry[0] + "Toit"
		roof.polygon = PackedVector2Array([
			top_left + Vector2(0, size.y * 0.28), top_left + Vector2(size.x * 0.5, 0),
			top_left + Vector2(size.x, size.y * 0.28)])
		roof.color = color.lightened(0.25)
		_attach(root, root.get_node(^"Decor"), roof)


## Lampes de nuit : halos `LightGlow` (type `lamp`) du groupe `night_lights`, cachés par défaut ;
## `WorldLighting.set_night` les montre la nuit sur une carte `johto_auto`.
func _add_night_glows(spec: Dictionary, root: Node) -> void:
	var glow_script: GDScript = load("res://game/world/lighting/light_glow.gd")
	var index := 0
	for cell: Vector2i in NIGHT_GLOWS.get(String(spec["id"]), []):
		var glow := Sprite2D.new()
		glow.set_script(glow_script)
		glow.name = "Lampe%d" % index
		glow.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
		glow.set(&"glow_type", &"lamp")
		glow.visible = false
		_attach(root, root.get_node(^"NightLights"), glow)
		glow.add_to_group(NIGHT_LIGHTS, true)
		index += 1


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


func _fail(message: String) -> void:
	push_error("build_joh3_maps : " + message)
	_errors += 1
