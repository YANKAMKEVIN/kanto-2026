extends SceneTree
## Construit game/world/maps/celadon_city.tscn (Céladopole, 70 × 46 cases) d'après la grille
## fonctionnelle `tools/plans/celadopole.txt` (jalon 20 T16, docs/tech/jalon-20.md §1.3, §2.1,
## §2.2, §2.8, §2.15 ; dossier 23 §7). **Sans PNJ, sans Dresseur, sans événement** (T17) : les
## cases des 12 habitants et des 2 Rocket en civil sont réservées (la forêt s'en écarte, la grille
## les laisse libres).
##
##   godot --headless --path . -s res://tools/build_celadon_city.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##   puis relancer `build_route_7.gd` (le raccord ouest de la Route 7 n'est plus « à venir »).
##
## **La grille fait foi** ; la vue générale peinte (`docs/design/reference/celadopole-vue-generale-
## v1.png`) ne donne que la DA : avenue est-ouest, promenade au pied du grand magasin, deux rues
## nord-sud, étang et quai au centre-nord, place de la fontaine, Casino (néons), Arène dans son
## enclos de haies au sud-ouest, haie d'arbres et talus à l'ouest.
## **Art provisoire** : façades générées (`tools/art/placeholders_celadopole.py`, série 22 bis à
## venir), le reste du kit existant (cerulean_map_kit : eau claire et quais de l'étang).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` chemin, `p` pavés, `q` quai de
##   l'étang (pavés), `w` eau (jamais praticable) ; tout le reste (forêt, talus, bâtiments toit
##   compris, haies, massifs, bancs, fontaine, arbres repères) est solide. **Exception (contrat
##   du J16)** : la case `W` de l'arbuste de l'enclos (19, 37) est praticable dans `Ground` et
##   **occupée** par le décor de l'arbuste ([FlagGate] `blocking_cells`) tant que
##   `cut_celadon_gym_bush` n'est pas levé : sans Coupe, l'enclos et l'Arène sont fermés ; le
##   reste de la ville est entièrement ouvert.
## - Passages : est (69, 21..23) PUSH → `route_7` / `from_celadon_n|c|s` (arrivées ici
##   `from_route_7_n|c|s`, tournées ←) ; portes STEP_ON ↑ des neuf bâtiments ouverts, arrivées
##   `from_<lieu>_w|e` devant chaque porte à deux cases (`from_chief` : porte d'une case).
##   Nord et sud : fermés **sans warp**. Ouest (jalon 21, T22) : voir le bloc « Jalon 21 » ci-dessous.
##   Le Casino (T20) reste « à venir » tant que `celadon_game_corner` n'existe pas.

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/celadopole.txt"
const OUT_PATH: String = "res://game/world/maps/celadon_city.tscn"
const MASK_PATH: String = "res://assets/world/maps/celadon_city_ground.png"
const NPCS_PATH: String = "res://data/npcs/celadon_city.json"
const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(70, 46)
const SEED: int = 2201
const DECOR_SEED: int = 2202
const FOREST_SEED: int = 2203
const QUAY_SEED: int = 2204
const CLIFF_SEED: int = 2205

const MAP_ID: StringName = &"celadon_city"
const DISPLAY_NAME: String = "Céladopole"
## Sous-titre du titre de zone (dossier 23, texte 13).
const REGION: String = "La cité aux mille couleurs"
## Praticables de la grille, plus `W` (l'arbuste de l'enclos : occupé par son décor, J16).
const WALKABLE_MARKS: String = ".=pqDW"
const CLIFF_MARKS: String = "s"

