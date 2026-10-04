class_name PartyTargetView
extends RefCounted
## Un Pokémon de l'équipe dans le choix du Pokémon (PartyPicker, dossier 08 §3) : le membre
## (nom, Nv., PV, statut), et soit « utilisable », soit **la raison** (« PV déjà au maximum »,
## « Ce Pokémon est K.O. »). Jamais un bouton désactivé sans explication. Contrat figé au T10.

var member: TeamMemberView
var usable: bool = false
## Raison affichée si [member usable] est faux ; vide sinon.
var reason: String = ""
## Phrase de refus complète (« Roucool a déjà tous ses PV. »), vide si utilisable ou non fournie ;
## champ ajouté au 6B (rétrocompatible : à défaut, [member reason] sert).
var refusal: String = ""


func _init(target_member: TeamMemberView = null, can_use: bool = false,
		why: String = "", refusal_text: String = "") -> void:
	member = target_member
	usable = can_use
	reason = why
	refusal = refusal_text
