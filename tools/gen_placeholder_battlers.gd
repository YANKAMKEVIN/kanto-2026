extends SceneTree
## Génère les sprites de combat provisoires des starters (jalon-04.md §14.4, T6), des espèces
## de la Route 1 (jalon 5), des quatre nouvelles espèces de la Route 22 (jalon-07.md Q-2 :
## provisoires en combat comme les autres, le peint en combat pour tous à la phase DA) et des
## huit espèces de la Forêt de Jade (jalon-09.md §2.5 : Chenipan → Papilusion, Aspicot →
## Dardargnan, Pikachu, Raichu ; les évolutions aussi, puisqu'elles naissent en combat) et des
## trois espèces des Dresseurs d'Argenta (jalon-10.md §2.3 : Sabelette, Racaillou, Onix ; en
## face, l'adversaire est l'artwork officiel, ces sprites ne servent que de repli et de dos) et
## des treize du jalon 13 (rival n° 3 : Roucoups, Herbizarre, Reptincel, Carabaffe ; Azuria :
## Stari, Staross, Hypotrempe, Kokiyas, Poissirène, Mystherbe, Ortide, Chétiflor, Boustiflor).
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
const SPECIES: Array[String] = [
	"bulbasaur", "charmander", "squirtle", "pidgey", "rattata",
	"spearow", "mankey", "nidoran_f", "nidoran_m",
	"caterpie", "metapod", "butterfree", "weedle", "kakuna", "beedrill", "pikachu", "raichu",
	"sandshrew", "geodude", "onix",
	# Jalon 13 (jalon-13.md §1.4, §2.15) : formes intermédiaires de l'équipe du rival n° 3 et
	# les neuf espèces d'Azuria (Dresseurs, Route 24, évolutions par niveau).
	"pidgeotto", "ivysaur", "charmeleon", "wartortle",
	"staryu", "starmie", "horsea", "shellder", "goldeen",
	"oddish", "gloom", "bellsprout", "weepinbell",
]
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


# --- Piafabec ---------------------------------------------------------------------

func _draw_spearow(img: Image, back: bool) -> void:
	var feather := Color("#a0643c")
	var wing := Color("#b04a32")
	var cream := Color("#ecd4a4")
	var beak := Color("#e8a8a0")
	var claw := Color("#d8b070")
	if back:
		# Vu de dos : corps, ailes rouges écartées, queue courte, tête et houppe.
		_e(img, 32, 46, 18, 15, feather, true)
		_e(img, 12, 40, 9, 13, wing, true)
		_e(img, 52, 40, 9, 13, wing, true)
		_r(img, 26, 56, 12, 6, feather.darkened(0.25))
		_e(img, 32, 24, 14, 12, feather, true)
		_r(img, 29, 8, 3, 6, wing)
		_r(img, 33, 10, 3, 5, wing)
		return
	# De face : ailes rouges écartées, ventre crème, serres, sourcils froncés, bec rose.
	_e(img, 11, 40, 9, 13, wing, true)
	_e(img, 53, 40, 9, 13, wing, true)
	_e(img, 32, 46, 18, 15, feather, true)
	_e(img, 32, 50, 11, 10, cream)
	_r(img, 25, 59, 3, 3, claw)
	_r(img, 36, 59, 3, 3, claw)
	_e(img, 32, 24, 15, 13, feather, true)
	_r(img, 29, 8, 3, 6, wing)
	_r(img, 33, 10, 3, 5, wing)
	_eye(img, 21, 19, Color("#2a2a2a"))
	_eye(img, 38, 19, Color("#2a2a2a"))
	_line(img, Vector2(19, 16), Vector2(27, 19), feather.darkened(0.45), 2)
	_line(img, Vector2(45, 16), Vector2(37, 19), feather.darkened(0.45), 2)
	_r(img, 29, 26, 6, 4, beak)
	_r(img, 30, 30, 4, 3, beak.darkened(0.2))


# --- Férosinge --------------------------------------------------------------------

