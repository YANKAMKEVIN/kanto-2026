extends SceneTree
## Objets **provisoires** des vraies cartes du jalon 16 (T11), dessinés en code, en attendant l'art
## de la série 18 (T10) : `electric_barrier` (un segment de la barrière électrique de l'Arène de
## Carmin, 96 × 112 ; trois côte à côte font la barrière de (7..9, 5)), objet fixe
## (`"sprite": "object/electric_barrier"`, une image pour les quatre orientations). Au T10,
## l'image de la série remplace celle-ci sous le **même identifiant** (rien à changer dans les
## données). Deux passes comme `build_qa_objects_j16.gd` : PNG, `--import`, puis `SpriteFrames`.
##
##   godot --headless --path . -s res://tools/build_provisional_objects_j16.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_provisional_objects_j16.gd

const OUT_DIR := "res://assets/sprites/objects/painted/"
const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]


func _init() -> void:
	var parts: Dictionary = {"electric_barrier": _barrier()}
	var pending := false
	for id: String in parts:
		var path := OUT_DIR + id + ".png"
		var absolute := ProjectSettings.globalize_path(path)
		var image: Image = parts[id]
		var old := Image.load_from_file(absolute) if FileAccess.file_exists(absolute) else null
		if old == null or old.get_data() != image.get_data():
			image.save_png(absolute)
			pending = true
		if not ResourceLoader.exists(path):
			pending = true
	if pending:
		print("build_provisional_objects_j16 : PNG écrits ; importer (--import) puis relancer")
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
			push_error("build_provisional_objects_j16 : %s non écrit" % id)
			quit(1)
			return
	print("build_provisional_objects_j16 : OK")
	quit(0)


## Champ d'énergie bleu translucide sur toute la largeur de la case (continu d'un segment au
## suivant), arcs clairs ondulés, socle émetteur sombre en bas.
func _barrier() -> Image:
	var image := Image.create(96, 112, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y: int in range(20, 100):
		var t := float(y - 20) / 80.0
		for x: int in 96:
			image.set_pixel(x, y, Color(0.3, 0.65, 1.0, lerpf(0.25, 0.55, t)))
	for arc: int in 4:
		var base_y := 32.0 + arc * 17.0
		for x: int in 96:
			var y := int(roundf(base_y + sin((x + arc * 23) * TAU / 48.0) * 5.0))
			for dy: int in range(-1, 2):
				var alpha := 0.95 if dy == 0 else 0.55
				image.set_pixel(x, y + dy, Color(0.85, 0.97, 1.0, alpha))
	image.fill_rect(Rect2i(0, 98, 96, 12), Color(0.16, 0.2, 0.28))
	image.fill_rect(Rect2i(0, 100, 96, 3), Color(0.5, 0.85, 1.0))
	return image
