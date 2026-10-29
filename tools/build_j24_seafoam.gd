extends SceneTree
## Construit les cinq étages des Îles Écume (jalon 24, T15 ; dossier 27 §7 ; `jalon-24.md` §2.5,
## §2.6, §2.6 bis), en tuiles provisoires (`OverworldTiles`), sans lumière, d'après les grilles
## `tools/plans/seafoam_1f.txt` … `seafoam_b4f.txt` (la grille fait foi ; contrôle
## `tools/art/plan_check_j24_seafoam.py`, anti-blocage compris).
##
## Par étage :
##   - sol : paroi `# | o x` (falaise), sol bas `. B O E U V` (terre), sol haut `:` (pavé),
##     escalier `=` (planches), eau surfable `w s ^ v < >` et points de chute dans l'eau, eau décor `~` ;
##   - [SeafoamFloorGate] `EtatEtage` : niveaux de sol et courants (actifs ou calmes selon les
##     8 drapeaux, [SeafoamState]) ;
##   - [SeafoamBoulderSetup] `Boulders` : trous, rochers (présence calculée par [SeafoamState]) ;
##     objets cachés interdits aux rochers ;
##   - trous : dessin ouvert / bouché ([FlagGate]) et chute du joueur ([WarpPoint] FALL `unless`
##     le drapeau du trou) vers le spawn `chute_<étage>_<n>` de l'étage du dessous ;
##   - rochers tombés dans l'eau (B3F, B4F) : [FlagGate] bloquant `if` le drapeau du trou du dessus ;
##   - échelles et passages : [WarpPoint] STEP_ON vers `arrivee_<paire>` ; entrées du 1F : STEP_ON ↓
##     vers la Route 20 ;
##   - panneaux (T-11, T-12, T-13) et objets cachés (`data/cutscenes/seafoam.json`).
## Artikodin (B4F) est un PNJ de `data/npcs/seafoam_b4f.json` (scène `articuno`).
##
##   godot --headless --path . -s res://tools/build_j24_seafoam.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const FLOORS: Array[String] = ["seafoam_1f", "seafoam_b1f", "seafoam_b2f", "seafoam_b3f",
	"seafoam_b4f"]
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
const FALL: int = 2
const SOLID_CHARS: String = "#|oxn"
const SURF_CHARS: String = "ws^v<>"
const LOW_CHARS: String = ".BOFEUV"
const CURRENTS: Dictionary = {"^": Vector2i.UP, "v": Vector2i.DOWN, "<": Vector2i.LEFT,
	">": Vector2i.RIGHT}
## Panneaux : texte du dossier → dialogue.
const SIGNS: Dictionary = {"T-11": &"seafoam_sign_boulders", "T-12": &"seafoam_sign_currents",
	"T-13": &"seafoam_sign_danger"}
## Objets cachés : objet → dialogue (scène du même nom). Le Max Éther (B3F) est posé depuis le lot 32P.
## Lumière par étage (`data/world/lighting.json`) : profils des grottes du J12 [D].
const LIGHTS: Dictionary = {"seafoam_1f": &"cave_1f", "seafoam_b1f": &"cave_1f",
	"seafoam_b2f": &"cave_b1f", "seafoam_b3f": &"cave_b1f", "seafoam_b4f": &"cave_b2f"}
