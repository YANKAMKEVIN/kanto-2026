extends SceneTree
## Sprites de combat provisoires des espèces du jalon 24 (`jalon-24.md` T4, dossier 27 §14.1) :
## Routes 19 à 21, Îles Écume, résurrection des fossiles, Artikodin, et les évolutions de ces
## espèces (`test_battle_art.gd` : chaque espèce des données a sa face et son dos).
## Fichier à part de `tools/gen_placeholder_battlers.gd` (que d'autres jalons modifient en
## parallèle) : mêmes règles (pixel art 64 × 64, contour sombre de 1 px, pieds à y = 61, lumière
## en haut à gauche), mêmes primitives recopiées. Léviator (J19) et Saquedeneu (J20) ne sont pas
## ici : leurs images sont reprises telles quelles de leurs branches. Le dos peint (rendu X/Y
## repeint) remplacera ces images au lot d'art (T5).
##
##   godot --headless --path . -s res://tools/gen_placeholder_battlers_j24.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
const SIZE: int = 64
const SPECIES: Array[String] = [
	"tentacool", "tentacruel", "poliwag", "poliwhirl", "poliwrath", "psyduck", "golduck",
	"slowpoke", "slowbro", "seel", "dewgong", "cloyster", "krabby", "kingler", "seadra",
	"seaking", "magikarp", "omanyte", "omastar", "kabuto", "kabutops", "articuno",
]
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
	print("Sprites de combat provisoires du J24 OK (%d espèces)" % SPECIES.size())
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


# --- Tentacool, Tentacruel -----------------------------------------------------------

func _draw_tentacool(img: Image, back: bool) -> void:
	_draw_jelly(img, back, Color("#6ab8e8"), 2, 13.0)


func _draw_tentacruel(img: Image, back: bool) -> void:
	_draw_jelly(img, back, Color("#4a90d0"), 5, 17.0)


func _draw_jelly(img: Image, back: bool, body: Color, legs: int, size: float) -> void:
	var leg := Color("#c0e0f0")
	for i: int in legs * 2:
		var x := 32.0 - legs * 3.0 + i * 3.0
		_line(img, Vector2(x, 34), Vector2(x + sin(i * 1.7) * 4.0, 61), leg, 2)
	_e(img, 32, 30, size, size * 0.9, body, true)
	_e(img, 32, 40, size, 4, body.darkened(0.15))
	var gem := Color("#e03040")
	_e(img, 32 - size * 0.45, 26 if back else 30, 4, 4, gem, true)
	_e(img, 32 + size * 0.45, 26 if back else 30, 4, 4, gem, true)
	if legs > 2:
		_e(img, 32, 20, 3, 3, gem, true)
	if not back:
		_r(img, 26, 38, 4, 2, EYE)
		_r(img, 34, 38, 4, 2, EYE)


# --- Ptitard, Têtarte, Tartard -------------------------------------------------------

func _draw_poliwag(img: Image, back: bool) -> void:
	var skin := Color("#6a8ad8")
	_leaf(img, Vector2(32, 40), Vector2(32, 20) if back else Vector2(50, 22), 6, WHITE)
	_e(img, 32, 44, 16, 15, skin, true)
	_r(img, 22, 58, 6, 4, skin.darkened(0.2))
	_r(img, 36, 58, 6, 4, skin.darkened(0.2))
	if back:
		return
	_spiral(img, 32, 48, 8, WHITE, EYE)
	_eye(img, 22, 33, Color("#2a2a30"))
	_eye(img, 37, 33, Color("#2a2a30"))
	_r(img, 30, 40, 4, 2, Color("#e05878"))


func _draw_poliwhirl(img: Image, back: bool) -> void:
	_draw_frog(img, back, Color("#5a7ac8"), false)


func _draw_poliwrath(img: Image, back: bool) -> void:
	_draw_frog(img, back, Color("#3a5aa8"), true)


