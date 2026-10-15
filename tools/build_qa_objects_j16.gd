extends SceneTree
## Objets **provisoires** des cartes de QA du jalon 16 (T16), dessinés en code (aucune image de
## série) : `qa_cut_tree` (l'arbuste à couper, 96 × 104) et `qa_barrier` (un pilier de la barrière
## électrique, 96 × 112), en objets fixes (`"sprite": "object/<id>"`, une image pour les quatre
## orientations). Remplacés par l'art de la série 18 sur les vraies cartes ; **retirés au T20**.
## Deux passes comme `build_police_objects.gd` : PNG, `--import`, puis `SpriteFrames`.
##
##   godot --headless --path . -s res://tools/build_qa_objects_j16.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_qa_objects_j16.gd

const OUT_DIR := "res://assets/sprites/objects/painted/"
const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]


func _init() -> void:
	var parts: Dictionary = {"qa_cut_tree": _tree(), "qa_barrier": _barrier()}
	var pending := false
	for id: String in parts:
		var path := OUT_DIR + id + ".png"
		var absolute := ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
		var image: Image = parts[id]
		var old := Image.load_from_file(absolute) if FileAccess.file_exists(absolute) else null
		if old == null or old.get_data() != image.get_data():
			image.save_png(absolute)
			pending = true
		if not ResourceLoader.exists(path):
			pending = true
	if pending:
		print("build_qa_objects_j16 : PNG écrits ; importer (--import) puis relancer l'outil")
		quit(2)
		return
	for id: String in parts:
		var texture := load(OUT_DIR + id + ".png") as Texture2D
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		for dir: String in DIRECTIONS:
			var idle := StringName("idle_" + dir)
			frames.add_animation(idle)
			frames.set_animation_loop(idle, true)
			frames.set_animation_speed(idle, 1.0)
			frames.add_frame(idle, texture)
		if ResourceSaver.save(frames, OUT_DIR + id + "_frames.tres") != OK:
			push_error("build_qa_objects_j16 : %s non écrit" % id)
			quit(1)
			return
	print("build_qa_objects_j16 : OK")
	quit(0)


## Arbuste : tronc court, feuillage en trois disques, contour sombre.
func _tree() -> Image:
	var image := Image.create(96, 104, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(42, 74, 12, 28), Color(0.36, 0.24, 0.14))
	var dark := Color(0.12, 0.3, 0.14)
	var leaf := Color(0.27, 0.56, 0.24)
	for disc: Array in [[Vector2(48, 44), 34.0], [Vector2(30, 60), 22.0], [Vector2(66, 60), 22.0]]:
		_disc(image, disc[0], disc[1] + 3.0, dark)
	for disc: Array in [[Vector2(48, 44), 34.0], [Vector2(30, 60), 22.0], [Vector2(66, 60), 22.0]]:
		_disc(image, disc[0], disc[1], leaf)
	_disc(image, Vector2(40, 34), 10.0, Color(0.42, 0.7, 0.34))
	return image


## Pilier de barrière : bandes jaunes et noires, éclair clair au sommet.
func _barrier() -> Image:
	var image := Image.create(96, 112, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y: int in range(16, 112):
		for x: int in range(30, 66):
			var stripe := ((x + y) / 12) % 2 == 0
			image.set_pixel(x, y, Color(0.98, 0.84, 0.15) if stripe else Color(0.1, 0.1, 0.12))
	_disc(image, Vector2(48, 14), 13.0, Color(0.6, 0.9, 1.0, 0.9))
	_disc(image, Vector2(48, 14), 7.0, Color(1, 1, 1))
	return image


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)


func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	for y: int in range(maxi(0, int(center.y - radius)), mini(image.get_height(),
			int(center.y + radius) + 1)):
		for x: int in range(maxi(0, int(center.x - radius)), mini(image.get_width(),
				int(center.x + radius) + 1)):
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
