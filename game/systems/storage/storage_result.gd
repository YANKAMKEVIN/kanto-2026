class_name StorageResult
extends RefCounted
## Résultat d'une action du Stockage ([StorageRules]) : le statut (raison d'un refus), le
## Pokémon concerné et la sélection à montrer ensuite. Donnée pure. Texte d'un refus :
## [method StorageViews.result_text].

var status: StorageRules.Status = StorageRules.Status.NOT_FOUND
## Le Pokémon concerné (déplacé, libéré, refusé) ; null si la place n'existait pas.
var pokemon: Pokemon
## Après un succès : où le Pokémon se trouve maintenant (libéré : celui qui prend sa place) ;
## après un refus : la place du Pokémon refusé (la carte qui tremble).
var selection: StorageSelection


func _init(result_status: StorageRules.Status = StorageRules.Status.NOT_FOUND,
		concerned: Pokemon = null, next: StorageSelection = null) -> void:
	status = result_status
	pokemon = concerned
	selection = next if next != null else StorageSelection.new()


func is_ok() -> bool:
	return status == StorageRules.Status.OK
