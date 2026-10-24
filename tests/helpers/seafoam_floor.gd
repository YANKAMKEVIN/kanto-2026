extends RefCounted
## Un étage des Îles Écume pour les tests (jalon 24, T9) : la grille `tools/plans/seafoam_*.txt`
## (lue par `plan_grid.gd`) posée dans un [GridWorld], dans l'état d'un [SeafoamState.Floor], avec
## les règles du jeu ([SurfRules], [CurrentField], [BoulderRules]). [method explore] refait
## l'exploration par poussée de `tools/art/plan_check_j24_seafoam.py` (`explorer`) : mêmes départs,
## mêmes comptes (configurations de rochers, états, impasses, trous que l'on peut boucher).
## Utilisation : [code]const SeafoamFloor := preload("res://tests/helpers/seafoam_floor.gd")[/code].

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const SOLID_CHARS: String = "#|onx"
const WATER_CHARS: String = "ws^v<>"

## Résultat de [method explore].
class Exploration:
	extends RefCounted
	var configs: int = 0
	var states: int = 0
	var impasses: int = 0
	## Trous bouchés au moins une fois (numéros), en plus de ceux du départ.
	var fillable: Array[int] = []

var plan: PlanGrid
var grid: GridWorld
var state: SeafoamState.Floor
var width: int = 0
var height: int = 0
## Échelles, passages, entrées : case → vrai (sorties de l'étage).
var exits: Dictionary = {}
## Trous ouverts : case → numéro.
var open_holes: Dictionary = {}
## Cases d'objets cachés (interdites aux rochers).
var no_push: Dictionary = {}
## Arrivées (spawns) et atterrissages des données de la grille.
var spawns: Array[Vector2i] = []
var landings: Array[Vector2i] = []
var map_id: StringName = &""
## Occupant fixe (Artikodin), case → objet.
var _statics: Dictionary = {}
var _boulder_token := RefCounted.new()


## Construit l'étage [param map_id] pour [param floor_state].
func setup(p_map_id: StringName, floor_state: SeafoamState.Floor) -> bool:
	map_id = p_map_id
	state = floor_state
	plan = PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % map_id):
		return false
	width = plan.width
	height = plan.height
	grid = GridWorld.new(Vector2i(width, height))
	for y: int in height:
		var row: String = plan.rows[y]
		for x: int in width:
			_paint(Vector2i(x, y), row[x])
	for id: String in plan.positions:
		var pos: Dictionary = plan.positions[id]
		var cells: Array = pos["cells"]
		match String(pos["kind"]):
			"echelle", "entree":
				for cell: Vector2i in cells:
					exits[cell] = true
					grid.set_level(cell, GridWorld.Level.ANY)
			"passage":
				for cell: Vector2i in cells:
					exits[cell] = true
			"chute_rocher":
				if String(pos["attrs"].get("sol", "")) == "eau":
					grid.set_surfable(cells[0])
			"objet_cache":
				no_push[cells[0]] = true
			"rencontre":
				var token := RefCounted.new()
				_statics[cells[0]] = token
				grid.occupy(cells[0], token)
			"spawn":
				spawns.append(cells[0])
			"chute_joueur":
				landings.append(cells[0])
	open_holes = floor_state.open_holes.duplicate()
	floor_state.apply_to(grid)
	return true


## Terminaux (sorties et trous ouverts) pour un ensemble de trous ouverts.
func terminals_for(holes: Dictionary) -> Dictionary:
	var result := exits.duplicate()
	for cell: Vector2i in holes:
		result[cell] = true
	return result


## Pose les rochers de [param cells] comme occupants (et retire les autres).
func place_boulders(cells: Array) -> void:
	for y: int in height:
		for x: int in width:
			var cell := Vector2i(x, y)
			if grid.get_occupant(cell) == _boulder_token:
				grid.release(cell, _boulder_token)
	for cell: Vector2i in cells:
		grid.occupy(cell, _boulder_token)


