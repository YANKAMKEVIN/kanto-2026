extends SceneTree
## Construit game/world/maps/route_1.tscn (Route 1, 48 × 44 cases) d'après le dossier-07.
##
##   godot --headless --path . -s res://tools/build_route_1.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)
##
## **DA.1 (docs/tech/integration-da-bourg-route1.md)** : la carte est peinte, comme la Route 22
## (lumière `golden_hour`), à l'image du prototype validé sur S24 (`proto/da_jadielle/
## proto_route1.gd`, vue générale peinte v1). La géométrie logique du jalon 5 ne change pas :
## `Ground` (TileMapLayer **invisible**, mêmes rectangles, mêmes tirages) reste la source du
## solide, des hautes herbes et du rebord. L'image : sol peint (masque G = chemin de terre),
## sous-bois [ForestFloor] et forêt serrée [DenseForest] sur toutes les cases de forêt, arbres
## repères aux cases des arbres du jalon 5, souche du recoin de la Potion, rebord peint,
## touffes jaune-vert (deux par case), fleurs et touffes semées, clôtures courtes au départ,
## panneau, clôtures et banc dans la prairie nord.
##
## Conception : docs/design/dossier-07-route-1.md (source de vérité), plan docs/tech/jalon-05.md
## §15.4 (carte), §15.5 (raccord Bourg Palette). Level design provisoire (« géométrie
## d'abord ») : chemin qui serpente entre des lisières de forêt, 3 zones de hautes herbes dont
## une bande obligatoire, rebord franchissable vers le sud, Potion cachée, sortie sud vers
## Bourg Palette (warps PUSH), sortie nord vers Jadielle (warps PUSH sur le haut du chemin,
## vers `viridian_city` ; jalon 7 T4 : remplace l'écran « JADIELLE — À venir » du jalon 5).
## Le Voyageur et les Pokémon d'ambiance sont dans data/npcs/route_1.json.

const OUT_PATH: String = "res://game/world/maps/route_1.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_1_ground.png"
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const TALL_GRASS_ID: String = "ground_hautes_herbes_jaune_01"
const GRASS_FRONT: String = "res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png"
const FLOWER_DECAL: String = "res://assets/world/ground/decals/decal_fleur_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"
const MEADOW_ATTEMPTS: int = 900
const MEADOW_FLOWER_CHANCE: float = 0.14
const TILE: int = 96
const SEED: int = 2026
const SIZE := Vector2i(48, 44)
## Chemin d'arrivée aligné sur Bourg Palette : x 23–24. Bords sud et nord du chemin bloqués
## (la tête du joueur reste à l'écran ; le passage vers Jadielle se fait en poussant vers le
## haut depuis la rangée 1).
const BLOCKED_CELLS: Array[Vector2i] = [
	Vector2i(23, 43), Vector2i(24, 43), Vector2i(23, 0), Vector2i(24, 0),
]

## Points d'apparition (Marker2D enfants de `Spawns`).
const SPAWNS: Dictionary = {
	"start": Vector2i(23, 40),
	"from_pallet_w": Vector2i(23, 42),
	"from_pallet_e": Vector2i(24, 42),
	# Arrivée depuis Jadielle (jalon 7 T4) : sur les cases de passage, tourné vers le sud.
	"from_viridian_w": Vector2i(23, 1),
	"from_viridian_e": Vector2i(24, 1),
}

