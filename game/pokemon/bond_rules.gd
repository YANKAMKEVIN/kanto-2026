class_name BondRules
extends RefCounted
## Le lien (JOH0, JH-11 validé par Kevin le 2026-11-02 ; `jalon-joh0.md` §2.7 ; dossier JOH-01
## §8) : une valeur **cachée** (JH-21) de 0 à 100 par Pokémon ([member Pokemon.bond]) qui vient
## de l'aventure, jamais d'un objet ni d'un soin. Classe statique et pure ; toutes les valeurs
## sont des défauts **[D]** (règle 4), à régler sur partie.
##
## - Départ : [constant START_CAPTURE] pour un Pokémon capturé, [constant START_GIFT] pour un
##   Pokémon de départ, un cadeau, un échange fixe ou un œuf éclos ([method start_for]) ; les
##   Pokémon d'une sauvegarde d'avant la v10 valent [constant Pokemon.DEFAULT_BOND] (50).
## - Gains : [constant WIN_GAIN] par combat gagné auquel le Pokémon a participé ;
##   +1 tous les [constant STEPS_PER_POINT] pas dans l'équipe, [constant COMPANION_BONUS] de plus
##   au compagnon ([BondStepCounter]).
## - Perte : [constant FAINT_LOSS] à chaque K.O.
## - Seuil : [constant THRESHOLD] ; au-delà, une règle d'évolution « bond » se déclenche au
##   prochain niveau gagné ([method Evolution.level_up_target]).
## - Paliers de lecture ([method tier], PNJ de Doublonville, JOH3) : < 30, 30–69, 70–89, ≥ 90.

const MIN: int = 0
const MAX: int = 100
const THRESHOLD: int = 70
const START_CAPTURE: int = 20
const START_GIFT: int = 50
const WIN_GAIN: int = 2
const STEPS_PER_POINT: int = 256
const COMPANION_BONUS: int = 1
const FAINT_LOSS: int = 3
## Bornes basses des paliers 1, 2 et 3 ([method tier]).
const TIER_BOUNDS: Array[int] = [30, 70, 90]


## Lien de départ selon la manière dont le Pokémon arrive dans l'équipe.
static func start_for(origin: Pokemon.Origin) -> int:
	return START_CAPTURE if origin == Pokemon.Origin.CAPTURE else START_GIFT


## Vrai si [param bond] permet une évolution par lien.
static func reaches_threshold(bond: int) -> bool:
	return bond >= THRESHOLD


## Fin de combat (Boot, `battle_finished`) : victoire ou capture → [constant WIN_GAIN] à chaque
## place de [param participants] (ceux qui ont gagné de l'XP, [method ExpSummary.get_entries]) ;
## quelle que soit l'issue, [constant FAINT_LOSS] à chaque place de [param fainted] (un K.O. du
## joueur par entrée, [method BattleDirector.get_fainted_indices]). Les œufs ne bougent pas.
static func apply_battle(party: Party, won: bool, participants: Array[int],
		fainted: Array[int]) -> void:
	if party == null:
		return
	if won:
		for index: int in participants:
			var pokemon := party.get_at(index)
			if pokemon != null and not pokemon.is_egg():
				pokemon.add_bond(WIN_GAIN)
	for index: int in fainted:
		var pokemon := party.get_at(index)
		if pokemon != null and not pokemon.is_egg():
			pokemon.add_bond(-FAINT_LOSS)


## Palier de lecture de [param bond] : 0 (< 30), 1 (30–69), 2 (70–89) ou 3 (≥ 90).
static func tier(bond: int) -> int:
	var result := 0
	for bound: int in TIER_BOUNDS:
		if bond >= bound:
			result += 1
	return result
