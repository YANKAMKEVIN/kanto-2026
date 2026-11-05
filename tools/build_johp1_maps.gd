extends SceneTree
## Construit les quatre cartes du jalon JOHP1 (arc des Pierres, `docs/tech/jalon-joh-pierres.md` §3)
## d'après leurs grilles (`tools/plans/ruins_of_alph.txt`, `alph_tent.txt`, `alph_gallery.txt`,
## `alph_chamber.txt` : **la grille fait foi**), en **tuiles provisoires** (`OverworldTiles`, modèle
## du JOH8 ; vues peintes `reference/johp1-vues-v1.png` pour le lot d'art suivant), et pose la
## **variante ARC** de la Route 36 sur la scène existante, **sans la reconstruire** (une carte
## peinte reste peinte ; idempotent : les nœuds `Johp1*` déjà présents sont remplacés).
##
##   godot --headless --path . -s res://tools/build_johp1_maps.gd [-- --maps=alph_gallery,route_36]
##   godot --headless --path . --import
##
## Données lues ailleurs (`tools/gen_johp1_data.py`) : PNJ, Dresseurs, objets (`data/npcs/`), textes
## et scènes (`johp1_alph.json`). Ici : sol, cases bloquées, passages, arrivées, panneau, examens,
## cache, déclencheurs (dont une scène par dalle), signes de la Galerie, porte du fond, aplats.
## Bord nord (leçon de la QA A17 du JOH1) : rangée 0 bloquée, entrées et arrivées à la rangée 1.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1
## Drapeaux (dossier JOH-11 §7).
const QUEST: StringName = &"johto_stones_quest"
const STONE: StringName = &"johto_stone_memory"
const TILES_DONE: StringName = &"johto_alph_tiles_done"
const TILE_FLAGS: Array[StringName] = [&"johto_alph_tile_1", &"johto_alph_tile_2", TILES_DONE]
## Valeurs de [enum AlphGlyph.Sign] (l'outil n'a pas besoin de la classe).
const MEMORY: int = 0
const RETURN: int = 1
const BREATH: int = 2
const DECOY: int = 3

const MAPS: Array[Dictionary] = [
	{"id": &"ruins_of_alph", "name": "Ruines d'Alpha", "region": "Route 36", "light": &"johto_auto",
		"seed": 5101, "interior": false},
	{"id": &"alph_tent", "name": "Ruines d'Alpha", "region": "Tente d'Héloïse",
		"light": &"interior_warm", "seed": 5102, "interior": true},
	{"id": &"alph_gallery", "name": "Ruines d'Alpha", "region": "Galerie des Glyphes",
		"light": &"cave_1f", "seed": 5103, "interior": false},
	{"id": &"alph_chamber", "name": "Ruines d'Alpha", "region": "Chambre de la Mémoire",
		"light": &"cave_b1f", "seed": 5104, "interior": false},
]
## Caractère → type de tuile provisoire [D]. Une case non praticable dont la tuile ne l'est pas est
## bloquée par `blocked_cells`.
const KINDS: Dictionary = {
	&"ruins_of_alph": {".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "T": "FOREST", "G": "FOREST",
		"R": "CLIFF", "N": "GRASS", "K": "CLIFF", "D": "DIRT", "E": "COBBLE"},
	&"alph_tent": {"X": "CLIFF", ".": "BOARDWALK", "M": "BOARDWALK", "c": "BOARDWALK", "E": "COBBLE"},
	&"alph_gallery": {"#": "CLIFF", ".": "DIRT", "g": "RUBBLE", "t": "COBBLE", "U": "COBBLE",
		"V": "COBBLE"},
	&"alph_chamber": {"#": "CLIFF", ".": "COBBLE", "S": "COBBLE", "U": "DIRT"},
}
## Passages : (carte/position) → carte, arrivée, déclenchement (défaut : bord = PUSH, sinon
## STEP_ON ↑), sens du pas d'un STEP_ON, sens à l'arrivée.
const WARPS: Dictionary = {
	"ruins_of_alph/warp_nord": {"to": &"route_36", "spawn": "from_ruins", "facing": Vector2i.UP},
	"ruins_of_alph/porte_tente": {"to": &"alph_tent", "spawn": "from_ruins", "facing": Vector2i.UP},
	"ruins_of_alph/entree_galerie": {"to": &"alph_gallery", "spawn": "from_ruins", "trigger": STEP_ON,
		"dir": Vector2i.DOWN, "facing": Vector2i.DOWN},
	"alph_tent/sortie": {"to": &"ruins_of_alph", "spawn": "retour_tente", "facing": Vector2i.DOWN},
	"alph_gallery/escalier_haut": {"to": &"ruins_of_alph", "spawn": "retour_galerie",
		"trigger": STEP_ON, "dir": Vector2i.ZERO, "facing": Vector2i.UP},
	"alph_gallery/escalier_bas": {"to": &"alph_chamber", "spawn": "from_gallery", "trigger": STEP_ON,
		"dir": Vector2i.ZERO, "facing": Vector2i.UP},
	"alph_chamber/escalier_haut": {"to": &"alph_gallery", "spawn": "from_chamber", "trigger": STEP_ON,
		"dir": Vector2i.ZERO, "facing": Vector2i.DOWN},
}
## Déclencheurs : (carte/position) → scène, sens du pas.
const TRIGGERS: Dictionary = {
	"ruins_of_alph/arrivee_titre": {"scene": &"ruins_of_alph_arrival", "dir": Vector2i.ZERO},
	"alph_gallery/barriere_fond": {"scene": &"alph_gallery_door", "dir": Vector2i.UP},
	"alph_chamber/scene_faux": {"scene": &"alph_chamber_fake", "dir": Vector2i.ZERO},
}
## Examens : (carte/position) → sens où le joueur regarde.
const EXAMS: Dictionary = {
	"alph_gallery/mur_1": Vector2i.UP,
	"alph_gallery/mur_2": Vector2i.UP,
	"alph_gallery/mur_3": Vector2i.DOWN,
	"alph_chamber/socle": Vector2i.UP,
}
## Dalles : rangée (de bas en haut) → signes de gauche à droite. Le signe du mur est à la place
## de la bonne dalle de la grille : (16, 10), (18, 7), (15, 4) [D].
const TILE_SIGNS: Dictionary = {
	"dalles_r1": [DECOY, MEMORY, RETURN, BREATH],
	"dalles_r2": [BREATH, MEMORY, DECOY, RETURN],
	"dalles_r3": [BREATH, RETURN, DECOY, MEMORY],
}
const GOOD_SCENES: Dictionary = {"dalles_r1": &"alph_tile_good_1", "dalles_r2": &"alph_tile_good_2",
	"dalles_r3": &"alph_tile_good_3"}
