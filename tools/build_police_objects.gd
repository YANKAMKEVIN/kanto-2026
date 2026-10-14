extends SceneTree
## Objets de police d'Azuria (jalon 14 T20b, jalon-14.md §2.12) : le ruban de la porte
## cambriolée et les deux barrières du barrage sud, en **objets fixes** (`"sprite": "object/<id>"`,
## une image pour les quatre orientations) dessinés à partir des images de la série 15 :
##   - `police_tape`    = `prop_ruban_01` entière (192 × 77), sur la case de la porte ;
##   - `police_barrier` / `police_barrier_e` = moitiés gauche et droite de la barrière à croisillon
##     (`prop_barriere_croisillon_01`, 192 × 108 : défaut T1, « police_barrier » n'a jamais été
##     générée), une par case, qui se rejoignent sur les deux cases (32..33, 38).
## Deux passes comme les autres outils : les PNG sont écrits, puis (après `--import`) les
## `SpriteFrames` ; relancer l'outil jusqu'à « OK ».
##
##   godot --headless --path . -s res://tools/build_police_objects.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_police_objects.gd

const OUT_DIR := "res://assets/sprites/objects/painted/"
const TAPE_SOURCE := "res://assets/world/props/prop_ruban_01.png"
const BARRIER_SOURCE := "res://assets/world/props/prop_barriere_croisillon_01.png"
const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]


func _init() -> void:
	var tape := Image.load_from_file(ProjectSettings.globalize_path(TAPE_SOURCE))
	var barrier := Image.load_from_file(ProjectSettings.globalize_path(BARRIER_SOURCE))
	if tape == null or barrier == null:
		push_error("build_police_objects : images de la série 15 introuvables")
		quit(1)
		return
	var half := barrier.get_width() / 2
	var parts: Dictionary = {
		"police_tape": tape,
		"police_barrier": barrier.get_region(Rect2i(0, 0, half, barrier.get_height())),
		"police_barrier_e": barrier.get_region(
			Rect2i(half, 0, barrier.get_width() - half, barrier.get_height())),
	}
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
		print("build_police_objects : PNG écrits ; importer (--import) puis relancer l'outil")
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
			push_error("build_police_objects : %s non écrit" % id)
			quit(1)
			return
	print("build_police_objects : OK")
	quit(0)
