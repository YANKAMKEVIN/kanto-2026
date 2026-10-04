class_name TrainerStatView
extends RefCounted
## Une ligne de la section Statistiques de l'écran Dresseur (dossier 08 §6 ; jalon-06.md
## §3.7) : seulement ce que la partie enregistre déjà. Contrat figé au T23.

## Identifiant stable (icône, tests) : [constant TrainerSummary.STAT_PLAY_TIME]…
var stat_id: StringName = &""
## « Temps de jeu », « Zones découvertes », « Captures », « Objets trouvés ».
var label: String = ""
## Valeur déjà écrite (« 0 h 27 », « 2 », « 1 250 »).
var value_text: String = ""


func _init(id: StringName = &"", stat_label: String = "", value: String = "") -> void:
	stat_id = id
	label = stat_label
	value_text = value
