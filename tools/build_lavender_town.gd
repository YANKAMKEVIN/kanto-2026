extends SceneTree
## Construit game/world/maps/lavender_town.tscn (Lavanville, 44 × 36 cases) d'après la grille
## fonctionnelle `tools/plans/lavanville.txt` (jalon 18 T14, docs/tech/jalon-18.md §4.1 à §4.3 ;
## dossier 21 §6, §13.1, §14 ; fiche `serie-21-j18.md`). **La grille fait foi** ; la vue générale
## (`docs/design/reference/lavanville-vue-generale-v1.png`) donne la DA : ville de pierre grise
## violacée, pavés à angles droits, haies de buis taillées, fleurs pâles, la Tour au nord-est,
## forêt dense tout autour.
##
## **Sans vie** (jalon 18 T14, la vie est au T18) : les cases des PNJ, des panneaux (le décor des
## panneaux est posé, sans point d'examen), l'emplacement du panneau du Scope du J19 (42, 11), les
## déclencheurs (légende d'arrivée) sont **réservés** : rien n'est posé, aucune donnée de dialogue.
##
##   godot --headless --path . -s res://tools/build_lavender_town.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import ; code 2 = masque
##   écrit, importer puis relancer)
##
## - `Ground` (invisible) = source logique : `.` pelouse, `p` `D` pavés (praticables) ; tout le
##   reste (forêt, haies, fleurs, bancs, arbres repères, bâtiments toit compris) est solide.
## - Image : sol peint (herbe, pavés de Lavanville au canal R), forêt serrée désaturée, bâtiments
##   (Centre et Boutique réutilisés, Maison des Pokémon, maisons 7 × 6, Tour 12 × 11), haies
##   (buis), fleurs pâles, ifs du parvis, bancs, arbres repères, trois panneaux.
## - Passages : portes STEP_ON ↑ des six bâtiments (spawns `retour_*`), nord (21..23, 0) PUSH ↑
##   vers la Route 10 (`route_10` / `from_lavender_w|c|e`, ou « Route 10 — À venir » tant que la
##   carte n'existe pas), ouest (0, 10..12) « Route 8 — À venir » et sud (21..23, 35) « Route 12 —
##   À venir » (`coming_soon`, développement : en release les bords sont bloqués).

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/lavanville.txt"
const OUT_PATH: String = "res://game/world/maps/lavender_town.tscn"
const MASK_PATH: String = "res://assets/world/maps/lavender_town_ground.png"
const NPCS_PATH: String = "res://data/npcs/lavender_town.json"
const SIZE := Vector2i(44, 36)
const SEED: int = 2901
const DECOR_SEED: int = 2902
const FOREST_SEED: int = 2903
const QUAY_SEED: int = 2904

const MAP_ID: StringName = &"lavender_town"
const DISPLAY_NAME: String = "Lavanville"
## Région : remplacée par la légende à la 1re arrivée (plan §4.1, §4.11).
const REGION: String = "Kanto"
const LIGHT_PROFILE: StringName = &"lavender"
const WALKABLE_MARKS: String = ".pD"
## Pavés de Lavanville (série 21) : canal R du sol peint.
const PAVING_TEXTURE: String = "res://assets/world/ground/ground_paves_lavanville_01.png"
const SUFFIXES_H: Array[String] = ["w", "c", "e"]
const SUFFIXES_V: Array[String] = ["n", "c", "s"]
const NORTH_MAP: StringName = &"route_10"
const NORTH_SPAWN_PREFIX: String = "from_lavender_"
const TOWER_STAIRS_SPAWN: StringName = &"from_pokemon_tower_2f"

