extends SceneTree
## Construit les cartes du jalon 23 d'après leurs grilles fonctionnelles (`tools/plans/*.txt`, la
## grille fait foi ; `docs/tech/jalon-23.md` §2.6, §2.11), en **tuiles provisoires**
## (`OverworldTiles`, `InteriorTiles` ; stratégie d'accélération : le code ne bloque jamais sur
## l'art). Modèle : `tools/build_j22_maps.gd`.
##   safari_zone_gate, safari_zone_center, safari_zone_east, safari_zone_north, safari_zone_west,
##   safari_zone_rest_house_{center,east,north,west} (une grille, quatre cartes : la sortie mène à
##   la zone d'origine), safari_zone_secret_house, wardens_house.
## L'Arène de Koga (`fuchsia_gym`) a son propre outil (`tools/build_fuchsia_gym.gd`).
##
##   godot --headless --path . -s res://tools/build_j23_maps.gd [-- --maps=safari_zone_east]
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_j22_maps.gd -- --maps=fuchsia_city
##     (Parmanie : ses portes du Parc, de l'Arène et du Gardien mènent ici depuis le J23)
##
## Données lues ailleurs (générées par `tools/gen_j23_data.py`) : PNJ et objets visibles
## (`data/npcs/<carte>.json`), textes (`data/dialogues/j23_<carte>.json`), objets et scènes
## (`data/cutscenes/j23_<carte>.json`). Ici : sol, cases bloquées, passages (raccords de bord =
## PUSH ; portes = STEP_ON ; sorties des intérieurs = PUSH ↓), arrivées (une par case, `<nom>`,
## `<nom>_1`…), panneaux et objets cachés (`InteractPoint`), déclencheur du comptoir de la Porte,
## rocher fixe du Gardien (case bloquée + examen, texte 46).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1

const REGION: String = "Parc Safari"

## Cartes : grille, identifiant, nom affiché, région, intérieur, graine ; « zone » : zone d'origine
## d'une maison de repos (sa sortie y ramène).
const MAPS: Array[Dictionary] = [
	{"plan": "safari_porte", "id": &"safari_zone_gate", "name": "Parc Safari",
		"region": "Parmanie", "interior": true, "seed": 2301},
	{"plan": "safari_centre", "id": &"safari_zone_center", "name": "Parc Safari — Zone Centre",
		"region": REGION, "seed": 2302},
	{"plan": "safari_est", "id": &"safari_zone_east", "name": "Parc Safari — Zone Est",
		"region": REGION, "seed": 2303},
	{"plan": "safari_nord", "id": &"safari_zone_north", "name": "Parc Safari — Zone Nord",
		"region": REGION, "seed": 2304},
	{"plan": "safari_ouest", "id": &"safari_zone_west", "name": "Parc Safari — Zone Ouest",
		"region": REGION, "seed": 2305},
	{"plan": "safari_maison_repos", "id": &"safari_zone_rest_house_center",
		"name": "Maison de repos", "region": REGION, "interior": true, "zone": "centre",
		"seed": 2306},
	{"plan": "safari_maison_repos", "id": &"safari_zone_rest_house_east",
		"name": "Maison de repos", "region": REGION, "interior": true, "zone": "est",
		"seed": 2307},
	{"plan": "safari_maison_repos", "id": &"safari_zone_rest_house_north",
		"name": "Maison de repos", "region": REGION, "interior": true, "zone": "nord",
		"seed": 2308},
	{"plan": "safari_maison_repos", "id": &"safari_zone_rest_house_west",
		"name": "Maison de repos", "region": REGION, "interior": true, "zone": "ouest",
		"seed": 2309},
	{"plan": "safari_maison_secrete", "id": &"safari_zone_secret_house",
		"name": "Maison Secrète", "region": REGION, "interior": true, "seed": 2310},
	{"plan": "parmanie_maison_gardien", "id": &"wardens_house", "name": "Parmanie",
		"region": "Parmanie", "interior": true, "seed": 2311},
]

## Grille d'une zone → carte.
const ZONE_MAPS: Dictionary = {
	"safari_centre": &"safari_zone_center", "safari_est": &"safari_zone_east",
	"safari_nord": &"safari_zone_north", "safari_ouest": &"safari_zone_west",
	"safari_porte": &"safari_zone_gate",
}
## Nom court d'une grille (suffixe des arrivées : « arrivee_<nom> »).
const SHORT: Dictionary = {
	"safari_centre": "centre", "safari_est": "est", "safari_nord": "nord",
	"safari_ouest": "ouest", "safari_porte": "porte",
}
const REST_HOUSES: Dictionary = {
	"centre": &"safari_zone_rest_house_center", "est": &"safari_zone_rest_house_east",
	"nord": &"safari_zone_rest_house_north", "ouest": &"safari_zone_rest_house_west",
}

