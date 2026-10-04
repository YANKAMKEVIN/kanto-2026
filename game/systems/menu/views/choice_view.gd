class_name ChoiceView
extends RefCounted
## Une question à deux grandes cartes (bible UI/UX §4, Q-18 ; jalon-06.md §6.12) : l'action et
## son renoncement, côte à côte, jamais une boîte « Oui / Non ». Montrée par le composant
## `ChoiceCards` (T28) ; au J6, la confirmation d'oubli d'une capacité quand le réglage
## « Confirmer certaines actions » est activé (T29) ; au J7A, SOIGNER / PAS MAINTENANT,
## libérer, vendre un favori. Contrat figé au T27.
##
## Un texte vide = élément absent (sauf les deux libellés, toujours présents).

## Question (« Oublier Charge ? »).
var title: String = ""
## Précision sous la question ; "" = absente.
var detail: String = ""
## Carte de l'action (« OUBLIER ») et sa précision.
var confirm_label: String = ""
var confirm_detail: String = ""
## Carte du renoncement (« GARDER ») et sa précision.
var cancel_label: String = ""
var cancel_detail: String = ""


func _init(question: String = "", confirm: String = "", cancel: String = "") -> void:
	title = question
	confirm_label = confirm
	cancel_label = cancel
