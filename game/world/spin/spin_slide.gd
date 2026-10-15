class_name SpinSlide
extends RefCounted
## Trajet d'une glisse sur les dalles tournantes (jalon 20 T4, docs/tech/jalon-20.md §2.4.3),
## calculé d'avance par [method SpinTileRules.slide]. Classe pure, sans nœud.
##
## [member cells] : cases traversées dans l'ordre, **sans** la dalle de départ ; [member facings] :
## direction de chaque pas (même longueur) ; [member end] : dernière case atteinte (la case
## d'arrêt si [member status] vaut OK). Le directeur (T19) joue les pas un par un : il lit
## [method next_direction], fait le pas, puis appelle [method step_done].
##
## **État « en glisse »** ([method is_sliding]) : vrai dès que le trajet est calculé et tant que
## tous ses pas n'ont pas été joués. Pendant ce temps, aucune sauvegarde ([method can_save]
## faux) : la position enregistrée est toujours une case stable (dossier 23 §13.3).

enum Status {
	OK, ## La glisse finit sur une case d'arrêt.
	NOT_AN_ARROW, ## La case de départ n'est pas une dalle : aucun trajet.
	BLOCKED, ## La case suivante n'est pas praticable (erreur de données).
	LOOP, ## Le trajet repasse par la même case dans la même direction (erreur de données).
	TOO_LONG, ## Plus de pas que la limite permise (erreur de données).
}

var start: Vector2i = Vector2i.ZERO
var cells: Array[Vector2i] = []
var facings: Array[Vector2i] = []
var end: Vector2i = Vector2i.ZERO
var status: Status = Status.NOT_AN_ARROW
## Nombre de pas déjà joués par le directeur.
var steps_done: int = 0


func is_ok() -> bool:
	return status == Status.OK


## Nombre de pas du trajet.
func size() -> int:
	return cells.size()


## Vrai tant qu'une glisse valide n'a pas fini de se jouer.
func is_sliding() -> bool:
	return status == Status.OK and steps_done < cells.size()


## Faux pendant la glisse : ni sauvegarde automatique, ni sauvegarde du menu.
func can_save() -> bool:
	return not is_sliding()


## Direction du prochain pas (ZERO si la glisse est finie ou invalide).
func next_direction() -> Vector2i:
	if not is_sliding():
		return Vector2i.ZERO
	return facings[steps_done]


## Case visée par le prochain pas ([member end] si la glisse est finie).
func next_cell() -> Vector2i:
	if not is_sliding():
		return end
	return cells[steps_done]


## Le directeur a joué le prochain pas.
func step_done() -> void:
	if is_sliding():
		steps_done += 1


## Arrête la glisse sur place (pas refusé) : plus aucun pas à jouer ; [member end] devient la
## dernière case réellement atteinte.
func abort() -> void:
	if not is_sliding():
		return
	end = start if steps_done == 0 else cells[steps_done - 1]
	cells.resize(steps_done)
	facings.resize(steps_done)


## Trajet en texte, au format des grilles (« O4,S2,E1 », N S E O) : sert aux messages.
func path_text() -> String:
	var parts: PackedStringArray = []
	var count := 0
	for i: int in facings.size():
		count += 1
		if i == facings.size() - 1 or facings[i + 1] != facings[i]:
			parts.append("%s%d" % [SpinTileRules.compass_letter(facings[i]), count])
			count = 0
	return ",".join(parts)
