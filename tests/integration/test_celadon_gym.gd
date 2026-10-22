extends GutTest
## Arène d'Erika (celadon_gym, jalon 20 T16, docs/tech/jalon-20.md §2.1, §2.8 ; dossier 23 §11) sur
## la vraie scène : **grille de la scène = grille fonctionnelle** `tools/plans/celadopole_arene.txt`,
## lumière `greenhouse`, sortie vers la ville (`from_gym_w|e`), bassins infranchissables, haies sur
## des cases bloquées, **E5 inévitable** (sa ligne couvre la case (8, 5), seul accès à la porte-haie
## (8, 4)), E1 à E4 évitables (un à un et ensemble), **Erika atteignable par le tour sans couper
## l'arbuste intérieur** (8, 10) qui n'ouvre qu'un raccourci. Dresseuses, Erika et scènes : T17.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/celadon_gym.tscn"
const PLAN_PATH := "res://tools/plans/celadopole_arene.txt"
const SIZE := Vector2i(17, 16)
const BUSH := Vector2i(8, 10)
const BUSH_FLAG := &"cut_celadon_gym_inner_bush"
const ENTRANCE := Vector2i(8, 14)
const DOOR_HEDGE := Vector2i(8, 4)
const ERIKA_FRONT := Vector2i(8, 3)
const WALKABLE := ".XW"

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


## Cases occupées par Erika et les Dresseuses (PNJ : solides pour le joueur), l'arbuste debout
## en plus si [param bush_standing].
func _terrain(bush_standing: bool, forbidden: Array[Vector2i] = []) -> GridWorld:
	var terrain := GridPaths.relief(_grid, SIZE)
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] in ["pnj", "dresseur"]:
			for cell: Vector2i in _plan.cells_at(id):
				terrain.set_solid(cell)
	terrain.set_solid(BUSH, bush_standing)
	for cell: Vector2i in forbidden:
		terrain.set_solid(cell)
	return terrain


## Cases vues par la Dresseuse [param id] : de sa case vers sa direction, [attr sight] cases, que
## le premier obstacle arrête.
func _line(id: String) -> Array[Vector2i]:
	var facing: Vector2i = {"left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP,
		"down": Vector2i.DOWN}[_plan.attr(id, "facing")]
	var cells: Array[Vector2i] = []
	var at := _plan.cell_of(id)
	for i: int in int(_plan.attr(id, "sight")):
		at += facing
		if _grid.is_solid(at):
			break
		cells.append(at)
	return cells


func test_metadata_light_shell_and_grid() -> void:
	assert_eq(_map.map_id, &"celadon_gym")
	assert_eq(_map.display_name, "Céladopole")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior)
	assert_eq(_map.light_profile, &"greenhouse")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"celadon_gym"), &"greenhouse")
	var profile := lighting.get_profile(&"greenhouse")
	assert_not_null(profile, "profil greenhouse")
	if profile != null:
		assert_false(profile.has_cast_shadow(), "sans ombre portée")
	assert_true(MapCatalog.load_interiors().has(&"celadon_gym"))
	assert_eq((_map.get_node(^"Shell") as Sprite2D).texture.get_size(), Vector2(SIZE * 96))
	assert_eq(_plan.walkable, ".X")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			# L'arbuste (W de la grille) est praticable dans `Ground` : sa FlagGate occupe la case.
			var solid := not _plan.is_walkable(cell) and cell != BUSH
			if _grid.is_solid(cell) != solid:
				mismatches += 1
				if mismatches <= 5:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/celadopole_arene.txt")


func test_exit_leads_to_the_town_with_two_arrivals() -> void:
	assert_eq(_map.get_spawn_cell(&"entrance"), ENTRANCE)
	var expected := {Vector2i(7, 14): &"from_gym_w", Vector2i(8, 14): &"from_gym_w",
		Vector2i(9, 14): &"from_gym_e"}
	for cell: Vector2i in expected:
		var out := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie %s" % cell)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"celadon_city", expected[cell]])
	assert_eq(_map.get_warps().size(), 3, "une seule sortie")
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	assert_eq(city.get_spawn_cell(&"from_gym_w"), Vector2i(10, 35))
	assert_eq(city.get_spawn_cell(&"from_gym_e"), Vector2i(11, 35))
	var door := city.get_warps().find_on_step(Vector2i(10, 34), Vector2i.UP)
	assert_not_null(door)
	if door != null:
		assert_eq([door.target_map, door.target_spawn], [&"celadon_gym", &"entrance"])


func test_basins_and_hedges_are_solid_and_hedge_objects_sit_on_solid_cells() -> void:
	for cell: Vector2i in _plan.cells_of("w"):
		assert_true(_grid.is_solid(cell), "bassin %s" % cell)
	for cell: Vector2i in _plan.cells_of("xj"):
		assert_true(_grid.is_solid(cell), "haie %s" % cell)
	var hedges := 0
	for child: Node in _map.get_node(^"Entities").get_children():
		var prop := child as WorldProp
		if prop == null:
			continue
		hedges += 1
		for cell: Vector2i in prop.get_solid_cells():
			assert_false(_plan.is_walkable(cell), "%s bloque la case praticable %s" % [prop.name,
				cell])
	assert_gt(hedges, 15, "haies et massifs posés")
	# Une seule ouverture dans la haie du fond : la porte-haie (8, 4).
	assert_false(_grid.is_solid(DOOR_HEDGE))
	for x: int in range(2, 15):
		if x != DOOR_HEDGE.x:
			assert_true(_grid.is_solid(Vector2i(x, 4)), "haie du fond (%d, 4)" % x)


