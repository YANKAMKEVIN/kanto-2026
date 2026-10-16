extends SceneTree
## Construit les deux étages de la Grotte Sombre (jalon 18 T13, docs/tech/jalon-18.md §4.1–§4.3,
## dossier 21 §5) d'après les grilles `tools/plans/grotte_sombre_{1f,b1f}.txt` (elles font foi),
## sur la boîte à outils `tools/cave_map_kit.gd` et les assets de la série 21 (table
## `tools/j18_asset_refs.gd`, repli explicite si un asset manque) :
##
##   godot --headless --path . -s res://tools/build_dark_cave.gd [-- --etage=1f|b1f|tous]
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import)
##
## - `Ground` (invisible) = source logique : `.` `j` `E` `e` `U` `V` sol calme, `g` gravats (tuiles
##   `RUBBLE`, **aucune table de rencontre ici**), tout le reste solide (`o` `K` `w` `f` `r` `#`).
## - Image : sol peint (sol calme, gravats, dessus des masses), parois en modules, repères
##   (grande colonne `K`, rochers `o`, flaque `w`, paroi fendue `f`, racines `r`, lampes, panneau,
##   filet de jour `j`), échelles `V` / `U`.
## - **Halos** [LightGlow] (≤ 16) : filet de jour et lampes ; pénombre précalculée (plus claire que
##   celle du Mont Sélénite, profils `dark_cave_1f` / `dark_cave_b1f`). Le voile d'obscurité (J17/J18) est posé par le
##   moteur, pas par cet outil.
## - Passages : échelles A et B `STEP_ON` sans direction vers le point d'apparition de même paire
##   (arrivée à l'opposé de l'échelle) ; entrée nord (27..28, 0) et sortie sud (8..9, 48) vers la
##   Route 10 (`from_dark_cave_n_w|e`, `from_dark_cave_s_w|e`). **Repli** tant que la Route 10
##   n'existe pas (construite en parallèle, T12) : destination « à venir » et retour sur la case
##   d'arrivée ; relancer l'outil une fois la Route 10 fusionnée (`test_dark_cave_maps` le signale).
## - **Vie (T20)** : Dresseurs et objets viennent de `data/npcs/dark_cave_*.json` (T16, posés par
##   la carte au chargement). Cet outil pose les points d'examen (panneau du randonneur, grande
##   colonne, racines, paroi fendue : T-6, T-8 à T-10) et l'objet caché du B1F (Super Potion,
##   « face à un indice » : la racine voisine de la case `objet_cache`).

