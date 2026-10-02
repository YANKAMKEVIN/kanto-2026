class_name PokemonData
extends RefCounted
## Point d'entrée des données Pokémon : types, espèces, capacités (jalon 4 §2.1, §3.2).
##
## Classe pure. [method load_dir] lit, sous la racine :
## - `types.json` : table des types ([TypeChart]) ;
## - tous les `.json` de `species/` : objets « identifiant → espèce » ([SpeciesData]) ;
## - tous les `.json` de `moves/` : objets « identifiant → capacité » ([MoveData]).
## Les identifiants sont uniques dans tout un dossier, les numéros de Pokédex aussi.
## Validation stricte, comme [DialogueLibrary] : clé inconnue, clé obligatoire absente,
## valeur hors bornes, identifiant en double, JSON illisible (avec la ligne). Puis
## [b]références croisées[/b] ([method check_references]) : types des espèces et des
## capacités, capacités des learnsets, cibles des évolutions. Une entrée invalide est
## écartée, l'erreur est signalée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/pokemon/"
const TYPES_FILE: String = "types.json"
const SPECIES_DIR: String = "species"
const MOVES_DIR: String = "moves"

const _SPECIES_KEYS: Array[String] = [
	"dex", "name", "types", "base_stats", "male_ratio", "growth_rate", "base_exp", "learnset",
	"evolutions",
]
const _SPECIES_REQUIRED: Array[String] = [
	"dex", "name", "types", "base_stats", "male_ratio", "growth_rate", "base_exp", "learnset",
]
const _MOVE_KEYS: Array[String] = [
	"name", "type", "category", "power", "accuracy", "pp", "priority", "crit_stage", "effects",
	"pending_effects", "description", "draft", "typeless",
]
const _MOVE_REQUIRED: Array[String] = [
	"name", "type", "category", "accuracy", "pp", "description",
]
const _EVOLUTION_KEYS: Dictionary[EvolutionRule.Method, Array] = {
	EvolutionRule.Method.LEVEL: ["into", "method", "level"],
	EvolutionRule.Method.ITEM: ["into", "method", "item"],
	EvolutionRule.Method.TRADE: ["into", "method"],
}
const _EFFECT_KEYS: Dictionary[MoveEffect.Kind, Array] = {
	MoveEffect.Kind.STAT_STAGE: ["kind", "stat", "stages", "target", "chance"],
	MoveEffect.Kind.RECOIL: ["kind", "fraction"],
	MoveEffect.Kind.SEED: ["kind", "fraction", "immune_types"],
}
## Clés d'effet facultatives (toutes les autres de [constant _EFFECT_KEYS] sont obligatoires).
const _EFFECT_OPTIONAL: Array[String] = ["chance", "immune_types"]

var _chart: TypeChart = TypeChart.new()
var _species: Dictionary[StringName, SpeciesData] = {}
var _moves: Dictionary[StringName, MoveData] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge la table des types, les capacités puis les espèces sous [param root], et vérifie
## les références croisées. Faux si une erreur a été signalée (les entrées valides restent).
func load_dir(root: String = DATA_DIR) -> bool:
	var ok := load_types(root.path_join(TYPES_FILE))
	ok = _load_folder(root.path_join(MOVES_DIR), load_moves_file) and ok
	ok = _load_folder(root.path_join(SPECIES_DIR), load_species_file) and ok
	return check_references() and ok


## Charge la table des types (ses erreurs rejoignent [method get_errors]).
func load_types(path: String) -> bool:
	var before := _chart.get_errors().size()
	var ok := _chart.load_file(path)
	for i: int in range(before, _chart.get_errors().size()):
		_errors.append(_chart.get_errors()[i])
	return ok


## Table des types à partir d'un objet déjà lu (tests).
func add_types_from_dict(data: Dictionary, source: String = "") -> bool:
	var before := _chart.get_errors().size()
	var ok := _chart.add_from_dict(data, source)
	for i: int in range(before, _chart.get_errors().size()):
		_errors.append(_chart.get_errors()[i])
	return ok


func load_species_file(path: String) -> bool:
	var data: Variant = _read_json(path, "espèce")
	return data != null and add_species_from_dict(data, path)


