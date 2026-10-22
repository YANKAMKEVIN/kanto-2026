extends SceneTree
## Construit game/world/maps/viridian_city.tscn (Jadielle **agrandie**, 56 × 36 cases) et son
## masque de sol assets/world/maps/viridian_city_ground.png (jalon-07.md §8 T4, §15.4,
## §15.20 : agrandissement décidé par Kevin au T5, passe 2 : densité, jardins, arrivée).
##
##   godot --headless --path . -s res://tools/build_viridian_city.gd [-- --dump]
##   godot --headless --path . --import
##   (la première fois, ou si le masque change : relancer l'outil après l'import, pour que la
##   scène référence le masque importé). `--dump` imprime le plan en caractères.
##
## Décision de Kevin (2026-10-05, T5 sur S24) : Jadielle trop petite et trop plate → on
## agrandit et on suit la **composition de la référence** `jadielle-vue-generale-v1.webp`,
## **sans eau** (dossier 09 §1 : ville dans les terres, bordée de forêt et de relief). La place
## est au **centre**. Trois niveaux reliés par des escaliers de ville :
## - **niveau haut** (rangées 1–11) : l'**arche nord** et la rue vers la Route 2 (jalon 8),
##   l'**Arène fermée** au nord-ouest sur sa terrasse (parvis pavé, escalier qui descend), deux
##   maisons à jardins clos, chemins de terre, belvédère à l'est ;
## - mur de soutènement à garde-corps (rangée 12), deux escaliers (Arène, rue nord) ;
## - **niveau de la place** (13–23) : la placette nord, le **Centre** (nord-ouest de l'arbre),
##   la **Boutique** (nord-est), l'**arbre central** et son massif, la rue est-ouest (vers la
##   **Route 22** à l'ouest, chemin de terre à la place du pont), deux maisons, deux jardins
##   publics ;
## - mur à garde-corps (rangée 24) et le **grand escalier sud**, en haut duquel se joue la
##   micro-scène d'arrivée (le premier pas sur la place) ;
## - **niveau bas** (25–31) : l'arrivée entretenue (haies, lampadaires, panneau), deux maisons
##   à jardins clos ;
## - **falaise** (rangée 32) que le chemin de la Route 1 traverse, puis la lisière (33–35).
## Chaque maison a un **jardin clos** (clôture, portail ouvert, boîte aux lettres, potager,
## arbres fruitiers, mobilier) ; bosquets (`GROVE`) entre les quartiers : arbres là où leur
## cime ne cache aucune case praticable ni le bord d'un mur, buissons sinon. Sol :
## `PaintedGround` + masque (R pavés, G chemin), touffes d'herbe sur les pelouses ; aucun
## `TileMapLayer` ; forêt, bosquets, jardins sous les toits, murs, falaise, clôtures =
## `blocked_cells`. Murs, escaliers et falaise : relief de la couche du sol (`GroundDecals`) ;
## clôtures et garde-corps : bandes peintes recadrées à la longueur voulue (`Entities`).
## Habitants : data/npcs/viridian_city.json ; micro-scène : data/cutscenes/viridian_city.json.

const OUT_PATH := "res://game/world/maps/viridian_city.tscn"
const MASK_PATH := "res://assets/world/maps/viridian_city_ground.png"
const PROPS_DIR := "res://game/world/props/painted/"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const CATALOGUE := "res://assets/world/catalogue.json"
const PROP_SCRIPT := "res://game/world/props/prop.gd"
const OBJECT_MATERIAL := "res://game/world/lighting/materials/world_object.tres"
const TUFT_TEXTURE := "res://assets/world/ground/decals/decal_touffe_%d.png"
const SIZE := Vector2i(56, 36)
const TILE := 96
## Graines fixes : végétation, décalcomanies du bord des pavés, touffes des pelouses.
const FOREST_SEED := 2026
const DECALS_SEED := 7
const TUFTS_SEED := 11
## WorldLighting.Z_GROUND_DECALS (les outils ne voient pas les class_name avant import).
const Z_GROUND_DECALS := -1

## Nature d'une case (peinte dans l'ordre de REGIONS) : forêt (bloquée, arbres ou buissons),
## jardin (bloqué, rien de planté : sous les toits, plates-bandes posées à la main), pelouse,
## pavés, chemin, mur de soutènement et falaise (bloqués, relief peint), escalier
## (praticable), bosquet (bloqué, arbres ou buissons, plus serré), broussailles (bloquées,
## buissons et rochers seulement : la ville reste visible depuis l'entrée).
enum Cell { FOREST, GARDEN, LAWN, PAVING, PATH, WALL, CLIFF, STAIR, GROVE, SCRUB }
const CHARS := "TgL#:WCSGs"

