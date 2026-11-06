extends SceneTree
## Passe d'ambiance des grottes du Chapitre Johto (décision de Kevin du 2026-11-04) : repeint les
## deux salles de la grotte marine (`sea_cave_1`, `sea_cave_2`, `build_joh1_sea_cave.gd`) d'après
## leurs vues générales validées (`grotte-marine-1-vue-generale-v1.png`, `-2-`) et la bouche de la
## grotte à Bourg Palette (`build_joh1_pallet_cave.gd`). Modèles : `build_joh_ambiance.gd` (Oliville)
## et `build_daf4_caves.gd` (Grotte Azurée : même sol, parois du Mont Sélénite).
##
## Passe APRÈS les outils d'origine ; idempotente (elle retire d'abord ses propres nœuds, préfixe
## `JohAmbCave`). **La logique ne change pas** : couches de tuiles (dont `Ground`, source logique),
## `surf_cells`, `current_cells`, `forced_surf_cells`, `blocked_cells`, [CurrentGate] `CourantChenal`,
## [FlagGate] `LugiaShadow` et son animation, passages, arrivées, déclencheurs, PNJ d'objets gardés ;
## les couches sont seulement masquées. Rien de posé ici n'a d'emprise (`Sprite2D` seuls, ou
## `WorldProp` hors des couches d'emprise de `GameMap`).
##
## **Salles** (`tools/cave_map_kit.gd`, une racine de kit jetable dont on adopte les nœuds) :
## - sol peint : îlots `.` = base (`ground_azuree_bas_01`), parois `#` = canal G
##   (`ground_masse_roche_01`), parois du Mont Sélénite en modules, tirées vers le bleu [D] ;
## - eau `w d > v` et sous les rochers `o` : eau animée du sol peint (`square_shore`, texture
##   `ground_eau_grotte_01`, sans écume), comme la mer d'Oliville : la frange est dans les parois ;
## - voile de l'eau `<carte>_eau.png` (8 px par case, écrit ici) : turquoise lumineux le long des
##   rives, bleu nuit au large, presque noir sur l'eau profonde `d` (sous l'ombre de Lugia) ;
## - masse rocheuse couverte de modules de face empilés, plus sombres loin des galeries ;
## - rebords d'îlots (`relief_rebord_azuree_*`), rochers `o` (`prop_rocher_grotte_01`) ;
## - plage `g`, sortie `E` et îlots : bandes refroidies de `ground_roche_01` et du sol ;
## - courant permanent de la salle 1 et cascade : `ground_courant_01` qui défile
##   (`game/world/ground/water_flow.gdshader`, image seule) ; le chenal de la salle 2 reste dessiné
##   par son [CurrentGate] ;
## - puits de lumière : halos `shaft` (flaque) et `beam` (colonne) dans `JohAmbCaveGlows` ; le
##   profil de lumière `sea_cave` ne change pas.
##
## **Lot 2** (branche `claude/ambiance-joh3-7`) : Puits Ramoloss B1F et B2F (`build_joh4_maps.gd`,
## vues `puits-ramoloss-*`) et Îles Tourbillon 1F, B1F et B2F (`build_joh7_maps.gd`, vues
## `iles-tourbillon-*`), mêmes briques, réglages dans [constant MAPS] : sol, bandes (gravats `g`),
## teintes, eau (rochers `o` sur l'eau seulement), échelles `U` / `V` (les dessins provisoires des
## nœuds `Echelle*` sont retirés, le nœud reste), caisses `R`, courants et cascades `F` (image
## seule), halo provisoire de `Decor` remplacé par les puits de lumière. Souterrain de Doublonville
## (`build_joh3_maps.gd`, vue `souterrain-doublonville-*`) : dalles et murs du Souterrain de Kanto
## en modules (`tools/module_walls.gd`, clé « modules »), rideaux de fer sur les boutiques `b`,
## escaliers `E` tournés vers la ville, caisse `k`.
##
## **Bourg Palette** : seuls les dessins des [FlagGate] `Joh1GrotteOuverte` et `Joh1GrotteFermee`
## changent (aplats `Polygon2D` retirés, images peintes en enfants) ; les portes, leurs conditions,
## les passages et le déclencheur restent ceux de `build_joh1_pallet_cave.gd`.
##
## **Lot JOH6** (Tour Cendrée 1F et B1F, Repaire Rocket d'Acajou B1F à B3F ; boutique : voir
## `build_joh6_paint_shop.gd`) : mêmes briques, réglages [constant MAPS] (clés « joh6 », « marks »,
## « props », « beams », « abyss », « partitions »…). Les aplats `Polygon2D` de `build_joh6_maps.gd`
## sont retirés ; les [FlagGate] (escaliers du repaire, porte à mot de passe, grille de la cellule,
## barreaux de la cage et son halo, levier), les dalles tournantes (`SpinTiles` et leurs décalcomanies)
## et les trous FALL gardent leur logique : seul leur dessin devient peint ([method _paint_gates]).
## À relancer après `build_joh6_maps.gd`.
##
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
##   godot --headless --path . -s res://tools/build_joh_ambiance_caves.gd [-- --maps=sea_cave_1]
##   (code 2 : images écrites ; godot --headless --path . --import, puis relancer)
##   À relancer après `build_joh1_sea_cave.gd` ou `build_joh1_pallet_cave.gd`.

const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const TINT_PATH: String = "res://assets/world/maps/%s_eau.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const PROPS: String = "res://game/world/props/painted/%s.tscn"
const FLOW_SHADER: String = "res://game/world/ground/water_flow.gdshader"
const OWN_PREFIX: String = "JohAmbCave"
const OWN_ROOT: Array[String] = ["PaintedGround", "JohAmbCaveTint", "JohAmbCaveSol",
	"JohAmbCaveGlows"]
const TILE: int = 96
const PALLET: StringName = &"pallet_town"
## Carte → grille, graine ; le reste : réglages du lot 2 (défauts : la grotte marine). « floor »,
## « mass » : textures ; « bands » [caractères, texture, teinte, préfixe] ; « wall », « rock » :
## teintes ; « land » : caractères bordés d'un rebord au-dessus de l'eau ; « water » : caractères
## d'eau ; « deep » : teinte de `d` ; « flows » [rectangle de cases, sens] ; « falls » [rectangle].
const MAPS: Dictionary = {
	&"sea_cave_1": {"plan": "grotte_marine_1", "seed": 3171},
	&"sea_cave_2": {"plan": "grotte_marine_2", "seed": 3181},
	&"slowpoke_well_b1f": {"plan": "slowpoke_well_b1f", "seed": 3471, "floor": "ground_grotte_01",
		"bands": [[".UVo", "ground_grotte_01", Color(0.74, 0.76, 0.8), "Floor"],
			["g", "ground_gravats_01", Color(0.78, 0.74, 0.74), "Rubble"]],
		"wall": Color(0.56, 0.6, 0.74), "rock": Color(0.7, 0.72, 0.8), "land": ".g", "water": "w"},
	&"slowpoke_well_b2f": {"plan": "slowpoke_well_b2f", "seed": 3481, "floor": "ground_grotte_01",
		"bands": [[".UoR", "ground_grotte_01", Color(0.62, 0.66, 0.76), "Floor"],
			["g", "ground_gravats_01", Color(0.7, 0.67, 0.7), "Rubble"]],
		"wall": Color(0.5, 0.55, 0.72), "rock": Color(0.62, 0.65, 0.76), "land": ".g",
		"water": "w"},
	&"whirl_islands_1f": {"plan": "whirl_islands_1f", "seed": 4271, "floor": "ground_grotte_01",
		"bands": [[".VEo", "ground_grotte_01", Color(0.9, 0.84, 0.82), "Floor"],
			["g", "ground_gravats_01", Color(0.92, 0.84, 0.76), "Rubble"]],
		"wall": Color(0.56, 0.6, 0.78), "rock": Color(0.74, 0.72, 0.76), "land": "", "water": ""},
	&"whirl_islands_b1f": {"plan": "whirl_islands_b1f", "seed": 4281, "floor": "ground_grotte_01",
		"bands": [[".UVo", "ground_grotte_01", Color(0.76, 0.8, 0.9), "Floor"],
			["g", "ground_gravats_01", Color(0.82, 0.8, 0.82), "Rubble"]],
		"wall": Color(0.56, 0.66, 0.92), "rock": Color(0.56, 0.66, 0.92), "land": ".g",
		"water": "w<>^v",
		"flows": [[Rect2i(16, 9, 1, 1), Vector2i.LEFT], [Rect2i(16, 20, 1, 1), Vector2i.RIGHT],
			[Rect2i(5, 13, 3, 1), Vector2i.LEFT], [Rect2i(7, 15, 1, 1), Vector2i.RIGHT]]},
	&"goldenrod_underground": {"plan": "souterrain", "seed": 3421,
		"floor": "ground_dalles_souterrain_01", "mass": "ground_masse_batiment_01",
		"modules": "relief_mur_souterrain", "walls": "Xb",
		"bands": [[".Ek", "ground_dalles_souterrain_01", Color(0.74, 0.8, 0.76), "Floor"],
			["b", "ground_beton_repaire_01", Color(0.5, 0.52, 0.54), "Roof"]],
		"land": "", "water": "", "wall": Color.WHITE},
	&"whirl_islands_b2f": {"plan": "whirl_islands_b2f", "seed": 4291,
		"floor": "ground_grotte_01",
		"bands": [[".Uo", "ground_grotte_01", Color(0.74, 0.78, 0.86), "Floor"]],
		"wall": Color(0.5, 0.62, 1.0), "rock": Color(0.5, 0.6, 0.9), "land": ".",
		"water": "wdF", "deep": Color(0.01, 0.05, 0.22, 0.62),
		"falls": [Rect2i(9, 1, 4, 3), Rect2i(14, 1, 4, 3)]},
	# Ruines d'Alpha (JOHP1, demande de Kevin du 2026-11-06) : temple creusé dans la roche, d'après
	# ses vues générales. Murs en modules, roche sombre autour (« fill » : sa teinte) ; le reste de l'image
	# (dalles, escaliers, frise, socle, portes) : `tools/build_joh_ambiance_alpha.gd`, à relancer
	# après cette passe.
	&"alph_gallery": {"plan": "alph_gallery", "seed": 5171, "floor": "ground_sol_alpha_01",
		"modules": "relief_mur_alpha", "walls": "#", "fill": Color(0.62, 0.68, 0.86),
		"bands": [[".tUV", "ground_sol_alpha_01", Color(0.78, 0.76, 0.74), "Floor"],
			["g", "ground_gravats_01", Color(0.6, 0.64, 0.76), "Rubble"]],
		"land": "", "water": "", "wall": Color(1.0, 0.98, 1.0)},
	&"alph_chamber": {"plan": "alph_chamber", "seed": 5181, "floor": "ground_sol_chambre_01",
		"modules": "relief_mur_alpha", "walls": "#", "fill": Color(0.62, 0.68, 0.86),
		"bands": [[".SU", "ground_sol_chambre_01", Color(0.74, 0.72, 0.7), "Floor"]],
		"land": "", "water": "", "wall": Color(1.0, 0.98, 1.0)},
	# Arc des Pierres (JOHP2, demande de Kevin du 2026-11-05) : Grotte de la Marée, d'après ses vues
	# générales. « crates » faux : ici `R` n'est pas une caisse. « sprites » [image, pied (cases),
	# nœud] : pompes et socle, sans emprise (leurs cases sont bloquées par la grille). Au B1F, les
	# gués `a` et `b` sont peints en eau : leurs [FlagGate] montrent les gravats avec leur vanne.
	&"tide_cave_1f": {"plan": "tide_cave_1f", "seed": 7171, "floor": "ground_grotte_01",
		"bands": [[".EVR", "ground_grotte_01", Color(0.8, 0.83, 0.9), "Floor"],
			["g", "ground_gravats_01", Color(0.8, 0.84, 0.82), "Rubble"]],
		"wall": Color(0.5, 0.56, 0.76), "rock": Color(0.56, 0.62, 0.78), "land": ".g",
		"water": "d", "deep": Color(0.01, 0.13, 0.26, 0.7), "crates": false,
		"sprites": [[TIDE_PUMP, Vector2(7.0, 8.0), "Pompe1"], [TIDE_PUMP, Vector2(11.0, 8.0), "Pompe2"]]},
	&"tide_cave_b1f": {"plan": "tide_cave_b1f", "seed": 7181, "floor": "ground_grotte_01",
		"bands": [[".US", "ground_grotte_01", Color(0.8, 0.83, 0.9), "Floor"]],
		"wall": Color(0.5, 0.56, 0.76), "rock": Color(0.56, 0.62, 0.78), "land": ".",
		"water": "dab", "deep": Color(0.0, 0.2, 0.2, 0.68), "crates": false,
		"sprites": [[TIDE_SOCLE, Vector2(5.0, 12.0), "Socle"]]},
	# Arc des Pierres (JOHP3, demande de Kevin du 2026-11-06) : Antre du Dragon, d'après ses vues
	# générales. « stairs » [centre (cases), rotation] : escalier de deux cases à la place des
	# échelles `U` et `V` ; la chute d'eau de la vue du 1F n'est pas reprise (absente de la grille).
	&"dragons_den_1f": {"plan": "dragons_den_1f", "seed": 7371, "floor": "ground_grotte_01",
		"bands": [[".EVo", "ground_grotte_01", Color(0.78, 0.84, 0.96), "Floor"],
			["g", "ground_gravats_01", Color(0.74, 0.78, 0.9), "Rubble"]],
		"wall": Color(0.5, 0.6, 0.92), "rock": Color(0.56, 0.64, 0.86), "land": ".g",
		"water": "d", "deep": Color(0.0, 0.2, 0.34, 0.5), "crates": false,
		"stairs": [[Vector2(14.0, 3.0), 0.0]]},
	# Chapitre Johto, JOH6 (demande de Kevin du 2026-11-06) : Tour Cendrée (1F, B1F) et Repaire Rocket
	# d'Acajou (B1F à B3F), d'après leurs vues générales. Dessins provisoires de
	# `build_joh6_maps.gd` retirés ([constant JOH6_MARK]) ; leurs [FlagGate], dalles tournantes et
	# trous FALL gardent leur logique, seul leur dessin devient peint. Clés propres à cette passe :
	# « rocks » faux (`o` = case d'arrêt des dalles), « fixtures » faux (pas d'échelles `U` / `V`
	# du lot 2), « marks » [caractères, objet, « floor » ou « entities », préfixe, échelle], « skip »
	# (rectangles sans « marks »), « props » [objet, pied (cases), couche, nœud, échelle, teinte],
	# « beams » (poutres `P` en runs), « abyss » (gouffre `O`, trous isolés), « border » (frontière
	# du sol). Les sols : `ground_cendres_01` (Tour), `ground_beton_repaire_01` (repaire).
	&"burned_tower_1f": {"plan": "burned_tower_1f", "seed": 6171, "joh6": true,
		"floor": "ground_cendres_01", "modules": "relief_mur_tour", "walls": "#",
		"bands": [[".VE", "ground_dalles_tour_01", Color(0.7, 0.68, 0.76), "Slabs"]],
		"land": "", "water": "", "rocks": false, "wall": Color(0.66, 0.56, 0.54),
		"border": Color(0.16, 0.14, 0.17),
		"beams": {"chars": "P", "h": "prop_poutre_calcinee_h_01", "v": "prop_poutre_calcinee_v_01"},
		"abyss": {"chars": "O", "hole": "res://assets/world/props/int_trou_plancher_01.png"}},
	&"burned_tower_b1f": {"plan": "burned_tower_b1f", "seed": 6181, "joh6": true,
		"floor": "ground_cendres_01", "modules": "relief_mur_tour", "walls": "#",
		"bands": [[".U", "ground_cendres_01", Color(0.6, 0.58, 0.64), "Floor"]],
		"land": "", "water": "", "rocks": false, "wall": Color(0.6, 0.52, 0.54),
		"border": Color(0.13, 0.12, 0.16),
		"marks": [["P", "prop_colonne_calcinee_01", "entities", "Column"]]},
	&"mahogany_hideout_b1f": {"plan": "mahogany_hideout_b1f", "gate_stairs": true, "partitions": true, "seed": 6191, "joh6": true,
		"floor": "ground_beton_repaire_01", "modules": "relief_mur_repaire", "walls": "#",
		"bands": [], "land": "", "water": "", "rocks": false, "fixtures": false,
		"wall": Color.WHITE, "border": Color(0.17, 0.18, 0.21),
		"marks": [["MX", "int_caisse_repaire_01", "entities", "Crate"],
			["S", "int_statue_persian_01", "entities", "Persian"]]},
	&"mahogany_hideout_b2f": {"plan": "mahogany_hideout_b2f", "gate_stairs": true, "partitions": true, "seed": 6201, "joh6": true,
		"floor": "ground_beton_repaire_01", "modules": "relief_mur_repaire", "walls": "#",
		"bands": [], "land": "", "water": "", "rocks": false, "fixtures": false,
		"wall": Color.WHITE, "border": Color(0.17, 0.18, 0.21),
		"marks": [["MX", "int_caisse_repaire_01", "entities", "Crate"]],
		"props": [[CELL_BARS, Vector2(3.5, 20.0), "entities", "CellLeft", Vector2(1.5, 2.54)],
			[CELL_BARS, Vector2(11.5, 20.0), "entities", "CellRight", Vector2(1.5, 2.54)]]},
	&"mahogany_hideout_b3f": {"plan": "mahogany_hideout_b3f", "gate_stairs": true, "partitions": true, "seed": 6211, "joh6": true,
		"floor": "ground_beton_repaire_01", "modules": "relief_mur_repaire", "walls": "#",
		"bands": [], "land": "", "water": "", "rocks": false, "fixtures": false,
		"wall": Color.WHITE, "border": Color(0.17, 0.18, 0.21),
		"skip": [Rect2i(15, 3, 6, 4)],
		"marks": [["M", "int_caisse_repaire_01", "entities", "Crate"],
			["X", "int_console_repaire_01", "entities", "Console"],
			["p", "int_pupitre_centrale_01", "entities", "Desk"]],
		"props": [["int_generateur_ondes_01", Vector2(18.0, 7.0), "entities", "Generator"],
			["int_cage_ondes_01", Vector2(17.5, 10.99), "entities", "Cage", Vector2.ONE,
				Color(0.5, 0.5, 0.58)]]},
	&"dragons_den_sanctuary": {"plan": "dragons_den_sanctuary", "seed": 7381,
		"floor": "ground_grotte_01",
		"bands": [[".SU", "ground_grotte_01", Color(0.8, 0.86, 1.0), "Floor"]],
		"wall": Color(0.46, 0.58, 0.98), "rock": Color(0.56, 0.64, 0.86), "land": ".",
		"water": "d", "deep": Color(0.0, 0.08, 0.26, 0.72), "crates": false,
		"stairs": [[Vector2(11.0, 16.0), PI]],
		"sprites": [[DEN_ALTAR, Vector2(11.0, 5.0), "AutelPeint"]]},
	# JOH9 : grotte du Mont Argenté, d'après ses vues générales. « down » : caractère de l'échelle
	# qui descend ; « frost » : nombre de traînées de givre au pied des parois (3F, ouvert au vent).
	&"mt_silver_1f": {"plan": "mt_silver_1f", "seed": 9171, "floor": "ground_grotte_01",
		"bands": [[".UEe", "ground_grotte_01", Color(0.78, 0.82, 0.94), "Floor"],
			["g", "ground_roche_01", Color(0.92, 0.92, 0.96), "Rubble"]],
		"wall": Color(0.5, 0.6, 0.92), "rock": Color(0.58, 0.66, 0.88), "land": ".g",
		"water": "w", "crates": false},
	&"mt_silver_2f": {"plan": "mt_silver_2f", "seed": 9181, "floor": "ground_grotte_01",
		"bands": [[".UD", "ground_grotte_01", Color(0.62, 0.66, 0.8), "Floor"],
			["g", "ground_roche_01", Color(0.76, 0.78, 0.86), "Rubble"]],
		"wall": Color(0.4, 0.5, 0.86), "rock": Color(0.5, 0.58, 0.82), "land": "", "water": "",
		"crates": false, "down": "D"},
	&"mt_silver_3f": {"plan": "mt_silver_3f", "seed": 9191, "floor": "ground_grotte_01",
		"bands": [[".UD", "ground_grotte_01", Color(0.84, 0.86, 0.94), "Floor"],
			["g", "ground_roche_01", Color(1.0, 1.0, 1.04), "Rubble"]],
		"wall": Color(1.15, 1.2, 1.35), "rock": Color(0.76, 0.82, 0.96), "land": "", "water": "",
		"crates": false, "down": "D", "frost": 26},
}
## Escaliers de l'Antre : pierre refroidie, comme le sol [D].
const STAIRS_TINT := Color(0.66, 0.74, 0.92)
const CELL_BARS: String = "res://assets/world/props/int_grille_manoir_fermee_01.png"
const DEN_ALTAR: String = "res://assets/world/props/prop_autel_antre_01.png"
const TIDE_PUMP: String = "res://assets/world/props/prop_pompe_rocket_01.png"
const TIDE_SOCLE: String = "res://assets/world/props/prop_socle_maree_01.png"
const PROP_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const FLOOR: String = "ground_azuree_bas_01"
const MASS: String = "ground_masse_roche_01"
const WATER: String = "ground_eau_grotte_01"
const FAST_WATER: String = "ground_courant_01"
const PEBBLES: String = "ground_roche_01"
const BORDER := Color(0.1, 0.13, 0.2)
const WATER_MARKS: String = "wd>v"
## Souterrain : rideaux de fer ; escaliers [centre (cases), rotation] (l'image descend vers le
## haut de l'écran : tournée vers le bord de la carte).
const SHOP: String = "int_boutique_fermee_01"
const SHOP_SPAN: int = 4
const STAIRS_ID: String = "prop_escalier_souterrain_monte_01"
const STAIRS_MAP_WIDTH: int = 40
const STAIRS: Array = [[Vector2(1.5, 6.0), -PI / 2.0], [Vector2(38.5, 8.0), PI / 2.0]]
const LADDER_UP: String = "prop_echelle_monte_01"
const LADDER_DOWN: String = "prop_echelle_descend_01"
const CRATE: String = "prop_caisse_r_01"
const FROST: String = "relief_givre_%02d"
## Sens d'un courant → rotation de la texture (son flux va vers le bas de l'image).
const FLOW_ROTATIONS: Dictionary = {Vector2i.DOWN: 0.0, Vector2i.UP: PI,
	Vector2i.RIGHT: -PI / 2.0, Vector2i.LEFT: PI / 2.0}
