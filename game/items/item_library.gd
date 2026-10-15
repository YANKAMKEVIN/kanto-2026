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
## Jalon 11 : une CT (« tm ») a « tm » (numéro de 1 à 50, unique) et « teaches » (identifiant de
## capacité, vérifié contre les données Pokémon par [method check_moves]) ; ces deux clés sont
## refusées ailleurs ; une CT n'a pas de prix (jamais vendue, dossier 14 §6.1).
## Jalon 12 (T20) : « field_use » facultatif ([constant ItemData.FIELD_USES]), réservé aux objets
## AVENTURE (« field ») : la Corde Sortie (« escape_rope »), une pierre d'évolution
## (« evolution_stone », T23).
## Jalon 12 (T23) : « obtained » facultatif (booléen) : toast « obtenu » d'une CT
## ([member ItemData.obtained], les fossiles).
## Jalon 16 : une CS est une CT (« tm ») qui porte « hm » (numéro de 1 à 5, unique) **au lieu**
## de « tm » ([member ItemData.hm_number]) ; « hm » est refusée hors de la catégorie CT.

const DATA_DIR: String = "res://data/items/"

const _KEYS: Array[String] = [
	"name", "plural", "feminine", "category", "catch_bonus", "heal_amount", "cures",
	"description", "draft", "price", "tm", "teaches", "field_use", "obtained",
	"hm",
]
## Numéros des CT de Rouge/Bleu (dossier 14 §6.1).
const TM_MIN: int = 1
const TM_MAX: int = 50
## Numéros des CS de Rouge/Bleu (jalon 16).
const HM_MIN: int = 1
const HM_MAX: int = 5
const _REQUIRED: Array[String] = ["name", "plural", "feminine", "category", "description"]
## Jalon 17 : « teachable » (booléen, CT et CS seulement ; [member ItemData.teachable]).
const _KEYS_J17: Array[String] = ["teachable"]

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
		if not _KEYS.has(str(key)) and not _KEYS_J17.has(str(key)):
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
	if item.category == ItemData.Category.TM and entry.has("hm"):
		var hm: Variant = entry["hm"]
		var teaches_hm: Variant = entry.get("teaches")
		if entry.has("tm"):
			ok = _fail("%s : une CS a « hm », jamais « tm »" % where)
		elif not JsonFields.is_int(hm) or int(hm) < HM_MIN or int(hm) > HM_MAX:
			ok = _fail("%s : « hm » doit être un numéro de %d à %d pour une CS" % [where, HM_MIN,
				HM_MAX])
		elif _hm_taken(int(hm)) != &"":
			ok = _fail("%s : CS%02d déjà définie par « %s »" % [where, int(hm), _hm_taken(int(hm))])
		else:
			item.hm_number = int(hm)
		if not teaches_hm is String or (teaches_hm as String).is_empty():
			ok = _fail("%s : « teaches » doit être un identifiant de capacité pour une CS" % where)
		else:
			item.teaches = StringName(teaches_hm)
	elif item.category == ItemData.Category.TM:
		var number: Variant = entry.get("tm")
		var teaches: Variant = entry.get("teaches")
		if not JsonFields.is_int(number) or int(number) < TM_MIN or int(number) > TM_MAX:
			ok = _fail("%s : « tm » doit être un numéro de %d à %d pour une CT" % [where, TM_MIN,
				TM_MAX])
		elif _tm_taken(int(number)) != &"":
			ok = _fail("%s : CT%02d déjà définie par « %s »" % [where, int(number),
				_tm_taken(int(number))])
		else:
			item.tm_number = int(number)
		if not teaches is String or (teaches as String).is_empty():
			ok = _fail("%s : « teaches » doit être un identifiant de capacité pour une CT" % where)
		else:
			item.teaches = StringName(teaches)
	else:
		for key: String in ["tm", "teaches", "hm"]:
			if entry.has(key):
				ok = _fail("%s : « %s » est réservé aux CT" % [where, key])
	if entry.has("field_use"):
		ok = _read_field_use(entry["field_use"], item, where) and ok
	if entry.has("obtained"):
		if entry["obtained"] is bool:
			item.obtained = entry["obtained"]
		else:
			ok = _fail("%s : « obtained » vaut true ou false" % where)
	if entry.has("teachable"):
		if not entry["teachable"] is bool:
			ok = _fail("%s : « teachable » vaut true ou false" % where)
		elif not item.is_tm():
			ok = _fail("%s : « teachable » est réservé aux CT et aux CS" % where)
		else:
			item.teachable = entry["teachable"]
	if entry.has("price"):
		var price: Variant = entry["price"]
		if not JsonFields.is_int(price) or int(price) < 0:
			ok = _fail("%s : « price » doit être un entier ≥ 0 (₽)" % where)
		elif (item.is_key() or item.is_permanent()) and int(price) > 0:
			ok = _fail("%s : un objet clé ou une CT n'a pas de prix" % where)
		else:
			item.price = int(price)
	return item if ok else null


## CT : chaque capacité enseignée existe dans [param data]. Faux (erreur signalée) sinon.
func check_moves(data: PokemonData) -> bool:
	var ok := true
	for item: ItemData in _items.values():
		if item.is_tm() and not data.has_move(item.teaches):
			ok = _fail("%s « %s » : capacité inconnue « %s »" % [item.source, item.id,
				item.teaches])
	return ok


## CT de numéro [param number] déjà chargée (son identifiant), ou &"".
func get_tm(number: int) -> StringName:
	return _tm_taken(number)


func _tm_taken(number: int) -> StringName:
	for item: ItemData in _items.values():
		if item.is_tm() and not item.is_hm() and item.tm_number == number:
			return item.id
	return &""


## CS de numéro [param number] déjà chargée (son identifiant), ou &"" (jalon 16).
func get_hm(number: int) -> StringName:
	return _hm_taken(number)


func _hm_taken(number: int) -> StringName:
	for item: ItemData in _items.values():
		if item.is_hm() and item.hm_number == number:
			return item.id
	return &""


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


## Usage en exploration (jalon 12) : un des [constant ItemData.FIELD_USES], objet AVENTURE seul.
func _read_field_use(value: Variant, item: ItemData, where: String) -> bool:
	if item.category != ItemData.Category.FIELD:
		return _fail("%s : « field_use » est réservé aux objets AVENTURE (field)" % where)
	if not value is String or not ItemData.FIELD_USES.has(StringName(value)):
		return _fail("%s : « field_use » vaut %s" % [where,
			", ".join(PackedStringArray(ItemData.FIELD_USES))])
	item.field_use = StringName(value)
	return true


func _fail(message: String) -> bool:
	var full := "ItemLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> ItemData:
	_fail(message)
	return null
