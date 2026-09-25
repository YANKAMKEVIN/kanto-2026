extends SceneTree
## Génère le sprite provisoire du joueur (pixel art 32×64 natif, affiché ×2) :
##   assets/sprites/characters/placeholder/player_sheet.png  (3 colonnes × 4 rangées)
##     colonnes : 0 immobile, 1 pas gauche, 2 pas droit
##     rangées  : 0 bas, 1 haut, 2 gauche, 3 droite
##   assets/sprites/characters/placeholder/player_frames.tres (SpriteFrames, écrit en texte)
##   assets/sprites/characters/placeholder/shadow.png        (ombre au sol)
## Repère de direction : visière de casquette et yeux (face/profil), sac jaune (dos).
##
##   godot --headless --path . -s res://tools/gen_placeholder_player.gd
##   godot --headless --path . --import

const DIR: String = "res://assets/sprites/characters/placeholder/"
const FW: int = 32
const FH: int = 64
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
## Cadence des animations (images/s) : 4 images = 2 pas.
const WALK_FPS: float = 9.0
const RUN_FPS: float = 16.0

const SKIN := Color("#f2c9a0")
const HAIR := Color("#3a2a1e")
const CAP := Color("#d8312b")
const CAP_DARK := Color("#9e1f1a")
const JACKET := Color("#3b6fd1")
const JACKET_DARK := Color("#2a519e")
const PANTS := Color("#2d3a5a")
const SHOE := Color("#e8e8e8")
const BAG := Color("#f2c12e")
const EYE := Color("#1c1c28")
const OUTLINE := Color("#1c1c28")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var sheet := Image.create_empty(FW * 3, FH * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row: int in 4:
		for col: int in 3:
			var frame := _draw_frame(DIRECTIONS[row], col)
			_outline(frame)
			sheet.blit_rect(frame, Rect2i(0, 0, FW, FH), Vector2i(col * FW, row * FH))
	sheet.save_png(DIR + "player_sheet.png")
	var shadow := Image.create_empty(48, 16, false, Image.FORMAT_RGBA8)
	for y: int in 16:
		for x: int in 48:
			var d := Vector2((x + 0.5 - 24.0) / 24.0, (y + 0.5 - 8.0) / 8.0).length()
			shadow.set_pixel(x, y, Color(0.05, 0.08, 0.04, 0.35 * clampf(1.0 - d, 0.0, 1.0) * 2.0))
	shadow.save_png(DIR + "shadow.png")
	_write_frames()
	print("joueur provisoire OK")
	quit()


func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < FW and yy < FH:
				img.set_pixel(xx, yy, c)


func _draw_frame(direction: String, col: int) -> Image:
	var img := Image.create_empty(FW, FH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bob := 1 if col != 0 else 0
	var lift_left := 2 if col == 1 else 0
	var lift_right := 2 if col == 2 else 0
	var side := direction == "left" or direction == "right"
	# Jambes et chaussures.
	if side:
		var front := 1 if col == 1 else (-1 if col == 2 else 0)
		_r(img, 13 - front * 2, 50, 6, 10, PANTS)
		_r(img, 13 + front * 2, 50, 6, 10, PANTS.darkened(0.2))
		_r(img, 12 - front * 2, 59, 8, 4, SHOE)
		_r(img, 12 + front * 2, 59, 8, 4, SHOE.darkened(0.15))
	else:
		_r(img, 11, 50 - bob, 4, 10 - lift_left, PANTS)
		_r(img, 17, 50 - bob, 4, 10 - lift_right, PANTS)
		_r(img, 10, 59 - lift_left, 6, 4, SHOE)
		_r(img, 16, 59 - lift_right, 6, 4, SHOE)
	# Buste.
	var body_x := 10 if side else 8
	var body_w := 12 if side else 16
	_r(img, body_x, 34 - bob, body_w, 17, JACKET)
	_r(img, body_x, 48 - bob, body_w, 3, JACKET_DARK)
	match direction:
		"down":
			_r(img, 15, 35 - bob, 2, 13, Color("#f4f4f4"))
			_r(img, 6, 36 - bob, 2, 12, JACKET_DARK)
			_r(img, 24, 36 - bob, 2, 12, JACKET_DARK)
			_r(img, 6, 48 - bob, 2, 3, SKIN)
			_r(img, 24, 48 - bob, 2, 3, SKIN)
		"up":
			_r(img, 10, 36 - bob, 12, 12, BAG)
			_r(img, 10, 36 - bob, 12, 2, BAG.darkened(0.3))
			_r(img, 6, 36 - bob, 2, 12, JACKET_DARK)
			_r(img, 24, 36 - bob, 2, 12, JACKET_DARK)
		"left":
			_r(img, 19, 36 - bob, 4, 11, BAG)
			var swing := 2 if col == 1 else (-2 if col == 2 else 0)
			_r(img, 14 + swing, 37 - bob, 4, 11, JACKET_DARK)
			_r(img, 14 + swing, 48 - bob, 4, 2, SKIN)
		"right":
			_r(img, 9, 36 - bob, 4, 11, BAG)
			var swing := -2 if col == 1 else (2 if col == 2 else 0)
			_r(img, 14 + swing, 37 - bob, 4, 11, JACKET_DARK)
			_r(img, 14 + swing, 48 - bob, 4, 2, SKIN)
	# Tête.
	var hy := 14 - bob
	_r(img, 8, hy, 16, 20, SKIN)
	match direction:
		"down":
			_r(img, 8, hy, 16, 5, HAIR)
			_r(img, 8, hy, 2, 12, HAIR)
			_r(img, 22, hy, 2, 12, HAIR)
			_r(img, 12, hy + 10, 2, 4, EYE)
			_r(img, 18, hy + 10, 2, 4, EYE)
			_r(img, 14, hy + 16, 4, 1, Color("#b86b5a"))
		"up":
			_r(img, 8, hy, 16, 20, HAIR)
			_r(img, 8, hy + 17, 16, 3, HAIR.darkened(0.3))
		"left":
			_r(img, 14, hy, 10, 20, HAIR)
			_r(img, 8, hy, 16, 5, HAIR)
			_r(img, 10, hy + 10, 2, 4, EYE)
			_r(img, 17, hy + 9, 3, 4, SKIN.darkened(0.1))
		"right":
			_r(img, 8, hy, 10, 20, HAIR)
			_r(img, 8, hy, 16, 5, HAIR)
			_r(img, 20, hy + 10, 2, 4, EYE)
			_r(img, 12, hy + 9, 3, 4, SKIN.darkened(0.1))
	# Casquette et visière (repère de direction).
	_r(img, 7, hy - 5, 18, 7, CAP)
	_r(img, 9, hy - 7, 14, 2, CAP)
	_r(img, 14, hy - 5, 4, 2, Color("#f4f4f4"))
	match direction:
		"down":
			_r(img, 8, hy + 2, 16, 3, CAP_DARK)
		"up":
			_r(img, 7, hy + 1, 18, 2, CAP_DARK)
		"left":
			_r(img, 1, hy + 1, 10, 3, CAP_DARK)
		"right":
			_r(img, 21, hy + 1, 10, 3, CAP_DARK)
	return img


## Contour sombre de 1 px autour des pixels opaques (lisibilité sur l'herbe).
func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y: int in FH:
		for x: int in FW:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < FW and p.y < FH and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


func _write_frames() -> void:
	var text := "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
	text += "[ext_resource type=\"Texture2D\" path=\"%splayer_sheet.png\" id=\"1_sheet\"]\n\n" % DIR
	for row: int in 4:
		for col: int in 3:
			text += "[sub_resource type=\"AtlasTexture\" id=\"f_%d_%d\"]\n" % [row, col]
			text += "atlas = ExtResource(\"1_sheet\")\n"
			text += "region = Rect2(%d, %d, %d, %d)\n\n" % [col * FW, row * FH, FW, FH]
	var anims: PackedStringArray = []
	for row: int in 4:
		var d := DIRECTIONS[row]
		anims.append(_anim("idle_" + d, [0], row, 1.0))
		anims.append(_anim("walk_" + d, [1, 0, 2, 0], row, WALK_FPS))
		anims.append(_anim("run_" + d, [1, 0, 2, 0], row, RUN_FPS))
	text += "[resource]\nanimations = [%s]\n" % ", ".join(anims)
	var f := FileAccess.open(DIR + "player_frames.tres", FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _anim(anim_name: String, cols: Array, row: int, fps: float) -> String:
	var frames: PackedStringArray = []
	for col: int in cols:
		frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"f_%d_%d\")\n}" % [row, col])
	return "{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [
		", ".join(frames), anim_name, fps
	]