const Kit := preload("res://tools/cave_map_kit.gd")
const Refs := preload("res://tools/j18_asset_refs.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const DISPLAY_NAME: String = "Grotte Sombre"
const TILE: int = 96

## Étage → [identifiant, nœud racine, taille, graine logique, graine du décor, profil].
const FLOORS: Dictionary = {
	"1f": [&"dark_cave_1f", "DarkCave1F", Vector2i(56, 49), 1801, 1802, &"dark_cave_1f"],
	"b1f": [&"dark_cave_b1f", "DarkCaveB1F", Vector2i(48, 38), 1811, 1812, &"dark_cave_b1f"],
}
## Pénombre par étage [D] (`tools/cave_shade.gd`). Propre à la Grotte Sombre (T20) : plus claire
## que celle du Mont Sélénite (ambiance 1, pied de paroi 0,80, pourtour 0,95 au lieu de 0,95 /
## 0,55 / 0,87), car le voile d'obscurité du J17 ôte déjà 38 % de la lumière hors du halo et le
## sol de la série 21 est plus sombre : mesuré à 0,049–0,100 de luminance hors du halo (seuil
## 0,10) avec la pénombre du Mont Sélénite (jalon-18.md, T15 puis T20).
const SHADE: Dictionary = {
	"1f": {"ambient": 1.0, "edge_min": 0.92, "edge_radius": 0.8, "room_min": 1.0,
		"room_radius": 3.2, "lift": 0.06, "tint": Color(0.84, 0.91, 1.0)},
	"b1f": {"ambient": 1.0, "edge_min": 0.92, "edge_radius": 0.8, "room_min": 1.0,
		"room_radius": 3.2, "lift": 0.06, "tint": Color(0.82, 0.90, 1.0)},
}
const SHADE_LIGHTS: Dictionary = {
	&"lamp": {"radius": 3.4, "strength": 0.95, "offset": Vector2(0.0, 40.0), "add": 0.15,
		"color": Color(1.0, 0.78, 0.5)},
	&"shaft": {"radius": 3.2, "strength": 1.0, "offset": Vector2.ZERO, "add": 0.12,
		"color": Color(0.86, 0.92, 1.0)},
	&"ladder": {"radius": 3.4, "strength": 1.0, "offset": Vector2.ZERO, "add": 0.06,
		"color": Color(0.9, 0.94, 1.0)},
}
const SHADE_WALL_FOLLOW: float = 0.7
const SHAFT_DECAL_ALPHA: float = 0.45
const BEAM_FOOT_SHARE: float = 0.6
## Hauteur (pixels au-dessus du pied) de la source de lumière d'une lampe.
const LAMP_LIGHT_HEIGHT: float = 62.0
## Échelle qui monte d'une case dont la voisine nord est praticable : ramenée dans sa case.
const SHORT_LADDER_HEIGHT: float = 128.0
## Entrée nord et sortie sud : [nœud, case, carte, spawn de la Route 10, spawn d'ici, direction
## du pas, orientation à l'arrivée d'ici (repli)].
const EXITS: Array = [
	["RouteNorthW", Vector2i(27, 0), &"from_dark_cave_n_w", &"from_route_10_n_w"],
	["RouteNorthE", Vector2i(28, 0), &"from_dark_cave_n_e", &"from_route_10_n_e"],
	["RouteSouthW", Vector2i(8, 48), &"from_dark_cave_s_w", &"from_route_10_s_w"],
	["RouteSouthE", Vector2i(9, 48), &"from_dark_cave_s_e", &"from_route_10_s_e"],
]
const ROUTE_10_SOON: String = "Route 10"
## Position du panneau du randonneur (décor bloquant, texte au T20).
const SIGN_POSITION: String = "panneau_randonneur"
## Points d'examen (T20) : position de la grille → dialogue. Une position de repère (`repere_*`)
## couvre toutes les cases de son groupe ; l'objet caché prend la racine voisine de sa case, les
## autres racines sont examinables (T-9).
const EXAMINABLES: Dictionary = {
	"dark_cave_1f": {"panneau_randonneur": &"dark_cave_1f_sign"},
	"dark_cave_b1f": {"repere_colonne": &"dark_cave_column", "repere_racines": &"dark_cave_roots",
		"repere_paroi": &"dark_cave_crack"},
}
const HIDDEN_ITEMS: Array[String] = ["dark_cave_b1f_hidden_1"]

var _kit: Object
var _floor_key: String = ""
var _picks: Dictionary = {}


func _init() -> void:
	var which := "tous"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--etage="):
			which = arg.trim_prefix("--etage=")
	var keys: Array = FLOORS.keys() if which == "tous" else [which]
	var code := 0
	for key: String in keys:
		if not FLOORS.has(key):
			push_error("build_dark_cave : étage inconnu « %s »" % key)
			quit(1)
			return
		code = maxi(code, _build(key))
	quit(code)


## 0 : enregistré ; 2 : masque écrit, importer puis relancer ; 1 : erreur.
func _build(key: String) -> int:
	_floor_key = key
	var spec: Array = FLOORS[key]
	var map_id: StringName = spec[0]
	_resolve_assets()
	if not _errors_so_far().is_empty():
		push_error("build_dark_cave %s : %s" % [key, _errors_so_far()])
		return 1
	_kit = Kit.new(Kit.PLANS[map_id], spec[2], spec[3], spec[4], Kit.DARK_CAVE_WALKABLE)
	if not _errors().is_empty():
		push_error("build_dark_cave %s : %s" % [key, _errors()])
		return 1
	_kit.set(&"floor_texture_path", Refs.GROUND + _picks[&"floor"][0] + ".png")
	_kit.set(&"mass_texture_path", Refs.GROUND + _picks[&"mass"][0] + ".png")
	_kit.set(&"rubble_texture_path", Refs.GROUND + _picks[&"rubble"][0] + ".png")
	var faces: Array[String] = []
	faces.assign(_picks[&"wall_faces"])
	_kit.set(&"wall_faces", faces)
	_kit.set(&"wall_side", _picks[&"wall_side"][0])
	_kit.set(&"wall_lip", _picks[&"wall_lip"][0])
	_kit.call(&"make_root", spec[1], map_id, DISPLAY_NAME, spec[5])
	var mask := "res://assets/world/maps/%s_ground.png" % map_id
	if not _kit.call(&"add_ground", mask):
		if not _errors().is_empty():
			push_error("build_dark_cave %s :\n%s" % [key, "\n".join(_errors())])
			_kit.call(&"discard")
			return 1
		print("build_dark_cave %s : masque écrit ; importer (--import) puis relancer" % key)
		_kit.call(&"discard")
		return 2
	var walls: Vector3i = _kit.call(&"place_walls", spec[4] + 7)
	_place_landmarks()
	_place_ladders(map_id)
	_place_examinables(map_id)
	if map_id == &"dark_cave_1f":
		_place_exits()
	var shade := "res://assets/world/maps/%s_shade.png" % map_id
	if _errors().is_empty() and not _kit.call(&"add_shade", shade, SHADE[key], SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_dark_cave %s : voile écrit ; importer (--import) puis relancer" % key)
			_kit.call(&"discard")
			return 2
	if not _errors().is_empty():
		push_error("build_dark_cave %s :\n%s" % [key, "\n".join(_errors())])
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", MAPS_DIR + String(map_id) + ".tscn")
	print("%s : %s (%d entités, %d au sol, parois %d faces / %d bords / %d lèvres, %d halos, "
		% [map_id, error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z,
		counts.z] + "%d nœuds)" % result.y)
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _rng() -> RandomNumberGenerator:
	return _kit.get(&"decor_rng")


## Assets de la table `DARK_CAVE` (série 21, repli explicite) : liste vide = manquant.
func _resolve_assets() -> void:
	_picks.clear()
	for name: StringName in Refs.DARK_CAVE:
		var entry: Dictionary = Refs.DARK_CAVE[name]
		_picks[name] = Refs.pick(entry)
		if Refs.status(entry) == &"fallback":
			print("build_dark_cave : %s → repli %s" % [name, _picks[name]])


func _errors_so_far() -> PackedStringArray:
	var missing := PackedStringArray()
	for name: StringName in _picks:
		if (_picks[name] as Array).is_empty() and not Refs.DARK_CAVE[name].get("optional", false):
			missing.append("asset manquant : %s" % name)
	return missing


# --- Repères ------------------------------------------------------------------------------


func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	# Grande colonne `K` (5 × 6) : pied au milieu de la rangée du bas.
	var index := 0
	for block: Rect2i in _blocks("K"):
		var anchor := Vector2i(block.position.x + block.size.x / 2, block.end.y - 1)
		_kit.call(&"add_prop_at", entities, _picks[&"column"][0], anchor, "Column%d" % index)
		index += 1
	# Rochers `o`.
	index = 0
	var rocks: Array = _picks[&"rock"]
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		_vary(_sprite_at(entities, rocks[index % rocks.size()], cell, "Rock%02d" % index),
			0.9, 1.08)
		index += 1
	# Racines `r` : une par case (1 × 2), miroir et valeur variés.
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "r"):
		_vary(_sprite_at(entities, _picks[&"roots"][0], cell, "Roots%d" % index), 0.92, 1.05)
		index += 1
	# Flaque `w` (8 × 4) : à plat, centrée sur la zone (étirée seulement par le repli).
	for block: Rect2i in _blocks("w"):
		var pool := _floor_decor(decals, _picks[&"pool"][0], block, "Pool")
		var sprite := pool.get_node(^"Sprite") as Sprite2D
		pool.scale = Vector2.ONE * (block.size.x * TILE / float(sprite.texture.get_width()))
		pool.position = (_center(block) + Vector2(0.0, sprite.texture.get_height()
			* pool.scale.y / 2.0)).round()
	# Paroi fendue `f` : module large posé sur la face (nom « Face… » : le voile la suit).
	for cell: Vector2i in _plan().call(&"cells_of", "f"):
		_sprite_at(entities, _picks[&"split_wall"][0], cell, "FaceSplit")
	# Lampes et filet de jour (halos de la grille).
	index = 0
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] != "halo":
			continue
		var cell: Vector2i = _plan().call(&"cell_of", id)
		match _plan().call(&"attr", id, "type"):
			"lamp":
				var foot := Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)
				_kit.call(&"add_prop_at", entities, _picks[&"lamp"][0], cell, "Lamp%d" % index)
				_kit.call(&"add_glow", &"lamp", foot - Vector2(0.0, LAMP_LIGHT_HEIGHT),
					"GlowLamp%d" % index)
			"shaft":
				_kit.call(&"add_glow", &"shaft", _kit.call(&"cell_center", cell), "GlowShaft%d" % index)
				_kit.call(&"add_glow", &"beam", _kit.call(&"cell_center", cell)
					+ Vector2(0.0, TILE * 1.5 * BEAM_FOOT_SHARE), "GlowBeam%d" % index)
			_:
				var errors := _errors()
				errors.append("%s : type de halo inconnu" % id)
				_kit.set(&"errors", errors)
		index += 1
	# Sol éclairé `j` : flaque de lumière au sol (le filet du B1F, la lumière du dehors au 1F).
	index = 0
	for block: Rect2i in _blocks("j"):
		var shaft: Node2D = _floor_decor(decals, _picks[&"day_shaft"][0], block,
			"DayShaft%d" % index)
		var sprite := shaft.get_node(^"Sprite") as Sprite2D
		var fit := minf(block.size.x * TILE * 1.15 / sprite.texture.get_width(),
			block.size.y * TILE * 1.35 / sprite.texture.get_height())
		shaft.scale = Vector2(fit, fit)
		shaft.position = _center(block) + Vector2(0.0, sprite.texture.get_height() * fit / 2.0)
		shaft.modulate.a = SHAFT_DECAL_ALPHA
		if _floor_key == "1f":
			# Lumière du dehors à l'entrée nord : un seul halo sur la bouche.
			_kit.call(&"add_glow", &"shaft", _center(block), "GlowEntrance%d" % index)
		index += 1
	# Panneau du randonneur (1F) : décor bloquant, texte au T20.
	if _plan().get(&"positions").has(SIGN_POSITION):
		_kit.call(&"add_prop_at", entities, _picks[&"sign"][0],
			_plan().call(&"cell_of", SIGN_POSITION), "SignHiker")


