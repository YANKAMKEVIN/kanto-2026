extends SceneTree
## Génère les tuiles de sol provisoires (96×96, dimensions finales) et le TileSet.
##
##   godot --headless --path . -s res://tools/gen_placeholder_tiles.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/gen_placeholder_tiles.gd
##
## 1er passage : écrit l'atlas PNG. Le TileSet référence la texture importée : il
## n'est écrit que si l'atlas a déjà été importé (d'où le 2e passage au tout début).
##
## Coordonnées d'atlas (colonne = variante, rangée = type) — définies dans
## `game/world/overworld_tiles.gd` (OverworldTiles), source unique partagée avec
## le constructeur de cartes et les tests :
##   rangée 0  GRASS      herbe rase        4 variantes
##   rangée 1  FLOWERS    fleurs (Detail)   3 variantes (fond transparent)
##   rangée 2  DIRT       chemin de terre   3
##   rangée 3  COBBLE     pavés             3
##   rangée 4  SAND       sable             3
##   rangée 5  BOARDWALK  terrasse bois     2
##   rangée 6  FOREST     sol de forêt      3  solid
##   rangée 7  CLIFF      falaise           2  solid
##   rangée 8  CROP       culture           2  solid
##   rangée 9  WATER      mer               3  water
##   rangée 10 SHALLOW    eau peu profonde  2  water

const TILES_SCRIPT: String = "res://game/world/overworld_tiles.gd"
const T: int = 96
const SEED: int = 20260925

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()


func _init() -> void:
	_tiles = load(TILES_SCRIPT)
	_rng.seed = SEED
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.06
	var kinds: Dictionary = _tiles.Kind
	var variants: Dictionary = _tiles.VARIANTS
	var columns: int = _tiles.ATLAS_COLUMNS
	var atlas := Image.create_empty(columns * T, kinds.size() * T, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for kind_name: String in kinds:
		var kind: int = kinds[kind_name]
		for variant: int in variants[kind]:
			var tile := _draw_tile(kind_name, variant)
			atlas.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(variant * T, kind * T))
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_tiles.TEXTURE_PATH.get_base_dir())
	)
	var err := atlas.save_png(_tiles.TEXTURE_PATH)
	print("atlas : ", _tiles.TEXTURE_PATH, " (", error_string(err), ")")
	if not FileAccess.file_exists(_tiles.TEXTURE_PATH + ".import"):
		print("Atlas pas encore importé : lancer --import puis relancer ce script.")
		quit()
		return
	_save_tileset()
	quit()


func _save_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(T, T)
	var layers: Array = [
		[_tiles.DATA_SOLID, TYPE_BOOL],
		[_tiles.DATA_TALL_GRASS, TYPE_BOOL],
		[_tiles.DATA_WATER, TYPE_BOOL],
		[_tiles.DATA_LEDGE, TYPE_INT],
	]
	for i: int in layers.size():
		tileset.add_custom_data_layer()
		tileset.set_custom_data_layer_name(i, String(layers[i][0]))
		tileset.set_custom_data_layer_type(i, layers[i][1])
	var source := TileSetAtlasSource.new()
	source.texture = load(_tiles.TEXTURE_PATH)
	source.texture_region_size = Vector2i(T, T)
	tileset.add_source(source, _tiles.SOURCE_ID)
	var variants: Dictionary = _tiles.VARIANTS
	for kind: int in variants:
		for variant: int in variants[kind]:
			var coords: Vector2i = _tiles.atlas_coords(kind, variant)
			source.create_tile(coords)
			var data := source.get_tile_data(coords, 0)
			data.set_custom_data(_tiles.DATA_SOLID, _tiles.is_solid_kind(kind))
			data.set_custom_data(_tiles.DATA_TALL_GRASS, false)
			data.set_custom_data(_tiles.DATA_WATER, _tiles.is_water_kind(kind))
			data.set_custom_data(_tiles.DATA_LEDGE, 0)
	var err := ResourceSaver.save(tileset, _tiles.TILESET_PATH)
	print("tileset : ", _tiles.TILESET_PATH, " (", error_string(err), ")")


# --- Dessin -------------------------------------------------------------------

