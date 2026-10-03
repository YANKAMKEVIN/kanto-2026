class_name PartyTargetView
extends RefCounted
## Un Pokémon de l'équipe dans le choix du Pokémon (PartyPicker, dossier 08 §3) : le membre
## (nom, Nv., PV, statut), et soit « utilisable », soit **la raison** (« PV déjà au maximum »,
## « Ce Pokémon est K.O. »). Jamais un bouton désactivé sans explication. Contrat figé au T10.

var member: TeamMemberView
var usable: bool = false
## Raison affichée si [member usable] est faux ; vide sinon.
var reason: String = ""


func _init(target_member: TeamMemberView = null, can_use: bool = false,
		why: String = "") -> void:
	member = target_member
	usable = can_use
	reason = why