## Signes des murs : (carte/position) → signe (celui de la légende).
const WALL_SIGNS: Dictionary = {"alph_gallery/mur_1": MEMORY, "alph_gallery/mur_2": RETURN,
	"alph_gallery/mur_3": BREATH}
## Signes de décor sur les parois de la Galerie (Zarbi, JH-77) [D] : case, signe.
const WALL_DECOR: Array = [[Vector2i(3, 2), DECOY], [Vector2i(7, 2), BREATH], [Vector2i(9, 2), RETURN],
	[Vector2i(3, 11), RETURN], [Vector2i(8, 11), DECOY], [Vector2i(15, 2), DECOY], [Vector2i(18, 2), MEMORY]]
## Aplats provisoires [D] : (carte) → [nœud, rectangle de cases, couleur, toit].
const FLATS: Dictionary = {
	&"ruins_of_alph": [
		["Tente", Rect2i(5, 8, 7, 6), Color(0.78, 0.71, 0.55), true],
		["Temple", Rect2i(12, 20, 12, 6), Color(0.46, 0.46, 0.42), false],
	],
	&"alph_tent": [
		["Caisses", Rect2i(1, 1, 7, 1), Color(0.42, 0.29, 0.17), false],
		["Table", Rect2i(2, 3, 2, 1), Color(0.5, 0.35, 0.2), false],
	],
	&"alph_chamber": [["Socle", Rect2i(6, 3, 2, 1), Color(0.62, 0.6, 0.54), false]],
}
const COLOR_STONE := Color(0.6, 0.6, 0.56)
const COLOR_MEMORY_STONE := Color(0.42, 0.4, 0.38)
const COLOR_DOOR := Color(0.2, 0.19, 0.21)
const COLOR_LIT := Color(1.0, 0.86, 0.4, 0.4)
const COLOR_FENCE := Color(0.82, 0.62, 0.22)
const COLOR_FENCE_STRIPE := Color(0.2, 0.17, 0.14)
const COLOR_WALL_SIGN := Color(0.86, 0.8, 0.6)
const COLOR_TILE_SIGN := Color(0.24, 0.21, 0.18)

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases (rangée 0 décalée).
var _spawns: Dictionary = {}
var _plans: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_collect_spawns(spec["id"], String(spec["id"]), "")
	_collect_spawns(&"route_36", "route_36", "ARC")
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	if wanted.is_empty() or wanted.has("route_36"):
		_route_36()
	print("build_johp1_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _wanted() -> Array:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			return Array(arg.trim_prefix("--maps=").split(","))
	return []


func _collect_spawns(map_id: StringName, plan_id: String, variant: String) -> void:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt", variant):
		_fail("%s : %s" % [plan_id, plan.error])
		return
	_plans[map_id] = plan
	var spawns: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			var cells: Array = []
			for cell: Vector2i in entry["cells"]:
				cells.append(_off_top(cell))
			spawns[id] = cells
	_spawns[map_id] = spawns


## Une case de la rangée 0 (bord nord) passe à la rangée 1.
func _off_top(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.DOWN if cell.y == 0 else cell


func _build(spec: Dictionary) -> void:
	var map_id: StringName = spec["id"]
	if _errors > 0:
		return
	var plan: Object = _plans[map_id]
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(spec, size)
	var blocked: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	var kinds: Dictionary = KINDS[map_id]
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if not kinds.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [map_id, mark, cell])
				continue
			var kind: int = _over.Kind[kinds[mark]]
			ground.set_cell(cell, _over.SOURCE_ID,
				_over.atlas_coords(kind, _rng.randi_range(0, _over.variant_count(kind) - 1)))
			if y == 0 and map_id == &"ruins_of_alph":
				blocked.append(cell) # bord nord : rangée 0 bloquée (voir l'en-tête)
			elif not plan.walkable.contains(mark) and not _over.is_solid_kind(kind):
				blocked.append(cell)
	_add_positions(map_id, plan, root, blocked)
	_add_flats(map_id, root)
	if map_id == &"alph_gallery":
		_add_gallery(plan, root)
	if map_id == &"alph_chamber":
		# La Pierre Mémoire, posée sur le socle tant qu'on ne l'a pas prise (aplat provisoire [D]).
		var none: Array[StringName] = []
		var taken: Array[StringName] = [STONE]
		var stone := _gate(root, root.get_node(^"Decor"), "PierreMemoire", Vector2i(6, 3), none, taken)
		_rect(root, stone, Rect2(26, -74, 44, 34), COLOR_MEMORY_STONE)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % map_id)


