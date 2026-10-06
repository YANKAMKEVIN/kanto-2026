extends SceneTree
## Construit game/world/maps/pallet_town.tscn (Bourg Palette, 48 × 34 cases).
##
##   godot --headless --path . -s res://tools/build_pallet_town.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)
##
## Plan : docs/tech/jalon-01.md §4 ; portes (warps et spawns) : docs/tech/jalon-02.md §4.2 ;
## points d'examen (`INTERACTABLES`) : docs/tech/jalon-03.md §3.2 ; hautes herbes et
## déclencheur (`TRIGGERS`) : docs/tech/jalon-03b.md §3.1.
##
## **DA.2 (docs/tech/integration-da-bourg-route1.md, Q1 = A)** : la carte est peinte, à
## l'image du prototype validé sur S24 (`proto/da_jadielle/proto_bourg.gd`, vue générale
## peinte v1), **sans changer sa géométrie logique**. `Ground`, `Detail`, `Obstacles` et
## `Overhead` (TileMapLayer **invisibles**, mêmes rectangles, mêmes tirages) restent la source
## du solide, de l'eau et des hautes herbes ; les emprises des anciens objets provisoires
## (maisons, labo, clôtures, arbres…) sont reprises par les objets peints posés aux mêmes cases
## et, là où l'image ne couvre pas tout, par `blocked_cells`. La géométrie du jalon 6 est figée
## dans `tests/fixtures/maps/pallet_town_logic.txt` (`tools/dump_map_logic.gd`) : l'outil la
## relit, **rogne** l'emprise de chaque objet peint aux cases déjà solides (sauf
## [constant NEW_SOLID_CELLS]) et bloque les cases solides que plus rien ne couvre ;
## `test_pallet_town_painted` vérifie que la grille est restée la même.
## Image : sol peint (masque RG : pavés, chemin) avec son rivage (sable, mer qui ondule,
## écume), sous-bois et forêt serrée sur les cases de forêt (et la falaise ouest), maisons,
## labo, grand arbre ancien, jardins clôturés, champ, jardins de recherche, ancien sentier,
## falaise côtière, ponton, escalier, barque, objets « avec propriétaire », fleurs, touffes,
## oyats ; lumière `golden_hour`.

const OUT_PATH: String = "res://game/world/maps/pallet_town.tscn"
const MASK_PATH: String = "res://assets/world/maps/pallet_town_ground.png"
const LOGIC_PATH: String = "res://tests/fixtures/maps/pallet_town_logic.txt"
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const OBJECT_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const TALL_GRASS_ID: String = "ground_hautes_herbes_jaune_01"
const GRASS_FRONT: String = "res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png"
const FLOWER_DECAL: String = "res://assets/world/ground/decals/decal_fleur_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"
const COAST_DECAL: String = "res://assets/world/ground/decals/decal_cote_%d.png"
const PIER_TEXTURE: String = "res://assets/world/props/prop_ponton_01.png"
const TILE: int = 96
const SEED: int = 1996
const DECOR_SEED: int = 1997
const FOREST_SEED: int = 3
const SIZE := Vector2i(48, 34)
const START_CELL := Vector2i(36, 10)
## Haut de la Route 1 : le chemin file jusqu'au bord, le joueur s'arrête en y 1.
const BLOCKED_CELLS: Array[Vector2i] = [Vector2i(23, 0), Vector2i(24, 0)]
## Cases d'herbe rase rendues solides par un objet peint nouveau (défaut DA.2, règle 4) : la
## mangeoire de Mme Aoki, au bord est de la place, à côté du banc. Hors de tout passage utile.
const NEW_SOLID_CELLS: Array[Vector2i] = [Vector2i(30, 15)]
## Le labo peint (10 × 8 cases à 1:1) est réduit aux 3/4 : à 1:1, son toit (≈ 6,7 rangées sur le
## pied) recouvrait le bas de l’îlot de l’arbre ancien et la rangée 17 de la place (à 0,85, le
## joueur y disparaissait encore jusqu’aux épaules). Écart avec le
## prototype (où la place était plus haute), noté au plan.
const LAB_SCALE: float = 0.75
const MEADOW_ATTEMPTS: int = 1100
const MEADOW_FLOWER_CHANCE: float = 0.16

## Points d'apparition (en plus de `start`, gardé pour les tests et les outils) :
## case de porte de chaque bâtiment (arrivée en sortant).
const SPAWNS: Dictionary = {
	"player_house_door": Vector2i(36, 9),
	"rival_house_door": Vector2i(11, 9),
	"oak_lab_door": Vector2i(24, 22),
	# Retour depuis la Route 1 (jalon 5 §15.5) : sur la colonne du chemin, tourné vers le bas.
	"from_route_1_w": Vector2i(23, 1),
	"from_route_1_e": Vector2i(24, 1),
}

## Sortie nord vers la Route 1 (jalon 5 §15.5) : warps PUSH « haut » au bord (le changement
## de carte vient de Player.bumped contre la rangée bloquée y 0). [nœud, case, spawn cible].
const PUSH_WARPS: Array = [
	["Route1NorthW", Vector2i(23, 1), &"from_pallet_w"],
	["Route1NorthE", Vector2i(24, 1), &"from_pallet_e"],
]
## Warp.Trigger.PUSH.
const PUSH: int = 1

