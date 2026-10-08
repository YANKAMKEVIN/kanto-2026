extends SceneTree
## Construit game/world/maps/viridian_forest.tscn (Forêt de Jade, 70 × 90 cases) d'après la
## grille fonctionnelle `tools/plans/viridian_forest.txt` (jalon 9 T19, docs/tech/jalon-09.md
## §2.7.4, §2.7.5, §2.8 ; forêt agrandie du 2026-10-08 : §7).
##
##   godot --headless --path . -s res://tools/build_viridian_forest.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/foret-jade-vue-generale-v1.png`) donne la DA : forêt sombre bleu-vert,
## sous-bois irrégulier (jamais de haies taillées), une seule grande souche, lumière chaude
## seulement dans les trouées. Modèle : `tools/build_route_2.gd` (deux passes masque / scène).
##
## - `Ground` (TileMapLayer **invisible**) = source logique, une case par caractère : `.`, `C`,
##   `L` herbe rase, `=`, `g`, `D` chemin, `h` hautes herbes ; tout le reste (forêt, poste,
##   repères, souches, racines) est solide. Les emprises des objets peints recouvrent ces mêmes
##   cases (test_viridian_forest le vérifie).
## - Image : sol peint (masque G = sentier), sous-bois [ForestFloor] plein sur la forêt et **en
##   taches** sur les bandes de sous-bois `.` (bord irrégulier, pas de haie), décalcomanies de
##   sous-bois (fougères, mousse, feuilles, racines, champignons) semées à graine fixe le long
##   des bandes et des lisières, forêt serrée [DenseForest] **uniformément plus sombre et plus
##   froide** que la Route 2 (encore plus au cœur), arbres des clairières, ronces et troncs
##   couchés de lisière, touffes jaune-vert (H3 plus sombre, sous la canopée), ombres de canopée
##   au sol (moins dans les clairières, aucune sous le rai), fleurs rares des clairières, rai de
##   lumière de C3 et quelques taches sur le sentier (Godot, sans image).
## - **Budget de nœuds** (≤ 3 000) : arbres et buissons de forêt, touffes d'herbes = un
##   `Sprite2D` chacun ([method DenseForest.place_sprites]) au lieu d'une scène `WorldProp` (deux
##   nœuds) ; tri de visibilité [method DenseForest.cull_hidden].
## - Passages : sortie sud (2 cases, PUSH ↓) vers le poste sud ; porte du poste nord (STEP_ON ↑).
##   Déclencheurs des 3 objets cachés. PNJ, Dresseurs, Pokémon d'ambiance et objets visibles :
##   `data/npcs/viridian_forest.json` (les arbres qui les cacheraient sont retirés).

const PLAN_PATH: String = "res://tools/plans/viridian_forest.txt"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const OUT_PATH: String = "res://game/world/maps/viridian_forest.tscn"
const MASK_PATH: String = "res://assets/world/maps/viridian_forest_ground.png"
const NPCS_PATH: String = "res://data/npcs/viridian_forest.json"
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const SHADOW_MATERIAL: String = "res://game/world/lighting/materials/cast_shadow.tres"
const TALL_GRASS_ID: String = "ground_hautes_herbes_jaune_01"
const GRASS_FRONT: String = "res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png"
const FLOWER_DECAL: String = "res://assets/world/ground/decals/decal_fleur_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"
const UNDERGROWTH_DECAL: String = "res://assets/world/ground/decals/decal_sousbois_%d.png"
const TILE: int = 96
const SIZE := Vector2i(70, 90)
const SEED: int = 2091
const DECOR_SEED: int = 2092
const FOREST_SEED: int = 9
## Tirages de [method DenseForest.plan] : 9 000 pour 58 × 74 (T19), même densité de départ sur
## 70 × 90 (jalon-09.md §7.4).
const FOREST_ATTEMPTS: int = 13200
## Densité selon la distance au praticable (§7.4, budget de nœuds) : au-delà de
## [constant FAR_DISTANCE] cases (Tchebychev) de toute case praticable (marges, cœur des
## massifs), un arbre sur [constant FAR_KEEP_ONE_IN] gardé, agrandi de [constant FAR_SCALE] ;
## aucun garnissage (le sous-bois sombre et les grandes cimes suffisent).
const FAR_DISTANCE: int = 6
const FAR_KEEP_ONE_IN: int = 3
const FAR_SCALE: float = 1.3

const MAP_ID: StringName = &"viridian_forest"
const DISPLAY_NAME: String = "Forêt de Jade"
## Sous-titre = celui de la zone (`data/world/zones.json`).
const REGION: String = "Jadielle — Argenta"
const LIGHT_PROFILE: StringName = &"forest"

## Passages (jalon-09.md §2.7.2, §6.13 point 7) : [nœud, position de la grille].
const SOUTH_EXITS: Array = [["ToGateSouthW", "warp_sud_w"], ["ToGateSouthE", "warp_sud_e"]]
const GATE_SOUTH: StringName = &"viridian_forest_gate_south"
const GATE_NORTH: StringName = &"viridian_forest_gate_north"
const PUSH: int = 1
const STEP_ON: int = 0

