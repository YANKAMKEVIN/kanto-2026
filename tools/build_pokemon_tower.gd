extends SceneTree
## Construit game/world/maps/pokemon_tower_1f.tscn (rez-de-chaussée de la Tour Pokémon, 20 × 18
## cases) d'après la grille `tools/plans/tour_pokemon_rdc.txt` (elle fait foi ; jalon 18 T14,
## docs/tech/jalon-18.md §4.1, §4.2, §4.12 ; dossier 21 §7, §13.1 ; fiche `serie-21-j18.md`
## § « Tour Pokémon »), **en modules** (dalles, murs, mobilier de la série 21) sur la boîte à
## outils `tools/cave_map_kit.gd` comme le souterrain du J15 : un seul kit pour la Tour, que le
## J19 reprend pour ses étages. Racine **bâtiment** (`interior = true`, sans Corde Sortie).
##
##   godot --headless --path . -s res://tools/build_pokemon_tower.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import ; code 2 = masque
##   écrit, importer puis relancer)
##
## **Sans vie** (T14) : les cases des PNJ (la Médium / Exorciste en (17, 3) occupe la seule case
## d'accès à l'escalier), les cases de lecture des tombes et les examens sont **réservés** :
## aucun PNJ, aucun point d'examen, aucune donnée de dialogue. L'escalier (17, 2) mène à
## `pokemon_tower_2f` (carte du J19, inexistante ici) : `coming_soon = "Tour Pokémon"` (inerte en
## release, de toute façon inatteignable tant que la gardienne tient (17, 3)).
##
## - `Ground` (invisible) : `.` sol, `X` paillasson, `S` escalier praticables ; tout le reste
##   (murs `K`, tombes `g`, comptoir `W`, bancs `n`, chandeliers `b`) solide.
## - Image : dalles gris perle, mur du fond (faces sur la rangée 2, bords latéraux, couronnement
##   de la rangée 16), escalier pris dans le mur, 36 tombes (trois variantes à la graine), six
##   chandeliers et leurs halos `candle`, comptoir, bancs d'une case.

const Kit := preload("res://tools/cave_map_kit.gd")

const MAP_ID: StringName = &"pokemon_tower_1f"
const OUT_PATH: String = "res://game/world/maps/pokemon_tower_1f.tscn"
const PLAN_PATH: String = "res://tools/plans/tour_pokemon_rdc.txt"
const MASK_PATH: String = "res://assets/world/maps/pokemon_tower_1f_ground.png"
const SIZE := Vector2i(20, 18)
const SEED: int = 3001
const DECOR_SEED: int = 3002
const WALL_SEED: int = 3009
const TOMB_SEED: int = 3011
const TILE: int = 96
const WALKABLE: String = ".XS"
const WALL_MARK: String = "K"
## Le mur (K) et l'escalier (S) comptent comme paroi pour dessiner les modules : l'escalier est
## pris dans le mur, aucune face ne le recouvre.
const WALL_LIKE: String = "KS"
const PROFILE: StringName = &"tower_cold"
const DISPLAY_NAME: String = "Tour Pokémon"

const GROUND_FLOOR: String = "res://assets/world/ground/ground_dalles_tour_01.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_roche_01.png"
## Caractère sans cellule : aucun gravat dans la Tour (le canal R du sol n'est pas utilisé).
const NO_RUBBLE_MARK: String = "~"
const BORDER_COLOR := Color(0.26, 0.25, 0.32)

## Murs de la Tour (même rôles que `relief_mur_souterrain_*`) : faces 2 cases de large, couronnement
## (sol au nord), bord latéral 34 px.
const WALL_FACES: Array[String] = ["relief_mur_tour_01", "relief_mur_tour_02"]
const WALL_CAP: String = "relief_mur_tour_03"
const WALL_SIDE: String = "relief_mur_tour_04"
const WALL_SPAN: int = 2
const SIDE_WIDTH: int = 34
const SIDE_TOP: int = 0
const SIDE_MIDDLE: int = 1
const SIDE_BOTTOM: int = 2
const WALL_VALUE_JITTER: float = 0.04

