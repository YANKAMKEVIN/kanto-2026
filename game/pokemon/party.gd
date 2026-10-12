class_name Party
extends RefCounted
## L'équipe : 6 Pokémon au maximum (dossier 04 §5), le premier est en tête.
##
## Classe pure. [method to_array] / [method load_array] préparent la sauvegarde.

const MAX_SIZE: int = 6

## Vrai pour l'équipe **du joueur** ([member GameState.party]) : chaque Pokémon qui entre reçoit
## un identifiant ([method Pokemon.ensure_uid], J11). Faux pour les équipes de Dresseurs et les
## équipes de travail, qui restent reproductibles à l'identique.
var assigns_uids: bool = false
var _members: Array[Pokemon] = []


## Ajoute [param pokemon] en fin d'équipe (avec un identifiant s'il n'en a pas, pour l'équipe du
## joueur : [member assigns_uids]). Faux si l'équipe est pleine (ou null).
func add(pokemon: Pokemon) -> bool:
	if pokemon == null or is_full():
		return false
	if assigns_uids:
		pokemon.ensure_uid()
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


## Échange les places [param a] et [param b] (Équipe du Menu Dresseur, jalon 6A : glisser A
## sur B, ou DÉPLACER A puis B ; « courte animation d'échange », dossier 08 §2). Le premier
## de la liste reste le Pokémon de tête. Vrai si l'ordre a changé ; faux (rien ne change) si
## une place n'existe pas ou si [param a] = [param b].
func swap(a: int, b: int) -> bool:
	if a == b or not _has_index(a) or not _has_index(b):
		return false
	var other := _members[a]
	_members[a] = _members[b]
	_members[b] = other
	return true


## Déplace le Pokémon de la place [param from] à la place [param to] en décalant les autres
## (insertion). Vrai si l'ordre a changé ; faux (rien ne change) si une place n'existe pas ou
## si [param from] = [param to]. L'Équipe du J6 échange ([method swap]) ; ceci sert à un
## futur glisser « insérer » (Stockage, J7A).
func move(from: int, to: int) -> bool:
	if from == to or not _has_index(from) or not _has_index(to):
		return false
	var pokemon := _members[from]
	_members.remove_at(from)
	_members.insert(to, pokemon)
	return true


## Retire et rend le Pokémon de la place [param index] (la même instance : PV, PP, favori et
## histoire gardés), ou null si la place n'existe pas. Les suivants remontent d'une place.
## Aucune règle ici : « garder au moins un Pokémon » est une règle du Stockage
## ([method StorageRules.can_deposit], jalon-07.md §3.5).
func remove_at(index: int) -> Pokemon:
	if not _has_index(index):
		return null
	var pokemon := _members[index]
	_members.remove_at(index)
	return pokemon


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


func _has_index(index: int) -> bool:
	return index >= 0 and index < _members.size()
