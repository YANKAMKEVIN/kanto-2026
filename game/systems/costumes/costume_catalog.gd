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
## lancer de dos `<…>_lancer.png` (repli), buste du menu `<…>_bust.webp` ; dos peints de combat
## `assets/sprites/trainers/battle/dos_costume_<…>[_surf][_lancer].webp` ([method battle_look]).
##
## [method shared] : catalogue chargé une fois (costumes et badges du jeu), pour les classes
## statiques ([TrainerLooks], [GameState]) ; les tests construisent le leur.

const DEFAULT_PATH: String = "res://data/costumes.json"
const DIR: String = "res://assets/sprites/characters/painted/costumes/"
## Préfixe des apparences du monde ([CharacterLook.painted_frames_path]).
const SPRITE_PREFIX: String = "costumes/"
## Apparence de combat d'un costume : ses dos peints (2026-11-04, Kevin : les costumes « ont encore
## l'ancienne pose pour le lancer »).
const BATTLE_LOOK_PREFIX: String = "costume_"
## Tenue d'origine (`player_costume` vide, CO-9).
const ORIGINAL: StringName = &""
## Apparence du joueur → suffixe des planches.
const VERSIONS: Dictionary[StringName, String] = {&"hero": "joueur", &"heroine": "joueuse"}
const DEFAULT_LOOK: StringName = &"hero"
## Annonce du déblocage après la remise du badge (CO-4).
const UNLOCK_FORMAT: String = "Nouveau costume : %s"

## Avantages (CO-12 à CO-15) : clés de « perk.effects » lues par les systèmes de jeu.
const EFFECT_ITEM_SENSE: StringName = &"item_sense"
const EFFECT_BITE_BONUS: StringName = &"bite_bonus"
const EFFECT_SURF_RATE: StringName = &"surf_rate"
const EFFECT_PRIZE: StringName = &"prize_multiplier"
## Explorateur : l'identifiant garde « grass », mais l'effet vaut sur tous les terrains au pas.
const EFFECT_RARE_GRASS: StringName = &"rare_grass"
const EFFECT_TRAINER_SIGHT: StringName = &"trainer_sight"
const EFFECT_ENCOUNTER_RATE: StringName = &"encounter_rate"
const EFFECT_MOVE_HINT: StringName = &"move_hint"
const EFFECT_WILD_EXP: StringName = &"wild_exp"
const EFFECT_CAPTURE: StringName = &"capture"
const EFFECTS: Array[StringName] = [EFFECT_ITEM_SENSE, EFFECT_BITE_BONUS, EFFECT_SURF_RATE,
	EFFECT_PRIZE, EFFECT_RARE_GRASS, EFFECT_TRAINER_SIGHT, EFFECT_ENCOUNTER_RATE,
	EFFECT_MOVE_HINT, EFFECT_WILD_EXP, EFFECT_CAPTURE]
## Texte d'un avantage (écran Dresseur, annonce du déblocage) : « Flair : … ».
const PERK_FORMAT: String = "%s : %s"

## Musiques (CO-16 à CO-19) : clés de « music ».
const MUSIC_BATTLE: StringName = &"battle"
const MUSIC_TOWN: StringName = &"town"

const _KEYS: Array[String] = ["id", "badge", "art", "names", "perk", "music"]

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


## « Flair : Signale les objets cachés à 3 cases. » ; "" si [param id] n'a pas d'avantage.
func perk_text(id: StringName) -> String:
	var perk: Dictionary = _find(id).get("perk", {})
	return PERK_FORMAT % [perk["name"], perk["text"]] if not perk.is_empty() else ""


## Morceaux [param kind] ([constant MUSIC_BATTLE], [constant MUSIC_TOWN]) de [param id] (CO-20 :
## un ou plusieurs) ; vide sans morceau (tenue d'origine comprise).
func music_tracks(id: StringName, kind: StringName) -> Array[StringName]:
	var music: Dictionary = _find(id).get("music", {})
	var result: Array[StringName] = []
	for track: Variant in music.get(kind, []):
		result.append(StringName(str(track)))
	return result


## Valeur de l'effet [param key] du costume [param id] ; [param fallback] s'il ne l'a pas.
func effect(id: StringName, key: StringName, fallback: float = 0.0) -> float:
	var perk: Dictionary = _find(id).get("perk", {})
	var effects: Dictionary = perk.get("effects", {})
	return float(effects.get(key, fallback))


## Effet [param key] du costume porté par [param state] (GameState, ou un double de test sans
## costume : [param fallback]). Les systèmes reçoivent l'état sans jamais nommer l'autoload.
static func worn_effect(state: Object, key: StringName, fallback: float = 0.0) -> float:
	if state == null or not state.has_method(&"worn_costume"):
		return fallback
	return shared().effect(state.call(&"worn_costume"), key, fallback)


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


## Apparence de combat du costume (dos peint `dos_costume_<art>_<version>[_surf][_lancer]` de
## `assets/sprites/trainers/battle/`, [method TrainerIntro.player_path]) ; &"" si inconnu.
func battle_look(id: StringName, look: StringName) -> StringName:
	var base := _base(id, look)
	return StringName(BATTLE_LOOK_PREFIX + base) if not base.is_empty() else &""


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
	var entry := {"id": id, "badge": StringName(dict["badge"]), "art": String(dict["art"]),
		"names": parsed_names}
	if dict.has("perk"):
		var perk := _parse_perk(dict["perk"], where)
		if perk.is_empty():
			return {}
		entry["perk"] = perk
	if dict.has("music"):
		if not dict["music"] is Dictionary:
			_error("%s : « music » { battle, town } attendu" % where)
			return {}
		var music: Dictionary[StringName, Array] = {}
		for kind: Variant in dict["music"]:
			var list: Variant = (dict["music"] as Dictionary)[kind]
			if not [MUSIC_BATTLE, MUSIC_TOWN].has(StringName(str(kind))) or not list is Array:
				_error("%s : « music.%s » (liste de morceaux) invalide" % [where, kind])
				return {}
			music[StringName(str(kind))] = list
		entry["music"] = music
	return entry


## Avantage d'un costume : { name, text, effects } ; {} (erreur notée) s'il est invalide.
func _parse_perk(raw: Variant, where: String) -> Dictionary:
	if not raw is Dictionary:
		_error("%s : « perk » { name, text, effects } attendu" % where)
		return {}
	var dict := raw as Dictionary
	for key: String in ["name", "text"]:
		if not dict.get(key) is String or (dict[key] as String).is_empty():
			_error("%s : « perk.%s » (texte non vide) attendu" % [where, key])
			return {}
	if not dict.get("effects") is Dictionary or (dict["effects"] as Dictionary).is_empty():
		_error("%s : « perk.effects » attendu" % where)
		return {}
	var effects: Dictionary[StringName, float] = {}
	for key: Variant in dict["effects"]:
		var value: Variant = (dict["effects"] as Dictionary)[key]
		if not EFFECTS.has(StringName(str(key))) or not (value is float or value is int):
			_error("%s : effet inconnu ou invalide « %s »" % [where, key])
			return {}
		effects[StringName(str(key))] = float(value)
	return {"name": String(dict["name"]), "text": String(dict["text"]), "effects": effects}


func _fail(message: String) -> bool:
	_error(message)
	return false


func _error(message: String) -> void:
	_errors.append(message)
	push_error("CostumeCatalog : " + message)
