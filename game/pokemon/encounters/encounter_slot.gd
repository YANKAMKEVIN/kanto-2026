class_name EncounterSlot
extends RefCounted
## Une entrée d'une table de rencontres : une espèce, une fourchette de niveaux, un poids
## (jalon 5 §2.2). Donnée pure.
##
## Le poids fixe la probabilité relative de l'espèce dans la table (poids / poids total). Le
## niveau tiré est uniforme dans [member min_level] .. [member max_level] (inclus).

var species: StringName = &""
var min_level: int = 1
var max_level: int = 1
var weight: int = 1


func _init(slot_species: StringName = &"", level_min: int = 1, level_max: int = 1,
		slot_weight: int = 1) -> void:
	species = slot_species
	min_level = level_min
	max_level = level_max
	weight = slot_weight