## [nature, rectangle en cases], peints dans l'ordre (le suivant écrase le précédent).
const REGIONS: Array = [
	[Cell.LAWN, Rect2i(3, 1, 50, 31)],
	# Niveau haut : bosquets du nord, de l'ouest de l'Arène, de l'est ; toits (jardins).
	[Cell.GROVE, Rect2i(3, 1, 24, 2)],
	[Cell.GROVE, Rect2i(30, 1, 23, 2)],
	[Cell.GROVE, Rect2i(3, 3, 2, 7)],
	[Cell.GROVE, Rect2i(15, 3, 1, 6)],
	[Cell.GROVE, Rect2i(25, 3, 1, 1)],
	[Cell.GROVE, Rect2i(44, 3, 9, 7)],
	[Cell.GARDEN, Rect2i(5, 3, 10, 3)],
	[Cell.GARDEN, Rect2i(16, 1, 9, 3)],
	[Cell.GARDEN, Rect2i(33, 1, 11, 3)],
	# Niveau de la place : toits (Centre, Boutique, maisons ouest et est), jardins publics.
	[Cell.GARDEN, Rect2i(3, 13, 6, 2)],
	[Cell.GROVE, Rect2i(12, 13, 5, 6)],
	[Cell.GARDEN, Rect2i(17, 13, 9, 5)],
	[Cell.GARDEN, Rect2i(32, 13, 8, 5)],
	[Cell.GROVE, Rect2i(40, 13, 3, 4)],
	[Cell.GARDEN, Rect2i(43, 13, 8, 2)],
	[Cell.GROVE, Rect2i(51, 13, 2, 11)],
	# Niveau bas : bosquets ouest et est, plates-bandes au pied du mur, toits.
	[Cell.GROVE, Rect2i(3, 25, 10, 7)],
	[Cell.GROVE, Rect2i(44, 25, 9, 7)],
	[Cell.GROVE, Rect2i(13, 31, 5, 1)],
	[Cell.GROVE, Rect2i(40, 31, 4, 1)],
	[Cell.GARDEN, Rect2i(13, 25, 12, 1)],
	[Cell.GARDEN, Rect2i(31, 25, 13, 1)],
	[Cell.GARDEN, Rect2i(17, 26, 6, 1)],
	[Cell.GARDEN, Rect2i(35, 26, 5, 1)],
	# Murs de soutènement (rangées 12 et 24) et falaise du sud (rangée 32) ; lisière au pied.
	[Cell.WALL, Rect2i(3, 12, 50, 1)],
	[Cell.WALL, Rect2i(3, 24, 50, 1)],
	[Cell.CLIFF, Rect2i(2, 32, 24, 1)],
	[Cell.CLIFF, Rect2i(31, 32, 24, 1)],
	[Cell.SCRUB, Rect2i(26, 32, 1, 1)],
	[Cell.SCRUB, Rect2i(30, 32, 1, 1)],
	[Cell.SCRUB, Rect2i(19, 33, 18, 3)],
	# Pavés : rue nord, parvis de l'Arène, allée de l'Arène, placette nord, rue de la place,
	# portes du Centre et de la Boutique, arrivée sud.
	[Cell.PAVING, Rect2i(27, 0, 3, 12)],
	[Cell.PAVING, Rect2i(4, 10, 13, 2)],
	[Cell.PAVING, Rect2i(9, 13, 3, 9)],
	[Cell.PAVING, Rect2i(26, 13, 6, 9)],
	[Cell.PAVING, Rect2i(9, 22, 42, 2)],
	[Cell.PAVING, Rect2i(21, 21, 2, 1)],
	[Cell.PAVING, Rect2i(35, 21, 2, 1)],
	[Cell.PAVING, Rect2i(27, 25, 3, 6)],
	# Escaliers de ville (praticables) : Arène, rue nord, grand escalier sud.
	[Cell.STAIR, Rect2i(9, 12, 3, 1)],
	[Cell.STAIR, Rect2i(27, 12, 3, 1)],
	[Cell.STAIR, Rect2i(27, 24, 3, 1)],
	# Chemins de terre : liaisons du niveau haut, route de l'ouest (Route 22), chemin du bas,
	# chemin de la Route 1 (allées des jardins, de la porte au portail : _paint_cells).
	[Cell.PATH, Rect2i(17, 10, 10, 2)],
	[Cell.PATH, Rect2i(30, 10, 14, 2)],
	[Cell.PATH, Rect2i(0, 22, 9, 2)],
	[Cell.PATH, Rect2i(18, 31, 9, 1)],
	[Cell.PATH, Rect2i(30, 31, 10, 1)],
	[Cell.PATH, Rect2i(27, 31, 3, 5)],
]

## Cases bloquées sans nature propre : bord nord du chemin (la tête du joueur reste à
## l'écran, comme la Route 1) ; les piliers des escaliers et les clôtures s'y ajoutent.
const BLOCKED_EDGE: Array[Vector2i] = [Vector2i(27, 0), Vector2i(28, 0), Vector2i(29, 0)]

## Escaliers de ville : [case du milieu des marches (rangée du mur), nom du nœud]. Marches sur
## trois cases, piliers sur les cases voisines.
const STAIRS: Array = [
	[Vector2i(10, 12), "StairGym"],
	[Vector2i(28, 12), "StairNorth"],
	[Vector2i(28, 24), "StairSouth"],
]
## Descente du pied de l'image de l'escalier sous le bas de la rangée du mur (cases).
const STAIR_DROP := 0.5
## Largeur de l'image de l'escalier (cases) : marches (3) et piliers.
const STAIR_WIDTH := 4.5
## Les murs passent un peu sous les piliers (cases) : aucune fente entre mur et pilier.
const WALL_UNDER_PILLAR := 0.3
## Rangées des murs de soutènement (garde-corps sur leur bord haut), et de la falaise.
const WALL_ROWS: Array[int] = [12, 24]
const CLIFF_ROW := 32
## Pied du garde-corps sous le haut de la rangée du mur (px) : posé sur le couronnement.
const BALUSTRADE_DROP := 10.0
## Échelle du garde-corps (image de 88 px de haut → ≈ 55 px) : collé au garde-corps, un
## personnage (héros 128 px, pieds 10 px au-dessus du pied du garde-corps) n'en a que les
## jambes cachées (≈ 45 px ; QA T5 sur S21 : il n'en restait que la tête). Mesuré par
## `test_viridian_city.test_balustrades_hide_only_the_legs`.
const BALUSTRADE_SCALE := 0.62

