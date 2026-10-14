extends RefCounted
## Recherches de chemin sur une [GridWorld] (4 directions, un pas par case, rebords compris par
## `get_step_target`), pour les critères des grilles refaits sur la vraie scène (jalon 10 T11,
## comme `test_route_2`). Utilisation :
## [code]const GridPaths := preload("res://tests/helpers/grid_paths.gd")[/code].

const INF := 1 << 30
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## Copie du relief de [param source] (solide, hautes herbes, rebords) sur [param size] cases.
static func relief(source: GridWorld, size: Vector2i) -> GridWorld:
	var grid := GridWorld.new(size)
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if source.is_solid(cell):
				grid.set_solid(cell)
			if source.is_tall_grass(cell):
				grid.set_tall_grass(cell)
			grid.set_ledge(cell, source.get_ledge(cell))
	return grid


## Distance en pas depuis [param starts] vers chaque case atteinte. Une case de [param stops]
## (portes STEP_ON) s'atteint mais ne se traverse pas.
static func distances(grid: GridWorld, starts: Array, stops: Dictionary = {}) -> Dictionary:
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	for start: Vector2i in starts:
		dist[start] = 0
		queue.append(start)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if stops.has(cell) and int(dist[cell]) > 0:
			continue
		for direction: Vector2i in DIRECTIONS:
			var next := grid.get_step_target(cell, direction)
			if next != cell and not dist.has(next):
				dist[next] = int(dist[cell]) + 1
				queue.append(next)
	return dist


## Nombre minimal de cases de [param counted] traversées de [param starts] à l'une des cases
## [param goals] (0-1 BFS, comme `plan_check.py`).
static func min_crossed(grid: GridWorld, starts: Array, goals: Array, counted: Dictionary) -> int:
	var cost: Dictionary = {}
	var deque: Array[Vector2i] = []
	for start: Vector2i in starts:
		cost[start] = 0
		deque.append(start)
	while not deque.is_empty():
		var cell: Vector2i = deque.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := grid.get_step_target(cell, direction)
			if next == cell:
				continue
			var k := int(cost[cell]) + (1 if counted.has(next) else 0)
			if k < int(cost.get(next, INF)):
				cost[next] = k
				if k > int(cost[cell]):
					deque.append(next)
				else:
					deque.push_front(next)
	var best := INF
	for goal: Vector2i in goals:
		best = mini(best, int(cost.get(goal, INF)))
	return best


static func count_nodes(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += count_nodes(child)
	return total


## Cases libres de [param grid] (ni solides, ni eau, sans occupant autre que [param mover])
## qu'on n'atteint pas à pied depuis [param start] **avec les occupants en place** (PNJ, objets,
## Dresseurs à leur case du moment). Sans rebord, le graphe est non orienté : une liste vide dit
## que tout point libre relie [param start] dans les deux sens (jalon 12, correctif du chercheur).
static func cut_off(grid: GridWorld, start: Vector2i, mover: Object = null) -> Array[Vector2i]:
	var reached := grid.find_reachable(start, mover)
	var missing: Array[Vector2i] = []
	var size := grid.get_size()
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if grid.is_free(cell, mover) and not grid.is_water(cell) and not reached.has(cell):
				missing.append(cell)
	return missing


## Cases que les **occupants** (PNJ, Dresseurs, objets) coupent de [param start] : atteignables
## sur le seul relief de [param grid], plus atteignables avec les occupants en place (cases
## occupées exclues). Les parties d'une carte reliées seulement par d'autres cartes (échelles)
## n'y figurent pas : elles sont hors d'atteinte dans les deux cas.
static func cut_by_occupants(grid: GridWorld, start: Vector2i,
		mover: Object = null) -> Array[Vector2i]:
	var bare := relief(grid, grid.get_size()).find_reachable(start)
	var reached := grid.find_reachable(start, mover)
	var missing: Array[Vector2i] = []
	for cell: Vector2i in bare:
		if grid.is_free(cell, mover) and not reached.has(cell):
			missing.append(cell)
	missing.sort()
	return missing
