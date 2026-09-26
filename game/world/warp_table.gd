class_name WarpTable
extends RefCounted
## Warps d'une carte, indexés par case. Classe pure : [GameMap] la remplit au chargement,
## le routeur de scènes l'interroge quand le joueur termine un pas ou pousse.
##
## Une case porte au plus un warp [constant Warp.STEP_ON] qui accepte une direction
## donnée, et au plus un warp [constant Warp.PUSH] par direction : sinon le déclenchement
## serait ambigu, [method add] refuse.

var _by_cell: Dictionary[Vector2i, Array] = {}
var _count: int = 0


## Ajoute un warp. Refuse (false) un warp invalide ou en conflit avec un warp existant.
func add(warp: Warp) -> bool:
	if warp == null or not warp.is_valid():
		return false
	var list: Array = _by_cell.get(warp.cell, [])
	for other: Warp in list:
		if _conflicts(warp, other):
			return false
	list.append(warp)
	_by_cell[warp.cell] = list
	_count += 1
	return true


## Warp déclenché par un pas terminé sur [param cell] vers [param direction], ou null.
func find_on_step(cell: Vector2i, direction: Vector2i) -> Warp:
	for warp: Warp in _by_cell.get(cell, []):
		if warp.matches_step(cell, direction):
			return warp
	return null


## Warp déclenché en poussant vers [param direction] depuis [param cell], ou null.
func find_on_push(cell: Vector2i, direction: Vector2i) -> Warp:
	for warp: Warp in _by_cell.get(cell, []):
		if warp.matches_push(cell, direction):
			return warp
	return null


## Warps de la case (vide si aucun).
func get_at(cell: Vector2i) -> Array[Warp]:
	var result: Array[Warp] = []
	for warp: Warp in _by_cell.get(cell, []):
		result.append(warp)
	return result


## Tous les warps, dans l'ordre des cases puis d'ajout.
func get_all() -> Array[Warp]:
	var result: Array[Warp] = []
	for cell: Vector2i in _by_cell:
		for warp: Warp in _by_cell[cell]:
			result.append(warp)
	return result


func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0


static func _conflicts(a: Warp, b: Warp) -> bool:
	if a.trigger != b.trigger:
		return false
	if a.trigger == Warp.Trigger.PUSH:
		return a.direction == b.direction
	# Deux STEP_ON se recouvrent si l'un accepte toute direction ou s'ils exigent la même.
	return a.direction == Vector2i.ZERO or b.direction == Vector2i.ZERO \
		or a.direction == b.direction
