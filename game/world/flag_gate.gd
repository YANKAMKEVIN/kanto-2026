class_name FlagGate
extends Node2D
## Décor qui suit les drapeaux d'histoire (docs/tech/jalon-14.md §2.8) : ses enfants (une lueur
## [LightGlow] sur l'objet attendu chez Léo, la planche clouée d'Azuria) ne sont affichés que si
## tous les drapeaux de [member if_flags] sont levés et aucun de [member unless_flags], comme la
## présence d'un PNJ ([method NpcSpec.is_present]).
##
## **Visuel seulement** par défaut : n'agit ni sur la grille ni sur les interactions. Exception
## (jalon 15) : [member blocking_cells], cases occupées tant que le décor est affiché.
## Posée par les outils de construction des cartes ; [method GameMap.apply_flag_gates] règle toutes celles de la carte à l'arrivée, puis
## Boot à chaque drapeau changé pendant la visite (la lueur suit un « set » de dialogue ou de
## scène sans changement de carte). Sans conditions : toujours affichée.

## Groupe de toutes les portes de drapeaux ([method GameMap.apply_flag_gates]).
const GROUP: StringName = &"flag_gate"

## Drapeaux qui doivent tous être levés.
@export var if_flags: Array[StringName] = []
## Drapeaux dont aucun ne doit être levé.
@export var unless_flags: Array[StringName] = []
## Jalon 15 (contrat du J16 : le jeune arbre devant l'Arène de Carmin) : cases de la carte
## **occupées** tant que le décor est affiché ([method GameMap.apply_flag_gates] les occupe ou
## les libère, comme la case d'un PNJ). Vide (défaut) : visuel seulement, comme au J14.
@export var blocking_cells: Array[Vector2i] = []


func _init() -> void:
	add_to_group(GROUP)


## Vrai si le décor doit être affiché avec [param flags] (null = nouvelle partie, aucun
## drapeau levé).
func is_open(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Affiche ou cache le décor selon [param flags].
func apply(flags: StoryFlags) -> void:
	visible = is_open(flags)


## Occupe (affiché) ou libère (caché) [member blocking_cells] dans [param grid].
func apply_to_grid(grid: GridWorld) -> void:
	if grid == null:
		return
	for cell: Vector2i in blocking_cells:
		if visible:
			grid.occupy(cell, self)
		else:
			grid.release(cell, self)
