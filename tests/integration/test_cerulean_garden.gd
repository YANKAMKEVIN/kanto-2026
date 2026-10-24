extends GutTest
## Jardin, impasse et sorties d'Azuria du J14 (jalon 14 T20b, dossier 17 §3.3, §14 ; plan
## `tools/art/plan_check_azuria_j14.py`, critères repris côté GDScript) sur la vraie scène
## `cerulean_city` et la grille `J14` :
## - jardin ouvert par la clôture arrachée (6, 2..3), impasse de 7 × 2 fermée à l'est, trou (14, 3)
##   praticable et examinable depuis (13, 3) ;
## - les bandes de la poursuite, du combat et du barrage couvrent toute la largeur de leur passage ;
## - **aucune case coincée** : dans les quatre états (E0 avant, E1 repéré, E2 battu, E3 sud
##   ouvert), toute case où le joueur peut se trouver (donc sauvegarder) reste libre et reliée à
##   l'entrée ouest dans tous les états suivants.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH := "res://tools/plans/azuria.txt"
const MAP_PATH := "res://game/world/maps/cerulean_city.tscn"
const SPOTTED := &"cerulean_rocket_spotted"
const BEATEN := &"cerulean_rocket_beaten"
const LEFT := &"cerulean_south_guard_left"
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ENTRY: Array[Vector2i] = [Vector2i(0, 19), Vector2i(0, 20), Vector2i(0, 21)]

var _plan: PlanGrid
var _states: Array[Array] = [[], [SPOTTED], [SPOTTED, BEATEN], [SPOTTED, BEATEN, LEFT]]


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH, "J14"), _plan.error)


func _flags(position_id: String, key: String) -> Array[String]:
	var list: Array[String] = []
	var text: String = _plan.attr(position_id, key)
	for flag: String in text.split(",", false):
		list.append(flag)
	return list


## Vrai si la position existe avec ces drapeaux.
func _present(id: String, flags: Array) -> bool:
	for flag: String in _flags(id, "if"):
		if not flags.has(StringName(flag)):
			return false
	for flag: String in _flags(id, "unless"):
		if flags.has(StringName(flag)):
			return false
	return true


func _blocked(flags: Array) -> Dictionary:
	var cells: Dictionary = {}
	for id: String in _plan.positions:
		if _plan.positions[id]["blocks"] and _present(id, flags):
			for cell: Vector2i in _plan.cells_at(id):
				cells[cell] = true
	return cells


func _bands(flags: Array) -> Dictionary:
	var cells: Dictionary = {}
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "declencheur" and _plan.attr(id, "scene") != "" \
				and _present(id, flags):
			for cell: Vector2i in _plan.cells_at(id):
				cells[cell] = true
	return cells


func _free(cell: Vector2i, blocked: Dictionary) -> bool:
	return _plan.is_walkable(cell) and not blocked.has(cell)


## Cases atteignables depuis l'entrée ; [param terminal] : on y entre mais on ne la dépasse pas.
func _reach(blocked: Dictionary, terminal: Dictionary) -> Dictionary:
	var seen: Dictionary = {}
	var stack: Array[Vector2i] = []
	for cell: Vector2i in ENTRY:
		seen[cell] = true
		stack.append(cell)
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if terminal.has(cell):
			continue
		for dir: Vector2i in DIRS:
			var next := cell + dir
			if not seen.has(next) and _free(next, blocked):
				seen[next] = true
				stack.append(next)
	return seen


func _terminal(flags: Array) -> Dictionary:
	var cells := _bands(flags)
	for door: Vector2i in _plan.cells_of("D"):
		cells[door] = true
	return cells


func test_the_garden_is_open_by_the_torn_fence_and_the_impasse_is_long_enough() -> void:
	for y: int in [2, 3]:
		assert_true(_plan.is_walkable(Vector2i(6, y)), "clôture arrachée (6, %d)" % y)
		for x: int in range(7, 14):
			assert_true(_plan.is_walkable(Vector2i(x, y)) or Vector2i(x, y) == Vector2i(9, 2),
				"jardin (%d, %d)" % [x, y])
		for x: int in range(15, 22):
			assert_true(_plan.is_walkable(Vector2i(x, y)), "impasse (%d, %d)" % [x, y])
		assert_false(_plan.is_walkable(Vector2i(22, y)), "fermée à l'est (22, %d)" % y)
	assert_true(_plan.is_walkable(Vector2i(14, 3)), "le trou est le passage")
	assert_false(_plan.is_walkable(Vector2i(14, 2)), "la clôture au-dessus reste fermée")
	assert_eq(_plan.cell_of("trou_cloture"), Vector2i(14, 3))
	# L'impasse n'est accessible que par le trou.
	var blocked := _blocked([])
	blocked[Vector2i(14, 3)] = true
	var reach := _reach(blocked, {})
	for x: int in range(15, 22):
		assert_false(reach.has(Vector2i(x, 3)), "impasse (%d, 3) fermée sans le trou" % x)
	# Le jardin est accessible depuis la rue.
	assert_true(_reach(_blocked([]), {}).has(Vector2i(13, 3)), "jardin relié à la rue")


