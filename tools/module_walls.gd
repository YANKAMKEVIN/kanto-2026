extends RefCounted
## Murs **en modules** d'un intérieur bâti sur `tools/cave_map_kit.gd` (série 22 bis, repaire
## Rocket et Casino ; fiche `serie-22bis-celadopole.md` §B, point technique Q-2), aux rôles des
## murs de la Tour (`tools/build_pokemon_tower.gd`, `relief_mur_tour_*`) :
## - **face** (01 / 02, deux cases de large) sur chaque case de maçonnerie dont la voisine sud est
##   ouverte ; elle déborde d'une case vers le haut sur la maçonnerie du dessus (mur épais) ;
## - **mur mince** (la voisine nord est ouverte aussi : cloison d'une case entre deux salles) : la
##   face est coupée à la case (bas de l'image) et coiffée du couronnement (03), rien ne déborde
##   sur le sol du nord ;
## - **couronnement** (03) au bord nord des maçonneries (sol au nord), couche du sol ;
## - **bord latéral** (04, tranches d'une case) le long du sol à l'est **et** à l'ouest (une
##   cloison verticale d'une case reçoit les deux bords).
## L'angle (05) n'est pas posé, comme à la Tour : le haut du bord latéral fait l'angle.
## Le reste de la maçonnerie montre la masse sombre du sol peint (canal G du kit) : c'est elle qui
## remplit le haut d'un mur du fond de plus de trois rangées (Casino, B2F).
##
## Utilisé par `load("res://tools/module_walls.gd").new(kit, ...)` puis [method place].

const TILE: int = 96
const WALL_SPAN: int = 2
const SIDE_TOP: int = 0
const SIDE_MIDDLE: int = 1
const SIDE_BOTTOM: int = 2
const WALL_VALUE_JITTER: float = 0.04

var _kit: Object
var _size: Vector2i
## Caractères qui reçoivent les modules.
var _masonry: String
## Caractères qui comptent comme paroi (aucun bord ni face à côté d'eux) : la maçonnerie et les
## repères pris dans le mur (escalier du Casino).
var _wall_like: String
var _faces: Array[String] = []
var _cap: String
var _side: String
var _rng := RandomNumberGenerator.new()


## [param prefix] : `relief_mur_repaire` ou `relief_mur_casino` (modules `_01` à `_04`).
func _init(kit: Object, prefix: String, masonry: String, wall_like: String,
		seed_value: int) -> void:
	_kit = kit
	_size = kit.get(&"size")
	_masonry = masonry
	_wall_like = wall_like
	_faces = [prefix + "_01", prefix + "_02"]
	_cap = prefix + "_03"
	_side = prefix + "_04"
	_rng.seed = seed_value


## Pose les murs ; renvoie (faces, bords, couronnements).
func place() -> Vector3i:
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	var cap_height := _texture(_cap).get_height()
	var faces := 0
	var caps := 0
	for y: int in _size.y:
		for thin: bool in [false, true]:
			var test := _is_thin_face if thin else _is_thick_face
			for run: Vector2i in _row_runs(y, test):
				for piece: Vector2i in _pieces(run):
					var id: String = _faces[_rng.randi_range(0, _faces.size() - 1)]
					var foot := Vector2((piece.x + piece.y / 2.0) * TILE, (y + 1) * TILE)
					var flip := _rng.randf() < 0.5
					var width := piece.y * TILE
					if thin:
						var face_height := TILE - cap_height
						var image_height := _texture(id).get_height()
						_strip(entities, id, foot, width, image_height - face_height, face_height,
							face_height, flip, "Face%03d" % faces)
						_strip(entities, _cap, foot, width, 0, cap_height, TILE, flip,
							"FaceTop%03d" % faces)
					else:
						_strip(entities, id, foot, width, 0, -1, -1, flip, "Face%03d" % faces)
					faces += 1
		for run: Vector2i in _row_runs(y, _is_cap):
			for piece: Vector2i in _pieces(run):
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, y * TILE + cap_height)
				_strip(decals, _cap, foot, piece.y * TILE, 0, -1, -1, _rng.randf() < 0.5,
					"Lip%03d" % caps)
				caps += 1
	var sides := 0
	for x: int in _size.x:
		for run: Vector2i in _column_runs(x, _is_side):
			for y: int in range(run.x, run.y + 1):
				var part := SIDE_MIDDLE
				if y == run.y:
					part = SIDE_BOTTOM
				elif y == run.x:
					part = SIDE_TOP
				var cell := Vector2i(x, y)
				for east: bool in [false, true]:
					var next := cell + (Vector2i.RIGHT if east else Vector2i.LEFT)
					if not _is_wall(next):
						_side_strip(entities, cell, east, part, "Side%03d" % sides)
						sides += 1
	return Vector3i(faces, sides, caps)


