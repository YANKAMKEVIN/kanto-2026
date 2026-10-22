extends SceneTree
## Génère les sprites de combat provisoires des starters (jalon-04.md §14.4, T6), des espèces
## de la Route 1 (jalon 5), des quatre nouvelles espèces de la Route 22 (jalon-07.md Q-2 :
## provisoires en combat comme les autres, le peint en combat pour tous à la phase DA) et des
## huit espèces de la Forêt de Jade (jalon-09.md §2.5 : Chenipan → Papilusion, Aspicot →
## Dardargnan, Pikachu, Raichu ; les évolutions aussi, puisqu'elles naissent en combat) et des
## trois espèces des Dresseurs d'Argenta (jalon-10.md §2.3 : Sabelette, Racaillou, Onix ; en
## face, l'adversaire est l'artwork officiel, ces sprites ne servent que de repli et de dos).
## Correctif QA 12A : toutes les évolutions des espèces des données (Reptincel…), test
## `test_battle_art.gd` (chaque espèce des données a sa face et son dos) ; et les neuf espèces
## d'Azuria du jalon 13 (Stari, Staross, Hypotrempe, Kokiyas, Poissirène, Mystherbe, Ortide,
## Chétiflor, Boustiflor).
## Jalon 14 (jalon-14.md §2.13) : les trois espèces du Cap d'Azuria (Abra, Kadabra, Machoc).
## Jalon 15 (jalon-15.md §2.7.1) : Miaouss et Persan (Rattatac vient du jalon 12).
## Jalon 17 (jalon-17.md §2.12.1) : les huit espèces de la Route 11 et de la Cave Taupiqueur.
## Jalon 19 (jalon-19.md §2.12, T3) : Fantominus, Spectrum, Noeunoeuf, Léviator. Osselait
## et Ossatueur n'en ont pas : ils ne s'affichent jamais au J19 (SPECTRE).
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
	# Jalon 12 (jalon-12.md §2.19, T12) : les 12 espèces de la Route 3 et du Mont Sélénite, et
	# Rattatac (Sbire R3). Ajouts en fin ; les sprites existants ne changent pas.
	"jigglypuff", "wigglytuff", "ekans", "arbok", "zubat", "golbat", "paras", "parasect",
	"clefairy", "clefable", "voltorb", "koffing", "raticate",
	# Correctif QA 12A (S24) : toutes les évolutions atteignables des espèces des données (le
	# joueur peut les avoir en tête : Reptincel au N16, etc.), dessinées sur la silhouette de leur
	# forme de base (recolorée) avec un trait distinctif. Ajouts en fin ; rien d'autre ne change.
	"ivysaur", "venusaur", "charmeleon", "charizard", "wartortle", "blastoise",
	"pidgeotto", "pidgeot", "fearow", "sandslash", "nidorina", "nidoqueen", "nidorino",
	"nidoking", "primeape", "graveler", "golem",
	# Jalon 13 (jalon-13.md §2.15) : les neuf espèces d'Azuria (Dresseurs, Route 24, évolutions
	# par niveau) ; les formes du rival n° 3 sont celles du correctif QA 12A ci-dessus.
	"staryu", "starmie", "horsea", "shellder", "goldeen",
	"oddish", "gloom", "bellsprout", "weepinbell",
	"abra", "kadabra", "machop",
	# Jalon 15 (jalon-15.md §2.7.1) : Miaouss et Persan (Rattatac existe depuis le J12).
	"meowth", "persian",
	# Jalon 17 (jalon-17.md §2.12.1) : Route 11, Cave Taupiqueur, Dresseurs (dos Colab au T13).
	"diglett", "dugtrio", "drowzee", "hypno", "magnemite", "magneton", "growlithe", "vulpix",
	# Jalon 20 (jalon-20.md §2.10.1, T7) : évolutions de Caninos et Goupix (ceux du J17), Évoli et
	# ses trois évolutions, les espèces d'Erika et de Giovanni. Ajouts en fin ; dos Colab au T3.
	"arcanine", "ninetales", "eevee", "vaporeon", "jolteon", "flareon",
	"victreebel", "tangela", "vileplume", "rhyhorn", "kangaskhan",
	# Jalon 19 (jalon-19.md §2.12) : Exorcistes et rival n° 5 (Caninos vient du J17). Ajouts en fin.
	"gastly", "haunter", "exeggcute", "gyarados",
	# Jalon 26 (jalon-26.md §2.7, T3) : Lokhlass (cadeau du 7F) et Alakazam (équipes de la Sylphe,
	# rival n° 6). Ajouts en fin ; rien d'autre ne change.
	"alakazam", "lapras",
	# Jalon 26 (T3) : Osselait et Ossatueur (équipes de la Sylphe SARL, jamais montrés au J19).
	"cubone", "marowak",
	# Jalon 27 (jalon-27.md §2.4, T3) : Kicklee et Tygnon (Dojo de Combat). Ajouts en fin ; les
	# autres espèces du J27 (Aéromite, Machopeur, Ramoloss, Flagadoss, M. Mime) ont leurs images
	# copiées des branches qui les créent (J22, J24, J29).
	"hitmonlee", "hitmonchan",
	# Jalon 21 (jalon-21.md §2.16) : Ptitard et Tentacool (Pêcheurs de la Route 12, provisoires
	# acceptés [D]) et Ronflex (dos de combat ; le dos peint de la série 23 est le prototype
	# battle_proto/dos_ia_143.png, comme les autres dos IA). Ajouts en fin.
	"poliwag", "tentacool", "snorlax",
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


# --- Miaouss et Persan (J15) ------------------------------------------------------

func _draw_meowth(img: Image, back: bool) -> void:
	_draw_cat(img, back, Color("#f0deb0"), Color("#c8a060"), Color("#e8c040"), 0.0)


func _draw_persian(img: Image, back: bool) -> void:
	_draw_cat(img, back, Color("#f0dca0"), Color("#d8b880"), Color("#e04040"), 1.0)


## Chat assis, queue relevée, pièce (ou joyau) au front. [param size] : 0 = Miaouss, 1 = Persan
## (corps plus allongé, oreilles plus hautes).
func _draw_cat(img: Image, back: bool, fur: Color, ear: Color, charm: Color,
		size: float) -> void:
	var body_rx := 15.0 + 5.0 * size
	var ear_h := 8.0 + 3.0 * size
	if back:
		_line(img, Vector2(44, 56), Vector2(56, 40), fur.darkened(0.1), 3)
		_line(img, Vector2(56, 40), Vector2(52, 30), fur.darkened(0.1), 3)
		_e(img, 32, 46, body_rx, 15, fur, true)
		_r(img, 21, 54, 8, 8, fur.darkened(0.15))
		_r(img, 35, 54, 8, 8, fur.darkened(0.15))
		_e(img, 32, 24, 16, 13, fur, true)
		_e(img, 21, 12, 5, ear_h, ear.darkened(0.2))
		_e(img, 43, 12, 5, ear_h, ear.darkened(0.2))
		return
	_line(img, Vector2(44, 57), Vector2(57, 44), fur.darkened(0.1), 3)
	_line(img, Vector2(57, 44), Vector2(54, 33), fur.darkened(0.1), 3)
	_e(img, 32, 47, body_rx, 15, fur, true)
	_r(img, 21, 56, 8, 6, fur.darkened(0.12))
	_r(img, 35, 56, 8, 6, fur.darkened(0.12))
	_e(img, 32, 24, 17, 14, fur, true)
	_e(img, 20, 11, 5, ear_h, fur)
	_e(img, 44, 11, 5, ear_h, fur)
	_e(img, 20, 12, 2, ear_h - 3.0, ear.darkened(0.3))
	_e(img, 44, 12, 2, ear_h - 3.0, ear.darkened(0.3))
	_e(img, 32, 13, 4, 4, charm, true)
	_eye(img, 21, 20, Color("#3a7a3a"))
	_eye(img, 38, 20, Color("#3a7a3a"))
	_r(img, 30, 30, 4, 2, Color("#c06070"))
	_line(img, Vector2(24, 31), Vector2(9, 28), fur.darkened(0.4))
	_line(img, Vector2(40, 31), Vector2(55, 28), fur.darkened(0.4))


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