func test_the_trigger_bands_cover_the_full_width_of_their_passage() -> void:
	assert_eq(_plan.cells_at("poursuite"), [Vector2i(7, 2), Vector2i(7, 3)] as Array[Vector2i])
	assert_eq(_plan.cells_at("combat_rocket"), [Vector2i(17, 2), Vector2i(17, 3)] as Array[Vector2i])
	var south: Array[Vector2i] = [Vector2i(31, 37), Vector2i(32, 37), Vector2i(33, 37)]
	assert_eq(_plan.cells_at("barrage_sud"), south)
	# Sans la bande, on passe ; avec (terminale), on ne dépasse pas la case de la bande.
	var chase := _reach(_blocked([]), _bands([]))
	assert_true(chase.has(Vector2i(7, 2)) and not chase.has(Vector2i(8, 2)),
		"la poursuite coupe la rue du jardin")
	var fight := _reach(_blocked([SPOTTED]), _terminal([SPOTTED]))
	assert_true(fight.has(Vector2i(17, 2)) and fight.has(Vector2i(17, 3)))
	assert_false(fight.has(Vector2i(18, 2)) or fight.has(Vector2i(18, 3)),
		"le combat coupe toute la largeur de l'impasse")
	var guard := _reach(_blocked([SPOTTED, BEATEN]), _terminal([SPOTTED, BEATEN]))
	for x: int in [31, 32, 33]:
		assert_true(guard.has(Vector2i(x, 37)))
		assert_false(guard.has(Vector2i(x, 38)), "avant le départ du policier, ni passage ni (%d, 38)" % x)


func test_the_south_is_closed_by_the_guard_and_the_barriers_until_he_leaves() -> void:
	for state: int in 3:
		var flags: Array = _states[state]
		var reach := _reach(_blocked(flags), {})
		for x: int in [31, 32, 33]:
			assert_false(reach.has(Vector2i(x, 40)), "E%d : (%d, 40) fermé" % [state, x])
	var open := _reach(_blocked(_states[3]), {})
	for x: int in [31, 32, 33]:
		assert_true(open.has(Vector2i(x, 40)), "E3 : le bord sud est libre (%d)" % x)


func test_no_cell_is_ever_stuck_after_a_save_in_any_state() -> void:
	var sets: Array[Dictionary] = []
	for flags: Array in _states:
		sets.append(_reach(_blocked(flags), _terminal(flags)))
	for i: int in _states.size():
		for j: int in range(i + 1, _states.size()):
			var blocked := _blocked(_states[j])
			var later := _reach(blocked, {})
			for cell: Vector2i in sets[i]:
				assert_true(_free(cell, blocked) or _plan.cells_of("D").has(cell),
					"E%d → E%d : %s devient bloquée" % [i, j, cell])
				assert_true(later.has(cell) or _plan.cells_of("D").has(cell),
					"E%d → E%d : %s coupée de l'entrée" % [i, j, cell])


func test_the_scene_matches_the_variant_for_the_new_cells() -> void:
	var map := (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(map)
	var grid := map.get_grid()
	for x: int in range(6, 22):
		for y: int in [2, 3]:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_solid(cell), cell == Vector2i(9, 2) or cell == Vector2i(14, 2),
				"%s (pot et clôture seuls bloqués)" % cell)
	assert_false(grid.is_solid(Vector2i(14, 3)), "trou")
	assert_true(grid.is_solid(Vector2i(14, 2)), "clôture à côté du trou")
	assert_true(grid.is_solid(Vector2i(22, 3)), "arbre dense qui ferme l'impasse")
	for x: int in [31, 32, 33]:
		for y: int in [38, 39, 40]:
			assert_false(grid.is_solid(Vector2i(x, y)), "couloir sud (%d, %d)" % [x, y])
	for y: int in [38, 39]:
		assert_true(grid.is_solid(Vector2i(30, y)) and grid.is_solid(Vector2i(34, y)))
	var gates := 0
	for node: Node in map.find_children("*", "Node2D", true, false):
		if node is FlagGate:
			gates += 1
			assert_eq((node as FlagGate).if_flags.size() + (node as FlagGate).unless_flags.size(),
				1, "%s : un drapeau" % node.name)
	# J18 (T15) : la scène est construite sur la variante J18 (cumulative sur J14) : l'arbre à
	# couper de la sortie est s'ajoute ; J31 (31A) : la bouche fermée de la Grotte Azurée.
	assert_eq(gates, 4, "planche clouée, porte condamnée, arbre à couper, bouche de la grotte")
	map.free()
