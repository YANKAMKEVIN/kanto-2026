class_name GroundWater
extends Node2D
## Eau animée d'un sol peint cuit par morceaux (moteur commun, perf A17) : la seule partie du
## sol qui dépend du temps (ondulation, frange et écume du rivage) est redessinée à chaque image,
## **seulement sur les cases d'eau** ([method water_rects]), par le shader du sol en passe
## « eau seule » (`ground_blend`, `pass_mode` 2). Posée par [method PaintedGround.bake_chunks]
## au-dessus des morceaux cuits (la terre, sable compris), elle redonne le rendu d'avant : le
## mélange normal de son alpha sur la terre refait les deux mix() du shader complet.
## Le sous-bois ([ForestFloor]) se dessinait par-dessus l'eau : là où il touche une case d'eau
## couverte, il est redessiné vivant au-dessus du calque ([method forest_rects], quelques cases
## de lisière), pour garder l'ordre d'avant.
## Nom du nœud : [constant NODE_NAME] (sonde [PerfProbe], tests).

const NODE_NAME: StringName = &"WaterOverlay"
## Passe « eau seule » du shader du sol.
const PASS_WATER: int = 2
## Rivage naturel : une case dont le voisinage (3 × 3) a de l'eau au-dessus de ce seuil peut
## porter de la frange (masque lu en linéaire, bruit de ± 0,15) : elle est couverte.
const NATURAL_THRESHOLD: float = 0.25
## Rivage à angles droits : case d'eau (valeur lue telle quelle) dès qu'il peut y avoir de l'eau
## ou de l'écume (seuil de l'écume du shader : 0,42).
const SQUARE_THRESHOLD: float = 0.4
## Sous-bois : une case dont le voisinage (3 × 3) dépasse ce seuil peut en porter (masque en
## linéaire, bruit de ± 0,25 ; seuil d'apparition du shader : 0,42).
const FOREST_THRESHOLD: float = 0.15

## Rectangles couverts, en cases.
var _rects: Array[Rect2i] = []
## Sous-bois redessiné au-dessus de l'eau, un dessin par [ForestFloor].
var _forests: Array[GroundChunks._RectDrawer] = []


## Prépare le calque : [param ground_material] est copié en passe « eau seule ».
## [param forests] : sous-bois cuits avec le sol, [param to_forest] : passage du repère du sol à
## celui de chacun.
func setup(ground_material: ShaderMaterial, shore: Texture2D, square: bool,
		forests: Array[CanvasItem] = [], to_forest: Array[Transform2D] = []) -> void:
	name = NODE_NAME
	var water := ground_material.duplicate() as ShaderMaterial
	water.set_shader_parameter(&"pass_mode", PASS_WATER)
	material = water
	var image := shore.get_image() if shore != null else null
	if image == null:
		return
	var covered := water_cells(image, square)
	_rects = cells_to_rects(covered, image.get_width())
	for i: int in forests.size():
		var forest := forests[i] as ForestFloor
		var mask := forest.mask.get_image() if forest != null and forest.mask != null else null
		if mask == null or mask.get_size() != image.get_size():
			continue
		var drawer := GroundChunks._RectDrawer.new()
		drawer.name = "ForestOverWater"
		drawer.material = forest.material
		# Dessiné après l'eau (enfant du calque), dans le repère du sous-bois.
		drawer.transform = to_forest[i] if i < to_forest.size() else Transform2D()
		var to_local := drawer.transform.affine_inverse()
		for rect: Rect2i in forest_rects(covered, mask):
			drawer.rects.append(to_local * Rect2(rect.position * Grid.TILE_SIZE,
				rect.size * Grid.TILE_SIZE))
		add_child(drawer)
		_forests.append(drawer)
	queue_redraw()


## Rectangles (en cases) du sous-bois redessiné au-dessus de l'eau, tous sous-bois confondus.
func get_forest_rect_count() -> int:
	var count := 0
	for drawer: GroundChunks._RectDrawer in _forests:
		count += drawer.rects.size()
	return count


func _draw() -> void:
	for rect: Rect2i in _rects:
		draw_rect(Rect2(rect.position * Grid.TILE_SIZE, rect.size * Grid.TILE_SIZE), Color.WHITE)


## Rectangles (en cases) dessinés.
func get_rects() -> Array[Rect2i]:
	return _rects.duplicate()


## Cases à couvrir du masque du rivage [param image] (canal vert = eau, 1 pixel = 1 case),
## regroupées en rectangles : suites de cases d'une rangée, fusionnées avec la rangée suivante
## quand elles sont identiques. [param square] : rivage à angles droits (les cases d'eau
## seules) ; sinon les cases d'eau et leurs voisines (frange et écume).
static func water_rects(image: Image, square: bool) -> Array[Rect2i]:
	return cells_to_rects(water_cells(image, square), image.get_width())


## Cases couvertes (rangée par rangée) : voir [method water_rects].
static func water_cells(image: Image, square: bool) -> Array[bool]:
	var width := image.get_width()
	var height := image.get_height()
	var water: Array[bool] = []
	water.resize(width * height)
	for y: int in height:
		for x: int in width:
			water[y * width + x] = image.get_pixel(x, y).g > \
				(SQUARE_THRESHOLD if square else NATURAL_THRESHOLD)
	var covered: Array[bool] = water
	if not square:
		covered = []
		covered.resize(width * height)
		for y: int in height:
			for x: int in width:
				covered[y * width + x] = _has_near(water, width, height, x, y)
	return covered


## Cases d'eau couvertes ([param covered]) où le sous-bois de masque [param forest_mask] peut se
## dessiner, en rectangles.
static func forest_rects(covered: Array[bool], forest_mask: Image) -> Array[Rect2i]:
	var width := forest_mask.get_width()
	var height := forest_mask.get_height()
	var forest: Array[bool] = []
	forest.resize(width * height)
	for y: int in height:
		for x: int in width:
			forest[y * width + x] = forest_mask.get_pixel(x, y).r > FOREST_THRESHOLD
	var both: Array[bool] = []
	both.resize(width * height)
	for y: int in height:
		for x: int in width:
			both[y * width + x] = covered[y * width + x] \
				and _has_near(forest, width, height, x, y)
	return cells_to_rects(both, width)


## Cases vraies de [param covered] (rangées de [param width]) regroupées en rectangles : suites
## d'une rangée, fusionnées avec la rangée suivante quand elles sont identiques.
static func cells_to_rects(covered: Array[bool], width: int) -> Array[Rect2i]:
	var height := covered.size() / width if width > 0 else 0
	var rects: Array[Rect2i] = []
	var open: Dictionary[Vector2i, int] = {}  # (début, fin) de la suite → index du rectangle
	for y: int in height:
		var next_open: Dictionary[Vector2i, int] = {}
		var x := 0
		while x < width:
			if not covered[y * width + x]:
				x += 1
				continue
			var start := x
			while x < width and covered[y * width + x]:
				x += 1
			var run := Vector2i(start, x)
			if open.has(run):
				var index: int = open[run]
				rects[index].size.y += 1
				next_open[run] = index
			else:
				rects.append(Rect2i(start, y, x - start, 1))
				next_open[run] = rects.size() - 1
		open = next_open
	return rects


static func _has_near(water: Array[bool], width: int, height: int, x: int,
		y: int) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and ny >= 0 and nx < width and ny < height and water[ny * width + nx]:
				return true
	return false
