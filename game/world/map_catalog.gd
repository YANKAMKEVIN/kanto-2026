class_name MapCatalog
extends RefCounted
## Emplacement des cartes : l'identifiant d'une carte est le nom de sa scène.
##
## `&"player_house_1f"` → `res://game/world/maps/player_house_1f.tscn`. Pas de registre à
## tenir à jour : un warp vers une carte inexistante est détecté par [method has_map]
## (routeur au moment du passage, test de cohérence des cartes à l'avance).

const MAPS_DIR: String = "res://game/world/maps/"
## Liste des cartes intérieures (préchargement du SceneRouter, jalon 10).
const INTERIORS_PATH: String = "res://data/world/interiors.json"


## Chemin de la scène d'une carte ("" pour un identifiant vide).
static func scene_path(map_id: StringName, dir: String = MAPS_DIR) -> String:
	if map_id.is_empty():
		return ""
	return dir.path_join(String(map_id) + ".tscn")


## Vrai si la scène de la carte existe.
static func has_map(map_id: StringName, dir: String = MAPS_DIR) -> bool:
	var path := scene_path(map_id, dir)
	return not path.is_empty() and ResourceLoader.exists(path)


## Identifiants des cartes intérieures lus dans [param path] (liste vide et erreur signalée si
## le fichier est absent ou mal formé). Le fichier est vérifié contre les scènes par
## `test_map_catalog` (racine `interior = true`).
static func load_interiors(path: String = INTERIORS_PATH) -> Array[StringName]:
	var ids: Array[StringName] = []
	var data: Variant = null
	if FileAccess.file_exists(path):
		data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not (data as Dictionary).get("maps") is Array:
		push_error("MapCatalog : liste des intérieurs illisible « %s »" % path)
		return ids
	for id: Variant in (data as Dictionary)["maps"]:
		ids.append(StringName(str(id)))
	return ids