func _add_positions(map_id: StringName, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var size: Vector2i = root.get(&"size")
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		var key := "%s/%s" % [map_id, id]
		var none: Array[StringName] = []
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], _off_top(cells[i]))
			"warp":
				if not WARPS.has(key):
					_fail("%s : passage sans destination" % key)
					continue
				_add_warp(root, id, cells, WARPS[key], size)
			"panneau":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), none)
				_add_prop(root, SIGN_PROP, cells[0], _node_name(id) + "Sign")
			"examen":
				var unless: Array[StringName] = []
				if id == "socle":
					unless.append(STONE)
				_interact(root, _node_name(id), cells[0], Vector2i(cells.size(), 1),
					EXAMS.get(key, Vector2i.ZERO), StringName("%s_%s" % [map_id, id]), unless)
			"cache":
				# Cache dans un pilier (indice de la grille) : le pilier occupe sa case.
				var got: Array[StringName] = [StringName("got_" + id)]
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO, StringName(id), got)
				blocked.append(cells[0])
				_flat(root, "Pilier", Rect2i(cells[0], Vector2i.ONE), COLOR_STONE, false)
			"declencheur":
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				_trigger(root, _node_name(id), cells, TRIGGERS[key]["dir"], TRIGGERS[key]["scene"])
			"dalle":
				var good := _cell_attr(entry["attrs"].get("bonne", ""))
				for cell: Vector2i in cells:
					var scene: StringName = GOOD_SCENES[id] if cell == good else &"alph_tile_wrong"
					var single: Array[Vector2i] = [cell]
					_trigger(root, "Dalle_%d_%d" % [cell.x, cell.y], single, Vector2i.ZERO, scene)


func _cell_attr(text: String) -> Vector2i:
	var parts := text.split(",")
	if parts.size() != 2:
		_fail("case illisible : « %s »" % text)
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))


