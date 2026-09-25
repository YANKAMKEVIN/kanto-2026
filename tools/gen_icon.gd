extends SceneTree
## Génère l'icône provisoire (Poké Ball stylisée) : res://assets/ui/icon.png

func _init() -> void:
	var size := 512
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	var bg := Color("#1A2433")
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var col := bg
			if d < 200.0:
				col = Color("#E3350D") if p.y < c.y else Color("#F4F4F4")
				if absf(p.y - c.y) < 16.0 or d > 186.0:
					col = Color("#1C1C1C")
				if d < 62.0:
					col = Color("#1C1C1C")
				if d < 44.0:
					col = Color("#F5C542")
			img.set_pixel(x, y, col)
	img.save_png("res://assets/ui/icon.png")
	print("icon OK")
	quit()