func _draw_mankey(img: Image, back: bool) -> void:
	var fur := Color("#e8dcc4")
	var limb := Color("#8a5a3a")
	var nose := Color("#e0a084")
	if back:
		# Vu de dos : boule de poils, bras et jambes bruns, queue, oreilles.
		_line(img, Vector2(44, 52), Vector2(58, 40), fur.darkened(0.12), 3)
		_r(img, 20, 52, 9, 10, limb)
		_r(img, 35, 52, 9, 10, limb)
		_e(img, 10, 38, 5, 9, limb, true)
		_e(img, 54, 38, 5, 9, limb, true)
		_e(img, 32, 36, 21, 20, fur, true)
		_e(img, 11, 24, 5, 5, fur.darkened(0.1))
		_e(img, 53, 24, 5, 5, fur.darkened(0.1))
		return
	# De face : grosse boule de poils, groin rose, yeux en colère, poings bruns levés.
	_line(img, Vector2(20, 52), Vector2(6, 42), fur.darkened(0.12), 3)
	_r(img, 20, 52, 9, 10, limb)
	_r(img, 35, 52, 9, 10, limb)
	_e(img, 32, 36, 21, 20, fur, true)
	_e(img, 9, 36, 5, 6, limb, true)
	_e(img, 55, 36, 5, 6, limb, true)
	_e(img, 11, 22, 5, 5, fur.darkened(0.1))
	_e(img, 53, 22, 5, 5, fur.darkened(0.1))
	_e(img, 11, 22, 2, 2, nose)
	_e(img, 53, 22, 2, 2, nose)
	_eye(img, 20, 24, Color("#2a2a2a"))
	_eye(img, 39, 24, Color("#2a2a2a"))
	_line(img, Vector2(17, 20), Vector2(28, 25), limb, 2)
	_line(img, Vector2(47, 20), Vector2(36, 25), limb, 2)
	_e(img, 32, 37, 8, 5, nose, true)
	_r(img, 29, 36, 2, 2, nose.darkened(0.4))
	_r(img, 34, 36, 2, 2, nose.darkened(0.4))
	_r(img, 27, 44, 10, 2, limb.darkened(0.2))


# --- Nidoran ♀ --------------------------------------------------------------------

func _draw_nidoran_f(img: Image, back: bool) -> void:
	var skin := Color("#94b4e4")
	var spot := Color("#4a6aa8")
	var ear := Color("#e8eef8")
	_draw_nidoran(img, back, skin, spot, ear, false)


# --- Nidoran ♂ --------------------------------------------------------------------

func _draw_nidoran_m(img: Image, back: bool) -> void:
	var skin := Color("#c890d0")
	var spot := Color("#7a4a90")
	var ear := Color("#5ab0a0")
	_draw_nidoran(img, back, skin, spot, ear, true)


## Silhouette commune aux deux Nidoran : corps bas sur quatre pattes, grandes oreilles,
## épines sur le dos ; la femelle a de petites moustaches, le mâle une corne et de plus
## grandes oreilles.
func _draw_nidoran(img: Image, back: bool, skin: Color, spot: Color, ear: Color,
		male: bool) -> void:
	var ear_r := Vector2(8, 12) if male else Vector2(7, 9)
	if back:
		# Vu de dos : corps, épines alignées, oreilles, petite queue.
		_r(img, 14, 52, 8, 10, skin.darkened(0.15))
		_r(img, 42, 52, 8, 10, skin.darkened(0.15))
		_e(img, 32, 44, 22, 14, skin, true)
		_e(img, 32, 26, 14, 11, skin, true)
		for i: int in 4:
			_r(img, 30, 25 + i * 7, 4, 3, spot.darkened(0.1))
			_r(img, 31, 24 + i * 7, 2, 1, spot.darkened(0.1))
		_e(img, 18, 18 - ear_r.y / 2.0, ear_r.x, ear_r.y, skin, true)
		_e(img, 46, 18 - ear_r.y / 2.0, ear_r.x, ear_r.y, skin, true)
		_r(img, 20, 40, 4, 4, spot)
		_r(img, 42, 46, 4, 3, spot)
		_e(img, 32, 58, 4, 3, skin.darkened(0.1))
		return
	# De face : pattes, corps tacheté, grande tête, oreilles, yeux rouges, épines.
	_r(img, 12, 52, 9, 10, skin.darkened(0.12))
	_r(img, 43, 52, 9, 10, skin.darkened(0.12))
	_r(img, 12, 60, 9, 2, WHITE)
	_r(img, 43, 60, 9, 2, WHITE)
	_e(img, 32, 47, 21, 12, skin, true)
	_r(img, 15, 44, 4, 4, spot)
	_r(img, 46, 42, 4, 4, spot)
	_line(img, Vector2(28, 14), Vector2(26, 9), spot, 2)
	_line(img, Vector2(36, 14), Vector2(38, 9), spot, 2)
	_e(img, 32, 30, 16, 13, skin, true)
	_e(img, 13, 22 - ear_r.y / 2.0, ear_r.x, ear_r.y, skin, true)
	_e(img, 51, 22 - ear_r.y / 2.0, ear_r.x, ear_r.y, skin, true)
	_e(img, 13, 22 - ear_r.y / 2.0, ear_r.x * 0.5, ear_r.y * 0.6, ear)
	_e(img, 51, 22 - ear_r.y / 2.0, ear_r.x * 0.5, ear_r.y * 0.6, ear)
	if male:
		_line(img, Vector2(32, 20), Vector2(32, 10), Color("#f0e6f4"), 3)
	_eye(img, 21, 26, Color("#c0392b"))
	_eye(img, 38, 26, Color("#c0392b"))
	_r(img, 29, 36, 6, 2, skin.darkened(0.4))
	if not male:
		_line(img, Vector2(22, 36), Vector2(12, 34), skin.darkened(0.3))
		_line(img, Vector2(42, 36), Vector2(52, 34), skin.darkened(0.3))
		_r(img, 30, 38, 1, 2, WHITE)
		_r(img, 33, 38, 1, 2, WHITE)


