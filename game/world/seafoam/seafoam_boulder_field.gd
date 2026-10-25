class_name SeafoamBoulderField
extends BoulderField
## Rochers d'un étage des Îles Écume (jalon 24, T15 ; dossier 27 §7.3) : le [BoulderField] de la
## passe systèmes 2, dont les rochers présents à l'entrée viennent de [SeafoamState] (rochers
## d'origine moins les rochers désignés des trous bouchés, plus les rochers tombés d'au-dessus).
## Les rochers tombés **dans l'eau** (B3F, B4F) ne sont pas des [Boulder] : la carte les dessine
## avec un [FlagGate] bloquant ; ils sont donc écartés ici ([member water_cells]).

## Étage (identifiant de la carte) dans `data/world/seafoam.json`.
var floor_id: StringName = &""
## Points de chute dans l'eau (jamais un [Boulder]).
var water_cells: Array[Vector2i] = []


func _init(p_floor_id: StringName = &"", p_water_cells: Array[Vector2i] = []) -> void:
	floor_id = p_floor_id
	water_cells = p_water_cells


## Rochers présents à l'entrée : ceux de [method SeafoamState.floor_state], sans ceux de l'eau.
func boulders_at_load(flags: StoryFlags) -> Array[Vector2i]:
	var floor_state := SeafoamFloorGate.state().floor_state(floor_id, flags)
	if floor_state == null:
		return super(flags)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in floor_state.boulders:
		if not water_cells.has(cell):
			cells.append(cell)
	return cells
