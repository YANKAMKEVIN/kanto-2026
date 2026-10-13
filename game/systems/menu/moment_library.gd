class_name MomentLibrary
extends RefCounted
## Textes des grands moments de l'écran Dresseur, lus dans `data/trainer/moments.json`
## (dossier 08 §6 ; jalon-06.md §3.7, Q-14).
##
## Classe pure. Les moments eux-mêmes sont des faits de la partie ([code]GameState.moments[/code]
## et [code]GameState.discovered_maps[/code]) ; ce fichier ne porte que leurs textes. Format :
## [codeblock]
## {
##   "moments": {
##     "starter":       { "title": "Premier Pokémon", "detail": "{species} rejoint…", "draft": true },
##     "rival_battle":  { "title": "Combat contre le rival", "detail": "{outcome}" },
##     "first_capture": { "title": "Première capture", "detail": "{species} rejoint…" },
##     "zone_arrival":  { "title": "{zone}", "detail": "Une nouvelle zone découverte." },
##     "badge":         { "title": "{badge}", "detail": "Obtenu à {city} contre {leader}." }
##   },
##   "outcomes": { "win": { "text": "Tu l'emportes.", "draft": true }, "loss": { … } },
##   "zone_arrivals": { "route_1": { "title": "Départ de Bourg Palette", "detail": "…" } }
## }
## [/codeblock]
## « moments » : un texte par type de [constant TYPES], **tous obligatoires** ; « title » texte
## non vide, « detail » texte (facultatif, "" = pas de ligne), « draft » booléen (texte
## provisoire). Marques permises : {zone} partout (nom de la zone du moment) ; {species} pour
## [constant STARTER] et [constant FIRST_CAPTURE] ; {outcome} pour [constant RIVAL_BATTLE]
## (texte de « outcomes » d'après l'issue enregistrée : « win », « loss »…) ; {badge}, {city},
## {leader} pour [constant BADGE] (nom du badge, ville et Champion lus dans [BadgeLibrary]
## d'après le badge des détails, J10). « zone_arrivals »
## (facultatif) : titre et détail propres à la première arrivée dans une zone (identifiant de
## [ZoneLibrary], vérifié par [method check_references]) ; sinon le texte de
## [constant ZONE_ARRIVAL]. Toute clé inconnue est une erreur ; une entrée invalide est écartée,
## l'erreur signalée ([method get_errors], push_error).

const DEFAULT_PATH: String = "res://data/trainer/moments.json"

## Types de moments (ceux de GameState, plus la première arrivée dans une zone, déduite des
## cartes découvertes, Q-14).
const STARTER: StringName = &"starter"
const RIVAL_BATTLE: StringName = &"rival_battle"
const FIRST_CAPTURE: StringName = &"first_capture"
const ZONE_ARRIVAL: StringName = &"zone_arrival"
## Badge obtenu (J10, dossier 12 §13 ; détails : [BadgeMoment]).
const BADGE: StringName = BadgeMoment.TYPE
## Léo redevenu humain (J14, dossier 17 §13 : `bill_restored`, texte n° 69 ; lieu = zone de la
## carte du moment, « Cap d'Azuria »). Écrit une seule fois par l'étape de scène « moment » (J12
## T23, branchée à l'alignement suivant : jalon-14.md §0.3).
const BILL_RESTORED: StringName = &"bill_restored"
const TYPES: Array[StringName] = [
	STARTER, RIVAL_BATTLE, FIRST_CAPTURE, ZONE_ARRIVAL, BADGE, BILL_RESTORED,
]

const MARK_ZONE: String = "{zone}"
const MARK_SPECIES: String = "{species}"
const MARK_OUTCOME: String = "{outcome}"
const MARK_BADGE: String = "{badge}"
const MARK_CITY: String = "{city}"
const MARK_LEADER: String = "{leader}"

const _ROOT_KEYS: Array[String] = ["moments", "outcomes", "zone_arrivals"]
const _TEXT_KEYS: Array[String] = ["title", "detail", "draft"]
const _OUTCOME_KEYS: Array[String] = ["text", "draft"]
## Marques permises par type ({zone} : partout).
const _MARKS: Dictionary[StringName, Array] = {
	STARTER: [MARK_ZONE, MARK_SPECIES],
	RIVAL_BATTLE: [MARK_ZONE, MARK_OUTCOME],
	FIRST_CAPTURE: [MARK_ZONE, MARK_SPECIES],
	ZONE_ARRIVAL: [MARK_ZONE],
	BADGE: [MARK_ZONE, MARK_BADGE, MARK_CITY, MARK_LEADER],
	BILL_RESTORED: [MARK_ZONE],
}

var _texts: Dictionary[StringName, MomentTextData] = {}
var _zone_texts: Dictionary[StringName, MomentTextData] = {}
var _outcomes: Dictionary[StringName, String] = {}
var _draft_outcomes: Array[StringName] = []
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
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"moments\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("moments") is Dictionary:
		return _fail("%s : « moments » doit être un objet { type: texte }" % source)
	var moments: Dictionary = data["moments"]
	for key: Variant in moments:
		var type := StringName(str(key))
		var where := "%s moment « %s »" % [source, type]
		if not TYPES.has(type):
			ok = _fail("%s : type inconnu (%s)" % [where, ", ".join(TYPES)])
			continue
		var text := _parse_text(moments[key], _MARKS[type], where)
		if text == null:
			ok = false
		else:
			_texts[type] = text
	for type: StringName in TYPES:
		if not _texts.has(type):
			ok = _fail("%s : texte du moment « %s » manquant" % [source, type])
	ok = _read_outcomes(data.get("outcomes", {}), source) and ok
	ok = _read_zone_arrivals(data.get("zone_arrivals", {}), source) and ok
	return ok