# --- Chenipan ---------------------------------------------------------------------

## Chenille verte en S, anneaux, ventre crème, antenne rouge fourchue, gros œil à pupille noire.
func _draw_caterpie(img: Image, back: bool) -> void:
	var skin := Color("#78c048")
	var belly := Color("#f0e0a0")
	var ring := Color("#4f8a30")
	var horn := Color("#e04838")
	# Segments du corps, de la queue (bas) à la tête (haut) ; vus de dos, la tête est en bas
	# de la pile et l'antenne pointe vers le haut.
	var segments: Array[Vector3] = [Vector3(50, 55, 7), Vector3(40, 54, 8),
		Vector3(30, 50, 9), Vector3(24, 42, 9)]
	for seg: Vector3 in segments:
		_e(img, seg.x, seg.y, seg.z, seg.z * 0.85, skin, true)
		if not back:
			_e(img, seg.x - 1, seg.y + seg.z * 0.35, seg.z * 0.6, seg.z * 0.35, belly)
		_line(img, Vector2(seg.x + seg.z * 0.7, seg.y - seg.z * 0.6),
			Vector2(seg.x + seg.z * 0.7, seg.y + seg.z * 0.6), ring)
	_line(img, Vector2(28, 16), Vector2(24, 7), horn, 3)
	_line(img, Vector2(24, 7), Vector2(18, 5), horn, 2)
	_line(img, Vector2(24, 7), Vector2(29, 3), horn, 2)
	_e(img, 28, 26, 13, 12, skin, true)
	if back:
		_e(img, 24, 21, 4, 3, skin.lightened(0.2))
		return
	_e(img, 30, 31, 8, 5, belly)
	_e(img, 19, 24, 5, 6, Color("#1c1c28"))
	_e(img, 19, 24, 3, 4, WHITE)
	_r(img, 18, 23, 3, 4, EYE)
	_r(img, 18, 23, 1, 1, WHITE)
	_r(img, 33, 30, 4, 2, ring.darkened(0.3))


# --- Chrysacier -------------------------------------------------------------------

## Cocon vert en amande, plaques de carapace, œil en fente.
func _draw_metapod(img: Image, back: bool) -> void:
	_draw_cocoon(img, back, Color("#5ea85a"), Color("#3f7a3c"), false)


# --- Coconfort --------------------------------------------------------------------

## Cocon jaune, plus pointu, crochets latéraux, œil en fente.
func _draw_kakuna(img: Image, back: bool) -> void:
	_draw_cocoon(img, back, Color("#e8c040"), Color("#a8842a"), true)


## Silhouette commune des cocons : dressé, plaques en chevrons ; [param hooks] = Coconfort.
func _draw_cocoon(img: Image, back: bool, shell: Color, plate: Color, hooks: bool) -> void:
	_e(img, 32, 40, 15, 21, shell, true)
	_e(img, 32, 18, 11, 10, shell, true)
	if hooks:
		_line(img, Vector2(19, 30), Vector2(12, 26), plate, 3)
		_line(img, Vector2(45, 30), Vector2(52, 26), plate, 3)
		_line(img, Vector2(32, 10), Vector2(32, 4), plate, 2)
	for i: int in 4:
		var y := 30 + i * 8
		_line(img, Vector2(19, y), Vector2(32, y + 3), plate)
		_line(img, Vector2(32, y + 3), Vector2(45, y), plate)
	_e(img, 26, 26, 4, 7, shell.lightened(0.25))
	if back:
		return
	_r(img, 22, 19, 9, 3, Color("#1c1c28"))
	_r(img, 24, 19, 4, 2, WHITE)
	_r(img, 36, 19, 6, 3, Color("#1c1c28"))


# --- Papilusion -------------------------------------------------------------------

