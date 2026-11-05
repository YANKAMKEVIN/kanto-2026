extends SceneTree
## Construit les trois cartes du jalon JOHP3 (arc des Pierres, `docs/tech/jalon-joh-pierres.md`
## §5.1) d'après leurs grilles fonctionnelles (`tools/plans/blackthorn_city.txt`,
## `dragons_den_1f.txt`, `dragons_den_sanctuary.txt` : **la grille fait foi**), en **tuiles
## provisoires** (`OverworldTiles`, modèle du JOH4 : le code ne bloque jamais sur l'art) :
##   blackthorn_city (Ébènelle), dragons_den_1f (Antre du Dragon), dragons_den_sanctuary
##   (Sanctuaire de l'Antre ; grottes : `data/world/caves.json`).
##
##   godot --headless --path . -s res://tools/build_johp3_maps.gd [-- --maps=blackthorn_city]
##   godot --headless --path . --import
##
## Construire d'abord les intérieurs (`build_painted_interiors.gd --blackthorn`) : les passages
## vers eux visent leur arrivée `entrance`.
##
## Données lues ailleurs (`tools/gen_johp3_data.py`) : PNJ, Dresseurs, objets visibles
## (`data/npcs/<carte>.json`), textes (`data/dialogues/johp3_*.json`), scènes
## (`data/cutscenes/johp3_*.json`). Ici : sol et cases bloquées, passages, arrivées, panneaux,
## examens, caches, déclencheurs, bâtiments du kit peint de Kanto [D], aplats provisoires (autel)
## [D], lampes de nuit d'Ébènelle (groupe `night_lights`). **Aucun nom d'autoload** dans ce fichier
## ni dans ce qu'il charge (mémoire « Outils sans autoload »).

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
## grotte (sol de grotte, sans ciel).
const MAPS: Array[Dictionary] = [
	{"plan": "blackthorn_city", "id": &"blackthorn_city", "name": "Ébènelle", "region": "Johto",
		"seed": 9301, "light": &"johto_auto", "cave": false},
	{"plan": "dragons_den_1f", "id": &"dragons_den_1f", "name": "Antre du Dragon",
		"region": "Ébènelle", "seed": 9302, "light": &"cave_1f", "cave": true},
	{"plan": "dragons_den_sanctuary", "id": &"dragons_den_sanctuary", "name": "Sanctuaire de l'Antre",
		"region": "Antre du Dragon", "seed": 9303, "light": &"cave_b1f", "cave": true},
]

## Caractère d'une grille → type de tuile (nom de [enum OverworldTiles.Kind]). Les cases non
## praticables de la grille dont la tuile ne l'est pas (emprises des bâtiments, bassins sans Surf)
## sont bloquées par `blocked_cells`.
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "h": "TALL_GRASS", "p": "COBBLE", "D": "COBBLE", "E": "DIRT", "T": "FOREST",
	"G": "FOREST", "R": "CLIFF", "S": "GRASS", "C": "GRASS", "m": "GRASS",
}
const CAVE_KINDS: Dictionary = {
	"#": "CLIFF", ".": "DIRT", "g": "RUBBLE", "d": "WATER", "o": "CLIFF", "E": "DIRT", "V": "DIRT",
	"S": "COBBLE", "U": "DIRT",
}
## Décor posé sur la couche Detail : aucun ici.
const DETAIL_KINDS: Dictionary = {}
## Eau surfable : aucune (A-6 : pas de Surf dans l'arc, les bassins sont un décor bloqué).
const SURF_CHARS: String = ""