## Portes : [nœud, case, carte cible, spawn cible]. On entre en marchant vers le haut
## sur la case de porte (STEP_ON, UP), l'orientation est conservée.
const DOORS: Array = [
	["DoorPlayerHouse", Vector2i(36, 9), &"player_house_1f", &"entrance"],
	["DoorRivalHouse", Vector2i(11, 9), &"rival_house", &"entrance"],
	["DoorOakLab", Vector2i(24, 22), &"oak_lab", &"entrance"],
]
## Warp.Trigger.STEP_ON (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0

## Sol logique, peint dans l'ordre (le suivant écrase le précédent). [type, [x0, y0, x1, y1]]
## Inchangé depuis le jalon 5 (invisible depuis DA.2).
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
	# Hautes herbes du haut de la Route 1 (jalon 3B §3.1) : 3 dernières rangées du chemin,
	# entre les clôtures. La rangée y 0 reste bloquée (BLOCKED_CELLS).
	["TALL_GRASS", [23, 0, 24, 2]],
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

## Massifs de fleurs (Detail, invisible) : [x0, y0, x1, y1, densité 0..1]. Mêmes tirages
## qu'avant DA.2 ; leurs cases reçoivent deux fleurs peintes chacune.
const FLOWER_BEDS: Array = [
	[3, 1, 44, 4, 0.10],
	[7, 5, 15, 10, 0.30],
	[32, 5, 40, 10, 0.30],
	[17, 5, 30, 11, 0.08],
	[6, 12, 16, 26, 0.07],
	[32, 12, 41, 28, 0.07],
	[17, 25, 35, 27, 0.15],
]

## Cases pavées en plus du `COBBLE` logique (prototype : allées pavées depuis les maisons,
## allée ouest qui longe le labo jusqu'au sentier côtier). Image seulement.
const EXTRA_PAVING: Array = [
	[11, 10, 11, 13], [11, 13, 16, 13], [36, 10, 36, 13], [32, 13, 36, 13],
	[15, 23, 16, 23], [15, 24, 15, 28],
]
## Le sentier côtier traverse la plage : sable dans l'image (x ≤ 14), comme l'escalier en bois.
const BEACH_SAND: Array = [[7, 29, 14, 30], [6, 27, 6, 27]]

## Arbres placés à la main au jalon 1 (mêmes cases, emprise d'une case) : [case, essence].
## Essences peintes variées, jamais deux identiques côte à côte.
const TREES: Array = [
	# Prairie du Nord.
	[Vector2i(5, 2), "tree_b_01"], [Vector2i(9, 3), "tree_c_01"], [Vector2i(16, 1), "tree_a_01"],
	[Vector2i(19, 3), "tree_d_01"], [Vector2i(27, 1), "tree_c_01"],
	[Vector2i(31, 2), "tree_e_01"],
	# Quartier résidentiel.
	[Vector2i(4, 7), "tree_a_01"], [Vector2i(4, 11), "tree_b_01"],
	[Vector2i(18, 7), "tree_fruitier_01_bourg"], [Vector2i(29, 6), "tree_fruitier_01_bourg"],
	[Vector2i(20, 9), "tree_d_01"],
	# Pelouse ouest.
	[Vector2i(4, 13), "tree_c_01"], [Vector2i(8, 14), "tree_e_01"], [Vector2i(13, 15), "tree_a_01"],
	[Vector2i(7, 17), "tree_b_01"], [Vector2i(11, 19), "tree_c_01"],
	[Vector2i(14, 18), "tree_d_01"],
	[Vector2i(8, 21), "tree_a_01"], [Vector2i(12, 24), "tree_b_01"],
	[Vector2i(10, 25), "tree_e_01"],
	# Entre la place et le couloir est, couloir est.
	[Vector2i(34, 17), "tree_c_01"], [Vector2i(33, 20), "tree_a_01"],
	[Vector2i(36, 21), "tree_d_01"],
	[Vector2i(40, 13), "tree_b_01"], [Vector2i(39, 16), "tree_c_01"],
	[Vector2i(41, 19), "tree_e_01"],
	[Vector2i(40, 22), "tree_a_01"], [Vector2i(40, 24), "tree_b_01"],
	[Vector2i(41, 15), "tree_a_01"],
]

