extends SceneTree
## Génère les props provisoires (formes simples aux dimensions finales) :
##   - textures PNG dans assets/tiles/placeholder/props/
##   - une scène héritée de game/world/props/prop.tscn par prop (empreinte du jalon 1 §4.3)
##   - mobilier d'intérieur (jalon 2 §4.1 et §4.3) : textures dans
##     assets/tiles/placeholder/props/interior/, scènes dans game/world/props/interior/
##
##   godot --headless --path . -s res://tools/gen_placeholder_props.gd
##   godot --headless --path . --import
##
## Les scènes sont écrites en texte (références par chemin) : pas besoin que les
## textures soient déjà importées.

const T: int = 96
const TEX_DIR: String = "res://assets/tiles/placeholder/props/"
const SCENE_DIR: String = "res://game/world/props/"
const INTERIOR_TEX_DIR: String = "res://assets/tiles/placeholder/props/interior/"
const INTERIOR_SCENE_DIR: String = "res://game/world/props/interior/"
const SEED: int = 4242

## nom → [largeur, hauteur (cases), colonne d'ancre depuis la gauche, empreinte]
var _props: Dictionary = {
	# Bâtiments : la case de porte (ancre 0, 0) est praticable (jalon 2 §4.2).
	"house_player": [7, 6, 3, _without_door(_rect_fp(-3, -4, 3, 0))],
	"house_rival": [7, 6, 3, _without_door(_rect_fp(-3, -4, 3, 0))],
	"oak_lab": [13, 7, 6, _without_door(_rect_fp(-6, -4, 6, 0))],
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
	"plant",
]

## Mobilier d'intérieur (jalon 2 §4.1, §4.3 à §4.7) : nom → [largeur, hauteur (cases), empreinte].
## Ancre = case en bas à gauche (colonne 0) ; empreinte relative à l'ancre.
## Seule la plante (1 × 2) devient transparente : sinon elle cache le joueur debout juste derrière.
var _interior: Dictionary = {
	"window": [2, 1, []],
	"window_lab": [3, 1, []],
	"wall_map": [2, 1, []],
	"bed": [2, 3, _rect_fp(0, -1, 1, 0)],
	"plant": [1, 2, [Vector2i.ZERO]],
	"kitchen_counter": [3, 2, _rect_fp(0, 0, 2, 0)],
	"fridge": [1, 3, [Vector2i.ZERO]],
	"dining_table": [3, 2, _rect_fp(0, -1, 2, 0)],
	# Table des starters du labo (§4.7) : toute la table est solide (3 × 2).
	"starter_table": [3, 2, _rect_fp(0, -1, 2, 0)],
	"lab_bench": [3, 2, _rect_fp(0, 0, 2, 0)],
	# Chambre du joueur (§4.3).
	"poster": [1, 1, []],
	"window_curtains": [2, 1, []],
	"nightstand_lamp": [1, 2, [Vector2i.ZERO]],
	"small_shelf": [1, 2, [Vector2i.ZERO]],
	"laptop_desk": [3, 2, _rect_fp(0, 0, 2, 0)],
	"desk_chair": [1, 1, [Vector2i.ZERO]],
	"tall_bookshelf": [2, 3, _rect_fp(0, -1, 1, 0)],
	"tv_console_side": [1, 3, _rect_fp(0, -1, 0, 0)],
	"travel_bag": [1, 1, [Vector2i.ZERO]],
	"low_cabinet": [3, 1, _rect_fp(0, 0, 2, 0)],
	"low_cabinet_small": [1, 1, [Vector2i.ZERO]],
	"pokeball_crate": [2, 1, _rect_fp(0, 0, 1, 0)],
	"rug_pokeball": [4, 3, []],
	"rug_check": [2, 1, []],
	"door_side": [1, 2, []],
	# Rez-de-chaussée du joueur (§4.4).
	"stairs_up_side": [2, 3, _rect_fp(0, -1, 1, -1)],
	"sofa": [3, 2, _rect_fp(0, 0, 2, 0)],
	"coffee_table": [2, 1, _rect_fp(0, 0, 1, 0)],
	"coat_rack": [1, 2, [Vector2i.ZERO]],
	"dresser_pokeball": [1, 2, [Vector2i.ZERO]],
	"front_door": [1, 2, []],
	"rug_plaid": [5, 4, []],
	"rug_living": [3, 3, []],
	# Maison du rival (§4.5).
	"range_hood_stove": [1, 2, [Vector2i.ZERO]],
	"stairs_up_wide": [3, 3, _rect_fp(0, -2, 2, 0)],
	# Bureau d'angle en L (mur du fond + mur ouest) : la chaise occupe le coin libre.
	"corner_desk_pc": [2, 2, [Vector2i(0, -1), Vector2i(1, -1), Vector2i(0, 0)]],
	"gamer_chair": [1, 1, [Vector2i.ZERO]],
	"dresser": [2, 2, _rect_fp(0, 0, 1, 0)],
	"bed_pokeball": [2, 3, _rect_fp(0, -2, 1, 0)],
	"nightstand_bag": [1, 2, [Vector2i.ZERO]],
	"wall_tv_side": [1, 3, _rect_fp(0, -1, 0, 0)],
	"shoe_rack": [1, 1, [Vector2i.ZERO]],
	"bathroom_sink": [2, 2, _rect_fp(0, 0, 1, 0)],
	"shower": [1, 3, _rect_fp(0, -1, 0, 0)],
	# Cloisons et murets, un segment par case : vertical (nord-sud) et horizontal.
	"partition": [1, 1, [Vector2i.ZERO]],
	"partition_h": [1, 1, [Vector2i.ZERO]],
	"rival_posters": [2, 1, []],
	"rug_bath": [2, 1, []],
	"rug_bedroom_grey": [3, 2, []],
	"rug_living_blue": [4, 3, []],
	# Laboratoire (§4.7).
	"aquarium": [1, 2, [Vector2i.ZERO]],
	"incubator": [2, 3, _rect_fp(0, -1, 1, 0)],
	"lab_computers": [2, 2, _rect_fp(0, 0, 1, 0)],
	"oak_desk": [3, 2, _rect_fp(0, 0, 2, 0)],
	"file_cabinet": [1, 2, [Vector2i.ZERO]],
	"display_case": [1, 3, _rect_fp(0, -2, 0, 0)],
	"long_counter": [5, 2, _rect_fp(0, 0, 4, 0)],
	"sofa_side": [1, 2, _rect_fp(0, -1, 0, 0)],
	"stool": [1, 1, [Vector2i.ZERO]],
	"wall_screen_side": [1, 3, _rect_fp(0, -1, 0, 0)],
	"stairs_deco": [3, 2, _rect_fp(0, -1, 2, 0)],
	"pokemon_poster": [1, 1, []],
	"lab_doorway": [2, 1, []],
	"rug_red": [4, 3, []],
	# Jalon 3A (jalon-03.md §3.2) : décor posé sur un meuble, sans empreinte (le meuble
	# dessous est déjà solide), placé juste après lui dans `Entities` (même ligne de tri).
	# Petit-déjeuner sur la table à manger (même taille que la table, 3 × 2).
	"breakfast": [3, 2, []],
	# Sur le lit du rival (2 cases du bas du lit) : carte de Kanto dépliée, sac ouvert,
	# affaires.
	"bed_items": [2, 2, []],
}