func _draw_tile(kind_name: String, variant: int) -> Image:
	var img := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
	_noise.seed = SEED + variant * 101 + kind_name.hash() % 1000
	_rng.seed = SEED + variant * 7919 + kind_name.hash()
	match kind_name:
		"GRASS":
			_fill_noise(img, Color("#6fa84a"), Color("#5c9440"), Color("#86bd5c"))
			_scatter_strokes(img, 26 + variant * 6, Color("#4e8236"), 5)
			_scatter_strokes(img, 10 + variant * 4, Color("#9fcf6e"), 4)
			_grid_hint(img)
		"FLOWERS":
			img.fill(Color(0, 0, 0, 0))
			var palettes: Array = [
				[Color("#f7f2e6"), Color("#f5d04a")],
				[Color("#f29bb8"), Color("#fff1a8")],
				[Color("#8fb6f2"), Color("#f7f2e6")],
			]
			var pal: Array = palettes[variant % palettes.size()]
			for i: int in 11:
				var c := Vector2i(_rng.randi_range(8, 87), _rng.randi_range(8, 87))
				_flower(img, c, pal[0], pal[1])
		"DIRT":
			_fill_noise(img, Color("#c9a36b"), Color("#b58f59"), Color("#dab683"))
			_scatter_dots(img, 14 + variant * 5, Color("#9c7a4a"), 2)
			_scatter_dots(img, 8, Color("#e6c99a"), 1)
			_grid_hint(img)
		"COBBLE":
			_draw_cobble(img, variant)
		"SAND":
			_fill_noise(img, Color("#ead49c"), Color("#dcc387"), Color("#f4e2b4"))
			_scatter_dots(img, 30 + variant * 8, Color("#c9ae74"), 1)
			if variant == 2:
				_scatter_dots(img, 3, Color("#f7f3ea"), 3)
			_grid_hint(img)
		"BOARDWALK":
			_draw_planks(img, variant)
		"FOREST":
			_draw_canopy(img, variant)
		"CLIFF":
			_draw_cliff(img, variant)
		"CROP":
			_draw_crop(img, variant)
		"WATER":
			_fill_noise(img, Color("#2c77ad"), Color("#23669a"), Color("#3a8cc2"))
			_waves(img, 5 + variant, Color("#6fb4df"))
		"SHALLOW":
			_fill_noise(img, Color("#4db3c2"), Color("#3fa1b3"), Color("#6cc9d3"))
			_waves(img, 4 + variant, Color("#a6e3e6"))
	return img


func _fill_noise(img: Image, base: Color, dark: Color, light: Color) -> void:
	for y: int in T:
		for x: int in T:
			var n := _noise.get_noise_2d(x, y)
			var c := base.lerp(dark, -n) if n < 0.0 else base.lerp(light, n)
			img.set_pixel(x, y, c)


## Motif très léger qui laisse lire la grille (bord haut et gauche assombris).
func _grid_hint(img: Image) -> void:
	for i: int in T:
		_blend(img, i, 0, Color(0, 0, 0, 0.10))
		_blend(img, 0, i, Color(0, 0, 0, 0.10))


