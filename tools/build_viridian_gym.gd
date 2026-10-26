extends SceneTree
## Construit game/world/maps/viridian_gym.tscn (l'Arène de Jadielle, 24 × 22 cases) d'après la
## grille `tools/plans/jadielle_arene.txt` (jalon 28 T6, docs/tech/jalon-28.md §2.1). Géométrie
## Rouge/Bleu 1:1 décalée de (+2, +2) ; dalles : nœud `SpinTiles` (moteur du J20, §2.4.2 de
## jalon-20.md, aucun code nouveau). Giovanni, Dresseurs, guide et objet viennent des données
## (`data/npcs/viridian_gym.json`) ; leurs cases sont libres dans la grille.
##
##   python3 tools/art/placeholders_j28.py      (enveloppe provisoire)
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_viridian_gym.gd
##
## - Art : enveloppe PROVISOIRE cuite d'après la grille (`ph_viridian_gym.png` : murs, sol,
##   flèches, disques d'arrêt) ; le lot d'art du J28 la remplacera (mêmes dimensions).
## - Passages : sortie (18..19, 20) PUSH ↓ → `viridian_city` / `from_gym` ; spawn `entrance` (18, 20).

const PLAN_PATH: String = "res://tools/plans/jadielle_arene.txt"
const OUT_PATH: String = "res://game/world/maps/viridian_gym.tscn"
const SHELL_PATH: String = "res://assets/world/interiors/placeholder/ph_viridian_gym.png"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const TILE: int = 96
const SIZE := Vector2i(24, 22)
const MAP_ID: StringName = &"viridian_gym"
const DISPLAY_NAME: String = "Jadielle"
const LIGHT_PROFILE: StringName = &"interior_warm"
const PUSH: int = 1
const EXIT_CELLS: Array[Vector2i] = [Vector2i(18, 20), Vector2i(19, 20)]
const ENTRANCE := Vector2i(18, 20)
## Départ de débogage `viridian_gym_giovanni` : devant Giovanni (case pour lui parler).
const BEFORE_GIOVANNI := Vector2i(4, 4)
const ARROWS: Dictionary[String, Vector2i] = {
	">": Vector2i.RIGHT, "<": Vector2i.LEFT, "^": Vector2i.UP, "v": Vector2i.DOWN,
}

var _root: Node2D
var _plan := PlanGrid.new()


func _init() -> void:
	if not _plan.load_file(PLAN_PATH) or Vector2i(_plan.width, _plan.height) != SIZE:
		push_error("build_viridian_gym : grille illisible (%s)" % _plan.error)
		quit(1)
		return
	_root = Node2D.new()
	_root.name = "ViridianGym"
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", MAP_ID)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", SIZE)
	_root.set(&"interior", true)
	_root.set(&"light_profile", LIGHT_PROFILE)
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(SHELL_PATH)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture == null or shell.texture.get_size() != Vector2(SIZE * TILE):
		push_error("build_viridian_gym : enveloppe absente ou ≠ %s cases" % SIZE)
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
	_add_passages()
	_add_spin_tiles()
	var blocked: Array[Vector2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if not _plan.is_walkable(cell):
				blocked.append(cell)
	_root.set(&"blocked_cells", blocked)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("viridian_gym : %s (%d cases bloquées)" % [error_string(err), blocked.size()])
	_root.free()
	quit(0 if err == OK else 1)


func _add_passages() -> void:
	var spawn := Marker2D.new()
	spawn.name = "entrance"
	spawn.position = _world(ENTRANCE)
	_attach(_root.get_node(^"Spawns"), spawn)
	var before := Marker2D.new()
	before.name = "before_giovanni"
	before.position = _world(BEFORE_GIOVANNI)
	_attach(_root.get_node(^"Spawns"), before)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for index: int in EXIT_CELLS.size():
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "Exit%d" % index
		point.position = _world(EXIT_CELLS[index])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", &"viridian_city")
		point.set(&"target_spawn", &"from_gym")
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(_root.get_node(^"Warps"), point)


## `SpinTiles` (jalon-20.md §2.4.2) : flèches et cases d'arrêt de la grille, enfant direct de la
## racine, dictionnaire et tableau typés.
func _add_spin_tiles() -> void:
	var field := Node2D.new()
	field.set_script(load("res://game/world/spin/spin_tile_field.gd"))
	field.name = "SpinTiles"
	var arrows: Dictionary[Vector2i, Vector2i] = {}
	for character: String in ARROWS:
		for cell: Vector2i in _plan.cells_of(character):
			arrows[cell] = ARROWS[character]
	var stops: Array[Vector2i] = []
	stops.assign(_plan.cells_of("o"))
	field.set(&"arrows", arrows)
	field.set(&"stops", stops)
	_attach(_root, field)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
