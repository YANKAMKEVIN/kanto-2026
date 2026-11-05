extends SceneTree
## Construit les quatre cartes du jalon JOHP2 (arc des Pierres, `docs/tech/jalon-joh-pierres.md`
## §4 ; dossier JOH-11 §8.2) d'après leurs grilles validées (`tools/plans/goeland_deck.txt`,
## `cianwood_city.txt`, `tide_cave_1f.txt`, `tide_cave_b1f.txt` : **la grille fait foi** ; contrôle
## `tools/art/plan_check_johp.py`), en tuiles provisoires (`OverworldTiles`) :
##   goeland_deck (le pont, une seule carte pour les deux sens), cianwood_city (Irisia),
##   tide_cave_1f, tide_cave_b1f (Grotte de la Marée : `data/world/caves.json`).
##
## Ici : sol et cases bloquées, passages (bord = PUSH, porte = STEP_ON ↑, échelle = STEP_ON), arrivées
## (une par case, `<id>`, `<id>_1`…), panneaux, examens, déclencheurs, bâtiments du kit peint [D],
## aplats provisoires (pompes, socle) [D], eau pêchable d'Irisia, lampes de nuit, et les décors qui
## suivent les drapeaux ([FlagGate]) : les deux gués du B1F (eau qui bloque jusqu'à leur vanne, §8.2)
## et le bateau noir peint (Irisia et ouverture du B1F, jusqu'à `johto_stone_tide_lost`).
## PNJ, Dresseurs, objets, textes, scènes : `tools/gen_johp2_data.py`. **Aucun nom d'autoload** dans
## ce fichier ni dans ce qu'il charge (mémoire « Outils sans autoload »).
##
##   godot --headless --path . -s res://tools/build_johp2_maps.gd [-- --maps=cianwood_city]
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
const NIGHT_LIGHTS: StringName = &"night_lights"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1

## Cartes : grille, identifiant, nom, sous-titre (champ « region » de la carte), graine, lumière,
## table des tuiles.
const MAPS: Array[Dictionary] = [
	{"plan": "goeland_deck", "id": &"goeland_deck", "name": "Le Goéland",
		"region": "Oliville — Irisia", "seed": 7101, "light": &"johto_auto", "kinds": "deck"},
	{"plan": "cianwood_city", "id": &"cianwood_city", "name": "Irisia", "region": "Johto",
		"seed": 7102, "light": &"johto_auto", "kinds": "island"},
	{"plan": "tide_cave_1f", "id": &"tide_cave_1f", "name": "Grotte de la Marée", "region": "Irisia",
		"seed": 7103, "light": &"sea_cave", "kinds": "cave"},
	{"plan": "tide_cave_b1f", "id": &"tide_cave_b1f", "name": "Grotte de la Marée", "region": "Irisia",
		"seed": 7104, "light": &"sea_cave", "kinds": "cave"},
]

## Caractère d'une grille → type de tuile (nom de [enum OverworldTiles.Kind]). Aucune eau surfable
## dans l'arc (A-6) : `w`, `d`, `X` sont de l'eau bloquée à pied, sans `surf_cells`.
const KINDS: Dictionary = {
	"deck": {"X": "WATER", ".": "BOARDWALK", "M": "CLIFF"},
	"island": {"w": "WATER", "R": "CLIFF", ".": "GRASS", "p": "COBBLE", "g": "SAND", "q": "BOARDWALK",
		"h": "TALL_GRASS", "G": "FOREST", "C": "CLIFF", "m": "CLIFF", "N": "CLIFF", "D": "COBBLE",
		"E": "DIRT"},
	"cave": {"#": "CLIFF", ".": "DIRT", "g": "RUBBLE", "d": "WATER", "R": "CLIFF", "E": "DIRT",
		"U": "DIRT", "V": "DIRT", "S": "CLIFF", "a": "RUBBLE", "b": "RUBBLE"},
}

