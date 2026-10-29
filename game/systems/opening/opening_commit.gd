class_name OpeningCommit
extends RefCounted
## Point de validation d'une nouvelle partie (dossier 13 §3.7, A10) : la seule écriture de
## l'ouverture, à la fin de la dernière réplique de Chen, **avant** le fondu vers la chambre.
##
## Classe pure, système de fichiers injectable ([SaveFileSystem] ; les tests utilisent
## `tests/helpers/memory_file_system.gd`). Protocole de [method run] :
##  1. si `save.json` existe : **copie atomique** vers `save.previous.json` (`.tmp` → relecture
##     → renommage), qui remplace l'éventuelle copie précédente. Coupure ici : `save.json` est
##     encore l'ancienne partie ;
##  2. construction de la nouvelle partie **en mémoire** par le [Callable] reçu (Boot :
##     `GameState.new_game()`, prénoms, position dans la chambre, puis `to_dict()`) ; cette
##     classe ne connaît pas [GameState] ;
##  3. **écriture atomique immédiate** par [method SaveSystem.write] (même chemin, même système
##     de fichiers) : avant le renommage, `save.json` reste l'ancienne partie ; après, la
##     nouvelle est complète.
## Il n'existe donc sur le disque que l'ancienne partie intacte (octet pour octet) ou la
## nouvelle complète. Si la copie de l'étape 1 échoue, rien n'est écrit (l'ancienne partie n'est
## jamais remplacée sans sa copie). La copie est faite dès que `save.json` existe, que
## [OpeningFlow] ait demandé [constant OpeningFlow.Effect.BACKUP_PREVIOUS] ou non (filet le plus
## large : un fichier présent n'est jamais écrasé sans copie). Sans `save.json` mais avec sa copie
## de secours `save.json.bak` (J33 T4 : la partie que Continuer aurait reprise), c'est la copie
## de secours qui est copiée : l'écriture de la nouvelle partie la remplacera plus tard.

enum Result {
	OK,
	## Copie de sécurité impossible : rien n'a été écrit, l'ancienne partie est intacte.
	BACKUP_FAILED,
	## Le constructeur n'a pas rendu de dictionnaire non vide : rien n'a été écrit (la copie de
	## l'étape 1 a pu l'être).
	BUILD_FAILED,
	## Écriture de la nouvelle partie impossible : `save.json` est l'ancienne partie (ou absent).
	WRITE_FAILED,
}

## Filet de la nouvelle partie, invisible dans le jeu, récupérable par adb (A10).
const PREVIOUS_PATH: String = "user://save.previous.json"

var fs: SaveFileSystem
var save_path: String
var previous_path: String
## Message lisible du dernier échec (vide si OK).
var last_error: String = ""


func _init(file_system: SaveFileSystem = null, save_file: String = SaveSystem.DEFAULT_PATH,
		previous_file: String = PREVIOUS_PATH) -> void:
	fs = file_system if file_system != null else SaveFileSystem.new()
	save_path = save_file
	previous_path = previous_file


## Le protocole complet. [param build_new_game] : `func() -> Dictionary` (dictionnaire prêt pour
## [method SaveSystem.write], la clé « version » est posée par lui).
func run(build_new_game: Callable) -> Result:
	last_error = ""
	if not _source_path().is_empty() and backup_previous() != OK:
		return Result.BACKUP_FAILED
	var built: Variant = build_new_game.call()
	if not built is Dictionary or (built as Dictionary).is_empty():
		last_error = "OpeningCommit : la nouvelle partie n'a pas pu être construite"
		push_warning(last_error)
		return Result.BUILD_FAILED
	var save := SaveSystem.new(fs, save_path)
	if save.write(built) != OK:
		last_error = save.last_error
		return Result.WRITE_FAILED
	return Result.OK


## Étape 1 seule : copie atomique de `save.json` (ou de sa copie de secours) vers
## [member previous_path]. OK s'il n'y a rien à copier. En cas d'échec, le temporaire est effacé
## et la copie précédente reste en place.
func backup_previous() -> Error:
	var source := _source_path()
	if source.is_empty():
		return OK
	var text := fs.read_text(source)
	if text.is_empty():
		return _fail(ERR_FILE_CANT_READ, "sauvegarde illisible, copie impossible")
	var temp := previous_path + SaveSystem.TEMP_SUFFIX
	var error := fs.write_text(temp, text)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "écriture de la copie impossible (%s)" % error_string(error))
	if fs.read_text(temp) != text:
		fs.remove(temp)
		return _fail(ERR_FILE_CORRUPT, "relecture de la copie différente : écriture coupée")
	error = fs.rename(temp, previous_path)
	if error != OK:
		fs.remove(temp)
		return _fail(error, "remplacement de la copie impossible (%s)" % error_string(error))
	return OK


## La partie existante : `save.json`, sinon `save.json.bak`, sinon vide.
func _source_path() -> String:
	if fs.exists(save_path):
		return save_path
	var backup := save_path + SaveSystem.BACKUP_SUFFIX
	return backup if fs.exists(backup) else ""


func _fail(error: Error, message: String) -> Error:
	last_error = "OpeningCommit : " + message
	push_warning(last_error)
	return error
