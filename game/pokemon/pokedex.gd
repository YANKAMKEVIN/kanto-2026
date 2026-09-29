class_name Pokedex
extends RefCounted
## Enregistrement des espèces vues et capturées (jalon 5 ; décision de Kevin, 2026-09-29).
##
## Classe pure, sans nœud ni autoload. **L'écran** Pokédex arrive au jalon 6 ; les **données**
## commencent à être collectées dès le jalon 5 et sont sérialisées dans la sauvegarde du
## jalon 5, pour que le jalon 6 ne soit qu'une interface sur des données déjà présentes,
## jamais un système rétro-greffé.
##
## Points de marquage (implémentés dans leurs tâches, pas ici) :
##  - « vu » quand un Pokémon adverse entre en combat (événement SENT_OUT côté FOE, 5B) ;
##  - « capturé » à la capture réussie (5D) ; capturer implique voir.
## Une espèce capturée est toujours aussi vue ([method mark_caught] appelle [method mark_seen]).
## `caught ⊆ seen` est un invariant.

var _seen: Dictionary[StringName, bool] = {}
var _caught: Dictionary[StringName, bool] = {}


## Marque [param species] comme vue. Vrai si c'est la première fois (nouvelle entrée « vu »).
func mark_seen(species: StringName) -> bool:
	if species.is_empty() or _seen.has(species):
		return false
	_seen[species] = true
	return true


## Marque [param species] comme capturée (et vue). Vrai si c'est la première capture de
## l'espèce (« Nouvelle entrée Pokédex », dossier 05 §17).
func mark_caught(species: StringName) -> bool:
	if species.is_empty():
		return false
	mark_seen(species)
	if _caught.has(species):
		return false
	_caught[species] = true
	return true


func is_seen(species: StringName) -> bool:
	return _seen.has(species)


func is_caught(species: StringName) -> bool:
	return _caught.has(species)


func seen_count() -> int:
	return _seen.size()


func caught_count() -> int:
	return _caught.size()


## Espèces vues, triées (ordre stable pour les tests et la future interface).
func seen_ids() -> Array[StringName]:
	return _sorted(_seen)


## Espèces capturées, triées.
func caught_ids() -> Array[StringName]:
	return _sorted(_caught)


## Vide le Pokédex (nouvelle partie).
func clear() -> void:
	_seen.clear()
	_caught.clear()


## Pokédex prêt pour le JSON (sauvegarde) : { "seen": [...], "caught": [...] }, triés.
func to_dict() -> Dictionary:
	return {
		"seen": _to_strings(seen_ids()),
		"caught": _to_strings(caught_ids()),
	}


## Remplace le contenu par [param dict] ([method to_dict]). Faux si une entrée est invalide
## (elle est écartée) ; capturer une espèce implique la voir, même si « seen » l'omet.
func from_dict(dict: Dictionary) -> bool:
	clear()
	var ok := true
	var seen := _read_list(dict.get("seen", []))
	var caught := _read_list(dict.get("caught", []))
	ok = seen[1] and caught[1]
	for species: StringName in seen[0]:
		mark_seen(species)
	for species: StringName in caught[0]:
		mark_caught(species)
	return ok


func _sorted(dict: Dictionary[StringName, bool]) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(dict.keys())
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


func _to_strings(ids: Array[StringName]) -> Array:
	var result: Array = []
	for id: StringName in ids:
		result.append(String(id))
	return result
