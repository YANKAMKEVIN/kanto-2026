extends SceneTree
## Construit game/world/maps/viridian_city.tscn (Jadielle **agrandie**, 56 × 40 cases) et son
## masque de sol assets/world/maps/viridian_city_ground.png (jalon-07.md §8 T4, §15.4,
## §15.20 : agrandissement décidé par Kevin au T5).
##
##   godot --headless --path . -s res://tools/build_viridian_city.gd [-- --dump]
##   godot --headless --path . --import
##   (la première fois, ou si le masque change : relancer l'outil après l'import, pour que la
##   scène référence le masque importé). `--dump` imprime le plan en caractères.
##
## Décision de Kevin (2026-10-05, T5 sur S24) : Jadielle trop petite et trop plate → on
## agrandit et on suit la **composition de la référence** `jadielle-vue-generale-v1.webp`,
## **sans eau** (dossier 09 §1 : ville dans les terres, bordée de forêt et de relief). La place
## revient au **centre** (abandon de la « place au sud » du T4). Trois niveaux reliés par des
## escaliers de ville :
## - **niveau haut** (rangées 1–11) : l'**arche nord** et la rue vers la Route 2 (« à venir »),
##   l'**Arène fermée** au nord-ouest sur sa terrasse (parvis pavé, escalier qui descend), deux
##   maisons et leurs jardins, chemins de terre secondaires ;
## - mur de soutènement (rangée 12) percé de deux escaliers (Arène, rue nord) ;
## - **niveau de la place** (13–23) : la placette nord, le **Centre** (toit rouge, nord-ouest
##   de l'arbre) et la **Boutique** (toit bleu, nord-est), l'**arbre central** et son massif
##   entre les deux, la rue est-ouest (vers la **Route 22** à l'ouest, chemin de terre à la
##   place du pont de la référence), deux maisons à jardins, le parc ;
## - mur de soutènement (rangée 24) et le **grand escalier sud**, en haut duquel se joue la
##   micro-scène d'arrivée (le premier pas sur la place) ;
## - **niveau bas** (25–33) : l'arrivée entretenue (haies, lampadaires, panneau), deux maisons
##   à jardins clôturés et potagers ;
## - **falaise** (rangée 34) que le chemin de la Route 1 traverse, puis la forêt sauvage.
## Bords : forêt dense et falaises. Sol : `PaintedGround` + masque (R pavés, G chemin) ; aucun
## `TileMapLayer` ; forêt, jardins sous les toits, murs, falaise = `blocked_cells` ; les objets
## peints marquent leur emprise. Murs, escaliers et falaise sont du relief de la couche du sol
## (`GroundDecals`). Habitants : data/npcs/viridian_city.json ; micro-scène :
## data/cutscenes/viridian_city.json.

const OUT_PATH := "res://game/world/maps/viridian_city.tscn"
const MASK_PATH := "res://assets/world/maps/viridian_city_ground.png"
const PROPS_DIR := "res://game/world/props/painted/"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const SIZE := Vector2i(56, 40)
const TILE := 96
## Graines fixes : forêt, décalcomanies du bord des pavés.
const FOREST_SEED := 2026
const DECALS_SEED := 7
## WorldLighting.Z_GROUND_DECALS (les outils ne voient pas les class_name avant import).
const Z_GROUND_DECALS := -1

## Nature d'une case (peinte dans l'ordre de REGIONS) : forêt (bloquée, arbres), jardin
## (bloqué, sans arbre : sous les toits), pelouse, pavés, chemin, mur de soutènement et
## falaise (bloqués, relief peint), escalier (praticable), pré (bloqué, sans arbre : le bas
## de la falaise reste visible).
enum Cell { FOREST, GARDEN, LAWN, PAVING, PATH, WALL, CLIFF, STAIR, MEADOW }
const CHARS := "TgL#:WCSm"

