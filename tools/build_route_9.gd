extends SceneTree
## Construit game/world/maps/route_9.tscn (Route 9, 80 × 36 cases) d'après la grille fonctionnelle
## `tools/plans/route_9.txt` (jalon 18 T12, docs/tech/jalon-18.md §4.1 à §4.3 ; dossier 21 §3).
##
##   godot --headless --path . -s res://tools/build_route_9.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/route-9-vue-generale-v1.png`)
## donne la DA : montagne **beige** de la série 12 (`relief_paroi_01..04`, toutes les falaises `K`),
## sentier de terre à angles droits, terrasses de sol rocheux, rochers `R` (muret du couloir haut,
## goulet de Bernard), forêt serrée, hautes herbes jaune-vert. Modèle : `build_route_3.gd`.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `o` sol rocheux, `h` hautes
##   herbes, `v` rebord (sauté vers le sud) ; tout le reste (forêt, paroi, rochers) est solide.
## - **Vie (T18)** : les cases des Dresseurs, PNJ, Pokémon d'ambiance et objets de la grille sont
##   **réservées** (la forêt s'en écarte) ; les PNJ viennent de `data/npcs/route_9.json`, les
##   rencontres de `data/encounters/route_9.json`. Point d'examen du panneau ouest et déclencheur
##   silencieux `route_9_entered` (colonne 1, rangées 22..24).
## - Passages : bord ouest (0, 22..24) = « Azuria — À venir » tant que la variante J18 d'Azuria
##   n'existe pas (la Coupe du J16 ouvre l'arbre (53, 23) ; §4.4) ; bord est (79, 12..14) PUSH →
##   `route_10` / `from_route_9` (spawns `from_route_10`, `_n`, `_s`). Aucun bâtiment, aucune porte.
## - Falaises : la masse du nord et de l'est en modules de paroi ; la bande `K` d'une rangée de la
##   terrasse haute (y 17) en falaises `relief_falaise_01` ; la colonne `K` isolée (50, 10..16)
##   et les cases `K` coincées dans la forêt sont **plantées d'arbres** (comme la vue).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_9.txt"
const OUT_PATH: String = "res://game/world/maps/route_9.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_9_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_9.json"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(80, 36)
const SEED: int = 1801
const DECOR_SEED: int = 1802
const FOREST_SEED: int = 1803
const PAROI_SEED: int = 1804

const MAP_ID: StringName = &"route_9"
const DISPLAY_NAME: String = "Route 9"
const REGION: String = "Azuria — Route 10"
const WALKABLE: String = ".=hvo"

## Raccord ouest : [nœud, case, spawn d'ici (la rangée), orientation au retour « à venir »].
## Plan : spawn `from_cerulean` ; les deux autres rangées gardent la leur (`_n`, `_s`) pour que le
## joueur ressorte sur la même rangée. Cible réelle (variante J18 d'Azuria, après le J16 ; T15) :
## `cerulean_city` / `from_route_9_n|from_route_9|from_route_9_s`, rangée par rangée (comme la
## Route 10).
const WEST_EXITS: Array = [
	["CeruleanN", Vector2i(0, 22), "from_cerulean_n", &"from_route_9_n"],
	["CeruleanC", Vector2i(0, 23), "from_cerulean", &"from_route_9"],
	["CeruleanS", Vector2i(0, 24), "from_cerulean_s", &"from_route_9_s"],
]
const WEST_LABEL: String = "Azuria"
## Raccord est : [nœud, case, spawn d'ici, spawn d'arrivée de la Route 10].
const EAST_EXITS: Array = [
	["Route10N", Vector2i(79, 12), "from_route_10_n", &"from_route_9_n"],
	["Route10C", Vector2i(79, 13), "from_route_10", &"from_route_9"],
	["Route10S", Vector2i(79, 14), "from_route_10_s", &"from_route_9_s"],
]
const EAST_MAP: StringName = &"route_10"
## Types de positions de la grille dont la case est réservée (PNJ, Dresseurs, objets : T16 / T18).
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneau : [position de la grille, nœud] (décor ; point d'examen au T18).
const SIGNS: Array = [["panneau_ouest", "SignWest"]]
## Point d'examen du panneau (lu de face, depuis le sud) : [nœud, dialogue].
const SIGN_READ: Array = ["SignWestRead", &"route_9_sign"]
## Déclencheur silencieux de l'objectif « traverser la Route 9 vers l'est. » (jalon-18.md §4.13) :
## colonne 1, rangées 22..24 (les trois cases d'arrivée d'Azuria sont en colonne 0) ; l'ancre
## est la case du bas, la boîte monte de trois cases.
const ENTERED_ANCHOR := Vector2i(1, 24)
const ENTERED_SIZE := Vector2i(1, 3)
const ENTERED_CUTSCENE: StringName = &"route_9_entered"

## Cases `K` converties en forêt (arbres) : colonne isolée du bord est de la terrasse haute.
const FOREST_K: Array[Rect2i] = [Rect2i(50, 10, 1, 7)]
## Bande `K` d'une rangée (terrasse haute, y 17, x 27..46) : falaises `relief_falaise_01` de 4 cases.
const CLIFF_ROW: int = 17
const CLIFF_FROM_X: int = 27
const CLIFF_TO_X: int = 46
const CLIFF_ID: String = "relief_falaise_01"

const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const SHADE_VALUE: float = 0.97
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
## Sol rocheux (canal rouge du masque) : trous d'herbe rares, roche tendre près de l'herbe.
const ROCK_HOLE_CHANCE: float = 0.14
const ROCK_HOLE_VALUE: float = 0.47
const ROCK_SOFT_VALUE: float = 0.62
const PATH_IN_ROCK_VALUE: float = 0.25
const ROCK_SCALE: float = 1.0
const MEADOW_ATTEMPTS: int = 900
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]
const ROCK_DECALS_PER_CELL: float = 0.8
const PEBBLES_ID: String = "prop_pierres_01"
const DRY_TUFT := Color(1.0, 0.93, 0.72)
const EARTH_TINT := Color(0.8, 0.78, 0.74, 0.5)
const TERRE_DECAL: String = "res://assets/world/ground/decals/decal_terre_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"

