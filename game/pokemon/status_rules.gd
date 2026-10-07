class_name StatusRules
extends RefCounted
## Statuts durables des Pokémon (jalon 9 §2.1.1) : classe statique et pure.
##
## Un statut est un identifiant ([member Pokemon.status]) ; [constant NONE] = aucun. Un seul
## statut à la fois : un Pokémon qui en a déjà un n'en reçoit pas d'autre. Jalon 9 : le poison
## seul ; le J11 ajoute ses statuts à [constant KNOWN] et leurs règles ici, sans toucher au
## modèle.
##
## Règles du poison (décision de Kevin, Q-6 du 2026-10-07, règles actuelles) : 1/8 des PV max
## perdus à chaque fin de tour en combat (au moins 1) ; types Poison et Acier immunisés ;
## capture ×1,5 sur une cible empoisonnée ; statut effacé au K.O. ([Battle]). Hors combat,
## **aucune perte de PV** (arbitrage 2 du dossier 10) : rien n'écoute les pas pour le poison.
## Le statut reste jusqu'à un objet qui le soigne ([member ItemData.cures]) ou un soin complet
## ([method Pokemon.heal_full] : Centre, Maman, réveil après une défaite).

## Réponse de [method can_inflict], dans l'ordre où elle est vérifiée : OK, ou la raison du
## refus — FAINTED (cible K.O.), IMMUNE (type immunisé), ALREADY (un statut déjà présent,
## quel qu'il soit : un seul à la fois).
enum Inflict { OK, ALREADY, IMMUNE, FAINTED }

const NONE: StringName = &""
const POISON: StringName = &"poison"
## Statuts connus de cette build (sauvegarde, départs de débogage, effets de capacité, objets).
const KNOWN: Array[StringName] = [POISON]
## Part des PV max perdue par le poison à chaque fin de tour (au moins 1 PV).
const POISON_FRACTION: float = 1.0 / 8.0
## Types qui ne peuvent pas être empoisonnés.
const POISON_IMMUNE_TYPES: Array[StringName] = [&"poison", &"steel"]
## Multiplicateur de capture d'une cible empoisonnée ([CaptureCalc], « bonus_statut »).
const POISON_CATCH_BONUS: float = 1.5


## Vrai si [param id] est un statut connu ([constant NONE] n'en est pas un).
static func is_known(id: StringName) -> bool:
	return KNOWN.has(id)


## Le statut [param status] peut-il être infligé à [param pokemon], de types [param types]
## (ceux de son [Battler] en combat) ? Rien ne change.
static func can_inflict(status: StringName, pokemon: Pokemon,
		types: Array[StringName]) -> Inflict:
	if pokemon == null or pokemon.is_fainted():
		return Inflict.FAINTED
	for type: StringName in immune_types(status):
		if types.has(type):
			return Inflict.IMMUNE
	if pokemon.status != NONE:
		return Inflict.ALREADY
	return Inflict.OK


## Types immunisés contre [param status] (vide : aucun).
static func immune_types(status: StringName) -> Array[StringName]:
	if status == POISON:
		return POISON_IMMUNE_TYPES
	return []


## PV que [param pokemon] perd en fin de tour à cause de son statut : 1/8 de ses PV max pour le
## poison (au moins 1, au plus ses PV restants) ; 0 sans statut à dégâts ou s'il est K.O.
## Rien ne change (le moteur retire les PV).
static func end_turn_damage(pokemon: Pokemon) -> int:
	if pokemon == null or pokemon.is_fainted() or pokemon.status != POISON:
		return 0
	return mini(maxi(floori(pokemon.max_hp() * POISON_FRACTION), 1), pokemon.hp)


## Multiplicateur de capture pour une cible au statut [param status] (1,0 sans statut).
static func catch_bonus(status: StringName) -> float:
	if status == POISON:
		return POISON_CATCH_BONUS
	return 1.0