## Tapis (rug_*) : posés par les constructeurs de cartes sous le calque `Detail` (au-dessus
## du sol, sous les entités), jamais dans `Entities` où le y-sort les mettrait devant le joueur.

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(INTERIOR_TEX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(INTERIOR_SCENE_DIR))
	for prop_name: String in _interior:
		var spec: Array = _interior[prop_name]
		_rng.seed = SEED + prop_name.hash()
		var img := Image.create_empty(spec[0] * T, spec[1] * T, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		call("_draw_" + prop_name, img)
		img.save_png(INTERIOR_TEX_DIR + prop_name + ".png")
		_write_interior_scene(prop_name, spec)
	print("props OK (%d + 2 clôtures, %d d'intérieur)" % [_props.size(), _interior.size()])
	quit()


## Empreinte sans la case d'ancre (case de porte d'un bâtiment).
static func _without_door(cells: Array[Vector2i]) -> Array[Vector2i]:
	cells.erase(Vector2i.ZERO)
	return cells


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


func _write_interior_scene(prop_name: String, spec: Array) -> void:
	var offset := Vector2(-T / 2, -spec[1] * T)
	var text := "[gd_scene format=3]\n\n"
	text += "[ext_resource type=\"PackedScene\" path=\"res://game/world/props/prop.tscn\" id=\"1_base\"]\n"
	text += "[ext_resource type=\"Texture2D\" path=\"%s%s.png\" id=\"2_tex\"]\n\n" % [
		INTERIOR_TEX_DIR, prop_name]
	text += "[node name=\"%s\" instance=ExtResource(\"1_base\")]\n" % _pascal(prop_name)
	text += "footprint = %s\n" % _footprint_text(spec[2])
	if prop_name in FADING:
		text += "fade_when_covering = true\n"
	text += "\n[node name=\"Sprite\" parent=\".\" index=\"0\"]\n"
	text += "texture = ExtResource(\"2_tex\")\n"
	text += "offset = Vector2(%d, %d)\n" % [offset.x, offset.y]
	_save_text(INTERIOR_SCENE_DIR + prop_name + ".tscn", text)


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


# --- Mobilier d'intérieur (formes simples aux dimensions finales) ------------------

const WOOD := Color("#9a6a3c")
const WOOD_DARK := Color("#5e3d22")
const WOOD_LIGHT := Color("#c08d5a")


## Meuble vu de 3/4 : dessus clair de [param top_h] px, façade dessous, ombre au sol.
func _box(img: Image, r: Rect2i, top_h: int, front: Color) -> void:
	_rect(img, Rect2i(r.position.x + 4, r.end.y - 6, r.size.x - 8, 6), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(r.position.x, r.position.y, r.size.x, r.size.y - 6), front.darkened(0.45))
	_rect(img, Rect2i(r.position.x + 3, r.position.y + 3, r.size.x - 6, top_h - 3),
		front.lightened(0.18))
	_rect(img, Rect2i(r.position.x + 3, r.position.y + top_h, r.size.x - 6,
		r.size.y - top_h - 9), front)


func _pokeball(img: Image, center: Vector2, radius: float) -> void:
	_ellipse(img, center, Vector2(radius, radius), Color("#1c1c1c"))
	_ellipse(img, center, Vector2(radius - 2, radius - 2), Color("#f4f4f4"))
	_poly(img, PackedVector2Array([Vector2(center.x - radius + 2, center.y),
		Vector2(center.x - radius * 0.7, center.y - radius * 0.7),
		Vector2(center.x, center.y - radius + 2),
		Vector2(center.x + radius * 0.7, center.y - radius * 0.7),
		Vector2(center.x + radius - 2, center.y)]), Color("#e3350d"))
	_rect(img, Rect2i(int(center.x - radius) + 1, int(center.y) - 1, int(radius * 2) - 2, 3),
		Color("#1c1c1c"))
	_ellipse(img, center, Vector2(radius * 0.3, radius * 0.3), Color("#1c1c1c"))
	_ellipse(img, center, Vector2(radius * 0.18, radius * 0.18), Color("#f4f4f4"))


## Rangée de dos de livres colorés dans [param r].
func _books(img: Image, r: Rect2i) -> void:
	var colors: Array[Color] = [Color("#c0392b"), Color("#2e6da4"), Color("#e0a93b"),
		Color("#3e8e5a"), Color("#8e5aa8"), Color("#e8e2d4")]
	var x := r.position.x
	while x < r.end.x - 4:
		var bw := _rng.randi_range(6, 11)
		var bh := _rng.randi_range(int(r.size.y * 0.7), r.size.y)
		_rect(img, Rect2i(x, r.end.y - bh, mini(bw, r.end.x - x), bh),
			colors[_rng.randi_range(0, colors.size() - 1)])
		x += bw + 1


func _shelves(img: Image, r: Rect2i, rows: int) -> void:
	_rect(img, r, WOOD_DARK)
	_rect(img, Rect2i(r.position.x + 6, r.position.y + 6, r.size.x - 12, r.size.y - 12),
		WOOD.darkened(0.3))
	var h := (r.size.y - 12) / rows
	for i: int in rows:
		var y := r.position.y + 6 + i * h
		_books(img, Rect2i(r.position.x + 10, y + 6, r.size.x - 20, h - 12))
		_rect(img, Rect2i(r.position.x + 6, y + h - 6, r.size.x - 12, 6), WOOD)


func _window_frame(img: Image, r: Rect2i, frame: Color) -> void:
	_rect(img, r, frame)
	var glass := Rect2i(r.position.x + 8, r.position.y + 8, r.size.x - 16, r.size.y - 18)
	_rect(img, glass, Color("#9fd0e6"))
	_rect(img, Rect2i(glass.position.x, glass.position.y + glass.size.y / 2, glass.size.x,
		glass.size.y / 2), Color("#f2c46b").lerp(Color("#9fd0e6"), 0.4))
	_ellipse(img, Vector2(glass.position.x + glass.size.x * 0.3, glass.end.y - 10),
		Vector2(glass.size.x * 0.25, 14), Color("#5f9a4a"))
	_rect(img, Rect2i(r.position.x + r.size.x / 2 - 2, r.position.y, 4, r.size.y), frame)
	_rect(img, Rect2i(r.position.x, glass.position.y + glass.size.y / 2 - 2, r.size.x, 4), frame)
	_rect(img, Rect2i(r.position.x - 4, r.end.y - 10, r.size.x + 8, 10), frame.darkened(0.2))


func _draw_window(img: Image) -> void:
	_window_frame(img, Rect2i(18, 10, img.get_width() - 36, 80), Color("#f4efe4"))


func _draw_window_lab(img: Image) -> void:
	_window_frame(img, Rect2i(12, 8, img.get_width() - 24, 82), Color("#8d969c"))


func _draw_window_curtains(img: Image) -> void:
	var w := img.get_width()
	_window_frame(img, Rect2i(40, 8, w - 80, 82), Color("#f4efe4"))
	_rect(img, Rect2i(12, 2, w - 24, 6), WOOD_DARK)
	for x: int in [14, w - 50]:
		_rect(img, Rect2i(x, 6, 36, 86), Color("#dfe6f2"))
		for k: int in 4:
			_rect(img, Rect2i(x + 4 + k * 9, 6, 2, 86), Color("#b9c4d8"))


func _draw_poster(img: Image) -> void:
	_rect(img, Rect2i(14, 8, 68, 78), Color("#f4efe4"))
	_rect(img, Rect2i(20, 14, 56, 66), Color("#8cc3e6"))
	_poly(img, PackedVector2Array([Vector2(20, 70), Vector2(46, 28), Vector2(76, 70)]),
		Color("#6d7f96"))
	_poly(img, PackedVector2Array([Vector2(38, 41), Vector2(46, 28), Vector2(54, 41)]),
		Color("#f4f4f4"))
	_rect(img, Rect2i(20, 66, 56, 14), Color("#5f9a4a"))


func _draw_wall_map(img: Image) -> void:
	var w := img.get_width()
	_rect(img, Rect2i(10, 6, w - 20, 84), Color("#a57a4a"))
	_rect(img, Rect2i(16, 12, w - 32, 72), Color("#6fa6c9"))
	_ellipse(img, Vector2(w * 0.42, 46), Vector2(48, 26), Color("#8fbf6a"))
	_ellipse(img, Vector2(w * 0.62, 38), Vector2(26, 18), Color("#a9c77a"))
	_ellipse(img, Vector2(w * 0.3, 62), Vector2(16, 10), Color("#8fbf6a"))
	for p: Vector2 in [Vector2(70, 40), Vector2(96, 52), Vector2(118, 36)]:
		_ellipse(img, p, Vector2(4, 4), Color("#c0392b"))


func _draw_desk(img: Image, top: Color) -> void:
	var w := img.get_width()
	_box(img, Rect2i(6, 100, w - 12, 90), 24, WOOD)
	for x: int in [16, w - 60]:
		_rect(img, Rect2i(x, 134, 44, 22), WOOD.darkened(0.15))
		_rect(img, Rect2i(x + 18, 143, 8, 3), Color("#e8c25a"))
	_rect(img, Rect2i(10, 102, w - 20, 20), top)


func _draw_small_shelf(img: Image) -> void:
	_shelves(img, Rect2i(10, 40, 76, img.get_height() - 44), 3)


func _draw_tall_bookshelf(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_shelves(img, Rect2i(8, 20, w - 16, h - 24), 4)
	_pokeball(img, Vector2(w - 40, 42), 12)
	_rect(img, Rect2i(30, h - 70, 50, 36), Color("#c0503a"))
	_rect(img, Rect2i(34, h - 66, 42, 6), Color("#e07a5f"))


func _draw_tv_console_side(img: Image) -> void:
	var h := img.get_height()
	# Meuble long contre le mur est, vu du dessus-côté ; écran plat sur le bord droit.
	_rect(img, Rect2i(10, 26, 76, h - 32), WOOD_DARK)
	_rect(img, Rect2i(14, 30, 64, h - 44), WOOD_LIGHT)
	_rect(img, Rect2i(74, 60, 12, 150), Color("#1f2226"))
	_rect(img, Rect2i(62, 110, 12, 40), Color("#3a3f47"))
	_rect(img, Rect2i(24, 100, 26, 16), Color("#3a3f47"))
	_rect(img, Rect2i(24, 150, 28, 34), Color("#4a6aa8"))
	_rect(img, Rect2i(28, 60, 18, 22), Color("#f4efe4"))
	_rect(img, Rect2i(0, h - 8, 90, 6), Color(0, 0, 0, 0.25))


func _draw_bed(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, h - 10, w - 16, 8), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(6, 10, w - 12, 70), WOOD_DARK)
	_rect(img, Rect2i(12, 16, w - 24, 58), WOOD)
	_rect(img, Rect2i(10, 70, w - 20, h - 84), Color("#f2f0ea"))
	_ellipse(img, Vector2(58, 96), Vector2(38, 20), Color("#ffffff"))
	_ellipse(img, Vector2(w - 58, 96), Vector2(38, 20), Color("#ffffff"))
	var blanket := Rect2i(10, 124, w - 20, h - 142)
	for y: int in range(blanket.position.y, blanket.end.y):
		for x: int in range(blanket.position.x, blanket.end.x):
			var check := ((x / 20) + (y / 20)) % 2 == 0
			_px(img, x, y, Color("#4a6aa8") if check else Color("#6f8cc6"))
	_rect(img, Rect2i(10, 124, w - 20, 10), Color("#f2f0ea"))
	_rect(img, Rect2i(6, h - 22, w - 12, 14), WOOD_DARK)


func _draw_plant(img: Image) -> void:
	var h := img.get_height()
	_shadow(img, Vector2(48, h - 8), Vector2(26, 7))
	_poly(img, PackedVector2Array([Vector2(28, h - 48), Vector2(68, h - 48), Vector2(62, h - 8),
		Vector2(34, h - 8)]), Color("#b0643a"))
	_rect(img, Rect2i(26, h - 52, 44, 8), Color("#8e4f2c"))
	for p: Vector2 in [Vector2(34, h - 80), Vector2(62, h - 84), Vector2(48, h - 110),
			Vector2(30, h - 118), Vector2(66, h - 124), Vector2(48, h - 146)]:
		_ball(img, p, 22, Color("#4f8a3a"))


func _draw_kitchen_counter(img: Image) -> void:
	var w := img.get_width()
	# Crédence basse : la fenêtre posée au-dessus reste visible.
	_rect(img, Rect2i(6, 46, w - 12, 24), Color("#e6dccb"))
	for x: int in range(6, w - 6, 24):
		_rect(img, Rect2i(x, 46, 1, 24), Color("#cfc3ae"))
	_box(img, Rect2i(4, 70, w - 8, 120), 30, Color("#e8e2d4"))
	for k: int in 3:
		_rect(img, Rect2i(14 + k * 94, 110, 80, 64), Color("#d4cab6"))
		_rect(img, Rect2i(48 + k * 94, 138, 12, 4), Color("#8a8f96"))
	_rect(img, Rect2i(30, 78, 70, 20), Color("#b9c2c9"))
	_rect(img, Rect2i(62, 60, 6, 22), Color("#8a8f96"))
	_rect(img, Rect2i(190, 76, 80, 24), Color("#2b2f36"))
	for x: int in [210, 250]:
		_ellipse(img, Vector2(x, 88), Vector2(12, 7), Color("#555a61"))


func _draw_fridge(img: Image) -> void:
	var h := img.get_height()
	_rect(img, Rect2i(10, h - 8, 76, 6), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(10, 12, 76, h - 20), Color("#b9c2c9"))
	_rect(img, Rect2i(14, 16, 68, h - 28), Color("#eef1f3"))
	_rect(img, Rect2i(14, 110, 68, 4), Color("#b9c2c9"))
	_rect(img, Rect2i(70, 60, 5, 36), Color("#8a8f96"))
	_rect(img, Rect2i(70, 130, 5, 50), Color("#8a8f96"))
	_rect(img, Rect2i(26, 40, 16, 14), Color("#e0a93b"))


func _draw_dining_table(img: Image) -> void:
	var w := img.get_width()
	for x: int in [48, 144, 240]:
		_rect(img, Rect2i(x - 20, 6, 40, 40), WOOD_DARK)
		_rect(img, Rect2i(x - 16, 10, 32, 30), WOOD)
	_box(img, Rect2i(10, 36, w - 20, 120), 88, WOOD_LIGHT)
	_ellipse(img, Vector2(w / 2.0, 80), Vector2(22, 14), Color("#f4f4f4"))
	_ellipse(img, Vector2(w / 2.0, 78), Vector2(10, 6), Color("#e07a5f"))
	for x: int in [48, 144, 240]:
		_rect(img, Rect2i(x - 20, 150, 40, 40), WOOD_DARK)
		_rect(img, Rect2i(x - 16, 154, 32, 24), WOOD)


func _draw_nightstand_lamp(img: Image) -> void:
	_box(img, Rect2i(12, 110, 72, 80), 20, WOOD)
	_rect(img, Rect2i(22, 146, 52, 4), WOOD_DARK)
	_ellipse(img, Vector2(48, 66), Vector2(42, 42), Color(1.0, 0.85, 0.5, 0.18))
	_rect(img, Rect2i(44, 80, 8, 34), Color("#8a6d2a"))
	_poly(img, PackedVector2Array([Vector2(28, 84), Vector2(36, 50), Vector2(60, 50),
		Vector2(68, 84)]), Color("#f7e2a8"))


func _draw_laptop_desk(img: Image) -> void:
	_draw_desk(img, WOOD_LIGHT)
	var w := img.get_width()
	_rect(img, Rect2i(w / 2 - 44, 44, 88, 58), Color("#2b2f36"))
	_rect(img, Rect2i(w / 2 - 38, 50, 76, 46), Color("#8fc3e8"))
	_rect(img, Rect2i(w / 2 - 50, 100, 100, 12), Color("#b9c2c9"))
	_rect(img, Rect2i(30, 30, 6, 76), Color("#3a3f47"))
	_poly(img, PackedVector2Array([Vector2(24, 34), Vector2(60, 24), Vector2(62, 40)]),
		Color("#3a3f47"))
	_ellipse(img, Vector2(58, 40), Vector2(10, 6), Color("#f7e2a8"))
	_rect(img, Rect2i(w - 70, 70, 34, 36), Color("#e0a93b"))


func _draw_desk_chair(img: Image) -> void:
	_shadow(img, Vector2(48, 88), Vector2(30, 7))
	_rect(img, Rect2i(46, 62, 4, 22), Color("#3a3f47"))
	_rect(img, Rect2i(26, 82, 44, 4), Color("#3a3f47"))
	_rect(img, Rect2i(24, 10, 48, 48), Color("#2e3f73"))
	_rect(img, Rect2i(28, 14, 40, 40), Color("#3d5294"))
	_rect(img, Rect2i(20, 52, 56, 12), Color("#2e3f73"))


func _draw_travel_bag(img: Image) -> void:
	_shadow(img, Vector2(48, 88), Vector2(34, 7))
	_rect(img, Rect2i(16, 30, 64, 56), Color("#2e4f8a"))
	_rect(img, Rect2i(20, 34, 56, 20), Color("#3d63a8"))
	_rect(img, Rect2i(30, 18, 36, 14), Color("#1f3560"))
	_rect(img, Rect2i(34, 22, 28, 8), Color(0, 0, 0, 0))
	for x: int in [28, 64]:
		_rect(img, Rect2i(x, 30, 5, 56), Color("#8e5f37"))
	_pokeball(img, Vector2(48, 66), 10)


func _draw_low_cabinet(img: Image) -> void:
	var w := img.get_width()
	_box(img, Rect2i(6, 40, w - 12, 52), 18, WOOD)
	_rect(img, Rect2i(24, 16, 32, 36), Color("#f4efe4"))
	_rect(img, Rect2i(28, 20, 24, 26), Color("#e0a98a"))
	_ball(img, Vector2(110, 26), 16, Color("#4f8a3a"))
	_rect(img, Rect2i(100, 34, 20, 18), Color("#b0643a"))
	_books(img, Rect2i(170, 22, 60, 30))
	_ellipse(img, Vector2(w - 30, 44), Vector2(20, 8), Color("#8e5f37"))


func _draw_low_cabinet_small(img: Image) -> void:
	_box(img, Rect2i(8, 40, 80, 52), 18, WOOD)
	_ellipse(img, Vector2(46, 38), Vector2(24, 16), Color("#c0392b"))
	_rect(img, Rect2i(22, 36, 48, 6), Color("#f4f4f4"))
	_ellipse(img, Vector2(64, 46), Vector2(18, 5), Color("#a82e22"))


func _draw_pokeball_crate(img: Image) -> void:
	var w := img.get_width()
	_box(img, Rect2i(8, 22, w - 16, 70), 14, WOOD)
	_rect(img, Rect2i(14, 26, w - 28, 30), WOOD_DARK)
	for k: int in 4:
		_pokeball(img, Vector2(40 + k * 38, 36), 14)


func _draw_rug_pokeball(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(6, 6, w - 12, h - 12), Color("#7d8290"))
	_rect(img, Rect2i(18, 18, w - 36, h - 36), Color("#b9bcc6"))
	_rect(img, Rect2i(28, 28, w - 56, h - 56), Color("#a7abb6"))
	var c := Vector2(w / 2.0, h / 2.0)
	_ellipse(img, c, Vector2(96, 96), Color("#7d8290"))
	_ellipse(img, c, Vector2(80, 80), Color("#a7abb6"))
	_rect(img, Rect2i(int(c.x) - 96, int(c.y) - 8, 192, 16), Color("#7d8290"))
	_ellipse(img, c, Vector2(34, 34), Color("#7d8290"))
	_ellipse(img, c, Vector2(20, 20), Color("#b9bcc6"))


func _draw_rug_check(img: Image) -> void:
	var w := img.get_width()
	for y: int in range(12, 84):
		for x: int in range(10, w - 10):
			var check := ((x / 16) + (y / 16)) % 2 == 0
			_px(img, x, y, Color("#4a6aa8") if check else Color("#8fa6d6"))
	_rect(img, Rect2i(10, 12, w - 20, 4), Color("#e8e2d4"))
	_rect(img, Rect2i(10, 80, w - 20, 4), Color("#e8e2d4"))


func _draw_door_side(img: Image) -> void:
	# Porte fermée du mur est, vue en perspective (panneau étroit).
	_poly(img, PackedVector2Array([Vector2(20, 30), Vector2(64, 12), Vector2(64, 186),
		Vector2(20, 176)]), WOOD_DARK)
	_poly(img, PackedVector2Array([Vector2(26, 36), Vector2(58, 22), Vector2(58, 176),
		Vector2(26, 170)]), WOOD)
	_ellipse(img, Vector2(32, 104), Vector2(4, 5), Color("#e8c25a"))


func _draw_stairs_up_side(img: Image) -> void:
	# Escalier qui monte vers le mur du fond, rampe à droite ; les 2 rangées hautes sont
	# les marches (la rangée haute du sprite déborde sur le mur).
	var w := img.get_width()
	var h := img.get_height()
	var steps := 10
	var top := 20
	var step_h := (h - top - 10) / steps
	for s: int in steps:
		var k := float(s) / (steps - 1)
		var tone := WOOD.lightened(0.3 * (1.0 - k)).darkened(0.25 * (1.0 - k))
		var y := top + s * step_h
		_rect(img, Rect2i(10, y, w - 34, step_h), tone)
		_rect(img, Rect2i(10, y + step_h - 3, w - 34, 3), tone.darkened(0.35))
	_rect(img, Rect2i(0, top - 10, 10, h - top), WOOD_DARK)
	_rect(img, Rect2i(w - 24, top - 10, 10, h - top), WOOD_DARK)
	for y: int in range(top + 10, h - 10, 36):
		_rect(img, Rect2i(w - 22, y, 6, 30), WOOD_LIGHT)
	_rect(img, Rect2i(w - 26, top - 16, 14, 10), WOOD_DARK)


func _draw_sofa(img: Image) -> void:
	var w := img.get_width()
	var fabric := Color("#e8dcc0")
	_rect(img, Rect2i(8, 182, w - 16, 8), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(10, 70, w - 20, 60), fabric.darkened(0.12))
	_rect(img, Rect2i(10, 124, w - 20, 60), fabric)
	_rect(img, Rect2i(4, 90, 30, 94), fabric.darkened(0.08))
	_rect(img, Rect2i(w - 34, 90, 30, 94), fabric.darkened(0.08))
	_rect(img, Rect2i(w / 2 - 1, 128, 2, 50), fabric.darkened(0.2))
	_rect(img, Rect2i(50, 96, 46, 36), Color("#3d5294"))
	_rect(img, Rect2i(w - 96, 98, 42, 34), Color("#e8e2d4"))


func _draw_coffee_table(img: Image) -> void:
	var w := img.get_width()
	_box(img, Rect2i(12, 30, w - 24, 60), 36, WOOD)
	_rect(img, Rect2i(36, 36, 44, 18), Color("#e0a93b"))
	_ball(img, Vector2(130, 34), 14, Color("#4f8a3a"))
	_rect(img, Rect2i(122, 40, 16, 14), Color("#b0643a"))


func _draw_coat_rack(img: Image) -> void:
	var h := img.get_height()
	_shadow(img, Vector2(48, h - 8), Vector2(22, 6))
	_rect(img, Rect2i(45, 30, 6, h - 40), WOOD_DARK)
	_rect(img, Rect2i(32, h - 14, 32, 6), WOOD_DARK)
	_rect(img, Rect2i(24, 50, 22, 70), Color("#34495e"))
	_rect(img, Rect2i(52, 54, 20, 60), Color("#4a6aa8"))
	_ellipse(img, Vector2(48, 30), Vector2(26, 10), Color("#c9a36b"))
	_ellipse(img, Vector2(48, 24), Vector2(14, 10), Color("#b58f59"))


func _draw_dresser_pokeball(img: Image) -> void:
	_box(img, Rect2i(10, 70, 76, 120), 22, WOOD)
	for k: int in 3:
		_rect(img, Rect2i(20, 102 + k * 26, 56, 20), WOOD.darkened(0.12))
		_rect(img, Rect2i(44, 110 + k * 26, 8, 3), Color("#e8c25a"))
	_pokeball(img, Vector2(48, 64), 16)


func _draw_front_door(img: Image) -> void:
	# Porte d'entrée dans le mur bas (vue du dessus) : seule la case basse est dessinée,
	# rien au-dessus du tapis de sortie (le joueur s'y tient).
	var y0 := T
	_rect(img, Rect2i(4, y0 + 4, 88, 88), WOOD_DARK)
	_rect(img, Rect2i(12, y0 + 10, 72, 78), WOOD)
	_rect(img, Rect2i(18, y0 + 16, 60, 26), WOOD_LIGHT)
	_rect(img, Rect2i(18, y0 + 50, 60, 30), WOOD_LIGHT)
	_ellipse(img, Vector2(72, y0 + 46), Vector2(4, 4), Color("#e8c25a"))
	_rect(img, Rect2i(4, y0, 88, 4), Color("#f0d7a0"))


func _draw_rug_plaid(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y: int in range(10, h - 10):
		for x: int in range(10, w - 10):
			var band_x := (x / 24) % 2 == 0
			var band_y := (y / 24) % 2 == 0
			var c := Color("#8fa6d6")
			if band_x and band_y:
				c = Color("#4a6aa8")
			elif band_x or band_y:
				c = Color("#6f8cc6")
			_px(img, x, y, c)
	_rect(img, Rect2i(10, 10, w - 20, 5), Color("#e8e2d4"))
	_rect(img, Rect2i(10, h - 15, w - 20, 5), Color("#e8e2d4"))


func _draw_rug_living(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, 8, w - 16, h - 16), Color("#8a7b6d"))
	_rect(img, Rect2i(20, 20, w - 40, h - 40), Color("#b9a98e"))
	_rect(img, Rect2i(34, 34, w - 68, h - 68), Color("#a8977c"))
	for k: int in 6:
		_rect(img, Rect2i(34 + k * 36, h / 2 - 2, 18, 4), Color("#8a7b6d"))


# --- Maison du rival (§4.5) ----------------------------------------------------------

func _draw_range_hood_stove(img: Image) -> void:
	# Cuisinière (case basse) et hotte basse : le haut de la case du mur reste dégagé.
	_rect(img, Rect2i(22, 30, 52, 30), Color("#6f787f"))
	_poly(img, PackedVector2Array([Vector2(14, 60), Vector2(22, 30), Vector2(74, 30),
		Vector2(82, 60)]), Color("#8d969c"))
	_rect(img, Rect2i(40, 0, 16, 30), Color("#6f787f"))
	_box(img, Rect2i(6, 70, 84, 120), 30, Color("#b9c2c9"))
	for x: int in [30, 66]:
		_ellipse(img, Vector2(x, 86), Vector2(12, 7), Color("#2b2f36"))
	_rect(img, Rect2i(18, 118, 60, 50), Color("#2b2f36"))
	_rect(img, Rect2i(24, 124, 48, 30), Color("#4a4f57"))


func _draw_stairs_up_wide(img: Image) -> void:
	# Escalier qui monte vers le mur du fond (décoratif, bloqué), rampe à gauche.
	var w := img.get_width()
	var h := img.get_height()
	var steps := 12
	var step_h := (h - 20) / steps
	for s: int in steps:
		var k := float(s) / (steps - 1)
		var tone := WOOD.lightened(0.25 * (1.0 - k)).darkened(0.2 * (1.0 - k))
		var y := 10 + s * step_h
		_rect(img, Rect2i(26, y, w - 36, step_h), tone)
		_rect(img, Rect2i(26, y + step_h - 3, w - 36, 3), tone.darkened(0.35))
	_rect(img, Rect2i(w - 10, 0, 10, h - 4), WOOD_DARK)
	_rect(img, Rect2i(6, 0, 12, h - 4), WOOD_DARK)
	for y: int in range(16, h - 20, 34):
		_rect(img, Rect2i(8, y, 8, 26), WOOD_LIGHT)
	_rect(img, Rect2i(0, h - 30, 24, 26), WOOD_DARK)
	_rect(img, Rect2i(4, h - 26, 16, 18), WOOD)
	_rect(img, Rect2i(0, h - 6, w, 6), Color(0, 0, 0, 0.25))


func _draw_corner_desk_pc(img: Image) -> void:
	# Bureau en L : plateau le long du mur du fond (rangée haute) et du mur ouest.
	var w := img.get_width()
	_box(img, Rect2i(4, 30, w - 8, 76), 26, WOOD)
	_box(img, Rect2i(4, 96, 86, 94), 26, WOOD)
	_rect(img, Rect2i(8, 34, w - 16, 20), WOOD_LIGHT)
	_rect(img, Rect2i(8, 100, 78, 20), WOOD_LIGHT)
	_rect(img, Rect2i(30, 0, 60, 40), Color("#1f2226"))
	_rect(img, Rect2i(34, 4, 52, 30), Color("#3b8fd6"))
	_rect(img, Rect2i(96, 6, 56, 36), Color("#1f2226"))
	_rect(img, Rect2i(100, 10, 48, 26), Color("#2b2f36"))
	_rect(img, Rect2i(40, 44, 60, 8), Color("#3a3f47"))
	_rect(img, Rect2i(14, 120, 22, 40), Color("#3a3f47"))
	_ellipse(img, Vector2(24, 130), Vector2(4, 4), Color("#6fe0b0"))


func _draw_gamer_chair(img: Image) -> void:
	_shadow(img, Vector2(48, 88), Vector2(30, 7))
	_rect(img, Rect2i(46, 64, 4, 20), Color("#2b2f36"))
	_rect(img, Rect2i(24, 82, 48, 4), Color("#2b2f36"))
	_rect(img, Rect2i(26, 2, 44, 58), Color("#1f2226"))
	_rect(img, Rect2i(30, 6, 36, 50), Color("#2b2f36"))
	_rect(img, Rect2i(44, 6, 8, 50), Color("#c0392b"))
	_rect(img, Rect2i(20, 52, 56, 14), Color("#1f2226"))


func _draw_dresser(img: Image) -> void:
	# Commode basse : la fenêtre au-dessus reste visible.
	var w := img.get_width()
	_box(img, Rect2i(8, 90, w - 16, 100), 20, WOOD)
	for row: int in 2:
		for col: int in 2:
			var r := Rect2i(18 + col * 84, 118 + row * 30, 72, 24)
			_rect(img, r, WOOD.darkened(0.12))
			_rect(img, Rect2i(r.position.x + 30, r.position.y + 10, 12, 3), Color("#e8c25a"))
	_rect(img, Rect2i(30, 70, 26, 24), Color("#f4efe4"))
	_rect(img, Rect2i(34, 74, 18, 16), Color("#8cc3e6"))
	_ball(img, Vector2(w - 50, 80), 14, Color("#4f8a3a"))
	_rect(img, Rect2i(w - 60, 84, 20, 12), Color("#b0643a"))


func _draw_bed_pokeball(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, h - 10, w - 16, 8), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(6, 8, w - 12, 60), WOOD_DARK)
	_rect(img, Rect2i(12, 14, w - 24, 48), WOOD)
	_rect(img, Rect2i(10, 60, w - 20, h - 76), Color("#f2f0ea"))
	_ellipse(img, Vector2(56, 86), Vector2(36, 18), Color("#ffffff"))
	_ellipse(img, Vector2(w - 56, 86), Vector2(36, 18), Color("#ffffff"))
	# Couette Poké Ball : rouge en haut, noir en bas, bande et bouton au centre.
	var top := 116
	_rect(img, Rect2i(10, top, w - 20, 70), Color("#c0392b"))
	_rect(img, Rect2i(10, top + 70, w - 20, h - top - 88), Color("#2b2f36"))
	_rect(img, Rect2i(10, top + 64, w - 20, 12), Color("#1c1c1c"))
	_ellipse(img, Vector2(w / 2.0, top + 70), Vector2(24, 24), Color("#1c1c1c"))
	_ellipse(img, Vector2(w / 2.0, top + 70), Vector2(16, 16), Color("#f4f4f4"))
	_rect(img, Rect2i(6, h - 22, w - 12, 14), WOOD_DARK)


