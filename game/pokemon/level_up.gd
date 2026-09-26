class_name LevelUp
extends RefCounted
## Un niveau gagné, renvoyé par [method Pokemon.gain_exp] : ce qui s'est passé, pour que
## la présentation le raconte et fasse choisir le joueur. Donnée pure.

## Niveau atteint.
var level: int = 0
## Capacités que l'espèce apprend à ce niveau et que le Pokémon ne connaissait pas.
## Rien n'est appris automatiquement : la présentation appelle [method Pokemon.learn_move]
## (et [method Pokemon.replace_move] si le joueur choisit d'en oublier une).
var moves: Array[StringName] = []
## Gain de chaque statistique ([constant SpeciesData.STATS]) à ce niveau.
var stat_gains: Dictionary[StringName, int] = {}
