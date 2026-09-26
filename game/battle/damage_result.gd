class_name DamageResult
extends RefCounted
## Résultat de [method DamageCalc.compute]. Donnée pure.

## Faux : la capacité a raté (précision).
var hit: bool = false
## Dégâts à infliger (0 si ratée ou sans effet).
var amount: int = 0
var critical: bool = false
## Produit des multiplicateurs de type (0 = sans effet, 2 = super efficace…).
var effectiveness: float = 1.0
