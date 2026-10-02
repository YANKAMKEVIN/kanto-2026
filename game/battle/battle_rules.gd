class_name BattleRules
extends RefCounted
## Les règles d'un combat : sauvage ou dresseur, fuite, XP, Balls (jalon 5 §2.2). Donnée pure.
##
## Le moteur ([Battle]) reçoit ces règles (null = comportement du 4B, combat du rival) : elles
## décident ce qui est permis (la fuite, les Balls) et ce qui suit la victoire (l'XP, son
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
## Objets connus (5D) : le moteur y lit le [member ItemData.catch_bonus] de la Ball lancée.
## Null = aucune Ball n'est utilisable, même si [member allow_balls]. Le Sac n'est pas ici :
## le moteur ne compte ni ne retire aucun objet (le directeur s'en charge).
var items: ItemLibrary = null


## Règles d'un combat sauvage : fuite permise, XP ×1, Balls permises (bonus lus dans
## [param item_library]).
static func for_wild(item_library: ItemLibrary = null) -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = true
	rules.can_flee = true
	rules.gives_exp = true
	rules.exp_multiplier = 1.0
	rules.allow_balls = true
	rules.items = item_library
	return rules


## Règles d'un combat de dresseur : pas de fuite, XP ×1,5, pas de Balls (Q23). L'XP suit
## [member TrainerData.gives_exp] de [param trainer] (faux pour le premier combat du rival,
## `rival_lab` : ni XP ni argent, décisions n° 6 et 15) ; sans dresseur, elle est donnée.
static func for_trainer(trainer: TrainerData = null) -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = false
	rules.can_flee = false
	rules.gives_exp = trainer.gives_exp if trainer != null else true
	rules.exp_multiplier = 1.5
	rules.allow_balls = false
	return rules
