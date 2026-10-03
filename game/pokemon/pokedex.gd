class_name Pokedex
extends RefCounted
## Enregistrement des espèces vues et capturées (jalon 5 ; décision de Kevin, 2026-09-29) et,
## par espèce, des faits que le Pokédex du J6 affichera (jalon 5 §16.3 : premières observation
## et capture, cartes, compteurs — voir [PokedexEntry]).
##
## Classe pure, sans nœud ni autoload. **L'écran** Pokédex arrive au jalon 6 ; les **données**
## sont collectées dès le jalon 5 et sérialisées dans la sauvegarde, pour que le jalon 6 ne
## soit qu'une interface sur des données déjà présentes, jamais un système rétro-greffé.
##
## Points de marquage (implémentés dans leurs tâches, pas ici) :
##  - « vu » quand un Pokémon adverse entre en combat (événement SENT_OUT côté FOE, 5B) ;
##  - « capturé » à la capture réussie (5D) ; capturer implique voir.
## Une espèce capturée est toujours aussi vue. `caught ⊆ seen` est un invariant.
## La carte et la date sont facultatives ([method mark_seen] / [method mark_caught] restent
## appelables avec la seule espèce) ; `GameState.record_seen` / `record_caught` les fournissent.
##
## J6 (jalon-06.md §3.5) : chaque observation ou capture émet [signal recorded] ; `Boot` (T16)
## s'y branche une seule fois pour débloquer les notes ([PokedexNotes]) et décider du toast
## ([PokedexUpdates]), quel que soit l'appelant (rencontre, combat de dresseur, starter,
## OBSERVER). Le chargement d'une sauvegarde n'émet rien.

## Une observation ([param caught] faux) ou une capture ([param caught] vrai) vient d'être
## enregistrée. [param first_seen] : c'était la première observation de l'espèce (une capture
## d'une espèce jamais vue l'est aussi). [param new_map] : [param map] vient d'entrer dans
## [member PokedexEntry.seen_maps] (première observation de l'espèce sur cette carte).
signal recorded(species: StringName, map: StringName, first_seen: bool, new_map: bool,
		caught: bool)

var _entries: Dictionary[StringName, PokedexEntry] = {}


## Marque [param species] comme vue (une observation de plus, sur [param map] à [param date]).
## Vrai si c'est la première fois (nouvelle entrée « vu »).
func mark_seen(species: StringName, map: StringName = &"", date: String = "") -> bool:
	if species.is_empty():
		return false
	var entry := _entry_for(species)
	var maps_before := entry.seen_maps.size()
	var first := entry.see(map, date)
	recorded.emit(species, map, first, entry.seen_maps.size() > maps_before, false)
	return first


## Marque [param species] comme capturée (et vue : une espèce jamais vue compte sa capture comme
## sa première observation, [code]times_seen[/code] = 1 ; une espèce déjà vue n'est pas
## recomptée). Vrai si c'est la première capture de l'espèce (« Nouvelle entrée Pokédex », dossier 05 §17).
func mark_caught(species: StringName, map: StringName = &"", date: String = "") -> bool:
	if species.is_empty():
		return false
	var entry := _entry_for(species)
	var maps_before := entry.seen_maps.size()
	var first_seen := entry.times_seen < 1
	var first := entry.capture(map, date)
	recorded.emit(species, map, first_seen, entry.seen_maps.size() > maps_before, true)
	return first


func is_seen(species: StringName) -> bool:
	return _entries.has(species)


func is_caught(species: StringName) -> bool:
	var entry: PokedexEntry = _entries.get(species)
	return entry != null and entry.caught


## Entrée de [param species], ou null si elle n'a jamais été vue.
func get_entry(species: StringName) -> PokedexEntry:
	return _entries.get(species)


## Nombre d'observations de [param species] (0 si jamais vue).
func times_seen(species: StringName) -> int:
	var entry: PokedexEntry = _entries.get(species)
	return entry.times_seen if entry != null else 0


## Nombre de captures de [param species] (0 si jamais capturée).
func times_caught(species: StringName) -> int:
	var entry: PokedexEntry = _entries.get(species)
	return entry.times_caught if entry != null else 0


## Vrai si [param species] a été vue sur la carte [param map].
func has_seen_at(species: StringName, map: StringName) -> bool:
	var entry: PokedexEntry = _entries.get(species)
	return entry != null and not map.is_empty() and entry.seen_maps.has(map)


