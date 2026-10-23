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
## Les soins sur un Pokémon de l'équipe sont permis (jalon 6, Q-10 : sauvage et dresseur). Il
## faut aussi [member items] pour lire le soin. Le SAC reste muet contre le rival du labo : c'est
## la grille d'actions qui le tait (BattleViews.trainer_actions, TrainerData.allow_bag).
var allow_heal_items: bool = false
## Objets connus (5D) : le moteur y lit le [member ItemData.catch_bonus] de la Ball lancée.
## Null = aucune Ball n'est utilisable, même si [member allow_balls]. Le Sac n'est pas ici :
## le moteur ne compte ni ne retire aucun objet (le directeur s'en charge).
var items: ItemLibrary = null
## Combat SPECTRE (jalon 19, dossier 22 §6, `jalon-19.md` §2.3) : le sauvage est masqué
## ([GhostDisguise]), il ne fait que parler, les capacités du joueur sont remplacées par la peur
## et les Balls sont refusées. Faux : aucune règle du mode spectre ne joue.
var ghost: bool = false
## La fuite réussit toujours, sans tirage ([FleeCalc] n'est pas consulté) ; combat SPECTRE.
var flee_always: bool = false
## Jalon 21 (`jalon-21.md` §2.6) : le sauvage ne peut pas être capturé ; une Ball choisie est
## refusée par le directeur avant d'être retirée du Sac ([method Battle.refuses_balls]). Le
## reste est un combat sauvage ordinaire (fuite par [FleeCalc], XP). Faux par défaut.
var uncatchable: bool = false
## J23 : rencontre Safari ([SafariBattle] au lieu de [Battle] ; `jalon-23.md` §2.3) : aucun
## Pokémon du joueur en scène, ni Sac, ni changement, ni XP, ni argent.
var safari: bool = false


## Règles d'un combat sauvage : fuite permise, XP ×1, Balls et soins permis (bonus et soins
## lus dans [param item_library]).
static func for_wild(item_library: ItemLibrary = null) -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = true
	rules.can_flee = true
	rules.gives_exp = true
	rules.exp_multiplier = 1.0
	rules.allow_balls = true
	rules.allow_heal_items = true
	rules.items = item_library
	return rules


## Règles d'un combat SPECTRE (jalon 19, dossier 22 §6.2) : sauvage, fuite toujours réussie,
## aucune XP ; le Sac s'ouvre (soins permis, une Ball choisie est refusée par le directeur avant
## d'être retirée du Sac : [method Battle.refuses_balls]).
static func for_ghost(item_library: ItemLibrary = null) -> BattleRules:
	var rules := for_wild(item_library)
	rules.ghost = true
	rules.flee_always = true
	rules.gives_exp = false
	return rules


## Règles d'un combat de dresseur : pas de fuite, XP ×1,5, pas de Balls (Q23). L'XP suit
## [member TrainerData.gives_exp] de [param trainer] (faux pour le premier combat du rival,
## `rival_lab` : ni XP ni argent, décisions n° 6 et 15) ; sans dresseur, elle est donnée.
## Soins permis (Q-10), lus dans [param item_library] (null : aucun soin possible).
static func for_trainer(trainer: TrainerData = null,
		item_library: ItemLibrary = null) -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = false
	rules.can_flee = false
	rules.gives_exp = trainer.gives_exp if trainer != null else true
	rules.exp_multiplier = 1.5
	rules.allow_balls = false
	rules.allow_heal_items = true
	rules.items = item_library
	return rules


## J23 : règles d'une rencontre Safari (`jalon-23.md` §2.3) : sauvage, FUIR toujours réussi,
## aucune XP, ni Sac (ni Balls du Sac, ni soins), ni changement de Pokémon.
static func for_safari() -> BattleRules:
	var rules := BattleRules.new()
	rules.wild = true
	rules.safari = true
	rules.can_flee = true
	rules.flee_always = true
	rules.gives_exp = false
	rules.exp_multiplier = 0.0
	rules.allow_balls = false
	rules.allow_heal_items = false
	rules.items = null
	return rules
