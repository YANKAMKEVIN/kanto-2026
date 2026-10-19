class_name WaterRodTables
extends RefCounted
## Tables de pêche (terrain « water_rod », jalon 22 §2.6), lues dans
## `data/fishing/water_rod.json`. Classe pure, validation stricte comme [EncounterLibrary].
##
## [b]Provisoire (T3 → T12).[/b] [EncounterLibrary] charge tout `data/encounters/` et refuse un
## terrain inconnu ([constant EncounterTable.TERRAINS]) : ces tables vivent donc à part jusqu'à
## T12, qui les rangera dans la bibliothèque (clé (carte, terrain, canne)). Les tables produites
## sont de vraies [EncounterTable] ; leur [member EncounterTable.terrain] vaut « water_rod »
## (la classe ne valide pas le terrain, seul le chargeur de la bibliothèque le fait).
## [codeblock]
## "super_rod_fuchsia": { "maps": ["fuchsia_city"], "terrain": "water_rod",
##   "rod": "super_rod", "rate": 75,
##   "slots": [ { "species": "seaking", "level": 23, "weight": 1 }, ... ] }
## [/codeblock]
## Clés obligatoires : maps (liste non vide ; [code]["*"][/code] = table globale de la canne),
## terrain (« water_rod »), rod ([constant FishingRules.RODS]), rate (chance de touche en %,
## 1..100), slots (liste non vide). Facultative : default (booléen ; vrai seulement avec
## [code]["*"][/code] : table par défaut de la Méga Canne, même rôle qu'une table globale).
## Un emplacement : species, level (1..100), weight (> 0). Les espèces ne sont vérifiées que si
## un [PokemonData] est fourni (T12 ajoutera le test « aucune espèce sans données »).
## La chance de touche est aussi rangée dans [member EncounterTable.rate], sur
## [constant EncounterTable.RATE_DEN] (100 % → 256, 50 % → 128, 75 % → 192).

const DATA_PATH: String = "res://data/fishing/water_rod.json"
const TERRAIN: StringName = &"water_rod"
## Carte joker : table valable sur toutes les cartes sans table propre.
const ANY_MAP: StringName = &"*"

const _KEYS: Array[String] = ["maps", "terrain", "rod", "rate", "slots"]
const _OPTIONAL_KEYS: Array[String] = ["default"]
const _SLOT_KEYS: Array[String] = ["species", "level", "weight"]

var _data: PokemonData
var _tables: Dictionary[StringName, EncounterTable] = {}
## Index « carte|canne » → identifiant de table (unicité du couple).
var _by_map: Dictionary[StringName, StringName] = {}
## Identifiant de table → canne.
var _rods: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## [param pokemon_data] : facultatif ; s'il est fourni, les espèces des emplacements doivent
## y exister.
func _init(pokemon_data: PokemonData = null) -> void:
	_data = pokemon_data


## Charge un fichier JSON. Faux s'il est illisible ou contient une erreur (les tables valides
## sont gardées).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _fail("%s : un objet JSON est attendu" % path)
	return add_from_dict(parsed, path)


## Ajoute les tables d'un objet « identifiant → table ». Faux si une entrée est invalide.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if _tables.has(id):
			ok = _fail("%s : identifiant en double" % where)
			continue
		var table := _parse_table(data[key], where)
		if table == null:
			ok = false
			continue
		table.id = id
		table.source = source
		var rod := StringName((data[key] as Dictionary)["rod"])
		if not _register(table, rod, where):
			ok = false
			continue
		_tables[id] = table
		_rods[id] = rod
	return ok


## Table de [param rod] sur [param map_id] : la table propre à la carte, sinon la table
## globale (ou par défaut) de la canne ; null si aucune.
func get_table(rod: StringName, map_id: StringName) -> EncounterTable:
	var key := _key(map_id, rod)
	if not _by_map.has(key):
		key = _key(ANY_MAP, rod)
		if not _by_map.has(key):
			return null
	return _tables[_by_map[key]]


## Canne de la table [param table_id] (&"" si inconnue).
func rod_of(table_id: StringName) -> StringName:
	return _rods.get(table_id, &"")


## Chance de touche (en %) déclarée par la table [param table_id] (0 si inconnue).
func bite_percent_of(table_id: StringName) -> int:
	if not _tables.has(table_id):
		return 0
	return roundi(_tables[table_id].rate * 100.0 / EncounterTable.RATE_DEN)


## Identifiants des tables, triés par ordre alphabétique.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_tables.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func get_errors() -> PackedStringArray:
	return _errors


