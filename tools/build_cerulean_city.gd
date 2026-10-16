extends SceneTree
## Construit game/world/maps/cerulean_city.tscn (Azuria, 56 × 41 cases) d'après la grille
## fonctionnelle `tools/plans/azuria.txt` (jalon 13 T7, docs/tech/jalon-13.md §2.1, §2.3, §2.5 ;
## dossier 16 §4–§6, §9). **Sans PNJ, sans interaction, sans déclencheur** (T17) : les cases des
## habitants, des examens et des déclencheurs sont réservées (la forêt s'en écarte, la grille les
## laisse libres ou bloquées comme le plan).
##
## **Jalon 14 (T20b, 14C)** : la grille lue est la variante `J14` de `tools/plans/azuria.txt`
## (jardin de la maison cambriolée et impasse praticables, trou praticable, porte cambriolée
## ouverte au warp, couloir sud jusqu'au raccord de la Route 5 — « À venir » au J14, la vraie
## Route 5 depuis le J15 T21). Caractères `J` (jardin
## ouvert) et `Y` (trou) praticables ; l'arbre dense en (22, 3) ferme l'impasse ; la planche
## clouée (14, 2) et la porte condamnée de la maison suivent `cerulean_rocket_beaten`
## ([FlagGate]) ; les déclencheurs de la poursuite, du combat et du barrage sud sont posés ici,
## leurs scènes (`data/cutscenes/cerulean_rocket.json`) décident selon les drapeaux. Les PNJ
## (Rocket, ruban, barrage) sont dans `data/npcs/cerulean_city.json`.
##
##   godot --headless --path . -s res://tools/build_cerulean_city.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale peinte (`docs/design/reference/azuria-vue-generale-v1.png`)
## donne la DA : ville claire en pierre pâle, canal en L à angles droits (4 de large) bordé de quais,
## trois ponts (central de 3 de large dans l'axe place → sortie nord, Arène, ouest), Centre en
## premier bâtiment de l'avenue, Arène à verrière de l'autre côté du canal, baie à l'est avec la
## Grotte Azurée sur son îlot, maison cambriolée (toit sombre, porte condamnée, jardin clos) au
## nord-ouest, Boutique et magasin de vélos au sud, forêt dense tout autour.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` chemin, `p` `q` pavés, `B` pont
##   (praticable), `w` eau (jamais praticable) ; tout le reste (forêt, bâtiments toit compris,
##   haies, clôtures, bancs, arbres en bac, îlot, palissade, jardin clos) est solide.
## - Image : sol peint (masque R = pavés et quais, G = chemins, jardin clos et sentiers peints),
##   eau claire des canaux dans la passe du sol (`cerulean_map_kit.gd`), quais en modules, tabliers
##   de pont par pont (un identifiant chacun), forêt serrée, bâtiments, mobilier de ville.
## - Passages : trois warps PUSH ← à l'ouest (0, 19..21) → `route_4` / `from_cerulean_n|c|s` (arrivée
##   ici : `from_route_4_n|c|s`), trois PUSH ↑ au nord (31..33, 0) → `route_24` /
##   `from_cerulean_w|c|e` (arrivée ici : `from_route_24_w|c|e`), portes STEP_ON ↑
##   des cinq bâtiments ouverts. Est et sud : fermés **sans warp**.

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/azuria.txt"
const OUT_PATH: String = "res://game/world/maps/cerulean_city.tscn"
const MASK_PATH: String = "res://assets/world/maps/cerulean_city_ground.png"
const NPCS_PATH: String = "res://data/npcs/cerulean_city.json"
## Variante de la grille : Azuria après le J18 (cumulative sur la J14 : arbre à couper en
## (53, 23), sentier et raccord de la Route 9 à l'est ; dossier 21 §9, I-2).
const PLAN_VARIANT: String = "J18"
const SIZE := Vector2i(56, 41)
const SEED: int = 2131
const DECOR_SEED: int = 2132
const FOREST_SEED: int = 31
const QUAY_SEED: int = 2133

const MAP_ID: StringName = &"cerulean_city"
const DISPLAY_NAME: String = "Azuria"
## Sous-titre du titre de zone (dossier 16 §21 n° 5).
const REGION: String = "La ville aux eaux claires"
const WALKABLE_MARKS: String = ".=pqBDJYk"

