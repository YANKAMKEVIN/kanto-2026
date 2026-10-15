class_name DarknessProfile
extends RefCounted
## Réglages du voile d'obscurité, lus dans `data/world/darkness.json` (brique commune J17 T9 /
## J18 : docs/tech/jalon-18.md §2.4, §2.9 ; docs/tech/jalon-17.md §2.10 ; dossier 21 I-7, I-8).
## Classe pure, sans nœud.
## [codeblock]
## { "color": "#04060c",
##   "dark": { "clear": 2.5, "fade": 4.0, "outside": 0.6 },
##   "lit":  { "clear": 7.0, "fade": 9.0, "outside": 0.3 },
##   "center_offset": -48, "breath": 0.03, "breath_period": 3.5,
##   "open_duration": 0.6, "glow_hole_scale": 1.0, "dither": 0.004 }
## [/codeblock]
## Deux états : « dark » (sans Flash) et « lit » (Flash) ; rayons en **cases**, rendus en pixels
## ([method params_at]) ; [method params_at] interpole de l'un à l'autre (ouverture animée du
## halo). Garde-fous : 0 < clear < fade, 0 < outside ≤ [constant MAX_OUTSIDE] (« jamais de noir
## total »), durée d'ouverture > 0. Toutes les clés sont obligatoires sauf « _doc » ; toute clé
## inconnue est une erreur ; en cas d'erreur, les valeurs par défaut (celles du fichier livré)
## restent en place ([method get_errors], push_error).

const DATA_PATH: String = "res://data/world/darkness.json"
## Opacité maximale du voile : jamais de noir total (I-7).
const MAX_OUTSIDE: float = 0.85
const MAX_SOURCES: int = VeilMath.MAX_SOURCES
const MAX_RADIUS: float = 20.0
const MAX_BREATH: float = 0.2
const MAX_DITHER: float = 0.05
const _ROOT_KEYS: Array[String] = ["_doc", "color", "dark", "lit", "center_offset", "breath",
	"breath_period", "open_duration", "glow_hole_scale", "dither"]
const _STATE_KEYS: Array[String] = ["clear", "fade", "outside"]

## Couleur du voile (opaque ; l'opacité vient de « outside »).
var color: Color = Color("#04060c")
## Rayons en cases et opacité, sans Flash (x = clear, y = fade, z = outside).
var dark: Vector3 = Vector3(2.5, 4.0, 0.6)
## Idem avec Flash.
var lit: Vector3 = Vector3(7.0, 9.0, 0.3)
## Pixels du centre du trou par rapport aux pieds du joueur (négatif = au-dessus).
var center_offset: float = -48.0
var breath_amplitude: float = 0.03
var breath_period: float = 3.5
var open_duration: float = 0.6
var glow_hole_scale: float = 1.0
var dither: float = 0.004

var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou invalide (rien n'est gardé).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return load_dict(json.data, path)


## Lit un objet déjà décodé. Tout ou rien.
func load_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	for key: String in _ROOT_KEYS:
		if key != "_doc" and not data.has(key):
			ok = _fail("%s : clé « %s » manquante" % [source, key])
	if not ok:
		return false
	var new_color := Color.BLACK
	var text: Variant = data["color"]
	if not text is String or not Color.html_is_valid(text) or (text as String).length() != 7:
		ok = _fail("%s : « color » doit être « #rrggbb »" % source)
	else:
		new_color = Color(text)
	var new_dark := _parse_state(data["dark"], "%s « dark »" % source)
	var new_lit := _parse_state(data["lit"], "%s « lit »" % source)
	ok = ok and new_dark != Vector3.ZERO and new_lit != Vector3.ZERO
	ok = _number(data["center_offset"], -256.0, 256.0, "center_offset", source) and ok
	ok = _number(data["breath"], 0.0, MAX_BREATH, "breath", source) and ok
	ok = _positive(data["breath_period"], "breath_period", source) and ok
	ok = _positive(data["open_duration"], "open_duration", source) and ok
	ok = _number(data["glow_hole_scale"], 0.0, 4.0, "glow_hole_scale", source) and ok
	ok = _number(data["dither"], 0.0, MAX_DITHER, "dither", source) and ok
	if not ok:
		return false
	color = new_color
	dark = new_dark
	lit = new_lit
	center_offset = float(data["center_offset"])
	breath_amplitude = float(data["breath"])
	breath_period = float(data["breath_period"])
	open_duration = float(data["open_duration"])
	glow_hole_scale = float(data["glow_hole_scale"])
	dither = float(data["dither"])
	return true


## Réglages en pixels pour une ouverture [param lit_amount] (0 = sans Flash, 1 = Flash ;
## borné), interpolés linéairement.
func params_at(lit_amount: float) -> VeilParams:
	var params := VeilParams.new()
	fill_params(params, lit_amount)
	return params


## Comme [method params_at], dans [param params] (aucune allocation : appelé à chaque image de
## l'ouverture).
func fill_params(params: VeilParams, lit_amount: float) -> void:
	var t := clampf(lit_amount, 0.0, 1.0)
	var state := dark.lerp(lit, t)
	params.clear_px = state.x * Grid.TILE_SIZE
	params.fade_px = state.y * Grid.TILE_SIZE
	params.outside = state.z


## Amplitude du battement : 0 si les animations sont réduites.
func breath(reduce_motion: bool) -> float:
	return 0.0 if reduce_motion else breath_amplitude


func get_errors() -> PackedStringArray:
	return _errors


## (clear, fade, outside) validés ; Vector3.ZERO si invalide (erreur signalée).
func _parse_state(raw: Variant, where: String) -> Vector3:
	if not raw is Dictionary:
		_fail("%s : un objet { clear, fade, outside } est attendu" % where)
		return Vector3.ZERO
	var entry: Dictionary = raw
	var ok := true
	for key: Variant in entry:
		if not _STATE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in _STATE_KEYS:
		if not entry.has(key):
			ok = _fail("%s : clé « %s » manquante" % [where, key])
	if not ok:
		return Vector3.ZERO
	ok = _number(entry["clear"], 0.0, MAX_RADIUS, "clear", where) and ok
	ok = _number(entry["fade"], 0.0, MAX_RADIUS, "fade", where) and ok
	ok = _number(entry["outside"], 0.0, MAX_OUTSIDE, "outside", where) and ok
	if not ok:
		return Vector3.ZERO
	var state := Vector3(float(entry["clear"]), float(entry["fade"]), float(entry["outside"]))
	if state.x <= 0.0 or state.y <= state.x:
		_fail("%s : il faut 0 < clear < fade" % where)
		return Vector3.ZERO
	if state.z <= 0.0:
		_fail("%s : « outside » doit être > 0" % where)
		return Vector3.ZERO
	return state


func _number(value: Variant, low: float, high: float, key: String, where: String) -> bool:
	if not (value is float or value is int) or float(value) < low or float(value) > high:
		return _fail("%s : « %s » doit être un nombre de %s à %s" % [where, key, low, high])
	return true


func _positive(value: Variant, key: String, where: String) -> bool:
	if not (value is float or value is int) or float(value) <= 0.0 or float(value) > 60.0:
		return _fail("%s : « %s » doit être un nombre > 0" % [where, key])
	return true


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("DarknessProfile : " + message)
	return false
