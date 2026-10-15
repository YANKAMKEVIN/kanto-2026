extends SceneTree
## Construit game/world/maps/underground_path.tscn (le passage souterrain, 26 × 30 cases) d'après
## la grille `tools/plans/underground_path.txt` (elle fait foi), sur la boîte à outils
## `tools/cave_map_kit.gd` (jalon 15 T18 ; docs/tech/jalon-15.md §2.1, §2.3, §3 « T18 » ;
## dossier 18 §5, §13.1 ; fiche `serie-17-carmin.md` § « Souterrain ») :
##
##   godot --headless --path . -s res://tools/build_underground_path.gd
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import ; code 2 = masque
##   ou voile écrit, importer puis relancer)
##
## - `Ground` (invisible) = source logique : `.` `=` `E` sol calme, tout le reste solide (`#`
##   roche, `r` stèle et banc, `n` pierre descellée). Aucune herbe, aucun gravat logique (les
##   traces `=` ne sont qu'un mélange de textures, canal R du sol peint).
## - Image : sol peint (dalles, traces de passage au canal R, roche brute au canal G), murs
##   maçonnés `relief_mur_souterrain_*` sur les cases `#` qui touchent le sol (faces au sud,
##   couronnement au nord, côtés à l'est et à l'ouest), deux escaliers, stèle, banc, pierre
##   descellée, six appliques.
## - **Halos** : six `LightGlow` de type `sconce` (une par applique, ≤ `MAX_PER_MAP`), plus le
##   voile de pénombre et la lumière du sol du J12 (`tools/cave_shade.gd`) qui la portent.
## - **Catégorie** : racine **extérieure** (`interior = false`, compagnon visible), **hors**
##   `caves.json` (pas de Corde Sortie), profil `underground`, aucun sol de ciel.
## - Passages : escaliers `STEP_ON` sans direction vers les deux bâtiments d'entrée
##   (`route_5_underground_gate` en haut, `route_6_underground_gate` en bas), points d'arrivée
##   `from_route_5_w|e` et `from_route_6_w|e`. Les bâtiments sont posés par les T13 et T14 :
##   noms d'arrivée supposés `from_underground_w|e` (hypothèse, à raccorder à l'intégration).
## - Objet caché (T19) : point EXAMINER sur la pierre descellée (11, 9) (`unless_flags`
##   `got_underground_hidden_1`) ; le passant (T-18) est dans `data/npcs/underground_path.json`.

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAP_ID: StringName = &"underground_path"
const OUT_PATH: String = "res://game/world/maps/underground_path.tscn"
const PLAN_PATH: String = "res://tools/plans/underground_path.txt"
const MASK_PATH: String = "res://assets/world/maps/underground_path_ground.png"
const SHADE_PATH: String = "res://assets/world/maps/underground_path_shade.png"
const SIZE := Vector2i(26, 30)
const SEED: int = 1801
const DECOR_SEED: int = 1802
const WALL_SEED: int = 1809
const TILE: int = 96
const WALKABLE: String = ".=E"
const WALL_MARK: String = "#"
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

## Escaliers (couche du sol) : le bas de l'image au bas de la rangée de l'escalier nord, au bas
## de la dernière rangée (mur) pour l'escalier sud ; images de 2 cases de large.
const STAIRS_NORTH: String = "prop_escalier_souterrain_monte_01"
const STAIRS_SOUTH: String = "prop_escalier_souterrain_descend_01"
const STAIRS_NORTH_FOOT := Vector2(4 * TILE, 2 * TILE)
const STAIRS_SOUTH_FOOT := Vector2(20 * TILE, 30 * TILE)

## Appliques : positions de la grille → côté de la paroi (le sol est à l'est, à l'ouest ou au
## sud de la case). Halo `sconce` posé sur le verre ambré.
const SCONCE_POSITIONS: Array[String] = ["applique_1", "applique_2", "applique_3"]
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

## Passages vers les bâtiments d'entrée (posés par les T13 et T14) : nœud, case, carte, points
## d'apparition d'arrivée dans le bâtiment (hypothèse), orientation à la sortie de l'escalier.
const GATES: Array = [
	["StairsNorthW", Vector2i(3, 1), &"route_5_underground_gate", &"from_underground_w"],
	["StairsNorthE", Vector2i(4, 1), &"route_5_underground_gate", &"from_underground_e"],
	["StairsSouthW", Vector2i(19, 28), &"route_6_underground_gate", &"from_underground_w"],
	["StairsSouthE", Vector2i(20, 28), &"route_6_underground_gate", &"from_underground_e"],
]
const ARRIVALS: Array[String] = ["from_route_5", "from_route_6"]