## Objets peints sur leur case d'ancrage (emprise de `PaintedPropRules`, rognée aux cases
## solides du jalon 6) : [objet, case, nom, échelle, miroir].
const ANCHORED: Array = [
	# Prairie : rochers, clôtures de la Route 1 (x 22 et 25, rangées 0 à 3).
	["prop_rocher_01", Vector2i(30, 3), "RockPrairieLarge", 1.0, false],
	["prop_cloture_v_01", Vector2i(22, 3), "FenceRoute1W", 1.0, false],
	["prop_cloture_v_01", Vector2i(25, 3), "FenceRoute1E", 1.0, false],
	# Champ de la jardinière : clôture, épouvantail, brouette et arrosoir.
	["prop_cloture_01", Vector2i(35, 3), "FenceFieldS1", 1.0, false],
	["prop_cloture_01", Vector2i(39, 3), "FenceFieldS2", 1.0, false],
	["prop_cloture_01", Vector2i(43, 3), "FenceFieldS3", 1.0, false],
	["prop_cloture_v_01", Vector2i(33, 3), "FenceFieldW", 1.0, false],
	["prop_cloture_v_01", Vector2i(44, 3), "FenceFieldE", 1.0, false],
	# Jardin du rival : haies sur les côtés, piquets devant (portillon en 11, 11).
	["prop_haie_v_01_bourg", Vector2i(6, 11), "HedgeRivalW1", 1.0, false],
	["prop_haie_v_01_bourg", Vector2i(6, 8), "HedgeRivalW2", 1.0, true],
	["prop_haie_v_01_bourg", Vector2i(16, 11), "HedgeRivalE1", 1.0, true],
	["prop_haie_v_01_bourg", Vector2i(16, 8), "HedgeRivalE2", 1.0, false],
	["prop_cloture_piquets_01", Vector2i(9, 11), "PicketRivalW", 1.0, false],
	["prop_cloture_piquets_01", Vector2i(14, 11), "PicketRivalE", 1.0, false],
	["prop_buisson_b_01_bourg", Vector2i(6, 5), "BushRivalCornerW", 1.0, false],
	["prop_buisson_b_01_bourg", Vector2i(7, 5), "BushRivalA", 1.0, true],
	["prop_buisson_a_01_bourg", Vector2i(15, 5), "BushRivalB", 1.0, false],
	["prop_buisson_a_01_bourg", Vector2i(16, 5), "BushRivalCornerE", 1.0, true],
	["prop_boite_lettres_01", Vector2i(13, 10), "MailboxRival", 1.0, false],
	# Jardin du joueur (portillon en 36, 11).
	["prop_haie_v_01_bourg", Vector2i(31, 11), "HedgePlayerW1", 1.0, false],
	["prop_haie_v_01_bourg", Vector2i(31, 8), "HedgePlayerW2", 1.0, true],
	["prop_haie_v_01_bourg", Vector2i(41, 11), "HedgePlayerE1", 1.0, true],
	["prop_haie_v_01_bourg", Vector2i(41, 8), "HedgePlayerE2", 1.0, false],
	["prop_cloture_piquets_01", Vector2i(34, 11), "PicketPlayerW", 1.0, false],
	["prop_cloture_piquets_01", Vector2i(39, 11), "PicketPlayerE", 1.0, false],
	["prop_buisson_a_01_bourg", Vector2i(31, 5), "BushPlayerCornerW", 1.0, false],
	["prop_buisson_b_01_bourg", Vector2i(41, 5), "BushPlayerCornerE", 1.0, true],
	["prop_boite_lettres_01", Vector2i(38, 10), "MailboxPlayer", 1.0, false],
	["prop_velo_01", Vector2i(40, 10), "Bicycle", 1.0, false],
	# Hortensias de Maman au pied du mur ouest de la maison.
	["prop_hortensias_01", Vector2i(33, 9), "MomHydrangeas", 1.0, false],
	# Entre les jardins, place.
	["prop_buisson_a_01_bourg", Vector2i(19, 11), "BushResidential", 1.0, false],
	["prop_lampadaire_01", Vector2i(17, 12), "LampPlazaNW", 1.0, false],
	["prop_lampadaire_01", Vector2i(31, 12), "LampPlazaNE", 1.0, false],
	["prop_lampadaire_01", Vector2i(17, 17), "LampPlazaSW", 1.0, false],
	["prop_lampadaire_01", Vector2i(31, 17), "LampPlazaSE", 1.0, false],
	["prop_panneau_01", Vector2i(21, 13), "SignPallet", 1.0, false],
	["prop_mangeoire_01", Vector2i(30, 15), "AokiFeeder", 1.0, false],
	# Pelouse ouest.
	["prop_rocher_01", Vector2i(11, 16), "RockLawn", 1.0, false],
	# Camionnette du labo.
	["prop_camionnette_01", Vector2i(15, 22), "Van", 1.0, false],
	# Jardins de recherche : clôtures en bois (prototype), buissons, potagers, petite serre.
	["prop_cloture_01", Vector2i(18, 24), "FenceGardenN1", 1.0, false],
	["prop_cloture_01", Vector2i(22, 24), "FenceGardenN2", 1.0, false],
	["prop_cloture_01", Vector2i(27, 24), "FenceGardenN3", 1.0, false],
	["prop_cloture_01", Vector2i(31, 24), "FenceGardenN4", 1.0, false],
	["prop_cloture_01", Vector2i(35, 24), "FenceGardenN5", 1.0, false],
	["prop_cloture_01", Vector2i(18, 28), "FenceGardenS1", 1.0, false],
	["prop_cloture_01", Vector2i(22, 28), "FenceGardenS2", 1.0, false],
	["prop_cloture_01", Vector2i(26, 28), "FenceGardenS3", 1.0, false],
	["prop_cloture_01", Vector2i(30, 28), "FenceGardenS4", 1.0, false],
	["prop_cloture_01", Vector2i(34, 28), "FenceGardenS5", 1.0, false],
	["prop_cloture_v_01", Vector2i(16, 27), "FenceGardenW", 1.0, false],
	["prop_cloture_v_01", Vector2i(36, 28), "FenceGardenE", 1.0, false],
	["prop_buisson_b_01_bourg", Vector2i(17, 25), "BushGardenA", 1.0, false],
	["prop_buisson_a_01_bourg", Vector2i(35, 25), "BushGardenB", 1.0, true],
	["prop_potager_01", Vector2i(27, 26), "VegetablePatchA", 1.0, false],
	["prop_potager_01", Vector2i(27, 27), "VegetablePatchB", 1.0, false],
	["bldg_serre_01", Vector2i(33, 27), "GreenhouseSmall", 1.0, false],
	# Côte : lampadaires du sentier, casiers de Haru (à la place du gros rocher de la plage).
	["prop_lampadaire_01", Vector2i(14, 29), "LampCoastW", 1.0, false],
	["prop_lampadaire_01", Vector2i(26, 29), "LampCoastC", 1.0, false],
	["prop_lampadaire_01", Vector2i(38, 29), "LampCoastE", 1.0, false],
	["prop_casiers_peche_01", Vector2i(5, 28), "HaruTraps", 1.0, false],
	["prop_cloture_v_01", Vector2i(45, 30), "BarrierRoute21", 1.0, false],
]

