class_name EventTriggerPoint
extends Marker2D
## Déclencheur de scène posé dans une carte (enfant de `Triggers`) : case juste avant les
## hautes herbes de la Route 1 (docs/tech/jalon-03b.md §2.2).
##
## Donnée de carte visible dans l'éditeur (croix du Marker2D), écrite par les scripts de
## construction comme les [WarpPoint] et les [InteractPoint]. La position est celle de la
## case d'ancrage, au pied (Grid.cell_to_world). [GameMap] convertit chaque point en
## [EventTrigger] (un par case couverte) et les range dans sa [TriggerTable]. Aucune
## condition ici : ce sont les variantes de la scène qui décident.

@export var cutscene_id: StringName = &""
## Cases couvertes depuis l'ancre (bas-gauche, comme les empreintes de props) :
## x 0..size.x-1, y -(size.y-1)..0.
@export var size: Vector2i = Vector2i.ONE
## Direction du pas qui arrive sur la case (ZERO = toutes).
@export var direction: Vector2i = Vector2i.ZERO


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


## Un [EventTrigger] par case couverte.
func to_triggers() -> Array[EventTrigger]:
	var result: Array[EventTrigger] = []
	for cell: Vector2i in get_cells():
		result.append(EventTrigger.new(cell, direction, cutscene_id))
	return result
