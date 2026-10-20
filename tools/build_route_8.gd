extends SceneTree
## Construit game/world/maps/route_8.tscn (Route 8, 80 × 26 cases) d'après la grille fonctionnelle
## `tools/plans/route_8.txt` (jalon 20 T15, docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23 §3).
##
##   godot --headless --path . -s res://tools/build_route_8.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; art provisoire du kit existant (stratégie d'accélération, levier 4 :
## le code n'attend pas l'art). Modèle : `build_route_9.gd` (kit `pewter_map_kit.gd`, corniche
## `v` sautée vers le sud).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `v` corniche
##   (sautée vers le sud, ne se monte pas), `D` porte, `e` raccord est ; tout le reste (forêt,
##   bâtiments, rochers, buissons, arbres repères, clôtures) est solide.
## - Passages : bord est (79, 10..12) PUSH → `lavender_town` / `from_route_8_n|c|s` (arrivées ici
##   `from_lavender_n|c|s`, sur les mêmes cases, tournées ←) ; porte du poste de Safrania (5, 17)
##   STEP_ON ↑ → `route_8_gate` / `entrance` (retour `from_gate` (5, 18), tourné ↓) ; porte du
##   bâtiment d'entrée du souterrain (11, 4) STEP_ON ↑ → `route_8_underground_gate` / `entrance`
##   (retour `from_underground` (11, 5), tourné ↓). Une carte cible absente → « à venir ».
## - Vie (T17) : Dresseurs, objets et Pokémon d'ambiance de la grille ont leurs cases **réservées**
##   (la forêt s'en écarte) ; PNJ dans `data/npcs/route_8.json`. Ici : les deux panneaux (EXAMINER,
##   textes 1 et 2), la pierre-indice de l'objet caché (Rappel) et son point EXAMINER, le
##   déclencheur d'arrivée `route_8_reached`.

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_8.txt"
const OUT_PATH: String = "res://game/world/maps/route_8.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_8_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_8.json"
const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(80, 26)
const SEED: int = 2081
const DECOR_SEED: int = 2082
const FOREST_SEED: int = 2083

const MAP_ID: StringName = &"route_8"
const DISPLAY_NAME: String = "Route 8"
const REGION: String = "Lavanville — Safrania"
const WALKABLE: String = ".=hveD"

const EAST_MAP: StringName = &"lavender_town"
const SUFFIXES: Array[String] = ["n", "c", "s"]
const GATE: StringName = &"route_8_gate"
const UNDERGROUND_GATE: StringName = &"route_8_underground_gate"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneaux : [position de la grille, nœud, dialogue] (lus de face, depuis le sud).
const SIGNS: Array = [
	["panneau_route", "SignRoute", &"route_8_sign"],
	["panneau_souterrain", "SignUnderground", &"route_8_underground_sign"],
]
## Objet caché : [position de la grille, nœud, indice].
const HIDDEN: Array = [["route_8_hidden_1", "HiddenRevive", "prop_indice_caillou_01"]]
## Arrivée (T17) : scène silencieuse qui lève `route_8_reached`.
const ARRIVAL_CUTSCENE: StringName = &"route_8_reached"
## Arbres repères (cases `G`), à tour de rôle ; échelles légèrement variées.
const TREE_IDS: Array[String] = ["tree_a_01", "tree_b_01", "tree_c_01", "tree_e_01"]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Clôtures (`c`) : modules du plus long au plus court (cases).
const FENCES: Array = [["prop_cloture_piquets_01", 4], ["prop_cloture_piquets_01_court", 3],
	["prop_cloture_courte_01", 1]]
## Départs de débogage : place de l'ouest, fourche des deux chemins, arrivée de l'est.
const DEBUG_SPAWNS: Array = [
	["west_square", Vector2i(8, 19)], ["fork", Vector2i(30, 12)], ["east_arrival", Vector2i(70, 11)],
]
const SHADE_VALUE: float = 1.0
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
const MEADOW_ATTEMPTS: int = 900
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object
var _outcrops: Array[Array] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_8 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route8", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth()):
		print("build_route_8 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_life()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	_place_ledges(decals)
	var taken := _place_buildings(entities)
	_place_props(entities)
	var rocks := _place_boulders(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_8 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_8 : %s (%d entités, %d au sol, %d rochers, forêt %d → %d, %d nœuds)"
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
	var east: Array = _plan().call(&"cells_at", "raccord_est")
	var lavender := _built(EAST_MAP)
	for i: int in east.size():
		var here := "from_lavender_" + SUFFIXES[i]
		_kit.call(&"add_spawn", here, east[i])
		if lavender:
			_kit.call(&"add_warp", "Lavender" + SUFFIXES[i].to_upper(), east[i], Kit.PUSH,
				Vector2i.RIGHT, EAST_MAP, StringName("from_route_8_" + SUFFIXES[i]),
				Vector2i.RIGHT)
		else:
			_kit.call(&"add_warp", "Lavender" + SUFFIXES[i].to_upper(), east[i], Kit.PUSH,
				Vector2i.RIGHT, &"", StringName(here), Vector2i.LEFT, "Lavanville")
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


## Panneaux (EXAMINER depuis la case du sud, tourné ↑), objet caché (point EXAMINER de la
## case-indice, de tous côtés ; il disparaît quand `got_<id>` est levé) et déclencheur de
## l'arrivée (T17) : tout pas vers l'ouest sur la 2e colonne du raccord est lève
## `route_8_reached` (scène silencieuse, objectif « rejoindre Céladopole »).
func _add_life() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1] + "Read", _cell(entry[0]), Vector2i.ONE,
			Vector2i.UP, entry[2])
	for entry: Array in HIDDEN:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, Vector2i.ZERO,
			StringName(entry[0]))
		var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
		var unless: Array[StringName] = [StringName("got_" + String(entry[0]))]
		point.set(&"unless_flags", unless)
	var east: Array = _plan().call(&"cells_at", "raccord_est")
	var column: Vector2i = (east[east.size() - 1] as Vector2i) + Vector2i.LEFT
	_kit.call(&"add_trigger", "Arrival", column, Vector2i(1, east.size()), Vector2i.LEFT,
		ARRIVAL_CUTSCENE)


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


## Arbres repères, buissons, clôtures, panneaux, indice de l'objet caché.
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
	_place_fences(entities)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	for entry: Array in HIDDEN:
		_kit.call(&"add_prop_at", entities, entry[2], _cell(entry[0]), entry[1] + "Clue")


## Clôtures : chaque suite horizontale de `c` couverte par les modules de [constant FENCES].
func _place_fences(entities: Node2D) -> void:
	var rules: GDScript = _kit.get(&"rules")
	var cells: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", "c"):
		cells[cell] = true
	var index := 0
	for y: int in SIZE.y:
		var x := 0
		while x < SIZE.x:
			if not cells.has(Vector2i(x, y)):
				x += 1
				continue
			var run := 0
			while cells.has(Vector2i(x + run, y)):
				run += 1
			for entry: Array in FENCES:
				var width: int = entry[1]
				if width > run:
					continue
				# Ancre : la case de l'emprise qui laisse l'emprise entière dans la suite.
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(entry[0]))
				var left := 0
				for offset: Vector2i in footprint:
					left = mini(left, offset.x)
				_kit.call(&"add_prop_at", entities, entry[0], Vector2i(x - left, y),
					"Fence%02d" % index)
				index += 1
				x += width
				break


## Une corniche peinte par case `v`.
func _place_ledges(decals: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "v"):
		_kit.call(&"add_prop_at", decals, "relief_rebord_01", cell, "Ledge%02d" % index)
		index += 1


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
