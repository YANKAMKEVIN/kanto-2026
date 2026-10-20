extends SceneTree
## Capture des six personnages de la série 22 (J20 T10) à l'échelle du jeu, 1:1, sur fond neutre.
##   godot --path . --resolution 2340x1080 -s res://tools/capture_serie22_pnj.gd -- --out=<dossier>

const LOOKS: Array[String] = [
	"erika", "giovanni", "rocket_civilian", "nerd", "beauty", "cooltrainer_f", "misty"]
const DIRS: Array[String] = ["down", "left", "right", "up"]
const DIR = "res://assets/sprites/characters/painted/"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var out := "build/captures/j20_t10"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var bg := ColorRect.new()
	bg.color = Color(0.62, 0.72, 0.45)
	bg.size = Vector2(2340, 1080)
	root.add_child(bg)
	for i in LOOKS.size():
		var frames := load(DIR + LOOKS[i] + "_frames.tres") as SpriteFrames
		for j in DIRS.size():
			for k in 2:
				var s := AnimatedSprite2D.new()
				s.sprite_frames = frames
				s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				s.position = Vector2(180 + i * 300 + j * 0 + k * 0, 220 + (j * 2 + k) * 0)
				s.position = Vector2(150 + i * 300, 200 + j * 250 + k * 0)
				s.animation = StringName(("idle_" if k == 1 else "walk_") + DIRS[j])
				s.centered = true
				s.offset = Vector2(0, -64)
				root.add_child(s)
				if k == 0:
					s.position.x -= 0
				else:
					s.position.x += 90
				s.play()
	for _f in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/serie22_pnj.png")
	print("CAPTURE ", out, "/serie22_pnj.png")
	quit()