## [nature, rectangle en cases], peints dans l'ordre (le suivant écrase le précédent).
const REGIONS: Array = [
	# Pelouses des trois niveaux, coins nord en forêt.
	[Cell.LAWN, Rect2i(3, 1, 50, 33)],
	[Cell.FOREST, Rect2i(3, 1, 19, 2)],
	[Cell.FOREST, Rect2i(35, 1, 18, 2)],
	# Murs de soutènement (rangées 12 et 24) et falaise du sud (rangée 34) ; pré au pied.
	[Cell.WALL, Rect2i(3, 12, 50, 1)],
	[Cell.WALL, Rect2i(3, 24, 50, 1)],
	[Cell.CLIFF, Rect2i(2, 34, 24, 1)],
	[Cell.CLIFF, Rect2i(31, 34, 24, 1)],
	[Cell.MEADOW, Rect2i(2, 35, 24, 2)],
	[Cell.MEADOW, Rect2i(31, 35, 24, 2)],
	# Jardins sous les toits (bloqués, sans arbre).
	[Cell.GARDEN, Rect2i(4, 3, 12, 3)],
	[Cell.GARDEN, Rect2i(18, 3, 5, 2)],
	[Cell.GARDEN, Rect2i(35, 3, 6, 2)],
	[Cell.GARDEN, Rect2i(13, 13, 13, 5)],
	[Cell.GARDEN, Rect2i(32, 13, 8, 5)],
	[Cell.GARDEN, Rect2i(3, 13, 5, 2)],
	[Cell.GARDEN, Rect2i(44, 13, 6, 2)],
	[Cell.GARDEN, Rect2i(16, 25, 8, 3)],
	[Cell.GARDEN, Rect2i(34, 25, 7, 3)],
	# Pavés : rue nord, parvis de l'Arène, allée de l'Arène, placette nord, rue de la place,
	# portes du Centre et de la Boutique, arrivée sud.
	[Cell.PAVING, Rect2i(27, 0, 3, 12)],
	[Cell.PAVING, Rect2i(4, 10, 13, 2)],
	[Cell.PAVING, Rect2i(9, 13, 3, 9)],
	[Cell.PAVING, Rect2i(26, 13, 6, 9)],
	[Cell.PAVING, Rect2i(9, 22, 40, 2)],
	[Cell.PAVING, Rect2i(21, 21, 2, 1)],
	[Cell.PAVING, Rect2i(35, 21, 2, 1)],
	[Cell.PAVING, Rect2i(27, 25, 3, 6)],
	# Escaliers de ville (praticables) : Arène, rue nord, grand escalier sud.
	[Cell.STAIR, Rect2i(9, 12, 3, 1)],
	[Cell.STAIR, Rect2i(27, 12, 3, 1)],
	[Cell.STAIR, Rect2i(27, 24, 3, 1)],
	# Chemins de terre : liaisons du niveau haut, route de l'ouest (Route 22), allées des
	# maisons, liaisons du niveau bas, chemin de la Route 1 (sauvage).
	[Cell.PATH, Rect2i(17, 10, 10, 2)],
	[Cell.PATH, Rect2i(30, 10, 9, 2)],
	[Cell.PATH, Rect2i(0, 22, 9, 2)],
	[Cell.PATH, Rect2i(20, 8, 1, 2)],
	[Cell.PATH, Rect2i(37, 8, 1, 2)],
	[Cell.PATH, Rect2i(5, 18, 1, 4)],
	[Cell.PATH, Rect2i(46, 18, 1, 4)],
	[Cell.PATH, Rect2i(19, 31, 1, 2)],
	[Cell.PATH, Rect2i(37, 31, 1, 2)],
	[Cell.PATH, Rect2i(19, 33, 8, 1)],
	[Cell.PATH, Rect2i(30, 33, 8, 1)],
	[Cell.PATH, Rect2i(27, 31, 3, 9)],
]

## Cases bloquées sans nature propre : bord nord du chemin (la tête du joueur reste à
## l'écran, comme la Route 1) et piliers des escaliers de ville (trois rangées : l'image
## déborde d'une demi-case au-dessus et au-dessous du mur).
const BLOCKED_EDGE: Array[Vector2i] = [Vector2i(27, 0), Vector2i(28, 0), Vector2i(29, 0)]