## Warps PUSH : vers Bourg Palette au bord sud, vers Jadielle au bord nord (jalon 7 T4).
## [nœud, case, carte, spawn, arrivée, direction de poussée].
const PUSH: int = 1
const WARPS: Array = [
	["PalletSouthW", Vector2i(23, 42), &"pallet_town", &"from_route_1_w", Vector2i.DOWN,
		Vector2i.DOWN],
	["PalletSouthE", Vector2i(24, 42), &"pallet_town", &"from_route_1_e", Vector2i.DOWN,
		Vector2i.DOWN],
	["ViridianNorthW", Vector2i(23, 1), &"viridian_city", &"from_route_1_w", Vector2i.UP,
		Vector2i.UP],
	["ViridianNorthE", Vector2i(24, 1), &"viridian_city", &"from_route_1_e", Vector2i.UP,
		Vector2i.UP],
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

## Massifs de fleurs (Detail, invisible) : [x0, y0, x1, y1, densité]. Leurs cases (mêmes
## tirages qu'au jalon 5, recopiées par le prototype) reçoivent deux fleurs peintes chacune.
const FLOWER_BEDS: Array = [
	[21, 38, 26, 43, 0.12],   # sud entretenu
	[6, 1, 41, 7, 0.06],      # prairie nord
]

## Arbres repères (DA.1) : [objet peint, case, nom]. Mêmes cases que les arbres du jalon 5
## (posés sur des cases de forêt, ou sur la case d'herbe du recoin de la Potion déjà bloquée
## par l'arbre), essences du prototype (`proto_route1.gd`, vue générale peinte v1) : arbre du
## recoin, deux conifères, deux feuillus, arbre d'automne orange, bouleau près du rebord.
const LANDMARKS: Array = [
	["tree_c_01", Vector2i(9, 19), "PotionTree"],
	["tree_b_01", Vector2i(7, 10), "TreeNW"],
	["tree_c_01", Vector2i(40, 10), "TreeNE"],
	["tree_automne_01", Vector2i(16, 21), "TreeMidW"],
	["tree_a_01", Vector2i(33, 21), "TreeMidE"],
	["tree_d_01", Vector2i(19, 30), "TreeSouthW"],
	["tree_b_01", Vector2i(30, 20), "TreeMidC"],
]

## Souche du recoin de la Potion (choix 6 de Kevin : « coincée entre les racines »), pied du
## prototype (cases) : au bas de la clairière, sous l'arbre. **Sans emprise** : elle est sur la
## case du déclencheur `Route1Potion`, qui doit rester praticable.
const STUMP_FOOT := Vector2(9.6, 20.95)

## Objets peints solides : [objet, case d'ancrage, nom]. Positions du prototype ramenées sur la
## grille (`PaintedPropRules.foot_position`) ; tous sur de l'herbe rase hors du chemin, des
## hautes herbes, des passages, des points d'apparition et des cases des PNJ.
const PROPS_FIXED: Array = [
	# Départ depuis Bourg Palette : clôtures courtes, un rocher, des buissons (choix 7).
	["prop_cloture_courte_01", Vector2i(21, 42), "FenceShortW"],
	["prop_cloture_courte_01", Vector2i(25, 42), "FenceShortE"],
	["prop_rocher_01", Vector2i(26, 40), "RockSouth"],
	["prop_buisson_b_01_bourg", Vector2i(21, 40), "BushSouth"],
	["prop_buisson_a_01_bourg", Vector2i(21, 36), "BushBend"],
	# Prairie du nord : panneau sans texte, clôtures en bois, banc (choix 2).
	["prop_panneau_01", Vector2i(22, 7), "SignNorth"],
	["prop_cloture_01", Vector2i(12, 3), "FenceMeadowW"],
	["prop_cloture_01", Vector2i(35, 2), "FenceMeadowE"],
	["prop_banc_01", Vector2i(38, 5), "BenchNorth"],
	# Bords des clairières (choix 1 : quelques buissons seulement).
	["prop_buisson_a_01_bourg", Vector2i(10, 13), "BushWest"],
	["prop_buisson_c_01_bourg", Vector2i(26, 10), "BushBand"],
	["prop_buisson_b_01_bourg", Vector2i(38, 24), "BushEast"],
	["prop_rocher_01", Vector2i(10, 28), "RockWest"],
]
## Petites pierres (traversables), pied du prototype en cases.
const STONES: Array[Vector2] = [Vector2(37.6, 27.6)]

## Ombre de contact sous les arbres de la forêt serrée (le prototype validé l'avait ; règle du
## J7 : pas d'ombre pour la végétation). **Désactivée par défaut** : passer à `true`, relancer
## l'outil (`godot --headless --path . -s res://tools/build_route_1.gd`) puis réimporter.
const FOREST_CONTACT_SHADOWS: bool = false
## Graines fixes des décors (le sol logique garde [constant SEED] et ses tirages du jalon 5).
const DECOR_SEED: int = 2027
## Dégagement de la forêt autour des PNJ (cases) : voir _clear_around_npcs.
const NPC_TREE_CLEAR_X: float = 2.2
const NPC_TREE_CLEAR_Y: float = 3.0
const FOREST_SEED: int = 1

## Déclencheurs de scène : [nœud, ancre, size, direction, scène]. Potion cachée dans un
## recoin de la Zone 2 (dossier-07 §6) : sur une case d'herbe rase (pas de rencontre).
const TRIGGERS: Array = [
	["Route1Potion", Vector2i(9, 20), Vector2i(1, 1), Vector2i.ZERO, "route_1_potion"],
]

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _decor_rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _kinds: Array = []
var _path_cells: Dictionary = {}
var _forest_cells: Dictionary = {}
var _tall_grass_cells: Dictionary = {}
var _flower_cells: Dictionary = {}


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = SEED
	_decor_rng.seed = DECOR_SEED
	var root := Node2D.new()
	root.name = "Route1"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"route_1")
	root.set(&"display_name", "Route 1")
	root.set(&"region", "Bourg Palette — Jadielle")
	root.set(&"size", SIZE)
	root.set(&"blocked_cells", BLOCKED_CELLS)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"grass_front", load(GRASS_FRONT))
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	# Source logique seulement (solide, hautes herbes, rebord) : l'image est peinte.
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	_kinds = _paint(ground, GROUND)
	_paint_flowers(detail, _kinds)
	_classify()

	var mask_texture := _write_mask()
	if mask_texture == null:
		print("build_route_1 : masque écrit ; importer (--import) puis relancer l'outil")
		root.free()
		quit(2)
		return
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", SIZE)
	painted.set(&"mask", mask_texture)
	_attach(root, root, painted)
	var floor_script := load("res://game/world/ground/forest_floor.gd") as GDScript
	_attach(root, root, floor_script.call(&"create", SIZE, _forest_cells) as Node)

	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = -1
	_attach(root, root, decals)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for layer: TileMapLayer in [ground, detail, obstacles, overhead]:
		layer.visible = false
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	_add_spawns(root)
	_add_warps(root)
	_add_triggers(root)

	_place_border_decals(root, decals)
	_place_flowers(root, decals)
	_place_ledge(root, decals)
	_place_landmarks(root, entities)
	_place_props(root, entities)
	_place_tall_grass(root, entities)
	var forest_script := load("res://game/world/forest/dense_forest.gd") as GDScript
	var plan: Array[Dictionary] = _clear_around_npcs(forest_script.call(&"plan",
		_forest_cells, SIZE, _landmark_feet(), FOREST_SEED), forest_script)
	forest_script.call(&"place", plan, entities, root, FOREST_CONTACT_SHADOWS)
	_place_meadow_seeds(root, decals)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("route_1 : %s (%d entités, %d objets de forêt, %d décalcomanies)" % [
		error_string(err), entities.get_child_count(), plan.size(), decals.get_child_count()])
	root.free()
	quit()