## Vérifie que chaque zone de « zone_arrivals » existe dans [param zones] ; les textes d'une
## zone inconnue sont écartés. Faux si une erreur a été trouvée.
func check_references(zones: ZoneLibrary) -> bool:
	var ok := true
	for zone: StringName in _zone_texts.keys():
		if zones == null or not zones.has_zone(zone):
			ok = _fail("zone_arrivals « %s » : zone inconnue de ZoneLibrary" % zone)
			_zone_texts.erase(zone)
	return ok


## Texte du moment [param type] ([constant TYPES]), ou null s'il n'est pas défini.
func get_text(type: StringName) -> MomentTextData:
	return _texts.get(type)


## Texte de la première arrivée dans [param zone] : le texte propre à la zone, sinon celui de
## [constant ZONE_ARRIVAL] (null si aucun des deux n'existe).
func get_zone_text(zone: StringName) -> MomentTextData:
	if _zone_texts.has(zone):
		return _zone_texts[zone]
	return _texts.get(ZONE_ARRIVAL)


## Zones qui ont un texte d'arrivée propre, dans l'ordre du fichier.
func get_zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_zone_texts.keys())
	return ids


## Texte de l'issue [param outcome] d'un combat (« win », « loss »…), "" si inconnue.
func outcome_text(outcome: StringName) -> String:
	return _outcomes.get(outcome, "")


## Issues connues, dans l'ordre du fichier.
func get_outcomes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_outcomes.keys())
	return ids


## Vrai si au moins un texte du fichier est marqué provisoire (relecture de Kevin).
func has_drafts() -> bool:
	if not _draft_outcomes.is_empty():
		return true
	for text: MomentTextData in _texts.values() + _zone_texts.values():
		if text.draft:
			return true
	return false


func get_errors() -> PackedStringArray:
	return _errors


func _read_outcomes(value: Variant, source: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « outcomes » doit être un objet { issue: { text } }" % source)
	var ok := true
	var outcomes: Dictionary = value
	for key: Variant in outcomes:
		var id := StringName(str(key))
		var where := "%s issue « %s »" % [source, id]
		if id.is_empty() or not outcomes[key] is Dictionary:
			ok = _fail("%s : un objet { \"text\" } est attendu" % where)
			continue
		var entry: Dictionary = outcomes[key]
		var entry_ok := true
		for entry_key: Variant in entry:
			if not _OUTCOME_KEYS.has(str(entry_key)):
				entry_ok = _fail("%s : clé inconnue « %s »" % [where, entry_key])
		if not _is_text(entry.get("text")):
			entry_ok = _fail("%s : « text » est un texte non vide" % where)
		elif "{" in str(entry["text"]):
			entry_ok = _fail("%s : « text » n'accepte aucune marque" % where)
		if entry.has("draft") and not entry["draft"] is bool:
			entry_ok = _fail("%s : « draft » vaut true ou false" % where)
		if not entry_ok:
			ok = false
			continue
		_outcomes[id] = str(entry["text"]).strip_edges()
		if entry.get("draft", false):
			_draft_outcomes.append(id)
	return ok


func _read_zone_arrivals(value: Variant, source: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : « zone_arrivals » doit être un objet { zone: texte }" % source)
	var ok := true
	var zones: Dictionary = value
	for key: Variant in zones:
		var zone := StringName(str(key))
		var where := "%s arrivée « %s »" % [source, zone]
		if zone.is_empty():
			ok = _fail("%s : identifiant de zone vide" % source)
			continue
		var text := _parse_text(zones[key], _MARKS[ZONE_ARRIVAL], where)
		if text == null:
			ok = false
		else:
			_zone_texts[zone] = text
	return ok


func _parse_text(value: Variant, marks: Array, where: String) -> MomentTextData:
	if not value is Dictionary:
		_fail("%s : un objet { \"title\", \"detail\" } est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _TEXT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	if not _is_text(entry.get("title")):
		ok = _fail("%s : « title » est un texte non vide" % where)
	if entry.has("detail") and not entry["detail"] is String:
		ok = _fail("%s : « detail » est un texte" % where)
	if entry.has("draft") and not entry["draft"] is bool:
		ok = _fail("%s : « draft » vaut true ou false" % where)
	if not ok:
		return null
	var text := MomentTextData.new()
	text.title = str(entry["title"]).strip_edges()
	text.detail = str(entry.get("detail", "")).strip_edges()
	text.draft = entry.get("draft", false)
	for field: String in [text.title, text.detail]:
		var bad := _unknown_mark(field, marks)
		if not bad.is_empty():
			ok = _fail("%s : marque « %s » non permise ici (%s)" % [where, bad,
				", ".join(marks)])
	return text if ok else null


## Première marque de [param text] absente de [param marks] ("" si toutes sont permises).
static func _unknown_mark(text: String, marks: Array) -> String:
	var from := text.find("{")
	while from >= 0:
		var to := text.find("}", from)
		if to < 0:
			return text.substr(from)
		var mark := text.substr(from, to - from + 1)
		if not marks.has(mark):
			return mark
		from = text.find("{", to)
	return ""


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _fail(message: String) -> bool:
	var full := "MomentLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
