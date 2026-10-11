class_name CaveExit
extends RefCounted
## Sortie d'une grotte (donnée pure, [CaveLibrary]) : où la Corde Sortie ramène le joueur
## (dossier 15 §11 : devant l'entrée extérieure, tourné vers le sud).

## Grotte de cette sortie (clé de `caves.json`).
var cave: StringName = &""
## Carte d'arrivée (extérieure).
var map: StringName = &""
## Point d'apparition de [member map].
var spawn: StringName = &""
## Orientation à l'arrivée (cardinale).
var facing: Vector2i = Vector2i.DOWN
