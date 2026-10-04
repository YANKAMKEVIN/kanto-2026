class_name BadgeSlotView
extends RefCounted
## Un des 8 emplacements de badges de l'écran Dresseur (dossier 08 §6 ; jalon-06.md §3.7,
## Q-13). Contrat figé au T23.
##
## Un badge **non obtenu est muet** : ni nom, ni ville, ni champion, ni image, ni « ??? »,
## ni toucher ; seul l'emplacement existe. Au J6, aucun badge n'est obtenu (J10) : les huit
## emplacements sont muets. Les champs d'un badge obtenu sont prêts pour plus tard.

## Place (0 à 7), dans l'ordre des arènes.
var index: int = 0
## Vrai si le badge est obtenu (toujours faux au J6).
var obtained: bool = false
## Identifiant du badge (image, plus tard) ; &"" si non obtenu.
var badge_id: StringName = &""
## « Badge Roche » ; "" si non obtenu.
var name: String = ""
## Détail au toucher : « Argenta — Pierre » ; "" si non obtenu.
var detail: String = ""


func _init(slot: int = 0) -> void:
	index = slot