## Forêt uniformément plus sombre et plus froide que la Route 2 (§2.8.2) : Shade réglé pour que
## toute la carte soit « au nord » (effet entier), essences bleu-vert (04, 05, 06) poids × 2
## partout ; au cœur (pied à plus de [constant CORE_DISTANCE] cases d'une case praticable),
## valeur ramenée de [constant SHADE_VALUE] à [constant CORE_VALUE].
const SHADE_VALUE: float = 0.78
const SHADE_RED: float = 0.97
const SHADE_BLUE: float = 1.05
const CORE_VALUE: float = 0.72
const CORE_DISTANCE: float = 4.0
const SHADE_WEIGHTS: Dictionary = {
	&"tree_foret_04": 2.0, &"tree_foret_05": 2.0, &"tree_foret_06": 2.0,
}
## Sous-bois partiel des bandes `.` (taches bruitées du shader, comme la lisière de la Route 2).
const UNDERGROWTH_STRIP: float = 0.5

## Repères et objets fixes de la grille : [objet, case d'ancrage, nom, miroir].
const FIXED_PROPS: Array = [
	["bldg_poste_foret_01", Vector2i(28, 5), "ForestGate", false],
	["prop_tronc_incline_01", Vector2i(43, 78), "LeaningTrunk", false],
	["prop_grande_souche_01", Vector2i(29, 56), "BigStump", false],
	["prop_racines_01", Vector2i(5, 49), "Roots", false],
	["prop_sac_rando_01", Vector2i(45, 42), "HikerBag", false],
	["prop_souche_01", Vector2i(23, 7), "StumpForecourt", false],
	["prop_souche_01", Vector2i(40, 42), "StumpHiker", true],
]
## Caractère de la grille sous chaque objet fixe (test_viridian_forest).
const FIXED_MARKS: Dictionary = {
	"ForestGate": "P", "LeaningTrunk": "I", "BigStump": "S", "Roots": "r",
	"StumpForecourt": "s", "StumpHiker": "s",
}
## Teinte des petites souches (± 8 %, §2.8.2 : jamais à l'écran ensemble).
const STUMP_TINTS: Dictionary = {"StumpForecourt": 0.92, "StumpHiker": 1.06}
## Arbres des clairières (§2.8.1 : 2 à 3 par clairière, sur des cases `T` du bord, jamais deux
## fois le même côte à côte ; aucun arbre neuf) : [objet, case (pied), nom, miroir]. Posés au
## bord **nord** ou sur les côtés des clairières : leur cime monte sur la forêt, pas sur le
## sentier. Forêt agrandie : au nord de C2 (H3), de C3 (H5) et de la boucle de la randonneuse
## (sentier), la forêt n'a que 2 ou 3 rangées : leurs arbres passent sur les côtés (défauts).
const CLEARING_TREES: Array = [
	["tree_b_01", Vector2i(50, 78), "TreeC1East", false],
	["tree_a_01", Vector2i(35, 80), "TreeC1West", true],
	["tree_a_01", Vector2i(19, 56), "TreeC2West", false],
	["tree_c_01", Vector2i(36, 54), "TreeC2NorthEast", false],
	["tree_a_01", Vector2i(29, 27), "TreeC3West", true],
	["tree_b_01", Vector2i(45, 28), "TreeC3East", false],
	["tree_a_01", Vector2i(49, 44), "TreeHiker", false],
	["tree_e_01", Vector2i(8, 6), "TreeH4North", true],
	["tree_b_01", Vector2i(13, 6), "TreeH4NorthEast", false],
	["tree_c_01", Vector2i(53, 2), "TreeO5North", true],
	["tree_b_01", Vector2i(34, 5), "TreeForecourtEast", true],
	["tree_c_01", Vector2i(23, 5), "TreeForecourtWest", false],
]
## Lisière (sur des cases de forêt au bord des clairières) : [objet, case d'ancrage, nom].
const EDGE_PROPS: Array = [
	["prop_ronces_01", Vector2i(21, 54), "EdgeBrambleC2"],
	["prop_tronc_couche_01", Vector2i(36, 25), "EdgeLogC3"],
	["prop_ronces_01", Vector2i(48, 78), "EdgeBrambleC1"],
	["prop_tronc_couche_01", Vector2i(4, 18), "EdgeLogH4"],
	["prop_ronces_01", Vector2i(52, 9), "EdgeBrambleO5"],
]
## Objets cachés : [nœud, position de la grille = scène].
const HIDDEN_ITEMS: Array = [
	["ForestItem3", "viridian_forest_item_3"],
	["ForestItem4", "viridian_forest_item_4"],
	["ForestItem6", "viridian_forest_item_6"],
]