## Passages : (carte, position) → carte cible, arrivée, libellé « À venir » si la cible manque,
## déclenchement (défaut : bord = PUSH, sinon STEP_ON ↑), direction du pas d'un STEP_ON.
const WARPS: Dictionary = {
	"blackthorn_city/porte_aieule": {"to": &"blackthorn_elder_house", "spawn": "entrance"},
	"blackthorn_city/porte_centre": {"to": &"blackthorn_center", "spawn": "entrance"},
	"blackthorn_city/porte_maison": {"to": &"blackthorn_house_1", "spawn": "entrance"},
	"blackthorn_city/entree_antre": {"to": &"dragons_den_1f", "spawn": "from_city", "trigger": STEP_ON,
		"dir": Vector2i.RIGHT, "facing": Vector2i.UP},
	"dragons_den_1f/sortie": {"to": &"blackthorn_city", "spawn": "retour_antre", "trigger": PUSH,
		"dir": Vector2i.DOWN, "facing": Vector2i.LEFT},
	"dragons_den_1f/escalier_bas": {"to": &"dragons_den_sanctuary", "spawn": "from_1f",
		"trigger": STEP_ON, "dir": Vector2i.ZERO, "facing": Vector2i.UP},
	"dragons_den_sanctuary/escalier_haut": {"to": &"dragons_den_1f", "spawn": "from_sanctuary",
		"trigger": STEP_ON, "dir": Vector2i.ZERO, "facing": Vector2i.DOWN},
}
## Déclencheurs de la grille : (carte, position) → scène, sens du pas (ZERO = toutes directions).
## Absent de la table : ignoré si dans [constant IGNORED_TRIGGERS].
const TRIGGERS: Dictionary = {
	"blackthorn_city/barriere_antre": {"scene": &"blackthorn_den_barrier", "dir": Vector2i.RIGHT},
	"dragons_den_1f/barriere_sanctuaire": {"scene": &"dragons_den_barrier", "dir": Vector2i.UP},
	"dragons_den_sanctuary/scene_ysolde": {"scene": &"dragons_den_ysolde", "dir": Vector2i.UP},
	"dragons_den_sanctuary/scene_autel": {"scene": &"dragons_den_altar", "dir": Vector2i.ZERO},
}
## Le titre d'Ébènelle vient de sa zone ; `scene_cenere` partage les cases de `scene_autel` (une
## seule scène à variantes, `dragons_den_altar`).
const IGNORED_TRIGGERS: Array[String] = ["blackthorn_city/arrivee_titre",
	"dragons_den_sanctuary/scene_cenere"]
## Déclencheurs hors grille [D] : (carte) → [nœud, cases, sens, scène].
const EXTRA_TRIGGERS: Dictionary = {}
## Positions dont la grille dit « examen » ou « pokemon » mais qui sont des PNJ de
## `data/npcs/` : aucune donnée ici.
const NPC_POSITIONS: Array[String] = ["blackthorn_city/dracolosse"]
## Arrivées supplémentaires : (carte) → nom → case.
const EXTRA_SPAWNS: Dictionary = {
	# Départ de débogage du Réveil (JOHP0) et des tests : devant l'autel, rangée 7 [D].
	"dragons_den_sanctuary": {"altar_front": Vector2i(10, 7)},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte ; porte est d'une porte
## de deux cases), nœud].
const BUILDINGS: Dictionary = {
	"blackthorn_city": [
		["bldg_centre_01", Vector2i(24, 12), "Centre"],
		["bldg_maison_argenta_01", Vector2i(15, 11), "MaisonAieule"],
		["bldg_maison_argenta_01", Vector2i(7, 12), "Maison1"],
	],
}
## Aplats provisoires [D] : (carte) → [nœud, rectangle de cases, couleur, toit].
const FLATS: Dictionary = {
	"dragons_den_sanctuary": [["Autel", Rect2i(10, 3, 2, 2), Color(0.62, 0.6, 0.55), false]],
}
## Lampes de nuit [D] : (carte) → cases (centre du halo au milieu de la case).
const NIGHT_GLOWS: Dictionary = {
	"blackthorn_city": [Vector2i(14, 12), Vector2i(17, 12), Vector2i(22, 13), Vector2i(26, 13),
		Vector2i(6, 13), Vector2i(12, 20), Vector2i(19, 20)],
}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}