# --- Jalon 12 : Route 3 et Mont Sélénite --------------------------------------------

## Rondoudou : boule rose, grands yeux bleus, mèche frisée sur le front.
func _draw_jigglypuff(img: Image, back: bool) -> void:
	_draw_puff(img, back, 20, 14, 2)


## Grodoudou : plus grand, longues oreilles, ventre blanc.
func _draw_wigglytuff(img: Image, back: bool) -> void:
	_draw_puff(img, back, 23, 22, 6)
	if not back:
		_e(img, 32, 50, 12, 8, Color("#f8eef0"))


func _draw_puff(img: Image, back: bool, radius: int, ear: int, tuft_drop: int) -> void:
	var skin := Color("#f4a8c0")
	var cy := 61 - radius
	for side: int in [-1, 1]:
		_line(img, Vector2(32 + side * 10, cy - radius + 6),
			Vector2(32 + side * 16, cy - radius - ear + 14), skin.darkened(0.08), 5)
		_r(img, 32 + side * 12 - 4, 57, 8, 5, skin.darkened(0.15))
	_e(img, 32, cy, radius, radius, skin, true)
	_e(img, 32, cy - radius + tuft_drop + 2, 5, 5, skin.lightened(0.1))
	if back:
		return
	for x: int in [22, 37]:
		_r(img, x, cy - 6, 6, 8, WHITE)
		_r(img, x + 1, cy - 5, 5, 6, Color("#3a7ad0"))
		_r(img, x + 2, cy - 4, 3, 4, EYE)
		_r(img, x + 2, cy - 4, 1, 1, WHITE)
	_r(img, 30, cy + 6, 4, 2, skin.darkened(0.45))


## Abo : serpent violet enroulé, ventre jaune, hochet jaune au bout de la queue.
func _draw_ekans(img: Image, back: bool) -> void:
	_draw_snake(img, back, Color("#9a6ac0"), false)


## Arbok : plus sombre, capuchon déployé avec son motif.
func _draw_arbok(img: Image, back: bool) -> void:
	_draw_snake(img, back, Color("#7a4ea0"), true)


func _draw_snake(img: Image, back: bool, skin: Color, hood: bool) -> void:
	var belly := Color("#e8d070")
	var coils: Array[Vector3] = [Vector3(46, 54, 8), Vector3(32, 56, 9), Vector3(20, 52, 8),
		Vector3(26, 42, 8), Vector3(36, 36, 7)]
	_e(img, 56, 46, 3, 4, belly)
	_line(img, Vector2(54, 52), Vector2(57, 46), skin, 3)
	for coil: Vector3 in coils:
		_e(img, coil.x, coil.y, coil.z, coil.z - 2, skin, true)
		if not back:
			_r(img, int(coil.x) - 3, int(coil.y) + 2, 6, 2, belly)
	if hood:
		_e(img, 34, 20, 16, 13, skin, true)
		if not back:
			_e(img, 34, 22, 9, 7, belly.darkened(0.1))
			_r(img, 29, 20, 3, 3, Color("#c03030"))
			_r(img, 37, 20, 3, 3, Color("#c03030"))
	_e(img, 36, 14 if hood else 24, 9, 8, skin, true)
	if back:
		return
	var y := 11 if hood else 21
	_r(img, 31, y, 4, 3, belly)
	_r(img, 38, y, 4, 3, belly)
	_r(img, 32, y + 1, 2, 2, EYE)
	_r(img, 39, y + 1, 2, 2, EYE)
	_r(img, 33, y + 7, 6, 1, skin.darkened(0.45))


## Nosferapti : petit corps bleu, grandes ailes violettes, pas d'yeux, bouche ouverte.
func _draw_zubat(img: Image, back: bool) -> void:
	_draw_bat(img, back, 9, 4)


## Nosferalto : corps plus gros, bouche immense.
func _draw_golbat(img: Image, back: bool) -> void:
	_draw_bat(img, back, 13, 9)


func _draw_bat(img: Image, back: bool, body_r: int, mouth: int) -> void:
	var skin := Color("#5a8ad8")
	var wing := Color("#9a6ac8")
	for side: int in [-1, 1]:
		var tip := Vector2(32 + side * 30, 14)
		_line(img, Vector2(32 + side * 6, 26), tip, wing.darkened(0.2), 2)
		for i: int in 4:
			_line(img, tip, Vector2(32 + side * (8 + i * 5), 34 + i * 2), wing)
		_e(img, 32 + side * 18, 24, 10, 7, wing, true)
		_line(img, Vector2(32 + side * 4, 34), Vector2(32 + side * 6, 52), skin.darkened(0.1), 2)
		_line(img, Vector2(32 + side * 6, 22), Vector2(32 + side * 9, 10), skin, 3)
	_e(img, 32, 26, body_r, body_r, skin, true)
	if back:
		return
	_r(img, 32 - mouth, 26, mouth * 2, mouth + 2, Color("#802838"))
	_r(img, 32 - mouth + 1, 26, 2, 3, WHITE)
	_r(img, 32 + mouth - 3, 26, 2, 3, WHITE)


## Paras : insecte orange, deux champignons rouges tachés sur le dos, pinces.
func _draw_paras(img: Image, back: bool) -> void:
	var shell := Color("#e88a40")
	var cap := Color("#d04030")
	_e(img, 32, 50, 18, 10, shell, true)
	for side: int in [-1, 1]:
		_r(img, 32 + side * 12 - 2, 56, 4, 6, shell.darkened(0.2))
		_e(img, 32 + side * 10, 34, 9, 7, cap, true)
		_r(img, 32 + side * 10 - 2, 32, 3, 2, Color("#f4e070"))
		if not back:
			_e(img, 32 + side * 20, 54, 5, 4, shell.lightened(0.15), true)
	if back:
		return
	_r(img, 25, 46, 4, 4, WHITE)
	_r(img, 35, 46, 4, 4, WHITE)
	_r(img, 26, 47, 2, 3, EYE)
	_r(img, 36, 47, 2, 3, EYE)


## Parasect : un seul grand champignon rouge qui couvre le corps, yeux blancs.
func _draw_parasect(img: Image, back: bool) -> void:
	var shell := Color("#e07838")
	var cap := Color("#c83828")
	for side: int in [-1, 1]:
		_r(img, 32 + side * 14 - 2, 54, 4, 8, shell.darkened(0.2))
		if not back:
			_e(img, 32 + side * 22, 50, 6, 5, shell.lightened(0.1), true)
	_e(img, 32, 50, 16, 9, shell, true)
	_e(img, 32, 30, 26, 16, cap, true)
	for spot: Vector2i in [Vector2i(20, 24), Vector2i(36, 20), Vector2i(44, 32), Vector2i(26, 36)]:
		_e(img, spot.x, spot.y, 3, 2, Color("#f4e070"))
	if back:
		return
	_r(img, 25, 48, 5, 3, WHITE)
	_r(img, 35, 48, 5, 3, WHITE)


## Mélofée : rose clair, oreilles pointues au bout brun, boucle sur le front, petites ailes.
func _draw_clefairy(img: Image, back: bool) -> void:
	_draw_fairy(img, back, 15, 10)


## Mélodelfe : plus grand, ailes plus larges.
func _draw_clefable(img: Image, back: bool) -> void:
	_draw_fairy(img, back, 19, 15)


func _draw_fairy(img: Image, back: bool, radius: int, wing: int) -> void:
	var skin := Color("#f8c8d0")
	var tip := Color("#7a5038")
	var cy := 61 - radius - 4
	for side: int in [-1, 1]:
		_e(img, 32 + side * (radius + 3), cy - 2, wing / 2 + 2, wing, Color("#f4e8f0"), true)
		_line(img, Vector2(32 + side * 6, cy - radius + 2),
			Vector2(32 + side * 14, cy - radius - 12), skin, 5)
		_r(img, 32 + side * 14 - 2, cy - radius - 14, 4, 4, tip)
		_r(img, 32 + side * 8 - 4, 56, 8, 6, skin.darkened(0.12))
	_e(img, 32, cy, radius, radius, skin, true)
	_line(img, Vector2(32, cy - radius), Vector2(36, cy - radius - 5), skin.darkened(0.1), 2)
	if back:
		_e(img, 32, cy + radius - 4, 4, 4, skin.darkened(0.15))
		return
	_r(img, 24, cy - 4, 4, 5, EYE)
	_r(img, 37, cy - 4, 4, 5, EYE)
	_r(img, 24, cy - 4, 1, 1, WHITE)
	_r(img, 37, cy - 4, 1, 1, WHITE)
	_e(img, 22, cy + 3, 3, 2, Color("#f08ca0"))
	_e(img, 42, cy + 3, 3, 2, Color("#f08ca0"))