## Objet caché (T19) : position de la grille, identifiant (dialogue, drapeau `got_<id>`).
const HIDDEN_POSITION: String = "underground_hidden_1"
const HIDDEN_ID: String = "underground_hidden_1"

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
		push_error("build_underground_path : %s" % "\n".join(_errors()))
		return 1
	_kit.call(&"make_root", "UndergroundPath", MAP_ID, DISPLAY_NAME, PROFILE)
	if not _kit.call(&"add_ground", MASK_PATH):
		if not _errors().is_empty():
			push_error("build_underground_path :\n%s" % "\n".join(_errors()))
			_kit.call(&"discard")
			return 1
		print("build_underground_path : masque écrit ; importer (--import) puis relancer")
		_kit.call(&"discard")
		return 2
	var walls := _place_walls()
	_place_stairs()
	_place_landmarks()
	_place_sconces()
	_place_passages()
	_place_hidden_item()
	if _errors().is_empty() and not _kit.call(&"add_shade", SHADE_PATH, SHADE, SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_underground_path : voile écrit ; importer (--import) puis relancer")
			_kit.call(&"discard")
			return 2
	if not _errors().is_empty():
		push_error("build_underground_path :\n%s" % "\n".join(_errors()))
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("underground_path : %s (%d entités, %d au sol, murs %d faces / %d côtés / %d couronnes, "
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
	for entry: Array in [[STAIRS_NORTH, STAIRS_NORTH_FOOT, "StairsNorth"],
			[STAIRS_SOUTH, STAIRS_SOUTH_FOOT, "StairsSouth"]]:
		var stairs: Node2D = _kit.call(&"add_prop", decals, entry[0], entry[1], entry[2])
		stairs.set(&"footprint", [] as Array[Vector2i])
		_kit.call(&"add_shade_source", &"stairs",
			(entry[1] as Vector2) - Vector2(0.0, TILE * 0.9))


func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var stele: Vector2i = _plan().call(&"cell_of", "stele_1")
	_kit.call(&"add_prop_at", entities, "prop_stele_01", stele, "Stele")
	var bench: Vector2i = _plan().call(&"cell_of", "banc_3")
	_kit.call(&"add_prop_at", entities, "prop_banc_souterrain_01", bench, "Bench")
	var stone: Vector2i = _plan().call(&"cell_of", HIDDEN_POSITION)
	_kit.call(&"add_prop_at", entities, "prop_pierre_descellee_01", stone, "LooseStone")


## Six appliques sur les cases `applique_*` : le sol est du côté est, ouest ou sud de la case ;
## l'image est faite pour un mur à gauche (miroir pour un mur à droite).
func _place_sconces() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var index := 0
	for id: String in SCONCE_POSITIONS:
		for cell: Vector2i in _plan().call(&"cells_at", id):
			if not _is_wall(cell):
				_fail("%s : %s n'est pas une paroi" % [id, cell])
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
	for id: String in ARRIVALS:
		var named: Dictionary = Kit.spawn_names(id, _plan().call(&"cells_at", id))
		for spawn_name: String in named:
			_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	for gate: Array in GATES:
		_kit.call(&"add_warp", gate[0], gate[1], Kit.STEP_ON, Vector2i.ZERO, gate[2], gate[3],
			Vector2i.DOWN)


## Point EXAMINER sur la pierre descellée (case bloquée) ; disparaît une fois la Guérison prise.
func _place_hidden_item() -> void:
	var clue: Vector2i = _plan().call(&"cell_of", HIDDEN_POSITION)
	_kit.call(&"add_interactable", "Hidden_%s" % HIDDEN_ID, clue, Vector2i.ONE, Vector2i.ZERO,
		StringName(HIDDEN_ID))
	var points := (_kit.get(&"root") as Node).get_node(^"Interactables")
	points.get_node(NodePath("Hidden_%s" % HIDDEN_ID)).set(&"unless_flags",
		[StringName("got_" + HIDDEN_ID)] as Array[StringName])
