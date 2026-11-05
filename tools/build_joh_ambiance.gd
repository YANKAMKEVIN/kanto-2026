extends SceneTree
## Passe d'ambiance du Chapitre Johto (cartes du JOH1 et du JOH2, décision de Kevin du 2026-11-04 :
## « prendre de l'avance sur l'art et l'ambiance de Johto »). Repeint en 2D HD les cartes écrites
## en tuiles provisoires par les outils des jalons, d'après leur vue générale validée : pilote
## **Oliville** (`olivine_city`, `build_joh1_olivine.gd`, vue `oliville-vue-generale-v1.png`), puis
## **Route 39**, **Route 38** et **Rosalia** (`build_joh2_maps.gd`, vues `route-39-`, `route-38-`
## et `rosalia-vue-generale-v1.png`).
##
## Passe APRÈS l'outil de la carte, sur le modèle de `build_daf10b_routes.gd` ; idempotente (elle
## retire d'abord ses propres nœuds). **La logique ne change pas** : couches de tuiles (dont
## `Ground`, source logique), `blocked_cells`, eau surfable, passages, panneaux, déclencheurs, PNJ
## et nœuds de `Entities` gardés ; les couches sont seulement masquées. L'image vient de
## `tools/coast_map_kit.gd` (une racine de kit jetable dont on adopte les nœuds), sur une copie
## **traduite** de la grille (`build/joh_ambiance/plans/`, légende du kit) :
## - forêt serrée `T`, herbe `.` (touffes et fleurs), pavés `p` (et portes `D`, caisses `k`) ;
## - plage de galets `g` (et bouche `E`) : canal vert du masque, texture [constant PEBBLES] ;
## - mer `w` : la mer de Bourg Palette (angles droits, écume) ; rivage rocheux en modules sur les
##   `R` qui touchent l'eau (récifs du bord sud, pied de la falaise ouest) ; les autres `R` et
##   l'emprise du phare `P` : paroi de la série 12, **rognée** là où elle monterait sur une case
##   praticable au nord (avenue) ;
## - quai et pontons `q` : planches du quai en rectangles répétés, bords de quai en bois (série 17,
##   bouts de pontons compris), lampadaires de quai et bittes posés dans l'eau au bord du quai ;
## - haies `x` (haie taillée), massif `y` (hortensias), caisses `k`, arbres repères `G` ;
## - bouche de la grotte marine (`relief_bouche_paroi_01`, couche du sol) ; phare peint
##   (`bldg_phare_oliville_01`, remplace `PharePlaceholder`).
## **Nuit** : les halos du groupe `night_lights` (enfants de `NightLights`) sont reposés par cette
## passe : `night_lamp` sur chaque lampadaire et la lanterne du phare, `night_window` sur les
## fenêtres et vitrines des bâtiments ; cachés de jour (`WorldLighting.set_night`).
## **Route 39** : chemin, hautes herbes (champs de la vue), arbres repères ; rochers et mer de
## décor (la mare de la vue, `W`) ; enclos à clôture blanche (avec son côté est, sur le pré `e`
## bloqué : la grille n'a pas de `f` à l'est), mangeoire et seau [D]. La ferme reste la maison du
## kit de Kanto [D].
## **Route 38** : sentier, hautes herbes, forêt (dont la barrière d'arbres), arbres repères ;
## petite falaise `R` : muret de pierre sur la rangée du bas, forêt sur celle du haut [D].
## **Rosalia** : pavés, hautes herbes, érables (`tree_automne_01` [D]), haies, massifs, bancs ;
## Tour Cendrée, Tour Carillon et maisons traditionnelles peintes. Les tours en aplats de `Decor`
## sont retirées ; `Bat_MaisonSages`, `Bat_Maison1` et `Bat_Maison2` (kit de Kanto) restent dans la
## carte mais **cachés** : leur emprise ne change pas, leur image est remplacée.
## **Lot 2** (branche `claude/ambiance-joh3-7`) : Routes 37, 36, 35 et 34, Doublonville, Bois aux
## Chênes, Écorcia, Routes 40 et 41, par le décor commun [method _johto] et les réglages de
## [constant MAPS] (légende propre à la grille, bâtiments, lampadaires, objets posés). Bâtiments
## propres à Johto peints par Codex (`tools/art/joh_ambiance_lot2.py`) ; les aplats de `Decor` sont
## retirés, les bâtiments du kit remplacés (clé « hide ») cachés avec leur emprise.
## Nœuds posés : racine `PaintedGround`, `JohAmbForestFloor`, `JohAmbDecals` (hors des couches
## d'emprise de `GameMap`) ; enfants préfixés `JohAmb` dans `Entities` (sans emprise propre : les
## cases sont celles de la grille) ; halos de `NightLights`.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après
## (différences attendues : `Entities/PharePlaceholder`, dessin provisoire retiré ; `NightLights`,
## `Node2D` de `build_joh2_maps.gd` devenu calque).
##
##   godot --headless --path . -s res://tools/build_joh_ambiance.gd [-- --maps=olivine_city,route_39]
##   (code 2 : masques écrits ; godot --headless --path . --import, puis relancer)
##   À relancer après chaque reconstruction de la carte par l'outil de son jalon.