const HIDDEN: Dictionary = {"nugget": &"seafoam_b2f_hidden_1",
	"ultra_ball": &"seafoam_b4f_hidden_1", "max_ether": &"seafoam_b3f_hidden_1"}

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
var _plans: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2424
	for id: String in FLOORS:
		_plans[id] = _plan(id)
	for id: String in FLOORS:
		_build_floor(id)
	print("build_j24_seafoam : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_floor(map_id: String) -> void:
	var plan: Object = _plans[map_id]
	var size := Vector2i(plan.width, plan.height)
	var node_name := "Seafoam" + map_id.trim_prefix("seafoam_").to_upper()
	var root := _new_map(node_name, StringName(map_id), "Îles Écume", size)
	var water_falls := _water_fall_cells(plan)
	_paint(root, plan, water_falls)
	var entities: Node = root.get_node(^"Entities")
	# Eau surfable, courants, Surf forcé.
	var surf: Array[Vector2i] = []
	surf.assign(plan.cells_of(SURF_CHARS))
	surf.append_array(water_falls)
	root.set(&"surf_cells", surf)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	for c: String in CURRENTS:
		for cell: Vector2i in plan.cells_of(c):
			currents[cell] = CURRENTS[c]
	root.set(&"current_cells", currents)
	var forced: Array[Vector2i] = []
	forced.assign(plan.cells_of("s"))
	for id: String in _ids(plan, "chute_joueur"):
		if plan.attr(id, "surf") == "oui":
			forced.append(plan.cell_of(id))
	root.set(&"forced_surf_cells", forced)
	_floor_gate(root, entities, plan, map_id)
	# Arrivées : spawns de la grille, atterrissages des chutes.
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	for id: String in _ids(plan, "chute_joueur"):
		var origin: String = plan.attr(id, "depuis")
		_spawn(root, "chute_%s_%s" % [origin.get_slice(":", 0), origin.get_slice(":", 1)],
			plan.cell_of(id))
	# Échelles, passages, entrées.
	for id: String in _ids(plan, "echelle"):
		var cell: Vector2i = plan.cell_of(id)
		var pair: String = plan.attr(id, "paire").to_lower()
		_warp(root, "Echelle_" + pair, cell, STEP_ON, Vector2i.ZERO,
			StringName(plan.attr(id, "vers")), StringName("arrivee_" + pair), Vector2i.DOWN, [])
		_ladder(root, entities, cell, plan.attr(id, "sens") == "monte")
	for id: String in _ids(plan, "passage"):
		var pair: String = plan.attr(id, "paire").to_lower()
		_warp(root, "Passage_" + pair, plan.cell_of(id), STEP_ON, Vector2i.ZERO,
			StringName(plan.attr(id, "vers")), StringName("arrivee_" + pair), Vector2i.DOWN, [])
	for id: String in _ids(plan, "entree"):
		var side: String = plan.attr(id, "cote")
		var index := 0
		for cell: Vector2i in plan.cells_at(id):
			index += 1
			_warp(root, "Entree_%s_%d" % [side, index], cell, STEP_ON, Vector2i.DOWN, &"route_20",
				StringName("from_seafoam_1f_" + side), Vector2i.DOWN, [])
	_boulders(root, entities, plan, map_id, water_falls)
	for id: String in _ids(plan, "panneau"):
		_add_sign(root, entities, plan.cell_of(id), SIGNS[plan.attr(id, "texte")])
	for id: String in _ids(plan, "objet_cache"):
		var item: String = plan.attr(id, "item")
		if HIDDEN.has(item):
			_hidden(root, plan.cell_of(id), HIDDEN[item])
	_save(root, MAPS_DIR + map_id + ".tscn")


## Points de chute de rochers posés dans l'eau (`sol=eau`).
func _water_fall_cells(plan: Object) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for id: String in _ids(plan, "chute_rocher"):
		if plan.attr(id, "sol") == "eau":
			cells.append(plan.cell_of(id))
	return cells


## Sol provisoire : un type de tuile par caractère.
func _paint(root: Node, plan: Object, water_falls: Array[Vector2i]) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var c: String = plan.at(cell)
			var kind: int = _over.Kind.DIRT
			if SOLID_CHARS.contains(c) and c != "n":
				kind = _over.Kind.CLIFF
			elif SURF_CHARS.contains(c) or c == "~" or water_falls.has(cell):
				kind = _over.Kind.WATER
			elif c == ":":
				kind = _over.Kind.COBBLE
			elif c == "=":
				kind = _over.Kind.BOARDWALK
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Niveaux de sol et courants : [SeafoamFloorGate].
func _floor_gate(root: Node, entities: Node, plan: Object, map_id: String) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/seafoam/seafoam_floor_gate.gd"))
	gate.name = "EtatEtage"
	gate.set(&"floor_id", StringName(map_id))
	var low: Array[Vector2i] = []
	var high: Array[Vector2i] = []
	var stairs: Array[Vector2i] = []
	var exits: Dictionary = {}
	for id: String in plan.positions:
		if String(plan.positions[id]["kind"]) in ["echelle", "entree"]:
			for cell: Vector2i in plan.cells_at(id):
				exits[cell] = true
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if exits.has(cell):
				continue
			var c: String = plan.at(cell)
			if c == ":":
				high.append(cell)
			elif c == "=":
				stairs.append(cell)
			elif LOW_CHARS.contains(c) or SURF_CHARS.contains(c) or c == "~":
				low.append(cell)
	gate.set(&"low_cells", low)
	gate.set(&"high_cells", high)
	gate.set(&"stairs_cells", stairs)
	_attach(root, entities, gate)


## Rochers, trous et rochers tombés dans l'eau.
func _boulders(root: Node, entities: Node, plan: Object, map_id: String,
		water_falls: Array[Vector2i]) -> void:
	var setup := Node.new()
	setup.set_script(load("res://game/world/seafoam/seafoam_boulder_setup.gd"))
	setup.name = "Boulders"
	setup.set(&"floor_id", StringName(map_id))
	setup.set(&"water_fall_cells", water_falls)
	var boulder_cells: Array[Vector2i] = []
	var boulder_holes: Array[int] = []
	for id: String in _ids(plan, "rocher"):
		boulder_cells.append(plan.cell_of(id))
		var hole: String = plan.attr(id, "trou")
		boulder_holes.append(int(hole) if not hole.is_empty() else 0)
	var hole_cells: Array[Vector2i] = []
	var hole_numbers: Array[int] = []
	var hole_flags: Array[StringName] = []
	for id: String in _ids(plan, "trou"):
		var cell: Vector2i = plan.cell_of(id)
		var number := int(plan.attr(id, "n"))
		var flag := StringName(plan.attr(id, "drapeau"))
		hole_cells.append(cell)
		hole_numbers.append(number)
		hole_flags.append(flag)
		var unless: Array[StringName] = [flag]
		_warp(root, "Trou%d" % number, cell, FALL, Vector2i.ZERO,
			StringName(plan.attr(id, "chute")), StringName("chute_%s_%d" % [map_id, number]),
			Vector2i.DOWN, unless)
		var open := _gate(root, entities, "TrouOuvert%d" % number, cell, [], [flag])
		_rect(root, open, Rect2(-40, -88, 80, 80), Color(0.05, 0.06, 0.1))
		_rect(root, open, Rect2(-28, -76, 56, 56), Color(0.0, 0.0, 0.02))
		var filled := _gate(root, entities, "TrouBouche%d" % number, cell, [flag], [])
		_rect(root, filled, Rect2(-44, -92, 88, 88), Color(0.52, 0.58, 0.64))
		_rect(root, filled, Rect2(-28, -76, 56, 56), Color(0.66, 0.72, 0.78))
	var no_push: Array[Vector2i] = []
	for id: String in _ids(plan, "objet_cache"):
		no_push.append(plan.cell_of(id))
	setup.set(&"boulder_cells", boulder_cells)
	setup.set(&"boulder_holes", boulder_holes)
	setup.set(&"hole_cells", hole_cells)
	setup.set(&"hole_numbers", hole_numbers)
	setup.set(&"hole_flags", hole_flags)
	setup.set(&"no_push_cells", no_push)
	_attach(root, root, setup)
	for id: String in _ids(plan, "chute_rocher"):
		var cell: Vector2i = plan.cell_of(id)
		if not water_falls.has(cell):
			continue
		var origin: String = plan.attr(id, "depuis")
		var flag := StringName("%s_hole_%s_filled" % [origin.get_slice(":", 0),
			origin.get_slice(":", 1)])
		var rock := _gate(root, entities, "RocherTombe_%d_%d" % [cell.x, cell.y], cell, [flag], [])
		var blocking: Array[Vector2i] = [cell]
		rock.set(&"blocking_cells", blocking)
		_boulder(root, rock)


## Échelle provisoire (bois ; plus claire si elle monte).
func _ladder(root: Node, entities: Node, cell: Vector2i, up: bool) -> void:
	var ladder := _gate(root, entities, "EchelleDessin_%d_%d" % [cell.x, cell.y], cell, [], [])
	var wood := Color(0.62, 0.46, 0.26) if up else Color(0.4, 0.28, 0.16)
	_rect(root, ladder, Rect2(-30, -88, 60, 80), wood)
	for y: int in [-80, -56, -32]:
		_rect(root, ladder, Rect2(-22, y, 44, 8), wood.darkened(0.45))


## Panneau : décor bloquant + point d'examen.
func _add_sign(root: Node, entities: Node, cell: Vector2i, text_id: StringName) -> void:
	var gate := _gate(root, entities, "Panneau_%d_%d" % [cell.x, cell.y], cell, [], [])
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-6, -60, 12, 56), Color(0.4, 0.28, 0.14))
	_rect(root, gate, Rect2(-34, -90, 68, 40), Color(0.72, 0.56, 0.32))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "PanneauPoint_%d_%d" % [cell.x, cell.y]
	point.position = _world(cell)
	point.set(&"dialogue_id", text_id)
	_attach(root, root.get_node(^"Interactables"), point)