## Escaliers de ville : [case du milieu des marches (rangée du mur), nom du nœud]. Marches sur
## trois cases, piliers sur les cases voisines.
const STAIRS: Array = [
	[Vector2i(10, 12), "StairGym"],
	[Vector2i(28, 12), "StairNorth"],
	[Vector2i(28, 24), "StairSouth"],
]
## Descente du pied de l'image de l'escalier sous le bas de la rangée du mur (cases) : les
## marches débordent d'une demi-case sur les deux niveaux.
const STAIR_DROP := 0.5
## Largeur de l'image de l'escalier (cases) : marches (3) et piliers.
const STAIR_WIDTH := 4.5
## Les murs passent un peu sous les piliers (cases) : aucune fente entre mur et pilier.
const WALL_UNDER_PILLAR := 0.3
## Rangées des murs de soutènement, et de la falaise du sud.
const WALL_ROWS: Array[int] = [12, 24]
const CLIFF_ROW := 34

## Objets peints : [identifiant, case d'ancrage, nom du nœud]. Pied posé par
## PaintedPropRules.foot_position (bord ou milieu de case selon la largeur).
const PROPS: Array = [
	[&"bldg_centre_01", Vector2i(22, 21), "PokemonCenter"],
	[&"bldg_boutique_01", Vector2i(36, 21), "PokeMart"],
	[&"bldg_arene_01", Vector2i(10, 9), "Gym"],
	[&"tree_central_01", Vector2i(29, 20), "CentralTree"],
	[&"prop_porte_nord_01", Vector2i(28, 2), "NorthGate"],
	# Six maisons (trois de chaque modèle), chacune avec son jardin.
	[&"bldg_maison_b_01", Vector2i(20, 7), "HouseNorthWest"],
	[&"bldg_maison_a_01", Vector2i(38, 7), "HouseNorthEast"],
	[&"bldg_maison_b_01", Vector2i(5, 17), "HouseWest"],
	[&"bldg_maison_a_01", Vector2i(47, 17), "HouseEast"],
	[&"bldg_maison_a_01", Vector2i(20, 30), "HouseSouthWest"],
	[&"bldg_maison_b_01", Vector2i(37, 30), "HouseSouthEast"],
	# Jardins : potagers, plates-bandes, clôtures et haies qui les ferment.
	[&"prop_potager_01", Vector2i(18, 9), "GardenNorthWestVeg"],
	[&"prop_platebande_01", Vector2i(22, 9), "GardenNorthWestBed"],
	[&"prop_cloture_v_01", Vector2i(16, 9), "GardenNorthWestFence"],
	[&"prop_platebande_01", Vector2i(34, 9), "GardenNorthEastBed"],
	[&"prop_potager_01", Vector2i(40, 9), "GardenNorthEastVeg"],
	[&"prop_cloture_v_01", Vector2i(42, 9), "GardenNorthEastFence"],
	[&"prop_potager_01", Vector2i(7, 19), "GardenWestVeg"],
	[&"prop_platebande_01", Vector2i(7, 21), "GardenWestBed"],
	[&"prop_potager_01", Vector2i(49, 19), "GardenEastVeg"],
	[&"prop_platebande_01", Vector2i(49, 21), "GardenEastBed"],
	[&"prop_haie_v_01", Vector2i(44, 21), "GardenEastHedge"],
	[&"prop_potager_01", Vector2i(17, 32), "GardenSouthWestVeg"],
	[&"prop_platebande_01", Vector2i(22, 32), "GardenSouthWestBed"],
	[&"prop_cloture_v_01", Vector2i(15, 32), "GardenSouthWestFence"],
	[&"prop_platebande_01", Vector2i(35, 32), "GardenSouthEastBed"],
	[&"prop_potager_01", Vector2i(39, 32), "GardenSouthEastVeg"],
	[&"prop_cloture_v_01", Vector2i(41, 32), "GardenSouthEastFence"],
	[&"prop_cloture_01", Vector2i(17, 33), "GardenSouthWestFenceFront"],
	[&"prop_cloture_01", Vector2i(40, 33), "GardenSouthEastFenceFront"],
	# Plates-bandes au bord de la place et au pied des murs ; haies en haut du mur nord et le
	# long de la rue de l'arche.
	[&"prop_platebande_01", Vector2i(42, 21), "BedSquareE"],
	[&"prop_platebande_01", Vector2i(9, 25), "BedSouthW1"],
	[&"prop_platebande_01", Vector2i(44, 25), "BedSouthE1"],
	[&"prop_platebande_01", Vector2i(48, 25), "BedSouthE2"],
	[&"prop_platebande_01", Vector2i(4, 25), "BedSouthW2"],
	[&"prop_haie_01", Vector2i(42, 11), "HedgeTerraceE1"],
	[&"prop_haie_01", Vector2i(46, 11), "HedgeTerraceE2"],
	[&"prop_haie_01", Vector2i(50, 11), "HedgeTerraceE3"],
	[&"prop_haie_v_01", Vector2i(26, 7), "HedgeNorthRoadW"],
	[&"prop_haie_v_01", Vector2i(30, 8), "HedgeNorthRoadE"],
	# L'arrivée entretenue : haies le long du chemin, lampadaires, panneau de la ville.
	[&"prop_haie_v_01", Vector2i(26, 29), "HedgeArrivalW"],
	[&"prop_haie_v_01", Vector2i(30, 29), "HedgeArrivalE"],
	[&"prop_lampadaire_01", Vector2i(26, 30), "LampArrivalW"],
	[&"prop_lampadaire_01", Vector2i(30, 30), "LampArrivalE"],
	[&"prop_panneau_01", Vector2i(26, 31), "SignViridian"],
	# Lampadaires : placette nord, place, parc, ouest, parvis de l'Arène.
	[&"prop_lampadaire_01", Vector2i(26, 14), "LampNorthW"],
	[&"prop_lampadaire_01", Vector2i(31, 14), "LampNorthE"],
	[&"prop_lampadaire_01", Vector2i(17, 21), "LampSquareW"],
	[&"prop_lampadaire_01", Vector2i(40, 21), "LampSquareE"],
	[&"prop_lampadaire_01", Vector2i(8, 16), "LampWest"],
	[&"prop_lampadaire_01", Vector2i(16, 11), "LampGym"],
	# Bancs : la Dresseuse (ouest de la place), le parc.
	[&"prop_banc_01", Vector2i(14, 21), "BenchSquare"],
	[&"prop_banc_01", Vector2i(42, 15), "BenchPark"],
	# Arbres des pelouses (placés à la main).
	[&"tree_a_01", Vector2i(23, 3), "TreeNorth1"],
	[&"tree_b_01", Vector2i(25, 7), "TreeNorth2"],
	[&"tree_a_01", Vector2i(33, 5), "TreeNorth3"],
	[&"tree_b_01", Vector2i(45, 6), "TreeNorth4"],
	[&"tree_a_01", Vector2i(49, 10), "TreeNorth5"],
	[&"tree_b_01", Vector2i(3, 9), "TreeNorth6"],
	[&"tree_a_01", Vector2i(12, 16), "TreeWest1"],
	[&"tree_b_01", Vector2i(15, 19), "TreeWest2"],
	[&"tree_a_01", Vector2i(41, 13), "TreePark1"],
	[&"tree_b_01", Vector2i(43, 19), "TreePark2"],
	[&"tree_a_01", Vector2i(51, 15), "TreeEast1"],
	[&"tree_b_01", Vector2i(51, 21), "TreeEast2"],
	[&"tree_b_01", Vector2i(5, 27), "TreeSouth1"],
	[&"tree_a_01", Vector2i(9, 30), "TreeSouth2"],
	[&"tree_a_01", Vector2i(12, 26), "TreeSouth3"],
	[&"tree_b_01", Vector2i(45, 27), "TreeSouth4"],
	[&"tree_a_01", Vector2i(49, 30), "TreeSouth5"],
	[&"tree_a_01", Vector2i(51, 26), "TreeSouth6"],
	# Rochers du pré, au pied de la falaise.
	[&"prop_rocher_01", Vector2i(7, 36), "RockMeadowW"],
	[&"prop_rocher_01", Vector2i(47, 35), "RockMeadowE"],
]
## Relief posé au sol (GroundDecals, sous les personnages) : le massif de l'arbre central.
const GROUND_PROPS: Array = [
	[&"prop_massif_01", Vector2i(29, 20), "CentralBed"],
]
## Forêt sans arbres : sous la route de l'ouest (les cimes la cacheraient).
const NO_TREES: Array[Rect2i] = [Rect2i(0, 24, 3, 3)]

