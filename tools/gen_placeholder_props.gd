extends SceneTree
## Génère les props provisoires (formes simples aux dimensions finales) :
##   - textures PNG dans assets/tiles/placeholder/props/
##   - une scène héritée de game/world/props/prop.tscn par prop (empreinte du jalon 1 §4.3)
##
##   godot --headless --path . -s res://tools/gen_placeholder_props.gd
##   godot --headless --path . --import
##
## Les scènes sont écrites en texte (références par chemin) : pas besoin que les
## textures soient déjà importées.

const T: int = 96
const TEX_DIR: String = "res://assets/tiles/placeholder/props/"
const SCENE_DIR: String = "res://game/world/props/"
const SEED: int = 4242

## nom → [largeur, hauteur (cases), colonne d'ancre depuis la gauche, empreinte]
var _props: Dictionary = {
	"house_player": [7, 6, 3, _rect_fp(-3, -4, 3, 0)],
	"house_rival": [7, 6, 3, _rect_fp(-3, -4, 3, 0)],
	"oak_lab": [13, 7, 6, _rect_fp(-6, -4, 6, 0)],
	"plaza_tree": [5, 6, 2, _rect_fp(-2, -2, 2, 0)],
	"tree_oak_a": [3, 4, 1, [Vector2i.ZERO]],
	"tree_oak_b": [3, 4, 1, [Vector2i.ZERO]],
	"tree_pine": [3, 4, 1, [Vector2i.ZERO]],
	"tree_birch": [3, 4, 1, [Vector2i.ZERO]],
	"tree_maple": [3, 4, 1, [Vector2i.ZERO]],
	"bush_a": [1, 2, 0, [Vector2i.ZERO]],
	"bush_b": [1, 2, 0, [Vector2i.ZERO]],
	"lamp_post": [1, 3, 0, [Vector2i.ZERO]],
	"bench": [2, 1, 0, _rect_fp(0, 0, 1, 0)],
	"sign_pallet": [1, 1, 0, [Vector2i.ZERO]],
	"mailbox": [1, 1, 0, [Vector2i.ZERO]],
	"bicycle": [1, 1, 0, [Vector2i.ZERO]],
	"van": [3, 2, 1, _rect_fp(-1, -1, 1, 0)],
	"greenhouse_large": [7, 4, 3, _rect_fp(-3, -1, 3, 0)],
	"greenhouse_small": [3, 3, 1, _rect_fp(-1, -1, 1, 0)],
	"vegetable_patch": [3, 1, 1, _rect_fp(-1, 0, 1, 0)],
	"rock_small": [1, 1, 0, [Vector2i.ZERO]],
	"rock_large": [2, 2, 0, _rect_fp(0, 0, 1, 0)],
	"brambles": [1, 2, 0, [Vector2i.ZERO]],
	"barrier_route21": [1, 2, 0, _rect_fp(0, -1, 0, 0)],
}

