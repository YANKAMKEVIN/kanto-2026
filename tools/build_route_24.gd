extends SceneTree
## Construit game/world/maps/route_24.tscn (Route 24, 56 × 62 cases : le Pont Pépite) d'après la
## grille fonctionnelle `tools/plans/route_24.txt` (jalon 13 T8, docs/tech/jalon-13.md §2.1,
## §2.3, §2.14 ; dossier 16 §7, §8, §11 à §13). Sans PNJ ni objet ni donnée : **les cases du rival,
## d'Ondine, des cinq Dresseurs, du recruteur, des objets et des herbes sont réservées** d'après
## les positions de la grille (la forêt s'en écarte) ; T17 / T19 / T22 les peuplent.
##
##   godot --headless --path . -s res://tools/build_route_24.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/route-24-vue-generale-v1.png`)
## donne la DA, avec l'écart déjà noté (série 15) : berges **naturelles** (talus de terre, herbe,
## galets, roseaux : `relief_berge_01..05`), pas la margelle de pierre de la vue ; seul le pied du
## pont (la place pavée, cases `p`) est bordé de quais de pierre (`relief_quai_*`).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `p` pavés,
##   `B` tablier (`BOARDWALK`, praticable), `e` raccord est ; `w` = eau (jamais praticable) ; le
##   reste (forêt, arbres repères, buissons, banc) est solide.
## - Image : sol peint (eau claire de canal à angles droits dans la passe du sol : aucun nœud par
##   case, aucune écume ; pavés de la place ; chemin), berges et quais en modules (`place_quays`
##   avec la table des berges pour tout sol sauf les pavés), Pont Pépite : tablier de 2 cases sur
##   25 rangées, **cinq modules** de 5 rangées qui alternent `tablier_01..03` (pas 25 rangées
##   identiques), piles au bord de l'eau, forêt serrée, arbres repères, buissons, banc, panneau,
##   roseaux, touffes, hautes herbes.
## - Passages : sortie sud (31..33, 61) PUSH ↓ → `cerulean_city` / `from_route_24_w|c|e` (tournée ↑) ;
##   spawns `from_cerulean_w|c|e` ici ; raccord est (55, 6..8) PUSH → « ROUTE 25 — À venir »
##   (développement ; bord bloqué en release), retour sur `from_route_25_n|c|s`, tourné ←.

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_24.txt"
const OUT_PATH: String = "res://game/world/maps/route_24.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_24_ground.png"
const SIZE := Vector2i(56, 62)
const SEED: int = 2501
const DECOR_SEED: int = 2502
const QUAY_SEED: int = 2503
const FOREST_SEED: int = 2504

const MAP_ID: StringName = &"route_24"
const DISPLAY_NAME: String = "Route 24"
## Sous-titre porté par la carte (zone `route_24`, §21 n° 56).
const REGION: String = "Le Pont Pépite"
const WALKABLE: String = ".=hpBe"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]

## Sortie sud : [nœud, case, spawn d'ici, spawn d'arrivée d'Azuria].
const SOUTH_MAP: StringName = &"cerulean_city"
const SOUTH_EXITS: Array = [
	["CeruleanW", Vector2i(31, 61), "from_cerulean_w", &"from_route_24_w"],
	["CeruleanC", Vector2i(32, 61), "from_cerulean_c", &"from_route_24_c"],
	["CeruleanE", Vector2i(33, 61), "from_cerulean_e", &"from_route_24_e"],
]
## Raccord est : [nœud, case, spawn de retour].
const EAST_EXITS: Array = [
	["Route25N", Vector2i(55, 6), "from_route_25_n"],
	["Route25C", Vector2i(55, 7), "from_route_25_c"],
	["Route25S", Vector2i(55, 8), "from_route_25_s"],
]
const ROUTE_25_SOON: String = "Route 25"

