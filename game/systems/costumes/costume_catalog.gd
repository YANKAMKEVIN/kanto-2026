class_name CostumeCatalog
extends RefCounted
## Les costumes du Dresseur (docs/design/dossier-costumes.md, CO-1 à CO-11) : un costume par
## badge (CO-3), une version pour le joueur et une pour la joueuse (suit `player_look`).
##
## Classe pure. `data/costumes.json` : { "costumes": [ { "id", "badge", "art", "names" } ] } ;
## « names » : { "hero": …, "heroine": … } (CO-10). Toute clé inconnue est une erreur ; une
## entrée invalide est écartée. **Débloqué = badge obtenu** (son drapeau levé, [BadgeLibrary]) :
## rien d'autre n'est enregistré (CO-9). La tenue d'origine est [constant ORIGINAL] (&"").
##
## Assets par convention (planches `tools/art/costumes/`, dossier
## `assets/sprites/characters/painted/costumes/`) : apparence du monde
## `costumes/<art>_<joueur|joueuse>` ([CharacterLook] : `painted/costumes/<…>_frames.tres`),
## lancer de dos `<…>_lancer.png`, buste du menu `<…>_bust.webp`.
##
## [method shared] : catalogue chargé une fois (costumes et badges du jeu), pour les classes
## statiques ([TrainerLooks], [GameState]) ; les tests construisent le leur.

const DEFAULT_PATH: String = "res://data/costumes.json"
const DIR: String = "res://assets/sprites/characters/painted/costumes/"
## Préfixe des apparences du monde ([CharacterLook.painted_frames_path]).
const SPRITE_PREFIX: String = "costumes/"
## Tenue d'origine (`player_costume` vide, CO-9).
const ORIGINAL: StringName = &""
## Apparence du joueur → suffixe des planches.
const VERSIONS: Dictionary[StringName, String] = {&"hero": "joueur", &"heroine": "joueuse"}
const DEFAULT_LOOK: StringName = &"hero"
## Annonce du déblocage après la remise du badge (CO-4).
const UNLOCK_FORMAT: String = "Nouveau costume : %s"

const _KEYS: Array[String] = ["id", "badge", "art", "names"]

static var _shared: CostumeCatalog

## Entrées valides, dans l'ordre du fichier (= ordre des arènes).
var _entries: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()
## Badges du jeu (drapeau de chaque badge) ; null : aucun costume n'est débloqué.
var badges: BadgeLibrary


## Catalogue du jeu (`data/costumes.json`, `data/badges.json`), chargé à la première demande.
static func shared() -> CostumeCatalog:
	if _shared == null:
		_shared = CostumeCatalog.new()
		_shared.load_file()
		_shared.badges = BadgeLibrary.new()
		_shared.badges.load_file()
	return _shared


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les entrées
## valides sont gardées).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary or not (json.data as Dictionary).get("costumes") is Array:
		return _fail("%s : { \"costumes\": [...] } attendu" % path)
	return add_from_array((json.data as Dictionary)["costumes"], path)


## Ajoute les costumes d'une liste déjà lue.
func add_from_array(list: Array, source: String = "") -> bool:
	var ok := true
	for i: int in list.size():
		var entry := _parse_entry(list[i], "%s costume %d" % [source, i + 1])
		if entry.is_empty():
			ok = false
		else:
			_entries.append(entry)
	return ok


func size() -> int:
	return _entries.size()


## Identifiants, dans l'ordre du fichier.
func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in _entries:
		result.append(entry["id"])
	return result


func has(id: StringName) -> bool:
	return not _find(id).is_empty()


## Badge qui débloque [param id], &"" si inconnu.
func badge_of(id: StringName) -> StringName:
	return _find(id).get("badge", &"")


## Costume débloqué par [param badge], &"" si aucun.
func costume_for_badge(badge: StringName) -> StringName:
	for entry: Dictionary in _entries:
		if entry["badge"] == badge:
			return entry["id"]
	return &""


