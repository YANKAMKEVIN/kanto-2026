class_name ObjectiveLibrary
extends RefCounted
## Objectifs du tableau de bord (dossier 08 §1, jalon-06.md §3.2, Q-4) : un rappel narratif
## pour le joueur qui reprend sa partie, jamais un GPS ni une liste de tâches.
##
## Classe pure. `data/story/objectives.json` est une liste **ordonnée** ; la première entrée
## dont les conditions tiennent l'emporte ; aucune → pas de ligne. Les étapes les plus
## avancées de l'histoire s'écrivent donc **en premier**.
## [codeblock]
## [
##   { "id": "deliver_parcel", "text": "rapporter le colis au Prof. Chen",
##     "if": ["got_parcel"], "unless": ["parcel_delivered"], "draft": true },
##   { "id": "reach_viridian", "text": "rejoindre Jadielle", "if": ["rival_battle_done"] }
## ]
## [/codeblock]
## « text » est la fin de la ligne : l'écran affiche « Objectif : <text> »
## ([constant DashboardViews.OBJECTIVE_PREFIX]). « if » : drapeaux tous levés ; « unless » :
## aucun levé ; « draft » : texte provisoire à relire par Kevin. Toute clé inconnue est une
## erreur ; une entrée invalide est écartée.

const DEFAULT_PATH: String = "res://data/story/objectives.json"

const _KEYS: Array[String] = ["id", "text", "if", "unless", "draft"]

var _entries: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les entrées
## valides sont gardées).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Array:
		return _fail("%s : une liste d'objectifs est attendue" % path)
	return add_from_array(json.data, path)


## Ajoute les objectifs d'une liste déjà lue, à la suite des précédents.
func add_from_array(list: Array, source: String = "") -> bool:
	var ok := true
	for i: int in list.size():
		var where := "%s objectif %d" % [source, i + 1]
		var entry := _parse_entry(list[i], where)
		if entry.is_empty():
			ok = false
		else:
			_entries.append(entry)
	return ok


## Texte de l'objectif courant (sans le préfixe « Objectif : »), "" s'il n'y en a aucun.
func current(flags: StoryFlags) -> String:
	var entry := _current_entry(flags)
	return entry["text"] if not entry.is_empty() else ""


## Identifiant de l'objectif courant (&"" s'il n'y en a aucun).
func current_id(flags: StoryFlags) -> StringName:
	var entry := _current_entry(flags)
	return entry["id"] if not entry.is_empty() else &""


## Identifiants, dans l'ordre du fichier.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in _entries:
		ids.append(entry["id"])
	return ids


## Vrai si l'objectif [param id] est marqué provisoire.
func is_draft(id: StringName) -> bool:
	for entry: Dictionary in _entries:
		if entry["id"] == id:
			return entry["draft"]
	return false


## Drapeaux lus par les conditions (« if », « unless ») : tests de cohérence des données.
func get_condition_flags() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: Dictionary in _entries:
		for flag: StringName in entry["if"] + entry["unless"]:
			if not found.has(flag):
				found.append(flag)
	return found


func size() -> int:
	return _entries.size()


func get_errors() -> PackedStringArray:
	return _errors


func _current_entry(flags: StoryFlags) -> Dictionary:
	for entry: Dictionary in _entries:
		var if_flags: Array[StringName] = entry["if"]
		var unless_flags: Array[StringName] = entry["unless"]
		if flags == null:
			if if_flags.is_empty():
				return entry
		elif flags.has_all(if_flags) and flags.has_none(unless_flags):
			return entry
	return {}


func _parse_entry(value: Variant, where: String) -> Dictionary:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return {}
	var raw: Dictionary = value
	var ok := true
	for key: Variant in raw:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var id := StringName(str(raw.get("id", "")))
	if not _is_text(raw.get("id")):
		ok = _fail("%s : « id » est un texte non vide" % where)
	elif get_ids().has(id):
		ok = _fail("%s : identifiant « %s » en double" % [where, id])
	if not _is_text(raw.get("text")):
		ok = _fail("%s : « text » est un texte non vide" % where)
	var if_flags: Array[StringName] = []
	var unless_flags: Array[StringName] = []
	ok = _read_flags(raw, "if", if_flags, where) and ok
	ok = _read_flags(raw, "unless", unless_flags, where) and ok
	if raw.has("draft") and not raw["draft"] is bool:
		ok = _fail("%s : « draft » vaut true ou false" % where)
	if not ok:
		return {}
	return {
		"id": id, "text": str(raw["text"]).strip_edges(), "if": if_flags,
		"unless": unless_flags, "draft": raw.get("draft", false),
	}


func _read_flags(raw: Dictionary, key: String, into: Array[StringName], where: String) -> bool:
	if not raw.has(key):
		return true
	if not raw[key] is Array:
		return _fail("%s : « %s » est une liste de drapeaux" % [where, key])
	for flag: Variant in raw[key]:
		if not _is_text(flag):
			return _fail("%s : « %s » est une liste de drapeaux" % [where, key])
		into.append(StringName(flag))
	return true


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _fail(message: String) -> bool:
	var full := "ObjectiveLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
