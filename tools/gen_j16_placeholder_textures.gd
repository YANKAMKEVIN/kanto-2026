extends SceneTree
## Textures **provisoires** des cartes du jalon 16 (T11 : S.S. Anne et Arène de Carmin), dessinées
## en code (API `Image`), en attendant l'art de la série 18 (T10). Petites textures **répétées**
## (`texture_repeat`) sous les polygones du décor provisoire (`tools/j16_placeholder_decor.gd`) :
## quelques centaines de Ko au total au lieu d'une enveloppe peinte de plusieurs Mo par pièce.
##   - `prov_parquet_01.png`  (192 × 192) : parquet chaud du navire (lames de 32 px décalées) ;
##   - `prov_tole_01.png`     (192 × 192) : dalles d'acier rivetées de l'Arène (une dalle par case) ;
##   - `prov_moquette_01.png` ( 96 ×  96) : moquette rouge du restaurant et des cabines.
## Le pont extérieur reprend les planches du quai (`ground_planches_quai_01`) et la mer de Bourg
## Palette (`ground_eau_01`).
##
##   godot --headless --path . -s res://tools/gen_j16_placeholder_textures.gd
##   godot --headless --path . --import

const OUT_DIR := "res://assets/world/interiors/provisoire/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var images := {"prov_parquet_01": _parquet(), "prov_tole_01": _steel(),
		"prov_moquette_01": _carpet()}
	for id: String in images:
		var path := ProjectSettings.globalize_path(OUT_DIR + id + ".png")
		var err := (images[id] as Image).save_png(path)
		print("%s : %s" % [id, error_string(err)])
	quit(0)


## Lames horizontales de 32 px, joints décalés, veinure légère (bruit de valeur à graine fixe).
func _parquet() -> Image:
	var image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1611
	var noise := FastNoiseLite.new()
	noise.seed = 1611
	noise.frequency = 0.08
	var base := Color(0.62, 0.42, 0.25)
	for row: int in 6:
		var tone := rng.randf_range(-0.05, 0.05)
		var seam := (row * 72) % 192
		for y: int in range(row * 32, row * 32 + 32):
			for x: int in 192:
				var grain := noise.get_noise_2d(x * 0.25, y * 2.0) * 0.06
				var c := base.lightened(tone + grain) if tone + grain > 0.0 \
					else base.darkened(-(tone + grain))
				var local := y - row * 32
				if local == 0:
					c = c.darkened(0.35)
				elif local == 1:
					c = c.lightened(0.08)
				if x == seam or x == (seam + 96) % 192:
					c = c.darkened(0.3)
				image.set_pixel(x, y, c)
	return image


## Dalles d'acier de 96 px (une par case), bord biseauté, quatre rivets, reflet diagonal doux.
func _steel() -> Image:
	var image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 1612
	noise.frequency = 0.05
	var base := Color(0.55, 0.6, 0.68)
	for y: int in 192:
		for x: int in 192:
			var lx := x % 96
			var ly := y % 96
			var c := base.lightened(noise.get_noise_2d(x, y) * 0.05 + 0.05)
			c = c.lightened(0.06 * (1.0 - absf(float(lx + ly - 96) / 96.0)))
			if lx <= 1 or ly <= 1:
				c = c.darkened(0.35)
			elif lx >= 94 or ly >= 94:
				c = c.lightened(0.12)
			for corner: Vector2i in [Vector2i(10, 10), Vector2i(85, 10), Vector2i(10, 85),
					Vector2i(85, 85)]:
				var d := Vector2(lx, ly).distance_to(Vector2(corner))
				if d < 3.5:
					c = base.darkened(0.25) if d > 2.0 else base.lightened(0.25)
			image.set_pixel(x, y, c)
	return image


## Moquette rouge tissée (petit motif losangé, bruit fin).
func _carpet() -> Image:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 1613
	noise.frequency = 0.3
	var base := Color(0.55, 0.16, 0.17)
	for y: int in 96:
		for x: int in 96:
			var c := base.lightened(noise.get_noise_2d(x, y) * 0.06 + 0.04)
			if (absi((x % 24) - 12) + absi((y % 24) - 12)) == 9:
				c = c.lightened(0.12)
			image.set_pixel(x, y, c)
	return image
