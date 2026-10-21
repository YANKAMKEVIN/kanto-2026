extends SceneTree
## Bruit de brume provisoire (512 px, se répète sans couture) de MistLayer, jalon 19 T19 :
##   godot --headless --path . -s res://tools/gen_mist_texture.gd
## Écrit `assets/world/mist_noise_01.png` (niveaux de gris). À remplacer par l'art du lot DA.

func _init() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 1950
	noise.frequency = 0.012
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	var image := noise.get_seamless_image(512, 512, false, false, 0.2)
	# Étale le contraste sur 0..1 (le bruit lissé reste autour du gris moyen).
	var low := 1.0
	var high := 0.0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var v := image.get_pixel(x, y).r
			low = minf(low, v)
			high = maxf(high, v)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var v := (image.get_pixel(x, y).r - low) / maxf(high - low, 0.001)
			image.set_pixel(x, y, Color(v, v, v, 1.0))
	image.convert(Image.FORMAT_L8)
	var code := image.save_png("res://assets/world/mist_noise_01.png")
	print("mist_noise_01.png : %s" % error_string(code))
	quit(0 if code == OK else 1)