## Bâtiments : [objet, case d'ancrage, nom du nœud, position des portes dans la grille,
## intérieur, spawn d'ici (devant la porte, tourné ↓), libellé « à venir »].
const BUILDINGS: Array = [
	["bldg_centre_01", Vector2i(9, 21), "PokemonCenter", "porte_centre", &"lavender_center",
		"retour_centre", "Centre Pokémon"],
	["bldg_boutique_01", Vector2i(31, 21), "PokeMart", "porte_boutique", &"lavender_mart",
		"retour_boutique", "Boutique"],
	["bldg_maison_pokemon_01", Vector2i(15, 9), "PokemonHouse", "porte_fuji", &"pokemon_house",
		"retour_fuji", "Maison des Pokémon"],
	["bldg_maison_lavanville_01", Vector2i(6, 9), "House1", "porte_maison_1",
		&"lavender_house_1", "retour_maison_1", "Maison"],
	["bldg_maison_lavanville_01", Vector2i(39, 21), "House2", "porte_maison_2",
		&"lavender_house_2", "retour_maison_2", "Maison"],
	["bldg_tour_pokemon_01", Vector2i(35, 10), "PokemonTower", "porte_tour",
		&"pokemon_tower_1f", "retour_tour", "Tour Pokémon"],
]
const INTERIOR_SPAWN: StringName = &"entrance"
## La maison 2 (`N`) est la maison 1 en miroir (fiche, variation n° 4).
const MIRRORED: Array[String] = ["House2"]
## Panneaux : [position de la grille, nom du nœud, dialogue (T-18 à T-20), orientation du
## joueur qui lit].
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"lavender_town_sign", Vector2i.RIGHT],
	["panneau_tour", "SignTower", &"lavender_tower_sign", Vector2i.UP],
	["panneau_fuji", "SignPokemonHouse", &"lavender_pokemon_house_sign", Vector2i.UP],
]
## Arrivée à Lavanville (T24) : scène silencieuse `lavender_reached` (objectif « Visiter la
## Tour Pokémon. »), tout pas vers le bas sur la 2e rangée (position `legende_arrivee`).
const ARRIVAL_CUTSCENE: StringName = &"lavender_reached"
## Ifs du parvis (de part et d'autre de la porte de la Tour, sur les cases de la façade) et
## massifs de fleurs pâles à côté.
const YEWS: Array[Vector2i] = [Vector2i(33, 10), Vector2i(36, 10)]
const PLANTERS: Array[Vector2i] = [Vector2i(32, 10), Vector2i(37, 10)]
const TREES: Array = [["tree_a_01", 0.8, false], ["tree_b_01", 0.78, true],
	["tree_a_01", 0.75, true], ["tree_b_01", 0.8, false]]
