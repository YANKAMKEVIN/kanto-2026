extends SceneTree
## Construit game/world/maps/saffron_city.tscn (Safrania, 60 × 50 cases) d'après la grille
## fonctionnelle `tools/plans/safrania.txt` (jalon 26 T6, docs/tech/jalon-26.md §2.1, §2.2).
## **Géométrie seulement** : ni PNJ, ni sbires, ni habitants (T9) ; leurs cases (positions `pnj` de
## la grille) restent libres et la forêt s'en écarte.
##
##   godot --headless --path . -s res://tools/build_saffron_city.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi.** Art **provisoire** : façades générées par
## `tools/art/placeholders_safrania.py` (Sylphe, Arène, Dojo, maisons, immeubles, postes), Centre et
## Boutique communs (`bldg_centre_01`, `bldg_boutique_01`), haies, massifs et panneaux du kit.
##
## - `Ground` (invisible) : `.` pelouse, `p` pavés, `D` porte (praticables) ; tout le reste
##   (arbres, bâtiments, haies, massifs, panneaux) est solide.
## - Passages = positions `warp` de la grille (STEP_ON dans le sens `dir=`), arrivées = positions
##   `spawn` (première case de la position). Les quatre postes : `route_5_gate`, `route_7_gate`,
##   `route_8_gate` / `from_saffron` (case devant leur porte nord, tournée ↓) et `route_6` /
##   `from_saffron` (36, 8). Intérieurs : arrivée `entrance`.
## - « À venir » : portes `a_venir=oui` (Dojo, Arène : J27) et toute porte dont la carte n'existe
##   pas encore (Sylphe SARL tant que `silph_co_1f` n'est pas construite : **relancer cet outil**
##   une fois la Sylphe construite) ; retour sur l'arrivée devant la porte, dos à elle.
## - Panneaux lisibles : ville (T26-22) et Arène ; les autres poteaux sont décoratifs [D].

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/safrania.txt"
const OUT_PATH: String = "res://game/world/maps/saffron_city.tscn"
const MASK_PATH: String = "res://assets/world/maps/saffron_city_ground.png"
const NPCS_PATH: String = "res://data/npcs/saffron_city.json"
const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(60, 50)
const SEED: int = 2611
const DECOR_SEED: int = 2612
const FOREST_SEED: int = 2613

const MAP_ID: StringName = &"saffron_city"
const DISPLAY_NAME: String = "Safrania"
## Sous-titre du titre de zone [D] : le panneau de ville validé (T26-22).
const REGION: String = "Ville dorée, cœur commercial de Kanto"
const WALKABLE_MARKS: String = ".pD"

## Libellés « à venir » par carte visée.
const COMING_SOON: Dictionary = {
	&"fighting_dojo": "Dojo", &"saffron_gym": "Arène de Safrania",
	&"silph_co_1f": "Sylphe SARL",
}
## Orientation à l'arrivée dans la carte visée : intérieurs = celle du point d'apparition
## (ZERO, comme Céladopole) ; postes = dos à la porte de Safrania.
const ARRIVAL_FACING: Dictionary = {
	&"route_5_gate": Vector2i.DOWN, &"route_7_gate": Vector2i.DOWN,
	&"route_8_gate": Vector2i.DOWN, &"route_6": Vector2i.DOWN,
}
const DIRS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
## Façades par caractère de la grille (bâtiments à porte) ; immeubles `B` selon leur taille ;
## postes `P` selon leur bord.
const FACADES: Dictionary = {
	"c": ["bldg_maison_safrania_01", "CopycatHouse"],
	"r": ["bldg_maison_safrania_02", "PidgeyHouse"],
	"y": ["bldg_maison_safrania_03", "PsychicHouse"],
	"S": ["bldg_sylphe_safrania_01", "SilphCo"],
	"O": ["bldg_boutique_01", "PokeMart"],
	"C": ["bldg_centre_01", "PokemonCenter"],
	"J": ["bldg_dojo_safrania_01", "Dojo"],
	"Z": ["bldg_arene_safrania_01", "Gym"],
}
const BLOCKS: Dictionary = {
	Vector2i(8, 4): "bldg_immeuble_bas_safrania_01",
	Vector2i(6, 4): "bldg_immeuble_bas_safrania_02",
}
const BLOCK_VARIANTS: Array[String] = ["bldg_immeuble_safrania_01", "bldg_immeuble_safrania_02",
	"bldg_immeuble_safrania_03"]
