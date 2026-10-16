extends SceneTree
## Construit game/world/maps/route_10.tscn (Route 10, 34 × 76 cases) d'après la grille
## fonctionnelle `tools/plans/route_10.txt` (jalon 18 T12, docs/tech/jalon-18.md §4.1 à §4.3 ;
## dossier 21 §4). Une carte, **deux secteurs** que rien ne relie à pied : le secteur nord
## (y 0..28), la bande centrale (falaise, forêt, rivière : jamais parcourue) et le secteur sud
## (y 47..75, depuis la sortie sud de la Grotte Sombre).
##
##   godot --headless --path . -s res://tools/build_route_10.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/route-10-vue-generale-v1.png`)
## donne la DA. Modèles : `build_route_3.gd` (relief, rochers), `build_route_24.gd` (rivière).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `o` sol rocheux, `h` hautes
##   herbes, `D` porte du Centre, `Q` bouches de la grotte ; `w` = **eau (jamais praticable)** ;
##   `E` = centrale lointaine (décor bloqué, **sans porte ni texte**, I-15) ; le reste est solide.
## - Image : sol peint (eau claire de canal à angles droits, berges naturelles `relief_berge_*`),
##   Centre Pokémon (`bldg_centre_01`), deux bouches de grotte dans la paroi (repli : module
##   `relief_entree_grotte_01` tant que `relief_bouche_paroi_01` de la série 19 n'est pas là),
##   paroi beige de la série 12 (nord et sud de la bande centrale ; le milieu de la bande est
##   planté d'arbres), centrale lointaine au-delà de l'eau, silhouette de la Tour au sud, rochers,
##   forêt serrée, hautes herbes.
## - **Carte sans vie** : les cases du randonneur, des Dresseurs et de l'objet sont réservées ;
##   aucune donnée de PNJ, de rencontre ni de dialogue (T16 / T18). Le panneau (14, 10) est posé
##   sans point d'examen.
## - Passages : porte du Centre (7..8, 11) STEP_ON ↑ → `route_10_center` ; raccord ouest (0, 12..14)
##   PUSH ← → `route_9` ; bouches (16..17, 7) et (8..9, 47) STEP_ON ↑ → `dark_cave_1f` (« Grotte
##   Sombre — À venir » tant que la carte n'existe pas) ; raccord sud (21..23, 75) PUSH ↓ →
##   `lavender_town` (« Lavanville — À venir » tant que la carte n'existe pas).

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_10.txt"
const OUT_PATH: String = "res://game/world/maps/route_10.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_10_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_10.json"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(34, 76)
const SEED: int = 1811
const DECOR_SEED: int = 1812
const QUAY_SEED: int = 1813
const FOREST_SEED: int = 1814
const PAROI_SEED: int = 1815

const MAP_ID: StringName = &"route_10"
const DISPLAY_NAME: String = "Route 10"
const REGION: String = "Route 9 — Lavanville"
const WALKABLE: String = ".=hoDQ"
const MAPS_DIR: String = "res://game/world/maps/"

const WEST_EXITS: Array = [
	["Route9N", Vector2i(0, 12), "from_route_9_n", &"from_route_10_n"],
	["Route9C", Vector2i(0, 13), "from_route_9", &"from_route_10"],
	["Route9S", Vector2i(0, 14), "from_route_9_s", &"from_route_10_s"],
]
## Porte du Centre : [nœud, case] ; spawns `from_center` (7, 12) et `from_center_b` (8, 12).
const CENTER_DOORS: Array = [["DoorCenterW", Vector2i(7, 11)], ["DoorCenterE", Vector2i(8, 11)]]
const CENTER_SPAWNS: Array = [["from_center", Vector2i(7, 12)], ["from_center_b", Vector2i(8, 12)]]
const CENTER_ANCHOR := Vector2i(8, 11)
## Bouches de la grotte : [nœud, case, spawn d'arrivée dans la grotte]. Spawns d'ici (devant,
## tournés ↓) : [nom, case].
const CAVE_MAP: StringName = &"dark_cave_1f"
const CAVE_LABEL: String = "Grotte Sombre"
const CAVE_NORTH: Array = [["CaveNorthW", Vector2i(16, 7)], ["CaveNorthE", Vector2i(17, 7)]]
const CAVE_NORTH_SPAWN: StringName = &"from_route_10_n"
const CAVE_NORTH_FRONT: Array = [["from_dark_cave_n", Vector2i(16, 8)],
	["from_dark_cave_n_b", Vector2i(17, 8)]]