## Papillon : deux paires d'ailes blanches veinées de noir, corps violet, grands yeux rouges.
func _draw_butterfree(img: Image, back: bool) -> void:
	var wing := Color("#f4f4f8")
	var vein := Color("#3a3a48")
	var body := Color("#6a5ab0")
	for side: int in [-1, 1]:
		_e(img, 32 + side * 17, 22, 15, 14, wing, true)
		_e(img, 32 + side * 14, 44, 11, 10, wing, true)
		_e(img, 32 + side * 25, 16, 5, 5, vein)
		_line(img, Vector2(32 + side * 4, 28), Vector2(32 + side * 28, 14), vein)
		_line(img, Vector2(32 + side * 4, 40), Vector2(32 + side * 20, 50), vein)
	_e(img, 32, 40, 6, 12, body, true)
	_r(img, 27, 52, 4, 6, body.darkened(0.2))
	_r(img, 33, 52, 4, 6, body.darkened(0.2))
	_e(img, 32, 24, 10, 9, body, true)
	_line(img, Vector2(28, 16), Vector2(22, 4), vein)
	_line(img, Vector2(36, 16), Vector2(42, 4), vein)
	if back:
		return
	_e(img, 27, 24, 5, 6, Color("#d03838"))
	_e(img, 37, 24, 5, 6, Color("#d03838"))
	_r(img, 25, 22, 2, 2, WHITE)
	_r(img, 35, 22, 2, 2, WHITE)
	_r(img, 30, 31, 4, 1, body.darkened(0.4))


# --- Aspicot ----------------------------------------------------------------------

## Larve brun orangé à anneaux, dard sur la tête et au bout de la queue, nez rose.
func _draw_weedle(img: Image, back: bool) -> void:
	var skin := Color("#d89040")
	var stinger := Color("#e8e4d8")
	var nose := Color("#e88a9a")
	var segments: Array[Vector3] = [Vector3(50, 55, 6), Vector3(41, 53, 7),
		Vector3(32, 49, 8), Vector3(26, 41, 8)]
	_line(img, Vector2(55, 54), Vector2(61, 52), stinger, 2)
	for seg: Vector3 in segments:
		_e(img, seg.x, seg.y, seg.z, seg.z * 0.85, skin, true)
		_line(img, Vector2(seg.x + seg.z * 0.7, seg.y - seg.z * 0.6),
			Vector2(seg.x + seg.z * 0.7, seg.y + seg.z * 0.6), skin.darkened(0.3))
	_line(img, Vector2(28, 16), Vector2(28, 4), stinger, 3)
	_e(img, 28, 26, 12, 11, skin, true)
	if back:
		_e(img, 24, 21, 4, 3, skin.lightened(0.2))
		return
	_e(img, 27, 31, 5, 4, nose)
	_r(img, 18, 22, 4, 5, EYE)
	_r(img, 18, 22, 1, 1, WHITE)
	_r(img, 33, 22, 4, 5, EYE)
	_r(img, 33, 22, 1, 1, WHITE)


# --- Dardargnan -------------------------------------------------------------------

## Guêpe jaune et noire, ailes translucides, deux dards aux bras, un au bout de l'abdomen.
func _draw_beedrill(img: Image, back: bool) -> void:
	var yellow := Color("#f0c838")
	var black := Color("#2a2a30")
	var wing := Color("#dfe8f4")
	var stinger := Color("#e8e4d8")
	_e(img, 14, 20, 10, 7, wing)
	_e(img, 50, 20, 10, 7, wing)
	_e(img, 32, 47, 10, 13, yellow, true)
	for y: int in [42, 50]:
		_r(img, 23, y, 18, 3, black)
	_line(img, Vector2(32, 59), Vector2(32, 61), stinger, 2)
	_e(img, 32, 30, 8, 6, yellow, true)
	_line(img, Vector2(24, 30), Vector2(10, 40), yellow.darkened(0.15), 3)
	_line(img, Vector2(40, 30), Vector2(54, 40), yellow.darkened(0.15), 3)
	_line(img, Vector2(10, 40), Vector2(8, 52), stinger, 3)
	_line(img, Vector2(54, 40), Vector2(56, 52), stinger, 3)
	_e(img, 32, 16, 10, 9, yellow, true)
	_line(img, Vector2(27, 8), Vector2(22, 1), black)
	_line(img, Vector2(37, 8), Vector2(42, 1), black)
	if back:
		return
	_e(img, 27, 16, 4, 4, Color("#d03838"))
	_e(img, 37, 16, 4, 4, Color("#d03838"))
	_r(img, 26, 15, 1, 1, WHITE)
	_r(img, 36, 15, 1, 1, WHITE)


# --- Pikachu ----------------------------------------------------------------------