## Tabliers par pont (clé = case du coin nord-ouest du pont) : central 3 de large, Arène 2 de
## large (`ns`), pont ouest `ew`.
const DECKS: Dictionary = {
	Vector2i(31, 15): "prop_pont_ville_03_01",
	Vector2i(40, 15): "prop_pont_ville_01",
	Vector2i(26, 8): "prop_pont_ville_ew_01",
}

## Raccords (noms posés par la T8) : Route 4 (rangées n / c / s) et Route 24 (colonnes w / c / e).
const WEST_CELLS: Array[Vector2i] = [Vector2i(0, 19), Vector2i(0, 20), Vector2i(0, 21)]
const NORTH_CELLS: Array[Vector2i] = [Vector2i(31, 0), Vector2i(32, 0), Vector2i(33, 0)]
const WEST_SUFFIXES: Array[String] = ["n", "c", "s"]
const NORTH_SUFFIXES: Array[String] = ["w", "c", "e"]

## Bâtiments : [objet, case d'ancrage, nom du nœud, position des portes dans la grille,
## intérieur, spawn d'ici (devant la porte, tourné ↓), libellé « à venir »].
const BUILDINGS: Array = [
	["bldg_centre_01", Vector2i(9, 18), "PokemonCenter", "porte_centre", &"cerulean_center",
		"from_center", "Centre Pokémon"],
	["bldg_boutique_01", Vector2i(26, 35), "PokeMart", "porte_boutique", &"cerulean_mart",
		"from_mart", "Boutique"],
	["bldg_arene_azuria_01", Vector2i(41, 9), "Gym", "porte_arene", &"cerulean_gym",
		"from_gym", "Arène d'Azuria"],
	["bldg_velos_01", Vector2i(39, 35), "BikeShop", "porte_velos", &"cerulean_bike_shop",
		"from_bike_shop", "Magasin de vélos"],
	["bldg_maison_argenta_01", Vector2i(19, 9), "HouseOpen", "porte_maison", &"cerulean_house",
		"from_house", "Maison"],
]
const INTERIOR_SPAWN: StringName = &"entrance"
## Maison cambriolée (`M`, porte `f` fermée) : même image que la maison ouverte, teinte plus
## sombre (toit brun de la vue) ; porte condamnée posée par-dessus.
const BURGLED_HOUSE := Vector2i(10, 9)
const BURGLED_TINT := Color(0.8, 0.7, 0.66)
## Drapeau de la victoire sur le Rocket d'Azuria (J14) : planche clouée, porte condamnée.
const VICTORY_FLAG: StringName = &"cerulean_rocket_beaten"
## Arbre dense qui ferme l'impasse à l'est (22, 3), posé à la main : la forêt autour du point
## d'arrêt du Rocket (21, 3) est dégagée pour qu'aucune cime ne le cache.
const IMPASSE_TREE := Vector2i(22, 3)
## Spawns de débogage : devant la clôture arrachée du jardin, et dans l'impasse juste avant la bande.
const DEBUG_GARDEN := Vector2i(5, 2)
const DEBUG_IMPASSE := Vector2i(16, 3)
## Devant l'arbre à couper de la barrière est (J18), tourné vers l'est (départ de débogage).
const DEBUG_EAST_TREE := Vector2i(52, 23)
const IMPASSE_TREE_ID: String = "tree_foret_03"
## Îlot de la Grotte Azurée : ancre du pied (bord bas, entre les colonnes 52 et 53).
const ISLET_ANCHOR := Vector2i(53, 6)
## Escalier de quai posé à la main sur la rive nord du canal horizontal (module 192 × 101).
const QUAY_STAIRS := Vector2(36.0, 15.0)

