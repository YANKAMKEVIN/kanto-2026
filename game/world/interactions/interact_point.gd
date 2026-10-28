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
## Jalon 12 (jalon-12.md §2.8, objets cachés « face à un indice ») : le point n'est plus une
## cible dès qu'un de ces drapeaux est levé (`got_<id>` : l'objet est trouvé, le bouton
## EXAMINER disparaît). Vide = toujours une cible. Recopié dans chaque [Interaction].
@export var unless_flags: Array[StringName] = []
## Jalon 32 (N-18) : le point n'est une cible que si **tous** ces drapeaux sont levés (Ronflex
## d'après la Ligue). Vide = aucune condition. Recopié dans chaque [Interaction].
@export var if_flags: Array[StringName] = []
## Jalon 28 : le point n'est plus une cible quand **tous** ces drapeaux sont levés (porte de
## l'Arène de Jadielle). Vide = sans effet. Recopié dans chaque [Interaction].
@export var unless_all_flags: Array[StringName] = []
## Jalon 16 (jalon-16.md §2.6) : objet à fouiller d'un puzzle d'interrupteurs ([SwitchPuzzle]) :
## identifiant du puzzle (`data/world/switch_puzzles.json`) et place de l'objet dans sa grille
## (1..n, ligne par ligne). &"" / 0 = point ordinaire. Recopiés dans chaque [Interaction].
@export var puzzle: StringName = &""
@export var puzzle_slot: int = 0
## Passe systèmes 2 (`systemes-2.md` §2.4, plan du J21 §2.2) : dormeur réveillé à la Poké Flûte
## (Ronflex) — scène jouée quand la Flûte retentit sur une case voisine ; &"" = aucun. Lu par
## [method GameMap.flute_targets].
@export var flute_cutscene: StringName = &""


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
		var interaction := Interaction.new(kind, cell, dialogue_id, facing, null)
		interaction.unless_flags = unless_flags.duplicate()
		interaction.if_flags = if_flags.duplicate()
		interaction.unless_all_flags = unless_all_flags.duplicate()
		interaction.puzzle = puzzle
		interaction.puzzle_slot = puzzle_slot
		result.append(interaction)
	return result
