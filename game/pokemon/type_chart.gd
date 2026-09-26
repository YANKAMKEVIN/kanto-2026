class_name TypeChart
extends RefCounted
## Table des types moderne (18 types), lue dans `data/pokemon/types.json`.
##
## Classe pure (docs/tech/jalon-04.md §2.1 et §3.2). Format :
## [codeblock]
## {
##   "types": { "normal": { "name": "Normal" }, "fire": { "name": "Feu" }, ... },
##   "chart": { "fire": { "grass": 2, "water": 0.5 }, "normal": { "ghost": 0 }, ... }
## }
## [/codeblock]
## « chart » : type attaquant → type défenseur → multiplicateur ; seules les valeurs ≠ 1
## sont écrites, et elles valent 0, 0.5 ou 2. Toute clé inconnue, tout type absent de
## « types » est une erreur ([method get_errors], push_error). Les couleurs des types
## restent dans `UiTokens` (présentation), pas ici.

const DATA_PATH: String = "res://data/pokemon/types.json"
## Valeurs admises dans « chart ».
const MULTIPLIERS: Array[float] = [0.0, 0.5, 2.0]

const _TYPE_KEYS: Array[String] = ["name"]

var _names: Dictionary[StringName, String] = {}
var _ids: Array[StringName] = []
## attaquant → (défenseur → multiplicateur).
var _chart: Dictionary[StringName, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les
## entrées valides sont gardées).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"types\": …, \"chart\": … } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not ["types", "chart"].has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("types") is Dictionary or (data.get("types") as Dictionary).is_empty():
		return _fail("%s : « types » doit être un objet non vide" % source)
	var types: Dictionary = data["types"]
	for key: Variant in types:
		ok = _parse_type(StringName(str(key)), types[key], source) and ok
	if data.has("chart"):
		if not data["chart"] is Dictionary:
			return _fail("%s : « chart » doit être un objet" % source)
		var chart: Dictionary = data["chart"]
		for key: Variant in chart:
			ok = _parse_row(StringName(str(key)), chart[key], source) and ok
	return ok


func has_type(id: StringName) -> bool:
	return _names.has(id)


## Nom affiché du type (« Feu »), ou chaîne vide s'il n'existe pas.
func get_type_name(id: StringName) -> String:
	return _names.get(id, "")


## Types connus, dans l'ordre du fichier.
func get_type_ids() -> Array[StringName]:
	return _ids.duplicate()


## Multiplicateur d'un type attaquant contre un seul type défenseur (1 par défaut).
func single(attack_type: StringName, defender_type: StringName) -> float:
	var row: Dictionary = _chart.get(attack_type, {})
	return row.get(defender_type, 1.0)


## Produit des multiplicateurs contre les types du défenseur. [param attack_type] vide
## (capacité sans type, Lutte) → 1.
func multiplier(attack_type: StringName, defender_types: Array[StringName]) -> float:
	if attack_type.is_empty():
		return 1.0
	var result := 1.0
	for defender: StringName in defender_types:
		result *= single(attack_type, defender)
	return result


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_type(id: StringName, value: Variant, source: String) -> bool:
	var where := "%s type « %s »" % [source, id]
	if id.is_empty():
		return _fail("%s : identifiant de type vide" % source)
	if _names.has(id):
		return _fail("%s : déjà défini" % where)
	if not value is Dictionary:
		return _fail("%s : un objet { \"name\": … } est attendu" % where)
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _TYPE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	if not entry.get("name") is String or (entry.get("name") as String).strip_edges().is_empty():
		return _fail("%s : « name » doit être un texte non vide" % where)
	if not ok:
		return false
	_names[id] = entry["name"]
	_ids.append(id)
	return true


func _parse_row(attacker: StringName, value: Variant, source: String) -> bool:
	var where := "%s chart « %s »" % [source, attacker]
	if not _names.has(attacker):
		return _fail("%s : type attaquant inconnu" % where)
	if _chart.has(attacker):
		return _fail("%s : ligne déjà définie" % where)
	if not value is Dictionary:
		return _fail("%s : un objet { défenseur: multiplicateur } est attendu" % where)
	var row: Dictionary = {}
	var ok := true
	var entries: Dictionary = value
	for key: Variant in entries:
		var defender := StringName(str(key))
		var factor: Variant = entries[key]
		if not _names.has(defender):
			ok = _fail("%s : type défenseur inconnu « %s »" % [where, defender])
		elif not (factor is float or factor is int) or not MULTIPLIERS.has(float(factor)):
			ok = _fail("%s « %s » : multiplicateur 0, 0.5 ou 2 attendu" % [where, defender])
		else:
			row[defender] = float(factor)
	_chart[attacker] = row
	return ok


func _fail(message: String) -> bool:
	var full := "TypeChart : " + message
	_errors.append(full)
	push_error(full)
	return false
