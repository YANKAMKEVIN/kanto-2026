class_name EncounterLibrary
extends RefCounted
## Toutes les tables de rencontres, lues dans les fichiers JSON de `data/encounters/`
## (jalon 5 §2.2, §3.6).
##
## Classe pure, validation stricte comme [ItemLibrary] et [PokemonData]. Chaque fichier est un
## objet « identifiant de table → table » ; les identifiants sont uniques dans tout le dossier
## et [b]au plus une table par couple (carte, terrain)[/b] :
## [codeblock]
## "route_1_grass": {
##   "maps": ["route_1", "pallet_town"], "terrain": "grass", "rate": 25,
##   "slots": [ { "species": "pidgey", "levels": [3, 3], "weight": 20 }, ... ]
## }
## [/codeblock]
## Clés obligatoires : maps (liste non vide), terrain ([constant EncounterTable.TERRAINS]),
## rate (1..255), slots (liste non vide). Un emplacement : species (espèce connue de
## [PokemonData]), levels ([min, max], 1..100, min ≤ max), weight (> 0). Les cartes ne sont
## pas vérifiées ici (tests de données, §4). Clé facultative « ramp » (montée du taux avec les
## pas d'herbe sans rencontre, voir [method EncounterTable.effective_rate]) :
## [code]"ramp": { "from_step": 15, "max_steps": 20 }[/code] avec 1 ≤ from_step < max_steps ≤ 255.
## Sans « ramp », le taux reste fixe. Une entrée invalide est écartée
## ([method get_errors], push_error).

const DATA_DIR: String = "res://data/encounters/"

const _KEYS: Array[String] = ["maps", "terrain", "rate", "slots"]
const _GRASS: StringName = &"grass"
const _OPTIONAL_KEYS: Array[String] = ["ramp"]
const _RAMP_KEYS: Array[String] = ["from_step", "max_steps"]
const _SLOT_KEYS: Array[String] = ["species", "levels", "weight"]

var _data: PokemonData
var _tables: Dictionary[StringName, EncounterTable] = {}
## Index « carte|terrain » → identifiant de table (unicité du couple).
var _by_map: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## [param pokemon_data] valide les espèces des emplacements.
func _init(pokemon_data: PokemonData) -> void:
	_data = pokemon_data


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une erreur a
## été signalée (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var sorted: Array[String] = []
	sorted.assign(DirAccess.get_files_at(dir))
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = load_file(dir.path_join(file)) and ok
	return ok


## Charge un fichier JSON. Faux s'il est illisible ou contient une erreur.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: table } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les tables d'un dictionnaire déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _tables.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _tables[id].source])
			continue
		var table := _parse_table(data[key], where)
		if table == null:
			ok = false
			continue
		table.id = id
		table.source = source
		if not _register_maps(table, where):
			ok = false
			continue
		_tables[id] = table
	return ok


## Table pour [param map_id] sur [param terrain], ou null.
func get_table(map_id: StringName, terrain: StringName = &"grass") -> EncounterTable:
	var id: StringName = _by_map.get(_map_key(map_id, terrain), &"")
	return _tables.get(id)


func has_table(map_id: StringName, terrain: StringName = &"grass") -> bool:
	return _by_map.has(_map_key(map_id, terrain))


## Débogage (départ de débogage, clé « wild ») : remplace la table d'herbes de [param map_id]
## par [param entry] (une table sans « maps » ni « terrain » : « rate », « slots », « ramp »).
## Faux (erreur signalée) si la table est invalide : rien ne change. Cas « herbes » de
## [method override_table] (jalon 12, T20).
func override_grass(map_id: StringName, entry: Dictionary, source: String = "") -> bool:
	return override_table(map_id, _GRASS, entry, source)


## Débogage (jalon 12, T20) : remplace la table de [param map_id] sur [param terrain]
## ([constant EncounterTable.TERRAINS]) par [param entry] (sans « maps » ni « terrain »).
## Faux (erreur signalée) si le terrain est inconnu ou la table invalide : rien ne change.
func override_table(map_id: StringName, terrain: StringName, entry: Dictionary,
		source: String = "") -> bool:
	if not EncounterTable.TERRAINS.has(terrain):
		return _fail("%s : terrain inconnu « %s » (%s)" % [source, terrain,
			", ".join(PackedStringArray(EncounterTable.TERRAINS))])
	var full := entry.duplicate()
	if full.has("maps") or full.has("terrain"):
		return _fail("%s : ni « maps » ni « terrain » dans une table forcée" % source)
	full["maps"] = [String(map_id)]
	full["terrain"] = String(terrain)
	var table := _parse_table(full, source)
	if table == null:
		return false
	# Herbes : identifiant d'avant le T20 (« debug_<carte> ») ; autres terrains suffixés.
	var suffix := "" if terrain == _GRASS else "_%s" % terrain
	table.id = StringName("debug_%s%s" % [map_id, suffix])
	table.source = source
	_tables[table.id] = table
	_by_map[_map_key(map_id, terrain)] = table.id
	return true


