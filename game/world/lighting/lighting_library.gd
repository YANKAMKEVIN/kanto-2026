class_name LightingLibrary
extends RefCounted
## Profils de lumière du monde, lus dans `data/world/lighting.json` (docs/tech/jalon-07.md
## §3.2). Classe pure, sans nœud : `Boot` la tient comme les autres bibliothèques et
## `WorldLighting` (T3) applique le profil nommé par `GameMap.light_profile`.
## [codeblock]
## {
##   "profiles": {
##     "golden_hour": {
##       "grade": { "shadows": [1.16, 1.07, 0.97], "midtones": [1.06, 1.01, 0.91],
##                  "highlights": [1.01, 0.97, 0.85], "strength": 1.0 },
##       "sun_direction": [-0.7, -0.7],
##       "rim": { "color": "#ffd17a", "strength": 1.0, "width": 5.0 },
##       "cast_shadow": { "color": "#1a1738", "alpha": 0.34, "length": 0.26,
##                        "skew_deg": -45.0 },
##       "contact": { "color": "#1f1a33", "alpha": 0.62 },
##       "wind": 5.0
##     }
##   },
##   "maps": { "viridian_city": "golden_hour", "viridian_center": "interior_warm" }
## }
## [/codeblock]
## « grade.flat » (facultatif, booléen) : étalonnage à plat, sans lecture de l'écran
## ([member LightProfile.grade_flat] ; tons moyens ≤ 1).
## « grade » et « sun_direction » sont obligatoires ; « rim », « cast_shadow », « contact »
## et « wind » sont facultatifs (absents = aucun liseré, aucune ombre portée, aucune ombre de
## contact, arbres immobiles). Dans chaque bloc présent, toutes les clés sont obligatoires.
## Bornes : gains dans ]0, [constant LightProfile.GAIN_MAX]] ; intensités et alphas dans
## [0, 1] (alphas > 0 : un bloc présent se voit) ; « width » dans ]0,
## [constant LightProfile.RIM_WIDTH_MAX]] pixels de texture ; « length » dans ]0, 1] ;
## « skew_deg » dans [−89, 89] ; « wind » dans [0, [constant LightProfile.WIND_MAX]] pixels ;
## « sun_direction » non nulle ; couleurs « #rrggbb » (l'alpha est une clé à part).
## « room » (facultatif, DAF.6, intérieurs : [RoomLight]) : « edge_color », « edge_alpha »,
## « edge_width » (cases, ]0, [constant LightProfile.ROOM_EDGE_MAX]]), « pool_color »,
## « pool_alpha », « pool_center » ([x, y] dans [0, 1]), « pool_radius » (]0,
## [constant LightProfile.ROOM_POOL_RADIUS_MAX]]) ; alphas dans [0, 1].
## « maps » (facultatif) : profil prévu pour chaque carte peinte, que l'outil de construction de
## la carte écrit dans `GameMap.light_profile` (la carte reste la source lue par `Boot`) ; un
## profil inconnu y est une erreur. Toute clé inconnue est une erreur ; un profil invalide est écarté, l'erreur signalée
## ([method get_errors], push_error).

const DATA_PATH: String = "res://data/world/lighting.json"

const _ROOT_KEYS: Array[String] = ["profiles", "maps"]
const _PROFILE_KEYS: Array[String] = [
	"grade", "sun_direction", "rim", "cast_shadow", "contact", "wind", "room",
]
const _GRADE_KEYS: Array[String] = ["shadows", "midtones", "highlights", "strength"]
## Clé facultative de « grade » : « flat » (booléen, [member LightProfile.grade_flat]).
const _GRADE_OPTIONAL_KEYS: Array[String] = ["flat"]
const _RIM_KEYS: Array[String] = ["color", "strength", "width"]
const _CAST_KEYS: Array[String] = ["color", "alpha", "length", "skew_deg"]
const _CONTACT_KEYS: Array[String] = ["color", "alpha"]
const _ROOM_KEYS: Array[String] = [
	"edge_color", "edge_alpha", "edge_width", "pool_color", "pool_alpha", "pool_center",
	"pool_radius",
]

var _profiles: Dictionary[StringName, LightProfile] = {}
var _maps: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les profils
## valides sont gardés).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"profiles\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les profils d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("profiles") is Dictionary:
		return _fail("%s : « profiles » doit être un objet { identifiant: profil }" % source)
	var profiles: Dictionary = data["profiles"]
	for key: Variant in profiles:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _profiles.has(id):
			ok = _fail("%s : profil déjà défini" % where)
			continue
		var errors := PackedStringArray()
		var profile := parse_profile(profiles[key], errors)
		for message: String in errors:
			_fail("%s : %s" % [where, message])
		if profile == null:
			ok = false
			continue
		profile.id = id
		_profiles[id] = profile
	if data.has("maps"):
		ok = _add_maps(data["maps"], source) and ok
	return ok


