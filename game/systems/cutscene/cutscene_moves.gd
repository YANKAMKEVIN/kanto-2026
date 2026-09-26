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


## Cases dont l'intérieur est traversé par le saut en ligne droite de [param from] à
## [param to] (centres des cases), sans les deux extrémités. Un saut qui passe exactement
## par un coin ou un bord ne traverse pas la case (un saut en diagonale d'une case ne
## traverse rien). Ordre de parcours du saut. Sert à vérifier qu'un saut ne passe au-dessus
## d'aucun personnage (jalon 4, décision de Kevin sur le 4A).
static func hop_crossed_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var hits: Dictionary[Vector2i, float] = {}
	var a := Vector2(from)
	var b := Vector2(to)
	for x: int in range(mini(from.x, to.x), maxi(from.x, to.x) + 1):
		for y: int in range(mini(from.y, to.y), maxi(from.y, to.y) + 1):
			var cell := Vector2i(x, y)
			if cell == from or cell == to:
				continue
			var t := _segment_enters_open_square(a, b, Vector2(cell))
			if t >= 0.0:
				hits[cell] = t
	cells.assign(hits.keys())
	cells.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return hits[p] < hits[q])
	return cells


## Case d'atterrissage d'un saut de [param from] vers les cases [param anchor] +
## [param offsets] (dans l'ordre) : la première qui est libre et praticable
## ([method GridWorld.is_free], [param mover] ignoré), dont le saut ne traverse la case
## d'aucun occupant ([method hop_crossed_cells]), et qui n'est pas juste au-dessus d'une case
## de [param tall_cells] (derrière la tête d'un grand personnage, ou cachée par un meuble qui
## dépasse).
## [constant CutsceneStep.NO_CELL] si aucune ne convient.
static func resolve_landing(grid: GridWorld, from: Vector2i, anchor: Vector2i,
		offsets: Array[Vector2i], mover: Object = null,
		tall_cells: Array[Vector2i] = []) -> Vector2i:
	for offset: Vector2i in offsets:
		var cell := anchor + offset
		if offset == Vector2i.ZERO or cell == from or not grid.is_free(cell, mover):
			continue
		if tall_cells.has(cell + Vector2i.DOWN):
			continue
		var clear := true
		for crossed: Vector2i in hop_crossed_cells(from, cell):
			var occupant := grid.get_occupant(crossed)
			if occupant != null and occupant != mover:
				clear = false
				break
		if clear:
			return cell
	return CutsceneStep.NO_CELL


## Paramètre d'entrée (0..1) du segment [param a]→[param b] dans l'intérieur de la case de
## centre [param center] (carré ouvert de côté 1), −1 s'il n'y entre pas (Liang-Barsky).
static func _segment_enters_open_square(a: Vector2, b: Vector2, center: Vector2) -> float:
	const EPS := 0.0001
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for axis: int in 2:
		var lo := center[axis] - 0.5 + EPS
		var hi := center[axis] + 0.5 - EPS
		if is_zero_approx(d[axis]):
			if a[axis] < lo or a[axis] > hi:
				return -1.0
			continue
		var ta := (lo - a[axis]) / d[axis]
		var tb := (hi - a[axis]) / d[axis]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
	return t0 if t0 < t1 else -1.0


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