var _kit: Object
var _outcrops: Array[Array] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_9 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "K", "o")
	_reserve_positions()
	_kit.call(&"make_root", "Route9", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_convert_cliff_to_forest()
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth(), _vary_mask):
		print("build_route_9 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var ground := root.get_node(^"PaintedGround")
	ground.set(&"r_texture", load(ROCK_TEXTURE))
	(ground.get(&"material") as ShaderMaterial).set_shader_parameter(&"paving_scale", ROCK_SCALE)
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	_place_rock_ground(decals)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	_place_cliff_band(decals)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_place_ledges(decals)
	var rocks := _place_boulders(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_9 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_9 : %s (%d entités, %d au sol dont %d modules de paroi, %d rochers, "
		% [error_string(result.x), counts.x, counts.y, modules, rocks]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des positions de la grille (Dresseurs, PNJ, Pokémon, objets) : réservées (T16 / T18).
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


## Cases `K` plantées d'arbres : plus de paroi (ni module), de la forêt (solide comme avant).
func _convert_cliff_to_forest() -> void:
	var cliffs: Dictionary = _kit.get(&"cliff_cells")
	var forest: Dictionary = _kit.get(&"forest_cells")
	for rect: Rect2i in FOREST_K:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if cliffs.has(cell):
					cliffs.erase(cell)
					forest[cell] = true
	# La bande d'une rangée (y 17) n'est pas de la paroi : falaises dédiées ([method _place_cliff_band]).
	for x: int in range(CLIFF_FROM_X, CLIFF_TO_X + 1):
		cliffs.erase(Vector2i(x, CLIFF_ROW))


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	for cell: Vector2i in _kit.get(&"cliff_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	var cerulean_built := ResourceLoader.exists("res://game/world/maps/cerulean_city.tscn") \
		and _cerulean_has_route_9()
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		if cerulean_built:
			_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, &"cerulean_city",
				entry[3], Vector2i.LEFT)
		else:
			_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, &"",
				StringName(entry[2]), Vector2i.RIGHT, WEST_LABEL)
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, EAST_MAP,
			StringName(entry[3]), Vector2i.RIGHT)


## Vie de la carte (T18) : point d'examen du panneau et déclencheur de l'objectif. Les Dresseurs,
## Pokémon d'ambiance et objets viennent de `data/npcs/route_9.json`, les rencontres de
## `data/encounters/route_9.json`.
func _add_life() -> void:
	_kit.call(&"add_interactable", SIGN_READ[0], _cell("panneau_ouest"), Vector2i.ONE, Vector2i.UP,
		SIGN_READ[1])
	_kit.call(&"add_trigger", "Route9Entered", ENTERED_ANCHOR, ENTERED_SIZE, Vector2i.ZERO,
		ENTERED_CUTSCENE)


## Vrai si Azuria porte déjà les spawns `from_route_9_*` (variante J18, après la Coupe du J16).
func _cerulean_has_route_9() -> bool:
	var text := FileAccess.get_file_as_string("res://game/world/maps/cerulean_city.tscn")
	return text.contains("from_route_9")


# --- Relief -------------------------------------------------------------------------------


## Affleurements `R` : composantes connexes ; les grandes collées à la paroi deviennent de la
## paroi, les autres des rochers ([method _place_boulders]).
func _classify_outcrops() -> void:
	var left: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", "R"):
		left[cell] = true
	var cliffs: Dictionary = _kit.get(&"cliff_cells")
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		var touches_cliff := false
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := cell + side
				if _plan().call(&"at", next) == "K":
					touches_cliff = true
				if left.has(next):
					left.erase(next)
					component.append(next)
					stack.append(next)
		component.sort()
		if touches_cliff and component.size() >= 40:
			for cell: Vector2i in component:
				cliffs[cell] = true
		else:
			_outcrops.append(component)
			var under: Dictionary = _kit.get(&"paved_cells")
			for cell: Vector2i in component:
				under[cell] = true


## Masque : sol rocheux varié (trous d'herbe, roche plus tendre près de l'herbe). Graine fixe.
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
			elif mark == "=" and _touches(cell, "o"):
				color.r = PATH_IN_ROCK_VALUE
			image.set_pixelv(cell, color)


func _touches(cell: Vector2i, marks: String) -> bool:
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if marks.contains(_plan().call(&"at", cell + side)):
			return true
	return false


## Sol rocheux : cailloux, touffes sèches et terre (casse la répétition de la texture).
func _place_rock_ground(decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var cells: Array[Vector2i] = _plan().call(&"cells_of", "o")
	var count := int(cells.size() * ROCK_DECALS_PER_CELL)
	for i in count:
		var cell: Vector2i = cells[decor.randi_range(0, cells.size() - 1)]
		var p := Vector2(cell) + Vector2(decor.randf_range(0.15, 0.85), decor.randf_range(0.3, 0.95))
		var roll := decor.randf()
		if roll < 0.45:
			var pebbles: Sprite2D = _kit.call(&"add_sprite", decals, PEBBLES_ID, p * Kit.TILE,
				"Pebbles%03d" % i)
			var scale := decor.randf_range(0.6, 1.0)
			pebbles.scale = Vector2(scale, scale)
			pebbles.flip_h = decor.randf() < 0.5
		elif roll < 0.85:
			var tuft: Sprite2D = _kit.call(&"decal", decals, TUFT_DECAL % decor.randi_range(1, 4),
				p * Kit.TILE, 0.75)
			tuft.modulate = DRY_TUFT
		else:
			var earth: Sprite2D = _kit.call(&"decal", decals, TERRE_DECAL % decor.randi_range(1, 4),
				p * Kit.TILE, 0.9)
			earth.modulate = EARTH_TINT


## Bande `K` d'une rangée de la terrasse haute : [constant CLIFF_ID] bout à bout (4 cases chacune).
func _place_cliff_band(decals: Node2D) -> void:
	var index := 0
	var left := CLIFF_FROM_X
	while left < CLIFF_TO_X + 1:
		var width := mini(4, CLIFF_TO_X + 1 - left)
		var cell := Vector2i(left + width / 2, CLIFF_ROW)
		_kit.call(&"add_prop_at", decals, CLIFF_ID, cell, "Cliff%02d" % index)
		left += width
		index += 1


## Un rebord peint par case `v`.
func _place_ledges(decals: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "v"):
		_kit.call(&"add_prop_at", decals, "relief_rebord_01", cell, "Ledge%02d" % index)
		index += 1


## Petits affleurements : grande pierre (3 × 2) là où elle tient, sinon rochers (2 × 1), sinon
## un rocher réduit sur sa case. Renvoie leur nombre.
func _place_boulders(entities: Node2D) -> int:
	var rules: GDScript = _kit.get(&"rules")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for component: Array in _outcrops:
		var free: Dictionary = {}
		for cell: Vector2i in component:
			free[cell] = true
		var order: Array = component.duplicate()
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y > b.y or (a.y == b.y and a.x < b.x))
		for cell: Vector2i in order:
			if not free.has(cell):
				continue
			var placed := false
			for id: String in ["prop_grande_pierre_01", "prop_rocher_01"]:
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(id))
				for align: Vector2i in footprint:
					var anchor := cell - align
					var fits := true
					for offset: Vector2i in footprint:
						fits = fits and free.has(anchor + offset)
					if not fits:
						continue
					var rock: Node2D = _kit.call(&"add_prop_at", entities, id, anchor,
						"Rock%02d" % index)
					_style_rock(rock, decor, 0.9 if id == "prop_grande_pierre_01" else 1.0)
					for offset: Vector2i in footprint:
						free.erase(anchor + offset)
					placed = true
					break
				if placed:
					break
			if not placed:
				var foot := Vector2(cell.x + decor.randf_range(0.35, 0.65),
					cell.y + decor.randf_range(0.85, 1.0))
				var small: Node2D = _kit.call(&"add_prop", entities, "prop_rocher_01",
					foot * Kit.TILE, "Rock%02d" % index)
				_kit.call(&"clear_footprint", small)
				_style_rock(small, decor, 0.62)
				free.erase(cell)
			index += 1
	return index


func _style_rock(rock: Node2D, decor: RandomNumberGenerator, scale: float) -> void:
	var s := scale * decor.randf_range(0.92, 1.08)
	rock.scale = Vector2(s, s)
	_kit.call(&"flip", rock, decor.randf() < 0.5)
	var value := decor.randf_range(0.9, 1.0)
	rock.modulate = Color(value, value, value)