func load_moves_file(path: String) -> bool:
	var data: Variant = _read_json(path, "capacité")
	return data != null and add_moves_from_dict(data, path)


## Ajoute les espèces d'un objet déjà lu. Appeler [method check_references] ensuite.
func add_species_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s espèce « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _species.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _species[id].source])
			continue
		var species := _parse_species(data[key], where)
		if species == null:
			ok = false
			continue
		var twin := _species_by_dex(species.dex)
		if twin != null:
			ok = _fail("%s : numéro %d déjà pris par « %s »" % [where, species.dex, twin.id])
			continue
		species.id = id
		species.source = source
		_species[id] = species
	return ok


## Ajoute les capacités d'un objet déjà lu. Appeler [method check_references] ensuite.
func add_moves_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s capacité « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _moves.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _moves[id].source])
			continue
		var move := _parse_move(data[key], where)
		if move == null:
			ok = false
			continue
		move.id = id
		move.source = source
		_moves[id] = move
	return ok


## Vérifie les références entre données (types, capacités, évolutions) et écarte les
## entrées qui en ont une cassée, jusqu'à ce qu'il n'en reste plus. Faux si une entrée a
## été écartée.
func check_references() -> bool:
	var ok := true
	for move: MoveData in _moves.values():
		if not _chart.has_type(move.type):
			ok = _fail("%s capacité « %s » : type inconnu « %s »" % [move.source, move.id,
				move.type])
			_moves.erase(move.id)
			continue
		for effect: MoveEffect in move.effects:
			for type: StringName in effect.immune_types:
				if not _chart.has_type(type) and _moves.has(move.id):
					ok = _fail("%s capacité « %s » : type immunisé inconnu « %s »" % [
						move.source, move.id, type])
					_moves.erase(move.id)
	var changed := true
	while changed:
		changed = false
		for species: SpeciesData in _species.values():
			if not _species_references_ok(species):
				_species.erase(species.id)
				ok = false
				changed = true
	return ok


func has_species(id: StringName) -> bool:
	return _species.has(id)


## Espèce [param id], ou null.
func get_species(id: StringName) -> SpeciesData:
	return _species.get(id)


func has_move(id: StringName) -> bool:
	return _moves.has(id)


## Capacité [param id], ou null.
func get_move(id: StringName) -> MoveData:
	return _moves.get(id)


func get_type_chart() -> TypeChart:
	return _chart


## Identifiants des espèces, par numéro de Pokédex.
func get_species_ids() -> Array[StringName]:
	var list: Array[SpeciesData] = []
	list.assign(_species.values())
	list.sort_custom(func(a: SpeciesData, b: SpeciesData) -> bool: return a.dex < b.dex)
	var ids: Array[StringName] = []
	for species: SpeciesData in list:
		ids.append(species.id)
	return ids


## Identifiants des capacités, triés.
func get_move_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_moves.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Erreurs signalées depuis la création (fichiers et entrées écartés).
func get_errors() -> PackedStringArray:
	return _errors


# --- Lecture ---------------------------------------------------------------------------

func _load_folder(dir: String, loader: Callable) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var sorted: Array[String] = []
	sorted.assign(DirAccess.get_files_at(dir))
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = loader.call(dir.path_join(file)) and ok
	return ok


func _read_json(path: String, what: String) -> Variant:
	if not FileAccess.file_exists(path):
		return _null_fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _null_fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _null_fail("%s : un objet { identifiant: %s } est attendu" % [path, what])
	return json.data