## Jardins clos : [maison, case d'ancrage, nom, enclos (Rect2i : colonnes des clôtures, de la
## rangée du haut de la maison à la rangée de la clôture avant)]. Les clôtures courent sur les
## deux colonnes de côté et la rangée avant, sauf le portail et les cases de la maison ; le
## **portail est dans la colonne de la porte** ([constant HOUSE_DOOR_DX]) et une allée de terre
## mène tout droit du portail à la case devant la porte (retours de Kevin au T5 : on doit
## pouvoir aller jusqu'à chaque porte, et le voir) ; la boîte aux lettres est à gauche du
## portail. Au moins une rangée d'allée entre la façade et la clôture avant.
const GARDENS: Array = [
	[&"bldg_maison_b_01", Vector2i(20, 6), "HouseNorthWest", Rect2i(16, 4, 9, 6)],
	[&"bldg_maison_a_01", Vector2i(38, 6), "HouseNorthEast", Rect2i(33, 4, 11, 6)],
	[&"bldg_maison_d_01", Vector2i(6, 17), "HouseWest", Rect2i(3, 15, 6, 7)],
	[&"bldg_maison_c_01", Vector2i(47, 17), "HouseEast", Rect2i(43, 15, 8, 7)],
	[&"bldg_maison_c_01", Vector2i(20, 28), "HouseSouthWest", Rect2i(13, 26, 12, 5)],
	[&"bldg_maison_d_01", Vector2i(37, 28), "HouseSouthEast", Rect2i(32, 26, 12, 5)],
]
## Colonne de la porte peinte de chaque modèle de maison, relative à la case d'ancrage (lue
## sur les images : A et B à gauche du milieu, C au milieu, D à droite). La porte est la case
## du bas de l'emprise dans cette colonne : on l'examine depuis la case du dessous.
const HOUSE_DOOR_DX: Dictionary = {
	&"bldg_maison_a_01": -1,
	&"bldg_maison_b_01": -1,
	&"bldg_maison_c_01": 0,
	&"bldg_maison_d_01": 1,
}
## Dialogue des portes de maisons (fermées : défaut en attendant la décision de Kevin).
const HOUSE_DOOR_DIALOGUE := &"viridian_house_door"