const ROCK_MARK: String = "o"
const LAND_MARKS: String = "."
const BEACH_MARKS: String = "gE"
## Roche sombre bleutée de la vue générale : parois, rochers, galets [D].
const WALL_TINT := Color(0.74, 0.82, 1.0)
const ROCK_TINT := Color(0.56, 0.66, 0.92)
const PEBBLE_TINT := Color(0.5, 0.56, 0.7)
const ISLAND_TINT := Color(0.62, 0.7, 0.9)
## Case d'une bande : un caractère de [param marks], hors de l'eau (rochers `o` sur l'eau).
func _is_band(plan: Object, marks: String, cell: Vector2i) -> bool:
	return marks.contains(plan.at(cell)) and not _wet.has(cell)


## Masse rocheuse : modules de face empilés (rangées décalées, deux cases de haut), de plus en plus
## sombres en s'éloignant des galeries (cases jusqu'au sombre, valeur la plus sombre).
const FILL_STEP: int = 2
const FILL_DEPTH: float = 5.0
const FILL_DARK: float = 0.58
## Modules à peine décalés vers le haut (pixels) : casse les lignes des rangées.
const FILL_JITTER: float = 14.0
const FACE: String = "relief_rebord_azuree_01"
const SIDE: String = "relief_rebord_azuree_cote_01"
const ROCK: String = "prop_rocher_grotte_01"
## Teinte de l'eau (voile posé sur l'eau animée) : pixels par case, voile selon la distance à la
## rive (1, 2, 3 cases, puis au large), eau profonde.
const TINT_PX: int = 8
const SHORE_TINTS: Array[Color] = [Color(0.15, 0.85, 0.8, 0.18), Color(0.1, 0.55, 0.7, 0.3),
	Color(0.05, 0.3, 0.5, 0.4)]
