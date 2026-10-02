class_name PokedexEntry
extends RefCounted
## Ce que le joueur sait d'une espèce (jalon 5 §16.3, affiché par le Pokédex du J6).
##
## Classe pure, tenue par [Pokedex]. Une entrée existe dès que l'espèce est vue ; `caught`
## s'ajoute à la capture. Les lieux sont des identifiants de carte, les dates la date réelle
## de l'appareil en ISO ([DeviceClock]) ; une carte ou une date inconnue reste vide. Une espèce
## capturée a toujours été vue au moins une fois ([method ensure_seen]).

var species: StringName = &""
var caught: bool = false
var first_seen_map: StringName = &""
var first_seen_date: String = ""
var first_caught_map: StringName = &""
var first_caught_date: String = ""
## Cartes où l'espèce a été vue, dans l'ordre de découverte.
var seen_maps: Array[StringName] = []
var times_seen: int = 0
var times_caught: int = 0
## Notes d'Observations débloquées (identifiants de `data/pokedex/kanto.json`, jalon-06.md
## §3.5), dans l'ordre de déblocage. Champ posé au T0 du J6 ; débloquées à partir du T14.
var notes: Array[StringName] = []


func _init(species_id: StringName = &"") -> void:
	species = species_id


## Une observation de plus. Vrai si c'est la première.
func see(map: StringName, date: String) -> bool:
	var first := times_seen == 0
	times_seen += 1
	if first:
		first_seen_map = map
		first_seen_date = date
	if not map.is_empty() and not seen_maps.has(map):
		seen_maps.append(map)
	return first


## Une capture de plus (l'espèce est forcément vue : si elle ne l'était pas, la capture compte
## aussi comme sa première observation, [member times_seen] valant alors 1 ; une espèce déjà
## vue n'est jamais comptée une seconde fois). Vrai si c'est la première capture.
func capture(map: StringName, date: String) -> bool:
	if times_seen < 1:
		see(map, date)
	var first := not caught
	caught = true
	times_caught += 1
	if first:
		first_caught_map = map
		first_caught_date = date
	return first


## Une espèce de l'entrée est forcément vue : au moins une observation. Corrige une entrée
## sauvegardée avant cette règle (starter « capturé » mais « vu 0 fois », jalon 5) ; sans
## première observation datée, celle-ci reprend le lieu et la date de la première capture.
func ensure_seen() -> void:
	if times_seen >= 1:
		return
	times_seen = 1
	if first_seen_date.is_empty() and first_seen_map.is_empty():
		first_seen_map = first_caught_map
		first_seen_date = first_caught_date
	if not first_seen_map.is_empty() and not seen_maps.has(first_seen_map):
		seen_maps.append(first_seen_map)


## Entrée prête pour le JSON.
func to_dict() -> Dictionary:
	return {
		"caught": caught,
		"first_seen_map": String(first_seen_map), "first_seen_date": first_seen_date,
		"first_caught_map": String(first_caught_map), "first_caught_date": first_caught_date,
		"seen_maps": JsonFields.ids_to_array(seen_maps),
		"times_seen": times_seen, "times_caught": times_caught,
		"notes": JsonFields.ids_to_array(notes),
	}


## Reconstruit l'entrée de [param species_id] ; tout champ absent ou mal formé prend sa valeur
## par défaut (jamais d'échec : les faits du Pokédex sont informatifs).
static func from_dict(species_id: StringName, dict: Dictionary) -> PokedexEntry:
	var entry := PokedexEntry.new(species_id)
	entry.caught = JsonFields.get_bool(dict, "caught")
	entry.first_seen_map = JsonFields.get_id(dict, "first_seen_map")
	entry.first_seen_date = JsonFields.get_string(dict, "first_seen_date")
	entry.first_caught_map = JsonFields.get_id(dict, "first_caught_map")
	entry.first_caught_date = JsonFields.get_string(dict, "first_caught_date")
	entry.seen_maps = JsonFields.get_ids(dict, "seen_maps")
	entry.times_seen = maxi(JsonFields.get_int(dict, "times_seen"), 0)
	entry.times_caught = maxi(JsonFields.get_int(dict, "times_caught"), 0)
	# Notes (J6) : absentes d'une sauvegarde v1 → aucune ; doublons écartés.
	for note: StringName in JsonFields.get_ids(dict, "notes"):
		if not entry.notes.has(note):
			entry.notes.append(note)
	if entry.caught or entry.times_caught > 0:
		entry.ensure_seen()
	return entry
