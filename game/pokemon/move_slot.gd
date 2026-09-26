class_name MoveSlot
extends RefCounted
## Un emplacement de capacité d'un [Pokemon] : la capacité et ses PP restants.

var move_id: StringName = &""
var pp: int = 0
var max_pp: int = 0


## Emplacement plein ([member pp] = [param max_pp_value]).
func _init(id: StringName = &"", max_pp_value: int = 0) -> void:
	move_id = id
	max_pp = max_pp_value
	pp = max_pp_value


## Consomme un PP. Faux (rien ne change) s'il n'en reste plus.
func use() -> bool:
	if pp <= 0:
		return false
	pp -= 1
	return true


## Remet les PP au maximum.
func restore() -> void:
	pp = max_pp


func to_dict() -> Dictionary:
	return {"id": String(move_id), "pp": pp, "max_pp": max_pp}