func _parse_species(value: Variant, where: String) -> SpeciesData:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var species := SpeciesData.new()
	var ok := _check_keys(entry, _SPECIES_KEYS, _SPECIES_REQUIRED, where)
	if entry.has("dex"):
		ok = _read_int(entry["dex"], 1, 9999, where + " dex") and ok
		species.dex = int(entry["dex"]) if _is_int(entry["dex"]) else 0
	if entry.has("name"):
		ok = _read_text(entry["name"], where + " name") and ok
		species.name = str(entry["name"])
	if entry.has("types"):
		ok = _read_types(entry["types"], species.types, where) and ok
	if entry.has("base_stats"):
		ok = _read_base_stats(entry["base_stats"], species.base_stats, where) and ok
	if entry.has("male_ratio"):
		var ratio: Variant = entry["male_ratio"]
		if not _is_number(ratio) or not (float(ratio) == -1.0 or
				(float(ratio) >= 0.0 and float(ratio) <= 1.0)):
			ok = _fail("%s : « male_ratio » vaut −1 (asexué) ou un nombre de 0 à 1" % where)
		else:
			species.male_ratio = float(ratio)
	if entry.has("growth_rate"):
		if not ExpCurve.RATE_NAMES.has(str(entry["growth_rate"])) \
				or not entry["growth_rate"] is String:
			ok = _fail("%s : « growth_rate » vaut %s" % [where,
				", ".join(PackedStringArray(ExpCurve.RATE_NAMES.keys()))])
		else:
			species.growth_rate = ExpCurve.RATE_NAMES[entry["growth_rate"]]
	if entry.has("base_exp"):
		ok = _read_int(entry["base_exp"], 1, 1000, where + " base_exp") and ok
		species.base_exp = int(entry["base_exp"]) if _is_int(entry["base_exp"]) else 0
	if entry.has("learnset"):
		ok = _read_learnset(entry["learnset"], species.learnset, where) and ok
	if entry.has("evolutions"):
		ok = _read_evolutions(entry["evolutions"], species.evolutions, where) and ok
	return species if ok else null


func _read_types(value: Variant, into: Array[StringName], where: String) -> bool:
	if not value is Array or not (value as Array).size() in [1, 2]:
		return _fail("%s : « types » doit être une liste de 1 ou 2 types" % where)
	for type: Variant in value:
		if not type is String or (type as String).is_empty():
			return _fail("%s : type invalide dans « types »" % where)
		if into.has(StringName(type)):
			return _fail("%s : type « %s » en double" % [where, type])
		into.append(StringName(type))
	return true