## Touffes des zones d'herbes sous la canopée (H3, H5 : positions « herbes » de la grille, une
## case dans la zone) : valeur multipliée.
const DARK_GRASS_ZONES: Array[String] = ["herbes_h3", "herbes_h5"]
const DARK_GRASS_VALUE: float = 0.86
## Ombres de canopée au sol (images d'ombre existantes, à plat) : probabilité par caractère.
const CANOPY_SHADOWS: Array[String] = [
	"res://assets/world/props/tree_a_01_shadow.png",
	"res://assets/world/props/tree_b_01_shadow.png",
	"res://assets/world/props/tree_central_01_shadow.png",
]
const CANOPY_SHADOW_CHANCE: Dictionary = {".": 0.3, "=": 0.18, "h": 0.12, "C": 0.12}
## Sous-bois semé : décalcomanies par case `.`, et sur les cases de forêt et de clairière au
## bord d'une case de l'autre sorte (lisière irrégulière).
const UNDERGROWTH_PER_STRIP: float = 0.45
const UNDERGROWTH_EDGE_CHANCE: float = 0.15
## Part des décalcomanies du bord du sentier gardées (budget de nœuds : le sentier fait
## ≈ 700 cases ; les bandes de sous-bois le bordent déjà ; 0,4 au T19, 0,2 forêt agrandie : premier repli du §7.4).
const BORDER_KEEP: float = 0.2
## Clairières : tirages de touffes et de fleurs (fleurs rares : 1, 3, 5, 6 seulement).
const MEADOW_ATTEMPTS: int = 420
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 3, 5, 6]
## Dégagement de la forêt autour des PNJ et des objets au sol (cases), comme la Route 2 ; plus
## étroit pour un Pokémon d'ambiance posé sur une case de forêt (seuls les arbres juste devant
## lui sont retirés : il reste « dans » la forêt).
const NPC_TREE_CLEAR_X: float = 2.2
const NPC_TREE_CLEAR_Y: float = 3.0
const PERCH_CLEAR_X: float = 1.3
const PERCH_CLEAR_Y: float = 2.2
const BALL_CLEAR_X: float = 0.9
## Repères posés contre la forêt et dégagés comme un Pokémon perché (aucun arbre juste devant) :
## l'amas de racines d'O4 et la case d'O4 où l'on se tient (sinon cachés par la lisière sud).
const CLEAR_LIKE_PERCH: Array[Vector2i] = [Vector2i(5, 49), Vector2i(6, 49)]
## Cime d'un arbre de forêt sur une case praticable au-dessus de lui (voir build_route_2.gd).
const WALK_OVERLAP_MAX: float = 0.35
const TREE_HALF_WIDTH: float = 0.8
const MIN_FIT_SCALE: float = 0.8
## Garnissage des bandes de forêt trop étroites pour un arbre (règle du couvert) : au lieu des
## buissons fleuris de Bourg Palette (rangées claires = « haies taillées », réserve de la vue
## validée), de **jeunes arbres de forêt** réduits et assombris, d'échelle tirée dans
## [SHRUB_SCALE_MIN, SHRUB_SCALE_MAX] puis réduite pour que la cime ne déborde pas de plus de
## [constant WALK_OVERLAP_MAX] case sur une case praticable au-dessus (au plus bas
## [constant SHRUB_SCALE_FLOOR]) ; valeur multipliée par [SHRUB_VALUE_MIN, SHRUB_VALUE_MAX].
const SHRUB_SCALE_MIN: float = 0.42
const SHRUB_SCALE_MAX: float = 0.74
## Écart horizontal du pied (cases) et part des cases laissées au sous-bois : une bande d'une
## case ne se lit pas comme une rangée plantée.
const SHRUB_JITTER_X: float = 0.3
const SHRUB_SKIP: float = 0.22
const SHRUB_SCALE_FLOOR: float = 0.4
const SHRUB_VALUE_MIN: float = 0.78
const SHRUB_VALUE_MAX: float = 0.92
const SHRUB_CLEAR_X: float = 1.6
const SHRUB_CLEAR_Y: float = 1.6
## Rai de lumière (C3, cases `L`) et taches sur le sentier (§2.7.5) : [centre de la tache au
## sol (cases), taille de la tache (cases), intensité du rai (0 = tache seule)].
const LIGHT_SPOTS: Array = [
	[Vector2(37.0, 28.5), Vector2(5.0, 3.2), 1.0],
	[Vector2(45.0, 82.0), Vector2(2.6, 1.8), 0.45],
	[Vector2(28.0, 61.0), Vector2(3.0, 2.0), 0.5],
	[Vector2(50.0, 31.0), Vector2(2.4, 1.6), 0.0],
	[Vector2(27.5, 9.0), Vector2(2.6, 1.8), 0.4],
	[Vector2(20.0, 42.0), Vector2(2.4, 1.6), 0.0],
	[Vector2(48.0, 19.0), Vector2(2.4, 1.6), 0.3],
]
## Couleur chaude des trouées (additive) ; le rai descend du haut-gauche (soleil du jeu).
## Plus orangée que le premier réglage (T19) : additive sur l'herbe, un jaune clair tirait au
## citron ; la lumière chaude ne vit que dans les trouées (forêt plus sombre à venir).
const LIGHT_COLOR := Color(1.0, 0.8, 0.46)
const SPOT_ALPHA: float = 0.4
const RAY_ALPHA: float = 0.3
const PATH_SPOT_GAIN: float = 0.55
## Rais qui portent des particules végétales (index de `LIGHT_SPOTS` : C3, C1, C2) ; chacun
## `PARTICLE_COUNT` grains au plus (§2.7.5 : ≤ 12), très lents, dérivant dans le sens du rai.
const PARTICLE_SPOTS: Array[int] = [0, 1, 2]
const PARTICLE_COUNT: int = 9
const PARTICLE_LIFETIME: float = 7.0
const RAY_LENGTH: float = 7.0
const RAY_SLANT: float = 0.55
## `WorldLighting.Z_SHADOWS`, `Z_GROUND_DECALS` (les outils ne lisent pas les `class_name`).
const Z_SHADOWS: int = -2
const Z_DECALS: int = -1
## Au-dessus des cimes (tri de `Entities` à z 0) : le rai passe devant les arbres.
const Z_RAYS: int = 5

var _plan: Object
var _tiles: GDScript
var _rules: GDScript
var _forest_script: GDScript
var _shade: Object
var _rng := RandomNumberGenerator.new()
var _decor_rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _models: Dictionary = {}
var _path_cells: Dictionary = {}
var _forest_cells: Dictionary = {}
var _tall_grass_cells: Dictionary = {}
var _tree_heights: Dictionary = {}
var _distance: Dictionary = {}


