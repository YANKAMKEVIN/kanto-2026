class_name EventTrigger
extends RefCounted
## Déclencheur de scène posé sur une case (docs/tech/jalon-03b.md §2.2), calqué sur un
## [Warp] en [constant Warp.STEP_ON] : un pas **terminé** sur [member cell], fait vers
## [member direction] (ZERO = n'importe laquelle), lance la scène [member cutscene_id].
##
## Donnée pure : `GameMap` en construit un par case couverte d'un `EventTriggerPoint` et les
## range dans une [TriggerTable]. Le déclencheur ne porte aucune condition : c'est la scène
## (ses variantes, `if` / `unless`) qui décide de ce qui se passe, ou de ne rien faire.
## Apparaître sur la case, ou y arriver par un pas scripté, ne déclenche rien.

var cell: Vector2i
var direction: Vector2i
var cutscene_id: StringName


func _init(at_cell: Vector2i = Vector2i.ZERO, step_direction: Vector2i = Vector2i.ZERO,
		cutscene: StringName = &"") -> void:
	cell = at_cell
	direction = step_direction
	cutscene_id = cutscene


## Scène renseignée, direction nulle ou cardinale.
func is_valid() -> bool:
	if cutscene_id.is_empty():
		return false
	return direction == Vector2i.ZERO or Grid.is_cardinal(direction)


## Vrai si un pas terminé sur [param at_cell], fait vers [param step_direction], déclenche.
func matches_step(at_cell: Vector2i, step_direction: Vector2i) -> bool:
	if at_cell != cell:
		return false
	return direction == Vector2i.ZERO or direction == step_direction
