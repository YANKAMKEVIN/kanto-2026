extends SceneTree
## Construit game/world/maps/underground_path_7_8.tscn (le souterrain ouest-est, 48 × 10 cases)
## d'après la grille `tools/plans/souterrain_7_8.txt` (elle fait foi), sur la boîte à outils
## `tools/cave_map_kit.gd` (jalon 20 T15 ; docs/tech/jalon-20.md §1.3, §2.1 ; dossier 23 §4).
## Même méthode que `build_underground_path.gd` (J15) ; art provisoire du kit du J15 (stratégie
## d'accélération).
##
##   godot --headless --path . -s res://tools/build_underground_path_7_8.gd
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import ; code 2 = masque
##   ou voile écrit, importer puis relancer)
##
## - `Ground` (invisible) = source logique : `.` `E` sol, tout le reste solide (`K` mur, `b` banc,
##   `n` pilier). Aucune herbe : **aucune rencontre** (hors `caves.json`, comme le J15).
## - **Catégorie** : racine **extérieure** (`interior = false`, compagnon visible), profil
##   `underground`, aucun sol de ciel.
## - Passages : escalier ouest (2, 5..6) STEP_ON ← → `route_7_underground_gate` /
##   `from_underground` ; escalier est (45, 7..8) STEP_ON → → `route_8_underground_gate` /
##   `from_underground` ; arrivées `from_route_7_n|s` (3, 5..6) tournées →, `from_route_8_n|s`
##   (44, 7..8) tournées ←.
## - Objets cachés : cases-indices (15, 2) et (34, 1) bloquées, carrelage fissuré ; points
##   EXAMINER (T17) `souterrain_hidden_1|2`, dialogues et scènes dans `data/`.

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAP_ID: StringName = &"underground_path_7_8"
const OUT_PATH: String = "res://game/world/maps/underground_path_7_8.tscn"
const PLAN_PATH: String = "res://tools/plans/souterrain_7_8.txt"
const MASK_PATH: String = "res://assets/world/maps/underground_path_7_8_ground.png"
const SHADE_PATH: String = "res://assets/world/maps/underground_path_7_8_shade.png"
const SIZE := Vector2i(48, 10)
const SEED: int = 2091
const DECOR_SEED: int = 2092
const WALL_SEED: int = 2093
const TILE: int = 96
const WALKABLE: String = ".E"
const WALL_MARK: String = "K"
const TRACE_MARK: String = "="
const PROFILE: StringName = &"underground"
const DISPLAY_NAME: String = "Passage souterrain"

const GROUND_DALLES: String = "res://assets/world/ground/ground_dalles_souterrain_01.png"
const GROUND_TRACES: String = "res://assets/world/ground/ground_traces_souterrain_01.png"
const GROUND_ROCK: String = "res://assets/world/ground/ground_masse_roche_01.png"
## Bande de frontière entre sols : pierre claire (le mélange dalles / traces ne doit pas dessiner
## de liseré sombre).
const BORDER_COLOR := Color(0.46, 0.43, 0.38)

## Murs maçonnés : faces (2 cases de large, 89 px), couronnement (33 px), côté (34 × 146 px).
const WALL_FACES: Array[String] = ["relief_mur_souterrain_01", "relief_mur_souterrain_02"]
const WALL_CAP: String = "relief_mur_souterrain_03"
const WALL_SIDE: String = "relief_mur_souterrain_04"
const WALL_SPAN: int = 2
const SIDE_WIDTH: int = 34
const SIDE_TOP: int = 0
const SIDE_MIDDLE: int = 1
const SIDE_BOTTOM: int = 2
const WALL_VALUE_JITTER: float = 0.04

## Escaliers (couche du sol, provisoires) : l'image d'escalier du J15 posée sur les deux cases
## de chaque escalier latéral (pied au bas de la case du bas).
const STAIRS: Array = [
	["prop_escalier_souterrain_monte_01", Vector2(2.5 * TILE, 7 * TILE), "StairsWest"],
	["prop_escalier_souterrain_monte_01", Vector2(45.5 * TILE, 9 * TILE), "StairsEast"],
]

## Appliques : positions de la grille → côté de la paroi (le sol est à l'est, à l'ouest ou au
## sud de la case). Halo `sconce` posé sur le verre ambré.
## Appliques sur des murs dont la voisine sud est le couloir (la grille n'en place pas) [D].
const SCONCE_CELLS: Array[Vector2i] = [Vector2i(5, 4), Vector2i(19, 4), Vector2i(30, 6),
	Vector2i(40, 6)]
const SCONCE_FOOT_RAISE: float = 14.0
const SCONCE_LIGHT_HEIGHT: float = 46.0
const SCONCE_SIDE_INSET: float = 22.0