## Signes des dalles et des murs, lueur d'une dalle éclairée, porte du fond.
func _add_gallery(plan: Object, root: Node2D) -> void:
	var decor := root.get_node(^"Decor")
	var rank := 0
	for id: String in ["dalles_r1", "dalles_r2", "dalles_r3"]:
		var entry: Dictionary = plan.positions[id]
		var good := _cell_attr(entry["attrs"].get("bonne", ""))
		var signs: Array = TILE_SIGNS[id]
		var cells: Array = entry["cells"]
		for i: int in cells.size():
			var cell: Vector2i = cells[i]
			if cell == good:
				var lit: Array[StringName] = [TILE_FLAGS[rank]]
				var none: Array[StringName] = []
				var gate := _gate(root, decor, "Lueur_%d_%d" % [cell.x, cell.y], cell, lit, none)
				_rect(root, gate, Rect2(-48, -96, 96, 96), COLOR_LIT)
			_glyph(root, "Signe_%d_%d" % [cell.x, cell.y], cell, signs[i], COLOR_TILE_SIGN)
		rank += 1
	for key: String in WALL_SIGNS:
		var id := key.get_slice("/", 1)
		var cell: Vector2i = (plan.positions[id]["cells"] as Array)[0]
		_glyph(root, _node_name(id) + "Signe", cell, WALL_SIGNS[key], COLOR_WALL_SIGN)
	for entry: Array in WALL_DECOR:
		var cell: Vector2i = entry[0]
		_glyph(root, "Paroi_%d_%d" % [cell.x, cell.y], cell, entry[1], COLOR_WALL_SIGN.darkened(0.25))
	# Porte du fond : occupe l'escalier jusqu'au dernier bon pas.
	var stairs: Array[Vector2i] = []
	stairs.assign(plan.positions["escalier_bas"]["cells"])
	var none: Array[StringName] = []
	var open: Array[StringName] = [TILES_DONE]
	var door := _gate(root, root.get_node(^"Entities"), "PorteFond", stairs[0], none, open)
	door.set(&"blocking_cells", stairs)
	_rect(root, door, Rect2(-48, -96, TILE * stairs.size(), 96), COLOR_DOOR)


func _glyph(root: Node2D, node_name: String, cell: Vector2i, sign_kind: int, color: Color) -> void:
	var glyph := Node2D.new()
	glyph.set_script(load("res://game/world/johto/alph_glyph.gd"))
	glyph.name = node_name
	glyph.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	glyph.set(&"sign_kind", sign_kind)
	glyph.set(&"color", color)
	_attach(root, root.get_node(^"Decor"), glyph)


# --- Route 36, variante ARC --------------------------------------------------------------------

## Pose la variante ARC de `route_36.txt` sur la scène existante : chemin (cases `=`), passage vers
## les Ruines (bord sud), arrivée, barrière de chantier (déclencheur, et décor qui occupe le
## passage tant que `johto_stones_quest` manque). La grille de base reste celle du JOH3.
func _route_36() -> void:
	var plan: Object = _plans[&"route_36"]
	var scene := load(MAPS_DIR + "route_36.tscn") as PackedScene
	if scene == null:
		_fail("route_36 introuvable")
		return
	var root := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	for group: NodePath in [^"Warps", ^"Spawns", ^"Triggers", ^"Entities"]:
		for child: Node in root.get_node(group).get_children():
			if child.name.begins_with("Johp1") or child.name.begins_with("from_ruins"):
				child.get_parent().remove_child(child)
				child.free()
	var base := PlanGrid.new()
	base.load_file(PLANS_DIR + "route_36.txt")
	var ground := root.get_node(^"Ground") as TileMapLayer
	var blocked: Array[Vector2i] = []
	blocked.assign(root.get(&"blocked_cells"))
	_rng.seed = 5105
	var dirt: int = _over.Kind["DIRT"]
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if plan.at(cell) == base.at(cell):
				continue
			ground.set_cell(cell, _over.SOURCE_ID,
				_over.atlas_coords(dirt, _rng.randi_range(0, _over.variant_count(dirt) - 1)))
			blocked.erase(cell)
	root.set(&"blocked_cells", blocked)
	var entry: Dictionary = plan.positions["warp_ruines"]
	var cells: Array[Vector2i] = []
	cells.assign(entry["cells"])
	for i: int in cells.size():
		var none: Array[StringName] = []
		var arrival := "from_route_36" if i == 0 else "from_route_36_%d" % i
		_warp(root, "Johp1WarpRuines_%d" % i, cells[i], PUSH, Vector2i.DOWN, &"ruins_of_alph",
			StringName(arrival), Vector2i.DOWN, none)
		_spawn(root, "from_ruins" if i == 0 else "from_ruins_%d" % i, cells[i])
	var fence_cells: Array[Vector2i] = []
	var barrier: Array[Vector2i] = []
	barrier.assign(plan.positions["barriere_ruines"]["cells"])
	_trigger(root, "Johp1BarriereRuines", barrier, Vector2i.DOWN, &"route_36_ruins_gate")
	for cell: Vector2i in barrier:
		fence_cells.append(cell + Vector2i.DOWN)
	var no_if: Array[StringName] = []
	var closed: Array[StringName] = [QUEST]
	var fence := _gate(root, root.get_node(^"Entities"), "Johp1Barriere", fence_cells[0], no_if, closed)
	fence.set(&"blocking_cells", fence_cells)
	var width := float(TILE * fence_cells.size())
	_rect(root, fence, Rect2(-46, -70, width - 4, 18), COLOR_FENCE)
	_rect(root, fence, Rect2(-46, -34, width - 4, 18), COLOR_FENCE)
	_rect(root, fence, Rect2(-46, -80, 12, 76), COLOR_FENCE_STRIPE)
	_rect(root, fence, Rect2(width - 62, -80, 12, 76), COLOR_FENCE_STRIPE)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAPS_DIR + "route_36.tscn")
	print("route_36 (ARC) : %s" % ("OK" if err == OK else "ERREUR %d" % err))
	if err != OK:
		_errors += 1
	root.free()


