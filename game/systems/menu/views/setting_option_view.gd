class_name SettingOptionView
extends RefCounted
## Une option d'un réglage à choix (jalon-06.md §6.12) : « Lente », « Normale »… Contrat
## figé au T27.

## Texte du bouton.
var label: String = ""
## Valeur du réglage à renvoyer telle quelle dans `setting_changed(key, value)` (entier d'enum
## ou flottant d'échelle) : jamais un rang dans la liste.
var value: Variant = null


func _init(option_label: String = "", option_value: Variant = null) -> void:
	label = option_label
	value = option_value
