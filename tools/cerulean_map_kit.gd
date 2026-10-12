extends "res://tools/pewter_map_kit.gd"
## Boîte à outils des cartes **d'eau** peintes (jalon 13 T6, docs/tech/jalon-13.md §2.3) :
## `tools/build_cerulean_city.gd` (T7, canaux d'Azuria) et `tools/build_route_24.gd` (T8, rivière
## et Pont Pépite). Tout ce que fait `tools/pewter_map_kit.gd` (deux passes masque / scène,
## grille lue telle quelle, forêt, décalcomanies, graines fixes), plus :
## - **praticables de la grille** (ligne `PRATICABLES` du fichier : `.=pqBD` à Azuria, `.=hpBe` à
##   la Route 24) au lieu de ceux d'Argenta ;
## - **source logique `Ground`** : `w` → eau (`OverworldTiles.Kind.WATER` : solide pour le joueur,
##   `GridWorld.is_water` pour le compagnon), `B` → pont (`BOARDWALK`, praticable), `q` → quai
##   (`COBBLE`, praticable ; pavés du masque du sol [D]) ;
## - **eau** dans la passe du sol ([method add_ground]) : rivage **sans sable**
##   (`GroundMask.build_water`, eau = cases `w` et `B`), **à angles droits**
##   (`PaintedGround.square_shore` : l'eau couvre exactement ses cases), texture de canal
##   [constant CANAL_WATER_TEXTURE], écume 0 ; aucun nœud par case, aucun shader de réflexion,
##   aucune particule, aucune `Light2D` (les reflets sont peints dans la texture) ;
## - **quais** ([method place_quays]) : modules `relief_quai_*` posés dans les cases d'eau le long
##   de **toute** frontière eau / sol (rangées de modules sur les bords droits, pièce d'angle là où
##   le sol ne touche l'eau qu'en diagonale) ; aucun module ne couvre une case praticable
##   (erreur sinon) ;
## - **ponts** ([method place_bridges]) : chaque rectangle de cases `B` reçoit un tablier en
##   modules répétés dans le sens de la traversée, dans `GroundDecals` (au-dessus du sol et des
##   quais, sous les personnages).
##
## **Art de la série 15 livré au T5** (`ground_eau_canal_01`, `relief_quai_01..06`, tabliers de
## pont) : les cartes d'Azuria et de la Route 24 utilisent les vrais modules ; [member errors]
## dit ce qui manque. [member allow_placeholders] (cartes d'essai et tests seulement, jamais un
## outil de carte) remplace une image absente par un **provisoire généré en mémoire** (nommé
## « PROVISOIRE <id> », aux dimensions des vrais modules, jamais écrit dans `assets/`).
##
## Utilisé par `load("res://tools/cerulean_map_kit.gd").new(...)`, comme la boîte d'Argenta.