const STAIRS: String = "relief_escalier_tour_01"
const STAIRS_SPAWN: StringName = &"from_pokemon_tower_2f"
const STAIRS_LABEL: String = "Tour Pokémon"
const TOMBS: Array[String] = ["int_tombe_tour_01", "int_tombe_tour_02", "int_tombe_tour_03"]
## Tombes nommées (T-36 à T-40) : variantes B ou C (bouquet, offrande), plus fréquentes qu'ailleurs.
const NAMED_TOMBS: Array[String] = ["tombe_1", "tombe_2", "tombe_3", "tombe_4", "tombe_5"]
## Examen des tombes (T24) : dialogue de chaque tombe nommée (T-36 à T-40), puis T-41 pour les
## 31 autres. Le gardien se parle à travers le comptoir : point d'examen sur les quatre cases.
const NAMED_GRAVE_DIALOGUES: Array[StringName] = [
	&"pokemon_tower_grave_1", &"pokemon_tower_grave_2", &"pokemon_tower_grave_3",
	&"pokemon_tower_grave_4", &"pokemon_tower_grave_5",
]
const OTHER_GRAVE_DIALOGUE: StringName = &"pokemon_tower_grave"
const KEEPER_DIALOGUE: StringName = &"pokemon_tower_keeper"
const CANDLE: String = "int_bougeoir_tour_01"
const CANDLE_GLOW: StringName = &"candle"
## Hauteur du halo au-dessus du pied du chandelier (flamme au sommet de l'image de 147 px).
const CANDLE_LIGHT_HEIGHT: float = 120.0
const COUNTER: String = "int_comptoir_tour_01"
const BENCH: String = "int_banc_tour_01"
## Sortie : deux cases PUSH ↓ vers Lavanville, devant la porte de la Tour (`retour_tour`).
const EXIT_MAP: StringName = &"lavender_town"
const EXIT_SPAWN: StringName = &"retour_tour"

var _kit: Object
var _wall_rng := RandomNumberGenerator.new()
var _tomb_rng := RandomNumberGenerator.new()


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, WALKABLE)
	_kit.set(&"floor_texture_path", GROUND_FLOOR)
	_kit.set(&"rubble_texture_path", GROUND_FLOOR)
	_kit.set(&"mass_texture_path", GROUND_MASS)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_mark", NO_RUBBLE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_kit.set(&"wall_marks", WALL_LIKE)
	_wall_rng.seed = WALL_SEED
	_tomb_rng.seed = TOMB_SEED
	quit(_build())


## 0 : enregistré ; 2 : masque écrit, importer puis relancer ; 1 : erreur.
func _build() -> int:
	if not _errors().is_empty():
		push_error("build_pokemon_tower : %s" % "\n".join(_errors()))
		return 1
	var root: Node2D = _kit.call(&"make_root", "PokemonTower1F", MAP_ID, DISPLAY_NAME, PROFILE)
	# Bâtiment (plan §4.1) : le compagnon y est caché, comme dans les autres intérieurs.
	root.set(&"interior", true)
	if not _kit.call(&"add_ground", MASK_PATH):
		if not _errors().is_empty():
			push_error("build_pokemon_tower :\n%s" % "\n".join(_errors()))
			_kit.call(&"discard")
			return 1
		print("build_pokemon_tower : masque écrit ; importer (--import) puis relancer")
		_kit.call(&"discard")
		return 2
	var walls := _place_walls()
	_place_stairs()
	var tombs := _place_tombs()
	_place_furniture()
	_place_passages()
	_add_life()
	if not _errors().is_empty():
		push_error("build_pokemon_tower :\n%s" % "\n".join(_errors()))
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("pokemon_tower_1f : %s (%d entités, %d au sol, murs %d faces / %d côtés / %d couronnes, "
		% [error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z]
		+ "%d tombes, %d halos, %d nœuds)" % [tombs, counts.z, result.y])
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


# --- Murs ---------------------------------------------------------------------------------


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y


## Paroi : mur `K` ou escalier `S` (pris dans le mur) ; un repère (chandelier) compte comme
## ouvert (il s'y voit, le mur se dessine autour). Hors de la carte = paroi.
func _is_wall(cell: Vector2i) -> bool:
	return not _in_bounds(cell) or WALL_LIKE.contains(_plan().call(&"at", cell))


func _is_masonry(cell: Vector2i) -> bool:
	return _in_bounds(cell) and _plan().call(&"at", cell) == WALL_MARK