func _draw_nightstand_bag(img: Image) -> void:
	_box(img, Rect2i(10, 104, 76, 86), 20, WOOD)
	_rect(img, Rect2i(20, 140, 56, 4), WOOD_DARK)
	_ellipse(img, Vector2(40, 64), Vector2(34, 34), Color(1.0, 0.85, 0.5, 0.18))
	_rect(img, Rect2i(36, 78, 6, 30), Color("#8a6d2a"))
	_poly(img, PackedVector2Array([Vector2(22, 80), Vector2(30, 52), Vector2(48, 52),
		Vector2(56, 80)]), Color("#f7e2a8"))
	# Sac à dos rouge posé contre le chevet.
	_rect(img, Rect2i(56, 130, 36, 56), Color("#a82e22"))
	_rect(img, Rect2i(60, 134, 28, 18), Color("#c0392b"))
	_rect(img, Rect2i(64, 122, 20, 10), Color("#7a2018"))


func _draw_wall_tv_side(img: Image) -> void:
	# Télé murale vue de côté (mur ouest) sur un meuble bas ; case haute presque vide.
	var h := img.get_height()
	_rect(img, Rect2i(10, 110, 70, h - 116), WOOD_DARK)
	_rect(img, Rect2i(14, 114, 62, h - 128), WOOD_LIGHT)
	_rect(img, Rect2i(6, 70, 14, 160), Color("#1f2226"))
	_rect(img, Rect2i(8, 74, 10, 152), Color("#2e4f8a"))
	_rect(img, Rect2i(40, 150, 26, 18), Color("#3a3f47"))
	_rect(img, Rect2i(40, 210, 26, 34), Color("#e8e2d4"))
	_rect(img, Rect2i(0, h - 8, 86, 6), Color(0, 0, 0, 0.25))