func _parse_table(value: Variant, where: String) -> EncounterTable:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := _check_keys(entry, _KEYS + _OPTIONAL_KEYS, _KEYS, where)
	if not ok:
		return null
	var table := EncounterTable.new()
	table.terrain = TERRAIN
	if not entry["terrain"] is String or StringName(entry["terrain"]) != TERRAIN:
		ok = _fail("%s : « terrain » vaut %s" % [where, TERRAIN])
	if not entry["rod"] is String or not FishingRules.RODS.has(StringName(entry["rod"])):
		ok = _fail("%s : « rod » vaut %s" % [where,
			", ".join(PackedStringArray(FishingRules.RODS))])
	if not _is_int(entry["rate"]) or int(entry["rate"]) < 1 or int(entry["rate"]) > 100:
		ok = _fail("%s : « rate » est une chance de touche de 1 à 100 (%%)" % where)
	else:
		table.rate = int(entry["rate"]) * EncounterTable.RATE_DEN / 100
	ok = _read_maps(entry["maps"], table.maps, where) and ok
	if entry.has("default"):
		if not entry["default"] is bool:
			ok = _fail("%s : « default » est un booléen" % where)
		elif entry["default"] and not (table.maps.size() == 1 and table.maps[0] == ANY_MAP):
			ok = _fail("%s : « default » demande « maps » = [\"*\"]" % where)
	ok = _read_slots(entry["slots"], table.slots, where) and ok
	return table if ok else null


func _read_maps(value: Variant, into: Array[StringName], where: String) -> bool:
	if not value is Array or (value as Array).is_empty():
		return _fail("%s : « maps » doit être une liste non vide" % where)
	for map: Variant in value:
		if not map is String or (map as String).is_empty():
			return _fail("%s : identifiant de carte invalide dans « maps »" % where)
		if into.has(StringName(map)):
			return _fail("%s : carte « %s » en double dans « maps »" % [where, map])
		into.append(StringName(map))
	if into.size() > 1 and into.has(ANY_MAP):
		return _fail("%s : « * » ne se mélange pas à d'autres cartes" % where)
	return true


func _read_slots(value: Variant, into: Array[EncounterSlot], where: String) -> bool:
	if not value is Array or (value as Array).is_empty():
		return _fail("%s : « slots » doit être une liste non vide" % where)
	var ok := true
	for i: int in (value as Array).size():
		var slot := _parse_slot(value[i], "%s emplacement %d" % [where, i + 1])
		if slot == null:
			ok = false
		else:
			into.append(slot)
	return ok


func _parse_slot(value: Variant, where: String) -> EncounterSlot:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	if not _check_keys(entry, _SLOT_KEYS, _SLOT_KEYS, where):
		return null
	var ok := true
	if not entry["species"] is String or (entry["species"] as String).is_empty():
		ok = _fail("%s : « species » doit être un identifiant d'espèce" % where)
	elif _data != null and not _data.has_species(StringName(entry["species"])):
		ok = _fail("%s : espèce inconnue « %s »" % [where, entry["species"]])
	if not _is_int(entry["level"]) or int(entry["level"]) < 1 \
			or int(entry["level"]) > ExpCurve.MAX_LEVEL:
		ok = _fail("%s : « level » de 1 à %d" % [where, ExpCurve.MAX_LEVEL])
	if not _is_int(entry["weight"]) or int(entry["weight"]) < 1:
		ok = _fail("%s : « weight » doit être un entier > 0" % where)
	if not ok:
		return null
	var level := int(entry["level"])
	return EncounterSlot.new(StringName(entry["species"]), level, level, int(entry["weight"]))


## Réserve les couples (carte, canne) de [param table] ; faux si l'un est déjà pris.
func _register(table: EncounterTable, rod: StringName, where: String) -> bool:
	for map: StringName in table.maps:
		var key := _key(map, rod)
		if _by_map.has(key):
			return _fail("%s : « %s » (%s) a déjà la table « %s »" % [where, map, rod,
				_by_map[key]])
	for map: StringName in table.maps:
		_by_map[_key(map, rod)] = table.id
	return true


func _key(map_id: StringName, rod: StringName) -> StringName:
	return StringName("%s|%s" % [map_id, rod])


func _check_keys(entry: Dictionary, allowed: Array[String], required: Array[String],
		where: String) -> bool:
	var ok := true
	for key: Variant in entry:
		if not allowed.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in required:
		if not entry.has(key):
			ok = _fail("%s : « %s » est obligatoire" % [where, key])
	return ok


static func _is_int(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))


func _fail(message: String) -> bool:
	var full := "WaterRodTables : " + message
	_errors.append(full)
	push_error(full)
	return false
