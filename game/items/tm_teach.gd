class_name TmTeach
extends RefCounted
## Apprendre une CT (jalon 11, dossier 14 §6.1) : classe statique et pure. Jalon 16 : une CS
## ([method ItemData.is_hm]) s'apprend de la même façon, compatibilité lue par
## [method PokemonData.can_learn_hm].
##
## Une CT ([method ItemData.is_tm]) enseigne sa capacité ([member ItemData.teaches]) à un Pokémon
## dont l'espèce est compatible ([method PokemonData.can_learn_tm]), hors combat seulement. Elle
## n'est **jamais consommée** : rien ici ne touche au Sac. Un Pokémon qui connaît déjà la capacité
## ne peut pas l'apprendre ; avec 4 capacités, la présentation lance le déroulé « oublier une
## capacité » existant ([method Pokemon.replace_move], GARDER annule).

## État d'un Pokémon face à une CT (liste de l'équipe, textes n° 41 du §13).
enum Check { COMPATIBLE, KNOWN, INCOMPATIBLE }

## Libellés de la liste de l'équipe (dossier 14 §13, n° 41).
const LABELS: Dictionary[Check, String] = {
	Check.COMPATIBLE: "COMPATIBLE",
	Check.KNOWN: "DÉJÀ CONNUE",
	Check.INCOMPATIBLE: "INCOMPATIBLE",
}
## Refus en combat (n° 44).
const IN_BATTLE_TEXT: String = "Les CT s'utilisent hors combat."


## État de [param pokemon] face à la CT [param item] (une CT inconnue ou sans capacité :
## INCOMPATIBLE). « Déjà connue » passe avant la compatibilité.
static func check(pokemon: Pokemon, item: ItemData, data: PokemonData) -> Check:
	if pokemon == null or item == null or not item.is_tm() or not data.has_move(item.teaches):
		return Check.INCOMPATIBLE
	if pokemon.knows_move(item.teaches):
		return Check.KNOWN
	var compatible := data.can_learn_hm(pokemon.species_id, item.hm_number) if item.is_hm() \
		else data.can_learn_tm(pokemon.species_id, item.tm_number)
	if not compatible:
		return Check.INCOMPATIBLE
	return Check.COMPATIBLE


## Fait apprendre la CT à [param pokemon] s'il a un emplacement libre : LEARNED (PP pleins),
## NEEDS_FORGET (4 capacités : rien ne change, la présentation fait choisir), ou INVALID
## (pas COMPATIBLE : rien ne change). La CT reste dans le Sac.
static func teach(pokemon: Pokemon, item: ItemData, data: PokemonData) -> Pokemon.LearnResult:
	if check(pokemon, item, data) != Check.COMPATIBLE:
		return Pokemon.LearnResult.INVALID
	return pokemon.learn_move(item.teaches, data)