const Kit := preload("res://tools/coast_map_kit.gd")
const PortKit := preload("res://tools/vermilion_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const TRANSLATED_DIR: String = "res://build/joh_ambiance/plans/"
const NPCS_PATH: String = "res://data/npcs/%s.json"
const OWN_PREFIX: String = "JohAmb"
const OWN_ROOT: Array[String] = ["PaintedGround", "JohAmbForestFloor", "JohAmbDecals"]
const TILE: int = 96
## Ce que devient la roche `R` de la grille : rivage au bord de l'eau et paroi ailleurs (Oliville),
## rivage partout (Route 39 : deux rangées au-dessus de la mer), muret sur la rangée du bas et
## forêt au-dessus (Route 38).
enum Rock { SHORE_THEN_PAROI, SHORE, WALL }

## Galets de la plage (sol rocheux de la Route 3 : galets gris) [D].
const PEBBLES: String = "res://assets/world/ground/ground_roche_01.png"
## Chemin des routes du JOH2 : le sable, plus proche de la terre orangée des vues générales que
## `ground_chemin_01` (gris-beige, et mauve la nuit) [D].
const EARTH: String = "res://assets/world/ground/ground_sable_01.png"
## Carte → grille, graine, roche, texture du chemin `=` (vide : celle du kit), vitres éclairées la
## nuit (`night_pane` en plus de `night_window` : l'additif se perd sur les vitres claires).
const MAPS: Dictionary = {
	&"olivine_city": {"plan": "oliville", "seed": 39050, "rock": Rock.SHORE_THEN_PAROI,
		"path": PEBBLES, "panes": true},
	&"route_39": {"plan": "route_39", "seed": 39101, "rock": Rock.SHORE, "path": EARTH,
		"panes": true},
	&"route_38": {"plan": "route_38", "seed": 38101, "rock": Rock.WALL, "path": EARTH,
		"panes": true},
	&"ecruteak_city": {"plan": "rosalia", "seed": 42101, "rock": Rock.SHORE, "path": "",
		"panes": true, "hide": ["Bat_MaisonSages", "Bat_Maison1", "Bat_Maison2"]},
	# Lot 2. Clés en plus : « legend » (caractères propres à la grille), « cells » (rectangles
	# [Rect2i, caractère du kit], après la légende), « deck » (platelage), « x » (haies `hedge`,
	# clôtures `fence`, rien sinon), « buildings » [objet, case d'ancrage, nœud, échelle],
	# « hide » (nœuds du kit cachés, emprise gardée), « lamps » (pieds, cases), « props » [objet,
	# pied (cases), nœud, échelle, teinte], « glows » [type, position (cases)], « stairs » (cases).
	&"route_37": {"plan": "route_37", "seed": 37201, "rock": Rock.SHORE, "path": EARTH,
		"panes": true},
	&"route_36": {"plan": "route_36", "seed": 36201, "rock": Rock.SHORE, "path": EARTH,
		"panes": true, "deck": "b", "legend": {"b": "z", "X": "c", "P": "c"},
		"cells": [[Rect2i(30, 1, 8, 3), "T"]],
		"buildings": [["bldg_grille_parc_01", Vector2i(34, 6), "GrilleParc"]],
		"props": [["prop_cloture_piquets_v_01", Vector2(46.3, 12.0), "Chantier", 1.0,
				Color(1.0, 0.56, 0.24)],
			["prop_lampe_chantier_01", Vector2(46.5, 9.1), "ChantierLampe0", 0.6],
			["prop_lampe_chantier_01", Vector2(46.5, 12.1), "ChantierLampe1", 0.6]],
		"glows": [[&"night_lamp", Vector2(46.5, 8.6)], [&"night_lamp", Vector2(46.5, 11.6)]]},
	&"route_35": {"plan": "route_35", "seed": 35201, "rock": Rock.SHORE, "path": EARTH,
		"panes": true, "x": "fence", "legend": {"P": "c", "w": "w"},
		"buildings": [["bldg_maison_toit_01", Vector2i(16, 39), "PosteGarde", Vector2(1.2, 1.2)]]},
	&"goldenrod_city": {"plan": "doublonville", "seed": 34201, "rock": Rock.SHORE, "path": "",
		"panes": true, "x": "hedge", "legend": {"U": "c", "A": "c", "L": "c", "F": "c"},
		"buildings": [["bldg_tour_radio_01", Vector2i(11, 15), "TourRadio"],
			["bldg_grand_magasin_01", Vector2i(50, 27), "GrandMagasin", Vector2(12.0 / 14.0, 1.0)],
			["bldg_gare_doublonville_01", Vector2i(59, 45), "Gare"]],
		"lamps": [Vector2(16.2, 20), Vector2(23.5, 20), Vector2(30.8, 20), Vector2(57.5, 20),
			Vector2(65.5, 20), Vector2(28.5, 25), Vector2(42.5, 25), Vector2(28.5, 34),
			Vector2(42.5, 34), Vector2(6.1, 16), Vector2(15.9, 16), Vector2(20.2, 16),
			Vector2(26.8, 16), Vector2(44.2, 16), Vector2(50.8, 16), Vector2(6.1, 28),
			Vector2(13.9, 28), Vector2(20.2, 28), Vector2(26.8, 28), Vector2(55.9, 28),
			Vector2(30.5, 37), Vector2(40.5, 41), Vector2(52.2, 46), Vector2(65.8, 46),
			Vector2(33.5, 5)],
		"props": [["prop_haut_parleur_01", Vector2(43.5, 25.0), "HautParleur", 1.0]],
		"stairs": [Vector2i(31, 25), Vector2i(39, 33)]},
	&"route_34": {"plan": "route_34", "seed": 34301, "rock": Rock.SHORE, "path": EARTH,
		"panes": true, "x": "fence", "legend": {"M": "w", "w": "w"}},
	&"ilex_forest": {"plan": "ilex_forest", "seed": 34401, "rock": Rock.SHORE, "path": EARTH,
		"panes": false, "shade": 0.8, "legend": {"C": ".", "A": "c", "s": "c", "k": "c"},
		"props": [["prop_autel_bois_01", Vector2(23.5, 12.0), "Autel", 1.0],
			["prop_souche_01", Vector2(11.5, 33.0), "Souche", 1.0],
			["prop_tas_bois_01", Vector2(33.0, 46.0), "Buches", 1.1]]},
	&"azalea_town": {"plan": "azalea_town", "seed": 34501, "rock": Rock.SHORE, "path": "",
		"panes": true, "legend": {"H": "c", "Q": "c", "E": "p"},
		"buildings": [["bldg_charbonnerie_01", Vector2i(9, 10), "Charbonnerie"],
			["bldg_maison_ecorcia_01", Vector2i(10, 30), "MaisonFargas"],
			["bldg_maison_ecorcia_01", Vector2i(30, 30), "Maison1"]],
		"hide": ["Bat_MaisonFargas", "Bat_Maison1"],
		"props": [["prop_puits_ecorcia_01", Vector2(37.5, 8.0), "Puits", 1.0]],
		"lamps": [Vector2(4.9, 11), Vector2(13.2, 11), Vector2(7.1, 21), Vector2(14.9, 21),
			Vector2(27.1, 21), Vector2(34.9, 21), Vector2(7.1, 31), Vector2(13.9, 31),
			Vector2(27.1, 31), Vector2(33.9, 31), Vector2(35.8, 7.6), Vector2(39.2, 7.6)]},
	&"route_40": {"plan": "route_40", "seed": 40201, "rock": Rock.SHORE, "path": PEBBLES,
		"panes": false, "legend": {"s": "s", "o": "w"}},
	&"route_41": {"plan": "route_41", "seed": 41201, "rock": Rock.SHORE, "path": PEBBLES,
		"panes": false, "legend": {"@": "w", "o": "w", ".": "="},
		"cells": [[Rect2i(22, 16, 16, 16), "w"]], "foam": Vector2(30.0, 24.0),
		"buildings": [["relief_ile_tourbillon_01", Vector2i(30, 31), "IleTourbillon"]]},
}
## Traduction des grilles du JOH1 et du JOH2 vers la légende du kit : `T` forêt, `.` herbe, `p`
## pavés, `=` chemin (galets à Oliville, terre ailleurs), `h` hautes herbes, `z` platelage (herbe
## sous les planches), `w` mer, `R` rivage, `#` paroi, `c` solide sans arbre (objets posés par
## cette passe ou par la carte).
const LEGEND: Dictionary = {
	"T": "T", ".": ".", "p": "p", "D": "p", "k": "p", "g": "=", "E": "=", "q": "z", "w": "w",
	"R": "R", "P": "#", "x": "c", "y": "c", "n": "c", "G": "c", "C": "c", "O": "c", "m": "c",
	"N": "c", "=": "=", "h": "h", "W": "w", "f": "c", "e": "c", "M": "c", "B": "c", "K": "c",
	"S": "c",
}
const KIT_WALKABLE: String = ".p=zhs"
## Pendant la pose de la paroi, l'eau compte comme praticable : aucun module sur la mer.
const PAROI_WALKABLE: String = ".p=zhsw"
const WATER_MARKS: Array[String] = ["w", "W"]
const PLANKS_EW: String = "res://assets/world/ground/ground_planches_quai_01.png"
const PLANKS_NS: String = "res://assets/world/ground/ground_planches_quai_ns_01.png"
const WOOD_END: String = "relief_quai_bois_04"
## Paroi rognée : recouvrement gardé sur la case praticable du dessus (pixels), hauteur minimale
## d'un module rogné (en deçà : retiré, la rangée suivante couvre déjà la falaise).
const PAROI_TOP_OVERLAP: float = 12.0
const PAROI_MIN_KEEP: float = 1.3 * TILE
const MEADOW_PER_CELL: float = 0.3
const MEADOW_FLOWER_CHANCE: float = 0.35
const FLOWERS: Array[int] = [1, 3, 5]
const SHADE_VALUE: float = 0.98
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
const RESERVED_KINDS: Array[String] = ["pnj", "pokemon", "objet_visible", "cache"]
const LAMP_IDS: Array[String] = ["prop_lampadaire_01", "prop_lampadaire_quai_01"]

## Oliville : réglages de la composition (cases).
const OLI_TREES: Array = [
	["tree_c_01", 0.8, false], ["tree_a_01", 0.8, true], ["tree_c_01", 0.75, true],
	["tree_c_01", 0.8, false], ["tree_a_01", 0.75, false],
]
const OLI_HEDGE: String = "prop_haie_taillee_01"
const OLI_HEDGE_SCALE_Y: float = 1.25
const OLI_FLOWERS: Array[String] = ["prop_hortensias_01", "prop_fleurs_pales_01"]
## Lampadaires de quai et bittes, posés dans l'eau au bord sud du quai (rangée 34), colonnes.
const OLI_QUAY_LAMPS: Array[int] = [24, 35, 45]
const OLI_BOLLARDS: Array[int] = [26, 31, 38, 43]
## Phare : case d'ancrage (bas de l'emprise, pied sur le bord gauche de la colonne 6).
const OLI_LIGHTHOUSE := Vector2i(6, 18)
## Halos du phare, par rapport au pied (pixels) : lanterne, puis les deux fenêtres de la tour.
const OLI_LANTERN := Vector2(0.0, -1006.0)
const OLI_TOWER_WINDOWS: Array[Vector2] = [Vector2(0.0, -749.0), Vector2(0.0, -553.0)]
## Bouche de la grotte marine : milieu de l'ouverture (pixels de l'image, depuis la gauche) et
## bord droit gardé (cases : la plage `g` commence en x = 11).
const OLI_MOUTH_ID: String = "relief_bouche_paroi_01"
const OLI_MOUTH_COLUMN: int = 10
const OLI_MOUTH_ROW: int = 32
const OLI_MOUTH_RIGHT: float = 11.12
const OLI_MOUTH_TINT := Color(1.0, 0.93, 0.8)

## Routes du JOH2 : arbres repères.
const ROUTE_TREES: Array = [
	["tree_c_01", 0.85, false], ["tree_a_01", 0.85, true], ["tree_c_01", 0.8, true],
]
## Route 39 : clôture blanche de l'enclos (modules de 4 et 3 cases, vertical de 3 cases, un peu
## rentré aux angles pour tomber sur les bouts des modules horizontaux), objets du pré `e` [D].
## Eau claire et écume sous la grande île (`joh_ambiance_lot2.py`, image à 24 px par case).
const JOH_FOAM: String = "res://assets/world/decals/decal_ecume_ile_01.png"
const JOH_FOAM_SCALE: float = 4.0
const JOH_FRUIT_SCALE: float = 0.8
const JOH_ROCK_SCALE: float = 0.62
## Escaliers du Souterrain de Doublonville, sur leur case [D].
const JOH_STAIRS: String = "prop_escalier_souterrain_descend_01"
const JOH_STAIRS_SCALE: float = 0.5
const R39_FENCE_H: Dictionary = {4: "prop_cloture_piquets_01", 3: "prop_cloture_piquets_01_court"}
const R39_FENCE_V: String = "prop_cloture_piquets_v_01"
const R39_FENCE_V_SPAN: int = 3
const R39_FENCE_V_INSET: float = 0.2
## Clôture plus basse que dans le kit (la vue générale la montre à hauteur de genou) [D].
const R39_FENCE_SCALE: float = 0.75
const R39_FEEDER_CELL := Vector2i(13, 33)
const R39_BUCKET_CELL := Vector2i(16, 33)
## Route 38 : muret de pierre (module de 4 cases, un peu plus haut que la rangée).
const R38_WALL: String = "relief_muret_01"
const R38_WALL_SPAN: int = 4
const R38_WALL_SCALE_Y: float = 1.3
## Rosalia : érables repères, bancs, bâtiments peints [identifiant, case d'ancrage, nœud].
const ROS_TREES: Array = [
	["tree_automne_01", 0.72, false], ["tree_automne_01", 0.66, true],
	["tree_automne_01", 0.7, true], ["tree_automne_01", 0.68, false],
]
const ROS_BENCH_SCALE: float = 0.75
## Lampadaires de Rosalia [D], pieds (cases) sur des cases déjà bloquées (la vue générale n'en
## montre pas, mais la ville serait sans lumière la nuit) : angles des bâtiments le long des rues,
## entrée du chemin gardé.
const ROS_LAMPS: Array[Vector2] = [
	Vector2(13.5, 13), Vector2(24.9, 13), Vector2(41.5, 13), Vector2(12.9, 30), Vector2(22.9, 30),
	Vector2(32.1, 30), Vector2(50.9, 30),
]
## Massifs : part d'hortensias et teinte (roses, comme la vue générale) [D].
const ROS_HYDRANGEA_SHARE: float = 0.4
const ROS_HYDRANGEA_TINT := Color(1.25, 0.82, 0.85)
## La porte de la maison de Rosalia est à gauche du milieu de l'image : pied décalé (pixels) pour
## la poser sur la case de la grille.
const ROS_HOUSE_DOOR_SHIFT: float = 40.0
const ROS_BUILDINGS: Array = [
	["bldg_tour_cendree_01", Vector2i(9, 12), "TourCendree"],
	["bldg_tour_carillon_01", Vector2i(50, 9), "TourCarillon"],
	["bldg_maison_rosalia_01", Vector2i(21, 12), "MaisonSages"],
	["bldg_maison_rosalia_01", Vector2i(35, 29), "Maison1"],
	["bldg_maison_rosalia_01", Vector2i(47, 29), "Maison2"],
]
## Lueur douce sur le parvis de la Tour Cendrée (cases, de part et d'autre de la porte).
const ROS_FORECOURT: Array[Vector2] = [Vector2(6.5, 12.5), Vector2(11.5, 12.5)]
## Halos des fenêtres des bâtiments, par rapport au pied (pixels) ; tête des lampadaires.
const WINDOWS: Dictionary = {
	"bldg_centre_01": [Vector2(-250, -193), Vector2(255, -191), Vector2(-4, -120)],
	"bldg_boutique_01": [Vector2(-250, -193), Vector2(250, -193), Vector2(0, -120)],
	"bldg_maison_argenta_01": [Vector2(-176, -165), Vector2(174, -164)],
	"bldg_maison_pecheur_01": [Vector2(-181, -143), Vector2(198, -143)],
	"bldg_maison_rosalia_01": [Vector2(-184, -168), Vector2(156, -168)],
	"bldg_tour_carillon_01": [Vector2(0, -680), Vector2(0, -552), Vector2(0, -426),
		Vector2(0, -298)],
	# Lot 2. La Tour Radio : quelques bureaux allumés, pas toute la façade [D].
	"bldg_tour_radio_01": [Vector2(-300, -226), Vector2(100, -226), Vector2(-100, -360),
		Vector2(300, -360), Vector2(-300, -492), Vector2(100, -620), Vector2(-100, -748),
		Vector2(0, -80)],
	"bldg_gare_doublonville_01": [Vector2(-430, -140), Vector2(-300, -140), Vector2(0, -130),
		Vector2(300, -140), Vector2(430, -140)],
	"bldg_grand_magasin_01": [Vector2(-480, -100), Vector2(-320, -100), Vector2(0, -110),
		Vector2(320, -100), Vector2(480, -100)],
	"bldg_charbonnerie_01": [Vector2(-240, -150), Vector2(-100, -150)],
	"bldg_maison_ecorcia_01": [Vector2(-170, -125), Vector2(170, -125)],
	"bldg_maison_toit_01": [Vector2(-125, -105), Vector2(125, -105)],
}
## Vitres éclairées, là où elles diffèrent des halos de [constant WINDOWS] (pas sur les portes, ni
## sur le store de la Boutique).
const PANES: Dictionary = {
	"bldg_centre_01": [Vector2(-240, -190), Vector2(250, -190)],
	"bldg_boutique_01": [Vector2(-272, -150), Vector2(228, -150)],
}
const LAMP_HEAD: Dictionary = {
	"prop_lampadaire_01": Vector2(0, -222), "prop_lampadaire_quai_01": Vector2(0, -160),
}
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	var wanted: Array = MAPS.keys()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			wanted = Array(arg.trim_prefix("--maps=").split(",")).map(
				func(s: String) -> StringName: return StringName(s))
	for map_id: StringName in wanted:
		if not MAPS.has(map_id):
			push_error("build_joh_ambiance : carte inconnue %s" % map_id)
			_errors += 1
			continue
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_joh_ambiance : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Dictionary = MAPS[map_id]
	var source := PlanGrid.new()
	if not source.load_file("res://tools/plans/%s.txt" % spec["plan"]):
		push_error("%s : %s" % [map_id, source.error])
		_errors += 1
		return
	var size := Vector2i(source.width, source.height)
	var seed_value: int = spec["seed"]
	var kit: Object = Kit.new(_translate(source, map_id, spec), size, seed_value,
		seed_value + 1, seed_value + 2)
	kit.set(&"errors", PackedStringArray())
	kit.call(&"set_marks", KIT_WALKABLE, "#", "")
	_reserve(kit, source, map_id)
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", "", &"johto_auto",
		NPCS_PATH % map_id)
	kit.call(&"make_shade", spec.get("shade", SHADE_VALUE), SHADE_RED, SHADE_BLUE)
	if not kit.call(&"add_ground", MASK_PATH % map_id, kit.call(&"forest_undergrowth")):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			_masks += 1
		else:
			push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
			_errors += 1
		kit.call(&"discard")
		return
	var painted: Node2D = kit_root.get_node(^"PaintedGround")
	if not String(spec["path"]).is_empty():
		painted.set(&"g_texture", load(spec["path"]))
	var decals: Node2D = kit.get(&"decals")
	var entities: Node2D = kit.get(&"entities")
	kit.call(&"place_border_decals", seed_value)
	kit.call(&"place_meadow", int(size.x * size.y * MEADOW_PER_CELL), MEADOW_FLOWER_CHANCE,
		FLOWERS)
	kit.call(&"place_tall_grass")
	var deck: String = spec.get("deck", "q")
	var planks := _place_planks(kit, decals, source.cells_of(deck))
	var edges := _fill_cliff_edges(kit, source)
	kit.call(&"set_marks", PAROI_WALKABLE, "#", "")
	var paroi: int = kit.call(&"place_paroi", seed_value + 3)
	kit.call(&"set_marks", KIT_WALKABLE, "#", "")
	var cropped := _crop_paroi(decals, source)
	var shore: int = kit.call(&"place_shore")
	var quays := 0 if source.cells_of(deck).is_empty() else _place_wood_quays(kit, source, deck)
	var counts := {}
	match map_id:
		&"olivine_city":
			counts = _olivine(kit, source, decals, entities)
		&"route_39":
			counts = _route_39(kit, source, entities)
		&"route_38":
			counts = _route_38(kit, source, decals, entities)
		&"ecruteak_city":
			counts = _rosalia(kit, source, entities)
		_:
			counts = _johto(kit, source, decals, entities, spec)
	var feet: Array[Vector2] = []
	feet.assign(counts.get("feet", []))
	var forest: Vector2i = kit.call(&"place_forest", seed_value + 5, feet, {})
	var errors: PackedStringArray = kit.get(&"errors")
	if not errors.is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(errors)])
		_errors += 1
		kit.call(&"discard")
		return

	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root, spec)
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	var renames := {"PaintedGround": "PaintedGround", "ForestFloor": "JohAmbForestFloor",
		"GroundDecals": "JohAmbDecals"}
	for node_name: String in renames:
		var node: Node = kit_root.get_node(NodePath(node_name))
		_adopt(node, root, root, kit_root)
		node.name = renames[node_name]
		root.move_child(node, index)
		index += 1
	var map_entities := root.get_node(^"Entities")
	for child: Node in (kit_root.get_node(^"Entities") as Node).get_children():
		child.name = OWN_PREFIX + String(child.name)
		_adopt(child, map_entities, root, kit_root)
	var glows := _night_lights(root, counts.get("glows", []) as Array, spec["panes"])
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (planches %d, bord de falaise %d, paroi %d dont %d rognés / %d retirés, "
		% [map_id, error_string(err), planks, edges, paroi, cropped.x, cropped.y]
		+ "rivage %d, quai %d, " % [shore, quays]
		+ "objets %d, halos %d, forêt %d → %d)" % [int(counts.get("props", 0)), glows,
			forest.x, forest.y])
	if err != OK:
		_errors += 1
	root.free()