const CAVE_NORTH_ANCHOR := Vector2i(17, 7)
const CAVE_SOUTH: Array = [["CaveSouthW", Vector2i(8, 47)], ["CaveSouthE", Vector2i(9, 47)]]
const CAVE_SOUTH_SPAWN: StringName = &"from_route_10_s"
const CAVE_SOUTH_FRONT: Array = [["from_dark_cave_s", Vector2i(8, 48)],
	["from_dark_cave_s_b", Vector2i(9, 48)]]
const CAVE_SOUTH_ANCHOR := Vector2i(9, 47)
## Module de la bouche : série 19 si elle est là, sinon l'entrée de la Route 3.
const MOUTH_IDS: Array[String] = ["relief_bouche_paroi_01", "relief_entree_grotte_01"]
## Raccord sud : [nœud, case, spawn d'ici] ; arrivée de Lavanville : `from_route_10`.
const SOUTH_MAP: StringName = &"lavender_town"
const SOUTH_LABEL: String = "Lavanville"
const SOUTH_EXITS: Array = [
	["LavenderW", Vector2i(21, 75), "from_lavender_w"],
	["LavenderC", Vector2i(22, 75), "from_lavender"],
	["LavenderE", Vector2i(23, 75), "from_lavender_e"],
]
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
const SIGNS: Array = [["panneau_grotte", "SignCave"]]

## Cases `K` plantées d'arbres : milieu de la bande centrale (la paroi n'est peinte qu'en haut et
## en bas, fiche série 21 §B2) ; bord de la terrasse de Paul.
const FOREST_K: Array[Rect2i] = [Rect2i(0, 32, 24, 11), Rect2i(14, 58, 1, 7)]

## Rive de la rivière : berges naturelles (comme la Route 24).
const BANK_MARKS: Array[String] = [".", "=", "T", "h", "o", "R", "K", "E"]
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
const CENTRAL_ID: String = "bldg_centrale_lointaine_01"
const CENTRAL_ANCHOR := Vector2i(31, 9)
const TOWER_ID: String = "prop_tour_lointaine_01"
const TOWER_FOOT := Vector2(10.5, 76.0)
const TOWER_SCALE: float = 0.62
const REEDS: Array[Vector2i] = [
	Vector2i(25, 12), Vector2i(25, 22), Vector2i(26, 52), Vector2i(25, 64), Vector2i(27, 70),
]
const SHADE_VALUE: float = 0.97
const SHADE_RED: float = 1.0
const SHADE_BLUE: float = 1.02
const ROCK_HOLE_CHANCE: float = 0.14
const ROCK_HOLE_VALUE: float = 0.47
const ROCK_SOFT_VALUE: float = 0.62
const PATH_IN_ROCK_VALUE: float = 0.25
const MEADOW_ATTEMPTS: int = 450
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
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, QUAY_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_10 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "K", "o")
	var sets: Dictionary = {}
	for mark: String in BANK_MARKS:
		sets[mark] = BANKS
	_kit.set(&"quay_sets", sets)
	_reserve_positions()
	_kit.call(&"make_root", "Route10", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_convert_cliff_to_forest()
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth(), _vary_mask):
		print("build_route_10 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var ground := root.get_node(^"PaintedGround")
	ground.set(&"r_texture", load(ROCK_TEXTURE))
	(ground.get(&"material") as ShaderMaterial).set_shader_parameter(&"paving_scale", 1.0)
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	_place_rock_ground(decals)
	var quays: int = _kit.call(&"place_quays")
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	_kit.call(&"add_prop_at", entities, "bldg_centre_01", CENTER_ANCHOR, "PokemonCenter")
	_place_mouth(decals, CAVE_NORTH_ANCHOR, "CaveMouthNorth")
	_place_mouth(decals, CAVE_SOUTH_ANCHOR, "CaveMouthSouth")
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_place_far_views(entities, decals)
	_place_reeds(entities)
	var rocks := _place_boulders(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_10 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_10 : %s (%d entités, %d au sol dont %d berges, %d modules de paroi, %d rochers, "
		% [error_string(result.x), counts.x, counts.y, quays, modules, rocks]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


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


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	for cell: Vector2i in _kit.get(&"cliff_cells"):
		values[cell] = 1.0
	return values


func _map_exists(map_id: StringName) -> bool:
	return ResourceLoader.exists(MAPS_DIR + "%s.tscn" % map_id)


## Bouche de la grotte : passage STEP_ON ↑ vers la Grotte Sombre, ou « à venir » (retour devant la
## bouche, sur [param front_spawn], tourné ↓) tant que sa carte n'existe pas.
func _add_cave_door(entry: Array, spawn: StringName, front_spawn: String) -> void:
	if _map_exists(CAVE_MAP):
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, CAVE_MAP, spawn,
			Vector2i.DOWN)
	else:
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, &"",
			StringName(front_spawn), Vector2i.DOWN, CAVE_LABEL)


func _add_passages() -> void:
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, &"route_9",
			StringName(entry[3]), Vector2i.LEFT)
	for i: int in CENTER_DOORS.size():
		_kit.call(&"add_warp", CENTER_DOORS[i][0], CENTER_DOORS[i][1], Kit.STEP_ON, Vector2i.UP,
			&"route_10_center", &"entrance", Vector2i.ZERO)
		_kit.call(&"add_spawn", CENTER_SPAWNS[i][0], CENTER_SPAWNS[i][1])
	for i: int in 2:
		_add_cave_door(CAVE_NORTH[i], CAVE_NORTH_SPAWN, CAVE_NORTH_FRONT[i][0])
		_kit.call(&"add_spawn", CAVE_NORTH_FRONT[i][0], CAVE_NORTH_FRONT[i][1])
		_add_cave_door(CAVE_SOUTH[i], CAVE_SOUTH_SPAWN, CAVE_SOUTH_FRONT[i][0])
		_kit.call(&"add_spawn", CAVE_SOUTH_FRONT[i][0], CAVE_SOUTH_FRONT[i][1])
	var south_built := _map_exists(SOUTH_MAP)
	for entry: Array in SOUTH_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		if south_built:
			_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.DOWN, SOUTH_MAP,
				&"from_route_10", Vector2i.DOWN)
		else:
			_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.DOWN, &"",
				StringName(entry[2]), Vector2i.UP, SOUTH_LABEL)


