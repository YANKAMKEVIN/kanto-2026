extends SceneTree
## Construit les quatre niveaux du Manoir Pokémon (jalon 25, T14 ; dossier 28 §4 ; `jalon-25.md`
## §2.1, §2.2, §2.7), en tuiles provisoires (`OverworldTiles`), d'après les grilles
## `tools/plans/manoir_1f.txt` … `manoir_b1f.txt` (la grille fait foi ; contrôle
## `tools/art/plan_check_manoir.py`, anti-blocage des grilles compris). L'art de la série 28 (kit
## modulaire) n'est pas encore intégré : aplats provisoires.
##
## Par niveau :
##   - sol : mur et mobilier `# T P` (falaise), plancher (planches ; carrelage au B1F) ;
##   - grilles `a` / `b` : un [FlagGate] bloquant par case (jeu A fermé sans `mansion_switch_on`,
##     jeu B fermé avec), et le rail au sol de la grille ouverte ;
##   - statues `T` : décor bloquant + point d'examen `mansion_statue` (face à elle, depuis la case
##     du dessous) : OUI → scène `mansion_switch` (étape « toggle ») ;
##   - journaux `P` : décor bloquant + point d'examen `mansion_journal_<n>` (relisibles) ;
##   - escaliers `U V` : [WarpPoint] STEP_ON vers le spawn `arrivee_<paire>` de l'autre niveau ;
##   - trous `O` (3F) : [WarpPoint] FALL du J24 vers le spawn `chute` du niveau du dessous ;
##   - seuils `E` (1F) : [WarpPoint] PUSH ↓ vers `cinnabar_island` / `from_manoir` ;
##   - objets cachés : point d'examen jusqu'au drapeau `got_<id>`.
## La remise de l'interrupteur à ARRÊT se fait sur Cramois'Île ([MansionSwitchReset]). Dresseurs
## et objets visibles : `data/npcs/pokemon_mansion_<niveau>.json` (`tools/gen_j25_world_data.py`).
##
##   godot --headless --path . -s res://tools/build_pokemon_mansion.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
## Carte → grille.
const FLOORS: Dictionary = {"pokemon_mansion_1f": "manoir_1f", "pokemon_mansion_2f": "manoir_2f",
	"pokemon_mansion_3f": "manoir_3f", "pokemon_mansion_b1f": "manoir_b1f"}
