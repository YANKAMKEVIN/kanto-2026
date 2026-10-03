class_name BattleEvent
extends RefCounted
## Une ligne du journal de combat (jalon 4 §2.2 et §3.4). Donnée pure.
##
## Le moteur ([Battle]) ne joue rien : il renvoie une liste d'événements que la
## présentation joue dans l'ordre, à son rythme. Chaque événement porte [b]l'état
## d'après[/b] (PV restants, niveau de statistique, PP) : la présentation n'interroge
## jamais le moteur pendant qu'elle joue. Champs utiles selon [member kind] :
## - BATTLE_STARTED : [member trainer_name] (camp adverse) ;
## - SENT_OUT : Pokémon envoyé ([member pokemon_name], [member species_id], [member level],
##   [member gender], [member hp], [member max_hp]) et [member trainer_name] de son camp ;
## - TURN_STARTED : [member turn] ;
## - MOVE_USED : lanceur, [member move_id], [member pp] restants (−1 pour Lutte) ;
## - MOVE_MISSED : lanceur, [member move_id] ;
## - DAMAGE : cible, [member amount] (PV perdus), [member hp], [member max_hp],
##   [member effectiveness], [member critical] ;
## - NO_EFFECT : cible (type immunisé), [member move_id] ;
## - STAT_CHANGED : Pokémon touché, [member stat], [member stages] (variation réelle),
##   [member stage] (niveau d'après) ;
## - STAT_UNCHANGED : Pokémon touché, [member stat], [member stages] (variation demandée),
##   [member stage] (déjà au bout) ;
## - RECOIL : lanceur, [member amount], [member hp], [member max_hp] ;
## - FAINTED : Pokémon K.O. ;
## - BATTLE_ENDED : [member outcome] ([enum Battle.Outcome], du point de vue du joueur) ;
## - FLED : le joueur a réussi à fuir (combat sauvage) ;
## - FLEE_FAILED : la fuite a échoué, l'adversaire va jouer.
## Jalon 5C (§2.3), toujours entre le FAINTED adverse et la suite (BATTLE_ENDED ou envoi
## suivant) ; le Pokémon concerné est un participant du joueur, pas forcément celui en jeu :
## - EXP_GAINED : une tranche de barre d'XP, dans le [member level] où elle se remplit, de
##   [member exp_from] à [member exp_to] (fractions 0..1 de la barre) ; [member amount] =
##   XP gagnée en tout sur la première tranche, 0 sur les suivantes (un niveau gagné ouvre
##   une nouvelle tranche) ; [member hp], [member max_hp] avant le niveau suivant ;
## - LEVEL_UP : nouveau [member level], [member hp] et [member max_hp] recalculés ;
## - MOVE_LEARNED : [member move_id] appris dans un emplacement libre (déjà fait par le
##   moteur) ;
## - MOVE_FORGET_OFFERED : [member move_id] à apprendre alors que les 4 emplacements sont
##   pris. Rien n'a changé : la présentation fait choisir le joueur
##   ([method Pokemon.replace_move] ou rien).
## Vampigraine (Q28) :
## - SEEDED : Pokémon sur lequel la graine est plantée ;
## - DRAINED : Pokémon drainé en fin de tour ([member amount] PV perdus, [member hp],
##   [member max_hp]) ; [member healed] PV rendus au Pokémon d'en face, qui en a ensuite
##   [member healed_hp].
## Tout événement sur un Pokémon porte aussi [member party_index] : sa place dans l'équipe de
## son camp (0 = en tête). La présentation retrouve ainsi le Pokémon exact (SENT_OUT : celui
## que le moteur envoie, pas forcément le premier de l'équipe ; MOVE_FORGET_OFFERED : celui qui
## apprend), sans le chercher par espèce et nom, ambigus avec deux Pokémon identiques.
## Capture (jalon 5D, §2.4), juste après TURN_STARTED, toutes sur le Pokémon sauvage (camp
## FOE, son état au moment du lancer) :
## - BALL_THROWN : la Ball [member item_id] ([member item_name] : son nom) est lancée ;
## - BALL_SHAKE : une secousse, numéro [member shake] (1 à 3) ; 0 à 3 de suite ;
## - CAUGHT : capturé (après 3 secousses), puis BATTLE_ENDED (CAUGHT) ; l'adversaire ne joue
##   pas, aucune XP n'est donnée ;
## - BROKE_FREE : il s'est libéré, puis l'adversaire joue son tour.
## Soin (jalon 6, §3.4), juste après TURN_STARTED, puis l'adversaire joue son tour :
## - ITEM_USED : le soin [member item_id] ([member item_name]) est donné au Pokémon du joueur
##   [member party_index] (pas forcément celui en jeu) ; [member amount] PV rendus,
##   [member hp] et [member max_hp] d'après.