## Objets posés librement (pied en cases, flottants) avec une emprise explicite (cases
## absolues, rognées elles aussi) : [objet, pied, nom, emprise, échelle, miroir, couche].
## Couche « sol » : `GroundDecals`. Petits rochers : le rocher peint réduit (une case).
const FREE: Array = [
	["prop_rocher_01", Vector2(13.5, 2.95), "RockPrairie", [Vector2i(13, 2)], 0.6, false, ""],
	["prop_rocher_01", Vector2(7.5, 23.95), "RockLawnSmall", [Vector2i(7, 23)], 0.6, true, ""],
	["prop_rocher_01", Vector2(5.5, 30.95), "RockBeachA", [Vector2i(5, 30)], 0.6, false, ""],
	# Champ : deux parcelles côte à côte sur les 10 × 2 cases cultivées.
	["ground_champ_01", Vector2(36.5, 3.15), "FieldW", [], 0.833, false, "ground"],
	["ground_champ_01", Vector2(41.5, 3.15), "FieldE", [], 0.833, true, "ground"],
	["prop_epouvantail_01", Vector2(41.4, 2.55), "Scarecrow", [Vector2i(41, 2)], 1.0, false, ""],
	["prop_arrosoir_seau_01", Vector2(42.6, 2.9), "WateringCan", [Vector2i(42, 2)], 1.0, false,
		""],
	["prop_brouette_01", Vector2(43.4, 2.95), "Wheelbarrow", [Vector2i(43, 2)], 1.0, true, ""],
	# Bois du rival, contre le mur est de sa maison (cases sans accès).
	["prop_tas_bois_01", Vector2(15.0, 10.0), "RivalWoodpile", [Vector2i(14, 9)], 1.0, false,
		""],
	# Pots de Maman entre la boîte aux lettres et le vélo (case sans accès).
	["prop_pots_fleurs_01_bourg", Vector2(39.5, 10.9), "MomPots", [], 1.0, false, ""],
	# Abords du labo : vélos des chercheurs, matériel, buissons (anciennes cases du labo).
	["prop_ratelier_velos_01", Vector2(19.0, 23.0), "LabBikes", [], 1.0, false, ""],
	["prop_materiel_labo_01", Vector2(30.0, 23.0), "LabEquipment", [], 1.0, false, ""],
	["prop_buisson_a_01_bourg", Vector2(18.6, 19.0), "BushLabW1", [], 1.0, false, ""],
	["prop_buisson_c_01_bourg", Vector2(19.3, 21.2), "BushLabW2", [], 1.0, false, ""],
	["prop_buisson_a_01_bourg", Vector2(29.4, 19.0), "BushLabE1", [], 1.0, true, ""],
	["prop_buisson_c_01_bourg", Vector2(29.7, 21.2), "BushLabE2", [], 1.0, true, ""],
	# Grande serre et petits potagers des jardins de recherche.
	["prop_potager_01", Vector2(18.0, 27.0), "VegetableBedW1", [], 0.7, false, ""],
	["prop_potager_01", Vector2(18.0, 28.0), "VegetableBedW2", [], 0.7, true, ""],
	["prop_potager_01", Vector2(23.0, 27.0), "VegetableBedE1", [], 0.7, true, ""],
	["prop_potager_01", Vector2(23.0, 28.0), "VegetableBedE2", [], 0.7, false, ""],
	# Ancien sentier envahi : tronc couché derrière les ronces (cases sans accès).
	["prop_tronc_couche_01", Vector2(44.6, 27.0), "OldTrailLog", [], 1.0, false, ""],
	# Barque de Haru tirée au bord de l'eau (à la place du petit rocher de la plage).
	["prop_barque_01", Vector2(12.5, 33.0), "HaruBoat", [Vector2i(12, 31)], 1.0, false, ""],
	# Escalier en bois du chemin de planches vers la plage (traversable).
	["relief_escalier_bois_01", Vector2(6.5, 28.0), "BeachStairs", [], 1.0, false, "ground"],
	# Rochers dans la mer.
	["prop_rocher_mer_01", Vector2(18.0, 33.9), "SeaRock1", [], 1.0, false, ""],
	["prop_rocher_mer_01", Vector2(27.4, 33.6), "SeaRock2", [], 0.9, true, ""],
	["prop_rocher_mer_01", Vector2(36.2, 33.95), "SeaRock3", [], 1.0, false, ""],
	["prop_rocher_mer_01", Vector2(44.5, 33.7), "SeaRock4", [], 0.85, true, ""],
	# Oyats sur la plage et au bord de la falaise (traversables).
	["prop_herbes_dune_01", Vector2(13.7, 27.8), "DuneGrass1", [], 1.0, false, ""],
	["prop_herbes_dune_01", Vector2(3.6, 27.7), "DuneGrass2", [], 0.9, true, ""],
	["prop_herbes_dune_01", Vector2(10.6, 31.8), "DuneGrass3", [], 0.9, false, ""],
	["prop_herbes_dune_01", Vector2(21.5, 30.95), "DuneGrass4", [], 0.8, false, ""],
	["prop_herbes_dune_01", Vector2(33.4, 30.95), "DuneGrass5", [], 0.8, true, ""],
	["prop_herbes_dune_01", Vector2(42.0, 30.95), "DuneGrass6", [], 0.8, false, ""],
]

