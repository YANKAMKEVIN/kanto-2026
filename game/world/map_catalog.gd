class_name MapCatalog
extends RefCounted
## Emplacement des cartes : l'identifiant d'une carte est le nom de sa scène.
##
## `&"player_house_1f"` → `res://game/world/maps/player_house_1f.tscn`. Pas de registre à
## tenir à jour : un warp vers une carte inexistante est détecté par [method has_map]
## (routeur au moment du passage, test de cohérence des cartes à l'avance).

const MAPS_DIR: String = "res://game/world/maps/"
## Préfixe des cartes de QA (jalon 9) : elles n'appartiennent à aucune zone, ne figurent ni sur
## la Carte ni au Pokédex, et aucun passage n'y mène (départs de débogage seulement). Les tests
## qui énumèrent les cartes du jeu les ignorent ([method is_qa_map]).
const QA_PREFIX: String = "qa_"


## Chemin de la scène d'une carte ("" pour un identifiant vide).
static func scene_path(map_id: StringName, dir: String = MAPS_DIR) -> String:
	if map_id.is_empty():
		return ""
	return dir.path_join(String(map_id) + ".tscn")


## Vrai si la scène de la carte existe.
static func has_map(map_id: StringName, dir: String = MAPS_DIR) -> bool:
	var path := scene_path(map_id, dir)
	return not path.is_empty() and ResourceLoader.exists(path)


## Vrai si c'est une carte de QA (identifiant préfixé de [constant QA_PREFIX]).
static func is_qa_map(map_id: StringName) -> bool:
	return String(map_id).begins_with(QA_PREFIX)