const OPEN_TINT := Color(0.02, 0.12, 0.32, 0.5)
const DEEP_TINT := Color(0.008, 0.03, 0.14, 0.82)
## Courant permanent : pixels de texture par seconde (celui de [CurrentGate] : 120).
const FLOW_SPEED: float = 120.0
const FLOW_STRENGTH: float = 0.95
## Cascade de la salle 1 : colonne, rangées (haut, bas) ; elle tombe de la paroi dans le bassin.
const FALL_COLUMN: int = 13
const FALL_ROWS := Vector2i(27, 31)
const FALL_STRENGTH: float = 0.85
## Eau qui se répand sur la plage au pied du chenal (salle 2) : cases, force [D].
const SPILLS: Dictionary = {&"sea_cave_2": Rect2i(6, 35, 3, 1)}
const SPILL_STRENGTH: float = 0.55
## Puits de lumière, par carte : [cases du pied de la colonne (x, y, décimaux)].
const SHAFTS: Dictionary = {
	&"alph_gallery": [Vector2(3.5, 4.5)],
	&"sea_cave_1": [Vector2(14.0, 6.5), Vector2(21.0, 22.0), Vector2(13.5, 32.5)],
	&"sea_cave_2": [Vector2(21.0, 11.0), Vector2(12.0, 11.5), Vector2(13.0, 26.5)],
	&"slowpoke_well_b1f": [Vector2(4.0, 4.0)],
	&"slowpoke_well_b2f": [Vector2(4.0, 5.0)],
	&"whirl_islands_1f": [Vector2(10.0, 6.0), Vector2(26.0, 4.0)],
	&"whirl_islands_b1f": [Vector2(11.0, 5.0), Vector2(26.0, 7.0), Vector2(10.5, 15.0)],
	&"whirl_islands_b2f": [Vector2(10.0, 8.0), Vector2(15.0, 8.0), Vector2(12.5, 11.0)],
	&"dragons_den_1f": [Vector2(11.0, 5.0)],
	&"burned_tower_1f": [Vector2(8.5, 5.0), Vector2(17.5, 4.0)],
	&"burned_tower_b1f": [Vector2(10.0, 7.0)],
	&"dragons_den_sanctuary": [Vector2(11.0, 6.0)],
	&"mt_silver_1f": [Vector2(11.0, 13.0), Vector2(23.0, 13.0)],
	&"mt_silver_3f": [Vector2(16.0, 3.0)],
}
## Flaques de lumière seules : jour de la sortie vers Oliville (salle 2), halo chaud [D] ; jour de
## l'entrée des Îles Tourbillon.
const POOLS: Dictionary = {&"sea_cave_2": [Vector2(4.0, 39.2)],
	&"mahogany_hideout_b1f": [Vector2(5.5, 2.4), Vector2(15.5, 2.4), Vector2(24.5, 2.4),
		Vector2(11.0, 10.4), Vector2(19.5, 10.4)],
	&"mahogany_hideout_b2f": [Vector2(9.5, 4.4), Vector2(16.0, 12.4), Vector2(24.0, 9.0),
		Vector2(8.0, 14.4)],
	&"mahogany_hideout_b3f": [Vector2(3.5, 1.6), Vector2(11.0, 1.6), Vector2(17.5, 1.6),
		Vector2(22.0, 1.6)],
	&"tide_cave_1f": [Vector2(24.0, 10.0)], &"tide_cave_b1f": [Vector2(1.5, 12.0)],
	&"dragons_den_1f": [Vector2(14.0, 22.5)],
	&"mt_silver_1f": [Vector2(1.0, 23.5), Vector2(16.0, 27.0)],
	&"whirl_islands_1f": [Vector2(1.0, 13.0)],
	&"goldenrod_underground": [Vector2(2.5, 6.5), Vector2(37.5, 8.5)]}

## Bourg Palette : images sous les portes (pied de la porte : milieu de la bouche, bas de la carte).
## La bouche est enfoncée sous le bord de la carte : la caméra s'arrête au bord, l'eau reste
## devant [D].
const PAL_OPEN := "Joh1GrotteOuverte"
const PAL_CLOSED := "Joh1GrotteFermee"
const PAL_MOUTH: String = "relief_bouche_talus_01"
const PAL_MOUTH_SCALE: float = 0.8
const PAL_SINK: float = 20.0
## Rochers de part et d'autre de la bouche : [objet, décalage du pied (pixels), miroir].
const PAL_FLANKS: Array = [
	["relief_rivage_05", Vector2(-192.0, 40.0), false],
	["relief_rivage_04", Vector2(192.0, 40.0), true],
]
## Rochers fermés : [objet, décalage du pied (pixels), miroir].
const PAL_REEF: Array = [
	["relief_rivage_01", Vector2(-96.0, 36.0), false],
	["relief_rivage_02", Vector2(96.0, 36.0), true],
]

var _errors: int = 0
var _masks: int = 0
## Réglages de la carte en cours : teintes des parois et des rochers, teinte de `d`, cases d'eau.
var _wall_tint := WALL_TINT
var _rock_tint := ROCK_TINT
var _deep_tint := DEEP_TINT
var _wet: Dictionary = {}
## Côtés des rebords un peu étirés : pas de trou entre deux cases (bassins droits de l'Antre).
var _seamless_sides: bool = false


func _init() -> void:
	var wanted: Array = MAPS.keys()
	wanted.append(PALLET)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			wanted = Array(arg.trim_prefix("--maps=").split(",")).map(
				func(s: String) -> StringName: return StringName(s))
	for map_id: StringName in wanted:
		if map_id == PALLET:
			_build_pallet()
		elif MAPS.has(map_id):
			_build_cave(map_id)
		else:
			push_error("build_joh_ambiance_caves : carte inconnue %s" % map_id)
			_errors += 1
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_joh_ambiance_caves : %d carte(s) à importer (--import) puis relancer" % _masks)
		quit(2)
	else:
		quit(0)


# --- Grotte marine ------------------------------------------------------------------------


func _build_cave(map_id: StringName) -> void:
	var spec: Dictionary = MAPS[map_id]
	var plan_path := "res://tools/plans/%s.txt" % spec["plan"]
	var plan := PlanGrid.new()
	if not plan.load_file(plan_path):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var seed_value: int = spec["seed"]
	_wall_tint = spec.get("wall", WALL_TINT)
	_rock_tint = spec.get("rock", ROCK_TINT)
	_deep_tint = spec.get("deep", DEEP_TINT)
	_wet = _wet_cells(plan, spec)
	_seamless_sides = spec.has("stairs")
	var kit: Object = Kit.new(plan_path, size, seed_value, seed_value + 1, plan.walkable)
	kit.set(&"floor_texture_path", GROUND % String(spec.get("floor", FLOOR)))
	kit.set(&"mass_texture_path", GROUND % String(spec.get("mass", MASS)))
	kit.set(&"border_color", spec.get("border", BORDER))
	kit.set(&"rubble_mark", "")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", spec.get("walls", "#"))
	if not _kit_ok(kit, map_id):
		return
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", &"")
	var tint_ready: bool = _wet.is_empty() \
		or kit.call(&"_write_png", _tint_image(plan), TINT_PATH % map_id)
	var ground_ready: bool = kit.call(&"add_ground", MASK_PATH % map_id)
	if not ground_ready or not tint_ready:
		if _kit_ok(kit, map_id):
			_masks += 1
		kit.call(&"discard")
		return
	var painted: Node2D = kit_root.get_node(^"PaintedGround")
	if not _wet.is_empty():
		_water(painted, size)
	var decals: Node2D = kit.get(&"decals")
	var entities: Node2D = kit.get(&"entities")
	var bands := 0
	for band: Array in spec.get("bands", [[BEACH_MARKS, PEBBLES, PEBBLE_TINT, "Beach"],
			[LAND_MARKS, FLOOR, ISLAND_TINT, "Island"]]):
		bands += _bands(kit, decals, plan, band[0], band[1], band[2], band[3])
	bands += _partitions(kit, decals, plan, spec)
	var filled := 0
	var walls: Vector3i
	if spec.has("modules"):
		if spec.has("fill"):
			var wall_tint := _wall_tint
			_wall_tint = spec["fill"]
			_fill_mass(kit, decals, plan, seed_value + 4)
			_wall_tint = wall_tint
		walls = ModuleWalls.new(kit, spec["modules"], spec["walls"], spec["walls"],
			seed_value + 2).place()
		filled = _shop_fronts(kit, entities, plan)
	else:
		filled = _fill_mass(kit, decals, plan, seed_value + 4)
		walls = kit.call(&"place_walls", seed_value + 2)
	_tint_walls(entities)
	_tint_walls(decals)
	var edges := _island_edges(kit, decals, plan, spec.get("land", LAND_MARKS))
	var rocks := _rocks(kit, entities, plan, seed_value + 3) if spec.get("rocks", true) else 0
	rocks += _fixtures(kit, entities, decals, plan, spec)
	if not spec.get("joh6", false):
		_flows(kit, decals, entities, plan, map_id)
	_lot2_flows(kit, decals, entities, spec)
	_lights(kit, map_id)
	if not _kit_ok(kit, map_id):
		kit.call(&"discard")
		return
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean_cave(root)
	_clear_placeholders(root, spec.get("joh6", false))
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	_adopt(painted, root, root, kit_root)
	root.move_child(painted, index)
	index += 1
	if not _wet.is_empty():
		var tint := Sprite2D.new()
		tint.name = "JohAmbCaveTint"
		tint.texture = load(TINT_PATH % map_id)
		tint.centered = false
		tint.scale = Vector2.ONE * (float(TILE) / TINT_PX)
		tint.z_index = -2
		root.add_child(tint)
		tint.owner = root
		root.move_child(tint, index)
		index += 1
	_adopt(decals, root, root, kit_root)
	decals.name = "JohAmbCaveSol"
	root.move_child(decals, index)
	var glows: Node2D = kit.get(&"glows")
	_adopt(glows, root, root, kit_root)
	glows.name = "JohAmbCaveGlows"
	root.move_child(glows, root.get_node(^"Entities").get_index() + 1)
	var map_entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		child.name = OWN_PREFIX + String(child.name)
		_adopt(child, map_entities, root, kit_root)
	kit.call(&"discard")
	if spec.get("joh6", false):
		_paint_gates(root, spec)
	var err := _save(root, path)
	print("%s : %s (parois %s, masse %d, bandes %d, rebords %d, rochers %d, halos %d)" % [map_id,
		error_string(err), walls, filled, bands, edges, rocks, glows.get_child_count()])
	root.free()


