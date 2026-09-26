extends SceneTree
## Génère les tuiles d'intérieur provisoires (96×96, dimensions finales) et leur TileSet.
##
##   godot --headless --path . -s res://tools/gen_placeholder_interior_tiles.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/gen_placeholder_interior_tiles.gd
##
## 1er passage : écrit l'atlas PNG. Le TileSet référence la texture importée : il n'est
## écrit que si l'atlas a déjà été importé (d'où le 2e passage au tout début).
##
## Coordonnées d'atlas (colonne = variante, rangée = type), définies dans
## `game/world/interior_tiles.gd` (InteriorTiles) :
##   rangée 0  FLOOR_WOOD   parquet chaud (maisons)         3 variantes
##   rangée 1  FLOOR_LAB    carrelage clair (labo)          2
##   rangée 2  WALL_HOUSE   mur de maison (1 = plinthe)     2  solid
##   rangée 3  WALL_LAB     mur technique (1 = plinthe)     2  solid
##   rangée 4  STAIRS_UP    marches vers le mur du fond     1
##   rangée 5  STAIRS_DOWN  trémie, marches qui descendent  1
##   rangée 6  MAT          tapis de sortie (Detail)        1
##   rangée 7  RUG          tapis décoratif (Detail)        2
## Les couches de données sont celles d'overworld.tres (mêmes noms, même ordre).

const TILES_SCRIPT: String = "res://game/world/interior_tiles.gd"
const OVERWORLD_SCRIPT: String = "res://game/world/overworld_tiles.gd"
const T: int = 96
const SEED: int = 20260926

var _tiles: GDScript
var _overworld: GDScript
var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()


func _init() -> void:
	_tiles = load(TILES_SCRIPT)
	_overworld = load(OVERWORLD_SCRIPT)
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.05
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
		[_overworld.DATA_SOLID, TYPE_BOOL],
		[_overworld.DATA_TALL_GRASS, TYPE_BOOL],
		[_overworld.DATA_WATER, TYPE_BOOL],
		[_overworld.DATA_LEDGE, TYPE_INT],
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
			data.set_custom_data(_overworld.DATA_SOLID, _tiles.is_solid_kind(kind))
			data.set_custom_data(_overworld.DATA_TALL_GRASS, false)
			data.set_custom_data(_overworld.DATA_WATER, false)
			data.set_custom_data(_overworld.DATA_LEDGE, 0)
	var err := ResourceSaver.save(tileset, _tiles.TILESET_PATH)
	print("tileset : ", _tiles.TILESET_PATH, " (", error_string(err), ")")


# --- Dessin -------------------------------------------------------------------

func _draw_tile(kind_name: String, variant: int) -> Image:
	var img := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_noise.seed = SEED + variant * 101 + kind_name.hash() % 1000
	_rng.seed = SEED + variant * 7919 + kind_name.hash()
	match kind_name:
		"FLOOR_WOOD":
			_draw_parquet(img, variant)
		"FLOOR_LAB":
			_draw_lab_floor(img, variant)
		"WALL_HOUSE":
			_draw_wall(img, variant, Color("#eadcbf"), Color("#8a5d36"), true)
		"WALL_LAB":
			_draw_wall(img, variant, Color("#dde2e4"), Color("#7d868c"), false)
		"STAIRS_UP":
			_draw_stairs(img, true)
		"STAIRS_DOWN":
			_draw_stairs(img, false)
		"MAT":
			_draw_mat(img)
		"RUG":
			_draw_rug(img, variant)
	return img


func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= T or y >= T:
		return
	img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _rect(img: Image, r: Rect2i, c: Color) -> void:
	for y: int in range(r.position.y, r.end.y):
		for x: int in range(r.position.x, r.end.x):
			_blend(img, x, y, c)