## Passages. [nœud, case, déclencheur (0 STEP_ON, 1 PUSH), direction, carte, spawn,
## orientation à l'arrivée].
const STEP_ON := 0
const PUSH := 1
const WARPS: Array = [
	# Sud : vers la Route 1 (bord nord de la Route 1, spawns from_viridian_*).
	["Route1W", Vector2i(27, 39), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1C", Vector2i(28, 39), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1E", Vector2i(29, 39), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_e",
		Vector2i.DOWN],
	# Portes du Centre et de la Boutique : les deux cases libres du bas de leur emprise.
	["DoorCenterW", Vector2i(21, 21), STEP_ON, Vector2i.UP, &"viridian_center", &"entrance",
		Vector2i.ZERO],
	["DoorCenterE", Vector2i(22, 21), STEP_ON, Vector2i.UP, &"viridian_center", &"entrance",
		Vector2i.ZERO],
	["DoorMartW", Vector2i(35, 21), STEP_ON, Vector2i.UP, &"viridian_mart", &"entrance",
		Vector2i.ZERO],
	["DoorMartE", Vector2i(36, 21), STEP_ON, Vector2i.UP, &"viridian_mart", &"entrance",
		Vector2i.ZERO],
	# Ouest : la Route 22 (spawn « from_viridian »).
	["Route22N", Vector2i(0, 22), PUSH, Vector2i.LEFT, &"route_22", &"from_viridian",
		Vector2i.LEFT],
	["Route22S", Vector2i(0, 23), PUSH, Vector2i.LEFT, &"route_22", &"from_viridian",
		Vector2i.LEFT],
]
## Sortie nord « à venir » (build de développement, dossier 09 §11) : [nœud, case, spawn de
## retour]. Le libellé est COMING_SOON_LABEL.
const COMING_SOON_LABEL := "Route 2"
const SOON_WARPS: Array = [
	["Route2SoonW", Vector2i(27, 1), &"route_2_soon_w"],
	["Route2SoonC", Vector2i(28, 1), &"route_2_soon_c"],
	["Route2SoonE", Vector2i(29, 1), &"route_2_soon_e"],
]
## Points d'apparition.
const SPAWNS: Dictionary = {
	"from_route_1_w": Vector2i(28, 39),
	"from_route_1_e": Vector2i(29, 39),
	"from_center": Vector2i(21, 21),
	"from_mart": Vector2i(36, 21),
	"from_route_22": Vector2i(0, 22),
	# Retour de l'écran « ROUTE 2 — À venir » : devant l'arche, tourné vers le sud.
	"route_2_soon_w": Vector2i(27, 3),
	"route_2_soon_c": Vector2i(28, 3),
	"route_2_soon_e": Vector2i(29, 3),
}
## Points d'examen : [nœud, ancre (bas-gauche), taille, orientation exigée, dialogue].
## La porte de l'Arène (deux cases du bas de son emprise, au milieu).
const INTERACTABLES: Array = [
	["GymDoor", Vector2i(9, 9), Vector2i(2, 1), Vector2i.UP, &"viridian_gym_door"],
]
## Déclencheurs : [nœud, ancre, taille, direction, scène]. Micro-scène d'arrivée : le premier
## pas sur la place, en haut du grand escalier sud (seul passage vers le nord : mur et piliers
## de part et d'autre).
const TRIGGERS: Array = [
	["ViridianArrival", Vector2i(27, 23), Vector2i(3, 1), Vector2i.UP, &"viridian_arrival"],
]

