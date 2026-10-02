class_name JsonFields
extends RefCounted
## Lecture tolérante des champs d'un dictionnaire issu de JSON (sauvegarde, jalon 5 §16).
##
## Statique et pur. JSON ne connaît que les flottants : un entier revient en `float`, un
## [StringName] en `String`, un [Vector2i] en liste `[x, y]`. Chaque lecteur renvoie la valeur
## par défaut si le champ manque ou n'a pas la forme attendue : un champ absent ou inconnu ne
## fait jamais planter le chargement (§16.1, format versionné).


## Vrai si [param value] est un nombre entier (int, ou float sans partie décimale).
static func is_int(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))


static func get_int(dict: Dictionary, key: String, default: int = 0) -> int:
	var value: Variant = dict.get(key)
	return int(value) if is_int(value) else default


static func get_float(dict: Dictionary, key: String, default: float = 0.0) -> float:
	var value: Variant = dict.get(key)
	return float(value) if (value is float or value is int) else default


static func get_bool(dict: Dictionary, key: String, default: bool = false) -> bool:
	var value: Variant = dict.get(key)
	return value if value is bool else default


static func get_string(dict: Dictionary, key: String, default: String = "") -> String:
	var value: Variant = dict.get(key)
	return value if value is String else default


## Identifiant ([StringName]) ; « get_id » et non « get_name », déjà pris par [Resource].
static func get_id(dict: Dictionary, key: String, default: StringName = &"") -> StringName:
	var value: Variant = dict.get(key)
	return StringName(value) if value is String else default


## Liste (copie) ou liste vide si le champ n'est pas une liste.
static func get_array(dict: Dictionary, key: String) -> Array:
	var value: Variant = dict.get(key)
	return (value as Array).duplicate() if value is Array else []


## Dictionnaire (copie) ou dictionnaire vide si le champ n'est pas un dictionnaire.
static func get_dict(dict: Dictionary, key: String) -> Dictionary:
	var value: Variant = dict.get(key)
	return (value as Dictionary).duplicate() if value is Dictionary else {}


## [Vector2i] écrit par [method vector2i_to_array] (`[x, y]`), sinon [param default].
static func get_vector2i(dict: Dictionary, key: String,
		default: Vector2i = Vector2i.ZERO) -> Vector2i:
	var value: Variant = dict.get(key)
	if not value is Array or (value as Array).size() != 2:
		return default
	var list := value as Array
	if not is_int(list[0]) or not is_int(list[1]):
		return default
	return Vector2i(int(list[0]), int(list[1]))


static func vector2i_to_array(value: Vector2i) -> Array:
	return [value.x, value.y]


## Liste d'identifiants : les entrées qui ne sont pas des chaînes non vides sont écartées.
static func get_ids(dict: Dictionary, key: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Variant in get_array(dict, key):
		if entry is String and not (entry as String).is_empty():
			result.append(StringName(entry))
	return result


static func ids_to_array(ids: Array[StringName]) -> Array:
	var result: Array = []
	for id: StringName in ids:
		result.append(String(id))
	return result