## Voltorbe : sphère rouge en haut, blanche en bas, regard mauvais.
func _draw_voltorb(img: Image, back: bool) -> void:
	var red := Color("#d83830")
	_e(img, 32, 42, 19, 19, WHITE.darkened(0.04), true)
	for y: int in range(23, 42):
		for x: int in range(12, 52):
			var d := Vector2((x + 0.5 - 32.0) / 19.0, (y + 0.5 - 42.0) / 19.0)
			if d.length_squared() <= 1.0:
				_px(img, x, y, red.darkened(0.2) if d.x * 0.6 + d.y * 0.8 > 0.55 else red)
	_r(img, 13, 41, 38, 2, OUTLINE)
	if back:
		_e(img, 24, 30, 4, 3, red.lightened(0.3))
		return
	_r(img, 22, 33, 7, 5, WHITE)
	_r(img, 35, 33, 7, 5, WHITE)
	_r(img, 24, 34, 3, 4, EYE)
	_r(img, 37, 34, 3, 4, EYE)
	_line(img, Vector2(21, 30), Vector2(29, 33), OUTLINE, 2)
	_line(img, Vector2(43, 30), Vector2(35, 33), OUTLINE, 2)


## Smogo : boule violette aux cratères, deux petites bulles de gaz.
func _draw_koffing(img: Image, back: bool) -> void:
	var skin := Color("#8a68a8")
	_e(img, 52, 18, 5, 5, skin.lightened(0.1), true)
	_e(img, 12, 24, 4, 4, skin.lightened(0.1), true)
	_e(img, 32, 38, 20, 19, skin, true)
	for crater: Vector2i in [Vector2i(16, 30), Vector2i(48, 34), Vector2i(26, 22), Vector2i(42, 50)]:
		_e(img, crater.x, crater.y, 3, 2, skin.darkened(0.3))
	if back:
		return
	_r(img, 23, 32, 6, 5, WHITE)
	_r(img, 35, 32, 6, 5, WHITE)
	_r(img, 25, 33, 3, 4, EYE)
	_r(img, 37, 33, 3, 4, EYE)
	_r(img, 27, 44, 10, 3, skin.darkened(0.5))
	_r(img, 29, 44, 2, 2, WHITE)
	_r(img, 33, 44, 2, 2, WHITE)
	_e(img, 32, 52, 6, 2, Color("#e8dca0"))


## Rattatac : rat brun clair, ventre crème, grandes incisives, moustaches.
func _draw_raticate(img: Image, back: bool) -> void:
	var fur := Color("#c8904a")
	var belly := Color("#f0e0c0")
	_line(img, Vector2(48, 56), Vector2(62, 44), fur.darkened(0.2), 3)
	_e(img, 32, 47, 22, 14, fur, true)
	_r(img, 16, 56, 9, 6, fur.darkened(0.15))
	_r(img, 39, 56, 9, 6, fur.darkened(0.15))
	_e(img, 32, 26, 18, 15, fur, true)
	_e(img, 15, 14, 7, 7, fur)
	_e(img, 49, 14, 7, 7, fur)
	if back:
		return
	_e(img, 32, 50, 13, 10, belly)
	_e(img, 32, 32, 11, 8, belly)
	_e(img, 15, 14, 4, 4, Color("#e0a080"))
	_e(img, 49, 14, 4, 4, Color("#e0a080"))
	_r(img, 22, 21, 5, 4, EYE)
	_r(img, 37, 21, 5, 4, EYE)
	_r(img, 22, 21, 1, 1, WHITE)
	_r(img, 37, 21, 1, 1, WHITE)
	_r(img, 30, 30, 4, 2, Color("#7a3a20"))
	_r(img, 28, 33, 3, 6, WHITE)
	_r(img, 33, 33, 3, 6, WHITE)
	_line(img, Vector2(24, 31), Vector2(9, 27), OUTLINE)
	_line(img, Vector2(40, 31), Vector2(55, 27), OUTLINE)


# --- Évolutions (correctif QA 12A) -------------------------------------------------

## Dessine la forme de base [param base] (de face ou de dos) sur un calque, recolore ses pixels
## colorés (teinte + [param hue], saturation × [param sat], assombris de [param dark] ; le blanc,
## le noir et les gris gardent leur valeur), puis le pose sur [param img] (par-dessus ce qui y est
## déjà dessiné : ailes, carapace dorsale…).
func _base(img: Image, back: bool, base: String, hue: float, sat: float = 1.0,
		dark: float = 0.0) -> void:
	var layer := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	layer.fill(Color(0, 0, 0, 0))
	call("_draw_" + base, layer, back)
	for y: int in SIZE:
		for x: int in SIZE:
			var c := layer.get_pixel(x, y)
			if c.a <= 0.0 or c.s < 0.15:
				continue
			var shifted := Color.from_hsv(fposmod(c.h + hue, 1.0), clampf(c.s * sat, 0.0, 1.0),
				c.v, c.a)
			layer.set_pixel(x, y, shifted.darkened(dark))
	img.blend_rect(layer, Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)


## Herbizarre : Bulbizarre plus sombre, bouton rose au sommet du bulbe.
func _draw_ivysaur(img: Image, back: bool) -> void:
	_base(img, back, "bulbasaur", 0.0, 1.0, 0.08)
	var bud := Color("#e070a0")
	var c := Vector2(32, 22) if back else Vector2(32, 8)
	_e(img, c.x, c.y, 5, 5, bud, true)
	_line(img, Vector2(c.x - 4, c.y + 4), Vector2(c.x - 8, c.y + 1), Color("#3a7a38"), 2)
	_line(img, Vector2(c.x + 4, c.y + 4), Vector2(c.x + 8, c.y + 1), Color("#3a7a38"), 2)


## Florizarre : Bulbizarre bleu-vert sombre, grande fleur rose à cœur jaune sur le dos.
func _draw_venusaur(img: Image, back: bool) -> void:
	_base(img, back, "bulbasaur", -0.03, 1.0, 0.15)
	var petal := Color("#e86a8a")
	var c := Vector2(32, 22) if back else Vector2(32, 9)
	for side: int in [-1, 1]:
		_e(img, c.x + side * 10, c.y, 9, 4, petal, true)
	_e(img, c.x, c.y - 4, 6, 4, petal, true)
	_e(img, c.x, c.y, 4, 3, Color("#f0d040"))


## Reptincel : Salamèche rouge sombre, corne vers l'arrière de la tête.
func _draw_charmeleon(img: Image, back: bool) -> void:
	_base(img, back, "charmander", -0.04, 1.1, 0.12)
	var skin := Color("#c8442c")
	if back:
		_line(img, Vector2(32, 10), Vector2(32, 3), skin, 3)
	else:
		_line(img, Vector2(40, 10), Vector2(47, 3), skin, 3)


## Dracaufeu : Salamèche orange, grandes ailes bleu-vert déployées, deux cornes.
func _draw_charizard(img: Image, back: bool) -> void:
	var wing := Color("#3a8aa0")
	for side: int in [-1, 1]:
		_e(img, 32 + side * 19, 28, 11, 15, wing, true)
		_line(img, Vector2(32 + side * 10, 30), Vector2(32 + side * 29, 14), wing.darkened(0.3), 2)
	_base(img, back, "charmander", 0.01, 1.0, 0.0)
	var skin := Color("#f08a3a")
	for side: int in [-1, 1]:
		_line(img, Vector2(32 + side * 8, 10), Vector2(32 + side * 11, 3), skin, 3)


