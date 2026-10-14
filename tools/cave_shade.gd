extends RefCounted
## Voile de pénombre d'une grotte (passe « lumière rare » du J12, dossier 15 §5 : « sombre mais
## jamais illisible », lumière rare portée par les lampes, puits de jour, éclats et projecteurs).
##
## Calcul **pur** (aucun nœud) d'une image en niveaux de gris teintés, une valeur par pixel du
## voile ([member px_per_cell] pixels par case), que l'outil de carte pose en **multiplication**
## au-dessus du sol peint et des décalcomanies, sous `Entities` (les personnages et les objets ne
## sont pas assombris : ils restent lisibles sur un sol plus sombre). Valeur d'un pixel de
## galerie :
##
##   ambiance × bord(d) × pourtour(d), relevée vers 1 par la lumière des sources
##
## où d = distance (pixels du monde) à la paroi la plus proche : `bord` assombrit la bande au pied
## des parois (de [code]edge_min[/code] à 1 sur [code]edge_radius[/code] cases), `pourtour` fait
## un dégradé plus large et plus léger vers les bords des salles ([code]room_min[/code] sur
## [code]room_radius[/code] cases). Une source (centre en pixels du monde, rayon en pixels,
## intensité dans [0, 1]) relève la valeur : v + (1 − v) × intensité × chute(distance / rayon).
## Les cases de paroi (masse) prennent la valeur du pied de paroi, relevée à moitié par les
## sources. Une source peut aussi **ajouter** de la lumière au sol ([member glow] : « add »
## × « color » × chute) : flaque claire posée en addition sous les personnages (le sol s'éclaire
## autour d'une lampe sans délaver le héros, qui garde son contraste). Aucune occultation
## (rayons courts : une lampe n'éclaire pas la galerie voisine au-delà de sa paroi de plus d'une
## case).
##
## Utilisé par `tools/cave_map_kit.gd` (`add_shade`) ; testé par `tests/unit/test_cave_shade.gd`.

const TILE: int = 96
## Clés des réglages d'un étage (toutes obligatoires).
const PARAM_KEYS: Array[String] = ["ambient", "edge_min", "edge_radius", "room_min",
	"room_radius", "tint"]

var size: Vector2i
var px_per_cell: int
var width: int
var height: int
## Valeurs du voile (0 noir … 1 aucun effet), rangée par rangée.
var values: PackedFloat32Array = PackedFloat32Array()
## Lumière ajoutée au sol (flaques des sources, en addition sous les personnages) : r, v, b
## entrelacés, dans [0, 1].
var glow: PackedFloat32Array = PackedFloat32Array()

var _open: Dictionary = {}
var _params: Dictionary = {}


## [param open_cells] : cases sans paroi (Vector2i → vrai) ; [param params] : [constant PARAM_KEYS].
func _init(map_size: Vector2i, open_cells: Dictionary, params: Dictionary,
		pixels_per_cell: int = 8) -> void:
	size = map_size
	px_per_cell = pixels_per_cell
	width = size.x * px_per_cell
	height = size.y * px_per_cell
	_open = open_cells
	_params = params


static func check_params(params: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key: String in PARAM_KEYS:
		if not params.has(key):
			errors.append("voile : réglage « %s » manquant" % key)
	return errors


## Calcule [member values] et [member glow] avec les sources [param lights] : { "center":
## Vector2, "radius": float (pixels), "strength": float, "add": float (facultatif),
## "color": Color (facultatif) }.
func compute(lights: Array) -> void:
	var distance := _wall_distance()
	var ambient := float(_params["ambient"])
	var edge_min := float(_params["edge_min"])
	var edge_radius := float(_params["edge_radius"]) * TILE
	var room_min := float(_params["room_min"])
	var room_radius := float(_params["room_radius"]) * TILE
	var wall_value := ambient * edge_min * room_min
	var scale := float(TILE) / px_per_cell
	values.resize(width * height)
	glow.resize(width * height * 3)
	glow.fill(0.0)
	var open_mask := PackedByteArray()
	open_mask.resize(width * height)
	for y: int in height:
		for x: int in width:
			var i := y * width + x
			var cell := Vector2i(x / px_per_cell, y / px_per_cell)
			if not _open.has(cell):
				values[i] = wall_value
				continue
			open_mask[i] = 1
			var d := maxf(distance[i] - 0.5, 0.0) * scale
			var edge := lerpf(edge_min, 1.0, smoothstep(0.0, edge_radius, d))
			var room := lerpf(room_min, 1.0, smoothstep(0.0, room_radius, d))
			values[i] = ambient * edge * room
	for light: Dictionary in lights:
		_add_light(light, open_mask)


## Valeur du voile au point [param world] (pixels du monde), au pixel le plus proche.
func sample(world: Vector2) -> float:
	var x := clampi(int(world.x / TILE * px_per_cell), 0, width - 1)
	var y := clampi(int(world.y / TILE * px_per_cell), 0, height - 1)
	return values[y * width + x]


## Moyenne du voile sur la case [param cell].
func cell_mean(cell: Vector2i) -> float:
	var total := 0.0
	for y: int in px_per_cell:
		for x: int in px_per_cell:
			total += values[(cell.y * px_per_cell + y) * width + cell.x * px_per_cell + x]
	return total / (px_per_cell * px_per_cell)


## Image RGB du voile : gris, refroidi vers [code]tint[/code] dans la pénombre (la couleur de
## multiplication garde le bleu des ombres, dossier 15 §7).
func to_image() -> Image:
	var tint: Color = _params["tint"]
	var data := PackedByteArray()
	data.resize(width * height * 3)
	for i: int in values.size():
		var v := values[i]
		var dark := 1.0 - v
		var r := v * lerpf(1.0, tint.r, dark)
		var g := v * lerpf(1.0, tint.g, dark)
		var b := v * lerpf(1.0, tint.b, dark)
		data[i * 3] = clampi(roundi(r * 255.0), 0, 255)
		data[i * 3 + 1] = clampi(roundi(g * 255.0), 0, 255)
		data[i * 3 + 2] = clampi(roundi(b * 255.0), 0, 255)
	return Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)


