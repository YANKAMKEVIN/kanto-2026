class_name Warp
extends RefCounted
## Passage d'une carte à une autre (porte, tapis de sortie, escalier), sans scène.
##
## Donnée pure : [GameMap] en construit un par nœud `WarpPoint` de son dossier `Warps`,
## et les range dans une [WarpTable]. Deux déclenchements, comme dans Rouge/Bleu :
## - [constant STEP_ON] : le joueur **termine un pas** sur la case (porte extérieure,
##   escalier). [member direction] = direction de pas exigée (ZERO = n'importe laquelle).
##   Apparaître sur la case ne déclenche rien : on peut arriver sur un escalier.
## - [constant PUSH] : le joueur **se tient** sur la case et **pousse** vers
##   [member direction] sans pouvoir avancer (tapis de sortie : pousser vers le bas).
## À l'arrivée, [member target_spawn] désigne un Marker2D de la carte cible ;
## [member facing] fixe l'orientation (ZERO = garder celle du joueur).

enum Trigger { STEP_ON, PUSH }

var cell: Vector2i
var trigger: Trigger
var direction: Vector2i
var target_map: StringName
var target_spawn: StringName
var facing: Vector2i


func _init(
	warp_cell: Vector2i,
	warp_trigger: Trigger,
	warp_direction: Vector2i,
	to_map: StringName,
	to_spawn: StringName,
	arrival_facing: Vector2i = Vector2i.ZERO
) -> void:
	cell = warp_cell
	trigger = warp_trigger
	direction = warp_direction
	target_map = to_map
	target_spawn = to_spawn
	facing = arrival_facing


## Cohérence de la donnée : cible renseignée, directions nulles ou cardinales,
## direction cardinale obligatoire pour [constant PUSH].
func is_valid() -> bool:
	if target_map.is_empty() or target_spawn.is_empty():
		return false
	if not _is_zero_or_cardinal(direction) or not _is_zero_or_cardinal(facing):
		return false
	return trigger != Trigger.PUSH or Grid.is_cardinal(direction)


## Vrai si un pas terminé sur [param at_cell], fait vers [param step_direction], déclenche.
func matches_step(at_cell: Vector2i, step_direction: Vector2i) -> bool:
	if trigger != Trigger.STEP_ON or at_cell != cell:
		return false
	return direction == Vector2i.ZERO or direction == step_direction


## Vrai si pousser vers [param push_direction] depuis [param at_cell] déclenche.
func matches_push(at_cell: Vector2i, push_direction: Vector2i) -> bool:
	return trigger == Trigger.PUSH and at_cell == cell and direction == push_direction


## Orientation du joueur à l'arrivée : [member facing], ou [param current] si ZERO.
func get_arrival_facing(current: Vector2i) -> Vector2i:
	return current if facing == Vector2i.ZERO else facing


static func _is_zero_or_cardinal(value: Vector2i) -> bool:
	return value == Vector2i.ZERO or Grid.is_cardinal(value)
