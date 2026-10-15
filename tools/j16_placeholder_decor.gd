extends RefCounted
## Décor **provisoire** des cartes du jalon 16 (T11 : les 9 pièces du S.S. Anne et l'Arène de
## Carmin), dessiné en polygones **à plat** sous les personnages, lu sur la grille fonctionnelle
## (`tools/plans/*.txt`, qui fait foi) : sol (texture répétée), murs du fond (face visible, hublots
## ou néons), bords des murs, portes, escaliers, sorties, mer, et le mobilier de la légende en
## blocs vus de trois quarts. **Aucune logique** : les cases solides viennent de la grille
## (`GameMap.blocked_cells`, écrites par `build_painted_interiors.gd`). Au T10, l'enveloppe peinte
## (`"shell"`) et les meubles de la série 18 (`"props"`, `"furniture"`) remplacent ce nœud sans
## toucher aux grilles : la pièce perd sa clé `"placeholder"`.
##
## Utilisé par `build_painted_interiors.gd` : `load("res://tools/j16_placeholder_decor.gd").new()`
## puis [method build] ; renvoie le nœud `PlaceholderDecor` (z du sol peint).
##
## Styles : `ship` (parquet, murs crème et lambris, hublots), `restaurant` (idem, comptoir de
## cuisine en inox), `cabin` (moquette, même murs),
## `deck` (pont en planches, superstructure blanche, mer), `gym` (dalles d'acier, néons bleus).

const TILE := 96
const Z_GROUND := -3
const TEX_PARQUET := "res://assets/world/interiors/provisoire/prov_parquet_01.png"
const TEX_STEEL := "res://assets/world/interiors/provisoire/prov_tole_01.png"
const TEX_CARPET := "res://assets/world/interiors/provisoire/prov_moquette_01.png"
const TEX_DECK := "res://assets/world/ground/ground_planches_quai_01.png"
const TEX_SEA := "res://assets/world/ground/ground_eau_01.png"
## Caractères de la grille qui ne sont pas du sol : mur et mer.
const WALL := "K"
const SEA := "w"
const OUT := "#"

const OUTSIDE := Color(0.11, 0.1, 0.13)
const TRIM := Color(0.42, 0.27, 0.16)
const TRIM_DARK := Color(0.2, 0.13, 0.09)
const BRASS := Color(0.82, 0.64, 0.3)
const WOOD := Color(0.5, 0.31, 0.18)
const WOOD_DARK := Color(0.33, 0.2, 0.12)
const SHADOW := Color(0, 0, 0, 0.28)

var _root: Node
var _decor: Node2D
var _plan: Object
var _style: StringName
var _textures: Dictionary = {}
var _count: int = 0


## Construit le décor de [param plan] (une `PlanGrid` lue) dans [param root] (racine de la carte,
## propriétaire des nœuds) au style [param style] ; renvoie le nœud `PlaceholderDecor`.
func build(root: Node, plan: Object, style: StringName) -> Node2D:
	_root = root
	_plan = plan
	_style = style
	_decor = Node2D.new()
	_decor.name = "PlaceholderDecor"
	_decor.z_index = Z_GROUND
	_attach(root, _decor)
	var size := Vector2(_plan.get(&"width"), _plan.get(&"height")) * TILE
	_poly(Rect2(Vector2.ZERO, size), _outside_color())
	_floors()
	_sea()
	_walls()
	_furniture()
	_openings()
	return _decor


## Nombre de polygones posés (budget de nœuds).
func get_count() -> int:
	return _count


# --- Sol, mer, murs -------------------------------------------------------------------------

func _floors() -> void:
	var cells := _cells(func(c: String) -> bool: return c != WALL and c != SEA)
	var texture := _floor_texture()
	for rect: Rect2i in _rects(cells):
		_poly(_px(rect), Color.WHITE, texture)


