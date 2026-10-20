extends GutTest
## Casino de Céladopole (celadon_game_corner, jalon 20 T20, docs/tech/jalon-20.md §2.1, §2.2,
## §2.6 ; dossier 23 §12) sur la vraie scène : **grille de la scène = grille fonctionnelle**
## `tools/plans/casino.txt`, lumière, sorties vers la ville (`from_casino_w|e`), 56 machines
## solides et examinables depuis les allées (texte 39), **escalier du repaire inatteignable sans
## l'interrupteur** (mur coulissant), puis praticable et menant au B1F. L'affiche, le Rocket, les
## cinq PNJ et la scène de l'interrupteur : T21.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/celadon_game_corner.tscn"
const PLAN_PATH := "res://tools/plans/casino.txt"
const SIZE := Vector2i(20, 18)
const STAIRS := Vector2i(17, 4)
const SWITCH := &"game_corner_switch"
const ENTRANCE := Vector2i(15, 16)

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


func after_each() -> void:
	_map.apply_flag_gates(null)


func test_metadata_light_and_shell() -> void:
	assert_eq(_map.map_id, &"celadon_game_corner")
	assert_eq(_map.display_name, "Céladopole")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior)
	assert_eq(_map.light_profile, &"interior_warm")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"celadon_game_corner"), &"interior_warm")
	assert_true(MapCatalog.load_interiors().has(&"celadon_game_corner"))
	assert_eq((_map.get_node(^"Shell") as Sprite2D).texture.get_size(), Vector2(SIZE * 96))
	assert_lte(GridPaths.count_nodes(_map), 3000)
	# Halos néon (couper « Réduire les animations » : le type vacille).
	var glows := _map.get_node(^"Glows").get_children()
	assert_eq(glows.size(), 4)
	for glow: Node in glows:
		assert_eq((glow as LightGlow).glow_type, &"neon")


func test_scene_grid_equals_the_functional_grid() -> void:
	assert_eq(Vector2i(_plan.width, _plan.height), SIZE)
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			# L'escalier (S) est praticable dans `Ground` : le mur coulissant occupe la case.
			var solid := not _plan.is_walkable(cell) and _plan.at(cell) != "S"
			if _grid.is_solid(cell) != solid:
				mismatches += 1
				if mismatches <= 5:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/casino.txt")


func test_exit_and_entrance() -> void:
	assert_eq(_map.get_spawn_cell(&"entrance"), ENTRANCE)
	assert_eq(_map.get_spawn_cell(&"from_hideout"), Vector2i(17, 5))
	var expected := {Vector2i(15, 17): &"from_casino_w", Vector2i(16, 17): &"from_casino_e"}
	for cell: Vector2i in expected:
		var out := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie %s" % cell)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"celadon_city", expected[cell]])
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	assert_eq(city.get_spawn_cell(&"from_casino_w"), Vector2i(39, 33))
	assert_eq(city.get_spawn_cell(&"from_casino_e"), Vector2i(40, 33))
	# La porte du Casino de la ville mène à la carte (plus de « à venir »).
	for x: int in [39, 40]:
		var door := city.get_warps().find_on_step(Vector2i(x, 32), Vector2i.UP)
		assert_not_null(door, "porte (%d, 32)" % x)
		if door != null:
			assert_false(door.is_coming_soon())
			assert_eq([door.target_map, door.target_spawn], [&"celadon_game_corner", &"entrance"])


func test_machines_are_solid_and_examinable_from_the_aisles() -> void:
	var machines := _plan.cells_of("M")
	assert_eq(machines.size(), 56)
	var seen := 0
	for cell: Vector2i in machines:
		assert_true(_grid.is_solid(cell), "machine %s" % cell)
		var found := _map.get_interactions().get_at(cell)
		assert_eq(found.size(), 1, "machine %s examinable" % cell)
		if found.size() == 1:
			seen += 1
			assert_eq(found[0].dialogue_id, &"game_corner_machine")
	assert_eq(seen, 56)
	# Depuis une allée : le joueur en (2, 9) face à l'ouest lit la machine (1, 9).
	assert_not_null(_map.get_interactions().find(Vector2i(1, 9), Vector2i.LEFT))
	assert_not_null(_map.get_interactions().find(Vector2i(6, 12), Vector2i.RIGHT))
	# Texte 39 du dossier.
	var library := DialogueLibrary.new()
	library.load_dir()
	assert_true(library.has_dialogue(&"game_corner_machine"))


func test_stairs_are_unreachable_without_the_switch() -> void:
	var gate := _map.get_node_or_null(^"Entities/SlidingWall") as FlagGate
	assert_not_null(gate, "mur coulissant")
	if gate == null:
		return
	assert_eq(gate.unless_flags, [SWITCH] as Array[StringName])
	assert_eq(gate.blocking_cells, [STAIRS] as Array[Vector2i])
	# Sans l'interrupteur : la case de l'escalier est occupée, la coursive reste libre.
	_map.apply_flag_gates(null)
	assert_true(_grid.is_occupied(STAIRS), "mur debout : case occupée")
	var terrain := GridPaths.relief(_grid, SIZE)
	terrain.set_solid(STAIRS, true)
	var reach := GridPaths.distances(terrain, [ENTRANCE])
	assert_false(reach.has(STAIRS), "escalier inatteignable sans l'interrupteur")
	assert_true(reach.has(Vector2i(17, 5)), "la coursive reste accessible")
	assert_true(reach.has(Vector2i(9, 5)), "devant l'affiche : case de l'interrupteur")
	# Avec : la case est libre et l'escalier mène au B1F.
	var flags := StoryFlags.new()
	flags.set_flag(SWITCH)
	_map.apply_flag_gates(flags)
	assert_false(_grid.is_occupied(STAIRS), "mur écarté : case libre")
	assert_false(_grid.is_solid(STAIRS))
	var open := GridPaths.distances(GridPaths.relief(_grid, SIZE), [ENTRANCE])
	assert_true(open.has(STAIRS), "escalier atteignable après l'interrupteur")
	var warp := _map.get_warps().find_on_step(STAIRS, Vector2i.UP)
	assert_not_null(warp, "escalier")
	if warp != null:
		assert_eq([warp.target_map, warp.target_spawn, warp.direction, warp.facing],
			[&"rocket_hideout_b1f", &"from_casino", Vector2i.ZERO, Vector2i.DOWN])
	var hideout := (load(MapCatalog.scene_path(&"rocket_hideout_b1f")) as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(hideout)
	assert_eq(hideout.get_spawn_cell(&"from_casino"), Vector2i(21, 3))
	assert_not_null(hideout.get_warps().find_on_step(Vector2i(21, 2), Vector2i.UP))


func test_wall_hides_the_stairs_only_while_standing() -> void:
	var gate := _map.get_node(^"Entities/SlidingWall") as FlagGate
	_map.apply_flag_gates(null)
	assert_true(gate.visible, "sans drapeau : le mur est affiché")
	var flags := StoryFlags.new()
	flags.set_flag(SWITCH)
	_map.apply_flag_gates(flags)
	assert_false(gate.visible, "interrupteur levé : le mur a disparu")
