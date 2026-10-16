extends GutTest
## Carte route_2_east (jalon 17 T19, docs/tech/jalon-17.md §2.1, §2.13 ; dossier 20 §3.4) :
## métadonnées, **grille de la scène = grille fonctionnelle** `tools/plans/route_2_east.txt` (l'arbuste
## `A` est praticable : il est occupé par sa `FlagGate`), passages (bouche de la Cave, porte du
## poste, bord ouest), 12 pas de la bouche au poste **sans Coupe**, partie sud et bord ouest
## inatteignables sans `cut_route_2_east_bush` et atteignables avec, panneau T-11, point d'examen
## de l'arbuste (Coupe du J16, T23 : lu des deux côtés, retiré avec lui), objets peints sur des
## cases bloquées, budget de nœuds.

const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_PATH := "res://game/world/maps/route_2_east.tscn"
const PLAN_PATH := "res://tools/plans/route_2_east.txt"
const SIZE := Vector2i(16, 48)
const BUSH_FLAG := &"cut_route_2_east_bush"
const BUSH_CELLS: Array[Vector2i] = [Vector2i(6, 21), Vector2i(7, 21)]
const MOUTH_PUSH: Array[Vector2i] = [Vector2i(6, 3), Vector2i(7, 3)]
const POST_DOOR := Vector2i(11, 11)
const WEST_EDGE: Array[Vector2i] = [Vector2i(0, 43), Vector2i(0, 44)]
const NODE_BUDGET := 900

var _map: GameMap
var _plan: PlanGrid


func before_each() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	_map.refresh_npcs(StoryFlags.new())


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func _stops() -> Dictionary:
	var stops: Dictionary = {POST_DOOR: true}
	for cell: Vector2i in MOUTH_PUSH + WEST_EDGE:
		stops[cell] = true
	return stops


func _reach(flags: Array[StringName]) -> Dictionary:
	_map.refresh_npcs(_flags(flags))
	return GridPaths.distances(_map.get_grid(), [_map.get_spawn_cell(&"from_cave_w")], _stops())


func test_metadata_light_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"route_2_east")
	assert_eq(_map.display_name, "Route 2", "le couloir garde le titre de la Route 2")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"forest")
	assert_false(_map.interior)
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"route_2_east"), &"route_2", "une seule Route 2 dans la Carte")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var grid := _map.get_grid()
	var signs: Array[Vector2i] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "panneau":
			signs.append_array(_plan.cells_at(id))
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var walkable := _plan.is_walkable(cell) or mark == "A"
			var expected_solid := not walkable or signs.has(cell)
			var ok := grid.is_solid(cell) == expected_solid and not grid.is_tall_grass(cell) \
				and grid.get_ledge(cell) == GridWorld.Ledge.NONE
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, mark, grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_2_east.txt")
	assert_eq(_plan.cells_of("A"), BUSH_CELLS, "l'arbuste ferme les deux cases du goulet")


func test_passages() -> void:
	var warps := _map.get_warps()
	var sides := ["w", "e"]
	for i: int in MOUTH_PUSH.size():
		var mouth := warps.find_on_step(MOUTH_PUSH[i], Vector2i.UP)
		assert_not_null(mouth, "bouche %s" % MOUTH_PUSH[i])
		if mouth != null:
			assert_eq(mouth.trigger, Warp.Trigger.STEP_ON)
			assert_eq(mouth.target_map, &"digletts_cave")
			assert_eq(mouth.target_spawn, StringName("from_route_2_east_" + sides[i]))
			assert_eq(mouth.facing, Vector2i.DOWN, "on arrive dans la Cave vers le sud")
		assert_eq(_map.get_spawn_cell(StringName("from_cave_" + sides[i])),
			MOUTH_PUSH[i] + Vector2i.DOWN)
	var door := warps.find_on_step(POST_DOOR, Vector2i.UP)
	assert_not_null(door, "porte du poste")
	if door != null:
		assert_eq(door.target_map, &"route_2_east_gate")
		assert_eq(door.target_spawn, &"entrance")
		assert_eq(door.facing, Vector2i.UP)
	assert_eq(_map.get_spawn_cell(&"from_gate"), POST_DOOR + Vector2i.DOWN)
	var west := ["n", "s"]
	for i: int in WEST_EDGE.size():
		var edge := warps.find_on_push(WEST_EDGE[i], Vector2i.LEFT)
		assert_not_null(edge, "bord ouest %s" % WEST_EDGE[i])
		if edge != null:
			assert_eq(edge.target_map, &"route_2")
			assert_eq(edge.target_spawn, StringName("from_route_2_east_" + west[i]))
		assert_eq(_map.get_spawn_cell(StringName("from_route_2_" + west[i])), WEST_EDGE[i])
	var gate_map := (load(MapCatalog.scene_path(&"route_2_east_gate")) as PackedScene) \
		.instantiate() as GameMap
	assert_true(gate_map.has_spawn(&"entrance"))
	for warp: Warp in gate_map.get_warps().get_all():
		assert_eq(warp.target_map, &"route_2_east")
		assert_eq(warp.target_spawn, &"from_gate")
	gate_map.free()


func test_the_cave_round_trip() -> void:
	var cave := (load(MapCatalog.scene_path(&"digletts_cave")) as PackedScene).instantiate() \
		as GameMap
	for spawn: StringName in [&"from_route_2_east_w", &"from_route_2_east_e"]:
		assert_true(cave.has_spawn(spawn), String(spawn))
	var back := 0
	for warp: Warp in cave.get_warps().get_all():
		if warp.target_map == &"route_2_east":
			back += 1
			assert_true(_map.has_spawn(warp.target_spawn), String(warp.target_spawn))
	assert_eq(back, 2, "deux cases de la bouche nord ramènent ici")
	cave.free()