var _over: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases (relues sur toutes les grilles avant de construire, rangée 0 décalée).
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
	print("build_johp3_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
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
			var cells: Array = []
			for cell: Vector2i in entry["cells"]:
				cells.append(_off_top(cell))
			spawns[id] = cells
	var extra: Dictionary = EXTRA_SPAWNS.get(String(spec["id"]), {})
	for name: String in extra:
		spawns[name] = [extra[name]]
	_spawns[spec["id"]] = spawns


## Une case de la rangée 0 (bord nord) passe à la rangée 1.
func _off_top(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.DOWN if cell.y == 0 else cell


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var cave: bool = spec["cave"]
	var kinds: Dictionary = CAVE_KINDS if cave else OUTDOOR_KINDS
	var root := _new_map(spec, size)
	var blocked: Array[Vector2i] = []
	var surf: Array[Vector2i] = []
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
			if DETAIL_KINDS.has(mark) and not cave:
				var detail_kind: int = _over.Kind[DETAIL_KINDS[mark]]
				(root.get_node(^"Detail") as TileMapLayer).set_cell(cell, _over.SOURCE_ID,
					_over.atlas_coords(detail_kind, _rng.randi_range(0, _over.variant_count(detail_kind) - 1)))
			if SURF_CHARS.contains(mark):
				surf.append(cell)
			elif y == 0 and not cave:
				blocked.append(cell) # bord nord : rangée 0 bloquée (voir l'en-tête)
			elif not plan.walkable.contains(mark) and not _over.is_solid_kind(kind):
				blocked.append(cell)
	root.set(&"surf_cells", surf)
	_add_positions(spec, plan, root, blocked)
	_add_extra_triggers(spec, root)
	_add_buildings(spec, root)
	_add_flats(spec, root)
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
		if NPC_POSITIONS.has(key):
			continue
		var unless := _flags(attrs.get("actif_sans", ""))
		var if_flags := _flags(attrs.get("actif_avec", ""))
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], _off_top(cells[i]))
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
				_interact(root, _node_name(id), cells[0], Vector2i(cells.size(), 1), Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), if_flags, unless)
			"pokemon":
				continue
			"cache":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO,
					StringName(id), [], [StringName("got_" + id)])
			"declencheur":
				if IGNORED_TRIGGERS.has(key):
					continue
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])
	var extra: Dictionary = EXTRA_SPAWNS.get(String(map_id), {})
	for name: String in extra:
		_spawn(root, name, extra[name])


func _add_extra_triggers(spec: Dictionary, root: Node2D) -> void:
	for entry: Array in EXTRA_TRIGGERS.get(String(spec["id"]), []):
		var cells: Array[Vector2i] = []
		cells.assign(entry[1])
		_trigger(root, entry[0], cells, entry[2], entry[3])


func _flags(text: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for flag: String in text.split(",", false):
		out.append(StringName(flag))
	return out


## Passage : un warp par case, chacun vers l'arrivée de même rang de la carte cible si elle en a
## autant (bords de 3 cases), sinon vers la première. Bord = PUSH vers l'extérieur ; porte =
## STEP_ON ↑ ; échelle = STEP_ON toutes directions. Cible absente (autre jalon) : « À venir »,
## retour sur l'arrivée de la case.
func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary,
		size: Vector2i, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var on_edge := _on_edge(cells[0], size)
	var trigger: int = dest.get("trigger", PUSH if on_edge else STEP_ON)
	var direction: Vector2i = dest.get("dir",
		_edge_direction(cells[0], size) if on_edge else Vector2i.UP)
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var exists := _spawns.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	var facing: Vector2i = dest.get("facing", direction)
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		var cell := _off_top(cells[i])
		if not exists:
			_warp(root, name, cell, trigger, direction, &"",
				StringName(_back_spawn(root, cell)), -direction,
				dest.get("label", String(target)), if_flags, unless)
			continue
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, name, cell, trigger, direction, target, StringName(arrival), facing, "",
			if_flags, unless)


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


## Aplats provisoires (corps sombre, toit plus clair) sur l'emprise bloquée de la grille [D] ;
## l'art du lot suivant les remplace.
func _add_flats(spec: Dictionary, root: Node) -> void:
	for entry: Array in FLATS.get(String(spec["id"]), []):
		var rect: Rect2i = entry[1]
		var color: Color = entry[2]
		var top_left := Vector2(rect.position) * TILE
		var size := Vector2(rect.size) * TILE
		var body := Polygon2D.new()
		body.name = entry[0]
		var roofed: bool = entry[3]
		var top := size.y * 0.25 if roofed else 0.0
		body.polygon = PackedVector2Array([top_left + Vector2(0, top), top_left + Vector2(size.x, top),
			top_left + size, top_left + Vector2(0, size.y)])
		body.color = color
		_attach(root, root.get_node(^"Decor"), body)
		if not roofed:
			continue
		var roof := Polygon2D.new()
		roof.name = entry[0] + "Toit"
		roof.polygon = PackedVector2Array([
			top_left + Vector2(-TILE * 0.2, size.y * 0.3), top_left + Vector2(size.x * 0.5, 0),
			top_left + Vector2(size.x + TILE * 0.2, size.y * 0.3)])
		roof.color = color.lightened(0.3)
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
	push_error("build_johp3_maps : " + message)
	_errors += 1
