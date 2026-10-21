class_name ForcedSlide
extends RefCounted
## Trajet d'une **glissade forcée**, calculé d'avance (passe systèmes 2, T15 ;
## `docs/tech/systemes-2.md` §2.6) : forme commune des dalles tournantes ([SpinSlide], J20) et
## des courants ([CurrentField.Ride]), jouée par [ForcedSlideDirector]. Classe pure, sans nœud.
##
## [member cells] : cases traversées dans l'ordre, **sans** la case de départ ; [member facings] :
## direction de chaque pas (même longueur) ; [member end] : dernière case atteinte. Le directeur
## joue les pas un par un : il lit [method next_direction], fait le pas, puis appelle
## [method step_done].
##
## **État « en glisse »** ([method is_sliding]) : vrai dès que le trajet est calculé et tant que
## tous ses pas n'ont pas été joués. Pendant ce temps, aucune sauvegarde ([method can_save]
## faux) : la position enregistrée est toujours une case stable.
##
## Chaque sous-classe porte son propre `status` (ses erreurs de données) : [method is_ok] et
## [method status_name] le lisent.

var start: Vector2i = Vector2i.ZERO
var cells: Array[Vector2i] = []
var facings: Array[Vector2i] = []
var end: Vector2i = Vector2i.ZERO
## Nombre de pas déjà joués par le directeur.
var steps_done: int = 0
## Le trajet finit sur un passage (warp) : le directeur le fait suivre (courants).
var warp: bool = false
## Le trajet finit sur une case de terre : le joueur y repasse à pied (courants).
var dismounts: bool = false


## Vrai si le trajet est valide (à redéfinir : lit le `status` de la sous-classe).
func is_ok() -> bool:
	return false


## Nom du statut, pour les messages d'erreur (à redéfinir).
func status_name() -> String:
	return ""


## Nombre de pas du trajet.
func size() -> int:
	return cells.size()


## Vrai tant qu'un trajet valide n'a pas fini de se jouer.
func is_sliding() -> bool:
	return is_ok() and steps_done < cells.size()


## Faux pendant la glissade : ni sauvegarde automatique, ni sauvegarde du menu.
func can_save() -> bool:
	return not is_sliding()


## Direction du prochain pas (ZERO si la glissade est finie ou invalide).
func next_direction() -> Vector2i:
	if not is_sliding():
		return Vector2i.ZERO
	return facings[steps_done]


## Case visée par le prochain pas ([member end] si la glissade est finie).
func next_cell() -> Vector2i:
	if not is_sliding():
		return end
	return cells[steps_done]


## Le directeur a joué le prochain pas.
func step_done() -> void:
	if is_sliding():
		steps_done += 1


## Arrête la glissade sur place (pas refusé) : plus aucun pas à jouer ; [member end] devient la
## dernière case réellement atteinte, et la fin prévue (passage, descente) est oubliée.
func abort() -> void:
	if not is_sliding():
		return
	end = start if steps_done == 0 else cells[steps_done - 1]
	cells.resize(steps_done)
	facings.resize(steps_done)
	warp = false
	dismounts = false