func _draw_shoe_rack(img: Image) -> void:
	_box(img, Rect2i(10, 34, 76, 58), 14, WOOD)
	for k: int in 2:
		_ellipse(img, Vector2(32 + k * 32, 60), Vector2(12, 6), Color("#3a3f47"))
		_ellipse(img, Vector2(32 + k * 32, 78), Vector2(12, 6), Color("#c0392b"))


func _draw_bathroom_sink(img: Image) -> void:
	var w := img.get_width()
	_rect(img, Rect2i(56, 2, 80, 60), Color("#b9c2c9"))
	_rect(img, Rect2i(60, 6, 72, 52), Color("#dfe9f0"))
	_box(img, Rect2i(6, 70, w - 12, 120), 44, Color("#e8e2d4"))
	_ellipse(img, Vector2(w / 2.0, 92), Vector2(38, 14), Color("#b9c2c9"))
	_ellipse(img, Vector2(w / 2.0, 92), Vector2(32, 10), Color("#eef4f7"))
	_rect(img, Rect2i(w / 2 - 3, 70, 6, 14), Color("#8a8f96"))
	for k: int in 2:
		_rect(img, Rect2i(18 + k * 86, 124, 70, 56), Color("#d4cab6"))


func _draw_shower(img: Image) -> void:
	var h := img.get_height()
	_rect(img, Rect2i(4, 96, 88, h - 100), Color("#c9d3da"))
	for y: int in range(100, h - 4, 24):
		_rect(img, Rect2i(4, y, 88, 2), Color("#aab6bf"))
	_rect(img, Rect2i(4, 96, 6, h - 100), Color(0.75, 0.88, 0.95, 0.9))
	_rect(img, Rect2i(60, 100, 6, 40), Color("#8a8f96"))
	_ellipse(img, Vector2(56, 142), Vector2(14, 6), Color("#8a8f96"))
	_rect(img, Rect2i(0, h - 6, 96, 6), Color(0, 0, 0, 0.25))