## Caractère d'une grille extérieure → type de tuile (nom de [enum OverworldTiles.Kind]).
const OUTDOOR_KINDS: Dictionary = {
	"T": "FOREST", "n": "FOREST", ".": "GRASS", "h": "TALL_GRASS", "W": "WATER", "B": "CLIFF",
	"D": "DIRT", "P": "GRASS", "e": "DIRT",
}
## Caractères praticables d'aspect mais bloqués (le panneau peint bloque aussi sa case).
const OUTDOOR_BLOCKED: String = "P"
## Intérieurs : murs, sorties et passages (tapis), le reste au sol, bloqué s'il n'est pas
## praticable dans la grille (comptoirs, vitrines, étagères, tables, lits, niche).
const INTERIOR_WALLS: String = "K"
const INTERIOR_MATS: String = "XN"
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}

var _over: GDScript
var _inside: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases.
var _spawns: Dictionary = {}
## Carte → arrivée → orientation.
var _facings: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_inside = load("res://game/world/interior_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_collect_spawns(spec)
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	print("build_j23_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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
	var facings: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			spawns[id] = entry["cells"]
			facings[id] = FACINGS.get((entry["attrs"] as Dictionary).get("facing", ""),
				Vector2i.DOWN)
	_spawns[spec["id"]] = spawns
	_facings[spec["id"]] = facings


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var interior: bool = spec.get("interior", false)
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec, size, interior)
	var blocked: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if interior:
				_paint_interior(ground, cell, mark, plan.walkable, blocked)
				continue
			if not OUTDOOR_KINDS.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [spec["id"], mark, cell])
				continue
			var kind: int = _over.Kind[OUTDOOR_KINDS[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if OUTDOOR_BLOCKED.contains(mark):
				blocked.append(cell)
	_add_positions(spec, plan, root, blocked)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


func _paint_interior(ground: TileMapLayer, cell: Vector2i, mark: String, walkable: String,
		blocked: Array[Vector2i]) -> void:
	var kind: int = _inside.Kind.FLOOR_WOOD
	if INTERIOR_WALLS.contains(mark):
		kind = _inside.Kind.WALL_HOUSE
	elif INTERIOR_MATS.contains(mark):
		kind = _inside.Kind.MAT
	elif not walkable.contains(mark):
		kind = _inside.Kind.RUG
		blocked.append(cell)
	var variant := _rng.randi_range(0, _inside.VARIANTS[kind] - 1)
	ground.set_cell(cell, _inside.SOURCE_ID, _inside.atlas_coords(kind, variant))


func _add_positions(spec: Dictionary, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var map_id: StringName = spec["id"]
	var size: Vector2i = root.get(&"size")
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		var attrs: Dictionary = entry["attrs"]
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp", "raccord", "porte":
				var link := _link(spec, id, attrs)
				if link.is_empty():
					_fail("%s : passage « %s » sans destination" % [map_id, id])
					continue
				var trigger := STEP_ON
				var direction := Vector2i.UP
				if entry["kind"] == "porte":
					direction = Vector2i.UP
				elif _on_edge(cells[0], size):
					trigger = PUSH
					direction = _edge_direction(cells[0], size)
				elif plan.at(cells[0]) == "X":
					# Sortie d'un intérieur : paillasson sur l'avant-dernière rangée, PUSH ↓.
					trigger = PUSH
					direction = Vector2i.DOWN
				_add_warp(root, id, cells, trigger, direction, link["map"], link["spawn"])
			"panneau":
				# Un examen par case (vitrine du Gardien : deux moitiés, A-13 et A-14).
				for i: int in cells.size():
					var suffix := "" if i == 0 else "_%d" % i
					_interact(root, _node_name(id) + suffix, cells[i], Vector2i.ZERO,
						StringName("%s_%s%s" % [map_id, id, suffix]), [])
				if not spec.get("interior", false):
					_add_sign(root, cells[0], _node_name(id))
			"objet_cache":
				_interact(root, _node_name(id), cells[0], Vector2i.ZERO,
					StringName("%s_%s" % [map_id, id]), [StringName(_item_flag(map_id, id))])
			"rocher":
				# Rocher fixe du Gardien (§2.11) : case bloquée, examen (texte 46). Le J24 le rend
				# poussable (dossier 27 §6.5).
				for cell: Vector2i in cells:
					blocked.append(cell)
				_interact(root, _node_name(id), cells[0], Vector2i.ZERO,
					StringName("%s_%s" % [map_id, id]), [])
				# Même image que les rochers de Force (passe systèmes 2, J24) : dessin seul.
				var rock := Node2D.new()
				rock.set_script(load("res://game/world/boulders/boulder.gd"))
				rock.name = _node_name(id) + "Image"
				rock.position = _world(cells[0])
				_attach(root, root.get_node(^"Entities"), rock)
			"declencheur":
				# Comptoir de la Porte : deux déclencheurs, un par sens du pas (§2.1, §2.2).
				_trigger(root, "CounterNorthbound", cells, Vector2i.UP,
					&"j23_safari_gate_enter")
				_trigger(root, "CounterSouthbound", cells, Vector2i.DOWN,
					&"j23_safari_gate_leave")


## Drapeau de ramassage d'un objet de la carte (même règle que `tools/gen_j23_data.py`).
static func _item_flag(map_id: StringName, id: String) -> String:
	return "got_%s_%s" % [map_id, id]


## Destination d'un passage : { map, spawn } (vide si inconnue).
func _link(spec: Dictionary, id: String, attrs: Dictionary) -> Dictionary:
	var plan_name: String = spec["plan"]
	var target: String = String(attrs.get("vers", "")).get_slice(":", 0)
	match plan_name:
		"safari_maison_repos":
			return {"map": ZONE_MAPS["safari_" + String(spec["zone"])],
				"spawn": "arrivee_maison_repos"}
		"safari_maison_secrete":
			return {"map": &"safari_zone_west", "spawn": "arrivee_maison_secrete"}
		"parmanie_maison_gardien":
			return {"map": &"fuchsia_city", "spawn": "from_wardens_house"}
	if plan_name == "safari_porte" and id == "sortie":
		return {"map": &"fuchsia_city", "spawn": "from_safari"}
	if target == "safari_maison_repos":
		return {"map": REST_HOUSES[SHORT[plan_name]], "spawn": "entree"}
	if target == "safari_maison_secrete":
		return {"map": &"safari_zone_secret_house", "spawn": "entree"}
	if not ZONE_MAPS.has(target):
		return {}
	if plan_name == "safari_centre" and target == "safari_porte":
		return {"map": ZONE_MAPS[target], "spawn": "arrivee_parc"}
	# Raccord « raccord_<cible>[_n] » → arrivée « arrivee_<source>[_n] » de la cible.
	var suffix := ""
	var parts := id.split("_")
	if parts.size() >= 3 and parts[-1].is_valid_int():
		suffix = "_" + parts[-1]
	return {"map": ZONE_MAPS[target], "spawn": "arrivee_%s%s" % [SHORT[plan_name], suffix]}


## Un warp par case, chacun vers l'arrivée de même rang de la cible si elle en a autant.
func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], trigger: int,
		direction: Vector2i, target: StringName, spawn: String) -> void:
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	var facing: Vector2i = (_facings.get(target, {}) as Dictionary).get(spawn, direction)
	if target == &"fuchsia_city":
		facing = Vector2i.DOWN
	for i: int in cells.size():
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, "%s_%d" % [_node_name(id), i], cells[i], trigger, direction, target,
			StringName(arrival), facing)


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

func _new_map(spec: Dictionary, size: Vector2i, interior: bool) -> Node2D:
	var root := Node2D.new()
	root.name = String(spec["id"]).to_pascal_case()
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", spec["id"])
	root.set(&"display_name", spec["name"])
	root.set(&"region", spec["region"])
	root.set(&"size", size)
	root.set(&"interior", interior)
	var tileset: TileSet = load(_inside.TILESET_PATH if interior else _over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
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
		target: StringName, spawn: StringName, facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, facing: Vector2i,
		dialogue: StringName, unless: Array) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	var flags: Array[StringName] = []
	for flag: Variant in unless:
		if not String(flag).is_empty():
			flags.append(StringName(flag))
	point.set(&"unless_flags", flags)
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
	var scene := load(PROPS_DIR + SIGN_PROP + ".tscn") as PackedScene
	if scene == null:
		_fail("panneau introuvable : %s" % SIGN_PROP)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name + "Sign"
	prop.position = _rules.call(&"foot_position", StringName(SIGN_PROP), cell)
	_attach(root, root.get_node(^"Entities"), prop)


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
	push_error("build_j23_maps : " + message)
	_errors += 1