## Souris jaune, oreilles pointues à bout noir, joues rouges, queue en éclair.
func _draw_pikachu(img: Image, back: bool) -> void:
	_draw_mouse(img, back, Color("#f8d838"), Color("#2a2a30"), Color("#e84838"), false)


# --- Raichu -----------------------------------------------------------------------

## Souris orange, oreilles arrondies, ventre crème, longue queue fine terminée en éclair.
func _draw_raichu(img: Image, back: bool) -> void:
	_draw_mouse(img, back, Color("#e8903a"), Color("#6a4a2a"), Color("#f0d040"), true)


## Silhouette commune des deux souris électriques ; [param evolved] = Raichu (plus grand).
func _draw_mouse(img: Image, back: bool, fur: Color, tip: Color, cheek: Color,
		evolved: bool) -> void:
	var tail := Color("#2a2a30") if evolved else fur.darkened(0.08)
	var bolt := Color("#f8d838") if evolved else fur
	var tail_side := 1 if back else -1
	var tx := 32 + tail_side * 20
	_line(img, Vector2(32 + tail_side * 10, 52), Vector2(tx, 40), tail, 2 if evolved else 3)
	_line(img, Vector2(tx, 40), Vector2(tx + tail_side * 6, 30), bolt, 4)
	_line(img, Vector2(tx + tail_side * 6, 30), Vector2(tx - tail_side * 2, 24), bolt, 4)
	_line(img, Vector2(tx - tail_side * 2, 24), Vector2(tx + tail_side * 8, 12), bolt, 5)
	var body_h := 15 if evolved else 13
	_r(img, 20, 54, 9, 8, fur.darkened(0.15))
	_r(img, 35, 54, 9, 8, fur.darkened(0.15))
	_e(img, 32, 46, 15, body_h, fur, true)
	if not back and evolved:
		_e(img, 32, 48, 9, 9, Color("#f4e4c0"))
	var ear_top := 2 if evolved else 0
	for side: int in [-1, 1]:
		var base := Vector2(32 + side * 9, 20)
		var top := Vector2(32 + side * 17, ear_top + 2)
		for w: int in range(0, 6):
			_line(img, base + Vector2(side * w * 0.5 - 3, 0), top, fur)
		_line(img, top + Vector2(-side * 1, 5), top, tip, 3)
	_e(img, 32, 26, 15, 13, fur, true)
	if back:
		_r(img, 22, 40, 20, 2, fur.darkened(0.3))
		_r(img, 24, 46, 16, 2, fur.darkened(0.3))
		return
	_eye(img, 22, 21, Color("#2a2a30"))
	_eye(img, 37, 21, Color("#2a2a30"))
	_e(img, 19, 32, 4, 3, cheek)
	_e(img, 45, 32, 4, 3, cheek)
	_r(img, 31, 29, 2, 1, EYE)
	_r(img, 28, 33, 8, 1, fur.darkened(0.45))


# --- Sabelette -------------------------------------------------------------------

## Petit Pokémon trapu couleur sable, dos écaillé en briques, ventre crème, griffes blanches.
func _draw_sandshrew(img: Image, back: bool) -> void:
	var skin := Color("#e0c060")
	var scale := Color("#b08a3a")
	_r(img, 20, 54, 9, 8, skin.darkened(0.15))
	_r(img, 35, 54, 9, 8, skin.darkened(0.15))
	_e(img, 32, 44, 16, 15, skin, true)
	_e(img, 32, 24, 13, 12, skin, true)
	for side: int in [-1, 1]:
		_e(img, 32 + side * 11, 14, 4, 5, skin.darkened(0.1))
		_line(img, Vector2(32 + side * 15, 44), Vector2(32 + side * 20, 50), WHITE, 2)
	if back:
		for row: int in 4:
			for col: int in 3:
				_r(img, 22 + col * 7 + (row % 2) * 3, 32 + row * 6, 6, 4, scale)
		return
	_e(img, 32, 48, 10, 9, Color("#f4e8c0"))
	_eye(img, 23, 20, Color("#2a2a30"))
	_eye(img, 36, 20, Color("#2a2a30"))
	_r(img, 30, 29, 4, 1, skin.darkened(0.45))


# --- Racaillou --------------------------------------------------------------------