func _sea() -> void:
	var cells := _cells(func(c: String) -> bool: return c == SEA)
	for rect: Rect2i in _rects(cells):
		_poly(_px(rect), Color(0.92, 0.97, 1.0), _texture(TEX_SEA))
	# Coque blanche sous la rambarde du sud (le flanc du navire, vu d'en haut).
	for cell: Vector2i in cells:
		if _at(cell + Vector2i.UP) == "r":
			var r := _px(Rect2i(cell, Vector2i.ONE))
			_poly(Rect2(r.position, Vector2(TILE, 34)), Color(0.93, 0.93, 0.9))
			_poly(Rect2(r.position + Vector2(0, 34), Vector2(TILE, 14)), Color(0.13, 0.2, 0.42))
			if cell.x % 2 == 0:
				_circle(r.position + Vector2(48, 17), 7.0, BRASS)
				_circle(r.position + Vector2(48, 17), 5.0, Color(0.35, 0.55, 0.8))


func _walls() -> void:
	var faces: Array[Vector2i] = []
	for cell: Vector2i in _cells(func(c: String) -> bool: return c == WALL or c == "D"):
		if _is_back_wall(cell):
			faces.append(cell)
	for rect: Rect2i in _rects(faces):
		_wall_face(_px(rect))
	for cell: Vector2i in faces:
		var below := cell + Vector2i.DOWN
		if _at(cell) == WALL and cell.x % 3 == 1 and _at(cell + Vector2i.LEFT) != "D" \
				and _at(cell + Vector2i.RIGHT) != "D":
			_wall_ornament(_px(Rect2i(cell, Vector2i.ONE)))
		# Ombre portée du mur sur le sol (dégradé).
		if _is_floor(below):
			var r := _px(Rect2i(below, Vector2i.ONE))
			_gradient(Rect2(r.position, Vector2(TILE, 26)), SHADOW, Color(0, 0, 0, 0))
	# Bords des murs latéraux et du bas : liseré du côté du sol.
	for cell: Vector2i in _cells(func(c: String) -> bool: return c == WALL):
		var r := _px(Rect2i(cell, Vector2i.ONE))
		if _style == &"deck":
			_deck_superstructure(cell, r)
			continue
		if _is_floor(cell + Vector2i.RIGHT):
			_poly(Rect2(r.end.x - 14, r.position.y, 14, TILE), _trim())
			_poly(Rect2(r.end.x - 18, r.position.y, 4, TILE), TRIM_DARK)
		if _is_floor(cell + Vector2i.LEFT):
			_poly(Rect2(r.position.x, r.position.y, 14, TILE), _trim())
			_poly(Rect2(r.position.x + 14, r.position.y, 4, TILE), TRIM_DARK)
		if _is_floor(cell + Vector2i.UP):
			_poly(Rect2(r.position.x, r.position.y, TILE, 14), _trim())
			_poly(Rect2(r.position.x, r.position.y + 14, TILE, 4), TRIM_DARK)


## Mur du fond : case de mur (ou porte percée dedans) qui a du sol juste au sud et un mur au nord.
func _is_back_wall(cell: Vector2i) -> bool:
	if _style == &"deck":
		return false
	var above := _at(cell + Vector2i.UP)
	var below := _at(cell + Vector2i.DOWN)
	# Au-dessus d'une porte latérale ou d'une sortie : bord de mur, pas mur du fond.
	return _is_floor(cell + Vector2i.DOWN) and below != "D" and below != "X" \
		and (above == WALL or above == OUT)


func _wall_face(r: Rect2) -> void:
	if _style == &"gym":
		_poly(r, Color(0.24, 0.27, 0.33))
		_poly(Rect2(r.position.x, r.end.y - 30, r.size.x, 30), Color(0.17, 0.19, 0.24))
		_poly(Rect2(r.position.x, r.end.y - 6, r.size.x, 6), Color(0.85, 0.7, 0.2))
		_poly(Rect2(r.position, Vector2(r.size.x, 8)), Color(0.08, 0.09, 0.12))
		return
	# Crème en haut, lambris de bois en bas, baguette de laiton entre les deux.
	_poly(r, Color(0.93, 0.87, 0.74))
	_poly(Rect2(r.position.x, r.end.y - 40, r.size.x, 40), WOOD)
	_poly(Rect2(r.position.x, r.end.y - 42, r.size.x, 3), BRASS)
	_poly(Rect2(r.position.x, r.end.y - 6, r.size.x, 6), WOOD_DARK)
	_poly(Rect2(r.position, Vector2(r.size.x, 10)), TRIM_DARK)


