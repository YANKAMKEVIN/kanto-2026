extends "res://tools/cerulean_map_kit.gd"
## Boîte à outils des cartes **côtières** peintes (jalon 14 T14, docs/tech/jalon-14.md §2.2) :
## `tools/build_route_25.gd` (Route 25 et Cap d'Azuria). Tout ce que fait
## `tools/cerulean_map_kit.gd` (praticables lus dans la grille, `w` = eau solide vue par
## `GridWorld.is_water`, deux passes masque / scène, graines fixes), mais la mer est **la mer de
## Bourg Palette** et non l'eau claire des canaux :
## - **mer** : cases `w`, texture `ground_eau_01`, écume de Bourg Palette (`foam_strength` par
##   défaut), **angles droits** ([member PaintedGround.square_shore] : l'eau couvre exactement ses
##   cases ; le rivage rocheux est posé par-dessus) ; aucun nœud par case, aucune `Light2D`,
##   aucune particule ;
## - **sable** : cases `s` (praticables, `OverworldTiles.Kind.SAND`), canal rouge du masque de
##   rivage ([method GroundMask.build_shore]) sur `ground_sable_01` ; l'eau touche le sable sans
##   module (l'écume seule) ;
## - **rivage rocheux** ([method place_shore]) : modules `relief_rivage_*` posés **sur les cases
##   `R` qui touchent la mer** (4-voisinage), jamais sur une case praticable (erreur sinon) :
##   « mer au sud » 01 / 02 (variantes à la graine, 2 cases de long, bout à bout), « mer à
##   l'est » 03 et « à l'ouest » 03 en miroir (étendues verticales), angle extérieur 04 (et miroir),
##   angle intérieur 05 (mer en diagonale seulement, et miroir), et bloc plein 06 sur les `R` qui
##   ne touchent pas la mer (hors piliers, posés en paroi par la carte) ;
## - **piliers** ([method pillar_components]) : composantes de `R` loin de l'eau, d'au moins
##   [constant PILLAR_MIN_CELLS] cases, qu'aucun module de rivage ne touche (la carte en fait de la
##   paroi de la série 12, comme les affleurements de la Route 3).
##
## Utilisé par `load("res://tools/coast_map_kit.gd").new(...)`.

const ROCK_MARK: String = "R"
const SAND_MARK: String = "s"
## Taille minimale d'un pilier de roche posé en paroi (cases).
const PILLAR_MIN_CELLS: int = 12
## Rôles des modules (côté de la mer vu depuis la case `R`) → images, miroirs.
const SHORE_PIECES: Dictionary[StringName, Dictionary] = {
	&"s": {"ids": ["relief_rivage_01", "relief_rivage_02"], "flip_h": false},
	&"e": {"ids": ["relief_rivage_03"], "flip_h": false},
	&"w": {"ids": ["relief_rivage_03"], "flip_h": true},
	&"se": {"ids": ["relief_rivage_04"], "flip_h": false},
	&"sw": {"ids": ["relief_rivage_04"], "flip_h": true},
	&"in_se": {"ids": ["relief_rivage_05"], "flip_h": false},
	&"in_sw": {"ids": ["relief_rivage_05"], "flip_h": true},
	&"block": {"ids": ["relief_rivage_06"], "flip_h": false},
}
const _SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var sand_cells: Dictionary = {}
var rock_cells: Dictionary = {}
## Rôle de chaque case `R` ([constant SHORE_PIECES], `&"far"` pour celles qui ne touchent pas la
## mer), rempli par [method classify_rocks].
var rock_roles: Dictionary = {}
## Cases `R` posées en paroi (piliers) : aucun module de rivage ne leur est posé.
var pillar_cells: Dictionary = {}
## Modules posés : {"id", "role", "rect" (pixels)} (tests).
var shore_pieces: Array[Dictionary] = []

var _shore_rng := RandomNumberGenerator.new()


func _init(plan_path: String, map_size: Vector2i, seed_value: int, decor_seed: int,
		shore_seed: int = 0) -> void:
	super(plan_path, map_size, seed_value, decor_seed, shore_seed)
	_shore_rng.seed = shore_seed


# --- Plan logique -------------------------------------------------------------------------


func _kind_of(mark: String) -> int:
	if mark == SAND_MARK:
		return tiles.Kind.SAND
	return super(mark)