const EAST_MAP: StringName = &"route_7"
const EAST_SUFFIXES: Array[String] = ["n", "c", "s"]
# --- Jalon 21 (T22) : raccord ouest vers la Route 16 (dossier 24 §10.2, jalon-21.md §2.12) ---------
## Bande ouest (0..3, 21..23) en chemin ; `warp_ouest` (0, 21..23) PUSH ← → `route_16` ; arrivées
## `from_route_16` (1, 21..23) tournées →. La grille donne un seul nom d'arrivée : la rangée du milieu
## le garde, les rangées nord et sud ajoutent le suffixe `_n` / `_s` pour garder la rangée de
## sortie [D] (même principe que la Route 7). Tant que `route_16` n'est pas construite : « à venir ».
const WEST_MAP: StringName = &"route_16"
const WEST_SUFFIXES: Array[String] = ["_n", "", "_s"]
const WEST_COMING_SOON: String = "Route 16"
const INTERIOR_SPAWN: StringName = &"entrance"
## Bâtiments : [objet, nœud, position des portes, intérieur, base du nom des arrivées, libellé
## « à venir », (arrivée dans l'intérieur : `entrance` par défaut)]. Ancre = la porte la plus à l'est (portes à deux cases : décalages −1 et 0).
const BUILDINGS: Array = [
	["bldg_grand_magasin_01", "DepartmentStore", "porte_magasin", &"celadon_dept_gf", "dept",
		"Grand magasin"],
	["bldg_residence_01", "Mansion", "porte_residence", &"celadon_mansion_gf", "mansion",
		"Résidence"],
	["bldg_escalier_service_01", "ServiceStairs", "porte_service", &"celadon_mansion_roof",
		"service", "Escalier de service", &"from_service"],
	["bldg_centre_01", "PokemonCenter", "porte_centre", &"celadon_center", "center",
		"Centre Pokémon"],
	["bldg_casino_01", "Casino", "porte_casino", &"celadon_game_corner", "casino", "Casino"],
	["bldg_arene_celadopole_01", "Gym", "porte_arene", &"celadon_gym", "gym",
		"Arène de Céladopole"],
	["bldg_maison_chef_01", "ChiefHouse", "porte_chef", &"celadon_chief_house", "chief",
		"Maison"],
	["bldg_restaurant_01", "Restaurant", "porte_restaurant", &"celadon_restaurant",
		"restaurant", "Restaurant"],
	["bldg_hotel_01", "Hotel", "porte_hotel", &"celadon_hotel", "hotel", "Hôtel"],
]
## Façade de l'ancien Coin à lots : décor sans porte (ancre = bas, colonne 52 = bord du milieu).
const LOTS_ANCHOR := Vector2i(52, 32)
const FOUNTAIN_ANCHOR := Vector2i(29, 30)

## Arbuste de l'enclos (contrat du J16, comme l'arbre de la sortie est d'Azuria).
const BUSH_FLAG: StringName = &"cut_celadon_gym_bush"
const BUSH_ID: String = "prop_jeune_arbre_arene_01"
const BUSH_SCALE: float = 0.7
const BUSH_NODE: String = "GymBush"
const BUSH_DIALOGUE: StringName = &"celadon_gym_bush"
## Panneaux et examens : [position de la grille, nœud, dialogue, orientation exigée].
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"celadon_city_sign", Vector2i.DOWN],
	["panneau_arene", "SignGym", &"celadon_gym_sign", Vector2i.LEFT],
]
## Jalon 21 (T22) : l'examen `obstacle_ouest` (haie et talus, H-4 du J20) et son texte 21 sont retirés.
## Objet caché : case bloquée décorée (poubelle) ; point EXAMINER de tous côtés (T17) qui
## disparaît quand `got_<id>` est levé.
const HIDDEN: Array = [["celadon_hidden_1", "HiddenClue", "int_poubelle_arene_01"]]
## Arrivée (T17) : pas vers l'ouest sur la 2e colonne du raccord est (68, 21..23), scène
## silencieuse qui lève `celadon_reached` (le titre de zone vient du ZoneAnnouncer).
const ARRIVAL_CUTSCENE: StringName = &"celadon_reached"
## Départs de débogage (T17 les relie à `tools/debug_start/`).
const DEBUG_SPAWNS: Array = [["gym_front", Vector2i(20, 37)], ["west_end", Vector2i(5, 22)]]

