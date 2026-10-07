extends SceneTree
## Construit game/world/maps/route_2.tscn (Route 2 sud, 42 × 60 cases) d'après la grille
## fonctionnelle `tools/plans/route_2.txt` (jalon 8 T5, docs/tech/jalon-08.md §1.1, §2).
##
##   godot --headless --path . -s res://tools/build_route_2.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)
##
## **La grille fait foi** (géométrie, positions, transition) ; la vue générale peinte
## (`docs/design/reference/route-2-vue-generale-v1.png`) donne la DA et la composition. Modèle :
## `tools/build_route_1.gd` (carte peinte à forêt serrée).
##
## - `Ground` (TileMapLayer **invisible**) = source logique, une case par caractère de la
##   grille : `.` herbe, `=` et `D` chemin, `h` hautes herbes, `v` rebord ; tout le reste
##   (forêt, poste, pierre, souche, pieds des grands arbres, clôtures, buissons, panneaux,
##   arbre dense, barrière, sentiers fermés) est solide. Les emprises des objets peints
##   recouvrent ces mêmes cases (test_route_2 le vérifie).
## - Image : sol peint (masque G = chemin et sentiers fermés, R = pavés déchaussés des deux
##   rangées du bas, continuité de la rue nord de Jadielle), sous-bois [ForestFloor] sur la
##   forêt **et en taches sur la prairie de la lisière** (0,45 / 0,55 au nord des rangées
##   20 / 12, loin du chemin), forêt serrée [DenseForest] plus sombre et plus froide vers le
##   nord ([DenseForest.Shade]), grands arbres repères (C1 et lisière nord), touffes
##   jaune-vert (plus sombres dans H3, sous la canopée), rebord peint, poste de la Forêt de
##   Jade, grande pierre, souche, panneaux, clôtures courtes, enclos de buissons, FUTUR A
##   (`tree_foret_08` réduit et assombri) et FUTUR B (barrière blanche), ronces et troncs
##   couchés de lisière, ombres de canopée au sol, fleurs de plus en plus rares vers le nord.
## - Passages : trois warps PUSH ↓ vers Jadielle au bas du chemin ; la porte du poste, STEP_ON
##   ↑, « FORÊT DE JADE — À venir » (constantes `FOREST_GATE_*` : au J9, seule cette ligne
##   change). Points d'examen (panneaux, FUTUR A / B), déclencheurs des objets cachés.
## - PNJ, Pokémon d'ambiance et objets visibles : `data/npcs/route_2.json` (leurs cases restent
##   libres d'objets ; les arbres de forêt dont le feuillage les cacherait sont retirés).

const PLAN_PATH: String = "res://tools/plans/route_2.txt"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const OUT_PATH: String = "res://game/world/maps/route_2.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_2_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_2.json"
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const SHADOW_MATERIAL: String = "res://game/world/lighting/materials/cast_shadow.tres"
const TALL_GRASS_ID: String = "ground_hautes_herbes_jaune_01"
const GRASS_FRONT: String = "res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png"
const FLOWER_DECAL: String = "res://assets/world/ground/decals/decal_fleur_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"
const TILE: int = 96
const SIZE := Vector2i(42, 60)
const SEED: int = 2028
const DECOR_SEED: int = 2029
const FOREST_SEED: int = 2

const MAP_ID: StringName = &"route_2"
const DISPLAY_NAME: String = "Route 2"
## Sous-titre = celui de la zone (`data/world/zones.json`, T1 du dossier 11).
const REGION: String = "Jadielle — Forêt de Jade"

## Porte du poste (dossier 11 arbitrage 1, jalon-08 §2.2). Au J9 : `FOREST_GATE_SOON` vide,
## `FOREST_GATE_MAP` = carte du poste, `FOREST_GATE_TARGET` = son point d'arrivée.
const FOREST_GATE_CELL := Vector2i(20, 8)
const FOREST_GATE_SOON: String = "Forêt de Jade"
const FOREST_GATE_MAP: StringName = &""
const FOREST_GATE_TARGET: StringName = &"from_forest_gate"
## Retour devant la porte (point d'apparition de la Route 2, tourné vers le sud).
const FOREST_GATE_SPAWN := Vector2i(20, 9)

