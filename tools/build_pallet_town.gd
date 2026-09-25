extends SceneTree
## Construit game/world/maps/pallet_town.tscn (Bourg Palette, 48 × 34 cases).
##
##   godot --headless --path . -s res://tools/build_pallet_town.gd
##   godot --headless --path . --import
##
## Plan : docs/tech/jalon-01.md §4. Zones et props sont décrits en données ci-dessous
## (rectangles inclusifs [x0, y0, x1, y1] et ancres de cases). Variantes de tuiles et
## essences d'arbres tirées avec une graine fixe : la carte est reproductible.

const OUT_PATH: String = "res://game/world/maps/pallet_town.tscn"
const PROPS: String = "res://game/world/props/"
const SEED: int = 1996
const SIZE := Vector2i(48, 34)
const START_CELL := Vector2i(36, 10)
## Haut de la Route 1 : le chemin file jusqu'au bord, le joueur s'arrête en y 1.
const BLOCKED_CELLS: Array[Vector2i] = [Vector2i(23, 0), Vector2i(24, 0)]

## Sol, peint dans l'ordre (le suivant écrase le précédent). [type, [x0, y0, x1, y1]]
const GROUND: Array = [
	["GRASS", [0, 0, 47, 33]],
	# Lisières (forêt dense, solide).
	["FOREST", [0, 0, 21, 0]],
	["FOREST", [26, 0, 47, 0]],
	["FOREST", [0, 0, 2, 25]],
	["FOREST", [45, 0, 47, 4]],
	["FOREST", [42, 5, 47, 28]],
	# Route 1 : chemin de terre jusqu'au bord nord, puis vers la place.
	["DIRT", [23, 0, 24, 11]],
	# Champ cultivé.
	["CROP", [34, 1, 43, 2]],
	# Chemins depuis les portillons des jardins vers la place.
	["DIRT", [11, 10, 11, 13]],
	["DIRT", [11, 13, 16, 13]],
	["DIRT", [36, 10, 36, 13]],
	["DIRT", [32, 13, 36, 13]],
	# Place centrale, passages le long du labo, parvis.
	["COBBLE", [17, 12, 31, 17]],
	["COBBLE", [17, 18, 17, 22]],
	["COBBLE", [31, 18, 31, 22]],
	["COBBLE", [17, 23, 31, 23]],
	# Accès à la côte par l'ouest et l'est du labo.
	["DIRT", [15, 23, 16, 23]],
	["DIRT", [15, 24, 15, 28]],
	["DIRT", [32, 23, 38, 23]],
	["DIRT", [38, 18, 38, 28]],
	["DIRT", [32, 18, 37, 18]],
	# Allée des jardins de recherche.
	["DIRT", [24, 25, 24, 27]],
	# Plage, sentier côtier, Route 21 (au-delà de la barrière).
	["SAND", [3, 27, 14, 31]],
	["DIRT", [7, 29, 47, 30]],
	# Sentier secret (envahi, inaccessible).
	["DIRT", [42, 26, 46, 26]],
	# Mer, eau peu profonde du rivage, ponton, escalier.
	["WATER", [0, 26, 2, 31]],
	["WATER", [0, 32, 47, 33]],
	["SHALLOW", [2, 27, 2, 31]],
	["SHALLOW", [3, 32, 14, 32]],
	["BOARDWALK", [9, 32, 9, 33]],
	["BOARDWALK", [6, 24, 6, 27]],
]

## Obstacles simples en tuiles : falaises.
const OBSTACLES: Array = [
	["CLIFF", [3, 18, 5, 26]],
	["CLIFF", [15, 31, 47, 31]],
]

## Massifs de fleurs (Detail) : [x0, y0, x1, y1, densité 0..1].
const FLOWER_BEDS: Array = [
	[3, 1, 44, 4, 0.10],
	[7, 5, 15, 10, 0.30],
	[32, 5, 40, 10, 0.30],
	[17, 5, 30, 11, 0.08],
	[6, 12, 16, 26, 0.07],
	[32, 12, 41, 28, 0.07],
	[17, 25, 35, 27, 0.15],
]

## Props uniques : [scène, [x, y], nom du nœud].
const PROPS_FIXED: Array = [
	["house_rival", [11, 9], "RivalHouse"],
	["house_player", [36, 9], "PlayerHouse"],
	["oak_lab", [24, 22], "OakLab"],
	["plaza_tree", [24, 16], "PlazaTree"],
	["bench", [19, 15], "BenchWest"],
	["bench", [28, 15], "BenchEast"],
	["sign_pallet", [21, 13], "SignPallet"],
	["mailbox", [13, 10], "MailboxRival"],
	["mailbox", [38, 10], "MailboxPlayer"],
	["bicycle", [40, 10], "Bicycle"],
	["van", [15, 22], "Van"],
	["greenhouse_large", [20, 27], "GreenhouseLarge"],
	["greenhouse_small", [33, 27], "GreenhouseSmall"],
	["vegetable_patch", [27, 26], "VegetablePatchA"],
	["vegetable_patch", [27, 27], "VegetablePatchB"],
	["brambles", [42, 26], "SecretBrambles"],
	["barrier_route21", [45, 30], "BarrierRoute21"],
	["lamp_post", [17, 12], "LampPlazaNW"],
	["lamp_post", [31, 12], "LampPlazaNE"],
	["lamp_post", [17, 17], "LampPlazaSW"],
	["lamp_post", [31, 17], "LampPlazaSE"],
	["lamp_post", [14, 29], "LampCoastW"],
	["lamp_post", [26, 29], "LampCoastC"],
	["lamp_post", [38, 29], "LampCoastE"],
	["rock_small", [13, 2], "RockPrairie"],
	["rock_large", [29, 3], "RockPrairieLarge"],
	["rock_large", [10, 16], "RockLawn"],
	["rock_small", [7, 23], "RockLawnSmall"],
	["rock_large", [4, 28], "RockBeach"],
	["rock_small", [5, 30], "RockBeachA"],
	["rock_small", [12, 31], "RockBeachB"],
	["bush_b", [7, 5], "BushRivalA"],
	["bush_a", [15, 5], "BushRivalB"],
	["bush_b", [17, 25], "BushGardenA"],
	["bush_a", [35, 25], "BushGardenB"],
	["bush_a", [19, 11], "BushResidential"],
]

