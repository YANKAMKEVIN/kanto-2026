class_name PokemonStorage
extends RefCounted
## Le « système de recherche de Chen » : les Pokémon capturés quand l'équipe est pleine
## (dossier 04 §5, dossier 05 §17, jalon 5 §2.4). Classe pure, sans interface : l'écran
## Stockage du Centre (J7A, [StorageRules]) la montre. Aucune limite, ordre d'arrivée.
##
## [method to_array] / [method load_array] : la sauvegarde (même format que [Party]).

## Vrai pour le Stockage **du joueur** ([member GameState.storage]) : chaque Pokémon rangé
## reçoit un identifiant ([method Pokemon.ensure_uid], J11) ; faux pour un Stockage de travail.
var assigns_uids: bool = false
var _pokemon: Array[Pokemon] = []


## Ajoute [param pokemon] à la fin (la même instance, PV et PP gardés ; un identifiant s'il n'en
## a pas, pour le Stockage du joueur : [member assigns_uids]). Faux s'il est null ou déjà rangé.
func add(pokemon: Pokemon) -> bool:
	if pokemon == null or _pokemon.has(pokemon):
		return false
	if assigns_uids:
		pokemon.ensure_uid()
	_pokemon.append(pokemon)
	return true


## Pokémon d'index [param index] (ordre d'arrivée), ou null.
func get_at(index: int) -> Pokemon:
	return _pokemon[index] if index >= 0 and index < _pokemon.size() else null


## Place de [param pokemon] (comparaison par identité), −1 s'il n'est pas rangé.
func index_of(pokemon: Pokemon) -> int:
	return _pokemon.find(pokemon)


## Retire et rend le Pokémon d'index [param index] (la même instance), ou null si l'index
## n'existe pas. Les suivants gardent leur ordre d'arrivée.
func remove_at(index: int) -> Pokemon:
	if index < 0 or index >= _pokemon.size():
		return null
	var pokemon := _pokemon[index]
	_pokemon.remove_at(index)
	return pokemon


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
		if assigns_uids:
			pokemon.ensure_uid()
		_pokemon.append(pokemon)
	return ok
