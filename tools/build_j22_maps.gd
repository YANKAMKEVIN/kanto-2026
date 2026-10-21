extends SceneTree
## Construit les cartes du jalon 22 d'après leurs grilles fonctionnelles (`tools/plans/*.txt`, la
## grille fait foi ; `docs/tech/jalon-22.md` §2.11), en **tuiles provisoires** (`OverworldTiles`,
## `InteriorTiles`, stratégie d'accélération : le code ne bloque jamais sur l'art ; vues peintes
## validées pour le lot d'art suivant) :
##   route_12_south, route_13, route_14, route_15, route_15_gate (+ 2F), route_16_west,
##   route_16_gate, route_17, route_18, route_18_gate, fuchsia_city.
##
##   godot --headless --path . -s res://tools/build_j22_maps.gd [-- --maps=route_13,route_14]
##   godot --headless --path . --import
##
## Données lues ailleurs (générées par `tools/gen_j22_data.py`) : PNJ, Dresseurs et objets
## visibles (`data/npcs/<carte>.json`), textes (`data/dialogues/j22_<carte>.json`), objets
## (`data/cutscenes/j22_<carte>.json`). Ici : sol, cases bloquées, eau pêchable, Piste et pente,
## passages (bord = PUSH vers l'extérieur ; porte = STEP_ON ; « coming_soon » = « À venir »),
## arrivées (une par case, `<nom>`, `<nom>_1`…), panneaux et objets cachés (`InteractPoint`),
## Pokémon du décor sans planche (examen), déclencheurs des gardes de la Piste.
## Une destination dont la scène n'existe pas encore (Route 12 et Route 16 du J21) devient
## « À venir » ; relancer l'outil quand elle existe.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1

## Cartes : grille, identifiant, nom, région, intérieur, Piste (« all », « cells », « »), colonne
## de départ et largeur (le poste 15 a ses deux étages côte à côte dans une grille).
const MAPS: Array[Dictionary] = [
	{"plan": "route_12_sud", "id": &"route_12_south", "name": "Route 12",
		"region": "Lavanville — Parmanie", "seed": 2201},
	{"plan": "route_13", "id": &"route_13", "name": "Route 13", "region": "Route 12 — Route 14",
		"seed": 2202},
	{"plan": "route_14", "id": &"route_14", "name": "Route 14", "region": "Route 13 — Route 15",
		"seed": 2203},
	{"plan": "route_15", "id": &"route_15", "name": "Route 15", "region": "Route 14 — Parmanie",
		"seed": 2204},
	{"plan": "route_15_gate", "id": &"route_15_gate", "name": "Route 15",
		"region": "Route 15", "interior": true, "x0": 0, "width": 12, "seed": 2205},
	{"plan": "route_15_gate", "id": &"route_15_gate_2f", "name": "Route 15",
		"region": "Route 15", "interior": true, "x0": 13, "width": 12, "seed": 2206},
	{"plan": "route_16_west", "id": &"route_16_west", "name": "Route 16",
		"region": "Céladopole — Piste Cyclable", "cycling": "cells", "seed": 2207},
	{"plan": "route_16_gate", "id": &"route_16_gate", "name": "Route 16",
		"region": "Route 16", "interior": true, "seed": 2208},
	{"plan": "route_17", "id": &"route_17", "name": "Route 17", "region": "Piste Cyclable",
		"cycling": "all", "seed": 2209},
	{"plan": "route_18", "id": &"route_18", "name": "Route 18", "region": "Piste Cyclable — Parmanie",
		"cycling": "cells", "seed": 2210},
	{"plan": "route_18_gate", "id": &"route_18_gate", "name": "Route 18",
		"region": "Route 18", "interior": true, "seed": 2211},
	{"plan": "parmanie", "id": &"fuchsia_city", "name": "Parmanie", "region": "Parmanie",
		"seed": 2212},
]