## Départs de l'exploration (comme `departs_exploration` du générateur) : arrivées et
## atterrissages hors rochers, glissade appliquée, terminaux exclus.
func starts(boulders: Array) -> Array[Vector2i]:
	var rocks: Dictionary = {}
	for cell: Vector2i in boulders:
		rocks[cell] = true
	var terms := terminals_for(open_holes)
	var all: Dictionary = {}
	for cell: Vector2i in spawns + landings:
		all[cell] = true
	var sorted_cells: Array = all.keys()
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y * width + a.x < b.y * width + b.x)
	var result: Array[Vector2i] = []
	for cell: Vector2i in sorted_cells:
		if rocks.has(cell):
			continue
		var s := cell
		if grid.is_current(s):
			s = CurrentField.ride(grid, s, terms).end
		if terms.has(s) or rocks.has(s):
			continue
		if not result.has(s):
			result.append(s)
	return result


## Exploration exhaustive par poussée depuis [param from] (rochers [param boulders], trous ouverts
## de l'étage), comme `explorer` du contrôle Python.
func explore(boulders: Array, from: Array[Vector2i]) -> Exploration:
	var result := Exploration.new()
	var start_plugged := _plugged_mask()
	var hole_cells: Dictionary = {}
	for cell: Vector2i in state.open_holes:
		hole_cells[state.open_holes[cell]] = cell
	for cell: Vector2i in state.plugged_holes:
		hole_cells[state.plugged_holes[cell]] = cell
	var adjacency_cache: Dictionary = {}
	var seen: Dictionary = {}          # clé d'état → { case: vrai }
	var configs: Dictionary = {}
	var edges: Dictionary = {}         # composante → [ [clé d'état, case du joueur] ]
	var comps: Dictionary = {}         # clé d'état → [ [cases, clé de composante] ]
	var with_exit: Dictionary = {}
	var plugged_seen: Dictionary = {}
	var queue: Array = []
	var rocks0 := _sorted(boulders)
	for s: Vector2i in from:
		queue.append([rocks0, start_plugged, s])
	var head := 0
	while head < queue.size():
		var item: Array = queue[head]
		head += 1
		var rocks: Array = item[0]
		var plugged: int = item[1]
		var player: Vector2i = item[2]
		var key := "%s|%d" % [str(rocks), plugged]
		var done: Dictionary = seen.get_or_add(key, {})
		if done.has(player):
			continue
		var holes := _open_holes_for(plugged, hole_cells)
		var adjacency: Dictionary = adjacency_cache.get(plugged, {})
		if adjacency.is_empty():
			adjacency = _adjacency(holes)
			adjacency_cache[plugged] = adjacency
		var rock_set: Dictionary = {}
		for cell: Vector2i in rocks:
			rock_set[cell] = true
		var component := _component(adjacency, rock_set, player, holes)
		var cells: Dictionary = component[0]
		var reaches_exit: bool = component[1]
		done.merge(cells)
		var min_cell := _min_cell(cells)
		var ckey := "%s@%d" % [key, min_cell]
		(comps.get_or_add(key, []) as Array).append([cells, ckey])
		result.states += 1
		configs[key] = true
		plugged_seen[plugged] = true
		if reaches_exit:
			with_exit[ckey] = true
		var next_list: Array = edges.get_or_add(ckey, [])
		place_boulders(rocks)
		for r: Vector2i in rocks:
			for d: Vector2i in DIRECTIONS:
				if not cells.has(r - d):
					continue
				var push := BoulderRules.push(grid, r, d, holes, no_push)
				if push.is_refused():
					continue
				var new_rocks := rocks.duplicate()
				new_rocks.erase(r)
				var new_plugged := plugged
				if push.outcome == BoulderRules.Outcome.FELL:
					new_plugged |= 1 << push.hole
				else:
					new_rocks.append(push.target)
				new_rocks = _sorted(new_rocks)
				next_list.append(["%s|%d" % [str(new_rocks), new_plugged], r])
				queue.append([new_rocks, new_plugged, r])
		place_boulders([])
	result.configs = configs.size()
	# Co-accessibilité : composantes d'où une suite de poussées mène à une sortie.
	var inverse: Dictionary = {}
	for ckey: String in edges:
		for edge: Array in edges[ckey]:
			for comp: Array in comps.get(edge[0], []):
				if (comp[0] as Dictionary).has(edge[1]):
					(inverse.get_or_add(comp[1], []) as Array).append(ckey)
					break
	var good: Dictionary = with_exit.duplicate()
	var work: Array = with_exit.keys()
	while not work.is_empty():
		var c: String = work.pop_back()
		for src: String in inverse.get(c, []):
			if not good.has(src):
				good[src] = true
				work.append(src)
	for ckey: String in edges:
		if not good.has(ckey):
			result.impasses += 1
	var fill: Dictionary = {}
	for plugged: int in plugged_seen:
		for n: int in [1, 2]:
			if plugged & (1 << n) and not start_plugged & (1 << n):
				fill[n] = true
	for n: int in [1, 2]:
		if fill.has(n):
			result.fillable.append(n)
	return result


