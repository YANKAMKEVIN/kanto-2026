class_name FleeCalc
extends RefCounted
## Réussite d'une tentative de fuite d'un combat sauvage (jalon 5 §2.2, Q18). Statique et pur.
##
## Formule des 3e et 4e générations, sur les Vitesses [b]sans niveaux de statistiques[/b]
## (les baisses de Vitesse de l'adversaire ne facilitent pas la fuite au jalon 5) :
## - fuite assurée si la Vitesse du joueur ≥ celle du sauvage (ou si le sauvage est immobile) ;
## - sinon F = ⌊A · 128 / B⌋ + 30 · C (A = Vitesse du joueur, B = celle du sauvage,
##   C = tentatives déjà ratées de ce combat) ; réussite si F > 255, sinon roll(256) − 1 < F.
## Un seul tirage roll(256), et seulement quand la fuite n'est pas déjà assurée : l'ordre est
## documenté par [Battle] (tentative de fuite avant le tour de l'adversaire).

const ROLL_DEN: int = 256
const ATTEMPT_BONUS: int = 30


## Vrai si la fuite réussit. [param failed_attempts] : tentatives déjà ratées de ce combat (C).
static func can_flee(player_speed: int, foe_speed: int, failed_attempts: int,
		rng: GameRng) -> bool:
	if foe_speed <= 0 or player_speed >= foe_speed:
		return true
	@warning_ignore("integer_division")
	var f := player_speed * 128 / foe_speed + ATTEMPT_BONUS * failed_attempts
	if f > 255:
		return true
	return rng.roll(ROLL_DEN) - 1 < f