## Carabaffe : Carapuce bleu lavande, oreilles et queue en plumes blanches.
func _draw_wartortle(img: Image, back: bool) -> void:
	var fur := Color("#e8eef8")
	for side: int in [-1, 1]:
		_e(img, 32 + side * 16, 9, 4, 8, fur, true)
	_e(img, 54, 54, 7, 7, fur, true)
	_base(img, back, "squirtle", 0.06, 1.0, 0.1)


## Tortank : Carapuce bleu foncé, deux canons gris sortant de la carapace.
func _draw_blastoise(img: Image, back: bool) -> void:
	_base(img, back, "squirtle", 0.05, 1.1, 0.22)
	var steel := Color("#9aa0aa")
	for side: int in [-1, 1]:
		var x := 32 + side * 14 - 4
		_r(img, x, 24, 9, 6, steel)
		_r(img, x, 24, 9, 2, steel.lightened(0.2))
		_r(img, x + 3, 25, 3, 3, OUTLINE)


## Roucoups : Roucool, longue crête rouge et jaune.
func _draw_pidgeotto(img: Image, back: bool) -> void:
	_base(img, back, "pidgey", 0.0, 1.0, 0.05)
	_line(img, Vector2(31, 12), Vector2(42, 2), Color("#d84030"), 3)
	_line(img, Vector2(33, 13), Vector2(45, 6), Color("#f0c040"), 2)


## Roucarnage : Roucool plus clair, très longue crête rouge et jaune retombant dans le dos.
func _draw_pidgeot(img: Image, back: bool) -> void:
	_base(img, back, "pidgey", 0.01, 1.1)
	_line(img, Vector2(31, 12), Vector2(46, 2), Color("#d84030"), 4)
	_line(img, Vector2(46, 2), Vector2(58, 14), Color("#d84030"), 3)
	_line(img, Vector2(34, 13), Vector2(48, 6), Color("#f0c040"), 2)
	_line(img, Vector2(48, 6), Vector2(57, 20), Color("#f0c040"), 2)


## Rapasdepic : Piafabec brun foncé, long bec effilé, crête rouge.
func _draw_fearow(img: Image, back: bool) -> void:
	_base(img, back, "spearow", 0.02, 0.9, 0.08)
	var beak := Color("#e8a8a0")
	if not back:
		_line(img, Vector2(32, 28), Vector2(32, 42), beak, 3)
	_e(img, 32, 9, 6, 4, Color("#c03a2a"), true)


## Sablaireau : Sabelette brun, épines brunes sur tout le dos.
func _draw_sandslash(img: Image, back: bool) -> void:
	var spike := Color("#8a5a2a")
	for i: int in 7:
		var a := lerpf(-2.4, -0.7, float(i) / 6.0)
		var base := Vector2(32, 34)
		_line(img, base + Vector2(cos(a), sin(a)) * 12.0, base + Vector2(cos(a), sin(a)) * 24.0,
			spike, 3)
	_base(img, back, "sandshrew", -0.02, 1.0, 0.12)
	if back:
		for i: int in 5:
			_line(img, Vector2(20 + i * 6, 34), Vector2(22 + i * 6, 26), spike, 2)


## Nidorina : Nidoran ♀ bleu plus clair et plus vert.
func _draw_nidorina(img: Image, back: bool) -> void:
	_base(img, back, "nidoran_f", -0.04, 1.0, 0.05)


## Nidoqueen : Nidoran ♀ bleu sombre, plastron crème.
func _draw_nidoqueen(img: Image, back: bool) -> void:
	_base(img, back, "nidoran_f", 0.0, 1.1, 0.22)
	if not back:
		_e(img, 32, 48, 11, 8, Color("#e8d8a8"), true)


## Nidorino : Nidoran ♂ violet plus soutenu, corne plus longue.
func _draw_nidorino(img: Image, back: bool) -> void:
	_base(img, back, "nidoran_m", 0.02, 1.15, 0.08)
	if not back:
		_line(img, Vector2(32, 20), Vector2(32, 5), Color("#f0e6f4"), 3)


## Nidoking : Nidoran ♂ violet sombre, plastron crème, grande corne.
func _draw_nidoking(img: Image, back: bool) -> void:
	_base(img, back, "nidoran_m", 0.04, 1.2, 0.2)
	if back:
		_line(img, Vector2(32, 18), Vector2(32, 6), Color("#f0e6f4"), 3)
		return
	_e(img, 32, 48, 11, 8, Color("#e8d8a8"), true)
	_line(img, Vector2(32, 20), Vector2(32, 3), Color("#f0e6f4"), 4)


## Colossinge : Férosinge plus clair, menottes grises aux poignets.
func _draw_primeape(img: Image, back: bool) -> void:
	_base(img, back, "mankey", 0.0)
	var steel := Color("#a0a4ac")
	var y := 38 if back else 36
	for side: int in [-1, 1]:
		_r(img, 32 + side * 22 - 4, y + 3, 8, 3, steel)


## Gravalanch : Racaillou plus massif et brun, deux bras de plus en bas.
func _draw_graveler(img: Image, back: bool) -> void:
	var rock := Color("#8a8070")
	for side: int in [-1, 1]:
		_line(img, Vector2(32 + side * 12, 50), Vector2(32 + side * 22, 58), rock, 5)
		_e(img, 32 + side * 23, 58, 5, 4, rock, true)
	_base(img, back, "geodude", 0.0, 1.5, 0.08)
	_e(img, 32, 24, 10, 6, rock, true)


## Grolem : carapace rocheuse vert-brun autour d'une tête grise.
func _draw_golem(img: Image, back: bool) -> void:
	var shell := Color("#8a8a5a")
	_e(img, 32, 42, 24, 20, shell, true)
	for p: Vector2i in [Vector2i(16, 34), Vector2i(46, 30), Vector2i(24, 52), Vector2i(42, 52)]:
		_e(img, p.x, p.y, 4, 3, shell.darkened(0.25))
	if back:
		_e(img, 32, 24, 10, 8, shell.lightened(0.1), true)
		return
	_e(img, 32, 38, 12, 10, Color("#c8b0a0"), true)
	_r(img, 25, 35, 4, 4, WHITE)
	_r(img, 35, 35, 4, 4, WHITE)
	_r(img, 26, 36, 2, 3, EYE)
	_r(img, 36, 36, 2, 3, EYE)
	_r(img, 28, 43, 8, 2, Color("#7a5a4a"))


# --- Abra, Kadabra (jalon 14) ----------------------------------------------------

## Abra : renard psychique jaune assis, yeux fermés, plastron brun, longues oreilles pointues.
func _draw_abra(img: Image, back: bool) -> void:
	_draw_psychic_fox(img, back, false)


## Kadabra : même silhouette, debout et plus grand, étoile rouge au front, moustaches,
## cuillère dans la main droite.
func _draw_kadabra(img: Image, back: bool) -> void:
	_draw_psychic_fox(img, back, true)


func _draw_psychic_fox(img: Image, back: bool, evolved: bool) -> void:
	var fur := Color("#e2b83c")
	var armor := Color("#8a5a2e")
	var head_y := 16 if evolved else 22
	var body_y := 38 if evolved else 42
	# Queue (à droite), pieds, corps, plastron, bras.
	_line(img, Vector2(44, body_y + 12), Vector2(58, body_y - 2), fur.darkened(0.1), 4)
	_r(img, 22, 56, 8, 6, fur.darkened(0.15))
	_r(img, 34, 56, 8, 6, fur.darkened(0.15))
	_e(img, 32, body_y, 14, 16 if evolved else 14, fur, true)
	if not back:
		_e(img, 32, body_y + 2, 9, 10, armor, true)
	_e(img, 15, body_y, 4, 9, fur, true)
	_e(img, 49, body_y, 4, 9, fur, true)
	if evolved and not back:
		_line(img, Vector2(52, body_y + 4), Vector2(58, body_y - 12), Color("#b8b8c4"), 2)
		_e(img, 58, body_y - 14, 3, 4, Color("#d0d0dc"), true)
	# Tête et oreilles.
	var ear := head_y - (13 if evolved else 18)
	_line(img, Vector2(20, head_y - 4), Vector2(14, ear), fur, 4)
	_line(img, Vector2(44, head_y - 4), Vector2(50, ear), fur, 4)
	_e(img, 32, head_y, 13, 11, fur, true)
	if back:
		_r(img, 26, head_y + 6, 12, 2, fur.darkened(0.2))
		return
	# Yeux fermés (Abra) ou plissés (Kadabra), museau.
	var lid := Color("#3a2a1a")
	_line(img, Vector2(22, head_y), Vector2(28, head_y + 1), lid, 2)
	_line(img, Vector2(36, head_y + 1), Vector2(42, head_y), lid, 2)
	_e(img, 32, head_y + 6, 5, 3, fur.lightened(0.15))
	_r(img, 31, head_y + 5, 2, 1, lid)
	if evolved:
		_e(img, 32, head_y - 7, 2, 2, Color("#d03a2a"))
		_line(img, Vector2(26, head_y + 7), Vector2(16, head_y + 12), fur.darkened(0.25), 1)
		_line(img, Vector2(38, head_y + 7), Vector2(48, head_y + 12), fur.darkened(0.25), 1)


