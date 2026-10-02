extends SceneTree
## Construit game/world/maps/route_1.tscn (Route 1, 48 × 44 cases) d'après le dossier-07.
##
##   godot --headless --path . -s res://tools/build_route_1.gd
##   godot --headless --path . --import
##
## Conception : docs/design/dossier-07-route-1.md (source de vérité), plan docs/tech/jalon-05.md
## §15.4 (carte), §15.5 (raccord Bourg Palette). Level design provisoire (« géométrie
## d'abord ») : chemin qui serpente entre des lisières de forêt, 3 zones de hautes herbes dont
## une bande obligatoire, rebord franchissable vers le sud, Potion cachée, sortie sud vers
## Bourg Palette (warps PUSH), sortie nord vers Jadielle (bord de carte bloqué ; en build de
## développement, un warp PUSH « JADIELLE — À venir » sur le haut du chemin, dossier-07 §12).
## Le Voyageur et les Pokémon d'ambiance sont dans data/npcs/route_1.json.

const OUT_PATH: String = "res://game/world/maps/route_1.tscn"
const PROPS: String = "res://game/world/props/"
const SEED: int = 2026
const SIZE := Vector2i(48, 44)
## Chemin d'arrivée aligné sur Bourg Palette : x 23–24. Bords sud et nord du chemin bloqués
## (la tête du joueur reste à l'écran ; nord = Jadielle, à venir).
const BLOCKED_CELLS: Array[Vector2i] = [
	Vector2i(23, 43), Vector2i(24, 43), Vector2i(23, 0), Vector2i(24, 0),
]

## Points d'apparition (Marker2D enfants de `Spawns`).
const SPAWNS: Dictionary = {
	"start": Vector2i(23, 40),
	"from_pallet_w": Vector2i(23, 42),
	"from_pallet_e": Vector2i(24, 42),
	# Retour de l'écran « JADIELLE — À venir » : une case en retrait du bord nord.
	"jadielle_soon_w": Vector2i(23, 2),
	"jadielle_soon_e": Vector2i(24, 2),
}

## Warps PUSH vers Bourg Palette au bord sud : [nœud, case, carte, spawn, arrivée].
const PUSH: int = 1
const WARPS: Array = [
	["PalletSouthW", Vector2i(23, 42), &"pallet_town", &"from_route_1_w", Vector2i.DOWN],
	["PalletSouthE", Vector2i(24, 42), &"pallet_town", &"from_route_1_e", Vector2i.DOWN],
]

## Destinations « à venir » (Warp.coming_soon, build de développement) : warps PUSH vers le
## haut sur les deux cases du chemin au bord nord. [nœud, case, libellé, spawn de retour sur
## cette carte, orientation au retour].
const SOON_WARPS: Array = [
	["JadielleSoonW", Vector2i(23, 1), "Jadielle", &"jadielle_soon_w", Vector2i.DOWN],
	["JadielleSoonE", Vector2i(24, 1), "Jadielle", &"jadielle_soon_e", Vector2i.DOWN],
]

## Sol, peint dans l'ordre (le suivant écrase le précédent). [type, [x0, y0, x1, y1]].
## Base : forêt partout, puis on creuse le couloir praticable (GRASS), puis le rebord, le
## chemin de terre (DIRT) qui serpente, et les hautes herbes.
const GROUND: Array = [
	["FOREST", [0, 0, 47, 43]],
	# Couloir praticable (herbe rase) : serpentin du sud (Bourg Palette) au nord (Jadielle).
	["GRASS", [21, 34, 26, 43]],   # entrée sud
	["GRASS", [21, 32, 36, 37]],   # coude est
	["GRASS", [31, 24, 38, 37]],   # montée est
	["GRASS", [10, 24, 38, 29]],   # traversée vers l'ouest
	["GRASS", [8, 15, 15, 29]],    # montée ouest
	["GRASS", [10, 13, 26, 18]],   # retour vers l'est
	["GRASS", [21, 10, 26, 18]],   # approche de la bande obligatoire
	["GRASS", [23, 8, 24, 9]],     # passage étroit (bande obligatoire)
	["GRASS", [21, 1, 26, 7]],     # au-delà de la bande
	["GRASS", [6, 1, 41, 7]],      # prairie nord (traces humaines vers Jadielle)
	["GRASS", [26, 29, 28, 33]],   # descente du raccourci (rebord)
	# Rebord franchissable vers le sud (raccourci de retour, dossier-07 §3).
	["LEDGE_DOWN", [26, 30, 28, 30]],
	# Chemin de terre qui serpente (2 cases de large).
	["DIRT", [23, 36, 24, 43]],
	["DIRT", [23, 35, 34, 36]],
	["DIRT", [33, 26, 34, 36]],
	["DIRT", [12, 25, 34, 26]],
	["DIRT", [12, 16, 13, 26]],
	["DIRT", [12, 15, 24, 16]],
	["DIRT", [23, 0, 24, 16]],
	# Hautes herbes : Zone 1 (initiation, contournable), Zone 2 (exploration, recoin/Potion),
	# Zone 3 (bande obligatoire sur le passage étroit).
	["TALL_GRASS", [27, 32, 30, 34]],
	["TALL_GRASS", [8, 18, 11, 27]],
	["TALL_GRASS", [23, 8, 24, 9]],
	# Clairière au pied de l'arbre isolé (recoin de la Potion) : herbe rase dans la Zone 2.
	["GRASS", [9, 20, 9, 20]],
]