## Décor à plat posé dans la couche du sol, centré sur [param block] (pied au bas de l'image).
func _floor_decor(parent: Node, id: String, block: Rect2i, node_name: String) -> Node2D:
	var prop: Node2D = _kit.call(&"add_prop", parent, id, Vector2.ZERO, node_name)
	prop.set(&"footprint", [] as Array[Vector2i])
	var sprite := prop.get_node(^"Sprite") as Sprite2D
	var height := float(sprite.texture.get_height())
	prop.position = (_center(block) + Vector2(0.0, height / 2.0)).round()
	return prop


func _vary(sprite: Sprite2D, low: float, high: float) -> void:
	var value := _rng().randf_range(low, high)
	sprite.modulate = Color(value, value, value)
	sprite.flip_h = _rng().randf() < 0.5


## Objet peint réduit à son `Sprite2D`, au pied de [param cell] ; la case est déjà bloquée par
## la grille (erreur si elle est praticable).
func _sprite_at(parent: Node, id: String, cell: Vector2i, node_name: String) -> Sprite2D:
	var rules: GDScript = _kit.get(&"rules")
	if _plan().call(&"is_walkable", cell):
		var errors := _errors()
		errors.append("%s : %s posé sur une case praticable %s" % [node_name, id, cell])
		_kit.set(&"errors", errors)
	return _kit.call(&"add_sprite", parent, id, rules.call(&"foot_position", StringName(id), cell),
		node_name)