# --- Machoc (jalon 14) ------------------------------------------------------------

## Petit lutteur gris-bleu debout, trois crêtes sur le crâne, ceinture de muscles, poings serrés.
func _draw_machop(img: Image, back: bool) -> void:
	var skin := Color("#8fa4b8")
	var crest := Color("#6e8296")
	_r(img, 21, 52, 9, 10, skin.darkened(0.12))
	_r(img, 34, 52, 9, 10, skin.darkened(0.12))
	_e(img, 32, 40, 14, 14, skin, true)
	_e(img, 13, 38, 5, 10, skin, true)
	_e(img, 51, 38, 5, 10, skin, true)
	_e(img, 12, 48, 5, 4, skin.darkened(0.08), true)
	_e(img, 52, 48, 5, 4, skin.darkened(0.08), true)
	_e(img, 32, 20, 12, 11, skin, true)
	_e(img, 32, 8, 3, 4, crest, true)
	_e(img, 25, 10, 3, 3, crest, true)
	_e(img, 39, 10, 3, 3, crest, true)
	if back:
		_r(img, 27, 34, 10, 2, skin.darkened(0.25))
		return
	_eye(img, 24, 17, Color("#c03030"))
	_eye(img, 35, 17, Color("#c03030"))
	_line(img, Vector2(22, 15), Vector2(29, 17), crest.darkened(0.3), 2)
	_line(img, Vector2(42, 15), Vector2(35, 17), crest.darkened(0.3), 2)
	_r(img, 27, 26, 10, 2, crest.darkened(0.4))
	_line(img, Vector2(24, 36), Vector2(30, 44), skin.darkened(0.3), 1)
	_line(img, Vector2(40, 36), Vector2(34, 44), skin.darkened(0.3), 1)


# --- Jalon 17 (jalon-17.md §2.12.1) ------------------------------------------------

## Taupiqueur : tête brune qui sort d'un monticule de terre, gros nez rose.
func _draw_diglett(img: Image, back: bool) -> void:
	_draw_mole(img, back, [Vector2(32, 34)], 11.0)


## Triopikeur : trois têtes de Taupiqueur, la plus haute au milieu.
func _draw_dugtrio(img: Image, back: bool) -> void:
	_draw_mole(img, back, [Vector2(18, 40), Vector2(46, 40), Vector2(32, 30)], 9.0)


func _draw_mole(img: Image, back: bool, heads: Array[Vector2], radius: float) -> void:
	var fur := Color("#9a6a40")
	var dirt := Color("#7a5a38")
	for head: Vector2 in heads:
		_r(img, int(head.x - radius), int(head.y), int(radius * 2.0), 60 - int(head.y), fur)
		_e(img, head.x, head.y, radius, radius * 1.1, fur, true)
	_e(img, 32, 58, 28, 6, dirt, true)
	_e(img, 20, 55, 7, 4, dirt.lightened(0.1), true)
	_e(img, 44, 56, 6, 3, dirt.lightened(0.1), true)
	if back:
		return
	for head: Vector2 in heads:
		_r(img, int(head.x - radius * 0.45), int(head.y - 2), 2, 4, EYE)
		_r(img, int(head.x + radius * 0.45) - 1, int(head.y - 2), 2, 4, EYE)
		_e(img, head.x, head.y + radius * 0.45, radius * 0.45, radius * 0.3, Color("#e07890"),
			true)


## Soporifik : corps jaune au ventre brun, long nez tombant, yeux mi-clos.
func _draw_drowzee(img: Image, back: bool) -> void:
	_draw_dream_eater(img, back, false)


## Hypno : même silhouette, plus grand, collerette blanche et pendule au bout d'un fil.
func _draw_hypno(img: Image, back: bool) -> void:
	_draw_dream_eater(img, back, true)


func _draw_dream_eater(img: Image, back: bool, evolved: bool) -> void:
	var skin := Color("#e8c040")
	var belly := Color("#7a5030")
	var head_y := 16 if evolved else 20
	_r(img, 22, 54, 8, 8, skin.darkened(0.15))
	_r(img, 34, 54, 8, 8, skin.darkened(0.15))
	_e(img, 32, 42, 15, 15, skin, true)
	if not back:
		_r(img, 18, 46, 28, 10, belly)
	_e(img, 15, 40, 4, 9, skin, true)
	_e(img, 49, 40, 4, 9, skin, true)
	if evolved:
		_e(img, 32, head_y + 11, 14, 4, WHITE.darkened(0.05), true)
		if not back:
			_line(img, Vector2(52, 38), Vector2(56, 52), Color("#b0b0b8"))
			_e(img, 56, 54, 3, 3, Color("#c8c8d4"), true)
	_e(img, 32, head_y, 12, 11, skin, true)
	_e(img, 22, head_y - 9, 3, 4, skin, true)
	_e(img, 42, head_y - 9, 3, 4, skin, true)
	if back:
		return
	_line(img, Vector2(23, head_y - 1), Vector2(28, head_y - 1), EYE, 2)
	_line(img, Vector2(36, head_y - 1), Vector2(41, head_y - 1), EYE, 2)
	_e(img, 32, head_y + 6, 4, 6, skin.darkened(0.08), true)


## Magnéti : boule d'acier à un œil, deux aimants en U, vis sur le dessus.
func _draw_magnemite(img: Image, back: bool) -> void:
	_draw_magnet(img, back, Vector2(32, 38), 12.0)


## Magnéton : trois Magnéti liés en triangle.
func _draw_magneton(img: Image, back: bool) -> void:
	for c: Vector2 in [Vector2(19, 44), Vector2(45, 44), Vector2(32, 22)]:
		_draw_magnet(img, back, c, 9.0)


func _draw_magnet(img: Image, back: bool, c: Vector2, r: float) -> void:
	var steel := Color("#a8b0bc")
	var red := Color("#d84838")
	var blue := Color("#3868c8")
	for side: float in [-1.0, 1.0]:
		var x := c.x + side * (r + 3.0)
		_r(img, int(x - 2), int(c.y - 4), 5, 8, steel.darkened(0.1))
		_r(img, int(x - 2), int(c.y - 6), 5, 3, red)
		_r(img, int(x - 2), int(c.y + 4), 5, 3, blue)
	_r(img, int(c.x - 1), int(c.y - r - 4), 3, 5, steel.darkened(0.2))
	_e(img, c.x, c.y, r, r, steel, true)
	if back:
		return
	_e(img, c.x, c.y, r * 0.45, r * 0.45, WHITE)
	_e(img, c.x, c.y, r * 0.2, r * 0.2, EYE)


## Caninos : chiot orange rayé de noir, crinière et queue crème.
func _draw_growlithe(img: Image, back: bool) -> void:
	var fur := Color("#e88a38")
	var cream := Color("#f0e0b0")
	_e(img, 52, 34, 6, 9, cream, true)
	_e(img, 32, 46, 17, 12, fur, true)
	for x: int in [24, 32, 40]:
		_line(img, Vector2(x, 38), Vector2(x - 2, 46), OUTLINE, 2)
	_r(img, 18, 54, 8, 8, fur.darkened(0.15))
	_r(img, 38, 54, 8, 8, fur.darkened(0.15))
	_e(img, 26, 24, 13, 12, fur, true)
	_e(img, 26, 14, 10, 5, cream, true)
	_e(img, 16, 16, 4, 7, fur.darkened(0.1), true)
	_e(img, 36, 16, 4, 7, fur.darkened(0.1), true)
	if back:
		return
	_e(img, 26, 31, 6, 4, cream, true)
	_r(img, 24, 29, 4, 2, OUTLINE)
	_eye(img, 18, 21, Color("#5a3a20"))
	_eye(img, 29, 21, Color("#5a3a20"))


