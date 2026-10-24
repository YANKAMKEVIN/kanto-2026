extends SceneTree
## Sprites de combat provisoires des espèces du jalon 25 (`jalon-25.md` T7, dossier 28 §9) :
## Ponyta, Galopa, Magmar, Ptéra (`test_battle_art.gd` : chaque espèce des données a sa face et
## son dos). Fichier à part des autres générateurs (d'autres jalons les modifient en parallèle) :
## mêmes règles (pixel art 64 × 64, contour sombre de 1 px, pieds à y = 61, lumière en haut à
## gauche), mêmes primitives recopiées. Les images de Tadmorv, Grotadmorv, Smogogo et Électrode
## (reprises du J22) sont copiées telles quelles de `origin/jalon-22`. Le dos peint (rendu X/Y
## repeint) remplacera ces images au lot d'art (T12).
##
##   godot --headless --path . -s res://tools/gen_placeholder_battlers_j25.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
const SIZE: int = 64
const SPECIES: Array[String] = ["ponyta", "rapidash", "magmar", "aerodactyl"]
const OUTLINE := Color("#1c1c28")
const EYE := Color("#1c1c28")
const WHITE := Color("#f4f4f4")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for species: String in SPECIES:
		for back: bool in [false, true]:
			var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			call("_draw_" + species, img, back)
			_outline(img)
			img.save_png(DIR + "%s_%s.png" % [species, "back" if back else "front"])
	print("Sprites de combat provisoires du J25 OK (%d espèces)" % SPECIES.size())
	quit()


# --- Primitives (recopiées de gen_placeholder_battlers.gd) ---------------------------

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)


func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_px(img, xx, yy, c)


func _e(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color,
		shade: bool = false) -> void:
	for yy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var d := Vector2((xx + 0.5 - cx) / rx, (yy + 0.5 - cy) / ry)
			if d.length_squared() > 1.0:
				continue
			var col := c
			if shade:
				var side := d.x * 0.6 + d.y * 0.8
				if side > 0.55:
					col = c.darkened(0.22)
				elif side < -0.62 and d.length_squared() > 0.45:
					col = c.lightened(0.18)
			_px(img, xx, yy, col)