## Raccord avec Jadielle (jalon-08 §2.1) : [nœud, case, spawn de Jadielle, spawn d'ici].
const SOUTH_EXITS: Array = [
	["ViridianSouthW", Vector2i(19, 59), &"from_route_2_w", "from_viridian_w"],
	["ViridianSouthC", Vector2i(20, 59), &"from_route_2_c", "from_viridian_c"],
	["ViridianSouthE", Vector2i(21, 59), &"from_route_2_e", "from_viridian_e"],
]
const PUSH: int = 1
const STEP_ON: int = 0

## Pavés déchaussés qui cèdent à la terre (rue nord de Jadielle) : rangées du bas du chemin.
const PAVED_ROWS: Array[int] = [58, 59]

## Lisière du dernier tiers (jalon-08 §1.2 B, consigne de Kevin à la validation de la vue) :
## teinte de la forêt selon la rangée, essences bleu-vert au nord.
const SHADE_FROM_ROW: float = 30.0
const SHADE_FULL_ROW: float = 8.0
const SHADE_VALUE: float = 0.72
const SHADE_RED: float = 0.97
const SHADE_BLUE: float = 1.04
const SHADE_WEIGHTS_ROW: float = 20.0
const SHADE_WEIGHTS: Dictionary = {
	&"tree_foret_04": 2.0, &"tree_foret_05": 2.0, &"tree_foret_06": 2.0,
}
## Sous-bois partiel : herbe rase à plus d'une case d'une case ouverte, au nord de ces rangées.
const UNDERGROWTH_ROWS: Array = [[20, 0.45], [12, 0.55]]
const OPEN_CHARS: String = "=hDvR"

## Grands arbres repères : [objet peint, case (pied), nom, miroir].
## C1 (défaut T5) : le feuillu rond `tree_c_01` à l'ouest, le plus étroit `tree_a_01` à l'est,
## réduit et poussé vers l'est dans sa case ([constant LANDMARK_NUDGES]) : le panneau T1 (22, 56)
## touche la colonne du pied (23, 58) et serait caché par une cime large.
## C1 : deux essences différentes de part et d'autre du chemin (pieds `G` de la grille).
## Lisière nord : conifère et grand feuillu sombre, sur des cases de forêt au bord de C3, de
## la montée et du parvis, assombris comme la forêt de leur rangée.
const LANDMARKS: Array = [
	["tree_c_01", Vector2i(17, 58), "TreeStartW", false],
	["tree_a_01", Vector2i(23, 58), "TreeStartE", true],
	["tree_b_01", Vector2i(2, 14), "EdgeTreeC3", false],
	["tree_e_01", Vector2i(28, 13), "EdgeTreeForecourt", true],
	["tree_b_01", Vector2i(10, 22), "EdgeTreeClimbE", true],
	["tree_e_01", Vector2i(4, 25), "EdgeTreeClimbW", false],
]
## Réglages d'un repère : nom → [décalage du pied (cases), échelle].
const LANDMARK_NUDGES: Dictionary = {"TreeStartE": [Vector2(0.3, 0.0), 0.9]}
## Lisière dense (sur des cases de forêt au bord des clairières du dernier tiers, jamais côte
## à côte) : [objet, case d'ancrage, nom].
const EDGE_PROPS: Array = [
	["prop_tronc_couche_01", Vector2i(5, 16), "EdgeLogC3"],
	["prop_ronces_01", Vector2i(11, 16), "EdgeBrambleC3"],
	["prop_ronces_01", Vector2i(2, 8), "EdgeBrambleC3W"],
	["prop_ronces_01", Vector2i(18, 23), "EdgeBrambleC2"],
	["prop_tronc_couche_01", Vector2i(27, 20), "EdgeLogC2"],
]
## Objets fixes de la grille : [objet, case d'ancrage, nom].
const FIXED_PROPS: Array = [
	["bldg_poste_foret_01", Vector2i(20, 8), "ForestGate"],
	["prop_grande_pierre_01", Vector2i(27, 24), "BigStone"],
	["prop_souche_01", Vector2i(14, 42), "Stump"],
	["prop_cloture_piquets_01_court", Vector2i(14, 58), "FenceStartW"],
	["prop_cloture_piquets_01_court", Vector2i(26, 58), "FenceStartE"],
	["prop_cloture_piquets_v_01", Vector2i(34, 44), "ClosedGate"],
	["prop_panneau_01", Vector2i(22, 56), "SignRoute"],
	["prop_panneau_01", Vector2i(23, 9), "SignForest"],
	["prop_panneau_01", Vector2i(33, 42), "SignClosed"],
]
## Petites pierres traversables (pied en cases) : clairière C3.
const STONES: Array[Vector2] = [Vector2(5.4, 8.75)]
## FUTUR A : arbre dense (`tree_foret_08` réduit et assombri) au pied de la case `A`.
const DENSE_TREE_ID: String = "tree_foret_08"
const DENSE_TREE_CELL := Vector2i(4, 19)
const DENSE_TREE_SCALE: float = 0.55
const DENSE_TREE_VALUE: float = 0.7

