extends SceneTree
## Capture de contrôle : l'illustration de Kanto avec chaque rectangle de zone et son identifiant,
## rendue dans un SubViewport 1586x992 et sauvée en PNG (non versionné, build/).
## godot --path . -s res://tools/kanto_zones_overlay.gd   (pas en --headless : il faut un rendu)

const OUT := "res://build/captures/jalon06_t19/kanto_zones_overlay.png"

var _vp: SubViewport
var _frames := 0


class Overlay extends Control:
	var zones: Dictionary
	## Genre de chaque zone (data/world/zones.json : l'identité des zones vit là).
	var kinds: Dictionary

	func _draw() -> void:
		var colors := {"town": Color.RED, "route": Color.YELLOW, "place": Color.MAGENTA,
				"sea_route": Color.CYAN}
		var font := ThemeDB.fallback_font
		for id: String in zones:
			var a: Array = zones[id]["area"]
			var c: Color = colors.get(kinds.get(id, ""), Color.WHITE)
			var r := Rect2(a[0], a[1], a[2], a[3])
			draw_rect(r, Color(c, 0.18), true)
			draw_rect(r, c, false, 3.0)
			var p := r.position + Vector2(3, -4)
			draw_string_outline(font, p, id, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.BLACK)
			draw_string(font, p, id, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


func _init() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://assets/ui/map/kanto_placeholder_areas.json"))
	_vp = SubViewport.new()
	_vp.size = Vector2i(1586, 992)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var tex := TextureRect.new()
	tex.texture = load("res://assets/ui/map/kanto_placeholder.webp")
	_vp.add_child(tex)
	var ov := Overlay.new()
	ov.zones = doc["zones"]
	var zones_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/world/zones.json"))
	for id: String in zones_doc["zones"]:
		ov.kinds[id] = zones_doc["zones"][id]["kind"]
	_vp.add_child(ov)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frames += 1
	if _frames < 5:
		return
	var img := _vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/captures/jalon06_t19"))
	print("overlay: ", img.get_size(), " ", img.save_png(OUT))
	quit()
