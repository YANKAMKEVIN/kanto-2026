class_name MapIllustration
extends RefCounted
## L'illustration de Kanto de l'écran Carte et sa géométrie (jalon-06.md §3.6) : chemin de
## l'image, taille, et rectangle de chaque zone **sur cette image**, lus dans
## `assets/ui/map/kanto_placeholder_areas.json`. Classe pure.
##
## Une seule source par fait (décision du T2) : l'identité d'une zone (nom, genre, cartes,
## textes) vit dans `data/world/zones.json` ([ZoneLibrary]) ; son rectangle appartient à
## l'illustration, qui sera refaite en phase DA à une autre taille (on changera alors ce
## fichier, pas les zones). Format :
## [codeblock]
## {
##   "_comment": "…",
##   "image": "res://assets/ui/map/kanto_placeholder.webp",
##   "image_size": [1586, 992],
##   "zones": { "pallet_town": { "area": [715, 595, 200, 110] } }
## }
## [/codeblock]
## Rectangles [x, y, largeur, hauteur] en pixels de l'image, entiers, dans l'image. Clé
## inconnue, rectangle hors de l'image ou mal formé : erreur ([method get_errors]), la zone
## n'a pas de rectangle (elle n'est alors pas touchable sur la carte).

const DEFAULT_PATH: String = "res://assets/ui/map/kanto_placeholder_areas.json"

const _ROOT_KEYS: Array[String] = ["_comment", "image", "image_size", "zones"]
const _ZONE_KEYS: Array[String] = ["area"]

var _image_path: String = ""
var _image_size: Vector2i = Vector2i.ZERO
var _areas: Dictionary[StringName, Rect2i] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les
## rectangles valides sont gardés).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"image\", \"image_size\", \"zones\" } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà parsé ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	var image: Variant = data.get("image")
	if not image is String or not (image as String).begins_with("res://"):
		ok = _fail("%s : « image » est un chemin res://" % source)
	else:
		_image_path = image
	var size := _read_ints(data.get("image_size"), 2)
	if size.is_empty() or size[0] <= 0 or size[1] <= 0:
		return _fail("%s : « image_size » vaut [largeur, hauteur]" % source)
	_image_size = Vector2i(size[0], size[1])
	if not data.get("zones") is Dictionary:
		return _fail("%s : « zones » doit être un objet { identifiant: { area } }" % source)
	var bounds := Rect2i(Vector2i.ZERO, _image_size)
	var zones: Dictionary = data["zones"]
	for key: Variant in zones:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		var entry: Variant = zones[key]
		if not entry is Dictionary:
			ok = _fail("%s : un objet { area } est attendu" % where)
			continue
		var valid := true
		for field: Variant in entry:
			if not _ZONE_KEYS.has(str(field)):
				valid = _fail("%s : clé inconnue « %s »" % [where, field])
		var a := _read_ints((entry as Dictionary).get("area"), 4)
		if a.is_empty() or a[2] <= 0 or a[3] <= 0:
			valid = _fail("%s : « area » vaut [x, y, largeur, hauteur]" % where)
		elif not bounds.encloses(Rect2i(a[0], a[1], a[2], a[3])):
			valid = _fail("%s : « area » sort de l'image" % where)
		if valid:
			_areas[id] = Rect2i(a[0], a[1], a[2], a[3])
		else:
			ok = false
	return ok


## Vérifie que chaque rectangle désigne une zone de [param zones]. Faux (erreurs signalées)
## sinon.
func check_references(zones: ZoneLibrary) -> bool:
	var ok := true
	for id: StringName in _areas:
		if zones == null or not zones.has_zone(id):
			ok = _fail("rectangle de « %s » : zone absente de zones.json" % id)
	return ok


## Chemin de l'image (« res://assets/ui/map/kanto_placeholder.webp »).
func get_image_path() -> String:
	return _image_path


## Taille de l'image en pixels.
func get_image_size() -> Vector2i:
	return _image_size


## Rectangle de [param zone] sur l'image ; vide (Rect2i()) si la zone n'en a pas.
func area_of(zone: StringName) -> Rect2i:
	return _areas.get(zone, Rect2i())


func has_area(zone: StringName) -> bool:
	return _areas.has(zone)


## Zones qui ont un rectangle, dans l'ordre du fichier.
func get_zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_areas.keys())
	return ids


func get_errors() -> PackedStringArray:
	return _errors


## [param count] entiers (nombres entiers du JSON), ou une liste vide.
static func _read_ints(value: Variant, count: int) -> Array[int]:
	var result: Array[int] = []
	if not value is Array or (value as Array).size() != count:
		return result
	for item: Variant in value:
		if not (item is int or item is float) or float(item) != floorf(float(item)):
			return [] as Array[int]
		result.append(int(item))
	return result


func _fail(message: String) -> bool:
	var full := "MapIllustration : " + message
	_errors.append(full)
	push_error(full)
	return false
