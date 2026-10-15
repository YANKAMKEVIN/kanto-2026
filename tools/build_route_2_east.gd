extends SceneTree
## Construit game/world/maps/route_2_east.tscn (Route 2 est, 16 × 48 cases) d'après la grille
## fonctionnelle `tools/plans/route_2_east.txt` (jalon 17 T19, docs/tech/jalon-17.md §2.1,
## §2.13 ; dossier 20 §3.4).
##
##   godot --headless --path . -s res://tools/build_route_2_east.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-2-est-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** (dossier 20, « Vues générales peintes v1 ») : clairières moins larges que la
## vue (la grille fait foi), arbuste du goulet (il n'est pas peint sur la vue) et personnages.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` `Q` chemin, `o` sol rocheux ;
##   `A` (l'arbuste du goulet) est **praticable dans la grille** : la case est occupée par la
##   [FlagGate] de l'arbuste tant que `cut_route_2_east_bush` n'est pas posé (jalon-17.md §2.4).
##   Tout le reste (forêt, paroi, éboulis, buissons, poste) est solide.
## - Image : sol peint (masque R = sol rocheux `ground_roche_01`, G = chemin et sentier peint
##   derrière les éboulis), sous-bois sur la forêt et sous la paroi, forêt serrée « plus sèche »,
##   paroi en modules (série 12) avec la bouche de la Cave (`relief_bouche_paroi_01`) posée par
##   dessus, éboulis de la Route 2 nord vus de l'arrière, poste de garde (`bldg_poste_safrania_01`,
##   7 × 4, porte au bas), arbuste du goulet (provisoire : le jeune arbre de l'Arène de Carmin,
##   en attendant celui du J16), buissons, panneau T-11, touffes et fleurs rares.
## - Passages : bouche de la Cave (6..7, 3) STEP_ON ↑ → `digletts_cave` / `from_route_2_east_w|e` ;
##   porte du poste (11, 11) STEP_ON ↑ → `route_2_east_gate` / `entrance` ; bord ouest (0, 43..44)
##   PUSH ← → `route_2` / `from_route_2_east_n|s`. Spawns `from_cave_w|e`, `from_gate`,
##   `from_route_2_n|s`, et `debug_south` (derrière l'arbuste, départ de débogage seulement).
## - Vie : panneau T-11 (point d'examen) ; les objets (Pierre Lune, Super Bonbon : T20) viennent
##   de `data/npcs/route_2_east.json`, leurs cases sont réservées (la forêt s'en écarte). Aucun
##   point d'examen sur l'arbuste avant le J16 (jalon-17.md §2.13).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_2_east.txt"
const OUT_PATH: String = "res://game/world/maps/route_2_east.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_2_east_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_2_east.json"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(16, 48)
const SEED: int = 2701
const DECOR_SEED: int = 2702
const FOREST_SEED: int = 27
const PAROI_SEED: int = 2703

const MAP_ID: StringName = &"route_2_east"
## Titre de la Route 2 (zone `route_2`, dossier 20 §3.6).
const DISPLAY_NAME: String = "Route 2"
const REGION: String = "Jadielle — Forêt de Jade"
const WALKABLE: String = ".=oQDA"

## Bouche de la Cave (STEP_ON ↑) : [nœud, case, spawn de la Cave, spawn d'ici (devant)].
const CAVE_MOUTH: Array = [
	["CaveMouthW", Vector2i(6, 3), &"from_route_2_east_w", "from_cave_w"],
	["CaveMouthE", Vector2i(7, 3), &"from_route_2_east_e", "from_cave_e"],
]
const CAVE_ANCHOR := Vector2i(7, 3)
const CAVE_MOUTH_ID: String = "relief_bouche_paroi_01"
## Porte du poste (STEP_ON ↑) et retour devant elle.
const POST_DOOR := Vector2i(11, 11)
const POST_ID: String = "bldg_poste_safrania_01"
const POST_MAP: StringName = &"route_2_east_gate"
const POST_SPAWN: StringName = &"entrance"
## Bord ouest (PUSH ←) vers la Route 2 sud : [nœud, case, spawn de la Route 2, spawn d'ici].
const WEST_EXITS: Array = [
	["Route2N", Vector2i(0, 43), &"from_route_2_east_n", "from_route_2_n"],
	["Route2S", Vector2i(0, 44), &"from_route_2_east_s", "from_route_2_s"],
]
const WEST_MAP: StringName = &"route_2"
## Départ de débogage derrière l'arbuste (jusqu'à la Coupe du J16 : seul moyen d'y aller).
const DEBUG_SPAWNS: Array = [["debug_south", Vector2i(6, 23)]]
## Arbuste coupable du goulet : drapeau du J16, deux cases, provisoire (jeune arbre de Carmin).
const BUSH_FLAG: StringName = &"cut_route_2_east_bush"
const BUSH_ID: String = "prop_jeune_arbre_arene_01"
const BUSH_NODE: String = "CorridorBush"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]

