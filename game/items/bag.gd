class_name Bag
extends RefCounted
## Le Sac du joueur : quantité par identifiant d'objet (jalon-04.md §14.6, jalon-05.md §2.4),
## objets favoris et ordre d'obtention (jalon-06.md §3.4 ; forme posée au T0, §5.1).
##
## Classe pure : elle ne connaît pas les objets eux-mêmes ([ItemLibrary]) ; celui qui ajoute
## vérifie l'identifiant. Aucune limite de quantité. [method to_dict] / [method load_dict] font
## l'aller-retour de la sauvegarde (format v2 : { "items", "favorites", "acquired" } ;
## l'ancienne forme plate du format v1 est encore lue, [method upgrade_flat]).
## Un objet retiré jusqu'à 0 garde son favori et son rang d'obtention : il réapparaîtra favori.

const ITEMS_KEY: String = "items"
const FAVORITES_KEY: String = "favorites"
const ACQUIRED_KEY: String = "acquired"

var _counts: Dictionary[StringName, int] = {}
## Objets marqués favoris, dans l'ordre où ils l'ont été.
var _favorites: Array[StringName] = []
## Rang de la dernière obtention de chaque objet (1, 2, 3… : plus grand = plus récent), pour le
## tri « récents » du Sac (jalon-06.md Q-12 : les objets obtenus le plus récemment d'abord).
var _acquired: Dictionary[StringName, int] = {}


## Ajoute [param count] objets [param item_id] (l'objet devient le plus récemment obtenu).
## Faux (rien ne change) si l'identifiant est vide ou si [param count] < 1.
func add(item_id: StringName, count: int = 1) -> bool:
	if item_id.is_empty() or count < 1:
		return false
	_counts[item_id] = count_of(item_id) + count
	_acquired[item_id] = _last_rank() + 1
	return true


## Retire [param count] objets [param item_id]. Faux (rien ne change) s'il n'y en a pas
## assez ou si [param count] < 1. L'objet disparaît du Sac à 0 (favori et rang gardés).
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
	return _sorted(ids)


## Vrai si [param item_id] est marqué favori (qu'il soit dans le Sac ou non).
func is_favorite(item_id: StringName) -> bool:
	return _favorites.has(item_id)


## Marque (ou démarque) [param item_id] comme favori. Faux si rien ne change ou si
## l'identifiant est vide.
func set_favorite(item_id: StringName, value: bool) -> bool:
	if item_id.is_empty() or is_favorite(item_id) == value:
		return false
	if value:
		_favorites.append(item_id)
	else:
		_favorites.erase(item_id)
	return true


## Inverse le favori de [param item_id] (appui long sur une carte du Sac). Faux si
## l'identifiant est vide (rien ne change).
func toggle_favorite(item_id: StringName) -> bool:
	return set_favorite(item_id, not is_favorite(item_id))


## Favoris, dans l'ordre où ils ont été marqués (copie).
func favorite_ids() -> Array[StringName]:
	return _favorites.duplicate()


## Rang de la dernière obtention de [param item_id] (plus grand = plus récent) ; 0 s'il n'a
## jamais été obtenu.
func acquired_rank(item_id: StringName) -> int:
	return _acquired.get(item_id, 0)


## Vide le Sac (nouvelle partie) : objets, favoris et ordre d'obtention.
func clear() -> void:
	_counts.clear()
	_favorites.clear()
	_acquired.clear()


## Sac prêt pour le JSON (sauvegarde, format v2), clés triées :
## [code]{ "items": { "poke_ball": 5 }, "favorites": ["potion"],
## "acquired": { "poke_ball": 1, "potion": 2 } }[/code].
func to_dict() -> Dictionary:
	var items: Dictionary = {}
	for item_id: StringName in get_ids():
		items[String(item_id)] = _counts[item_id]
	var ranked: Array[StringName] = []
	ranked.assign(_acquired.keys())
	var acquired: Dictionary = {}
	for item_id: StringName in _sorted(ranked):
		acquired[String(item_id)] = _acquired[item_id]
	return {
		ITEMS_KEY: items,
		FAVORITES_KEY: JsonFields.ids_to_array(_favorites),
		ACQUIRED_KEY: acquired,
	}


## Remplace le contenu par [param dict] ([method to_dict]). Accepte aussi l'ancienne forme
## plate du format v1 ([code]{ "poke_ball": 5 }[/code], via [method upgrade_flat]). Faux si une
## quantité est invalide (elle est écartée, les autres sont gardées). Favoris et rangs sont
## informatifs : mal formés, ils sont ignorés sans erreur ; un objet présent sans rang en
## reçoit un après les autres (ordre alphabétique).
func load_dict(dict: Dictionary) -> bool:
	clear()
	var source := dict if dict.has(ITEMS_KEY) else upgrade_flat(dict)
	var ok := true
	var items: Variant = source.get(ITEMS_KEY)
	if not items is Dictionary:
		push_error("Bag : « items » doit être un objet « objet → quantité »")
		items = {}
		ok = false
	for key: Variant in items:
		var value: Variant = items[key]
		if not JsonFields.is_int(value) or not add(StringName(str(key)), int(value)):
			push_error("Bag : entrée écartée « %s »" % key)
			ok = false
	_acquired.clear()
	var acquired: Variant = source.get(ACQUIRED_KEY)
	if acquired is Dictionary:
		for key: Variant in acquired:
			var rank: Variant = acquired[key]
			if key is String and not (key as String).is_empty() and JsonFields.is_int(rank) \
					and int(rank) > 0:
				_acquired[StringName(key)] = int(rank)
	for item_id: StringName in get_ids():
		if not _acquired.has(item_id):
			_acquired[item_id] = _last_rank() + 1
	var favorites: Variant = source.get(FAVORITES_KEY)
	if favorites is Array:
		for entry: Variant in favorites:
			if entry is String and not (entry as String).is_empty():
				set_favorite(StringName(entry), true)
	return ok


## Ancienne forme plate du Sac (sauvegarde v1 : [code]{ "poke_ball": 5 }[/code]) → forme v2 :
## les mêmes quantités (vérifiées par [method load_dict], pas ici), aucun favori, ordre
## d'obtention alphabétique des quantités valides (la v1 ne le connaissait pas). Une seule
## règle pour [method load_dict] et la migration ([method SaveSystem.upgrade]).
static func upgrade_flat(flat: Dictionary) -> Dictionary:
	var keys: Array = flat.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
	var acquired: Dictionary = {}
	for key: Variant in keys:
		if not str(key).is_empty() and JsonFields.is_int(flat[key]) and int(flat[key]) > 0:
			acquired[str(key)] = acquired.size() + 1
	return {ITEMS_KEY: flat.duplicate(), FAVORITES_KEY: [], ACQUIRED_KEY: acquired}


func _last_rank() -> int:
	var last := 0
	for rank: int in _acquired.values():
		last = maxi(last, rank)
	return last


func _sorted(ids: Array[StringName]) -> Array[StringName]:
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids
