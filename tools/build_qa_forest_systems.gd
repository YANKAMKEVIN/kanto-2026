extends SceneTree
## Construit game/world/maps/qa_forest_systems.tscn : la carte de QA du jalon 9 (jalon-09.md
## §2.6), 26 × 20 cases, tuiles provisoires (`OverworldTiles`), aucune lumière.
##
##   godot --headless --path . -s res://tools/build_qa_forest_systems.gd
##   godot --headless --path . --import
##
## Carte **inaccessible en jeu** (aucun warp n'y mène) : seulement par les départs de débogage
## `poison_qa`, `evolution_qa`, `trainers_qa`, `trainers_weak_qa`. Retirée à la clôture du J9.
##
## Plan (x, y en cases ; le nord est en haut) :
##
##   y 1..6   zone nord : clairière de Noé et Milo (x 7..14), Tom (x 15..19), Éli (x 22..24) ;
##   y 7..11  murs, sauf l'alcôve de Théo (16, 8..11) et la montée (8, 7..11) ;
##   y 12     COULOIR d'une case de large, de (24, 12) à (8, 12) : il croise la ligne de vue
##            de Théo en (16, 12) (obligatoire : aucun autre passage vers le nord) ;
##   y 13..14 murs, sauf la montée (24, 13..14) ;
##   y 15..18 zone sud : garde (11, 15), hautes herbes 5 × 4 (x 2..6), sortie (10..12, 18).
##
## Pourquoi un couloir **qui croise** la ligne de vue plutôt qu'un couloir dans l'axe : le
## Dresseur marche jusqu'à la case voisine du joueur (Rouge/Bleu). Dans l'axe d'un couloir d'une
## case, il s'arrêterait devant le joueur et fermerait le passage pour de bon ; de côté, il
## reste dans son alcôve.
##
## Cases **réservées** aux Dresseurs (posés au T12, `data/npcs/qa_forest_systems.json`) :
## [constant TRAINER_SLOTS] (jalon-09.md §6, T6). Le sol est déjà fait pour eux (bande d'herbes
## de contournement de Milo, arbre qui coupe sa vision).

const OUT_PATH: String = "res://game/world/maps/qa_forest_systems.tscn"
const SIZE := Vector2i(26, 20)
const TILE: int = 96

## Sortie sud : trois cases (PUSH vers le bas sur la bordure solide) vers Jadielle, devant
## le Centre (`from_center`, existant) : Centre et Boutique à deux pas.
const EXIT_ROW: int = 18
const EXIT_CELLS: Array[Vector2i] = [Vector2i(10, 18), Vector2i(11, 18), Vector2i(12, 18)]
const EXIT_TARGET: StringName = &"viridian_city"
const EXIT_SPAWN: StringName = &"from_center"
const PUSH: int = 1

## Points d'apparition (Marker2D de `Spawns`) des départs de débogage.
## `poison_start` : devant le garde (une case entre eux) ; `evolution_start` : au bord des
## hautes herbes, tourné vers elles ; `theo_corridor` : dans le couloir, 4 cases avant la ligne
## de vue de Théo.
const SPAWNS: Dictionary = {
	"poison_start": Vector2i(11, 16),
	"evolution_start": Vector2i(7, 17),
	"theo_corridor": Vector2i(20, 12),
}

## Zones (x, y, largeur, hauteur).
const SOUTH_ZONE := Rect2i(1, 15, 24, 4)
const NORTH_ZONE := Rect2i(1, 1, 24, 6)
const CORRIDOR := Rect2i(8, 12, 17, 1)
const RISE_EAST := Rect2i(24, 13, 1, 2)
const RISE_WEST := Rect2i(8, 7, 1, 5)
const THEO_ALCOVE := Rect2i(16, 8, 1, 4)
const START_GRASS := Rect2i(2, 15, 5, 4)
const FOREST_GRASS := Rect2i(10, 6, 3, 1)
const TREE_CELL := Vector2i(11, 5)
const DIRT_RECTS: Array[Rect2i] = [
	Rect2i(10, 16, 3, 3), Rect2i(8, 12, 17, 1), Rect2i(8, 7, 1, 5), Rect2i(24, 13, 1, 2),
	Rect2i(16, 8, 1, 4),
]

## Cases réservées aux Dresseurs [identifiant : case, orientation, vision] (T12). Les
## identifiants sont ceux de `data/trainers/viridian_forest.json` ; les visions, celles du §2.4.1.
## - Théo : dans l'alcôve, tourné vers le bas ; vue sur (16, 9..12), détectée en (16, 12) à 4
##   cases (3 libres entre eux).
## - Noé (7, 3) vers la droite : (8..12, 3) ; Milo (11, 1) vers le bas : (11, 2..4), coupée par
##   l'arbre (11, 5). Les deux lignes se croisent en (11, 3) (un seul défi à la fois). Milo est
##   contournable par la rangée 6 (herbes en (10..12, 6)), Noé aussi.
## - Tom (19, 4) vers la gauche : (15..18, 4) ; abordable de côté depuis (19, 3) ou (19, 5).
## - Éli (23, 1) vers le bas : (23, 2..6), au fond de la zone nord.
const TRAINER_SLOTS: Dictionary = {
	"forest_scout_theo": [Vector2i(16, 8), Vector2i.DOWN, 4],
	"forest_scout_noe": [Vector2i(7, 3), Vector2i.RIGHT, 5],
	"forest_scout_milo": [Vector2i(11, 1), Vector2i.DOWN, 5],
	"forest_youngster_tom": [Vector2i(19, 4), Vector2i.LEFT, 4],
	"forest_scout_eli": [Vector2i(23, 1), Vector2i.DOWN, 5],
}

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _kinds: Array = []


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 909
	var root := Node2D.new()
	root.name = "QaForestSystems"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"qa_forest_systems")
	root.set(&"display_name", "QA : Forêt (systèmes)")
	root.set(&"region", "QA")
	root.set(&"size", SIZE)

	_plan()
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	_paint(ground)
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
	_add_spawns(root)
	_add_warps(root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("qa_forest_systems : %s" % ("OK" if err == OK else "ERREUR %d" % err))
	root.free()
	quit(0 if err == OK else 1)


func _plan() -> void:
	_kinds.resize(SIZE.x * SIZE.y)
	_kinds.fill(_tiles.Kind["FOREST"])
	for rect: Rect2i in [SOUTH_ZONE, NORTH_ZONE, CORRIDOR, RISE_EAST, RISE_WEST, THEO_ALCOVE]:
		_fill(rect, "GRASS")
	for rect: Rect2i in DIRT_RECTS:
		_fill(rect, "DIRT")
	_fill(START_GRASS, "TALL_GRASS")
	_fill(FOREST_GRASS, "TALL_GRASS")
	_kinds[TREE_CELL.y * SIZE.x + TREE_CELL.x] = _tiles.Kind["FOREST"]


func _fill(rect: Rect2i, kind_name: String) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_kinds[y * SIZE.x + x] = _tiles.Kind[kind_name]


func _paint(layer: TileMapLayer) -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var kind: int = _kinds[y * SIZE.x + x]
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


func _add_spawns(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	var number := 0
	for cell: Vector2i in EXIT_CELLS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "ExitViridian%d" % number
		number += 1
		point.position = _world(cell)
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", EXIT_TARGET)
		point.set(&"target_spawn", EXIT_SPAWN)
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)


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