## Forêt : distance minimale entre deux arbres (cases) et décalage aléatoire du pied (px).
const TREE_SPACING := 1.9
const TREE_JITTER := Vector2(22.0, 16.0)

var _rules: Script
var _cells: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	_paint_cells()
	if "--dump" in OS.get_cmdline_user_args():
		_dump()
	var mask_changed := _write_mask()
	if mask_changed or not ResourceLoader.exists(MASK_PATH):
		print("viridian_city : masque écrit (%s) ; lancer « godot --headless --path . --import »"
			% MASK_PATH + " puis relancer l'outil.")
		if not ResourceLoader.exists(MASK_PATH):
			quit(0)
			return
	var root := _build()
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("viridian_city : %s (%d entités, %d cases bloquées)" % [error_string(err),
		root.get_node(^"Entities").get_child_count(),
		(root.get(&"blocked_cells") as Array).size()])
	root.free()
	quit(0 if err == OK else 1)


func _paint_cells() -> void:
	_cells.resize(SIZE.x * SIZE.y)
	_cells.fill(Cell.FOREST)
	for region: Array in REGIONS:
		var rect: Rect2i = region[1]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_cells[y * SIZE.x + x] = region[0]


func _cell(c: Vector2i) -> int:
	return _cells[c.y * SIZE.x + c.x]


