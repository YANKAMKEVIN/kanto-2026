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
## - BATTLE_ENDED : [member outcome] ([enum Battle.Outcome], du point de vue du joueur).

enum Kind {
	BATTLE_STARTED, SENT_OUT, TURN_STARTED, MOVE_USED, MOVE_MISSED, DAMAGE, NO_EFFECT,
	STAT_CHANGED, STAT_UNCHANGED, RECOIL, FAINTED, BATTLE_ENDED,
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


func _init(event_kind: Kind = Kind.BATTLE_STARTED, event_side: SideId = SideId.PLAYER) -> void:
	kind = event_kind
	side = event_side


## Tous les champs (journaux, tests de reproductibilité).
func to_dict() -> Dictionary:
	return {
		"kind": Kind.find_key(kind), "side": SideId.find_key(side), "pokemon": pokemon_name,
		"species": species_id, "level": level, "gender": gender, "trainer": trainer_name,
		"turn": turn, "move": move_id, "pp": pp, "amount": amount, "hp": hp,
		"max_hp": max_hp, "effectiveness": effectiveness, "critical": critical,
		"stat": stat, "stages": stages, "stage": stage, "outcome": outcome,
	}