## Objet caché : point d'examen jusqu'au drapeau `got_<dialogue>`.
func _hidden(root: Node, cell: Vector2i, dialogue_id: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "Cache_%d_%d" % [cell.x, cell.y]
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue_id)
	var unless: Array[StringName] = [StringName("got_" + String(dialogue_id))]
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Interactables"), point)


## Identifiants des positions de type [param kind], dans l'ordre du fichier.
func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array,
		unless: Array) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	var typed_if: Array[StringName] = []
	typed_if.assign(if_flags)
	var typed_unless: Array[StringName] = []
	typed_unless.assign(unless)
	gate.set(&"if_flags", typed_if)
	gate.set(&"unless_flags", typed_unless)
	_attach(root, parent, gate)
	return gate


## Rocher tombé : même dessin que [Boulder].
func _boulder(root: Node, parent: Node) -> void:
	var r: float = Boulder.RADIUS
	var body := Vector2(0.0, -r - 2.0)
	_disc(root, parent, Vector2(0.0, -4.0), Boulder.SHADOW_SIZE, Boulder.COLOR_SHADOW)
	_disc(root, parent, body, Vector2(r, r), Boulder.COLOR_BODY)
	_disc(root, parent, body + Vector2(-8.0, -10.0), Vector2(r, r) * 0.7, Boulder.COLOR_LIGHT)
	_disc(root, parent, body + Vector2(-14.0, -16.0), Vector2(r, r) * 0.35,
		Boulder.COLOR_LIGHT.lightened(0.12))


func _disc(root: Node, parent: Node, center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 32:
		var angle := TAU * i / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = points
	_attach(root, parent, poly)


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_j24_seafoam : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String,
		size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", LIGHTS[String(map_id)])
	var tileset: TileSet = load(_over.TILESET_PATH)
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
		target: StringName, spawn: StringName, facing: Vector2i, unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Warps"), point)


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