func _line(img: Image, a: Vector2, b: Vector2, c: Color, width: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i: int in steps:
		var p := a.lerp(b, float(i) / maxf(steps - 1, 1))
		_r(img, int(round(p.x)) - width / 2, int(round(p.y)) - width / 2, width, width, c)


func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y: int in SIZE:
		for x: int in SIZE:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < SIZE and p.y < SIZE \
						and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


func _eye(img: Image, x: int, y: int, iris: Color) -> void:
	_r(img, x, y, 5, 6, WHITE)
	_r(img, x + 1, y + 1, 4, 5, iris)
	_r(img, x + 2, y + 2, 3, 4, EYE)
	_r(img, x + 2, y + 2, 1, 1, WHITE)


func _poly(img: Image, points: PackedVector2Array, c: Color) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		box = box.expand(point)
	for yy: int in range(int(box.position.y), int(box.end.y) + 1):
		for xx: int in range(int(box.position.x), int(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), points):
				_px(img, xx, yy, c)


func _leaf(img: Image, a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var n := (b - a).orthogonal().normalized() * w
	var mid := a.lerp(b, 0.45)
	_poly(img, PackedVector2Array([a, mid + n, b, mid - n]), c)
	_line(img, a, a.lerp(b, 0.8), c.darkened(0.3))


## Spirale (ventre des Ptitard, coquille des Amonita) : anneaux alternés.
func _spiral(img: Image, cx: float, cy: float, r: float, a: Color, b: Color) -> void:
	var radius := r
	var i := 0
	while radius > 1.0:
		_e(img, cx + i * 0.6, cy - i * 0.4, radius, radius, a if i % 2 == 0 else b)
		radius -= 2.5
		i += 1


# --- Ponyta, Galopa ------------------------------------------------------------------

func _draw_ponyta(img: Image, back: bool) -> void:
	_draw_horse(img, back, 0.8)


func _draw_rapidash(img: Image, back: bool) -> void:
	_draw_horse(img, back, 1.0)


func _draw_horse(img: Image, back: bool, scale: float) -> void:
	var coat := Color("#f4ecd8")
	var flame := Color("#f08030")
	var hot := Color("#f8d040")
	var h := 22.0 * scale
	for x: float in [22.0, 28.0, 38.0, 44.0]:
		_line(img, Vector2(x, 61.0 - h), Vector2(x, 61), coat.darkened(0.15), 3)
	_e(img, 33, 61.0 - h - 6.0, 17.0 * scale, 10.0 * scale, coat, true)
	_leaf(img, Vector2(50, 61.0 - h - 8.0), Vector2(60, 61.0 - h + 6.0), 5.0 * scale, flame)
	_e(img, 24, 61.0 - h - 18.0 * scale, 8.0 * scale, 9.0 * scale, coat, true)
	for i: int in 3:
		_leaf(img, Vector2(26 + i * 3, 61.0 - h - 24.0 * scale),
			Vector2(30 + i * 5, 61.0 - h - 36.0 * scale), 3.0 * scale, flame if i != 1 else hot)
	if back:
		return
	_eye(img, 19, int(61.0 - h - 22.0 * scale), Color("#e03040"))


# --- Magmar --------------------------------------------------------------------------

func _draw_magmar(img: Image, back: bool) -> void:
	var skin := Color("#e8602a")
	var flame := Color("#f8d040")
	_line(img, Vector2(24, 50), Vector2(22, 61), skin.darkened(0.2), 5)
	_line(img, Vector2(40, 50), Vector2(42, 61), skin.darkened(0.2), 5)
	_e(img, 32, 40, 14, 15, skin, true)
	if not back:
		_e(img, 32, 44, 8, 9, Color("#f0c070"))
	_line(img, Vector2(20, 34), Vector2(12, 46), skin, 4)
	_line(img, Vector2(44, 34), Vector2(52, 46), skin, 4)
	_e(img, 32, 20, 10, 9, skin, true)
	for i: int in 3:
		_leaf(img, Vector2(26 + i * 6, 14), Vector2(24 + i * 8, 2), 3, flame)
	_leaf(img, Vector2(44, 48), Vector2(58, 56), 4, flame)
	if back:
		return
	_eye(img, 24, 17, Color("#202020"))
	_r(img, 31, 25, 9, 2, Color("#701818"))


# --- Ptéra ---------------------------------------------------------------------------

func _draw_aerodactyl(img: Image, back: bool) -> void:
	var skin := Color("#a8a0b8")
	var wing := Color("#8880a0")
	_line(img, Vector2(28, 54), Vector2(26, 61), skin.darkened(0.2), 3)
	_line(img, Vector2(37, 54), Vector2(39, 61), skin.darkened(0.2), 3)
	_leaf(img, Vector2(26, 34), Vector2(2, 18), 9, wing)
	_leaf(img, Vector2(38, 34), Vector2(62, 18), 9, wing)
	_leaf(img, Vector2(32, 52), Vector2(32, 61), 3, skin.darkened(0.15))
	_e(img, 32, 42, 10, 14, skin, true)
	if not back:
		_e(img, 32, 44, 5, 9, Color("#d8d0c0"))
	_e(img, 32, 24, 9, 8, skin, true)
	_poly(img, PackedVector2Array([Vector2(24, 24), Vector2(12, 28), Vector2(24, 30)]), skin)
	for i: int in 3:
		_line(img, Vector2(28 + i * 4, 17), Vector2(26 + i * 5, 9), skin.darkened(0.2), 2)
	if back:
		return
	_eye(img, 27, 19, Color("#e0c040"))
	_r(img, 14, 28, 10, 2, Color("#f4f4f4"))