## Objets peints : [identifiant, case d'ancrage, nom du nœud]. Pied posé par
## PaintedPropRules.foot_position (bord ou milieu de case selon la largeur).
const PROPS: Array = [
	[&"bldg_centre_01", Vector2i(22, 21), "PokemonCenter"],
	[&"bldg_boutique_01", Vector2i(36, 21), "PokeMart"],
	[&"bldg_arene_01", Vector2i(10, 9), "Gym"],
	[&"tree_central_01", Vector2i(29, 20), "CentralTree"],
	[&"prop_porte_nord_01", Vector2i(28, 2), "NorthGate"],
	# Jardin nord-ouest.
	[&"prop_potager_01", Vector2i(22, 8), "NWVeg"],
	[&"tree_fruitier_01", Vector2i(17, 6), "NWFruit"],
	[&"prop_buisson_b_01", Vector2i(17, 8), "NWBush"],
	[&"prop_tonneau_01", Vector2i(23, 5), "NWBarrel"],
	[&"prop_pots_fleurs_01", Vector2i(18, 7), "NWPots"],
	# Jardin nord-est.
	[&"prop_potager_01", Vector2i(35, 8), "NEVeg"],
	[&"prop_linge_01", Vector2i(41, 8), "NELinen"],
	[&"tree_fruitier_01", Vector2i(42, 5), "NEFruit"],
	[&"prop_buisson_a_01", Vector2i(34, 5), "NEBush"],
	[&"prop_caisses_01", Vector2i(41, 6), "NECrates"],
	[&"prop_pots_fleurs_01", Vector2i(39, 7), "NEPots"],
	# Jardin ouest.
	[&"tree_fruitier_01", Vector2i(4, 18), "WFruit"],
	[&"prop_pots_fleurs_01", Vector2i(5, 18), "WPots"],
	[&"prop_potager_01", Vector2i(5, 20), "WVeg"],
	# Jardin est.
	[&"prop_potager_01", Vector2i(45, 20), "EVeg"],
	[&"tree_fruitier_01", Vector2i(44, 19), "EFruit"],
	[&"prop_pots_fleurs_01", Vector2i(48, 20), "EPots"],
	[&"prop_tonneau_01", Vector2i(49, 19), "EBarrel"],
	[&"prop_caisses_01", Vector2i(49, 18), "ECrates"],
	# Jardin sud-ouest.
	[&"prop_potager_01", Vector2i(15, 29), "SWVeg"],
	[&"prop_linge_01", Vector2i(15, 26), "SWLinen"],
	[&"tree_fruitier_01", Vector2i(14, 28), "SWFruit"],
	[&"prop_tonneau_01", Vector2i(23, 27), "SWBarrel"],
	[&"prop_caisses_01", Vector2i(23, 26), "SWCrates"],
	[&"prop_pots_fleurs_01", Vector2i(22, 29), "SWPots"],
	# Jardin sud-est.
	[&"prop_potager_01", Vector2i(41, 29), "SEVeg"],
	[&"prop_linge_01", Vector2i(41, 26), "SELinen"],
	[&"tree_fruitier_01", Vector2i(33, 27), "SEFruit"],
	[&"prop_buisson_b_01", Vector2i(34, 29), "SEBush"],
	[&"prop_tonneau_01", Vector2i(42, 27), "SEBarrel"],
	[&"prop_pots_fleurs_01", Vector2i(36, 29), "SEPots"],
	# Plates-bandes et buissons au pied des murs, derrière le Centre et la Boutique.
	[&"prop_platebande_01", Vector2i(19, 14), "BedBehindCenterW"],
	[&"prop_platebande_01", Vector2i(23, 14), "BedBehindCenterE"],
	[&"prop_platebande_01", Vector2i(33, 14), "BedBehindMartW"],
	[&"prop_platebande_01", Vector2i(37, 14), "BedBehindMartE"],
	[&"prop_buisson_c_01", Vector2i(18, 13), "BushBehindCenter1"],
	[&"prop_buisson_a_01", Vector2i(22, 13), "BushBehindCenter2"],
	[&"prop_buisson_c_01", Vector2i(25, 13), "BushBehindCenter3"],
	[&"prop_buisson_c_01", Vector2i(33, 13), "BushBehindMart1"],
	[&"prop_buisson_b_01", Vector2i(36, 13), "BushBehindMart2"],
	[&"prop_buisson_c_01", Vector2i(39, 13), "BushBehindMart3"],
	[&"prop_platebande_01", Vector2i(14, 25), "BedSouthWallW"],
	[&"prop_buisson_a_01", Vector2i(23, 25), "BushSouthWallW"],
	[&"prop_buisson_b_01", Vector2i(24, 25), "BushSouthWallW2"],
	[&"prop_platebande_01", Vector2i(33, 25), "BedSouthWallE"],
	[&"prop_platebande_01", Vector2i(42, 25), "BedSouthWallE2"],
	[&"prop_buisson_a_01", Vector2i(31, 25), "BushSouthWallE"],
	# Le long de la rue de l'arche : haies, lampadaires.
	[&"prop_haie_v_01", Vector2i(26, 7), "HedgeNorthRoadW"],
	[&"prop_haie_v_01", Vector2i(30, 8), "HedgeNorthRoadE"],
	[&"prop_lampadaire_01", Vector2i(26, 9), "LampNorthRoadW"],
	[&"prop_lampadaire_01", Vector2i(30, 9), "LampNorthRoadE"],
	# Belvédère est du niveau haut.
	[&"prop_banc_01", Vector2i(48, 11), "BenchBelvedere"],
	[&"prop_lampadaire_01", Vector2i(45, 11), "LampBelvedere"],
	[&"prop_pots_fleurs_01", Vector2i(51, 11), "PotsBelvedere"],
	[&"prop_buisson_b_01", Vector2i(52, 10), "BushBelvedere"],
	# L'arrivée : haies le long du chemin, lampadaires jusqu'à la lisière, panneau.
	[&"prop_haie_v_01", Vector2i(26, 29), "HedgeArrivalW"],
	[&"prop_haie_v_01", Vector2i(30, 29), "HedgeArrivalE"],
	[&"prop_lampadaire_01", Vector2i(26, 30), "LampArrivalW"],
	[&"prop_lampadaire_01", Vector2i(30, 30), "LampArrivalE"],
	[&"prop_lampadaire_01", Vector2i(26, 33), "LampEdgeW"],
	[&"prop_lampadaire_01", Vector2i(30, 33), "LampEdgeE"],
	[&"prop_panneau_01", Vector2i(25, 30), "SignViridian"],
	[&"prop_pots_fleurs_01", Vector2i(25, 25), "PotsArrivalW"],
	# Lampadaires : placette nord, place, parvis de l'Arène, ouest.
	[&"prop_lampadaire_01", Vector2i(26, 14), "LampNorthW"],
	[&"prop_lampadaire_01", Vector2i(31, 14), "LampNorthE"],
	[&"prop_lampadaire_01", Vector2i(17, 21), "LampSquareW"],
	[&"prop_lampadaire_01", Vector2i(40, 21), "LampSquareE"],
	[&"prop_lampadaire_01", Vector2i(16, 11), "LampGym"],
	[&"prop_lampadaire_01", Vector2i(8, 21), "LampWest"],
	# Jardins publics : banc de la Dresseuse (ouest), banc du parc (est), pots, buissons.
	[&"prop_banc_01", Vector2i(14, 21), "BenchSquare"],
	[&"prop_pots_fleurs_01", Vector2i(17, 19), "PotsSquareW"],
	[&"prop_buisson_b_01", Vector2i(16, 19), "BushSquareW"],
	[&"prop_banc_01", Vector2i(42, 18), "BenchPark"],
	[&"prop_pots_fleurs_01", Vector2i(42, 21), "PotsSquareE"],
	[&"prop_buisson_a_01", Vector2i(40, 17), "BushPark"],
	# Tonneaux et caisses devant la Boutique (livraisons).
	[&"prop_caisses_01", Vector2i(41, 20), "MartCrates"],
	[&"prop_tonneau_01", Vector2i(40, 20), "MartBarrel"],
	# Rochers de la lisière.
	[&"prop_rocher_01", Vector2i(21, 34), "RockEdgeW"],
	[&"prop_rocher_01", Vector2i(35, 35), "RockEdgeE"],
]
## Relief posé au sol (GroundDecals, sous les personnages) : le massif de l'arbre central.
const GROUND_PROPS: Array = [
	[&"prop_massif_01", Vector2i(29, 20), "CentralBed"],
]
## Forêt sans plantation : sous la route de l'ouest (les cimes la cacheraient).
const NO_TREES: Array[Rect2i] = [Rect2i(0, 24, 3, 3)]