func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= T or y >= T:
		return
	img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _disc(img: Image, center: Vector2, radius: float, c: Color) -> void:
	var r := ceili(radius)
	for y: int in range(int(center.y) - r, int(center.y) + r + 1):
		for x: int in range(int(center.x) - r, int(center.x) + r + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				_blend(img, x, y, c)


func _scatter_strokes(img: Image, count: int, c: Color, length: int) -> void:
	for i: int in count:
		var x := _rng.randi_range(2, T - 3)
		var y := _rng.randi_range(length, T - 2)
		for k: int in length:
			_blend(img, x + (k % 2 if i % 2 == 0 else 0), y - k, c)


func _scatter_dots(img: Image, count: int, c: Color, radius: int) -> void:
	for i: int in count:
		var p := Vector2(_rng.randf_range(3, T - 3), _rng.randf_range(3, T - 3))
		_disc(img, p, radius, c)


func _flower(img: Image, c: Vector2i, petal: Color, heart: Color) -> void:
	var center := Vector2(c) + Vector2(0.5, 0.5)
	for d: Vector2 in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
		_disc(img, center + d * 1.3, 3.0, petal)
	_disc(img, center, 2.2, heart)
	for k: int in range(7, 11):
		_blend(img, c.x, c.y + k, Color("#3f7a2f"))


func _draw_cobble(img: Image, variant: int) -> void:
	img.fill(Color("#8f8576"))
	var rows := 4
	var h := T / rows
	for r: int in rows:
		var shift := (h / 2) * (r % 2) + variant * 5
		for k: int in range(-1, 4):
			var x0 := k * 32 + shift
			var tone := Color("#bdb2a0").lerp(Color("#a89c89"), _rng.randf())
			for y: int in range(r * h + 2, (r + 1) * h - 2):
				for x: int in range(x0 + 2, x0 + 30):
					if x >= 0 and x < T:
						var edge := mini(mini(x - x0 - 2, x0 + 29 - x), mini(y - r * h - 2, (r + 1) * h - 3 - y))
						var c := tone.lightened(0.08) if edge > 2 else tone
						c = c.darkened(0.06 * (_noise.get_noise_2d(x, y) + 1.0))
						img.set_pixel(x, y, c)
	_grid_hint(img)


func _draw_planks(img: Image, variant: int) -> void:
	var plank := 24
	for y: int in T:
		for x: int in T:
			var n := _noise.get_noise_2d(x * 0.3, y * 3.0)
			var c := Color("#a0703f").lerp(Color("#7d5530"), 0.5 + n * 0.5)
			if y % plank == 0 or y % plank == plank - 1:
				c = Color("#5a3a1e")
			img.set_pixel(x, y, c)
	for r: int in T / plank:
		var joint := (r * 37 + variant * 23) % T
		for y: int in range(r * plank, (r + 1) * plank):
			img.set_pixel(joint, y, Color("#5a3a1e"))
		_disc(img, Vector2(joint + 5, r * plank + 6), 1.2, Color("#3b2612"))


func _draw_canopy(img: Image, _variant: int) -> void:
	_fill_noise(img, Color("#2d5a2b"), Color("#1f4420"), Color("#3a6d33"))
	for i: int in 9:
		var p := Vector2(_rng.randf_range(0, T), _rng.randf_range(0, T))
		var r := _rng.randf_range(14, 24)
		_disc(img, p + Vector2(3, 4), r, Color(0.05, 0.12, 0.05, 0.45))
		_disc(img, p, r, Color("#3f7a36"))
		_disc(img, p - Vector2(r * 0.3, r * 0.3), r * 0.55, Color("#58934a"))


func _draw_cliff(img: Image, variant: int) -> void:
	_fill_noise(img, Color("#8b7863"), Color("#6c5b49"), Color("#a8937b"))
	for i: int in 5 + variant:
		var x := _rng.randi_range(4, T - 4)
		var y := _rng.randi_range(4, T - 20)
		for k: int in _rng.randi_range(8, 18):
			_blend(img, x + (k / 4) * (1 if i % 2 == 0 else -1), y + k, Color("#4a3d31"))
	for x: int in T:
		for y: int in 6:
			_blend(img, x, y, Color(1, 1, 1, 0.12))


func _draw_crop(img: Image, variant: int) -> void:
	_fill_noise(img, Color("#7a5532"), Color("#5f4126"), Color("#8e6841"))
	var green := Color("#6bb04a") if variant == 0 else Color("#9ec24a")
	for r: int in 4:
		var y := 12 + r * 24
		for x: int in range(4, T - 4, 7):
			_disc(img, Vector2(x + (r % 2) * 3, y), 3.2, green)
			_blend(img, x, y + 4, Color("#3f6a28"))


func _waves(img: Image, count: int, c: Color) -> void:
	for i: int in count:
		var y := _rng.randi_range(6, T - 6)
		var x0 := _rng.randi_range(0, T - 30)
		var length := _rng.randi_range(12, 26)
		for k: int in length:
			var yy := y + int(round(sin(k * 0.45) * 1.5))
			_blend(img, x0 + k, yy, c)
