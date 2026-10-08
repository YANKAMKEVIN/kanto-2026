extends SceneTree
## Construit game/world/maps/pewter_city.tscn (Argenta, 52 × 44 cases) d'après la grille
## fonctionnelle `tools/plans/argenta.txt` (jalon 10 T11, docs/tech/jalon-10.md §2.1 ; dossier 12
## §4–§9, §17).
##
##   godot --headless --path . -s res://tools/build_pewter_city.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/argenta-vue-generale-v1.png`) donne la DA : paroi de montagne au
## nord, Arène-forteresse dans les rochers (nord-est), place pavée au gros rocher, Musée à
## colonnes au sud-ouest contre l'avenue (visible dès le premier écran, arbitrage 10), enseigne
## Centre / Boutique de Jadielle, chantier du tailleur, bande de forêt vers la Route 2 nord ;
## ville minérale sans être aride (pas de hautes herbes, fleurs rares).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` chemin, `p` pavés ; tout le reste
##   (paroi, forêt, bâtiments toit compris, rocher, blocs, bancs, buissons, pieds d'arbres) est
##   solide ; les panneaux (positions `bloque` sur l'herbe) sont bloqués par leur emprise.
## - Image : sol peint (masque R = place pavée, G = chemins et pied de paroi), sous-bois sur la
##   forêt, paroi en modules (série 12), forêt serrée un peu plus sèche, arbres de la ville
##   (`G`, jamais deux fois le même côte à côte), Musée, Arène, Centre, Boutique, deux maisons
##   (une image, 40 colonnes d'écart), gros rocher de la place, blocs du tailleur, bancs,
##   buissons, panneaux, pots de fleurs et caisses contre le Centre et la Boutique (variation
##   du plan §1.4 A, sur leurs emprises).
## - Passages : trois warps PUSH ↓ vers la Route 2 nord (14..16, 0) ; sortie est (51, 25..27)
##   PUSH → « ROUTE 3 — À venir » (build de développement ; le garde la ferme avant le badge,
##   T14) ; portes STEP_ON ↑ du Musée, de l'Arène, du Centre, de la Boutique et des maisons vers
##   leurs intérieurs (T13) — **tant qu'un intérieur n'existe pas, sa porte est une destination
##   « à venir »** (retour devant la porte, tourné ↓) : relancer l'outil au T13.
## - Déclencheurs : arrivée silencieuse (17..19, 42) ↑ (`pewter_arrival`, pose `pewter_arrived`) ;
##   verrou de la Route 3 (48, 25..27), toute direction (`route_3_guard` : règle + recul).
## - Habitants, Racaillou, garde : `data/npcs/pewter_city.json`.

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/argenta.txt"
const OUT_PATH: String = "res://game/world/maps/pewter_city.tscn"
const MASK_PATH: String = "res://assets/world/maps/pewter_city_ground.png"
const NPCS_PATH: String = "res://data/npcs/pewter_city.json"
const SIZE := Vector2i(52, 44)
const SEED: int = 2111
const DECOR_SEED: int = 2112
const FOREST_SEED: int = 13
const PAROI_SEED: int = 2113

const MAP_ID: StringName = &"pewter_city"
const DISPLAY_NAME: String = "Argenta"
## Titre seul (arbitrage 10).
const REGION: String = ""

## Raccord sud (jalon-10 §2.1) : [nœud, case, spawn de la Route 2 nord, spawn d'ici].
const SOUTH_EXITS: Array = [
	["Route2NorthW", Vector2i(17, 43), &"from_pewter_w", "from_route_2_north_w"],
	["Route2NorthC", Vector2i(18, 43), &"from_pewter_c", "from_route_2_north_c"],
	["Route2NorthE", Vector2i(19, 43), &"from_pewter_e", "from_route_2_north_e"],
]
## Sortie est (51, 25..27) : « ROUTE 3 — À venir » ; retour sur la case même, tourné ←.
const EAST_EXITS: Array = [
	["Route3N", Vector2i(51, 25), "from_route_3_n"],
	["Route3C", Vector2i(51, 26), "from_route_3_c"],
	["Route3S", Vector2i(51, 27), "from_route_3_s"],
]
const ROUTE_3_SOON: String = "Route 3"

## Bâtiments : [objet, case d'ancrage, nom du nœud, position des portes dans la grille,
## intérieur, spawn d'ici (devant la porte, tourné ↓), libellé « à venir »].
const BUILDINGS: Array = [
	["bldg_musee_argenta_01", Vector2i(9, 39), "Museum", "porte_musee", &"pewter_museum",
		"from_museum", "Musée d'Argenta"],
	["bldg_arene_argenta_01", Vector2i(36, 11), "Gym", "porte_arene", &"pewter_gym",
		"from_gym", "Arène d'Argenta"],
	["bldg_centre_01", Vector2i(26, 39), "PokemonCenter", "porte_centre", &"pewter_center",
		"from_center", "Centre Pokémon"],
	["bldg_boutique_01", Vector2i(30, 31), "PokeMart", "porte_boutique", &"pewter_mart",
		"from_mart", "Boutique"],
	["bldg_maison_argenta_01", Vector2i(6, 20), "HouseMason", "porte_tailleur",
		&"pewter_house_mason", "from_house_mason", "Maison"],
	["bldg_maison_argenta_01", Vector2i(46, 20), "HouseResearcher", "porte_chercheuse",
		&"pewter_house_researcher", "from_house_researcher", "Maison"],
]
## Spawn devant une porte : colonne de la porte (la plus à l'est si elle en a deux).
const INTERIOR_SPAWN: StringName = &"entrance"