## Ponton (une colonne praticable, (9, 32..33)) : bande centrale de l'image du ponton (le
## ponton peint fait 5 cases de large ; la carte n'en a qu'une). Rognure en pixels de l'image.
const PIER_REGION := Rect2(168, 0, 144, 357)
## Bas du plancher dans l'image (pixels) : le plancher finit au bord bas de la carte.
const PIER_DECK_BOTTOM: float = 235.0

## Points d'examen : [nœud, ancre, size, facing, dialogue, verbe]. Ancre = case en bas à
## gauche ; facing ZERO = de tous côtés ; verbe = Interaction.Kind (valeur).
## Texte du panneau provisoire (`draft`, jalon-03.md Q8).
const INTERACTABLES: Array = [
	["SignPallet", Vector2i(21, 13), Vector2i(1, 1), Vector2i.ZERO, "sign_pallet_town"],
]

## Déclencheurs de scène : [nœud, ancre, size, direction, scène]. Ancre = case en bas à
## gauche ; direction ZERO = pas venu de n'importe quel côté. Route1Grass : la case juste
## avant les hautes herbes, sur les deux colonnes du chemin (jalon-03b.md §3.1, Q2).
const TRIGGERS: Array = [
	["Route1Grass", Vector2i(23, 3), Vector2i(2, 1), Vector2i.ZERO, "route1_grass"],
]
## Interaction.Kind (valeurs).
const EXAMINE: int = 1

var _tiles: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _decor_rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _kinds: Array = []
var _obstacle_kinds: Array = []
## Géométrie figée du jalon 6 : cases solides (hors eau).
var _old_solid: Dictionary = {}
var _paving: Dictionary = {}
var _path: Dictionary = {}
var _sand: Dictionary = {}
var _water: Dictionary = {}
var _forest: Dictionary = {}
var _tall_grass: Dictionary = {}
var _flower_cells: Dictionary = {}
## Objets peints posés : [nœud, cases d'emprise absolues demandées].
var _placed: Array = []
var _landmark_feet: Array[Vector2] = []


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	_rng.seed = SEED
	_decor_rng.seed = DECOR_SEED
	if not _read_logic():
		quit(1)
		return
	var root := Node2D.new()
	root.name = "PalletTown"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"pallet_town")
	root.set(&"display_name", "Bourg Palette")
	root.set(&"region", "Kanto")
	root.set(&"size", SIZE)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"grass_front", load(GRASS_FRONT))
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	# Source logique seulement (solide, eau, hautes herbes) : l'image est peinte.
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	_kinds = _paint(ground, GROUND)
	_obstacle_kinds = _paint(obstacles, OBSTACLES)
	_paint_flowers(detail, _kinds)
	_classify()

	var mask_texture := _write_mask()
	if mask_texture == null:
		print("build_pallet_town : masque écrit ; importer (--import) puis relancer l'outil")
		root.free()
		quit(2)
		return
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", SIZE)
	painted.set(&"mask", mask_texture)
	var mask_script := load("res://game/world/ground/ground_mask.gd") as GDScript
	painted.set(&"shore_mask", ImageTexture.create_from_image(
		mask_script.call(&"build_shore", SIZE, _sand, _water) as Image))
	_attach(root, root, painted)
	var floor_script := load("res://game/world/ground/forest_floor.gd") as GDScript
	_attach(root, root, floor_script.call(&"create", SIZE, _forest) as Node)

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
	var start := Marker2D.new()
	start.name = "start"
	start.position = _world(START_CELL)
	_attach(root, root.get_node(^"Spawns"), start)
	_add_doors(root)
	_add_interactables(root)
	_add_triggers(root)

	_place_border_decals(root, decals)
	_place_flowers(root, decals)
	_place_buildings(root, entities)
	_place_trees(root, entities)
	_place_anchored(root, entities)
	_place_free(root, entities, decals)
	_place_cliff(root, decals)
	_place_pier(root, decals)
	_place_coast_decals(root, decals)
	_place_tall_grass(root, entities)
	var forest_script := load("res://game/world/forest/dense_forest.gd") as GDScript
	var plan: Array[Dictionary] = forest_script.call(&"plan", _forest, SIZE, _landmark_feet,
		FOREST_SEED)
	forest_script.call(&"place", plan, entities, root, false)
	_place_meadow_seeds(root, decals)
	var blocked := _reconcile()
	root.set(&"blocked_cells", blocked)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("pallet_town : %s (%d entités, %d objets de forêt, %d décalcomanies, %d cases bloquées)"
		% [error_string(err), entities.get_child_count(), plan.size(), decals.get_child_count(),
		blocked.size()])
	root.free()
	quit()


# --- Géométrie logique (inchangée) ---------------------------------------------------------


