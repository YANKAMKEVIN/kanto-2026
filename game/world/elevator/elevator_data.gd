class_name ElevatorData
extends RefCounted
## Un ascenseur (jalon 20 T5, docs/tech/jalon-20.md §2.3), lu dans `data/world/elevators.json`
## par [ElevatorLibrary]. Classe pure, sans nœud.
##
## [member floors] : étages proposés au panneau, dans l'ordre affiché ; chacun est un
## dictionnaire { "id": StringName, "label": String, "map": StringName, "spawn": StringName }
## (« map » / « spawn » : où mène la sortie de la cabine quand cet étage est l'étage courant).

var id: StringName = &""
## Carte de la cabine.
var car: StringName = &""
## Objet exigé dans le Sac (&"" : aucun).
var key: StringName = &""
var floors: Array[Dictionary] = []


## Étage [param floor_id] ({} s'il n'est pas desservi).
func get_floor(floor_id: StringName) -> Dictionary:
	for entry: Dictionary in floors:
		if entry["id"] == floor_id:
			return entry
	return {}


func has_floor(floor_id: StringName) -> bool:
	return not get_floor(floor_id).is_empty()


## Étage dont la carte est [param map_id] ({} si cette carte n'est pas desservie).
func floor_for_map(map_id: StringName) -> Dictionary:
	for entry: Dictionary in floors:
		if entry["map"] == map_id:
			return entry
	return {}


## Premier étage de la liste (celui de la sortie par défaut de la cabine).
func default_floor() -> Dictionary:
	return floors[0] if not floors.is_empty() else {}


## Identifiants des étages, dans l'ordre du panneau.
func floor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in floors:
		ids.append(entry["id"])
	return ids


func needs_key() -> bool:
	return not key.is_empty()