func _init() -> void:
	_plan = PlanGrid.new()
	if not _plan.call(&"load_file", PLAN_PATH):
		push_error("build_viridian_forest : grille illisible : %s" % _plan.get(&"error"))
		quit(1)
		return
	if Vector2i(_plan.get(&"width"), _plan.get(&"height")) != SIZE:
		push_error("build_viridian_forest : la grille n'est pas de %s cases" % SIZE)
		quit(1)
		return
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	_forest_script = load("res://game/world/forest/dense_forest.gd")
	_shade = _make_shade()
	_rng.seed = SEED
	_decor_rng.seed = DECOR_SEED
	var root := Node2D.new()
	root.name = "ViridianForest"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", MAP_ID)
	root.set(&"display_name", DISPLAY_NAME)
	root.set(&"region", REGION)
	root.set(&"size", SIZE)
	root.set(&"light_profile", LIGHT_PROFILE)
	root.set(&"grass_front", load(GRASS_FRONT))
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	_paint_logic(ground)
	_compute_distances()

	var mask_texture := _write_mask()
	if mask_texture == null:
		print("build_viridian_forest : masque écrit ; importer (--import) puis relancer l'outil")
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
	decals.z_index = Z_DECALS
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
	_place_undergrowth(root, decals)
	_place_canopy_shadows(root, decals)
	_place_meadow_seeds(root, decals)
	_place_fixed(root, entities)
	_place_clearing_trees(root, entities)
	_place_edge_props(root, entities)
	_place_tall_grass(root, entities)
	var raw: Array[Dictionary] = _forest_script.call(&"plan", _planted_forest(), SIZE,
		_landmark_feet(), FOREST_SEED, _shade, FOREST_ATTEMPTS)
	var cleared := _clear_around_npcs(_thin_far(raw))
	var kept: Array[Dictionary] = _forest_script.call(&"cull_hidden", cleared,
		_plan.call(&"cells_of", _plan.get(&"walkable")), SIZE)
	kept = _shrubify(kept)
	_darken_core(kept)
	_forest_script.call(&"place_sprites", kept, entities, root)
	_place_light(root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("viridian_forest : %s (%d entités, forêt %d au plan → %d dégagée → %d gardée, "
		% [error_string(err), entities.get_child_count(), raw.size(), cleared.size(),
		kept.size()] + "%d décalcomanies, %d nœuds)" % [decals.get_child_count(), _count(root)])
	root.free()
	for model: Variant in _models.values():
		(model as Node).free()
	quit()


# --- Plan logique -------------------------------------------------------------------------


func _make_shade() -> Object:
	var shade_class: Variant = _forest_script.get_script_constant_map()["Shade"]
	var shade: Object = shade_class.new()
	# Effet entier partout : toute la carte est « au nord » de full_row.
	shade.set(&"from_row", float(SIZE.y + 200))
	shade.set(&"full_row", float(SIZE.y + 100))
	shade.set(&"value", SHADE_VALUE)
	shade.set(&"red", SHADE_RED)
	shade.set(&"blue", SHADE_BLUE)
	shade.set(&"weights_row", float(SIZE.y + 100))
	var weights: Dictionary[StringName, float] = {}
	for id: StringName in SHADE_WEIGHTS:
		weights[id] = SHADE_WEIGHTS[id]
	shade.set(&"weights", weights)
	return shade


func _kind_of(mark: String) -> int:
	match mark:
		".", "C", "L":
			return _tiles.Kind.GRASS
		"=", "g", "D":
			return _tiles.Kind.DIRT
		"h":
			return _tiles.Kind.TALL_GRASS
	return _tiles.Kind.FOREST


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
				"=", "g", "D":
					_path_cells[cell] = true


## Distance (cases, 8 voisines) de chaque case de forêt à la case praticable la plus proche.
func _compute_distances() -> void:
	var queue: Array[Vector2i] = []
	for cell: Vector2i in _plan.call(&"cells_of", _plan.get(&"walkable")):
		_distance[cell] = 0
		queue.append(cell)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var next := cell + Vector2i(dx, dy)
				if next.x < 0 or next.y < 0 or next.x >= SIZE.x or next.y >= SIZE.y:
					continue
				if not _distance.has(next):
					_distance[next] = int(_distance[cell]) + 1
					queue.append(next)


func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", SIZE, {}, _path_cells)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MASK_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


## Masque du sous-bois : forêt pleine (cases `T` et objets posés dessus), bandes `.` partielles.
func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _forest_cells:
		values[cell] = 1.0
	for cell: Vector2i in _plan.call(&"cells_of", "r"):
		values[cell] = 1.0
	for cell: Vector2i in _plan.call(&"cells_of", "."):
		values[cell] = UNDERGROWTH_STRIP
	return values


## Cases de forêt où la forêt serrée pousse : toutes, sauf celles des objets de lisière et des
## arbres des clairières (posés sur la forêt).
func _planted_forest() -> Dictionary:
	var taken: Dictionary = {}
	for entry: Array in EDGE_PROPS + CLEARING_TREES:
		for offset: Vector2i in _rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	var forest: Dictionary = {}
	for cell: Vector2i in _forest_cells:
		if not taken.has(cell):
			forest[cell] = true
	return forest


# --- Scène ------------------------------------------------------------------------------


func _add_spawns(root: Node) -> void:
	_add_spawn(root, "from_gate_south", _plan.call(&"cell_of", "from_gate_south"))
	_add_spawn(root, "from_gate_north", _plan.call(&"cell_of", "from_gate_north"))
	# Départs de débogage `trainers_qa` / `trainers_weak_qa` (clôture du J9, T23).
	_add_spawn(root, "before_theo", _plan.call(&"cell_of", "before_theo"))


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
		point.position = _world(_plan.call(&"cell_of", entry[1]))
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", GATE_SOUTH)
		point.set(&"target_spawn", &"from_forest")
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)
	var door := Marker2D.new()
	door.set_script(warp_script)
	door.name = "ToGateNorth"
	door.position = _world(_plan.call(&"cell_of", "warp_poste_nord"))
	door.set(&"trigger", STEP_ON)
	door.set(&"direction", Vector2i.UP)
	door.set(&"target_map", GATE_NORTH)
	door.set(&"target_spawn", &"from_forest")
	door.set(&"arrival_facing", Vector2i.UP)
	_attach(root, root.get_node(^"Warps"), door)


