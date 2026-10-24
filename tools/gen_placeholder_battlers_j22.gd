extends SceneTree
## Sprites de combat provisoires des 13 espèces du jalon 22 (`jalon-22.md` §2.12, §2.15, T7) :
## Magicarpe, Krabby, Poissoroy, Mimitoss, Aéromite, Doduo, Dodrio, Canarticho, Tadmorv,
## Grotadmorv, Smogogo, Électrode, Machopeur (`test_battle_art.gd` : chaque espèce des données a
## sa face et son dos).
## Fichier à part de `tools/gen_placeholder_battlers.gd` (que d'autres jalons modifient en
## parallèle), sur le modèle de `gen_placeholder_battlers_j24.gd` : mêmes règles (pixel art
## 64 × 64, contour sombre de 1 px, pieds à y = 61, lumière en haut à gauche), mêmes primitives
## recopiées. **Krabby, Poissoroy et Magicarpe sont recopiés à l'identique du J24** (mêmes images :
## la fusion des deux jalons ne crée pas de conflit). Le dos peint (rendu X/Y repeint par Colab,
## `serie-combat-dos-pilote.md` §7) remplacera ces dos : la chaîne ne tourne pas sur le Mac
## (repeint sur Colab, modèles X/Y à télécharger ; seul Magicarpe a un modèle et un prototype,
## `battle_proto/dos_ia_129.png`).
##
##   godot --headless --path . -s res://tools/gen_placeholder_battlers_j22.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
const SIZE: int = 64
const SPECIES: Array[String] = [
	"magikarp", "krabby", "seaking", "venonat", "venomoth", "doduo", "dodrio", "farfetchd",
	"grimer", "muk", "weezing", "electrode", "machoke",
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
	print("Sprites de combat provisoires du J22 OK (%d espèces)" % SPECIES.size())
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


# --- Krabby (recopié du J24) ----------------------------------------------------------

func _draw_krabby(img: Image, back: bool) -> void:
	_draw_crab(img, back, Color("#e0603a"), 6.0, 6.0)


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


# --- Poissoroy, Magicarpe (recopiés du J24) -----------------------------------------

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




# --- Mimitoss, Aéromite -----------------------------------------------------------------

## Mimitoss : boule de duvet violette, grands yeux à facettes rouges, antennes, pattes courtes.
func _draw_venonat(img: Image, back: bool) -> void:
	var fur := Color("#7a58a8")
	_line(img, Vector2(26, 20), Vector2(22, 6), fur.darkened(0.2), 2)
	_line(img, Vector2(38, 20), Vector2(42, 6), fur.darkened(0.2), 2)
	_r(img, 20, 54, 7, 7, fur.darkened(0.25))
	_r(img, 37, 54, 7, 7, fur.darkened(0.25))
	_e(img, 32, 38, 19, 18, fur, true)
	for p: Vector2i in [Vector2i(17, 28), Vector2i(47, 30), Vector2i(20, 48), Vector2i(44, 50)]:
		_e(img, p.x, p.y, 2, 2, fur.lightened(0.2))
	if back:
		return
	_e(img, 24, 34, 6, 6, Color("#d83040"), true)
	_e(img, 40, 34, 6, 6, Color("#d83040"), true)
	_r(img, 22, 32, 2, 2, WHITE)
	_r(img, 38, 32, 2, 2, WHITE)
	_r(img, 29, 46, 6, 2, Color("#f0e0f0"))


## Aéromite : papillon de nuit, corps violet clair, grandes ailes mauves poudrées, antennes.
func _draw_venomoth(img: Image, back: bool) -> void:
	var wing := Color("#c8a8e0")
	var body := Color("#9a78c8")
	_leaf(img, Vector2(30, 32), Vector2(4, 12), 10, wing)
	_leaf(img, Vector2(34, 32), Vector2(60, 12), 10, wing)
	_leaf(img, Vector2(30, 40), Vector2(10, 54), 7, wing.darkened(0.1))
	_leaf(img, Vector2(34, 40), Vector2(54, 54), 7, wing.darkened(0.1))
	for p: Vector2i in [Vector2i(14, 20), Vector2i(50, 20), Vector2i(16, 48), Vector2i(48, 48)]:
		_e(img, p.x, p.y, 2, 2, wing.darkened(0.3))
	_e(img, 32, 44, 7, 12, body, true)
	_e(img, 32, 26, 8, 7, body, true)
	_line(img, Vector2(29, 20), Vector2(25, 9), body.darkened(0.3))
	_line(img, Vector2(35, 20), Vector2(39, 9), body.darkened(0.3))
	_line(img, Vector2(30, 56), Vector2(28, 61), body.darkened(0.2), 2)
	_line(img, Vector2(34, 56), Vector2(36, 61), body.darkened(0.2), 2)
	if back:
		return
	_e(img, 28, 26, 3, 3, Color("#4a90d8"))
	_e(img, 36, 26, 3, 3, Color("#4a90d8"))


# --- Doduo, Dodrio ----------------------------------------------------------------------

func _draw_doduo(img: Image, back: bool) -> void:
	_draw_runner_bird(img, back, [Vector2(23, 14), Vector2(41, 14)], 6.0)


func _draw_dodrio(img: Image, back: bool) -> void:
	_draw_runner_bird(img, back, [Vector2(17, 16), Vector2(47, 16), Vector2(32, 8)], 5.5)


## Oiseau coureur brun (Doduo, Dodrio) : corps rond, longues pattes, plusieurs têtes au bout
## de cous fins, bec pointu ; de dos, la queue de plumes sombres.
func _draw_runner_bird(img: Image, back: bool, heads: Array[Vector2], r: float) -> void:
	var feather := Color("#b07840")
	var leg := Color("#a89070")
	var beak := Color("#e8c890")
	_line(img, Vector2(26, 46), Vector2(24, 61), leg, 2)
	_line(img, Vector2(38, 46), Vector2(40, 61), leg, 2)
	_r(img, 21, 60, 6, 2, leg.darkened(0.2))
	_r(img, 38, 60, 6, 2, leg.darkened(0.2))
	for head: Vector2 in heads:
		_line(img, Vector2(32, 36), head + Vector2(0, r), feather.darkened(0.25), 2)
	_e(img, 32, 40, 14, 10, feather, true)
	if back:
		_e(img, 32, 48, 7, 4, Color("#4a3020"))
	for head: Vector2 in heads:
		_e(img, head.x, head.y, r, r, feather.lightened(0.05), true)
		if not back:
			_r(img, int(head.x) - 2, int(head.y) + 1, 4, int(r) + 2, beak)
			_r(img, int(head.x) - 3, int(head.y) - 2, 2, 2, EYE)
			_r(img, int(head.x) + 2, int(head.y) - 2, 2, 2, EYE)


# --- Canarticho -------------------------------------------------------------------------

## Canarticho : canard brun clair, ventre crème, sourcils noirs, poireau tenu sous l'aile.
func _draw_farfetchd(img: Image, back: bool) -> void:
	var feather := Color("#b08a60")
	var cream := Color("#f0e0c0")
	var leek_x := 50 if back else 14
	_line(img, Vector2(leek_x, 58), Vector2(leek_x + (4 if back else -4), 18), Color("#e8f0d0"), 3)
	_leaf(img, Vector2(leek_x + (4 if back else -4), 20), Vector2(leek_x + (10 if back else -10), 6), 3,
		Color("#58a040"))
	_r(img, 24, 56, 6, 5, Color("#e8a040"))
	_r(img, 35, 56, 6, 5, Color("#e8a040"))
	_e(img, 32, 44, 15, 13, feather, true)
	_e(img, 32, 22, 11, 10, feather, true)
	if back:
		_e(img, 32, 54, 6, 3, feather.darkened(0.3))
		return
	_e(img, 32, 48, 9, 8, cream)
	_r(img, 26, 26, 12, 4, Color("#f0c860"))
	_r(img, 24, 17, 5, 2, OUTLINE)
	_r(img, 35, 17, 5, 2, OUTLINE)
	_r(img, 26, 20, 2, 3, EYE)
	_r(img, 36, 20, 2, 3, EYE)


# --- Tadmorv, Grotadmorv ----------------------------------------------------------------

func _draw_grimer(img: Image, back: bool) -> void:
	_draw_sludge(img, back, Color("#9a6ab8"), 14.0)


func _draw_muk(img: Image, back: bool) -> void:
	_draw_sludge(img, back, Color("#8a58a8"), 20.0)


## Boue violette (Tadmorv, Grotadmorv) : flaque large au sol, corps en goutte, bras dégoulinants.
func _draw_sludge(img: Image, back: bool, sludge: Color, r: float) -> void:
	_e(img, 32, 57, r + 10, 5, sludge.darkened(0.1), true)
	_e(img, 32, 46 - r * 0.4, r, r, sludge, true)
	_e(img, 32 - r - 2, 46, 5, 8, sludge, true)
	_e(img, 32 + r + 2, 46, 5, 8, sludge, true)
	for i: int in 3:
		_e(img, 20 + i * 12, 58, 2, 3, sludge.lightened(0.15))
	if back:
		return
	var cy := 42.0 - r * 0.5
	_r(img, 24, int(cy), 5, 4, WHITE)
	_r(img, 35, int(cy), 5, 4, WHITE)
	_r(img, 26, int(cy) + 1, 2, 2, EYE)
	_r(img, 37, int(cy) + 1, 2, 2, EYE)
	_e(img, 32, cy + 9, r * 0.45, 3, sludge.darkened(0.45))


# --- Smogogo ----------------------------------------------------------------------------

## Smogogo : deux boules de gaz violettes soudées, la petite à droite, crânes pâles en relief.
func _draw_weezing(img: Image, back: bool) -> void:
	var skin := Color("#7a5a98")
	_e(img, 22, 34, 16, 15, skin, true)
	_e(img, 45, 44, 12, 11, skin, true)
	_e(img, 32, 16, 4, 3, skin.lightened(0.15), true)
	_e(img, 56, 26, 3, 3, skin.lightened(0.15), true)
	for crater: Vector2i in [Vector2i(10, 30), Vector2i(30, 24), Vector2i(52, 52)]:
		_e(img, crater.x, crater.y, 3, 2, skin.darkened(0.3))
	if back:
		return
	_e(img, 22, 46, 5, 3, Color("#e8dca0"))
	for c: Vector2 in [Vector2(22, 32), Vector2(45, 42)]:
		_r(img, int(c.x) - 7, int(c.y) - 3, 5, 4, WHITE)
		_r(img, int(c.x) + 2, int(c.y) - 3, 5, 4, WHITE)
		_r(img, int(c.x) - 5, int(c.y) - 2, 2, 3, EYE)
		_r(img, int(c.x) + 4, int(c.y) - 2, 2, 3, EYE)
		_r(img, int(c.x) - 4, int(c.y) + 4, 8, 2, skin.darkened(0.5))


# --- Électrode --------------------------------------------------------------------------

## Électrode : Voltorbe inversé, haut blanc et bas rouge, grand sourire.
func _draw_electrode(img: Image, back: bool) -> void:
	var red := Color("#d83830")
	_e(img, 32, 41, 20, 20, red, true)
	for y: int in range(21, 41):
		for x: int in range(12, 53):
			var d := Vector2((x + 0.5 - 32.0) / 20.0, (y + 0.5 - 41.0) / 20.0)
			if d.length_squared() <= 1.0:
				var c := WHITE.darkened(0.04)
				_px(img, x, y, c.darkened(0.18) if d.x * 0.6 + d.y * 0.8 > 0.55 else c)
	_r(img, 12, 40, 41, 2, OUTLINE)
	if back:
		_e(img, 24, 28, 4, 3, WHITE)
		return
	_r(img, 21, 31, 7, 5, WHITE.darkened(0.1))
	_r(img, 36, 31, 7, 5, WHITE.darkened(0.1))
	_r(img, 24, 32, 3, 4, EYE)
	_r(img, 37, 32, 3, 4, EYE)
	_line(img, Vector2(20, 28), Vector2(28, 31), OUTLINE, 2)
	_line(img, Vector2(44, 28), Vector2(36, 31), OUTLINE, 2)
	_line(img, Vector2(22, 47), Vector2(42, 47), OUTLINE, 2)
	_line(img, Vector2(22, 47), Vector2(26, 52), OUTLINE, 1)
	_line(img, Vector2(42, 47), Vector2(38, 52), OUTLINE, 1)
	_r(img, 26, 52, 12, 1, OUTLINE)


# --- Machopeur --------------------------------------------------------------------------

## Machopeur : Machoc plus grand et plus musclé, gris-bleu, ceinture de championnat dorée.
func _draw_machoke(img: Image, back: bool) -> void:
	var skin := Color("#8a9ab0")
	var crest := Color("#a03838")
	_r(img, 20, 50, 10, 12, skin.darkened(0.12))
	_r(img, 34, 50, 10, 12, skin.darkened(0.12))
	_e(img, 32, 38, 17, 15, skin, true)
	_e(img, 11, 34, 7, 12, skin, true)
	_e(img, 53, 34, 7, 12, skin, true)
	_e(img, 10, 46, 6, 5, skin.darkened(0.08), true)
	_e(img, 54, 46, 6, 5, skin.darkened(0.08), true)
	_r(img, 17, 46, 30, 5, Color("#383848"))
	_r(img, 28, 45, 8, 7, Color("#e8c040"))
	_e(img, 32, 17, 11, 10, skin, true)
	for x: int in [26, 32, 38]:
		_e(img, x, 6, 2, 4, crest, true)
	if back:
		_line(img, Vector2(32, 26), Vector2(32, 44), skin.darkened(0.25), 1)
		return
	_eye(img, 24, 14, Color("#c03030"))
	_eye(img, 35, 14, Color("#c03030"))
	_r(img, 27, 23, 10, 2, skin.darkened(0.45))
	_line(img, Vector2(24, 32), Vector2(30, 40), skin.darkened(0.3), 1)
	_line(img, Vector2(40, 32), Vector2(34, 40), skin.darkened(0.3), 1)
