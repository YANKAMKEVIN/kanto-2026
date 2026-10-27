class_name ToxicRules
extends RefCounted
## Poison grave de Toxik (J23, dossier 26 §10.4, N-14 ; plan `jalon-23.md` §2.12) : classe statique
## et pure, branchée sur le moteur de combat en T18.
##
## Le Pokémon gravement empoisonné a le statut [constant StatusRules.POISON] **et** un compteur N
## (porté par son combattant). À chaque fin de tour, N augmente de 1 puis il perd N/16 de ses PV
## max (au moins 1, au plus ses PV restants) : 1/16, 2/16, 3/16… Au **changement de Pokémon** et
## en **fin de combat**, le compteur repart à zéro et le poison grave redevient un poison simple
## (Rouge/Bleu). L'interaction RB avec Vampigraine n'est pas reprise. Hors combat : poison simple
## (aucun effet, règle du J11).

## Part des PV max perdue par cran de compteur.
const STEP_FRACTION: float = 1.0 / 16.0
## Compteur d'un Pokémon qui n'est pas gravement empoisonné (ou qui vient de l'être, avant son
## premier tour).
const OFF: int = 0
## Plafond du compteur (RB n'en a pas ; 15/16 suffit à tout K.O.).
const MAX_COUNTER: int = 15


## Compteur après une fin de tour (1 au premier tour, puis +1, plafonné).
static func next_counter(counter: int) -> int:
	return mini(maxi(counter, OFF) + 1, MAX_COUNTER)


## PV perdus par [param pokemon] en fin de tour avec le compteur [param counter] (déjà augmenté
## par [method next_counter]) : ⌊PVmax × N / 16⌋, au moins 1, au plus ses PV ; 0 s'il est K.O.,
## s'il n'est pas empoisonné ou si N vaut 0. Rien ne change (le moteur retire les PV).
static func end_turn_damage(pokemon: Pokemon, counter: int) -> int:
	if pokemon == null or pokemon.is_fainted() or pokemon.status != StatusRules.POISON \
			or counter <= OFF:
		return 0
	var damage := floori(pokemon.max_hp() * STEP_FRACTION * counter)
	return mini(maxi(damage, 1), pokemon.hp)


## Compteur au changement de Pokémon ou en fin de combat : toujours [constant OFF] (le Pokémon
## garde un poison simple).
static func reset_counter() -> int:
	return OFF