func _center(block: Rect2i) -> Vector2:
	return (Vector2(block.position) + Vector2(block.size) / 2.0) * TILE


## Rectangles englobants des groupes de cases [param mark] voisines (4-connexité).
func _blocks(mark: String) -> Array[Rect2i]:
	var cells: Array = _plan().call(&"cells_of", mark)
	var seen: Dictionary = {}
	var blocks: Array[Rect2i] = []
	for start: Vector2i in cells:
		if seen.has(start):
			continue
		var rect := Rect2i(start, Vector2i.ONE)
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			rect = rect.expand(cell).expand(cell + Vector2i.ONE)
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := cell + step
				if not seen.has(next) and cells.has(next):
					seen[next] = true
					stack.append(next)
		blocks.append(rect)
	return blocks


# --- Points d'examen et objet caché (T20) -------------------------------------------------


func _place_examinables(map_id: StringName) -> void:
	var positions: Dictionary = _plan().get(&"positions")
	var clues: Array[Vector2i] = []
	for id: String in HIDDEN_ITEMS:
		if not positions.has(id):
			continue
		var clue := _clue_of(_plan().call(&"cell_of", id))
		if clue == Vector2i(-1, -1):
			var errors := _errors()
			errors.append("%s : aucun repère bloquant voisin" % id)
			_kit.set(&"errors", errors)
			continue
		clues.append(clue)
		var node_name := "Hidden_%s" % id
		_kit.call(&"add_interactable", node_name, clue, Vector2i.ONE, Vector2i.ZERO, StringName(id))
		var points := (_kit.get(&"root") as Node).get_node(^"Interactables")
		points.get_node(NodePath(node_name)).set(&"unless_flags",
			[StringName("got_" + id)] as Array[StringName])
	var table: Dictionary = EXAMINABLES.get(String(map_id), {})
	for id: String in table:
		if not positions.has(id):
			continue
		var cells: Array = _plan().call(&"cells_at", id)
		var index := 0
		for cell: Vector2i in cells:
			if clues.has(cell):
				continue
			_kit.call(&"add_interactable", "Examine_%s_%d" % [id, index], cell, Vector2i.ONE,
				Vector2i.ZERO, table[id])
			index += 1


