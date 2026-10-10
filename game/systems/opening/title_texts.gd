class_name TitleTexts
extends RefCounted
## Textes de l'écran titre (dossier 13 §5.2, §5.4) : `data/opening/title.json`.
##
## Classe pure. Format : { "entries": { continue, new_game, settings }, "messages": { corrupt,
## newer, unsaved }, "confirm": { title, body, cancel, confirm } } (+ « _note »). Validation
## stricte : clé inconnue ou manquante, texte vide = erreur, et rien n'est appliqué (tout ou
## rien) ; [method text] rend alors "".

const DEFAULT_PATH: String = "res://data/opening/title.json"
const GROUP_ENTRIES: StringName = &"entries"
const GROUP_MESSAGES: StringName = &"messages"
const GROUP_CONFIRM: StringName = &"confirm"
## Clés attendues de chaque groupe (toutes obligatoires).
const SCHEMA: Dictionary[StringName, Array] = {
	GROUP_ENTRIES: ["continue", "new_game", "settings"],
	GROUP_MESSAGES: ["corrupt", "newer", "unsaved"],
	GROUP_CONFIRM: ["title", "body", "cancel", "confirm"],
}

## Groupe → { clé → texte }.
var _texts: Dictionary[StringName, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


func load_file(path: String = DEFAULT_PATH) -> bool:
	var data := OpeningJson.read_object(path, _errors)
	if data.is_empty():
		_report()
		return false
	return add_from_dict(data, path)


func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	var allowed: Array[String] = ["_note"]
	for group: StringName in SCHEMA:
		allowed.append(String(group))
	for key: String in OpeningJson.unknown_keys(data, allowed):
		errors.append("%s : clé inconnue « %s »" % [source, key])
	var texts: Dictionary[StringName, Dictionary] = {}
	for group: StringName in SCHEMA:
		var value: Variant = data.get(String(group))
		if not value is Dictionary:
			errors.append("%s : objet « %s » attendu" % [source, group])
			continue
		var keys: Array[String] = []
		keys.assign(SCHEMA[group])
		for key: String in OpeningJson.unknown_keys(value, keys):
			errors.append("%s %s : clé inconnue « %s »" % [source, group, key])
		for key: String in keys:
			if not OpeningJson.is_text((value as Dictionary).get(key)):
				errors.append("%s %s : texte « %s » manquant ou vide" % [source, group, key])
		texts[group] = (value as Dictionary).duplicate()
	if not errors.is_empty():
		_errors.append_array(errors)
		_report()
		return false
	_texts = texts
	return true


func is_loaded() -> bool:
	return not _texts.is_empty()


## Texte [param key] du groupe [param group] ("" s'il n'existe pas).
func text(group: StringName, key: StringName) -> String:
	return _texts.get(group, {}).get(String(key), "")


func get_errors() -> PackedStringArray:
	return _errors


func _report() -> void:
	for message: String in _errors:
		push_warning("TitleTexts : " + message)