func _draw_partition(img: Image) -> void:
	# Segment nord-sud vu du dessus, continu d'une case à l'autre : joues sombres, chaperon.
	_rect(img, Rect2i(26, 0, 44, 96), WOOD_DARK)
	_rect(img, Rect2i(30, 0, 36, 96), WOOD)
	_rect(img, Rect2i(36, 0, 24, 96), WOOD_LIGHT)
	_rect(img, Rect2i(70, 0, 6, 96), Color(0, 0, 0, 0.18))


func _draw_partition_h(img: Image) -> void:
	# Segment est-ouest : chaperon en haut, face visible dessous (vue de 3/4).
	_rect(img, Rect2i(0, 30, 96, 60), WOOD_DARK)
	_rect(img, Rect2i(0, 34, 96, 18), WOOD_LIGHT)
	_rect(img, Rect2i(0, 54, 96, 32), WOOD)
	_rect(img, Rect2i(0, 90, 96, 6), Color(0, 0, 0, 0.25))


func _draw_rival_posters(img: Image) -> void:
	# Affiche d'un Pokémon de feu et fanion Poké Ball (rival).
	_rect(img, Rect2i(8, 6, 80, 84), Color("#f4efe4"))
	_rect(img, Rect2i(14, 12, 68, 72), Color("#f2a65a"))
	_ellipse(img, Vector2(48, 50), Vector2(20, 26), Color("#e0632a"))
	_poly(img, PackedVector2Array([Vector2(62, 30), Vector2(78, 16), Vector2(72, 44)]),
		Color("#f5d04a"))
	_rect(img, Rect2i(108, 6, 76, 84), Color("#1c1c1c"))
	_rect(img, Rect2i(112, 10, 68, 76), Color("#a82e22"))
	_pokeball(img, Vector2(146, 48), 24)