## Repère bloquant (racine `r`) voisin de la case où l'on se tient pour fouiller.
func _clue_of(stand: Vector2i) -> Vector2i:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _plan().call(&"at", stand + step) == "r":
			return stand + step
	return Vector2i(-1, -1)


# --- Échelles, entrées, sorties -----------------------------------------------------------


func _place_ladders(map_id: StringName) -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn":
			var named: Dictionary = Kit.spawn_names(id, _plan().call(&"cells_at", id))
			for spawn_name: String in named:
				_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	for link: Dictionary in _kit.call(&"ladder_links"):
		var cell: Vector2i = link["cell"]
		var up: bool = _plan().call(&"attr", link["id"], "sens") == "monte"
		var prop_id: String = _picks[&"ladder_up"][0] if up else _picks[&"ladder_down"][0]
		var ladder: Node2D = _kit.call(&"add_floor_prop", prop_id, cell,
			"Ladder%s" % String(link["pair"]))
		_kit.call(&"add_shade_source", &"ladder", _kit.call(&"cell_center", cell))
		if up and bool(_plan().call(&"is_walkable", cell + Vector2i.UP)):
			var sprite := ladder.get_node(^"Sprite") as Sprite2D
			ladder.scale = Vector2(1.0, SHORT_LADDER_HEIGHT / sprite.texture.get_size().y)
		_kit.call(&"add_ladder", "Ladder%sWarp" % String(link["pair"]), link)
	print("%s : échelles %s" % [map_id, _kit.call(&"ladder_links").map(
		func(l: Dictionary) -> String: return "%s→%s/%s %s" % [l["pair"], l["target_map"],
			l["target_spawn"], l["facing"]])])


## Entrée nord et sortie sud du 1F : deux passages `STEP_ON` chacun vers la Route 10 (ou « à
## venir » tant qu'elle n'existe pas).
func _place_exits() -> void:
	var built := ResourceLoader.exists(MAPS_DIR + "route_10.tscn")
	for entry: Array in EXITS:
		var cell: Vector2i = entry[1]
		var north := cell.y == 0
		var step := Vector2i.UP if north else Vector2i.DOWN
		if built:
			_kit.call(&"add_warp", entry[0], cell, Kit.STEP_ON, step, &"route_10", entry[2],
				Vector2i.DOWN)
		else:
			_kit.call(&"add_warp", entry[0], cell, Kit.STEP_ON, step, &"", entry[3],
				Vector2i.DOWN if north else Vector2i.UP, ROUTE_10_SOON)
	if not built:
		print("dark_cave_1f : entrée nord et sortie sud → « %s — À venir » (repli, route_10 "
			% ROUTE_10_SOON + "absente)")