## Copie traduite de la grille (légende du kit, praticables du kit, positions d'origine), la roche
## selon la clé « rock » de [param spec], la clé « cells » en dernier. Renvoie son chemin.
func _translate(source: Object, map_id: StringName, spec: Dictionary) -> String:
	var rock: Rock = spec["rock"]
	var legend: Dictionary = LEGEND.merged(spec.get("legend", {}), true)
	var lines := PackedStringArray(["PRATICABLES " + KIT_WALKABLE, "",
		"GRILLE %d %d" % [source.width, source.height]])
	for y: int in source.height:
		var row := ""
		for x: int in source.width:
			var mark: String = source.at(Vector2i(x, y))
			var out: String = legend.get(mark, "T")
			if mark == "R":
				out = _rock_mark(source, Vector2i(x, y), rock)
			for entry: Array in spec.get("cells", []):
				if (entry[0] as Rect2i).has_point(Vector2i(x, y)):
					out = entry[1]
			row += out
		lines.append("%02d %s" % [y, row])
	lines.append("FIN")
	var path := TRANSLATED_DIR + "%s.txt" % map_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TRANSLATED_DIR))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	return path


## Caractère du kit pour la roche de [param cell] : voir [enum Rock] (`R` loin de l'eau, en
## 8-voisinage, devient de la paroi `#`).
func _rock_mark(source: Object, cell: Vector2i, rock: Rock) -> String:
	match rock:
		Rock.SHORE:
			return "R"
		Rock.WALL:
			return "T" if source.at(cell + Vector2i.DOWN) == "R" else "c"
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if WATER_MARKS.has(source.at(cell + Vector2i(dx, dy))):
				return "R"
	return "#"