## Massifs de fleurs (Detail) : [x0, y0, x1, y1, densité].
const FLOWER_BEDS: Array = [
	[21, 38, 26, 43, 0.12],   # sud entretenu
	[6, 1, 41, 7, 0.06],      # prairie nord
]

## Props uniques : [scène, [x, y], nom]. Arbre isolé de la Potion + quelques arbres de décor
## (posés sur des cases de forêt, sans effet sur l'accessibilité).
const PROPS_FIXED: Array = [
	["tree_oak_a", [9, 19], "PotionTree"],
	["tree_pine", [7, 10], "TreeNW"],
	["tree_oak_b", [40, 10], "TreeNE"],
	["tree_maple", [16, 21], "TreeMidW"],
	["tree_oak_a", [33, 21], "TreeMidE"],
	["tree_birch", [19, 30], "TreeSouthW"],
	["tree_pine", [30, 20], "TreeMidC"],
]

## Clôtures du sud (dossier-07 : « végétation entretenue, clôtures »). [style, [x, y], long, vert].
const FENCES: Array = [
	["picket", [20, 43], 6, true],
	["picket", [27, 43], 6, true],
]

## Déclencheurs de scène : [nœud, ancre, size, direction, scène]. Potion cachée dans un
## recoin de la Zone 2 (dossier-07 §6) : sur une case d'herbe rase (pas de rencontre).
const TRIGGERS: Array = [
	["Route1Potion", Vector2i(9, 20), Vector2i(1, 1), Vector2i.ZERO, "route_1_potion"],
]

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = SEED
	var root := Node2D.new()
	root.name = "Route1"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"route_1")
	root.set(&"display_name", "Route 1")
	root.set(&"region", "Bourg Palette — Jadielle")
	root.set(&"size", SIZE)
	root.set(&"blocked_cells", BLOCKED_CELLS)
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
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
	_add_triggers(root)

	var kinds: Array = _paint(ground, GROUND)
	_paint_flowers(detail, kinds)
	_place_props(root, entities)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("route_1 : %s (%d entités)" % [error_string(err), entities.get_child_count()])
	root.free()
	quit()


func _add_spawns(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for entry: Array in WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", entry[2])
		point.set(&"target_spawn", entry[3])
		point.set(&"arrival_facing", entry[4])
		_attach(root, root.get_node(^"Warps"), point)
	for entry: Array in SOON_WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.UP)
		point.set(&"coming_soon", entry[2])
		point.set(&"target_spawn", entry[3])
		point.set(&"arrival_facing", entry[4])
		_attach(root, root.get_node(^"Warps"), point)


func _add_triggers(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in TRIGGERS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"cutscene_id", StringName(entry[4]))
		_attach(root, root.get_node(^"Triggers"), point)


func _world(cell: Vector2i) -> Vector2:
	var tile: int = 96
	return Vector2(cell.x * tile + tile / 2.0, (cell.y + 1) * tile)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer


func _kind(kind_name: String) -> int:
	return _tiles.Kind[kind_name]


func _paint(layer: TileMapLayer, rects: Array) -> Array:
	var kinds: Array = []
	kinds.resize(SIZE.x * SIZE.y)
	kinds.fill(-1)
	for entry: Array in rects:
		var r: Array = entry[1]
		for y: int in range(r[1], r[3] + 1):
			for x: int in range(r[0], r[2] + 1):
				kinds[y * SIZE.x + x] = _kind(entry[0])
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var kind: int = kinds[y * SIZE.x + x]
			if kind < 0:
				continue
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))
	return kinds


func _paint_flowers(detail: TileMapLayer, kinds: Array) -> void:
	var flowers := _kind("FLOWERS")
	var grass := _kind("GRASS")
	for bed: Array in FLOWER_BEDS:
		for y: int in range(bed[1], bed[3] + 1):
			for x: int in range(bed[0], bed[2] + 1):
				if kinds[y * SIZE.x + x] != grass or _rng.randf() >= bed[4]:
					continue
				var variant := _rng.randi_range(0, _tiles.variant_count(flowers) - 1)
				detail.set_cell(Vector2i(x, y), _tiles.SOURCE_ID,
					_tiles.atlas_coords(flowers, variant))


func _scene(scene_name: String) -> PackedScene:
	if not _scenes.has(scene_name):
		_scenes[scene_name] = load(PROPS + scene_name + ".tscn")
	return _scenes[scene_name]


func _add_prop(root: Node, entities: Node, scene_name: String, cell: Vector2i,
		node_name: String) -> Node2D:
	var prop := _scene(scene_name).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = _world(cell)
	_attach(root, entities, prop)
	return prop


func _place_props(root: Node, entities: Node) -> void:
	for entry: Array in PROPS_FIXED:
		_add_prop(root, entities, entry[0], Vector2i(entry[1][0], entry[1][1]), entry[2])
	var i := 0
	for entry: Array in FENCES:
		var fence := _add_prop(root, entities, "fence_" + entry[0],
			Vector2i(entry[1][0], entry[1][1]), "Fence%02d" % i)
		fence.set(&"length", entry[2])
		fence.set(&"vertical", entry[3])
		i += 1
