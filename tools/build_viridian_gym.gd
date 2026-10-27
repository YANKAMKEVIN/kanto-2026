extends SceneTree
## Construit game/world/maps/viridian_gym.tscn (l'Arène de Jadielle, 24 × 22 cases) d'après la
## grille `tools/plans/jadielle_arene.txt` (jalon 28 T6, docs/tech/jalon-28.md §2.1). Géométrie
## Rouge/Bleu 1:1 décalée de (+2, +2) ; dalles : nœud `SpinTiles` (moteur du J20, §2.4.2 de
## jalon-20.md, aucun code nouveau). Giovanni, Dresseurs, guide et objet viennent des données
## (`data/npcs/viridian_gym.json`) ; leurs cases sont libres dans la grille.
##
##   godot --headless --path . -s res://tools/build_viridian_gym.gd   (code 2 : masque écrit,
##   godot --headless --path . --import                              importer puis relancer)
##
## - Art en modules (lot DAF.4, `tools/art/daf3.py`) sur `tools/cave_map_kit.gd`, comme le repaire :
##   dalles de grès peintes, masse sombre, murs `relief_mur_jadielle_*` (rôles de la Tour,
##   `tools/module_walls.gd`, maçonnerie `K`), flèches et disques d'arrêt du repaire au sol
##   (décalcomanies d'une case, même moteur de dalles), paillasson sur la sortie ; couches logiques
##   du kit retirées, collision = `blocked_cells`.
## - Passages : sortie (18..19, 20) PUSH ↓ → `viridian_city` / `from_gym` ; spawn `entrance` (18, 20).

const PLAN_PATH: String = "res://tools/plans/jadielle_arene.txt"
const OUT_PATH: String = "res://game/world/maps/viridian_gym.tscn"
const MASK_PATH: String = "res://assets/world/maps/viridian_gym_ground.png"
const GROUND_FLOOR: String = "res://assets/world/ground/ground_dalles_jadielle_01.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_batiment_01.png"
## Frontière : le grès un peu assombri [D].
const BORDER_COLOR := Color(0.60, 0.49, 0.38)
const WALL_MARK: String = "K"
const WALL_PREFIX: String = "relief_mur_jadielle"
const SEEDS: Array[int] = [2801, 2802, 2803]
const ARROW_DECALS: Dictionary[String, String] = {
	"<": "decal_fleche_repaire_01_gauche", ">": "decal_fleche_repaire_01",
	"^": "decal_fleche_repaire_01_haut", "v": "decal_fleche_repaire_01_bas",
}
const STOP_DECAL: String = "decal_arret_repaire_01"
const DOORMAT: String = "int_paillasson_sylphe_01"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
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
	var kit: Object = Kit.new(PLAN_PATH, SIZE, SEEDS[0], SEEDS[1], _plan.walkable)
	kit.set(&"floor_texture_path", GROUND_FLOOR)
	kit.set(&"rubble_texture_path", GROUND_FLOOR)
	kit.set(&"mass_texture_path", GROUND_MASS)
	kit.set(&"border_color", BORDER_COLOR)
	kit.set(&"rubble_mark", "~")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", WALL_MARK)
	kit.set(&"mass_mark", WALL_MARK)
	_root = kit.call(&"make_root", "ViridianGym", MAP_ID, DISPLAY_NAME, LIGHT_PROFILE)
	_root.set(&"interior", true)
	if not kit.call(&"add_ground", MASK_PATH):
		var errors: PackedStringArray = kit.get(&"errors")
		kit.call(&"discard")
		if errors.is_empty():
			print("build_viridian_gym : masque écrit ; importer (--import) puis relancer")
			quit(2)
		else:
			push_error("build_viridian_gym :\n%s" % "\n".join(errors))
			quit(1)
		return
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := _root.get_node(layer_name)
		_root.remove_child(layer)
		layer.free()
	ModuleWalls.new(kit, WALL_PREFIX, WALL_MARK, WALL_MARK, SEEDS[2]).place()
	for character: String in ARROW_DECALS:
		for cell: Vector2i in _plan.cells_of(character):
			kit.call(&"add_floor_prop", ARROW_DECALS[character], cell, "Arrow%02d_%02d" % [cell.x, cell.y])
	for cell: Vector2i in _plan.cells_of("o"):
		kit.call(&"add_floor_prop", STOP_DECAL, cell, "Stop%02d_%02d" % [cell.x, cell.y])
	kit.call(&"add_floor_prop", DOORMAT, EXIT_CELLS[1], "Doormat")
	if not (kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_viridian_gym :\n%s" % "\n".join(kit.get(&"errors")))
		_root.free()
		quit(1)
		return
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