## Classe en plus le sable et les rochers.
func _paint_logic(layer: TileMapLayer) -> void:
	super(layer)
	for cell: Vector2i in plan.call(&"cells_of", SAND_MARK):
		sand_cells[cell] = true
	for cell: Vector2i in plan.call(&"cells_of", ROCK_MARK):
		rock_cells[cell] = true
	classify_rocks()


func _skips_border_decal(cell: Vector2i) -> bool:
	return super(cell) or rock_cells.has(cell)


# --- Mer ----------------------------------------------------------------------------------


## Masque du rivage de la mer : R = sable, G = eau (les ponts n'existent pas sur la côte).
func build_water_mask() -> Image:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	return script.call(&"build_shore", size, sand_cells, water_cells)


## La mer de Bourg Palette (texture et écume par défaut), à angles droits.
func _add_water(painted: Node2D) -> void:
	if water_cells.is_empty():
		return
	painted.set(&"shore_mask", ImageTexture.create_from_image(build_water_mask()))
	painted.set(&"square_shore", true)


# --- Rivage rocheux -----------------------------------------------------------------------


## Rôle de chaque case `R` d'après ses voisines d'eau (pas de « mer au nord » dans les grilles de
## la côte : une telle case est traitée comme un bloc).
func classify_rocks() -> void:
	rock_roles.clear()
	for cell: Vector2i in rock_cells:
		var south := water_cells.has(cell + Vector2i.DOWN)
		var east := water_cells.has(cell + Vector2i.RIGHT)
		var west := water_cells.has(cell + Vector2i.LEFT)
		var role := &"far"
		if south and east:
			role = &"se"
		elif south and west:
			role = &"sw"
		elif south and not east and not west:
			role = &"s"
		elif east and not south:
			role = &"e"
		elif west and not south:
			role = &"w"
		elif water_cells.has(cell + Vector2i(1, 1)):
			role = &"in_se"
		elif water_cells.has(cell + Vector2i(-1, 1)):
			role = &"in_sw"
		rock_roles[cell] = role


## Composantes (4-voisinage) de cases `R` « loin de l'eau » d'au moins [constant PILLAR_MIN_CELLS]
## cases dont aucune case ne touche un module de rivage : les piliers.
func pillar_components() -> Array[Array]:
	var left: Dictionary = {}
	for cell: Vector2i in rock_roles:
		if rock_roles[cell] == &"far":
			left[cell] = true
	var found: Array[Array] = []
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		var touches_shore := false
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in _SIDES:
				var next := cell + side
				if left.has(next):
					left.erase(next)
					component.append(next)
					stack.append(next)
				elif rock_roles.has(next) and rock_roles[next] != &"far":
					touches_shore = true
		component.sort()
		if component.size() >= PILLAR_MIN_CELLS and not touches_shore:
			found.append(component)
	return found


## Pose les modules du rivage sur les cases `R` (dans `GroundDecals`, du nord au sud : un module
## plus bas recouvre le pied de celui d'au-dessus). Renvoie le nombre de modules.
func place_shore() -> int:
	for component: Array in pillar_components():
		for cell: Vector2i in component:
			pillar_cells[cell] = true
	var ordered: Array = rock_roles.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	# 1. blocs pleins (cases loin de l'eau hors piliers), puis angles, puis étendues droites.
	for cell: Vector2i in ordered:
		if rock_roles[cell] == &"far" and not pillar_cells.has(cell):
			_place_block(cell)
	for cell: Vector2i in ordered:
		var role: StringName = rock_roles[cell]
		if role in [&"se", &"sw", &"in_se", &"in_sw"]:
			_place_single(role, cell)
	for role: StringName in [&"s", &"e", &"w"]:
		for run: Dictionary in _rock_runs(role):
			_fill_rock_run(role, run)
	return shore_pieces.size()


