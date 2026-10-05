class_name BattleConclusion
extends RefCounted
## Conséquences d'un combat terminé, décidées **hors du moteur** (jalon 4 §3.4,
## jalon-04.md §14.5). Donnée pure, construite par [method resolve].
##
## Premier combat du rival (décisions de Kevin n° 6 et 15) : le Prof. Chen soigne les deux
## Pokémon quelle que soit l'issue, ni argent ni XP, pas de retour au point de soin.
## L'XP n'est pas ici : elle se gagne pendant le combat (jalon 5, [member TrainerData.gives_exp]).
## Argent (jalon 7, dossier 09 §10) : seulement à la victoire, [method TrainerData.prize_for] ;
## jamais de perte d'argent à la défaite (le joueur ne paie rien).

var outcome: int = Battle.Outcome.NONE
## Soigner l'équipe du joueur (PV et PP) à la sortie du combat.
var heal_party: bool = false
## Argent gagné (0 : défaite, ou dresseur qui n'en donne pas). Jamais négatif.
var prize_money: int = 0
## Défaite qui renvoie au point de soin (jalon 5 : Maman, puis Centre Pokémon).
var blackout: bool = false


## Conséquences de l'issue [param outcome] ([enum Battle.Outcome]) d'un combat contre
## [param trainer] (null = Pokémon sauvage). [param last_foe_level] : niveau du dernier Pokémon
## de l'équipe adverse (gain par niveau, [member TrainerData.prize_per_level]).
static func resolve(trainer: TrainerData, outcome: int,
		last_foe_level: int = 0) -> BattleConclusion:
	var result := BattleConclusion.new()
	result.outcome = outcome
	var lost := outcome == Battle.Outcome.LOSS
	if trainer == null:
		result.blackout = lost
		return result
	result.heal_party = trainer.heal_after
	result.prize_money = trainer.prize_for(last_foe_level) \
		if outcome == Battle.Outcome.WIN else 0
	result.blackout = lost and not trainer.can_lose
	return result
