extends SceneTree
## Construit les quatre cartes du jalon JOH8 (Chapitre Johto, `docs/tech/jalon-joh8.md` §2.1 à
## §2.3) d'après leurs grilles fonctionnelles (`tools/plans/bell_tower_woods.txt`,
## `bell_tower_1f.txt`, `bell_tower_2f.txt`, `bell_tower_roof.txt` : **la grille fait foi**), en
## **tuiles provisoires** (`OverworldTiles`, modèle du JOH2), logique seule : l'image vient des
## passes d'ambiance :
##   bell_tower_woods (Bois de la Tour), bell_tower_1f, bell_tower_2f, bell_tower_roof.
##
##   godot --headless --path . -s res://tools/build_joh8_maps.gd [-- --maps=bell_tower_2f]
##   godot --headless --path . --import
##
## Données lues ailleurs (`tools/gen_joh8_data.py`) : PNJ, Dresseurs, objets, Dante, Entei, Ho-Oh
## (`data/npcs/bell_tower_*.json`), textes et scènes (`joh8_bell_tower.json`). Ici : sol et cases
## bloquées, passages (bord = PUSH, porte et escaliers = STEP_ON ; destination absente = « À
## venir »), **planches qui cèdent** (warps FALL vers l'arrivée `chute` du 1F, comme les trous du
## Manoir), arrivées, panneau, examens, déclencheurs (scène du sommet ; long escalier en fondu
## H-12 : un déclencheur sur la marche, pas de warp), **cage de feu** (FlagGate bloquante
## `unless johto_ho_oh_seen`), façade de la tour en aplat, lanternes (lampes de nuit du Bois).
## Relancer `--maps=bell_tower_woods` quand `ecruteak_city.tscn` (JOH2) existe : le raccord sud
## cesse d'être « À venir » ; et relancer `build_joh2_maps.gd --maps=ecruteak_city` pour le
## raccord nord de Rosalia.
## **À relancer ensuite**, sinon la peinture est perdue (`tools/build_joh_ambiance_carillon.gd` donne
## l'ordre des trois passes) : ces cartes sont peintes depuis le 2026-11-06.

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
const FALL: int = 2
## Drapeau qui fait voler la cage en éclats (H-21).
const CAGE_FLAG: StringName = &"johto_ho_oh_seen"

## Cartes : grille, identifiant, nom, sous-titre, extérieur (lumière), graine.
const MAPS: Array[Dictionary] = [
	{"id": &"bell_tower_woods", "name": "Bois de la Tour", "region": "Rosalia",
		"light": &"johto_auto", "seed": 4801},
	{"id": &"bell_tower_1f", "name": "Tour Carillon", "region": "Rosalia", "light": &"tower",
		"seed": 4811},
	{"id": &"bell_tower_2f", "name": "Tour Carillon", "region": "Rosalia", "light": &"tower",
		"seed": 4821},
	{"id": &"bell_tower_roof", "name": "Tour Carillon", "region": "Rosalia",
		"light": &"johto_auto", "seed": 4831},
]
## Grilles d'autres jalons dont on lit les arrivées (raccords).
const OTHER_PLANS: Dictionary = {&"ecruteak_city": "rosalia"}

## Caractère → type de tuile provisoire, par carte [D]. Une case non praticable dont la tuile
## ne l'est pas est bloquée par `blocked_cells` (sauf la cage : FlagGate).
const KINDS: Dictionary = {
	&"bell_tower_woods": {".": "GRASS", "p": "COBBLE", "h": "TALL_GRASS", "T": "FOREST",
		"G": "FOREST", "L": "COBBLE", "K": "CLIFF", "D": "COBBLE"},
	&"bell_tower_1f": {"#": "CLIFF", ".": "BOARDWALK", "A": "CROP", "M": "CLIFF", "U": "COBBLE",
		"E": "COBBLE"},
	&"bell_tower_2f": {"#": "CLIFF", ".": "BOARDWALK", "O": "DIRT", "M": "CLIFF", "U": "COBBLE",
		"D": "COBBLE"},
	&"bell_tower_roof": {"r": "CLIFF", "#": "CLIFF", ".": "COBBLE", "B": "CLIFF", "c": "COBBLE",
		"M": "CLIFF", "D": "COBBLE"},
}
## Cases laissées libres par la grille de tuiles malgré leur caractère non praticable : la cage
## (sa FlagGate les occupe tant qu'elle est debout).
const GATED_MARKS: Dictionary = {&"bell_tower_roof": "c"}