## Panneaux lisibles : [position de la grille, nœud, dialogue].
const SIGNS: Array = [
	["panneau_ville", "SignCity", &"saffron_city_sign"],
	["panneau_arene", "SignGym", &"saffron_gym_sign"],
]
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const TRIMMED_IDS: Array[String] = ["prop_buis_taille_01", "prop_buis_taille_02"]
const SHADE_VALUE: float = 0.98
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.0
const MEADOW_ATTEMPTS: int = 400
const MEADOW_FLOWER_CHANCE: float = 0.3
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object
var _errors: PackedStringArray = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_saffron_city : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE_MARKS, "", "")
	_kit.call(&"make_root", "SaffronCity", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_reserve_npc_cells()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_saffron_city : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_signs()
	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var taken := _place_buildings(entities)
	_place_props(entities)
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, [] as Array[Vector2], taken)
	var errors: PackedStringArray = _kit.get(&"errors")
	errors.append_array(_errors)
	if not errors.is_empty():
		push_error("build_saffron_city :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", _out_path())
	print("saffron_city : %s (%d entités, %d au sol, forêt %d → %d, %d nœuds)"
		% [error_string(result.x), counts.x, counts.y, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


## Scène écrite : [constant OUT_PATH], ou `--out=<res://…>` (vérification du diff).
func _out_path() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return OUT_PATH


func _plan() -> Object:
	return _kit.get(&"plan")


func _positions() -> Dictionary:
	return _plan().get(&"positions")


## Cases des PNJ du T9 (sbires, habitants, libération) : la forêt s'en écarte.
func _reserve_npc_cells() -> void:
	var reserved: Array[Vector2i] = []
	for id: String in _positions():
		if _positions()[id]["kind"] == "pnj":
			reserved.append_array(_positions()[id]["cells"])
	_kit.set(&"reserved_cells", reserved)


## Arrivées (toutes les positions `spawn`, première case) et portes (positions `warp`).
func _add_passages() -> void:
	var spawns_by_cell: Dictionary = {}
	for id: String in _positions():
		if _positions()[id]["kind"] != "spawn":
			continue
		var cells: Array = _positions()[id]["cells"]
		_kit.call(&"add_spawn", id, cells[0])
		for cell: Vector2i in cells:
			spawns_by_cell[cell] = id
	for id: String in _positions():
		if _positions()[id]["kind"] != "warp":
			continue
		var target := StringName(_plan().call(&"attr", id, "to"))
		var spawn := StringName(_plan().call(&"attr", id, "spawn"))
		var direction: Vector2i = DIRS[_plan().call(&"attr", id, "dir")]
		var soon: bool = _plan().call(&"attr", id, "a_venir") == "oui" \
			or not ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
		var cells: Array = _positions()[id]["cells"]
		for index: int in cells.size():
			var cell: Vector2i = cells[index]
			var node := _warp_node(id, index, cells.size())
			if soon:
				var back: String = spawns_by_cell.get(cell - direction, "")
				if back.is_empty():
					_errors.append("%s : aucune arrivée devant %s" % [id, cell])
					continue
				_kit.call(&"add_warp", node, cell, Kit.STEP_ON, direction, &"",
					StringName(back), -direction, COMING_SOON.get(target, String(target)))
			else:
				_kit.call(&"add_warp", node, cell, Kit.STEP_ON, direction, target, spawn,
					ARRIVAL_FACING.get(target, Vector2i.ZERO))


## Nœud d'une case de porte : `porte_poste_r5` → `DoorPosteR5` (une case), `DoorPosteR50` /
## `DoorPosteR51` (deux cases, d'ouest en est ou du nord au sud).
static func _warp_node(id: String, index: int, count: int) -> String:
	var name := "Door" + id.trim_prefix("porte_").to_pascal_case()
	if count == 1:
		return name
	return name + str(index)


func _add_signs() -> void:
	for entry: Array in SIGNS:
		var cell: Vector2i = _plan().call(&"cell_of", entry[0])
		var from := _from_cell(entry[0])
		_kit.call(&"add_interactable", entry[1], cell, Vector2i.ONE, cell - from, entry[2])


## Case d'où l'on lit un panneau (`depuis=x,y`).
func _from_cell(id: String) -> Vector2i:
	var parts: PackedStringArray = String(_plan().call(&"attr", id, "depuis")).split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


## Rectangles des bâtiments (un par composante d'un même caractère) : [caractère, case en haut à
## gauche, taille].
func _building_rects() -> Array:
	var rects: Array = []
	var seen: Dictionary = {}
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var start := Vector2i(x, y)
			var mark: String = _plan().call(&"at", start)
			if seen.has(start) or not (FACADES.has(mark) or mark == "B" or mark == "P"):
				continue
			var low := start
			var high := start
			var stack: Array[Vector2i] = [start]
			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				if seen.has(cell) or _plan().call(&"at", cell) != mark:
					continue
				seen[cell] = true
				low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
				high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
				for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					stack.append(cell + side)
			rects.append([mark, low, high - low + Vector2i.ONE])
	return rects


## Façades sur les emprises de la grille (ancre = milieu du bas : `PaintedPropRules`). Renvoie les
## cases couvertes (aucun arbre dessous).
func _place_buildings(entities: Node2D) -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	var blocks := 0
	for rect: Array in _building_rects():
		var mark: String = rect[0]
		var origin: Vector2i = rect[1]
		var size: Vector2i = rect[2]
		var anchor := Vector2i(origin.x + size.x / 2, origin.y + size.y - 1)
		var id: String
		var node: String
		if mark == "B":
			id = BLOCKS.get(size, BLOCK_VARIANTS[blocks % BLOCK_VARIANTS.size()])
			node = "Block%02d" % blocks
			blocks += 1
		elif mark == "P":
			var side := "nord" if origin.y == 0 else "sud" if origin.y + size.y == SIZE.y \
				else "ouest" if origin.x == 0 else "est"
			id = "bldg_poste_safrania_%s_01" % side
			node = "Gate" + side.capitalize()
		else:
			id = FACADES[mark][0]
			node = FACADES[mark][1]
		_kit.call(&"add_prop_at", entities, id, anchor, node)
		for offset: Vector2i in rules.call(&"footprint", StringName(id)):
			taken[anchor + offset] = true
		for y: int in range(origin.y, origin.y + size.y):
			for x: int in range(origin.x, origin.x + size.x):
				taken[Vector2i(x, y)] = true
	return taken


## Haies (`x`), massifs (`j`), poteaux des panneaux (`n`).
func _place_props(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "j"):
		var trimmed: Node2D = _kit.call(&"add_prop_at", entities,
			TRIMMED_IDS[(cell.x + cell.y) % TRIMMED_IDS.size()], cell, "Trimmed%02d" % index)
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
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", cell, "SignPost%02d" % index)
		index += 1
