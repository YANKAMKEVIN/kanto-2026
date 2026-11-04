extends SceneTree
## Construit les trois cartes extérieures du jalon JOH2 (Chapitre Johto, `docs/tech/jalon-joh2.md`
## §2.1 à §2.2) d'après leurs grilles fonctionnelles (`tools/plans/route_39.txt`, `route_38.txt`,
## `rosalia.txt` : **la grille fait foi**), en **tuiles provisoires** (`OverworldTiles`, modèle du
## J22 : le code ne bloque jamais sur l'art ; vues peintes validées pour le lot d'art suivant) :
##   route_39, route_38, ecruteak_city (Rosalia).
##
##   godot --headless --path . -s res://tools/build_joh2_maps.gd [-- --maps=route_39,route_38]
##   godot --headless --path . --import
##
## Données lues ailleurs (`tools/gen_joh2_data.py`) : PNJ, Dresseurs et objets visibles
## (`data/npcs/<carte>.json`), textes (`data/dialogues/joh2_*.json`), scènes
## (`data/cutscenes/joh2_*.json`). Ici : sol et cases bloquées, passages (bord = PUSH, porte =
## STEP_ON ; destination absente = « À venir »), arrivées (une par case, `<nom>`, `<nom>_1`…),
## panneaux, examens, Pokémon du décor (examen), caches, déclencheurs des scènes, bâtiments du kit
## peint de Kanto posés sur leur emprise [D], tours en aplats provisoires [D], lampes de nuit
## (groupe `night_lights`, allumées la nuit seulement par `WorldLighting.set_night`).
## Relancer `--maps=route_39` quand `olivine_city.tscn` (JOH1) existe : le raccord ouest cesse
## d'être « À venir ».

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

## Cartes : grille, identifiant, nom, sous-titre (champ « region » de la carte), graine.
const MAPS: Array[Dictionary] = [
	{"plan": "route_39", "id": &"route_39", "name": "Route 39", "region": "Oliville — Rosalia",
		"seed": 3901},
	{"plan": "route_38", "id": &"route_38", "name": "Route 38", "region": "Rosalia — Route 39",
		"seed": 3801},
	{"plan": "rosalia", "id": &"ecruteak_city", "name": "Rosalia", "region": "Johto",
		"seed": 4201},
]

## Caractère d'une grille → type de tuile (nom de [enum OverworldTiles.Kind]). Les cases non
## praticables de la grille dont la tuile ne l'est pas (fleurs, pré d'enclos, banc, porte) sont
## bloquées par `blocked_cells`.
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "p": "COBBLE", "D": "COBBLE", "T": "FOREST",
	"x": "FOREST", "G": "FOREST", "R": "CLIFF", "W": "WATER", "f": "CLIFF", "e": "CROP",
	"y": "FLOWERS", "n": "CROP", "M": "CLIFF", "B": "CLIFF", "K": "CLIFF", "S": "CLIFF",
	"C": "CLIFF", "O": "CLIFF", "m": "CLIFF", "N": "CLIFF",
}