## Sol rocheux : valeur du masque R (voir `build_route_3.gd`).
const ROCK_HOLE_CHANCE: float = 0.16
const ROCK_HOLE_VALUE: float = 0.47
const ROCK_SOFT_VALUE: float = 0.62
const PATH_IN_ROCK_VALUE: float = 0.25
## Sol rocheux : décalcomanies par case `o` (cailloux, touffes sèches).
const ROCK_DECALS_PER_CELL: float = 0.8
const PEBBLES_ID: String = "prop_pierres_01"
const DRY_TUFT := Color(1.0, 0.93, 0.72)
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"

## Éboulis de la Route 2 nord vus de l'arrière (`E`, 0..1 × 5..6) : rochers assombris et pierres,
## sans emprise propre (les cases sont bloquées par la grille) : [objet, pied (cases), échelle,
## miroir].
const RUBBLE: Array = [
	["prop_rocher_01", Vector2(1.6, 5.85), 0.95, true],
	["prop_rocher_01", Vector2(0.8, 6.15), 1.1, false],
	["prop_pierres_01", Vector2(1.5, 6.9), 1.2, true],
	["prop_rocher_01", Vector2(0.95, 5.5), 0.85, false],
	["prop_pierres_01", Vector2(0.4, 6.8), 1.0, false],
]
const RUBBLE_VALUE: float = 0.78
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Forêt « plus sèche » (mêmes valeurs que la Route 2 nord et la Route 3).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
## Prairie : touffes et fleurs rares (« touches discrètes »).
const MEADOW_ATTEMPTS: int = 520
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_2_east : %s" % _kit.get(&"errors"))
		quit(1)
		return
	# La bouche `Q` est comptée dans la paroi : elle continue derrière l'ouverture.
	_kit.call(&"set_marks", WALKABLE, "KQ", "o")
	_reserve_positions()
	_kit.call(&"make_root", "Route2East", MAP_ID, DISPLAY_NAME, REGION, &"forest", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_shape_ground()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth"), _vary_mask):
		print("build_route_2_east : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var ground := root.get_node(^"PaintedGround")
	ground.set(&"r_texture", load(ROCK_TEXTURE))
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_kit.call(&"add_interactable", "SignCave", _cell("panneau_cave"), Vector2i.ONE, Vector2i.UP,
		&"route_2_east_cave_sign")

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	_place_rock_ground(decals)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	_kit.call(&"add_prop_at", entities, CAVE_MOUTH_ID, CAVE_ANCHOR, "CaveMouth")
	_kit.call(&"add_prop_at", entities, POST_ID, POST_DOOR, "ResearchPost")
	_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell("panneau_cave"), "SignCave")
	_place_rubble(entities)
	_place_bush(entities)
	_place_small_bushes(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, _taken())

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_2_east :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_2_east : %s (%d entités, %d au sol dont %d modules de paroi, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, modules, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des positions des PNJ, Pokémon et objets de la grille : réservées (la forêt s'en écarte).
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


## Sol : l'arbuste `A` repose sur le chemin ; les éboulis `E` reposent sur la roche.
func _shape_ground() -> void:
	var path: Dictionary = _kit.get(&"path_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "A"):
		path[cell] = true
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _plan().call(&"cells_of", "E"):
		paved[cell] = true


func _add_passages() -> void:
	for entry: Array in CAVE_MOUTH:
		_kit.call(&"add_spawn", entry[3], (entry[1] as Vector2i) + Vector2i.DOWN)
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, &"digletts_cave",
			entry[2], Vector2i.DOWN)
	_kit.call(&"add_spawn", "from_gate", POST_DOOR + Vector2i.DOWN)
	_kit.call(&"add_warp", "PostDoor", POST_DOOR, Kit.STEP_ON, Vector2i.UP, POST_MAP,
		POST_SPAWN, Vector2i.UP)
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, WEST_MAP,
			entry[2], Vector2i.LEFT)
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Masque : sol rocheux varié (trous d'herbe, roche plus tendre près de l'herbe) ; chemin qui
## borde la roche. Graine fixe.
func _vary_mask(image: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = _plan().call(&"at", cell)
			var color := image.get_pixelv(cell)
			if mark == "o":
				var near_grass := false
				for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if _plan().call(&"at", cell + side) == ".":
						near_grass = true
				var roll := rng.randf()
				if roll < ROCK_HOLE_CHANCE:
					color.r = ROCK_HOLE_VALUE
				elif near_grass or roll < ROCK_HOLE_CHANCE * 2.0:
					color.r = ROCK_SOFT_VALUE
			elif ("=Qe".contains(mark)) and _touches(cell, "o"):
				color.r = PATH_IN_ROCK_VALUE
			image.set_pixelv(cell, color)


func _touches(cell: Vector2i, marks: String) -> bool:
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if marks.contains(_plan().call(&"at", cell + side)):
			return true
	return false


# --- Décor --------------------------------------------------------------------------------


## Sol rocheux : cailloux et touffes sèches (casse la répétition de la texture).
func _place_rock_ground(decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var cells: Array[Vector2i] = _plan().call(&"cells_of", "o")
	var count := int(cells.size() * ROCK_DECALS_PER_CELL)
	for i in count:
		var cell: Vector2i = cells[decor.randi_range(0, cells.size() - 1)]
		var p := Vector2(cell) + Vector2(decor.randf_range(0.15, 0.85),
			decor.randf_range(0.3, 0.95))
		if decor.randf() < 0.55:
			var pebbles: Sprite2D = _kit.call(&"add_sprite", decals, PEBBLES_ID, p * Kit.TILE,
				"Pebbles%03d" % i)
			var scale := decor.randf_range(0.6, 1.0)
			pebbles.scale = Vector2(scale, scale)
			pebbles.flip_h = decor.randf() < 0.5
		else:
			var tuft: Sprite2D = _kit.call(&"decal", decals,
				TUFT_DECAL % decor.randi_range(1, 4), p * Kit.TILE, 0.75)
			tuft.modulate = DRY_TUFT


## Éboulis vus de l'arrière : rochers assombris et pierres (sans emprise propre).
func _place_rubble(entities: Node2D) -> void:
	var index := 0
	for entry: Array in RUBBLE:
		var stone: Node2D = _kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * Kit.TILE, "Rubble%d" % index)
		index += 1
		stone.scale = Vector2(entry[2], entry[2])
		stone.modulate = Color(RUBBLE_VALUE, RUBBLE_VALUE, RUBBLE_VALUE)
		_kit.call(&"flip", stone, entry[3])
		_kit.call(&"clear_footprint", stone)


## Arbuste du goulet : une [FlagGate] `unless cut_route_2_east_bush` dont le décor est l'objet
## peint (sans emprise) et dont `blocking_cells` ferment les deux cases (contrat du J16, comme le
## jeune arbre de l'Arène de Carmin). Aucun point d'examen avant le J16.
func _place_bush(entities: Node2D) -> void:
	var cells: Array = _plan().call(&"cells_at", "arbuste")
	var rules: GDScript = _kit.get(&"rules")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = BUSH_NODE
	gate.position = (rules.call(&"foot_position", StringName(BUSH_ID), cells[-1]) as Vector2) \
		.round()
	var unless: Array[StringName] = [BUSH_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var bush: Node2D = _kit.call(&"add_prop", gate, BUSH_ID, Vector2.ZERO, "Bush")
	_kit.call(&"clear_footprint", bush)


## Un buisson par case `x` : les trois images mélangées, jamais la même que la voisine.
func _place_small_bushes(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var chosen: Dictionary = {}
	var index := 0
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
		var value := decor.randf_range(0.92, 1.05)
		bush.modulate = Color(value, value, value) * tint


## Cases de forêt où rien ne pousse : sous le poste (posé sur la forêt de la grille).
func _taken() -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	for offset: Vector2i in rules.call(&"footprint", StringName(POST_ID)):
		taken[POST_DOOR + offset] = true
	return taken
