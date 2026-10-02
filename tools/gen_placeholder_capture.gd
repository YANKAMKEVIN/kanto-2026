extends SceneTree
## Génère les sprites provisoires de la capture (jalon 5D, T15), en pixel art natif, affichés
## en NEAREST par le BattleStage :
##   assets/sprites/pokemon/placeholder/poke_ball.png     Poké Ball 32 × 32 (pieds = bas de l'image)
##   assets/sprites/pokemon/placeholder/trainer_back.png  dresseur de dos, bras du lancer tendu
##                                                       vers la droite, 64 × 64
## Mêmes couleurs que le joueur provisoire (tools/gen_placeholder_player.gd) : casquette rouge,
## veste bleue, sac jaune. Remplaçables par les vrais sprites sans toucher au code.
##
##   godot --headless --path . -s res://tools/gen_placeholder_capture.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/pokemon/placeholder/"
const OUTLINE := Color("#1c1c28")
const RED := Color("#d8312b")
const WHITE := Color("#f4f4f4")
const SKIN := Color("#f2c9a0")
const HAIR := Color("#3a2a1e")
const CAP := Color("#d8312b")
const CAP_DARK := Color("#9e1f1a")
const JACKET := Color("#3b6fd1")
const JACKET_DARK := Color("#2a519e")
const PANTS := Color("#2d3a5a")
const BAG := Color("#f2c12e")

var _w: int = 0
var _h: int = 0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var ball := _new(32, 32)
	_draw_ball(ball)
	_outline(ball)
	ball.save_png(DIR + "poke_ball.png")
	var trainer := _new(64, 64)
	_draw_trainer(trainer)
	_outline(trainer)
	trainer.save_png(DIR + "trainer_back.png")
	print("Sprites provisoires de la capture OK")
	quit()


func _new(width: int, height: int) -> Image:
	_w = width
	_h = height
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < _w and y < _h:
		img.set_pixel(x, y, c)


func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_px(img, xx, yy, c)


func _line(img: Image, a: Vector2, b: Vector2, c: Color, width: int) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i: int in steps:
		var p := a.lerp(b, float(i) / maxf(steps - 1, 1))
		_r(img, int(round(p.x)) - width / 2, int(round(p.y)) - width / 2, width, width, c)


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


## Poké Ball : disque de 28 px, moitié haute rouge, moitié basse blanche, bande sombre, bouton.
## Lumière en haut à gauche (reflet), ombrage en bas à droite.
func _draw_ball(img: Image) -> void:
	var center := Vector2(16.0, 16.0)
	var radius := 14.0
	for y: int in 32:
		for x: int in 32:
			var d := Vector2(x + 0.5, y + 0.5) - center
			if d.length() > radius:
				continue
			var color := RED if d.y < -1.5 else WHITE
			if absf(d.y) <= 1.5:
				color = OUTLINE
			var shade := d.x * 0.6 + d.y * 0.8
			if shade > 6.0:
				color = color.darkened(0.2)
			_px(img, x, y, color)
	# Bouton central : anneau sombre, centre clair.
	for y: int in 32:
		for x: int in 32:
			var d := Vector2(x + 0.5, y + 0.5) - center
			if d.length() <= 4.5:
				_px(img, x, y, OUTLINE)
			if d.length() <= 3.0:
				_px(img, x, y, WHITE)
			if d.length() <= 1.5:
				_px(img, x, y, Color("#c9ced6"))
	# Reflet en haut à gauche.
	_r(img, 7, 7, 4, 2, Color("#f27a74"))
	_r(img, 6, 9, 2, 3, Color("#f27a74"))


## Dresseur de dos au moment du lancer : tête casquette, sac jaune, bras gauche le long du
## corps, bras droit tendu vers le haut à droite (vers le Pokémon sauvage).
func _draw_trainer(img: Image) -> void:
	# Jambes.
	_r(img, 17, 46, 8, 18, PANTS)
	_r(img, 27, 46, 8, 18, PANTS.darkened(0.15))
	# Buste et sac.
	_r(img, 13, 24, 26, 24, JACKET)
	_r(img, 13, 44, 26, 4, JACKET_DARK)
	_r(img, 17, 27, 18, 17, BAG)
	_r(img, 17, 27, 18, 3, BAG.darkened(0.3))
	_r(img, 17, 41, 18, 3, BAG.darkened(0.15))
	# Bras gauche le long du corps, main.
	_r(img, 8, 26, 5, 18, JACKET_DARK)
	_r(img, 8, 43, 5, 4, SKIN)
	# Bras droit tendu vers le haut à droite, main ouverte.
	_line(img, Vector2(38, 29), Vector2(54, 18), JACKET_DARK, 6)
	_line(img, Vector2(54, 18), Vector2(59, 14), SKIN, 5)
	_r(img, 58, 9, 4, 4, SKIN)
	# Tête de dos : cheveux, nuque, casquette.
	_r(img, 17, 5, 18, 20, HAIR)
	_r(img, 17, 22, 18, 3, HAIR.darkened(0.3))
	_r(img, 15, 1, 22, 9, CAP)
	_r(img, 17, 0, 18, 2, CAP)
	_r(img, 15, 8, 22, 3, CAP_DARK)
	_r(img, 23, 2, 6, 3, WHITE)