## Rocher gris arrondi, deux bras musclés, sourcils épais ; pas de jambes (il flotte bas).
func _draw_geodude(img: Image, back: bool) -> void:
	var rock := Color("#9a9488")
	for side: int in [-1, 1]:
		_line(img, Vector2(32 + side * 14, 38), Vector2(32 + side * 24, 46), rock.darkened(0.1), 6)
		_e(img, 32 + side * 26, 50, 6, 6, rock, true)
		_r(img, 32 + side * 26 - 3, 54, 2, 2, rock.darkened(0.35))
	_e(img, 32, 40, 17, 16, rock, true)
	_e(img, 22, 48, 3, 2, rock.darkened(0.3))
	_e(img, 42, 34, 3, 2, rock.darkened(0.3))
	if back:
		_e(img, 30, 30, 4, 3, rock.darkened(0.3))
		return
	_r(img, 22, 33, 8, 3, rock.darkened(0.5))
	_r(img, 34, 33, 8, 3, rock.darkened(0.5))
	_r(img, 24, 36, 4, 4, WHITE)
	_r(img, 36, 36, 4, 4, WHITE)
	_r(img, 25, 37, 2, 3, EYE)
	_r(img, 37, 37, 2, 3, EYE)
	_r(img, 27, 46, 10, 2, rock.darkened(0.5))


# --- Onix -------------------------------------------------------------------------

## Long serpent de rochers gris enroulé, tête au sommet avec une corne sur le crâne.
func _draw_onix(img: Image, back: bool) -> void:
	var rock := Color("#8e8e96")
	var segments: Array[Vector3] = [
		Vector3(14, 54, 7), Vector3(24, 56, 8), Vector3(36, 55, 8), Vector3(47, 50, 7),
		Vector3(50, 40, 7), Vector3(44, 32, 7), Vector3(34, 30, 7), Vector3(26, 24, 8),
	]
	for seg: Vector3 in segments:
		_e(img, seg.x, seg.y, seg.z, seg.z - 1, rock, true)
		_r(img, int(seg.x) - 2, int(seg.y) - 1, 3, 1, rock.darkened(0.35))
	_line(img, Vector2(24, 8), Vector2(22, 1), rock.darkened(0.2), 3)
	_e(img, 26, 14, 12, 9, rock, true)
	if back:
		return
	_r(img, 19, 12, 6, 2, WHITE)
	_r(img, 21, 12, 2, 2, EYE)
	_r(img, 18, 18, 14, 2, rock.darkened(0.5))


# --- Jalon 13 : outils ------------------------------------------------------------

## Polygone plein (étoiles de Stari et Staross, feuilles, coquille).
func _poly(img: Image, points: PackedVector2Array, c: Color) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		box = box.expand(point)
	for yy: int in range(int(box.position.y), int(box.end.y) + 1):
		for xx: int in range(int(box.position.x), int(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), points):
				_px(img, xx, yy, c)