## Goupix : renardeau brun-roux, toupet bouclé, six queues recourbées.
func _draw_vulpix(img: Image, back: bool) -> void:
	var fur := Color("#c8603a")
	var tail := Color("#e07848")
	for i: int in 6:
		var a := deg_to_rad(-70.0 + 24.0 * i)
		_line(img, Vector2(42, 46), Vector2(42, 46) + Vector2(cos(a), sin(a)) * 16.0, tail, 3)
	_e(img, 30, 46, 14, 11, fur, true)
	_r(img, 20, 54, 6, 8, fur.darkened(0.15))
	_r(img, 34, 54, 6, 8, fur.darkened(0.15))
	_e(img, 26, 26, 12, 11, fur, true)
	_e(img, 17, 14, 4, 7, fur.darkened(0.1), true)
	_e(img, 35, 14, 4, 7, fur.darkened(0.1), true)
	_e(img, 26, 15, 6, 4, tail.lightened(0.15), true)
	if back:
		return
	_eye(img, 18, 23, Color("#5a2a1a"))
	_eye(img, 29, 23, Color("#5a2a1a"))
	_r(img, 25, 32, 3, 2, OUTLINE)


# --- Jalon 20 : Routes 7 et 8, Céladopole, Erika, Giovanni ----------------------------

## Arcanin : grand chien orange, crinière et queue crème touffues, rayures noires.
func _draw_arcanine(img: Image, back: bool) -> void:
	var fur := Color("#e07a30")
	var cream := Color("#f2e2b8")
	_e(img, 54, 30, 7, 12, cream, true)
	_e(img, 34, 40, 20, 13, fur, true)
	for x: int in [28, 36, 44]:
		_line(img, Vector2(x, 31), Vector2(x - 3, 41), OUTLINE, 2)
	_r(img, 16, 50, 8, 12, fur.darkened(0.15))
	_r(img, 42, 50, 8, 12, fur.darkened(0.15))
	_e(img, 22, 26, 13, 12, cream, true)
	_e(img, 20, 16, 11, 10, fur, true)
	_e(img, 12, 7, 3, 6, fur.darkened(0.1), true)
	_e(img, 27, 7, 3, 6, fur.darkened(0.1), true)
	if back:
		return
	_e(img, 18, 22, 6, 4, cream, true)
	_r(img, 16, 20, 4, 2, OUTLINE)
	_eye(img, 12, 12, Color("#5a3a20"))
	_eye(img, 22, 12, Color("#5a3a20"))


## Feunard : renard crème élancé, neuf queues en éventail.
func _draw_ninetales(img: Image, back: bool) -> void:
	var fur := Color("#f0dca0")
	var tip := Color("#e89048")
	for i: int in 9:
		var a := deg_to_rad(-100.0 + 18.0 * i)
		var end := Vector2(44, 40) + Vector2(cos(a), sin(a)) * 18.0
		_line(img, Vector2(44, 40), end, fur.darkened(0.08), 3)
		_r(img, int(end.x) - 1, int(end.y) - 1, 3, 3, tip)
	_e(img, 30, 44, 14, 10, fur, true)
	_r(img, 20, 52, 5, 10, fur.darkened(0.15))
	_r(img, 34, 52, 5, 10, fur.darkened(0.15))
	_e(img, 22, 26, 11, 10, fur, true)
	_e(img, 14, 14, 3, 7, fur.darkened(0.1), true)
	_e(img, 29, 14, 3, 7, fur.darkened(0.1), true)
	if back:
		return
	_eye(img, 15, 23, Color("#b03030"))
	_eye(img, 25, 23, Color("#b03030"))
	_r(img, 21, 31, 3, 2, OUTLINE)


## Évoli : petit mammifère brun, collerette et bout de queue crème, grandes oreilles.
func _draw_eevee(img: Image, back: bool) -> void:
	_draw_eeveelution(img, back, Color("#a8703a"), Color("#f0e0b8"), 0)


## Aquali : corps bleu, collerette blanche en nageoire, queue de poisson.
func _draw_vaporeon(img: Image, back: bool) -> void:
	_draw_eeveelution(img, back, Color("#5aa0d8"), Color("#f0f4f8"), 1)


## Voltali : poil jaune hérissé, collerette blanche en pointes.
func _draw_jolteon(img: Image, back: bool) -> void:
	_draw_eeveelution(img, back, Color("#f0d030"), Color("#f8f8f0"), 2)


## Pyroli : poil orange, collerette et queue jaune pâle, très touffues.
func _draw_flareon(img: Image, back: bool) -> void:
	_draw_eeveelution(img, back, Color("#e86a30"), Color("#f8e098"), 3)


## Famille d'Évoli : même silhouette ; [param form] 0 Évoli, 1 Aquali, 2 Voltali, 3 Pyroli.
func _draw_eeveelution(img: Image, back: bool, fur: Color, ruff: Color, form: int) -> void:
	if form == 1:
		_line(img, Vector2(42, 48), Vector2(56, 36), fur, 4)
		_e(img, 57, 32, 5, 7, fur.lightened(0.2), true)
	else:
		_e(img, 50, 38, 7, 10, fur, true)
		_e(img, 54, 32, 4, 5, ruff, true)
	_e(img, 32, 47, 14, 10, fur, true)
	_r(img, 22, 54, 6, 8, fur.darkened(0.15))
	_r(img, 36, 54, 6, 8, fur.darkened(0.15))
	if form == 2:
		for i: int in 7:
			var a := deg_to_rad(40.0 + 16.0 * i)
			_line(img, Vector2(28, 38), Vector2(28, 38) + Vector2(cos(a), sin(a)) * 11.0, ruff, 2)
	else:
		_e(img, 28, 38, 11, 7, ruff, true)
	_e(img, 28, 24, 11, 10, fur, true)
	_e(img, 18, 10, 4, 9, fur.darkened(0.1), true)
	_e(img, 38, 10, 4, 9, fur.darkened(0.1), true)
	if form == 3:
		_e(img, 28, 15, 6, 4, ruff, true)
	if back:
		return
	_eye(img, 20, 21, Color("#4a2a1a"))
	_eye(img, 31, 21, Color("#4a2a1a"))
	_r(img, 27, 30, 3, 2, OUTLINE)


## Empiflor : grand calice jaune-vert ouvert vers le haut, feuille en couvercle, liane.
func _draw_victreebel(img: Image, back: bool) -> void:
	var bell := Color("#d8d040")
	var leaf := Color("#4a9a40")
	_line(img, Vector2(40, 8), Vector2(52, 2), Color("#7a5a30"), 2)
	_leaf(img, Vector2(36, 12), Vector2(56, 8), 6, leaf)
	_e(img, 32, 38, 20, 23, bell, true)
	_leaf(img, Vector2(14, 44), Vector2(2, 56), 6, leaf)
	_leaf(img, Vector2(50, 44), Vector2(62, 56), 6, leaf)
	if back:
		_r(img, 20, 30, 24, 2, bell.darkened(0.3))
		return
	_e(img, 32, 26, 15, 9, Color("#e8d8a0"))
	_e(img, 32, 30, 11, 5, Color("#c04040"))
	_eye(img, 20, 40, Color("#2a2a30"))
	_eye(img, 39, 40, Color("#2a2a30"))


## Saquedeneu : boule de lianes bleues emmêlées, pieds rouges, yeux dans l'ombre.
func _draw_tangela(img: Image, back: bool) -> void:
	var vine := Color("#3a5ab0")
	_r(img, 20, 55, 9, 7, Color("#c03a30"))
	_r(img, 35, 55, 9, 7, Color("#c03a30"))
	_e(img, 32, 34, 22, 22, vine, true)
	for i: int in 9:
		var y := 16 + i * 4
		_line(img, Vector2(14, y), Vector2(50, y + (2 if i % 2 == 0 else -2)),
			vine.darkened(0.3), 1)
	if back:
		return
	_r(img, 20, 30, 24, 8, Color("#101018"))
	_r(img, 24, 32, 4, 4, WHITE)
	_r(img, 36, 32, 4, 4, WHITE)