const WATER_MARK: String = "w"
const BRIDGE_MARK: String = "B"
const QUAY_MARK: String = "q"
## Eau claire des canaux et de la rivière (série 15, T2 : reflets peints dans la texture).
const CANAL_WATER_TEXTURE: String = "res://assets/world/ground/ground_eau_canal_01.png"
## Écume des canaux : aucune (les quais sont des murs, pas des plages).
const CANAL_FOAM: float = 0.0
## Côtés d'une case d'eau où peut se trouver le sol (bord droit) et diagonales (angle).
const SIDES: Dictionary[StringName, Vector2i] = {
	&"n": Vector2i.UP, &"s": Vector2i.DOWN, &"w": Vector2i.LEFT, &"e": Vector2i.RIGHT,
}
const CORNERS: Dictionary[StringName, Vector2i] = {
	&"nw": Vector2i(-1, -1), &"ne": Vector2i(1, -1), &"sw": Vector2i(-1, 1),
	&"se": Vector2i(1, 1),
}
## Pièces de quai par position (côté du sol vu depuis la case d'eau), **alignées sur la fiche de la
## série 15 (T1) et sur les vrais modules (T5)** : identifiants (variantes tirées à la graine) et miroirs.
## `n` = sol au nord (face du mur vue de face), `s` = sol au sud (lèvre du quai), `w` / `e` =
## bords latéraux (une image, miroir), angles = pièce de coin (sol en diagonale seulement).
## `relief_quai_06` (escalier de quai) n'est jamais posé d'office : l'outil de la carte le place.
const QUAY_PIECES: Dictionary[StringName, Dictionary] = {
	&"n": {"ids": ["relief_quai_01", "relief_quai_02"], "flip_h": false, "flip_v": false},
	&"s": {"ids": ["relief_quai_03"], "flip_h": false, "flip_v": false},
	&"w": {"ids": ["relief_quai_04"], "flip_h": false, "flip_v": false},
	&"e": {"ids": ["relief_quai_04"], "flip_h": true, "flip_v": false},
	&"nw": {"ids": ["relief_quai_05"], "flip_h": false, "flip_v": false},
	&"ne": {"ids": ["relief_quai_05"], "flip_h": true, "flip_v": false},
	&"sw": {"ids": ["relief_quai_05"], "flip_h": false, "flip_v": true},
	&"se": {"ids": ["relief_quai_05"], "flip_h": true, "flip_v": true},
}
## Tailles des provisoires (pixels) = celles des **vrais modules** de la série 15 (T5, mesurées
## sur `assets/world/relief/relief_quai_0N.png` : n 192 × 69 / 71, s 192 × 30, w 20 × 112,
## angle 40 × 51) : un module de côté `n` / `s` mesure 192 px le long du bord (2 cases), un module
## `w` / `e` 112 px (1 case, `round(112 / 96)`). Largeur × hauteur de l'image.
const PLACEHOLDER_QUAY_SIZE: Dictionary[StringName, Vector2i] = {
	&"n": Vector2i(192, 70), &"s": Vector2i(192, 30), &"w": Vector2i(20, 112),
	&"e": Vector2i(20, 112), &"corner": Vector2i(40, 51),
}
## Couleurs des provisoires : pierre claire du quai, ligne d'eau, bois du tablier.
const PLACEHOLDER_STONE: Color = Color(0.83, 0.80, 0.73)
const PLACEHOLDER_WET: Color = Color(0.30, 0.38, 0.40)
const PLACEHOLDER_PLANK: Color = Color(0.62, 0.47, 0.32)
const PLACEHOLDER_CANAL_TINT: Color = Color(0.45, 0.80, 0.82)

## Images absentes remplacées par des provisoires en mémoire (cartes d'essai et tests).
var allow_placeholders: bool = false
## Cases par nature (Vector2i → vrai).
var water_cells: Dictionary = {}
var bridge_cells: Dictionary = {}
var quay_cells: Dictionary = {}
## Modules posés par [method place_quays] : {"id", "side", "rect" (pixels), "node"}.
var quay_pieces: Array[Dictionary] = []
## Ponts trouvés par [method bridge_rects] puis posés : {"rect" (cases), "axis" (&"ns" | &"ew")}.
var bridges: Array[Dictionary] = []

var _quay_rng := RandomNumberGenerator.new()
var _pieces: Dictionary = {}


## Comme la boîte d'Argenta, mais les praticables sont ceux de la grille ; [param quay_seed] :
## tirage des variantes de modules de quai.
func _init(plan_path: String, map_size: Vector2i, seed_value: int, decor_seed: int,
		quay_seed: int = 0) -> void:
	super(plan_path, map_size, seed_value, decor_seed)
	_quay_rng.seed = quay_seed
	var own := PlanGrid.new()
	if own.load_file(plan_path):
		plan.set(&"walkable", own.walkable)
		if own.walkable.contains(WATER_MARK):
			errors.append("l'eau « %s » est praticable dans la grille" % WATER_MARK)


# --- Plan logique -------------------------------------------------------------------------


func _kind_of(mark: String) -> int:
	match mark:
		WATER_MARK:
			return tiles.Kind.WATER
		BRIDGE_MARK:
			return tiles.Kind.BOARDWALK
		QUAY_MARK:
			return tiles.Kind.COBBLE
	if is_walkable_mark(mark) and not WALKABLE.contains(mark):
		return tiles.Kind.GRASS
	return super(mark)