func _add_triggers(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in HIDDEN_ITEMS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(_plan.call(&"cell_of", entry[1]))
		point.set(&"size", Vector2i.ONE)
		point.set(&"direction", Vector2i.ZERO)
		point.set(&"cutscene_id", StringName(entry[1]))
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


## `Sprite2D` seul (un nœud) à l'image et au matériau de l'objet peint [param id].
func _add_sprite(root: Node, parent: Node, id: String, foot: Vector2,
		node_name: String) -> Sprite2D:
	if not _models.has(id):
		_models[id] = _forest_script.call(&"painted_sprite_model", StringName(id))
	var sprite := (_models[id] as Sprite2D).duplicate() as Sprite2D
	sprite.name = node_name
	sprite.position = foot.round()
	_attach(root, parent, sprite)
	return sprite


func _flip(prop: Node2D, flip: bool) -> void:
	var sprite := prop.get_node_or_null(^"Sprite") as Sprite2D
	if sprite != null:
		sprite.flip_h = flip


func _forest_tint() -> Color:
	return _forest_script.call(&"row_tint", _shade, 0.0)


func _decal(root: Node, parent: Node, texture: String, foot: Vector2, scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture)
	sprite.position = foot
	sprite.scale = Vector2.ONE * scale * _decor_rng.randf_range(0.85, 1.15)
	sprite.flip_h = _decor_rng.randf() < 0.5
	_attach(root, parent, sprite)
	return sprite


## Décalcomanies du bord du sentier (terre et touffes), comme la Route 2.
func _place_border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var plan: Array = script.call(&"plan", _path_cells, SIZE, SEED)
	var kept: Array[Dictionary] = []
	for decal: Dictionary in plan:
		var cell := Vector2i((decal["position"] as Vector2) / TILE)
		if _forest_cells.has(cell) or String(decal["texture"]).contains("decal_pave"):
			continue
		if _decor_rng.randf() >= BORDER_KEEP:
			continue
		kept.append(decal)
	script.call(&"place", kept, decals, root)


## Sous-bois semé (§2.8.2, réserve « haies taillées ») : fougères, mousse, feuilles mortes,
## racines, brindilles, champignons sur les bandes `.` et à la lisière (cases de forêt qui
## touchent une case ouverte, cases ouvertes qui touchent la forêt) : bord irrégulier.
func _place_undergrowth(root: Node, decals: Node2D) -> void:
	var tint := _forest_tint()
	var index := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = _plan.call(&"at", cell)
			var chance := 0.0
			if mark == ".":
				chance = UNDERGROWTH_PER_STRIP
			elif (mark == "T" and int(_distance.get(cell, 99)) == 1) \
					or (mark == "C" and _touches_forest(cell)):
				chance = UNDERGROWTH_EDGE_CHANCE
			if _decor_rng.randf() >= chance:
				continue
			var foot := (Vector2(cell) + Vector2(_decor_rng.randf_range(0.15, 0.85),
				_decor_rng.randf_range(0.35, 0.95))) * TILE
			var sprite := _decal(root, decals, UNDERGROWTH_DECAL % _decor_rng.randi_range(1, 8),
				foot, 0.95)
			sprite.name = "Undergrowth%03d" % index
			index += 1
			if mark == "T":
				sprite.modulate = tint


func _touches_forest(cell: Vector2i) -> bool:
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _forest_cells.has(cell + direction):
			return true
	return false


## Ombres de canopée posées à plat sur les cases ouvertes : nombreuses sous les couloirs,
## rares dans les clairières, aucune sous le rai ni près des taches de lumière.
func _place_canopy_shadows(root: Node, decals: Node2D) -> void:
	var material: Material = load(SHADOW_MATERIAL)
	var index := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var mark: String = _plan.call(&"at", Vector2i(x, y))
			var chance: float = CANOPY_SHADOW_CHANCE.get(mark, 0.0)
			if _near_light(Vector2(x + 0.5, y + 0.5)) or _decor_rng.randf() >= chance:
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


func _near_light(point: Vector2) -> bool:
	for spot: Array in LIGHT_SPOTS:
		var size: Vector2 = spot[1]
		var d := (point - (spot[0] as Vector2)) / (size * 0.6)
		if d.length() < 1.0:
			return true
	return false


## Touffes et fleurs rares, seulement dans les clairières (`C`, `L`).
func _place_meadow_seeds(root: Node, decals: Node2D) -> void:
	for attempt in MEADOW_ATTEMPTS:
		var p := Vector2(_decor_rng.randf_range(0.5, SIZE.x - 0.5),
			_decor_rng.randf_range(0.5, SIZE.y - 0.5))
		var mark: String = _plan.call(&"at", Vector2i(p))
		if mark != "C" and mark != "L":
			continue
		if _decor_rng.randf() < MEADOW_FLOWER_CHANCE:
			var flower: int = FLOWERS[_decor_rng.randi_range(0, FLOWERS.size() - 1)]
			_decal(root, decals, FLOWER_DECAL % flower, p * TILE, 1.0)
		else:
			_decal(root, decals, TUFT_DECAL % _decor_rng.randi_range(1, 4), p * TILE, 0.9)


func _place_fixed(root: Node, entities: Node2D) -> void:
	for entry: Array in FIXED_PROPS:
		var prop := _add_prop_at(root, entities, entry[0], entry[1], entry[2])
		_flip(prop, entry[3])
		if STUMP_TINTS.has(entry[2]):
			var v: float = STUMP_TINTS[entry[2]]
			prop.modulate = Color(v, v, v)


func _place_clearing_trees(root: Node, entities: Node2D) -> void:
	var tint := _forest_tint()
	for entry: Array in CLEARING_TREES:
		var tree := _add_prop_at(root, entities, entry[0], entry[1], entry[2])
		_flip(tree, entry[3])
		# Moitié moins assombris que la forêt : ils bordent la lumière des clairières.
		tree.modulate = Color.WHITE.lerp(tint, 0.5)


func _place_edge_props(root: Node, entities: Node2D) -> void:
	var tint := _forest_tint()
	for entry: Array in EDGE_PROPS:
		var prop := _add_prop_at(root, entities, entry[0], entry[1], entry[2])
		_flip(prop, _decor_rng.randf() < 0.5)
		prop.modulate = tint


func _landmark_feet() -> Array[Vector2]:
	var feet: Array[Vector2] = []
	for entry: Array in CLEARING_TREES:
		feet.append((_rules.call(&"foot_position", StringName(entry[0]), entry[1]) as Vector2)
			/ TILE)
	return feet


## Deux touffes jaune-vert par case de hautes herbes (un `Sprite2D` chacune, vent) ; H3 plus
## sombre (sous la canopée). Non solides ; la donnée `tall_grass` est dans Ground.
func _place_tall_grass(root: Node, entities: Node2D) -> void:
	var dark := _dark_grass_cells()
	var index := 0
	for cell: Vector2i in _tall_grass_cells:
		for k: int in 2:
			var foot := Vector2(cell) + Vector2(_decor_rng.randf_range(0.25, 0.75),
				0.55 + 0.45 * k)
			var tuft := _add_sprite(root, entities, TALL_GRASS_ID, foot * TILE,
				"Tuft%03d" % index)
			index += 1
			var scale := _decor_rng.randf_range(1.0, 1.3)
			tuft.scale = Vector2(scale, scale)
			tuft.material = load(WIND_MATERIAL)
			tuft.flip_h = _decor_rng.randf() < 0.5
			if dark.has(cell):
				tuft.modulate = Color(DARK_GRASS_VALUE, DARK_GRASS_VALUE, DARK_GRASS_VALUE)


## Distance au praticable de la case du pied [param foot] (cases).
func _foot_distance(foot: Vector2) -> int:
	var cell := Vector2i(clampi(floori(foot.x), 0, SIZE.x - 1),
		clampi(floori(foot.y - 0.01), 0, SIZE.y - 1))
	return int(_distance.get(cell, 0))


## Éclaircit la forêt loin du praticable (voir [constant FAR_DISTANCE]) : arbres gardés un sur
## [constant FAR_KEEP_ONE_IN] (graine fixe) et agrandis ; buissons du plan retirés.
func _thin_far(plan: Array[Dictionary]) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = FOREST_SEED + 3
	var kept: Array[Dictionary] = []
	for entry: Dictionary in plan:
		if _foot_distance(entry["foot"]) < FAR_DISTANCE:
			kept.append(entry)
		elif entry["kind"] == &"tree" and rng.randi_range(1, FAR_KEEP_ONE_IN) == 1:
			entry["scale"] = float(entry["scale"]) * FAR_SCALE
			kept.append(entry)
	return kept


## Cases des zones de [constant DARK_GRASS_ZONES] (composantes 4-connexes de hautes herbes).
func _dark_grass_cells() -> Dictionary:
	var cells: Dictionary = {}
	for zone: String in DARK_GRASS_ZONES:
		var queue: Array[Vector2i] = [_plan.call(&"cell_of", zone) as Vector2i]
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			if cells.has(cell) or not _tall_grass_cells.has(cell):
				continue
			cells[cell] = true
			for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				queue.append(cell + direction)
	return cells


## Cases des PNJ, Pokémon et objets du fichier de la carte (départ et routines) → vrai si la
## case est de la forêt (Pokémon perché).
func _npc_cells() -> Dictionary:
	var cells: Dictionary = {}
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NPCS_PATH))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
		cells[cell] = _forest_cells.has(cell)
		if entry.has("route"):
			for point: Array in entry["route"]["cells"]:
				cells[Vector2i(int(point[0]), int(point[1]))] = false
	for cell: Vector2i in CLEAR_LIKE_PERCH:
		cells[cell] = true
	return cells