## Caractère d'une grille extérieure → type de tuile (nom de [enum OverworldTiles.Kind]).
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "q": "BOARDWALK", "y": "SAND", "D": "COBBLE",
	"k": "COBBLE", "s": "SAND", "w": "WATER", "~": "WATER", "f": "SHALLOW", "T": "FOREST",
	"x": "FOREST", " ": "FOREST", "R": "CLIFF", "P": "CLIFF", "m": "CLIFF", "C": "CLIFF",
	"O": "CLIFF", "F": "CLIFF", "Z": "CLIFF", "S": "CLIFF", "c": "CROP", "b": "CROP", "n": "CROP",
	"g": "DIRT",
}
## Caractères praticables d'aspect mais bloqués pour le joueur (sol d'enclos).
const OUTDOOR_BLOCKED: String = "g"
## Intérieurs : murs (tuile solide), sorties et escaliers (tapis), le reste au sol, bloqué si
## ce n'est pas praticable dans la grille (comptoirs, plantes, bibliothèques, jumelles).
const INTERIOR_WALLS: String = "KV"
const INTERIOR_MATS: String = "XU"

## Libellés « À venir » des destinations réservées (coming_soon de la grille).
const COMING_SOON_LABELS: Dictionary = {
	"route_12_sud": "Route 12", "route_16_fly_house": "Maison", "fuchsia_gym": "Arène de Parmanie",
	"safari_zone_gate": "Parc Safari", "wardens_house": "Maison du Gardien", "route_19": "Route 19",
}
## Libellés des cartes d'autres jalons pas encore construites.
const TARGET_LABELS: Dictionary = {&"route_12": "Route 12", &"route_16": "Route 16"}
const ARROWS: Dictionary = {"↑": Vector2i.UP, "↓": Vector2i.DOWN, "←": Vector2i.LEFT,
	"→": Vector2i.RIGHT}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}

