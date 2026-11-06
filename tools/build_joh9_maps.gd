extends SceneTree
## Construit les cartes du jalon JOH9 (Mont Argenté, Route 28 ; `docs/tech/jalon-joh9.md` §2.1)
## d'après leurs grilles fonctionnelles (`tools/plans/silver_trail.txt`, `mt_silver_outside.txt`,
## `mt_silver_1f.txt`, `mt_silver_2f.txt`, `mt_silver_3f.txt`, `mt_silver_summit.txt`,
## `route_28.txt` : **la grille fait foi**), en **tuiles provisoires** (`OverworldTiles`, modèle du
## JOH2 et du J29 : le code ne bloque jamais sur l'art ; vues peintes validées pour le lot d'art) :
##   silver_trail, mt_silver_outside, mt_silver_1f, mt_silver_2f, mt_silver_3f, mt_silver_summit,
##   route_28.
## Intérieurs (Centre du Mont Argenté, poste de la Route 28, maison du gardien) :
## `build_painted_interiors.gd --joh9`. Porte neuve de la Route 22 (variante `JOH9`) :
## `build_joh9_route22.gd`.
##
##   godot --headless --path . -s res://tools/build_joh9_maps.gd [-- --maps=silver_trail,route_28]
##   godot --headless --path . --import
##
## **Image** : `tools/build_joh_ambiance.gd -- --maps=silver_trail,mt_silver_outside,mt_silver_summit,route_28`
## et `tools/build_joh_ambiance_caves.gd -- --maps=mt_silver_1f,mt_silver_2f,mt_silver_3f` repeignent
## ces cartes sans toucher à la logique (les aplats y sont retirés) ; les relancer après cet outil.
##
## Données lues ailleurs (`tools/gen_joh9_data.py`) : PNJ et Dresseurs (`data/npcs/<carte>.json`),
## textes (`data/dialogues/joh9_*.json`), scènes (`data/cutscenes/joh9_*.json`). Ici : sol et cases
## bloquées, eau surfable (lac du 1F), rochers de Force (1F), échelles, passages (bord = PUSH, porte
## = STEP_ON ; destination absente = « À venir »), arrivées, panneau, examens, déclencheurs des
## scènes, bâtiments du kit peint de Kanto posés sur leur emprise [D], mer de nuages du sommet en
## aplat [D]. Relancer `--maps=silver_trail` quand `lake_of_rage.tscn` (JOH6) existe : le raccord
## ouest cesse d'être « À venir ».

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
const LIGHT_PROFILE: StringName = &"johto_auto"
## Grottes : profil du Mont Sélénite (`data/world/lighting.json`) [D].
const CAVE_LIGHT: StringName = &"cave_1f"
const NIGHT_LIGHTS: StringName = &"night_lights"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1

## Cartes : grille, identifiant, nom, sous-titre (champ « region » de la carte), graine, grotte.
const MAPS: Array[Dictionary] = [
	{"plan": "silver_trail", "id": &"silver_trail", "name": "Sentier du Mont Argenté",
		"region": "Lac Colère — Mont Argenté", "seed": 9101},
	{"plan": "mt_silver_outside", "id": &"mt_silver_outside", "name": "Mont Argenté",
		"region": "Johto", "seed": 9102},
	{"plan": "mt_silver_1f", "id": &"mt_silver_1f", "name": "Mont Argenté", "region": "Grotte",
		"seed": 9103, "cave": true},
	{"plan": "mt_silver_2f", "id": &"mt_silver_2f", "name": "Mont Argenté", "region": "Grotte",
		"seed": 9104, "cave": true},
	{"plan": "mt_silver_3f", "id": &"mt_silver_3f", "name": "Mont Argenté", "region": "Grotte",
		"seed": 9105, "cave": true},
	{"plan": "mt_silver_summit", "id": &"mt_silver_summit", "name": "Sommet du Mont Argenté",
		"region": "Johto", "seed": 9106, "no_fly": true},
	{"plan": "route_28", "id": &"route_28", "name": "Route 28", "region": "Mont Argenté — Kanto",
		"seed": 9107},
]