## Hublot (navire) ou néon (Arène) sur une case du mur du fond.
func _wall_ornament(r: Rect2) -> void:
	if _style == &"gym":
		_poly(Rect2(r.position.x + 10, r.position.y + 18, 76, 12), Color(0.55, 0.8, 1.0))
		_poly(Rect2(r.position.x + 14, r.position.y + 21, 68, 6), Color(0.88, 0.97, 1.0))
		return
	var c := r.position + Vector2(48, 36)
	_circle(c, 19.0, BRASS)
	_circle(c, 14.0, Color(0.42, 0.66, 0.9))
	_circle(c + Vector2(-4, -4), 5.0, Color(0.8, 0.92, 1.0))


## Superstructure blanche du pont extérieur (colonne ouest) : blanc, arête ombrée côté pont,
## hublots.
func _deck_superstructure(cell: Vector2i, r: Rect2) -> void:
	_poly(r, Color(0.9, 0.9, 0.87))
	if _is_floor(cell + Vector2i.RIGHT) or _at(cell + Vector2i.RIGHT) == "D":
		_poly(Rect2(r.end.x - 10, r.position.y, 10, TILE), Color(0.62, 0.63, 0.62))
	if cell.y % 2 == 0 and _at(cell + Vector2i.RIGHT) != "D":
		_circle(r.position + Vector2(44, 48), 11.0, BRASS)
		_circle(r.position + Vector2(44, 48), 8.0, Color(0.38, 0.62, 0.88))


# --- Mobilier ---------------------------------------------------------------------------------

func _furniture() -> void:
	for chr: String in "bctxnLaNvgklurimB":
		var cells := _cells(func(c: String) -> bool: return c == chr)
		if chr in ["k", "i", "u", "x", "l", "m"]:
			for cell: Vector2i in cells:
				_piece(chr, _px(Rect2i(cell, Vector2i.ONE)), Rect2i(cell, Vector2i.ONE))
		else:
			for rect: Rect2i in _rects(cells):
				_piece(chr, _px(rect), rect)