## Image RGB de la lumière ajoutée au sol ([member glow]), posée en addition.
func glow_image() -> Image:
	var data := PackedByteArray()
	data.resize(width * height * 3)
	for i: int in glow.size():
		data[i] = clampi(roundi(glow[i] * 255.0), 0, 255)
	return Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)


## Moyenne de la lumière ajoutée (trois canaux) sur la case [param cell].
func glow_cell_mean(cell: Vector2i) -> float:
	var total := 0.0
	for y: int in px_per_cell:
		for x: int in px_per_cell:
			var i := (cell.y * px_per_cell + y) * width + cell.x * px_per_cell + x
			total += glow[i * 3] + glow[i * 3 + 1] + glow[i * 3 + 2]
	return total / (px_per_cell * px_per_cell * 3.0)


## Chute d'une source : 1 au centre (cœur d'un quart du rayon), 0 au rayon, adoucie.
static func falloff(t: float) -> float:
	if t >= 1.0:
		return 0.0
	var u := clampf((t - 0.25) / 0.75, 0.0, 1.0)
	return 1.0 - u * u * (3.0 - 2.0 * u)


func _add_light(light: Dictionary, open_mask: PackedByteArray) -> void:
	var center: Vector2 = light["center"]
	var radius := float(light["radius"])
	var strength := float(light["strength"])
	if radius <= 0.0 or strength <= 0.0:
		return
	var add := float(light.get("add", 0.0))
	var color: Color = light.get("color", Color.WHITE)
	var scale := float(TILE) / px_per_cell
	var x0 := maxi(0, int((center.x - radius) / scale))
	var x1 := mini(width - 1, int((center.x + radius) / scale) + 1)
	var y0 := maxi(0, int((center.y - radius) / scale))
	var y1 := mini(height - 1, int((center.y + radius) / scale) + 1)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			var p := Vector2((x + 0.5) * scale, (y + 0.5) * scale)
			var lift := strength * falloff(p.distance_to(center) / radius)
			if lift <= 0.0:
				continue
			var i := y * width + x
			if open_mask[i] == 0:
				lift *= 0.5
			values[i] = values[i] + (1.0 - values[i]) * lift
			if add > 0.0:
				var amount := add * lift / strength
				glow[i * 3] = minf(glow[i * 3] + color.r * amount, 1.0)
				glow[i * 3 + 1] = minf(glow[i * 3 + 1] + color.g * amount, 1.0)
				glow[i * 3 + 2] = minf(glow[i * 3 + 2] + color.b * amount, 1.0)


## Distance (en pixels du voile) de chaque pixel au pixel de paroi le plus proche : chanfrein
## 8 voisins (1, √2), deux passes ; le bord de la carte compte comme paroi.
func _wall_distance() -> PackedFloat32Array:
	var big := float(width + height)
	var dist := PackedFloat32Array()
	dist.resize(width * height)
	for y: int in height:
		for x: int in width:
			var cell := Vector2i(x / px_per_cell, y / px_per_cell)
			var border := x == 0 or y == 0 or x == width - 1 or y == height - 1
			dist[y * width + x] = big if _open.has(cell) and not border else 0.0
	var diag := sqrt(2.0)
	for y: int in height:
		for x: int in width:
			var i := y * width + x
			var d := dist[i]
			if d == 0.0:
				continue
			if x > 0:
				d = minf(d, dist[i - 1] + 1.0)
			if y > 0:
				d = minf(d, dist[i - width] + 1.0)
				if x > 0:
					d = minf(d, dist[i - width - 1] + diag)
				if x < width - 1:
					d = minf(d, dist[i - width + 1] + diag)
			dist[i] = d
	for y: int in range(height - 1, -1, -1):
		for x: int in range(width - 1, -1, -1):
			var i := y * width + x
			var d := dist[i]
			if d == 0.0:
				continue
			if x < width - 1:
				d = minf(d, dist[i + 1] + 1.0)
			if y < height - 1:
				d = minf(d, dist[i + width] + 1.0)
				if x < width - 1:
					d = minf(d, dist[i + width + 1] + diag)
				if x > 0:
					d = minf(d, dist[i + width - 1] + diag)
			dist[i] = d
	return dist