## Nom affiché (CO-10) pour l'apparence [param look] ; "" si inconnu.
func display_name(id: StringName, look: StringName) -> String:
	var names: Dictionary = _find(id).get("names", {})
	return names.get(_version_look(look), "")


## « Nouveau costume : Tanjiro » (CO-4) ; "" si inconnu.
func unlock_text(id: StringName, look: StringName) -> String:
	var name := display_name(id, look)
	return UNLOCK_FORMAT % name if not name.is_empty() else ""


## Vrai si [param id] est un costume connu dont le badge est obtenu. [param has_flag] :
## `func(flag: StringName) -> bool` (drapeaux d'histoire de la partie).
func is_unlocked(id: StringName, has_flag: Callable) -> bool:
	if not has(id) or badges == null or not has_flag.is_valid():
		return false
	var flag := badges.flag(badge_of(id))
	return not flag.is_empty() and bool(has_flag.call(flag))


## Costume réellement porté (CO-9) : [param id] s'il est débloqué, sinon la tenue d'origine.
func worn(id: StringName, has_flag: Callable) -> StringName:
	return id if is_unlocked(id, has_flag) else ORIGINAL


## Apparence du monde ([CharacterLook]) du costume [param id] pour [param look] ; &"" si inconnu.
func world_sprite(id: StringName, look: StringName) -> StringName:
	var base := _base(id, look)
	return StringName(SPRITE_PREFIX + base) if not base.is_empty() else &""


## Lancer de dos en combat ; "" si inconnu.
func thrower_path(id: StringName, look: StringName) -> String:
	var base := _base(id, look)
	return DIR + base + "_lancer.png" if not base.is_empty() else ""


## Buste du menu ; "" si inconnu.
func bust_path(id: StringName, look: StringName) -> String:
	var base := _base(id, look)
	return DIR + base + "_bust.webp" if not base.is_empty() else ""


func get_errors() -> PackedStringArray:
	return _errors


## `<art>_<joueur|joueuse>`, "" si [param id] est inconnu.
func _base(id: StringName, look: StringName) -> String:
	var entry := _find(id)
	if entry.is_empty():
		return ""
	return "%s_%s" % [entry["art"], VERSIONS[_version_look(look)]]


static func _version_look(look: StringName) -> StringName:
	return look if VERSIONS.has(look) else DEFAULT_LOOK


func _find(id: StringName) -> Dictionary:
	if id.is_empty():
		return {}
	for entry: Dictionary in _entries:
		if entry["id"] == id:
			return entry
	return {}


func _parse_entry(raw: Variant, where: String) -> Dictionary:
	if not raw is Dictionary:
		_error("%s : objet attendu" % where)
		return {}
	var dict := raw as Dictionary
	for key: Variant in dict:
		if not _KEYS.has(str(key)):
			_error("%s : clé inconnue « %s »" % [where, key])
			return {}
	for key: String in ["id", "badge", "art"]:
		if not dict.get(key) is String or (dict[key] as String).is_empty():
			_error("%s : « %s » (texte non vide) attendu" % [where, key])
			return {}
	var names: Variant = dict.get("names")
	if not names is Dictionary:
		_error("%s : « names » { hero, heroine } attendu" % where)
		return {}
	var parsed_names: Dictionary[StringName, String] = {}
	for look: StringName in VERSIONS:
		var name: Variant = (names as Dictionary).get(String(look))
		if not name is String or (name as String).is_empty():
			_error("%s : nom « %s » attendu" % [where, look])
			return {}
		parsed_names[look] = name
	var id := StringName(dict["id"])
	if has(id):
		_error("%s : identifiant en double « %s »" % [where, id])
		return {}
	return {"id": id, "badge": StringName(dict["badge"]), "art": String(dict["art"]),
		"names": parsed_names}


func _fail(message: String) -> bool:
	_error(message)
	return false


func _error(message: String) -> void:
	_errors.append(message)
	push_error("CostumeCatalog : " + message)