## Passages : (carte, position) → carte cible, arrivée, déclenchement (défaut : bord = PUSH, sinon
## STEP_ON ↑), direction du pas, orientation à l'arrivée.
const WARPS: Dictionary = {
	"cianwood_city/porte_centre": {"to": &"cianwood_center", "spawn": "entrance"},
	"cianwood_city/porte_goulven": {"to": &"cianwood_goulven_house", "spawn": "entrance"},
	"cianwood_city/porte_maison": {"to": &"cianwood_house_1", "spawn": "entrance"},
	"cianwood_city/entree_grotte": {"to": &"tide_cave_1f", "spawn": "from_city", "trigger": STEP_ON,
		"dir": Vector2i.LEFT, "facing": Vector2i.LEFT},
	"tide_cave_1f/sortie": {"to": &"cianwood_city", "spawn": "retour_grotte", "trigger": PUSH,
		"dir": Vector2i.RIGHT, "facing": Vector2i.RIGHT},
	"tide_cave_1f/echelle_bas": {"to": &"tide_cave_b1f", "spawn": "from_1f", "trigger": STEP_ON,
		"dir": Vector2i.ZERO, "facing": Vector2i.DOWN},
	"tide_cave_b1f/echelle_haut": {"to": &"tide_cave_1f", "spawn": "from_b1f", "trigger": STEP_ON,
		"dir": Vector2i.ZERO, "facing": Vector2i.UP},
}
## Déclencheurs de la grille : (carte, position) → scène, sens du pas (ZERO = toutes directions).
const TRIGGERS: Dictionary = {
	"cianwood_city/arrivee_titre": {"scene": &"cianwood_arrival", "dir": Vector2i.ZERO},
	"tide_cave_b1f/scene_socle": {"scene": &"tide_cave_socle", "dir": Vector2i.LEFT},
}
## Orientation exigée des examens (défaut : ↑ ; ZERO = toutes).
const EXAM_FACINGS: Dictionary = {
	"cianwood_city/bateau_noir": Vector2i.DOWN,
	"tide_cave_1f/pompe_1": Vector2i.ZERO,
	"tide_cave_1f/pompe_2": Vector2i.ZERO,
	"tide_cave_b1f/socle": Vector2i.ZERO,
}
## Gués : (carte, caractère de la grille) → drapeau qui les découvre (eau tant qu'il manque).
const FORDS: Dictionary = {
	"tide_cave_b1f": {"a": &"johto_tide_valve_1", "b": &"johto_tide_valves_done"},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte ; porte est d'une porte de
## deux cases), nœud].
const BUILDINGS: Dictionary = {
	"cianwood_city": [
		["bldg_centre_01", Vector2i(22, 13), "Centre"],
		["bldg_maison_argenta_01", Vector2i(10, 13), "MaisonGoulven"],
		["bldg_maison_argenta_01", Vector2i(21, 21), "Maison1"],
	],
}
## Aplats provisoires [D] : (carte) → [nœud, rectangle de cases, couleur, toit].
const FLATS: Dictionary = {
	"goeland_deck": [["Cabine", Rect2i(11, 2, 3, 1), Color(0.46, 0.3, 0.2), true]],
	"tide_cave_1f": [
		["Pompe1", Rect2i(6, 6, 2, 2), Color(0.2, 0.2, 0.24), false],
		["Pompe2", Rect2i(10, 6, 2, 2), Color(0.2, 0.2, 0.24), false],
	],
	"tide_cave_b1f": [["Socle", Rect2i(4, 11, 2, 1), Color(0.5, 0.5, 0.54), false]],
}
## Bateaux peints (proue noire à gauche, proue du Goéland à droite) : (carte) → [nœud, image, pied
## gauche en cases, échelle, largeur montée en pixels depuis la poupe (0 = le navire entier), drapeau
## qui le retire]. Le bateau noir est au large d'Irisia, sa cabine au-dessus de la mer ; à l'ouverture
## du B1F (2 cases), seule sa poupe se voit, réduite, et la scène du socle l'anime
## (`Decor/BateauNoir`). Le Goéland, amarré à l'est du quai, sort de l'écran (bord de la carte).
const BLACK_BOAT: String = "res://assets/world/props/prop_bateau_noir_01.png"
const GOELAND: String = "res://assets/world/props/prop_goeland_01.png"
const BOAT_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const TIDE_LOST: StringName = &"johto_stone_tide_lost"
const BOATS: Dictionary = {
	"cianwood_city": [
		["BateauNoir", BLACK_BOAT, Vector2(23.6, 28.2), 1.0, 0, TIDE_LOST],
		["Goeland", GOELAND, Vector2(31.0, 16.2), 1.0, 0, &""],
	],
	"tide_cave_b1f": [["BateauNoir", BLACK_BOAT, Vector2(0.0, 13.0), 0.667, 288, TIDE_LOST]],
}
## Lampes de nuit [D] : (carte) → cases (centre du halo au milieu de la case).
const NIGHT_GLOWS: Dictionary = {
	"cianwood_city": [Vector2i(17, 13), Vector2i(25, 13), Vector2i(9, 13), Vector2i(12, 13),
		Vector2i(26, 16), Vector2i(20, 21), Vector2i(23, 21)],
}
## Eau pêchable : (carte) → caractère d'eau, caractères de rive (eau voisine d'une rive).
const FISHING: Dictionary = {"cianwood_city": ["w", "gq"]}

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
	print("build_johp2_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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
	_spawns[spec["id"]] = spawns


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var kinds: Dictionary = KINDS[spec["kinds"]]
	var root := _new_map(spec, size)
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
					and not _over.is_water_kind(kind):
				blocked.append(cell)
	_add_positions(spec, plan, root, blocked)
	_add_fishing(spec, plan, root)
	_add_buildings(spec, root)
	_add_flats(spec, root)
	_add_fords(spec, plan, root)
	_add_boats(spec, root)
	_add_night_glows(spec, root)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


func _add_positions(spec: Dictionary, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var map_id: StringName = spec["id"]
	var size: Vector2i = root.get(&"size")
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
				_add_prop(root, SIGN_PROP, cells[0], _node_name(id) + "Sign")
			"examen":
				_add_exam(root, id, cells, EXAM_FACINGS.get(key, Vector2i.UP),
					StringName("%s_%s" % [map_id, id]), if_flags, unless,
					attrs.get("drapeau", ""))
			"declencheur":
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])


## Examen : un point par rangée de cases. Vanne : l'examen disparaît avec son drapeau (une seule
## fois) ; [param own_flag] s'ajoute alors à ses conditions « sauf ».
func _add_exam(root: Node2D, id: String, cells: Array[Vector2i], facing: Vector2i,
		dialogue: StringName, if_flags: Array[StringName], unless: Array[StringName],
		own_flag: String) -> void:
	var conditions: Array[StringName] = unless.duplicate()
	if not own_flag.is_empty():
		conditions.append(StringName(own_flag))
	var rows: Dictionary = {}
	for cell: Vector2i in cells:
		if not rows.has(cell.y):
			rows[cell.y] = []
		(rows[cell.y] as Array).append(cell)
	var index := 0
	for y: int in rows:
		var row: Array = rows[y]
		var name := _node_name(id) if index == 0 else "%s%d" % [_node_name(id), index]
		_interact(root, name, row[0], Vector2i(row.size(), 1), facing, dialogue, if_flags, conditions)
		index += 1


func _flags(text: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for flag: String in text.split(",", false):
		out.append(StringName(flag))
	return out


## Passage : un warp par case, chacun vers l'arrivée de même rang de la carte cible si elle en a
## autant, sinon vers la première. Bord = PUSH vers l'extérieur ; porte = STEP_ON ↑ ; échelle =
## STEP_ON toutes directions.
func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary,
		size: Vector2i, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var on_edge := _on_edge(cells[0], size)
	var trigger: int = dest.get("trigger", PUSH if on_edge else STEP_ON)
	var direction: Vector2i = dest.get("dir", Vector2i.UP)
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	var facing: Vector2i = dest.get("facing", direction)
	for i: int in cells.size():
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, "%s_%d" % [_node_name(id), i], cells[i], trigger, direction, target,
			StringName(arrival), facing, if_flags, unless)


func _on_edge(cell: Vector2i, size: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == size.x - 1 or cell.y == size.y - 1


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
	root.set(&"light_profile", spec["light"])
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
		target: StringName, spawn: StringName, facing: Vector2i,
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
	point.set(&"coming_soon", "")
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


## Aplats provisoires (corps sombre, toit plus clair) sur l'emprise bloquée de la grille [D] ;
## l'art du lot suivant les remplace.
func _add_flats(spec: Dictionary, root: Node) -> void:
	for entry: Array in FLATS.get(String(spec["id"]), []):
		var rect: Rect2i = entry[1]
		var color: Color = entry[2]
		var top_left := Vector2(rect.position) * TILE
		var size := Vector2(rect.size) * TILE
		var body := _polygon(entry[0], top_left, size, color)
		_attach(root, root.get_node(^"Decor"), body)
		if entry[3]:
			var roof := Polygon2D.new()
			roof.name = String(entry[0]) + "Toit"
			roof.polygon = PackedVector2Array([
				top_left + Vector2(-TILE * 0.2, size.y * 0.3), top_left + Vector2(size.x * 0.5, 0),
				top_left + Vector2(size.x + TILE * 0.2, size.y * 0.3)])
			roof.color = color.lightened(0.3)
			_attach(root, root.get_node(^"Decor"), roof)


func _polygon(node_name: String, top_left: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var body := Polygon2D.new()
	body.name = node_name
	body.polygon = PackedVector2Array([top_left, top_left + Vector2(size.x, 0), top_left + size,
		top_left + Vector2(0, size.y)])
	body.color = color
	return body


## Gués du B1F : une [FlagGate] par gué, de l'eau peinte en aplat qui bloque ses cases tant que le
## drapeau de sa vanne manque (§8.2). Sous `Entities` (seules les portes de `_PROP_LAYERS` bloquent
## à la construction de la grille) ; [method GameMap.apply_flag_gates] la règle à l'arrivée, Boot à
## chaque drapeau changé.
func _add_fords(spec: Dictionary, plan: Object, root: Node) -> void:
	var fords: Dictionary = FORDS.get(String(spec["id"]), {})
	for mark: String in fords:
		var flag: StringName = fords[mark]
		var cells: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				if plan.at(Vector2i(x, y)) == mark:
					cells.append(Vector2i(x, y))
		var gate := _gate(root, root.get_node(^"Entities"), "Gue" + mark.to_upper(), [], [flag])
		gate.set(&"blocking_cells", cells)
		for cell: Vector2i in cells:
			var water := _polygon("Eau%d_%d" % [cell.x, cell.y], Vector2(cell) * TILE,
				Vector2.ONE * TILE, Color(0.18, 0.4, 0.55))
			_attach(root, gate, water)


## Bateaux peints, [FlagGate] sous `Decor` : visuels seulement (leurs cases sont de l'eau bloquée).
## Le nœud porte le nom que la scène du socle anime.
func _add_boats(spec: Dictionary, root: Node) -> void:
	for entry: Array in BOATS.get(String(spec["id"]), []):
		var texture := load(entry[1]) as Texture2D
		if texture == null:
			_fail("image absente : %s (lancer --import)" % entry[1])
			continue
		var unless: Array[StringName] = []
		if not (entry[5] as StringName).is_empty():
			unless.append(entry[5])
		var gate := _gate(root, root.get_node(^"Decor"), entry[0], [], unless)
		var sprite := Sprite2D.new()
		sprite.name = "Coque"
		sprite.texture = texture
		sprite.material = load(BOAT_MATERIAL)
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var size := texture.get_size()
		var stern: int = entry[4]
		if stern > 0:
			sprite.region_enabled = true
			sprite.region_rect = Rect2(size.x - stern, 0, stern, size.y)
		var scale: float = entry[3]
		sprite.scale = Vector2.ONE * scale
		var foot: Vector2 = entry[2]
		sprite.position = foot * TILE - Vector2(0, size.y * scale)
		_attach(root, gate, sprite)


func _gate(root: Node, parent: Node, node_name: String, if_flags: Array[StringName],
		unless: Array[StringName]) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = node_name
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless)
	var none: Array[Vector2i] = []
	gate.set(&"blocking_cells", none)
	_attach(root, parent, gate)
	return gate


## Eau pêchable : chaque case d'eau voisine d'une rive (quai, plage) de la grille.
func _add_fishing(spec: Dictionary, plan: Object, root: Node) -> void:
	if not FISHING.has(String(spec["id"])):
		return
	var water: String = FISHING[String(spec["id"])][0]
	var shores: String = FISHING[String(spec["id"])][1]
	var cells: Array[Vector2i] = []
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if plan.at(cell) != water:
				continue
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var near := cell + step
				if near.x >= 0 and near.y >= 0 and near.x < plan.width and near.y < plan.height \
						and shores.contains(plan.at(near)):
					cells.append(cell)
					break
	root.set(&"fishable_cells", cells)


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
	push_error("build_johp2_maps : " + message)
	_errors += 1
