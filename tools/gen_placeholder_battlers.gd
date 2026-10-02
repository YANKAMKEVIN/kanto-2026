extends SceneTree
## Génère les sprites de combat provisoires des trois starters (jalon-04.md §14.4, T6).
## Pixel art 64 × 64 natif, affiché en NEAREST par le BattleStage (×4 de dos, ×3 de face) :
##   assets/sprites/pokemon/placeholder/<espèce>_front.png   (vue de face : l'adversaire)
##   assets/sprites/pokemon/placeholder/<espèce>_back.png    (vue de dos : le Pokémon du joueur)
##   assets/sprites/pokemon/placeholder/battle_shadow.png     (ombre ovale au sol, 40 × 10)
## Mêmes silhouettes et couleurs que les sprites du monde (tools/gen_placeholder_npcs.gd),
## plus détaillées : ombrage à gauche (lumière en haut à gauche), reflets, contour sombre de
## 1 px. Pieds sur la dernière rangée utile (y = 61) : BattleStage pose l'origine aux pieds.
## De dos, la flamme de Salamèche reste lisible (queue relevée à droite).
##
##   godot --headless --path . -s res://tools/gen_placeholder_battlers.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
const SIZE: int = 64
const SPECIES: Array[String] = ["bulbasaur", "charmander", "squirtle", "pidgey", "rattata"]
const OUTLINE := Color("#1c1c28")
const EYE := Color("#1c1c28")
const WHITE := Color("#f4f4f4")
const SHADOW_SIZE := Vector2i(40, 10)

var _w: int = SIZE
var _h: int = SIZE


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for species: String in SPECIES:
		for back: bool in [false, true]:
			var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			call("_draw_" + species, img, back)
			_outline(img)
			img.save_png(DIR + "%s_%s.png" % [species, "back" if back else "front"])
	_write_shadow()
	print("Sprites de combat provisoires OK (%d espèces)" % SPECIES.size())
	quit()


# --- Primitives -------------------------------------------------------------------

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < _w and y < _h:
		img.set_pixel(x, y, c)


func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_px(img, xx, yy, c)


## Ellipse pleine ; avec [param shade], moitié droite-basse assombrie, liseré clair en haut
## à gauche (volume lisible à grande échelle).
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


## Contour sombre de 1 px autour des pixels opaques.
func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y: int in _h:
		for x: int in _w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < _w and p.y < _h and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


## Œil de face : blanc, iris, pupille, reflet.
func _eye(img: Image, x: int, y: int, iris: Color) -> void:
	_r(img, x, y, 5, 6, WHITE)
	_r(img, x + 1, y + 1, 4, 5, iris)
	_r(img, x + 2, y + 2, 3, 4, EYE)
	_r(img, x + 2, y + 2, 1, 1, WHITE)


# --- Bulbizarre -------------------------------------------------------------------

func _draw_bulbasaur(img: Image, back: bool) -> void:
	var body := Color("#6cc0a0")
	var spot := Color("#3f8a70")
	var bulb := Color("#4f9a4a")
	var leaf := Color("#3a7a38")
	if back:
		# Pattes arrière, corps, tête derrière le bulbe, oreilles, le bulbe domine.
		_e(img, 32, 50, 22, 11, body, true)
		_r(img, 12, 52, 8, 10, body.darkened(0.15))
		_r(img, 44, 52, 8, 10, body.darkened(0.15))
		_r(img, 12, 60, 8, 2, body.darkened(0.3))
		_r(img, 44, 60, 8, 2, body.darkened(0.3))
		_e(img, 32, 30, 16, 12, body, true)
		_r(img, 17, 17, 5, 7, body)
		_r(img, 42, 17, 5, 7, body)
		_e(img, 32, 40, 19, 17, bulb, true)
		_line(img, Vector2(32, 25), Vector2(32, 55), leaf, 2)
		_line(img, Vector2(20, 32), Vector2(27, 52), leaf)
		_line(img, Vector2(44, 32), Vector2(37, 52), leaf)
		_e(img, 25, 32, 4, 5, bulb.lightened(0.28))
		_r(img, 10, 44, 5, 4, spot)
		_r(img, 50, 46, 4, 4, spot)
		return
	# De face : bulbe derrière la tête, pattes avant, grande tête, yeux rouges.
	_e(img, 32, 20, 16, 13, bulb, true)
	_line(img, Vector2(32, 8), Vector2(32, 20), leaf, 2)
	_e(img, 26, 15, 4, 4, bulb.lightened(0.28))
	_e(img, 32, 48, 22, 12, body, true)
	_r(img, 10, 50, 9, 12, body.darkened(0.12))
	_r(img, 45, 50, 9, 12, body.darkened(0.12))
	_r(img, 10, 60, 9, 2, body.darkened(0.3))
	_r(img, 45, 60, 9, 2, body.darkened(0.3))
	_e(img, 32, 37, 19, 13, body, true)
	_r(img, 14, 23, 5, 7, body)
	_r(img, 45, 23, 5, 7, body)
	_eye(img, 20, 34, Color("#c0392b"))
	_eye(img, 39, 34, Color("#c0392b"))
	_r(img, 26, 45, 12, 2, spot.darkened(0.2))
	_r(img, 28, 47, 8, 1, Color("#d06a6a"))
	_r(img, 18, 26, 4, 3, spot)
	_r(img, 41, 28, 3, 3, spot)
	_r(img, 30, 29, 4, 3, spot)


