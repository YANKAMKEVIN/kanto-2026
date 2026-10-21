extends SceneTree
## Construit les cartes de QA de la Force (passe systèmes 2, `systemes-2.md` §2.7, §2.14, T17-T22),
## en tuiles provisoires (`OverworldTiles`), sans lumière, d'après les grilles
## `tools/plans/qa_strength.txt` et `qa_strength_b1.txt` (la grille fait foi) :
##   - `qa_strength` (24 × 16) : couloirs et salles à rochers, deux trous (chute du joueur vers
##     `qa_strength_b1`), un interrupteur + barrière, une case interdite, de l'eau décor, un panneau ;
##   - `qa_strength_b1` (12 × 8) : arrivée des chutes (spawns `chute_joueur_N`), rochers tombés
##     (dessin + case bloquée une fois le trou bouché), échelle vers `qa_strength:from_b1`.
## Les rochers eux-mêmes ne sont PAS dessinés ici : le moteur les instancie depuis le nœud
## `Boulders` ([BoulderSetup]). Ici : sol, dessins de trous, d'interrupteur, de barrière (FlagGate,
## placeholders Polygon2D), WarpPoint FALL.
##
##   godot --headless --path . -s res://tools/build_qa_strength.gd
##   godot --headless --path . --import
##
## Cartes **inaccessibles en jeu** : départ de débogage `s2_strength` seulement. **Retirées à la
## clôture de la passe (S2Z)** avec leurs données `qa_strength*` et ce script.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
const FALL: int = 2
const SIGN_DIALOGUE: StringName = &"qa_strength_sign"

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2907
	_build_upper()
	_build_lower()
	print("build_qa_strength : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_upper() -> void:
	var plan := _plan("qa_strength")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaStrength", &"qa_strength", "QA Force", size, false)
	_paint(root, plan, {"#": "CLIFF", "w": "WATER", ".": "GRASS"}, "GRASS")
	_spawn(root, "depart", plan.cell_of("depart"))
	_spawn(root, "from_b1", plan.cell_of("from_b1"))
	for id: String in ["sortie_o", "sortie_e"]:
		_warp(root, id.capitalize().replace("_", ""), plan.cell_of(id), PUSH, Vector2i.DOWN,
			&"qa_mount", &"depart", Vector2i.DOWN, [])
	var setup := Node.new()
	setup.set_script(load("res://game/world/boulders/boulder_setup.gd"))
	setup.name = "Boulders"
	var boulder_cells: Array[Vector2i] = []
	var boulder_holes: Array[int] = []
	var hole_cells: Array[Vector2i] = []
	var hole_numbers: Array[int] = []
	var hole_flags: Array[StringName] = []
	var switch_cells: Array[Vector2i] = []
	var switch_ids: Array[StringName] = []
	var switch_flags: Array[StringName] = []
	var no_push: Array[Vector2i] = []
	var entities: Node = root.get_node(^"Entities")
	for id: String in _ids(plan, "rocher"):
		boulder_cells.append(plan.cell_of(id))
		boulder_holes.append(int(plan.attr(id, "trou")))
	for id: String in _ids(plan, "trou"):
		var cell: Vector2i = plan.cell_of(id)
		var number: int = int(plan.attr(id, "n"))
		var flag: StringName = StringName(plan.attr(id, "drapeau"))
		hole_cells.append(cell)
		hole_numbers.append(number)
		hole_flags.append(flag)
		_warp(root, "Trou%d" % number, cell, FALL, Vector2i.ZERO,
			StringName(plan.attr(id, "chute")), StringName("chute_joueur_%d" % number),
			Vector2i.DOWN, [flag])
		var open := _gate(root, entities, "TrouOuvert%d" % number, cell, [], [flag])
		_rect(root, open, Rect2(-40, -88, 80, 80), Color(0.05, 0.04, 0.06))
		_rect(root, open, Rect2(-28, -76, 56, 56), Color(0.0, 0.0, 0.0))
		var filled := _gate(root, entities, "TrouBouche%d" % number, cell, [flag], [])
		_rect(root, filled, Rect2(-44, -92, 88, 88), Color(0.42, 0.40, 0.36))
		_rect(root, filled, Rect2(-28, -76, 56, 56), Color(0.58, 0.56, 0.5))
	for id: String in _ids(plan, "interrupteur"):
		var cell: Vector2i = plan.cell_of(id)
		var flag: StringName = StringName(plan.attr(id, "drapeau"))
		switch_cells.append(cell)
		switch_ids.append(StringName(id))
		switch_flags.append(flag)
		var raised := _gate(root, entities, "InterrupteurReleve", cell, [], [flag])
		_rect(root, raised, Rect2(-34, -82, 68, 68), Color(0.85, 0.7, 0.2))
		var pressed := _gate(root, entities, "InterrupteurEnfonce", cell, [flag], [])
		_rect(root, pressed, Rect2(-34, -82, 68, 68), Color(0.4, 0.34, 0.12))
	for id: String in _ids(plan, "interdit_rocher"):
		no_push.append_array(plan.cells_at(id))
	for id: String in _ids(plan, "barriere"):
		var flag: StringName = StringName(plan.attr(id, "ouverte_si"))
		var gate := _gate(root, entities, "Barriere", plan.cells_at(id)[0], [], [flag])
		var cells: Array[Vector2i] = plan.cells_at(id)
		var blocking: Array[Vector2i] = []
		blocking.assign(cells)
		gate.set(&"blocking_cells", blocking)
		var span: int = cells[-1].x - cells[0].x + 1
		_rect(root, gate, Rect2(-44, -80, span * TILE - 8, 64), Color(0.55, 0.15, 0.15))
	setup.set(&"boulder_cells", boulder_cells)
	setup.set(&"boulder_holes", boulder_holes)
	setup.set(&"hole_cells", hole_cells)
	setup.set(&"hole_numbers", hole_numbers)
	setup.set(&"hole_flags", hole_flags)
	setup.set(&"switch_cells", switch_cells)
	setup.set(&"switch_ids", switch_ids)
	setup.set(&"switch_flags", switch_flags)
	setup.set(&"no_push_cells", no_push)
	_attach(root, root, setup)
	for id: String in _ids(plan, "panneau"):
		_add_sign(root, entities, plan.cell_of(id), StringName(plan.attr(id, "texte")))
	_save(root, MAPS_DIR + "qa_strength.tscn")


func _build_lower() -> void:
	var plan := _plan("qa_strength_b1")
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map("QaStrengthB1", &"qa_strength_b1", "QA Force B1", size, false)
	_paint(root, plan, {"#": "CLIFF"}, "DIRT")
	var entities: Node = root.get_node(^"Entities")
	for id: String in _ids(plan, "chute_joueur"):
		_spawn(root, id, plan.cell_of(id))
	_spawn(root, "from_strength", plan.cell_of("from_strength"))
	_warp(root, "Echelle", plan.cell_of("echelle_haut"), STEP_ON, Vector2i.UP, &"qa_strength",
		&"from_b1", Vector2i.DOWN, [])
	var ladder := _gate(root, entities, "EchelleDessin", plan.cell_of("echelle_haut"), [], [])
	_rect(root, ladder, Rect2(-30, -88, 60, 80), Color(0.55, 0.38, 0.2))
	_rect(root, ladder, Rect2(-22, -80, 44, 8), Color(0.3, 0.2, 0.1))
	_rect(root, ladder, Rect2(-22, -56, 44, 8), Color(0.3, 0.2, 0.1))
	_rect(root, ladder, Rect2(-22, -32, 44, 8), Color(0.3, 0.2, 0.1))
	for id: String in _ids(plan, "chute_rocher"):
		var origin: String = plan.attr(id, "depuis")
		var number := int(origin.get_slice(":", 1))
		var flag := StringName("qa_strength_hole_%d_filled" % number)
		var cell: Vector2i = plan.cell_of(id)
		var rock := _gate(root, entities, "RocherTombe%d" % number, cell, [flag], [])
		var blocking: Array[Vector2i] = [cell]
		rock.set(&"blocking_cells", blocking)
		_rect(root, rock, Rect2(-36, -84, 72, 72), Color(0.5, 0.46, 0.4))
		_rect(root, rock, Rect2(-26, -76, 40, 30), Color(0.66, 0.62, 0.56))
	_save(root, MAPS_DIR + "qa_strength_b1.tscn")


## Identifiants des positions de type [param kind], dans l'ordre du fichier (ordre du dictionnaire).
func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


## Sol : un type de tuile par caractère de la grille (défaut [param fallback]).
func _paint(root: Node, plan: Object, kinds: Dictionary, fallback: String) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind[kinds.get(plan.at(cell), fallback)]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Panneau : décor bloquant (toujours affiché) + point d'examen.
func _add_sign(root: Node, entities: Node, cell: Vector2i, text_id: StringName) -> void:
	var gate := _gate(root, entities, "Panneau", cell, [], [])
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-6, -60, 12, 56), Color(0.4, 0.28, 0.14))
	_rect(root, gate, Rect2(-34, -90, 68, 40), Color(0.72, 0.56, 0.32))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "PanneauPoint"
	point.position = _world(cell)
	point.set(&"dialogue_id", text_id)
	_attach(root, root.get_node(^"Interactables"), point)


## FlagGate de dessin posé sur la case [param cell] (origine = pied de la case).
func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array[StringName],
		unless: Array[StringName]) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless)
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


# --- Outils (modèle de build_qa_sea.gd) -------------------------------------------------------

func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		push_error("build_qa_strength : %s" % plan.error)
		_errors += 1
	return plan


func _new_map(node_name: String, map_id: StringName, display_name: String, size: Vector2i,
		interior: bool) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", "QA")
	root.set(&"size", size)
	root.set(&"interior", interior)
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