## Points d'examen : [nœud, ancre (bas-gauche), taille, orientation exigée, dialogue].
const INTERACTABLES: Array = [
	["SignRoute", Vector2i(22, 56), Vector2i(1, 1), Vector2i.UP, &"route_2_sign"],
	["SignForest", Vector2i(23, 9), Vector2i(1, 1), Vector2i.UP, &"route_2_forest_sign"],
	["DenseTree", Vector2i(4, 19), Vector2i(1, 1), Vector2i.LEFT, &"route_2_dense_tree"],
	["SignClosed", Vector2i(33, 42), Vector2i(1, 1), Vector2i.UP, &"route_2_closed_sign"],
	["ClosedGate", Vector2i(34, 44), Vector2i(1, 2), Vector2i.RIGHT, &"route_2_closed_gate"],
]
## Objets cachés (comme la Potion de la Route 1) : [nœud, position de la grille, scène].
const HIDDEN_ITEMS: Array = [
	["Route2Item3", "route_2_item_3", &"route_2_item_3"],
	["Route2Item4", "route_2_item_4", &"route_2_item_4"],
]

## Buissons des cases `x` (hors panneaux) : un par case, les trois mélangés.
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Touffes de H3 (sous la canopée) : rangées au nord de celle-ci, valeur multipliée.
const DARK_GRASS_ROW: int = 13
const DARK_GRASS_VALUE: float = 0.86
## Ombres de canopée au sol (images d'ombre existantes, à plat) : probabilité par case
## praticable × t (0 à la rangée SHADE_FROM_ROW, 1 au nord).
const CANOPY_SHADOWS: Array[String] = [
	"res://assets/world/props/tree_a_01_shadow.png",
	"res://assets/world/props/tree_b_01_shadow.png",
	"res://assets/world/props/tree_central_01_shadow.png",
]
const CANOPY_SHADOW_CHANCE: float = 0.4
## Prairie : tirages de touffes et de fleurs ; fleurs de plus en plus rares vers le nord, au
## nord de FLOWER_NORTH_ROW seulement le trèfle (5) et l'herbe sombre (6).
const MEADOW_ATTEMPTS: int = 1000
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWER_NORTH_ROW: int = 20
const NORTH_FLOWERS: Array[int] = [5, 6]
## Dégagement de la forêt autour des PNJ et des objets au sol (cases), comme la Route 1.
const NPC_TREE_CLEAR_X: float = 2.2
const NPC_TREE_CLEAR_Y: float = 3.0
## Demi-largeur (cases) sans buisson de forêt autour d'un objet au sol, sur sa case et celle du
## dessous (T7).
const BALL_CLEAR_X: float = 0.9
const FOREST_CONTACT_SHADOWS: bool = false
## Cime d'un arbre de forêt sur une case praticable au-dessus de lui : au plus ce débord
## (cases), demi-largeur prise en compte (cases, × échelle), échelle minimale avant retrait
## ([method _fit_to_walkable]).
const WALK_OVERLAP_MAX: float = 0.35
const TREE_HALF_WIDTH: float = 0.8
const MIN_FIT_SCALE: float = 0.8
## `WorldLighting.Z_SHADOWS` (les outils ne lisent pas les `class_name` du jeu).
const Z_SHADOWS: int = -2

