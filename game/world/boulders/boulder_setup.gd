class_name BoulderSetup
extends Node
## Rochers de Force d'une carte, tels que les pose l'outil de construction (passe systèmes 2,
## `systemes-2.md` §2.7.2, §2.7.4) : donnée seulement, lue à l'entrée sur la carte pour bâtir un
## [BoulderField] ([method to_field]). Un seul nœud par carte, enfant direct de la racine, nommé
## `Boulders`. Tableaux parallèles (les scènes `.tscn` écrites par les outils restent lisibles).
##
## Le dessin des trous, des interrupteurs et des barrières est fait par des [FlagGate] (trou
## ouvert `unless` son drapeau, trou bouché `if` son drapeau, interrupteur enfoncé `if` son
## drapeau, barrière `unless` le drapeau de l'interrupteur, `blocking_cells`) ; la chute du joueur,
## par un [WarpPoint] [constant Warp.Trigger.FALL] `unless_flags` le drapeau du trou.

## Nom du nœud dans la carte.
const NODE_NAME: StringName = &"Boulders"

## Origines des rochers.
@export var boulder_cells: Array[Vector2i] = []
## Trou désigné de chaque rocher (même indice ; 0 : aucun).
@export var boulder_holes: Array[int] = []
## Drapeau sans lequel chaque rocher n'est pas là (même indice ; vide : toujours là ; jalon 29).
@export var boulder_requires: Array[StringName] = []
## Trous : case, numéro, drapeau posé quand un rocher y tombe.
@export var hole_cells: Array[Vector2i] = []
@export var hole_numbers: Array[int] = []
@export var hole_flags: Array[StringName] = []
## Interrupteurs : case, identifiant, drapeau posé quand un rocher s'y arrête.
@export var switch_cells: Array[Vector2i] = []
@export var switch_ids: Array[StringName] = []
@export var switch_flags: Array[StringName] = []
## Cases interdites aux rochers (objets cachés…).
@export var no_push_cells: Array[Vector2i] = []


## [BoulderField] équivalent.
func to_field() -> BoulderField:
	var field := BoulderField.new()
	for i: int in boulder_cells.size():
		field.add_boulder(boulder_cells[i], boulder_holes[i] if i < boulder_holes.size() else 0,
			boulder_requires[i] if i < boulder_requires.size() else &"")
	for i: int in hole_cells.size():
		field.add_hole(hole_cells[i], hole_numbers[i], hole_flags[i])
	for i: int in switch_cells.size():
		field.add_switch(switch_cells[i], switch_ids[i], switch_flags[i])
	for cell: Vector2i in no_push_cells:
		field.add_no_push(cell)
	return field