## Rafflesia : corps bleu d'Ortide, immense fleur rouge à pois blancs sur la tête.
func _draw_vileplume(img: Image, back: bool) -> void:
	var body := Color("#3a4a98")
	var petal := Color("#d03a3a")
	_e(img, 32, 16, 30, 13, petal, true)
	for p: Vector2i in [Vector2i(12, 14), Vector2i(24, 8), Vector2i(40, 8), Vector2i(52, 14),
			Vector2i(32, 20)]:
		_e(img, p.x, p.y, 3, 2, Color("#f0d0d0"))
	_e(img, 32, 16, 6, 4, Color("#6a3060"))
	_r(img, 21, 55, 8, 7, body.darkened(0.2))
	_r(img, 35, 55, 8, 7, body.darkened(0.2))
	_e(img, 32, 44, 15, 13, body, true)
	if back:
		return
	_e(img, 26, 42, 3, 3, Color("#e03040"))
	_e(img, 38, 42, 3, 3, Color("#e03040"))
	_r(img, 28, 49, 8, 2, body.darkened(0.45))


## Rhinocorne : rhinocéros gris à plaques, corne blanche sur le museau.
func _draw_rhyhorn(img: Image, back: bool) -> void:
	var hide := Color("#9a9aa8")
	_e(img, 36, 40, 22, 14, hide, true)
	for x: int in [26, 36, 46]:
		_line(img, Vector2(x, 28), Vector2(x + 4, 44), hide.darkened(0.3), 1)
	_r(img, 18, 50, 9, 12, hide.darkened(0.2))
	_r(img, 46, 50, 9, 12, hide.darkened(0.2))
	_e(img, 16, 36, 12, 10, hide, true)
	_line(img, Vector2(8, 30), Vector2(4, 20), Color("#f0ece0"), 4)
	_e(img, 20, 24, 3, 5, hide.darkened(0.15), true)
	if back:
		return
	_eye(img, 13, 31, Color("#c03030"))
	_r(img, 8, 41, 6, 2, OUTLINE)


## Kangourex : grande mère brune debout, ventre crème, petit dans la poche.
func _draw_kangaskhan(img: Image, back: bool) -> void:
	var fur := Color("#8a6a48")
	var belly := Color("#e8d8a8")
	_e(img, 46, 52, 12, 6, fur.darkened(0.1), true)
	_e(img, 32, 40, 17, 20, fur, true)
	_r(img, 20, 54, 9, 8, fur.darkened(0.2))
	_r(img, 35, 54, 9, 8, fur.darkened(0.2))
	_e(img, 30, 14, 11, 10, fur, true)
	_e(img, 22, 6, 3, 5, fur.darkened(0.1), true)
	_e(img, 38, 6, 3, 5, fur.darkened(0.1), true)
	if back:
		return
	_e(img, 32, 44, 11, 13, belly, true)
	_e(img, 32, 46, 6, 5, fur.lightened(0.15), true)
	_r(img, 30, 45, 2, 2, OUTLINE)
	_r(img, 34, 45, 2, 2, OUTLINE)
	_eye(img, 23, 11, Color("#2a2a30"))
	_eye(img, 33, 11, Color("#2a2a30"))
	_r(img, 27, 20, 6, 2, OUTLINE)
# --- Tour Pokémon (jalon 19) -----------------------------------------------------

## Fantominus : boule de gaz sombre, halo violet autour, grands yeux, bouche ouverte.
func _draw_gastly(img: Image, back: bool) -> void:
	var gas := Color("#9a7ac8")
	_e(img, 32, 34, 25, 23, Color(gas, 0.55))
	_e(img, 32, 34, 15, 14, Color("#2a2234"), true)
	if back:
		return
	_e(img, 25, 31, 4, 4, WHITE)
	_e(img, 39, 31, 4, 4, WHITE)
	_r(img, 26, 31, 2, 3, EYE)
	_r(img, 38, 31, 2, 3, EYE)
	_e(img, 32, 41, 6, 3, Color("#c04a6a"))
	_r(img, 28, 39, 2, 2, WHITE)
	_r(img, 35, 39, 2, 2, WHITE)


## Spectrum : corps violet sans jambes, crête pointue, deux mains qui flottent, large sourire.
func _draw_haunter(img: Image, back: bool) -> void:
	var skin := Color("#6a4a98")
	_poly(img, PackedVector2Array([Vector2(18, 20), Vector2(32, 4), Vector2(46, 20)]), skin)
	_e(img, 32, 30, 17, 16, skin, true)
	_poly(img, PackedVector2Array([Vector2(20, 40), Vector2(44, 40), Vector2(32, 60)]),
		skin.darkened(0.15))
	_e(img, 8, 36, 5, 5, skin.lightened(0.1), true)
	_e(img, 56, 36, 5, 5, skin.lightened(0.1), true)
	if back:
		return
	_r(img, 22, 24, 7, 4, WHITE)
	_r(img, 35, 24, 7, 4, WHITE)
	_r(img, 25, 25, 2, 3, EYE)
	_r(img, 38, 25, 2, 3, EYE)
	_r(img, 24, 34, 16, 3, Color("#c04a6a"))
	_r(img, 26, 34, 2, 2, WHITE)
	_r(img, 36, 34, 2, 2, WHITE)


## Noeunoeuf : six œufs roses serrés, fissures, petits visages.
func _draw_exeggcute(img: Image, back: bool) -> void:
	var shell := Color("#f0c0c0")
	var crack := Color("#c0807a")
	var eggs: Array[Vector2i] = [Vector2i(16, 50), Vector2i(32, 52), Vector2i(48, 50),
		Vector2i(22, 34), Vector2i(42, 34), Vector2i(32, 20)]
	for egg: Vector2i in eggs:
		_e(img, egg.x, egg.y, 9, 10, shell, true)
		_line(img, Vector2(egg.x - 5, egg.y - 3), Vector2(egg.x + 1, egg.y - 6), crack, 1)
		if back:
			continue
		_r(img, egg.x - 4, egg.y, 2, 2, EYE)
		_r(img, egg.x + 2, egg.y, 2, 2, EYE)
		_r(img, egg.x - 1, egg.y + 4, 3, 1, crack.darkened(0.3))


## Léviator : serpent de mer bleu dressé en S, ventre crème, crête et barbillons.
func _draw_gyarados(img: Image, back: bool) -> void:
	var skin := Color("#3a6ac8")
	var belly := Color("#f0e0a0")
	_e(img, 40, 56, 18, 6, skin.darkened(0.1), true)
	_line(img, Vector2(44, 54), Vector2(28, 40), skin, 9)
	_line(img, Vector2(28, 40), Vector2(36, 24), skin, 8)
	_e(img, 32, 16, 13, 10, skin, true)
	_poly(img, PackedVector2Array([Vector2(26, 8), Vector2(32, 0), Vector2(38, 8)]), WHITE)
	if back:
		_line(img, Vector2(40, 30), Vector2(48, 44), Color("#2a4a98"), 2)
		return
	_line(img, Vector2(42, 52), Vector2(30, 41), belly, 3)
	_line(img, Vector2(30, 40), Vector2(36, 27), belly, 3)
	_r(img, 24, 12, 5, 4, WHITE)
	_r(img, 35, 12, 5, 4, WHITE)
	_r(img, 26, 13, 2, 3, EYE)
	_r(img, 37, 13, 2, 3, EYE)
	_r(img, 25, 21, 14, 3, Color("#2a2a4a"))
	_line(img, Vector2(22, 20), Vector2(12, 26), WHITE, 1)
	_line(img, Vector2(42, 20), Vector2(52, 26), WHITE, 1)


# --- Alakazam, Lokhlass (jalon 26) ------------------------------------------------