## Clôtures : [style, [x, y] ancre, longueur, vertical].
## Horizontale : ancre = case ouest. Verticale : ancre = case sud.
const FENCES: Array = [
	# Route 1.
	["wood", [22, 3], 4, true],
	["wood", [25, 3], 4, true],
	# Champ cultivé.
	["wood", [33, 2], 2, true],
	["wood", [44, 2], 2, true],
	["wood", [33, 3], 12, false],
	# Jardin du rival (portillon ouvert en 11, 11).
	["picket", [6, 10], 6, true],
	["picket", [16, 10], 6, true],
	["picket", [6, 11], 5, false],
	["picket", [12, 11], 5, false],
	# Jardin du joueur (portillon ouvert en 36, 11).
	["picket", [31, 10], 6, true],
	["picket", [41, 10], 6, true],
	["picket", [31, 11], 5, false],
	["picket", [37, 11], 5, false],
	# Jardins de recherche (portillon ouvert en 24, 24).
	["picket", [16, 24], 8, false],
	["picket", [25, 24], 12, false],
	["picket", [16, 28], 21, false],
	["picket", [16, 27], 3, true],
	["picket", [36, 27], 3, true],
	# Barrière du sentier côtier.
	["wood", [15, 31], 30, false],
]

## Arbres placés à la main (essence tirée au sort sans répétition voisine).
const TREES: Array = [
	# Prairie du Nord.
	[5, 2], [9, 3], [16, 1], [19, 3], [27, 1], [31, 2],
	# Quartier résidentiel.
	[4, 7], [4, 11], [18, 7], [29, 6], [20, 9],
	# Pelouse ouest.
	[4, 13], [8, 14], [13, 15], [7, 17], [11, 19], [14, 18], [8, 21], [12, 24], [10, 25],
	# Entre la place et le couloir est, couloir est.
	[34, 17], [33, 20], [36, 21], [40, 13], [39, 16], [41, 19], [40, 22], [40, 24],
	[41, 15],
]

## Pas d'arbre de lisière ici : leurs cimes cacheraient l'entrée du sentier secret.
const FOREST_CLEARINGS: Array = [[41, 26, 47, 28]]

const TREE_SCENES: Array[String] = [
	"tree_oak_a", "tree_oak_b", "tree_pine", "tree_birch", "tree_maple",
]

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _last_tree: int = -1


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = SEED
	var root := Node2D.new()
	root.name = "PalletTown"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"pallet_town")
	root.set(&"display_name", "Bourg Palette")
	root.set(&"region", "Kanto")
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
	for group: String in ["Warps", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	var start := Marker2D.new()
	start.name = "start"
	start.position = _world(START_CELL)
	_attach(root, root.get_node(^"Spawns"), start)

	var kinds: Array = _paint(ground, GROUND)
	_paint(obstacles, OBSTACLES)
	_paint_flowers(detail, kinds)
	_place_props(root, entities)
	_place_forest(root, entities, kinds)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("pallet_town : %s (%d entités)" % [error_string(err), entities.get_child_count()])
	root.free()
	quit()


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


## Peint des rectangles de tuiles ; renvoie la grille des types (index y * w + x).
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
	# État d'édition : pack() ne garde que les propriétés modifiées (position, longueur…),
	# l'empreinte reste définie dans la scène du prop.
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
	i = 0
	for cell: Array in TREES:
		_add_prop(root, entities, _pick_tree(), Vector2i(cell[0], cell[1]), "Tree%02d" % i)
		i += 1


## Arbres des lisières : un sur deux environ, décalés en quinconce ; la forêt elle-même
## est une tuile de canopée solide.
func _place_forest(root: Node, entities: Node, kinds: Array) -> void:
	var forest := _kind("FOREST")
	var i := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if kinds[y * SIZE.x + x] != forest:
				continue
			if (x + y * 2) % 3 != 0 and not _is_forest_edge(kinds, x, y):
				continue
			if (x + y) % 2 != 0 or _in_clearing(x, y):
				continue
			_add_prop(root, entities, _pick_tree(), Vector2i(x, y), "ForestTree%03d" % i)
			i += 1


func _in_clearing(x: int, y: int) -> bool:
	for r: Array in FOREST_CLEARINGS:
		if x >= r[0] and x <= r[2] and y >= r[1] and y <= r[3]:
			return true
	return false


func _is_forest_edge(kinds: Array, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var p := Vector2i(x, y) + d
		if p.x < 0 or p.y < 0 or p.x >= SIZE.x or p.y >= SIZE.y:
			continue
		if kinds[p.y * SIZE.x + p.x] != _kind("FOREST"):
			return true
	return false


func _pick_tree() -> String:
	var index := _rng.randi_range(0, TREE_SCENES.size() - 2)
	if index >= _last_tree and _last_tree >= 0:
		index += 1
	index = mini(index, TREE_SCENES.size() - 1)
	_last_tree = index
	return TREE_SCENES[index]