## Passages. [nœud, case, déclencheur (0 STEP_ON, 1 PUSH), direction, carte, spawn,
## orientation à l'arrivée].
const STEP_ON := 0
const PUSH := 1
const WARPS: Array = [
	# Sud : vers la Route 1 (bord nord de la Route 1, spawns from_viridian_*).
	["Route1W", Vector2i(27, 35), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1C", Vector2i(28, 35), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1E", Vector2i(29, 35), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_e",
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
## Jalon 28 (jalon-28.md §2.1) : porte de l'Arène, PUSH ↑ depuis les deux cases devant elle,
## active seulement si `silph_giovanni_defeated` ([member WarpPoint.if_flags]) ; le point
## d'examen « La porte est verrouillée. » porte le `unless` inverse. Posés à la main dans la
## scène (2026-10-22), comme les sorties nord : [nœud, case].
const GYM_DOOR_FLAG: StringName = &"silph_giovanni_defeated"
const GYM_DOOR_WARPS: Array = [
	["GymDoorW", Vector2i(9, 10)],
	["GymDoorE", Vector2i(10, 10)],
]
## Sortie nord vers la Route 2 (jalon 8 T5, jalon-08.md §2.1 ; avant : « ROUTE 2 — À venir ») :
## [nœud, case, spawn de la Route 2]. PUSH ↑, arrivée tournée ↑ ; rangée 0 toujours bloquée.
## **Ne pas relancer l'outil pour ce seul changement** : la scène a été modifiée à la main sur
## ces six nœuds (warps et spawns), `test_viridian_city` compare la scène à ces constantes.
const NORTH_WARPS: Array = [
	["Route2W", Vector2i(27, 1), &"from_viridian_w"],
	["Route2C", Vector2i(28, 1), &"from_viridian_c"],
	["Route2E", Vector2i(29, 1), &"from_viridian_e"],
]
## Points d'apparition.
const SPAWNS: Dictionary = {
	"from_route_1_w": Vector2i(28, 35),
	"from_route_1_e": Vector2i(29, 35),
	"from_center": Vector2i(21, 21),
	"from_mart": Vector2i(36, 21),
	"from_route_22": Vector2i(0, 22),
	# Jalon 28 : retour de l'Arène, devant la porte.
	"from_gym": Vector2i(9, 10),
	# Arrivée depuis la Route 2 (jalon 8 T5) : sur les cases du passage, tournée vers le sud.
	"from_route_2_w": Vector2i(27, 1),
	"from_route_2_c": Vector2i(28, 1),
	"from_route_2_e": Vector2i(29, 1),
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

## Végétation : distances minimales (cases) entre deux arbres de forêt, de bosquet, entre un
## buisson et tout autre plant ; décalage aléatoire du pied (px).
const TREE_SPACING := 1.9
const GROVE_TREE_SPACING := 1.6
const BUSH_SPACING := 1.05
const TREE_JITTER := Vector2(22.0, 16.0)
const BUSH_JITTER := Vector2(30.0, 24.0)
## Part des buissons sautés (bosquets, broussailles de la lisière).
const BUSH_SKIP := 0.25
const BUSH_SKIP_SCRUB := 0.45
## Hauteur (cases) que couvre la cime d'un arbre au-dessus de son pied : pas d'arbre si une
## case praticable, un mur ou la falaise est dessous (buisson à la place).
const CROWN_ROWS := 4
## Touffes d'herbe : probabilité par case de pelouse.
const TUFT_CHANCE := 0.45

var _rules: Script
var _catalogue: Dictionary = {}
var _cells: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
## Clôtures : cases bloquées et tronçons [début, fin incluse, rangée ou colonne, vertical].
var _fence_cells: Dictionary = {}


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	_catalogue = (JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE)) as Dictionary)[
		"objets"]
	_paint_cells()
	_plan_fences()
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
	# Allées des jardins : de la case devant la porte jusqu'au portail (clôture avant).
	for garden: Array in GARDENS:
		var door := _door_cell(garden)
		for y in range(door.y + 1, (garden[3] as Rect2i).end.y):
			_cells[y * SIZE.x + door.x] = Cell.PATH


func _cell(c: Vector2i) -> int:
	if c.x < 0 or c.y < 0 or c.x >= SIZE.x or c.y >= SIZE.y:
		return Cell.FOREST
	return _cells[c.y * SIZE.x + c.x]


func _walkable_kind(kind: int) -> bool:
	return kind == Cell.LAWN or kind == Cell.PAVING or kind == Cell.PATH or kind == Cell.STAIR


## Case de la porte d'une maison (rangée du bas de son emprise, colonne de la porte peinte).
func _door_cell(garden: Array) -> Vector2i:
	return (garden[1] as Vector2i) + Vector2i(int(HOUSE_DOOR_DX[garden[0]]), 0)


## Colonne du portail d'un jardin : celle de la porte.
func _gate_x(garden: Array) -> int:
	return _door_cell(garden).x


## Cases des maisons d'un jardin (emprise du modèle autour de la case d'ancrage).
func _house_cells(garden: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset: Vector2i in _rules.call(&"footprint", garden[0]):
		cells.append((garden[1] as Vector2i) + offset)
	return cells


## Clôtures des jardins : colonnes de côté (de la rangée du haut à l'avant-dernière), rangée
## avant (coins compris), sauf le portail et les cases de la maison.
func _plan_fences() -> void:
	for garden: Array in GARDENS:
		var rect: Rect2i = garden[3]
		var gate := Vector2i(_gate_x(garden), rect.end.y - 1)
		var house := _house_cells(garden)
		var cells: Array[Vector2i] = []
		for y in range(rect.position.y, rect.end.y - 1):
			cells.append(Vector2i(rect.position.x, y))
			cells.append(Vector2i(rect.end.x - 1, y))
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, rect.end.y - 1))
		for cell: Vector2i in cells:
			if cell != gate and not house.has(cell):
				_fence_cells[cell] = true