func _piece(chr: String, r: Rect2, cells: Rect2i) -> void:
	match chr:
		"b":  # banquette : dossier, assise rouges, cadre de bois
			_block(r.grow(-6), Color(0.66, 0.2, 0.22), WOOD_DARK, 0.28)
			_poly(Rect2(r.position.x + 10, r.position.y + 10, r.size.x - 20, 22),
				Color(0.52, 0.14, 0.17))
		"c":
			if _style == &"restaurant":
				# Comptoir de la cuisine (restaurant) : inox.
				_block(r.grow_individual(-4, -10, -4, -4), Color(0.78, 0.8, 0.82),
					Color(0.5, 0.52, 0.56), 0.4)
			else:
				# Comptoir d'accueil : bois verni, bandeau de laiton, sonnette.
				_block(r.grow_individual(-4, -18, -4, -4), Color(0.56, 0.35, 0.2), WOOD_DARK,
					0.45)
				_poly(Rect2(r.position.x + 4, r.end.y - 18, r.size.x - 8, 4), BRASS)
				_circle(r.position + Vector2(r.size.x * 0.6, 40), 7.0, BRASS)
		"t":  # table nappée
			_block(r.grow(-8), Color(0.96, 0.95, 0.9), Color(0.82, 0.8, 0.74), 0.3)
			_circle(r.position + Vector2(r.size.x * 0.5, 34), 9.0, Color(0.85, 0.3, 0.3))
		"n":  # table sous le hublot
			_block(r.grow_individual(-6, -14, -6, -10), Color(0.55, 0.36, 0.22), WOOD_DARK, 0.35)
		"L":  # lit : cadre, drap, oreiller, couverture
			_block(r.grow(-4), WOOD, WOOD_DARK, 0.12)
			_poly(r.grow_individual(-12, -12, -12, -22), Color(0.95, 0.95, 0.93))
			_poly(Rect2(r.position.x + 18, r.position.y + 16, r.size.x - 36, 30),
				Color(1, 1, 1))
			_poly(Rect2(r.position.x + 12, r.position.y + 62, r.size.x - 24, r.size.y - 84),
				Color(0.25, 0.38, 0.62))
		"a":  # armoire
			_block(r.grow_individual(-8, -2, -8, -4), Color(0.5, 0.31, 0.18), WOOD_DARK, 0.75)
			_poly(Rect2(r.get_center().x - 1, r.position.y + 30, 2, r.size.y - 36), TRIM_DARK)
		"N":  # bureau du capitaine, papiers
			_block(r.grow_individual(-4, -10, -4, -6), Color(0.38, 0.23, 0.14), TRIM_DARK, 0.4)
			_poly(Rect2(r.position.x + 30, r.position.y + 22, 40, 26), Color(0.95, 0.93, 0.85))
			_poly(Rect2(r.position.x + 120, r.position.y + 24, 30, 20), Color(0.9, 0.86, 0.7))
		"v":  # lavabo
			_block(r.grow_individual(-14, -6, -14, -20), Color(0.95, 0.96, 0.97),
				Color(0.75, 0.77, 0.8), 0.35)
			_circle(r.position + Vector2(48, 34), 14.0, Color(0.7, 0.8, 0.88))
		"g":  # carte marine encadrée, posée contre le mur
			_block(r.grow_individual(-10, -4, -10, -30), WOOD_DARK, TRIM_DARK, 0.15)
			_poly(r.grow_individual(-18, -12, -18, -44), Color(0.9, 0.84, 0.64))
			_poly(Rect2(r.position.x + 40, r.position.y + 30, 60, 4), Color(0.3, 0.45, 0.65))
		"k":  # caisse de bois
			_block(r.grow(-5), Color(0.66, 0.5, 0.3), Color(0.45, 0.32, 0.18), 0.3)
			var top := r.grow(-5)
			top.size.y *= 0.7
			_poly(Rect2(top.position.x, top.get_center().y - 3, top.size.x, 6),
				Color(0.45, 0.32, 0.18))
		"l":  # chaise longue
			_block(Rect2(r.position.x + 22, r.position.y + 6, 52, 84), Color(0.72, 0.52, 0.3),
				Color(0.5, 0.34, 0.2), 0.12)
			_poly(Rect2(r.position.x + 28, r.position.y + 10, 40, 16), Color(0.95, 0.93, 0.86))
		"u":  # bouée
			_circle(r.get_center() + Vector2(3, 5), 30.0, SHADOW)
			_circle(r.get_center(), 30.0, Color(0.88, 0.2, 0.18))
			for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
				_circle(r.get_center() + Vector2.from_angle(angle + PI * 0.25) * 22.0, 9.0,
					Color(0.97, 0.97, 0.95))
			_circle(r.get_center(), 14.0, _floor_tint())
		"r":  # rambarde : barre blanche et montants
			var horizontal := cells.size.x >= cells.size.y
			if horizontal:
				var y := r.position.y + 40.0
				_poly(Rect2(r.position.x, y + 14, r.size.x, 6), SHADOW)
				_poly(Rect2(r.position.x, y, r.size.x, 14), Color(0.96, 0.96, 0.94))
				_poly(Rect2(r.position.x, y, r.size.x, 4), Color(0.75, 0.55, 0.3))
				for k: int in int(r.size.x / 48.0):
					_poly(Rect2(r.position.x + 20 + k * 48, y + 14, 6, 22), Color(0.85, 0.85, 0.83))
			else:
				var x := r.position.x + 40.0
				_poly(Rect2(x + 14, r.position.y, 6, r.size.y), SHADOW)
				_poly(Rect2(x, r.position.y, 14, r.size.y), Color(0.96, 0.96, 0.94))
				_poly(Rect2(x, r.position.y, 4, r.size.y), Color(0.75, 0.55, 0.3))
		"x":  # plante en pot
			_circle(r.get_center() + Vector2(4, 30), 22.0, SHADOW)
			_block(Rect2(r.position.x + 28, r.position.y + 46, 40, 40), Color(0.85, 0.85, 0.82),
				BRASS, 0.4)
			for leaf: Array in [[Vector2(48, 36), 22.0], [Vector2(32, 44), 16.0],
					[Vector2(64, 44), 16.0], [Vector2(48, 22), 14.0]]:
				_circle(r.position + leaf[0], leaf[1], Color(0.2, 0.48, 0.22))
				_circle(r.position + leaf[0] + Vector2(-3, -4), leaf[1] * 0.6,
					Color(0.36, 0.66, 0.3))
		"i":  # poubelle d'acier (objet à fouiller ; toutes identiques)
			var c := r.position + Vector2(48, 0)
			_circle(c + Vector2(6, 80), 26.0, SHADOW)
			_poly(Rect2(c.x - 24, r.position.y + 30, 48, 52), Color(0.48, 0.52, 0.58))
			_poly(Rect2(c.x - 24, r.position.y + 30, 10, 52), Color(0.68, 0.72, 0.78))
			_ellipse(c + Vector2(0, 82), Vector2(24, 8), Color(0.48, 0.52, 0.58))
			_ellipse(c + Vector2(0, 30), Vector2(26, 10), Color(0.72, 0.76, 0.82))
			_poly(Rect2(c.x - 8, r.position.y + 20, 16, 6), Color(0.35, 0.38, 0.44))
		"m":  # machine électrique, voyant bleu
			_block(r.grow_individual(-3, -6, -3, -2), Color(0.42, 0.46, 0.53),
				Color(0.28, 0.31, 0.37), 0.55)
			_poly(Rect2(r.position.x + 40, r.position.y + 60, 16, 6), Color(0.45, 0.8, 1.0))
		"B":  # socle de la barrière : rail émetteur au sol
			_poly(Rect2(r.position.x, r.position.y + 70, r.size.x, 10), Color(0.2, 0.35, 0.55))
			_poly(Rect2(r.position.x, r.position.y + 73, r.size.x, 4), Color(0.45, 0.75, 1.0))