## Berges naturelles : valables pour tout sol sauf les pavés (cases `p`, quais de pierre).
const BANK_MARKS: Array[String] = [".", "=", "T", "x", "h", "G", "n"]
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
## Tabliers du Pont Pépite : alternés module après module.
const DECKS: Array[String] = [
	"prop_pont_pepite_tablier_01", "prop_pont_pepite_tablier_02", "prop_pont_pepite_tablier_03",
]
## Piles de pont : aux deux têtes (cases d'eau de chaque côté du tablier).
const PILE_ID: String = "prop_pont_pepite_pile_01"
const PILE_COLUMNS: Array[int] = [31, 34]
const PILE_ROWS: Array[int] = [20, 44]
## Arbres repères (cases `G`) : [objet, échelle, miroir] ; jamais deux fois le même côte à côte.
const TREES: Dictionary = {
	Vector2i(20, 3): ["tree_b_01", 1.0, false],
	Vector2i(28, 4): ["tree_e_01", 0.95, true],
	Vector2i(42, 4): ["tree_c_01", 0.95, false],
	Vector2i(17, 8): ["tree_a_01", 1.0, true],
	Vector2i(49, 10): ["tree_c_01", 0.9, false],
	Vector2i(40, 48): ["tree_b_01", 0.8, true],
}
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const BENCH_SCALE: float = 0.62
## Recouvrement des modules de tablier (pixels) : cache le bord transparent des images.
const DECK_OVERLAP: float = 10.0
## Roseaux isolés dans l'eau, près des berges : cases d'eau (côté nord du fleuve et canal).
const REEDS: Array[Vector2i] = [
	Vector2i(6, 20), Vector2i(13, 20), Vector2i(21, 20), Vector2i(29, 20), Vector2i(37, 20),
	Vector2i(45, 20), Vector2i(52, 20), Vector2i(10, 44), Vector2i(19, 44), Vector2i(26, 52),
	Vector2i(29, 58),
]
const SHADE_VALUE: float = 1.0
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
const MEADOW_ATTEMPTS: int = 700
const MEADOW_FLOWER_CHANCE: float = 0.25
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_24 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	var sets: Dictionary = {}
	for mark: String in BANK_MARKS:
		sets[mark] = BANKS
	_kit.set(&"quay_sets", sets)
	_kit.set(&"deck_overlap", DECK_OVERLAP)
	_reserve_positions()
	_kit.call(&"make_root", "Route24", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", "")
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth()):
		print("build_route_24 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var quays: int = _kit.call(&"place_quays")
	var decks: int = _kit.call(&"place_bridges", {&"ns": DECKS})
	_place_props(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var rules: GDScript = _kit.get(&"rules")
	for cell: Vector2i in TREES:
		feet.append((rules.call(&"foot_position", StringName(TREES[cell][0]), cell) as Vector2)
			/ float(Kit.TILE))
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_24 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_24 : %s (%d entités, %d au sol dont %d modules de berge / quai et %d de tablier, "
		% [error_string(result.x), counts.x, counts.y, quays, decks]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des positions de la grille (rival, Ondine, Dresseurs, objets, herbes) : réservées.
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


## Sous-bois sur la forêt `T`.
func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	for entry: Array in SOUTH_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.DOWN, SOUTH_MAP,
			StringName(entry[3]), Vector2i.UP)
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, &"",
			StringName(entry[2]), Vector2i.LEFT, ROUTE_25_SOON)


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var spec: Array = TREES[cell]
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
	_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell("panneau_pont"), "SignPont")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var chosen: Dictionary = {}
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id \
					and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.12)
		bush.scale = Vector2(scale, scale)
		bush.modulate = tint
	index = 0
	for cell: Vector2i in REEDS:
		var reed: Node2D = _kit.call(&"add_prop_at", entities, "prop_roseaux_01", cell,
			"Reeds%02d" % index)
		index += 1
		_kit.call(&"flip", reed, decor.randf() < 0.5)
	index = 0
	for row: int in PILE_ROWS:
		for column: int in PILE_COLUMNS:
			_kit.call(&"add_prop_at", entities, PILE_ID, Vector2i(column, row),
				"Pile%02d" % index)
			index += 1
