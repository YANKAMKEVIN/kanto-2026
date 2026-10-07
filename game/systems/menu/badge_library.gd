class_name BadgeLibrary
extends RefCounted
## Les 8 badges de Kanto (préparés au MM.1, décision de Kevin du 2026-10-07 ;
## docs/tech/menu-maquettes.md « Préparés dès maintenant » ; dossier 08 §6).
##
## Classe pure. `data/badges.json` : { "badges": [ { "id", "order", "name", "leader", "city",
## "flag", "draft" } ] }. **Un badge est obtenu quand son drapeau d'histoire est levé** : aucun
## champ de sauvegarde en plus (les drapeaux sont déjà sauvegardés) ; le J10 n'aura qu'à lever
## le drapeau à la victoire en arène. Un badge non obtenu reste muet (ni nom, ni ville, ni
## champion : [BadgeSlotView]). « draft » : texte à relire par Kevin. Toute clé inconnue est une
## erreur ; une entrée invalide est écartée.

const DEFAULT_PATH: String = "res://data/badges.json"
## Kanto : huit arènes.
const COUNT: int = 8
## Détail d'un badge obtenu : « Argenta — Pierre ».
const DETAIL_FORMAT: String = "%s — %s"

const _KEYS: Array[String] = ["id", "order", "name", "leader", "city", "flag", "draft"]
const _TEXT_KEYS: Array[String] = ["id", "name", "leader", "city", "flag"]

## Entrées valides, triées par ordre d'arène.
var _entries: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les entrées
## valides sont gardées).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary or not (json.data as Dictionary).get("badges") is Array:
		return _fail("%s : { \"badges\": [...] } attendu" % path)
	return add_from_array((json.data as Dictionary)["badges"], path)


## Ajoute les badges d'une liste déjà lue (triés ensuite par ordre d'arène).
func add_from_array(list: Array, source: String = "") -> bool:
	var ok := true
	for i: int in list.size():
		var entry := _parse_entry(list[i], "%s badge %d" % [source, i + 1])
		if entry.is_empty():
			ok = false
		else:
			_entries.append(entry)
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]))
	return ok


func size() -> int:
	return _entries.size()


## Identifiants, dans l'ordre des arènes.
func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in _entries:
		result.append(entry["id"])
	return result


func has_badge(id: StringName) -> bool:
	return not _find(id).is_empty()


## Nom (« Badge Roche »), "" si inconnu.
func badge_name(id: StringName) -> String:
	return _find(id).get("name", "")


func leader(id: StringName) -> String:
	return _find(id).get("leader", "")


func city(id: StringName) -> String:
	return _find(id).get("city", "")


## Drapeau d'histoire qui marque le badge obtenu, &"" si inconnu.
func flag(id: StringName) -> StringName:
	return _find(id).get("flag", &"")


func order(id: StringName) -> int:
	return _find(id).get("order", 0)


func is_draft(id: StringName) -> bool:
	return _find(id).get("draft", false)


## Vrai si [param id] est obtenu (son drapeau est levé dans [param flags]).
func is_obtained(id: StringName, flags: StoryFlags) -> bool:
	var badge_flag := flag(id)
	return flags != null and not badge_flag.is_empty() and flags.has_flag(badge_flag)


## Badges obtenus, dans l'ordre des arènes.
func obtained_ids(flags: StoryFlags) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in ids():
		if is_obtained(id, flags):
			result.append(id)
	return result


func obtained_count(flags: StoryFlags) -> int:
	return obtained_ids(flags).size()


## Les [constant COUNT] emplacements, dans l'ordre des arènes : un badge obtenu porte son
## identifiant, son nom et « Ville — Champion » ; les autres sont muets (vue « badges obtenus »
## de l'écran Dresseur, MM.2).
func slots(flags: StoryFlags) -> Array[BadgeSlotView]:
	var result: Array[BadgeSlotView] = []
	for i: int in COUNT:
		var slot := BadgeSlotView.new(i)
		if i < _entries.size():
			var id: StringName = _entries[i]["id"]
			if is_obtained(id, flags):
				slot.obtained = true
				slot.badge_id = id
				slot.name = badge_name(id)
				slot.detail = DETAIL_FORMAT % [city(id), leader(id)]
		result.append(slot)
	return result


func get_errors() -> PackedStringArray:
	return _errors


func _find(id: StringName) -> Dictionary:
	for entry: Dictionary in _entries:
		if entry["id"] == id:
			return entry
	return {}


func _parse_entry(raw: Variant, where: String) -> Dictionary:
	if not raw is Dictionary:
		_fail("%s : objet attendu" % where)
		return {}
	var data: Dictionary = raw
	for key: Variant in data.keys():
		if not _KEYS.has(str(key)):
			_fail("%s : clé inconnue « %s »" % [where, key])
			return {}
	for key: String in _TEXT_KEYS:
		if not data.get(key) is String or (data[key] as String).strip_edges().is_empty():
			_fail("%s : « %s » doit être un texte non vide" % [where, key])
			return {}
	var order_value: Variant = data.get("order")
	if not (order_value is float or order_value is int) \
			or float(order_value) != floorf(float(order_value)) \
			or int(order_value) < 1 or int(order_value) > COUNT:
		_fail("%s : « order » doit être un entier de 1 à %d" % [where, COUNT])
		return {}
	if data.has("draft") and not data["draft"] is bool:
		_fail("%s : « draft » doit être vrai ou faux" % where)
		return {}
	var id := StringName(data["id"])
	if has_badge(id):
		_fail("%s : identifiant « %s » en double" % [where, id])
		return {}
	for entry: Dictionary in _entries:
		if int(entry["order"]) == int(order_value):
			_fail("%s : ordre %d déjà pris" % [where, int(order_value)])
			return {}
		if entry["flag"] == StringName(data["flag"]):
			_fail("%s : drapeau « %s » déjà pris" % [where, data["flag"]])
			return {}
	return {
		"id": id,
		"order": int(order_value),
		"name": data["name"],
		"leader": data["leader"],
		"city": data["city"],
		"flag": StringName(data["flag"]),
		"draft": data.get("draft", false),
	}


func _fail(message: String) -> bool:
	_errors.append(message)
	push_warning("BadgeLibrary : " + message)
	return false
