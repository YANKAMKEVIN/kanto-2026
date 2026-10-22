class_name SeafoamBoulderSetup
extends BoulderSetup
## Nœud `Boulders` d'un étage des Îles Écume (jalon 24, T15) : comme [BoulderSetup] (trous,
## cases interdites), mais les rochers présents viennent de [SeafoamState]
## ([SeafoamBoulderField]). Les origines de [member BoulderSetup.boulder_cells] restent posées
## par l'outil pour la lecture humaine ; c'est l'état de l'étage qui fait foi.

## Étage (identifiant de la carte).
@export var floor_id: StringName = &""
## Points de chute dans l'eau (dessinés par un [FlagGate], jamais des [Boulder]).
@export var water_fall_cells: Array[Vector2i] = []


func to_field() -> BoulderField:
	var field := SeafoamBoulderField.new(floor_id, water_fall_cells)
	for i: int in boulder_cells.size():
		field.add_boulder(boulder_cells[i], boulder_holes[i] if i < boulder_holes.size() else 0)
	for i: int in hole_cells.size():
		field.add_hole(hole_cells[i], hole_numbers[i], hole_flags[i])
	for cell: Vector2i in no_push_cells:
		field.add_no_push(cell)
	return field