enum Kind {
	BATTLE_STARTED, SENT_OUT, TURN_STARTED, MOVE_USED, MOVE_MISSED, DAMAGE, NO_EFFECT,
	STAT_CHANGED, STAT_UNCHANGED, RECOIL, FAINTED, BATTLE_ENDED, FLED, FLEE_FAILED,
	EXP_GAINED, LEVEL_UP, MOVE_LEARNED, MOVE_FORGET_OFFERED, SEEDED, DRAINED,
	BALL_THROWN, BALL_SHAKE, CAUGHT, BROKE_FREE,
	ITEM_USED,
}
enum SideId { PLAYER, FOE }

var kind: Kind = Kind.BATTLE_STARTED
## Camp concerné (le lanceur, la cible ou le Pokémon touché selon [member kind]).
var side: SideId = SideId.PLAYER
## Nom affiché du Pokémon concerné (surnom ou espèce).
var pokemon_name: String = ""
var species_id: StringName = &""
var level: int = 0
var gender: Pokemon.Gender = Pokemon.Gender.NONE
## Place du Pokémon concerné dans l'équipe de son camp (−1 : événement sans Pokémon).
var party_index: int = -1
var trainer_name: String = ""
var turn: int = 0
var move_id: StringName = &""
var pp: int = 0
var amount: int = 0
var hp: int = 0
var max_hp: int = 0
var effectiveness: float = 1.0
var critical: bool = false
var stat: StringName = &""
var stages: int = 0
var stage: int = 0
var outcome: int = 0
## EXP_GAINED : remplissage de la barre d'XP au début et à la fin de la tranche (0..1).
var exp_from: float = 0.0
var exp_to: float = 0.0
## DRAINED : PV rendus au Pokémon d'en face, et ses PV ensuite.
var healed: int = 0
var healed_hp: int = 0
## BALL_THROWN, ITEM_USED : l'objet (identifiant et nom affiché, « Poké Ball », « Potion »).
var item_id: StringName = &""
var item_name: String = ""
## BALL_SHAKE : numéro de la secousse (1 à 3).
var shake: int = 0


func _init(event_kind: Kind = Kind.BATTLE_STARTED, event_side: SideId = SideId.PLAYER) -> void:
	kind = event_kind
	side = event_side


## Tous les champs (journaux, tests de reproductibilité).
func to_dict() -> Dictionary:
	return {
		"kind": Kind.find_key(kind), "side": SideId.find_key(side), "pokemon": pokemon_name,
		"species": species_id, "party_index": party_index, "level": level, "gender": gender,
		"trainer": trainer_name, "turn": turn, "move": move_id, "pp": pp, "amount": amount, "hp": hp,
		"max_hp": max_hp, "effectiveness": effectiveness, "critical": critical,
		"stat": stat, "stages": stages, "stage": stage, "outcome": outcome,
		"exp_from": exp_from, "exp_to": exp_to, "healed": healed, "healed_hp": healed_hp,
		"item": item_id, "item_name": item_name, "shake": shake,
	}
