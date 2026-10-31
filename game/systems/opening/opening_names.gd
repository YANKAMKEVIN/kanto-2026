class_name OpeningNames
extends RefCounted
## Prénoms proposés et longueur permise (dossier 13, A5 et A7) : `data/opening/names.json`.
##
## Classe pure. Format :
## [codeblock]
## { "max_length": 10,
##   "player": { "default": "Kevin", "suggestions": ["Red", "Sacha", "Kevin"] },
##   "rival":  { "default": "Régis", "suggestions": ["Régis", "Blue", "Gary"] },
##   "heroine": { … }, "rivale": { … } }
## [/codeblock]
## « heroine » et « rivale » (chantier JR, JR-4, facultatifs) : prénoms de la joueuse et de la
## rivale, pris à la place de ceux du rôle quand l'apparence choisie est celle-là.
## Validation stricte au chargement : clé inconnue (hors « _note »), rôle manquant, longueur
## qui n'est pas un entier ≥ 1, prénom invalide ou non normalisé ([NameRules]), doublon,
## 0 ou plus de [constant MAX_SUGGESTIONS] propositions = erreur. Un fichier en erreur n'est
## **pas** appliqué (tout ou rien) : [method is_loaded] reste faux.

const DEFAULT_PATH: String = "res://data/opening/names.json"
const ROLE_PLAYER: StringName = &"player"
const ROLE_RIVAL: StringName = &"rival"
const ROLES: Array[StringName] = [ROLE_PLAYER, ROLE_RIVAL]
## Trois pastilles au plus sous le champ (dossier 13 §5.5).
const MAX_SUGGESTIONS: int = 3
## Prénoms propres à une apparence (facultatifs) : apparence → rôle qu'elle remplace.
const LOOK_ROLES: Dictionary[StringName, StringName] = {
	&"heroine": ROLE_PLAYER,
	&"rivale": ROLE_RIVAL,
}

const _ROOT_KEYS: Array[String] = ["_note", "max_length", "player", "rival", "heroine",
	"rivale"]
const _ROLE_KEYS: Array[String] = ["default", "suggestions"]

var _max_length: int = 0
## Rôle → { "default": String, "suggestions": PackedStringArray }.
var _roles: Dictionary[StringName, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux (et rien d'appliqué) si le fichier manque ou contient une erreur.
func load_file(path: String = DEFAULT_PATH) -> bool:
	var data := OpeningJson.read_object(path, _errors)
	if data.is_empty():
		_report()
		return false
	return add_from_dict(data, path)


## Applique un dictionnaire déjà lu (tout ou rien).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	for key: String in OpeningJson.unknown_keys(data, _ROOT_KEYS):
		errors.append("%s : clé inconnue « %s »" % [source, key])
	var max_length: Variant = data.get("max_length")
	if not JsonFields.is_int(max_length) or int(max_length) < 1:
		errors.append("%s : « max_length » doit être un entier ≥ 1" % source)
		max_length = 0
	var roles: Dictionary[StringName, Dictionary] = {}
	for role: StringName in ROLES:
		var parsed := _parse_role(data.get(String(role)), int(max_length),
			"%s %s" % [source, role], errors)
		if not parsed.is_empty():
			roles[role] = parsed
	for look: StringName in LOOK_ROLES:
		if not data.has(String(look)):
			continue
		var parsed := _parse_role(data[String(look)], int(max_length),
			"%s %s" % [source, look], errors)
		if not parsed.is_empty():
			roles[look] = parsed
	if not errors.is_empty():
		_errors.append_array(errors)
		_report()
		return false
	_max_length = int(max_length)
	_roles = roles
	return true


func is_loaded() -> bool:
	return _max_length > 0


## Nombre de caractères au plus d'un prénom (0 si rien n'est chargé).
func max_length() -> int:
	return _max_length


## Prénom par défaut de [param role] ([constant ROLE_PLAYER] ou [constant ROLE_RIVAL]), ou de
## l'apparence [param look] si elle a les siens ([constant LOOK_ROLES]).
func default_name(role: StringName, look: StringName = &"") -> String:
	return _roles.get(_key(role, look), {}).get("default", "")


## Pastilles de [param role] (ou de l'apparence [param look]), dans l'ordre des données.
func suggestions(role: StringName, look: StringName = &"") -> PackedStringArray:
	return _roles.get(_key(role, look), {}).get("suggestions", PackedStringArray())


func _key(role: StringName, look: StringName) -> StringName:
	return look if LOOK_ROLES.get(look, &"") == role and _roles.has(look) else role


func get_errors() -> PackedStringArray:
	return _errors


func _parse_role(value: Variant, max_length: int, where: String,
		errors: PackedStringArray) -> Dictionary:
	if not value is Dictionary:
		errors.append("%s : objet { default, suggestions } attendu" % where)
		return {}
	var dict := value as Dictionary
	var count := errors.size()
	for key: String in OpeningJson.unknown_keys(dict, _ROLE_KEYS):
		errors.append("%s : clé inconnue « %s »" % [where, key])
	var default_name: Variant = dict.get("default")
	_check_name(default_name, max_length, "%s default" % where, errors)
	var list: Variant = dict.get("suggestions")
	var suggestions := PackedStringArray()
	if not list is Array or (list as Array).is_empty() \
			or (list as Array).size() > MAX_SUGGESTIONS:
		errors.append("%s : 1 à %d « suggestions » attendues" % [where, MAX_SUGGESTIONS])
	else:
		for i: int in (list as Array).size():
			var entry: Variant = list[i]
			if _check_name(entry, max_length, "%s suggestion %d" % [where, i + 1], errors):
				if suggestions.has(entry):
					errors.append("%s : « %s » proposé deux fois" % [where, entry])
				suggestions.append(entry)
	if errors.size() != count:
		return {}
	return {"default": default_name, "suggestions": suggestions}


## Vrai si [param value] est un prénom valide **et déjà normalisé**.
func _check_name(value: Variant, max_length: int, where: String,
		errors: PackedStringArray) -> bool:
	if not value is String:
		errors.append("%s : prénom (texte) attendu" % where)
		return false
	var text := value as String
	if max_length > 0 and NameRules.validate(text, max_length) != NameRules.Result.OK:
		errors.append("%s : « %s » n'est pas un prénom valide" % [where, text])
		return false
	if NameRules.normalize(text) != text:
		errors.append("%s : « %s » n'est pas normalisé (« %s »)"
			% [where, text, NameRules.normalize(text)])
		return false
	return true


func _report() -> void:
	for message: String in _errors:
		push_warning("OpeningNames : " + message)