## Plan en caractères (T forêt, g jardin, L pelouse, # pavés, : chemin, W mur, C falaise,
## S escalier, G bosquet, s broussailles ; x : piliers, clôtures et bords bloqués).
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
	# Murs de soutènement et falaise : un toit du niveau du dessous ne s'efface pas sous le
	# joueur de la terrasse (QA T5).
	var levels: Array[int] = WALL_ROWS.duplicate()
	levels.append(CLIFF_ROW)
	root.set(&"level_rows", levels)
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
	plan.append_array(_lawn_tufts())
	border.call(&"place", plan, decals, root)
	_place_relief(root, decals)
	for entry: Array in GROUND_PROPS:
		_add_prop(root, decals, entry[0], entry[1], entry[2])
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for garden: Array in GARDENS:
		_add_prop(root, entities, garden[0], garden[1], garden[2])
	for entry: Array in PROPS:
		_add_prop(root, entities, entry[0], entry[1], entry[2])
	_place_gardens(root, entities)
	_place_balustrades(root, entities)
	_plant(root, entities)
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	_add_spawns(root)
	_add_warps(root)
	_add_interactables(root)
	_add_triggers(root)
	return root


## Forêt, bosquets, broussailles, jardins, murs, falaise, piliers, clôtures, bord du chemin.
func _blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			if not _walkable_kind(_cell(Vector2i(x, y))):
				cells.append(Vector2i(x, y))
	for cell: Vector2i in _extra_blocked():
		if not cells.has(cell):
			cells.append(cell)
	return cells


## Piliers des escaliers (colonnes voisines des marches, rangée du mur et ses deux voisines),
## clôtures des jardins et bord nord du chemin.
func _extra_blocked() -> Array[Vector2i]:
	var cells: Array[Vector2i] = BLOCKED_EDGE.duplicate()
	for stair: Array in STAIRS:
		var middle: Vector2i = stair[0]
		for dx: int in [-2, 2]:
			for dy: int in [-1, 0, 1]:
				cells.append(middle + Vector2i(dx, dy))
	for cell: Vector2i in _fence_cells:
		cells.append(cell)
	return cells


## Cases pavées et du chemin, dans l'ordre de lecture (décalcomanies de leur bord).
func _edge_cells() -> Dictionary:
	var cells := {}
	for y in SIZE.y:
		for x in SIZE.x:
			var kind := _cell(Vector2i(x, y))
			if kind == Cell.PAVING or kind == Cell.PATH or kind == Cell.STAIR:
				cells[Vector2i(x, y)] = true
	return cells


## Touffes d'herbe sur les pelouses (graine fixe) : rien ne reste en aplat.
func _lawn_tufts() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = TUFTS_SEED
	var tufts: Array[Dictionary] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var kind := _cell(Vector2i(x, y))
			if kind != Cell.LAWN and kind != Cell.GROVE and kind != Cell.SCRUB:
				continue
			if rng.randf() >= TUFT_CHANCE:
				continue
			tufts.append({
				"texture": TUFT_TEXTURE % rng.randi_range(1, 4),
				"position": (Vector2(x, y) + Vector2(rng.randf_range(0.2, 0.8),
					rng.randf_range(0.3, 0.9))) * TILE,
				"scale": rng.randf_range(0.5, 0.8),
				"flip_h": rng.randf() < 0.5,
			})
	return tufts


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