## Classe en plus l'eau, les ponts et les quais (quais = pavés du masque du sol [D]).
func _paint_logic(layer: TileMapLayer) -> void:
	super(layer)
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.call(&"at", cell)
			match mark:
				WATER_MARK:
					water_cells[cell] = true
				BRIDGE_MARK:
					bridge_cells[cell] = true
				QUAY_MARK:
					quay_cells[cell] = true
					paved_cells[cell] = true


func is_walkable_mark(mark: String) -> bool:
	return (plan.get(&"walkable") as String).contains(mark)


## Vrai si [param cell] est du sol au bord de l'eau : dans la carte, ni eau ni pont (le bord de
## la carte prolonge l'eau : aucun quai contre lui).
func is_land(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return false
	return not water_cells.has(cell) and not bridge_cells.has(cell)


func _skips_border_decal(cell: Vector2i) -> bool:
	return super(cell) or water_cells.has(cell) or bridge_cells.has(cell)


# --- Eau ----------------------------------------------------------------------------------


## Masque du sol peint (R = pavés et quais, G = chemin), comme [method add_ground] l'écrit.
func build_mask() -> Image:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	return script.call(&"build", size, paved_cells, path_cells)


## Masque du rivage, **sans sable** : eau = cases d'eau et de pont (l'eau passe sous les ponts).
func build_water_mask() -> Image:
	var water: Dictionary = water_cells.duplicate()
	water.merge(bridge_cells)
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	return script.call(&"build_water", size, water)


## [method add_ground] de la boîte d'Argenta, puis l'eau sur le sol peint.
func add_ground(mask_path: String, undergrowth: Dictionary,
		mask_hook: Callable = Callable()) -> bool:
	if not super(mask_path, undergrowth, mask_hook):
		return false
	_add_water(root.get_node(^"PaintedGround"))
	return true


## Sol au masque construit en mémoire (carte d'essai, tests : rien n'est écrit dans `assets/`),
## puis l'eau.
func add_ground_in_memory(undergrowth: Dictionary) -> void:
	_add_water(add_ground_with(ImageTexture.create_from_image(build_mask()), undergrowth))


func _add_water(painted: Node2D) -> void:
	if water_cells.is_empty() and bridge_cells.is_empty():
		return
	painted.set(&"shore_mask", ImageTexture.create_from_image(build_water_mask()))
	painted.set(&"water_texture", _canal_texture())
	painted.set(&"foam_strength", CANAL_FOAM)
	painted.set(&"square_shore", true)


func _canal_texture() -> Texture2D:
	if ResourceLoader.exists(CANAL_WATER_TEXTURE):
		return load(CANAL_WATER_TEXTURE)
	if not allow_placeholders:
		errors.append("texture d'eau absente (série 15, T2) : %s" % CANAL_WATER_TEXTURE)
		return null
	# Provisoire : l'eau de mer éclaircie vers le turquoise des canaux.
	var image := (load("res://assets/world/ground/ground_eau_01.png") as Texture2D).get_image()
	image.decompress()
	image.convert(Image.FORMAT_RGB8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			image.set_pixel(x, y, image.get_pixel(x, y).lerp(PLACEHOLDER_CANAL_TINT, 0.45))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = "PROVISOIRE ground_eau_canal_01"
	return texture


# --- Quais --------------------------------------------------------------------------------


## Quais sur toute frontière eau / sol : pour chaque côté, les cases d'eau dont le voisin de ce
## côté est du sol, regroupées en étendues droites, couvertes de modules bout à bout (le dernier
## aligné sur la fin de l'étendue, un module plus long que l'étendue est raccourci) ; une pièce
## d'angle dans chaque case d'eau qui ne touche le sol qu'en diagonale. Dans `GroundDecals`.
## Renvoie le nombre de modules.
func place_quays() -> int:
	for side: StringName in SIDES:
		for run: Dictionary in quay_runs(side):
			_fill_run(side, run)
	for corner: StringName in CORNERS:
		for cell: Vector2i in corner_cells(corner):
			_place_corner(corner, cell)
	return quay_pieces.size()


## Étendues de bord du côté [param side] : {"line" (rangée ou colonne), "from", "to"} (cases,
## bornes incluses), dans l'ordre des rangées puis des colonnes.
func quay_runs(side: StringName) -> Array[Dictionary]:
	var offset: Vector2i = SIDES[side]
	var horizontal := offset.y != 0
	var runs: Array[Dictionary] = []
	var lines := size.y if horizontal else size.x
	var length := size.x if horizontal else size.y
	for line: int in lines:
		var start := -1
		for i: int in length + 1:
			var cell := Vector2i(i, line) if horizontal else Vector2i(line, i)
			var edge := i < length and water_cells.has(cell) and is_land(cell + offset)
			if edge and start < 0:
				start = i
			elif not edge and start >= 0:
				runs.append({"line": line, "from": start, "to": i - 1})
				start = -1
	return runs


## Cases d'eau qui touchent le sol en diagonale [param corner] seulement (ses deux voisines de
## ce côté sont de l'eau ou des ponts).
func corner_cells(corner: StringName) -> Array[Vector2i]:
	var offset: Vector2i = CORNERS[corner]
	var cells: Array[Vector2i] = []
	for cell: Vector2i in water_cells:
		if is_land(cell + offset) and not is_land(cell + Vector2i(offset.x, 0)) \
				and not is_land(cell + Vector2i(0, offset.y)):
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells


func _fill_run(side: StringName, run: Dictionary) -> void:
	var horizontal := (SIDES[side] as Vector2i).y != 0
	var from: int = run["from"]
	var to: int = run["to"]
	var at := from
	while at <= to:
		var id := _pick(side)
		var texture := _piece_texture(id, side)
		if texture == null:
			return
		var along := texture.get_width() if horizontal else texture.get_height()
		var cells := maxi(1, roundi(float(along) / TILE))
		var count := cells
		if at + cells > to + 1:
			# Dernier module : aligné sur la fin de l'étendue (chevauche le précédent), raccourci
			# si l'étendue est plus courte que lui.
			count = mini(cells, to - from + 1)
			at = to + 1 - count
		_place_piece(id, side, _edge_rect(side, run["line"], at, count, texture), texture)
		at += count


## Rectangle (pixels) d'un module du côté [param side] : [param count] cases depuis [param at]
## le long du bord, profondeur = celle de l'image, collé au bord eau / sol.
func _edge_rect(side: StringName, line: int, at: int, count: int, texture: Texture2D) -> Rect2:
	match side:
		&"n":
			return Rect2(at * TILE, line * TILE, count * TILE, texture.get_height())
		&"s":
			return Rect2(at * TILE, (line + 1) * TILE - texture.get_height(), count * TILE,
				texture.get_height())
		&"w":
			return Rect2(line * TILE, at * TILE, texture.get_width(), count * TILE)
	return Rect2((line + 1) * TILE - texture.get_width(), at * TILE, texture.get_width(),
		count * TILE)


func _place_corner(corner: StringName, cell: Vector2i) -> void:
	var id := _pick(corner)
	var texture := _piece_texture(id, corner)
	if texture == null:
		return
	var offset: Vector2i = CORNERS[corner]
	var piece := Vector2(texture.get_size())
	var origin := Vector2(cell * TILE)
	if offset.x > 0:
		origin.x += TILE - piece.x
	if offset.y > 0:
		origin.y += TILE - piece.y
	_place_piece(id, corner, Rect2(origin, piece), texture)


func _pick(role: StringName) -> String:
	var ids: Array = QUAY_PIECES[role]["ids"]
	return ids[_quay_rng.randi_range(0, ids.size() - 1)]


## Un `Sprite2D` (un nœud) qui remplit exactement [param rect] ; erreur si le rectangle couvre
## une case praticable.
func _place_piece(id: String, role: StringName, rect: Rect2, texture: Texture2D) -> void:
	var node_name := "Quai%03d" % quay_pieces.size()
	for cell: Vector2i in cells_of_rect(rect):
		if is_walkable(cell):
			errors.append("%s (%s) : couvre la case praticable %s" % [node_name, id, cell])
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.material = _piece_material(id)
	sprite.centered = false
	sprite.position = rect.position
	sprite.scale = rect.size / Vector2(texture.get_size())
	sprite.flip_h = QUAY_PIECES[role]["flip_h"]
	sprite.flip_v = QUAY_PIECES[role]["flip_v"]
	attach(decals, sprite)
	quay_pieces.append({"id": id, "side": role, "rect": rect, "node": sprite})


## Cases touchées par [param rect] (pixels ; un bord posé sur une ligne de la grille ne touche
## pas la case d'à côté).
static func cells_of_rect(rect: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var first := Vector2i((rect.position / TILE).floor())
	var last := Vector2i(((rect.end - Vector2.ONE * 0.5) / TILE).floor())
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			cells.append(Vector2i(x, y))
	return cells


# --- Ponts --------------------------------------------------------------------------------


## Rectangles des ponts (cases `B` reliées), dans l'ordre des rangées ; sens de la traversée :
## `ns` si du praticable borde le rectangle au nord ou au sud, sinon `ew`. Erreur si un pont
## n'est pas un rectangle plein.
func bridge_rects() -> Array[Dictionary]:
	var seen: Dictionary = {}
	var found: Array[Dictionary] = []
	var ordered: Array = bridge_cells.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	for start: Vector2i in ordered:
		if seen.has(start):
			continue
		var part: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			part.append(cell)
			for side: Vector2i in SIDES.values():
				var next := cell + side
				if bridge_cells.has(next) and not seen.has(next):
					seen[next] = true
					queue.append(next)
		var rect := Rect2i(part[0], Vector2i.ONE)
		for cell: Vector2i in part:
			rect = rect.merge(Rect2i(cell, Vector2i.ONE))
		if rect.get_area() != part.size():
			errors.append("pont non rectangulaire en %s" % rect)
		var axis := &"ew"
		for x: int in range(rect.position.x, rect.end.x):
			if is_walkable(Vector2i(x, rect.position.y - 1)) \
					or is_walkable(Vector2i(x, rect.end.y)):
				axis = &"ns"
		found.append({"rect": rect, "axis": axis})
	return found


## Tablier de chaque pont : modules [param decks] (`{&"ns": id, &"ew": id}`) répétés dans le
## sens de la traversée (dernier aligné sur le bout), à la largeur exacte du pont, dans
## `GroundDecals` après les quais. Une clé `Vector2i` (case du coin nord-ouest du pont) donne le
## module d'**un** pont (largeurs différentes : Azuria, 2 et 3 de large). Renvoie le nombre de
## modules.
func place_bridges(decks: Dictionary) -> int:
	bridges = bridge_rects()
	var count := 0
	for index: int in bridges.size():
		var rect: Rect2i = bridges[index]["rect"]
		var axis: StringName = bridges[index]["axis"]
		var id: String = decks.get(rect.position, decks.get(axis, ""))
		var texture := _deck_texture(id, axis, rect)
		if texture == null:
			continue
		var ns := axis == &"ns"
		var span := rect.size.y if ns else rect.size.x
		var along := texture.get_height() if ns else texture.get_width()
		var cells := clampi(roundi(float(along) / TILE), 1, span)
		var at := 0
		while at < span:
			var step := mini(cells, span - at)
			var first := at if at + cells <= span else span - cells
			var area := Rect2i(rect.position + (Vector2i(0, first) if ns else Vector2i(first, 0)),
				Vector2i(rect.size.x, cells) if ns else Vector2i(cells, rect.size.y))
			var sprite := Sprite2D.new()
			sprite.name = "Pont%02d_%02d" % [index, at]
			sprite.texture = texture
			sprite.material = _piece_material(id)
			sprite.centered = false
			sprite.position = Vector2(area.position * TILE)
			sprite.scale = Vector2(area.size * TILE) / Vector2(texture.get_size())
			attach(decals, sprite)
			count += 1
			at += step
	return count


# --- Images (série 15 ou provisoires) -----------------------------------------------------


func _piece_texture(id: String, role: StringName) -> Texture2D:
	if _pieces.has(id):
		return _pieces[id]["texture"]
	var model: Sprite2D = forest_script.call(&"painted_sprite_model", StringName(id)) \
		if ResourceLoader.exists(PROPS + id + ".tscn") else null
	var entry := {"texture": null, "material": null}
	if model != null:
		entry = {"texture": model.texture, "material": model.material}
		model.free()
	elif allow_placeholders:
		entry["texture"] = _placeholder_quay(id, role)
	else:
		errors.append("module de quai absent (série 15, T2 / T5) : %s" % id)
	_pieces[id] = entry
	return entry["texture"]


func _deck_texture(id: String, axis: StringName, rect: Rect2i) -> Texture2D:
	var key := id if not id.is_empty() else "deck_" + String(axis)
	if _pieces.has(key):
		return _pieces[key]["texture"]
	var model: Sprite2D = null
	if not id.is_empty() and ResourceLoader.exists(PROPS + id + ".tscn"):
		model = forest_script.call(&"painted_sprite_model", StringName(id))
	var entry := {"texture": null, "material": null}
	if model != null:
		entry = {"texture": model.texture, "material": model.material}
		model.free()
	elif allow_placeholders:
		entry["texture"] = _placeholder_deck(key, axis, rect)
	else:
		errors.append("tablier de pont absent (série 15, T2 / T5) : %s" % key)
	_pieces[key] = entry
	return entry["texture"]


func _piece_material(id: String) -> Material:
	return _pieces[id]["material"] if _pieces.has(id) else null


## Module de quai provisoire : pierre claire, joints, ligne d'eau sombre du côté de l'eau.
func _placeholder_quay(id: String, role: StringName) -> Texture2D:
	var horizontal := role == &"n" or role == &"s"
	var corner := CORNERS.has(role)
	var image_size: Vector2i = PLACEHOLDER_QUAY_SIZE[&"corner" if corner else role]
	var image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	image.fill(PLACEHOLDER_STONE)
	var wet := 4
	for y: int in image_size.y:
		for x: int in image_size.x:
			var joint := (x % 48 == 0) if horizontal else (y % 48 == 0)
			# Ligne d'eau au bord opposé au sol (dessiné pour le côté nord, ouest, ou l'angle
			# nord-ouest ; les miroirs font le reste).
			var waterline := y >= image_size.y - wet if horizontal and role == &"n" \
				else (y < wet if role == &"s" else x >= image_size.x - wet)
			if corner:
				waterline = x >= image_size.x - wet or y >= image_size.y - wet
			if waterline:
				image.set_pixel(x, y, PLACEHOLDER_WET)
			elif joint and not corner:
				image.set_pixel(x, y, PLACEHOLDER_STONE.darkened(0.25))
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = "PROVISOIRE %s" % id
	return texture


## Tablier provisoire : planches perpendiculaires à la traversée, garde-corps sombres.
func _placeholder_deck(key: String, axis: StringName, rect: Rect2i) -> Texture2D:
	var ns := axis == &"ns"
	var image_size := Vector2i(rect.size.x * TILE, TILE) if ns \
		else Vector2i(TILE, rect.size.y * TILE)
	var image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	image.fill(PLACEHOLDER_PLANK)
	for y: int in image_size.y:
		for x: int in image_size.x:
			var across := x if ns else y
			var along := y if ns else x
			var width := image_size.x if ns else image_size.y
			if across < 10 or across >= width - 10:
				image.set_pixel(x, y, PLACEHOLDER_PLANK.darkened(0.45))
			elif along % 16 == 0:
				image.set_pixel(x, y, PLACEHOLDER_PLANK.darkened(0.3))
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = "PROVISOIRE %s" % key
	return texture