const STEP_ON: int = 0
const PUSH: int = 1
const FALL: int = 2
const SWITCH_FLAG: StringName = &"mansion_switch_on"
const SOLID_CHARS: String = "#TP"
## Lumière (`data/world/lighting.json`) : profil de la Tour Pokémon [D].
const LIGHT: StringName = &"tower"
const COLOR_GATE := Color(0.2, 0.2, 0.24)
const COLOR_BAR := Color(0.55, 0.56, 0.6)
const COLOR_RAIL := Color(0.3, 0.28, 0.26)

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 2525
	for map_id: String in FLOORS:
		_build_floor(map_id)
	print("build_pokemon_mansion : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build_floor(map_id: String) -> void:
	var plan := _plan(FLOORS[map_id])
	var size := Vector2i(plan.width, plan.height)
	var node_name := "PokemonMansion" + map_id.trim_prefix("pokemon_mansion_").to_upper()
	var root := _new_map(node_name, StringName(map_id), "Manoir Pokémon", size)
	var entities: Node = root.get_node(^"Entities")
	_paint(root, plan, map_id == "pokemon_mansion_b1f")
	# Grilles A / B.
	for cell: Vector2i in plan.cells_of("a"):
		_switch_gate(root, entities, cell, "a")
	for cell: Vector2i in plan.cells_of("b"):
		_switch_gate(root, entities, cell, "b")
	# Spawns.
	for id: String in _ids(plan, "spawn"):
		_spawn(root, id, plan.cell_of(id))
	# Escaliers.
	for id: String in _ids(plan, "escalier"):
		var cell: Vector2i = plan.cell_of(id)
		var pair: String = plan.attr(id, "paire").to_lower()
		_warp(root, "Escalier_" + pair, cell, STEP_ON, Vector2i.ZERO,
			StringName(plan.attr(id, "vers")), StringName("arrivee_" + pair), Vector2i.DOWN, [])
		_stairs(root, entities, cell, plan.attr(id, "sens") == "monte")
	# Trous (Warp FALL du J24, jamais bouchés).
	for id: String in _ids(plan, "trou"):
		var cell: Vector2i = plan.cell_of(id)
		_warp(root, "Trou_" + id.trim_prefix("trou_"), cell, FALL, Vector2i.ZERO,
			StringName(plan.attr(id, "vers")), StringName(plan.attr(id, "arrivee")),
			Vector2i.DOWN, [])
		var hole := _gate(root, entities, "TrouDessin_%d_%d" % [cell.x, cell.y], cell, [], [])
		_rect(root, hole, Rect2(-44, -90, 88, 84), Color(0.08, 0.06, 0.05))
		_rect(root, hole, Rect2(-32, -78, 64, 60), Color(0.0, 0.0, 0.0))
	# Sorties vers Cramois'Île (porte principale, petite porte sud-est).
	for id: String in _ids(plan, "warp"):
		var index := 0
		for cell: Vector2i in plan.cells_at(id):
			index += 1
			_warp(root, "%s_%d" % [id.to_pascal_case(), index], cell, PUSH, Vector2i.DOWN,
				StringName(plan.attr(id, "vers")), &"from_manoir", Vector2i.DOWN, [])
	# Statues (interrupteur), journaux.
	for id: String in _ids(plan, "statue"):
		_statue(root, entities, plan.cell_of(id))
	for id: String in _ids(plan, "journal"):
		_journal(root, entities, plan.cell_of(id), "mansion_" + id)
	# Objets cachés.
	for id: String in _ids(plan, "objet_cache"):
		_hidden(root, plan.cell_of(id), StringName(id))
	_save(root, MAPS_DIR + map_id + ".tscn")


func _paint(root: Node, plan: Object, basement: bool) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var kind: int = _over.Kind.COBBLE if basement else _over.Kind.BOARDWALK
			if SOLID_CHARS.contains(plan.at(cell)):
				kind = _over.Kind.CLIFF
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Une case de grille : fermée (barreaux, bloquante) selon l'interrupteur, rail au sol sinon.
func _switch_gate(root: Node, entities: Node, cell: Vector2i, gate_set: String) -> void:
	var on: Array = [SWITCH_FLAG]
	var closed_if: Array = [] if gate_set == "a" else on
	var closed_unless: Array = on if gate_set == "a" else []
	var closed := _gate(root, entities, "Grille%s_%d_%d" % [gate_set.to_upper(), cell.x, cell.y],
		cell, closed_if, closed_unless)
	var blocking: Array[Vector2i] = [cell]
	closed.set(&"blocking_cells", blocking)
	_rect(root, closed, Rect2(-46, -100, 92, 10), COLOR_GATE)
	for x: int in [-38, -18, 2, 22]:
		_rect(root, closed, Rect2(x, -96, 10, 92), COLOR_BAR)
	var open := _gate(root, entities, "Rail%s_%d_%d" % [gate_set.to_upper(), cell.x, cell.y],
		cell, closed_unless, closed_if)
	_rect(root, open, Rect2(-46, -10, 92, 6), COLOR_RAIL)


## Statue à interrupteur : décor bloquant, point d'examen lu face à elle (depuis le dessous).
func _statue(root: Node, entities: Node, cell: Vector2i) -> void:
	var gate := _gate(root, entities, "Statue_%d_%d" % [cell.x, cell.y], cell, [], [])
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-36, -30, 72, 26), Color(0.5, 0.5, 0.52))
	_rect(root, gate, Rect2(-24, -100, 48, 72), Color(0.86, 0.86, 0.84))
	_rect(root, gate, Rect2(-14, -116, 28, 20), Color(0.86, 0.86, 0.84))
	var point := _point(root, "StatuePoint_%d_%d" % [cell.x, cell.y], cell, &"mansion_statue")
	point.set(&"facing", Vector2i.UP)


## Pupitre et carnet : décor bloquant, point d'examen relisible.
func _journal(root: Node, entities: Node, cell: Vector2i, dialogue_id: String) -> void:
	var gate := _gate(root, entities, "Pupitre_%d_%d" % [cell.x, cell.y], cell, [], [])
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_rect(root, gate, Rect2(-30, -60, 60, 56), Color(0.36, 0.22, 0.12))
	_rect(root, gate, Rect2(-26, -74, 52, 18), Color(0.9, 0.86, 0.72))
	_point(root, "PupitrePoint_%d_%d" % [cell.x, cell.y], cell, StringName(dialogue_id))


## Escalier provisoire (plus clair s'il monte).
func _stairs(root: Node, entities: Node, cell: Vector2i, up: bool) -> void:
	var gate := _gate(root, entities, "EscalierDessin_%d_%d" % [cell.x, cell.y], cell, [], [])
	var wood := Color(0.66, 0.5, 0.3) if up else Color(0.3, 0.2, 0.12)
	_rect(root, gate, Rect2(-44, -92, 88, 86), wood)
	for y: int in [-80, -60, -40, -20]:
		_rect(root, gate, Rect2(-44, y, 88, 6), wood.darkened(0.4))


func _point(root: Node, point_name: String, cell: Vector2i, dialogue_id: StringName) -> Marker2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = point_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue_id)
	_attach(root, root.get_node(^"Interactables"), point)
	return point


func _hidden(root: Node, cell: Vector2i, dialogue_id: StringName) -> void:
	var point := _point(root, "Cache_%d_%d" % [cell.x, cell.y], cell, dialogue_id)
	var unless: Array[StringName] = [StringName("got_" + String(dialogue_id))]
	point.set(&"unless_flags", unless)


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
		push_error("build_pokemon_mansion : %s" % plan.error)
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
	root.set(&"interior", false) # grotte au sens de `data/world/caves.json` (Corde Sortie)
	root.set(&"light_profile", LIGHT)
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
