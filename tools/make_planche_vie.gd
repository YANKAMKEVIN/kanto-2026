extends SceneTree
## Assemble les captures de `build/captures/j18_vie/` en une planche 3 colonnes (imagettes 780 × 360).
func _init() -> void:
	var dir := "res://build/captures/j18_vie/"
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".png") and f != "J18_VIE_PLANCHE.png":
			names.append(f)
	names.sort()
	var rows := ceili(names.size() / 3.0)
	var sheet := Image.create(780 * 3, 360 * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.08, 0.1))
	for i: int in names.size():
		var img := Image.load_from_file(ProjectSettings.globalize_path(dir + names[i]))
		img.resize(780, 360, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, 780, 360), Vector2i((i % 3) * 780, (i / 3) * 360))
		print(i, " ", names[i])
	sheet.save_png(ProjectSettings.globalize_path(dir + "J18_VIE_PLANCHE.png"))
	quit()
