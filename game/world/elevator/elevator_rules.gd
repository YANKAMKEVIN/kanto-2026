class_name ElevatorRules
extends RefCounted
## Règles de l'ascenseur (jalon 20 T5, docs/tech/jalon-20.md §2.3.2, dossier 23 §9 et §13.4).
## Classe pure et statique, sans nœud : le directeur (T13) et le panneau (T14) s'en servent.
##
## Une seule mécanique pour le grand magasin (sans clé) et le repaire (Clé Ascenseur) : le panneau
## propose les étages des données ; choisir un étage change l'**étage courant**, et la sortie de
## la cabine mène à l'arrivée de cet étage. **La cabine n'est jamais une position sauvée** :
## [method save_target] rend l'arrivée de l'étage courant (dossier 23 §13.3, plan §2.3.5).

enum Status {
	OK, ## Trajet permis : l'étage courant devient l'étage choisi.
	NO_KEY, ## L'ascenseur exige un objet absent du Sac (« Il faut une clé. »).
	UNKNOWN_FLOOR, ## Étage non desservi par cet ascenseur.
	SAME_FLOOR, ## Étage déjà courant : rien ne bouge.
}


## Vrai si le panneau répond : aucune clé exigée, ou la clé est dans [param bag].
static func can_operate(elevator: ElevatorData, bag: Bag) -> bool:
	if elevator == null:
		return false
	return not elevator.needs_key() or (bag != null and bag.has(elevator.key))


## Choix de l'étage [param wanted_id] depuis l'étage courant [param current_id]. La clé passe
## avant tout : sans elle, le panneau ne répond pas, quel que soit l'étage.
static func choose(elevator: ElevatorData, current_id: StringName, wanted_id: StringName,
		bag: Bag) -> Status:
	if elevator == null:
		return Status.UNKNOWN_FLOOR
	if not can_operate(elevator, bag):
		return Status.NO_KEY
	if not elevator.has_floor(wanted_id):
		return Status.UNKNOWN_FLOOR
	if wanted_id == current_id:
		return Status.SAME_FLOOR
	return Status.OK


## Où mène la sortie de la cabine quand [param floor_id] est l'étage courant :
## { "map": StringName, "spawn": StringName } ({} si l'étage n'est pas desservi).
static func exit_target(elevator: ElevatorData, floor_id: StringName) -> Dictionary:
	if elevator == null:
		return {}
	var entry := elevator.get_floor(floor_id)
	if entry.is_empty():
		return {}
	return {"map": entry["map"], "spawn": entry["spawn"]}


## Étage courant à l'entrée dans la cabine : celui dont la carte est [param arrived_from] (la
## carte quittée), sinon le premier étage (chargement d'une partie, carte inconnue).
static func entry_floor(elevator: ElevatorData, arrived_from: StringName) -> StringName:
	if elevator == null:
		return &""
	var entry := elevator.floor_for_map(arrived_from)
	if entry.is_empty():
		entry = elevator.default_floor()
	return StringName(entry.get("id", &""))


## Position à sauver quand le joueur est dans la cabine à l'étage [param floor_id] : l'arrivée de
## cet étage ({ "map", "spawn" }), jamais la cabine. Étage inconnu : le premier étage.
static func save_target(elevator: ElevatorData, floor_id: StringName) -> Dictionary:
	if elevator == null:
		return {}
	var target := exit_target(elevator, floor_id)
	if target.is_empty():
		target = exit_target(elevator, entry_floor(elevator, &""))
	return target
