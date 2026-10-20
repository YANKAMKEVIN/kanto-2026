class_name ElevatorPanelView
extends RefCounted
## Ce que montre le panneau d'étages (jalon 20 T13, `docs/tech/jalon-20.md` §2.3.4) : titre,
## bouton de fermeture, une ligne par étage desservi (ordre des données), l'étage courant
## marqué. Donnée pure, construite par [ElevatorDirector] et lue par l'écran [ElevatorPanel]
## (T14) ; aucun nœud.

## Annexe A du plan, n° 158 et 159 (validés le 2026-10-16).
const TITLE: String = "Quel étage ?"
const CLOSE_LABEL: String = "FERMER"

var title: String = TITLE
var close_label: String = CLOSE_LABEL
## Ascenseur montré (identifiant de `data/world/elevators.json`).
var elevator_id: StringName = &""
## Une entrée par étage : { "id": StringName, "label": String, "current": bool }.
var floors: Array[Dictionary] = []


## Vue de [param elevator] avec [param current_id] pour étage courant (grisé à l'écran).
static func build(elevator: ElevatorData, current_id: StringName) -> ElevatorPanelView:
	var view := ElevatorPanelView.new()
	if elevator == null:
		return view
	view.elevator_id = elevator.id
	for entry: Dictionary in elevator.floors:
		view.floors.append({"id": entry["id"], "label": entry["label"],
			"current": entry["id"] == current_id})
	return view


## Identifiant de l'étage courant (&"" si aucun n'est marqué).
func current_floor() -> StringName:
	for entry: Dictionary in floors:
		if entry["current"]:
			return entry["id"]
	return &""


## Étages qu'on peut choisir (tous sauf le courant), dans l'ordre.
func choosable_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in floors:
		if not entry["current"]:
			ids.append(entry["id"])
	return ids
