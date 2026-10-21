extends SceneTree
## Construit game/world/maps/celadon_gym.tscn (l'Arène d'Erika, 17 × 16 cases) d'après la grille
## fonctionnelle `tools/plans/celadopole_arene.txt` (jalon 20 T16, docs/tech/jalon-20.md §2.1,
## §2.8 ; dossier 23 §11). **Géométrie seulement** : Erika, les cinq Dresseuses, leurs scènes et le
## « parler à Erika » viennent au T17 ; leurs cases (`bloque`) sont libres dans la grille.
##
##   godot --headless --path . -s res://tools/build_celadon_gym.gd
##   godot --headless --path . --import
##
## **La grille fait foi** : serre élégante, de bas en haut l'entrée (un bassin au coin sud-ouest),
## un premier lacet de haies (ouvert à l'est seulement), le couloir, un second lacet (ouvert à
## l'ouest seulement), le vestibule et la serre d'Erika fermée par une haie dont l'unique ouverture
## est la porte-haie (8, 4) ; bassins de part et d'autre d'Erika.
## - Le tour (sans Coupe) mène à Erika en une trentaine de pas ; le **second arbuste** (8, 10)
##   ouvre un raccourci facultatif (contrat du J16 : [FlagGate] `unless cut_celadon_gym_inner_bush`
##   dont les cases sont occupées tant qu'il est debout ; case praticable dans `Ground`).
## - **Art** : coque peinte de la série 22 bis (`int_celadon_gym_coque`, serre : bassins, sol, murs,
##   verrière) ; haies et massifs = objets peints existants (Lavanville).
## - Lumière `greenhouse` (nouveau profil : vert filtré par la verrière, sans ombre portée).
## - Passages : sortie (7..9, 14) PUSH ↓ → `celadon_city` / `from_gym_w|e`.

const PLAN_PATH: String = "res://tools/plans/celadopole_arene.txt"
const OUT_PATH: String = "res://game/world/maps/celadon_gym.tscn"
const SHELL_PATH: String = "res://assets/world/interiors/int_celadon_gym_coque.png"
const PROPS_DIR: String = "res://game/world/props/painted/"
const RULES_SCRIPT: String = "res://game/world/props/painted_prop_rules.gd"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const SIZE := Vector2i(17, 16)
const MAP_ID: StringName = &"celadon_gym"
const DISPLAY_NAME: String = "Céladopole"
const WALKABLE: String = ".XW"
const PUSH: int = 1
const STEP_ON: int = 0
const EXIT_CELLS: Array[Vector2i] = [Vector2i(7, 14), Vector2i(8, 14), Vector2i(9, 14)]
const EXIT_SPAWNS: Array[StringName] = [&"from_gym_w", &"from_gym_w", &"from_gym_e"]
const ENTRANCE := Vector2i(8, 14)
## Arbuste du raccourci (contrat du J16) : drapeau, décor, dialogue de Coupe (T17 : scène).
const BUSH_CELL := Vector2i(8, 10)
const BUSH_FLAG: StringName = &"cut_celadon_gym_inner_bush"
const BUSH_ID: String = "prop_jeune_arbre_arene_01"
const BUSH_SCALE: float = 0.7
const BUSH_DIALOGUE: StringName = &"celadon_gym_inner_bush"
const HEDGE_PAIR: String = "prop_haie_taillee_01"
const HEDGE_SINGLE: String = "prop_buis_taille_01"
const MASS_ID: String = "prop_buis_taille_02"

var _root: Node2D
var _rules: GDScript
var _scenes: Dictionary = {}
var _plan := PlanGrid.new()
var _covered: Dictionary = {}


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	if not _plan.load_file(PLAN_PATH) or Vector2i(_plan.width, _plan.height) != SIZE:
		push_error("build_celadon_gym : grille illisible (%s)" % _plan.error)
		quit(1)
		return
	_root = Node2D.new()
	_root.name = "CeladonGym"
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", MAP_ID)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", SIZE)
	_root.set(&"interior", true)
	_root.set(&"light_profile", &"greenhouse")
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(SHELL_PATH)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture.get_size() != Vector2(SIZE * TILE):
		push_error("build_celadon_gym : enveloppe %s ≠ %s cases" % [shell.texture.get_size(), SIZE])
		quit(1)
		return
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
	_place_hedges(entities)
	_place_masses(entities)
	_place_inner_bush(entities)
	_add_passages()
	_add_interactions()
	var blocked: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if not WALKABLE.contains(_plan.at(cell)) and not _covered.has(cell):
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("celadon_gym : %s (%d cases bloquées par la grille, %d nœuds)" % [error_string(err),
		blocked.size(), _count(_root)])
	_root.free()
	quit(0 if err == OK else 1)