func test_the_post_is_twelve_steps_from_the_mouth_without_cutting() -> void:
	var dist := _reach([])
	# 12 pas de la case d'arrivée devant la bouche (7, 4) à la case devant la porte du poste ; la
	# porte elle-même est au 13e (`plan_check_j17` : « porte atteinte en 13 pas »).
	var from_gate := _map.get_spawn_cell(&"from_gate")
	assert_eq(int(dist.get(from_gate, -1)), 13, "depuis (6, 4)")
	var east := GridPaths.distances(_map.get_grid(), [_map.get_spawn_cell(&"from_cave_e")],
		_stops())
	assert_eq(int(east.get(from_gate, -1)), 12, "12 pas de la bouche au poste")
	assert_eq(int(east.get(POST_DOOR, -1)), 13, "la porte est au pas suivant")
	assert_true(dist.has(_map.get_spawn_cell(&"from_cave_e")))
	assert_false(dist.has(Vector2i(6, 22)), "pas de Coupe : le goulet est fermé")


func test_the_south_needs_the_bush_flag() -> void:
	var closed := _reach([])
	var south: Array[Vector2i] = [Vector2i(6, 23), Vector2i(7, 38), Vector2i(0, 43),
		Vector2i(0, 44), Vector2i(4, 25)]
	for cell: Vector2i in south:
		assert_false(closed.has(cell), "%s inatteignable sans le drapeau" % cell)
	for cell: Vector2i in BUSH_CELLS:
		assert_true(_map.get_grid().is_occupied(cell), "arbuste en %s" % cell)
		assert_false(closed.has(cell))
	var open := _reach([BUSH_FLAG])
	for cell: Vector2i in south + BUSH_CELLS:
		assert_true(open.has(cell), "%s atteignable avec le drapeau" % cell)
	for cell: Vector2i in BUSH_CELLS:
		assert_false(_map.get_grid().is_occupied(cell), "case %s libérée" % cell)
	assert_eq(int(open.get(Vector2i(0, 44), -1)), 45 + 1, "bord ouest : 45 pas (+ la rangée)")


func test_the_bush_is_a_flag_gate_with_its_cut_examine_point() -> void:
	var gate := _map.get_node_or_null(^"Entities/CorridorBush") as FlagGate
	assert_not_null(gate, "arbuste du goulet")
	if gate == null:
		return
	assert_eq(gate.unless_flags, [BUSH_FLAG] as Array[StringName])
	assert_eq(gate.blocking_cells, BUSH_CELLS)
	assert_true(gate.visible)
	var bush := gate.get_node_or_null(^"Bush") as WorldProp
	assert_not_null(bush, "décor de l'arbuste")
	if bush != null:
		assert_eq(bush.scene_file_path.get_file().get_basename(), "prop_jeune_arbre_arene_01",
			"l'arbuste du J16")
	# T23 : examiné du nord comme du sud, dialogue de Coupe ; retiré avec l'arbuste.
	var cut := _flags([BUSH_FLAG])
	for cell: Vector2i in BUSH_CELLS:
		for from: Vector2i in [cell + Vector2i.UP, cell + Vector2i.DOWN]:
			var found := InteractionFinder.find(_map.get_grid(), _map.get_interactions(), from,
				cell - from)
			assert_not_null(found, "arbuste examiné depuis %s" % from)
			if found != null:
				assert_eq(found.kind, Interaction.Kind.EXAMINE)
				assert_eq(found.dialogue_id, &"route_2_east_bush")
				assert_true(found.is_available(StoryFlags.new()), "avant la coupe")
				assert_false(found.is_available(cut), "plus de point une fois coupé")
	_map.refresh_npcs(cut)
	assert_false(gate.visible, "arbuste coupé : retiré")


func test_the_cave_sign_is_read_from_the_south() -> void:
	var from := Vector2i(9, 6)
	var found := InteractionFinder.find(_map.get_grid(), _map.get_interactions(), from,
		Vector2i.UP)
	assert_not_null(found, "panneau T-11 lu depuis (9, 6) tourné ↑")
	if found != null:
		assert_eq(found.kind, Interaction.Kind.EXAMINE)
		assert_eq(found.dialogue_id, &"route_2_east_cave_sign")
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	assert_true(dialogues.has_dialogue(&"route_2_east_cave_sign"))


func test_painted_props_sit_on_blocked_cells() -> void:
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if not child is WorldProp:
				continue
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				assert_false(_plan.is_walkable(cell) and not _plan.blocking_cells().has(cell),
					"%s sur %s praticable" % [child.name, cell])
	var post := _map.get_entities().get_node_or_null(^"ResearchPost") as WorldProp
	assert_not_null(post, "poste")
	if post != null:
		assert_eq(post.get_solid_cells().size(), _plan.cells_of("P").size())
		for cell: Vector2i in post.get_solid_cells():
			assert_eq(_plan.at(cell), "P")
	assert_not_null(_map.get_entities().get_node_or_null(^"CaveMouth"), "bouche de la Cave")


func test_no_tall_grass_no_trainer_no_encounter() -> void:
	var grid := _map.get_grid()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			assert_false(grid.is_tall_grass(Vector2i(x, y)))
	assert_eq(_map.get_node(^"Triggers").get_child_count(), 0)


func test_node_budget() -> void:
	var map := (load(MAP_PATH) as PackedScene).instantiate()
	var total := GridPaths.count_nodes(map)
	map.free()
	assert_lte(total, NODE_BUDGET, "nœuds de la scène")
	gut.p("route_2_east : %d nœuds" % total)