func _draw_frog(img: Image, back: bool, skin: Color, strong: bool) -> void:
	var arm := 6 if strong else 4
	_line(img, Vector2(18, 36), Vector2(6, 24), skin, arm)
	_line(img, Vector2(46, 36), Vector2(58, 24), skin, arm)
	_e(img, 6, 22, arm, arm, WHITE, true)
	_e(img, 58, 22, arm, arm, WHITE, true)
	_e(img, 32, 40, 19, 18, skin, true)
	_e(img, 22, 58, 7, 4, skin.darkened(0.15))
	_e(img, 42, 58, 7, 4, skin.darkened(0.15))
	if back:
		return
	_spiral(img, 32, 44, 11, WHITE, EYE)
	_eye(img, 20, 24, Color("#2a2a30"))
	_eye(img, 39, 24, Color("#2a2a30"))
	if strong:
		_line(img, Vector2(19, 22), Vector2(26, 25), EYE, 2)
		_line(img, Vector2(45, 22), Vector2(38, 25), EYE, 2)


# --- Psykokwak, Akwakwak -------------------------------------------------------------

func _draw_psyduck(img: Image, back: bool) -> void:
	var body := Color("#f0d050")
	_e(img, 32, 48, 14, 13, body, true)
	_e(img, 32, 26, 15, 13, body, true)
	_line(img, Vector2(20, 44), Vector2(18, 24), body.darkened(0.1), 4)
	_line(img, Vector2(44, 44), Vector2(46, 24), body.darkened(0.1), 4)
	_r(img, 22, 59, 8, 3, Color("#f0e0b0"))
	_r(img, 34, 59, 8, 3, Color("#f0e0b0"))
	for i: int in 3:
		_line(img, Vector2(30 + i * 2, 14), Vector2(29 + i * 2, 8), EYE)
	if back:
		return
	_e(img, 32, 32, 8, 4, Color("#f0e0b0"), true)
	_r(img, 22, 22, 6, 6, WHITE)
	_r(img, 36, 22, 6, 6, WHITE)
	_r(img, 24, 24, 2, 2, EYE)
	_r(img, 38, 24, 2, 2, EYE)


func _draw_golduck(img: Image, back: bool) -> void:
	var body := Color("#4a8ad0")
	_e(img, 32, 46, 12, 15, body, true)
	_e(img, 32, 20, 11, 11, body, true)
	_line(img, Vector2(21, 40), Vector2(10, 50), body, 4)
	_line(img, Vector2(43, 40), Vector2(54, 50), body, 4)
	_r(img, 22, 58, 8, 4, Color("#f0e0a0"))
	_r(img, 34, 58, 8, 4, Color("#f0e0a0"))
	_e(img, 32, 12, 3, 3, Color("#e03040"), true)
	if back:
		return
	_e(img, 32, 26, 7, 3, Color("#f0e0a0"), true)
	_eye(img, 23, 15, Color("#e03040"))
	_eye(img, 36, 15, Color("#e03040"))


# --- Ramoloss, Flagadoss -------------------------------------------------------------

func _draw_slowpoke(img: Image, back: bool) -> void:
	var skin := Color("#f0a0b8")
	_line(img, Vector2(44, 52), Vector2(60, 58), skin, 5)
	_e(img, 32, 48, 18, 12, skin, true)
	_e(img, 26, 28, 14, 12, skin, true)
	_r(img, 18, 58, 6, 4, skin.darkened(0.2))
	_r(img, 38, 58, 6, 4, skin.darkened(0.2))
	if back:
		return
	_e(img, 20, 34, 9, 5, Color("#f8e0e0"), true)
	_r(img, 18, 24, 5, 2, EYE)
	_r(img, 28, 24, 5, 2, EYE)


func _draw_slowbro(img: Image, back: bool) -> void:
	var skin := Color("#f0a0b8")
	var shell := Color("#a0a0b8")
	_line(img, Vector2(44, 50), Vector2(56, 44), skin, 5)
	_e(img, 56, 44, 7, 7, shell, true)
	_r(img, 52, 41, 8, 2, shell.darkened(0.3))
	_e(img, 30, 44, 15, 17, skin, true)
	_e(img, 30, 20, 13, 11, skin, true)
	_r(img, 20, 58, 6, 4, skin.darkened(0.2))
	_r(img, 34, 58, 6, 4, skin.darkened(0.2))
	if back:
		return
	_e(img, 30, 46, 9, 11, Color("#f8e0d0"))
	_e(img, 24, 26, 8, 4, Color("#f8e0e0"), true)
	_r(img, 22, 16, 5, 2, EYE)
	_r(img, 33, 16, 5, 2, EYE)