## Plan en caractères (T forêt, g jardin, L pelouse, # pavés, : chemin, W mur, C falaise,
## S escalier, m pré ; x : piliers et bords bloqués).
func _dump() -> void:
	var extra := _extra_blocked()
	var header := "    "
	for x in SIZE.x:
		header += str(x % 10)
	print(header)
	for y in SIZE.y:
		var line := "%3d " % y
		for x in SIZE.x:
			line += "x" if extra.has(Vector2i(x, y)) else CHARS[_cell(Vector2i(x, y))]
		print(line)


## Écrit le masque (R pavés et escaliers, G chemin). Vrai s'il a changé.
func _write_mask() -> bool:
	var image := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	for y in SIZE.y:
		for x in SIZE.x:
			match _cell(Vector2i(x, y)):
				Cell.PAVING, Cell.STAIR:
					image.set_pixel(x, y, Color(1, 0, 0))
				Cell.PATH:
					image.set_pixel(x, y, Color(0, 1, 0))
	var path := ProjectSettings.globalize_path(MASK_PATH)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var before := PackedByteArray()
	if FileAccess.file_exists(path):
		var old := Image.load_from_file(path)
		if old != null:
			old.convert(Image.FORMAT_RGB8)
			before = old.get_data()
	if before == image.get_data():
		return false
	image.save_png(path)
	return true


func _build() -> Node2D:
	_rng.seed = FOREST_SEED
	var root := Node2D.new()
	root.name = "ViridianCity"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"viridian_city")
	root.set(&"display_name", "Jadielle")
	root.set(&"region", "")
	root.set(&"size", SIZE)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"blocked_cells", _blocked_cells())
	var ground: Node2D = (load("res://game/world/ground/painted_ground.gd") as Script).new()
	ground.name = "PaintedGround"
	ground.set(&"size", SIZE)
	ground.set(&"mask", load(MASK_PATH))
	_attach(root, root, ground)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = Z_GROUND_DECALS
	_attach(root, root, decals)
	var border := load("res://game/world/ground/border_decals.gd") as Script
	var plan: Array[Dictionary] = border.call(&"plan", _edge_cells(), SIZE, DECALS_SEED)
	border.call(&"place", plan, decals, root)
	_place_relief(root, decals)
	for entry: Array in GROUND_PROPS:
		_add_prop(root, decals, entry[0], entry[1], entry[2])
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for entry: Array in PROPS:
		_add_prop(root, entities, entry[0], entry[1], entry[2])
	_plant_forest(root, entities)
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	_add_spawns(root)
	_add_warps(root)
	_add_interactables(root)
	_add_triggers(root)
	return root


