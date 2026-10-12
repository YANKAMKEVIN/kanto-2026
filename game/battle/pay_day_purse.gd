class_name PayDayPurse
extends RefCounted
## Pièces du Jackpot éparpillées pendant un combat (jalon 15, docs/tech/jalon-15.md §2.7.3 ;
## dossier 18 §10.2, effet de Rouge/Bleu). Règle pure, sans dépendance au moteur : le moteur
## (T17, après le J12) en crée une par combat, l'alimente à chaque Jackpot réussi et la lit à
## la conclusion.
##
## - Chaque utilisation réussie **du camp du joueur** ajoute « per_level × niveau du lanceur »
##   (donnée de l'effet, 2 en Rouge/Bleu) ; le Jackpot de l'adversaire ne rapporte rien.
## - Les pièces sont ramassées seulement si le combat est gagné ou se termine par une capture
##   [D] ; jamais à la fuite ni à la défaite. Contre un Pokémon sauvage aussi.
## - Le plafond de l'argent du joueur est celui de [method GameState.add_money] ; la bourse
##   elle-même ne déborde pas d'un entier.

## Pièces par niveau du lanceur, en Rouge/Bleu (valeur de la donnée « per_level »).
const RB_PER_LEVEL: int = 2

var _total: int = 0


## Ajoute les pièces d'un Jackpot réussi lancé par un Pokémon de niveau [param user_level].
## [param player_side] faux (Jackpot adverse), niveau ou taux ≤ 0 : rien. Renvoie les pièces
## éparpillées par ce Jackpot (0 si rien n'est ajouté), pour le message de combat.
func add(user_level: int, per_level: int = RB_PER_LEVEL, player_side: bool = true) -> int:
	if not player_side or user_level <= 0 or per_level <= 0:
		return 0
	var amount := user_level * per_level
	_total += amount
	return amount


## Pièces éparpillées depuis le début du combat.
func total() -> int:
	return _total


## Pièces ramassées pour l'issue [param outcome] ([enum Battle.Outcome]) : le total après une
## victoire ou une capture, 0 sinon.
func collected(outcome: int) -> int:
	if outcome == Battle.Outcome.WIN or outcome == Battle.Outcome.CAUGHT:
		return _total
	return 0
