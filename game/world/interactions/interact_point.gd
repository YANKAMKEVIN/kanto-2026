class_name InteractPoint
extends Marker2D
## Point fixe d'interaction posé dans une carte (enfant de `Interactables`) : table, carte
## de Kanto, panneau (docs/tech/jalon-03.md §2.2).
##
## Donnée de carte visible dans l'éditeur (croix du Marker2D), écrite par les scripts de
## construction comme les [WarpPoint]. La position est celle de la case d'ancrage, au pied
## (Grid.cell_to_world). [GameMap] convertit chaque point en [Interaction] (une par case
## couverte) et les range dans son [InteractionTable].

@export var dialogue_id: StringName = &""
@export var kind: Interaction.Kind = Interaction.Kind.EXAMINE
## Cases couvertes depuis l'ancre (bas-gauche, comme les empreintes de props) :
## x 0..size.x-1, y -(size.y-1)..0. Une table 3 × 2 = un seul point.
@export var size: Vector2i = Vector2i.ONE
## Orientation exigée du joueur (ZERO = de tous côtés).
@export var facing: Vector2i = Vector2i.ZERO


## Case d'ancrage (bas-gauche), déduite de la position.
func get_cell() -> Vector2i:
	return Grid.world_to_cell(position)


## Cases couvertes, de gauche à droite puis de bas en haut. Vide si [member size] n'est
## pas strictement positif.
func get_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var anchor := get_cell()
	for y: int in maxi(size.y, 0):
		for x: int in maxi(size.x, 0):
			cells.append(anchor + Vector2i(x, -y))
	return cells


## Une [Interaction] par case couverte (source null : point fixe).
func to_interactions() -> Array[Interaction]:
	var result: Array[Interaction] = []
	for cell: Vector2i in get_cells():
		result.append(Interaction.new(kind, cell, dialogue_id, facing, null))
	return result
