class_name ShopLibrary
extends RefCounted
## Toutes les boutiques, lues dans les fichiers JSON de `data/shops/` (dossier 09 §9,
## jalon-07.md §3.4).
##
## Classe pure, validation stricte comme [ItemLibrary]. Chaque fichier est un objet
## « identifiant → boutique » ; les identifiants sont uniques dans tout le dossier :
## [codeblock]
## "viridian_mart": {
##   "stock": [
##     { "item": "poke_ball" },
##     { "item": "potion" },
##     { "item": "antidote", "if": ["poison_unlocked"], "unless": [] }
##   ]
## }
## [/codeblock]
## « stock » : liste non vide, dans l'ordre d'affichage ; « item » obligatoire, une seule fois
## par boutique ; « if » / « unless » : listes de drapeaux, facultatives. Toute clé inconnue
## est une erreur ; une boutique invalide est écartée ([method get_errors], push_error).
## [method check_references] vérifie ensuite les objets (connus, avec un prix, jamais clés).

const DATA_DIR: String = "res://data/shops/"

const _SHOP_KEYS: Array[String] = ["stock"]
const _STOCK_KEYS: Array[String] = ["item", "if", "unless"]

var _shops: Dictionary[StringName, ShopData] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une erreur a
## été signalée (les boutiques valides sont gardées).
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
		return _fail("%s : un objet { identifiant: boutique } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les boutiques d'un dictionnaire déjà lu ([param source] : messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _shops.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _shops[id].source])
			continue
		var shop := _parse_shop(data[key], where)
		if shop == null:
			ok = false
			continue
		shop.id = id
		shop.source = source
		_shops[id] = shop
	return ok


## Vérifie que chaque objet en stock existe dans [param items], a un prix et n'est pas un objet
## clé. Faux si une erreur a été signalée ; l'objet fautif est retiré du stock.
func check_references(items: ItemLibrary) -> bool:
	var ok := true
	for shop: ShopData in _shops.values():
		var kept: Array[Dictionary] = []
		for entry: Dictionary in shop.stock:
			var where := "%s « %s », objet « %s »" % [shop.source, shop.id, entry["item"]]
			var item: ItemData = items.get_item(entry["item"]) if items != null else null
			if item == null:
				ok = _fail("%s : objet inconnu" % where)
			elif item.is_key():
				ok = _fail("%s : un objet clé ne se vend pas" % where)
			elif item.price <= 0:
				ok = _fail("%s : objet sans prix (« price »)" % where)
			else:
				kept.append(entry)
		shop.stock = kept
	return ok


func has_shop(id: StringName) -> bool:
	return _shops.has(id)


## Boutique [param id], ou null.
func get_shop(id: StringName) -> ShopData:
	return _shops.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_shops.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Drapeaux lus par les conditions du stock (tests de cohérence des données).
func get_condition_flags() -> Array[StringName]:
	var found: Array[StringName] = []
	for shop: ShopData in _shops.values():
		for entry: Dictionary in shop.stock:
			for flag: StringName in entry["if"] + entry["unless"]:
				if not found.has(flag):
					found.append(flag)
	return found


func size() -> int:
	return _shops.size()


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_shop(value: Variant, where: String) -> ShopData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var raw: Dictionary = value
	var ok := true
	for key: Variant in raw:
		if not _SHOP_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var list: Variant = raw.get("stock")
	if not list is Array or (list as Array).is_empty():
		return _null_fail("%s : « stock » est une liste non vide d'objets" % where)
	var shop := ShopData.new()
	for i: int in (list as Array).size():
		var entry := _parse_stock_entry(list[i], "%s, stock %d" % [where, i + 1])
		if entry.is_empty():
			ok = false
		elif shop.item_ids().has(entry["item"]):
			ok = _fail("%s : objet « %s » en double" % [where, entry["item"]])
		else:
			shop.stock.append(entry)
	return shop if ok else null


func _parse_stock_entry(value: Variant, where: String) -> Dictionary:
	if not value is Dictionary:
		_fail("%s : un objet { \"item\": … } est attendu" % where)
		return {}
	var raw: Dictionary = value
	var ok := true
	for key: Variant in raw:
		if not _STOCK_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	if not _is_text(raw.get("item")):
		ok = _fail("%s : « item » est un identifiant d'objet" % where)
	var if_flags: Array[StringName] = []
	var unless_flags: Array[StringName] = []
	ok = _read_flags(raw, "if", if_flags, where) and ok
	ok = _read_flags(raw, "unless", unless_flags, where) and ok
	if not ok:
		return {}
	return {"item": StringName(raw["item"]), "if": if_flags, "unless": unless_flags}


func _read_flags(raw: Dictionary, key: String, into: Array[StringName], where: String) -> bool:
	if not raw.has(key):
		return true
	if not raw[key] is Array:
		return _fail("%s : « %s » est une liste de drapeaux" % [where, key])
	for flag: Variant in raw[key]:
		if not _is_text(flag):
			return _fail("%s : « %s » est une liste de drapeaux" % [where, key])
		into.append(StringName(flag))
	return true


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _fail(message: String) -> bool:
	var full := "ShopLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> ShopData:
	_fail(message)
	return null
