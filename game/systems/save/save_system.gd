class_name SaveSystem
extends RefCounted
## Lecture et écriture de la sauvegarde unique du joueur (jalon 5 §16.1, 5C.5).
##
## Classe pure : elle ne connaît ni [GameState] ni l'arbre de scènes. Elle reçoit un
## dictionnaire prêt pour le JSON (`GameState.to_dict()`) et en rend un (`GameState.load_dict`).
## Celui qui la tient (Boot, tâche S2) décide des moments d'autosave.
##
## Garanties :
##  - **un seul emplacement** ([constant DEFAULT_PATH]) ;
##  - **écriture atomique** : le JSON est écrit dans un fichier temporaire, relu et comparé,
##    puis renommé par-dessus la sauvegarde ; une coupure en pleine écriture laisse l'ancienne
##    sauvegarde intacte ;
##  - **format versionné** : [constant VERSION] à la racine ; une version plus ancienne est
##    migrée ([method upgrade]) et les champs absents prennent leur valeur par défaut (côté
##    `GameState.load_dict`) ; une version plus récente est refusée sans être touchée ;
##  - **un fichier corrompu** renvoie une erreur claire ([member last_error]) et est mis de côté
##    (`save.json.corrupt`) plutôt qu'écrasé par l'autosave suivant : il n'est jamais détruit.
## Le système de fichiers est injectable ([SaveFileSystem]) pour des tests déterministes.

## Version du format écrit par cette build. À incrémenter quand un champ change de forme ;
## ajouter alors un cas à [method upgrade]. Ajouter un champ n'exige pas de nouvelle version
## (un champ absent prend sa valeur par défaut au chargement).
const VERSION: int = 1
const DEFAULT_PATH: String = "user://save.json"
const TEMP_SUFFIX: String = ".tmp"
const CORRUPT_SUFFIX: String = ".corrupt"
const VERSION_KEY: String = "version"

## Chemin de la sauvegarde (les tests en changent).
var path: String = DEFAULT_PATH
## Accès disque (les tests injectent un système de fichiers en mémoire).
var fs: SaveFileSystem = SaveFileSystem.new()
## Résultat de la dernière opération : OK, ERR_FILE_NOT_FOUND (aucune sauvegarde : cas normal
## d'une nouvelle partie), ERR_FILE_CORRUPT (illisible, mis de côté), ERR_INVALID_DATA (version
## plus récente que cette build), ou l'erreur d'écriture.
var last_status: Error = OK
## Message lisible du dernier échec (vide si OK).
var last_error: String = ""


func _init(file_system: SaveFileSystem = null, save_path: String = DEFAULT_PATH) -> void:
	if file_system != null:
		fs = file_system
	path = save_path


func has_save() -> bool:
	return fs.exists(path)


## Écrit [param state] (racine : dictionnaire, la clé « version » est posée ici) de façon
## atomique. En cas d'échec, la sauvegarde précédente est intacte et le temporaire effacé.
func write(state: Dictionary) -> Error:
	var content := state.duplicate()
	content[VERSION_KEY] = VERSION
	var text := JSON.stringify(content, "\t")
	var temp := path + TEMP_SUFFIX
	var error := fs.write_text(temp, text)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "écriture du fichier temporaire impossible (%s)" % error_string(error))
	if fs.read_text(temp) != text:
		fs.remove(temp)
		return _fail(ERR_FILE_CORRUPT, "relecture du fichier temporaire différente : écriture coupée")
	error = fs.rename(temp, path)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "remplacement de la sauvegarde impossible (%s)" % error_string(error))
	return _ok()


## Lit la sauvegarde, la migre à [constant VERSION] et la renvoie ; dictionnaire vide si elle
## manque ou est invalide ([member last_status], [member last_error]). Un fichier corrompu est
## renommé `<path>.corrupt` ; un fichier d'une version plus récente est laissé tel quel.
func read() -> Dictionary:
	if not fs.exists(path):
		_fail(ERR_FILE_NOT_FOUND, "aucune sauvegarde")
		return {}
	var text := fs.read_text(path)
	# JSON.new().parse plutôt que JSON.parse_string : pas d'erreur moteur imprimée, le message
	# est rendu proprement dans last_error.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	var reason := ""
	if text.is_empty():
		reason = "fichier vide"
	elif parsed == null:
		reason = json.get_error_message()
	elif not parsed is Dictionary:
		reason = "la racine n'est pas un objet"
	elif not JsonFields.is_int((parsed as Dictionary).get(VERSION_KEY)):
		reason = "version absente"
	if not reason.is_empty():
		_quarantine()
		_fail(ERR_FILE_CORRUPT, "sauvegarde illisible (%s), mise de côté dans %s"
			% [reason, _corrupt_path()])
		return {}
	var content := parsed as Dictionary
	var error := upgrade(content)
	if error != OK:
		_fail(error, "sauvegarde d'une version plus récente (%d > %d) : mise à jour du jeu requise"
			% [int(content[VERSION_KEY]), VERSION])
		return {}
	_ok()
	return content


## Supprime la sauvegarde (nouvelle partie volontaire ; pas appelé au jalon 5).
func erase() -> Error:
	if not fs.exists(path):
		return _ok()
	var error := fs.remove(path)
	return _ok() if error == OK else _fail(error, "suppression impossible (%s)" % error_string(error))


## Migre [param content] (modifié en place) de sa version à [constant VERSION]. OK si la version
## est la courante ou plus ancienne ; ERR_INVALID_DATA si elle est plus récente. Les champs
## absents ne sont pas ajoutés ici : `GameState.load_dict` leur donne leur valeur par défaut.
static func upgrade(content: Dictionary) -> Error:
	var from := JsonFields.get_int(content, VERSION_KEY, 0)
	if from > VERSION:
		return ERR_INVALID_DATA
	while from < VERSION:
		match from:
			# Exemple pour plus tard : 1 → 2, si un champ change de forme :
			# 1:
			# 	content["play_time"] = int(content.get("play_time", 0.0))
			_:
				pass  # Aucune forme n'a changé avant cette version : les défauts suffisent.
		from += 1
	content[VERSION_KEY] = VERSION
	return OK


func _corrupt_path() -> String:
	return path + CORRUPT_SUFFIX


func _quarantine() -> void:
	if fs.exists(_corrupt_path()):
		fs.remove(_corrupt_path())
	fs.rename(path, _corrupt_path())


func _ok() -> Error:
	last_status = OK
	last_error = ""
	return OK


func _fail(status: Error, message: String) -> Error:
	last_status = status
	last_error = "SaveSystem : " + message
	push_warning(last_error)
	return status
