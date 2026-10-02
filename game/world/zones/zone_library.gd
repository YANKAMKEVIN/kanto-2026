class_name ZoneLibrary
extends RefCounted
## Zones du Kanto du projet, lues dans `data/world/zones.json` (jalon-06.md §3.2, §3.6).
##
## Classe pure. Une zone regroupe des cartes : le Labo du Prof. Chen et les maisons
## appartiennent à Bourg Palette. Le Menu Dresseur ne parle qu'en zones (nom de la zone
## actuelle, lieu de rencontre d'un Pokémon, Carte). Format :
## [codeblock]
## {
##   "zones": {
##     "pallet_town": { "name": "Bourg Palette", "kind": "town",
##                      "maps": ["pallet_town", "player_house_1f", "oak_lab"] },
##     "route_1": { "name": "Route 1", "kind": "route", "maps": ["route_1"] }
##   }
## }
## [/codeblock]
## « kind » : une valeur de [constant ZoneData.KINDS]. « maps » (facultatif, liste vide par
## défaut) : chaque carte n'appartient qu'à une zone. Toute clé inconnue est une erreur ;
## une zone invalide est écartée, l'erreur signalée ([method get_errors], push_error).
## Le T18 ajoutera sous-titre, description et services (pas le rectangle sur l'illustration,
## qui reste dans le fichier de l'illustration).

const DEFAULT_PATH: String = "res://data/world/zones.json"

const _ROOT_KEYS: Array[String] = ["zones"]
const _ZONE_KEYS: Array[String] = ["name", "kind", "maps"]

var _zones: Dictionary[StringName, ZoneData] = {}
var _by_map: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les zones
## valides sont gardées).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"zones\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les zones d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("zones") is Dictionary:
		return _fail("%s : « zones » doit être un objet { identifiant: zone }" % source)
	var zones: Dictionary = data["zones"]
	for key: Variant in zones:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _zones.has(id):
			ok = _fail("%s : zone déjà définie dans %s" % [where, _zones[id].source])
			continue
		var zone := _parse_zone(zones[key], where)
		if zone == null:
			ok = false
			continue
		zone.id = id
		zone.source = source
		_zones[id] = zone
		for map_id: StringName in zone.maps:
			_by_map[map_id] = id
	return ok


## Zone de la carte [param map_id] (&"" si la carte n'est rangée nulle part).
func zone_of(map_id: StringName) -> StringName:
	return _by_map.get(map_id, &"")


## Nom de la zone de la carte [param map_id] ("" si la carte n'est rangée nulle part).
func zone_name_of(map_id: StringName) -> String:
	var zone := get_zone(zone_of(map_id))
	return zone.name if zone != null else ""


## Zone [param id], ou null.
func get_zone(id: StringName) -> ZoneData:
	return _zones.get(id)


func has_zone(id: StringName) -> bool:
	return _zones.has(id)


## Identifiants des zones, dans l'ordre du fichier.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_zones.keys())
	return ids


## Toutes les cartes rangées dans une zone.
func get_maps() -> Array[StringName]:
	var maps: Array[StringName] = []
	maps.assign(_by_map.keys())
	return maps


func size() -> int:
	return _zones.size()


## Erreurs signalées depuis la création (fichiers et zones écartés).
func get_errors() -> PackedStringArray:
	return _errors


func _parse_zone(value: Variant, where: String) -> ZoneData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _ZONE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var zone := ZoneData.new()
	if not _is_text(entry.get("name")):
		ok = _fail("%s : « name » est un texte non vide" % where)
	else:
		zone.name = entry["name"]
	var kind := StringName(str(entry.get("kind", "")))
	if not entry.get("kind") is String or not ZoneData.KINDS.has(kind):
		ok = _fail("%s : « kind » vaut town, route, place ou sea_route" % where)
	else:
		zone.kind = kind
	var raw_maps: Variant = entry.get("maps", [])
	if not raw_maps is Array:
		ok = _fail("%s : « maps » est une liste d'identifiants de cartes" % where)
	else:
		for map: Variant in raw_maps:
			var map_id := StringName(str(map))
			if not _is_text(map):
				ok = _fail("%s : « maps » est une liste d'identifiants de cartes" % where)
			elif zone.maps.has(map_id):
				ok = _fail("%s : carte « %s » en double" % [where, map_id])
			elif _by_map.has(map_id):
				ok = _fail("%s : carte « %s » déjà rangée dans « %s »" % [where, map_id,
					_by_map[map_id]])
			else:
				zone.maps.append(map_id)
	return zone if ok else null


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _fail(message: String) -> bool:
	var full := "ZoneLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