## Passages : (carte, position) → carte cible, arrivée, libellé « À venir » si la cible manque.
const WARPS: Dictionary = {
	"route_39/warp_ouest": {"to": &"olivine_city", "spawn": "from_route_39", "label": "Oliville"},
	"route_39/warp_est": {"to": &"route_38", "spawn": "from_route_39"},
	"route_38/warp_ouest": {"to": &"route_39", "spawn": "from_route_38"},
	"route_38/warp_est": {"to": &"ecruteak_city", "spawn": "from_route_38"},
	"ecruteak_city/warp_ouest": {"to": &"route_38", "spawn": "from_ecruteak"},
	"ecruteak_city/warp_sud": {"to": &"route_37", "spawn": "from_ecruteak", "label": "Route 37"},
	"ecruteak_city/warp_est": {"to": &"route_42", "spawn": "from_ecruteak", "label": "Route 42"},
	"ecruteak_city/warp_bois": {"to": &"bell_tower_woods", "spawn": "from_ecruteak",
		"label": "Bois de la Tour"},
	"ecruteak_city/porte_centre": {"to": &"ecruteak_center", "spawn": "entrance"},
	"ecruteak_city/porte_boutique": {"to": &"ecruteak_mart", "spawn": "entrance"},
	"ecruteak_city/porte_sages": {"to": &"ecruteak_elders_house", "spawn": "entrance"},
	"ecruteak_city/porte_maison_1": {"to": &"ecruteak_house_1", "spawn": "entrance"},
	"ecruteak_city/porte_maison_2": {"to": &"ecruteak_house_2", "spawn": "entrance"},
	# JOH6 : l'entrée de la Tour Cendrée, gardée par son drapeau (jamais ouverte à l'acte 1) [D].
	"ecruteak_city/entree_tour_cendree": {"to": &"burned_tower_1f", "spawn": "from_city",
		"label": "Tour Cendrée"},
}
## Déclencheurs : (carte, position) → scène, sens du pas (vide = toutes directions).
const TRIGGERS: Dictionary = {
	"ecruteak_city/scene_sbires": {"scene": &"ecruteak_rockets", "dir": Vector2i.ZERO},
	"ecruteak_city/barriere_carillon": {"scene": &"ecruteak_bell_tower_guard", "dir": Vector2i.UP},
	"ecruteak_city/barriere_route_42": {"scene": &"ecruteak_route_42_guard", "dir": Vector2i.RIGHT},
	# JOH6 : le doyen à la sortie de la Tour Cendrée (C-10, C-11).
	"ecruteak_city/scene_doyen_plan": {"scene": &"ecruteak_dante_plan", "dir": Vector2i.ZERO},
}
## Arrivées supplémentaires (alias) : (carte) → nom → case.
const EXTRA_SPAWNS: Dictionary = {
	# Point de Vol « Rosalia » (`fly_points.json` : `from_center`) = devant le Centre.
	"ecruteak_city": {"from_center": Vector2i(8, 30)},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte ; milieu pour une porte
## d'une case), nœud].
const BUILDINGS: Dictionary = {
	"route_39": [["bldg_maison_pecheur_01", Vector2i(16, 29), "FermeMeumeu"]],
	"ecruteak_city": [
		["bldg_centre_01", Vector2i(9, 29), "Centre"],
		["bldg_boutique_01", Vector2i(19, 29), "Boutique"],
		["bldg_maison_argenta_01", Vector2i(21, 12), "MaisonSages"],
		["bldg_maison_argenta_01", Vector2i(35, 29), "Maison1"],
		["bldg_maison_argenta_01", Vector2i(47, 29), "Maison2"],
	],
}
## Tours en aplats provisoires [D] : (carte) → [nœud, rectangle de cases, couleur].
const TOWERS: Dictionary = {
	"ecruteak_city": [
		["TourCendree", Rect2i(4, 2, 10, 11), Color(0.16, 0.13, 0.12)],
		["TourCarillon", Rect2i(46, 1, 8, 9), Color(0.42, 0.22, 0.14)],
	],
}
## Lampes de nuit [D] : (carte) → cases (centre du halo au milieu de la case).
const NIGHT_GLOWS: Dictionary = {
	"route_39": [Vector2i(14, 29), Vector2i(18, 29)],
	"ecruteak_city": [Vector2i(6, 28), Vector2i(11, 28), Vector2i(16, 28), Vector2i(21, 28),
		Vector2i(19, 11), Vector2i(33, 28), Vector2i(45, 28), Vector2i(6, 12), Vector2i(11, 12)],
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
	print("build_joh2_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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
			if not OUTDOOR_KINDS.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [spec["id"], mark, cell])
				continue
			var kind: int = _over.Kind[OUTDOOR_KINDS[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if not plan.walkable.contains(mark) and not _over.is_solid_kind(kind):
				blocked.append(cell)
	_add_positions(spec, plan, root, blocked)
	_add_buildings(spec, root)
	_add_towers(spec, root)
	_add_night_glows(spec, root)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


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
			"pokemon":
				# Pokémon du décor sans planche : examen seulement [D] ; un texte par espèce.
				var species := id.rstrip("0123456789").rstrip("_")
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO,
					StringName("%s_%s" % [map_id, species]), [], [])
				for cell: Vector2i in cells:
					blocked.append(cell)
			"cache":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO,
					StringName(id), [], [StringName("got_" + id)])
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
	var direction := _edge_direction(cells[0], size) if on_edge else Vector2i.UP
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
	root.set(&"light_profile", LIGHT_PROFILE)
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
	push_error("build_joh2_maps : " + message)
	_errors += 1
