extends SceneTree
## Construit game/world/maps/route_6.tscn (Route 6, 42 × 56 cases) d'après la grille fonctionnelle
## `tools/plans/route_6.txt` (jalon 15 T14, docs/tech/jalon-15.md §2.1, §2.4, §2.8 ; dossier 18
## §6, §7, §13.1). La vie (six Dresseurs, garde, pêcheur, promeneur, Poké Ball, Pokémon
## d'ambiance) est dans `data/npcs/route_6.json` ; la forêt s'écarte de leurs cases.
##
##   godot --headless --path . -s res://tools/build_route_6.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/route-6-vue-generale-v1.png`)
## donne la DA, avec l'écart du dossier §13.1 : **un peu d'air marin dans la lisière** (herbes
## de dune et galets au sud, sur l'approche de Carmin). Étang = eau claire de canal à angles
## droits, berges naturelles (`relief_berge_*`, comme la Route 24), roseaux, nénuphars.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `D` porte ;
##   `W` = eau (jamais praticable) ; le reste (forêt, bâtiments, rochers, arbres, buissons,
##   clôture) est solide.
## - Passages : porte du bâtiment de sortie du souterrain (7, 4) STEP_ON ↑ →
##   `route_6_underground_gate` / `from_route_6` (arrivée ici `from_underground` (7, 5), tournée
##   ↓) ; bord sud (25..27, 55) PUSH ↓ → `vermilion_city` / `from_route_6_w|c|e` (arrivées ici
##   `from_vermilion_w|c|e`, tournées ↑) ; porte du poste vers Safrania (36, 7) : `saffron_city` /
##   `from_gate_r6` depuis le J26 (T6 ; « Safrania — À venir » tant que la ville n'existe pas),
##   gardée tant que les postes sont fermés ; arrivée depuis la ville `from_saffron` (36, 8).
## - Garde (T-17, §2.4) : trois déclencheurs sur `verrou_safrania` (réplique puis recul d'une case,
##   à l'opposé du garde).

const Kit := preload("res://tools/vermilion_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_6.txt"
const OUT_PATH: String = "res://game/world/maps/route_6.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_6_ground.png"
const SIZE := Vector2i(42, 56)
const SEED: int = 2601
const DECOR_SEED: int = 2602
const QUAY_SEED: int = 2603
const FOREST_SEED: int = 2604

const MAP_ID: StringName = &"route_6"
const DISPLAY_NAME: String = "Route 6"
## Sous-titre (zone `route_6`, annexe A.2).
const REGION: String = "Safrania — Carmin-sur-Mer"
const NPCS_PATH: String = "res://data/npcs/route_6.json"

const GATE_ROOM: StringName = &"route_6_underground_gate"
const SOUTH_MAP: StringName = &"vermilion_city"
## Safrania (J26 T6) : la porte du poste (36, 7) y mène ; arrivée depuis la ville devant la porte.
const SAFFRON_MAP: StringName = &"saffron_city"
const SAFFRON_ARRIVAL := Vector2i(36, 8)
const SUFFIXES: Array[String] = ["w", "c", "e"]

## Berges naturelles (série 15) : pour tout sol de la Route 6.
const BANK_MARKS: Array[String] = [".", "=", "T", "x", "h", "G", "R", "c"]
const BANKS: Dictionary[StringName, Dictionary] = {
	&"n": {"ids": ["relief_berge_01", "relief_berge_02"], "flip_h": false, "flip_v": false},
	&"s": {"ids": ["relief_berge_03"], "flip_h": false, "flip_v": false},
	&"w": {"ids": ["relief_berge_04"], "flip_h": false, "flip_v": false},
	&"e": {"ids": ["relief_berge_04"], "flip_h": true, "flip_v": false},
	&"nw": {"ids": ["relief_berge_05"], "flip_h": false, "flip_v": false},
	&"ne": {"ids": ["relief_berge_05"], "flip_h": true, "flip_v": false},
	&"sw": {"ids": ["relief_berge_05"], "flip_h": false, "flip_v": true},
	&"se": {"ids": ["relief_berge_05"], "flip_h": true, "flip_v": true},
}
## Arbres repères (cases `G`) : [objet, échelle, miroir].
const TREES: Dictionary = {
	Vector2i(29, 12): ["tree_b_01", 0.85, false],
	Vector2i(38, 12): ["tree_c_01", 0.9, true],
	Vector2i(38, 22): ["tree_e_01", 0.8, false],
	Vector2i(10, 26): ["tree_a_01", 0.9, true],
	Vector2i(37, 38): ["tree_c_01", 0.85, false],
}
## Rochers (cases `R`, deux blocs de 2 × 2) : un `prop_rocher_01` (2 × 1) par rangée.
const ROCKS: Array[Vector2i] = [Vector2i(31, 20), Vector2i(31, 21), Vector2i(11, 21),
	Vector2i(11, 22)]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Roseaux et nénuphars de l'étang (cases d'eau, x 12..21, y 28..37).
const REEDS: Array[Vector2i] = [Vector2i(12, 28), Vector2i(21, 30), Vector2i(12, 35),
	Vector2i(20, 37), Vector2i(16, 37)]