## Cases des PNJ et objets de la grille d'origine (et des places de rechange du fichier des PNJ) :
## la forêt s'en écarte.
func _reserve(kit: Object, source: Object, map_id: StringName) -> void:
	var cells: Array[Vector2i] = []
	var positions: Dictionary = source.get(&"positions")
	for id: String in positions:
		if RESERVED_KINDS.has(String(positions[id]["kind"])):
			cells.append_array(positions[id]["cells"])
	var npcs := NPCS_PATH % map_id
	if FileAccess.file_exists(npcs):
		var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(npcs))
		for key: String in roster:
			var moved: Variant = (roster[key] as Dictionary).get("moved")
			if moved is Dictionary and (moved as Dictionary).has("cell"):
				var cell: Array = moved["cell"]
				cells.append(Vector2i(int(cell[0]), int(cell[1])))
	kit.set(&"reserved_cells", cells)


# --- Oliville -----------------------------------------------------------------------------


## Décor d'Oliville ; renvoie {"props": nombre, "feet": pieds des arbres repères (cases),
## "glows": halos [[type, position (pixels)]] en plus de ceux des objets de la carte}.
func _olivine(kit: Object, source: Object, decals: Node2D, entities: Node2D) -> Dictionary:
	var feet: Array[Vector2] = []
	var glows: Array = []
	var rules: GDScript = kit.get(&"rules")
	var count := _place_trees(kit, source, entities, OLI_TREES, feet)
	count += _place_hedges(kit, source, entities)
	count += _place_flowers(kit, source, entities)
	# Caisses `k` : paire → caisses du port, case seule → petite pile.
	for run: Rect2i in _runs(source.cells_of("k"), 1):
		var id := "prop_caisses_port_01" if run.size.x >= 2 else "prop_caisses_01"
		var foot := Vector2((run.position.x + run.size.x / 2.0) * TILE,
			(run.position.y + 1) * TILE)
		var crates: Node2D = kit.call(&"add_prop", entities, id, foot, "Crates%02d" % count)
		kit.call(&"clear_footprint", crates)
		count += 1
	# Bord sud du quai (dans l'eau, rangée 34) : lampadaires et bittes.
	var edge_row := _quay_edge_row(source)
	for column: int in OLI_QUAY_LAMPS:
		var lamp: Node2D = kit.call(&"add_prop", entities, "prop_lampadaire_quai_01",
			Vector2(column * TILE + TILE / 2.0, edge_row * TILE + 16.0), "QuayLamp%d" % column)
		kit.call(&"clear_footprint", lamp)
		count += 1
	for column: int in OLI_BOLLARDS:
		var bollard: Node2D = kit.call(&"add_prop", entities, "prop_bitte_01",
			Vector2(column * TILE + TILE / 2.0, edge_row * TILE + 14.0), "Bollard%d" % column)
		kit.call(&"clear_footprint", bollard)
		count += 1
	# Bouche de la grotte marine (couche du sol), rognée à droite au bord de la plage.
	_place_mouth(kit, decals)
	count += 1
	# Phare peint.
	var lighthouse: Node2D = kit.call(&"add_prop", entities, "bldg_phare_oliville_01",
		rules.call(&"foot_position", &"bldg_phare_oliville_01", OLI_LIGHTHOUSE), "Phare")
	kit.call(&"clear_footprint", lighthouse)
	count += 1
	glows.append([&"night_lamp", lighthouse.position + OLI_LANTERN])
	for offset: Vector2 in OLI_TOWER_WINDOWS:
		glows.append([&"night_window", lighthouse.position + offset])
	return {"props": count, "feet": feet, "glows": glows}


