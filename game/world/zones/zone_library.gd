class_name ZoneLibrary
extends RefCounted
## Zones du Kanto du projet, lues dans `data/world/zones.json` (jalon-06.md §3.2, §3.6).
##
## Classe pure. Une zone regroupe des cartes : le Labo du Prof. Chen et les maisons
## appartiennent à Bourg Palette. Le Menu Dresseur ne parle qu'en zones (nom de la zone
## actuelle, lieu de rencontre d'un Pokémon, Carte). Format :
## [codeblock]
## {
##   "services": {
##     "pokemon_center": { "name": "Centre Pokémon" }
##   },
##   "zones": {
##     "pallet_town": { "name": "Bourg Palette", "kind": "town",
##                      "maps": ["pallet_town", "player_house_1f", "oak_lab"],
##                      "description": "…", "draft": true },
##     "route_1": { "name": "Route 1", "kind": "route", "maps": ["route_1"],
##                  "subtitle": "Bourg Palette — Jadielle", "description": "…",
##                  "draft": true },
##     "viridian_city": { "name": "Jadielle", "kind": "town", "maps": ["viridian_center"],
##                        "services": [ { "id": "pokemon_center",
##                                        "found_on": "viridian_center" } ] }
##   }
## }
## [/codeblock]
## « kind » : une valeur de [constant ZoneData.KINDS]. « maps » (facultatif, liste vide par
## défaut) : chaque carte n'appartient qu'à une zone. « subtitle » et « description »
## (facultatifs, textes non vides) : panneau de la Carte ; « draft » : textes provisoires.
## « interior_title » (facultatif, false par défaut) : le titre de zone s'affiche aussi à
## l'arrivée dans les cartes intérieures de la zone (S.S. Anne : dès le pont principal, J16).
## « services » (facultatif) : chaque service vient du catalogue « services » (lu avant les
## zones du même objet) et se découvre sur une carte de la zone (« found_on »).
## Toute clé inconnue est une erreur ; une zone invalide est écartée, l'erreur signalée
## ([method get_errors], push_error). Le rectangle d'une zone sur l'illustration n'est pas
## ici : il appartient à l'illustration ([MapIllustration]), refaite en phase DA.

const DEFAULT_PATH: String = "res://data/world/zones.json"

const _ROOT_KEYS: Array[String] = ["services", "zones"]
const _ZONE_KEYS: Array[String] = ["name", "kind", "maps", "subtitle", "description", "draft",
	"services", "interior_title"]
const _SERVICE_KEYS: Array[String] = ["name"]
const _ZONE_SERVICE_KEYS: Array[String] = ["id", "found_on"]

var _zones: Dictionary[StringName, ZoneData] = {}
var _by_map: Dictionary[StringName, StringName] = {}
## Catalogue des services : identifiant → nom affiché.
var _service_names: Dictionary[StringName, String] = {}
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
	if data.has("services") and not _parse_service_catalog(data["services"], source):
		ok = false
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


## Vrai si la carte [param map_id], même intérieure, annonce le titre de sa zone à l'arrivée
## ([member ZoneData.interior_title]).
func interior_title_of(map_id: StringName) -> bool:
	var zone := get_zone(zone_of(map_id))
	return zone != null and zone.interior_title


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


## Nom affiché du service [param id] (« Centre Pokémon ») ; "" s'il n'est pas au catalogue.
func service_name(id: StringName) -> String:
	return _service_names.get(id, "")


## Identifiants du catalogue des services, dans l'ordre du fichier.
func get_service_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_service_names.keys())
	return ids


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
	for key: String in ["subtitle", "description"]:
		if entry.has(key) and not _is_text(entry[key]):
			ok = _fail("%s : « %s » est un texte non vide" % [where, key])
	if _is_text(entry.get("subtitle")):
		zone.subtitle = entry["subtitle"]
	if _is_text(entry.get("description")):
		zone.description = entry["description"]
	if entry.has("draft") and not entry["draft"] is bool:
		ok = _fail("%s : « draft » vaut true ou false" % where)
	zone.draft = entry.get("draft") is bool and bool(entry["draft"])
	if entry.has("interior_title") and not entry["interior_title"] is bool:
		ok = _fail("%s : « interior_title » vaut true ou false" % where)
	zone.interior_title = entry.get("interior_title") is bool and bool(entry["interior_title"])
	if entry.has("services") and not _parse_zone_services(entry["services"], zone, where):
		ok = false
	return zone if ok else null


func _parse_service_catalog(value: Variant, source: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « services » doit être un objet { identifiant: { name } }" % source)
	var ok := true
	var catalog: Dictionary = value
	for key: Variant in catalog:
		var id := StringName(str(key))
		var where := "%s, service « %s »" % [source, id]
		if id.is_empty() or not catalog[key] is Dictionary:
			ok = _fail("%s : un objet { name } est attendu" % where)
			continue
		if _service_names.has(id):
			ok = _fail("%s : service déjà défini" % where)
			continue
		var entry: Dictionary = catalog[key]
		var valid := true
		for field: Variant in entry:
			if not _SERVICE_KEYS.has(str(field)):
				valid = _fail("%s : clé inconnue « %s »" % [where, field])
		if not _is_text(entry.get("name")):
			valid = _fail("%s : « name » est un texte non vide" % where)
		if valid:
			_service_names[id] = entry["name"]
		else:
			ok = false
	return ok


## Services d'une zone : chacun au catalogue, une seule fois, découvert sur une carte de la
## zone.
func _parse_zone_services(value: Variant, zone: ZoneData, where: String) -> bool:
	if not value is Array:
		return _fail("%s : « services » est une liste de { id, found_on }" % where)
	var ok := true
	for raw: Variant in value:
		if not raw is Dictionary:
			ok = _fail("%s : « services » est une liste de { id, found_on }" % where)
			continue
		var entry: Dictionary = raw
		var valid := true
		for field: Variant in entry:
			if not _ZONE_SERVICE_KEYS.has(str(field)):
				valid = _fail("%s : service, clé inconnue « %s »" % [where, field])
		var id := StringName(str(entry.get("id", "")))
		var map := StringName(str(entry.get("found_on", "")))
		if not _is_text(entry.get("id")) or not _service_names.has(id):
			valid = _fail("%s : service « %s » absent du catalogue « services »" % [where, id])
		elif _has_service(zone, id):
			valid = _fail("%s : service « %s » en double" % [where, id])
		elif not _is_text(entry.get("found_on")) or not zone.maps.has(map):
			valid = _fail("%s : service « %s » : « found_on » doit être une carte de la zone"
				% [where, id])
		if valid:
			zone.services.append(ZoneService.new(id, map))
		else:
			ok = false
	return ok


static func _has_service(zone: ZoneData, id: StringName) -> bool:
	for service: ZoneService in zone.services:
		if service.id == id:
			return true
	return false


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _fail(message: String) -> bool:
	var full := "ZoneLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