# --- Plan logique (inchangé depuis le jalon 5) --------------------------------------------


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


## Mêmes tirages qu'au jalon 5 : les cases fleuries sont celles du plan du prototype.
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
				_flower_cells[Vector2i(x, y)] = true


## Cases du chemin, de la forêt et des hautes herbes, dans l'ordre des rangées (celui du
## prototype : la forêt serrée en dépend).
func _classify() -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var kind: int = _kinds[y * SIZE.x + x]
			var cell := Vector2i(x, y)
			if kind == _kind("DIRT"):
				_path_cells[cell] = true
			elif kind == _kind("FOREST"):
				_forest_cells[cell] = true
			elif kind == _kind("TALL_GRASS"):
				_tall_grass_cells[cell] = true


## Masque du sol peint (G = chemin de terre), écrit dans assets/world/maps/. Null tant que
## l'image n'est pas importée.
func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", SIZE, [], _path_cells)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MASK_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


# --- Scène ------------------------------------------------------------------------------


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
		point.set(&"direction", entry[5])
		point.set(&"target_map", entry[2])
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


func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS + id + ".tscn")
	return _scenes[id]


## Objet peint, pied à [param foot] (pixels).
func _add_prop(root: Node, parent: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot.round()
	_attach(root, parent, prop)
	return prop


## Objet peint ancré sur [param cell] (emprise de `PaintedPropRules` autour de la case).
func _add_prop_at(root: Node, parent: Node, id: String, cell: Vector2i,
		node_name: String) -> Node2D:
	var rules := load("res://game/world/props/painted_prop_rules.gd") as GDScript
	var foot: Vector2 = rules.call(&"foot_position", StringName(id), cell)
	return _add_prop(root, parent, id, foot, node_name)


func _decal(root: Node, parent: Node, texture: String, foot: Vector2, scale: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture)
	sprite.position = foot
	sprite.scale = Vector2.ONE * scale * _decor_rng.randf_range(0.85, 1.15)
	sprite.flip_h = _decor_rng.randf() < 0.5
	_attach(root, parent, sprite)


## Décalcomanies du bord du chemin (terre et touffes ; pas de pavés sur une route de terre).
func _place_border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var plan: Array = script.call(&"plan", _path_cells, SIZE, SEED)
	var kept: Array[Dictionary] = []
	for decal: Dictionary in plan:
		if not String(decal["texture"]).contains("decal_pave"):
			kept.append(decal)
	script.call(&"place", kept, decals, root)


## Deux fleurs peintes par case fleurie du jalon 5 (départ et prairie nord).
func _place_flowers(root: Node, decals: Node2D) -> void:
	for cell: Vector2i in _flower_cells:
		for i in 2:
			var foot := (Vector2(cell) + Vector2(_decor_rng.randf(), _decor_rng.randf())) * TILE
			_decal(root, decals, FLOWER_DECAL % _decor_rng.randi_range(1, 8), foot, 1.0)


## Rebord peint (relief de la couche du sol, sans emprise : la donnée « ledge » est dans
## `Ground`) sur chaque case du rebord.
func _place_ledge(root: Node, decals: Node2D) -> void:
	var index := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _kinds[y * SIZE.x + x] == _kind("LEDGE_DOWN"):
				_add_prop_at(root, decals, "relief_rebord_01", Vector2i(x, y),
					"Ledge%02d" % index)
				index += 1


func _place_landmarks(root: Node, entities: Node2D) -> void:
	for entry: Array in LANDMARKS:
		_add_prop_at(root, entities, entry[0], entry[1], entry[2])
	var stump := _add_prop(root, entities, "prop_souche_01", STUMP_FOOT * TILE, "PotionStump")
	var no_footprint: Array[Vector2i] = []
	stump.set(&"footprint", no_footprint)


func _landmark_feet() -> Array[Vector2]:
	var rules := load("res://game/world/props/painted_prop_rules.gd") as GDScript
	var feet: Array[Vector2] = []
	for entry: Array in LANDMARKS:
		var foot: Vector2 = rules.call(&"foot_position", StringName(entry[0]), entry[1])
		feet.append(foot / TILE)
	return feet


func _place_props(root: Node, entities: Node2D) -> void:
	for entry: Array in PROPS_FIXED:
		_add_prop_at(root, entities, entry[0], entry[1], entry[2])
	var index := 0
	for foot: Vector2 in STONES:
		_add_prop(root, entities, "prop_pierres_01", foot * TILE, "Stones%02d" % index)
		index += 1


## Deux touffes jaune-vert par case de hautes herbes, décalées et de tailles variées
## (prototype) : pas de rangées visibles. Non solides ; la donnée `tall_grass` est dans Ground.
func _place_tall_grass(root: Node, entities: Node2D) -> void:
	var wind: Material = load(WIND_MATERIAL)
	var index := 0
	for cell: Vector2i in _tall_grass_cells:
		for k: int in 2:
			var foot := Vector2(cell) + Vector2(_decor_rng.randf_range(0.25, 0.75),
				0.55 + 0.45 * k)
			var tuft := _add_prop(root, entities, TALL_GRASS_ID, foot * TILE, "Tuft%03d" % index)
			index += 1
			var scale := _decor_rng.randf_range(1.0, 1.3)
			tuft.scale = Vector2(scale, scale)
			var sprite := tuft.get_node(^"Sprite")
			sprite.set(&"material", wind)
			sprite.set(&"flip_h", _decor_rng.randf() < 0.5)


## Cases des PNJ du fichier de la carte (départ et routines).
func _npc_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/route_1.json"))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
		if entry.has("route"):
			for cell: Array in entry["route"]["cells"]:
				cells.append(Vector2i(int(cell[0]), int(cell[1])))
	return cells


## Retire du plan de la forêt les arbres dont le feuillage (≈ 3 cases de large) passerait
## devant un PNJ qui marche au bord de la forêt (le Voyageur était à moitié caché) : pied à
## moins de [constant NPC_TREE_CLEAR_X] colonnes d'une case de PNJ et de 0 à
## [constant NPC_TREE_CLEAR_Y] rangées plus au sud. Les cases de forêt ainsi dégarnies
## reçoivent des buissons (plus bas, ils ne cachent personne), comme dans `DenseForest`.
func _clear_around_npcs(plan: Array[Dictionary], forest_script: GDScript) -> Array[Dictionary]:
	var npcs := _npc_cells()
	var kept: Array[Dictionary] = []
	var trees: Array[Vector2] = _landmark_feet()
	var removed := false
	for entry: Dictionary in plan:
		if entry["kind"] != &"tree":
			continue
		var foot: Vector2 = entry["foot"]
		var near := false
		for cell: Vector2i in npcs:
			var dx := absf(foot.x - (cell.x + 0.5))
			var dy := foot.y - (cell.y + 1.0)
			if dx < NPC_TREE_CLEAR_X and dy > -0.5 and dy < NPC_TREE_CLEAR_Y:
				near = true
				break
		if near:
			removed = true
			continue
		kept.append(entry)
		trees.append(foot)
	if not removed:
		return plan
	# Buissons : ceux du plan, plus les cases de forêt que plus aucun arbre ne garnit.
	var bushed: Dictionary = {}
	for entry: Dictionary in plan:
		if entry["kind"] == &"bush":
			kept.append(entry)
			bushed[Vector2i(floori(entry["foot"].x), floori(entry["foot"].y - 0.95))] = true
	var bush_rng := RandomNumberGenerator.new()
	bush_rng.seed = FOREST_SEED + 1
	var constants := forest_script.get_script_constant_map()
	var bush_ids: Array = constants["BUSH_IDS"]
	var reference: Vector2 = constants["CELL_REFERENCE"]
	var drop: float = constants["BUSH_DROP"]
	for cell: Vector2i in _forest_cells:
		if bushed.has(cell) or forest_script.call(&"is_covered", cell, trees):
			continue
		var foot := Vector2(cell) + reference + Vector2(
			bush_rng.randf_range(-0.15, 0.15), drop)
		kept.append({"kind": &"bush", "id": bush_ids[bush_rng.randi_range(0, 1)],
			"foot": foot, "position": foot * TILE, "scale": 1.0, "flip_h": false,
			"tint": Color.WHITE})
	return kept


## Touffes, fleurs sauvages sur l'herbe rase, en gardant des étendues calmes (prototype :
## 900 tirages, 14 % de fleurs).
func _place_meadow_seeds(root: Node, decals: Node2D) -> void:
	for attempt in MEADOW_ATTEMPTS:
		var p := Vector2(_decor_rng.randf_range(0.5, SIZE.x - 0.5),
			_decor_rng.randf_range(0.5, SIZE.y - 0.5))
		var cell := Vector2i(p)
		if _path_cells.has(cell) or _tall_grass_cells.has(cell) or _forest_cells.has(cell):
			continue
		if _decor_rng.randf() < MEADOW_FLOWER_CHANCE:
			_decal(root, decals, FLOWER_DECAL % _decor_rng.randi_range(1, 8), p * TILE, 1.0)
		else:
			_decal(root, decals, TUFT_DECAL % _decor_rng.randi_range(1, 4), p * TILE, 0.9)
