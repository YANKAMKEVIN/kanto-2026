class_name TriggerTable
extends RefCounted
## Déclencheurs de scène d'une carte, indexés par case (docs/tech/jalon-03b.md §2.2).
##
## Classe pure, calquée sur [WarpTable] : `GameMap` la remplit au chargement à partir de ses
## `EventTriggerPoint`, le directeur de scènes l'interroge quand le joueur termine un pas.
## Une case porte au plus un déclencheur qui accepte une direction donnée : sinon le
## déclenchement serait ambigu, [method add] refuse.

var _by_cell: Dictionary[Vector2i, Array] = {}
var _count: int = 0


## Ajoute un déclencheur. Refuse (false) un déclencheur invalide ou en conflit avec un autre
## de la même case (l'un accepte toute direction, ou tous deux la même).
func add(trigger: EventTrigger) -> bool:
	if trigger == null or not trigger.is_valid():
		return false
	var list: Array = _by_cell.get(trigger.cell, [])
	for other: EventTrigger in list:
		if trigger.direction == Vector2i.ZERO or other.direction == Vector2i.ZERO \
				or trigger.direction == other.direction:
			return false
	list.append(trigger)
	_by_cell[trigger.cell] = list
	_count += 1
	return true


## Déclencheur d'un pas terminé sur [param cell] vers [param direction], ou null.
func find_on_step(cell: Vector2i, direction: Vector2i) -> EventTrigger:
	for trigger: EventTrigger in _by_cell.get(cell, []):
		if trigger.matches_step(cell, direction):
			return trigger
	return null


## Déclencheurs de la case (vide si aucun).
func get_at(cell: Vector2i) -> Array[EventTrigger]:
	var result: Array[EventTrigger] = []
	result.assign(_by_cell.get(cell, []))
	return result


## Tous les déclencheurs, dans l'ordre des cases puis d'ajout.
func get_all() -> Array[EventTrigger]:
	var result: Array[EventTrigger] = []
	for list: Array in _by_cell.values():
		result.append_array(list)
	return result


func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0