## Arbres de la ville (cases `G` de la grille) : [objet, échelle, miroir], dans l'ordre de
## lecture de la grille ; jamais deux fois le même côte à côte ; plus petits sur la place.
const TOWN_TREES: Dictionary = {
	Vector2i(22, 6): ["tree_b_01", 1.0, false],
	Vector2i(44, 8): ["tree_e_01", 0.9, true],
	Vector2i(25, 9): ["tree_c_01", 0.95, false],
	Vector2i(47, 11): ["tree_a_01", 1.0, true],
	Vector2i(15, 15): ["tree_a_01", 0.85, false],
	Vector2i(40, 15): ["tree_c_01", 0.8, true],
	Vector2i(15, 22): ["tree_c_01", 0.8, false],
	Vector2i(40, 22): ["tree_a_01", 0.85, true],
	Vector2i(24, 25): ["tree_a_01", 0.85, false],
	Vector2i(4, 27): ["tree_e_01", 0.95, false],
	Vector2i(10, 28): ["tree_b_01", 1.0, true],
	Vector2i(36, 30): ["tree_a_01", 0.95, false],
	Vector2i(44, 30): ["tree_c_01", 1.0, true],
	Vector2i(46, 35): ["tree_e_01", 0.95, true],
	Vector2i(40, 36): ["tree_b_01", 1.0, false],
	Vector2i(32, 38): ["tree_a_01", 0.95, true],
}
## Gros rocher de la place (3 × 3) et blocs du tailleur (3 × 2) : case d'ancrage.
const PLAZA_ROCK := Vector2i(26, 19)
const MASON_BLOCKS := Vector2i(4, 24)
## Bancs (`n`, une case) : l'image de 2 cases réduite, sans emprise (la grille bloque la case).
const BENCH_SCALE: float = 0.62
## Variations contre les façades du Centre et de la Boutique (sur leurs emprises, sans emprise
## propre, dessinées devant la façade) : [objet, pied (cases), miroir].
const FACADE_PROPS: Array = [
	["prop_pots_fleurs_01", Vector2(23.5, 40.0), false],
	["prop_pots_fleurs_01", Vector2(28.5, 40.0), true],
	["prop_caisses_01", Vector2(27.5, 32.0), false],
	["prop_pots_fleurs_01", Vector2(32.5, 32.0), true],
]
## Panneaux : [position de la grille, nœud, dialogue, orientation exigée]. « ARGENTA » se lit
## depuis l'avenue (17, 42) ← ou depuis l'herbe à l'ouest : de tous côtés.
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"pewter_city_sign", Vector2i.ZERO],
	["panneau_arene", "SignGym", &"pewter_gym_sign", Vector2i.UP],
	["panneau_musee", "SignMuseum", &"pewter_museum_sign", Vector2i.UP],
]
## Buissons des cases `x`.
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
## Pelouses : touffes et fleurs rares (« touches discrètes », dossier 12 §17).
const MEADOW_ATTEMPTS: int = 700
const MEADOW_FLOWER_CHANCE: float = 0.18
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_pewter_city : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"make_root", "PewterCity", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_pewter_city : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	var arrival: Array = _plan().call(&"cells_at", "arrivee")
	_kit.call(&"add_trigger", "PewterArrival", arrival[0], Vector2i(arrival.size(), 1),
		Vector2i.UP, &"pewter_arrival")
	var lock: Array = _plan().call(&"cells_at", "verrou_route_3")
	_kit.call(&"add_trigger", "Route3Guard", lock[-1], Vector2i(1, lock.size()), Vector2i.ZERO,
		&"route_3_guard")

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	_place_buildings(entities)
	_place_props(entities)
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, _tree_feet(), {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_pewter_city :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("pewter_city : %s (%d entités, %d au sol dont %d modules de paroi, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, modules, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


func _add_passages() -> void:
	for entry: Array in SOUTH_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.DOWN, &"route_2_north",
			entry[2], Vector2i.DOWN)
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, &"",
			StringName(entry[2]), Vector2i.LEFT, ROUTE_3_SOON)
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


func _place_buildings(entities: Node2D) -> void:
	for entry: Array in BUILDINGS:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
	_kit.call(&"add_prop_at", entities, "prop_rocher_place_01", PLAZA_ROCK, "PlazaRock")
	_kit.call(&"add_prop_at", entities, "prop_blocs_tailles_01", MASON_BLOCKS, "MasonBlocks")


## Pieds des arbres de la ville (cases) : la forêt serrée s'en écarte.
func _tree_feet() -> Array[Vector2]:
	var rules: GDScript = _kit.get(&"rules")
	var feet: Array[Vector2] = []
	for cell: Vector2i in TOWN_TREES:
		var spec: Array = TOWN_TREES[cell]
		feet.append((rules.call(&"foot_position", StringName(spec[0]), cell) as Vector2)
			/ float(Kit.TILE))
	return feet


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TOWN_TREES[cell]
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
	index = 0
	for entry: Array in FACADE_PROPS:
		var prop: Node2D = _kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * tile + Vector2(0.0, 1.0), "Facade%d" % index)
		index += 1
		_kit.call(&"flip", prop, entry[2])
		_kit.call(&"clear_footprint", prop)
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