## Profil [param id], ou null s'il est inconnu (&"" compris : aucune lumière du monde).
func get_profile(id: StringName) -> LightProfile:
	return _profiles.get(id)


func has_profile(id: StringName) -> bool:
	return _profiles.has(id)


## Identifiants des profils, dans l'ordre du fichier.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_profiles.keys())
	return ids


func size() -> int:
	return _profiles.size()


## Profil prévu pour la carte [param map_id] (section « maps »), &"" si elle n'en a pas.
func get_map_profile(map_id: StringName) -> StringName:
	return _maps.get(map_id, &"")


## Cartes de la section « maps », dans l'ordre du fichier.
func get_planned_maps() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_maps.keys())
	return ids


func get_errors() -> PackedStringArray:
	return _errors


## Valide un profil (objet JSON déjà lu) et le renvoie, ou null s'il est invalide. Les
## erreurs sont **ajoutées** à [param errors], sans préfixe ; l'identifiant n'est pas lu ici.
static func parse_profile(value: Variant, errors: PackedStringArray) -> LightProfile:
	if not value is Dictionary:
		errors.append("un objet est attendu")
		return null
	var entry: Dictionary = value
	var count := errors.size()
	var profile := LightProfile.new()
	_check_keys(entry, _PROFILE_KEYS, "", errors)
	if not entry.has("grade"):
		errors.append("« grade » est obligatoire")
	elif _block(entry["grade"], _GRADE_KEYS, "grade", errors, _GRADE_OPTIONAL_KEYS):
		var grade: Dictionary = entry["grade"]
		profile.grade_shadows = _gains(grade, "shadows", errors)
		profile.grade_midtones = _gains(grade, "midtones", errors)
		profile.grade_highlights = _gains(grade, "highlights", errors)
		profile.grade_strength = _number(grade, "strength", "grade", 0.0, 1.0, true, errors)
		if grade.has("flat"):
			if not grade["flat"] is bool:
				errors.append("« grade.flat » doit être un booléen")
			elif grade["flat"]:
				# Le calque multiplie : il ne peut qu'assombrir (gains des tons moyens ≤ 1).
				var mid := profile.grade_midtones
				if mid.x > 1.0 or mid.y > 1.0 or mid.z > 1.0:
					errors.append("« grade.flat » demande des tons moyens ≤ 1")
				else:
					profile.grade_flat = true
	if not entry.has("sun_direction"):
		errors.append("« sun_direction » est obligatoire")
	else:
		var sun: Variant = entry["sun_direction"]
		if not _is_vector2(sun) or Vector2(float(sun[0]), float(sun[1])).is_zero_approx():
			errors.append("« sun_direction » doit être [x, y], non nulle")
		else:
			profile.sun_direction = Vector2(float(sun[0]), float(sun[1]))
	if entry.has("rim") and _block(entry["rim"], _RIM_KEYS, "rim", errors):
		var rim: Dictionary = entry["rim"]
		profile.rim_color = _color(rim, "rim", errors)
		profile.rim_strength = _number(rim, "strength", "rim", 0.0, 1.0, false, errors)
		profile.rim_width = _number(rim, "width", "rim", 0.0, LightProfile.RIM_WIDTH_MAX,
			false, errors)
	if entry.has("cast_shadow") \
			and _block(entry["cast_shadow"], _CAST_KEYS, "cast_shadow", errors):
		var cast: Dictionary = entry["cast_shadow"]
		profile.cast_shadow_color = _color(cast, "cast_shadow", errors)
		profile.cast_shadow_color.a = _number(cast, "alpha", "cast_shadow", 0.0, 1.0, false,
			errors)
		profile.cast_shadow_length = _number(cast, "length", "cast_shadow", 0.0, 1.0, false,
			errors)
		profile.cast_shadow_skew_deg = _number(cast, "skew_deg", "cast_shadow",
			-LightProfile.SKEW_MAX_DEG, LightProfile.SKEW_MAX_DEG, true, errors)
	if entry.has("contact") and _block(entry["contact"], _CONTACT_KEYS, "contact", errors):
		var contact: Dictionary = entry["contact"]
		profile.contact_color = _color(contact, "contact", errors)
		profile.contact_color.a = _number(contact, "alpha", "contact", 0.0, 1.0, false,
			errors)
	if entry.has("room") and _block(entry["room"], _ROOM_KEYS, "room", errors):
		_parse_room(entry["room"], profile, errors)
	if entry.has("wind"):
		profile.wind_strength = _number(entry, "wind", "", 0.0, LightProfile.WIND_MAX, true,
			errors)
	return profile if errors.size() == count else null