## Voile de pénombre (réglages de `tools/cave_shade.gd`) : plus clair et plus chaud que les
## grottes, la lumière vient des appliques [D, à régler sur capture].
const SHADE := {"ambient": 0.9, "edge_min": 0.72, "edge_radius": 0.8, "room_min": 0.9,
	"room_radius": 3.0, "tint": Color(1.0, 0.93, 0.84)}
const SHADE_LIGHTS: Dictionary = {
	&"sconce": {"radius": 3.6, "strength": 0.95, "offset": Vector2(0.0, 30.0), "add": 0.2,
		"color": Color(1.0, 0.74, 0.42)},
	&"stairs": {"radius": 3.0, "strength": 0.9, "offset": Vector2.ZERO, "add": 0.06,
		"color": Color(1.0, 0.88, 0.7)},
}
const SHADE_WALL_FOLLOW: float = 0.7

## Passages : [nœud, case, direction, bâtiment] ; retour dans le bâtiment `from_underground`.
const GATES: Array = [
	["StairsWestN", Vector2i(2, 5), Vector2i.LEFT, &"route_7_underground_gate"],
	["StairsWestS", Vector2i(2, 6), Vector2i.LEFT, &"route_7_underground_gate"],
	["StairsEastN", Vector2i(45, 7), Vector2i.RIGHT, &"route_8_underground_gate"],
	["StairsEastS", Vector2i(45, 8), Vector2i.RIGHT, &"route_8_underground_gate"],
]
## Arrivées : [position de la grille, préfixe du nom] (suffixes `_n|s`).
const ARRIVALS: Array = [["from_entree_r7", "from_route_7"], ["from_entree_r8", "from_route_8"]]
## Objets cachés : positions de la grille (identifiant = dialogue, drapeau `got_<id>`).
const HIDDEN: Array[String] = ["souterrain_hidden_1", "souterrain_hidden_2"]

var _kit: Object
var _wall_rng := RandomNumberGenerator.new()


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, WALKABLE)
	_kit.set(&"floor_texture_path", GROUND_DALLES)
	_kit.set(&"rubble_texture_path", GROUND_TRACES)
	_kit.set(&"mass_texture_path", GROUND_ROCK)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_mark", TRACE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_wall_rng.seed = WALL_SEED
	quit(_build())


