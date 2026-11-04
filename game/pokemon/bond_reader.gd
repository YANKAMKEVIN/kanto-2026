class_name BondReader
extends RefCounted
## JOH3 (dossier JOH-04 §9, Mme Clémence) : le palier du lien du Pokémon « qui marche devant »
## le joueur. Classe pure, statique.
##
## Le Pokémon lu : le compagnon s'il y en a un ; sinon, si le premier de l'équipe est un œuf,
## [constant EGG] (texte à part, D-27) ; sinon le premier Pokémon qui n'est pas un œuf. Palier :
## [method BondRules.tier] (0 : < 30, 1 : 30–69, 2 : 70–89, 3 : ≥ 90).

## Le premier de l'équipe est un œuf (et aucun compagnon).
const EGG: int = -1
## Aucun Pokémon lisible (équipe vide, ou pas d'état).
const NONE: int = -2


## Palier du Pokémon de tête de [param state] (l'autoload GameState ou une instance de
## game_state.gd : `party`, `get_companion()`).
static func lead_tier(state: Object) -> int:
	var lead := lead_pokemon(state)
	if lead == null:
		var party: Party = state.get(&"party") if state != null else null
		return EGG if party != null and party.size() > 0 and party.get_at(0).is_egg() else NONE
	return BondRules.tier(lead.bond)


## Le Pokémon lu (null : œuf en tête sans compagnon, ou équipe vide).
static func lead_pokemon(state: Object) -> Pokemon:
	if state == null:
		return null
	if state.has_method(&"get_companion"):
		var companion: Pokemon = state.call(&"get_companion")
		if companion != null and not companion.is_egg():
			return companion
	var party: Party = state.get(&"party")
	if party == null or party.size() == 0 or party.get_at(0).is_egg():
		return null
	for pokemon: Pokemon in party.get_all():
		if not pokemon.is_egg():
			return pokemon
	return null