## Lit la géométrie figée du jalon 6 (« # » ou « G » = solide).
func _read_logic() -> bool:
	var text := FileAccess.get_file_as_string(LOGIC_PATH)
	var rows := text.strip_edges().split("\n")
	if rows.size() != SIZE.y:
		push_error("build_pallet_town : %s illisible" % LOGIC_PATH)
		return false
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var c := rows[y][x]
			if c == "#" or c == "G":
				_old_solid[Vector2i(x, y)] = true
	return true


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
				_flower_cells[Vector2i(x, y)] = true


## Natures de l'image : pavés, chemins, sable, eau, forêt (la falaise ouest est habillée en
## forêt), hautes herbes.
func _classify() -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var kind: int = _kinds[y * SIZE.x + x]
			if kind == _kind("COBBLE"):
				_paving[cell] = true
			elif kind == _kind("DIRT"):
				_path[cell] = true
			elif kind == _kind("SAND"):
				_sand[cell] = true
			elif kind == _kind("WATER") or kind == _kind("SHALLOW"):
				_water[cell] = true
			elif kind == _kind("FOREST"):
				_forest[cell] = true
			elif kind == _kind("TALL_GRASS"):
				_tall_grass[cell] = true
			if _obstacle_kinds[y * SIZE.x + x] == _kind("CLIFF") and x < 10:
				_forest[cell] = true
	for rect: Array in EXTRA_PAVING:
		for cell: Vector2i in _rect_cells(rect):
			_path.erase(cell)
			_paving[cell] = true
	for rect: Array in BEACH_SAND:
		for cell: Vector2i in _rect_cells(rect):
			_path.erase(cell)
			_sand[cell] = true
	# Ponton : la mer passe dessous ; sable sous l'eau peu profonde du rivage de la plage.
	for cell: Vector2i in [Vector2i(9, 32), Vector2i(9, 33)]:
		_water[cell] = true
	for cell: Vector2i in _water.keys():
		if cell.x <= 15 and cell.y <= 32:
			_sand[cell] = true


func _rect_cells(rect: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect[1], rect[3] + 1):
		for x: int in range(rect[0], rect[2] + 1):
			cells.append(Vector2i(x, y))
	return cells


## Masque du sol peint (R pavés, G chemin), écrit dans assets/world/maps/. Null tant que
## l'image n'est pas importée.
func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", SIZE, _paving, _path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MASK_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


## Emprises définitives : celles des objets peints rognées aux cases solides du jalon 6 (plus
## [constant NEW_SOLID_CELLS]) ; les cases solides du jalon 6 que ni le sol logique ni un
## objet ne couvrent vont dans `blocked_cells`. Renvoie `blocked_cells`.
func _reconcile() -> Array[Vector2i]:
	var covered: Dictionary = {}
	for cell: Vector2i in BLOCKED_CELLS:
		covered[cell] = true
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var index := y * SIZE.x + x
			for kind: int in [_kinds[index], _obstacle_kinds[index]]:
				if kind >= 0 and _tiles.is_solid_kind(kind):
					covered[Vector2i(x, y)] = true
	var walkable_hits: PackedStringArray = []
	for entry: Array in _placed:
		var node: Node2D = entry[0]
		var anchor: Vector2i = node.call(&"get_anchor_cell")
		var footprint: Array[Vector2i] = []
		for cell: Vector2i in entry[1]:
			if _old_solid.has(cell) or NEW_SOLID_CELLS.has(cell):
				footprint.append(cell - anchor)
				covered[cell] = true
			elif not _water.has(cell) and cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x \
					and cell.y < SIZE.y:
				walkable_hits.append("%s %s" % [node.name, cell])
		node.set(&"footprint", footprint)
	if not walkable_hits.is_empty():
		print("build_pallet_town : emprises rognées sur des cases praticables : %s"
			% ", ".join(walkable_hits))
	var blocked: Array[Vector2i] = BLOCKED_CELLS.duplicate()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _old_solid.has(cell) and not covered.has(cell):
				blocked.append(cell)
	return blocked


# --- Scène : logique ---------------------------------------------------------------------


func _add_doors(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for door: Array in DOORS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = door[0]
		point.position = _world(door[1])
		point.set(&"trigger", STEP_ON)
		point.set(&"direction", Vector2i.UP)
		point.set(&"target_map", door[2])
		point.set(&"target_spawn", door[3])
		_attach(root, root.get_node(^"Warps"), point)
	# Sortie nord vers la Route 1 (jalon 5 §15.5) : warps PUSH « haut » au bord.
	for warp: Array in PUSH_WARPS:
		var push := Marker2D.new()
		push.set_script(warp_script)
		push.name = warp[0]
		push.position = _world(warp[1])
		push.set(&"trigger", PUSH)
		push.set(&"direction", Vector2i.UP)
		push.set(&"target_map", &"route_1")
		push.set(&"target_spawn", warp[2])
		push.set(&"arrival_facing", Vector2i.UP)
		_attach(root, root.get_node(^"Warps"), push)


func _add_interactables(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in INTERACTABLES:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"facing", entry[3])
		point.set(&"dialogue_id", StringName(entry[4]))
		point.set(&"kind", entry[5] if entry.size() > 5 else EXAMINE)
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


# --- Scène : objets peints ---------------------------------------------------------------


func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS + id + ".tscn")
		if _scenes[id] == null:
			push_error("build_pallet_town : objet peint absent « %s »" % id)
	return _scenes[id]