func _draw_rug_bath(img: Image) -> void:
	var w := img.get_width()
	_rect(img, Rect2i(16, 20, w - 32, 60), Color("#7d93b8"))
	_rect(img, Rect2i(24, 28, w - 48, 44), Color("#9fb3d6"))


func _draw_rug_bedroom_grey(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, 8, w - 16, h - 16), Color("#4a4f57"))
	_rect(img, Rect2i(20, 20, w - 40, h - 40), Color("#6f747c"))
	_ellipse(img, Vector2(w / 2.0, h / 2.0), Vector2(60, 50), Color("#5b6068"))


func _draw_rug_living_blue(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, 8, w - 16, h - 16), Color("#5a6f96"))
	_rect(img, Rect2i(20, 20, w - 40, h - 40), Color("#8fa0c0"))
	for y: int in range(34, h - 34, 28):
		for x: int in range(34, w - 34, 28):
			_ellipse(img, Vector2(x + 14, y + 14), Vector2(8, 8), Color("#6f84ad"))


# --- Laboratoire (§4.7) --------------------------------------------------------------

func _draw_aquarium(img: Image) -> void:
	_box(img, Rect2i(8, 120, 80, 70), 14, Color("#5b646c"))
	_rect(img, Rect2i(10, 20, 76, 104), Color("#3b4450"))
	_rect(img, Rect2i(14, 24, 68, 96), Color(0.45, 0.75, 0.85, 0.95))
	_rect(img, Rect2i(14, 100, 68, 20), Color("#c9b98e"))
	_ball(img, Vector2(30, 92), 12, Color("#4f8a3a"))
	_ellipse(img, Vector2(58, 60), Vector2(8, 5), Color("#f2a65a"))


func _draw_incubator(img: Image) -> void:
	# Cuve cylindrique lumineuse (incubateur), emblème Poké Ball.
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, h - 10, w - 16, 8), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(16, 24, w - 32, h - 40), Color("#8d969c"))
	_rect(img, Rect2i(28, 60, w - 56, h - 120), Color("#1f3a55"))
	_rect(img, Rect2i(34, 66, w - 68, h - 132), Color(0.35, 0.8, 1.0, 0.55))
	_ellipse(img, Vector2(w / 2.0, 24), Vector2(w / 2.0 - 16, 16), Color("#b9c2c9"))
	_ellipse(img, Vector2(w / 2.0, 24), Vector2(28, 8), Color("#5b646c"))
	_pokeball(img, Vector2(w / 2.0, h / 2.0), 24)
	_rect(img, Rect2i(16, h - 60, w - 32, 44), Color("#6f787f"))
	for k: int in 3:
		_ellipse(img, Vector2(50 + k * 46, h - 38), Vector2(6, 6),
			[Color("#6fe0b0"), Color("#f5d04a"), Color("#e3350d")][k])