func test_the_inner_bush_is_a_flag_gate_closing_only_a_shortcut() -> void:
	var gate := _map.get_node_or_null(^"Entities/GymInnerBush") as FlagGate
	assert_not_null(gate, "arbuste intérieur")
	if gate == null:
		return
	assert_eq(gate.unless_flags, [BUSH_FLAG] as Array[StringName])
	assert_eq(gate.blocking_cells, [BUSH] as Array[Vector2i])
	_map.apply_flag_gates(null)
	assert_true(_grid.is_occupied(BUSH), "debout : case occupée")
	var flags := StoryFlags.new()
	flags.set_flag(BUSH_FLAG)
	_map.apply_flag_gates(flags)
	assert_false(_grid.is_occupied(BUSH), "coupé : case libre")
	_map.apply_flag_gates(null)
	var point: InteractPoint = null
	for child: Node in _map.get_node(^"Interactables").get_children():
		point = child as InteractPoint
	assert_not_null(point)
	if point != null:
		assert_eq([point.get_cell(), point.dialogue_id, point.unless_flags],
			[BUSH, &"celadon_gym_inner_bush", [BUSH_FLAG] as Array[StringName]])


func test_erika_is_reachable_by_the_tour_without_cutting() -> void:
	var tour := GridPaths.distances(_terrain(true), [ENTRANCE])
	assert_true(tour.has(ERIKA_FRONT), "Erika atteignable sans couper l'arbuste intérieur")
	assert_true(tour.has(DOOR_HEDGE))
	var steps: int = tour[ERIKA_FRONT]
	gut.p("tour : %d pas jusqu'à Erika" % steps)
	assert_between(steps, 24, 40, "≈ 30 pas (dossier)")
	var shortcut := GridPaths.distances(_terrain(false), [ENTRANCE])
	assert_lt(int(shortcut[ERIKA_FRONT]), steps - 6, "le raccourci coupe nettement")
	# Le raccourci n'est jamais indispensable : tout l'intérieur se joint sans lui.
	for cell: Vector2i in _plan.cells_of(".X"):
		var occupied := false
		for id: String in _plan.positions:
			if _plan.positions[id]["kind"] in ["pnj", "dresseur"] \
					and _plan.cells_at(id).has(cell):
				occupied = true
		if not occupied:
			assert_true(tour.has(cell), "%s atteignable par le tour" % cell)


func test_e5_is_unavoidable_and_e1_to_e4_are_avoidable() -> void:
	var e5 := _line("dresseuse_e5")
	assert_true(e5.has(Vector2i(8, 5)), "la ligne d'E5 couvre (8, 5)")
	# Sans pouvoir franchir la ligne d'E5, la porte-haie et Erika sont hors d'atteinte, par le
	# tour comme par le raccourci.
	for standing: bool in [true, false]:
		var blocked := GridPaths.distances(_terrain(standing, e5), [ENTRANCE])
		assert_false(blocked.has(DOOR_HEDGE), "E5 inévitable (arbuste %s)" % standing)
		assert_false(blocked.has(ERIKA_FRONT))
	# E1 à E4 : le vestibule (7, 5), juste devant la ligne d'E5, reste atteignable en évitant
	# leurs lignes, chacune à son tour puis toutes ensemble.
	var goal := Vector2i(7, 5)
	var ids := ["dresseuse_e1", "dresseuse_e2", "dresseuse_e3", "dresseuse_e4"]
	var all_lines: Array[Vector2i] = []
	for id: String in ids:
		var line := _line(id)
		assert_false(line.is_empty(), "%s voit quelque chose" % id)
		all_lines.append_array(line)
		for standing: bool in [true, false]:
			var path := GridPaths.distances(_terrain(standing, line), [ENTRANCE])
			assert_true(path.has(goal), "%s évitable (arbuste %s)" % [id, standing])
	for standing: bool in [true, false]:
		var together := GridPaths.distances(_terrain(standing, all_lines), [ENTRANCE])
		assert_true(together.has(goal), "E1 à E4 évitables ensemble (arbuste %s)" % standing)
	# L'entrée de l'Arène n'est vue par personne.
	assert_false(all_lines.has(ENTRANCE))
	assert_eq(_plan.attr("dresseuse_e5", "mandatory"), "1")


func test_trainer_cells_are_free_and_never_cut_the_gym() -> void:
	var cells: Array[Vector2i] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] in ["pnj", "dresseur"]:
			cells.append_array(_plan.cells_at(id))
	assert_eq(cells.size(), 6, "Erika et cinq Dresseuses")
	for cell: Vector2i in cells:
		assert_false(_grid.is_solid(cell), "%s : case libre" % cell)
		assert_ne(cell, BUSH)
	# Erika (8, 2) et sa case de parole (8, 3) : au bout de la porte-haie, hors de la ligne d'E5.
	assert_eq(_plan.cell_of("erika"), Vector2i(8, 2))
	assert_false(_line("dresseuse_e5").has(ERIKA_FRONT))
