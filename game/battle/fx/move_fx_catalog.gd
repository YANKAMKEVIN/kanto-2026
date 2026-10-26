class_name MoveFxCatalog
extends RefCounted
## Catalogue des effets d'attaques (chantier Combat vivant, `docs/tech/combat-vivant.md` §2.2,
## §2.3 ; règle 7 : en données). Classe pure : aucune dépendance à l'arbre de scènes.
##
## Dossier `data/battle/move_fx/` :
## - `families.json` : familles (briques, parts des phases, lumière, caméra), variantes d'impact,
##   modificateurs, signatures, durées de CV-2, plafonds et repli par type ;
## - tous les autres fichiers (`plancher.json`, puis un par lot `p1.json`…) : `moves`, une entrée
##   par attaque ([MoveFxEntry]). Une attaque présente dans deux fichiers est une erreur
##   ([method get_errors]) ; la première lue est gardée.
## Une attaque sans entrée (ajoutée par un jalon en cours) n'est jamais sans effet : [method entry]
## rend la famille de son type et de sa catégorie (`fallback`), comme `SfxCatalog.move_sfx`.

const DEFAULT_DIR: String = "res://data/battle/move_fx"
const FAMILIES_FILE: String = "families.json"
## Famille de dernier recours si le repli lui-même manque.
const LAST_RESORT_FAMILY: StringName = &"contact"
const CONTACT_FAMILY: StringName = &"contact"

var _families: Dictionary[StringName, Dictionary] = {}
var _impacts: Dictionary[StringName, Dictionary] = {}
var _modifiers: Dictionary[StringName, Dictionary] = {}
var _signatures: Dictionary[StringName, Dictionary] = {}
var _durations: Dictionary = {}
var _limits: Dictionary = {}
var _fallback_by_type: Dictionary[StringName, StringName] = {}
var _fallback_by_category: Dictionary[StringName, StringName] = {}
var _fallback_impact: StringName = &"coup"
var _moves: Dictionary[StringName, MoveFxEntry] = {}
var _errors: PackedStringArray = PackedStringArray()


## Catalogue lu dans [param dir] (`families.json` puis les fichiers d'attaques, par ordre de nom).
static func load_dir(dir: String = DEFAULT_DIR) -> MoveFxCatalog:
	var catalog := MoveFxCatalog.new()
	var families: Variant = catalog._read_json(dir.path_join(FAMILIES_FILE))
	if families is Dictionary:
		catalog.read_families(families)
	var files := Array(DirAccess.get_files_at(dir))
	files.sort()
	for file: String in files:
		if not file.ends_with(".json") or file == FAMILIES_FILE:
			continue
		var data: Variant = catalog._read_json(dir.path_join(file))
		if data is Dictionary:
			catalog.add_moves(data, file)
	catalog.validate()
	return catalog


## Remplit familles, impacts, modificateurs, signatures, durées et repli depuis [param data]
## (contenu de `families.json`). Les clés qui commencent par « _ » sont des commentaires.
func read_families(data: Dictionary) -> void:
	_families = _read_table(data.get("families", {}))
	_impacts = _read_table(data.get("impacts", {}))
	_modifiers = _read_table(data.get("modifiers", {}))
	_signatures = _read_table(data.get("signatures", {}))
	_durations = JsonFields.get_dict(data, "durations")
	_limits = JsonFields.get_dict(data, "limits")
	var fallback := JsonFields.get_dict(data, "fallback")
	_fallback_by_type = _read_names(JsonFields.get_dict(fallback, "by_type"))
	_fallback_by_category = _read_names(JsonFields.get_dict(fallback, "by_category"))
	_fallback_impact = JsonFields.get_id(fallback, "impact", &"coup")


## Ajoute les attaques de [param data] (`moves` d'un fichier de lot). [param source] : nom du
## fichier (messages d'erreur).
func add_moves(data: Dictionary, source: String = "") -> void:
	var moves := JsonFields.get_dict(data, "moves")
	for key: String in moves:
		if key.begins_with("_"):
			continue
		var id := StringName(key)
		if _moves.has(id):
			_errors.append("%s : « %s » déjà dans %s" % [source, key, _moves[id].source])
			continue
		var raw: Variant = moves[key]
		if not raw is Dictionary:
			_errors.append("%s : « %s » n'est pas un objet" % [source, key])
			continue
		var entry := MoveFxEntry.new()
		entry.move_id = id
		entry.family = JsonFields.get_id(raw, "family")
		entry.impact = JsonFields.get_id(raw, "impact")
		entry.modifiers = JsonFields.get_ids(raw, "modifiers")
		entry.signature = JsonFields.get_id(raw, "signature")
		entry.source = source
		_moves[id] = entry


