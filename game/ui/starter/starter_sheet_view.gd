class_name StarterSheetView
extends RefCounted
## Ce qu'affiche la fiche du starter (StarterSheet) : des chaînes, rien d'autre.
##
## Celui qui ouvre la fiche la remplit à partir des données ; la fiche ne connaît ni les
## Pokémon ni les données. Pas de statistiques (dossier 02 §3 : jamais de fiche technique).

## Nom affiché (« Salamèche » ; la fiche le met en MAJUSCULES).
var display_name: String = ""
## Identifiants des types (&"fire"…), dans l'ordre : couleur et icône des pastilles.
var type_ids: Array[StringName] = []
## Noms des types à afficher (« Feu »…), dans le même ordre que type_ids.
var type_names: Array[String] = []
## Phrase de caractère (« Fougueux et courageux. »), en italique.
var phrase: String = ""


func _init(
	name: String = "", ids: Array[StringName] = [], names: Array[String] = [],
	text: String = ""
) -> void:
	display_name = name
	type_ids = ids
	type_names = names
	phrase = text


## Vue affichable : un nom, 1 ou 2 types, autant de noms que d'identifiants.
func is_valid() -> bool:
	return not display_name.is_empty() and type_ids.size() in [1, 2] \
		and type_names.size() == type_ids.size()