## 0 : enregistré ; 2 : masque ou voile écrit, importer puis relancer ; 1 : erreur.
func _build() -> int:
	if not _errors().is_empty():
		push_error("build_underground_path_7_8 : %s" % "\n".join(_errors()))
		return 1
	_kit.set(&"wall_marks", WALL_MARK)
	_kit.call(&"make_root", "UndergroundPath78", MAP_ID, DISPLAY_NAME, PROFILE)
	if not _kit.call(&"add_ground", MASK_PATH):
		if not _errors().is_empty():
			push_error("build_underground_path_7_8 :\n%s" % "\n".join(_errors()))
			_kit.call(&"discard")
			return 1
		print("build_underground_path_7_8 : masque écrit ; importer (--import) puis relancer")
		_kit.call(&"discard")
		return 2
	var walls := _place_walls()
	_place_stairs()
	_place_landmarks()
	_place_sconces()
	_place_passages()
	if _errors().is_empty() and not _kit.call(&"add_shade", SHADE_PATH, SHADE, SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_underground_path_7_8 : voile écrit ; importer (--import) puis relancer")
			_kit.call(&"discard")
			return 2
	if not _errors().is_empty():
		push_error("build_underground_path_7_8 :\n%s" % "\n".join(_errors()))
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("underground_path_7_8 : %s (%d entités, %d au sol, murs %d faces / %d côtés / %d couronnes, "
		% [error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z]
		+ "%d halos, %d nœuds)" % [counts.z, result.y])
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _fail(message: String) -> void:
	var errors := _errors()
	errors.append(message)
	_kit.set(&"errors", errors)


# --- Murs ---------------------------------------------------------------------------------


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y


## Paroi : roche `#` ; une case de repère (stèle, banc, pierre) compte comme ouverte (le repère
## s'y voit, le mur se dessine autour). Hors de la carte = paroi.
func _is_wall(cell: Vector2i) -> bool:
	return not _in_bounds(cell) or _plan().call(&"at", cell) == WALL_MARK


func _is_masonry(cell: Vector2i) -> bool:
	return _in_bounds(cell) and _plan().call(&"at", cell) == WALL_MARK


## Face : paroi dont la voisine sud est ouverte.
func _is_face(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_wall(cell + Vector2i.DOWN)


## Couronne : paroi (pas une face) dont la voisine nord est ouverte.
func _is_cap(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) and not _is_wall(cell + Vector2i.UP)


## Côté : paroi (pas une face) dont une voisine est ou ouest est ouverte.
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


## Module de paroi au pied [param foot], [param width] pixels du milieu de l'image (toute
## l'image si elle n'est pas plus large).
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


## Tranche d'une case du côté, collée au bord du sol (à l'est ou à l'ouest de la case).
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


# --- Escaliers, repères --------------------------------------------------------------------


func _place_stairs() -> void:
	var decals: Node2D = _kit.get(&"decals")
	for entry: Array in STAIRS:
		var stairs: Node2D = _kit.call(&"add_prop", decals, entry[0], entry[1], entry[2])
		stairs.set(&"footprint", [] as Array[Vector2i])
		_kit.call(&"add_shade_source", &"stairs",
			(entry[1] as Vector2) - Vector2(0.0, TILE * 0.9))


## Bancs `b`, pilier `n`, indices des objets cachés (carrelage fissuré).
func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "b"):
		_kit.call(&"add_prop_at", entities, "prop_banc_souterrain_01", cell, "Bench%d" % index)
		index += 1
	for cell: Vector2i in _plan().call(&"cells_of", "n"):
		_kit.call(&"add_prop_at", entities, "prop_stele_01", cell, "Pillar")
	for i: int in HIDDEN.size():
		var cell: Vector2i = _plan().call(&"cell_of", HIDDEN[i])
		_kit.call(&"add_prop_at", entities, "prop_pierre_descellee_01", cell, "CrackedTile%d" % i)
		# Point EXAMINER (T17) : de tous côtés, il disparaît quand `got_<id>` est levé.
		_kit.call(&"add_interactable", "Hidden%d" % (i + 1), cell, Vector2i.ONE, Vector2i.ZERO,
			StringName(HIDDEN[i]))
		var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
		var unless: Array[StringName] = [StringName("got_" + HIDDEN[i])]
		point.set(&"unless_flags", unless)


## Appliques sur [constant SCONCE_CELLS] : le sol est du côté est, ouest ou sud de la case ;
## l'image est faite pour un mur à gauche (miroir pour un mur à droite).
func _place_sconces() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var index := 0
	for cell: Vector2i in SCONCE_CELLS:
		if true:
			if not _is_wall(cell):
				_fail("applique : %s n'est pas une paroi" % cell)
				continue
			var foot := Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE - SCONCE_FOOT_RAISE)
			var mirror := false
			var floor_east := not _is_wall(cell + Vector2i.RIGHT)
			var floor_west := not _is_wall(cell + Vector2i.LEFT)
			var shift := 0.0
			if floor_east and not floor_west:
				foot.x = (cell.x + 1) * TILE - SCONCE_SIDE_INSET
				shift = 4.0
			elif floor_west and not floor_east:
				foot.x = cell.x * TILE + SCONCE_SIDE_INSET
				mirror = true
				shift = -4.0
			var lamp: Sprite2D = _kit.call(&"add_sprite", entities, "prop_applique_01", foot,
				"Sconce%d" % index)
			lamp.flip_h = mirror
			# Triée après le mur sur lequel elle est fixée : le pied passe sous le sien (+ 2 px),
			# l'image est relevée d'autant (même rendu).
			lamp.position.y += SCONCE_FOOT_RAISE + 2.0
			lamp.offset.y -= SCONCE_FOOT_RAISE + 2.0
			_kit.call(&"add_glow", &"sconce",
				foot + Vector2(shift, -SCONCE_LIGHT_HEIGHT), "GlowSconce%d" % index)
			index += 1


# --- Passages, objet caché ---------------------------------------------------------------------


func _place_passages() -> void:
	for entry: Array in ARRIVALS:
		var cells: Array[Vector2i] = _plan().call(&"cells_at", entry[0])
		var named: Dictionary = Kit.spawn_names(entry[1], cells)
		for spawn_name: String in named:
			_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	for gate: Array in GATES:
		if ResourceLoader.exists("res://game/world/maps/%s.tscn" % gate[3]):
			_kit.call(&"add_warp", gate[0], gate[1], Kit.STEP_ON, gate[2], gate[3],
				&"from_underground", Vector2i.DOWN)
		else:
			# Bâtiment pas encore construit : « à venir », retour sur l'arrivée de ce côté.
			var back := "from_route_7_n" if gate[2] == Vector2i.LEFT else "from_route_8_n"
			_kit.call(&"add_warp", gate[0], gate[1], Kit.STEP_ON, gate[2], &"",
				StringName(back), -gate[2], "Passage souterrain")
