class_name ItemLibrary
extends RefCounted
## Tous les objets, lus dans les fichiers JSON de `data/items/` (jalon-04.md §14.6,
## jalon-05.md §2.4).
##
## Classe pure, validation stricte comme [TrainerLibrary]. Chaque fichier est un objet
## « identifiant → objet » ; les identifiants sont uniques dans tout le dossier :
## [codeblock]
## "poke_ball": {
##   "name": "Poké Ball", "plural": "Poké Balls", "feminine": true,
##   "category": "ball", "catch_bonus": 1,
##   "description": "Permet de capturer un Pokémon sauvage.", "draft": true
## }
## [/codeblock]
## Clés obligatoires : name, plural, feminine, category ([constant ItemData.CATEGORY_NAMES]),
## description ; catch_bonus (nombre > 0) obligatoire pour une Ball et refusé ailleurs ;
## un soin (« heal ») a heal_amount (entier > 0, PV rendus) et / ou cures (liste non vide de
## statuts connus de [StatusRules], sans doublon : l'Antidote [code]["poison"][/code]), au moins
## l'un des deux ; ces deux clés sont refusées ailleurs ;
## draft facultative (texte à relire par Kevin) ; price facultatif (entier ≥ 0, ₽ ; 0 ou absent =
## pas en vente), refusé non nul pour un objet clé (« key »). Toute clé inconnue est une erreur ; une
## entrée invalide est écartée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/items/"

const _KEYS: Array[String] = [
	"name", "plural", "feminine", "category", "catch_bonus", "heal_amount", "cures",
	"description", "draft", "price",
]
const _REQUIRED: Array[String] = ["name", "plural", "feminine", "category", "description"]

var _items: Dictionary[StringName, ItemData] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var sorted: Array[String] = []
	sorted.assign(DirAccess.get_files_at(dir))
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = load_file(dir.path_join(file)) and ok
	return ok


## Charge un fichier JSON. Faux s'il est illisible ou contient une erreur.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: objet } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les objets d'un dictionnaire déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _items.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _items[id].source])
			continue
		var item := _parse_item(data[key], where)
		if item == null:
			ok = false
			continue
		item.id = id
		item.source = source
		item.order = _items.size()
		_items[id] = item
	return ok


func has_item(id: StringName) -> bool:
	return _items.has(id)


## Objet [param id], ou null.
func get_item(id: StringName) -> ItemData:
	return _items.get(id)


## Identifiants connus, dans l'ordre des données (fichiers par ordre alphabétique, puis ordre
## des entrées) : ordre « pertinence » du Sac.
func get_ids_in_data_order() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	return ids


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func size() -> int:
	return _items.size()


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_item(value: Variant, where: String) -> ItemData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in _REQUIRED:
		if not entry.has(key):
			ok = _fail("%s : « %s » est obligatoire" % [where, key])
	if not ok:
		return null
	var item := ItemData.new()
	for key: String in ["name", "plural", "description"]:
		if not entry[key] is String or (entry[key] as String).strip_edges().is_empty():
			ok = _fail("%s : « %s » doit être un texte non vide" % [where, key])
	if ok:
		item.name = entry["name"]
		item.plural = entry["plural"]
		item.description = entry["description"]
	for key: String in ["feminine", "draft"]:
		if entry.has(key) and not entry[key] is bool:
			ok = _fail("%s : « %s » vaut true ou false" % [where, key])
	if ok:
		item.feminine = entry["feminine"]
		item.draft = entry.get("draft", false)
	var category: Variant = entry["category"]
	if not category is String or not ItemData.CATEGORY_NAMES.has(category):
		return _null_fail("%s : catégorie inconnue « %s » (%s)" % [where, category,
			", ".join(ItemData.CATEGORY_NAMES)])
	item.category = ItemData.CATEGORY_NAMES.find(category) as ItemData.Category
	if item.category == ItemData.Category.BALL:
		var bonus: Variant = entry.get("catch_bonus")
		if not (bonus is float or bonus is int) or float(bonus) <= 0.0:
			ok = _fail("%s : « catch_bonus » doit être un nombre > 0 pour une Ball" % where)
		else:
			item.catch_bonus = float(bonus)
	elif entry.has("catch_bonus"):
		ok = _fail("%s : « catch_bonus » est réservé aux Balls" % where)
	if item.category == ItemData.Category.HEAL:
		if not entry.has("heal_amount") and not entry.has("cures"):
			ok = _fail("%s : un soin a « heal_amount » ou « cures »" % where)
		if entry.has("heal_amount"):
			var amount: Variant = entry["heal_amount"]
			if not JsonFields.is_int(amount) or int(amount) <= 0:
				ok = _fail("%s : « heal_amount » doit être un entier > 0 pour un soin" % where)
			else:
				item.heal_amount = int(amount)
		if entry.has("cures"):
			ok = _read_cures(entry["cures"], item, where) and ok
	else:
		for key: String in ["heal_amount", "cures"]:
			if entry.has(key):
				ok = _fail("%s : « %s » est réservé aux soins" % [where, key])
	if entry.has("price"):
		var price: Variant = entry["price"]
		if not JsonFields.is_int(price) or int(price) < 0:
			ok = _fail("%s : « price » doit être un entier ≥ 0 (₽)" % where)
		elif item.category == ItemData.Category.KEY and int(price) > 0:
			ok = _fail("%s : un objet clé n'a pas de prix" % where)
		else:
			item.price = int(price)
	return item if ok else null


## Statuts soignés : liste non vide de statuts connus, sans doublon.
func _read_cures(value: Variant, item: ItemData, where: String) -> bool:
	var message := "%s : « cures » doit être une liste non vide de statuts (%s), sans doublon" \
		% [where, ", ".join(PackedStringArray(StatusRules.KNOWN))]
	if not value is Array or (value as Array).is_empty():
		return _fail(message)
	for status: Variant in value:
		if not status is String or not StatusRules.is_known(StringName(status)) \
				or item.cures.has(StringName(status)):
			item.cures.clear()
			return _fail(message)
		item.cures.append(StringName(status))
	return true


func _fail(message: String) -> bool:
	var full := "ItemLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> ItemData:
	_fail(message)
	return null
