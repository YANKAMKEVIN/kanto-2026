class_name ChargeRules
extends RefCounted
## Règles pures de « charge puis frappe » (jalon 14, `jalon-14.md` §2.3, dossier 17 §7). Statique.
##
## Tour 1 : la capacité (effet CHARGE de [MoveData]) se charge, aucun dégât ; le lanceur est
## peut-être invulnérable ([member MoveEffect.invulnerable], Tunnel). Tour 2 : action imposée,
## frappe sans PP — sauf si le lanceur ne peut pas agir, ou s'il était endormi ou gelé au moment
## d'agir (même s'il se réveille ou dégèle alors, comme Patience) : il « remonte » sans frapper.
## Sous terre, il évite toute capacité qui le vise ([method targets_foe]) ; les capacités sur
## soi et les dégâts de fin de tour (poison, brûlure, graine) ne sont pas concernés.


## Vrai si [param move] vise le Pokémon d'en face : capacité offensive, ou capacité de statut
## dont un effet touche la cible (statut, confusion, graine, apeurement, dégâts fixes, niveau
## d'une statistique de la cible). Puissance, Armure, Patience, Téléport : non.
static func targets_foe(move: MoveData) -> bool:
	if move == null:
		return false
	if move.is_damaging():
		return true
	for effect: MoveEffect in move.effects:
		match effect.kind:
			MoveEffect.Kind.STATUS, MoveEffect.Kind.CONFUSION, MoveEffect.Kind.SEED, \
					MoveEffect.Kind.FLINCH, MoveEffect.Kind.FIXED_DAMAGE:
				return true
			MoveEffect.Kind.STAT_STAGE:
				if effect.target == MoveEffect.Target.FOE:
					return true
	return false


## Vrai si [param target] (invulnérable pendant sa charge) évite [param move].
static func dodges(target: Battler, move: MoveData) -> bool:
	return target != null and target.invulnerable and targets_foe(move)


## Vrai si la charge d'un Pokémon est rompue au tour 2 : il ne peut pas agir ([param can_act]
## faux : paralysie totale, sommeil, gel, apeurement, se frapper dans la confusion), ou il était
## endormi ou gelé au moment d'agir ([param status_before], avant le réveil ou le dégel).
static func breaks_charge(status_before: StringName, can_act: bool) -> bool:
	return not can_act or status_before == StatusRules.SLEEP \
		or status_before == StatusRules.FREEZE