func _draw_lab_computers(img: Image) -> void:
	# Machines et ordinateurs : rangée haute presque dégagée (écrans bas).
	var w := img.get_width()
	_box(img, Rect2i(4, 80, w - 8, 110), 22, Color("#8d969c"))
	for k: int in 2:
		var x := 14 + k * 90
		_rect(img, Rect2i(x, 40, 72, 48), Color("#2b2f36"))
		_rect(img, Rect2i(x + 4, 44, 64, 38), Color("#5fa3d6") if k == 0 else Color("#1f2a33"))
		if k == 1:
			for r: int in 3:
				_rect(img, Rect2i(x + 10, 50 + r * 10, _rng.randi_range(20, 50), 3),
					Color("#6fe0b0"))
	for k: int in 4:
		_rect(img, Rect2i(16 + k * 44, 118, 36, 60), Color("#6f787f"))
		_ellipse(img, Vector2(34 + k * 44, 130), Vector2(4, 4), Color("#6fe0b0"))


func _draw_oak_desk(img: Image) -> void:
	# Bureau de Chen : écran bas au centre, la fenêtre derrière reste lisible.
	var w := img.get_width()
	_box(img, Rect2i(6, 96, w - 12, 94), 30, Color("#b98a52"))
	_rect(img, Rect2i(w / 2 - 38, 50, 76, 50), Color("#2b2f36"))
	_rect(img, Rect2i(w / 2 - 32, 56, 64, 36), Color("#8fc3e8"))
	_rect(img, Rect2i(w / 2 - 44, 104, 88, 12), Color("#d8d8d8"))
	_rect(img, Rect2i(20, 100, 60, 18), Color("#f4f4f4"))
	_rect(img, Rect2i(28, 96, 60, 18), Color("#efe6c8"))
	_books(img, Rect2i(w - 90, 70, 70, 36))
	for x: int in [16, w - 76]:
		_rect(img, Rect2i(x, 136, 60, 40), Color("#a07443"))


func _draw_file_cabinet(img: Image) -> void:
	_box(img, Rect2i(10, 70, 76, 120), 16, Color("#6f787f"))
	for k: int in 3:
		_rect(img, Rect2i(18, 94 + k * 30, 60, 24), Color("#8d969c"))
		_rect(img, Rect2i(40, 104 + k * 30, 16, 3), Color("#3a3f47"))
	_rect(img, Rect2i(18, 52, 26, 22), Color("#e0a93b"))
	_rect(img, Rect2i(50, 56, 28, 18), Color("#f4efe4"))


func _draw_display_case(img: Image) -> void:
	# Vitrine vue de côté (mur est) : étagères de Poké Balls.
	var h := img.get_height()
	_rect(img, Rect2i(10, 14, 78, h - 20), Color("#5b646c"))
	_rect(img, Rect2i(16, 20, 66, h - 32), Color(0.75, 0.88, 0.95, 0.9))
	for row: int in 4:
		var y := 80 + row * 56
		_rect(img, Rect2i(16, y, 66, 5), Color("#8d969c"))
		_pokeball(img, Vector2(36, y - 14), 11)
		_pokeball(img, Vector2(62, y - 14), 11)
	_rect(img, Rect2i(4, h - 8, 90, 6), Color(0, 0, 0, 0.25))


func _draw_long_counter(img: Image) -> void:
	var w := img.get_width()
	_box(img, Rect2i(4, 64, w - 8, 126), 40, WOOD)
	_rect(img, Rect2i(8, 68, w - 16, 30), WOOD_LIGHT)
	_rect(img, Rect2i(180, 20, 90, 64), Color("#2b2f36"))
	_rect(img, Rect2i(186, 26, 78, 50), Color("#1f2a33"))
	_rect(img, Rect2i(192, 50, 66, 3), Color("#6fe0b0"))
	_rect(img, Rect2i(216, 84, 18, 10), Color("#2b2f36"))
	_pokeball(img, Vector2(340, 76), 14)
	_books(img, Rect2i(14, 118, w - 28, 62))


func _draw_sofa_side(img: Image) -> void:
	# Canapé bleu vu de côté, dossier contre le mur ouest.
	var h := img.get_height()
	var fabric := Color("#3d5294")
	_rect(img, Rect2i(8, h - 8, 80, 6), Color(0, 0, 0, 0.25))
	_rect(img, Rect2i(8, 10, 30, h - 18), fabric.darkened(0.2))
	_rect(img, Rect2i(34, 22, 52, h - 32), fabric)
	_rect(img, Rect2i(30, 6, 58, 20), fabric.darkened(0.1))
	_rect(img, Rect2i(30, h - 26, 58, 20), fabric.darkened(0.1))
	_rect(img, Rect2i(36, h / 2 - 1, 48, 2), fabric.darkened(0.3))


func _draw_stool(img: Image) -> void:
	_shadow(img, Vector2(48, 88), Vector2(24, 6))
	_rect(img, Rect2i(45, 44, 6, 38), Color("#3a3f47"))
	_rect(img, Rect2i(30, 80, 36, 4), Color("#3a3f47"))
	_ellipse(img, Vector2(48, 40), Vector2(24, 12), Color("#4a4f57"))
	_ellipse(img, Vector2(48, 37), Vector2(20, 9), Color("#6f747c"))


func _draw_wall_screen_side(img: Image) -> void:
	# Grand écran mural vu de côté (mur est), sur un meuble bas.
	var h := img.get_height()
	_rect(img, Rect2i(10, 120, 70, h - 126), WOOD_DARK)
	_rect(img, Rect2i(14, 124, 62, h - 138), WOOD_LIGHT)
	_rect(img, Rect2i(76, 40, 16, 180), Color("#1f2226"))
	_rect(img, Rect2i(78, 44, 12, 172), Color("#5fa3d6"))
	_rect(img, Rect2i(24, 150, 30, 40), Color("#f4efe4"))
	_rect(img, Rect2i(0, h - 8, 90, 6), Color(0, 0, 0, 0.25))


func _draw_stairs_deco(img: Image) -> void:
	# Escalier qui descend (décoratif, bloqué) avec rampe en bois et cadres au mur.
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(0, 0, w, 30), WOOD_DARK)
	_rect(img, Rect2i(4, 4, w - 8, 22), WOOD)
	for k: int in 3:
		_rect(img, Rect2i(40 + k * 60, 6, 30, 18), Color("#f4efe4"))
	var steps := 7
	var step_h := (h - 40) / steps
	for s: int in steps:
		var k := float(s) / (steps - 1)
		var tone := WOOD.darkened(0.15 + 0.45 * k)
		var y := 34 + s * step_h
		_rect(img, Rect2i(40, y, w - 44, step_h), tone)
		_rect(img, Rect2i(40, y + step_h - 3, w - 44, 3), tone.darkened(0.3))
	_poly(img, PackedVector2Array([Vector2(24, 34), Vector2(40, 34), Vector2(w - 20, h - 6),
		Vector2(w - 40, h - 6)]), WOOD_DARK)
	_rect(img, Rect2i(10, 30, 20, h - 30), WOOD_DARK)


func _draw_pokemon_poster(img: Image) -> void:
	_rect(img, Rect2i(12, 6, 72, 84), Color("#f4efe4"))
	_rect(img, Rect2i(18, 12, 60, 72), Color("#efe6c8"))
	_pokeball(img, Vector2(48, 58), 18)
	_ellipse(img, Vector2(32, 26), Vector2(9, 8), Color("#8fbf6a"))
	_ellipse(img, Vector2(64, 26), Vector2(9, 8), Color("#f2a65a"))


func _draw_lab_doorway(img: Image) -> void:
	# Ouverture de l'entrée dans le mur bas : seuil clair et portes vitrées ouvertes.
	var w := img.get_width()
	_rect(img, Rect2i(0, 0, w, 96), Color("#3b4450"))
	_rect(img, Rect2i(8, 6, w - 16, 90), Color("#e6e2d8"))
	for y: int in range(20, 96, 18):
		_rect(img, Rect2i(8, y, w - 16, 3), Color("#c9c4b8"))
	_rect(img, Rect2i(8, 6, 18, 90), Color(0.62, 0.82, 0.9, 0.9))
	_rect(img, Rect2i(w - 26, 6, 18, 90), Color(0.62, 0.82, 0.9, 0.9))
	_rect(img, Rect2i(8, 0, w - 16, 6), Color("#f0d7a0"))