## Rangée d'eau au sud du quai (première rangée d'eau sous une case `q` de la plus longue étendue).
func _quay_edge_row(source: Object) -> int:
	var best := Rect2i()
	for run: Rect2i in _runs(source.cells_of("q"), 1):
		if run.size.x > best.size.x:
			best = run
	return best.position.y + 1


## Bouche de la grotte marine : ouverture sur la colonne de la bouche `E`, pied au bas de la
## dernière rangée de la bouche, image rognée à droite au bord de la plage.
func _place_mouth(kit: Object, decals: Node2D) -> void:
	var mouth: Node2D = kit.call(&"add_prop", decals, OLI_MOUTH_ID,
		Vector2((OLI_MOUTH_COLUMN + 0.5) * TILE, (OLI_MOUTH_ROW + 1) * TILE), "SeaCaveMouth")
	kit.call(&"clear_footprint", mouth)
	var sprite := mouth.get_node(^"Sprite") as Sprite2D
	var size := sprite.texture.get_size()
	var left := mouth.position.x - size.x / 2.0
	var keep := clampf(OLI_MOUTH_RIGHT * TILE - left, TILE, size.x)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, 0.0, keep, size.y)
	# Pierre grise de la bouche réchauffée vers le beige de la paroi de la série 12 [D].
	mouth.modulate = OLI_MOUTH_TINT


# --- Route 39 -----------------------------------------------------------------------------


## Décor de la Route 39 : arbres repères, enclos et ses objets ; halos : fenêtres de la ferme.
func _route_39(kit: Object, source: Object, entities: Node2D) -> Dictionary:
	var feet: Array[Vector2] = []
	var count := _place_trees(kit, source, entities, ROUTE_TREES, feet)
	var fence := Rect2i()
	for cell: Vector2i in source.cells_of("f"):
		fence = Rect2i(cell, Vector2i.ONE) if fence.size == Vector2i.ZERO \
			else fence.expand(cell + Vector2i.ONE)
	count += _place_fence(kit, entities, fence)
	for entry: Array in [["prop_mangeoire_01", R39_FEEDER_CELL, "Feeder"],
			["prop_arrosoir_seau_01", R39_BUCKET_CELL, "Bucket"]]:
		var cell: Vector2i = entry[1]
		var prop: Node2D = kit.call(&"add_prop", entities, entry[0],
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, entry[2])
		kit.call(&"clear_footprint", prop)
		count += 1
	return {"props": count, "feet": feet}


## Clôture blanche autour de [param rect] (cases des côtés compris) : nord et sud en modules du
## plus long au plus court, ouest et est en modules de [constant R39_FENCE_V_SPAN] cases.
func _place_fence(kit: Object, entities: Node2D, rect: Rect2i) -> int:
	var count := 0
	for row: int in [rect.position.y, rect.end.y - 1]:
		var at := 0
		while at < rect.size.x:
			var rest := rect.size.x - at
			var span := 3 if rest == 3 or rest == 6 else 4
			var fence: Node2D = kit.call(&"add_prop", entities, R39_FENCE_H[span],
				Vector2((rect.position.x + at + span / 2.0) * TILE, (row + 1) * TILE),
				"Fence%02d" % count)
			kit.call(&"clear_footprint", fence)
			fence.scale.y = R39_FENCE_SCALE
			at += span
			count += 1
	for side: float in [rect.position.x + R39_FENCE_V_INSET, rect.end.x - R39_FENCE_V_INSET]:
		var y := rect.position.y + R39_FENCE_V_SPAN
		while y < rect.end.y - 1:
			var fence: Node2D = kit.call(&"add_prop", entities, R39_FENCE_V,
				Vector2(side, y + 1) * TILE, "Fence%02d" % count)
			kit.call(&"clear_footprint", fence)
			fence.scale.x = R39_FENCE_SCALE
			y += R39_FENCE_V_SPAN
			count += 1
	return count


# --- Route 38 -----------------------------------------------------------------------------