func _kit_ok(kit: Object, map_id: StringName) -> bool:
	var errors: PackedStringArray = kit.get(&"errors")
	if errors.is_empty():
		return true
	push_error("%s :\n%s" % [map_id, "\n".join(errors)])
	_errors += 1
	return false


## Cases d'eau : les caractères de la carte, et les rochers `o` (grotte marine : tous ; lot 2 :
## ceux qui ont de l'eau sur au moins deux côtés, les autres sont sur la terre ferme).
func _wet_cells(plan: Object, spec: Dictionary) -> Dictionary:
	var marks: String = spec.get("water", WATER_MARKS)
	var wet: Dictionary = {}
	if marks.is_empty():
		return wet
	for cell: Vector2i in plan.cells_of(marks):
		wet[cell] = true
	for cell: Vector2i in plan.cells_of(ROCK_MARK):
		var sides := 0
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if marks.contains(plan.at(cell + side)) and not plan.at(cell + side).is_empty():
				sides += 1
		if sides >= 2 or not spec.has("water"):
			wet[cell] = true
	return wet


## Eau animée du sol peint sur l'eau et sous les rochers, à angles droits, sans écume.
func _water(painted: Node2D, size: Vector2i) -> void:
	var cells: Array[Vector2i] = []
	cells.assign(_wet.keys())
	var mask := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = mask.call(&"build_water", size, cells)
	painted.set(&"shore_mask", ImageTexture.create_from_image(image))
	painted.set(&"square_shore", true)
	painted.set(&"water_texture", load(GROUND % WATER))
	painted.set(&"foam_strength", 0.0)


## Voile de l'eau : clair le long des rives, bleu nuit au large, presque noir sur l'eau profonde ;
## rien hors de l'eau (frontière franche, les parois la recouvrent).
func _tint_image(plan: Object) -> Image:
	var small := Image.create(plan.width, plan.height, false, Image.FORMAT_RGBA8)
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var color := Color(SHORE_TINTS[0], 0.0)
			if plan.at(cell) == "d":
				color = _deep_tint
			elif _is_wet(plan, cell):
				var shore := _shore_distance(plan, cell)
				color = SHORE_TINTS[shore - 1] if shore <= SHORE_TINTS.size() else OPEN_TINT
			small.set_pixelv(cell, color)
	small.resize(plan.width * TINT_PX, plan.height * TINT_PX, Image.INTERPOLATE_BILINEAR)
	for y: int in small.get_height():
		for x: int in small.get_width():
			if not _is_wet(plan, Vector2i(x / TINT_PX, y / TINT_PX)):
				small.set_pixel(x, y, Color(SHORE_TINTS[0], 0.0))
	return small


func _is_wet(_plan: Object, cell: Vector2i) -> bool:
	return _wet.has(cell)


## Distance (cases, 8-voisinage) de [param cell] à la plus proche case sèche, bornée au-delà de
## [constant SHORE_TINTS].
func _shore_distance(plan: Object, cell: Vector2i) -> int:
	for radius: int in range(1, SHORE_TINTS.size() + 1):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if not _is_wet(plan, cell + Vector2i(dx, dy)):
					return radius
	return SHORE_TINTS.size() + 1


## Bandes horizontales de la texture [param ground] sur les cases [param marks], coordonnées du
## monde (aucun raccord visible), sous les lèvres de paroi. Renvoie leur nombre.
func _bands(kit: Object, decals: Node2D, plan: Object, marks: String, ground: String,
		tint: Color, prefix: String) -> int:
	var texture: Texture2D = load(GROUND % ground)
	var count := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if not _is_band(plan, marks, Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < plan.width and _is_band(plan, marks, Vector2i(x, y)):
				x += 1
			var sprite := Sprite2D.new()
			sprite.name = "%s%02d" % [prefix, count]
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE)
			sprite.position = Vector2(start * TILE, y * TILE)
			sprite.modulate = tint
			kit.call(&"attach", decals, sprite)
			count += 1
	return count


## Masse rocheuse : modules de face empilés sur toute la masse, du nord au sud (chaque rangée
## recouvre le haut de la précédente), rangées décalées d'une case et demie ; ils s'assombrissent
## loin des galeries. Sous les parois de la grille (posées ensuite). Renvoie leur nombre.
func _fill_mass(kit: Object, decals: Node2D, plan: Object, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var faces: Array[String] = kit.get(&"wall_faces")
	var count := 0
	var row := 0
	for y: int in range(1, plan.height, FILL_STEP):
		var both := func(cell: Vector2i) -> bool:
			return plan.at(cell) == "#" and plan.at(cell + Vector2i.UP) == "#"
		for run: Vector2i in kit.call(&"_row_runs", y, both):
			var pieces: Array[Vector2i] = []
			var left := run.x
			if row % 2 == 1 and run.y > run.x:
				pieces.append(Vector2i(left, 1))
				left += 1
			pieces.append_array(kit.call(&"_pieces", Vector2i(left, run.y)))
			for piece: Vector2i in pieces:
				var id: String = faces[rng.randi_range(0, faces.size() - 1)]
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE,
					(y + 1) * TILE - rng.randf_range(0.0, FILL_JITTER))
				var sprite: Sprite2D = kit.call(&"_wall_module", decals, id, foot, piece.y * TILE,
					-1, false, "Fill%03d" % count, rng)
				sprite.flip_h = rng.randf() < 0.5
				var depth := _mass_depth(plan, Vector2i(piece.x + piece.y / 2, y))
				var value := lerpf(1.0, FILL_DARK, clampf(depth / FILL_DEPTH, 0.0, 1.0))
				sprite.modulate *= _wall_tint * Color(value, value, value)
				count += 1
		row += 1
	return count


## Distance (cases) de [param cell] à la plus proche case qui n'est pas de la masse, bornée.
func _mass_depth(plan: Object, cell: Vector2i) -> float:
	var limit := int(FILL_DEPTH)
	for radius: int in range(1, limit + 1):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var near := cell + Vector2i(dx, dy)
				if plan.at(near) != "#" and plan.at(near) != "T":
					return float(radius)
	return FILL_DEPTH


func _tint_walls(parent: Node) -> void:
	for child: Node in parent.get_children():
		var label := String(child.name)
		if label.begins_with("Face") or label.begins_with("Side") or label.begins_with("Lip"):
			var sprite := child as Sprite2D
			sprite.modulate *= _wall_tint


## Rebords des îlots : face sous la case du bord sud (posée sur l'eau, le joueur garde toute
## l'île), bords latéraux à l'est et à l'ouest. Renvoie le nombre d'objets.
func _island_edges(kit: Object, decals: Node2D, plan: Object, land: String) -> int:
	var count := 0
	if land.is_empty():
		return count
	for cell: Vector2i in plan.cells_of(land):
		if _is_wet(plan, cell + Vector2i.DOWN):
			var face: Node2D = kit.call(&"add_prop", decals, FACE,
				Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE + _height(kit, FACE)),
				"Ledge%03d" % count)
			face.set(&"footprint", [] as Array[Vector2i])
			face.modulate = ISLAND_TINT
			count += 1
		for dx: int in [-1, 1]:
			if _is_wet(plan, cell + Vector2i(dx, 0)):
				var side: Node2D = kit.call(&"add_floor_prop", SIDE, cell, "Side%03d" % count)
				side.position.x += dx * (TILE / 2.0 - 12.0)
				if _seamless_sides:
					side.scale.y = 1.2
				side.modulate = ISLAND_TINT
				count += 1
	return count


func _height(kit: Object, id: String) -> float:
	return (kit.call(&"_texture_of", id) as Texture2D).get_height()


