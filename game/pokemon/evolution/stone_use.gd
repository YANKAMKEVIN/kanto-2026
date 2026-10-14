class_name StoneUse
extends RefCounted
## Utiliser une pierre d'évolution (jalon 12, T23 ; `jalon-12.md` §2.9, dossier 15 §10) : classe
## statique et pure.
##
## Une pierre ([member ItemData.field_use] = [constant ItemData.FIELD_USE_EVOLUTION_STONE], la
## Pierre Lune) fait évoluer un Pokémon de l'équipe dont l'espèce a une règle « item » pour elle
## ([method Evolution.item_target], données RB). Hors combat seulement (catégorie AVENTURE). Deux
## états seulement (jamais « déjà connue », ce n'est pas [TmTeach]) ; un Pokémon K.O. reste
## COMPATIBLE [D]. Rien ici ne touche au Sac : la pierre est retirée par Boot au moment exact de
## l'évolution ([signal EvolutionDirector.evolution_applied]).

## État d'un Pokémon face à une pierre (liste de l'équipe, dossier 15 §20 n° 35).
enum Check { COMPATIBLE, INCOMPATIBLE }

## Libellés de la liste de l'équipe : ceux des CT (J11), toujours visibles.
const LABELS: Dictionary[Check, String] = {
	Check.COMPATIBLE: TmTeach.LABELS[TmTeach.Check.COMPATIBLE],
	Check.INCOMPATIBLE: TmTeach.LABELS[TmTeach.Check.INCOMPATIBLE],
}


## Vrai si [param item] est une pierre d'évolution (UTILISER ouvre le choix du Pokémon).
static func is_stone(item: ItemData) -> bool:
	return item != null and item.has_field_use() \
		and item.field_use == ItemData.FIELD_USE_EVOLUTION_STONE


## Espèce obtenue en utilisant la pierre [param item_id] sur [param pokemon], ou &"" (aucune
## règle, ou espèce visée inconnue des données).
static func target(pokemon: Pokemon, item_id: StringName, data: PokemonData) -> StringName:
	if pokemon == null or data == null:
		return &""
	var into := Evolution.item_target(pokemon, item_id, data)
	return into if data.has_species(into) else &""


## État de [param pokemon] face à la pierre [param item_id].
static func check(pokemon: Pokemon, item_id: StringName, data: PokemonData) -> Check:
	return Check.INCOMPATIBLE if target(pokemon, item_id, data).is_empty() else Check.COMPATIBLE


## Le candidat que joue [method EvolutionDirector.play_item] pour le Pokémon [param index] de
## [param party] : **non annulable**, avec la pierre ; null si le Pokémon n'est pas COMPATIBLE.
static func candidate(party: Party, index: int, item_id: StringName,
		data: PokemonData) -> EvolutionCandidate:
	var pokemon := party.get_at(index) if party != null else null
	var into := target(pokemon, item_id, data)
	if into.is_empty():
		return null
	var result := EvolutionCandidate.new(index, pokemon.species_id, into)
	result.cancellable = false
	result.item_id = item_id
	return result
