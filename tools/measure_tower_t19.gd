extends SceneTree
## Mesures de luminance des captures du T19 (jalon 19) :
##   godot --headless --path . -s res://tools/measure_tower_t19.gd -- --dir=build/captures/jalon19_t19
## Luminance moyenne (0-255), part de pixels clairs (> 235) et sombres (< 25), image entière.

func _init() -> void:
	var dir: String = "build/captures/jalon19_t19"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.trim_prefix("--dir=")
	var files: PackedStringArray = DirAccess.get_files_at(dir)
	files.sort()
	for f: String in files:
		if not f.ends_with(".png"):
			continue
		var img: Image = Image.load_from_file("%s/%s" % [dir, f])
		var sum: float = 0.0
		var hi: int = 0
		var lo: int = 0
		var n: int = img.get_width() * img.get_height()
		for y: int in img.get_height():
			for x: int in img.get_width():
				var l: float = img.get_pixel(x, y).get_luminance() * 255.0
				sum += l
				hi += 1 if l > 235.0 else 0
				lo += 1 if l < 25.0 else 0
		print("MESURE %s moy=%.1f clair=%.2f%% sombre=%.1f%%" % [f, sum / n, 100.0 * hi / n, 100.0 * lo / n])
	quit()