## Rochers `o` : un par case, sur leurs cases déjà bloquées (sprites seuls, sans emprise).
func _rocks(kit: Object, entities: Node2D, plan: Object, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := 0
	for cell: Vector2i in plan.cells_of(ROCK_MARK):
		var foot := Vector2((cell.x + 0.5) * TILE + rng.randf_range(-8.0, 8.0),
			(cell.y + 1) * TILE - rng.randf_range(0.0, 8.0))
		var rock: Sprite2D = kit.call(&"add_sprite", entities, ROCK, foot, "Rock%02d" % count)
		var s := rng.randf_range(1.25, 1.5)
		rock.scale = Vector2(s, s)
		rock.flip_h = rng.randf() < 0.5
		var value := rng.randf_range(0.92, 1.04)
		rock.modulate = _rock_tint * Color(value, value, value)
		count += 1
	return count


## Rideaux de fer (Souterrain) sur les étendues de boutiques `b` ouvertes au sud, en modules de
## quatre cases, le dernier coupé. Renvoie leur nombre.
func _shop_fronts(kit: Object, entities: Node2D, plan: Object) -> int:
	var count := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			var cell := Vector2i(x, y)
			if plan.at(cell) != "b" or not plan.is_walkable(cell + Vector2i.DOWN):
				x += 1
				continue
			var start := x
			while plan.at(Vector2i(x, y)) == "b" and plan.is_walkable(Vector2i(x, y + 1)):
				x += 1
			var left := start
			while left < x:
				var span := mini(SHOP_SPAN, x - left)
				var foot := Vector2((left + span / 2.0) * TILE, (y + 1) * TILE)
				var shop: Sprite2D = kit.call(&"add_sprite", entities, SHOP, foot,
					"Shop%02d" % count)
				if span < SHOP_SPAN:
					var size := shop.texture.get_size()
					shop.region_enabled = true
					shop.region_rect = Rect2(0.0, 0.0, span * TILE, size.y)
				left += span
				count += 1
	return count


## Échelles `U` (qui montent, debout) et `V` (trappe, au sol), caisses `R` et `k`, escaliers `E` du
## Souterrain (par paire, tournés vers le bord) : images seules sur leurs cases. Renvoie leur nombre.
func _fixtures(kit: Object, entities: Node2D, decals: Node2D, plan: Object,
		spec: Dictionary) -> int:
	var count := 0
	for entry: Array in spec.get("sprites", []):
		var sprite := Sprite2D.new()
		sprite.name = entry[2]
		sprite.texture = load(entry[0])
		sprite.material = load(PROP_MATERIAL)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var size := sprite.texture.get_size()
		sprite.centered = false
		sprite.offset = Vector2(-size.x / 2.0, -size.y)
		sprite.position = (entry[1] as Vector2) * TILE
		kit.call(&"attach", entities, sprite)
		count += 1
	count += _marks(kit, entities, decals, plan, spec)
	count += _props(kit, entities, decals, spec)
	count += _beams(kit, entities, plan, spec)
	count += _abyss(kit, decals, plan, spec)
	if not spec.get("fixtures", true):
		return count
	if plan.width == STAIRS_MAP_WIDTH:
		for cell: Vector2i in plan.cells_of("k"):
			kit.call(&"add_sprite", entities, "prop_caisses_01",
				(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Crate%02d" % count)
			count += 1
		for entry: Array in STAIRS:
			var stairs: Sprite2D = kit.call(&"add_sprite", decals, STAIRS_ID,
				(entry[0] as Vector2) * TILE, "Stairs%02d" % count)
			stairs.position = (entry[0] as Vector2) * TILE
			stairs.rotation = entry[1]
			count += 1
	for entry: Array in spec.get("stairs", []):
		var flight: Sprite2D = kit.call(&"add_sprite", decals, STAIRS_ID,
			(entry[0] as Vector2) * TILE, "Stairs%02d" % count)
		flight.position = (entry[0] as Vector2) * TILE
		flight.rotation = entry[1]
		flight.modulate = STAIRS_TINT
		count += 1
	if spec.has("stairs"):
		return count
	for cell: Vector2i in plan.cells_of("U"):
		kit.call(&"add_sprite", entities, LADDER_UP,
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Ladder%02d" % count)
		count += 1
	for cell: Vector2i in plan.cells_of(spec.get("down", "V")):
		kit.call(&"add_sprite", decals, LADDER_DOWN,
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Ladder%02d" % count)
		count += 1
	count += _frost(kit, decals, plan, spec)
	if spec.get("crates", true):
		for cell: Vector2i in plan.cells_of("R"):
			kit.call(&"add_sprite", entities, CRATE, (Vector2(cell) + Vector2(0.5, 1.0)) * TILE,
				"Crate%02d" % count)
			count += 1
	return count


## Traînées de givre au pied des parois (clé « frost » : leur nombre), couche du sol. Renvoie leur
## nombre.
func _frost(kit: Object, decals: Node2D, plan: Object, spec: Dictionary) -> int:
	var wanted: int = spec.get("frost", 0)
	if wanted == 0:
		return 0
	var edge: Array[Vector2i] = []
	for cell: Vector2i in plan.cells_of(".") + plan.cells_of("g"):
		if plan.at(cell + Vector2i.UP) == "#" or plan.at(cell + Vector2i.DOWN) == "#":
			edge.append(cell)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec["seed"]) + 9
	for index: int in wanted:
		var cell: Vector2i = edge[rng.randi_range(0, edge.size() - 1)]
		var drift: Sprite2D = kit.call(&"add_sprite", decals, FROST % rng.randi_range(1, 4),
			(Vector2(cell) + Vector2(0.5, 0.5)) * TILE, "Frost%02d" % index)
		drift.position = (Vector2(cell) + Vector2(0.5, rng.randf_range(0.2, 0.8))) * TILE
		drift.flip_h = rng.randf() < 0.5
	return wanted


## JOH6 : un objet peint (image seule, sans emprise) sur chaque case des caractères de la clé
## « marks », hors des rectangles « skip » (voir [constant MAPS]). Renvoie leur nombre.
func _marks(kit: Object, entities: Node2D, decals: Node2D, plan: Object, spec: Dictionary) -> int:
	var rules: GDScript = kit.get(&"rules")
	var skips: Array = spec.get("skip", [])
	var count := 0
	for entry: Array in spec.get("marks", []):
		var parent: Node2D = decals if entry[2] == "floor" else entities
		for cell: Vector2i in plan.cells_of(entry[0]):
			var skipped := false
			for rect: Rect2i in skips:
				skipped = skipped or rect.has_point(cell)
			if skipped:
				continue
			var foot: Vector2 = rules.call(&"foot_position", StringName(entry[1]), cell)
			var sprite: Sprite2D = kit.call(&"add_sprite", parent, entry[1], foot,
				"%s%03d" % [entry[3], count])
			if entry.size() > 4:
				sprite.scale = entry[4]
			count += 1
	return count


## JOH6 : grands objets au pied donné en cases (clé « props » : objet peint ou image `res://`).
func _props(kit: Object, entities: Node2D, decals: Node2D, spec: Dictionary) -> int:
	var count := 0
	for entry: Array in spec.get("props", []):
		var parent: Node2D = decals if entry[2] == "floor" else entities
		var foot: Vector2 = (entry[1] as Vector2) * TILE
		var sprite: Sprite2D
		if String(entry[0]).begins_with("res://"):
			sprite = _png_sprite(entry[0], foot, entry[3])
			kit.call(&"attach", parent, sprite)
		else:
			sprite = kit.call(&"add_sprite", parent, entry[0], foot, entry[3])
		if entry.size() > 4:
			sprite.scale = entry[4]
		if entry.size() > 5:
			sprite.modulate = entry[5]
		count += 1
	return count


## Image seule (nœud `Sprite2D`) dont le pied est en [param foot] (pixels).
func _png_sprite(path: String, foot: Vector2, node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path)
	sprite.material = load(PROP_MATERIAL)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var size := sprite.texture.get_size()
	sprite.centered = false
	sprite.offset = Vector2(-size.x / 2.0, -size.y)
	sprite.position = foot.round()
	return sprite


## JOH6 : poutres calcinées `P` de la Tour (clé « beams »). Une étendue horizontale de trois cases ou
## plus reçoit la poutre couchée (étirée à sa longueur), les autres cases la poutre debout, couchée
## sur la carte (étirée à la hauteur de son étendue verticale). Renvoie leur nombre.
func _beams(kit: Object, entities: Node2D, plan: Object, spec: Dictionary) -> int:
	var cfg: Dictionary = spec.get("beams", {})
	if cfg.is_empty():
		return 0
	var marks: String = cfg["chars"]
	var used: Dictionary = {}
	var count := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if not marks.contains(plan.at(Vector2i(x, y))):
				x += 1
				continue
			var start := x
			while x < plan.width and marks.contains(plan.at(Vector2i(x, y))):
				x += 1
			if x - start < 3:
				continue
			for ux: int in range(start, x):
				used[Vector2i(ux, y)] = true
			var length := x - start
			var beam: Sprite2D = kit.call(&"add_sprite", entities, cfg["h"],
				Vector2((start + length / 2.0) * TILE, (y + 1) * TILE - 6.0),
				"Beam%02d" % count)
			beam.scale = Vector2(length / 5.0, 1.0)
			count += 1
	for x: int in plan.width:
		var y := 0
		while y < plan.height:
			var cell := Vector2i(x, y)
			if not marks.contains(plan.at(cell)) or used.has(cell):
				y += 1
				continue
			var start := y
			while y < plan.height and marks.contains(plan.at(Vector2i(x, y))) \
					and not used.has(Vector2i(x, y)):
				y += 1
			var length := y - start
			var beam: Sprite2D = kit.call(&"add_sprite", entities, cfg["v"],
				Vector2((x + 0.5) * TILE, y * TILE - 4.0), "Beam%02d" % count)
			beam.scale = Vector2(1.0, length * float(TILE) / 770.0)
			count += 1
	return count


## JOH6 : gouffre (clé « abyss ») sur les cases `O` de la Tour : un ensemble de plusieurs cases est
## un puits sombre avec sa lèvre, une case isolée un trou de plancher ([constant PROPS] « hole »).
func _abyss(kit: Object, decals: Node2D, plan: Object, spec: Dictionary) -> int:
	var cfg: Dictionary = spec.get("abyss", {})
	if cfg.is_empty():
		return 0
	var seen: Dictionary = {}
	var count := 0
	for first: Vector2i in plan.cells_of(cfg["chars"]):
		if seen.has(first):
			continue
		var cells: Array[Vector2i] = []
		var stack: Array[Vector2i] = [first]
		seen[first] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			cells.append(cell)
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = cell + side
				if not seen.has(next) and String(cfg["chars"]).contains(plan.at(next)) \
						and not plan.at(next).is_empty():
					seen[next] = true
					stack.append(next)
		if cells.size() == 1:
			var hole := _png_sprite(cfg["hole"], Vector2((first.x + 0.5) * TILE,
				(first.y + 0.5) * TILE + 45.0), "Hole%02d" % count)
			hole.material = null
			kit.call(&"attach", decals, hole)
		else:
			var rect := Rect2i(cells[0], Vector2i.ONE)
			for cell: Vector2i in cells:
				rect = rect.merge(Rect2i(cell, Vector2i.ONE))
			_pit(kit, decals, rect, count)
		count += 1
	return count


## Puits sombre sur [param rect] (cases) : dégradé du bord éclairé vers le noir, lèvre en bois.
func _pit(kit: Object, decals: Node2D, rect: Rect2i, index: int) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([Color(0.22, 0.2, 0.24), Color(0.03, 0.03, 0.05),
		Color(0.0, 0.0, 0.01)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 8
	texture.height = 64
	var pit := Sprite2D.new()
	pit.name = "Pit%02d" % index
	pit.texture = texture
	pit.centered = false
	pit.position = Vector2(rect.position * TILE)
	pit.scale = Vector2(rect.size.x * TILE / 8.0, rect.size.y * TILE / 64.0)
	kit.call(&"attach", decals, pit)
	var lip_gradient := Gradient.new()
	lip_gradient.colors = PackedColorArray([Color(0.36, 0.28, 0.24), Color(0.2, 0.16, 0.15)])
	var lip_texture := GradientTexture2D.new()
	lip_texture.gradient = lip_gradient
	lip_texture.fill_from = Vector2(0.0, 0.0)
	lip_texture.fill_to = Vector2(0.0, 1.0)
	lip_texture.width = 8
	lip_texture.height = 8
	var lip := Sprite2D.new()
	lip.name = "PitLip%02d" % index
	lip.texture = lip_texture
	lip.centered = false
	lip.position = Vector2(rect.position * TILE) + Vector2(0.0, -8.0)
	lip.scale = Vector2(rect.size.x * TILE / 8.0, 16.0 / 8.0)
	kit.call(&"attach", decals, lip)


## JOH6 : dessus des cloisons d'une case (`#` avec du sol à l'ouest et à l'est) : une bande du sol
## entre les deux bords latéraux des modules (clé « partitions »), sinon la masse sombre y fait une
## rainure. Renvoie leur nombre.
func _partitions(kit: Object, decals: Node2D, plan: Object, spec: Dictionary) -> int:
	if not spec.get("partitions", false):
		return 0
	var texture: Texture2D = load(GROUND % String(spec["floor"]))
	var count := 0
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if x == 0 or x == plan.width - 1 or plan.at(cell) != "#" \
					or not plan.is_walkable(cell + Vector2i.LEFT) \
					or not plan.is_walkable(cell + Vector2i.RIGHT):
				continue
			var sprite := Sprite2D.new()
			sprite.name = "Partition%03d" % count
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(x * TILE + 30, y * TILE, TILE - 60, TILE)
			sprite.position = Vector2(x * TILE + 30, y * TILE)
			sprite.modulate = Color(0.62, 0.64, 0.7)
			kit.call(&"attach", decals, sprite)
			count += 1
	return count


## Eau vive de la salle 1 : courant `>` et cascade (image seule).
func _flows(kit: Object, decals: Node2D, entities: Node2D, plan: Object,
		map_id: StringName) -> void:
	var cells: Array[Vector2i] = plan.cells_of(">")
	if not cells.is_empty():
		var rect := Rect2(Vector2(cells[0]), Vector2.ONE)
		for cell: Vector2i in cells:
			rect = rect.merge(Rect2(Vector2(cell), Vector2.ONE))
		var length := rect.size.x * TILE
		var across := rect.size.y * TILE
		var sprite := _flow_sprite(Vector2(across, length), Vector4(0.08, 0.08, 0.0, 0.14),
			FLOW_STRENGTH, "Current")
		# Le flux de la texture va vers le bas de l'image : tournée vers l'est.
		sprite.rotation = -PI / 2.0
		sprite.position = (rect.position + rect.size / 2.0) * TILE
		kit.call(&"attach", decals, sprite)
	if SPILLS.has(map_id):
		var spill: Rect2i = SPILLS[map_id]
		var foam := _flow_sprite(Vector2(spill.size * TILE), Vector4(0.1, 0.1, 0.0, 0.85),
			SPILL_STRENGTH, "Spill")
		foam.centered = false
		foam.position = Vector2(spill.position * TILE)
		kit.call(&"attach", decals, foam)
	if map_id == &"sea_cave_1":
		var height := (FALL_ROWS.y - FALL_ROWS.x) * TILE
		var fall := _flow_sprite(Vector2(TILE * 1.5, height), Vector4(0.3, 0.3, 0.28, 0.12),
			FALL_STRENGTH, "Fall")
		fall.centered = false
		fall.offset = Vector2(-TILE * 0.75, -height)
		fall.position = Vector2((FALL_COLUMN + 0.5) * TILE, FALL_ROWS.y * TILE)
		kit.call(&"attach", entities, fall)


## Lot 2 : courants (image seule, dans le sens de la grille) et cascades.
func _lot2_flows(kit: Object, decals: Node2D, entities: Node2D, spec: Dictionary) -> void:
	var index := 0
	for entry: Array in spec.get("flows", []):
		var rect: Rect2i = entry[0]
		var sense: Vector2i = entry[1]
		var along := float((rect.size.x if sense.x != 0 else rect.size.y) * TILE)
		var across := float((rect.size.y if sense.x != 0 else rect.size.x) * TILE)
		var flow := _flow_sprite(Vector2(across, along), Vector4(0.08, 0.08, 0.12, 0.12),
			FLOW_STRENGTH, "Flow%d" % index)
		flow.rotation = FLOW_ROTATIONS[sense]
		flow.position = (Vector2(rect.position) + Vector2(rect.size) / 2.0) * TILE
		kit.call(&"attach", decals, flow)
		index += 1
	for rect: Rect2i in spec.get("falls", []):
		var size := Vector2(rect.size * TILE)
		var fall := _flow_sprite(size, Vector4(0.04, 0.04, 0.02, 0.1), FALL_STRENGTH,
			"Fall%d" % index)
		fall.centered = false
		fall.offset = Vector2(0.0, -size.y)
		fall.position = Vector2(rect.position.x * TILE, rect.end.y * TILE)
		kit.call(&"attach", entities, fall)
		index += 1


## Sprite d'eau vive : région [param size] (pixels) d'une texture répétée, shader de défilement.
func _flow_sprite(size: Vector2, fade: Vector4, strength: float, node_name: String) -> Sprite2D:
	var texture: Texture2D = load(GROUND % FAST_WATER)
	var side := float(texture.get_width())
	var material := ShaderMaterial.new()
	material.shader = load(FLOW_SHADER)
	material.set_shader_parameter(&"flow", Vector2(0.0, -FLOW_SPEED / side))
	material.set_shader_parameter(&"extent", size / side)
	material.set_shader_parameter(&"fade", fade)
	material.set_shader_parameter(&"strength", strength)
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.material = material
	return sprite


## Puits de lumière : flaque au sol et colonne, en [constant SHAFTS] ; flaques seules en
## [constant POOLS].
func _lights(kit: Object, map_id: StringName) -> void:
	var index := 0
	for at: Vector2 in SHAFTS.get(map_id, []):
		var foot := at * TILE
		kit.call(&"add_glow", &"shaft", foot + Vector2(0.0, -0.4 * TILE), "Shaft%d" % index)
		kit.call(&"add_glow", &"beam", foot, "Beam%d" % index)
		index += 1
	for at: Vector2 in POOLS.get(map_id, []):
		kit.call(&"add_glow", &"projector", at * TILE, "Pool%d" % index)
		index += 1


## Dessins provisoires de `build_joh7_maps.gd` : halo de `Decor`, échelles en aplats (le nœud
## `Echelle*`, qui n'a pas de fonction, reste).
func _clear_placeholders(root: Node, joh6: bool = false) -> void:
	if joh6:
		_clear_polygons(root.get_node(^"Decor"), root)
		_clear_polygons(root.get_node(^"Entities"), root)
		return
	var parents: Array[Node] = []
	var decor := root.get_node_or_null(^"Decor")
	if decor != null:
		parents.append(decor)
	for child: Node in root.get_node(^"Entities").get_children():
		if String(child.name).begins_with("Echelle"):
			parents.append(child)
	if decor != null:
		for child: Node in decor.get_children():
			if String(child.name).begins_with("Echelle"):
				parents.append(child)
	for parent: Node in parents:
		for child: Node in parent.get_children():
			if child is Polygon2D:
				parent.remove_child(child)
				child.free()


## JOH6 : retire les aplats `Polygon2D` de `build_joh6_maps.gd` sous [param node] (ceux de la scène
## de la carte seulement, pas ceux d'une instance) ; les nœuds qui les portaient, [FlagGate]
## compris, restent avec leur logique.
func _clear_polygons(node: Node, root: Node) -> void:
	for child: Node in node.get_children():
		_clear_polygons(child, root)
		if child is Polygon2D and child.owner == root:
			node.remove_child(child)
			child.free()


## Retire ce que cette passe a posé (relance).
func _clean_cave(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	_clean_prefixed(root.get_node(^"Entities"))
	var decor := root.get_node_or_null(^"Decor")
	if decor != null:
		_clean_prefixed(decor)


## Retire, sous [param node] et ses descendants, les nœuds de cette passe (images des [FlagGate]).
func _clean_prefixed(node: Node) -> void:
	for child: Node in node.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			node.remove_child(child)
			child.free()
		else:
			_clean_prefixed(child)


# --- JOH6 : dessins des portes à drapeau -----------------------------------------------------

const STAIRS_ART: Dictionary = {"U": "int_escalier_repaire_monte_01",
	"D": "int_escalier_repaire_descend_01"}
const DOOR_ART: String = "int_porte_ascenseur_repaire_01"
const CAGE_ART: String = "int_cage_ondes_01"
const LEVER_ART: String = "int_console_repaire_01"


## Remplace par de l'art peint le dessin des nœuds de `build_joh6_maps.gd` (leur logique ne change
## pas : drapeaux, cases occupées, interactions) : escaliers du repaire (`Escalier*`, le `U` ou le
## `D` de la grille), porte à mot de passe, grille de la cellule, barreaux de la cage (vifs tant que
## le générateur tourne : l'image de base de la cage est sombre) et son halo, levier.
func _paint_gates(root: Node2D, spec: Dictionary) -> void:
	var plan := PlanGrid.new()
	plan.load_file("res://tools/plans/%s.txt" % spec["plan"])
	var rules := load("res://game/world/props/painted_prop_rules.gd") as GDScript
	for parent_name: String in ["Decor", "Entities"]:
		for gate: Node in root.get_node(NodePath(parent_name)).get_children():
			if not gate is Node2D:
				continue
			var label := String(gate.name)
			var node := gate as Node2D
			var cell := Vector2i(int(node.position.x / TILE), int(node.position.y / TILE) - 1)
			if label.begins_with("Escalier") and spec.get("gate_stairs", false):
				var id: String = STAIRS_ART.get(plan.at(cell), "")
				if not id.is_empty():
					var foot: Vector2 = rules.call(&"foot_position", StringName(id), cell)
					_gate_sprite(root, node, id, foot - node.position, false, "Stairs")
			elif label == "PortePorteMdp":
				var door := _gate_sprite(root, node, DOOR_ART, Vector2.ZERO, false, "Door")
				door.scale = Vector2(0.52, 0.8)
			elif label == "PortePorteCellule":
				var bars := _png_sprite(CELL_BARS, Vector2.ZERO, OWN_PREFIX + "Bars")
				bars.scale = Vector2(0.5, 0.75)
				node.add_child(bars)
				bars.owner = root
			elif label == "CageAOndes":
				_gate_sprite(root, node, CAGE_ART, Vector2.ZERO, false, "CageOn")
			elif label == "CageHalo":
				_halo(root, node, Vector2(TILE, -1.5 * TILE), 336.0, Color(0.55, 0.4, 1.0, 0.4))
			elif label.begins_with("DessinLevier"):
				var lever := _gate_sprite(root, node, LEVER_ART, Vector2.ZERO, false, "Lever")
				lever.scale = Vector2(0.8, 0.8)


## Halo radial additif de [param size] pixels de diamètre, centré en [param at] (repère de
## [param parent]).
func _halo(root: Node, parent: Node2D, at: Vector2, size: float, color: Color) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	var halo := Sprite2D.new()
	halo.name = OWN_PREFIX + "Halo"
	halo.texture = texture
	halo.position = at
	halo.scale = Vector2.ONE * (size / 128.0)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = material
	parent.add_child(halo)
	halo.owner = root


# --- Bourg Palette ------------------------------------------------------------------------


func _build_pallet() -> void:
	var path := MAPS_DIR + "%s.tscn" % PALLET
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var entities := root.get_node(^"Entities")
	var open := entities.get_node_or_null(NodePath(PAL_OPEN))
	var closed := entities.get_node_or_null(NodePath(PAL_CLOSED))
	if open == null or closed == null:
		push_error("pallet_town : portes de la bouche absentes (build_joh1_pallet_cave.gd)")
		_errors += 1
		root.free()
		return
	var removed := _clear_gate(open) + _clear_gate(closed)
	var mouth := _gate_sprite(root, open, PAL_MOUTH, Vector2(0.0, PAL_SINK), false, "Mouth")
	mouth.scale = Vector2.ONE * PAL_MOUTH_SCALE
	var index := 0
	for spec: Array in PAL_FLANKS:
		_gate_sprite(root, open, spec[0], spec[1], spec[2], "Flank%d" % index)
		index += 1
	index = 0
	for spec: Array in PAL_REEF:
		_gate_sprite(root, closed, spec[0], spec[1], spec[2], "Reef%d" % index)
		index += 1
	var err := _save(root, path)
	print("pallet_town : %s (%d aplats retirés)" % [error_string(err), removed])
	root.free()


## Vide les dessins d'une porte : aplats `Polygon2D` et images d'une passe précédente. Renvoie le
## nombre d'aplats retirés.
func _clear_gate(gate: Node) -> int:
	var removed := 0
	for child: Node in gate.get_children():
		if child is Polygon2D:
			removed += 1
		elif not String(child.name).begins_with(OWN_PREFIX):
			continue
		gate.remove_child(child)
		child.free()
	return removed


## Image de l'objet peint [param id] sous la porte, pied en [param foot] (repère de la porte).
func _gate_sprite(root: Node, gate: Node, id: String, foot: Vector2, flip: bool,
		node_name: String) -> Sprite2D:
	var model := (load(PROPS % id) as PackedScene).instantiate()
	var sprite := (model.get_node(^"Sprite") as Sprite2D).duplicate() as Sprite2D
	model.free()
	sprite.name = OWN_PREFIX + node_name
	sprite.unique_name_in_owner = false
	sprite.position = (foot + sprite.position).round()
	sprite.flip_h = flip
	gate.add_child(sprite)
	sprite.owner = root
	return sprite


# --- Communs ------------------------------------------------------------------------------


func _save(root: Node, path: String) -> int:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		_errors += 1
	return err


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir
## `build_daf4_caves.gd`).
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