func _ball_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NPCS_PATH))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		if entry.get("verb", "") == "take":
			cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
	return cells


## Vrai si un buisson au pied [param foot] cacherait un objet au sol ou un Pokémon perché
## (buisson dans sa case ou juste au-dessous).
func _hides_small(foot: Vector2, cells: Array[Vector2i]) -> bool:
	for cell: Vector2i in cells:
		if absf(foot.x - (cell.x + 0.5)) < BALL_CLEAR_X \
				and foot.y > cell.y + 0.5 and foot.y < cell.y + 2.0:
			return true
	return false


## Comme la Route 2 : retire les arbres de forêt dont le feuillage cacherait un PNJ, un Pokémon
## ou un objet au sol, réduit ceux dont la cime descendrait sur une case praticable, et garnit
## de buissons les cases de forêt qui ne sont plus couvertes.
func _clear_around_npcs(plan: Array[Dictionary]) -> Array[Dictionary]:
	var npcs := _npc_cells()
	var small: Array[Vector2i] = _ball_cells()
	for cell: Vector2i in npcs:
		if npcs[cell]:
			small.append(cell)
	var kept: Array[Dictionary] = []
	var trees: Array[Vector2] = _landmark_feet()
	for entry: Dictionary in plan:
		if entry["kind"] != &"tree":
			continue
		var foot: Vector2 = entry["foot"]
		var near := false
		for cell: Vector2i in npcs:
			var perched: bool = npcs[cell]
			var dx := absf(foot.x - (cell.x + 0.5))
			var dy := foot.y - (cell.y + 1.0)
			if perched and dx < PERCH_CLEAR_X and dy > 0.0 and dy < PERCH_CLEAR_Y:
				near = true
			elif not perched and dx < NPC_TREE_CLEAR_X and dy > -0.5 and dy < NPC_TREE_CLEAR_Y:
				near = true
			if near:
				break
		var fitted := _fit_to_walkable(entry)
		if near or fitted <= 0.0:
			continue
		entry["scale"] = fitted
		kept.append(entry)
		trees.append(foot)
	var bushed: Dictionary = {}
	for entry: Dictionary in plan:
		if entry["kind"] == &"bush" and not _hides_small(entry["foot"], small):
			kept.append(entry)
			bushed[Vector2i(floori(entry["foot"].x), floori(entry["foot"].y - 0.95))] = true
	var bush_rng := RandomNumberGenerator.new()
	bush_rng.seed = FOREST_SEED + 1
	var constants := _forest_script.get_script_constant_map()
	var bush_ids: Array = constants["BUSH_IDS"]
	var reference: Vector2 = constants["CELL_REFERENCE"]
	var drop: float = constants["BUSH_DROP"]
	for cell: Vector2i in _planted_forest():
		if int(_distance.get(cell, 0)) >= FAR_DISTANCE:
			continue
		if bushed.has(cell) or _forest_script.call(&"is_covered", cell, trees):
			continue
		var foot := Vector2(cell) + reference + Vector2(bush_rng.randf_range(-0.15, 0.15), drop)
		if _hides_small(foot, small):
			continue
		kept.append({"kind": &"bush", "id": bush_ids[bush_rng.randi_range(0, 1)],
			"foot": foot, "position": foot * TILE, "scale": 1.0,
			"flip_h": bush_rng.randf() < 0.5, "tint": _forest_tint()})
	return kept