## Décor de la Route 38 : arbres repères et muret de pierre sur la rangée du bas de la falaise.
func _route_38(kit: Object, source: Object, decals: Node2D, entities: Node2D) -> Dictionary:
	var feet: Array[Vector2] = []
	var count := _place_trees(kit, source, entities, ROUTE_TREES, feet)
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var foot_cells: Array[Vector2i] = []
	for cell: Vector2i in source.cells_of("R"):
		if source.at(cell + Vector2i.DOWN) != "R":
			foot_cells.append(cell)
	for run: Rect2i in _runs(foot_cells):
		var at := 0
		while at < run.size.x:
			var span := mini(R38_WALL_SPAN, run.size.x - at)
			var wall: Node2D = kit.call(&"add_prop", decals, R38_WALL,
				Vector2((run.position.x + at + span / 2.0) * TILE, (run.position.y + 1) * TILE),
				"Wall%02d" % count)
			wall.scale = Vector2(float(span) / R38_WALL_SPAN, R38_WALL_SCALE_Y)
			kit.call(&"flip", wall, decor.randf() < 0.5)
			at += span
			count += 1
	return {"props": count, "feet": feet}


# --- Rosalia ------------------------------------------------------------------------------


## Décor de Rosalia : érables, haies, massifs, bancs et bâtiments peints ; halos : parvis de la
## Tour Cendrée (les fenêtres viennent des objets de la carte).
func _rosalia(kit: Object, source: Object, entities: Node2D) -> Dictionary:
	var feet: Array[Vector2] = []
	var glows: Array = []
	var rules: GDScript = kit.get(&"rules")
	var count := _place_trees(kit, source, entities, ROS_TREES, feet)
	count += _place_hedges(kit, source, entities)
	count += _place_flowers(kit, source, entities, ROS_HYDRANGEA_SHARE, ROS_HYDRANGEA_TINT)
	for cell: Vector2i in source.cells_of("n"):
		var bench: Node2D = kit.call(&"add_prop", entities, "prop_banc_01",
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Bench%02d" % count)
		kit.call(&"clear_footprint", bench)
		bench.scale = Vector2.ONE * ROS_BENCH_SCALE
		count += 1
	for entry: Array in ROS_BUILDINGS:
		var foot: Vector2 = rules.call(&"foot_position", StringName(entry[0]), entry[1])
		if entry[0] == "bldg_maison_rosalia_01":
			foot.x += ROS_HOUSE_DOOR_SHIFT
		var building: Node2D = kit.call(&"add_prop", entities, entry[0], foot, entry[2])
		kit.call(&"clear_footprint", building)
		count += 1
	# Après les bâtiments : à pieds égaux, le dernier posé est dessiné devant.
	for foot: Vector2 in ROS_LAMPS:
		var lamp: Node2D = kit.call(&"add_prop", entities, "prop_lampadaire_01", foot * TILE,
			"Lamp%02d" % count)
		kit.call(&"clear_footprint", lamp)
		count += 1
	for cell: Vector2 in ROS_FORECOURT:
		glows.append([&"night_window", cell * TILE])
	return {"props": count, "feet": feet, "glows": glows}


# --- Lot 2 --------------------------------------------------------------------------------


## Décor commun du lot 2 : arbres repères `G`, fruitiers `a`, haies ou clôtures `x`, massifs `y`,
## bancs `n`, rochers `r` et rochers de mer `o`, bâtiments, objets posés, escaliers, lampadaires.
func _johto(kit: Object, source: Object, decals: Node2D, entities: Node2D,
		spec: Dictionary) -> Dictionary:
	var feet: Array[Vector2] = []
	var glows: Array = []
	var rules: GDScript = kit.get(&"rules")
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var count := _place_trees(kit, source, entities, ROUTE_TREES, feet)
	for cell: Vector2i in source.cells_of("a"):
		var fruit: Node2D = kit.call(&"add_prop", entities, "tree_fruitier_01",
			rules.call(&"foot_position", &"tree_fruitier_01", cell), "Fruit%02d" % count)
		kit.call(&"clear_footprint", fruit)
		fruit.scale = Vector2.ONE * JOH_FRUIT_SCALE
		kit.call(&"flip", fruit, decor.randf() < 0.5)
		feet.append(fruit.position / float(TILE))
		count += 1
	match spec.get("x", ""):
		"hedge":
			count += _place_hedges(kit, source, entities)
		"fence":
			count += _place_fence_rows(kit, source, entities)
	# Massifs roses, comme le jardin de la vue générale de Doublonville [D].
	count += _place_flowers(kit, source, entities, ROS_HYDRANGEA_SHARE, ROS_HYDRANGEA_TINT)
	for cell: Vector2i in source.cells_of("n"):
		var bench: Node2D = kit.call(&"add_prop", entities, "prop_banc_01",
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Bench%02d" % count)
		kit.call(&"clear_footprint", bench)
		bench.scale = Vector2.ONE * ROS_BENCH_SCALE
		count += 1
	for cell: Vector2i in source.cells_of("r"):
		var rock: Node2D = kit.call(&"add_prop", entities, "prop_rocher_01",
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Rock%02d" % count)
		kit.call(&"clear_footprint", rock)
		rock.scale = Vector2.ONE * JOH_ROCK_SCALE
		count += 1
	for cell: Vector2i in source.cells_of("o"):
		var foot := (Vector2(cell) + Vector2(0.5, 0.92)) * TILE
		var stone: Node2D = kit.call(&"add_prop", entities, "prop_rocher_mer_01", foot,
			"SeaRock%02d" % count)
		kit.call(&"clear_footprint", stone)
		stone.scale = Vector2.ONE * decor.randf_range(0.62, 0.78)
		kit.call(&"flip", stone, decor.randf() < 0.5)
		count += 1
	if spec.has("foam"):
		var foam := Sprite2D.new()
		foam.name = "Ecume"
		foam.texture = load(JOH_FOAM)
		foam.position = (spec["foam"] as Vector2) * TILE
		foam.scale = Vector2.ONE * JOH_FOAM_SCALE
		kit.call(&"attach", decals, foam)
	for entry: Array in spec.get("buildings", []):
		var foot: Vector2 = rules.call(&"foot_position", StringName(entry[0]), entry[1])
		var building: Node2D = kit.call(&"add_prop", entities, entry[0], foot, entry[2])
		kit.call(&"clear_footprint", building)
		if entry.size() > 3:
			building.scale = entry[3]
		count += 1
	for entry: Array in spec.get("props", []):
		var prop: Node2D = kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * TILE, entry[2])
		kit.call(&"clear_footprint", prop)
		prop.scale = Vector2.ONE * float(entry[3])
		if entry.size() > 4:
			prop.modulate = entry[4]
		count += 1
	for cell: Vector2i in spec.get("stairs", []):
		var stairs: Node2D = kit.call(&"add_prop", decals, JOH_STAIRS,
			(Vector2(cell) + Vector2(0.5, 1.05)) * TILE, "Stairs%02d" % count)
		kit.call(&"clear_footprint", stairs)
		stairs.scale = Vector2.ONE * JOH_STAIRS_SCALE
		count += 1
	# Après les bâtiments : à pieds égaux, le dernier posé est dessiné devant.
	for foot: Vector2 in spec.get("lamps", []):
		var lamp: Node2D = kit.call(&"add_prop", entities, "prop_lampadaire_01", foot * TILE,
			"Lamp%02d" % count)
		kit.call(&"clear_footprint", lamp)
		count += 1
	for entry: Array in spec.get("glows", []):
		glows.append([entry[0], (entry[1] as Vector2) * TILE])
	return {"props": count, "feet": feet, "glows": glows}


## Clôtures `x` : étendues horizontales en modules de piquets blancs (voir [method _place_fence]).
func _place_fence_rows(kit: Object, source: Object, entities: Node2D) -> int:
	var count := 0
	for run: Rect2i in _runs(source.cells_of("x"), 1):
		var at := 0
		while at < run.size.x:
			var rest := run.size.x - at
			var span := rest if rest <= 3 else (3 if rest == 6 else 4)
			var id: String = R39_FENCE_H[4] if span == 4 else R39_FENCE_H[3]
			var fence: Node2D = kit.call(&"add_prop", entities, id,
				Vector2((run.position.x + at + span / 2.0) * TILE, (run.position.y + 1) * TILE),
				"Fence%02d" % count)
			kit.call(&"clear_footprint", fence)
			fence.scale = Vector2(float(span) / (4.0 if span == 4 else 3.0), R39_FENCE_SCALE)
			at += span
			count += 1
	return count


# --- Communs ------------------------------------------------------------------------------


## Arbres repères `G` ([param specs] : [identifiant, échelle, miroir], à tour de rôle) ; ajoute
## leurs pieds (cases) à [param feet]. Renvoie leur nombre.
func _place_trees(kit: Object, source: Object, entities: Node2D, specs: Array,
		feet: Array[Vector2]) -> int:
	var rules: GDScript = kit.get(&"rules")
	var index := 0
	for cell: Vector2i in source.cells_of("G"):
		var spec: Array = specs[index % specs.size()]
		var tree: Node2D = kit.call(&"add_prop", entities, spec[0],
			rules.call(&"foot_position", StringName(spec[0]), cell), "Tree%02d" % index)
		kit.call(&"clear_footprint", tree)
		tree.scale = Vector2(spec[1], spec[1])
		kit.call(&"flip", tree, spec[2])
		feet.append(tree.position / float(TILE))
		index += 1
	return index


## Haies `x` : modules de deux cases, le dernier étiré sur trois si l'étendue est impaire. Renvoie
## leur nombre.
func _place_hedges(kit: Object, source: Object, entities: Node2D) -> int:
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var count := 0
	for run: Rect2i in _runs(source.cells_of("x")):
		var at := 0
		while at < run.size.x:
			var span := 2 if run.size.x - at != 3 else 3
			span = mini(span, run.size.x - at)
			var foot := Vector2((run.position.x + at + span / 2.0) * TILE,
				(run.position.y + 1) * TILE)
			var hedge: Node2D = kit.call(&"add_prop", entities, OLI_HEDGE, foot,
				"Hedge%02d" % count)
			kit.call(&"clear_footprint", hedge)
			hedge.scale = Vector2(span / 2.0, OLI_HEDGE_SCALE_Y)
			kit.call(&"flip", hedge, decor.randf() < 0.5)
			at += span
			count += 1
	return count


## Massif `y` : hortensias et fleurs pâles mêlés, deux touffes par case en quinconce (rangées
## décalées d'une demi-touffe), pour ne pas lire des rangées de culture. Renvoie leur nombre.
func _place_flowers(kit: Object, source: Object, entities: Node2D,
		hydrangea_share: float = 0.55, hydrangea_tint: Color = Color.WHITE) -> int:
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in source.cells_of("y"):
		var shift := 0.12 if cell.y % 2 == 0 else -0.12
		for k: int in 2:
			var hydrangea := decor.randf() < hydrangea_share
			var id: String = OLI_FLOWERS[0] if hydrangea else OLI_FLOWERS[1]
			var foot := Vector2(cell.x + 0.27 + 0.46 * k + shift + decor.randf_range(-0.1, 0.1),
				cell.y + 0.6 + 0.35 * k + decor.randf_range(-0.05, 0.05)) * TILE
			var bush: Node2D = kit.call(&"add_prop", entities, id, foot, "Flowers%03d" % index)
			kit.call(&"clear_footprint", bush)
			var s := decor.randf_range(0.72, 0.92)
			bush.scale = Vector2(s, s)
			kit.call(&"flip", bush, decor.randf() < 0.5)
			var value := decor.randf_range(0.92, 1.04)
			bush.modulate = Color(value, value, value) * (hydrangea_tint if hydrangea else Color.WHITE)
			index += 1
	return index


## Étendues horizontales (rectangles d'une rangée) de [param cells], d'au moins [param minimum]
## cases, dans l'ordre de la carte.
func _runs(cells: Array[Vector2i], minimum: int = 2) -> Array[Rect2i]:
	var left: Dictionary = {}
	for cell: Vector2i in cells:
		left[cell] = true
	var keys: Array = left.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var out: Array[Rect2i] = []
	for start: Vector2i in keys:
		if left.has(start - Vector2i(1, 0)) or not left.has(start):
			continue
		var width := 1
		while left.has(start + Vector2i(width, 0)):
			width += 1
		if width >= minimum:
			out.append(Rect2i(start, Vector2i(width, 1)))
	return out


## Platelage (`q`) : planches du quai en rectangles répétés (dans les décors au sol), est-ouest
## sur le quai, nord-sud sur les pontons.
func _place_planks(kit: Object, decals: Node2D, cells: Array[Vector2i]) -> int:
	var left: Dictionary = {}
	for cell: Vector2i in cells:
		left[cell] = true
	var index := 0
	var keys: Array = left.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	for start: Vector2i in keys:
		if not left.has(start):
			continue
		var width := 1
		while left.has(start + Vector2i(width, 0)):
			width += 1
		var height := 1
		while true:
			var full := true
			for dx: int in width:
				full = full and left.has(start + Vector2i(dx, height))
			if not full:
				break
			height += 1
		for dy: int in height:
			for dx: int in width:
				left.erase(start + Vector2i(dx, dy))
		var sprite := Sprite2D.new()
		sprite.name = "Planks%02d" % index
		sprite.texture = load(PLANKS_EW if width >= height else PLANKS_NS)
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(width, height) * TILE)
		sprite.position = Vector2(start * TILE)
		kit.call(&"attach", decals, sprite)
		index += 1
	return index


## Bord de la falaise : un bloc de rocher (`relief_rivage_06`, une case) sur chaque case de paroi
## qui touche une case praticable de terre, posé **avant** la paroi : il bouche les jours entre
## les modules (sous-bois sombre) au bord des chemins, de la plage et de la bouche. Renvoie leur
## nombre.
func _fill_cliff_edges(kit: Object, source: Object) -> int:
	var cliffs: Dictionary = kit.get(&"cliff_cells")
	var ordered: Array = cliffs.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var count := 0
	for cell: Vector2i in ordered:
		var edge := false
		for side: Vector2i in SIDES:
			edge = edge or _is_land_walkable(source, cell + side)
		if edge:
			kit.call(&"_place_block", cell)
			count += 1
	return count


## Paroi rognée : un module dont le haut monterait sur une case praticable posée **au-dessus** de
## la falaise (avenue au nord) est coupé à cette case (avec [constant PAROI_TOP_OVERLAP]), ou
## retiré s'il en reste trop peu. Renvoie [rognés, retirés].
func _crop_paroi(decals: Node2D, source: Object) -> Vector2i:
	var cropped := 0
	var removed := 0
	for child: Node in decals.get_children():
		if not String(child.name).begins_with("Paroi"):
			continue
		var prop := child as Node2D
		var sprite := prop.get_node(^"Sprite") as Sprite2D
		var size := sprite.texture.get_size()
		var top := prop.position.y - size.y
		var x0 := floori((prop.position.x - size.x / 2.0 + TILE / 4.0) / TILE)
		var x1 := floori((prop.position.x + size.x / 2.0 - TILE / 4.0) / TILE)
		var limit := -INF
		for x: int in range(x0, x1 + 1):
			for y: int in range(floori(top / TILE), floori(prop.position.y / TILE)):
				var cell := Vector2i(x, y)
				var below: String = source.at(cell + Vector2i.DOWN)
				if _is_land_walkable(source, cell) and not below.is_empty() \
						and not _is_land_walkable(source, cell + Vector2i.DOWN):
					limit = maxf(limit, float((y + 1) * TILE))
		if limit == -INF:
			continue
		var cut := limit - PAROI_TOP_OVERLAP - top
		if cut <= 0.0:
			continue
		if size.y - cut < PAROI_MIN_KEEP:
			decals.remove_child(prop)
			prop.free()
			removed += 1
			continue
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0.0, cut, size.x, size.y - cut)
		sprite.offset.y = -(size.y - cut)
		cropped += 1
	return Vector2i(cropped, removed)


