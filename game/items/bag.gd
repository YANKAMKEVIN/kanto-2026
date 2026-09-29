class_name Bag
extends RefCounted
## Le Sac du joueur : quantité par identifiant d'objet (jalon-04.md §14.6, jalon-05.md §2.4).
##
## Classe pure : elle ne connaît pas les objets eux-mêmes ([ItemLibrary]) ; celui qui ajoute
## vérifie l'identifiant. Aucune limite de quantité. [method to_dict] / [method load_dict]
## préparent la sauvegarde (pas encore branchée).

var _counts: Dictionary[StringName, int] = {}


## Ajoute [param count] objets [param item_id]. Faux (rien ne change) si l'identifiant est
## vide ou si [param count] < 1.
func add(item_id: StringName, count: int = 1) -> bool:
	if item_id.is_empty() or count < 1:
		return false
	_counts[item_id] = count_of(item_id) + count
	return true


## Retire [param count] objets [param item_id]. Faux (rien ne change) s'il n'y en a pas
## assez ou si [param count] < 1. L'objet disparaît du Sac à 0.
func remove(item_id: StringName, count: int = 1) -> bool:
	if count < 1 or count_of(item_id) < count:
		return false
	var left := count_of(item_id) - count
	if left == 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = left
	return true


func count_of(item_id: StringName) -> int:
	return _counts.get(item_id, 0)


func has(item_id: StringName) -> bool:
	return count_of(item_id) > 0


func is_empty() -> bool:
	return _counts.is_empty()


## Identifiants des objets présents, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_counts.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Vide le Sac (nouvelle partie).
func clear() -> void:
	_counts.clear()


## Sac prêt pour le JSON (future sauvegarde) : { "poke_ball": 5 }.
func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for item_id: StringName in get_ids():
		result[String(item_id)] = _counts[item_id]
	return result


## Remplace le contenu par [param dict] ([method to_dict]). Faux si une entrée est invalide
## (elle est écartée, les autres sont gardées).
func load_dict(dict: Dictionary) -> bool:
	_counts.clear()
	var ok := true
	for key: Variant in dict:
		var value: Variant = dict[key]
		var valid := (value is int or value is float) and float(value) == floorf(float(value))
		if not valid or not add(StringName(str(key)), int(value)):
			push_error("Bag : entrée écartée « %s »" % key)
			ok = false
	return ok
