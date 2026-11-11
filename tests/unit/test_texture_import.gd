extends GutTest
## Réglages d'import des images (RC 0.36.2, décision de Kevin du 2026-11-11) : les images peintes
## sont importées **avec perte** (WebP qualité 0,9) pour garder l'APK léger (959 → 410 Mo) ; ce qui
## est lu comme des **données** reste **sans perte** :
## - les masques de `assets/world/maps` (1 pixel = 1 case : sol, eau, lumière, ombre, voile…) ;
## - l'atlas du Pokédex ([PokedexArt], voir `test_pokedex_art.gd`) ;
## - les icônes SVG, l'icône de l'application et les tuiles provisoires.
## Une nouvelle image peinte arrive « sans perte » par défaut : mettre `compress/mode=1` et
## `compress/lossy_quality=0.9` dans son `.import`.

const ROOT := "res://assets"
const MASK_DIR := "res://assets/world/maps/"
## Préfixes et fichiers gardés sans perte (en plus des masques).
const LOSSLESS_PREFIXES: Array[String] = [
	"res://assets/ui/icon", "res://assets/tiles/placeholder/",
	"res://assets/sprites/pokemon/official/atlas_128.png",
]
const RASTER: Array[String] = ["png", "webp", "jpg", "jpeg"]


func test_data_masks_stay_lossless() -> void:
	var count := 0
	for path: String in _imports():
		if path.begins_with(MASK_DIR):
			count += 1
			assert_eq(_mode(path), 0, "%s : masque de données, doit rester sans perte" % path)
	assert_gt(count, 100, "les masques de assets/world/maps sont trouvés")


func test_painted_images_are_lossy() -> void:
	var wrong: PackedStringArray = []
	var count := 0
	for path: String in _imports():
		var source := path.trim_suffix(".import")
		if not RASTER.has(source.get_extension().to_lower()) or path.begins_with(MASK_DIR) \
				or LOSSLESS_PREFIXES.any(func(p: String) -> bool: return source.begins_with(p)):
			continue
		count += 1
		var config := _config(path)
		if config.get_value("params", "compress/mode", -1) != 1 \
				or absf(float(config.get_value("params", "compress/lossy_quality", 0.0)) - 0.9) > 0.001:
			wrong.append(source)
	assert_gt(count, 3000, "les images peintes sont trouvées")
	assert_eq(wrong.size(), 0, "images à importer avec perte (compress/mode=1, qualité 0.9) : %s"
		% ", ".join(wrong.slice(0, 20)))


func _mode(import_path: String) -> int:
	return int(_config(import_path).get_value("params", "compress/mode", -1))


func _config(import_path: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(import_path)
	return config


func _imports() -> PackedStringArray:
	var found: PackedStringArray = []
	_walk(ROOT, found)
	return found


func _walk(dir_path: String, found: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_walk(dir_path.path_join(sub), found)
	for file: String in dir.get_files():
		if file.ends_with(".import"):
			found.append(dir_path.path_join(file))
