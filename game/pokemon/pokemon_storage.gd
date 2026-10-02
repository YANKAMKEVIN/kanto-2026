class_name PokemonStorage
extends RefCounted
## Le « système de recherche de Chen » : les Pokémon capturés quand l'équipe est pleine
## (dossier 04 §5, dossier 05 §17, jalon 5 §2.4). Classe pure, sans interface : la liste reste
## invisible jusqu'au menu « Mes Pokémon » (Q38). Aucune limite, ordre d'arrivée.
##
## [method to_array] / [method load_array] : la sauvegarde (même format que [Party]).

var _pokemon: Array[Pokemon] = []


## Ajoute [param pokemon] à la fin (la même instance, PV et PP gardés). Faux s'il est null ou
## déjà rangé.
func add(pokemon: Pokemon) -> bool:
	if pokemon == null or _pokemon.has(pokemon):
		return false
	_pokemon.append(pokemon)
	return true


func size() -> int:
	return _pokemon.size()


func is_empty() -> bool:
	return _pokemon.is_empty()


## Les Pokémon rangés, dans l'ordre d'arrivée (copie de la liste).
func get_all() -> Array[Pokemon]:
	return _pokemon.duplicate()


func clear() -> void:
	_pokemon.clear()


## Contenu prêt pour le JSON ([method Pokemon.to_dict] de chacun).
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pokemon: Pokemon in _pokemon:
		result.append(pokemon.to_dict())
	return result


## Remplace le contenu par celui de [param entries] ([method to_array]). Faux si une entrée
## est invalide (elle est écartée avec push_error, les autres sont gardées).
func load_array(entries: Array, data: PokemonData) -> bool:
	_pokemon.clear()
	var ok := true
	for entry: Variant in entries:
		var pokemon: Pokemon = Pokemon.from_dict(entry, data) if entry is Dictionary else null
		if pokemon == null:
			push_error("PokemonStorage : entrée du stockage écartée")
			ok = false
			continue
		_pokemon.append(pokemon)
	return ok
