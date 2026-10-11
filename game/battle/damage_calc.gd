class_name DamageCalc
extends RefCounted
## Précision et dégâts, formule moderne (5e génération et suivantes), jalon 4 §2.2.
## Statique et pur ; tout l'aléatoire vient du [GameRng] reçu.
##
## Ordre des tirages de [method compute] : aucun si la cible est immunisée ; précision
## (roll(100), sauf capacité qui ne rate jamais) ; critique (roll(24), roll(8)… selon
## [member MoveData.crit_stage]) ; aléatoire (85..100, un roll(16)).
## Dégâts : base = ⌊⌊⌊2·N/5 + 2⌋ · P · A / D⌋ / 50⌋ + 2, puis dans l'ordre critique ×1,5,
## aléatoire ⌊× (85..100) / 100⌋, bonus de type (STAB) ×1,5, efficacité ; chaque étape
## arrondie vers le bas, minimum 1 si l'efficacité n'est pas nulle. Physique : Attaque /
## Défense ; spéciale : Attaque Spéciale / Défense Spéciale. Un critique ignore les baisses
## de l'attaquant et les hausses du défenseur. Un attaquant brûlé inflige moitié moins de dégâts
## physiques (jalon 11, après l'efficacité, au moins 1).

@warning_ignore_start("integer_division")


## Résultat d'une capacité offensive de [param attacker] sur [param defender].
static func compute(attacker: Battler, defender: Battler, move: MoveData, chart: TypeChart,
		rng: GameRng) -> DamageResult:
	var result := DamageResult.new()
	var attack_type := &"" if move.typeless else move.type
	result.effectiveness = chart.multiplier(attack_type, defender.types)
	if result.effectiveness == 0.0:
		result.hit = true
		return result
	if not accuracy_check(attacker, defender, move, rng):
		return result
	result.hit = true
	result.critical = rng.chance(1, move.crit_denominator())
	var physical := move.category == MoveData.Category.PHYSICAL
	var attack := attacker.effective_stat(&"atk" if physical else &"spa", result.critical)
	var defense := defender.effective_stat(&"def" if physical else &"spd", false,
		result.critical)
	var level := attacker.pokemon.level
	var damage := (2 * level / 5 + 2) * move.power * attack / maxi(defense, 1) / 50 + 2
	if result.critical:
		damage = damage * 3 / 2
	damage = damage * rng.range_int(85, 100) / 100
	if not move.typeless and attacker.types.has(move.type):
		damage = damage * 3 / 2
	damage = floori(damage * result.effectiveness)
	# Brûlure (jalon 11, [StatusRules]) : dégâts physiques du lanceur brûlé ÷ 2.
	if physical and StatusRules.halves_physical(attacker.pokemon.status):
		damage = damage / 2
	result.amount = maxi(damage, 1)
	return result


## Vrai si la capacité touche : toujours si [member MoveData.accuracy] vaut 0 (aucun
## tirage), sinon roll(100) ≤ précision × multiplicateur (précision du lanceur − esquive de
## la cible).
static func accuracy_check(attacker: Battler, defender: Battler, move: MoveData,
		rng: GameRng) -> bool:
	if move.never_misses():
		return true
	var net := attacker.get_stage(&"acc") - defender.get_stage(&"eva")
	var threshold := floori(move.accuracy * Battler.accuracy_multiplier(net))
	return rng.roll(100) <= threshold
