class_name FlagGate
extends Node2D
## Décor qui suit les drapeaux d'histoire (docs/tech/jalon-14.md §2.8) : ses enfants (une lueur
## [LightGlow] sur l'objet attendu chez Léo, la planche clouée d'Azuria) ne sont affichés que si
## tous les drapeaux de [member if_flags] sont levés et aucun de [member unless_flags], comme la
## présence d'un PNJ ([method NpcSpec.is_present]).
##
## **Visuel seulement** : n'agit ni sur la grille ni sur les interactions (un décor qui bloque
## une case ne se met pas sous une porte de drapeaux). Posée par les outils de construction des
## cartes ; [method GameMap.apply_flag_gates] règle toutes celles de la carte à l'arrivée, puis
## Boot à chaque drapeau changé pendant la visite (la lueur suit un « set » de dialogue ou de
## scène sans changement de carte). Sans conditions : toujours affichée.

## Groupe de toutes les portes de drapeaux ([method GameMap.apply_flag_gates]).
const GROUP: StringName = &"flag_gate"

## Drapeaux qui doivent tous être levés.
@export var if_flags: Array[StringName] = []
## Drapeaux dont aucun ne doit être levé.
@export var unless_flags: Array[StringName] = []


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
