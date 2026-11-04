class_name TeamReturnSelection
extends RefCounted
## Le choix des 6 au retour de l'équipe (JH-24, Kevin : « le joueur choisit ses 6 » ;
## `jalon-joh0.md` §2.2). Classe pure, sans écran : la réserve (l'équipe de Johto puis l'équipe
## confisquée, 12 Pokémon au plus), la sélection dans l'**ordre de touche**, la règle de
## validation ([method can_confirm] : 1 à [constant Party.MAX_SIZE] Pokémon, au moins un en état
## de combattre) et la sélection proposée au départ ([method default_selection] : l'équipe de
## Johto puis la confisquée jusqu'à 6 **[D]**). L'écran ([TeamReturnScreen]) l'affiche et lui
## renvoie les touches ; [method TeamConfiscation.restore] reçoit [method kept].

## Provenance d'un Pokémon de la réserve.
enum Source { JOHTO, KANTO }
## Pokémon gardés au plus (la taille de l'équipe) ; l'écran lit cette borne, pas [Party].
const MAX_KEPT: int = Party.MAX_SIZE

var _pool: Array[Pokemon] = []
var _sources: Array[Source] = []
var _selected: Array[String] = []


## [param johto] : l'équipe du moment ; [param confiscated] : l'équipe volée. Chaque Pokémon
## reçoit un identifiant s'il n'en a pas (la sélection parle en identifiants).
func _init(johto: Array[Pokemon] = [], confiscated: Array[Pokemon] = []) -> void:
	for pokemon: Pokemon in johto:
		pokemon.ensure_uid()
		_pool.append(pokemon)
		_sources.append(Source.JOHTO)
	for pokemon: Pokemon in confiscated:
		pokemon.ensure_uid()
		_pool.append(pokemon)
		_sources.append(Source.KANTO)


## La réserve, dans l'ordre d'affichage.
func get_pool() -> Array[Pokemon]:
	return _pool.duplicate()


## Provenance du Pokémon [param index] de la réserve (JOHTO si l'index est hors réserve).
func source_of(index: int) -> Source:
	return _sources[index] if index >= 0 and index < _sources.size() else Source.JOHTO


func size() -> int:
	return _pool.size()


## Identifiants de la réserve, dans l'ordre d'affichage (l'écran parle en identifiants).
func uids() -> Array[String]:
	var result: Array[String] = []
	for pokemon: Pokemon in _pool:
		result.append(pokemon.uid)
	return result


## Vrai si le Pokémon [param uid] est choisi.
func is_selected(uid: String) -> bool:
	return _selected.has(uid)


## Nombre de Pokémon choisis.
func count() -> int:
	return _selected.size()


## Choisit ou retire le Pokémon [param uid]. Faux (rien ne change) s'il n'est pas dans la
## réserve, ou s'il faudrait dépasser 6.
func toggle(uid: String) -> bool:
	if _find(uid) == null:
		return false
	if _selected.has(uid):
		_selected.erase(uid)
		return true
	if _selected.size() >= Party.MAX_SIZE:
		return false
	_selected.append(uid)
	return true


## Remplace la sélection par [param uids] (identifiants inconnus ignorés, 6 au plus).
func select(uids: Array[String]) -> void:
	_selected.clear()
	for uid: String in uids:
		toggle(uid)


## La sélection proposée au départ : l'équipe de Johto puis la confisquée, jusqu'à 6.
func default_selection() -> Array[String]:
	var result: Array[String] = []
	for pokemon: Pokemon in _pool:
		if result.size() >= Party.MAX_SIZE:
			break
		result.append(pokemon.uid)
	return result


## Contrôle de la sélection ([enum TeamConfiscation.Check]).
func check() -> TeamConfiscation.Check:
	return TeamConfiscation.check_kept(_pool, _selected)


## Vrai si VALIDER est permis : 1 à 6 Pokémon, au moins un en état de combattre.
func can_confirm() -> bool:
	return check() == TeamConfiscation.Check.OK


## Les identifiants choisis, dans l'ordre de touche (copie).
func kept() -> Array[String]:
	return _selected.duplicate()


func _find(uid: String) -> Pokemon:
	if uid.is_empty():
		return null
	for pokemon: Pokemon in _pool:
		if pokemon.uid == uid:
			return pokemon
	return null
