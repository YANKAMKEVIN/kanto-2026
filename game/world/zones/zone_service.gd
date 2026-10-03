class_name ZoneService
extends RefCounted
## Un service d'une zone (Centre Pokémon, Boutique, Arène ; dossier 08 §5 ; jalon-06.md §3.6).
## Donnée pure, construite par [ZoneLibrary]. Aucun au J6 : le format est prêt pour le J7A.
##
## Un service n'existe pour le joueur qu'une fois **découvert** : quand il est entré sur la
## carte [member found_on] (une carte de la zone, par exemple l'intérieur du Centre).

## Identifiant du catalogue des services de `zones.json` (« pokemon_center »…).
var id: StringName = &""
## Carte de la zone dont la première visite découvre le service.
var found_on: StringName = &""


func _init(service_id: StringName = &"", map: StringName = &"") -> void:
	id = service_id
	found_on = map
