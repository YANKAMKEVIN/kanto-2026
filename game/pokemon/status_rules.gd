class_name StatusRules
extends RefCounted
## Statuts durables des Pokémon (jalon 9 §2.1.1, jalon 11 §2.2) : classe statique et pure.
##
## Un statut est un identifiant ([member Pokemon.status]) ; [constant NONE] = aucun. Un seul
## statut à la fois : un Pokémon qui en a déjà un n'en reçoit pas d'autre.
##
## Règles du poison (décision de Kevin, Q-6 du 2026-10-07, inchangées au J11) : 1/8 des PV max
## perdus à chaque fin de tour en combat (au moins 1) ; types Poison et Acier immunisés ;
## capture ×1,5. Statut effacé au K.O. ([Battle]). Hors combat, **aucune perte de PV ni aucun
## effet** (arbitrage 2 du dossier 10, règle commune du dossier 14 §3.1) : rien n'écoute les
## pas. Le statut reste jusqu'à un objet qui le soigne ([member ItemData.cures]) ou un soin
## complet ([method Pokemon.heal_full] : Centre, Maman, réveil après une défaite).
##
## Statuts du J11 (dossier 14 §3.1, décision 3 « règles modernes simplifiées » ; valeurs par
## défaut [D] de la règle 4 notées) :
##  - brûlure : 1/16 des PV max en fin de tour (au moins 1) ; dégâts **physiques** infligés
##    ÷ 2 ([DamageCalc]) ; type Feu immunisé [D] ; capture ×1,5 [D] ;
##  - paralysie : Vitesse ÷ 2 (ordre d'action) ; 25 % de chance de ne pas agir à chaque
##    tentative ; type Électrik immunisé [D] ; capture ×1,5 [D] ;
##  - sommeil : 1 à 3 tours perdus, tirés à l'application ([method sleep_turns],
##    [member Pokemon.status_turns]) ; le compteur baisse à chaque tentative d'agir ; à 0, le
##    Pokémon se réveille et agit dans le même tour [D] ; capture ×2,5 [D] ;
##  - gel : ne peut pas agir ; 20 % de dégel à chaque tentative (il agit alors) ; dégelé par
##    une capacité Feu qui le touche ([Battle]) [D] ; type Glace immunisé [D] ; capture ×2,5.
## Le compteur de sommeil est gardé au changement de Pokémon, après le combat et dans la
## sauvegarde (A-1).

## Réponse de [method can_inflict], dans l'ordre où elle est vérifiée : OK, ou la raison du
## refus — FAINTED (cible K.O.), IMMUNE (type immunisé), ALREADY (un statut déjà présent,
## quel qu'il soit : un seul à la fois).
enum Inflict { OK, ALREADY, IMMUNE, FAINTED }
## Réponse de [method check_act] : le Pokémon agit (OK ; WOKE_UP et THAWED : son statut vient
## de finir, il agit quand même) ou non (FULLY_PARALYZED, ASLEEP, FROZEN).
enum Act { OK, FULLY_PARALYZED, ASLEEP, WOKE_UP, FROZEN, THAWED }

const NONE: StringName = &""
const POISON: StringName = &"poison"
const PARALYSIS: StringName = &"paralysis"
const SLEEP: StringName = &"sleep"
const BURN: StringName = &"burn"
const FREEZE: StringName = &"freeze"
## Statuts connus de cette build (sauvegarde, départs de débogage, effets de capacité, objets).
const KNOWN: Array[StringName] = [POISON, PARALYSIS, SLEEP, BURN, FREEZE]
## Part des PV max perdue par le poison à chaque fin de tour (au moins 1 PV).
const POISON_FRACTION: float = 1.0 / 8.0
## Part des PV max perdue par la brûlure à chaque fin de tour (au moins 1 PV).
const BURN_FRACTION: float = 1.0 / 16.0
## Types qui ne peuvent pas être empoisonnés.
const POISON_IMMUNE_TYPES: Array[StringName] = [&"poison", &"steel"]
## Types immunisés contre chaque statut du J11.
const IMMUNE_TYPES: Dictionary[StringName, Array] = {
	BURN: [&"fire"], PARALYSIS: [&"electric"], FREEZE: [&"ice"],
}
## Multiplicateur de capture d'une cible empoisonnée ([CaptureCalc], « bonus_statut »).
const POISON_CATCH_BONUS: float = 1.5
## Multiplicateur de capture : sommeil et gel ×2,5, les autres ×1,5.
const STRONG_CATCH_BONUS: float = 2.5
## Chance (en %) qu'un Pokémon paralysé ne puisse pas agir.
const FULL_PARALYSIS_CHANCE: int = 25
## Chance (en %) qu'un Pokémon gelé dégèle au moment d'agir.
const THAW_CHANCE: int = 20
## Tours de sommeil tirés à l'application ([method sleep_turns]).
const SLEEP_MIN_TURNS: int = 1
const SLEEP_MAX_TURNS: int = 3
## Vitesse d'un Pokémon paralysé (multiplicateur).
const PARALYSIS_SPEED: float = 0.5


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
	var result: Array[StringName] = []
	result.assign(IMMUNE_TYPES.get(status, []))
	return result