## Garnissage (entrées « buisson » du plan) en jeunes arbres de forêt (voir SHRUB_*). Le nœud
## garde son nom `ForestBush…` ([method DenseForest.place_sprites]).
## Un jeune arbre juste devant un PNJ debout sur une case praticable (pied à moins de
## [constant SHRUB_CLEAR_X] de côté, plus bas de moins de [constant SHRUB_CLEAR_Y]) est retiré :
## il le cacherait (alcôve de Théo).
func _shrubify(entries: Array[Dictionary]) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = FOREST_SEED + 2
	var ids: Array = _forest_script.get_script_constant_map()["TREE_IDS"]
	var npcs := _npc_cells()
	var result: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if entry["kind"] != &"bush":
			result.append(entry)
			continue
		var hides := false
		for cell: Vector2i in npcs:
			var dy: float = entry["foot"].y - (cell.y + 1.0)
			if not npcs[cell] and absf(entry["foot"].x - (cell.x + 0.5)) < SHRUB_CLEAR_X \
					and dy > 0.0 and dy < SHRUB_CLEAR_Y:
				hides = true
		if hides or rng.randf() < SHRUB_SKIP:
			continue
		var moved: Vector2 = entry["foot"] + Vector2(rng.randf_range(-SHRUB_JITTER_X,
			SHRUB_JITTER_X), rng.randf_range(-0.1, 0.05))
		entry["foot"] = moved
		entry["position"] = moved * TILE
		result.append(entry)
		var id := String(ids[rng.randi_range(0, ids.size() - 1)])
		var foot: Vector2 = entry["foot"]
		var height := _tree_height(id)
		var scale := rng.randf_range(SHRUB_SCALE_MIN, SHRUB_SCALE_MAX)
		var lowest_free := -INF
		var reach := TREE_HALF_WIDTH * scale
		for x: int in range(floori(foot.x - reach), floori(foot.x + reach) + 1):
			for y: int in range(floori(foot.y - height * scale) - 1, floori(foot.y)):
				if _plan.call(&"is_walkable", Vector2i(x, y)):
					lowest_free = maxf(lowest_free, float(y + 1))
		if lowest_free > -INF:
			scale = minf(scale, (foot.y - (lowest_free - WALK_OVERLAP_MAX)) / height)
		scale = maxf(scale, SHRUB_SCALE_FLOOR)
		var value := rng.randf_range(SHRUB_VALUE_MIN, SHRUB_VALUE_MAX)
		var tint := _forest_tint()
		entry["id"] = StringName(id)
		entry["scale"] = scale
		entry["flip_h"] = rng.randf() < 0.5
		entry["tint"] = Color(tint.r * value, tint.g * value, tint.b * value)
	return result


