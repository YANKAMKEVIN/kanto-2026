class_name CaveLevelGate
extends FlagGate
## Niveaux de sol d'une grotte sans autre mécanique (jalon 31, Grotte Azurée ; collisions par
## paires de Rouge/Bleu : sol bas, sol haut, escalier entre les deux) : un [FlagGate] sans
## dessin, réglé par [method GameMap.apply_flag_gates] comme [SeafoamFloorGate] (J24), dont il
## reprend la seule partie « niveaux » (pas de courants ni de drapeaux).

@export var low_cells: Array[Vector2i] = []
@export var high_cells: Array[Vector2i] = []
@export var stairs_cells: Array[Vector2i] = []


func apply_to_grid(grid: GridWorld) -> void:
	if grid == null:
		return
	for cell: Vector2i in low_cells:
		grid.set_level(cell, GridWorld.Level.LOW)
	for cell: Vector2i in high_cells:
		grid.set_level(cell, GridWorld.Level.HIGH)
	for cell: Vector2i in stairs_cells:
		grid.set_level(cell, GridWorld.Level.STAIRS)
