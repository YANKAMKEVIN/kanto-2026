extends SceneTree
## Génère les sprites provisoires des PNJ et des Pokémon du décor (jalon-03.md §2.3, T4).
## Pixel art aux dimensions finales, affiché ×2 en NEAREST par la scène `Npc` :
##   - personnes 32 × 64 natif (Léo, enfant : 32 × 48) ;
##   - Pokémon 32 × 32 natif.
## Pour chaque apparence <id> :
##   assets/sprites/characters/placeholder/<id>_sheet.png   (colonnes × 4 rangées)
##     colonnes : 0 repos, 1 attente (respiration, picorage, flamme), 2.. réaction
##     rangées  : 0 bas, 1 haut, 2 gauche, 3 droite
##   assets/sprites/characters/placeholder/<id>_frames.tres (SpriteFrames)
##     idle_<dir> (bouclée, lente) et, pour les starters et le Rattata, react_<dir>
##     (non bouclée ; la scène Npc revient à l'attente à la fin).
## `npc` reste le sprite générique (apparence inconnue).
## Repères de direction : yeux (face), cheveux / dos / carapace / bulbe (dos), œil et
## museau (profil). Contour sombre de 1 px (lisibilité sur l'herbe et le parquet).
##
##   godot --headless --path . -s res://tools/gen_placeholder_npcs.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/characters/placeholder/"
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
const OUTLINE := Color("#1c1c28")
const EYE := Color("#1c1c28")
const WHITE := Color("#f4f4f4")
const MOUTH := Color("#b86b5a")

## Apparences : id → [largeur, hauteur, images de réaction, i/s attente, i/s réaction].
const SPRITES: Dictionary = {
	"npc": [32, 64, 0, 1.5, 0.0],
	"mom": [32, 64, 0, 1.5, 0.0],
	"rival": [32, 64, 0, 1.5, 0.0],
	"maya": [32, 64, 0, 1.5, 0.0],
	"aoki": [32, 64, 0, 1.5, 0.0],
	"leo": [32, 48, 0, 2.0, 0.0],
	"haru": [32, 64, 0, 1.2, 0.0],
	"bulbasaur": [32, 32, 4, 1.5, 6.0],
	"charmander": [32, 32, 4, 4.0, 10.0],
	"squirtle": [32, 32, 4, 1.5, 6.0],
	"rattata": [32, 32, 4, 2.0, 10.0],
	"pidgey": [32, 32, 0, 1.6, 0.0],
}

## Personnes : palette et accessoires (voir _draw_person).
const PEOPLE: Dictionary = {
	"npc": {"skin": "#e9c3a0", "hair": "#6b4a2e", "hair_style": "short",
		"top": "#7d8f6a", "bottom": "#4a4640", "shoe": "#2e2a26"},
	# Maman : robe rose, tablier clair, cheveux longs attachés.
	"mom": {"skin": "#f0c8a0", "hair": "#7a4a2a", "hair_style": "long",
		"top": "#d66b7c", "bottom": "#d66b7c", "shoe": "#7a4a3a", "skirt": true,
		"apron": "#f6f1e6"},
	# Rival : cheveux en pointes, veste sombre, pantalon violet (référence maison-rival).
	"rival": {"skin": "#f2c9a0", "hair": "#c77a3a", "hair_style": "spiky",
		"top": "#3b3f4a", "inner": "#9aa0aa", "bottom": "#6a4a9a", "shoe": "#2e2a26"},
	# Maya : blouse blanche de chercheuse, chignon sombre, lunettes.
	"maya": {"skin": "#e9c3a0", "hair": "#2b2230", "hair_style": "bun",
		"top": "#f4f6f8", "inner": "#5a8fc0", "bottom": "#3a4a6a", "shoe": "#2e2a26",
		"coat": true, "glasses": true},
	# Mme Aoki : cheveux gris en chignon, châle violet, jupe longue.
	"aoki": {"skin": "#efcfb0", "hair": "#b9bcc2", "hair_style": "bun",
		"top": "#6a7f5a", "bottom": "#55664a", "shoe": "#4a3a30", "skirt": true,
		"shawl": "#8a5aa0"},
	# Léo : enfant (32 × 48), t-shirt jaune à rayure, short bleu.
	"leo": {"skin": "#f2c9a0", "hair": "#3a2a1e", "hair_style": "short",
		"top": "#e0a93b", "inner": "#c0392b", "bottom": "#3b6fd1", "shoe": "#f4f4f4"},
	# Haru : chapeau de paille, gilet, canne à pêche.
	"haru": {"skin": "#d9a878", "hair": "#4a3a2a", "hair_style": "short",
		"top": "#2f6f8f", "inner": "#e8e2d4", "bottom": "#5a4a3a", "shoe": "#2e2a26",
		"hat": "#e2c26a", "rod": true},
}

