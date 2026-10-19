class_name CaveExit
extends RefCounted
## Sortie d'une grotte (donnée pure, [CaveLibrary]) : où la Corde Sortie ramène le joueur
## (dossier 15 §11 : devant l'entrée extérieure, tourné vers le sud).
## Grotte à plusieurs bouches (jalon 17, Cave Taupiqueur, jalon-17.md §2.3) : chaque sortie sert
## une plage de rangées ([member first_row]..[member last_row]) ; la Corde ramène à la bouche de
## la moitié où se tient le joueur.

## Grotte de cette sortie (clé de `caves.json`).
var cave: StringName = &""
## Carte d'arrivée (extérieure).
var map: StringName = &""
## Point d'apparition de [member map].
var spawn: StringName = &""
## Orientation à l'arrivée (cardinale).
var facing: Vector2i = Vector2i.DOWN
## Première et dernière rangée (comprises) servies par cette sortie ; -1 = toute la grotte
## (sortie unique, clé « escape »).
var first_row: int = -1
var last_row: int = -1


## Vrai si cette sortie sert la rangée [param row].
func covers_row(row: int) -> bool:
	return first_row < 0 or (row >= first_row and row <= last_row)
