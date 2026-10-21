class_name ElevatorLibrary
extends RefCounted
## Ascenseurs de Kanto, lus dans `data/world/elevators.json` (jalon 20 T5, docs/tech/jalon-20.md
## §2.3.1). Classe pure, sans nœud.
## [codeblock]
## { "elevators": { "celadon_dept": {
##     "car": "celadon_dept_elevator", "key": "",
##     "floors": [ { "id": "gf", "label": "RdC", "map": "celadon_dept_gf",
##                   "spawn": "from_elevator" }, … ] } } }
## [/codeblock]
## Racine : « elevators » et « _doc » (texte libre, ignoré). Clés d'un ascenseur : « car »
## (carte de la cabine, non vide, une seule fois dans le fichier), « key » (objet exigé, "" =
## aucun), « floors » (liste non vide). Clés d'un étage : « id », « label », « map », « spawn »
## (textes non vides) ; un identifiant ou une carte d'étage n'apparaît qu'une fois par ascenseur,
## et la cabine n'est pas un étage. Toute clé inconnue est une erreur ; un ascenseur invalide est
## écarté, l'erreur signalée ([method get_errors], push_error). Que les cartes et leurs points
## d'apparition existent, et que la clé soit un objet clé, se vérifie avec les vraies données
## (`test_elevator_library`, dès qu'elles existent).

const DATA_PATH: String = "res://data/world/elevators.json"
const _ROOT_KEYS: Array[String] = ["_doc", "elevators"]
const _ELEVATOR_KEYS: Array[String] = ["car", "key", "floors"]
const _FLOOR_KEYS: Array[String] = ["id", "label", "map", "spawn"]

## Ascenseur → données (ordre du fichier).
var _elevators: Dictionary[StringName, ElevatorData] = {}
## Carte de cabine → ascenseur.
var _by_car: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les ascenseurs
## valides sont gardés).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"elevators\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les ascenseurs d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("elevators") is Dictionary:
		return _fail("%s : « elevators » doit être un objet { ascenseur: { car, key, floors } }"
			% source)
	var elevators: Dictionary = data["elevators"]
	for key: Variant in elevators:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant d'ascenseur vide" % source)
			continue
		if _elevators.has(id):
			ok = _fail("%s : ascenseur déjà défini" % where)
			continue
		var elevator := _parse_elevator(id, elevators[key], where)
		if elevator == null:
			ok = false
			continue
		_elevators[id] = elevator
		_by_car[elevator.car] = id
	return ok


## Ascenseur dont [param map_id] est la cabine ; null hors cabine.
func for_car(map_id: StringName) -> ElevatorData:
	return _elevators.get(_by_car.get(map_id, &""))


## Vrai si [param map_id] est une cabine d'ascenseur (jamais une position sauvée).
func is_car(map_id: StringName) -> bool:
	return _by_car.has(map_id)


## Ascenseur [param id] ; null s'il est inconnu.
func get_elevator(id: StringName) -> ElevatorData:
	return _elevators.get(id)


## Identifiants des ascenseurs, dans l'ordre du fichier.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_elevators.keys())
	return ids


func size() -> int:
	return _elevators.size()


func get_errors() -> PackedStringArray:
	return _errors


func _parse_elevator(id: StringName, raw: Variant, where: String) -> ElevatorData:
	if not raw is Dictionary:
		_fail("%s : un ascenseur est un objet { car, key, floors }" % where)
		return null
	var entry: Dictionary = raw
	var valid := true
	for key: Variant in entry:
		if not _ELEVATOR_KEYS.has(str(key)):
			valid = _fail("%s : clé inconnue « %s »" % [where, key])
	var car: Variant = entry.get("car")
	if not car is String or (car as String).strip_edges().is_empty():
		return _fail_null("%s : « car » doit être une carte non vide" % where)
	if _by_car.has(StringName(car)):
		return _fail_null("%s : cabine « %s » déjà utilisée" % [where, car])
	var key_item: Variant = entry.get("key")
	if not key_item is String:
		return _fail_null("%s : « key » doit être un objet ou \"\"" % where)
	if not entry.get("floors") is Array or (entry["floors"] as Array).is_empty():
		return _fail_null("%s : « floors » doit être une liste non vide d'étages" % where)
	var elevator := ElevatorData.new()
	elevator.id = id
	elevator.car = StringName(car)
	elevator.key = StringName((key_item as String).strip_edges())
	for value: Variant in entry["floors"]:
		var floor_entry := _parse_floor(value, where)
		if floor_entry.is_empty():
			return null
		if elevator.has_floor(floor_entry["id"]):
			return _fail_null("%s : étage « %s » en double" % [where, floor_entry["id"]])
		if not elevator.floor_for_map(floor_entry["map"]).is_empty():
			return _fail_null("%s : carte « %s » desservie deux fois"
				% [where, floor_entry["map"]])
		if floor_entry["map"] == elevator.car:
			return _fail_null("%s : la cabine n'est pas un étage" % where)
		elevator.floors.append(floor_entry)
	return elevator if valid else null


func _parse_floor(raw: Variant, where: String) -> Dictionary:
	if not raw is Dictionary:
		_fail("%s : un étage est un objet { id, label, map, spawn }" % where)
		return {}
	var entry: Dictionary = raw
	var valid := true
	for key: Variant in entry:
		if not _FLOOR_KEYS.has(str(key)):
			valid = _fail("%s : clé inconnue « floors.%s »" % [where, key])
	for key: String in _FLOOR_KEYS:
		var value: Variant = entry.get(key)
		if not value is String or (value as String).strip_edges().is_empty():
			valid = _fail("%s : « floors.%s » doit être un texte non vide" % [where, key])
	if not valid:
		return {}
	return {"id": StringName(entry["id"]), "label": String(entry["label"]),
		"map": StringName(entry["map"]), "spawn": StringName(entry["spawn"])}


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("ElevatorLibrary : " + message)
	return false


func _fail_null(message: String) -> ElevatorData:
	_fail(message)
	return null
