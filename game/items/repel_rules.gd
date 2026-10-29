class_name RepelRules
extends RefCounted
## Repousse, Super Repousse, Max Repousse (lot 32P, AUD-14). Classe statique et pure.
##
## Rouge/Bleu : pendant [member ItemData.repel_steps] pas (100 / 200 / 250), un Pokémon sauvage
## d'un niveau **inférieur** à celui du premier Pokémon de l'équipe ne se montre pas (le premier
## Pokémon encore debout [D]). Les herbes, grottes et gravats sont concernés ; la pêche et les
## rencontres fixes ne le sont pas. Une nouvelle Repousse remplace le compteur en cours
## (Rouge/Bleu). Le compteur ([member GameState.repel_steps]) **n'est pas sauvegardé** [D] : il
## repart de zéro au chargement, sans toucher au format de la sauvegarde.

## Phrase du Sac quand la Repousse est utilisée (texte validé par Kevin le 2026-10-29).
const USED_FORMAT := "Les Pokémon sauvages faibles t'éviteront (%d pas)."
## Fin de l'effet : dialogue de `data/dialogues/key_items.json`.
const WORE_OFF_DIALOGUE: StringName = &"repel_wore_off"


## Vrai si [param item] est une Repousse (UTILISER agit sans choisir de Pokémon).
static func is_repel(item: ItemData) -> bool:
	return item != null and item.has_field_use() and item.field_use == ItemData.FIELD_USE_REPEL


## Niveau du premier Pokémon debout de [param party] ; 0 sans Pokémon debout.
static func lead_level(party: Party) -> int:
	if party == null:
		return 0
	for pokemon: Pokemon in party.get_all():
		if not pokemon.is_fainted():
			return pokemon.level
	return 0


## Vrai si la Repousse active ([param steps_left] > 0) écarte un sauvage de niveau
## [param wild_level] face à l'équipe [param party].
static func blocks(steps_left: int, wild_level: int, party: Party) -> bool:
	return steps_left > 0 and wild_level < lead_level(party)


## Compteur après un pas : [param steps_left] − 1, jamais sous 0.
static func tick(steps_left: int) -> int:
	return maxi(steps_left - 1, 0)