var _plan: Object
var _tiles: GDScript
var _rules: GDScript
var _forest_script: GDScript
var _shade: Object
var _rng := RandomNumberGenerator.new()
var _decor_rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _path_cells: Dictionary = {}
var _paved_cells: Dictionary = {}
var _forest_cells: Dictionary = {}
var _tall_grass_cells: Dictionary = {}
var _tree_heights: Dictionary = {}


func _init() -> void:
	_plan = PlanGrid.new()
	if not _plan.call(&"load_file", PLAN_PATH):
		push_error("build_route_2 : grille illisible : %s" % _plan.get(&"error"))
		quit(1)
		return
	if Vector2i(_plan.get(&"width"), _plan.get(&"height")) != SIZE:
		push_error("build_route_2 : la grille n'est pas de %s cases" % SIZE)
		quit(1)
		return
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	_forest_script = load("res://game/world/forest/dense_forest.gd")
	_shade = _make_shade()
	_rng.seed = SEED
	_decor_rng.seed = DECOR_SEED
	var root := Node2D.new()
	root.name = "Route2"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", MAP_ID)
	root.set(&"display_name", DISPLAY_NAME)
	root.set(&"region", REGION)
	root.set(&"size", SIZE)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"grass_front", load(GRASS_FRONT))
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	# Source logique seulement (solide, hautes herbes, rebord) : l'image est peinte.
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	_paint_logic(ground)

	var mask_texture := _write_mask()
	if mask_texture == null:
		print("build_route_2 : masque écrit ; importer (--import) puis relancer l'outil")
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
	_attach(root, root, floor_script.call(&"create", SIZE, _undergrowth()) as Node)

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
	_add_interactables(root)
	_add_triggers(root)

	_place_border_decals(root, decals)
	_place_canopy_shadows(root, decals)
	_place_ledge(root, decals)
	_place_landmarks(root, entities)
	_place_props(root, entities)
	_place_bushes(root, entities)
	_place_dense_tree(root, entities)
	_place_tall_grass(root, entities)
	var plan: Array[Dictionary] = _clear_around_npcs(_forest_script.call(&"plan",
		_planted_forest(), SIZE, _landmark_feet(), FOREST_SEED, _shade))
	_forest_script.call(&"place", plan, entities, root, FOREST_CONTACT_SHADOWS)
	_place_meadow_seeds(root, decals)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("route_2 : %s (%d entités, %d objets de forêt, %d décalcomanies, %d nœuds)" % [
		error_string(err), entities.get_child_count(), plan.size(), decals.get_child_count(),
		_count(root)])
	root.free()
	quit()


# --- Plan logique -------------------------------------------------------------------------


func _make_shade() -> Object:
	# Classe interne `DenseForest.Shade`, instanciée depuis le script chargé.
	var shade_class: Variant = _forest_script.get_script_constant_map()["Shade"]
	var shade: Object = shade_class.new()
	shade.set(&"from_row", SHADE_FROM_ROW)
	shade.set(&"full_row", SHADE_FULL_ROW)
	shade.set(&"value", SHADE_VALUE)
	shade.set(&"red", SHADE_RED)
	shade.set(&"blue", SHADE_BLUE)
	shade.set(&"weights_row", SHADE_WEIGHTS_ROW)
	var weights: Dictionary[StringName, float] = {}
	for id: StringName in SHADE_WEIGHTS:
		weights[id] = SHADE_WEIGHTS[id]
	shade.set(&"weights", weights)
	return shade


func _kind_of(mark: String) -> int:
	match mark:
		".":
			return _tiles.Kind.GRASS
		"=", "D":
			return _tiles.Kind.DIRT
		"h":
			return _tiles.Kind.TALL_GRASS
		"v":
			return _tiles.Kind.LEDGE_DOWN
	return _tiles.Kind.FOREST


## Une case de `Ground` par caractère de la grille ; classe les cases (chemin, pavés, forêt,
## hautes herbes) dans l'ordre des rangées (celui dont la forêt serrée dépend).
func _paint_logic(layer: TileMapLayer) -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = _plan.call(&"at", cell)
			var kind := _kind_of(mark)
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(cell, _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))
			match mark:
				"T":
					_forest_cells[cell] = true
				"h":
					_tall_grass_cells[cell] = true
				"=", "D", "a", "b":
					if mark == "=" and PAVED_ROWS.has(y):
						_paved_cells[cell] = true
					else:
						_path_cells[cell] = true