## Pose [param status] sur [param pokemon] (déjà vérifié par [method can_inflict]) : le compteur
## de sommeil est tiré dans [param rng] (un range_int), aucun tirage pour les autres statuts.
static func apply(status: StringName, pokemon: Pokemon, rng: GameRng) -> void:
	pokemon.status = status
	pokemon.status_turns = sleep_turns(rng) if status == SLEEP else 0


## Tours de sommeil tirés à l'application (1 à 3).
static func sleep_turns(rng: GameRng) -> int:
	return rng.range_int(SLEEP_MIN_TURNS, SLEEP_MAX_TURNS)


## Le Pokémon [param pokemon] peut-il agir ce tour-ci ? Fait évoluer son statut (compteur de
## sommeil, réveil, dégel). Tirages : roll(100) pour la paralysie et pour le gel ; aucun pour le
## sommeil ni sans statut qui empêche d'agir.
static func check_act(pokemon: Pokemon, rng: GameRng) -> Act:
	match pokemon.status:
		SLEEP:
			if pokemon.status_turns > 0:
				pokemon.status_turns -= 1
				return Act.ASLEEP
			pokemon.cure_status()
			return Act.WOKE_UP
		FREEZE:
			if rng.roll(100) <= THAW_CHANCE:
				pokemon.cure_status()
				return Act.THAWED
			return Act.FROZEN
		PARALYSIS:
			if rng.roll(100) <= FULL_PARALYSIS_CHANCE:
				return Act.FULLY_PARALYZED
	return Act.OK


## Vrai si [param act] empêche d'agir.
static func prevents_action(act: Act) -> bool:
	return act == Act.FULLY_PARALYZED or act == Act.ASLEEP or act == Act.FROZEN


## PV que [param pokemon] perd en fin de tour à cause de son statut : 1/8 de ses PV max pour le
## poison, 1/16 pour la brûlure (au moins 1, au plus ses PV restants) ; 0 sans statut à dégâts
## ou s'il est K.O. Rien ne change (le moteur retire les PV).
static func end_turn_damage(pokemon: Pokemon) -> int:
	if pokemon == null or pokemon.is_fainted():
		return 0
	var fraction := 0.0
	if pokemon.status == POISON:
		fraction = POISON_FRACTION
	elif pokemon.status == BURN:
		fraction = BURN_FRACTION
	else:
		return 0
	return mini(maxi(floori(pokemon.max_hp() * fraction), 1), pokemon.hp)


## Multiplicateur de Vitesse d'un Pokémon au statut [param status] (paralysie : ÷ 2).
static func speed_multiplier(status: StringName) -> float:
	return PARALYSIS_SPEED if status == PARALYSIS else 1.0


## Vrai si le statut [param status] divise par deux les dégâts physiques infligés (brûlure).
static func halves_physical(status: StringName) -> bool:
	return status == BURN


## Multiplicateur de capture pour une cible au statut [param status] (1,0 sans statut).
static func catch_bonus(status: StringName) -> float:
	if status == SLEEP or status == FREEZE:
		return STRONG_CATCH_BONUS
	if status == POISON:
		return POISON_CATCH_BONUS
	if is_known(status):
		return 1.5
	return 1.0