## Passages : (carte/position) → carte cible, arrivée, libellé « À venir » si la cible manque.
const WARPS: Dictionary = {
	"bell_tower_woods/warp_sud": {"to": &"ecruteak_city", "spawn": "from_bois", "label": "Rosalia"},
	"bell_tower_woods/porte_tour": {"to": &"bell_tower_1f", "spawn": "from_woods"},
	"bell_tower_1f/sortie": {"to": &"bell_tower_woods", "spawn": "retour_tour"},
}
## Escaliers joués comme une scène (fondu et texte) au lieu d'un warp : (carte/position) → scène.
const STAIR_SCENES: Dictionary = {"bell_tower_2f/vers_sommet": &"bell_tower_climb"}
## Déclencheurs : (carte/position) → scène, sens du pas (vide = toutes directions).
const TRIGGERS: Dictionary = {
	"bell_tower_roof/scene_sommet": {"scene": &"bell_tower_summit", "dir": Vector2i.ZERO},
}
## Examens : (carte/position) → sens où le joueur regarde.
const EXAMS: Dictionary = {
	"bell_tower_1f/autel": Vector2i.UP,
	"bell_tower_2f/examen_planche": Vector2i.DOWN,
	"bell_tower_roof/cloche": Vector2i.UP,
	"bell_tower_roof/rambarde": Vector2i.RIGHT,
}
## Façade de la tour en aplat provisoire [D] : (carte) → [nœud, rectangle, couleur].
const FACADES: Dictionary = {
	&"bell_tower_woods": [["TourCarillon", Rect2i(8, 1, 8, 5), Color(0.45, 0.22, 0.14)]],
}
## Objets de décor en aplat provisoire [D] : (carte) → [nœud, rectangle de cases, couleur, liseré].
const PIECES: Dictionary = {
	&"bell_tower_1f": [["Autel", Rect2i(9, 1, 6, 2), Color(0.55, 0.12, 0.1), Color(0.85, 0.7, 0.35)]],
	&"bell_tower_roof": [["GrandeCloche", Rect2i(8, 1, 4, 3), Color(0.45, 0.33, 0.18),
		Color(0.75, 0.6, 0.3)]],
}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
const COLOR_LANTERN := Color(0.62, 0.6, 0.55)
const COLOR_LANTERN_TOP := Color(0.36, 0.34, 0.32)
const COLOR_CAGE := Color(0.95, 0.42, 0.1)
const COLOR_CAGE_CORE := Color(1.0, 0.8, 0.3)
const COLOR_PLANK := Color(0.32, 0.22, 0.14, 0.55)