## Masque du sol peint (R = pavés, G = chemin et sentiers fermés). Null tant que l'image
## n'est pas importée.
func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", SIZE, _paved_cells, _path_cells)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MASK_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


## Masque du sous-bois : forêt pleine, plus l'herbe rase éloignée du chemin dans la lisière
## (valeur partielle : taches bruitées).
func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _forest_cells:
		values[cell] = 1.0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _plan.call(&"at", cell) != "." or _near_open(cell):
				continue
			var value := 0.0
			for entry: Array in UNDERGROWTH_ROWS:
				if y < int(entry[0]):
					value = maxf(value, float(entry[1]))
			if value > 0.0:
				values[cell] = value
	return values


## Vrai si une case ouverte (chemin, hautes herbes, porte, rebord, pierre) est à une case au
## plus de [param cell] (8 voisines), comme `plan_aplats.py --lisiere`.
func _near_open(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if OPEN_CHARS.contains(_plan.call(&"at", cell + Vector2i(dx, dy))):
				return true
	return false


## Cases de forêt où la forêt serrée pousse : toutes, sauf celles des objets de lisière et de
## la barrière (posés sur la forêt, plus bas que les arbres).
func _planted_forest() -> Dictionary:
	var taken: Dictionary = {}
	for entry: Array in EDGE_PROPS + FIXED_PROPS:
		for offset: Vector2i in _rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	var forest: Dictionary = {}
	for cell: Vector2i in _forest_cells:
		if not taken.has(cell):
			forest[cell] = true
	return forest


# --- Scène ------------------------------------------------------------------------------


func _add_spawns(root: Node) -> void:
	for entry: Array in SOUTH_EXITS:
		_add_spawn(root, entry[3], entry[1])
	_add_spawn(root, String(FOREST_GATE_TARGET), FOREST_GATE_SPAWN)


func _add_spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
	_attach(root, root.get_node(^"Spawns"), marker)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for entry: Array in SOUTH_EXITS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", &"viridian_city")
		point.set(&"target_spawn", entry[2])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)
	var door := Marker2D.new()
	door.set_script(warp_script)
	door.name = "ForestGateSoon" if not FOREST_GATE_SOON.is_empty() else "ForestGate"
	door.position = _world(FOREST_GATE_CELL)
	door.set(&"trigger", STEP_ON)
	door.set(&"direction", Vector2i.UP)
	door.set(&"target_map", FOREST_GATE_MAP)
	door.set(&"target_spawn", FOREST_GATE_TARGET)
	door.set(&"arrival_facing", Vector2i.DOWN)
	door.set(&"coming_soon", FOREST_GATE_SOON)
	_attach(root, root.get_node(^"Warps"), door)


func _add_interactables(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in INTERACTABLES:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"facing", entry[3])
		point.set(&"dialogue_id", entry[4])
		_attach(root, root.get_node(^"Interactables"), point)


