class_name CutsceneMoves
extends RefCounted
## Calculs de déplacement des scènes scriptées (docs/tech/jalon-03b.md §2.3), sans scène.
##
## Appelés au **début** d'une étape « move » (ils allouent), jamais à chaque image.


## Première case libre et praticable autour de [param anchor], dans l'ordre de
## [param offsets] ([method GridWorld.is_free] ; [param mover] y est ignoré comme occupant).
## [constant CutsceneStep.NO_CELL] si aucune ne convient.
static func resolve_near(grid: GridWorld, anchor: Vector2i, offsets: Array[Vector2i],
		mover: Object = null) -> Vector2i:
	for offset: Vector2i in offsets:
		var cell := anchor + offset
		if offset != Vector2i.ZERO and grid.is_free(cell, mover):
			return cell
	return CutsceneStep.NO_CELL


## Chemin d'un suiveur qui marche **un pas derrière** un meneur : un pas vers la case de
## départ du meneur, puis les pas du meneur sauf le dernier. Le suiveur finit ainsi sur
## l'avant-dernière case du meneur, et entre toujours dans la case que le meneur vient de
## quitter. Vide si les deux ne sont pas voisins ou si le meneur ne bouge pas. Pas de
## rebord : chaque direction avance d'une case.
static func follow_path(follower_cell: Vector2i, leader_cell: Vector2i,
		leader_path: Array[Vector2i]) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var first := leader_cell - follower_cell
	if leader_path.is_empty() or not Grid.is_cardinal(first):
		return path
	path.append(first)
	for i: int in leader_path.size() - 1:
		path.append(leader_path[i])
	return path


## Cases successives parcourues depuis [param from] en suivant [param path] (sans
## [param from]). Sert aux tests de données : chemins libres, sans warp ni déclencheur.
static func path_cells(from: Vector2i, path: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell := from
	for direction: Vector2i in path:
		cell += direction
		cells.append(cell)
	return cells