# --- Otaria, Lamantine ---------------------------------------------------------------

func _draw_seel(img: Image, back: bool) -> void:
	_draw_seal(img, back, Color("#e8eef8"), 14.0, false)


func _draw_dewgong(img: Image, back: bool) -> void:
	_draw_seal(img, back, Color("#f4f6fc"), 18.0, true)


func _draw_seal(img: Image, back: bool, fur: Color, length: float, mane: bool) -> void:
	var dir := 1 if back else -1
	_leaf(img, Vector2(32 - dir * length, 52), Vector2(32 - dir * (length + 12), 58), 5,
		fur.darkened(0.1))
	_e(img, 32, 48, length + 4, 12, fur, true)
	_e(img, 32 + dir * (length - 4), 30, 11, 10, fur, true)
	_line(img, Vector2(32 + dir * (length - 4), 21), Vector2(32 + dir * (length - 4), 13),
		Color("#d8d0c0"), 3)
	if mane:
		_line(img, Vector2(32 + dir * (length - 12), 24), Vector2(32 + dir * (length - 16), 38),
			fur.darkened(0.08), 3)
	_leaf(img, Vector2(32 + dir * 4, 56), Vector2(32 + dir * 12, 61), 3, fur.darkened(0.15))
	if back:
		return
	_r(img, 32 - (length - 4) - 6, 28, 3, 2, EYE)
	_r(img, 32 - (length - 4) + 3, 28, 3, 2, EYE)
	_e(img, 32 - (length - 4), 34, 4, 2, Color("#f0c8c0"))


# --- Crustabri -----------------------------------------------------------------------

func _draw_cloyster(img: Image, back: bool) -> void:
	var shell := Color("#6a5a98")
	var spike := Color("#d8d8e8")
	for i: int in 7:
		var a := -PI + i * PI / 6.0
		var base := Vector2(32, 38) + Vector2(cos(a), sin(a)) * 20
		_line(img, base, Vector2(32, 38) + Vector2(cos(a), sin(a)) * 30, spike, 3)
	_e(img, 32, 40, 26, 21, shell, true)
	for i: int in range(-3, 4):
		_line(img, Vector2(32, 60), Vector2(32 + i * 8, 20), shell.darkened(0.2))
	if back:
		return
	_e(img, 32, 42, 13, 12, Color("#2a2030"))
	_e(img, 32, 40, 8, 8, Color("#9898a8"), true)
	_r(img, 28, 38, 2, 2, EYE)
	_r(img, 34, 38, 2, 2, EYE)
	_line(img, Vector2(32, 32), Vector2(32, 24), Color("#9898a8"), 2)


# --- Krabby, Krabboss ----------------------------------------------------------------

func _draw_krabby(img: Image, back: bool) -> void:
	_draw_crab(img, back, Color("#e0603a"), 6.0, 6.0)


func _draw_kingler(img: Image, back: bool) -> void:
	_draw_crab(img, back, Color("#d04a30"), 6.0, 11.0)


func _draw_crab(img: Image, back: bool, shell: Color, left: float, right: float) -> void:
	var belly := Color("#f0e0b0")
	for i: int in 3:
		_line(img, Vector2(22 - i * 3, 50), Vector2(16 - i * 3, 60), shell.darkened(0.15), 2)
		_line(img, Vector2(42 + i * 3, 50), Vector2(48 + i * 3, 60), shell.darkened(0.15), 2)
	var lc := 13.0 if back else 51.0
	var rc := 51.0 if back else 13.0
	_line(img, Vector2(24, 40), Vector2(lc, 30), shell, 3)
	_line(img, Vector2(40, 40), Vector2(rc, 30), shell, 3)
	_e(img, lc, 24, left, left + 2, shell, true)
	_e(img, rc, 24 - (right - left), right, right + 2, shell, true)
	_e(img, 32, 44, 15, 11, shell, true)
	if back:
		return
	_e(img, 32, 49, 10, 5, belly)
	_line(img, Vector2(27, 34), Vector2(27, 28), shell, 2)
	_line(img, Vector2(37, 34), Vector2(37, 28), shell, 2)
	_e(img, 27, 27, 3, 3, WHITE)
	_e(img, 37, 27, 3, 3, WHITE)
	_r(img, 27, 27, 1, 2, EYE)
	_r(img, 37, 27, 1, 2, EYE)