## Identifiants des tables, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_tables.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func size() -> int:
	return _tables.size()


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


# --- Lecture ---------------------------------------------------------------------------

func _parse_table(value: Variant, where: String) -> EncounterTable:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var ok := _check_keys(entry, _KEYS + _OPTIONAL_KEYS, _KEYS, where)
	var table := EncounterTable.new()
	if entry.has("terrain"):
		if not entry["terrain"] is String \
				or not EncounterTable.TERRAINS.has(StringName(str(entry["terrain"]))):
			ok = _fail("%s : « terrain » vaut %s" % [where,
				", ".join(PackedStringArray(EncounterTable.TERRAINS))])
		else:
			table.terrain = StringName(entry["terrain"])
	if entry.has("rate"):
		if not _is_int(entry["rate"]) or int(entry["rate"]) < 1 or int(entry["rate"]) > 255:
			ok = _fail("%s : « rate » est un entier de 1 à 255" % where)
		else:
			table.rate = int(entry["rate"])
	if entry.has("ramp"):
		ok = _read_ramp(entry["ramp"], table, where) and ok
	if entry.has("maps"):
		ok = _read_maps(entry["maps"], table.maps, where) and ok
	if entry.has("slots"):
		ok = _read_slots(entry["slots"], table.slots, where) and ok
	return table if ok else null


func _read_ramp(value: Variant, table: EncounterTable, where: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « ramp » doit être un objet { from_step, max_steps }" % where)
	var entry: Dictionary = value
	if not _check_keys(entry, _RAMP_KEYS, _RAMP_KEYS, where + " « ramp »"):
		return false
	if not _is_int(entry["from_step"]) or not _is_int(entry["max_steps"]) \
			or int(entry["from_step"]) < 1 or int(entry["max_steps"]) > 255 \
			or int(entry["from_step"]) >= int(entry["max_steps"]):
		return _fail("%s : « ramp » demande des entiers 1 ≤ from_step < max_steps ≤ 255" % where)
	table.ramp_from = int(entry["from_step"])
	table.ramp_max = int(entry["max_steps"])
	return true


func _read_maps(value: Variant, into: Array[StringName], where: String) -> bool:
	if not value is Array or (value as Array).is_empty():
		return _fail("%s : « maps » doit être une liste non vide" % where)
	for map: Variant in value:
		if not map is String or (map as String).is_empty():
			return _fail("%s : identifiant de carte invalide dans « maps »" % where)
		if into.has(StringName(map)):
			return _fail("%s : carte « %s » en double dans « maps »" % [where, map])
		into.append(StringName(map))
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
	var slot := EncounterSlot.new()
	var ok := true
	if not entry["species"] is String or (entry["species"] as String).is_empty():
		ok = _fail("%s : « species » doit être un identifiant d'espèce" % where)
	elif _data == null or not _data.has_species(StringName(entry["species"])):
		ok = _fail("%s : espèce inconnue « %s »" % [where, entry["species"]])
	else:
		slot.species = StringName(entry["species"])
	if not entry["levels"] is Array or (entry["levels"] as Array).size() != 2 \
			or not _is_int(entry["levels"][0]) or not _is_int(entry["levels"][1]):
		ok = _fail("%s : « levels » doit être [min, max]" % where)
	else:
		var lo := int(entry["levels"][0])
		var hi := int(entry["levels"][1])
		if lo < 1 or hi > ExpCurve.MAX_LEVEL or lo > hi:
			ok = _fail("%s : niveaux de 1 à %d, min ≤ max" % [where, ExpCurve.MAX_LEVEL])
		else:
			slot.min_level = lo
			slot.max_level = hi
	if not _is_int(entry["weight"]) or int(entry["weight"]) < 1:
		ok = _fail("%s : « weight » doit être un entier > 0" % where)
	else:
		slot.weight = int(entry["weight"])
	return slot if ok else null


## Réserve les couples (carte, terrain) de [param table] ; faux si l'un est déjà pris.
func _register_maps(table: EncounterTable, where: String) -> bool:
	for map: StringName in table.maps:
		var key := _map_key(map, table.terrain)
		if _by_map.has(key):
			return _fail("%s : « %s » (%s) a déjà la table « %s »" % [where, map, table.terrain,
				_by_map[key]])
	for map: StringName in table.maps:
		_by_map[_map_key(map, table.terrain)] = table.id
	return true


func _map_key(map_id: StringName, terrain: StringName) -> StringName:
	return StringName("%s|%s" % [map_id, terrain])


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
	var full := "EncounterLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> EncounterTable:
	_fail(message)
	return null