## Débloque la note d'Observations [param note_id] de [param species] (jalon-06.md §3.5).
## Faux si l'espèce n'a jamais été vue ou si la note l'est déjà. N'émet rien : c'est
## [PokedexNotes] qui dit ce qui est nouveau.
func unlock_note(species: StringName, note_id: StringName) -> bool:
	var entry: PokedexEntry = _entries.get(species)
	if entry == null or note_id.is_empty() or entry.notes.has(note_id):
		return false
	entry.notes.append(note_id)
	return true


## Vrai si la note [param note_id] de [param species] est débloquée.
func has_note(species: StringName, note_id: StringName) -> bool:
	var entry: PokedexEntry = _entries.get(species)
	return entry != null and entry.notes.has(note_id)


## Nombre d'espèces vues.
func seen_count() -> int:
	return _entries.size()


## Nombre d'espèces capturées.
func caught_count() -> int:
	var count := 0
	for entry: PokedexEntry in _entries.values():
		if entry.caught:
			count += 1
	return count


## Espèces vues, triées (ordre stable pour les tests et la future interface).
func seen_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_entries.keys())
	return _sorted(ids)


## Espèces capturées, triées.
func caught_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for species: StringName in _entries:
		if _entries[species].caught:
			ids.append(species)
	return _sorted(ids)


## Vide le Pokédex (nouvelle partie).
func clear() -> void:
	_entries.clear()


## Pokédex prêt pour le JSON (sauvegarde) : { "entries": { "pidgey": PokedexEntry.to_dict } },
## espèces triées.
func to_dict() -> Dictionary:
	var entries: Dictionary = {}
	for species: StringName in seen_ids():
		entries[String(species)] = _entries[species].to_dict()
	return {"entries": entries}


## Remplace le contenu par [param dict] ([method to_dict]). Faux si une entrée est invalide
## (elle est écartée). Accepte aussi l'ancienne forme { "seen": [...], "caught": [...] }
## (jalon 5 T0, avant les faits du §16.3) : capturer une espèce implique la voir, même si
## « seen » l'omet.
func from_dict(dict: Dictionary) -> bool:
	clear()
	if not dict.has("entries"):
		return _from_lists(dict)
	var entries: Variant = dict.get("entries")
	if not entries is Dictionary:
		push_error("Pokedex : dictionnaire d'entrées attendu")
		return false
	var ok := true
	for key: Variant in entries:
		var value: Variant = entries[key]
		if not key is String or (key as String).is_empty() or not value is Dictionary:
			push_error("Pokedex : entrée écartée « %s »" % key)
			ok = false
			continue
		var entry := PokedexEntry.from_dict(StringName(key), value)
		# Une entrée existe parce que l'espèce a été vue : jamais « vue 0 fois » (anciennes
		# sauvegardes du jalon 5, avant la règle « une capture vaut une première observation »).
		entry.ensure_seen()
		_entries[StringName(key)] = entry
	return ok


func _entry_for(species: StringName) -> PokedexEntry:
	var entry: PokedexEntry = _entries.get(species)
	if entry == null:
		entry = PokedexEntry.new(species)
		_entries[species] = entry
	return entry


func _from_lists(dict: Dictionary) -> bool:
	var seen := _read_list(dict.get("seen", []))
	var caught := _read_list(dict.get("caught", []))
	# Chargement : directement sur les entrées, sans émettre [signal recorded].
	for species: StringName in seen[0]:
		_entry_for(species).see(&"", "")
	for species: StringName in caught[0]:
		_entry_for(species).capture(&"", "")
	return seen[1] and caught[1]


func _sorted(ids: Array[StringName]) -> Array[StringName]:
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Renvoie [liste d'identifiants valides, ok] : ok est faux si [param value] n'est pas une
## liste ou si une entrée a été écartée (elle est signalée par push_error).
func _read_list(value: Variant) -> Array:
	var ids: Array[StringName] = []
	if not value is Array:
		push_error("Pokedex : liste d'espèces attendue")
		return [ids, false]
	var ok := true
	for entry: Variant in value:
		if entry is String and not (entry as String).is_empty():
			ids.append(StringName(entry))
		else:
			push_error("Pokedex : espèce écartée « %s »" % entry)
			ok = false
	return [ids, ok]
