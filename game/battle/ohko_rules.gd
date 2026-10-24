class_name OhkoRules
extends RefCounted
## K.O. en un coup (passe systèmes 2, `docs/tech/systemes-2.md` §2.11 ; Q-2 : règle moderne) :
## pur, statique.
##
## - échoue si le lanceur est d'un niveau inférieur à la cible ;
## - précision = précision de la capacité + (niveau du lanceur − niveau de la cible), au plus 100 ;
##   les niveaux de précision et d'esquive ne comptent pas ;
## - les immunités de type ordinaires et l'esquive d'une cible sous terre restent celles du moteur
##   ([Battle]).


## Vrai si le niveau du lanceur permet de toucher (pas inférieur à celui de la cible).
static func level_allows(user_level: int, target_level: int) -> bool:
	return user_level >= target_level


## Chance de toucher, en % (0 si le niveau ne le permet pas).
static func accuracy(move_accuracy: int, user_level: int, target_level: int) -> int:
	if not level_allows(user_level, target_level):
		return 0
	return mini(move_accuracy + user_level - target_level, 100)