# --- Passages ---------------------------------------------------------------------------------

func _openings() -> void:
	for cell: Vector2i in _cells(func(c: String) -> bool: return c == "D"):
		var r := _px(Rect2i(cell, Vector2i.ONE))
		if _is_back_wall(cell):
			_door_in_wall(r)
		else:
			_side_door(cell, r)
	for cell: Vector2i in _cells(func(c: String) -> bool: return c == "X"):
		var r := _px(Rect2i(cell, Vector2i.ONE))
		var mat := Color(0.32, 0.36, 0.44) if _style == &"gym" else Color(0.5, 0.16, 0.16)
		_poly(r.grow_individual(-4, -10, -4, -6), mat)
		_poly(Rect2(r.position.x + 4, r.end.y - 14, r.size.x - 8, 8), mat.darkened(0.3))
		if _at(cell + Vector2i.LEFT) == WALL:
			_poly(Rect2(r.position.x, r.position.y, 10, TILE), BRASS.darkened(0.2))
		if _at(cell + Vector2i.RIGHT) == WALL:
			_poly(Rect2(r.end.x - 10, r.position.y, 10, TILE), BRASS.darkened(0.2))
	var stairs := _cells(func(c: String) -> bool: return c == "S")
	for rect: Rect2i in _rects(stairs):
		_stairs(_px(rect), rect)


func _door_in_wall(r: Rect2) -> void:
	_poly(Rect2(r.position.x + 12, r.position.y + 6, 72, 90), TRIM_DARK)
	_poly(Rect2(r.position.x + 16, r.position.y + 10, 64, 86), Color(0.45, 0.28, 0.16))
	_poly(Rect2(r.position.x + 30, r.position.y + 2, 36, 6), BRASS)
	_circle(r.position + Vector2(48, 34), 10.0, BRASS)
	_circle(r.position + Vector2(48, 34), 7.0, Color(0.42, 0.66, 0.9))
	_circle(r.position + Vector2(68, 62), 3.5, BRASS)


## Porte d'un mur latéral : seuil au sol, battant contre le mur.
func _side_door(cell: Vector2i, r: Rect2) -> void:
	var wall_on_left := not _is_floor(cell + Vector2i.LEFT)
	var x := r.position.x if wall_on_left else r.end.x - 22
	_poly(r.grow_individual(-6, -14, -6, -14), Color(0.5, 0.16, 0.16))
	_poly(Rect2(x, r.position.y, 22, TILE), TRIM_DARK)
	_poly(Rect2(x + 4, r.position.y + 4, 14, TILE - 8), Color(0.45, 0.28, 0.16))
	_circle(Vector2(x + 11, r.position.y + 54), 3.5, BRASS)