## Arbres du cœur (pied à plus de [constant CORE_DISTANCE] cases d'une case praticable) : encore
## plus sombres (§2.8.2).
func _darken_core(entries: Array[Dictionary]) -> void:
	var factor := CORE_VALUE / SHADE_VALUE
	for entry: Dictionary in entries:
		var foot: Vector2 = entry["foot"]
		var cell := Vector2i(clampi(floori(foot.x), 0, SIZE.x - 1),
			clampi(floori(foot.y - 0.01), 0, SIZE.y - 1))
		if int(_distance.get(cell, 0)) > int(CORE_DISTANCE):
			var tint: Color = entry["tint"]
			entry["tint"] = Color(tint.r * factor, tint.g * factor, tint.b * factor, tint.a)


## Échelle d'un arbre de forêt pour que sa cime ne descende pas de plus de
## [constant WALK_OVERLAP_MAX] case sur une case praticable au-dessus de lui (build_route_2.gd).
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


func _tree_height(id: String) -> float:
	if not _tree_heights.has(id):
		var node := _scene(id).instantiate()
		var sprite := node.get_node(^"Sprite") as Sprite2D
		_tree_heights[id] = float(sprite.texture.get_height()) / TILE
		node.free()
	return _tree_heights[id]


## Rai de lumière de C3 et taches des trouées (§2.7.5, §2.8.2) : par Godot, sans image. Tache
## au sol = `Sprite2D` à dégradé radial (additif, z des décalcomanies) ; rai = quadrilatère
## incliné du haut-gauche vers la tache (`Polygon2D`, couleurs aux sommets, additif, au-dessus
## des cimes). Réglages (intensités, particules) : T21.
func _place_light(root: Node) -> void:
	var holder := Node2D.new()
	holder.name = "LightRays"
	_attach(root, root, holder)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(LIGHT_COLOR, SPOT_ALPHA),
		Color(LIGHT_COLOR, SPOT_ALPHA * 0.45), Color(LIGHT_COLOR, 0.0)])
	var spot_texture := GradientTexture2D.new()
	spot_texture.gradient = gradient
	spot_texture.fill = GradientTexture2D.FILL_RADIAL
	spot_texture.fill_from = Vector2(0.5, 0.5)
	spot_texture.fill_to = Vector2(1.0, 0.5)
	spot_texture.width = 128
	spot_texture.height = 128
	var index := 0
	for spot: Array in LIGHT_SPOTS:
		var centre: Vector2 = spot[0]
		var size: Vector2 = spot[1]
		var sprite := Sprite2D.new()
		sprite.name = "LightSpot%d" % index
		sprite.texture = spot_texture
		sprite.material = additive
		sprite.z_as_relative = false
		sprite.z_index = Z_DECALS
		sprite.position = centre * TILE
		sprite.scale = size * TILE / 128.0
		# Sur le sentier (beige), l'additif blanchit : tache plus discrète que sur l'herbe de C3.
		sprite.modulate.a = 1.0 if index == 0 else PATH_SPOT_GAIN
		_attach(root, holder, sprite)
		var strength: float = spot[2]
		if strength > 0.0:
			var ray := Polygon2D.new()
			ray.name = "LightRay%d" % index
			ray.material = additive
			ray.z_as_relative = false
			ray.z_index = Z_RAYS
			var half := size.x * 0.32 * TILE
			var bottom := centre * TILE
			var top := bottom + Vector2(-RAY_SLANT, -1.0) * RAY_LENGTH * TILE * (0.6 + 0.4 * strength)
			var top_half := half * 0.75
			ray.polygon = PackedVector2Array([
				top + Vector2(-top_half, 0), top + Vector2(top_half, 0),
				bottom.lerp(top, 0.35) + Vector2(half * 0.9, 0),
				bottom + Vector2(half, 0), bottom + Vector2(-half, 0),
				bottom.lerp(top, 0.35) + Vector2(-half * 0.9, 0),
			])
			var mid := Color(LIGHT_COLOR, RAY_ALPHA * strength)
			ray.vertex_colors = PackedColorArray([Color(LIGHT_COLOR, 0.0), Color(LIGHT_COLOR, 0.0),
				mid, Color(LIGHT_COLOR, RAY_ALPHA * strength * 0.2),
				Color(LIGHT_COLOR, RAY_ALPHA * strength * 0.2), mid])
			_attach(root, holder, ray)
			if index in PARTICLE_SPOTS:
				_attach(root, holder, _ray_particles(index, bottom, top, half))
		index += 1


## Grains de pollen et brins de feuille dans un rai (T21) : `CPUParticles2D` (≤ 12), additifs,
## émis le long de l'axe du rai, dérive lente vers le bas-droite, fondu entrée / sortie,
## graine fixe, déjà en cours à l'ouverture de la carte (`preprocess`).
func _ray_particles(index: int, bottom: Vector2, top: Vector2, half: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "RayMotes%d" % index
	particles.z_as_relative = false
	particles.z_index = Z_RAYS
	particles.position = bottom.lerp(top, 0.5)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = additive
	var grain := Gradient.new()
	grain.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grain.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = grain
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 16
	texture.height = 16
	particles.texture = texture
	particles.amount = PARTICLE_COUNT
	particles.lifetime = PARTICLE_LIFETIME
	particles.preprocess = PARTICLE_LIFETIME
	particles.use_fixed_seed = true
	particles.seed = 11 + index
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var axis := top - bottom
	particles.emission_rect_extents = Vector2(half * 0.9, absf(axis.y) * 0.42)
	particles.direction = Vector2(0.55, 1.0).normalized()
	particles.spread = 14.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 13.0
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(LIGHT_COLOR, 0.0), Color(LIGHT_COLOR, 0.55),
		Color(LIGHT_COLOR, 0.55), Color(LIGHT_COLOR, 0.0)])
	particles.color_ramp = fade
	return particles


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