## Objet peint, pied à [param foot] (pixels), emprise demandée [param cells] (absolue,
## rognée par [method _reconcile]).
func _add_prop(root: Node, parent: Node, id: String, foot: Vector2, node_name: String,
		cells: Array, scale: float = 1.0, flip: bool = false) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot.round()
	if scale != 1.0:
		prop.scale = Vector2(scale, scale)
	_attach(root, parent, prop)
	if flip:
		prop.get_node(^"Sprite").set(&"flip_h", true)
	var requested: Array[Vector2i] = []
	requested.assign(cells)
	_placed.append([prop, requested])
	return prop


## Objet peint ancré sur [param cell] : pied et emprise de `PaintedPropRules`.
func _add_anchored(root: Node, parent: Node, id: String, cell: Vector2i, node_name: String,
		scale: float = 1.0, flip: bool = false) -> Node2D:
	var foot: Vector2 = _rules.call(&"foot_position", StringName(id), cell)
	var cells: Array[Vector2i] = []
	for offset: Vector2i in _rules.call(&"footprint", StringName(id)):
		cells.append(cell + offset)
	return _add_prop(root, parent, id, foot, node_name, cells, scale, flip)


func _rect(x0: int, y0: int, x1: int, y1: int, except: Array = []) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _rect_cells([x0, y0, x1, y1]):
		if not except.has(cell):
			cells.append(cell)
	return cells


## Maisons, labo et arbre ancien aux ancres du plan (portes (11, 9), (36, 9), (24, 22)) avec
## les emprises du jalon 1 ; la porte peinte tombe sur la case de porte (à 13 et 18 px près
## pour les maisons). Labo : double porte peinte centrée sur la case (24, 22), ses voisines
## (23, 22) et (25, 22) restent solides.
func _place_buildings(root: Node, entities: Node2D) -> void:
	_add_prop(root, entities, "bldg_maison_rival_01", Vector2(11 * TILE, 10 * TILE),
		"RivalHouse", _rect(8, 5, 14, 9, [Vector2i(11, 9)]))
	# Porte peinte 60 px à gauche du milieu de l'image : pied au bord droit de la case 36.
	_add_prop(root, entities, "bldg_maison_joueur_01", Vector2(37 * TILE - 1, 10 * TILE),
		"PlayerHouse", _rect(33, 5, 39, 9, [Vector2i(36, 9)]))
	var lab := _add_prop(root, entities, "bldg_labo_01", Vector2(24.5 * TILE, 23 * TILE), "OakLab",
		_rect(18, 18, 30, 22, [Vector2i(24, 22)]), LAB_SCALE)
	# Réduit, le toit ne cache plus la rangée 17 : seules les antennes dépassaient sur le
	# joueur et tout le labo devenait transparent. Pas de fondu.
	lab.set(&"fade_when_covering", false)
	# Arbre ancien et son îlot de fleurs bordé de pierre, centré sur la case (24, 16).
	_add_prop(root, entities, "tree_ancien_01", Vector2(24.5 * TILE, 17 * TILE), "PlazaTree",
		_rect(22, 14, 26, 16))
	_landmark_feet.append(Vector2(24.5, 17.0))
	# Bancs de part et d'autre de l'arbre (largeur paire : pied 1 px avant le bord, pour que
	# l'ancre reste la case ouest du banc, comme au jalon 1).
	_add_prop(root, entities, "prop_banc_01", Vector2(20 * TILE - 1, 16 * TILE), "BenchWest",
		[Vector2i(19, 15), Vector2i(20, 15)])
	_add_prop(root, entities, "prop_banc_01", Vector2(29 * TILE - 1, 16 * TILE), "BenchEast",
		[Vector2i(28, 15), Vector2i(29, 15)])
	# Grande serre (ancre (20, 27)) sur l'emprise de 7 × 2 cases : la serre au milieu, de petits
	# potagers de part et d'autre (FREE).
	_add_prop(root, entities, "bldg_serre_01", Vector2(20.5 * TILE, 28 * TILE),
		"GreenhouseLarge", _rect(17, 26, 23, 27))
	# Ronces de l'ancien sentier (ancre (42, 26)).
	_add_prop(root, entities, "prop_ronces_01", Vector2(42.5 * TILE, 27 * TILE),
		"SecretBrambles", [Vector2i(42, 26)])


func _place_trees(root: Node, entities: Node2D) -> void:
	var index := 0
	for entry: Array in TREES:
		var cell: Vector2i = entry[0]
		var flip := index % 3 == 1
		_add_anchored(root, entities, entry[1], cell, "Tree%02d" % index, 1.0, flip)
		_landmark_feet.append(Vector2(cell.x + 0.5, cell.y + 1.0))
		index += 1


func _place_anchored(root: Node, entities: Node2D) -> void:
	for entry: Array in ANCHORED:
		_add_anchored(root, entities, entry[0], entry[1], entry[2], entry[3], entry[4])


func _place_free(root: Node, entities: Node2D, decals: Node2D) -> void:
	for entry: Array in FREE:
		var parent: Node = decals if entry[6] == "ground" else entities
		var foot: Vector2 = entry[1]
		_add_prop(root, parent, entry[0], foot * TILE, entry[2], entry[3], entry[4], entry[5])