## Forêt, jardins, murs, falaise, pré, piliers des escaliers et bord du chemin.
func _blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			match _cell(Vector2i(x, y)):
				Cell.FOREST, Cell.GARDEN, Cell.WALL, Cell.CLIFF, Cell.MEADOW:
					cells.append(Vector2i(x, y))
	for cell: Vector2i in _extra_blocked():
		if not cells.has(cell):
			cells.append(cell)
	return cells


## Piliers des escaliers (colonnes voisines des marches, rangée du mur et ses deux voisines)
## et bord nord du chemin.
func _extra_blocked() -> Array[Vector2i]:
	var cells: Array[Vector2i] = BLOCKED_EDGE.duplicate()
	for stair: Array in STAIRS:
		var middle: Vector2i = stair[0]
		for dx: int in [-2, 2]:
			for dy: int in [-1, 0, 1]:
				cells.append(middle + Vector2i(dx, dy))
	return cells


## Cases pavées et du chemin, dans l'ordre de lecture (décalcomanies de leur bord). Les
## escaliers n'en ont pas (leur image couvre la case).
func _edge_cells() -> Dictionary:
	var cells := {}
	for y in SIZE.y:
		for x in SIZE.x:
			var kind := _cell(Vector2i(x, y))
			if kind == Cell.PAVING or kind == Cell.PATH or kind == Cell.STAIR:
				cells[Vector2i(x, y)] = true
	return cells


## Murs de soutènement (tronçons de 4 cases bout à bout, interrompus par les escaliers), puis
## les escaliers par-dessus (leurs piliers couvrent la fin des murs), puis la falaise du sud.
func _place_relief(root: Node, decals: Node) -> void:
	var index := 0
	for row: int in WALL_ROWS:
		for run: Vector2 in _wall_runs(row):
			for left: float in _segments(run):
				_add_prop_at(root, decals, &"relief_muret_01",
					Vector2((left + 2.0) * TILE, (row + 1) * TILE), "Wall%02d" % index)
				index += 1
	for stair: Array in STAIRS:
		var middle: Vector2i = stair[0]
		_add_prop_at(root, decals, &"relief_escalier_ville_01",
			Vector2((middle.x + 0.5) * TILE, (middle.y + 1.0 + STAIR_DROP) * TILE), stair[1])
	index = 0
	var x := 0
	while x < SIZE.x:
		if _cell(Vector2i(x, CLIFF_ROW)) != Cell.CLIFF:
			x += 1
			continue
		# Tronçons de 4 cases alignés sur la grille (emprise de la falaise = sa rangée).
		_add_prop(root, decals, &"relief_falaise_01", Vector2i(x + 2, CLIFF_ROW),
			"Cliff%02d" % index)
		index += 1
		x += 4


## Étendues [début, fin[ (cases) d'un mur de soutènement, sans les escaliers.
func _wall_runs(row: int) -> Array[Vector2]:
	var runs: Array[Vector2] = []
	var start := -1
	for x in SIZE.x + 1:
		var wall := x < SIZE.x and _cell(Vector2i(x, row)) == Cell.WALL
		if wall and start < 0:
			start = x
		elif not wall and start >= 0:
			runs.append(Vector2(start, x))
			start = -1
	# Les escaliers coupent le mur : leur image (marches et piliers) remplace le mur.
	var cut: Array[Vector2] = []
	for run: Vector2 in runs:
		var pieces: Array[Vector2] = [run]
		for stair: Array in STAIRS:
			var middle: Vector2i = stair[0]
			if middle.y != row:
				continue
			var span := Vector2(middle.x + 0.5 - STAIR_WIDTH / 2.0,
				middle.x + 0.5 + STAIR_WIDTH / 2.0)
			var next: Array[Vector2] = []
			for piece: Vector2 in pieces:
				if span.y <= piece.x or span.x >= piece.y:
					next.append(piece)
					continue
				if span.x > piece.x:
					next.append(Vector2(piece.x, span.x + WALL_UNDER_PILLAR))
				if span.y < piece.y:
					next.append(Vector2(span.y - WALL_UNDER_PILLAR, piece.y))
			pieces = next
		cut.append_array(pieces)
	return cut


