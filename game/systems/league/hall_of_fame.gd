class_name HallOfFame
extends RefCounted
## Panthéon : historique des équipes victorieuses de la Ligue (jalon 30 T6 ;
## `docs/tech/jalon-30.md` §2.4, §2.6).
##
## Classe pure, sans scène. Chaque victoire ajoute une **entrée**, instantané immuable :
## [codeblock]
## { "date": "2026-10-22T21:04:00", "play_time": 123456.0, "player": "Kevin",
##   "starter": "charmander",
##   "team": [ { "species": "charizard", "nickname": "", "level": 65, "uid": "…" }, … ] }
## [/codeblock]
## Une entrée n'est jamais modifiée ni effacée ; les lectures rendent des copies. Plafond
## [constant MAX_ENTRIES] (RB) : au-delà, on n'ajoute plus (Q30-5, défaut du plan), et
## [method add] le dit ([constant AddResult.FULL]).
## Sauvegarde (sous-jalon 30A) : champ facultatif « hall_of_fame » de la v7 ([method to_array],
## [method load_array]) ; absent → Panthéon vide. Le champ n'est écrit que s'il n'est pas vide.

enum AddResult { ADDED, FULL, INVALID }

## Entrées au plus (RB : 50).
const MAX_ENTRIES: int = 50
## Pokémon au plus dans une entrée (une équipe).
const MAX_TEAM: int = 6

var _entries: Array[Dictionary] = []


## Instantané de [param team] (des [Pokemon], dans l'ordre de l'équipe ; les œufs ou entrées
## nulles sont ignorés). [param date] : horloge de l'appareil (texte ISO), [param play_time] en
## secondes. Rien n'est lié aux objets d'origine : modifier un Pokémon après coup ne change pas
## l'entrée.
static func snapshot(team: Array, player: String, starter: StringName, play_time: float,
		date: String) -> Dictionary:
	var members: Array = []
	for pokemon: Variant in team:
		if not pokemon is Pokemon or members.size() >= MAX_TEAM:
			continue
		var mon := pokemon as Pokemon
		members.append({
			"species": String(mon.species_id),
			"nickname": mon.nickname,
			"level": mon.level,
			"uid": mon.uid,
		})
	return {
		"date": date,
		"play_time": maxf(play_time, 0.0),
		"player": player,
		"starter": String(starter),
		"team": members,
	}


## Ajoute [param entry] (copie profonde, normalisée). [constant AddResult.FULL] au-delà de
## [constant MAX_ENTRIES] ; [constant AddResult.INVALID] si l'entrée n'a pas d'équipe valide.
func add(entry: Dictionary) -> AddResult:
	var clean := _sanitize(entry)
	if clean.is_empty():
		return AddResult.INVALID
	if is_full():
		return AddResult.FULL
	_entries.append(clean)
	return AddResult.ADDED


func size() -> int:
	return _entries.size()


func is_empty() -> bool:
	return _entries.is_empty()


func is_full() -> bool:
	return _entries.size() >= MAX_ENTRIES


## Copie de l'entrée [param index] (0 = la plus ancienne) ; vide hors limites.
func get_entry(index: int) -> Dictionary:
	if index < 0 or index >= _entries.size():
		return {}
	return _entries[index].duplicate(true)


## Copies de toutes les entrées, de la plus ancienne à la plus récente.
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		result.append(entry.duplicate(true))
	return result


func clear() -> void:
	_entries.clear()


## Pour la sauvegarde : liste JSON des entrées (copie).
func to_array() -> Array:
	var result: Array = []
	for entry: Dictionary in _entries:
		result.append(entry.duplicate(true))
	return result


## Remplace le contenu par [param list] (champ « hall_of_fame » d'une sauvegarde). Les entrées
## mal formées sont écartées, les suivantes gardées ; au plus [constant MAX_ENTRIES] (les
## premières). Faux si une entrée a dû être écartée, vrai sinon (liste vide comprise).
func load_array(list: Array) -> bool:
	_entries.clear()
	var ok := true
	for raw: Variant in list:
		var clean := _sanitize(raw) if raw is Dictionary else {}
		if clean.is_empty():
			ok = false
			continue
		if is_full():
			ok = false
			continue
		_entries.append(clean)
	return ok


## Entrée normalisée (types JSON, champs connus seulement), ou vide si l'équipe est vide ou
## invalide. Un Pokémon sans espèce ou de niveau hors 1..100 rend l'entrée invalide.
static func _sanitize(entry: Dictionary) -> Dictionary:
	var team: Array = []
	for raw: Variant in JsonFields.get_array(entry, "team"):
		if not raw is Dictionary:
			return {}
		var mon := raw as Dictionary
		var species := JsonFields.get_string(mon, "species")
		var level := JsonFields.get_int(mon, "level", 0)
		if species.is_empty() or level < 1 or level > 100:
			return {}
		team.append({
			"species": species,
			"nickname": JsonFields.get_string(mon, "nickname"),
			"level": level,
			"uid": JsonFields.get_string(mon, "uid"),
		})
	if team.is_empty() or team.size() > MAX_TEAM:
		return {}
	return {
		"date": JsonFields.get_string(entry, "date"),
		"play_time": maxf(JsonFields.get_float(entry, "play_time"), 0.0),
		"player": JsonFields.get_string(entry, "player"),
		"starter": JsonFields.get_string(entry, "starter"),
		"team": team,
	}