func _read_base_stats(value: Variant, into: Dictionary[StringName, int], where: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « base_stats » doit être un objet" % where)
	var stats: Dictionary = value
	var ok := true
	for key: Variant in stats:
		if not SpeciesData.STATS.has(StringName(str(key))):
			ok = _fail("%s base_stats : clé inconnue « %s »" % [where, key])
	for stat: StringName in SpeciesData.STATS:
		if not stats.has(String(stat)):
			ok = _fail("%s base_stats : « %s » manquant" % [where, stat])
		elif _read_int(stats[String(stat)], 1, 255, "%s base_stats %s" % [where, stat]):
			into[stat] = int(stats[String(stat)])
		else:
			ok = false
	return ok


func _read_learnset(value: Variant, into: Array[Array], where: String) -> bool:
	if not value is Array or (value as Array).is_empty():
		return _fail("%s : « learnset » doit être une liste non vide" % where)
	var previous := 1
	for i: int in (value as Array).size():
		var entry: Variant = value[i]
		var at := "%s learnset %d" % [where, i + 1]
		if not entry is Array or (entry as Array).size() != 2 or not _is_int(entry[0]) \
				or not entry[1] is String or (entry[1] as String).is_empty():
			return _fail("%s : [niveau, capacité] attendu" % at)
		var level := int(entry[0])
		if level < 1 or level > ExpCurve.MAX_LEVEL:
			return _fail("%s : niveau de 1 à %d attendu" % [at, ExpCurve.MAX_LEVEL])
		if level < previous:
			return _fail("%s : les niveaux doivent être croissants" % at)
		previous = level
		into.append([level, StringName(entry[1])])
	return true


func _read_evolutions(value: Variant, into: Array[EvolutionRule], where: String) -> bool:
	if not value is Array:
		return _fail("%s : « evolutions » doit être une liste" % where)
	var ok := true
	for i: int in (value as Array).size():
		var rule := _parse_evolution(value[i], "%s évolution %d" % [where, i + 1])
		if rule == null:
			ok = false
		else:
			into.append(rule)
	return ok


func _parse_evolution(value: Variant, where: String) -> EvolutionRule:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	if not entry.get("method") is String \
			or not EvolutionRule.METHOD_NAMES.has(entry.get("method")):
		return _null_fail("%s : « method » vaut %s" % [where,
			", ".join(PackedStringArray(EvolutionRule.METHOD_NAMES.keys()))])
	var rule := EvolutionRule.new()
	rule.method = EvolutionRule.METHOD_NAMES[entry["method"]]
	var allowed: Array[String] = []
	allowed.assign(_EVOLUTION_KEYS[rule.method])
	var ok := _check_keys(entry, allowed, allowed, where)
	if entry.get("into") is String and not (entry["into"] as String).is_empty():
		rule.into = StringName(entry["into"])
	elif entry.has("into"):
		ok = _fail("%s : « into » doit être un identifiant d'espèce" % where)
	if rule.method == EvolutionRule.Method.LEVEL and entry.has("level"):
		ok = _read_int(entry["level"], 1, ExpCurve.MAX_LEVEL, where + " level") and ok
		rule.level = int(entry["level"]) if _is_int(entry["level"]) else 0
	if rule.method == EvolutionRule.Method.ITEM and entry.has("item"):
		if not entry["item"] is String or (entry["item"] as String).is_empty():
			ok = _fail("%s : « item » doit être un identifiant d'objet" % where)
		else:
			rule.item = StringName(entry["item"])
	return rule if ok else null


func _parse_move(value: Variant, where: String) -> MoveData:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var move := MoveData.new()
	var ok := _check_keys(entry, _MOVE_KEYS, _MOVE_REQUIRED, where)
	if entry.has("name"):
		ok = _read_text(entry["name"], where + " name") and ok
		move.name = str(entry["name"])
	if entry.has("type"):
		if not entry["type"] is String or (entry["type"] as String).is_empty():
			ok = _fail("%s : « type » doit être un identifiant de type" % where)
		else:
			move.type = StringName(entry["type"])
	if entry.has("category"):
		if not entry["category"] is String \
				or not MoveData.CATEGORY_NAMES.has(entry["category"]):
			ok = _fail("%s : « category » vaut physical, special ou status" % where)
		else:
			move.category = MoveData.CATEGORY_NAMES[entry["category"]]
	for field: Array in [["power", 0, 250], ["accuracy", 0, 100], ["pp", 1, 64],
			["priority", -7, 5], ["crit_stage", 0, 3]]:
		var key: String = field[0]
		if entry.has(key):
			if _read_int(entry[key], field[1], field[2], "%s %s" % [where, key]):
				move.set(key, int(entry[key]))
			else:
				ok = false
	if ok and move.is_damaging() and move.power < 1:
		ok = _fail("%s : « power » ≥ 1 attendu pour une capacité offensive" % where)
	if ok and not move.is_damaging() and move.power != 0:
		ok = _fail("%s : une capacité de statut n'a pas de « power »" % where)
	if entry.has("effects"):
		ok = _read_effects(entry["effects"], move.effects, where) and ok
	if entry.has("pending_effects"):
		var pending: Variant = entry["pending_effects"]
		if not pending is Array:
			ok = _fail("%s : « pending_effects » doit être une liste de textes" % where)
		else:
			for tag: Variant in pending:
				if not tag is String or (tag as String).is_empty():
					ok = _fail("%s : « pending_effects » doit être une liste de textes" % where)
					break
				move.pending_effects.append(tag)
	if entry.has("description"):
		ok = _read_text(entry["description"], where + " description") and ok
		move.description = str(entry["description"])
	for key: String in ["draft", "typeless"]:
		if entry.has(key):
			if entry[key] is bool:
				move.set(key, entry[key])
			else:
				ok = _fail("%s : « %s » vaut true ou false" % [where, key])
	return move if ok else null


func _read_effects(value: Variant, into: Array[MoveEffect], where: String) -> bool:
	if not value is Array:
		return _fail("%s : « effects » doit être une liste" % where)
	var ok := true
	for i: int in (value as Array).size():
		var effect := _parse_effect(value[i], "%s effet %d" % [where, i + 1])
		if effect == null:
			ok = false
		else:
			into.append(effect)
	return ok


func _parse_effect(value: Variant, where: String) -> MoveEffect:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	if not entry.get("kind") is String or not MoveEffect.KIND_NAMES.has(entry.get("kind")):
		return _null_fail("%s : « kind » vaut %s" % [where,
			", ".join(PackedStringArray(MoveEffect.KIND_NAMES.keys()))])
	var effect := MoveEffect.new()
	effect.kind = MoveEffect.KIND_NAMES[entry["kind"]]
	var allowed: Array[String] = []
	allowed.assign(_EFFECT_KEYS[effect.kind])
	var required: Array[String] = allowed.duplicate()
	for key: String in _EFFECT_OPTIONAL:
		required.erase(key)
	var ok := _check_keys(entry, allowed, required, where)
	if effect.kind == MoveEffect.Kind.RECOIL or effect.kind == MoveEffect.Kind.SEED:
		if entry.has("fraction"):
			var fraction: Variant = entry["fraction"]
			if not _is_number(fraction) or float(fraction) <= 0.0 or float(fraction) > 1.0:
				ok = _fail("%s : « fraction » doit être un nombre de 0 (exclu) à 1" % where)
			else:
				effect.fraction = float(fraction)
		if entry.has("immune_types"):
			ok = _read_type_list(entry["immune_types"], effect.immune_types,
				where + " immune_types") and ok
		return effect if ok else null
	if entry.has("stat"):
		if not MoveEffect.STAGE_STATS.has(StringName(str(entry["stat"]))) \
				or not entry["stat"] is String:
			ok = _fail("%s : « stat » vaut %s" % [where,
				", ".join(PackedStringArray(MoveEffect.STAGE_STATS))])
		else:
			effect.stat = StringName(entry["stat"])
	if entry.has("stages"):
		if not _read_int(entry["stages"], -6, 6, where + " stages") \
				or int(entry["stages"]) == 0:
			ok = _fail("%s : « stages » de −6 à +6, jamais 0" % where)
		else:
			effect.stages = int(entry["stages"])
	if entry.has("target"):
		if not entry["target"] is String or not MoveEffect.TARGET_NAMES.has(entry["target"]):
			ok = _fail("%s : « target » vaut self ou foe" % where)
		else:
			effect.target = MoveEffect.TARGET_NAMES[entry["target"]]
	if entry.has("chance"):
		if _read_int(entry["chance"], 1, 100, where + " chance"):
			effect.chance = int(entry["chance"])
		else:
			ok = false
	return effect if ok else null


# --- Références croisées ---------------------------------------------------------------

func _species_references_ok(species: SpeciesData) -> bool:
	var where := "%s espèce « %s »" % [species.source, species.id]
	var ok := true
	for type: StringName in species.types:
		if not _chart.has_type(type):
			ok = _fail("%s : type inconnu « %s »" % [where, type])
	for move_id: StringName in species.learnset_moves():
		if not _moves.has(move_id):
			ok = _fail("%s : capacité inconnue « %s » dans le learnset" % [where, move_id])
	for rule: EvolutionRule in species.evolutions:
		if rule.into == species.id or not _species.has(rule.into):
			ok = _fail("%s : évolution vers une espèce inconnue « %s »" % [where, rule.into])
	return ok


func _species_by_dex(dex: int) -> SpeciesData:
	for species: SpeciesData in _species.values():
		if species.dex == dex:
			return species
	return null


# --- Outils de validation ---------------------------------------------------------------

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


func _read_int(value: Variant, low: int, high: int, where: String) -> bool:
	if not _is_int(value) or int(value) < low or int(value) > high:
		return _fail("%s : entier de %d à %d attendu" % [where, low, high])
	return true


## Liste d'identifiants de types (non vides), vérifiés plus tard par [method check_references].
func _read_type_list(value: Variant, into: Array[StringName], where: String) -> bool:
	if not value is Array:
		return _fail("%s : une liste d'identifiants de types est attendue" % where)
	for type: Variant in value:
		if not type is String or (type as String).is_empty():
			return _fail("%s : une liste d'identifiants de types est attendue" % where)
		into.append(StringName(type))
	return true


func _read_text(value: Variant, where: String) -> bool:
	if not value is String or (value as String).strip_edges().is_empty():
		return _fail("%s : texte non vide attendu" % where)
	return true


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_int(value: Variant) -> bool:
	return _is_number(value) and float(value) == floorf(float(value))


func _fail(message: String) -> bool:
	var full := "PokemonData : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> Variant:
	_fail(message)
	return null