var _over: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases.
var _spawns: Dictionary = {}
## Carte → grille (arrivées tournées).
var _plans: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_collect_spawns(spec["id"], String(spec["id"]))
	for map_id: StringName in OTHER_PLANS:
		_collect_spawns(map_id, OTHER_PLANS[map_id])
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	print("build_joh8_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _wanted() -> Array:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			return Array(arg.trim_prefix("--maps=").split(","))
	return []


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		_fail("%s : %s" % [plan_id, plan.error])
	return plan


func _collect_spawns(map_id: StringName, plan_id: String) -> void:
	var plan := _plan(plan_id)
	_plans[map_id] = plan
	var spawns: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			spawns[id] = entry["cells"]
	_spawns[map_id] = spawns


func _build(spec: Dictionary) -> void:
	var map_id: StringName = spec["id"]
	var plan: Object = _plans[map_id]
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec, size)
	var blocked: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	var kinds: Dictionary = KINDS[map_id]
	var gated: String = GATED_MARKS.get(map_id, "")
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if not kinds.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [map_id, mark, cell])
				continue
			var kind: int = _over.Kind[kinds[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if mark == gated:
				continue
			if not plan.walkable.contains(mark) and not _over.is_solid_kind(kind):
				blocked.append(cell)
	_add_positions(map_id, plan, root, blocked)
	_add_facades(map_id, root)
	_add_pieces(map_id, root)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % map_id)


func _add_positions(map_id: StringName, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var size: Vector2i = root.get(&"size")
	var entities := root.get_node(^"Entities")
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		var attrs: Dictionary = entry["attrs"]
		var key := "%s/%s" % [map_id, id]
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp":
				if not WARPS.has(key):
					_fail("%s : passage sans destination" % key)
					continue
				_add_warp(root, id, cells, WARPS[key], size)
			"escalier":
				if STAIR_SCENES.has(key):
					_trigger(root, _node_name(id), cells, Vector2i.ZERO, STAIR_SCENES[key])
					continue
				var dest: PackedStringArray = String(attrs.get("vers", "")).split(":")
				if dest.size() != 2:
					_fail("%s : « vers » attendu carte:arrivée" % key)
					continue
				_add_warp(root, id, cells, {"to": StringName(dest[0]), "spawn": dest[1]}, size, true)
			"trou":
				var dest_map := StringName(attrs.get("vers", ""))
				var arrival := StringName(attrs.get("arrivee", ""))
				for cell: Vector2i in cells:
					_warp(root, "Trou_%d_%d" % [cell.x, cell.y], cell, FALL, Vector2i.ZERO,
						dest_map, arrival, Vector2i.DOWN, "")
					var board := _gate(root, entities, "Planche_%d_%d" % [cell.x, cell.y], cell, [])
					_rect(root, board, Rect2(-46, -94, 92, 4), COLOR_PLANK)
					_rect(root, board, Rect2(-46, -52, 92, 4), COLOR_PLANK)
			"panneau":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]))
				_add_prop(root, SIGN_PROP, cells[0], _node_name(id) + "Sign")
			"examen":
				var span := Vector2i(cells.size(), 1)
				_interact(root, _node_name(id), cells[0], span, EXAMS.get(key, Vector2i.ZERO),
					StringName("%s_%s" % [map_id, id]))
			"declencheur":
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])
			"decor":
				if attrs.get("role", "") == "lanterne":
					_lantern(root, entities, cells[0])
			"repere":
				if id == "cage_feu":
					_cage(root, entities, cells, plan)


func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary,
		size: Vector2i, stairs: bool = false) -> void:
	var on_edge := _on_edge(cells[0], size) and not stairs
	var trigger := PUSH if on_edge else STEP_ON
	var direction := _edge_direction(cells[0], size) if on_edge else Vector2i.ZERO
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var exists := ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target) or _is_built_here(target)
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		if not exists:
			_warp(root, name, cells[i], trigger, direction, &"",
				StringName(_back_spawn(root, cells[i])), -direction, dest.get("label", String(target)))
			continue
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival),
			_arrival_facing(target, spawn, direction), "")


func _is_built_here(map_id: StringName) -> bool:
	for spec: Dictionary in MAPS:
		if spec["id"] == map_id:
			return true
	return false


func _arrival_facing(target: StringName, spawn: String, direction: Vector2i) -> Vector2i:
	var plan: Object = _plans.get(target)
	if plan != null:
		var entry: Dictionary = plan.positions.get(spawn, {})
		var facing: String = (entry.get("attrs", {}) as Dictionary).get("facing", "")
		if FACINGS.has(facing):
			return FACINGS[facing]
	return direction if direction != Vector2i.ZERO else Vector2i.DOWN


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
	# Tableaux typés posés explicitement (outil sans autoloads, comme le JOH2).
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
	var none: Array[StringName] = []
	point.set(&"if_flags", none)
	point.set(&"unless_flags", none.duplicate())
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, span: Vector2i, facing: Vector2i,
		dialogue: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", span)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	var none: Array[StringName] = []
	point.set(&"if_flags", none)
	point.set(&"unless_flags", none.duplicate())
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
	point.position = _world(Vector2i(top_left.x, bottom_right.y))
	point.set(&"size", bottom_right - top_left + Vector2i.ONE)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


func _add_prop(root: Node, id: String, anchor: Vector2i, node_name: String) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", StringName(id), anchor)
	_attach(root, root.get_node(^"Entities"), prop)


## Lanterne de pierre (aplat provisoire) et sa lampe de nuit (groupe `night_lights`).
func _lantern(root: Node, entities: Node, cell: Vector2i) -> void:
	var gate := _gate(root, entities, "Lanterne_%d_%d" % [cell.x, cell.y], cell, [])
	_rect(root, gate, Rect2(-14, -70, 28, 64), COLOR_LANTERN)
	_rect(root, gate, Rect2(-24, -84, 48, 16), COLOR_LANTERN_TOP)
	var glow := Sprite2D.new()
	glow.set_script(load("res://game/world/lighting/light_glow.gd"))
	glow.name = "Lampe_%d_%d" % [cell.x, cell.y]
	glow.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	glow.set(&"glow_type", &"lamp")
	glow.visible = false
	_attach(root, root.get_node(^"NightLights"), glow)
	glow.add_to_group(NIGHT_LIGHTS, true)