const TREES: Array = [
	["tree_c_01", 0.7, false], ["tree_a_01", 0.65, true], ["tree_b_01", 0.62, false],
	["tree_c_01", 0.7, true], ["tree_e_01", 0.6, false], ["tree_a_01", 0.68, false],
]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const TRIMMED_IDS: Array[String] = ["prop_buis_taille_01", "prop_buis_taille_02"]
const BENCH_SCALE: float = 0.55
const SHADE_VALUE: float = 0.98
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
const MEADOW_ATTEMPTS: int = 900
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 3, 5]
## Décor de l'étang : roseaux et nénuphars posés dans l'eau (sans emprise : l'eau est solide).
const POND_REEDS: Array[Vector2i] = [Vector2i(40, 12), Vector2i(48, 12), Vector2i(49, 7)]
const POND_LILIES: Array[Vector2i] = [Vector2i(43, 9), Vector2i(46, 10), Vector2i(41, 7)]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_celadon_city : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE_MARKS, CLIFF_MARKS, "")
	_kit.call(&"make_root", "CeladonCity", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_prepare_cells()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_celadon_city : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var quays: int = _kit.call(&"place_quays")
	var cliffs: int = _kit.call(&"place_paroi", CLIFF_SEED)
	var taken := _place_buildings(entities)
	_place_props(entities)
	_place_pond_decor(entities)
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, [] as Array[Vector2], taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_celadon_city :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", _out_path())
	print("celadon_city : %s (%d entités, %d au sol dont %d quais et %d modules de talus, "
		% [error_string(result.x), counts.x, counts.y, quays, cliffs]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
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


func _built(map_id: StringName) -> bool:
	return ResourceLoader.exists(MAPS_DIR + "%s.tscn" % map_id)


## Natures de cases que la boîte à outils ne classe pas d'office : l'arbuste reste de l'herbe, les
## arbres repères posés sur les pavés (arbres en bac) gardent les pavés ; cases des habitants,
## objets visibles et cachés réservées à la forêt.
func _prepare_cells() -> void:
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		if _is_planter(cell):
			paved[cell] = true
	var reserved: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = (_plan().get(&"positions") as Dictionary)
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if kind == "pnj":
			reserved.append_array(positions[id]["cells"])
		if kind == "cache":
			reserved.append_array(positions[id]["cells"])
			balls.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", reserved)
	_kit.set(&"reserved_balls", balls)


## Arbre repère sur les pavés (au moins deux voisines pavées) : arbre en bac ; sinon vrai arbre.
func _is_planter(cell: Vector2i) -> bool:
	var paved := 0
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _plan().call(&"at", cell + side) == "p":
			paved += 1
	return paved >= 2


func _add_passages() -> void:
	var east: Array[Vector2i] = _plan().call(&"cells_at", "warp_est")
	var road := _built(EAST_MAP)
	for i: int in east.size():
		var suffix: String = EAST_SUFFIXES[i]
		_kit.call(&"add_spawn", "from_route_7_" + suffix, east[i])
		if road:
			_kit.call(&"add_warp", "Route7" + suffix.to_upper(), east[i], Kit.PUSH,
				Vector2i.RIGHT, EAST_MAP, StringName("from_celadon_" + suffix), Vector2i.RIGHT)
		else:
			_kit.call(&"add_warp", "Route7" + suffix.to_upper(), east[i], Kit.PUSH,
				Vector2i.RIGHT, &"", StringName("from_route_7_" + suffix), Vector2i.LEFT,
				"Route 7")
	_add_west_passages()
	for entry: Array in BUILDINGS:
		var doors: Array[Vector2i] = _plan().call(&"cells_at", entry[2])
		var interior: StringName = entry[3]
		var arrival: StringName = entry[6] if entry.size() > 6 else INTERIOR_SPAWN
		var built := _built(interior)
		for i: int in doors.size():
			var here := _arrival_name(entry[4], i, doors.size())
			_kit.call(&"add_spawn", here, doors[i] + Vector2i.DOWN)
			var node := "Door%s%s" % [entry[1], "" if doors.size() == 1 else ["W", "E"][i]]
			if built:
				_kit.call(&"add_warp", node, doors[i], Kit.STEP_ON, Vector2i.UP, interior,
					arrival, Vector2i.ZERO)
			else:
				_kit.call(&"add_warp", node, doors[i], Kit.STEP_ON, Vector2i.UP, &"",
					StringName(here), Vector2i.DOWN, entry[5])
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Jalon 21 (T22) : sortie ouest, trois cases PUSH ← vers la Route 16 (`from_celadon[_n|_s]`).
func _add_west_passages() -> void:
	var west: Array[Vector2i] = _plan().call(&"cells_at", "warp_ouest")
	var road := _built(WEST_MAP)
	for i: int in west.size():
		var suffix: String = WEST_SUFFIXES[i]
		var here := StringName("from_route_16" + suffix)
		_kit.call(&"add_spawn", here, (_plan().call(&"cells_at", "from_route_16") as Array)[i])
		if road:
			_kit.call(&"add_warp", "Route16" + ["N", "C", "S"][i], west[i], Kit.PUSH,
				Vector2i.LEFT, WEST_MAP, StringName("from_celadon" + suffix), Vector2i.LEFT)
		else:
			_kit.call(&"add_warp", "Route16" + ["N", "C", "S"][i], west[i], Kit.PUSH,
				Vector2i.LEFT, &"", here, Vector2i.RIGHT, WEST_COMING_SOON)


## `from_dept_w` / `from_dept_e` pour une porte à deux cases, `from_chief` pour une seule.
static func _arrival_name(base: String, index: int, count: int) -> String:
	if count == 1:
		return "from_" + base
	return "from_%s_%s" % [base, "w" if index == 0 else "e"]


## Panneaux et examens, point de l'arbuste de l'enclos.
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	var cell := _cell("arbuste_enclos")
	_kit.call(&"add_interactable", "GymBushExamine", cell, Vector2i.ONE, Vector2i.ZERO,
		BUSH_DIALOGUE)
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [BUSH_FLAG]
	point.set(&"unless_flags", unless)
	for entry: Array in HIDDEN:
		_kit.call(&"add_interactable", "Hidden1", _cell(entry[0]), Vector2i.ONE, Vector2i.ZERO,
			StringName(entry[0]))
		var hidden: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
		var hidden_unless: Array[StringName] = [StringName("got_" + String(entry[0]))]
		hidden.set(&"unless_flags", hidden_unless)
	var east: Array = _plan().call(&"cells_at", "arrivee_est")
	_kit.call(&"add_trigger", "Arrival", east[east.size() - 1], Vector2i(1, east.size()),
		Vector2i.LEFT, ARRIVAL_CUTSCENE)


## Bâtiments, façade de l'ancien Coin à lots, fontaine. Renvoie les cases couvertes (aucun arbre
## dessous).
func _place_buildings(entities: Node2D) -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	var placed: Array = []
	for entry: Array in BUILDINGS:
		var doors: Array[Vector2i] = _plan().call(&"cells_at", entry[2])
		placed.append([entry[0], doors[-1], entry[1]])
	placed.append(["bldg_coin_lots_01", LOTS_ANCHOR, "OldLotsFacade"])
	placed.append(["prop_fontaine_01", FOUNTAIN_ANCHOR, "Fountain"])
	for entry: Array in placed:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	return taken


## Arbres repères, arbres en bac, bancs, massifs taillés, haies, panneaux, indice, arbuste.
func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		if _is_planter(cell):
			_kit.call(&"add_prop_at", entities, "prop_arbre_bac_01", cell, "Planter%02d" % index)
		else:
			var spec: Array = TREES[index % TREES.size()]
			var tree: Node2D = _kit.call(&"add_prop_at", entities, spec[0], cell,
				"Tree%02d" % index)
			tree.scale = Vector2(spec[1], spec[1])
			_kit.call(&"flip", tree, spec[2])
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		var bench: Node2D = _kit.call(&"add_prop", entities, "prop_banc_pierre_01",
			Vector2(cell.x + 0.5, cell.y + 1.0) * tile, "Bench%d" % index)
		index += 1
		bench.scale = Vector2(BENCH_SCALE, BENCH_SCALE)
		_kit.call(&"clear_footprint", bench)
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "j"):
		var trimmed: Node2D = _kit.call(&"add_prop_at", entities,
			TRIMMED_IDS[(cell.x + cell.y) % TRIMMED_IDS.size()], cell, "Trimmed%03d" % index)
		_kit.call(&"flip", trimmed, decor.randf() < 0.5)
		index += 1
	var chosen: Dictionary = {}
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Hedge%03d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.1)
		bush.scale = Vector2(scale, scale)
		var value := decor.randf_range(0.94, 1.06)
		bush.modulate = Color(value, value, value)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1] + "Post")
	for entry: Array in HIDDEN:
		_kit.call(&"add_prop_at", entities, entry[2], _cell(entry[0]), entry[1])
	_place_bush(entities)