## Face : mur dont la voisine sud est ouverte.
func _is_face(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_wall(cell + Vector2i.DOWN)


## Couronne : mur (pas une face) dont la voisine nord est ouverte.
func _is_cap(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) and not _is_wall(cell + Vector2i.UP)


## Côté : mur (pas une face) dont une voisine est ou ouest est ouverte (flancs de la porte
## comme les murs latéraux).
func _is_side(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) \
		and (not _is_wall(cell + Vector2i.LEFT) or not _is_wall(cell + Vector2i.RIGHT))


func _place_walls() -> Vector3i:
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	var faces := 0
	var caps := 0
	for y: int in SIZE.y:
		for run: Vector2i in _row_runs(y, _is_face):
			for piece: Vector2i in _pieces(run):
				var id: String = WALL_FACES[_wall_rng.randi_range(0, WALL_FACES.size() - 1)]
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, (y + 1) * TILE)
				var sprite := _module(entities, id, foot, piece.y * TILE, "Face%03d" % faces)
				sprite.flip_h = _wall_rng.randf() < 0.5
				faces += 1
		for run: Vector2i in _row_runs(y, _is_cap):
			for piece: Vector2i in _pieces(run):
				var cap_height := _texture_height(WALL_CAP)
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, y * TILE + cap_height)
				var sprite := _module(decals, WALL_CAP, foot, piece.y * TILE, "Lip%03d" % caps)
				sprite.flip_h = _wall_rng.randf() < 0.5
				caps += 1
	var sides := 0
	for x: int in SIZE.x:
		for run: Vector2i in _column_runs(x, _is_side):
			for y: int in range(run.x, run.y + 1):
				var part := SIDE_MIDDLE
				if y == run.y:
					part = SIDE_BOTTOM
				elif y == run.x:
					part = SIDE_TOP
				_side_strip(entities, Vector2i(x, y), part, "Side%03d" % sides)
				sides += 1
	return Vector3i(faces, sides, caps)


## Module de mur au pied [param foot], [param width] pixels du milieu de l'image (toute l'image
## si elle n'est pas plus large).
func _module(parent: Node, id: String, foot: Vector2, width: int, node_name: String) -> Sprite2D:
	var sprite: Sprite2D = _kit.call(&"add_sprite", parent, id, foot, node_name)
	var size := sprite.texture.get_size()
	var w := minf(float(width), size.x)
	if w < size.x:
		sprite.region_enabled = true
		sprite.region_rect = Rect2((size.x - w) / 2.0, 0.0, w, size.y)
		sprite.offset = Vector2(-w / 2.0, -size.y)
	var value := 1.0 + _wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)
	return sprite


## Tranche d'une case du bord latéral, collée au bord du sol (à l'est ou à l'ouest de la case).
func _side_strip(parent: Node, cell: Vector2i, part: int, node_name: String) -> void:
	var floor_east := not _is_wall(cell + Vector2i.RIGHT)
	var centre_x := (cell.x + 1) * TILE - SIDE_WIDTH / 2.0 if floor_east \
		else cell.x * TILE + SIDE_WIDTH / 2.0
	var foot := Vector2(centre_x, (cell.y + 1) * TILE)
	var sprite: Sprite2D = _kit.call(&"add_sprite", parent, WALL_SIDE, foot, node_name)
	var size := sprite.texture.get_size()
	var y0 := 0.0
	if part == SIDE_MIDDLE:
		y0 = floorf((size.y - TILE) / 2.0)
	elif part == SIDE_BOTTOM:
		y0 = size.y - TILE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, y0, size.x, TILE)
	sprite.offset = Vector2(-size.x / 2.0, -TILE)
	var value := 1.0 + _wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)


func _texture_height(id: String) -> float:
	var scene: PackedScene = _kit.call(&"scene", id)
	var model := scene.instantiate()
	var height := float((model.get_node(^"Sprite") as Sprite2D).texture.get_height())
	model.free()
	return height


