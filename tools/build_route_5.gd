extends SceneTree
## Construit game/world/maps/route_5.tscn (Route 5, 42 × 62 cases) d'après la grille fonctionnelle
## `tools/plans/route_5.txt` v2 (jalon 15 T13 et T21, docs/tech/jalon-15.md §1.3, §2.1, §2.8 ;
## dossier 18 §3, §4.1, §7, §13.1).
##
##   godot --headless --path . -s res://tools/build_route_5.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-5-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** (dossier 18 §13.1) : Pension, petit bois et détour peints 2 à 3 cases trop haut,
## bande de forêt du bas trop épaisse ; bottes de foin et pommier hors du jardin (objets rares).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `D` `G` `E`
##   portes (praticables) ; tout le reste (forêt `T`, Pension `W`, poste `P`, entrée du souterrain
##   `U`, clôture `c`, jardin `j`) est solide.
## - Image : sol peint (chemin de terre), forêt serrée, Pension (série 17, toit rouge-brique), poste
##   de garde vers Safrania et bâtiment d'entrée du souterrain (série 17), jardin clos (clôture de
##   piquets blancs, pommier, plates-bandes, hortensias, fleurs), panneaux, tronc couché (indice de
##   l'Antidote caché), touffes et fleurs, hautes herbes jaune-vert.
## - Passages : bord nord (19..21, 0) PUSH ↑ → `cerulean_city` / `from_route_5_w|c|e` (T21 : raccord
##   réel, rangée pour colonne, décalage de 12 colonnes), arrivées `from_cerulean_w|c|e` ici
##   (tournées ↓ par la sortie d'Azuria) ; portes STEP_ON ↑ : Pension (27, 27) → `route_5_daycare`,
##   poste (34, 44) → `route_5_gate`, entrée du souterrain (11, 56) → `route_5_underground_gate` ;
##   spawns de sortie `from_daycare`, `from_gate`, `from_underground` (case au sud de la porte).
## - Vie : PNJ et objet visible dans `data/npcs/route_5.json` (cases de la grille réservées : la
##   forêt s'en écarte) ; panneaux et indice = points d'examen ; Antidote caché (`unless_flags`,
##   modèle `tools/build_route_24.gd`) ; déclencheur silencieux `route_5_arrival` sur (19..21, 1)
##   (pose `route_5_entered`, toute direction) ; rencontres : `data/encounters/route_5.json`.

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_5.txt"
const OUT_PATH: String = "res://game/world/maps/route_5.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_5_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_5.json"
const SIZE := Vector2i(42, 62)
const SEED: int = 501
const DECOR_SEED: int = 502
const FOREST_SEED: int = 503

const MAP_ID: StringName = &"route_5"
const DISPLAY_NAME: String = "Route 5"
## Sous-titre = zone `route_5` (annexe A.2 validée).
const REGION: String = "Azuria — Safrania"
const WALKABLE: String = ".=hDGE"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]

## Raccord nord (T21) : [nœud, case, spawn d'ici, spawn d'arrivée d'Azuria (31..33, 40)].
const NORTH_MAP: StringName = &"cerulean_city"
const NORTH_EXITS: Array = [
	["CeruleanW", Vector2i(19, 0), "from_cerulean_w", &"from_route_5_w"],
	["CeruleanC", Vector2i(20, 0), "from_cerulean_c", &"from_route_5_c"],
	["CeruleanE", Vector2i(21, 0), "from_cerulean_e", &"from_route_5_e"],
]
## Bâtiments : [position de la porte (grille), objet peint, nœud, carte intérieure, spawn de la
## carte intérieure, spawn de sortie d'ici (case au sud de la porte), nœud du passage].
const BUILDINGS: Array = [
	["pension_porte", "bldg_pension_01", "Daycare", &"route_5_daycare", &"entrance",
		"from_daycare", "DoorDaycare"],
	["poste_porte", "bldg_poste_safrania_01", "SaffronGate", &"route_5_gate", &"from_route_5",
		"from_gate", "DoorGate"],
	["souterrain_entree", "bldg_entree_souterrain_01", "UndergroundEntrance",
		&"route_5_underground_gate", &"from_route_5", "from_underground", "DoorUnderground"],
]
## Panneaux : [position, nœud du décor, dialogue, orientation exigée du joueur].
const SIGNS: Array = [
	["panneau_route", "SignRoute", &"route_5_sign", Vector2i.RIGHT],
	["panneau_pension", "SignDaycare", &"route_5_daycare_sign", Vector2i.DOWN],
	["panneau_carrefour", "SignCrossroads", &"route_5_crossroads_sign", Vector2i.RIGHT],
]
## Antidote caché (O2) : tronc couché d'une autre teinte (série 17) au pied du petit bois ;
## examiné de tous côtés (règle du J12) ; disparaît une fois l'objet pris.
const HIDDEN_ITEM: String = "route_5_hidden_1"
const HIDDEN_PROP: String = "prop_indice_tronc_01"
## Déclencheur silencieux de l'arrivée (§1.3 n° 5 [D]) : rangée 1, toute direction.
const ARRIVAL_ANCHOR := Vector2i(19, 1)
const ARRIVAL_SIZE := Vector2i(3, 1)
const ARRIVAL_CUTSCENE: StringName = &"route_5_arrival"