## Cases des arbres en bac (`G`) et bancs (`n`).
const BENCH_SCALE: float = 0.55
## Panneaux : [position de la grille, nœud, dialogue, orientation exigée] (T17).
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"cerulean_city_sign", Vector2i.UP],
	["panneau_arene", "SignGym", &"cerulean_gym_sign", Vector2i.UP],
]
## Examens (T17, dossier 16 §6, §4.2) : [position de la grille, nœud, dialogue, orientation
## exigée] ; taille et ancre déduites de la grille. Aucun marqueur, aucun objectif : le
## décor seul porte l'indice.
## J14 : la porte cambriolée est un passage (ruban = PNJ objet qui s'examine), la palissade du
## sud est un couloir (barrage = PNJ) ; le trou (14, 3) s'examine depuis (13, 3) tourné → (n° 29).
const EXAMS: Array = [
	["cloture_arrachee", "TornFence", &"cerulean_torn_fence", Vector2i.RIGHT],
	["trou_cloture", "FenceHole", &"cerulean_fence_hole", Vector2i.RIGHT],
]
## Barrière est (J18, dossier 21 §9, I-2) : l'arbre à couper (53, 23) entre deux pans de clôture,
## sur le modèle de l'arbuste de l'Arène de Carmin (J16) : [FlagGate] `unless` le drapeau de Coupe
## (cases bloquantes tant qu'il est debout), point d'examen (texte 17, ou l'offre de Coupe) et
## scène `cut_tree_cerulean_east` (cible `Entities/EastTree`).
const EAST_TREE_FLAG: StringName = &"cut_cerulean_east_bush"
const EAST_TREE_DIALOGUE: StringName = &"cerulean_east_tree"
const EAST_TREE_ID: String = "tree_c_01"
const EAST_FENCE_CELLS: Array[Vector2i] = [Vector2i(53, 22), Vector2i(53, 24)]
## Raccord est : trois cases PUSH → vers la Route 9 (`from_cerulean_n|""|_s`, rangée pour rangée) ;
## arrivées ici `from_route_9_n|""|_s`.
const EAST_MAP: StringName = &"route_9"
const EAST_SPAWNS: Array[String] = ["from_route_9_n", "from_route_9", "from_route_9_s"]
const EAST_TARGETS: Array[StringName] = [&"from_cerulean_n", &"from_cerulean", &"from_cerulean_s"]
## Déclencheurs de scène du J14 : [position de la grille, nœud, direction du pas, scène].
const SCENE_TRIGGERS: Array = [
	["poursuite", "RocketChase", Vector2i.RIGHT, &"cerulean_rocket_chase"],
	["combat_rocket", "RocketFight", Vector2i.RIGHT, &"cerulean_rocket_fight"],
	["barrage_sud", "SouthGuard", Vector2i.DOWN, &"cerulean_south_guard"],
]
## Raccord sud : trois cases PUSH ↓ (J14) ; arrivées ici `from_route_5_w|c|e`. **Jalon 15 T21** :
## la vraie Route 5 (`route_5` / `from_cerulean_w|c|e`, colonne pour colonne, tournée ↓) remplace
## « ROUTE 5 — À venir ».
const SOUTH_SUFFIXES: Array[String] = ["w", "c", "e"]
const SOUTH_MAP: StringName = &"route_5"
## Arrivée à Azuria : déclencheurs silencieux [position de la grille, nœud, direction].
const ARRIVALS: Array = [
	["arrivee_ouest", "ArrivalWest", Vector2i.RIGHT],
	["arrivee_nord", "ArrivalNorth", Vector2i.DOWN],
]
## Haies et buissons des cases `x`.
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const SHADE_VALUE: float = 0.98
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
## Pelouses : touffes et fleurs (un peu plus de fleurs qu'à Argenta : « fleurs plus fréquentes en
## ville », fiche série 15 §B).
const MEADOW_ATTEMPTS: int = 900
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED, PLAN_VARIANT)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_cerulean_city : %s" % _kit.get(&"errors"))
		quit(1)
		return
	# Praticables de la grille ; `K` (îlot) n'est pas une paroi de montagne.
	_kit.call(&"set_marks", WALKABLE_MARKS, "", "")
	_kit.call(&"make_root", "CeruleanCity", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_prepare_cells()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_cerulean_city : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_burgled_door()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var quays: int = _kit.call(&"place_quays")
	var decks: int = _kit.call(&"place_bridges", DECKS)
	_place_ground_props(decals)
	_place_buildings(entities)
	_place_props(entities)
	_place_water_props(entities)
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, [] as Array[Vector2], {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_cerulean_city :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", _out_path())
	print("cerulean_city : %s (%d entités, %d au sol dont %d quais et %d tabliers, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, quays, decks, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	quit(0 if result.x == OK else 1)


## Scène écrite : [constant OUT_PATH], ou `--out=<res://…>` (vérification du diff).
func _out_path() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return OUT_PATH


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Natures de cases que la boîte à outils ne classe pas d'office : l'îlot et la bouche de la
## Grotte Azurée sont **dans l'eau** (ni quai ni sol : aucune pièce de quai ne les longe, l'eau
## passe dessous), le jardin clos et les sentiers peints sont de la terre, les arbres en bac
## gardent les pavés sous eux ; cases des habitants réservées à la forêt.
func _prepare_cells() -> void:
	var water: Dictionary = _kit.get(&"water_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "KA"):
		water[cell] = true
	var path: Dictionary = _kit.get(&"path_cells")
	# Jardin clos et trou (J14 : praticables, toujours de la terre), sentiers peints.
	for cell: Vector2i in _plan().call(&"cells_of", "jJYak"):
		path[cell] = true
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		paved[cell] = true
	var reserved: Array[Vector2i] = []
	var positions: Dictionary = (_plan().get(&"positions") as Dictionary)
	for id: String in positions:
		if positions[id]["kind"] == "pnj":
			reserved.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", reserved)


func _add_passages() -> void:
	for i: int in WEST_CELLS.size():
		_kit.call(&"add_warp", "Route4" + WEST_SUFFIXES[i].to_upper(), WEST_CELLS[i], Kit.PUSH,
			Vector2i.LEFT, &"route_4", StringName("from_cerulean_" + WEST_SUFFIXES[i]),
			Vector2i.LEFT)
		_kit.call(&"add_spawn", "from_route_4_" + WEST_SUFFIXES[i], WEST_CELLS[i])
	for i: int in NORTH_CELLS.size():
		_kit.call(&"add_warp", "Route24" + NORTH_SUFFIXES[i].to_upper(), NORTH_CELLS[i],
			Kit.PUSH, Vector2i.UP, &"route_24", StringName("from_cerulean_" + NORTH_SUFFIXES[i]),
			Vector2i.UP)
		_kit.call(&"add_spawn", "from_route_24_" + NORTH_SUFFIXES[i], NORTH_CELLS[i])
	var south: Array[Vector2i] = _plan().call(&"cells_at", "warp_sud")
	for i: int in south.size():
		_kit.call(&"add_warp", "Route5" + SOUTH_SUFFIXES[i].to_upper(), south[i], Kit.PUSH,
			Vector2i.DOWN, SOUTH_MAP, StringName("from_cerulean_" + SOUTH_SUFFIXES[i]),
			Vector2i.DOWN)
		_kit.call(&"add_spawn", "from_route_5_" + SOUTH_SUFFIXES[i], south[i])
	var east: Array[Vector2i] = _plan().call(&"cells_at", "warp_est")
	for i: int in east.size():
		_kit.call(&"add_warp", "Route9" + ["N", "C", "S"][i], east[i], Kit.PUSH, Vector2i.RIGHT,
			EAST_MAP, EAST_TARGETS[i], Vector2i.RIGHT)
		_kit.call(&"add_spawn", EAST_SPAWNS[i], east[i])
	for entry: Array in BUILDINGS:
		var doors: Array = _plan().call(&"cells_at", entry[3])
		var front: Vector2i = (doors[-1] as Vector2i) + Vector2i.DOWN
		_kit.call(&"add_spawn", entry[5], front)
		var interior: StringName = entry[4]
		var built := ResourceLoader.exists("res://game/world/maps/%s.tscn" % interior)
		var index := 0
		for door: Vector2i in doors:
			var node := "Door%s%s" % [entry[2], "" if doors.size() == 1 else ["W", "E"][index]]
			index += 1
			if built:
				_kit.call(&"add_warp", node, door, Kit.STEP_ON, Vector2i.UP, interior,
					INTERIOR_SPAWN, Vector2i.ZERO)
			else:
				_kit.call(&"add_warp", node, door, Kit.STEP_ON, Vector2i.UP, &"",
					StringName(entry[5]), Vector2i.DOWN, entry[6])


## Maison cambriolée (J14) : porte (10, 9) STEP_ON ↑ vers l'intérieur ; le ruban (PNJ) l'occupe
## jusqu'à la victoire sur le Rocket. Arrivée devant la porte, tourné ↓.
func _add_burgled_door() -> void:
	var door: Vector2i = _cell("porte_cambriolee")
	_kit.call(&"add_warp", "DoorBurgledHouse", door, Kit.STEP_ON, Vector2i.UP,
		&"cerulean_burgled_house", INTERIOR_SPAWN, Vector2i.ZERO)
	_kit.call(&"add_spawn", "from_burgled_house", door + Vector2i.DOWN)
	# Départs de débogage (tools/debug_start/) : rue du jardin, bout de l'impasse (avant la bande).
	_kit.call(&"add_spawn", "garden_start", DEBUG_GARDEN)
	_kit.call(&"add_spawn", "impasse_start", DEBUG_IMPASSE)
	_kit.call(&"add_spawn", "east_tree", DEBUG_EAST_TREE)


## Vie d'Azuria (T17) : panneaux, examens, déclencheurs d'arrivée.
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	for entry: Array in EXAMS:
		var box := _box(entry[0])
		_kit.call(&"add_interactable", entry[1], box[0], box[1], entry[3], entry[2])
	var tree := _box("barriere_est")
	_kit.call(&"add_interactable", "EastTreeExamine", tree[0], tree[1], Vector2i.RIGHT,
		EAST_TREE_DIALOGUE)
	var examine: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [EAST_TREE_FLAG]
	examine.set(&"unless_flags", unless)
	for entry: Array in ARRIVALS:
		var box := _box(entry[0])
		_kit.call(&"add_trigger", entry[1], box[0], box[1], entry[2], &"cerulean_arrival")
	for entry: Array in SCENE_TRIGGERS:
		var box := _box(entry[0])
		_kit.call(&"add_trigger", entry[1], box[0], box[1], entry[2], entry[3])


## Rectangle d'une position de la grille : [ancre (bas-gauche), taille].
func _box(id: String) -> Array:
	var low := Vector2i(1 << 20, -1)
	var high := Vector2i(-1, 1 << 20)
	for cell: Vector2i in _plan().call(&"cells_at", id):
		low = Vector2i(mini(low.x, cell.x), maxi(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), mini(high.y, cell.y))
	return [low, Vector2i(high.x - low.x + 1, low.y - high.y + 1)]


## Relief du sol (sous les personnages) : îlot de la Grotte Azurée, escalier de quai.
func _place_ground_props(decals: Node2D) -> void:
	var rules: GDScript = _kit.get(&"rules")
	var foot: Vector2 = rules.call(&"foot_position", &"relief_grotte_azuree_01", ISLET_ANCHOR)
	_kit.call(&"add_prop", decals, "relief_grotte_azuree_01", foot, "GrotteAzuree")
	_kit.call(&"add_prop", decals, "relief_quai_06",
		(QUAY_STAIRS * float(Kit.TILE)) + Vector2(96.0, 101.0), "EscalierQuai")


func _place_buildings(entities: Node2D) -> void:
	for entry: Array in BUILDINGS:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
	var burgled: Node2D = _kit.call(&"add_prop_at", entities, "bldg_maison_argenta_01",
		BURGLED_HOUSE, "HouseBurgled")
	burgled.modulate = BURGLED_TINT
	# Décor de la maison cambriolée (fiche série 15 : planche du cambriolage) — décor seul.
	# J14 : la porte est un passage (sans emprise) ; les planches de la porte disparaissent avec
	# le ruban, à la victoire sur le Rocket (FlagGate, visuel seulement).
	_add_gated(entities, "prop_porte_condamnee_01", BURGLED_HOUSE, "BoardedDoor", [],
		[VICTORY_FLAG])
	_kit.call(&"add_prop_at", entities, "prop_pot_renverse_01", _cell("pot_renverse"),
		"SpilledPot")
	# Le trou du fond (14, 3) est praticable : l'image du trou n'a plus d'emprise.
	var hole: Node2D = _kit.call(&"add_prop", entities, "prop_cloture_trou_01",
		(_kit.get(&"rules") as GDScript).call(&"foot_position", &"prop_cloture_trou_01",
			_cell("trou_cloture")), "FenceGap")
	_kit.call(&"clear_footprint", hole)
	# La planche clouée (fiche série 15, « clôture réparée ») sur la clôture voisine (14, 2) : décor
	# seul, le trou reste praticable.
	_add_gated(entities, "prop_cloture_reparee_01", _cell("planche_clouee"), "NailedBoard",
		[VICTORY_FLAG], [])
	_kit.call(&"add_prop_at", entities, "prop_cloture_arrachee_01", Vector2i(7, 1),
		"FenceTorn")
	# Clôtures : jardin clos (nord : x 9..14, ouest x 6, est x 14) et barrière est (x 53).
	_kit.call(&"add_prop_at", entities, "prop_cloture_01", Vector2i(11, 1), "FenceGardenN")
	# (J14 : la clôture ouest du jardin (6, 2..3) est arrachée, on entre par là.)
	for cell: Vector2i in [Vector2i(13, 1), Vector2i(14, 1), Vector2i(14, 2), Vector2i(14, 4),
			Vector2i(14, 5)]:
		_kit.call(&"add_prop_at", entities, "prop_cloture_courte_01", cell,
			"FenceShort%d_%d" % [cell.x, cell.y])
	_kit.call(&"add_prop_at", entities, "prop_cloture_v_01", Vector2i(14, 9), "FenceGardenE")
	# Barrière est (J18) : deux pans de clôture et l'arbre à couper entre eux (le pan de 4 cases
	# du J14 couvrait la case de l'arbre).
	for cell: Vector2i in EAST_FENCE_CELLS:
		_kit.call(&"add_prop_at", entities, "prop_cloture_courte_01", cell,
			"FenceEast%d" % cell.y)
	_add_cut_tree(entities)


## L'arbre à couper (53, 23) : [FlagGate] `unless` [constant EAST_TREE_FLAG], cases bloquantes
## tant qu'il est debout, image sans emprise (la grille ne le compte pas : la case est praticable
## dans la grille, comme l'arbuste de l'Arène de Carmin).
func _add_cut_tree(entities: Node2D) -> void:
	var cell := Vector2i(53, 23)
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "EastTree"
	gate.position = ((_kit.get(&"rules") as GDScript).call(&"foot_position",
		StringName(EAST_TREE_ID), cell) as Vector2).round()
	var unless: Array[StringName] = [EAST_TREE_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var tree: Node2D = _kit.call(&"add_prop", gate, EAST_TREE_ID, Vector2.ZERO, "Tree")
	_kit.call(&"clear_footprint", tree)


## Décor suivant les drapeaux : un [FlagGate] au pied de l'objet, l'objet en enfant (visuel
## seulement, sans emprise : la grille décide des cases).
func _add_gated(entities: Node2D, id: String, cell: Vector2i, node_name: String,
		if_flags: Array[StringName], unless_flags: Array[StringName]) -> void:
	var foot: Vector2 = (_kit.get(&"rules") as GDScript).call(&"foot_position",
		StringName(id), cell)
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = node_name + "Gate"
	gate.position = foot.round()
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless_flags)
	_kit.call(&"attach", entities, gate)
	var prop: Node2D = _kit.call(&"add_prop", gate, id, Vector2.ZERO, node_name)
	_kit.call(&"clear_footprint", prop)


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	_kit.call(&"add_prop_at", entities, IMPASSE_TREE_ID, IMPASSE_TREE, "ImpasseTree")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		_kit.call(&"add_prop_at", entities, "prop_arbre_bac_01", cell, "Planter%02d" % index)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		var bench: Node2D = _kit.call(&"add_prop", entities, "prop_banc_pierre_01",
			Vector2(cell.x + 0.5, cell.y + 1.0) * tile, "Bench%d" % index)
		index += 1
		bench.scale = Vector2(BENCH_SCALE, BENCH_SCALE)
		_kit.call(&"clear_footprint", bench)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var chosen: Dictionary = {}
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.12)
		bush.scale = Vector2(scale, scale)
		var value := decor.randf_range(0.94, 1.06)
		bush.modulate = Color(value, value, value)


## Petits objets posés **dans l'eau** au bord des quais (cases d'eau, jamais praticables) :
## lampadaires, bittes, roseaux de la baie. Sans emprise (l'eau est déjà solide).
func _place_water_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var index := 0
	# Lampadaires le long de la rive ouest du canal vertical (colonne 26) et de la rive sud
	# du canal horizontal (rangée 18).
	for cell: Vector2i in [Vector2i(26, 4), Vector2i(26, 13), Vector2i(30, 18),
			Vector2i(37, 18), Vector2i(44, 18)]:
		var lamp: Node2D = _kit.call(&"add_prop", entities, "prop_lampadaire_quai_01",
			Vector2(cell.x * tile + 14.0, (cell.y + 1) * tile - 14.0), "Lamp%d" % index)
		_kit.call(&"clear_footprint", lamp)
		index += 1
	index = 0
	for cell: Vector2i in [Vector2i(26, 7), Vector2i(26, 11), Vector2i(34, 18),
			Vector2i(49, 14)]:
		var bollard: Node2D = _kit.call(&"add_prop", entities, "prop_bitte_01",
			Vector2(cell.x * tile + 22.0, (cell.y + 1) * tile - 18.0), "Bollard%d" % index)
		_kit.call(&"clear_footprint", bollard)
		index += 1
	index = 0
	for cell: Vector2i in [Vector2i(50, 11), Vector2i(53, 13), Vector2i(51, 17),
			Vector2i(54, 9)]:
		var reeds: Node2D = _kit.call(&"add_prop_at", entities, "prop_roseaux_01", cell,
			"Reeds%d" % index)
		_kit.call(&"clear_footprint", reeds)
		index += 1