func _add_triggers(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in HIDDEN_ITEMS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(_plan.call(&"cell_of", entry[1]))
		point.set(&"size", Vector2i.ONE)
		point.set(&"direction", Vector2i.ZERO)
		point.set(&"cutscene_id", entry[2])
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


func _add_prop(root: Node, parent: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot.round()
	_attach(root, parent, prop)
	return prop


func _add_prop_at(root: Node, parent: Node, id: String, cell: Vector2i,
		node_name: String) -> Node2D:
	var foot: Vector2 = _rules.call(&"foot_position", StringName(id), cell)
	return _add_prop(root, parent, id, foot, node_name)


func _flip(prop: Node2D, flip: bool) -> void:
	var sprite := prop.get_node_or_null(^"Sprite") as Sprite2D
	if sprite != null:
		sprite.flip_h = flip


func _row_tint(row: float) -> Color:
	return _forest_script.call(&"row_tint", _shade, row)


func _decal(root: Node, parent: Node, texture: String, foot: Vector2, scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture)
	sprite.position = foot
	sprite.scale = Vector2.ONE * scale * _decor_rng.randf_range(0.85, 1.15)
	sprite.flip_h = _decor_rng.randf() < 0.5
	_attach(root, parent, sprite)
	return sprite


## Décalcomanies du bord du chemin : terre et touffes partout, pavés déchaussés seulement
## autour des pavés du bas (continuité de Jadielle).
func _place_border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var cells: Dictionary = _paved_cells.duplicate()
	for cell: Vector2i in _path_cells:
		cells[cell] = true
	var plan: Array = script.call(&"plan", cells, SIZE, SEED)
	var kept: Array[Dictionary] = []
	var paved_top := float(PAVED_ROWS.min() - 1) * TILE
	for decal: Dictionary in plan:
		var paving := String(decal["texture"]).contains("decal_pave")
		if paving and (decal["position"] as Vector2).y < paved_top:
			continue
		# Pas de décalcomanie sur les sentiers fermés au cœur de la forêt (ils restent nets).
		var cell := Vector2i((decal["position"] as Vector2) / TILE)
		if _forest_cells.has(cell):
			continue
		kept.append(decal)
	script.call(&"place", kept, decals, root)


## Ombres de canopée posées à plat sur l'herbe, le chemin et les hautes herbes, de plus en
## plus nombreuses vers le nord (images d'ombre existantes, matériau d'ombre portée).
func _place_canopy_shadows(root: Node, decals: Node2D) -> void:
	var material: Material = load(SHADOW_MATERIAL)
	var index := 0
	for y: int in SIZE.y:
		var t := clampf((SHADE_FROM_ROW - y) / (SHADE_FROM_ROW - SHADE_FULL_ROW), 0.0, 1.0)
		for x: int in SIZE.x:
			var mark: String = _plan.call(&"at", Vector2i(x, y))
			if not ".=h".contains(mark) or _decor_rng.randf() >= CANOPY_SHADOW_CHANCE * t:
				continue
			var sprite := Sprite2D.new()
			sprite.name = "CanopyShadow%03d" % index
			index += 1
			sprite.texture = load(CANOPY_SHADOWS[_decor_rng.randi_range(0, 2)])
			sprite.material = material
			sprite.z_as_relative = false
			sprite.z_index = Z_SHADOWS
			sprite.position = (Vector2(x, y) + Vector2(_decor_rng.randf_range(0.2, 0.8),
				_decor_rng.randf_range(0.2, 0.8))) * TILE
			sprite.rotation = _decor_rng.randf_range(-0.5, 0.5)
			sprite.scale = Vector2.ONE * _decor_rng.randf_range(1.2, 1.8)
			sprite.flip_h = _decor_rng.randf() < 0.5
			_attach(root, decals, sprite)


func _place_ledge(root: Node, decals: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan.call(&"cells_of", "v"):
		_add_prop_at(root, decals, "relief_rebord_01", cell, "Ledge%02d" % index)
		index += 1


func _place_landmarks(root: Node, entities: Node2D) -> void:
	for entry: Array in LANDMARKS:
		var foot: Vector2 = _landmark_foot(entry) * TILE
		var tree := _add_prop(root, entities, entry[0], foot, entry[2])
		_flip(tree, entry[3])
		if LANDMARK_NUDGES.has(entry[2]):
			var scale: float = LANDMARK_NUDGES[entry[2]][1]
			tree.scale = Vector2(scale, scale)
		tree.modulate = _row_tint(float((entry[1] as Vector2i).y) + 1.0)


func _landmark_feet() -> Array[Vector2]:
	var feet: Array[Vector2] = []
	for entry: Array in LANDMARKS:
		feet.append(_landmark_foot(entry))
	return feet


## Pied d'un repère en cases (règle d'emprise, plus son décalage éventuel).
func _landmark_foot(entry: Array) -> Vector2:
	var foot: Vector2 = _rules.call(&"foot_position", StringName(entry[0]), entry[1])
	var nudge: Vector2 = LANDMARK_NUDGES[entry[2]][0] if LANDMARK_NUDGES.has(entry[2]) \
		else Vector2.ZERO
	return foot / TILE + nudge


func _place_props(root: Node, entities: Node2D) -> void:
	for entry: Array in FIXED_PROPS:
		_add_prop_at(root, entities, entry[0], entry[1], entry[2])
	for entry: Array in EDGE_PROPS:
		var prop := _add_prop_at(root, entities, entry[0], entry[1], entry[2])
		_flip(prop, _decor_rng.randf() < 0.5)
		prop.modulate = _row_tint(float((entry[1] as Vector2i).y) + 1.0)
	var index := 0
	for foot: Vector2 in STONES:
		_add_prop(root, entities, "prop_pierres_01", foot * TILE, "Stones%02d" % index)
		index += 1


## Un buisson par case `x` qui n'est pas un panneau : les trois images mélangées (jamais la
## même que la voisine de gauche ou du dessus), miroir, taille et teinte variées, plus sombres
## au nord.
func _place_bushes(root: Node, entities: Node2D) -> void:
	var signs: Dictionary = {}
	for entry: Array in FIXED_PROPS:
		if entry[0] == "prop_panneau_01":
			signs[entry[1]] = true
	var chosen: Dictionary = {}
	var index := 0
	for cell: Vector2i in _plan.call(&"cells_of", "x"):
		if signs.has(cell):
			continue
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id \
					and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[_decor_rng.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush := _add_prop_at(root, entities, id, cell, "Bush%02d" % index)
		index += 1
		_flip(bush, _decor_rng.randf() < 0.5)
		var scale := _decor_rng.randf_range(0.9, 1.12)
		bush.scale = Vector2(scale, scale)
		var value := _decor_rng.randf_range(0.92, 1.08)
		bush.modulate = Color(value, value, value) * _row_tint(float(cell.y) + 1.0)


## FUTUR A : l'arbre dense qui ferme le sentier de l'ouest (case `A`, déjà solide).
func _place_dense_tree(root: Node, entities: Node2D) -> void:
	var tree := _add_prop_at(root, entities, DENSE_TREE_ID, DENSE_TREE_CELL, "DenseTreeFuturA")
	tree.scale = Vector2(DENSE_TREE_SCALE, DENSE_TREE_SCALE)
	var tint := _row_tint(float(DENSE_TREE_CELL.y) + 1.0)
	tree.modulate = Color(tint.r * DENSE_TREE_VALUE, tint.g * DENSE_TREE_VALUE,
		tint.b * DENSE_TREE_VALUE)


## Deux touffes jaune-vert par case de hautes herbes, décalées et de tailles variées ; H3
## (sous la canopée) plus sombre. Non solides ; la donnée `tall_grass` est dans Ground.
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
			if cell.y < DARK_GRASS_ROW:
				tuft.modulate = Color(DARK_GRASS_VALUE, DARK_GRASS_VALUE, DARK_GRASS_VALUE)


## Cases des objets au sol (verbe « take » du fichier de la carte).
func _ball_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NPCS_PATH))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		if entry.get("verb", "") == "take":
			cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
	return cells


## Vrai si un buisson de forêt au pied [param foot] cacherait un objet au sol (T7 : la Ball
## doit rester lisible) : buisson dans la case de l'objet ou dans celle juste au-dessous.
func _hides_ball(foot: Vector2) -> bool:
	for cell: Vector2i in _ball_cells():
		if absf(foot.x - (cell.x + 0.5)) < BALL_CLEAR_X \
				and foot.y > cell.y + 0.5 and foot.y < cell.y + 2.0:
			return true
	return false


## Cases des PNJ, Pokémon et objets du fichier de la carte (départ et routines).
func _npc_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NPCS_PATH))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
		if entry.has("route"):
			for cell: Array in entry["route"]["cells"]:
				cells.append(Vector2i(int(cell[0]), int(cell[1])))
	return cells