## Arbuste de l'enclos (19, 37) : [FlagGate] `unless cut_celadon_gym_bush` dont le décor est le
## jeune arbre des arbustes du J16 (sans emprise), cases occupées tant qu'il est affiché.
func _place_bush(entities: Node2D) -> void:
	var cell := _cell("arbuste_enclos")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = BUSH_NODE
	gate.position = Vector2((cell.x + 0.5) * Kit.TILE, (cell.y + 1) * Kit.TILE).round()
	var unless: Array[StringName] = [BUSH_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var tree: Node2D = _kit.call(&"add_prop", gate, BUSH_ID, Vector2.ZERO, "Bush")
	tree.scale = Vector2(BUSH_SCALE, BUSH_SCALE)
	_kit.call(&"clear_footprint", tree)


## Roseaux et nénuphars de l'étang (dans l'eau, sans emprise).
func _place_pond_decor(entities: Node2D) -> void:
	var index := 0
	for cell: Vector2i in POND_REEDS:
		var reeds: Node2D = _kit.call(&"add_prop_at", entities, "prop_roseaux_01", cell,
			"Reeds%d" % index)
		_kit.call(&"clear_footprint", reeds)
		index += 1
	index = 0
	for cell: Vector2i in POND_LILIES:
		var lilies: Node2D = _kit.call(&"add_prop_at", entities, "prop_nenuphars_0%d" %
			(1 + index % 3), cell, "Lilies%d" % index)
		_kit.call(&"clear_footprint", lilies)
		index += 1