## Étendues droites de cases de rôle [param role] : {"line", "from", "to"} (colonne ou rangée,
## bornes incluses), dans l'ordre de la carte.
func _rock_runs(role: StringName) -> Array[Dictionary]:
	var horizontal := role == &"s"
	var runs: Array[Dictionary] = []
	var lines := size.y if horizontal else size.x
	var length := size.x if horizontal else size.y
	for line: int in lines:
		var start := -1
		for i: int in length + 1:
			var cell := Vector2i(i, line) if horizontal else Vector2i(line, i)
			var on: bool = i < length and rock_roles.get(cell, &"") == role
			if on and start < 0:
				start = i
			elif not on and start >= 0:
				runs.append({"line": line, "from": start, "to": i - 1})
				start = -1
	return runs


func _fill_rock_run(role: StringName, run: Dictionary) -> void:
	var horizontal := role == &"s"
	var from: int = run["from"]
	var to: int = run["to"]
	var at := from
	while at <= to:
		var id := _pick_shore(role)
		var texture := _shore_texture(id)
		if texture == null:
			return
		var along := texture.get_width() if horizontal else texture.get_height()
		var cells := maxi(1, roundi(float(along) / TILE))
		var count := cells
		if at + cells > to + 1:
			count = mini(cells, to - from + 1)
			at = to + 1 - count
		var line: int = run["line"]
		var rect: Rect2
		if horizontal:
			# Mer au sud : bas du module sur le bord sud de la case, un peu plus haut que la case.
			rect = Rect2(at * TILE, (line + 1) * TILE - texture.get_height(), count * TILE,
				texture.get_height())
		else:
			rect = Rect2(line * TILE, at * TILE, TILE, count * TILE)
		_place_shore_piece(id, role, rect, texture)
		at += count


func _place_single(role: StringName, cell: Vector2i) -> void:
	var id := _pick_shore(role)
	var texture := _shore_texture(id)
	if texture == null:
		return
	var piece := Vector2(texture.get_size())
	var origin := Vector2(cell * TILE) + Vector2(0.0, TILE - piece.y)
	_place_shore_piece(id, role, Rect2(origin, piece), texture)


func _place_block(cell: Vector2i) -> void:
	var id := _pick_shore(&"block")
	var texture := _shore_texture(id)
	if texture == null:
		return
	var piece := Vector2(texture.get_size())
	# Largeur d'une case exacte (jamais sur la voisine) ; seule la hauteur varie.
	var height := piece.y * _shore_rng.randf_range(0.97, 1.08)
	var rect := Rect2(Vector2(cell * TILE) + Vector2(0.0, TILE - height), Vector2(TILE, height))
	_place_shore_piece(id, &"block", rect, texture, _shore_rng.randf() < 0.5)


func _pick_shore(role: StringName) -> String:
	var ids: Array = SHORE_PIECES[role]["ids"]
	return ids[_shore_rng.randi_range(0, ids.size() - 1)]


## Un `Sprite2D` (un nœud) qui remplit exactement [param rect] ; erreur si le rectangle couvre
## une case praticable.
func _place_shore_piece(id: String, role: StringName, rect: Rect2, texture: Texture2D,
		mirror: bool = false) -> void:
	var node_name := "Rivage%03d" % shore_pieces.size()
	# Un module déborde de quelques pixels (jusqu'à 20 % de case) sur la case au nord : c'est de
	# la roche qui chevauche, jamais un obstacle ; au-delà, la case compte.
	for cell: Vector2i in cells_of_rect(rect.grow_individual(0.0, -float(TILE) * 0.2, 0.0, 0.0)):
		if is_walkable(cell):
			errors.append("%s (%s) : couvre la case praticable %s" % [node_name, id, cell])
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.material = _piece_material(id)
	sprite.centered = false
	sprite.position = rect.position
	sprite.scale = rect.size / Vector2(texture.get_size())
	sprite.flip_h = SHORE_PIECES[role]["flip_h"] != mirror
	attach(decals, sprite)
	shore_pieces.append({"id": id, "role": role, "rect": rect, "node": sprite})


func _shore_texture(id: String) -> Texture2D:
	if _pieces.has(id):
		return _pieces[id]["texture"]
	var model: Sprite2D = null
	if ResourceLoader.exists(PROPS + id + ".tscn"):
		model = forest_script.call(&"painted_sprite_model", StringName(id))
	var entry := {"texture": null, "material": null}
	if model != null:
		entry = {"texture": model.texture, "material": model.material}
		model.free()
	else:
		errors.append("module de rivage absent (série 16, T13) : %s" % id)
	_pieces[id] = entry
	return entry["texture"]