# --- Salamèche --------------------------------------------------------------------

func _draw_charmander(img: Image, back: bool) -> void:
	var skin := Color("#f08a3a")
	var belly := Color("#f8d890")
	if back:
		# Queue relevée à droite, flamme bien visible ; tête et dos.
		_line(img, Vector2(38, 56), Vector2(52, 46), skin.darkened(0.1), 4)
		_line(img, Vector2(52, 46), Vector2(55, 34), skin.darkened(0.1), 3)
		_flame(img, Vector2(55, 25), 7.0)
		_r(img, 20, 52, 9, 10, skin.darkened(0.18))
		_r(img, 35, 52, 9, 10, skin.darkened(0.18))
		_e(img, 32, 44, 14, 15, skin, true)
		_r(img, 15, 36, 6, 10, skin.darkened(0.1))
		_r(img, 43, 36, 6, 10, skin.darkened(0.1))
		_e(img, 32, 22, 15, 14, skin, true)
		_e(img, 27, 17, 4, 3, skin.lightened(0.22))
		_line(img, Vector2(32, 34), Vector2(32, 56), skin.darkened(0.2))
		return
	# De face : queue à gauche (côté du joueur), flamme ; ventre crème, grands yeux.
	_line(img, Vector2(20, 56), Vector2(10, 46), skin.darkened(0.1), 4)
	_line(img, Vector2(10, 46), Vector2(8, 36), skin.darkened(0.1), 3)
	_flame(img, Vector2(8, 27), 7.0)
	_r(img, 20, 52, 9, 10, skin.darkened(0.15))
	_r(img, 35, 52, 9, 10, skin.darkened(0.15))
	_r(img, 19, 60, 3, 2, WHITE)
	_r(img, 41, 60, 3, 2, WHITE)
	_e(img, 32, 45, 13, 14, skin, true)
	_e(img, 32, 47, 8, 11, belly)
	_r(img, 15, 36, 6, 9, skin)
	_r(img, 43, 36, 6, 9, skin)
	_e(img, 32, 22, 15, 14, skin, true)
	_eye(img, 22, 17, Color("#2a6a8a"))
	_eye(img, 37, 17, Color("#2a6a8a"))
	_r(img, 26, 29, 12, 2, skin.darkened(0.4))
	_r(img, 28, 31, 8, 2, Color("#c0503a"))


func _flame(img: Image, center: Vector2, size: float) -> void:
	_e(img, center.x, center.y, size * 0.8, size * 1.3, Color("#e84020"))
	_e(img, center.x, center.y + size * 0.3, size * 0.55, size * 0.85, Color("#f8c030"))
	_e(img, center.x, center.y + size * 0.5, size * 0.25, size * 0.4, Color("#fff4c0"))


# --- Carapuce ---------------------------------------------------------------------

func _draw_squirtle(img: Image, back: bool) -> void:
	var skin := Color("#7ec8e8")
	var shell := Color("#b0703a")
	var rim := Color("#f0e0a0")
	if back:
		# Carapace brune à écailles, queue enroulée en bas à droite, tête derrière.
		_e(img, 32, 20, 14, 13, skin, true)
		_r(img, 20, 52, 9, 10, skin.darkened(0.15))
		_r(img, 35, 52, 9, 10, skin.darkened(0.15))
		_r(img, 11, 32, 7, 10, skin)
		_r(img, 46, 32, 7, 10, skin)
		_e(img, 32, 42, 18, 17, rim, true)
		_e(img, 32, 42, 16, 15, shell, true)
		for p: Vector2i in [Vector2i(32, 32), Vector2i(24, 40), Vector2i(40, 40),
				Vector2i(32, 48), Vector2i(26, 52), Vector2i(38, 52)]:
			_e(img, p.x, p.y, 4, 3, shell.lightened(0.15))
		_e(img, 52, 55, 5, 5, skin, true)
		_e(img, 52, 55, 2, 2, skin.darkened(0.35))
		return
	# De face : ventre crème à plaques, bord de carapace, queue à droite, grands yeux.
	_e(img, 52, 52, 5, 5, skin, true)
	_e(img, 52, 52, 2, 2, skin.darkened(0.35))
	_e(img, 32, 44, 16, 16, shell, true)
	_e(img, 32, 44, 13, 14, rim)
	_r(img, 23, 40, 18, 1, shell.darkened(0.2))
	_r(img, 23, 46, 18, 1, shell.darkened(0.2))
	_r(img, 24, 52, 16, 1, shell.darkened(0.2))
	_r(img, 20, 54, 9, 8, skin.darkened(0.1))
	_r(img, 35, 54, 9, 8, skin.darkened(0.1))
	_r(img, 12, 36, 7, 9, skin)
	_r(img, 45, 36, 7, 9, skin)
	_e(img, 32, 20, 15, 14, skin, true)
	_eye(img, 22, 15, Color("#7a3a20"))
	_eye(img, 37, 15, Color("#7a3a20"))
	_r(img, 27, 27, 10, 2, skin.darkened(0.4))