# --- Rôles des cases ----------------------------------------------------------------------


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func _at(cell: Vector2i) -> String:
	return (_kit.get(&"plan") as Object).call(&"at", cell)


## Paroi (hors de la carte compris) : tout le reste est ouvert (sol, mobilier, portes).
func _is_wall(cell: Vector2i) -> bool:
	return not _in_bounds(cell) or _wall_like.contains(_at(cell))


func _is_masonry(cell: Vector2i) -> bool:
	return _in_bounds(cell) and _masonry.contains(_at(cell))


func _is_face(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_wall(cell + Vector2i.DOWN)


## Face d'un mur épais (maçonnerie au nord, dans la carte : le module déborde sur elle).
func _is_thick_face(cell: Vector2i) -> bool:
	return _is_face(cell) and _in_bounds(cell + Vector2i.UP) and _is_wall(cell + Vector2i.UP)


## Face d'un mur mince (sol au nord, ou bord nord de la carte : coupée à la case, coiffée du
## couronnement, rien ne dépasse de la carte).
func _is_thin_face(cell: Vector2i) -> bool:
	return _is_face(cell) and not _is_thick_face(cell)


func _is_cap(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) and not _is_wall(cell + Vector2i.UP)


func _is_side(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) \
		and (not _is_wall(cell + Vector2i.LEFT) or not _is_wall(cell + Vector2i.RIGHT))


# --- Sprites ------------------------------------------------------------------------------


## Bande du module [param id] : [param width] pixels du milieu de l'image, lignes
## [param src_y] à [param src_y] + [param height] (−1 : jusqu'en bas), dessinée de façon que son
## haut soit [param top] pixels au-dessus du pied (−1 : bas de la bande sur le pied).
func _strip(parent: Node, id: String, foot: Vector2, width: int, src_y: int, height: int,
		top: int, flip: bool, node_name: String) -> Sprite2D:
	var sprite: Sprite2D = _kit.call(&"add_sprite", parent, id, foot, node_name)
	var size := sprite.texture.get_size()
	var w := minf(float(width), size.x)
	var h := size.y - src_y if height < 0 else float(height)
	var above := h if top < 0 else float(top)
	sprite.position = foot.round()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2((size.x - w) / 2.0, float(src_y), w, h)
	sprite.offset = Vector2(-w / 2.0, -above)
	sprite.flip_h = flip
	_jitter(sprite)
	return sprite


## Tranche d'une case du bord latéral, collée au bord du sol ([param east] : sol à l'est).
func _side_strip(parent: Node, cell: Vector2i, east: bool, part: int, node_name: String) -> void:
	var size := _texture(_side).get_size()
	var centre_x := (cell.x + 1) * TILE - size.x / 2.0 if east else cell.x * TILE + size.x / 2.0
	var y0 := 0
	if part == SIDE_MIDDLE:
		y0 = floori((size.y - TILE) / 2.0)
	elif part == SIDE_BOTTOM:
		y0 = int(size.y) - TILE
	_strip(parent, _side, Vector2(centre_x, (cell.y + 1) * TILE), int(size.x), y0, TILE, TILE,
		not east, node_name)


func _jitter(sprite: Sprite2D) -> void:
	var value := 1.0 + _rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)


func _texture(id: String) -> Texture2D:
	var model := (_kit.call(&"scene", id) as PackedScene).instantiate()
	var texture := (model.get_node(^"Sprite") as Sprite2D).texture
	model.free()
	return texture


# --- Étendues -----------------------------------------------------------------------------


func _row_runs(y: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for x: int in _size.x + 1:
		var inside := x < _size.x and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = x
		elif not inside and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


func _column_runs(x: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for y: int in _size.y + 1:
		var inside := y < _size.y and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = y
		elif not inside and start >= 0:
			runs.append(Vector2i(start, y - 1))
			start = -1
	return runs


## Modules de [constant WALL_SPAN] cases (début, largeur) ; le dernier recouvre le précédent pour
## finir au bout ; une case seule = un module découpé.
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
