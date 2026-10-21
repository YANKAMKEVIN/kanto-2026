extends SceneTree
## Construit game/world/maps/route_7.tscn (Route 7, 28 × 24 cases) d'après la grille fonctionnelle
## `tools/plans/route_7.txt` (jalon 20 T15, docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23 §5).
##
##   godot --headless --path . -s res://tools/build_route_7.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; art provisoire du kit existant (stratégie d'accélération). Même méthode
## que `build_route_8.gd` (kit `pewter_map_kit.gd`), sans corniche ni clôture.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `D` porte ;
##   tout le reste (forêt, bâtiments, rochers, buissons, arbres repères) est solide.
## - Passages : bord ouest (0, 10..12) PUSH ← → `celadon_city` / `from_route_7_n|c|s` (arrivées ici
##   `from_celadon_n|c|s`, mêmes cases, tournées →) ; **« Céladopole — À venir » tant que la carte
##   de la ville (T16) n'existe pas** (relancer l'outil ensuite) ; porte du poste de Safrania
##   (23, 7) STEP_ON ↑ → `route_7_gate` / `entrance` (retour `from_gate` (23, 8)) ; porte du
##   bâtiment d'entrée du souterrain (23, 17) STEP_ON ↑ → `route_7_underground_gate` / `entrance`
##   (retour `from_underground` (23, 18)).
## - Vie : aucun Dresseur, aucun objet (dossier §5) ; Pokémon d'ambiance réservés (T17) ; les deux
##   panneaux (EXAMINER, textes 11 et 2).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_7.txt"
const OUT_PATH: String = "res://game/world/maps/route_7.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_7_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_7.json"
const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(28, 24)
const SEED: int = 2071
const DECOR_SEED: int = 2072
const FOREST_SEED: int = 2073

const MAP_ID: StringName = &"route_7"
const DISPLAY_NAME: String = "Route 7"
const REGION: String = "Céladopole — Safrania"
const WALKABLE: String = ".=hD"

const WEST_MAP: StringName = &"celadon_city"
const SUFFIXES: Array[String] = ["n", "c", "s"]
const GATE: StringName = &"route_7_gate"
const UNDERGROUND_GATE: StringName = &"route_7_underground_gate"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneaux : [position de la grille, nœud, dialogue] (lus de face, depuis le sud).
const SIGNS: Array = [
	["panneau_route", "SignRoute", &"route_7_sign"],
	["panneau_souterrain", "SignUnderground", &"route_7_underground_sign"],
]
const TREE_IDS: Array[String] = ["tree_a_01", "tree_b_01", "tree_c_01", "tree_e_01"]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Départs de débogage : arrivée de l'ouest, devant le poste.
const DEBUG_SPAWNS: Array = [["west_arrival", Vector2i(3, 11)], ["gate_front", Vector2i(23, 10)]]
const SHADE_VALUE: float = 1.0
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
const MEADOW_ATTEMPTS: int = 300
const MEADOW_FLOWER_CHANCE: float = 0.35
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object
var _outcrops: Array[Array] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_7 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route7", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth()):
		print("build_route_7 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var taken := _place_buildings(entities)
	_place_props(entities)
	var rocks := _place_boulders(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_7 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_7 : %s (%d entités, %d au sol, %d rochers, forêt %d → %d, %d nœuds)"
		% [error_string(result.x), counts.x, counts.y, rocks, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


func _built(map_id: StringName) -> bool:
	return ResourceLoader.exists(MAPS_DIR + "%s.tscn" % map_id)


## Cases des positions de la grille (Dresseurs, Pokémon, objets) : réservées (T17).
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


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	var west: Array = _plan().call(&"cells_at", "warp_ouest")
	var city := _built(WEST_MAP)
	for i: int in west.size():
		var here := "from_celadon_" + SUFFIXES[i]
		_kit.call(&"add_spawn", here, west[i])
		if city:
			_kit.call(&"add_warp", "Celadon" + SUFFIXES[i].to_upper(), west[i], Kit.PUSH,
				Vector2i.LEFT, WEST_MAP, StringName("from_route_7_" + SUFFIXES[i]),
				Vector2i.LEFT)
		else:
			_kit.call(&"add_warp", "Celadon" + SUFFIXES[i].to_upper(), west[i], Kit.PUSH,
				Vector2i.LEFT, &"", StringName(here), Vector2i.RIGHT, "Céladopole")
	for entry: Array in [["porte_poste", "DoorGate", GATE, "from_gate", "from_poste",
			"Poste de garde"], ["porte_souterrain", "DoorUnderground", UNDERGROUND_GATE,
			"from_underground", "from_souterrain", "Passage souterrain"]]:
		var door := _cell(entry[0])
		if _built(entry[2]):
			_kit.call(&"add_warp", entry[1], door, Kit.STEP_ON, Vector2i.UP, entry[2],
				&"entrance", Vector2i.UP)
		else:
			_kit.call(&"add_warp", entry[1], door, Kit.STEP_ON, Vector2i.UP, &"",
				StringName(entry[3]), Vector2i.DOWN, entry[5])
		_kit.call(&"add_spawn", entry[3], _cell(entry[4]))
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Panneaux (EXAMINER depuis la case du sud, tourné ↑).
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1] + "Read", _cell(entry[0]), Vector2i.ONE,
			Vector2i.UP, entry[2])


## Poste de Safrania et bâtiment d'entrée du souterrain (emprises `P` de 7 × 4, porte à la 4e
## colonne de la rangée du bas). Renvoie les cases qu'ils couvrent (aucun arbre dessous).
func _place_buildings(entities: Node2D) -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	for entry: Array in [["bldg_entree_souterrain_01", _cell("porte_souterrain"),
			"UndergroundEntrance"], ["bldg_poste_safrania_01", _cell("porte_poste"), "SaffronGate"]]:
		_kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	return taken


## Arbres repères, buissons, panneaux.
func _place_props(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "G"):
		var tree: Node2D = _kit.call(&"add_prop_at", entities, TREE_IDS[index % TREE_IDS.size()],
			cell, "Tree%02d" % index)
		var scale := decor.randf_range(0.8, 0.92)
		tree.scale = Vector2(scale, scale)
		_kit.call(&"flip", tree, index % 2 == 1)
		index += 1
	var tint: Color = _kit.call(&"forest_tint")
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var bush: Node2D = _kit.call(&"add_prop_at", entities, BUSH_IDS[index % BUSH_IDS.size()],
			cell, "Bush%02d" % index)
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		bush.modulate = tint
		index += 1
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])


## Rochers `R` : composantes connexes posées comme à la Route 9 (grande pierre 3 × 2, rocher
## 2 × 1, sinon un rocher réduit sur sa case).
func _classify_outcrops() -> void:
	var left: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", "R"):
		left[cell] = true
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := cell + side
				if left.has(next):
					left.erase(next)
					component.append(next)
					stack.append(next)
		component.sort()
		_outcrops.append(component)


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
