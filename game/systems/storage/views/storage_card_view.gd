class_name StorageCardView
extends RefCounted
## Une carte de l'écran Stockage (colonne ÉQUIPE ou grille STOCKAGE ; jalon-07.md §3.5, §6.4).
## Construite par [StorageViews]. Contrat figé au T14 : les champs ne changent ni de nom ni de
## sens ; on peut en ajouter.

## Liste de la carte et sa place dans cette liste (ce que l'écran renvoie dans ses signaux).
var place: StorageRules.Place = StorageRules.Place.PARTY
var index: int = 0
## Ce qu'affiche la carte, dans le langage de l'Équipe ([member TeamMemberView.party_index] =
## [member index], même pour le stockage) : nom, sexe, niveau, PV, « K.O. », favori.
var member: TeamMemberView
## Carte sélectionnée ([member StorageView.selection]).
var selected: bool = false