# --- Hypocéan ------------------------------------------------------------------------

func _draw_seadra(img: Image, back: bool) -> void:
	var skin := Color("#3a7ac8")
	var dir := 1 if back else -1
	_e(img, 32 - dir * 6, 55, 8, 6, skin, true)
	_e(img, 32 - dir * 6, 55, 3, 3, skin.darkened(0.3))
	_e(img, 32, 40, 12, 16, skin, true)
	if not back:
		_r(img, 28, 32, 8, 18, Color("#f0e0a0"))
	for i: int in 3:
		_leaf(img, Vector2(32 - dir * 10, 30 + i * 8), Vector2(32 - dir * 24, 26 + i * 8), 4,
			Color("#e8e8f8"))
	_e(img, 32, 19, 12, 10, skin, true)
	_r(img, 32 + dir * 9, 17, 11, 4, skin.darkened(0.08))
	for i: int in 4:
		_line(img, Vector2(26 + i * 4, 10), Vector2(24 + i * 4, 3), skin.darkened(0.2), 2)
	if not back:
		_eye(img, 23, 15, Color("#e03040"))


# --- Poissoroy, Magicarpe ------------------------------------------------------------

func _draw_seaking(img: Image, back: bool) -> void:
	var body := Color("#f07a30")
	var white := Color("#f4f0ec")
	var dir := 1 if back else -1
	_leaf(img, Vector2(32 - dir * 18, 40), Vector2(32 - dir * 31, 26), 8, white)
	_leaf(img, Vector2(32 - dir * 18, 40), Vector2(32 - dir * 31, 56), 8, white)
	_e(img, 32, 40, 22, 15, body, true)
	_e(img, 26, 36, 6, 5, white)
	_e(img, 38, 46, 6, 4, white)
	_leaf(img, Vector2(32, 26), Vector2(32 - dir * 8, 10), 6, body.darkened(0.1))
	_line(img, Vector2(32 + dir * 20, 34), Vector2(32 + dir * 30, 22), Color("#e8d8b0"), 3)
	if not back:
		_eye(img, 15, 34, Color("#2a6a8a"))
		_r(img, 11, 43, 5, 2, Color("#e05878"))


func _draw_magikarp(img: Image, back: bool) -> void:
	var body := Color("#e8603a")
	var fin := Color("#f4e0a0")
	var dir := 1 if back else -1
	_leaf(img, Vector2(32 - dir * 18, 42), Vector2(32 - dir * 30, 30), 7, fin)
	_leaf(img, Vector2(32 - dir * 18, 42), Vector2(32 - dir * 30, 56), 7, fin)
	_e(img, 32, 42, 20, 16, body, true)
	_leaf(img, Vector2(32, 27), Vector2(32 - dir * 10, 14), 6, fin)
	for i: int in 3:
		_line(img, Vector2(28 + i * 5, 34), Vector2(26 + i * 5, 50), body.darkened(0.15))
	_line(img, Vector2(32 + dir * 18, 44), Vector2(32 + dir * 28, 52), fin, 2)
	if not back:
		_eye(img, 14, 36, Color("#2a2a30"))
		_e(img, 13, 46, 3, 3, Color("#f0c0b0"))


# --- Amonita, Amonistar --------------------------------------------------------------

func _draw_omanyte(img: Image, back: bool) -> void:
	_draw_ammonite(img, back, 16.0, false)


func _draw_omastar(img: Image, back: bool) -> void:
	_draw_ammonite(img, back, 20.0, true)


