class_name BattleDecorCache
extends RefCounted
## Préchargement des images du décor peint d'une carte (correctif QA S24 du CB.3) : à l'entrée
## d'une carte, ses images sont demandées **en tâche de fond** ([BackgroundLoader] : synchrone
## en headless) ; au combat, [method take] les rend sans décoder sur le fil principal (avant :
## une image de ≈ 130 ms à chaque entrée en combat).
##
## Mémoire : seules les images demandées au dernier [method prepare] sont gardées (le décor
## par défaut de la carte courante) ; celles de la carte précédente sont rendues. Une image
## non préparée (variante locale) est chargée à la demande et n'est pas gardée.
## Aucune dépendance à l'arbre de scènes.

## Chemin → image chargée et gardée.
var _held: Dictionary[String, Texture2D] = {}
## Chemins demandés au chargeur en tâche de fond, pas encore récupérés.
var _pending: Dictionary[String, bool] = {}


## Garde (et charge en tâche de fond) les images [param paths] ; rend les autres.
func prepare(paths: Array[String]) -> void:
	for path: String in _held.keys():
		if not paths.has(path):
			_held.erase(path)
	for path: String in _pending.keys():
		if not paths.has(path):
			_collect(path)
	for path: String in paths:
		if path == "" or _held.has(path) or _pending.has(path):
			continue
		if not ResourceLoader.exists(path):
			continue
		if BackgroundLoader.request(path, "Texture2D") == OK:
			_pending[path] = true


## Image [param path] : gardée, ou récupérée du chargement en tâche de fond (attend s'il n'est
## pas fini), sinon chargée tout de suite (non gardée). Null si le fichier manque.
func take(path: String) -> Texture2D:
	if path == "":
		return null
	if _held.has(path):
		return _held[path]
	if _pending.has(path):
		var texture := _collect(path)
		if texture != null:
			_held[path] = texture
			return texture
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Vrai si [param path] est prêt sans attente (gardé, ou chargé en tâche de fond).
func is_ready(path: String) -> bool:
	if _held.has(path):
		return true
	return _pending.has(path) and BackgroundLoader.status(path) \
		== ResourceLoader.THREAD_LOAD_LOADED


## Chemins gardés ou en cours de chargement (pour les tests et les mesures).
func get_paths() -> Array[String]:
	var paths: Array[String] = []
	paths.assign(_held.keys())
	for path: String in _pending:
		if not paths.has(path):
			paths.append(path)
	return paths


func _collect(path: String) -> Texture2D:
	_pending.erase(path)
	var status := BackgroundLoader.status(path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE \
			or status == ResourceLoader.THREAD_LOAD_FAILED:
		return null
	return BackgroundLoader.fetch(path) as Texture2D
