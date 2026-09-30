class_name BattleRules
extends RefCounted
## Les règles d'un combat : sauvage ou dresseur, fuite, XP, Balls (jalon 5 §2.2). Donnée pure.
##
## Le moteur ([Battle]) reçoit ces règles (null = comportement du 4B, combat du rival) : elles
## décident ce qui est permis (la fuite, plus tard le Sac) et ce qui suit la victoire (l'XP, son
## multiplicateur). Elles ne portent aucun nœud ni aucune donnée ; les conséquences hors moteur
## (soin, argent) restent au directeur (dresseur) ou à l'[EncounterDirector] (sauvage).

## Combat contre un Pokémon sauvage (par opposition à un dresseur).
var wild: bool = false
## La fuite ([constant BattleAction.Kind.RUN]) est permise.
var can_flee: bool = false
## Le combat donne de l'XP à la victoire (5C).
var gives_exp: bool = true
## Multiplicateur d'XP (1,0 sauvage ; 1,5 dresseur, Q23).
var exp_multiplier: float = 1.0
## Le Sac et les Balls sont permis (sauvage seulement, 5D).
var allow_balls: bool = false


## Règles d'un combat sauvage : fuite permise, XP ×1, Balls permises.
static func for_wild() -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = true
	rules.can_flee = true
	rules.gives_exp = true
	rules.exp_multiplier = 1.0
	rules.allow_balls = true
	return rules


## Règles d'un combat de dresseur : pas de fuite, XP ×1,5, pas de Balls (Q23). [param trainer]
## est reçu pour d'éventuelles règles propres au dresseur (aucune au jalon 5).
static func for_trainer(_trainer: TrainerData = null) -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = false
	rules.can_flee = false
	rules.gives_exp = true
	rules.exp_multiplier = 1.5
	rules.allow_balls = false
	return rules
