class_name PokedexHabitatView
extends RefCounted
## Une zone de l'onglet Habitat d'une fiche du Pokédex (dossier 08 §4 ; jalon-06.md §3.5) :
## **seulement** une zone où le joueur a observé l'espèce (jamais une zone non découverte,
## jamais « ??? »). Toucher la zone → `MenuRoute.map(zone_id)`. Contrat figé au T14 (§6.9).

var zone_id: StringName = &""
## « Route 1 ».
var name: String = ""


func _init(zone: StringName = &"", shown_name: String = "") -> void:
	zone_id = zone
	name = shown_name