## Bords gauches des tronçons de 4 cases qui couvrent [param run] : bout à bout depuis le
## début, le dernier aligné sur la fin.
func _segments(run: Vector2) -> Array[float]:
	var lefts: Array[float] = []
	var left := run.x
	while left + 4.0 < run.y:
		lefts.append(left)
		left += 4.0
	lefts.append(maxf(run.x, run.y - 4.0))
	return lefts


## Arbres peints sur les cases de forêt : tirage à graine fixe, espacement minimal, décalage
## léger (l'ancre reste dans sa case, déjà bloquée). Jamais sous l'image d'un objet déjà posé
## (bâtiments, arche, haies : leurs cases sont aussi « forêt » sous l'emprise).
func _plant_forest(root: Node, entities: Node) -> void:
	var covered: Array[Rect2] = []
	var feet: Array[Vector2] = []
	for child: Node in entities.get_children():
		var sprite := child.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null and sprite.texture != null:
			var rect := Rect2((child as Node2D).position + sprite.offset, sprite.texture.get_size())
			covered.append(rect)
			if String(child.name).begins_with("Tree"):
				feet.append((child as Node2D).position / TILE)
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if _cell(cell) != Cell.FOREST or NO_TREES.any(func(r: Rect2i) -> bool:
					return r.has_point(cell)):
				continue
			var foot := Vector2((x + 0.5) * TILE, (y + 1) * TILE - 1.0)
			if covered.any(func(r: Rect2) -> bool: return r.has_point(foot)):
				continue
			cells.append(cell)
	# Ordre mélangé (graine fixe) pour une forêt sans alignement.
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	var index := 0
	for cell: Vector2i in cells:
		var centre := Vector2(cell.x + 0.5, cell.y + 1.0)
		var near := false
		for other: Vector2 in feet:
			if other.distance_to(centre) < TREE_SPACING:
				near = true
				break
		if near:
			continue
		feet.append(centre)
		var id := &"tree_b_01" if _rng.randf() < 0.5 else &"tree_a_01"
		var prop := _add_prop(root, entities, id, cell, "Forest%03d" % index)
		prop.position += Vector2(_rng.randf_range(-TREE_JITTER.x, TREE_JITTER.x),
			-_rng.randf_range(0.0, TREE_JITTER.y))
		index += 1


func _scene(id: StringName) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	return _scenes[id]


func _add_prop(root: Node, parent: Node, id: StringName, anchor: Vector2i,
		node_name: String) -> Node2D:
	return _add_prop_at(root, parent, id, _rules.call(&"foot_position", id, anchor), node_name)


## Objet posé au pixel (relief sans emprise : murs, escaliers).
func _add_prop_at(root: Node, parent: Node, id: StringName, foot: Vector2,
		node_name: String) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot.round()
	_attach(root, parent, prop)
	return prop


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
		point.set(&"trigger", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"target_map", entry[4])
		point.set(&"target_spawn", entry[5])
		point.set(&"arrival_facing", entry[6])
		_attach(root, root.get_node(^"Warps"), point)
	for entry: Array in SOON_WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.UP)
		point.set(&"coming_soon", COMING_SOON_LABEL)
		point.set(&"target_spawn", entry[2])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)


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
	for entry: Array in TRIGGERS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"cutscene_id", entry[4])
		_attach(root, root.get_node(^"Triggers"), point)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root