func _is_land_walkable(source: Object, cell: Vector2i) -> bool:
	var mark: String = source.at(cell)
	return not mark.is_empty() and not WATER_MARKS.has(mark) and source.is_walkable(cell)


## Bords de quai en bois (série 17) sur les seules frontières eau / platelage `q` : le reste du
## sol (plage, rochers) passe pour un « pont » le temps de la pose (aucun quai de pierre). Bouts
## de pontons (étendue « au nord » d'au plus deux cases, eau des deux côtés) :
## [constant WOOD_END]. Renvoie le nombre de modules.
func _place_wood_quays(kit: Object, source: Object, deck: String = "q") -> int:
	var water: Dictionary = kit.get(&"water_cells")
	var bridges: Dictionary = kit.get(&"bridge_cells")
	var fake: Array[Vector2i] = []
	for y: int in source.height:
		for x: int in source.width:
			var cell := Vector2i(x, y)
			if not water.has(cell) and source.at(cell) != deck and not bridges.has(cell):
				bridges[cell] = true
				fake.append(cell)
	var tables := {"z": PortKit.WOOD_PIECES}
	kit.set(&"quay_sets", tables)
	var count: int = kit.call(&"place_quays")
	for cell: Vector2i in fake:
		bridges.erase(cell)
	# Bouts de pontons : module « n » sous une case `q` sans platelage à gauche ni à droite.
	var end_texture: Texture2D = null
	var end_material: Material = null
	for piece: Dictionary in kit.get(&"quay_pieces"):
		if piece["side"] != &"n":
			continue
		var rect: Rect2 = piece["rect"]
		var first := Vector2i(int(rect.position.x) / TILE, int(rect.position.y) / TILE)
		var cells := int(roundf(rect.size.x / TILE))
		var land_left: bool = source.at(first + Vector2i(-1, -1)) == deck
		var land_right: bool = source.at(first + Vector2i(cells, -1)) == deck
		if land_left or land_right or cells > 2:
			continue
		if end_texture == null:
			var model: Sprite2D = (kit.get(&"forest_script") as GDScript).call(
				&"painted_sprite_model", StringName(WOOD_END))
			end_texture = model.texture
			end_material = model.material
			model.free()
		var sprite: Sprite2D = piece["node"]
		sprite.texture = end_texture
		sprite.material = end_material
		sprite.scale = Vector2(rect.size.x / end_texture.get_width(), 1.0)
	return count


