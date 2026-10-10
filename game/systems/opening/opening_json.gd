class_name OpeningJson
extends RefCounted
## Lecture des fichiers `data/opening/*.json` (dossier 13 §3.2) : un objet JSON à la racine.
##
## Classe pure et statique, partagée par [OpeningNames], [TitleTexts] et [IntroScript] : chacun
## valide ensuite ses propres clés (toute clé inconnue est une erreur, comme dans les autres
## bibliothèques de données).


## Objet racine de [param path], ou dictionnaire vide si le fichier manque ou n'est pas un
## objet JSON ; le motif est ajouté à [param errors].
static func read_object(path: String, errors: PackedStringArray) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("fichier introuvable : %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		errors.append("%s : objet JSON attendu à la racine" % path)
		return {}
	return json.data


## Clés de [param dict] absentes de [param allowed] (fautes de frappe), dans l'ordre.
static func unknown_keys(dict: Dictionary, allowed: Array[String]) -> PackedStringArray:
	var unknown := PackedStringArray()
	for key: Variant in dict:
		if not key is String or not allowed.has(key):
			unknown.append(str(key))
	return unknown


## Vrai si [param value] est une chaîne non vide.
static func is_text(value: Variant) -> bool:
	return value is String and not (value as String).is_empty()
