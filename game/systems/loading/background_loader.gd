class_name BackgroundLoader
extends RefCounted
## Chargement en arrière-plan ([method ResourceLoader.load_threaded_request]) avec un repli
## **synchrone en headless** : préchargement des cartes voisines ([code]SceneRouter[/code]) et
## des décors de combat ([BattleDecorCache]).
##
## Pourquoi le repli : en headless, Godot 4.7 rend avec le serveur factice, dont le stockage de
## textures ([code]servers/rendering/dummy/storage/texture_storage.h[/code]) range ses textures
## dans un [code]RID_PtrOwner[/code] **sans verrou**. Un chargement en tâche de fond qui crée
## des textures pendant que le fil principal en crée aussi corrompt ce registre :
## « Parameter "t" is null » dans [code]texture_2d_initialize[/code], au hasard et surtout sous
## charge (l'erreur intermittente des tests, jalons 9 à 12). Le téléphone et le Mac (vrai
## rendu, registre protégé) gardent le vrai chargement en arrière-plan.
##
## En repli, [method request] charge tout de suite sur le fil appelant ; [method status] répond
## alors [constant ResourceLoader.THREAD_LOAD_LOADED] (ou [constant ResourceLoader.
## THREAD_LOAD_FAILED]) jusqu'à [method fetch], qui rend la ressource et l'oublie, comme
## [method ResourceLoader.load_threaded_get].

## Vrai : vrai chargement en arrière-plan ; faux : repli synchrone. Les tests peuvent le changer.
static var threaded: bool = DisplayServer.get_name() != "headless"

## Repli synchrone : chemin → ressource chargée (null si le chargement a échoué), pas encore
## récupérée par [method fetch].
static var _loaded: Dictionary[String, Resource] = {}


## Demande [param path] (type [param type_hint]). OK si la demande est prise.
static func request(path: String, type_hint: String = "") -> Error:
	if threaded:
		return ResourceLoader.load_threaded_request(path, type_hint)
	if not _loaded.has(path):
		_loaded[path] = ResourceLoader.load(path, type_hint)
	return OK


## État de la demande [param path] (valeurs de [enum ResourceLoader.ThreadLoadStatus]).
static func status(path: String) -> ResourceLoader.ThreadLoadStatus:
	if threaded:
		return ResourceLoader.load_threaded_get_status(path)
	if not _loaded.has(path):
		return ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	if _loaded[path] == null:
		return ResourceLoader.THREAD_LOAD_FAILED
	return ResourceLoader.THREAD_LOAD_LOADED


## Ressource demandée (attend la fin du chargement s'il est en cours) ; la demande est close.
static func fetch(path: String) -> Resource:
	if threaded:
		return ResourceLoader.load_threaded_get(path)
	var resource: Resource = _loaded.get(path)
	_loaded.erase(path)
	return resource