# --- Relief -------------------------------------------------------------------------------


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
		var under: Dictionary = _kit.get(&"paved_cells")
		for cell: Vector2i in component:
			under[cell] = true


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


## Bouche de la grotte dans la paroi (sol, sous le joueur qui y entre).
func _place_mouth(decals: Node2D, anchor: Vector2i, node_name: String) -> void:
	for id: String in MOUTH_IDS:
		if ResourceLoader.exists("res://game/world/props/painted/%s.tscn" % id):
			_kit.call(&"add_prop_at", decals, id, anchor, node_name)
			return
	push_error("build_route_10 : aucune image de bouche de grotte")


## Centrale lointaine au-delà de l'eau (cases `E` bloquées par la grille) et silhouette de la Tour
## au sud (sol, sous la forêt serrée ; cases `tour_lointaine` bloquées par la grille).
func _place_far_views(entities: Node2D, decals: Node2D) -> void:
	if ResourceLoader.exists("res://game/world/props/painted/%s.tscn" % CENTRAL_ID):
		var central: Node2D = _kit.call(&"add_prop", entities, CENTRAL_ID,
			(Vector2(CENTRAL_ANCHOR.x + 0.5, CENTRAL_ANCHOR.y + 1.0)) * Kit.TILE, "Central")
		_kit.call(&"clear_footprint", central)
	if ResourceLoader.exists("res://game/world/props/painted/%s.tscn" % TOWER_ID):
		var tower: Node2D = _kit.call(&"add_prop", decals, TOWER_ID, TOWER_FOOT * Kit.TILE,
			"FarTower")
		_kit.call(&"clear_footprint", tower)
		tower.scale = Vector2(TOWER_SCALE, TOWER_SCALE)


func _place_reeds(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in REEDS:
		var reed: Node2D = _kit.call(&"add_prop_at", entities, "prop_roseaux_01", cell,
			"Reeds%02d" % index)
		index += 1
		_kit.call(&"flip", reed, decor.randf() < 0.5)


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