## Jardin clos de la Pension (clôture 31..37 × 22..31, fleurs 32..36 × 23..30) : clôture de
## piquets blancs (deux tronçons par côté nord et sud, trois par côté est et ouest, le troisième
## chevauche le deuxième d'une case), pommier, plates-bandes, hortensias.
## [objet, case d'ancrage, nœud].
const FENCE: Array = [
	["prop_cloture_piquets_01", Vector2i(33, 22), "FenceNorthW"],
	["prop_cloture_piquets_01_court", Vector2i(36, 22), "FenceNorthE"],
	["prop_cloture_piquets_v_01", Vector2i(31, 25), "FenceWestN"],
	["prop_cloture_piquets_v_01", Vector2i(31, 28), "FenceWestC"],
	["prop_cloture_piquets_v_01", Vector2i(31, 30), "FenceWestS"],
	["prop_cloture_piquets_v_01", Vector2i(37, 25), "FenceEastN"],
	["prop_cloture_piquets_v_01", Vector2i(37, 28), "FenceEastC"],
	["prop_cloture_piquets_v_01", Vector2i(37, 30), "FenceEastS"],
	["prop_cloture_piquets_01", Vector2i(33, 31), "FenceSouthW"],
	["prop_cloture_piquets_01_court", Vector2i(36, 31), "FenceSouthE"],
]
const GARDEN: Array = [
	["tree_fruitier_01_bourg", Vector2i(34, 25), "GardenTree"],
	["prop_platebande_01", Vector2i(33, 28), "GardenBedWest"],
	["prop_platebande_01", Vector2i(35, 30), "GardenBedEast"],
	["prop_hortensias_01", Vector2i(32, 23), "GardenHydrangeaNW"],
	["prop_hortensias_01", Vector2i(36, 24), "GardenHydrangeaNE"],
	["prop_hortensias_01", Vector2i(36, 27), "GardenHydrangeaE"],
	["prop_hortensias_01", Vector2i(32, 30), "GardenHydrangeaSW"],
]
const GARDEN_TREE_SCALE: float = 0.85
## Fleurs semées sur les cases du jardin (décalcomanies, une à deux par case).
const GARDEN_FLOWERS: Array[int] = [1, 2, 3, 5, 6]
const GARDEN_FLOWER_ATTEMPTS: int = 40
## Forêt « verdoyante » (mêmes valeurs que la Route 24).
const SHADE_VALUE: float = 1.0
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
## Prairie : touffes et fleurs (la vue en est semée).
const MEADOW_ATTEMPTS: int = 1100
const FLOWER_CHANCE: float = 0.38
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_5 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route5", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	# Seuils des portes du poste et de l'entrée : de la terre, comme le parvis.
	var paths: Dictionary = _kit.get(&"path_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "GE"):
		paths[cell] = true
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_5 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_examine_points()
	_kit.call(&"add_trigger", "Arrival", ARRIVAL_ANCHOR, ARRIVAL_SIZE, Vector2i.ZERO,
		ARRIVAL_CUTSCENE)

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, FLOWER_CHANCE, FLOWERS)
	for entry: Array in BUILDINGS:
		_kit.call(&"add_prop_at", entities, entry[1], _cell(entry[0]), entry[2])
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_kit.call(&"add_prop_at", entities, HIDDEN_PROP, _cell(HIDDEN_ITEM), "TrunkClue")
	_place_garden(entities, decals)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_5 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_5 : %s (%d entités, %d au sol, forêt %d → %d, %d nœuds)" % [
		error_string(result.x), counts.x, counts.y, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des PNJ et objets de la grille : réservées (la forêt s'en écarte).
func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if RESERVED_KINDS.has(kind):
			cells.append_array(positions[id]["cells"])
		if BALL_KINDS.has(kind):
			balls.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)
	_kit.set(&"reserved_balls", balls)


func _add_passages() -> void:
	for entry: Array in NORTH_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.UP, NORTH_MAP,
			entry[3], Vector2i.UP)
	for entry: Array in BUILDINGS:
		var door := _cell(entry[0])
		_kit.call(&"add_spawn", entry[5], door + Vector2i.DOWN)
		_kit.call(&"add_warp", entry[6], door, Kit.STEP_ON, Vector2i.UP, entry[3], entry[4],
			Vector2i.UP)


## Panneaux (EXAMINER de face) et tronc de l'Antidote caché (de tous côtés, `unless_flags`).
func _add_examine_points() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", String(entry[1]) + "Point", _cell(entry[0]), Vector2i.ONE,
			entry[3], entry[2])
	_kit.call(&"add_interactable", "HiddenAntidote", _cell(HIDDEN_ITEM), Vector2i.ONE,
		Vector2i.ZERO, StringName(HIDDEN_ITEM))
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [StringName("got_" + HIDDEN_ITEM)]
	point.set(&"unless_flags", unless)


## Jardin clos : clôture, pommier, plates-bandes, hortensias, fleurs semées (aucun Pokémon, F-4).
func _place_garden(entities: Node2D, decals: Node2D) -> void:
	for entry: Array in FENCE:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	for entry: Array in GARDEN:
		var prop: Node2D = _kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		_kit.call(&"flip", prop, decor.randf() < 0.5)
		if String(entry[0]).begins_with("tree_"):
			prop.scale = Vector2(GARDEN_TREE_SCALE, GARDEN_TREE_SCALE)
	var garden: Array[Vector2i] = _plan().call(&"cells_of", "j")
	for attempt: int in GARDEN_FLOWER_ATTEMPTS:
		var cell: Vector2i = garden[decor.randi_range(0, garden.size() - 1)]
		var foot := (Vector2(cell) + Vector2(decor.randf_range(0.15, 0.85),
			decor.randf_range(0.3, 0.95))) * Kit.TILE
		var flower: int = GARDEN_FLOWERS[decor.randi_range(0, GARDEN_FLOWERS.size() - 1)]
		_kit.call(&"decal", decals, Kit.FLOWER_DECAL % flower, foot, 1.0)
