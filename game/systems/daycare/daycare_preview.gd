class_name DaycarePreview
extends RefCounted
## Aperçu du retrait de la Pension ([method DaycareRules.preview]), calculé **sans rien changer** :
## ce que le gardien annonce avant la confirmation (F-4 : jetons `{pokemon}`, `{levels}`,
## `{price}`). Donnée pure ; il donne exactement le résultat d'un [method DaycareRules.withdraw]
## fait juste après.

## Ce que le retrait donnerait : OK, ou la raison du refus (EMPTY, PARTY_FULL, NO_MONEY).
var status: DaycareRules.Status = DaycareRules.Status.EMPTY
## Le Pokémon gardé (null si la Pension est vide).
var pokemon: Pokemon = null
## Niveaux qui seraient gagnés.
var levels_gained: int = 0
## Niveau qui serait atteint.
var level_after: int = 0
## Prix demandé (100 ₽ + 100 ₽ par niveau gagné, F-2).
var price: int = 0
## Montant qui serait réellement débité (inférieur au prix si l'argent manque, F-2).
var paid: int = 0


func is_ok() -> bool:
	return status == DaycareRules.Status.OK


## Vrai si l'argent du joueur ne couvre pas le prix (texte T-11).
func is_short() -> bool:
	return paid < price