func _draw_rug_red(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, Rect2i(8, 8, w - 16, h - 16), Color("#7a2a22"))
	_rect(img, Rect2i(20, 20, w - 40, h - 40), Color("#a8453a"))
	for y: int in range(30, h - 30, 22):
		_rect(img, Rect2i(30, y, w - 60, 2), Color("#8e3a30"))


func _draw_starter_table(img: Image) -> void:
	# Table des starters (3 × 2, entièrement solide) : trois Poké Balls sur des socles.
	var w := img.get_width()
	var h := img.get_height()
	_box(img, Rect2i(6, 20, w - 12, h - 24), 96, Color("#c9ccc9"))
	for k: int in 3:
		var c := Vector2(58 + k * 90, 70)
		_rect(img, Rect2i(int(c.x) - 30, int(c.y) - 20, 60, 44), Color("#9aa0a6"))
		_ellipse(img, c + Vector2(0, 14), Vector2(22, 7), Color(0, 0, 0, 0.2))
		_pokeball(img, c, 18)
	_rect(img, Rect2i(20, 136, 70, 36), Color("#6f787f"))
	_rect(img, Rect2i(w - 90, 136, 70, 36), Color("#6f787f"))
	_rect(img, Rect2i(110, 136, 68, 36), Color("#a07443"))


func _draw_lab_bench(img: Image) -> void:
	# Paillasse : microscope, terrarium, fioles.
	var w := img.get_width()
	_box(img, Rect2i(4, 70, w - 8, 120), 40, Color("#e8ecee"))
	_rect(img, Rect2i(40, 40, 16, 50), Color("#3a3f47"))
	_rect(img, Rect2i(30, 84, 36, 10), Color("#3a3f47"))
	_rect(img, Rect2i(52, 30, 20, 12), Color("#3a3f47"))
	_rect(img, Rect2i(110, 36, 70, 56), Color(0.7, 0.88, 0.8, 0.85))
	_ball(img, Vector2(145, 76), 16, Color("#4f8a3a"))
	for k: int in 3:
		var x := 206 + k * 22
		_rect(img, Rect2i(x, 64, 12, 28), Color(0.6, 0.85, 0.95, 0.8))
		_rect(img, Rect2i(x, 80, 12, 12), [Color("#6fe0b0"), Color("#e07a5f"),
			Color("#8fb6f2")][k])


func _draw_breakfast(img: Image) -> void:
	# Même cadre que dining_table : plateau de la table entre y 36 et y 124 environ.
	var cx := img.get_width() / 2.0
	# Set de table et assiette : pain grillé et œuf.
	_rect(img, Rect2i(int(cx) - 58, 58, 116, 50), Color("#e8d7b0"))
	_ellipse(img, Vector2(cx - 20, 83), Vector2(24, 15), Color("#f4f4f4"))
	_ellipse(img, Vector2(cx - 20, 83), Vector2(18, 11), Color("#e6e6e6"))
	_rect(img, Rect2i(int(cx) - 34, 74, 16, 14), Color("#d9a35a"))
	_rect(img, Rect2i(int(cx) - 32, 76, 12, 10), Color("#e8bf78"))
	_ellipse(img, Vector2(cx - 12, 84), Vector2(7, 6), Color("#fbfbf2"))
	_ellipse(img, Vector2(cx - 12, 84), Vector2(3, 3), Color("#f2b632"))
	# Bol de céréales.
	_ellipse(img, Vector2(cx + 20, 80), Vector2(13, 9), Color("#5a8fc0"))
	_ellipse(img, Vector2(cx + 20, 78), Vector2(10, 6), Color("#f2e6c8"))
	for k: int in 5:
		_rect(img, Rect2i(int(cx) + 13 + k * 3, 76 + (k % 2) * 2, 2, 2), Color("#c98a3a"))
	# Tasse fumante et verre de jus.
	_rect(img, Rect2i(int(cx) + 38, 70, 12, 14), Color("#f4f4f4"))
	_rect(img, Rect2i(int(cx) + 50, 73, 4, 7), Color("#f4f4f4"))
	_rect(img, Rect2i(int(cx) + 40, 71, 8, 3), Color("#6b4a2a"))
	for k: int in 3:
		_rect(img, Rect2i(int(cx) + 40 + k * 3, 58 - (k % 2) * 3, 2, 8), Color(1, 1, 1, 0.55))
	_rect(img, Rect2i(int(cx) - 54, 66, 9, 18), Color(0.95, 0.65, 0.2, 0.9))
	_rect(img, Rect2i(int(cx) - 54, 66, 9, 3), Color(1, 1, 1, 0.6))


func _draw_bed_items(img: Image) -> void:
	# Cadre : les deux cases du bas du lit (couette Poké Ball à partir de y 20).
	var w := img.get_width()
	# Carte de Kanto dépliée, plis visibles, villes entourées au crayon.
	var map := Rect2i(14, 34, 104, 76)
	_rect(img, Rect2i(map.position.x + 3, map.position.y + 4, map.size.x, map.size.y),
		Color(0, 0, 0, 0.25))
	_rect(img, map, Color("#efe4c4"))
	_rect(img, Rect2i(map.position.x + 4, map.position.y + 4, map.size.x - 8,
		map.size.y - 8), Color("#8fc3de"))
	_ellipse(img, Vector2(54, 70), Vector2(34, 22), Color("#9cc97a"))
	_ellipse(img, Vector2(86, 58), Vector2(20, 14), Color("#b5d38a"))
	_ellipse(img, Vector2(40, 90), Vector2(14, 8), Color("#9cc97a"))
	for x: int in [48, 83]:
		_rect(img, Rect2i(x, map.position.y, 1, map.size.y), Color("#c9b98f"))
	_rect(img, Rect2i(map.position.x, 72, map.size.x, 1), Color("#c9b98f"))
	for p: Vector2 in [Vector2(40, 86), Vector2(58, 64), Vector2(90, 54)]:
		_ellipse(img, p, Vector2(4, 4), Color("#5a4636"))
		_ellipse(img, p, Vector2(3, 3), Color("#9cc97a"))
		_ellipse(img, p, Vector2(1.5, 1.5), Color("#c0392b"))
	# Crayon posé sur la carte.
	_rect(img, Rect2i(62, 98, 30, 4), Color("#e0a93b"))
	_rect(img, Rect2i(92, 98, 5, 4), Color("#3a2a1e"))
	# Sac à dos ouvert, rabat relevé, affaires qui dépassent.
	var bag := Rect2i(124, 66, 52, 58)
	_ellipse(img, Vector2(152, 128), Vector2(30, 6), Color(0, 0, 0, 0.25))
	_rect(img, bag, Color("#2e7d4f"))
	_rect(img, Rect2i(bag.position.x + 6, bag.position.y + 28, bag.size.x - 12, 22),
		Color("#256842"))
	_rect(img, Rect2i(bag.position.x + 4, bag.position.y - 22, bag.size.x - 8, 20),
		Color("#3b9a63"))
	_rect(img, Rect2i(bag.position.x + 4, bag.position.y, bag.size.x - 8, 6),
		Color("#1c3f2a"))
	_rect(img, Rect2i(136, 58, 10, 14), Color("#f4f4f4"))
	_rect(img, Rect2i(150, 56, 14, 12), Color("#c0392b"))
	_pokeball(img, Vector2(162, 64), 6)
	# Affaires posées à côté : gourde, jumelles.
	_rect(img, Rect2i(w - 30, 130, 10, 26), Color("#8fb6f2"))
	_rect(img, Rect2i(w - 29, 126, 8, 5), Color("#3a3f47"))
	_ellipse(img, Vector2(40, 140), Vector2(8, 8), Color("#2b2f36"))
	_ellipse(img, Vector2(58, 140), Vector2(8, 8), Color("#2b2f36"))
	_rect(img, Rect2i(40, 136, 18, 6), Color("#3a3f47"))
	_ellipse(img, Vector2(40, 140), Vector2(4, 4), Color("#6fa6c9"))
	_ellipse(img, Vector2(58, 140), Vector2(4, 4), Color("#6fa6c9"))