## Cage de feu (aplat provisoire) : FlagGate qui occupe ses barreaux (`c` de la grille) tant que
## Ho-Oh ne l'a pas brisée (H-21).
func _cage(root: Node, entities: Node, cells: Array[Vector2i], plan: Object) -> void:
	var bars: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if plan.at(cell) == "c":
			bars.append(cell)
	var anchor := Vector2i(cells[0].x, cells[cells.size() - 1].y)
	var gate := _gate(root, entities, "CageDeFeu", anchor, [CAGE_FLAG])
	gate.set(&"blocking_cells", bars)
	for cell: Vector2i in bars:
		var offset := Vector2((cell - anchor) * TILE)
		_rect(root, gate, Rect2(offset + Vector2(-36, -92), Vector2(72, 88)), COLOR_CAGE)
		_rect(root, gate, Rect2(offset + Vector2(-8, -92), Vector2(16, 88)), COLOR_CAGE_CORE)


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i,
		unless: Array) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	var typed_if: Array[StringName] = []
	gate.set(&"if_flags", typed_if)
	var typed_unless: Array[StringName] = []
	typed_unless.assign(unless)
	gate.set(&"unless_flags", typed_unless)
	var none: Array[Vector2i] = []
	gate.set(&"blocking_cells", none)
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


## Façade de la Tour Carillon vue du Bois : aplat provisoire (corps, trois toits) [D].
func _add_facades(map_id: StringName, root: Node) -> void:
	for entry: Array in FACADES.get(map_id, []):
		var rect: Rect2i = entry[1]
		var color: Color = entry[2]
		var top_left := Vector2(rect.position) * TILE
		var size := Vector2(rect.size) * TILE
		var body := Polygon2D.new()
		body.name = entry[0]
		body.polygon = PackedVector2Array([top_left + Vector2(TILE * 0.5, size.y * 0.2),
			top_left + Vector2(size.x - TILE * 0.5, size.y * 0.2), top_left + size,
			top_left + Vector2(0, size.y)])
		body.color = color
		_attach(root, root.get_node(^"Decor"), body)
		for i: int in 3:
			var roof := Polygon2D.new()
			roof.name = "%sToit%d" % [entry[0], i]
			var y := top_left.y + size.y * (0.05 + 0.3 * i)
			roof.polygon = PackedVector2Array([Vector2(top_left.x - TILE * 0.3, y + TILE * 0.6),
				Vector2(top_left.x + size.x * 0.5, y), Vector2(top_left.x + size.x + TILE * 0.3,
				y + TILE * 0.6)])
			roof.color = Color(0.62, 0.18, 0.12)
			_attach(root, root.get_node(^"Decor"), roof)


## Autel du 1F, grande cloche du sommet : aplats provisoires sur leur emprise bloquée [D].
func _add_pieces(map_id: StringName, root: Node) -> void:
	for entry: Array in PIECES.get(map_id, []):
		var rect: Rect2i = entry[1]
		var top_left := Vector2(rect.position) * TILE
		var size := Vector2(rect.size) * TILE
		var body := Polygon2D.new()
		body.name = entry[0]
		if entry[0] == "GrandeCloche":
			body.polygon = PackedVector2Array([top_left + Vector2(size.x * 0.3, 0),
				top_left + Vector2(size.x * 0.7, 0), top_left + Vector2(size.x * 0.95, size.y * 0.9),
				top_left + Vector2(size.x * 0.05, size.y * 0.9)])
		else:
			body.polygon = PackedVector2Array([top_left + Vector2(8, 8),
				top_left + Vector2(size.x - 8, 8), top_left + size - Vector2(8, 8),
				top_left + Vector2(8, size.y - 8)])
		body.color = entry[2]
		_attach(root, root.get_node(^"Decor"), body)
		var rim := Line2D.new()
		rim.name = entry[0] + "Liseré"
		rim.points = body.polygon
		rim.closed = true
		rim.width = 8.0
		rim.default_color = entry[3]
		_attach(root, root.get_node(^"Decor"), rim)


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
	push_error("build_joh8_maps : " + message)
	_errors += 1