# --- Roucool ----------------------------------------------------------------------

func _draw_pidgey(img: Image, back: bool) -> void:
	var feather := Color("#b08050")
	var cream := Color("#f0dca8")
	var beak := Color("#e0a040")
	var crest := Color("#8a5a30")
	if back:
		# Vu de dos : corps, ailes repliées, queue en éventail, tête et crête.
		_e(img, 32, 46, 20, 16, feather, true)
		_r(img, 22, 55, 6, 7, crest)
		_r(img, 30, 56, 5, 6, feather.darkened(0.15))
		_r(img, 37, 55, 6, 7, crest)
		_e(img, 15, 44, 6, 12, feather.darkened(0.14))
		_e(img, 49, 44, 6, 12, feather.darkened(0.14))
		_e(img, 32, 24, 15, 13, feather, true)
		_r(img, 27, 9, 3, 7, crest)
		_r(img, 34, 9, 3, 7, crest)
		return
	# De face : corps rond, ventre crème, ailes, pattes, grands yeux, bec, crête.
	_e(img, 32, 46, 20, 16, feather, true)
	_e(img, 32, 50, 12, 11, cream)
	_e(img, 14, 44, 6, 12, feather.darkened(0.12))
	_e(img, 50, 44, 6, 12, feather.darkened(0.12))
	_r(img, 25, 59, 3, 3, beak)
	_r(img, 36, 59, 3, 3, beak)
	_e(img, 32, 24, 15, 14, feather, true)
	_e(img, 32, 28, 9, 7, cream)
	_r(img, 27, 9, 3, 7, crest)
	_r(img, 34, 9, 3, 7, crest)
	_eye(img, 21, 19, Color("#2a2a2a"))
	_eye(img, 38, 19, Color("#2a2a2a"))
	_r(img, 29, 27, 6, 3, beak)
	_r(img, 30, 30, 4, 2, beak.darkened(0.2))


# --- Rattata ----------------------------------------------------------------------

func _draw_rattata(img: Image, back: bool) -> void:
	var fur := Color("#9a6ab8")
	var belly := Color("#f0e0c0")
	var ear := Color("#e0a0b0")
	var tail := Color("#c89ad8")
	if back:
		# Vu de dos : queue enroulée, corps, pattes, tête, grandes oreilles.
		_line(img, Vector2(46, 54), Vector2(60, 40), tail, 3)
		_e(img, 32, 46, 20, 15, fur, true)
		_r(img, 18, 54, 8, 8, fur.darkened(0.15))
		_r(img, 38, 54, 8, 8, fur.darkened(0.15))
		_e(img, 32, 24, 16, 13, fur, true)
		_e(img, 18, 12, 7, 8, fur)
		_e(img, 46, 12, 7, 8, fur)
		return
	# De face : queue à droite, corps, ventre crème, pattes, oreilles, yeux rouges, crocs.
	_line(img, Vector2(46, 56), Vector2(60, 46), tail, 3)
	_e(img, 32, 47, 20, 15, fur, true)
	_e(img, 32, 50, 12, 11, belly)
	_r(img, 20, 56, 8, 6, fur.darkened(0.12))
	_r(img, 36, 56, 8, 6, fur.darkened(0.12))
	_e(img, 32, 24, 17, 15, fur, true)
	_e(img, 32, 30, 10, 8, belly)
	_e(img, 16, 12, 8, 9, fur)
	_e(img, 48, 12, 8, 9, fur)
	_e(img, 16, 12, 4, 5, ear)
	_e(img, 48, 12, 4, 5, ear)
	_eye(img, 21, 19, Color("#c0392b"))
	_eye(img, 38, 19, Color("#c0392b"))
	_r(img, 30, 30, 4, 2, Color("#7a3a20"))
	_r(img, 29, 33, 2, 3, WHITE)
	_r(img, 33, 33, 2, 3, WHITE)
	_line(img, Vector2(24, 31), Vector2(11, 29), fur.darkened(0.25))
	_line(img, Vector2(40, 31), Vector2(53, 29), fur.darkened(0.25))


# --- Ombre ------------------------------------------------------------------------

## Ombre ovale au sol, pixel art (bord en escalier), noir translucide.
func _write_shadow() -> void:
	_w = SHADOW_SIZE.x
	_h = SHADOW_SIZE.y
	var img := Image.create_empty(_w, _h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(_w, _h) / 2.0
	for y: int in _h:
		for x: int in _w:
			var d := Vector2((x + 0.5 - c.x) / c.x, (y + 0.5 - c.y) / c.y).length_squared()
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.42 if d < 0.55 else 0.28))
	img.save_png(DIR + "battle_shadow.png")
	_w = SIZE
	_h = SIZE
