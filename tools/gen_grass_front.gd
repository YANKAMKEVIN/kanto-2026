extends SceneTree
## Génère la bande d'herbe provisoire dessinée devant les jambes du joueur dans les hautes
## herbes (jalon 5 §3.5). NEAREST, dimensions finales.
##
##   godot --headless --path . -s res://tools/gen_grass_front.gd

const OUT_PATH := "res://assets/sprites/characters/placeholder/grass_front.png"
const W := 96
const H := 40
const DARK := Color(0.13, 0.35, 0.15, 1.0)
const MID := Color(0.20, 0.48, 0.22, 1.0)
const LIGHT := Color(0.32, 0.62, 0.30, 1.0)


func _init() -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var shades: Array[Color] = [DARK, MID, LIGHT]
	# Touffes de brins : colonnes verticales de hauteur variable, montant du bas.
	for x: int in W:
		if x % 3 != 0:
			continue
		var blade_h := rng.randi_range(H / 2, H - 2)
		var shade: Color = shades[rng.randi_range(0, 2)]
		var lean := rng.randi_range(-1, 1)
		for y: int in range(H - blade_h, H):
			var bx := clampi(x + lean * (H - y) / 12, 0, W - 1)
			img.set_pixel(bx, y, shade)
			if bx + 1 < W:
				img.set_pixel(bx + 1, y, shade.darkened(0.1))
	img.save_png(ProjectSettings.globalize_path(OUT_PATH))
	print("grass_front : ", OUT_PATH)
	quit()