## Haies `x` : modules de deux cases d'abord, une case isolée en buis ; chaque suite horizontale
## est couverte case par case, de gauche à droite.
func _place_hedges(entities: Node2D) -> void:
	var index := 0
	for y: int in SIZE.y:
		var x := 0
		while x < SIZE.x:
			if _plan.at(Vector2i(x, y)) != "x":
				x += 1
				continue
			var run := 0
			while _plan.at(Vector2i(x + run, y)) == "x":
				run += 1
			var at := 0
			while at < run:
				if run - at >= 2:
					_add_prop(entities, HEDGE_PAIR, Vector2i(x + at + 1, y), "Hedge%02d" % index)
					at += 2
				else:
					_add_prop(entities, HEDGE_SINGLE, Vector2i(x + at, y), "Hedge%02d" % index)
					at += 1
				index += 1
			x += run


## Massifs `j` (une case).
func _place_masses(entities: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan.cells_of("j"):
		_add_prop(entities, MASS_ID, cell, "Mass%02d" % index)
		index += 1


func _add_prop(parent: Node, id: String, anchor: Vector2i, node_name: String) -> Node2D:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + id + ".tscn")
	var prop := (_scenes[id] as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = (_rules.call(&"foot_position", StringName(id), anchor) as Vector2).round()
	for offset: Vector2i in _rules.call(&"footprint", StringName(id)):
		var cell := anchor + offset
		if WALKABLE.contains(_plan.at(cell)):
			push_error("%s (%s) : emprise sur la case praticable %s" % [node_name, id, cell])
			quit(1)
		_covered[cell] = true
	_attach(parent, prop)
	return prop


## Second arbuste (8, 10) : [FlagGate] occupant la case tant que `cut_celadon_gym_inner_bush`
## n'est pas levé ; le décor est le jeune arbre des arbustes du J16 (sans emprise).
func _place_inner_bush(entities: Node2D) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "GymInnerBush"
	gate.position = Vector2((BUSH_CELL.x + 0.5) * TILE, (BUSH_CELL.y + 1) * TILE).round()
	var unless: Array[StringName] = [BUSH_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = [BUSH_CELL]
	gate.set(&"blocking_cells", blocking)
	_attach(entities, gate)
	if not _scenes.has(BUSH_ID):
		_scenes[BUSH_ID] = load(PROPS_DIR + BUSH_ID + ".tscn")
	var tree := (_scenes[BUSH_ID] as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	tree.name = "Bush"
	tree.scale = Vector2(BUSH_SCALE, BUSH_SCALE)
	tree.set(&"footprint", [] as Array[Vector2i])
	_attach(gate, tree)


func _add_passages() -> void:
	var spawn := Marker2D.new()
	spawn.name = "entrance"
	spawn.position = _world(ENTRANCE)
	_attach(_root.get_node(^"Spawns"), spawn)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for index: int in EXIT_CELLS.size():
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "Exit%d" % index
		point.position = _world(EXIT_CELLS[index])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", &"celadon_city")
		point.set(&"target_spawn", EXIT_SPAWNS[index])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(_root.get_node(^"Warps"), point)


## Point d'examen de l'arbuste intérieur (retiré avec lui).
func _add_interactions() -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = "GymInnerBushExamine"
	point.position = _world(BUSH_CELL)
	point.set(&"dialogue_id", BUSH_DIALOGUE)
	var unless: Array[StringName] = [BUSH_FLAG]
	point.set(&"unless_flags", unless)
	_attach(_root.get_node(^"Interactables"), point)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