## Caractère d'une grille → type de tuile (nom de [enum OverworldTiles.Kind]) [D] : neige `n` =
## SAND (pâle, praticable, sans rencontre) ; grotte : sol `.` DIRT, gravats `g` RUBBLE, paroi `#`
## et rochers `o` CLIFF, lac `w` WATER (surfable) ; mer de nuages `c` WATER (décor bloqué,
## recouverte d'un aplat blanc). Les cases non praticables de la grille dont la tuile ne l'est pas
## (porte, emprise) sont bloquées par `blocked_cells`.
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "n": "SAND", "D": "COBBLE", "T": "FOREST",
	"G": "FOREST", "R": "CLIFF", "o": "CLIFF", "C": "CLIFF", "P": "CLIFF", "m": "CLIFF",
	"K": "CLIFF", "E": "DIRT", "c": "WATER",
}
const CAVE_KINDS: Dictionary = {
	"#": "CLIFF", ".": "DIRT", "g": "RUBBLE", "o": "CLIFF", "w": "WATER", "U": "DIRT",
	"D": "DIRT", "E": "DIRT", "e": "DIRT",
}

## Passages : (carte, position) → carte cible, arrivée, libellé « À venir » si la cible manque.
## Les échelles (positions « escalier ») lisent leur cible dans l'attribut `vers=` de la grille.
const WARPS: Dictionary = {
	"silver_trail/warp_ouest": {"to": &"lake_of_rage", "spawn": "from_sentier",
		"label": "Lac Colère"},
	"silver_trail/warp_nord": {"to": &"mt_silver_outside", "spawn": "from_trail"},
	"silver_trail/porte_centre": {"to": &"mt_silver_center", "spawn": "entrance"},
	"mt_silver_outside/warp_sud": {"to": &"silver_trail", "spawn": "from_outside"},
	"mt_silver_outside/entree_grotte": {"to": &"mt_silver_1f", "spawn": "from_outside"},
	"mt_silver_1f/entree": {"to": &"mt_silver_outside", "spawn": "retour_grotte"},
	"mt_silver_1f/sortie_ouest": {"to": &"route_28", "spawn": "from_mt_silver"},
	"route_28/warp_est": {"to": &"mt_silver_1f", "spawn": "from_route_28"},
	"route_28/porte_poste": {"to": &"route_28_gate", "spawn": "from_route_28"},
	"route_28/porte_maison": {"to": &"route_28_house", "spawn": "entrance"},
}
## Déclencheurs : (carte, position) → scène, sens du pas (vide = toutes directions).
const TRIGGERS: Dictionary = {
	"mt_silver_outside/scene_relais": {"scene": &"mt_silver_relay", "dir": Vector2i.UP},
	"mt_silver_2f/scene_rival": {"scene": &"mt_silver_2f_rival", "dir": Vector2i.ZERO},
	"mt_silver_summit/scene_sommet": {"scene": &"mt_silver_summit", "dir": Vector2i.ZERO},
}
## Déclencheurs hors grille [D] : (carte) → [nœud, cases, sens, scène]. A-22 : entrée de la
## salle du vent (3F), une fois.
const EXTRA_TRIGGERS: Dictionary = {
	"mt_silver_3f": [["Vent", [Vector2i(12, 12), Vector2i(12, 13)], Vector2i.LEFT,
		&"mt_silver_3f_wind"]],
}
## Examens : (carte, position) → dialogue.
const EXAMINES: Dictionary = {
	"mt_silver_summit/ruines": &"mt_silver_summit_ruines",
	"mt_silver_summit/echarpe": &"mt_silver_summit_echarpe",
}
## Arrivées supplémentaires (alias) : (carte) → nom → case.
const EXTRA_SPAWNS: Dictionary = {
	# Point de Vol « Mont Argenté » (`fly_points.json`) = devant le Centre.
	"silver_trail": {"from_center": Vector2i(5, 12)},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte), nœud].