func _draw_ammonite(img: Image, back: bool, r: float, spikes: bool) -> void:
	var shell := Color("#d8c890")
	var body := Color("#6ab0e0")
	for i: int in 6:
		var x := 32.0 - 12.0 + i * 5.0
		_line(img, Vector2(x, 44), Vector2(x + sin(i * 2.0) * 3.0, 61), body, 3)
	if spikes:
		for i: int in 5:
			var a := -PI * 0.9 + i * PI * 0.2
			_line(img, Vector2(32, 32) + Vector2(cos(a), sin(a)) * r,
				Vector2(32, 32) + Vector2(cos(a), sin(a)) * (r + 8), shell.darkened(0.2), 3)
	_e(img, 32, 32, r, r, shell, true)
	_spiral(img, 32, 30, r - 4, shell.darkened(0.15), shell.lightened(0.1))
	if back:
		return
	_e(img, 32, 46, 10, 6, body, true)
	_e(img, 27, 45, 3, 3, WHITE)
	_e(img, 37, 45, 3, 3, WHITE)
	_r(img, 27, 45, 2, 2, EYE)
	_r(img, 37, 45, 2, 2, EYE)


# --- Kabuto, Kabutops ----------------------------------------------------------------

func _draw_kabuto(img: Image, back: bool) -> void:
	var shell := Color("#a06a3a")
	for i: int in 3:
		_line(img, Vector2(22 + i * 10, 52), Vector2(20 + i * 10, 61), Color("#5a4030"), 2)
	_e(img, 32, 44, 22, 16, shell, true)
	_line(img, Vector2(14, 44), Vector2(50, 44), shell.darkened(0.25))
	if back:
		_line(img, Vector2(32, 30), Vector2(32, 58), shell.darkened(0.25))
		return
	_e(img, 32, 54, 14, 5, Color("#2a2020"))
	_e(img, 26, 53, 2, 2, Color("#f0d040"))
	_e(img, 38, 53, 2, 2, Color("#f0d040"))


func _draw_kabutops(img: Image, back: bool) -> void:
	var shell := Color("#a06a3a")
	var blade := Color("#e0d8c0")
	_line(img, Vector2(24, 54), Vector2(20, 61), shell.darkened(0.2), 4)
	_line(img, Vector2(40, 54), Vector2(44, 61), shell.darkened(0.2), 4)
	_e(img, 32, 42, 12, 16, shell, true)
	_line(img, Vector2(21, 34), Vector2(10, 24), shell, 4)
	_line(img, Vector2(43, 34), Vector2(54, 24), shell, 4)
	_leaf(img, Vector2(10, 24), Vector2(4, 44), 4, blade)
	_leaf(img, Vector2(54, 24), Vector2(60, 44), 4, blade)
	_e(img, 32, 18, 11, 9, shell, true)
	_line(img, Vector2(32, 10), Vector2(32, 4), shell.darkened(0.2), 2)
	if back:
		return
	_e(img, 32, 44, 7, 10, Color("#d8c8a0"))
	_e(img, 27, 18, 2, 2, Color("#e03040"))
	_e(img, 37, 18, 2, 2, Color("#e03040"))


# --- Artikodin -----------------------------------------------------------------------

func _draw_articuno(img: Image, back: bool) -> void:
	var feather := Color("#6ac0e8")
	var light := Color("#d8f0fa")
	var dir := 1 if back else -1
	_leaf(img, Vector2(32 - dir * 6, 46), Vector2(32 - dir * 28, 60), 6, feather.darkened(0.15))
	_leaf(img, Vector2(26, 30), Vector2(2, 14), 9, feather)
	_leaf(img, Vector2(38, 30), Vector2(62, 14), 9, feather)
	_e(img, 32, 38, 11, 14, feather, true)
	if not back:
		_e(img, 32, 40, 6, 9, light)
	_e(img, 32 + dir * 3, 18, 8, 8, feather, true)
	for i: int in 3:
		_leaf(img, Vector2(30 - dir * 2, 11), Vector2(26 - dir * (4 + i * 3), 2 + i * 2), 2, light)
	_r(img, 28, 56, 2, 5, Color("#8a8a9a"))
	_r(img, 35, 56, 2, 5, Color("#8a8a9a"))
	if not back:
		_r(img, 32 - 9, 18, 6, 3, Color("#8a8a9a"))
		_eye(img, 28, 13, Color("#e03040"))
