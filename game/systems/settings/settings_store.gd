class_name SettingsStore
extends RefCounted
## Fichier des réglages de l'appareil, `user://settings.json` (jalon-06.md §3.8, §5.3).
##
## **Séparé de la sauvegarde** : un réglage ne se perd pas quand la partie est mise de côté et
## ne revient pas avec une vieille partie. Mêmes garanties que la sauvegarde, par le même
## code ([SaveSystem], avec sa propre version [constant VERSION]) :
##  - écriture atomique (temporaire, relecture, renommage) ; un échec laisse l'ancien fichier ;
##  - fichier absent → réglages par défaut, sans avertissement (premier lancement) ;
##  - fichier illisible → réglages par défaut, fichier mis de côté (`settings.json.corrupt`) ;
##  - fichier d'une version plus récente → réglages par défaut, fichier laissé tel quel
##    jusqu'au prochain changement de réglage (qui l'écrase : ce ne sont que des préférences) ;
##  - champ inconnu ignoré, champ mal formé à sa valeur par défaut
##    ([method GameSettings.from_dict]).
## Écrit à chaque changement de réglage (Boot, T29) ; sous GUT et dans les outils, Boot n'en
## ouvre aucun (même garde que la sauvegarde).

## Version du format des réglages (indépendante de [constant SaveSystem.VERSION]).
const VERSION: int = 1
const DEFAULT_PATH: String = "user://settings.json"

## Résultat de la dernière opération (OK, ERR_FILE_NOT_FOUND, ERR_FILE_CORRUPT,
## ERR_INVALID_DATA, ou l'erreur d'écriture) et son message (vide si OK).
var last_status: Error = OK
var last_error: String = ""

var _file: SaveSystem


func _init(file_system: SaveFileSystem = null, path: String = DEFAULT_PATH) -> void:
	_file = SaveSystem.new(file_system, path)
	_file.version = VERSION


func get_path() -> String:
	return _file.path


func has_file() -> bool:
	return _file.has_save()


## Réglages du fichier, ou les réglages par défaut s'il manque ou ne se lit pas (jamais null).
func load_settings() -> GameSettings:
	if not _file.has_save():
		last_status = ERR_FILE_NOT_FOUND
		last_error = ""
		return GameSettings.new()
	var content := _file.read()
	last_status = _file.last_status
	last_error = _file.last_error
	if last_status != OK:
		return GameSettings.new()
	return GameSettings.from_dict(content)


## Écrit [param settings] de façon atomique.
func save_settings(settings: GameSettings) -> Error:
	var error := _file.write(settings.to_dict())
	last_status = _file.last_status
	last_error = _file.last_error
	return error