var _w: int = 32
var _h: int = 64


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for sprite_name: String in SPRITES:
		var spec: Array = SPRITES[sprite_name]
		_w = spec[0]
		_h = spec[1]
		var columns: int = 2 + int(spec[2])
		var sheet := Image.create_empty(_w * columns, _h * 4, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))
		for row: int in 4:
			for col: int in columns:
				var frame := _frame(sprite_name, DIRECTIONS[row], col)
				_outline(frame)
				sheet.blit_rect(frame, Rect2i(0, 0, _w, _h), Vector2i(col * _w, row * _h))
		sheet.save_png(DIR + sprite_name + "_sheet.png")
		_write_frames(sprite_name, spec)
	print("PNJ et Pokémon provisoires OK (%d apparences)" % SPRITES.size())
	quit()


func _frame(sprite_name: String, direction: String, col: int) -> Image:
	var img := Image.create_empty(_w, _h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# col 0 : repos ; col 1 : attente ; col ≥ 2 : réaction (étape col − 2).
	var idle := col == 1
	var react := col - 2
	if PEOPLE.has(sprite_name):
		_draw_person(img, PEOPLE[sprite_name], direction, 1 if idle else 0)
	else:
		call("_draw_" + sprite_name, img, direction, idle, react)
	return img


# --- Primitives -------------------------------------------------------------------

func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < _w and yy < _h:
				img.set_pixel(xx, yy, c)


func _e(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var d := Vector2((xx + 0.5 - cx) / rx, (yy + 0.5 - cy) / ry)
			if d.length_squared() <= 1.0 and xx >= 0 and yy >= 0 and xx < _w and yy < _h:
				img.set_pixel(xx, yy, c)


func _line(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i: int in steps:
		var p := a.lerp(b, float(i) / maxf(steps - 1, 1))
		var x := int(round(p.x))
		var y := int(round(p.y))
		if x >= 0 and y >= 0 and x < _w and y < _h:
			img.set_pixel(x, y, c)


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


# --- Personnes (32 × 64, enfant 32 × 48) -------------------------------------------

## Personnage debout. [param bob] : 1 = respiration (buste et tête 1 px plus bas).
func _draw_person(img: Image, p: Dictionary, direction: String, bob: int) -> void:
	var kid := _h < 64
	var skin := Color(p["skin"])
	var hair := Color(p["hair"])
	var top := Color(p["top"])
	var bottom := Color(p["bottom"])
	var shoe := Color(p["shoe"])
	var side := direction == "left" or direction == "right"
	var sd := -1 if direction == "left" else 1
	# Repères verticaux : tête, buste, jambes, pieds.
	var head_y := (6 if kid else 12) + bob
	var head_h := 16 if kid else 20
	var body_y := (22 if kid else 32) + bob
	var body_h := (14 if kid else 19) - bob
	var leg_y := 36 if kid else 50
	var leg_h := _h - 4 - leg_y
	var foot_y := _h - 5
	# Jambes (ou jupe longue) et chaussures.
	if p.get("skirt", false):
		_r(img, 8 if not side else 9, leg_y - 2, 16 if not side else 14, leg_h + 1, bottom)
		_r(img, 8 if not side else 9, leg_y + leg_h - 2, 16 if not side else 14, 2,
			bottom.darkened(0.2))
	elif side:
		_r(img, 13, leg_y, 6, leg_h, bottom)
	else:
		_r(img, 11, leg_y, 4, leg_h, bottom)
		_r(img, 17, leg_y, 4, leg_h, bottom)
	if side:
		_r(img, 12 + sd, foot_y, 8, 4, shoe)
	else:
		_r(img, 10, foot_y, 6, 4, shoe)
		_r(img, 16, foot_y, 6, 4, shoe)
	# Buste.
	var bx := 10 if side else 8
	var bw := 12 if side else 16
	_r(img, bx, body_y, bw, body_h, top)
	_r(img, bx, body_y + body_h - 3, bw, 3, top.darkened(0.25))
	if p.has("inner") and direction == "down":
		var inner := Color(p["inner"])
		if p.get("coat", false):
			_r(img, 14, body_y + 1, 4, body_h - 4, inner)
		elif kid:
			_r(img, bx, body_y + 5, bw, 2, inner)
		else:
			_r(img, 14, body_y + 1, 4, body_h - 5, inner)
	if p.get("coat", false):
		# Blouse longue : pans qui descendent sur les jambes.
		if side:
			_r(img, bx, leg_y, bw, 7, top)
		else:
			_r(img, 8, leg_y, 5, 7, top)
			_r(img, 19, leg_y, 5, 7, top)
		_r(img, bx, body_y, bw, 1, top.darkened(0.15))
	if p.has("apron") and direction != "up":
		var apron := Color(p["apron"])
		if side:
			_r(img, 16 + (2 if sd > 0 else -6), body_y + 4, 6, body_h + 7, apron)
		else:
			_r(img, 10, body_y + 4, 12, body_h + 7, apron)
			_r(img, 13, body_y + 11, 6, 4, apron.darkened(0.12))
	if p.has("apron") and direction == "up":
		_r(img, 15, body_y + 3, 2, 5, Color(p["apron"]))
	if p.has("shawl"):
		var shawl := Color(p["shawl"])
		_r(img, bx - 1, body_y, bw + 2, 7, shawl)
		if not side:
			_r(img, 14, body_y + 6, 4, 4, shawl.darkened(0.2))
	# Bras.
	var arm := top.darkened(0.2)
	if side:
		_r(img, 14, body_y + 3, 4, body_h - 6, arm)
		_r(img, 14, body_y + body_h - 3, 4, 2, skin)
	else:
		_r(img, 6, body_y + 2, 2, body_h - 5, arm)
		_r(img, 24, body_y + 2, 2, body_h - 5, arm)
		_r(img, 6, body_y + body_h - 3, 2, 3, skin)
		_r(img, 24, body_y + body_h - 3, 2, 3, skin)
	# Tête.
	var hx := 8
	var hw := 16
	_r(img, hx, head_y, hw, head_h, skin)
	_draw_hair(img, p, direction, hx, head_y, hw, head_h, hair)
	# Visage.
	var eye_y := head_y + (8 if kid else 9)
	match direction:
		"down":
			_r(img, 12, eye_y, 2, 3 if kid else 4, EYE)
			_r(img, 18, eye_y, 2, 3 if kid else 4, EYE)
			_r(img, 14, eye_y + (5 if kid else 6), 4, 1, MOUTH)
			if p.get("glasses", false):
				_r(img, 11, eye_y - 1, 4, 1, EYE)
				_r(img, 17, eye_y - 1, 4, 1, EYE)
				_r(img, 15, eye_y, 2, 1, EYE)
		"left":
			_r(img, 10, eye_y, 2, 3 if kid else 4, EYE)
			_r(img, 6, eye_y + 3, 3, 3, skin.darkened(0.1))
			if p.get("glasses", false):
				_r(img, 9, eye_y - 1, 5, 1, EYE)
		"right":
			_r(img, 20, eye_y, 2, 3 if kid else 4, EYE)
			_r(img, 23, eye_y + 3, 3, 3, skin.darkened(0.1))
			if p.get("glasses", false):
				_r(img, 18, eye_y - 1, 5, 1, EYE)
	# Chapeau à large bord.
	if p.has("hat"):
		var hat := Color(p["hat"])
		_r(img, 3, head_y - 1, 26, 3, hat)
		_r(img, 8, head_y - 6, 16, 6, hat)
		_r(img, 8, head_y - 2, 16, 1, hat.darkened(0.35))
	# Canne à pêche tenue dans la main (repère : vers l'avant).
	if p.get("rod", false):
		var rod := Color("#6b4a2a")
		match direction:
			"down":
				_line(img, Vector2(25, body_y + body_h - 3), Vector2(31, head_y - 4), rod)
			"up":
				_line(img, Vector2(6, body_y + body_h - 3), Vector2(1, head_y - 6), rod)
			"left":
				_line(img, Vector2(14, body_y + body_h - 3), Vector2(0, body_y - 8), rod)
			"right":
				_line(img, Vector2(17, body_y + body_h - 3), Vector2(31, body_y - 8), rod)


func _draw_hair(img: Image, p: Dictionary, direction: String, hx: int, hy: int, hw: int,
		hh: int, hair: Color) -> void:
	var style: String = p["hair_style"]
	match direction:
		"down":
			_r(img, hx - 1, hy - 2, hw + 2, 6, hair)
			_r(img, hx - 1, hy, 2, 8, hair)
			_r(img, hx + hw - 1, hy, 2, 8, hair)
		"up":
			_r(img, hx - 1, hy - 2, hw + 2, hh + 2, hair)
			_r(img, hx - 1, hy + hh - 3, hw + 2, 3, hair.darkened(0.3))
		"left":
			_r(img, hx + 6, hy - 2, hw - 5, hh - 2, hair)
			_r(img, hx - 1, hy - 2, hw + 2, 6, hair)
		"right":
			_r(img, hx - 1, hy - 2, hw - 5, hh - 2, hair)
			_r(img, hx - 1, hy - 2, hw + 2, 6, hair)
	match style:
		"long":
			# Cheveux aux épaules, queue de cheval visible de dos et de profil.
			if direction == "down":
				_r(img, hx - 2, hy + 2, 3, hh - 2, hair)
				_r(img, hx + hw - 1, hy + 2, 3, hh - 2, hair)
			elif direction == "up":
				_r(img, hx + 5, hy + hh - 2, 6, 10, hair.darkened(0.1))
			else:
				var back := hx + hw - 2 if direction == "left" else hx - 3
				_r(img, back, hy + 4, 5, 14, hair.darkened(0.1))
		"spiky":
			# Mèches en pointes au-dessus de la tête.
			for k: int in 4:
				var x := hx - 1 + k * 5
				_r(img, x, hy - 5, 3, 3, hair)
				_r(img, x + 1, hy - 7, 2, 2, hair)
			_r(img, hx - 3, hy - 1, 3, 4, hair)
			_r(img, hx + hw, hy - 1, 3, 4, hair)
		"bun":
			# Chignon sur le haut du crâne.
			_r(img, hx + 5, hy - 7, 6, 5, hair)
			_r(img, hx + 6, hy - 8, 4, 1, hair.lightened(0.15))


# --- Pokémon (32 × 32) ------------------------------------------------------------

## Bulbizarre : corps bleu-vert tacheté, bulbe vert sur le dos, yeux rouges.
## Réaction : petit mouvement de tête (hochement).
func _draw_bulbasaur(img: Image, direction: String, idle: bool, react: int) -> void:
	var body := Color("#6cc0a0")
	var spot := Color("#3f8a70")
	var bulb := Color("#4f9a4a")
	var bob := 1 if idle else 0
	var nod: int = [0, 2, 0, 2][react] if react >= 0 else 0
	var hy := 16.0 + bob + nod
	match direction:
		"down":
			_e(img, 16, 12 + bob, 7, 6, bulb)
			_e(img, 16, 11 + bob, 3, 3, bulb.lightened(0.2))
			_e(img, 16, 25, 11, 5, body)
			_r(img, 6, 26, 4, 4, body.darkened(0.15))
			_r(img, 22, 26, 4, 4, body.darkened(0.15))
			_e(img, 16, hy + 3, 9, 7, body)
			_r(img, 10, int(hy) - 2, 2, 3, body)
			_r(img, 20, int(hy) - 2, 2, 3, body)
			_r(img, 11, int(hy) + 2, 3, 3, Color("#c0392b"))
			_r(img, 18, int(hy) + 2, 3, 3, Color("#c0392b"))
			_r(img, 11, int(hy) + 2, 1, 1, WHITE)
			_r(img, 18, int(hy) + 2, 1, 1, WHITE)
			_r(img, 14, int(hy) + 7, 4, 1, spot)
		"up":
			_e(img, 16, 25, 11, 5, body)
			_e(img, 16, hy + 1, 8, 6, body)
			_r(img, 10, int(hy) - 4, 2, 3, body)
			_r(img, 20, int(hy) - 4, 2, 3, body)
			_e(img, 16, 19 + bob, 9, 8, bulb)
			_e(img, 14, 16 + bob, 3, 3, bulb.lightened(0.25))
			_r(img, 7, 22, 3, 3, spot)
			_r(img, 22, 22, 3, 3, spot)
		_:
			var s := -1 if direction == "left" else 1
			var cx := 16
			_e(img, cx - 4 * s, 13 + bob, 7, 6, bulb)
			_e(img, cx - 5 * s, 11 + bob, 2, 2, bulb.lightened(0.25))
			_e(img, cx - 2 * s, 24, 10, 5, body)
			_r(img, cx - 9 * s - 2, 26, 4, 4, body.darkened(0.15))
			_r(img, cx + 3 * s - 2, 26, 4, 4, body.darkened(0.15))
			_r(img, cx - 4 * s - 2, 21, 4, 3, spot)
			_e(img, cx + 6 * s, hy + 3, 7, 6, body)
			_r(img, cx + 4 * s - 1, int(hy) - 3, 2, 3, body)
			_r(img, cx + 8 * s - 1, int(hy) + 2, 3, 3, Color("#c0392b"))
			_r(img, cx + 12 * s - 1, int(hy) + 6, 2, 1, spot)


## Salamèche : orange, ventre crème, queue à flamme. La flamme vacille en attente ;
## réaction : la flamme grandit et s'agite, petit sursaut.
func _draw_charmander(img: Image, direction: String, idle: bool, react: int) -> void:
	var skin := Color("#f08a3a")
	var belly := Color("#f8d890")
	var hop: int = [0, 2, 1, 0][react] if react >= 0 else 0
	var flame_size := 3.0
	if idle:
		flame_size = 2.2
	if react >= 0:
		flame_size = [4.5, 5.5, 4.8, 5.2][react]
	var flicker := 1 if (idle or react == 1 or react == 3) else 0
	var by := 22 - hop
	var hy := 11 - hop
	match direction:
		"down":
			_line(img, Vector2(21, by + 5), Vector2(26, by - 1), skin.darkened(0.1))
			_r(img, 21, by + 3, 4, 2, skin.darkened(0.1))
			_flame(img, Vector2(26 + flicker, by - 4), flame_size)
			_e(img, 16, by, 7, 8, skin)
			_e(img, 16, by + 1, 4, 6, belly)
			_r(img, 10, by + 6, 4, 4, skin.darkened(0.15))
			_r(img, 18, by + 6, 4, 4, skin.darkened(0.15))
			_r(img, 8, by - 3, 3, 4, skin)
			_r(img, 21, by - 3, 3, 4, skin)
			_e(img, 16, hy, 8, 7, skin)
			_r(img, 12, hy - 1, 2, 4, EYE)
			_r(img, 18, hy - 1, 2, 4, EYE)
			_r(img, 12, hy - 1, 1, 1, WHITE)
			_r(img, 18, hy - 1, 1, 1, WHITE)
			_r(img, 14, hy + 4, 4, 1, skin.darkened(0.35))
		"up":
			_e(img, 16, by, 7, 8, skin)
			_e(img, 16, hy, 8, 7, skin)
			_line(img, Vector2(16, by + 6), Vector2(16, by + 1), skin.darkened(0.15))
			_flame(img, Vector2(16 + flicker, by - 1), flame_size)
			_r(img, 8, by - 3, 3, 4, skin)
			_r(img, 21, by - 3, 3, 4, skin)
		_:
			var s := -1 if direction == "left" else 1
			_line(img, Vector2(16 - 3 * s, by + 5), Vector2(16 - 10 * s, by), skin.darkened(0.1))
			_flame(img, Vector2(16 - 11 * s + flicker * -s, by - 4), flame_size)
			_e(img, 16 - s, by, 6, 8, skin)
			_e(img, 16 + 2 * s, by + 1, 3, 6, belly)
			_r(img, 16 - 3, by + 6, 5, 4, skin.darkened(0.15))
			_r(img, 16 + 3 * s - 1, by - 3, 3, 4, skin)
			_e(img, 16 + 3 * s, hy, 8, 7, skin)
			_r(img, 16 + 6 * s - 1, hy - 1, 2, 4, EYE)
			_r(img, 16 + 6 * s - 1, hy - 1, 1, 1, WHITE)
			_r(img, 16 + 9 * s - 1, hy + 3, 2, 1, skin.darkened(0.35))


func _flame(img: Image, center: Vector2, size: float) -> void:
	_e(img, center.x, center.y, size * 0.8, size * 1.2, Color("#e84020"))
	_e(img, center.x, center.y + size * 0.25, size * 0.5, size * 0.8, Color("#f8c030"))
	_e(img, center.x, center.y + size * 0.4, size * 0.2, size * 0.35, Color("#fff4c0"))


## Carapuce : bleu clair, carapace brune à bord crème, queue enroulée.
## Réaction : tête qui s'incline d'un côté puis de l'autre (curiosité).
func _draw_squirtle(img: Image, direction: String, idle: bool, react: int) -> void:
	var skin := Color("#7ec8e8")
	var shell := Color("#b0703a")
	var rim := Color("#f0e0a0")
	var bob := 1 if idle else 0
	var tilt: int = [0, -2, 0, 2][react] if react >= 0 else 0
	var hy := 11 + bob
	match direction:
		"down":
			_e(img, 23, 26, 3, 3, skin)
			_e(img, 16, 22, 8, 8, shell)
			_e(img, 16, 22, 6, 7, rim)
			_r(img, 12, 19, 8, 1, shell.darkened(0.2))
			_r(img, 12, 23, 8, 1, shell.darkened(0.2))
			_r(img, 9, 27, 4, 4, skin)
			_r(img, 19, 27, 4, 4, skin)
			_r(img, 7, 19, 3, 5, skin)
			_r(img, 22, 19, 3, 5, skin)
			_e(img, 16 + tilt, hy, 8, 7, skin)
			_r(img, 12 + tilt, hy - 1, 2, 4, Color("#7a3a20"))
			_r(img, 18 + tilt, hy - 1, 2, 4, Color("#7a3a20"))
			_r(img, 12 + tilt, hy - 1, 1, 1, WHITE)
			_r(img, 18 + tilt, hy - 1, 1, 1, WHITE)
			_r(img, 14 + tilt, hy + 4, 4, 1, skin.darkened(0.35))
		"up":
			_e(img, 16 + tilt, hy, 8, 7, skin)
			_e(img, 16, 22, 9, 9, shell)
			_e(img, 16, 22, 6, 6, shell.lightened(0.15))
			_r(img, 13, 20, 6, 1, shell.darkened(0.3))
			_r(img, 13, 24, 6, 1, shell.darkened(0.3))
			_e(img, 16, 30, 3, 2, skin)
		_:
			var s := -1 if direction == "left" else 1
			_e(img, 16 - 9 * s, 25, 3, 3, skin)
			_e(img, 16 - 9 * s, 25, 1, 1, skin.darkened(0.3))
			_e(img, 16 - 2 * s, 22, 7, 8, shell)
			_e(img, 16 + 3 * s, 22, 3, 7, rim)
			_r(img, 16 - 3, 27, 6, 4, skin)
			_e(img, 16 + 4 * s + tilt * s, hy, 8, 7, skin)
			_r(img, 16 + 7 * s - 1, hy - 1, 2, 4, Color("#7a3a20"))
			_r(img, 16 + 7 * s - 1, hy - 1, 1, 1, WHITE)


## Rattata : violet, ventre crème, grandes oreilles, longue queue. Réaction : petit bond.
func _draw_rattata(img: Image, direction: String, idle: bool, react: int) -> void:
	var fur := Color("#9a6ab8")
	var belly := Color("#f0e0c0")
	var bob := 1 if idle else 0
	var hop: int = [3, 6, 3, 0][react] if react >= 0 else 0
	var by := 25 - hop
	match direction:
		"down":
			_line(img, Vector2(22, by + 2), Vector2(29, by - 5), fur.darkened(0.2))
			_e(img, 16, by, 9, 6, fur)
			_e(img, 16, by + 1, 5, 4, belly)
			_r(img, 9, by + 4, 4, 3, fur.darkened(0.15))
			_r(img, 19, by + 4, 4, 3, fur.darkened(0.15))
			var hy := by - 8 + bob
			_e(img, 9, hy - 5, 4, 4, fur)
			_e(img, 23, hy - 5, 4, 4, fur)
			_e(img, 9, hy - 5, 2, 2, Color("#e0a0b0"))
			_e(img, 23, hy - 5, 2, 2, Color("#e0a0b0"))
			_e(img, 16, hy, 8, 6, fur)
			_e(img, 16, hy + 3, 4, 3, belly)
			_r(img, 11, hy - 2, 3, 3, Color("#c0392b"))
			_r(img, 18, hy - 2, 3, 3, Color("#c0392b"))
			_r(img, 15, hy + 4, 2, 2, WHITE)
		"up":
			var hy := by - 8 + bob
			_e(img, 16, by, 9, 6, fur)
			_line(img, Vector2(16, by + 4), Vector2(16, 31), fur.darkened(0.2))
			_e(img, 9, hy - 5, 4, 4, fur)
			_e(img, 23, hy - 5, 4, 4, fur)
			_e(img, 16, hy, 8, 6, fur)
		_:
			var s := -1 if direction == "left" else 1
			_line(img, Vector2(16 - 8 * s, by), Vector2(16 - 15 * s, by - 7), fur.darkened(0.2))
			_e(img, 16 - 2 * s, by, 9, 5, fur)
			_e(img, 16, by + 2, 5, 3, belly)
			_r(img, 16 - 8 * s - 2, by + 3, 4, 3, fur.darkened(0.15))
			_r(img, 16 + 3 * s - 2, by + 3, 4, 3, fur.darkened(0.15))
			var hy := by - 6 + bob
			_e(img, 16 + 4 * s, hy - 6, 3, 4, fur)
			_e(img, 16 + 4 * s, hy - 6, 1, 2, Color("#e0a0b0"))
			_e(img, 16 + 7 * s, hy, 7, 5, fur)
			_e(img, 16 + 12 * s, hy + 2, 2, 2, belly)
			_r(img, 16 + 9 * s - 1, hy - 2, 3, 3, Color("#c0392b"))
			_r(img, 16 + 13 * s - 1, hy + 3, 2, 2, WHITE)


## Roucool : oiseau brun, face et ventre crème, petite crête. Attente : il picore.
func _draw_pidgey(img: Image, direction: String, idle: bool, _react: int) -> void:
	var feather := Color("#b08050")
	var cream := Color("#f0dca8")
	var beak := Color("#4a4a4a")
	var peck := 4 if idle else 0
	match direction:
		"down":
			_e(img, 16, 24, 8, 6, feather)
			_e(img, 16, 25, 5, 4, cream)
			_r(img, 13, 29, 2, 3, Color("#e0a060"))
			_r(img, 17, 29, 2, 3, Color("#e0a060"))
			var hy := 15 + peck
			_e(img, 16, hy, 6, 5, feather)
			_e(img, 16, hy + 1, 4, 3, cream)
			_r(img, 15, hy - 7, 2, 3, feather.darkened(0.2))
			_r(img, 13, hy - 1, 2, 2, EYE)
			_r(img, 17, hy - 1, 2, 2, EYE)
			_r(img, 15, hy + 2, 2, 2, beak)
		"up":
			var hy := 15 + peck
			_e(img, 16, 24, 8, 6, feather)
			_e(img, 16, 30, 4, 2, feather.darkened(0.25))
			_e(img, 16, hy, 6, 5, feather)
			_r(img, 15, hy - 7, 2, 3, feather.darkened(0.2))
			_r(img, 11, 21, 10, 2, feather.darkened(0.2))
		_:
			var s := -1 if direction == "left" else 1
			_e(img, 16 - 8 * s, 25, 4, 2, feather.darkened(0.25))
			_e(img, 16 - s, 24, 8, 6, feather)
			_e(img, 16 + 3 * s, 25, 4, 4, cream)
			_r(img, 15, 29, 2, 3, Color("#e0a060"))
			var hy := 15 + peck
			var hx := 16 + 5 * s + (3 * s if idle else 0)
			_e(img, hx, hy, 5, 5, feather)
			_e(img, hx + 2 * s, hy + 1, 3, 3, cream)
			_r(img, hx - 3 * s - 1, hy - 7, 2, 3, feather.darkened(0.2))
			_r(img, hx + 2 * s - 1, hy - 1, 2, 2, EYE)
			_r(img, hx + 5 * s - (1 if s < 0 else 0), hy + 1, 2, 2, beak)


# --- Écriture des SpriteFrames -----------------------------------------------------

func _write_frames(sprite_name: String, spec: Array) -> void:
	var fw: int = spec[0]
	var fh: int = spec[1]
	var react_count: int = spec[2]
	var columns := 2 + react_count
	var text := "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
	text += "[ext_resource type=\"Texture2D\" path=\"%s%s_sheet.png\" id=\"1_sheet\"]\n\n" % [
		DIR, sprite_name]
	for row: int in 4:
		for col: int in columns:
			text += "[sub_resource type=\"AtlasTexture\" id=\"f_%d_%d\"]\n" % [row, col]
			text += "atlas = ExtResource(\"1_sheet\")\n"
			text += "region = Rect2(%d, %d, %d, %d)\n\n" % [col * fw, row * fh, fw, fh]
	var anims: PackedStringArray = []
	for row: int in 4:
		anims.append(_anim("idle_" + DIRECTIONS[row], [0, 1], row, spec[3], true))
		if react_count > 0:
			var cols: Array = []
			for k: int in react_count:
				cols.append(2 + k)
			cols.append(0)
			anims.append(_anim("react_" + DIRECTIONS[row], cols, row, spec[4], false))
	text += "[resource]\nanimations = [%s]\n" % ", ".join(anims)
	var f := FileAccess.open(DIR + sprite_name + "_frames.tres", FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _anim(anim_name: String, cols: Array, row: int, fps: float, loop: bool) -> String:
	var frames: PackedStringArray = []
	for col: int in cols:
		frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"f_%d_%d\")\n}" % [row, col])
	return "{\n\"frames\": [%s],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [
		", ".join(frames), "true" if loop else "false", anim_name, fps
	]
