class_name LightGlowLibrary
extends RefCounted
## Types de halo de lumière ([LightGlow]), lus dans `data/world/light_glows.json`
## (docs/tech/jalon-12.md §2.4). Classe pure, sans nœud.
## [codeblock]
## { "types": {
##     "lamp": { "color": "#ffb260", "radius": 2.6, "alpha": 0.30, "flicker": 0.18 } } }
## [/codeblock]
## Clés d'un type (toutes obligatoires) : « color » (« #rrggbb »), « radius » (cases, dans
## ]0, [constant RADIUS_MAX]]), « alpha » (intensité au centre, dans ]0, [constant ALPHA_MAX]] :
## un halo éclaire sans effacer le décor ni les personnages), « flicker » (amplitude du
## vacillement, dans [0, [constant FLICKER_MAX]] ; 0 = fixe). Clés facultatives (passe « lumière
## rare ») : « shape » (« radial » par défaut, ou « column » : colonne de lumière douce d'un puits
## de jour, posée à son pied, « radius » = demi-largeur), « blend » (« add » par défaut, ou « mix »
## pour un décor clair) ) et « height » (hauteur de la colonne en
## cases, dans ]0, [constant RADIUS_MAX]], obligatoire pour « column »). Racine : « types » et
## « _doc » (texte libre). Toute clé inconnue est une erreur ; un type invalide est écarté, l'erreur
## signalée ([method get_errors], push_error).


## Un type de halo.
class GlowType:
	extends RefCounted
	var id: StringName = &""
	var color: Color = Color.WHITE
	## Rayon où le halo s'éteint, en cases.
	var radius: float = 1.0
	var alpha: float = 0.2
	var flicker: float = 0.0
	## [constant SHAPE_RADIAL] ou [constant SHAPE_COLUMN].
	var shape: StringName = &"radial"
	## Hauteur d'une colonne, en cases (0 pour un halo radial).
	var height: float = 0.0
	## [constant BLEND_ADD] ou [constant BLEND_MIX].
	var blend: StringName = &"add"


const SHAPE_RADIAL: StringName = &"radial"
const SHAPE_COLUMN: StringName = &"column"
## Fusion avec le décor : additive (lumière, défaut) ou « mix » (teinte posée sur le décor,
## pour un décor clair où l'additif se perd : lueur d'aide du jalon 14).
const BLEND_ADD: StringName = &"add"
const BLEND_MIX: StringName = &"mix"
const DATA_PATH: String = "res://data/world/light_glows.json"
## Intensité maximale d'un halo (plan du J12 §2.4).
const ALPHA_MAX: float = 0.35
## Intensité maximale d'un halo « mix » : il teinte le décor sans jamais l'éclaircir, il ne peut
## donc pas le « brûler » ; sur un décor clair, 0,35 reste imperceptible (jalon 14, lueur d'aide).
const ALPHA_MAX_MIX: float = 0.7
const RADIUS_MAX: float = 8.0
const FLICKER_MAX: float = 0.5
## Budget de halos par carte (plan du J12 §2.4 : ≤ 16 par étage), vérifié par les tests des
## cartes.
const MAX_PER_MAP: int = 16
const _ROOT_KEYS: Array[String] = ["_doc", "types"]
const _TYPE_KEYS: Array[String] = ["color", "radius", "alpha", "flicker"]
const _OPTIONAL_KEYS: Array[String] = ["shape", "height", "blend"]

var _types: Dictionary[StringName, GlowType] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les types
## valides sont gardés).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"types\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les types d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("types") is Dictionary:
		return _fail("%s : « types » doit être un objet { identifiant: type }" % source)
	var types: Dictionary = data["types"]
	for key: Variant in types:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _types.has(id):
			ok = _fail("%s : type déjà défini" % where)
			continue
		var type := _parse_type(types[key], where)
		if type == null:
			ok = false
			continue
		type.id = id
		_types[id] = type
	return ok


## Type [param id], ou null s'il est inconnu.
func get_type(id: StringName) -> GlowType:
	return _types.get(id)


func has_type(id: StringName) -> bool:
	return _types.has(id)


## Identifiants des types, dans l'ordre du fichier.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_types.keys())
	return ids


func size() -> int:
	return _types.size()


func get_errors() -> PackedStringArray:
	return _errors


func _parse_type(raw: Variant, where: String) -> GlowType:
	if not raw is Dictionary:
		_fail("%s : un type est un objet { color, radius, alpha, flicker }" % where)
		return null
	var entry: Dictionary = raw
	var valid := true
	for key: Variant in entry:
		if not _TYPE_KEYS.has(str(key)) and not _OPTIONAL_KEYS.has(str(key)):
			valid = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in _TYPE_KEYS:
		if not entry.has(key):
			valid = _fail("%s : « %s » manquant" % [where, key])
	if not valid:
		return null
	var color: Variant = entry["color"]
	if not color is String or not _is_hex_color(color):
		valid = _fail("%s : « color » doit être « #rrggbb »" % where)
	valid = _check_number(entry["radius"], 0.0, RADIUS_MAX, false, "radius", where) and valid
	valid = _check_number(entry["flicker"], 0.0, FLICKER_MAX, true, "flicker", where) and valid
	var shape := SHAPE_RADIAL
	if entry.has("shape"):
		var raw_shape: Variant = entry["shape"]
		if raw_shape is String and StringName(raw_shape) in [SHAPE_RADIAL, SHAPE_COLUMN]:
			shape = StringName(raw_shape)
		else:
			valid = _fail("%s : « shape » doit être « radial » ou « column »" % where)
	var blend := BLEND_ADD
	if entry.has("blend"):
		var raw_blend: Variant = entry["blend"]
		if raw_blend is String and StringName(raw_blend) in [BLEND_ADD, BLEND_MIX]:
			blend = StringName(raw_blend)
		else:
			valid = _fail("%s : « blend » doit être « add » ou « mix »" % where)
	var alpha_max := ALPHA_MAX_MIX if blend == BLEND_MIX else ALPHA_MAX
	valid = _check_number(entry["alpha"], 0.0, alpha_max, false, "alpha", where) and valid
	if shape == SHAPE_COLUMN and not entry.has("height"):
		valid = _fail("%s : « height » manquant (colonne)" % where)
	if entry.has("height"):
		valid = _check_number(entry["height"], 0.0, RADIUS_MAX, false, "height", where) and valid
	if not valid:
		return null
	var type := GlowType.new()
	type.shape = shape
	type.blend = blend
	type.height = float(entry.get("height", 0.0))
	type.color = Color.html(color)
	type.radius = float(entry["radius"])
	type.alpha = float(entry["alpha"])
	type.flicker = float(entry["flicker"])
	return type


## Nombre dans ]low, high] (ou [low, high] si [param low_included]).
func _check_number(value: Variant, low: float, high: float, low_included: bool, key: String,
		where: String) -> bool:
	if not (value is float or value is int):
		return _fail("%s : « %s » doit être un nombre" % [where, key])
	var number := float(value)
	var above := number >= low if low_included else number > low
	if not above or number > high:
		return _fail("%s : « %s » hors de %s%s, %s]" % [where, key,
			"[" if low_included else "]", low, high])
	return true


static func _is_hex_color(text: String) -> bool:
	if text.length() != 7 or not text.begins_with("#"):
		return false
	return text.substr(1).is_valid_hex_number()


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("LightGlowLibrary : " + message)
	return false
