class_name HintStore
extends RefCounted
## Consignes déjà montrées au joueur (gestes annoncés une fois, comme la pression longue sur une
## capacité, [MoveSheetHint]) : `user://hints.json`.
##
## Une préférence de l'appareil, à part de la sauvegarde (une consigne vue ne revient pas avec une
## nouvelle partie) et des réglages ([GameSettings] ne tient que ce que l'écran Paramètres règle).
## Même code et mêmes garanties que [SettingsStore] : écriture atomique par [SaveSystem] ; fichier
## absent, illisible ou d'une version plus récente → « rien n'a été vu », sans avertissement.
## Sous GUT et dans les outils, Boot n'en ouvre aucun (même garde que les réglages).

const VERSION: int = 1
const DEFAULT_PATH: String = "user://hints.json"

var _file: SaveSystem
## Dernier contenu lu ou écrit (toutes les consignes).
var _content: Dictionary = {}
var _loaded: bool = false


func _init(file_system: SaveFileSystem = null, path: String = DEFAULT_PATH) -> void:
	_file = SaveSystem.new(file_system, path)
	_file.version = VERSION
	_file.keep_backup = false


func get_path() -> String:
	return _file.path


## État de la consigne [param key] (dictionnaire vide si rien n'a été noté).
func load_hint(key: String) -> Dictionary:
	_ensure_loaded()
	var value: Variant = _content.get(key)
	return (value as Dictionary).duplicate() if value is Dictionary else {}


## Note l'état de la consigne [param key] (écriture atomique ; les autres consignes sont gardées).
func save_hint(key: String, state: Dictionary) -> Error:
	_ensure_loaded()
	_content[key] = state.duplicate()
	return _file.write(_content)


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not _file.has_save():
		return
	var content := _file.read()
	if _file.last_status == OK:
		content.erase(SaveSystem.VERSION_KEY)
		_content = content