## Kadabra en plus massif : même silhouette, deuxième cuillère à gauche, moustache blanche.
func _draw_alakazam(img: Image, back: bool) -> void:
	_draw_psychic_fox(img, back, true)
	_line(img, Vector2(12, 34), Vector2(6, 22), Color("#b8b8c4"), 2)
	_e(img, 6, 20, 3, 4, Color("#d0d0dc"), true)
	if not back:
		_line(img, Vector2(26, 23), Vector2(16, 29), WHITE, 2)
		_line(img, Vector2(38, 23), Vector2(48, 29), WHITE, 2)


## Long cou et petite tête de face, carapace brun clair sur le dos, nageoires, corps bleu.
func _draw_lapras(img: Image, back: bool) -> void:
	var skin := Color("#4a90d8")
	var belly := Color("#e8dca8")
	var shell := Color("#9a9aa8")
	_e(img, 32, 52, 24, 9, skin.darkened(0.08), true)
	_e(img, 32, 46, 19, 10, skin, true)
	_e(img, 44, 38, 8, 8, shell, true)
	_r(img, 41, 33, 2, 3, shell.lightened(0.3))
	_r(img, 46, 33, 2, 3, shell.lightened(0.3))
	_r(img, 51, 38, 2, 3, shell.lightened(0.3))
	_e(img, 20, 54, 7, 3, skin.darkened(0.15), true)
	_e(img, 46, 56, 7, 3, skin.darkened(0.15), true)
	_line(img, Vector2(26, 40), Vector2(22, 24), skin, 8)
	_e(img, 22, 16, 9, 8, skin, true)
	if back:
		_r(img, 18, 11, 8, 2, skin.darkened(0.25))
		return
	_e(img, 32, 52, 14, 5, belly)
	_e(img, 20, 20, 5, 3, belly)
	_eye(img, 24, 14, Color("#2a2a3a"))
	_r(img, 14, 10, 2, 3, skin.lightened(0.2))


## Osselait : petit corps brun, crâne blanc en casque (deux orbites noires), queue courte.
func _draw_cubone(img: Image, back: bool) -> void:
	_draw_bone_keeper(img, back, false)


## Ossatueur : même motif, plus grand, os tenu à droite.
func _draw_marowak(img: Image, back: bool) -> void:
	_draw_bone_keeper(img, back, true)


func _draw_bone_keeper(img: Image, back: bool, evolved: bool) -> void:
	var skin := Color("#a8784a")
	var bone := Color("#ece4cc")
	var body_y := 44 if not evolved else 40
	var head_y := 24 if not evolved else 18
	_line(img, Vector2(44, body_y + 8), Vector2(54, body_y - 2), skin.darkened(0.1), 3)
	_r(img, 22, 54, 8, 7, skin.darkened(0.12))
	_r(img, 34, 54, 8, 7, skin.darkened(0.12))
	_e(img, 32, body_y, 12 if not evolved else 14, 12 if not evolved else 14, skin, true)
	_e(img, 17, body_y - 2, 3, 6, skin, true)
	_e(img, 47, body_y - 2, 3, 6, skin, true)
	_e(img, 32, head_y, 12, 11, bone, true)
	if evolved:
		_line(img, Vector2(52, body_y + 4), Vector2(58, body_y - 18), bone, 3)
		_e(img, 58, body_y - 20, 3, 3, bone, true)
	if back:
		_r(img, 26, head_y + 6, 12, 2, bone.darkened(0.2))
		return
	_r(img, 24, head_y - 1, 5, 5, Color("#2a2a3a"))
	_r(img, 35, head_y - 1, 5, 5, Color("#2a2a3a"))
	_e(img, 32, head_y + 8, 6, 3, skin.lightened(0.1))


# --- Jalon 21 : Route 12, Ronflex ---------------------------------------------------

## Ptitard : corps rond bleu, spirale blanche sur le ventre, queue plate, petits pieds.
func _draw_poliwag(img: Image, back: bool) -> void:
	var skin := Color("#5a7ad8")
	_e(img, 52, 36, 9, 5, Color(skin.lightened(0.35), 0.8))
	_r(img, 22, 52, 7, 8, skin.darkened(0.15))
	_r(img, 35, 52, 7, 8, skin.darkened(0.15))
	_e(img, 32, 36, 19, 18, skin, true)
	if back:
		return
	_e(img, 32, 42, 9, 9, WHITE)
	_e(img, 32, 42, 5, 5, EYE)
	_e(img, 32, 42, 2, 2, WHITE)
	_eye(img, 24, 25, Color("#2a2a30"))
	_eye(img, 36, 25, Color("#2a2a30"))


## Tentacool : ombrelle bleue translucide, deux gemmes rouges, tentacules sous le corps.
func _draw_tentacool(img: Image, back: bool) -> void:
	var dome := Color("#7ab8e8")
	for x: int in [22, 28, 36, 42]:
		_line(img, Vector2(x, 38), Vector2(x + (x - 32) / 3, 60), Color("#c8c8d8"), 2)
	_e(img, 32, 24, 18, 16, Color(dome, 0.9), true)
	_e(img, 23, 31, 4, 4, Color("#d83a3a"), true)
	_e(img, 41, 31, 4, 4, Color("#d83a3a"), true)
	_r(img, 22, 36, 20, 4, Color("#c8c8d8"))
	if back:
		return
	_r(img, 26, 37, 3, 2, EYE)
	_r(img, 35, 37, 3, 2, EYE)


## Ronflex : grand corps bleu-vert assis, ventre crème, petites oreilles, yeux fermés.
func _draw_snorlax(img: Image, back: bool) -> void:
	var skin := Color("#2e6a78")
	var belly := Color("#efe2c0")
	_e(img, 32, 40, 26, 21, skin, true)
	_e(img, 32, 14, 15, 11, skin, true)
	_r(img, 18, 2, 4, 6, skin.darkened(0.1))
	_r(img, 42, 2, 4, 6, skin.darkened(0.1))
	_e(img, 12, 56, 7, 5, belly)
	_e(img, 52, 56, 7, 5, belly)
	if back:
		return
	_e(img, 32, 44, 18, 15, belly, true)
	_e(img, 32, 17, 10, 6, belly)
	_r(img, 25, 13, 5, 1, EYE)
	_r(img, 34, 13, 5, 1, EYE)
	_r(img, 28, 20, 8, 1, EYE)


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


# --- Kicklee, Tygnon (jalon 27) ---------------------------------------------------

## Corps brun sans cou, très longues jambes repliées, petits yeux ; bras fins.
func _draw_hitmonlee(img: Image, back: bool) -> void:
	var skin := Color("#b08a5a")
	_line(img, Vector2(26, 38), Vector2(16, 52), skin.darkened(0.1), 5)
	_line(img, Vector2(16, 52), Vector2(22, 61), skin.darkened(0.1), 5)
	_line(img, Vector2(38, 38), Vector2(48, 52), skin.darkened(0.1), 5)
	_line(img, Vector2(48, 52), Vector2(42, 61), skin.darkened(0.1), 5)
	_e(img, 32, 28, 12, 14, skin, true)
	_line(img, Vector2(21, 26), Vector2(12, 36), skin, 2)
	_line(img, Vector2(43, 26), Vector2(52, 36), skin, 2)
	if back:
		_r(img, 27, 30, 10, 2, skin.darkened(0.25))
		return
	_r(img, 25, 20, 14, 4, skin.darkened(0.35))
	_eye(img, 27, 21, Color("#f0e8d0"))
	_eye(img, 35, 21, Color("#f0e8d0"))


## Corps brun trapu, tunique violette, deux gros gants de boxe rouges.
func _draw_hitmonchan(img: Image, back: bool) -> void:
	var skin := Color("#b8946a")
	var tunic := Color("#8a5aa8")
	var glove := Color("#d83a3a")
	_r(img, 24, 50, 7, 12, skin.darkened(0.12))
	_r(img, 33, 50, 7, 12, skin.darkened(0.12))
	_e(img, 32, 40, 13, 13, tunic, true)
	_e(img, 32, 20, 11, 11, skin, true)
	_e(img, 13, 34, 7, 7, glove, true)
	_e(img, 51, 34, 7, 7, glove, true)
	if back:
		_r(img, 27, 36, 10, 2, tunic.darkened(0.3))
		return
	_eye(img, 27, 18, Color("#1c1c28"))
	_eye(img, 36, 18, Color("#1c1c28"))
	_r(img, 28, 25, 8, 2, skin.darkened(0.4))
