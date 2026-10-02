class_name Party
extends RefCounted
## L'équipe : 6 Pokémon au maximum (dossier 04 §5), le premier est en tête.
##
## Classe pure. [method to_array] / [method load_array] préparent la sauvegarde.

const MAX_SIZE: int = 6

var _members: Array[Pokemon] = []


## Ajoute [param pokemon] en fin d'équipe. Faux si l'équipe est pleine (ou null).
func add(pokemon: Pokemon) -> bool:
	if pokemon == null or is_full():
		return false
	_members.append(pokemon)
	return true


## Premier Pokémon de l'équipe, ou null.
func get_lead() -> Pokemon:
	return _members[0] if not _members.is_empty() else null


## Pokémon d'index [param index], ou null.
func get_at(index: int) -> Pokemon:
	return _members[index] if index >= 0 and index < _members.size() else null


## Place de [param pokemon] dans l'équipe (0 = en tête), −1 s'il n'y est pas. Comparaison par
## identité : deux Pokémon de la même espèce ne se confondent jamais.
func index_of(pokemon: Pokemon) -> int:
	return _members.find(pokemon)


## Les membres, dans l'ordre (copie de la liste).
func get_all() -> Array[Pokemon]:
	return _members.duplicate()


func size() -> int:
	return _members.size()


func is_full() -> bool:
	return _members.size() >= MAX_SIZE


## Premier Pokémon non K.O., ou null.
func first_able() -> Pokemon:
	for pokemon: Pokemon in _members:
		if not pokemon.is_fainted():
			return pokemon
	return null


func has_able() -> bool:
	return first_able() != null


## PV et PP au maximum pour toute l'équipe.
func heal_all() -> void:
	for pokemon: Pokemon in _members:
		pokemon.heal_full()


func clear() -> void:
	_members.clear()


## Équipe prête pour le JSON (future sauvegarde).
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pokemon: Pokemon in _members:
		result.append(pokemon.to_dict())
	return result


## Remplace l'équipe par celle de [param entries] ([method to_array]). Faux si une entrée
## est invalide (elle est écartée, les autres sont gardées).
func load_array(entries: Array, data: PokemonData) -> bool:
	_members.clear()
	var ok := true
	for entry: Variant in entries:
		var pokemon: Pokemon = Pokemon.from_dict(entry, data) if entry is Dictionary else null
		if pokemon == null or not add(pokemon):
			push_error("Party : entrée d'équipe écartée")
			ok = false
	return ok