## Escalier : marches en bandes (montant si un mur est au nord, descendant sinon) et rampes.
func _stairs(r: Rect2, cells: Rect2i) -> void:
	var up := _at(cells.position + Vector2i.UP) == WALL
	var steps := 6
	for k: int in steps:
		var t := float(k) / float(steps - 1)
		var shade := lerpf(0.75, 0.35, t) if up else lerpf(0.35, 0.8, t)
		var color := Color(0.62, 0.45, 0.3).darkened(1.0 - shade)
		_poly(Rect2(r.position.x, r.position.y + k * r.size.y / steps, r.size.x,
			r.size.y / steps - 2), color)
	_poly(Rect2(r.position.x, r.position.y, 8, r.size.y), BRASS)
	_poly(Rect2(r.end.x - 8, r.position.y, 8, r.size.y), BRASS)


# --- Outils -----------------------------------------------------------------------------------

func _block(r: Rect2, top: Color, front: Color, front_ratio: float) -> void:
	_poly(Rect2(r.position + Vector2(6, 8), r.size), SHADOW)
	var front_h := roundf(r.size.y * front_ratio)
	_poly(Rect2(r.position, Vector2(r.size.x, r.size.y - front_h)), top)
	_poly(Rect2(r.position.x, r.end.y - front_h, r.size.x, front_h), front)
	_poly(Rect2(r.position, Vector2(r.size.x, 3)), top.lightened(0.25))


func _poly(r: Rect2, color: Color, texture: Texture2D = null) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y)])
	polygon.color = color
	if texture != null:
		polygon.texture = texture
		polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_add(polygon)
	return polygon


func _gradient(r: Rect2, from: Color, to: Color) -> void:
	var polygon := _poly(r, Color.WHITE)
	polygon.vertex_colors = PackedColorArray([from, from, to, to])


func _circle(center: Vector2, radius: float, color: Color) -> void:
	_ellipse(center, Vector2(radius, radius), color)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for k: int in 24:
		var a := TAU * k / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	_add(polygon)


func _add(node: Node2D) -> void:
	_count += 1
	node.name = "P%03d" % _count
	_attach(_decor, node)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root


## Rectangles maximaux (glouton : bande horizontale, puis vers le bas) couvrant [param cells].
func _rects(cells: Array[Vector2i]) -> Array[Rect2i]:
	var left: Dictionary = {}
	for cell: Vector2i in cells:
		left[cell] = true
	var rects: Array[Rect2i] = []
	for cell: Vector2i in cells:
		if not left.has(cell):
			continue
		var w := 1
		while left.has(cell + Vector2i(w, 0)):
			w += 1
		var h := 1
		var grow := true
		while grow:
			for dx: int in w:
				if not left.has(cell + Vector2i(dx, h)):
					grow = false
					break
			if grow:
				h += 1
		for dy: int in h:
			for dx: int in w:
				left.erase(cell + Vector2i(dx, dy))
		rects.append(Rect2i(cell, Vector2i(w, h)))
	return rects


func _cells(test: Callable) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in int(_plan.get(&"height")):
		for x: int in int(_plan.get(&"width")):
			if test.call(_at(Vector2i(x, y))):
				cells.append(Vector2i(x, y))
	return cells


## Caractère de la grille ; « # » hors carte (la grille dit « T », qui est aussi le
## déclencheur du rival dans le couloir).
func _at(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(_plan.get(&"width")) \
			or cell.y >= int(_plan.get(&"height")):
		return OUT
	return _plan.call(&"at", cell)


func _is_floor(cell: Vector2i) -> bool:
	var c := _at(cell)
	return c != WALL and c != SEA and c != OUT


func _px(rect: Rect2i) -> Rect2:
	return Rect2(Vector2(rect.position * TILE), Vector2(rect.size * TILE))


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


func _floor_texture() -> Texture2D:
	match _style:
		&"gym":
			return _texture(TEX_STEEL)
		&"deck":
			return _texture(TEX_DECK)
		&"cabin":
			return _texture(TEX_CARPET)
	return _texture(TEX_PARQUET)


func _floor_tint() -> Color:
	match _style:
		&"deck":
			return Color(0.78, 0.6, 0.38)
		&"gym":
			return Color(0.58, 0.63, 0.7)
	return Color(0.6, 0.4, 0.24)


func _outside_color() -> Color:
	return Color(0.08, 0.1, 0.14) if _style == &"gym" else OUTSIDE


func _trim() -> Color:
	return Color(0.32, 0.36, 0.44) if _style == &"gym" else TRIM
