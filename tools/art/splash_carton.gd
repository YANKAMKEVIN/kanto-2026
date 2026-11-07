extends SceneTree
## Capture du carton de l'ident, rendu par la vraie [IdentSequence] à 1920 × 1080.
##
##   godot --path . -s res://tools/art/splash_carton.gd

const OUT := "res://assets/ui/opening/splash_carton.png"
const SIZE := Vector2i(1920, 1080)

var _viewport: SubViewport
var _frames: int = 0


func _init() -> void:
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var texts: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/opening/title.json"))["ident"]
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var ident := IdentSequence.new()
	ident.set_texts(texts["studio"], texts["presents"])
	_viewport.add_child(ident)
	process_frame.connect(_capture)


func _capture() -> void:
	_frames += 1
	if _frames < 10:
		return
	process_frame.disconnect(_capture)
	var image := _viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var err := image.save_png(ProjectSettings.globalize_path(OUT))
	print("Carton : %s (%d)" % [OUT, err])
	quit(err)
