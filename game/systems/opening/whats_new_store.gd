class_name WhatsNewStore
extends RefCounted
## Dernière version dont le joueur a vu les nouveautés ([WhatsNew]) : `user://whats_new.json`.
##
## Une préférence de l'appareil, à part de la sauvegarde (elle ne revient pas avec une vieille
## partie) et des réglages ([GameSettings] ne tient que ce que l'écran Paramètres règle). Même
## code et mêmes garanties que [SettingsStore] : écriture atomique par [SaveSystem] ; fichier
## absent, illisible ou d'une version plus récente → « aucune version vue », sans avertissement.
## Sous GUT et dans les outils, Boot n'en ouvre aucun (même garde que les réglages).

const VERSION: int = 1
const DEFAULT_PATH: String = "user://whats_new.json"
const SEEN_KEY: String = "seen"

var _file: SaveSystem


func _init(file_system: SaveFileSystem = null, path: String = DEFAULT_PATH) -> void:
	_file = SaveSystem.new(file_system, path)
	_file.version = VERSION
	_file.keep_backup = false


func get_path() -> String:
	return _file.path


## Dernière version vue (« 0.37.3 »), ou "" si aucune ne l'a été.
func load_seen() -> String:
	if not _file.has_save():
		return ""
	var content := _file.read()
	if _file.last_status != OK:
		return ""
	var seen: Variant = content.get(SEEN_KEY)
	return str(seen) if seen is String else ""


## Note [param version] comme vue (écriture atomique).
func save_seen(version: String) -> Error:
	return _file.write({SEEN_KEY: version})
