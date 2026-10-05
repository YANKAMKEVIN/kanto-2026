class_name StorageActionView
extends RefCounted
## Un bouton d'action du Pokémon sélectionné dans l'écran Stockage (DÉPOSER, REPRENDRE, FAVORI,
## LIBÉRER ; dossier 09 §19). Construit par [StorageViews]. Contrat figé au T14.
##
## Une action n'est jamais grisée : un refus se montre **au toucher** (tremblement de la carte
## et raison, langage du 6B), décidé par [StorageRules], pas par l'écran.

## [constant StorageViews.ACTION_DEPOSIT], [constant StorageViews.ACTION_WITHDRAW],
## [constant StorageViews.ACTION_FAVORITE] ou [constant StorageViews.ACTION_RELEASE].
var id: StringName = &""
## Libellé validé (« DÉPOSER »).
var label: String = ""
## FAVORI : vrai si le Pokémon est favori (bouton enfoncé). Faux pour les autres actions.
var active: bool = false


func _init(action_id: StringName = &"", action_label: String = "", is_active: bool = false) -> void:
	id = action_id
	label = action_label
	active = is_active