## Cases atteintes par le joueur (à pied et en Surf) depuis [param from], rochers posés.
func reachable(boulders: Array, from: Vector2i) -> Dictionary:
	place_boulders(boulders)
	var reached := SurfRules.find_reachable(grid, from, true, terminals_for(open_holes),
		state.surf_forbidden)
	place_boulders([])
	return reached


func _paint(cell: Vector2i, c: String) -> void:
	if SOLID_CHARS.contains(c):
		grid.set_solid(cell)
	elif c == "~":
		grid.set_water(cell)
		grid.set_level(cell, GridWorld.Level.LOW)
	elif WATER_CHARS.contains(c):
		grid.set_surfable(cell)
		grid.set_level(cell, GridWorld.Level.LOW)
	elif c == ":":
		grid.set_level(cell, GridWorld.Level.HIGH)
	elif c == "=":
		grid.set_level(cell, GridWorld.Level.STAIRS)
	elif c in [".", "B", "O", "F"]:
		grid.set_level(cell, GridWorld.Level.LOW)


func _adjacency(holes: Dictionary) -> Dictionary:
	var terms := terminals_for(holes)
	var adjacency: Dictionary = {}
	for y: int in height:
		for x: int in width:
			var cell := Vector2i(x, y)
			if grid.is_solid(cell) or _statics.has(cell) or terms.has(cell) \
					or grid.is_current(cell):
				continue
			if grid.is_water(cell) and not grid.is_surfable(cell):
				continue
			var targets: Array[Vector2i] = []
			for d: Vector2i in DIRECTIONS:
				var t := SurfRules.next_cell(grid, cell, d, true, state.surf_forbidden)
				if t == cell:
					continue
				if not terms.has(t) and grid.is_current(t):
					var ride := CurrentField.ride(grid, t, terms)
					if not ride.is_ok():
						continue
					t = ride.end
				targets.append(t)
			adjacency[cell] = targets
	return adjacency


func _component(adjacency: Dictionary, rocks: Dictionary, start: Vector2i,
		holes: Dictionary) -> Array:
	var cells: Dictionary = {start: true}
	var stack: Array[Vector2i] = [start]
	var reaches_exit := false
	while not stack.is_empty():
		var u: Vector2i = stack.pop_back()
		for v: Vector2i in adjacency.get(u, []):
			if rocks.has(v):
				continue
			if exits.has(v):
				reaches_exit = true
			elif holes.has(v):
				pass
			elif not cells.has(v):
				cells[v] = true
				stack.append(v)
	return [cells, reaches_exit]


func _open_holes_for(plugged: int, hole_cells: Dictionary) -> Dictionary:
	var holes: Dictionary = {}
	for n: int in hole_cells:
		if not plugged & (1 << n):
			holes[hole_cells[n]] = n
	return holes


func _plugged_mask() -> int:
	var mask := 0
	for cell: Vector2i in state.plugged_holes:
		mask |= 1 << state.plugged_holes[cell]
	return mask


func _min_cell(cells: Dictionary) -> int:
	var best := width * height
	for cell: Vector2i in cells:
		best = mini(best, cell.y * width + cell.x)
	return best


func _sorted(cells: Array) -> Array:
	var copy := cells.duplicate()
	copy.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y * width + a.x < b.y * width + b.x)
	return copy
