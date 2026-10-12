extends SceneTree
## Construit game/world/maps/cerulean_city.tscn (Azuria, 56 × 41 cases) d'après la grille
## fonctionnelle `tools/plans/azuria.txt` (jalon 13 T7, docs/tech/jalon-13.md §2.1, §2.3, §2.5 ;
## dossier 16 §4–§6, §9). **Sans PNJ, sans interaction, sans déclencheur** (T17) : les cases des
## habitants, des examens et des déclencheurs sont réservées (la forêt s'en écarte, la grille les
## laisse libres ou bloquées comme le plan).
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
const SIZE := Vector2i(56, 41)
const SEED: int = 2131
const DECOR_SEED: int = 2132
const FOREST_SEED: int = 31
const QUAY_SEED: int = 2133

const MAP_ID: StringName = &"cerulean_city"
const DISPLAY_NAME: String = "Azuria"
## Sous-titre du titre de zone (dossier 16 §21 n° 5).
const REGION: String = "La ville aux eaux claires"
const WALKABLE_MARKS: String = ".=pqBD"

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
## Îlot de la Grotte Azurée : ancre du pied (bord bas, entre les colonnes 52 et 53).
const ISLET_ANCHOR := Vector2i(53, 6)
## Escalier de quai posé à la main sur la rive nord du canal horizontal (module 192 × 101).
const QUAY_STAIRS := Vector2(36.0, 15.0)

## Cases des arbres en bac (`G`) et bancs (`n`).
const BENCH_SCALE: float = 0.55
## Panneaux : [position de la grille, nœud] — décor seul (lecture : T17).
const SIGNS: Array = [["panneau_ville", "SignCity"], ["panneau_arene", "SignGym"]]
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
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
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
	for cell: Vector2i in _plan().call(&"cells_of", "ja"):
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
	_kit.call(&"add_prop_at", entities, "prop_porte_condamnee_01", BURGLED_HOUSE, "BoardedDoor")
	_kit.call(&"add_prop_at", entities, "prop_pot_renverse_01", _cell("pot_renverse"),
		"SpilledPot")
	_kit.call(&"add_prop_at", entities, "prop_cloture_trou_01", _cell("trou_cloture"),
		"FenceGap")
	_kit.call(&"add_prop_at", entities, "prop_cloture_arrachee_01", Vector2i(7, 1),
		"FenceTorn")
	# Palissade de chantier au sud (x 30..34, y 38..39) : deux modules de 3 qui se chevauchent.
	_kit.call(&"add_prop_at", entities, "prop_palissade_chantier_01", Vector2i(31, 39),
		"HoardingW")
	_kit.call(&"add_prop_at", entities, "prop_palissade_chantier_02", Vector2i(33, 39),
		"HoardingE")
	# Clôtures : jardin clos (nord : x 9..14, ouest x 6, est x 14) et barrière est (x 53).
	_kit.call(&"add_prop_at", entities, "prop_cloture_01", Vector2i(11, 1), "FenceGardenN")
	for cell: Vector2i in [Vector2i(13, 1), Vector2i(14, 1), Vector2i(14, 2), Vector2i(14, 4),
			Vector2i(14, 5), Vector2i(6, 2), Vector2i(6, 3)]:
		_kit.call(&"add_prop_at", entities, "prop_cloture_courte_01", cell,
			"FenceShort%d_%d" % [cell.x, cell.y])
	_kit.call(&"add_prop_at", entities, "prop_cloture_v_01", Vector2i(14, 9), "FenceGardenE")
	_kit.call(&"add_prop_at", entities, "prop_cloture_v_01", Vector2i(53, 24), "FenceEast")
	_kit.call(&"add_prop_at", entities, "tree_c_01", Vector2i(53, 23), "TreeEast")


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
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