## Comme la Route 1 : retire les arbres de forêt dont le feuillage cacherait un PNJ, un
## Pokémon ou un objet au sol (niches de la grille), et garnit de buissons les cases de forêt
## qui ne sont plus couvertes.
func _clear_around_npcs(plan: Array[Dictionary]) -> Array[Dictionary]:
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
		var fitted := _fit_to_walkable(entry)
		if near or fitted <= 0.0:
			removed = true
			continue
		entry["scale"] = fitted
		kept.append(entry)
		trees.append(foot)
	var hidden := false
	for entry: Dictionary in plan:
		hidden = hidden or (entry["kind"] == &"bush" and _hides_ball(entry["foot"]))
	if not removed and not hidden:
		return plan
	var bushed: Dictionary = {}
	for entry: Dictionary in plan:
		if entry["kind"] == &"bush" and not _hides_ball(entry["foot"]):
			kept.append(entry)
			bushed[Vector2i(floori(entry["foot"].x), floori(entry["foot"].y - 0.95))] = true
	var bush_rng := RandomNumberGenerator.new()
	bush_rng.seed = FOREST_SEED + 1
	var constants := _forest_script.get_script_constant_map()
	var bush_ids: Array = constants["BUSH_IDS"]
	var reference: Vector2 = constants["CELL_REFERENCE"]
	var drop: float = constants["BUSH_DROP"]
	for cell: Vector2i in _planted_forest():
		if bushed.has(cell) or _forest_script.call(&"is_covered", cell, trees):
			continue
		var foot := Vector2(cell) + reference + Vector2(
			bush_rng.randf_range(-0.15, 0.15), drop)
		if _hides_ball(foot):
			continue
		kept.append({"kind": &"bush", "id": bush_ids[bush_rng.randi_range(0, 1)],
			"foot": foot, "position": foot * TILE, "scale": 1.0, "flip_h": false,
			"tint": _row_tint(foot.y)})
	return kept