## Garde-corps de pierre sur le bord haut des murs (sauf devant les escaliers) : bandes de
## 4 × BALUSTRADE_SCALE cases (image entière), la dernière recadrée à la longueur restante.
func _place_balustrades(root: Node, entities: Node) -> void:
	var index := 0
	for row: int in WALL_ROWS:
		for run: Vector2 in _wall_runs(row):
			var left := run.x + WALL_UNDER_PILLAR
			var end := run.y - WALL_UNDER_PILLAR
			while end - left > 0.2:
				var length := minf(4.0 * BALUSTRADE_SCALE, end - left)
				_strip(root, entities, &"prop_balustrade_01",
					Vector2(left * TILE, row * TILE + BALUSTRADE_DROP), length, false,
					"Balustrade%02d" % index, BALUSTRADE_SCALE)
				index += 1
				left += length


## Maisons posées (PROPS) ; ici : clôtures (bandes recadrées), portail, boîte aux lettres.
func _place_gardens(root: Node, entities: Node) -> void:
	for garden: Array in GARDENS:
		var rect: Rect2i = garden[3]
		var prefix: String = garden[2]
		var front := rect.end.y - 1
		var gate_x := _gate_x(garden)
		# Rangée avant : de part et d'autre du portail.
		var runs: Array[Vector2i] = [Vector2i(rect.position.x, gate_x - 1),
			Vector2i(gate_x + 1, rect.end.x - 1)]
		var index := 0
		for run: Vector2i in runs:
			var x := run.x
			while x <= run.y:
				var length := mini(4, run.y - x + 1)
				_strip(root, entities, &"prop_cloture_01", Vector2(x * TILE, (front + 1) * TILE),
					length, false, "%sFence%d" % [prefix, index])
				index += 1
				x += length
		# Côtés : de la rangée du haut à la rangée avant (exclue), sans la maison.
		for column: int in [rect.position.x, rect.end.x - 1]:
			var bottom := front - 1
			while bottom >= rect.position.y:
				if not _fence_cells.has(Vector2i(column, bottom)):
					bottom -= 1
					continue
				var top := bottom
				while top - 1 >= rect.position.y and _fence_cells.has(Vector2i(column, top - 1)) \
						and bottom - top + 1 < 4:
					top -= 1
				_strip(root, entities, &"prop_cloture_v_01",
					Vector2((column + 0.5) * TILE, (bottom + 1) * TILE), bottom - top + 1, true,
					"%sFence%d" % [prefix, index])
				index += 1
				bottom = top - 1
		_add_prop(root, entities, &"prop_portail_01", Vector2i(gate_x, front), prefix + "Gate")
		var mailbox := _add_prop(root, entities, &"prop_boite_lettres_01",
			Vector2i(gate_x - 1, front), prefix + "Mailbox")
		# Sur la case de la clôture (déjà bloquée), dessinée devant elle.
		mailbox.set(&"footprint", [] as Array[Vector2i])
		mailbox.position += Vector2(18.0, 6.0)


## Bande peinte recadrée ([param length] cases) d'un objet de 4 cases : clôture, garde-corps.
## Horizontale : [param foot] = bas-gauche ; verticale : milieu du bas, l'image garde son bas.
## Sans emprise (cases bloquées par la carte) ni ombre. [param scale] : échelle de l'image
## (la bande couvre toujours [param length] cases).
func _strip(root: Node, parent: Node, id: StringName, foot: Vector2, length: float,
		vertical: bool, node_name: String, scale: float = 1.0) -> Node2D:
	var entry: Dictionary = _catalogue[String(id)]
	var texture := load(entry["fichier"]) as Texture2D
	var size := Vector2(entry["taille"][0], entry["taille"][1])
	var prop := Node2D.new()
	prop.set_script(load(PROP_SCRIPT))
	prop.name = node_name
	prop.position = foot.round()
	prop.set(&"footprint", [] as Array[Vector2i])
	_attach(root, parent, prop)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.material = load(OBJECT_MATERIAL)
	if vertical:
		var shown := roundf(length * TILE)
		sprite.region_rect = Rect2(0.0, size.y - shown, size.x, shown)
		sprite.offset = Vector2(-size.x / 2.0, -shown)
	else:
		var shown := roundf(length * TILE / scale)
		sprite.region_rect = Rect2(0.0, 0.0, shown, size.y)
		sprite.offset = Vector2(0.0, -size.y)
	sprite.scale = Vector2(scale, scale)
	_attach(root, prop, sprite)
	return prop