## Étendues [début, fin] (colonnes incluses) de la rangée [param y] où [param test] est vrai.
func _row_runs(y: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for x: int in SIZE.x + 1:
		var inside := x < SIZE.x and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = x
		elif not inside and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


## Étendues [début, fin] (rangées incluses) de la colonne [param x] où [param test] est vrai.
func _column_runs(x: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for y: int in SIZE.y + 1:
		var inside := y < SIZE.y and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = y
		elif not inside and start >= 0:
			runs.append(Vector2i(start, y - 1))
			start = -1
	return runs


## Découpe d'une étendue en modules de [constant WALL_SPAN] cases : (début, largeur). Le dernier
## recouvre le précédent pour finir au bout ; une case seule = un module découpé.
func _pieces(run: Vector2i) -> Array[Vector2i]:
	var pieces: Array[Vector2i] = []
	var length := run.y - run.x + 1
	if length < WALL_SPAN:
		pieces.append(Vector2i(run.x, length))
		return pieces
	var left := run.x
	while left + WALL_SPAN <= run.y + 1:
		pieces.append(Vector2i(left, WALL_SPAN))
		left += WALL_SPAN
	if left <= run.y:
		pieces.append(Vector2i(run.y + 1 - WALL_SPAN, WALL_SPAN))
	return pieces


# --- Escalier, tombes, mobilier ------------------------------------------------------------


## Escalier montant pris dans le mur (couche du sol, case praticable `S`).
func _place_stairs() -> void:
	for cell: Vector2i in _plan().call(&"cells_of", "S"):
		_kit.call(&"add_floor_prop", STAIRS, cell, "Stairs")


## Tombes `g` : trois variantes à la graine (nue, bouquet, offrande) ; les tombes nommées sont
## toujours le bouquet ou l'offrande. Renvoie leur nombre.
func _place_tombs() -> int:
	var entities: Node2D = _kit.get(&"entities")
	var named: Dictionary = {}
	for id: String in NAMED_TOMBS:
		for cell: Vector2i in _plan().call(&"cells_at", id):
			named[cell] = true
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "g"):
		var roll := _tomb_rng.randf()
		var variant := 0 if roll < 0.5 else (1 if roll < 0.75 else 2)
		if named.has(cell) and variant == 0:
			variant = 1 + _tomb_rng.randi_range(0, 1)
		_kit.call(&"add_prop_at", entities, TOMBS[variant], cell, "Tomb%02d" % index)
		index += 1
	return index


## Chandeliers (halo `candle` sur chaque flamme), comptoir du gardien, bancs d'une case.
func _place_furniture() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "b"):
		_kit.call(&"add_prop_at", entities, CANDLE, cell, "Candlestick%d" % index)
		var foot: Vector2 = _kit.call(&"world", cell)
		_kit.call(&"add_glow", CANDLE_GLOW, foot - Vector2(0.0, CANDLE_LIGHT_HEIGHT),
			"GlowCandle%d" % index)
		index += 1
	var counters: Array[Vector2i] = _plan().call(&"cells_of", "W")
	if counters.size() != 4:
		_fail("comptoir : %d cases au lieu de 4" % counters.size())
	else:
		# 4 cases en ligne : le module de 4 est ancré sur la 3e case (pied sur le bord).
		_kit.call(&"add_prop_at", entities, COUNTER, counters[2], "Counter")
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		_kit.call(&"add_prop_at", entities, BENCH, cell, "Bench%d" % index)
		index += 1


## Points d'examen (T24) : 36 tombes lues de tous côtés (les 5 nommées ont leur texte), comptoir
## du gardien lu depuis le sud (le gardien est derrière). Les PNJ viennent des données.
func _add_life() -> void:
	var named: Dictionary = {}
	for i: int in NAMED_TOMBS.size():
		for cell: Vector2i in _plan().call(&"cells_at", NAMED_TOMBS[i]):
			named[cell] = NAMED_GRAVE_DIALOGUES[i]
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "g"):
		_kit.call(&"add_interactable", "GraveExamine%02d" % index, cell, Vector2i.ONE,
			Vector2i.ZERO, named.get(cell, OTHER_GRAVE_DIALOGUE))
		index += 1
	var counters: Array[Vector2i] = _plan().call(&"cells_of", "W")
	if counters.size() != 4:
		return
	_kit.call(&"add_interactable", "CounterExamine", counters[0], Vector2i(4, 1), Vector2i.UP,
		KEEPER_DIALOGUE)


func _fail(message: String) -> void:
	var errors := _errors()
	errors.append(message)
	_kit.set(&"errors", errors)


# --- Passages ---------------------------------------------------------------------------------


func _place_passages() -> void:
	var exit_cells: Array[Vector2i] = _plan().call(&"cells_at", "sortie")
	for i: int in exit_cells.size():
		_kit.call(&"add_warp", "Exit%d" % i, exit_cells[i], Kit.PUSH, Vector2i.DOWN, EXIT_MAP,
			EXIT_SPAWN, Vector2i.DOWN)
	_kit.call(&"add_spawn", "entrance", _plan().call(&"cell_of", "entree"))
	# Escalier : `pokemon_tower_2f` n'existe pas au J18 (carte du J19) → « Tour Pokémon — À venir » ;
	# retour sur la case d'accès (17, 3), tourné vers le bas. Le J19 remplace ce passage.
	var stairs: Vector2i = _plan().call(&"cell_of", "escalier")
	var access := stairs + Vector2i.DOWN
	_kit.call(&"add_spawn", String(STAIRS_SPAWN), access)
	_kit.call(&"add_warp", "Stairs2F", stairs, Kit.STEP_ON, Vector2i.UP, &"", STAIRS_SPAWN,
		Vector2i.DOWN, STAIRS_LABEL)
