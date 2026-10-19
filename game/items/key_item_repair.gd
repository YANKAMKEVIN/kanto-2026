class_name KeyItemRepair
extends RefCounted
## Rattrapage des objets remis par une scène (jalon 16 T13, jalon-16.md §2.8, dossier 19 §6) :
## chaque règle lie un objet à son drapeau de remise. Appliquée au chargement d'une partie :
## - objet dans le Sac sans le drapeau → le drapeau est levé (la scène ne se rejoue pas) ;
## - drapeau sans l'objet dans le Sac → l'objet est rendu une fois (un seul exemplaire).
## Chaque correction est journalisée. Classe pure, sans scène. Règles dans
## `data/story/key_item_repairs.json` : `[{ "item": "hm01", "flag": "got_hm01" }, …]`.

const DATA_PATH: String = "res://data/story/key_item_repairs.json"
const _KEYS: Array[String] = ["item", "flag"]

## Règles chargées : { item: StringName, flag: StringName }.
var rules: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


## Lit [param path]. Faux (et [method get_errors]) si le fichier manque ou une règle est fausse.
func load_file(path: String = DATA_PATH) -> bool:
	rules.clear()
	_errors.clear()
	if not FileAccess.file_exists(path):
		_errors.append("fichier absent : %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Array:
		_errors.append("%s : la racine doit être une liste" % path)
		return false
	for entry: Variant in parsed:
		if not entry is Dictionary:
			_errors.append("règle qui n'est pas un objet")
			continue
		var dict: Dictionary = entry
		var bad := false
		for key: Variant in dict:
			if not _KEYS.has(str(key)):
				_errors.append("clé inconnue « %s »" % key)
				bad = true
		for key: String in _KEYS:
			if not dict.get(key) is String or str(dict[key]).is_empty():
				_errors.append("« %s » doit être un texte non vide" % key)
				bad = true
		if not bad:
			rules.append({"item": StringName(dict["item"]), "flag": StringName(dict["flag"])})
	return _errors.is_empty()


func get_errors() -> PackedStringArray:
	return _errors


## Applique les règles à [param flags] et [param bag]. Rend les lignes de journal des
## corrections faites (vide si tout est cohérent). Sans effet la seconde fois.
func apply(flags: StoryFlags, bag: Bag) -> PackedStringArray:
	var notes := PackedStringArray()
	for rule: Dictionary in rules:
		var item: StringName = rule["item"]
		var flag: StringName = rule["flag"]
		var has_item := bag.has(item)
		var has_flag := flags.has_flag(flag)
		if has_item and not has_flag:
			flags.set_flag(flag)
			notes.append("%s dans le Sac sans « %s » : drapeau levé" % [item, flag])
		elif has_flag and not has_item:
			bag.add(item, 1)
			notes.append("« %s » sans %s dans le Sac : objet rendu" % [flag, item])
	return notes