const LILIES: Array = [
	["prop_nenuphars_01", Vector2(14.4, 30.6)], ["prop_nenuphars_02", Vector2(15.2, 31.1)],
	["prop_nenuphars_01", Vector2(18.6, 33.7)], ["prop_nenuphars_03", Vector2(17.9, 34.3)],
	["prop_nenuphars_02", Vector2(13.6, 35.2)],
]
## Indice de l'objet caché (joncs couchés, rive ouest) : position `cache` de la grille.
const HIDDEN_CELL_ID: String = "route_6_hidden_1"
const HIDDEN_ID: StringName = &"route_6_hidden_1"
## Garde de Safrania : [nœud, case, scène] (recul à l'opposé du garde).
const GUARD_TRIGGERS: Array = [
	["SaffronGuardWest", Vector2i(35, 8), Vector2i.ONE, &"route_6_gate_rule_w"],
	["SaffronGuardEast", Vector2i(37, 8), Vector2i.ONE, &"route_6_gate_rule_e"],
	["SaffronGuardSouth", Vector2i(35, 9), Vector2i(3, 1), &"route_6_gate_rule_s"],
]
## Panneaux : [position de la grille, nœud, dialogue, orientation exigée] (§0.2 n° 7, A.3).
const SIGNS: Array = [
	["panneau_route", "SignRoute", &"route_6_sign", Vector2i.LEFT],
	["panneau_poste", "SignGate", &"route_6_gate_sign", Vector2i.UP],
]
## « Air marin » (dossier §13.1) : herbes de dune et galets sur la lisière de l'approche sud,
## cases praticables d'herbe rase (décor traversable) ; pieds en cases.
const SEA_AIR: Array = [
	["prop_herbes_dune_01", Vector2(20.5, 47.9)], ["prop_herbes_dune_01", Vector2(23.4, 52.8)],
	["prop_herbes_dune_01", Vector2(31.6, 47.7)], ["prop_herbes_dune_01", Vector2(34.4, 51.9)],
	["prop_herbes_dune_01", Vector2(22.6, 54.9)], ["prop_pierres_01", Vector2(30.5, 53.9)],
	["prop_herbes_dune_01", Vector2(33.5, 41.8)], ["prop_pierres_01", Vector2(39.5, 45.9)],
]
## Vue lointaine du port (belvédère (37, 46)) : pied (cases) au-dessus de la forêt du sud-est.
const PORT_VIEW_FOOT := Vector2(38.0, 50.0)
## Brume du lointain (bleuté, un peu transparent) : le port se lit au loin, pas dans la forêt.
const PORT_VIEW_HAZE := Color(0.82, 0.9, 1.0, 0.82)
## Départs de débogage : place de la sortie, étang, belvédère.
const DEBUG_SPAWNS: Array = [
	["exit_square", Vector2i(7, 7)], ["pond", Vector2i(26, 33)],
	["belvedere", Vector2i(34, 44)],
]
const WALKABLE: String = ".=hD"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const SHADE_VALUE: float = 1.0
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
const MEADOW_ATTEMPTS: int = 650
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_6 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	var sets: Dictionary = {}
	for mark: String in BANK_MARKS:
		sets[mark] = BANKS
	_kit.set(&"quay_sets", sets)
	_reserve_positions()
	_kit.call(&"make_root", "Route6", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth()):
		print("build_route_6 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var banks: int = _kit.call(&"place_quays")
	_place_water_decor(entities, decals)
	var taken := _place_buildings(entities)
	_place_props(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var rules: GDScript = _kit.get(&"rules")
	for cell: Vector2i in TREES:
		feet.append((rules.call(&"foot_position", StringName(TREES[cell][0]), cell) as Vector2)
			/ float(Kit.TILE))
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_6 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_6 : %s (%d entités, %d au sol dont %d modules de berge, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, banks, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des positions de la grille (Dresseurs, PNJ, objets, Pokémon) : réservées.
func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if RESERVED_KINDS.has(kind):
			cells.append_array(positions[id]["cells"])
		if kind == "objet_visible" or kind == "cache":
			balls.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)
	_kit.set(&"reserved_balls", balls)


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	var door := _cell("warp_souterrain")
	var built := ResourceLoader.exists("res://game/world/maps/%s.tscn" % GATE_ROOM)
	if built:
		_kit.call(&"add_warp", "DoorUnderground", door, Kit.STEP_ON, Vector2i.UP, GATE_ROOM,
			&"from_route_6", Vector2i.ZERO)
	else:
		_kit.call(&"add_warp", "DoorUnderground", door, Kit.STEP_ON, Vector2i.UP, &"",
			&"from_underground", Vector2i.DOWN, "Passage souterrain")
	_kit.call(&"add_spawn", "from_underground", _cell("from_souterrain"))
	var south: Array = _plan().call(&"cells_at", "warp_sud")
	for i: int in south.size():
		_kit.call(&"add_warp", "Vermilion" + SUFFIXES[i].to_upper(), south[i], Kit.PUSH,
			Vector2i.DOWN, SOUTH_MAP, StringName("from_route_6_" + SUFFIXES[i]), Vector2i.DOWN)
		_kit.call(&"add_spawn", "from_vermilion_" + SUFFIXES[i], south[i])
	# J26 (T6) : la porte du poste mène à Safrania (`from_gate_r6`, tournée ↑) dès que la ville
	# existe ; elle ne s'atteint que `if [saffron_gates_open]` (le garde, devant elle en (36, 8),
	# s'écarte alors en (35, 8) ; les règles de recul restent `unless [saffron_gates_open]`).
	# Arrivée depuis la ville : `from_saffron` (36, 8), tournée ↓ (case libérée par le garde).
	if ResourceLoader.exists("res://game/world/maps/%s.tscn" % SAFFRON_MAP):
		_kit.call(&"add_warp", "DoorSaffron", _cell("porte_safrania"), Kit.STEP_ON, Vector2i.UP,
			SAFFRON_MAP, &"from_gate_r6", Vector2i.UP)
	else:
		_kit.call(&"add_warp", "DoorSaffron", _cell("porte_safrania"), Kit.STEP_ON, Vector2i.UP,
			&"", &"from_underground", Vector2i.DOWN, "Safrania")
	_kit.call(&"add_spawn", "from_saffron", SAFFRON_ARRIVAL)
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Panneaux, garde, objet caché (`InteractPoint` + `unless_flags`, modèle du J12).
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	for entry: Array in GUARD_TRIGGERS:
		_kit.call(&"add_trigger", entry[0], entry[1], entry[2], Vector2i.ZERO, entry[3])
	_kit.call(&"add_interactable", "HiddenSuperPotion", _cell(HIDDEN_CELL_ID), Vector2i.ONE,
		Vector2i.ZERO, HIDDEN_ID)
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [StringName("got_" + String(HIDDEN_ID))]
	point.set(&"unless_flags", unless)


## Bâtiment de sortie du souterrain et poste vers Safrania, sur les emprises `U` / `P` (porte au
## milieu de la rangée du bas). Renvoie les cases de forêt qu'ils couvrent (aucun arbre dessous).
func _place_buildings(entities: Node2D) -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	for entry: Array in [["bldg_entree_souterrain_01", _cell("warp_souterrain"), "UndergroundExit"],
			["bldg_poste_safrania_01", _cell("porte_safrania"), "SaffronGate"]]:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	return taken


func _place_props(entities: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TREES[cell]
		var tree: Node2D = _kit.call(&"add_prop_at", entities, spec[0], cell, "Tree%02d" % index)
		index += 1
		tree.scale = Vector2(spec[1], spec[1])
		_kit.call(&"flip", tree, spec[2])
	index = 0
	for cell: Vector2i in ROCKS:
		var rock: Node2D = _kit.call(&"add_prop_at", entities, "prop_rocher_01", cell,
			"Rock%d" % index)
		_kit.call(&"flip", rock, index % 2 == 1)
		index += 1
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	# Clôture basse (30..34, 52) : une clôture de 4 et un poteau court.
	_kit.call(&"add_prop_at", entities, "prop_cloture_01", Vector2i(32, 52), "Fence")
	_kit.call(&"add_prop_at", entities, "prop_cloture_courte_01", Vector2i(34, 52), "FenceEnd")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var bush: Node2D = _kit.call(&"add_prop_at", entities, BUSH_IDS[index % BUSH_IDS.size()],
			cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		bush.modulate = tint
	# Indice de l'objet caché : joncs jaunis couchés (case bloquée de la grille).
	_kit.call(&"add_prop_at", entities, "prop_indice_joncs_01", _cell(HIDDEN_CELL_ID),
		"HiddenClue1")
	for entry: Array in SEA_AIR:
		var foot: Vector2 = (entry[1] as Vector2) * float(Kit.TILE)
		var tuft: Node2D = _kit.call(&"add_prop", entities, entry[0], foot,
			"SeaAir%d" % index)
		index += 1
		_kit.call(&"flip", tuft, decor.randf() < 0.5)
	# Au-dessus de la cime des arbres (fiche série 17) : personne ne passe au sud du belvédère.
	var view: Node2D = _kit.call(&"add_prop", entities, "prop_vue_port_01",
		PORT_VIEW_FOOT * float(Kit.TILE), "PortView")
	view.z_index = 1
	view.modulate = PORT_VIEW_HAZE


## Étang : roseaux (cases d'eau, déjà solides) et nénuphars à plat (couche du sol).
func _place_water_decor(entities: Node2D, decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in REEDS:
		var reed: Node2D = _kit.call(&"add_prop_at", entities, "prop_roseaux_01", cell,
			"Reeds%02d" % index)
		_kit.call(&"clear_footprint", reed)
		_kit.call(&"flip", reed, decor.randf() < 0.5)
		index += 1
	index = 0
	for entry: Array in LILIES:
		_kit.call(&"add_prop", decals, entry[0], (entry[1] as Vector2) * float(Kit.TILE),
			"Lilies%d" % index)
		index += 1
