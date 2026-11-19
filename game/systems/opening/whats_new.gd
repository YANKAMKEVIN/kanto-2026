class_name WhatsNew
extends RefCounted
## Nouveautés d'une version, montrées une fois sur l'écran titre au premier lancement après une
## mise à jour : `data/opening/whats_new.json`.
##
## Classe pure. Format (+ « _note ») :
## [codeblock]
## { "version": "0.37.3", "title": "Nouveautés de la {version}",
##   "hint": "Touche la carte pour la fermer",
##   "lines": [ "Attaques Glace refaites…", "…" ] }
## [/codeblock]
## « version » : MAJEUR.MINEUR.CORRECTIF ([GameVersion]) ; « lines » : [constant MIN_LINES] à
## [constant MAX_LINES] textes non vides. Validation stricte (clé inconnue ou manquante, texte
## vide = erreur) : un fichier en erreur n'est pas appliqué, et la carte ne s'affiche alors jamais.
##
## La carte ne vaut que pour **la version du build** ([method is_for]) : un fichier resté sur une
## version passée ne montre rien, jamais des lignes périmées.

const DEFAULT_PATH: String = "res://data/opening/whats_new.json"
const MIN_LINES: int = 1
const MAX_LINES: int = 5

const _KEYS: Array[String] = ["_note", "version", "title", "hint", "lines"]

var version: String = ""
var hint: String = ""
var lines: PackedStringArray = PackedStringArray()

var _title: String = ""
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux (et rien d'appliqué) si le fichier manque ou contient une erreur.
func load_file(path: String = DEFAULT_PATH) -> bool:
	var errors := PackedStringArray()
	var data := OpeningJson.read_object(path, errors)
	if data.is_empty():
		_report(errors)
		return false
	return add_from_dict(data, path)


## Applique un dictionnaire déjà lu (tout ou rien).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	for key: String in OpeningJson.unknown_keys(data, _KEYS):
		errors.append("%s : clé inconnue « %s »" % [source, key])
	for key: String in ["version", "title", "hint"]:
		if not OpeningJson.is_text(data.get(key)):
			errors.append("%s : « %s » doit être un texte non vide" % [source, key])
	if OpeningJson.is_text(data.get("version")) \
			and GameVersion.code_of(data["version"]) < 0:
		errors.append("%s : « version » doit s'écrire MAJEUR.MINEUR.CORRECTIF" % source)
	var read := PackedStringArray()
	var raw: Variant = data.get("lines")
	if not raw is Array or (raw as Array).size() < MIN_LINES \
			or (raw as Array).size() > MAX_LINES:
		errors.append("%s : « lines » doit être une liste de %d à %d textes" % [source,
			MIN_LINES, MAX_LINES])
	else:
		for i: int in (raw as Array).size():
			if OpeningJson.is_text((raw as Array)[i]):
				read.append((raw as Array)[i])
			else:
				errors.append("%s : lines[%d] doit être un texte non vide" % [source, i])
	if not errors.is_empty():
		_report(errors)
		return false
	version = data["version"]
	_title = data["title"]
	hint = data["hint"]
	lines = read
	return true


func is_loaded() -> bool:
	return not version.is_empty()


func get_errors() -> PackedStringArray:
	return _errors


## « Nouveautés de la 0.37.3 ».
func title_text() -> String:
	return _title.format({"version": version})


## Vrai si ces nouveautés sont celles de la version [param current] du build.
func is_for(current: String) -> bool:
	return is_loaded() and version == current


## La carte se montre au lancement : il y a une partie à continuer ([param has_valid_save] : sur
## une première installation, rien n'est « nouveau »), ces nouveautés sont celles de la version
## [param current], et le joueur ne les a pas encore vues ([param seen] : dernière version vue,
## "" si aucune).
func should_show(current: String, seen: String, has_valid_save: bool) -> bool:
	return has_valid_save and is_for(current) and seen != current


func _report(errors: PackedStringArray) -> void:
	_errors.append_array(errors)
	for error: String in errors:
		push_warning("WhatsNew : %s" % error)