## Falaise côtière (couche du sol) sur la rangée 31, de x 15 au bord est.
func _place_cliff(root: Node, decals: Node2D) -> void:
	var index := 0
	for edge: int in range(17, 50, 4):
		_add_anchored(root, decals, "relief_falaise_01", Vector2i(edge, 31), "Cliff%02d" % index,
			1.0, index % 2 == 1)
		index += 1


## Ponton : la bande centrale de l'image, plancher sur (9, 32..33) (couche du sol).
func _place_pier(root: Node, decals: Node2D) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Pier"
	sprite.texture = load(PIER_TEXTURE)
	sprite.material = load(OBJECT_MATERIAL)
	sprite.region_enabled = true
	sprite.region_rect = PIER_REGION
	sprite.centered = false
	sprite.offset = Vector2(-PIER_REGION.size.x / 2.0, -PIER_REGION.size.y)
	sprite.position = Vector2(9.5 * TILE, 34 * TILE + PIER_REGION.size.y - PIER_DECK_BOTTOM)
	_attach(root, decals, sprite)


func _decal(root: Node, parent: Node, texture: String, foot: Vector2, scale: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture)
	sprite.position = foot
	sprite.scale = Vector2.ONE * scale * _decor_rng.randf_range(0.85, 1.15)
	sprite.flip_h = _decor_rng.randf() < 0.5
	_attach(root, parent, sprite)


## Bords des pavés et des chemins (terre, pavés déchaussés, touffes). Pas de pavé déchaussé le
## long d'un chemin de terre ; rien sur le sable, dans l'eau ni sur la falaise.
func _place_border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var ways: Dictionary = _paving.duplicate()
	ways.merge(_path)
	var plan: Array = script.call(&"plan", ways, SIZE, SEED)
	var kept: Array[Dictionary] = []
	for decal: Dictionary in plan:
		var point: Vector2 = decal["position"]
		var cell := Vector2i((point / TILE).floor())
		if _sand.has(cell) or _water.has(cell) or point.y > 30.85 * TILE:
			continue
		if String(decal["texture"]).contains("decal_pave") and not _near_paving(cell):
			continue
		kept.append(decal)
	script.call(&"place", kept, decals, root)


func _near_paving(cell: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _paving.has(cell + d):
			return true
	return false


## Deux fleurs peintes par case fleurie du jalon 1 (jardins, prairie, abords).
func _place_flowers(root: Node, decals: Node2D) -> void:
	for cell: Vector2i in _flower_cells:
		if _old_solid.has(cell):
			continue
		for i in 2:
			var foot := (Vector2(cell) + Vector2(_decor_rng.randf(), _decor_rng.randf())) * TILE
			_decal(root, decals, FLOWER_DECAL % _decor_rng.randi_range(1, 8), foot, 1.0)


## Fleurs côtières sur la lèvre de la falaise et sur le haut de la plage.
func _place_coast_decals(root: Node, decals: Node2D) -> void:
	for attempt in 90:
		var p := Vector2(_decor_rng.randf_range(15.2, 47.8), _decor_rng.randf_range(30.8, 31.05))
		if attempt >= 60:
			p = Vector2(_decor_rng.randf_range(3.2, 14.8), _decor_rng.randf_range(27.1, 28.6))
			if _old_solid.has(Vector2i(p)) or Rect2(5.4, 25.0, 2.2, 3.2).has_point(p):
				continue
		_decal(root, decals, COAST_DECAL % _decor_rng.randi_range(1, 8), p * TILE, 1.0)


## Deux touffes jaune-vert par case de hautes herbes (comme la Route 1), au vent.
func _place_tall_grass(root: Node, entities: Node2D) -> void:
	var wind: Material = load(WIND_MATERIAL)
	var index := 0
	for cell: Vector2i in _tall_grass:
		for k: int in 2:
			var foot := Vector2(cell) + Vector2(_decor_rng.randf_range(0.25, 0.75),
				0.55 + 0.45 * k)
			var tuft := _scene(TALL_GRASS_ID).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) \
				as Node2D
			tuft.name = "Tuft%03d" % index
			tuft.position = (foot * TILE).round()
			_attach(root, entities, tuft)
			index += 1
			var scale := _decor_rng.randf_range(1.0, 1.3)
			tuft.scale = Vector2(scale, scale)
			var sprite := tuft.get_node(^"Sprite")
			sprite.set(&"material", wind)
			sprite.set(&"flip_h", _decor_rng.randf() < 0.5)


## Touffes et fleurs sauvages semées sur l'herbe rase, en gardant des étendues calmes.
func _place_meadow_seeds(root: Node, decals: Node2D) -> void:
	for attempt in MEADOW_ATTEMPTS:
		var p := Vector2(_decor_rng.randf_range(0.5, SIZE.x - 0.5),
			_decor_rng.randf_range(0.5, 30.5))
		var cell := Vector2i(p)
		if _paving.has(cell) or _path.has(cell) or _tall_grass.has(cell) or _forest.has(cell) \
				or _sand.has(cell) or _water.has(cell) or _old_solid.has(cell):
			continue
		if _decor_rng.randf() < MEADOW_FLOWER_CHANCE:
			_decal(root, decals, FLOWER_DECAL % _decor_rng.randi_range(1, 8), p * TILE, 1.0)
		else:
			_decal(root, decals, TUFT_DECAL % _decor_rng.randi_range(1, 4), p * TILE, 0.9)