## Végétation sur la forêt, les bosquets et les broussailles : arbres là où leur cime ne
## couvre aucune case praticable ni un mur ou la falaise, buissons sinon (broussailles :
## buissons et rochers seulement). Tirage à graine fixe ; jamais sous l'image d'un objet
## déjà posé ni sur son emprise.
func _plant(root: Node, entities: Node) -> void:
	var covered: Array[Rect2] = []
	var taken := {}
	var trees: Array[Vector2] = []
	var plants: Array[Vector2] = []
	var buildings: Array[String] = ["PokemonCenter", "PokeMart", "Gym", "NorthGate"]
	for garden: Array in GARDENS:
		buildings.append(garden[2])
	for child: Node in entities.get_children():
		var prop := child as Node2D
		if buildings.has(String(child.name)):
			var sprite := child.get_node(^"Sprite") as Sprite2D
			covered.append(Rect2(prop.position + sprite.offset, sprite.get_rect().size))
		var solid: Variant = child.get(&"footprint")
		if solid is Array:
			for offset: Vector2i in solid:
				taken[_cell_of(prop.position) + offset] = true
		plants.append(prop.position / TILE)
		if String(child.name).contains("Fruit") or child.name == "CentralTree":
			trees.append(prop.position / TILE)
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var kind := _cell(cell)
			if kind != Cell.FOREST and kind != Cell.GROVE and kind != Cell.SCRUB:
				continue
			if taken.has(cell) or NO_TREES.any(func(r: Rect2i) -> bool: return r.has_point(cell)):
				continue
			var foot := Vector2((x + 0.5) * TILE, (y + 1) * TILE - 1.0)
			if covered.any(func(r: Rect2) -> bool: return r.has_point(foot)):
				continue
			cells.append(cell)
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	var index := 0
	for cell: Vector2i in cells:
		var kind := _cell(cell)
		var centre := Vector2(cell.x + 0.5, cell.y + 1.0)
		# La lisière de la forêt peut cacher le pied de la falaise ; pas un bosquet de la ville.
		var tall := kind != Cell.SCRUB and _crown_is_clear(cell, kind == Cell.FOREST)
		var id: StringName
		if tall:
			var spacing := TREE_SPACING if kind == Cell.FOREST else GROVE_TREE_SPACING
			if _too_close(trees, centre, spacing) or _too_close(plants, centre, BUSH_SPACING):
				continue
			var roll := _rng.randf()
			if kind == Cell.GROVE and roll < 0.15:
				id = &"tree_fruitier_01"
			else:
				id = &"tree_b_01" if roll < 0.55 else &"tree_a_01"
			trees.append(centre)
		else:
			if _too_close(plants, centre, BUSH_SPACING):
				continue
			# Buissons clairsemés (pas de rangées) : on en saute une partie.
			var roll := _rng.randf()
			if roll < (BUSH_SKIP_SCRUB if kind == Cell.SCRUB else BUSH_SKIP):
				continue
			roll = _rng.randf()
			var left := cell + Vector2i.LEFT
			if roll < 0.25 and _cell(left) == kind and not taken.has(left) \
					and not _too_close(plants, centre + Vector2.LEFT, BUSH_SPACING):
				id = &"prop_buisson_c_01"
				taken[left] = true
				plants.append(centre + Vector2.LEFT)
			else:
				id = &"prop_buisson_a_01" if roll < 0.6 else &"prop_buisson_b_01"
		plants.append(centre)
		var prop := _add_prop(root, entities, id, cell, "Plant%03d" % index)
		var jitter := TREE_JITTER if tall else BUSH_JITTER
		prop.position += Vector2(_rng.randf_range(-jitter.x, jitter.x),
			-_rng.randf_range(0.0, jitter.y))
		index += 1


## Vrai si la cime d'un arbre planté sur [param cell] ne couvre ni case praticable (colonnes
## voisines, [constant CROWN_ROWS] rangées au-dessus) ni, sauf [param over_relief], un mur ou
## la falaise.
func _crown_is_clear(cell: Vector2i, over_relief: bool = false) -> bool:
	for dy in range(1, CROWN_ROWS + 1):
		for dx in range(-1, 2):
			var kind := _cell(cell + Vector2i(dx, -dy))
			if _walkable_kind(kind):
				return false
			if not over_relief and (kind == Cell.WALL or kind == Cell.CLIFF):
				return false
	return true


func _too_close(feet: Array[Vector2], p: Vector2, distance: float) -> bool:
	for other: Vector2 in feet:
		if other.distance_to(p) < distance:
			return true
	return false


static func _cell_of(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / TILE), floori((position.y - 1.0) / TILE))


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
	for entry: Array in NORTH_WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.UP)
		point.set(&"target_map", &"route_2")
		point.set(&"target_spawn", entry[2])
		point.set(&"arrival_facing", Vector2i.UP)
		_attach(root, root.get_node(^"Warps"), point)
	for entry: Array in GYM_DOOR_WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.UP)
		point.set(&"target_map", &"viridian_gym")
		point.set(&"target_spawn", &"entrance")
		point.set(&"arrival_facing", Vector2i.UP)
		var gate: Array[StringName] = [GYM_DOOR_FLAG]
		point.set(&"if_flags", gate)
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
		if entry[4] == &"viridian_gym_door":
			var locked: Array[StringName] = [GYM_DOOR_FLAG]
			point.set(&"unless_flags", locked)
		_attach(root, root.get_node(^"Interactables"), point)
	# Portes des maisons : fermées (« C'est fermé. »), examinées de face depuis l'allée.
	for garden: Array in GARDENS:
		var door := Marker2D.new()
		door.set_script(point_script)
		door.name = String(garden[2]) + "Door"
		door.position = _world(_door_cell(garden))
		door.set(&"size", Vector2i.ONE)
		door.set(&"facing", Vector2i.UP)
		door.set(&"dialogue_id", HOUSE_DOOR_DIALOGUE)
		_attach(root, root.get_node(^"Interactables"), door)


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
