class_name PokedexScene
extends RefCounted
## Décor du grand portrait du Pokédex (refonte T4 : **essai** de « décor du portrait », la
## vraie mise en scène relève de la phase DA). Une image peinte floutée, issue des décors du jeu
## (tools/build_pokedex_scenes.gd), choisie d'après le **premier habitat observé** de l'espèce
## (le joueur y a vu l'espèce : rien n'est révélé) ; sans habitat, ou pour une zone sans décor,
## le décor par défaut. La table zone → décor est dans [constant TABLE_PATH] (présentation).
## Classe statique ; la table est lue une fois.

const TABLE_PATH := "res://assets/ui/pokedex/scenes.json"
const SCENES_DIR := "res://assets/ui/pokedex/scenes/"
const EXTENSION := ".webp"

static var _default: String = ""
static var _zones: Dictionary = {}
static var _loaded: bool = false


## Nom du décor (« village », « prairie »…) pour une espèce observée dans [param habitats]
## (dans l'ordre de découverte) : celui de la **première** zone, sinon le décor par défaut.
static func scene_for(habitats: Array[PokedexHabitatView]) -> String:
	_load()
	if not habitats.is_empty():
		var name: Variant = _zones.get(String(habitats[0].zone_id), null)
		if name is String and not (name as String).is_empty():
			return name
	return _default


## Chemin de l'image du décor [param scene] ("" si vide).
static func path_of(scene: String) -> String:
	return "" if scene.is_empty() else SCENES_DIR + scene + EXTENSION


## Image du décor choisi pour [param habitats] (null si le fichier manque).
static func texture_for(habitats: Array[PokedexHabitatView]) -> Texture2D:
	var path := path_of(scene_for(habitats))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Nom du décor par défaut.
static func default_scene() -> String:
	_load()
	return _default


## Tous les décors de la table (défaut compris), sans doublon.
static func all_scenes() -> PackedStringArray:
	_load()
	var names := PackedStringArray([_default])
	for value: Variant in _zones.values():
		if value is String and not names.has(value):
			names.append(value)
	return names


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_PATH))
	if not parsed is Dictionary:
		push_error("PokedexScene : table illisible %s" % TABLE_PATH)
		return
	var table: Dictionary = parsed
	_default = String(table.get("default", ""))
	if table.get("zones") is Dictionary:
		_zones = table["zones"]