var _over: GDScript
var _inside: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases (relues sur toutes les grilles avant de construire).
var _spawns: Dictionary = {}
var _built: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_inside = load("res://game/world/interior_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_built[spec["id"]] = true
		_collect_spawns(spec)
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	print("build_j22_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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


## Cases de [param cells] dans la carte (étage du poste 15), en coordonnées de la carte.
func _local(spec: Dictionary, cells: Array) -> Array[Vector2i]:
	var x0: int = spec.get("x0", 0)
	var width: int = spec.get("width", -1)
	var out: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if cell.x >= x0 and (width < 0 or cell.x < x0 + width):
			out.append(cell - Vector2i(x0, 0))
	return out


func _collect_spawns(spec: Dictionary) -> void:
	var plan := _plan(spec)
	var spawns: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			var cells := _local(spec, entry["cells"])
			if not cells.is_empty():
				spawns[id] = cells
	_spawns[spec["id"]] = spawns


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var interior: bool = spec.get("interior", false)
	var size := Vector2i(spec.get("width", plan.width), plan.height)
	var root := _new_map(spec, size, interior)
	var blocked: Array[Vector2i] = []
	var fishable: Array[Vector2i] = []
	var slopes: Array[Vector2i] = []
	var road: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	var x0: int = spec.get("x0", 0)
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell + Vector2i(x0, 0))
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
			match mark:
				"f":
					fishable.append(cell)
				"s":
					slopes.append(cell)
					road.append(cell)
				"k":
					road.append(cell)
	_add_positions(spec, plan, root, blocked)
	root.set(&"blocked_cells", blocked)
	root.set(&"fishable_cells", fishable)
	root.set(&"slope_cells", slopes)
	match spec.get("cycling", ""):
		"all":
			root.set(&"cycling_road", true)
		"cells":
			root.set(&"cycling_road_cells", road)
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
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells := _local(spec, entry["cells"])
		if cells.is_empty():
			continue
		var attrs: Dictionary = entry["attrs"]
		var comment: String = _comment(String(spec["plan"]), id)
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp":
				_add_warp(spec, root, id, cells, attrs, comment, size_of(root))
			"panneau":
				var facing := _arrow_after(comment, "depuis")
				_interact(root, _node_name(id), cells[0], facing,
					StringName("%s_%s" % [map_id, id]), [])
				if spec.get("interior", false):
					continue
				_add_sign(root, cells[0], _node_name(id))
			"pokemon":
				# Pokémon du décor (M-20) sans planche peinte : examen seulement [D].
				_interact(root, _node_name(id), cells[0], Vector2i.ZERO,
					StringName("%s_%s" % [map_id, id]), [])
				for cell: Vector2i in cells:
					blocked.append(cell)
			"cache":
				_interact(root, _node_name(id), cells[0], Vector2i.ZERO, StringName(id),
					[StringName(attrs.get("drapeau", ""))])
			"repere":
				if attrs.has("scene"):
					_trigger(root, _node_name(id), cells,
						FACINGS.get(attrs.get("sens", ""), Vector2i.ZERO),
						StringName(attrs["scene"]))


func size_of(root: Node2D) -> Vector2i:
	return root.get(&"size")


## Passage : un warp par case, chacun vers l'arrivée de même rang de la carte cible si elle en a
## autant (portes de 2 ou 3 cases), sinon vers la première.
func _add_warp(spec: Dictionary, root: Node2D, id: String, cells: Array[Vector2i],
		attrs: Dictionary, comment: String, size: Vector2i) -> void:
	var direction := _arrow_of_trigger(comment)
	var trigger := PUSH
	if comment.contains("STEP_ON"):
		trigger = STEP_ON
	elif not comment.contains("PUSH"):
		trigger = PUSH if _on_edge(cells[0], size) else STEP_ON
	if direction == Vector2i.ZERO:
		direction = _edge_direction(cells[0], size) if trigger == PUSH else Vector2i.UP
	if attrs.has("coming_soon"):
		var label: String = COMING_SOON_LABELS.get(attrs["coming_soon"], "À venir")
		for i: int in cells.size():
			_warp(root, "%s_%d" % [_node_name(id), i], cells[i], trigger, direction, &"",
				StringName(_back_spawn(spec, cells[i], direction)), -direction, label)
		return
	var target := StringName(attrs.get("to", ""))
	var spawn: String = attrs.get("spawn", "")
	var exists: bool = _built.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		if not exists:
			_warp(root, name, cells[i], trigger, direction, &"",
				StringName(_back_spawn(spec, cells[i], direction)), -direction,
				TARGET_LABELS.get(target, String(target)))
			continue
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival),
			_arrival_facing(target, spawn, direction), "")


## Arrivée « tournée » de la carte cible (attribut facing de sa grille), sinon la direction du
## passage.
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
func _back_spawn(spec: Dictionary, cell: Vector2i, _direction: Vector2i) -> String:
	var spawns: Dictionary = _spawns.get(spec["id"], {})
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


## Commentaire de la position (texte après « # » sur sa ligne de la grille).
func _comment(plan_name: String, id: String) -> String:
	var text := FileAccess.get_file_as_string(PLANS_DIR + plan_name + ".txt")
	for line: String in text.split("\n"):
		if line.begins_with(id + " ") and line.contains("#"):
			return line.substr(line.find("#") + 1)
	return ""


## Flèche du déclencheur : la première après « STEP_ON » / « PUSH ».
func _arrow_of_trigger(comment: String) -> Vector2i:
	for key: String in ["STEP_ON", "PUSH"]:
		var at := comment.find(key)
		if at >= 0:
			return _first_arrow(comment.substr(at))
	return Vector2i.ZERO


func _arrow_after(comment: String, word: String) -> Vector2i:
	var at := comment.find(word)
	return _first_arrow(comment.substr(at)) if at >= 0 else Vector2i.ZERO


func _first_arrow(text: String) -> Vector2i:
	var best := -1
	var result := Vector2i.ZERO
	for arrow: String in ARROWS:
		var at := text.find(arrow)
		if at >= 0 and (best < 0 or at < best):
			best = at
			result = ARROWS[arrow]
	return result


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
		target: StringName, spawn: StringName, facing: Vector2i, coming_soon: String) -> void:
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
	point.position = _world(top_left)
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
	push_error("build_j22_maps : " + message)
	_errors += 1