static func _parse_room(room: Dictionary, profile: LightProfile,
		errors: PackedStringArray) -> void:
	profile.room_edge_color = _color(room, "room", errors, "edge_color")
	profile.room_edge_color.a = _number(room, "edge_alpha", "room", 0.0, 1.0, true, errors)
	profile.room_edge_width = _number(room, "edge_width", "room", 0.0,
		LightProfile.ROOM_EDGE_MAX, false, errors)
	profile.room_pool_color = _color(room, "room", errors, "pool_color")
	profile.room_pool_color.a = _number(room, "pool_alpha", "room", 0.0, 1.0, true, errors)
	profile.room_pool_radius = _number(room, "pool_radius", "room", 0.0,
		LightProfile.ROOM_POOL_RADIUS_MAX, false, errors)
	var center: Variant = room["pool_center"]
	if _is_vector2(center) and float(center[0]) >= 0.0 and float(center[0]) <= 1.0 \
			and float(center[1]) >= 0.0 and float(center[1]) <= 1.0:
		profile.room_pool_center = Vector2(float(center[0]), float(center[1]))
	else:
		errors.append("« room.pool_center » doit être [x, y] dans [0, 1]")


## Vrai si [param value] est un objet aux clés exactement [param keys] (toutes présentes,
## aucune autre). Les erreurs sont ajoutées.
static func _block(value: Variant, keys: Array[String], name: String,
		errors: PackedStringArray, optional: Array[String] = []) -> bool:
	if not value is Dictionary:
		errors.append("« %s » doit être un objet { %s }" % [name, ", ".join(keys)])
		return false
	var block: Dictionary = value
	var count := errors.size()
	var allowed: Array[String] = keys.duplicate()
	allowed.append_array(optional)
	_check_keys(block, allowed, name, errors)
	for key: String in keys:
		if not block.has(key):
			errors.append("« %s.%s » est obligatoire" % [name, key])
	return errors.size() == count


static func _check_keys(entry: Dictionary, allowed: Array[String], name: String,
		errors: PackedStringArray) -> void:
	for key: Variant in entry:
		if not allowed.has(str(key)):
			if name.is_empty():
				errors.append("clé inconnue « %s »" % key)
			else:
				errors.append("clé inconnue dans « %s » : « %s »" % [name, key])


## Gains RVB [r, g, b], chacun dans ]0, GAIN_MAX].
static func _gains(block: Dictionary, key: String, errors: PackedStringArray) -> Vector3:
	var value: Variant = block[key]
	if value is Array and (value as Array).size() == 3:
		var gains := Vector3.ONE
		var ok := true
		for i: int in 3:
			var n: Variant = value[i]
			if not (n is float or n is int) or float(n) <= 0.0 \
					or float(n) > LightProfile.GAIN_MAX:
				ok = false
				break
			gains[i] = float(n)
		if ok:
			return gains
	errors.append("« grade.%s » doit être [r, g, b], gains dans ]0, %s]" % [key,
		LightProfile.GAIN_MAX])
	return Vector3.ONE


## Nombre dans [min, max] ([param min_included] faux : ]min, max]).
static func _number(block: Dictionary, key: String, name: String, min_value: float,
		max_value: float, min_included: bool, errors: PackedStringArray) -> float:
	var value: Variant = block[key]
	var label := key if name.is_empty() else "%s.%s" % [name, key]
	if (value is float or value is int) and float(value) <= max_value \
			and (float(value) > min_value or (min_included and float(value) == min_value)):
		return float(value)
	errors.append("« %s » doit être un nombre dans %s%s, %s]" % [label,
		"[" if min_included else "]", min_value, max_value])
	return min_value


## Couleur « #rrggbb » (opaque : l'alpha est une clé à part), clé [param key] du bloc.
static func _color(block: Dictionary, name: String, errors: PackedStringArray,
		key: String = "color") -> Color:
	var value: Variant = block[key]
	if value is String and (value as String).length() == 7 \
			and (value as String).begins_with("#") and Color.html_is_valid(value):
		return Color.html(value)
	errors.append("« %s.%s » doit être une couleur « #rrggbb »" % [name, key])
	return Color.WHITE


static func _is_vector2(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int):
			return false
	return true


func _add_maps(value: Variant, source: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « maps » doit être un objet { carte: profil }" % source)
	var ok := true
	var maps: Dictionary = value
	for key: Variant in maps:
		var map_id := StringName(str(key))
		var profile_id := StringName(str(maps[key]))
		if map_id.is_empty() or not maps[key] is String:
			ok = _fail("%s « maps » : entrée invalide « %s »" % [source, key])
		elif not _profiles.has(profile_id):
			ok = _fail("%s « maps » « %s » : profil inconnu « %s »" % [source, map_id,
				profile_id])
		elif _maps.has(map_id):
			ok = _fail("%s « maps » « %s » : carte déjà définie" % [source, map_id])
		else:
			_maps[map_id] = profile_id
	return ok


func _fail(message: String) -> bool:
	var full := "LightingLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
