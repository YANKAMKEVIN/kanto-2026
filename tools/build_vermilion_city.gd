extends SceneTree
## Construit game/world/maps/vermilion_city.tscn (Carmin-sur-Mer, 64 × 43 cases, quai compris)
## d'après la grille fonctionnelle `tools/plans/vermilion_city.txt` (jalon 15 T14,
## docs/tech/jalon-15.md §2.1, §2.9, §2.11 ; dossier 18 §8, §13.1, §17). Les habitants (marin,
## dockers, habitante, enfant, vieil homme, Roucool) sont dans `data/npcs/vermilion_city.json`.
##
##   godot --headless --path . -s res://tools/build_vermilion_city.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/carmin-vue-generale-v1.png`)
## donne la DA, avec l'écart du §13.1 : le navire suit la grille (29 × 7, paquebot), pas le
## « ferry » court de la vue.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` rue de terre, `p` pavés, `q` `g`
##   planches du quai, des pontons et de la passerelle, `E` accès au navire (terminal),
##   `D` portes ; `W` mer et `N` coque = eau (jamais praticable) ; le reste solide. **Exception
##   (contrat du J16)** : les deux cases `A` du jeune arbre sont praticables dans `Ground` et
##   **occupées** par le décor de l'arbre ([FlagGate] `blocking_cells`) tant que
##   `cut_vermilion_gym_bush` n'est pas levé : coupé (J16), la porte de l'Arène s'ouvre.
## - Image : sol peint (pavés de la place, rues de terre), mer de Bourg Palette à angles droits
##   assombrie (bleu profond), platelage en rectangles répétés, bords de quai en bois (série 17),
##   bâtiments, **S.S. Anne en trois objets** sous une [FlagGate] (`unless ss_anne_departed`,
##   contrat du J16) avec la passerelle, bittes, cordage, caisses, grue, bancs, arbres, buissons.
## - Passages : nord (30..32, 0) PUSH ↑ → `route_6` / `from_vermilion_w|c|e` (arrivées ici
##   `from_route_6_w|c|e`) ; est (63, 11..13) PUSH → `route_11` / `from_vermilion_n|c|s` (T17 du J17 ; retour sur la case,
##   tourné ←) ; portes des sept bâtiments ; Arène et embarquement : « À venir », inatteignables
##   (arbre, marin et cordage).

const Kit := preload("res://tools/vermilion_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/vermilion_city.txt"
const OUT_PATH: String = "res://game/world/maps/vermilion_city.tscn"
const MASK_PATH: String = "res://assets/world/maps/vermilion_city_ground.png"
const NPCS_PATH: String = "res://data/npcs/vermilion_city.json"
const SIZE := Vector2i(64, 43)
const SEED: int = 2701
const DECOR_SEED: int = 2702
const QUAY_SEED: int = 2703
const FOREST_SEED: int = 2704

const MAP_ID: StringName = &"vermilion_city"
const DISPLAY_NAME: String = "Carmin-sur-Mer"
## Sous-titre du titre de zone (T-25).
const REGION: String = "Le port des grands départs"
## Praticables de la grille, plus le jeune arbre (`A`, bloqué par son décor, contrat du J16).
const WALKABLE_MARKS: String = ".=pqgEDA"
const SUFFIXES: Array[String] = ["w", "c", "e"]
const EAST_SUFFIXES: Array[String] = ["n", "c", "s"]

## Drapeaux du contrat du J16 (dossier 18 §17, plan §2.9 ; noms à confirmer avec le J16).
const SHIP_FLAG: StringName = &"ss_anne_departed"
const BUSH_FLAG: StringName = &"cut_vermilion_gym_bush"

## Bâtiments : [objet, position des portes dans la grille, nœud, intérieur, spawn d'ici (devant
## la porte), libellé « à venir » (vide = intérieur construit)].
const BUILDINGS: Array = [
	["bldg_maison_argenta_01", "porte_maison_1", "House1", &"vermilion_house_1",
		"from_house_1", ""],
	["bldg_fan_club_01", "porte_fan_club", "FanClub", &"vermilion_fan_club", "from_fan_club", ""],
	["bldg_centre_01", "porte_centre", "PokemonCenter", &"vermilion_center", "from_center", ""],
	["bldg_boutique_01", "porte_boutique", "PokeMart", &"vermilion_mart", "from_mart", ""],
	["bldg_arene_carmin_01", "porte_arene", "Gym", &"", "from_gym",
		"Arène de Carmin-sur-Mer"],
	["bldg_maison_pecheur_01", "porte_pecheur", "FisherHouse", &"vermilion_fisher_house",
		"from_fisher_house", ""],
	["bldg_maison_argenta_01", "porte_maison_2", "House2", &"vermilion_house_2",
		"from_house_2", ""],
]
const INTERIOR_SPAWN: StringName = &"entrance"
## Panneaux : [position de la grille, nœud, dialogue, orientation exigée].
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"vermilion_city_sign", Vector2i.LEFT],
	["panneau_arene", "SignGym", &"vermilion_gym_sign", Vector2i.UP],
	["panneau_quai", "SignDock", &"vermilion_dock_sign", Vector2i.UP],
]
## Arbres repères (cases `G`), dans l'ordre de la grille : [objet, échelle, miroir].
const TREES: Array = [
	["tree_c_01", 0.8, false], ["tree_a_01", 0.75, true], ["tree_b_01", 0.75, false],
	["tree_c_01", 0.8, true], ["tree_e_01", 0.7, false], ["tree_c_01", 0.8, true],
	["tree_a_01", 0.8, false], ["tree_b_01", 0.8, true], ["tree_c_01", 0.85, false],
	["tree_e_01", 0.7, true],
]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const BENCH_SCALE: float = 0.62
## S.S. Anne : trois tranches (10, 9, 10 cases) sur les colonnes 21..30, 31..39, 40..49, pied au
## bas de la rangée 34 (ligne de flottaison, fiche série 17 « Alignement »).
const SHIP_SLICES: Array = [
	["bldg_ss_anne_proue_01", 21, 10], ["bldg_ss_anne_milieu_01", 31, 9],
	["bldg_ss_anne_poupe_01", 40, 10],
]
const SHIP_FOOT_ROW: int = 35
## Passerelle (31..32, 27) : pied (cases), au bord du pont du navire.
const GANGWAY_FOOT := Vector2(32.0, 30.4)
## Bittes décoratives au bord du quai (dans l'eau, rangée 27) : colonnes.
const EDGE_BOLLARDS: Array[int] = [5, 15, 20, 27, 37, 41, 49, 59]
## Cordages lovés sur le quai (décor traversable) : pieds en cases.
const ROPES: Array[Vector2] = [Vector2(33.5, 25.8), Vector2(11.4, 24.7), Vector2(53.3, 25.7)]
## Grue du port sur la paire de caisses de la rangée 24 (fiche : à juger sur capture).
const CRANE_CELL := Vector2i(58, 24)
## Colonnes de la rangée 42 peintes comme la mer (entre les falaises de l'ouest et de l'est).
const SEA_EDGE_COLUMNS := Vector2i(2, 61)
const SHADE_VALUE: float = 0.98
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
const MEADOW_ATTEMPTS: int = 700
const MEADOW_FLOWER_CHANCE: float = 0.35
const FLOWERS: Array[int] = [1, 3, 5]
## Départs de débogage : place, quai devant le marin, devant l'Arène.
const DEBUG_SPAWNS: Array = [
	["square", Vector2i(31, 18)], ["dock", Vector2i(31, 24)], ["gym_front", Vector2i(48, 11)],
]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_vermilion_city : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE_MARKS, "", "")
	_kit.set(&"sea", true)
	var wood: Dictionary = {}
	for mark: String in ["q", "g", "k", "z"]:
		wood[mark] = Kit.WOOD_PIECES
	_kit.set(&"quay_sets", wood)
	_reserve_positions()
	_kit.call(&"make_root", "VermilionCity", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_open_sea_edge()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth()):
		print("build_vermilion_city : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	var tints: int = _kit.call(&"place_sea_tint")
	var planks: int = _kit.call(&"place_planks")
	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var quays: int = _kit.call(&"place_quays")
	_place_ship(entities, decals)
	_place_buildings(entities)
	_place_props(entities)
	var taken := _taken_by_buildings()
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, _tree_feet(), taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_vermilion_city :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("vermilion_city : %s (%d entités, %d au sol dont %d aplats de mer, %d platelages, "
		% [error_string(result.x), counts.x, counts.y, tints, planks]
		+ "%d bords de quai ; forêt %d → %d ; %d nœuds)" % [quays, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] in ["pnj", "pokemon"]:
			cells.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)


## Bord sud de la carte (rangée 42, `T` de la grille entre deux colonnes de falaise) : **peint
## comme la mer** (la vue générale ouvre le port sur le large ; un rideau d'arbres au sud
## fermait le bassin comme une piscine). La case reste solide (`Ground` inchangé : la grille fait
## foi), seule l'image change : ni arbre, ni bord de quai.
func _open_sea_edge() -> void:
	var water: Dictionary = _kit.get(&"water_cells")
	var forest: Dictionary = _kit.get(&"forest_cells")
	for x: int in range(SEA_EDGE_COLUMNS.x, SEA_EDGE_COLUMNS.y + 1):
		var cell := Vector2i(x, SIZE.y - 1)
		water[cell] = true
		forest.erase(cell)


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	var north: Array = _plan().call(&"cells_at", "warp_nord")
	for i: int in north.size():
		_kit.call(&"add_warp", "Route6" + SUFFIXES[i].to_upper(), north[i], Kit.PUSH,
			Vector2i.UP, &"route_6", StringName("from_vermilion_" + SUFFIXES[i]), Vector2i.UP)
		_kit.call(&"add_spawn", "from_route_6_" + SUFFIXES[i], north[i])
	var east: Array = _plan().call(&"cells_at", "warp_est")
	for i: int in east.size():
		# Jalon 17 (T17) : le bord est mène à la vraie Route 11, rangée pour rangée (0, 11..13),
		# tourné vers l'est ; retour sur `from_route_11_n|c|s`, tourné vers l'ouest.
		_kit.call(&"add_warp", "Route11" + EAST_SUFFIXES[i].to_upper(), east[i], Kit.PUSH,
			Vector2i.RIGHT, &"route_11", StringName("from_vermilion_" + EAST_SUFFIXES[i]),
			Vector2i.RIGHT)
		_kit.call(&"add_spawn", "from_route_11_" + EAST_SUFFIXES[i], east[i])
	for entry: Array in BUILDINGS:
		var doors: Array = _plan().call(&"cells_at", entry[1])
		var front: Vector2i = (doors[-1] as Vector2i) + Vector2i.DOWN
		_kit.call(&"add_spawn", entry[4], front)
		var index := 0
		for door: Vector2i in doors:
			var node := "Door%s%s" % [entry[2], "" if doors.size() == 1 else ["W", "E"][index]]
			index += 1
			if String(entry[5]).is_empty():
				_kit.call(&"add_warp", node, door, Kit.STEP_ON, Vector2i.UP, entry[3],
					INTERIOR_SPAWN, Vector2i.ZERO)
			else:
				_kit.call(&"add_warp", node, door, Kit.STEP_ON, Vector2i.UP, &"",
					StringName(entry[4]), Vector2i.DOWN, entry[5])
	# Embarquement (futur J16) : inatteignable tant que le marin et le cordage gardent la
	# passerelle ; retour sur la passerelle, tourné ↑.
	var boarding: Array = _plan().call(&"cells_at", "embarquement")
	for i: int in boarding.size():
		var cell: Vector2i = boarding[i]
		var spawn: String = "from_ss_anne_" + SUFFIXES[i * 2]
		_kit.call(&"add_spawn", spawn, cell + Vector2i.UP)
		_kit.call(&"add_warp", "Boarding" + SUFFIXES[i * 2].to_upper(), cell, Kit.STEP_ON,
			Vector2i.DOWN, &"", StringName(spawn), Vector2i.UP, "S.S. Anne")
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Panneaux, examen du jeune arbre (retiré avec l'arbre), arrivée à Carmin (`vermilion_reached`).
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	var tree := _box("examen_arbre")
	_kit.call(&"add_interactable", "GymTreeExamine", tree[0], tree[1], Vector2i.UP,
		&"vermilion_gym_tree")
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [BUSH_FLAG]
	point.set(&"unless_flags", unless)
	var arrival: Array = _plan().call(&"cells_at", "warp_nord")
	_kit.call(&"add_trigger", "Arrival", (arrival[0] as Vector2i) + Vector2i.DOWN,
		Vector2i(arrival.size(), 1), Vector2i.ZERO, &"vermilion_arrival")


## Rectangle d'une position de la grille : [ancre (bas-gauche), taille].
func _box(id: String) -> Array:
	var low := Vector2i(1 << 20, -1)
	var high := Vector2i(-1, 1 << 20)
	for cell: Vector2i in _plan().call(&"cells_at", id):
		low = Vector2i(mini(low.x, cell.x), maxi(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), mini(high.y, cell.y))
	return [low, Vector2i(high.x - low.x + 1, low.y - high.y + 1)]


## Ancre d'un bâtiment = case de porte de droite (largeur paire : pied sur le bord) ou unique.
func _anchor(entry: Array) -> Vector2i:
	var doors: Array = _plan().call(&"cells_at", entry[1])
	return doors[-1]


func _place_buildings(entities: Node2D) -> void:
	for entry: Array in BUILDINGS:
		_kit.call(&"add_prop_at", entities, entry[0], _anchor(entry), entry[2])


func _taken_by_buildings() -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	for entry: Array in BUILDINGS:
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[_anchor(entry) + offset] = true
	return taken


func _tree_feet() -> Array[Vector2]:
	var feet: Array[Vector2] = []
	var rules: GDScript = _kit.get(&"rules")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TREES[index % TREES.size()]
		index += 1
		feet.append((rules.call(&"foot_position", StringName(spec[0]), cell) as Vector2)
			/ float(Kit.TILE))
	return feet


## Le S.S. Anne (trois objets séparés) et sa passerelle, chacun sous une [FlagGate]
## `unless ss_anne_departed` (contrat du J16) : le navire dans `Entities` (pied à la ligne de
## flottaison, rien ne passe au sud), la passerelle à plat dans `GroundDecals`.
func _place_ship(entities: Node2D, decals: Node2D) -> void:
	var tile := float(Kit.TILE)
	var ship := _gate(entities, "SsAnne", Vector2(35.5 * tile, SHIP_FOOT_ROW * tile))
	for entry: Array in SHIP_SLICES:
		var centre := (float(entry[1]) + float(entry[2]) / 2.0) * tile
		var slice: Node2D = _kit.call(&"add_prop", ship, entry[0],
			Vector2(centre, SHIP_FOOT_ROW * tile) - ship.position, String(entry[0]).trim_prefix(
				"bldg_").to_pascal_case())
		_kit.call(&"clear_footprint", slice)
	var gangway := _gate(decals, "Gangway", GANGWAY_FOOT * tile)
	_kit.call(&"add_prop", gangway, "prop_passerelle_01", Vector2.ZERO, "Passerelle")


func _gate(parent: Node2D, node_name: String, foot: Vector2) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = node_name
	gate.position = foot.round()
	var unless: Array[StringName] = [SHIP_FLAG]
	gate.set(&"unless_flags", unless)
	_kit.call(&"attach", parent, gate)
	return gate


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TREES[index % TREES.size()]
		var tree: Node2D = _kit.call(&"add_prop_at", entities, spec[0], cell, "Tree%02d" % index)
		index += 1
		tree.scale = Vector2(spec[1], spec[1])
		_kit.call(&"flip", tree, spec[2])
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		var bench: Node2D = _kit.call(&"add_prop", entities, "prop_banc_01",
			Vector2(cell.x + 0.5, cell.y + 1.0) * tile, "Bench%d" % index)
		index += 1
		bench.scale = Vector2(BENCH_SCALE, BENCH_SCALE)
		_kit.call(&"clear_footprint", bench)
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var bush: Node2D = _kit.call(&"add_prop_at", entities, BUSH_IDS[index % BUSH_IDS.size()],
			cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	# Jeune arbre de l'Arène (contrat du J16) : objet séparé, retiré par `cut_vermilion_gym_bush`
	# avec ses deux cases (occupées tant qu'il est affiché).
	var bush_cells: Array = _plan().call(&"cells_at", "examen_arbre")
	var rules: GDScript = _kit.get(&"rules")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "GymTree"
	gate.position = (rules.call(&"foot_position", &"prop_jeune_arbre_arene_01",
		bush_cells[-1]) as Vector2).round()
	var unless: Array[StringName] = [BUSH_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(bush_cells)
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var young: Node2D = _kit.call(&"add_prop", gate, "prop_jeune_arbre_arene_01", Vector2.ZERO,
		"YoungTree")
	_kit.call(&"clear_footprint", young)
	# Port : caisses (cases `k` de la rangée 26), grue (rangée 24), bitte et cordage de la
	# passerelle, bittes des bouts de pontons, bittes de bord de quai (dans l'eau), cordages.
	for cell: Vector2i in [Vector2i(24, 26), Vector2i(45, 26)]:
		_kit.call(&"add_prop_at", entities, "prop_caisses_port_01", cell,
			"Crates%d" % cell.x)
	_kit.call(&"add_prop_at", entities, "prop_grue_quai_01", CRANE_CELL, "Crane")
	_kit.call(&"add_prop_at", entities, "prop_bitte_amarre_01", _cell("cordage_passerelle"),
		"MooringPost")
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "z"):
		if cell == _cell("cordage_passerelle"):
			continue
		_kit.call(&"add_prop_at", entities, "prop_bitte_01", cell, "PierBollard%d" % index)
		index += 1
	index = 0
	for column: int in EDGE_BOLLARDS:
		var bollard: Node2D = _kit.call(&"add_prop", entities, "prop_bitte_01",
			Vector2(column * tile + tile / 2.0, 27.0 * tile + 14.0), "EdgeBollard%d" % index)
		_kit.call(&"clear_footprint", bollard)
		index += 1
	index = 0
	for foot: Vector2 in ROPES:
		_kit.call(&"add_prop", entities, "prop_cordage_01", foot * tile, "Rope%d" % index)
		index += 1
