class_name TrainerData
extends RefCounted
## Un dresseur et ses combats, lu dans `data/trainers/*.json` par [TrainerLibrary]
## (jalon 4 §2.2 et §3.2). Donnée pure.
##
## Les conséquences du combat ([member can_lose], [member heal_after], [member gives_exp],
## [member prize_money]) sont décidées hors du moteur par celui qui joue le combat.

var id: StringName = &""
## Nom dans les messages de combat (« Le Rival envoie Carapuce ! »).
var name: String = ""
## Nom de l'IA ([constant BattleAI.KINDS]).
var ai: StringName = BattleAI.RANDOM
## Le joueur peut perdre sans conséquence (pas de retour au Centre).
var can_lose: bool = false
## Les deux équipes sont soignées à la fin, quelle que soit l'issue.
var heal_after: bool = false
## Le combat rapporte de l'XP (formule d'XP gagnée : jalon 5).
var gives_exp: bool = true
## Argent fixe gagné en cas de victoire (exclusif de [member prize_per_level]).
var prize_money: int = 0
## Argent par niveau du dernier Pokémon de l'équipe (Rouge/Bleu : base × niveau, dossier 09
## §20 Q1) ; 0 = pas de gain par niveau. Exclusif de [member prize_money].
var prize_per_level: int = 0
## Le SAC est utilisable pendant le combat (décision de Kevin du 2026-10-03 : contre tous les
## Dresseurs ; seul le combat du labo le garde muet).
var allow_bag: bool = true
## Message générique de fin (« Tu as battu… », « … a gagné cette fois... »). Faux pour le
## premier combat du rival : ses répliques d'après-combat en tiennent lieu (décision de
## Kevin n° 15, jalon 4 §8).
var end_message: bool = true
## Message générique de début (« Le Rival veut se battre ! »). Faux pour le premier combat
## du rival : la réplique « On ne va quand même pas partir… » qui lance le combat en tient
## lieu (décision de Kevin n° 17, Q-K, jalon-04.md §8). Vrai par défaut pour les autres
## Dresseurs (même mécanique que [member end_message]).
var start_message: bool = true
## L'IA peut changer de Pokémon une fois par combat (jalon 13, dossier 16 §14 : Ondine et le
## rival n° 3) ; donnée « switch », faux par défaut.
var can_switch: bool = false
## Équipe fixe (vide si l'équipe dépend du starter du joueur).
var team: Array[TrainerSlot] = []
## Équipe selon le starter du joueur (combats du rival, comme Rouge/Bleu).
var team_by_starter: Dictionary[StringName, Array] = {}
## Carte de présentation d'un Champion (jalon 10, jalon-10.md §2.7 : bloc « card ») : nom
## (« PIERRE ») et titre (« Champion d'Arène d'Argenta ») ; vides = pas de carte.
var card_name: String = ""
var card_title: String = ""
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Équipe à affronter quand le starter du joueur est [param player_starter] (vide si le
## dresseur n'a pas d'équipe pour ce starter).
func team_for(player_starter: StringName) -> Array[TrainerSlot]:
	var result: Array[TrainerSlot] = []
	if not team.is_empty():
		result.assign(team)
	else:
		result.assign(team_by_starter.get(player_starter, []))
	return result


## Argent gagné à la victoire : [member prize_money] s'il est fixé, sinon
## [member prize_per_level] × [param last_level] (niveau du dernier Pokémon de son équipe).
func prize_for(last_level: int) -> int:
	if prize_money > 0:
		return prize_money
	return prize_per_level * maxi(last_level, 0)


## Vrai si le Dresseur a une carte de présentation (étape de scène « champion_card »).
func has_card() -> bool:
	return not card_name.is_empty() and not card_title.is_empty()


## IA du dresseur.
func make_ai() -> BattleAI:
	return BattleAI.new(ai, can_switch)