const HEDGE_IDS: Array[String] = ["prop_buis_taille_01", "prop_buis_taille_02"]
const FLOWER_SINGLE: String = "prop_fleurs_pales_01"
const FLOWER_PAIR: String = "prop_fleurs_pales_02"
## Ombre « plus sèche » de la forêt, un peu froide et désaturée (profil `lavender`).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 0.99
const SHADE_BLUE: float = 1.05
## Pelouses : touffes seulement (les fleurs pâles sont des objets ; aucune décalcomanie de fleur
## blanche ou mauve dans les images du jeu).
const MEADOW_ATTEMPTS: int = 700
const MEADOW_FLOWER_CHANCE: float = 0.0
const FLOWERS: Array[int] = [1]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_lavender_town : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE_MARKS, "", "")
	_kit.call(&"make_root", "LavenderTown", MAP_ID, DISPLAY_NAME, REGION, LIGHT_PROFILE,
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_prepare_cells()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_lavender_town : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var painted: Node = (_kit.get(&"root") as Node).get_node(^"PaintedGround")
	painted.set(&"r_texture", load(PAVING_TEXTURE))
	var entities: Node2D = _kit.get(&"entities")
	_add_passages()
	_add_life()
	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	_place_buildings(entities)
	_place_props(entities)
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, [] as Array[Vector2], {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_lavender_town :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("lavender_town : %s (%d entités, %d au sol, forêt %d → %d, %d nœuds)"
		% [error_string(result.x), counts.x, counts.y, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


func _fail(message: String) -> void:
	var errors: PackedStringArray = _kit.get(&"errors")
	errors.append(message)
	_kit.set(&"errors", errors)


## Les portes restent des pavés (la boîte à outils les compte en chemin de terre) ; les cases des
## PNJ sont réservées à la forêt (aucun arbre ne cache un futur habitant).
func _prepare_cells() -> void:
	var path: Dictionary = _kit.get(&"path_cells")
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "D"):
		path.erase(cell)
		paved[cell] = true
	var reserved: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "pnj":
			reserved.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", reserved)


# --- Passages -----------------------------------------------------------------------------


func _add_passages() -> void:
	var north_built := ResourceLoader.exists("res://game/world/maps/route_10.tscn")
	var north: Array[Vector2i] = _plan().call(&"cells_at", "warp_nord")
	for i: int in north.size():
		var suffix: String = SUFFIXES_H[i]
		# Arrivée de la Route 10 (`from_route_10_w|c|e`) ; le point sans suffixe est celui du
		# milieu (accord de nom avec la Route 10 du T12 à vérifier à la fusion).
		_kit.call(&"add_spawn", "from_route_10_" + suffix, north[i])
		if north_built:
			_kit.call(&"add_warp", "Route10" + suffix.to_upper(), north[i], Kit.PUSH,
				Vector2i.UP, NORTH_MAP, StringName(NORTH_SPAWN_PREFIX + suffix), Vector2i.UP)
		else:
			_kit.call(&"add_warp", "Route10" + suffix.to_upper(), north[i], Kit.PUSH,
				Vector2i.UP, &"", StringName("from_route_10_" + suffix), Vector2i.DOWN,
				"Route 10")
	_kit.call(&"add_spawn", "from_route_10", north[1])
	# Ouest : « ROUTE 8 — À venir » ; retour une case à l'intérieur, tourné vers l'est.
	var west: Array[Vector2i] = _plan().call(&"cells_at", "warp_ouest")
	var west_back: Array[Vector2i] = _plan().call(&"cells_at", "from_route_8")
	for i: int in west.size():
		var name := "from_route_8_" + SUFFIXES_V[i]
		_kit.call(&"add_spawn", name, west_back[i])
		_kit.call(&"add_warp", "Route8" + SUFFIXES_V[i].to_upper(), west[i], Kit.PUSH,
			Vector2i.LEFT, &"", StringName(name), Vector2i.RIGHT, "Route 8")
	# Sud : « ROUTE 12 — À venir » ; retour une case au nord, tourné vers le haut.
	var south: Array[Vector2i] = _plan().call(&"cells_at", "warp_sud")
	var south_back: Array[Vector2i] = _plan().call(&"cells_at", "from_route_12")
	for i: int in south.size():
		var name := "from_route_12_" + SUFFIXES_H[i]
		_kit.call(&"add_spawn", name, south_back[i])
		_kit.call(&"add_warp", "Route12" + SUFFIXES_H[i].to_upper(), south[i], Kit.PUSH,
			Vector2i.DOWN, &"", StringName(name), Vector2i.UP, "Route 12")
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


# --- Vie (T24) ----------------------------------------------------------------------------


## Examen des trois panneaux et déclencheur de l'arrivée (les PNJ viennent de `NPCS_PATH`).
## Le panneau du Scope Sylphe (42, 11) est réservé au J19 : rien n'y est posé.
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", String(entry[1]) + "Point", _cell(entry[0]), Vector2i.ONE,
			entry[3], entry[2])
	var arrival: Array = _plan().call(&"cells_at", "legende_arrivee")
	_kit.call(&"add_trigger", "Arrival", arrival[0], Vector2i(arrival.size(), 1), Vector2i.DOWN,
		ARRIVAL_CUTSCENE)


# --- Bâtiments, objets ---------------------------------------------------------------------


func _place_buildings(entities: Node2D) -> void:
	for entry: Array in BUILDINGS:
		var building: Node2D = _kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		if MIRRORED.has(entry[2]):
			_kit.call(&"flip", building, true)


func _place_props(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TREES[index % TREES.size()]
		var tree: Node2D = _kit.call(&"add_prop_at", entities, spec[0], cell, "Tree%02d" % index)
		index += 1
		tree.scale = Vector2(spec[1], spec[1])
		_kit.call(&"flip", tree, spec[2])
	# Bancs `nn` : un module de 2 cases par paire (ancré sur la case de droite).
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		if _plan().call(&"at", cell + Vector2i.LEFT) == "n":
			continue
		if _plan().call(&"at", cell + Vector2i.RIGHT) != "n":
			_fail("banc isolé en %s" % cell)
			continue
		_kit.call(&"add_prop_at", entities, "prop_banc_01", cell + Vector2i.RIGHT,
			"Bench%d" % index)
		index += 1
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	# Haies `x` : buis taillés, deux modèles jamais identiques côte à côte, valeur variée.
	var chosen: Dictionary = {}
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in HEDGE_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id \
					and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		if options.is_empty():
			options.assign(HEDGE_IDS)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Hedge%03d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var value := decor.randf_range(0.95, 1.05)
		bush.modulate = Color(value, value, value)
	_place_flowers(entities)
	# Ifs et massifs de part et d'autre de la porte de la Tour : sur la façade (cases du
	# bâtiment, déjà bloquées), triés après lui.
	var tile := float(Kit.TILE)
	index = 0
	for cell: Vector2i in YEWS:
		var yew: Node2D = _kit.call(&"add_prop", entities, "prop_if_taille_01",
			Vector2((cell.x + 0.5) * tile, (cell.y + 1) * tile + 1.0), "Yew%d" % index)
		_kit.call(&"clear_footprint", yew)
		index += 1
	index = 0
	for cell: Vector2i in PLANTERS:
		var planter: Node2D = _kit.call(&"add_prop", entities, FLOWER_SINGLE,
			Vector2((cell.x + 0.5) * tile, (cell.y + 1) * tile + 1.0), "Planter%d" % index)
		_kit.call(&"clear_footprint", planter)
		index += 1


## Massifs `y` : un module de 2 cases pour deux cases voisines d'une même rangée (ancré à droite),
## un module d'une case pour les autres.
func _place_flowers(entities: Node2D) -> void:
	var done: Dictionary = {}
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "y"):
		if done.has(cell):
			continue
		var right := cell + Vector2i.RIGHT
		if _plan().call(&"at", right) == "y" and not done.has(right):
			done[cell] = true
			done[right] = true
			_kit.call(&"add_prop_at", entities, FLOWER_PAIR, right, "Flowers%03d" % index)
		else:
			done[cell] = true
			_kit.call(&"add_prop_at", entities, FLOWER_SINGLE, cell, "Flowers%03d" % index)
		index += 1