const BUILDINGS: Dictionary = {
	"silver_trail": [["bldg_centre_01", Vector2i(6, 11), "Centre"]],
	"route_28": [["bldg_poste_route_22_01", Vector2i(4, 9), "Poste"],
		["bldg_maison_argenta_01", Vector2i(23, 9), "MaisonGardien"]],
}
## Lampes de nuit [D] : (carte) → cases.
const NIGHT_GLOWS: Dictionary = {
	"silver_trail": [Vector2i(4, 12), Vector2i(7, 12)],
	"route_28": [Vector2i(22, 10), Vector2i(24, 10)],
}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
const COLOR_LADDER := Color(0.55, 0.38, 0.2)
const COLOR_LADDER_RUNG := Color(0.3, 0.2, 0.1)
const COLOR_CLOUDS := Color(0.94, 0.95, 0.98, 0.92)
const COLOR_SNOW := Color(0.96, 0.97, 1.0, 0.8)

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
	print("build_joh9_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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
	var cave: bool = spec.get("cave", false)
	var kinds: Dictionary = CAVE_KINDS if cave else OUTDOOR_KINDS
	var blocked: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if not kinds.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [spec["id"], mark, cell])
				continue
			var kind: int = _over.Kind[kinds[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if not plan.walkable.contains(mark) and not _over.is_solid_kind(kind) \
					and kinds[mark] != "WATER":
				blocked.append(cell)
	# Lac du 1F : eau surfable (Surf obligatoire vers le nord).
	var surf: Array[Vector2i] = []
	if cave:
		surf.assign(plan.cells_of("w"))
	root.set(&"surf_cells", surf)
	_add_positions(spec, plan, root, blocked)
	_add_buildings(spec, root)
	_add_night_glows(spec, root)
	_add_snow(spec, plan, root)
	_add_clouds(spec, plan, root)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


func _add_positions(spec: Dictionary, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var map_id: StringName = spec["id"]
	var size := size_of(root)
	var boulders: Array[Vector2i] = []
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
			"escalier":
				# Échelle : STEP_ON sans direction vers l'arrivée de la paire (attribut `vers=`).
				var target: String = attrs.get("vers", "")
				if target.is_empty():
					_fail("%s : échelle sans vers=" % key)
					continue
				var dest := StringName(target.get_slice(":", 0))
				var arrival := StringName(target.get_slice(":", 1))
				_warp(root, _node_name(id), cells[0], STEP_ON, Vector2i.ZERO, dest, arrival,
					_arrival_facing(dest, String(arrival), Vector2i.DOWN), "", [], [])
				_ladder(root, cells[0], attrs.get("sens", "") == "monte")
			"panneau":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), [], [])
				_add_sign(root, cells[0], _node_name(id))
			"examen":
				if not EXAMINES.has(key):
					_fail("%s : examen sans dialogue" % key)
					continue
				var anchor := cells[0]
				var span := Vector2i(cells.size(), 1)
				_interact(root, _node_name(id), anchor, span, Vector2i.ZERO, EXAMINES[key],
					if_flags, unless)
			"rocher":
				boulders.append(cells[0])
			"declencheur":
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])
	for extra: Array in EXTRA_TRIGGERS.get(String(map_id), []):
		var cells: Array[Vector2i] = []
		cells.assign(extra[1])
		_trigger(root, extra[0], cells, extra[2], extra[3])
	if not boulders.is_empty():
		_boulders(root, boulders)
	var spawns: Dictionary = EXTRA_SPAWNS.get(String(map_id), {})
	for name: String in spawns:
		_spawn(root, name, spawns[name])