## Vérifie les références (famille, impact, modificateurs, signature, repli) ; vrai si tout va.
func validate() -> bool:
	var ok := true
	for id: StringName in _moves:
		var entry := _moves[id]
		var where := "%s : « %s »" % [entry.source, id]
		if not _families.has(entry.family):
			_errors.append("%s : famille inconnue « %s »" % [where, entry.family])
			ok = false
		if entry.family == CONTACT_FAMILY and entry.impact.is_empty():
			_errors.append("%s : une attaque de contact a une variante d'impact" % where)
			ok = false
		if not entry.impact.is_empty() and not _impacts.has(entry.impact):
			_errors.append("%s : impact inconnu « %s »" % [where, entry.impact])
			ok = false
		for modifier: StringName in entry.modifiers:
			if not _modifiers.has(modifier):
				_errors.append("%s : modificateur inconnu « %s »" % [where, modifier])
				ok = false
		if not entry.signature.is_empty():
			if not _signatures.has(entry.signature):
				_errors.append("%s : signature inconnue « %s »" % [where, entry.signature])
				ok = false
			elif JsonFields.get_id(_signatures[entry.signature], "base") != entry.family:
				_errors.append("%s : signature d'une autre famille" % where)
				ok = false
	for family: StringName in _fallback_by_type.values() + _fallback_by_category.values():
		if not _families.has(family):
			_errors.append("repli : famille inconnue « %s »" % family)
			ok = false
	if not _impacts.has(_fallback_impact):
		_errors.append("repli : impact inconnu « %s »" % _fallback_impact)
		ok = false
	return ok


func has_entry(move_id: StringName) -> bool:
	return _moves.has(move_id)


## Effet de [param move_id]. Sans entrée : famille de repli, calculée avec [param type] et
## [param category] (`physical` | `special` | `status`) de l'attaque ; `fallback` vrai.
func entry(move_id: StringName, type: StringName = &"",
		category: StringName = &"physical") -> MoveFxEntry:
	if _moves.has(move_id):
		return _moves[move_id]
	var fallback := MoveFxEntry.new()
	fallback.move_id = move_id
	fallback.fallback = true
	fallback.family = fallback_family(type, category)
	if fallback.family == CONTACT_FAMILY:
		fallback.impact = _fallback_impact
	return fallback


## Famille de repli : statut → `by_category.status` ; sinon le type, puis la catégorie.
func fallback_family(type: StringName, category: StringName) -> StringName:
	var family: StringName = &""
	if category != &"status":
		family = _fallback_by_type.get(type, &"")
	if family.is_empty():
		family = _fallback_by_category.get(category, &"")
	if not _families.has(family):
		family = LAST_RESORT_FAMILY
	return family


## Identifiants des attaques qui ont une entrée, triés.
func move_ids() -> Array[StringName]:
	var ids: Array[StringName] = _moves.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func family_ids() -> Array[StringName]:
	return _families.keys()


## Réglages de la famille [param id] (vide si inconnue).
func family(id: StringName) -> Dictionary:
	return _families.get(id, {})


func has_impact(id: StringName) -> bool:
	return _impacts.has(id)


func modifier(id: StringName) -> Dictionary:
	return _modifiers.get(id, {})


func signature(id: StringName) -> Dictionary:
	return _signatures.get(id, {})


func signature_ids() -> Array[StringName]:
	return _signatures.keys()


## Durées de CV-2 (`bands`, `status_position`, `fast`, `charge_turn`).
func durations() -> Dictionary:
	return _durations


## Plafonds (caméra, flashs, particules réduites).
func limits() -> Dictionary:
	return _limits


func get_errors() -> PackedStringArray:
	return _errors


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_errors.append("fichier absent « %s »" % path)
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		_errors.append("JSON illisible « %s »" % path)
		return null
	return data


## Table « identifiant → objet », sans les commentaires (« _doc »).
static func _read_table(raw: Variant) -> Dictionary[StringName, Dictionary]:
	var table: Dictionary[StringName, Dictionary] = {}
	if raw is Dictionary:
		for key: String in raw:
			if not key.begins_with("_") and raw[key] is Dictionary:
				table[StringName(key)] = raw[key]
	return table


static func _read_names(raw: Dictionary) -> Dictionary[StringName, StringName]:
	var names: Dictionary[StringName, StringName] = {}
	for key: String in raw:
		if not key.begins_with("_") and raw[key] is String:
			names[StringName(key)] = StringName(raw[key])
	return names