# --- Nœuds ------------------------------------------------------------------------------------

func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary, size: Vector2i) -> void:
	var on_edge := _on_edge(cells[0], size)
	var trigger: int = dest.get("trigger", PUSH if on_edge else STEP_ON)
	var direction: Vector2i = dest.get("dir", _edge_direction(cells[0], size) if on_edge else Vector2i.UP)
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var target_cells: Array = (_spawns.get(target, {}) as Dictionary).get(spawn, [])
	if target_cells.is_empty():
		_fail("%s : arrivée %s/%s absente" % [id, target, spawn])
		return
	for i: int in cells.size():
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		var none: Array[StringName] = []
		_warp(root, "%s_%d" % [_node_name(id), i], _off_top(cells[i]), trigger, direction, target,
			StringName(arrival), dest["facing"], none)


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


func _new_map(spec: Dictionary, size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = String(spec["id"]).to_pascal_case()
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", spec["id"])
	root.set(&"display_name", spec["name"])
	root.set(&"region", spec["region"])
	root.set(&"size", size)
	root.set(&"interior", spec["interior"])
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
		target: StringName, spawn: StringName, facing: Vector2i, none: Array[StringName]) -> void:
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
	point.set(&"if_flags", none)
	point.set(&"unless_flags", none.duplicate())
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, span: Vector2i, facing: Vector2i,
		dialogue: StringName, unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", span)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	var none: Array[StringName] = []
	point.set(&"if_flags", none)
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


func _add_prop(root: Node, id: String, anchor: Vector2i, node_name: String) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	var rules: GDScript = load("res://game/world/props/painted_prop_rules.gd")
	prop.position = rules.call(&"foot_position", StringName(id), anchor)
	_attach(root, root.get_node(^"Entities"), prop)


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array[StringName],
		unless: Array[StringName]) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless)
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


## Aplats provisoires (corps, toit plus clair) sur l'emprise bloquée de la grille [D].
func _add_flats(map_id: StringName, root: Node) -> void:
	for entry: Array in FLATS.get(map_id, []):
		_flat(root, entry[0], entry[1], entry[2], entry[3])


func _flat(root: Node, node_name: String, rect: Rect2i, color: Color, roofed: bool) -> void:
	var top_left := Vector2(rect.position) * TILE
	var size := Vector2(rect.size) * TILE
	var body := Polygon2D.new()
	body.name = node_name
	var top := size.y * 0.25 if roofed else 0.0
	body.polygon = PackedVector2Array([top_left + Vector2(0, top), top_left + Vector2(size.x, top),
		top_left + size, top_left + Vector2(0, size.y)])
	body.color = color
	_attach(root, root.get_node(^"Decor"), body)
	if not roofed:
		return
	var roof := Polygon2D.new()
	roof.name = node_name + "Toit"
	roof.polygon = PackedVector2Array([top_left + Vector2(-TILE * 0.2, size.y * 0.3),
		top_left + Vector2(size.x * 0.5, 0), top_left + Vector2(size.x + TILE * 0.2, size.y * 0.3)])
	roof.color = color.lightened(0.3)
	_attach(root, root.get_node(^"Decor"), roof)


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
	push_error("build_johp1_maps : " + message)
	_errors += 1