## Halos de nuit : `NightLights` vidé puis rempli (groupe `night_lights`, cachés au départ) :
## [param extra] ([type, position]), lampadaires de `Entities` (tête), fenêtres des bâtiments
## peints de `Entities` (et leurs vitres avec [param panes]). Renvoie le nombre de halos.
func _night_lights(root: Node, extra: Array, panes: bool) -> int:
	var lights := root.get_node_or_null(^"NightLights")
	if lights != null and not lights is CanvasLayer:
		root.remove_child(lights)
		lights.free()
		lights = null
	if lights == null:
		# Calque au-dessus de l'étalonnage d'écran (et du gain à plat de l'économie), qui suit la
		# caméra : la nuit assombrit le monde, pas la lumière des lampes (relevé de QA A17).
		var layer := CanvasLayer.new()
		layer.name = "NightLights"
		layer.layer = UiTokens.LAYER_NIGHT_LIGHTS
		layer.follow_viewport_enabled = true
		root.add_child(layer)
		layer.owner = root
		lights = layer
	for child: Node in lights.get_children():
		lights.remove_child(child)
		child.free()
	var entries: Array = extra.duplicate()
	for prop: Node in root.get_node(^"Entities").get_children():
		var id := _prop_id(prop)
		if prop is CanvasItem and not (prop as CanvasItem).visible:
			continue
		if LAMP_HEAD.has(id):
			entries.append([&"night_lamp", (prop as Node2D).position + LAMP_HEAD[id]])
		elif WINDOWS.has(id):
			var scale := (prop as Node2D).scale
			for offset: Vector2 in WINDOWS[id]:
				entries.append([&"night_window", (prop as Node2D).position + offset * scale])
			if panes:
				for offset: Vector2 in PANES.get(id, WINDOWS[id]):
					entries.append([&"night_pane", (prop as Node2D).position + offset * scale])
	var index := 0
	for entry: Array in entries:
		var glow := Sprite2D.new()
		glow.set_script(load("res://game/world/lighting/light_glow.gd"))
		glow.name = "Lampe%02d" % index
		glow.set(&"glow_type", entry[0])
		glow.position = (entry[1] as Vector2).round()
		glow.visible = false  # écrasé par LightGlow._ready : Boot rappelle set_night
		glow.add_to_group(&"night_lights", true)
		lights.add_child(glow)
		glow.owner = root
		index += 1
	return index


## Identifiant de l'objet peint d'un nœud de `Entities` (d'après la texture de son `Sprite`).
func _prop_id(prop: Node) -> String:
	var sprite := prop.get_node_or_null(^"Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path.get_file().get_basename()


## Retire ce que cette passe a posé (relance) et les dessins provisoires de l'outil de la carte
## (phare, tours en aplats de `Decor`) ; cache les bâtiments du kit remplacés.
func _clean(root: Node, spec: Dictionary) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		var n := String(child.name)
		if n.begins_with(OWN_PREFIX) or n == "PharePlaceholder":
			entities.remove_child(child)
			child.free()
		elif (spec.get("hide", []) as Array).has(n):
			(child as CanvasItem).visible = false
	var decor := root.get_node_or_null(^"Decor")
	if decor != null:
		for child: Node in decor.get_children():
			if child is Polygon2D:
				decor.remove_child(child)
				child.free()


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir
## `build_daf4_exterieurs.gd`).
func _adopt(node: Node, parent: Node, root: Node, kit_root: Node) -> void:
	var owned: Array[Node] = []
	_collect(node, kit_root, owned)
	for n: Node in owned:
		n.owner = null
	node.get_parent().remove_child(node)
	parent.add_child(node)
	for n: Node in owned:
		n.owner = root


func _collect(node: Node, kit_root: Node, into: Array[Node]) -> void:
	if node.owner == kit_root:
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, kit_root, into)