## Props hauts qui deviennent semi-transparents quand le joueur passe derrière.
const FADING: Array[String] = [
	"house_player", "house_rival", "oak_lab", "plaza_tree", "greenhouse_large",
	"greenhouse_small", "tree_oak_a", "tree_oak_b", "tree_pine", "tree_birch", "tree_maple",
]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEX_DIR))
	for prop_name: String in _props:
		var spec: Array = _props[prop_name]
		_rng.seed = SEED + prop_name.hash()
		var img := Image.create_empty(spec[0] * T, spec[1] * T, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		call("_draw_" + _draw_key(prop_name), img, prop_name)
		img.save_png(TEX_DIR + prop_name + ".png")
		_write_prop_scene(prop_name, spec)
	for style: String in ["picket", "wood"]:
		var h := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
		var v := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
		h.fill(Color(0, 0, 0, 0))
		v.fill(Color(0, 0, 0, 0))
		_draw_fence(h, v, style)
		h.save_png(TEX_DIR + "fence_%s_h.png" % style)
		v.save_png(TEX_DIR + "fence_%s_v.png" % style)
		_write_fence_scene(style)
	print("props OK (%d + 2 clôtures)" % _props.size())
	quit()


static func _rect_fp(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			cells.append(Vector2i(x, y))
	return cells


func _draw_key(prop_name: String) -> String:
	if prop_name.begins_with("tree_"):
		return "tree"
	if prop_name.begins_with("house_"):
		return "house"
	if prop_name.begins_with("bush_"):
		return "bush"
	if prop_name.begins_with("greenhouse_"):
		return "greenhouse"
	if prop_name.begins_with("rock_"):
		return "rock"
	return prop_name


# --- Écriture des scènes -------------------------------------------------------

func _pascal(prop_name: String) -> String:
	return prop_name.to_pascal_case()


func _footprint_text(cells: Array) -> String:
	var parts: PackedStringArray = []
	for c: Vector2i in cells:
		parts.append("Vector2i(%d, %d)" % [c.x, c.y])
	return "Array[Vector2i]([%s])" % ", ".join(parts)


func _write_prop_scene(prop_name: String, spec: Array) -> void:
	var offset := Vector2(-(spec[2] * T + T / 2), -spec[1] * T)
	var text := "[gd_scene format=3]\n\n"
	text += "[ext_resource type=\"PackedScene\" path=\"res://game/world/props/prop.tscn\" id=\"1_base\"]\n"
	text += "[ext_resource type=\"Texture2D\" path=\"%s%s.png\" id=\"2_tex\"]\n\n" % [TEX_DIR, prop_name]
	text += "[node name=\"%s\" instance=ExtResource(\"1_base\")]\n" % _pascal(prop_name)
	text += "footprint = %s\n" % _footprint_text(spec[3])
	if prop_name in FADING:
		text += "fade_when_covering = true\n"
	text += "\n[node name=\"Sprite\" parent=\".\" index=\"0\"]\n"
	text += "texture = ExtResource(\"2_tex\")\n"
	text += "offset = Vector2(%d, %d)\n" % [offset.x, offset.y]
	_save_text(SCENE_DIR + prop_name + ".tscn", text)


func _write_fence_scene(style: String) -> void:
	var text := "[gd_scene format=3]\n\n"
	text += "[ext_resource type=\"PackedScene\" path=\"res://game/world/props/prop.tscn\" id=\"1_base\"]\n"
	text += "[ext_resource type=\"Script\" path=\"res://game/world/props/fence.gd\" id=\"2_fence\"]\n"
	text += "[ext_resource type=\"Texture2D\" path=\"%sfence_%s_h.png\" id=\"3_h\"]\n" % [TEX_DIR, style]
	text += "[ext_resource type=\"Texture2D\" path=\"%sfence_%s_v.png\" id=\"4_v\"]\n\n" % [TEX_DIR, style]
	text += "[node name=\"Fence%s\" instance=ExtResource(\"1_base\")]\n" % style.capitalize()
	text += "script = ExtResource(\"2_fence\")\n"
	text += "horizontal_texture = ExtResource(\"3_h\")\n"
	text += "vertical_texture = ExtResource(\"4_v\")\n\n"
	text += "[node name=\"Sprite\" parent=\".\" index=\"0\"]\n"
	text += "texture = ExtResource(\"3_h\")\n"
	text += "texture_repeat = 2\n"
	text += "region_enabled = true\n"
	text += "region_rect = Rect2(0, 0, 96, 96)\n"
	text += "offset = Vector2(-48, -96)\n"
	_save_text(SCENE_DIR + "fence_%s.tscn" % style, text)


func _save_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


# --- Primitives de dessin (mélange alpha) --------------------------------------

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _rect(img: Image, r: Rect2i, c: Color) -> void:
	for y: int in range(r.position.y, r.end.y):
		for x: int in range(r.position.x, r.end.x):
			_px(img, x, y, c)


func _ellipse(img: Image, center: Vector2, radii: Vector2, c: Color) -> void:
	for y: int in range(int(center.y - radii.y) - 1, int(center.y + radii.y) + 2):
		for x: int in range(int(center.x - radii.x) - 1, int(center.x + radii.x) + 2):
			var d := Vector2((x + 0.5 - center.x) / radii.x, (y + 0.5 - center.y) / radii.y)
			if d.length_squared() <= 1.0:
				_px(img, x, y, c)


## Boule ombrée, lumière venant du haut-droite (golden hour).
func _ball(img: Image, center: Vector2, radius: float, base: Color) -> void:
	var light := Vector2(0.45, -0.55)
	for y: int in range(int(center.y - radius) - 1, int(center.y + radius) + 2):
		for x: int in range(int(center.x - radius) - 1, int(center.x + radius) + 2):
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radius
			if d.length_squared() > 1.0:
				continue
			var k := clampf(d.dot(light) + 0.15, -1.0, 1.0)
			var c := base.lightened(k * 0.35) if k > 0.0 else base.darkened(-k * 0.4)
			_px(img, x, y, c)


func _poly(img: Image, points: PackedVector2Array, c: Color) -> void:
	var r := Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		r = r.expand(p)
	for y: int in range(int(r.position.y), int(r.end.y) + 1):
		for x: int in range(int(r.position.x), int(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_px(img, x, y, c)


func _shadow(img: Image, center: Vector2, radii: Vector2) -> void:
	_ellipse(img, center, radii, Color(0.08, 0.1, 0.05, 0.28))


# --- Dessins des props ----------------------------------------------------------

func _draw_house(img: Image, prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var rival := prop_name == "house_rival"
	var wall := Color("#e9dcc3") if not rival else Color("#d9dde0")
	var roof := Color("#c8432f") if not rival else Color("#a8503a")
	_shadow(img, Vector2(w / 2.0, h - 14), Vector2(w / 2.0 - 10, 18))
	# Murs (les 3 rangées basses) et soubassement.
	_rect(img, Rect2i(30, 250, w - 60, h - 262), wall)
	_rect(img, Rect2i(30, h - 44, w - 60, 32), wall.darkened(0.25))
	_rect(img, Rect2i(30, 250, 18, h - 262), wall.darkened(0.12))
	# Toit à deux pans (déborde sur la rangée haute non solide).
	_poly(img, PackedVector2Array([Vector2(8, 280), Vector2(w / 2.0, 10), Vector2(w - 8, 280)]),
		roof.darkened(0.3))
	_poly(img, PackedVector2Array([Vector2(16, 270), Vector2(w / 2.0, 22), Vector2(w / 2.0, 270)]),
		roof.darkened(0.08))
	_poly(img, PackedVector2Array([Vector2(w / 2.0, 22), Vector2(w - 16, 270), Vector2(w / 2.0, 270)]),
		roof.lightened(0.12))
	for i: int in 9:
		var y := 50 + i * 25
		_rect(img, Rect2i(int(w / 2.0 - (y - 22) * 1.3), y, int((y - 22) * 2.6), 2),
			Color(0, 0, 0, 0.12))
	# Cheminée.
	_rect(img, Rect2i(w - 190, 40, 40, 90), Color("#8a7b6d"))
	# Porte (case d'ancre) et fenêtres.
	var door_x := w / 2 - 38
	_rect(img, Rect2i(door_x - 8, h - 170, 92, 8), Color("#6b4a2f"))
	_rect(img, Rect2i(door_x, h - 162, 76, 150), Color("#7a4f2c"))
	_rect(img, Rect2i(door_x + 8, h - 150, 60, 60), Color("#8e5f37"))
	_ellipse(img, Vector2(door_x + 62, h - 90), Vector2(5, 5), Color("#e8c25a"))
	for wx: int in [90, 200, w - 290, w - 180]:
		_rect(img, Rect2i(wx - 6, 316, 96, 96), Color("#f7f1e3"))
		_rect(img, Rect2i(wx, 322, 84, 84), Color("#f2c46b") if wx < w / 2 else Color("#8cb8d6"))
		_rect(img, Rect2i(wx + 40, 322, 4, 84), Color("#f7f1e3"))
		_rect(img, Rect2i(wx, 362, 84, 4), Color("#f7f1e3"))
		_rect(img, Rect2i(wx - 10, 412, 104, 12), Color("#6f8f3e"))
		for f: int in 6:
			_ellipse(img, Vector2(wx + 6 + f * 16, 410), Vector2(5, 5),
				Color("#f29bb8") if f % 2 == 0 else Color("#f7f2e6"))


func _draw_oak_lab(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_shadow(img, Vector2(w / 2.0, h - 14), Vector2(w / 2.0 - 8, 20))
	var wall := Color("#c9ccc9")
	_rect(img, Rect2i(20, 250, w - 40, h - 262), wall)
	_rect(img, Rect2i(20, 250, w - 40, 14), wall.darkened(0.3))
	_rect(img, Rect2i(20, h - 40, w - 40, 28), wall.darkened(0.3))
	# Toit plat (déborde sur les 2 rangées hautes) et panneaux solaires.
	_rect(img, Rect2i(10, 30, w - 20, 225), Color("#5b5f66"))
	_rect(img, Rect2i(10, 30, w - 20, 10), Color("#7a7f87"))
	for i: int in 6:
		var px := 330 + i * 100
		_rect(img, Rect2i(px, 70, 90, 140), Color("#2a4b7a"))
		for k: int in 3:
			_rect(img, Rect2i(px, 70 + k * 47, 90, 2), Color("#8fb3e0"))
		_rect(img, Rect2i(px + 44, 70, 2, 140), Color("#8fb3e0"))
	_rect(img, Rect2i(90, 80, 70, 70), Color("#9a9ea5"))
	_rect(img, Rect2i(w - 170, 70, 60, 110), Color("#9a9ea5"))
	# Fenêtres éclairées.
	for i: int in 10:
		if i == 4 or i == 5:
			continue
		var wx := 70 + i * 114
		_rect(img, Rect2i(wx, 330, 84, 110), Color("#3b4450"))
		_rect(img, Rect2i(wx + 5, 335, 74, 100), Color("#f0c878"))
		_rect(img, Rect2i(wx + 40, 335, 4, 100), Color("#3b4450"))
	# Entrée vitrée (case d'ancre, façade sud) et emblème Poké Ball.
	var cx := w / 2
	_rect(img, Rect2i(cx - 100, h - 230, 200, 200), Color("#3b4450"))
	_rect(img, Rect2i(cx - 90, h - 220, 180, 190), Color("#9fd0e6"))
	_rect(img, Rect2i(cx - 2, h - 220, 4, 190), Color("#3b4450"))
	_ellipse(img, Vector2(cx, 300), Vector2(40, 40), Color("#f4f4f4"))
	_poly(img, PackedVector2Array([Vector2(cx - 40, 300), Vector2(cx + 40, 300),
		Vector2(cx + 38, 285), Vector2(cx, 260), Vector2(cx - 38, 285)]), Color("#e3350d"))
	_rect(img, Rect2i(cx - 40, 297, 80, 6), Color("#1c1c1c"))
	_ellipse(img, Vector2(cx, 300), Vector2(11, 11), Color("#1c1c1c"))
	_ellipse(img, Vector2(cx, 300), Vector2(7, 7), Color("#f4f4f4"))


func _draw_plaza_tree(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Îlot fleuri bordé de pierre (3 rangées basses = empreinte).
	_ellipse(img, Vector2(w / 2.0, h - 144), Vector2(236, 138), Color("#8e8576"))
	_ellipse(img, Vector2(w / 2.0, h - 150), Vector2(220, 124), Color("#b9ae9c"))
	_ellipse(img, Vector2(w / 2.0, h - 150), Vector2(200, 108), Color("#5f8f3e"))
	for i: int in 70:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.35, 0.95)
		var p := Vector2(w / 2.0 + cos(a) * 196 * r, h - 150 + sin(a) * 104 * r)
		var colors: Array[Color] = [Color("#f29bb8"), Color("#f7f2e6"), Color("#f5d04a")]
		_ellipse(img, p, Vector2(6, 6), colors[i % 3])
	# Tronc et racines.
	_shadow(img, Vector2(w / 2.0, h - 150), Vector2(120, 40))
	_rect(img, Rect2i(w / 2 - 34, 250, 68, h - 400), Color("#6b4a2f"))
	_rect(img, Rect2i(w / 2 - 34, 250, 20, h - 400), Color("#583b24"))
	_poly(img, PackedVector2Array([Vector2(w / 2.0 - 34, h - 170), Vector2(w / 2.0 - 70, h - 140),
		Vector2(w / 2.0 + 70, h - 140), Vector2(w / 2.0 + 34, h - 170)]), Color("#6b4a2f"))
	# Grande cime.
	var leaf := Color("#4f8a3a")
	for p: Vector2 in [Vector2(-130, 190), Vector2(130, 190), Vector2(-80, 120),
			Vector2(90, 110), Vector2(0, 90), Vector2(-150, 250), Vector2(150, 250),
			Vector2(0, 200)]:
		_ball(img, Vector2(w / 2.0, 0) + p, 95, leaf)
	for i: int in 14:
		var p := Vector2(_rng.randf_range(60, w - 60), _rng.randf_range(40, 290))
		_ball(img, p, 34, leaf.lightened(0.1))


func _draw_tree(img: Image, prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2.0
	_shadow(img, Vector2(cx, h - 16), Vector2(80, 20))
	var trunk := Color("#6b4a2f") if prop_name != "tree_birch" else Color("#e8e2d4")
	_rect(img, Rect2i(int(cx) - 16, h - 150, 32, 138), trunk)
	_rect(img, Rect2i(int(cx) - 16, h - 150, 10, 138), trunk.darkened(0.2))
	if prop_name == "tree_birch":
		for i: int in 6:
			_rect(img, Rect2i(int(cx) - 12, h - 140 + i * 22, 14, 4), Color("#3b3b3b"))
	match prop_name:
		"tree_pine":
			for i: int in 4:
				var y := 40.0 + i * 55
				var half := 50.0 + i * 28
				_poly(img, PackedVector2Array([Vector2(cx, y - 30), Vector2(cx + half, y + 70),
					Vector2(cx - half, y + 70)]), Color("#2f6b3c").lightened(i * 0.04))
				_poly(img, PackedVector2Array([Vector2(cx, y - 30), Vector2(cx + half, y + 70),
					Vector2(cx, y + 70)]), Color(1, 1, 0.7, 0.10))
		"tree_birch":
			for p: Vector2 in [Vector2(0, 110), Vector2(-50, 150), Vector2(50, 150), Vector2(0, 190)]:
				_ball(img, Vector2(cx, 0) + p, 64, Color("#8dbb4e"))
		"tree_maple":
			for p: Vector2 in [Vector2(-60, 160), Vector2(60, 160), Vector2(0, 110), Vector2(0, 190)]:
				_ball(img, Vector2(cx, 0) + p, 76, Color("#c8792f"))
		"tree_oak_b":
			for p: Vector2 in [Vector2(-70, 180), Vector2(70, 180), Vector2(-30, 110),
					Vector2(40, 100), Vector2(0, 200)]:
				_ball(img, Vector2(cx, 0) + p, 70, Color("#3f7a36"))
		_:
			for p: Vector2 in [Vector2(-60, 170), Vector2(60, 170), Vector2(0, 100), Vector2(0, 190)]:
				_ball(img, Vector2(cx, 0) + p, 80, Color("#4f8a3a"))
	for i: int in 8:
		var p := Vector2(_rng.randf_range(50, w - 50), _rng.randf_range(50, 230))
		if prop_name != "tree_pine":
			_ellipse(img, p, Vector2(8, 5), Color(1, 1, 0.8, 0.18))


func _draw_bush(img: Image, prop_name: String) -> void:
	var cx := T / 2.0
	var h := img.get_height()
	_shadow(img, Vector2(cx, h - 10), Vector2(40, 10))
	var leaf := Color("#4f8a3a") if prop_name == "bush_a" else Color("#5d9a44")
	_ball(img, Vector2(cx - 16, h - 50), 30, leaf)
	_ball(img, Vector2(cx + 16, h - 50), 30, leaf)
	_ball(img, Vector2(cx, h - 90), 34, leaf.lightened(0.05))
	if prop_name == "bush_b":
		for i: int in 8:
			_ellipse(img, Vector2(_rng.randf_range(20, 76), _rng.randf_range(h - 120, h - 30)),
				Vector2(4, 4), Color("#f29bb8"))


func _draw_lamp_post(img: Image, _prop_name: String) -> void:
	var cx := T / 2
	var h := img.get_height()
	_shadow(img, Vector2(cx, h - 10), Vector2(22, 7))
	_rect(img, Rect2i(cx - 14, h - 30, 28, 22), Color("#1f2226"))
	_rect(img, Rect2i(cx - 5, 70, 10, h - 90), Color("#23272c"))
	_ellipse(img, Vector2(cx, 60), Vector2(34, 34), Color(1.0, 0.8, 0.4, 0.18))
	_rect(img, Rect2i(cx - 18, 36, 36, 44), Color("#23272c"))
	_rect(img, Rect2i(cx - 13, 42, 26, 32), Color("#ffd98a"))
	_poly(img, PackedVector2Array([Vector2(cx - 24, 38), Vector2(cx, 18), Vector2(cx + 24, 38)]),
		Color("#1f2226"))


func _draw_bench(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	_shadow(img, Vector2(w / 2.0, 86), Vector2(86, 8))
	_rect(img, Rect2i(14, 22, w - 28, 12), Color("#8e5f37"))
	_rect(img, Rect2i(14, 40, w - 28, 12), Color("#8e5f37"))
	_rect(img, Rect2i(10, 58, w - 20, 16), Color("#a0703f"))
	for x: int in [20, w - 30]:
		_rect(img, Rect2i(x, 22, 10, 66), Color("#2b2b2b"))


func _draw_sign_pallet(img: Image, _prop_name: String) -> void:
	_shadow(img, Vector2(48, 88), Vector2(34, 6))
	_rect(img, Rect2i(20, 60, 8, 30), Color("#6b4a2f"))
	_rect(img, Rect2i(68, 60, 8, 30), Color("#6b4a2f"))
	_rect(img, Rect2i(6, 14, 84, 50), Color("#5a3a1e"))
	_rect(img, Rect2i(10, 18, 76, 42), Color("#c9a36b"))
	for i: int in 3:
		_rect(img, Rect2i(18, 26 + i * 11, 60 - i * 12, 4), Color("#5a3a1e"))


func _draw_mailbox(img: Image, _prop_name: String) -> void:
	_shadow(img, Vector2(48, 88), Vector2(20, 6))
	_rect(img, Rect2i(44, 46, 8, 44), Color("#5a4630"))
	_rect(img, Rect2i(28, 20, 40, 30), Color("#c0392b"))
	_ellipse(img, Vector2(48, 22), Vector2(20, 8), Color("#d24a3a"))
	_rect(img, Rect2i(68, 16, 4, 18), Color("#f5d04a"))


func _draw_bicycle(img: Image, _prop_name: String) -> void:
	_shadow(img, Vector2(48, 86), Vector2(40, 7))
	for x: int in [24, 72]:
		_ellipse(img, Vector2(x, 66), Vector2(18, 18), Color("#1f2226"))
		_ellipse(img, Vector2(x, 66), Vector2(13, 13), Color(0, 0, 0, 0))
	_poly(img, PackedVector2Array([Vector2(24, 64), Vector2(48, 44), Vector2(72, 64),
		Vector2(66, 64), Vector2(48, 50), Vector2(30, 64)]), Color("#c0392b"))
	_rect(img, Rect2i(40, 36, 16, 5), Color("#1f2226"))
	_rect(img, Rect2i(62, 34, 5, 16), Color("#555"))


func _draw_van(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_shadow(img, Vector2(w / 2.0, h - 12), Vector2(w / 2.0 - 6, 16))
	_rect(img, Rect2i(18, 20, w - 36, h - 50), Color("#e8e6e0"))
	_rect(img, Rect2i(18, 20, w - 36, 20), Color("#f6f5f1"))
	_rect(img, Rect2i(w - 90, 50, 60, 40), Color("#6d8ca8"))
	_rect(img, Rect2i(30, 50, 150, 40), Color("#6d8ca8"))
	_rect(img, Rect2i(18, 110, w - 36, 12), Color("#2e7d6b"))
	for x: int in [60, w - 60]:
		_ellipse(img, Vector2(x, h - 28), Vector2(22, 22), Color("#1f2226"))
		_ellipse(img, Vector2(x, h - 28), Vector2(9, 9), Color("#9a9ea5"))


func _draw_greenhouse(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_shadow(img, Vector2(w / 2.0, h - 10), Vector2(w / 2.0 - 4, 14))
	var top := T
	_rect(img, Rect2i(12, top, w - 24, h - top - 10), Color(0.72, 0.9, 0.88, 0.75))
	_poly(img, PackedVector2Array([Vector2(12, top), Vector2(w / 2.0, 14), Vector2(w - 12, top)]),
		Color(0.8, 0.95, 0.93, 0.8))
	for x: int in range(12, w - 11, 48):
		_rect(img, Rect2i(x, top, 4, h - top - 10), Color("#f2f2ee"))
	_rect(img, Rect2i(12, top, w - 24, 4), Color("#f2f2ee"))
	_rect(img, Rect2i(12, h - 14, w - 24, 4), Color("#f2f2ee"))
	for i: int in w / 30:
		_ball(img, Vector2(_rng.randf_range(30, w - 30), _rng.randf_range(top + 40, h - 30)), 14,
			Color("#4f8a3a"))


func _draw_vegetable_patch(img: Image, _prop_name: String) -> void:
	var w := img.get_width()
	_rect(img, Rect2i(6, 20, w - 12, 70), Color("#6b4a2f"))
	_rect(img, Rect2i(12, 26, w - 24, 58), Color("#7a5532"))
	for r: int in 2:
		for x: int in range(26, w - 20, 26):
			_ball(img, Vector2(x, 42 + r * 26), 10, Color("#6bb04a") if r == 0 else Color("#9ec24a"))


func _draw_rock(img: Image, prop_name: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_shadow(img, Vector2(w / 2.0, h - 12), Vector2(w / 2.0 - 8, 10))
	if prop_name == "rock_small":
		_ball(img, Vector2(48, 62), 28, Color("#8d8a82"))
		_ball(img, Vector2(64, 72), 16, Color("#7c7970"))
	else:
		_ball(img, Vector2(80, 120), 62, Color("#8d8a82"))
		_ball(img, Vector2(140, 140), 42, Color("#7c7970"))
		_ellipse(img, Vector2(70, 80), Vector2(22, 8), Color("#6f9a45"))


func _draw_brambles(img: Image, _prop_name: String) -> void:
	var h := img.get_height()
	for i: int in 16:
		var p := Vector2(_rng.randf_range(12, 84), _rng.randf_range(40, h - 16))
		_ball(img, p, _rng.randf_range(14, 22), Color("#3d5a2a"))
	for i: int in 30:
		var p := Vector2(_rng.randf_range(10, 86), _rng.randf_range(34, h - 10))
		_px(img, int(p.x), int(p.y), Color("#c9c29a"))
		_ellipse(img, p, Vector2(2, 2), Color("#7a3b5a"))


func _draw_barrier_route21(img: Image, _prop_name: String) -> void:
	var h := img.get_height()
	_rect(img, Rect2i(14, 40, 12, h - 44), Color("#5a3a1e"))
	_rect(img, Rect2i(70, 40, 12, h - 44), Color("#5a3a1e"))
	for y: int in [70, 120, 160]:
		_rect(img, Rect2i(4, y, 88, 12), Color("#a0703f"))
	_rect(img, Rect2i(16, 6, 64, 40), Color("#5a3a1e"))
	_rect(img, Rect2i(20, 10, 56, 32), Color("#e8e2d4"))
	_poly(img, PackedVector2Array([Vector2(30, 26), Vector2(56, 16), Vector2(56, 36)]),
		Color("#c0392b"))


func _draw_fence(h: Image, v: Image, style: String) -> void:
	if style == "picket":
		var white := Color("#f4f1ea")
		var shade := Color("#c9c4b8")
		_rect(h, Rect2i(0, 44, T, 8), shade)
		_rect(h, Rect2i(0, 70, T, 8), shade)
		for x: int in range(4, T, 24):
			_rect(h, Rect2i(x, 30, 14, 62), white)
			_poly(h, PackedVector2Array([Vector2(x, 30), Vector2(x + 7, 22), Vector2(x + 14, 30)]),
				white)
			_rect(h, Rect2i(x + 10, 30, 4, 62), shade)
		_rect(v, Rect2i(42, 0, 6, T), shade)
		_rect(v, Rect2i(50, 0, 6, T), shade)
		for y: int in range(0, T, 24):
			_rect(v, Rect2i(40, y, 18, 14), white)
	else:
		var wood := Color("#a0703f")
		var dark := Color("#5a3a1e")
		_rect(h, Rect2i(0, 40, T, 12), wood)
		_rect(h, Rect2i(0, 66, T, 12), wood)
		_rect(h, Rect2i(0, 52, T, 2), dark)
		_rect(h, Rect2i(0, 78, T, 2), dark)
		_rect(h, Rect2i(8, 28, 12, 66), dark)
		_rect(h, Rect2i(56, 28, 12, 66), dark)
		_rect(v, Rect2i(40, 0, 8, T), wood)
		_rect(v, Rect2i(52, 0, 8, T), wood)
		_rect(v, Rect2i(40, 30, 20, 20), dark)