## Rochers de Force (modèle du J29, sans trou ni interrupteur) : poussés dans tous les sens par
## les règles communes ([BoulderRules]) ; la grille donne la voie attendue (`lane=`).
func _boulders(root: Node, cells: Array[Vector2i]) -> void:
	var setup := Node.new()
	setup.set_script(load("res://game/world/boulders/boulder_setup.gd"))
	setup.name = "Boulders"
	var holes: Array[int] = []
	var requires: Array[StringName] = []
	for _cell: Vector2i in cells:
		holes.append(0)
		requires.append(&"")
	setup.set(&"boulder_cells", cells)
	setup.set(&"boulder_holes", holes)
	setup.set(&"boulder_requires", requires)
	for property: StringName in [&"hole_cells", &"switch_cells", &"no_push_cells"]:
		var empty: Array[Vector2i] = []
		setup.set(property, empty)
	var no_ints: Array[int] = []
	setup.set(&"hole_numbers", no_ints)
	for property: StringName in [&"hole_flags", &"switch_ids", &"switch_flags"]:
		var none: Array[StringName] = []
		setup.set(property, none)
	_attach(root, root, setup)


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
	var direction := _edge_direction(cells[0], size) if on_edge else Vector2i.UP
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var exists := _spawns.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	if target == &"lake_of_rage":  # grille du JOH6 : raccord case à case
		var lake := PlanGrid.new()
		if lake.load_file(PLANS_DIR + "lake_of_rage.txt"):
			target_cells = (lake.positions.get(spawn, {}) as Dictionary).get("cells", [])
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		if not exists:
			_warp(root, name, cells[i], trigger, direction, &"",
				StringName(_back_spawn(root, cells[i])), -direction,
				dest.get("label", String(target)), if_flags, unless)
			continue
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival),
			_arrival_facing(target, spawn, direction), "", if_flags, unless)


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
	root.set(&"light_profile", CAVE_LIGHT if spec.get("cave", false) else LIGHT_PROFILE)
	# Sommet : Vol et Téléport interdits [D] (dossier §13 : entre Dante et le rival ; la scène les
	# enchaîne, le sommet reste sans Vol, on redescend par l'échelle).
	root.set(&"no_fly", spec.get("no_fly", false))
	root.set(&"no_teleport", spec.get("no_fly", false))
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


## Échelle dessinée en aplats (modèle du J29) : montante = barreaux sur la paroi, descendante =
## trappe sombre.
func _ladder(root: Node, cell: Vector2i, up: bool) -> void:
	var ladder := Node2D.new()
	ladder.name = "Echelle%d_%d" % [cell.x, cell.y]
	ladder.position = _world(cell)
	_attach(root, root.get_node(^"Decor"), ladder)
	if up:
		_rect(root, ladder, Rect2(-30, -88, 60, 80), COLOR_LADDER)
		for k: int in 3:
			_rect(root, ladder, Rect2(-22, -80 + k * 24, 44, 8), COLOR_LADDER_RUNG)
	else:
		_rect(root, ladder, Rect2(-36, -84, 72, 72), Color(0.08, 0.06, 0.05))
		for k: int in 2:
			_rect(root, ladder, Rect2(-24, -70 + k * 26, 48, 8), COLOR_LADDER)


## Neige provisoire [D] : voile blanc léger sur les cases `n` et les herbes au-dessus de la
## muraille de glace du sentier (la tuile SAND seule fait plage).
func _add_snow(spec: Dictionary, plan: Object, root: Node) -> void:
	var cells: Array[Vector2i] = plan.cells_of("n")
	if cells.is_empty():
		return
	var layer := Node2D.new()
	layer.name = "Neige"
	_attach(root, root.get_node(^"Decor"), layer)
	for cell: Vector2i in cells:
		_rect(root, layer, Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE), COLOR_SNOW)


## Mer de nuages du sommet [D] : aplat blanc sur les cases `c`.
func _add_clouds(spec: Dictionary, plan: Object, root: Node) -> void:
	var cells: Array[Vector2i] = plan.cells_of("c")
	if cells.is_empty():
		return
	var layer := Node2D.new()
	layer.name = "Nuages"
	_attach(root, root.get_node(^"Decor"), layer)
	for cell: Vector2i in cells:
		_rect(root, layer, Rect2(cell.x * TILE - 8, cell.y * TILE - 16, TILE + 16, TILE + 24),
			COLOR_CLOUDS)


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


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
	push_error("build_joh9_maps : " + message)
	_errors += 1