## Étoile à cinq branches de centre [param c], rayons [param outer] et [param inner], tournée
## de [param turn] radians.
func _star(img: Image, c: Vector2, outer: float, inner: float, col: Color,
		turn: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i: int in 10:
		var radius := outer if i % 2 == 0 else inner
		var angle := -PI / 2.0 + turn + i * PI / 5.0
		points.append(c + Vector2(cos(angle), sin(angle)) * radius)
	_poly(img, points, col)


## Rapproche toutes les couleurs déjà peintes de [param col] (forme évoluée d'un dessin
## existant, avant le contour).
func _tint(img: Image, col: Color, amount: float) -> void:
	for y: int in _h:
		for x: int in _w:
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c != WHITE and c != EYE:
				img.set_pixel(x, y, c.lerp(col, amount))


## Feuille en losange de [param a] (attache) à [param b] (pointe), demi-largeur [param w].
func _leaf(img: Image, a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var n := (b - a).orthogonal().normalized() * w
	var mid := a.lerp(b, 0.45)
	_poly(img, PackedVector2Array([a, mid + n, b, mid - n]), c)
	_line(img, a, a.lerp(b, 0.8), c.darkened(0.3))


# --- Roucoups, Herbizarre, Reptincel, Carabaffe (rival n° 3) ----------------------

func _draw_pidgeotto(img: Image, back: bool) -> void:
	_draw_pidgey(img, back)
	var crest := Color("#d04a30")
	var gold := Color("#f0c040")
	for i: int in 4:
		_line(img, Vector2(30 + i, 12), Vector2(40 + i * 3, 0 + i), crest if i < 2 else gold, 2)
	_e(img, 32, 58, 10, 4, Color("#8a5a30"))


func _draw_ivysaur(img: Image, back: bool) -> void:
	_draw_bulbasaur(img, back)
	_tint(img, Color("#3f8a8a"), 0.18)
	var bud := Color("#e070a0")
	if back:
		_e(img, 32, 30, 8, 7, bud, true)
		_r(img, 31, 23, 2, 6, bud.darkened(0.3))
		return
	_e(img, 32, 10, 8, 7, bud, true)
	_leaf(img, Vector2(26, 16), Vector2(8, 10), 4, Color("#3a7a38"))
	_leaf(img, Vector2(38, 16), Vector2(56, 10), 4, Color("#3a7a38"))


func _draw_charmeleon(img: Image, back: bool) -> void:
	_draw_charmander(img, back)
	_tint(img, Color("#c0302a"), 0.45)
	_line(img, Vector2(32, 10), Vector2(36, 2), Color("#a02a24"), 3)


func _draw_wartortle(img: Image, back: bool) -> void:
	_draw_squirtle(img, back)
	_tint(img, Color("#5a6ad8"), 0.3)
	var fur := Color("#e8f0ff")
	for side: int in [-1, 1]:
		_e(img, 32 + side * 15, 7, 5, 7, fur)
	_e(img, 54 if not back else 10, 56, 7, 5, fur)


# --- Stari, Staross ---------------------------------------------------------------

func _draw_staryu(img: Image, back: bool) -> void:
	var body := Color("#c0904a")
	_star(img, Vector2(32, 36), 27, 11, body)
	_star(img, Vector2(32, 36), 21, 8, body.lightened(0.12))
	var gem := Color("#e03040") if not back else Color("#c0904a").darkened(0.25)
	_e(img, 32, 36, 6, 6, gem, true)
	if not back:
		_e(img, 30, 34, 2, 2, Color("#ffd0d0"))


func _draw_starmie(img: Image, back: bool) -> void:
	var body := Color("#8a5ab8")
	_star(img, Vector2(32, 34), 29, 12, body.darkened(0.25), PI / 5.0)
	_star(img, Vector2(32, 34), 25, 10, body)
	_star(img, Vector2(32, 34), 19, 7, body.lightened(0.15))
	_e(img, 32, 34, 7, 7, Color("#f0c040") if back else Color("#e03050"), true)
	if not back:
		_e(img, 30, 32, 2, 2, WHITE)


# --- Hypotrempe, Kokiyas, Poissirène ----------------------------------------------

func _draw_horsea(img: Image, back: bool) -> void:
	var skin := Color("#6ab0e0")
	var belly := Color("#f0e0a0")
	var dir := 1 if back else -1
	# Queue enroulée en bas, corps vertical, tête et museau tubulaire, nageoire dorsale.
	_e(img, 32 - dir * 6, 55, 7, 6, skin, true)
	_e(img, 32 - dir * 6, 55, 3, 3, skin.darkened(0.3))
	_e(img, 32, 40, 11, 15, skin, true)
	if not back:
		_r(img, 28, 32, 7, 18, belly)
		for y: int in [36, 41, 46]:
			_r(img, 28, y, 7, 1, belly.darkened(0.2))
	_leaf(img, Vector2(32 - dir * 9, 36), Vector2(32 - dir * 20, 30), 4, Color("#e8e8f8"))
	_e(img, 32, 20, 11, 10, skin, true)
	_r(img, 32 + dir * 8, 18, 10, 4, skin.darkened(0.08))
	_r(img, 32 + dir * 17, 17, 2, 6, skin.darkened(0.3))
	for i: int in 3:
		_line(img, Vector2(28 + i * 4, 11), Vector2(26 + i * 4, 4), skin.darkened(0.15), 2)
	if not back:
		_eye(img, 24, 16, Color("#2a2a30"))


func _draw_shellder(img: Image, back: bool) -> void:
	var shell := Color("#8a6ab8")
	var spike := Color("#6a4a98")
	# Coquille en éventail (côtes), pointes sur le bord ; de face, l'intérieur sombre et la
	# langue.
	for side: int in [-1, 1]:
		for i: int in 3:
			_line(img, Vector2(32 + side * (14 + i * 6), 30 + i * 8),
				Vector2(32 + side * (24 + i * 4), 26 + i * 9), spike, 3)
	_e(img, 32, 42, 24, 19, shell, true)
	for i: int in range(-3, 4):
		_line(img, Vector2(32, 58), Vector2(32 + i * 7, 25), shell.darkened(0.2))
	if back:
		return
	_e(img, 32, 44, 15, 10, Color("#2a2030"))
	_eye(img, 23, 39, Color("#2a2a30"))
	_eye(img, 37, 39, Color("#2a2a30"))
	_e(img, 32, 52, 6, 3, Color("#e05878"))


func _draw_goldeen(img: Image, back: bool) -> void:
	var body := Color("#f4f0ec")
	var orange := Color("#f07a30")
	var dir := 1 if back else -1
	# Poisson de profil : queue en voile, corps blanc à taches orange, corne, nageoires.
	_leaf(img, Vector2(32 - dir * 16, 40), Vector2(32 - dir * 30, 28), 7, orange.lightened(0.2))
	_leaf(img, Vector2(32 - dir * 16, 40), Vector2(32 - dir * 30, 54), 7, orange.lightened(0.2))
	_e(img, 32, 40, 20, 14, body, true)
	_e(img, 28, 34, 6, 5, orange)
	_e(img, 38, 45, 5, 4, orange)
	_leaf(img, Vector2(32, 28), Vector2(32 - dir * 6, 14), 5, orange)
	_leaf(img, Vector2(30, 52), Vector2(30 - dir * 4, 61), 4, orange)
	_line(img, Vector2(32 + dir * 18, 36), Vector2(32 + dir * 28, 26), Color("#e8d8b0"), 3)
	if not back:
		_eye(img, 16, 34, Color("#2a6a8a"))
		_r(img, 12, 42, 5, 2, Color("#e05878"))


# --- Mystherbe, Ortide, Chétiflor, Boustiflor -------------------------------------

func _draw_oddish(img: Image, back: bool) -> void:
	_draw_weed(img, back, Color("#4a5ab0"), Color("#4aa040"), false)


func _draw_gloom(img: Image, back: bool) -> void:
	_draw_weed(img, back, Color("#3a4a98"), Color("#3a8a38"), true)


## Corps rond et bleu, bouquet de feuilles sur la tête ; [param evolved] = Ortide (fleur rouge,
## bouche baveuse).
func _draw_weed(img: Image, back: bool, body: Color, leaf: Color, evolved: bool) -> void:
	var tips: Array[Vector2] = [Vector2(8, 10), Vector2(20, 2), Vector2(32, 0), Vector2(44, 2),
		Vector2(56, 10)]
	if evolved:
		for tip: Vector2 in tips:
			_leaf(img, Vector2(32, 28), tip + Vector2(0, 6), 6, Color("#c03a30"))
		_e(img, 32, 24, 6, 4, Color("#e8a040"))
	else:
		for tip: Vector2 in tips:
			_leaf(img, Vector2(32, 26), tip, 5, leaf)
	_r(img, 21, 55, 8, 7, body.darkened(0.2))
	_r(img, 35, 55, 8, 7, body.darkened(0.2))
	_e(img, 32, 43, 17, 15, body, true)
	if back:
		return
	_e(img, 25, 40, 3, 3, Color("#e03040"))
	_e(img, 39, 40, 3, 3, Color("#e03040"))
	_r(img, 28, 48, 8, 2, body.darkened(0.45))
	if evolved:
		_r(img, 29, 50, 2, 5, Color("#d8d0f0"))


func _draw_bellsprout(img: Image, back: bool) -> void:
	var stem := Color("#5aa040")
	var bell := Color("#f0d040")
	# Tige fine, deux feuilles en bras, racines en pieds, tête en cloche jaune.
	_line(img, Vector2(32, 30), Vector2(32, 58), stem, 3)
	_line(img, Vector2(32, 58), Vector2(24, 62), stem.darkened(0.2), 2)
	_line(img, Vector2(32, 58), Vector2(40, 62), stem.darkened(0.2), 2)
	_leaf(img, Vector2(32, 44), Vector2(14, 38), 5, stem.lightened(0.1))
	_leaf(img, Vector2(32, 44), Vector2(50, 38), 5, stem.lightened(0.1))
	_e(img, 32, 20, 14, 12, bell, true)
	_line(img, Vector2(32, 8), Vector2(36, 2), stem.darkened(0.2), 2)
	if back:
		return
	_e(img, 24, 24, 6, 4, Color("#e07858"))
	_eye(img, 33, 14, Color("#2a2a30"))


func _draw_weepinbell(img: Image, back: bool) -> void:
	var bell := Color("#e8c838")
	var leaf := Color("#4a9a40")
	# Grosse cloche suspendue à un crochet, deux feuilles, bouche large.
	_line(img, Vector2(32, 2), Vector2(32, 10), Color("#7a5a30"), 3)
	_line(img, Vector2(32, 2), Vector2(38, 4), Color("#7a5a30"), 2)
	_leaf(img, Vector2(18, 34), Vector2(4, 50), 6, leaf)
	_leaf(img, Vector2(46, 34), Vector2(60, 50), 6, leaf)
	_e(img, 32, 36, 20, 24, bell, true)
	if back:
		_r(img, 22, 30, 20, 2, bell.darkened(0.3))
		return
	_e(img, 32, 46, 12, 7, Color("#e07858"))
	_e(img, 32, 47, 9, 4, Color("#a03a30"))
	_eye(img, 22, 24, Color("#2a2a30"))
	_eye(img, 37, 24, Color("#2a2a30"))


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