## Échelle d'un arbre de forêt pour que sa cime ne descende pas de plus de
## [constant WALK_OVERLAP_MAX] case sur une case praticable au-dessus de lui (règle du couvert
## de [DenseForest] : 3 cases, alors que l'image fait 3 cases de haut au-dessus d'un pied tiré
## n'importe où dans sa case ; le joueur qui longe la lisière par le nord était caché jusqu'à la
## tête). Échelle réduite au besoin jusqu'à [constant MIN_FIT_SCALE] ; en dessous : 0 (arbre
## retiré, la case reçoit un buisson, comme les bords de chemin de la vue générale).
func _fit_to_walkable(entry: Dictionary) -> float:
	var foot: Vector2 = entry["foot"]
	var scale: float = entry["scale"]
	var height := _tree_height(String(entry["id"]))
	var reach := TREE_HALF_WIDTH * scale
	var lowest_free := -INF
	for x: int in range(floori(foot.x - reach), floori(foot.x + reach) + 1):
		for y: int in range(floori(foot.y - height * scale) - 1, floori(foot.y) + 1):
			if _plan.call(&"is_walkable", Vector2i(x, y)):
				lowest_free = maxf(lowest_free, float(y + 1))
	if lowest_free == -INF:
		return scale
	var allowed := (foot.y - (lowest_free - WALK_OVERLAP_MAX)) / height
	if allowed >= scale:
		return scale
	return allowed if allowed >= MIN_FIT_SCALE else 0.0


## Hauteur de l'image d'un arbre de forêt, en cases.
func _tree_height(id: String) -> float:
	if not _tree_heights.has(id):
		var node := _scene(id).instantiate()
		var sprite := node.get_node(^"Sprite") as Sprite2D
		_tree_heights[id] = float(sprite.texture.get_height()) / TILE
		node.free()
	return _tree_heights[id]


## Touffes et fleurs sauvages sur l'herbe rase : fleurs de plus en plus rares vers le nord ;
## au nord de [constant FLOWER_NORTH_ROW], seulement le trèfle et l'herbe sombre.
func _place_meadow_seeds(root: Node, decals: Node2D) -> void:
	for attempt in MEADOW_ATTEMPTS:
		var p := Vector2(_decor_rng.randf_range(0.5, SIZE.x - 0.5),
			_decor_rng.randf_range(0.5, SIZE.y - 0.5))
		var cell := Vector2i(p)
		if _plan.call(&"at", cell) != ".":
			continue
		var north := clampf((p.y - 8.0) / 44.0, 0.0, 1.0)
		if _decor_rng.randf() < MEADOW_FLOWER_CHANCE * (0.25 + 0.75 * north):
			var flower: int = _decor_rng.randi_range(1, 8)
			if p.y < FLOWER_NORTH_ROW:
				flower = NORTH_FLOWERS[_decor_rng.randi_range(0, NORTH_FLOWERS.size() - 1)]
			_decal(root, decals, FLOWER_DECAL % flower, p * TILE, 1.0)
		else:
			var tuft := _decal(root, decals, TUFT_DECAL % _decor_rng.randi_range(1, 4),
				p * TILE, 0.9)
			tuft.modulate = _row_tint(p.y)


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