## Lames de parquet horizontales (4 par tuile), joints décalés selon la variante.
func _draw_parquet(img: Image, variant: int) -> void:
	var plank := 24
	var tones: Array[Color] = [Color("#b7824f"), Color("#a9743f"), Color("#c08d5a")]
	for r: int in T / plank:
		var base := tones[(r + variant) % tones.size()]
		for y: int in range(r * plank, (r + 1) * plank):
			for x: int in T:
				var n := _noise.get_noise_2d(x * 0.25, y * 2.5)
				var c := base.lerp(base.darkened(0.18), 0.5 + n * 0.5)
				if y == r * plank:
					c = Color("#6e4a2a")
				elif y == r * plank + 1:
					c = base.lightened(0.12)
				img.set_pixel(x, y, c)
		var joint := (r * 41 + variant * 29 + 13) % T
		for y: int in range(r * plank + 1, (r + 1) * plank):
			img.set_pixel(joint, y, Color("#6e4a2a"))


## Carrelage clair : 4 carreaux de 48 px, joints gris.
func _draw_lab_floor(img: Image, variant: int) -> void:
	var base := Color("#e3e6e1") if variant == 0 else Color("#dcdfda")
	for y: int in T:
		for x: int in T:
			var n := _noise.get_noise_2d(x, y)
			var c := base.lerp(base.darkened(0.06), 0.5 + n * 0.5)
			if x % 48 == 0 or y % 48 == 0:
				c = Color("#b7bcb8")
			img.set_pixel(x, y, c)
	if variant == 1:
		_rect(img, Rect2i(60, 60, 20, 3), Color(0.55, 0.6, 0.62, 0.25))


## Mur vu de face. Variante 0 : partie haute, unie (se répète sans couture sur les murs
## latéraux) ; 1 : rangée basse, plinthe sombre en pied.
func _draw_wall(img: Image, variant: int, base: Color, trim: Color, stripes: bool) -> void:
	for y: int in T:
		for x: int in T:
			var n := _noise.get_noise_2d(x * 0.5, y * 0.5)
			var c := base.lerp(base.darkened(0.05), 0.5 + n * 0.5)
			if stripes and x % 24 < 2:
				c = c.darkened(0.06)
			if not stripes and x == 0:
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	if variant == 1:
		_rect(img, Rect2i(0, T - 20, T, 20), trim)
		_rect(img, Rect2i(0, T - 20, T, 3), trim.lightened(0.25))
		_rect(img, Rect2i(0, T - 3, T, 3), trim.darkened(0.3))


## Escalier : marches horizontales. Montant : plus clair vers le haut (vers le mur du
## fond). Descendant : trémie qui s'assombrit vers le bas.
func _draw_stairs(img: Image, up: bool) -> void:
	var steps := 6
	var h := T / steps
	var wood := Color("#a8743f")
	for s: int in steps:
		var k := float(s) / (steps - 1)
		var tone := wood.lightened(0.25 * (1.0 - k)) if up else wood.darkened(0.7 * k)
		_rect(img, Rect2i(6, s * h, T - 12, h), tone)
		_rect(img, Rect2i(6, s * h + h - 3, T - 12, 3), tone.darkened(0.35))
	_rect(img, Rect2i(0, 0, 6, T), Color("#5a3a1e"))
	_rect(img, Rect2i(T - 6, 0, 6, T), Color("#5a3a1e"))


## Tapis de sortie : paillasson rouge, bord inférieur marqué (côté porte).
func _draw_mat(img: Image) -> void:
	_rect(img, Rect2i(8, 18, 80, 70), Color("#8f2f24"))
	_rect(img, Rect2i(14, 24, 68, 52), Color("#b8483a"))
	for i: int in 5:
		_rect(img, Rect2i(18, 30 + i * 9, 60, 3), Color("#9a3a2e"))
	_rect(img, Rect2i(8, 80, 80, 8), Color("#f0d7a0"))


## Tapis décoratif qui se raccorde d'une tuile à l'autre (0 bleu à carreaux, 1 rouge).
func _draw_rug(img: Image, variant: int) -> void:
	var a := Color("#4a6aa8") if variant == 0 else Color("#a8453c")
	var b := Color("#6f8cc6") if variant == 0 else Color("#c7665a")
	for y: int in T:
		for x: int in T:
			var check := ((x / 24) + (y / 24)) % 2 == 0
			img.set_pixel(x, y, a if check else b)
	for i: int in 30:
		_blend(img, _rng.randi_range(0, T - 1), _rng.randi_range(0, T - 1),
			Color(1, 1, 1, 0.12))
