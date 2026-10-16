extends GutTest
## Carte vermilion_city (Carmin-sur-Mer, jalon 15 T14, docs/tech/jalon-15.md §2.1, §2.9, §2.11 ;
## dossier 18 §8, §17) sur la vraie scène : métadonnées et lumière, mer du port, **grille de la
## scène = grille fonctionnelle** `tools/plans/vermilion_city.txt` (exception du contrat du J16 :
## les cases `A` du jeune arbre sont occupées par son décor), raccords (Route 6, « Route 11 — À
## venir », sept portes), Arène et embarquement inatteignables, **contrat du J16** (navire absent
## si `ss_anne_departed`, arbuste retiré par `cut_vermilion_gym_bush` : ses cases se libèrent et
## la porte de l'Arène devient atteignable), habitants aux cases de la grille, budget de nœuds.
## Jalon 16 T15 : Arène et embarquement branchés (`vermilion_gym`, `ss_anne_main_deck`), examen
## de l'arbre = `cut_tree`, garde-fou de la passerelle et réplique du marin après le départ.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/vermilion_city.tscn"
const PLAN_PATH := "res://tools/plans/vermilion_city.txt"
const SIZE := Vector2i(64, 43)
const NODE_BUDGET := 3000
const ENTRY := Vector2i(31, 0)
const SHIP_FLAG := &"ss_anne_departed"
const BUSH_FLAG := &"cut_vermilion_gym_bush"
## Porte → [intérieur, spawn d'ici].
const DOORS := {
	Vector2i(7, 9): [&"vermilion_house_1", &"from_house_1"],
	Vector2i(15, 9): [&"vermilion_fan_club", &"from_fan_club"],
	Vector2i(16, 9): [&"vermilion_fan_club", &"from_fan_club"],
	Vector2i(24, 9): [&"vermilion_center", &"from_center"],
	Vector2i(25, 9): [&"vermilion_center", &"from_center"],
	Vector2i(37, 9): [&"vermilion_mart", &"from_mart"],
	Vector2i(38, 9): [&"vermilion_mart", &"from_mart"],
	Vector2i(8, 22): [&"vermilion_fisher_house", &"from_fisher_house"],
	Vector2i(56, 19): [&"vermilion_house_2", &"from_house_2"],
}

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


## Relief + eau + cases occupées (PNJ, arbre) de [param grid].
func _terrain(grid: GridWorld) -> GridWorld:
	var terrain := GridPaths.relief(grid, SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if grid.is_water(cell) or grid.is_occupied(cell):
				terrain.set_solid(cell)
	return terrain


func _reach(grid: GridWorld) -> Dictionary:
	var stops: Dictionary = {}
	for warp: Warp in _map.get_warps().get_all():
		if warp.trigger == Warp.Trigger.STEP_ON:
			stops[warp.cell] = true
	return GridPaths.distances(grid, [ENTRY], stops)


## Carte neuve dans l'arbre, drapeaux [param flags] appliqués comme à l'arrivée.
func _map_with(flags: Array[StringName]) -> GameMap:
	var map := (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var story := StoryFlags.new()
	for flag: StringName in flags:
		story.set_flag(flag)
	map.refresh_npcs(story)
	return map


# --- Métadonnées -------------------------------------------------------------------------

func test_metadata_light_zone_and_sea() -> void:
	assert_eq(_map.map_id, &"vermilion_city")
	assert_eq(_map.display_name, "Carmin-sur-Mer")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"vermilion_city"), &"golden_hour")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"vermilion_city"), &"vermilion_city")
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground)
	if ground != null:
		assert_not_null(ground.shore_mask, "mer peinte")
		assert_true(ground.square_shore, "quais à angles droits")
		assert_null(ground.water_texture, "la mer de Bourg Palette")
		assert_eq(GroundMask.shore_at(ground.shore_mask.get_image(), Vector2i(10, 38)),
			GroundMask.Kind.WATER)
	assert_true(_map.get_node(^"GroundDecals").get_child_count() > 0)


func test_scene_grid_is_the_functional_grid() -> void:
	var bush: Array[Vector2i] = _plan.cells_at("examen_arbre")
	# Panneaux : positions `bloque` de la grille, posées sur l'herbe.
	var signs: Array[Vector2i] = _plan.cells_at("panneau_ville") + _plan.cells_at(
		"panneau_arene") + _plan.cells_at("panneau_quai")
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark := _plan.at(cell)
			var water := mark == "W" or mark == "N"
			var ok := _grid.is_water(cell) == water and not _grid.is_tall_grass(cell)
			if bush.has(cell):
				# Contrat du J16 : praticable dessous, occupée par l'arbre.
				ok = ok and not _grid.is_solid(cell) and _grid.is_occupied(cell)
			elif not water:
				ok = ok and _grid.is_solid(cell) == (not _plan.is_walkable(cell)
					or signs.has(cell))
			if not ok:
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s, eau %s" % [cell, mark,
						_grid.is_solid(cell), _grid.is_water(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/vermilion_city.txt")
	assert_eq(_plan.walkable, ".=pqgED")


# --- Passages ----------------------------------------------------------------------------

func test_north_edge_leads_to_route_6() -> void:
	var suffixes := ["w", "c", "e"]
	for i: int in 3:
		var cell := Vector2i(30 + i, 0)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.UP)
		assert_not_null(warp, "raccord nord %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_6", StringName("from_vermilion_" + suffixes[i]), Vector2i.UP])
		assert_eq(_map.get_spawn_cell(StringName("from_route_6_" + suffixes[i])), cell)


func test_east_edge_is_route_11_coming_soon() -> void:
	var suffixes := ["n", "c", "s"]
	for i: int in 3:
		var cell := Vector2i(63, 11 + i)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "raccord est %s" % cell)
		if warp != null:
			assert_true(warp.is_coming_soon(), "Route 11 — À venir")
			assert_eq(warp.coming_soon, "Route 11")
			assert_eq([warp.target_spawn, warp.facing],
				[StringName("from_route_11_" + suffixes[i]), Vector2i.LEFT])
		assert_eq(_map.get_spawn_cell(StringName("from_route_11_" + suffixes[i])), cell)
	assert_true(_reach(_terrain(_grid)).has(Vector2i(63, 12)), "sortie est atteignable")


func test_doors_lead_into_the_interiors_and_back() -> void:
	var dist := _reach(_terrain(_grid))
	for door: Vector2i in DOORS:
		var info: Array = DOORS[door]
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp, "porte %s" % door)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn], [info[0], &"entrance"])
		assert_true(dist.has(door), "porte %s atteignable" % door)
		assert_true(_map.has_spawn(info[1]), "spawn %s" % info[1])
		var room := (load(MapCatalog.scene_path(info[0])) as PackedScene).instantiate() \
			as GameMap
		var back := room.get_warps().find_on_push(Vector2i(7, 8), Vector2i.DOWN)
		assert_not_null(back, "%s : sortie" % info[0])
		if back != null:
			assert_eq([back.target_map, back.target_spawn], [&"vermilion_city", info[1]])
		room.free()


func test_gym_and_boarding_lead_inside_and_are_unreachable() -> void:
	var dist := _reach(_terrain(_grid))
	for door: Vector2i in [Vector2i(49, 9), Vector2i(50, 9)]:
		var warp := _map.get_warps().find_on_step(door, Vector2i.UP)
		assert_not_null(warp)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.coming_soon],
				[&"vermilion_gym", &"entrance", ""], "Arène branchée (J16 T15)")
		assert_false(dist.has(door), "porte de l'Arène derrière l'arbre")
	for cell: Vector2i in _plan.cells_at("embarquement"):
		var warp := _map.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_not_null(warp)
		if warp != null:
			assert_eq(warp.target_map, &"ss_anne_main_deck", "embarquement branché (J16 T15)")
			assert_false(warp.is_coming_soon())
		assert_false(dist.has(cell), "embarquement derrière le marin")
		assert_false(dist.has(cell + Vector2i.UP), "passerelle gardée")
	assert_eq(_map.get_warps().size(), 3 + 3 + 11 + 2, "nord, est, onze portes, embarquement")


# --- Contrat du J16 ------------------------------------------------------------------------

func test_bush_blocks_the_gym_until_cut() -> void:
	var map := _map_with([])
	var gate := map.get_node(^"Entities/GymTree") as FlagGate
	assert_not_null(gate, "jeune arbre, objet séparé")
	assert_true(gate.visible)
	assert_eq(gate.unless_flags, [BUSH_FLAG] as Array[StringName])
	assert_not_null(gate.get_node_or_null(^"YoungTree"))
	for cell: Vector2i in _plan.cells_at("examen_arbre"):
		assert_true(map.get_grid().is_occupied(cell), "arbre en %s" % cell)
		var examine := map.get_interactions().find(cell, Vector2i.UP)
		assert_not_null(examine, "EXAMINER l'arbre (T-29)")
		if examine != null:
			assert_eq(examine.dialogue_id, &"cut_tree", "Coupe (J16 T15)")
			assert_eq(examine.unless_flags, [BUSH_FLAG] as Array[StringName])
	var cut := _map_with([BUSH_FLAG])
	assert_false((cut.get_node(^"Entities/GymTree") as FlagGate).visible, "arbre coupé")
	var stops: Dictionary = {}
	for cell: Vector2i in _plan.cells_at("examen_arbre"):
		assert_false(cut.get_grid().is_occupied(cell), "case %s libérée" % cell)
	var dist := GridPaths.distances(_terrain(cut.get_grid()), [ENTRY], stops)
	assert_true(dist.has(Vector2i(49, 9)), "porte de l'Arène atteignable une fois l'arbre coupé")


func test_ship_is_a_separate_object_gone_when_departed() -> void:
	var map := _map_with([])
	var ship := map.get_node(^"Entities/SsAnne") as FlagGate
	assert_not_null(ship, "S.S. Anne")
	assert_eq(ship.unless_flags, [SHIP_FLAG] as Array[StringName])
	assert_eq(ship.get_child_count(), 3, "proue, milieu, poupe")
	for child: Node in ship.get_children():
		assert_true((child as WorldProp).get_footprint().is_empty(), "%s sans emprise" % child.name)
	assert_true(ship.visible)
	var gangway := map.get_node(^"GroundDecals/Gangway") as FlagGate
	assert_not_null(gangway, "passerelle")
	assert_true(gangway.visible)
	var departed := _map_with([SHIP_FLAG])
	assert_false((departed.get_node(^"Entities/SsAnne") as FlagGate).visible, "navire parti")
	assert_false((departed.get_node(^"GroundDecals/Gangway") as FlagGate).visible)
	for cell: Vector2i in _plan.cells_of("N"):
		assert_true(departed.get_grid().is_water(cell), "la mer reste en %s" % cell)


## Jalon 16 T15 : garde-fou sans image sur la passerelle et l'accès (31..32, 27..28), seulement
## après le départ ; jamais d'autre case occupée.
func test_gangway_guard_after_departure() -> void:
	var cells: Array[Vector2i] = [Vector2i(31, 27), Vector2i(32, 27), Vector2i(31, 28),
		Vector2i(32, 28)]
	var docked := _map_with([])
	var guard := docked.get_node(^"Entities/GangwayGuard") as FlagGate
	assert_not_null(guard, "garde-fou")
	assert_eq(guard.get_child_count(), 0, "sans image")
	assert_eq(guard.if_flags, [SHIP_FLAG] as Array[StringName])
	assert_eq(guard.blocking_cells, cells)
	for cell: Vector2i in cells:
		assert_false(docked.get_grid().is_occupied(cell), "navire à quai : %s libre" % cell)
	var departed := _map_with([SHIP_FLAG])
	for cell: Vector2i in cells:
		assert_true(departed.get_grid().is_occupied(cell), "après le départ : %s gardée" % cell)
	var dist := _reach(_terrain(departed.get_grid()))
	for cell: Vector2i in cells:
		assert_false(dist.has(cell), "%s inatteignable après le départ" % cell)
	assert_true(dist.has(departed.get_spawn_cell(&"dock")), "le quai reste praticable")
	assert_eq(departed.get_spawn_cell(&"dock"), Vector2i(31, 24))


func test_sailor_identical_with_or_without_the_ticket() -> void:
	for flags: Array[StringName] in [[] as Array[StringName], [&"got_ss_ticket"] as
			Array[StringName]]:
		var map := _map_with(flags)
		var sailor := map.get_npc(&"sailor")
		assert_not_null(sailor, "marin (%s)" % [flags])
		if sailor != null:
			assert_eq(sailor.get_cell(), _plan.cell_of("marin"))
			assert_eq(sailor.get_spec().dialogue, &"vermilion_sailor")
	# Jalon 16 T15 : après le départ, le marin est en (31, 26) avec DEP-03.
	var departed := _map_with([&"got_ss_ticket", SHIP_FLAG])
	var back := departed.get_npc(&"sailor")
	assert_not_null(back, "marin après le départ")
	if back != null:
		assert_eq(back.get_cell(), Vector2i(31, 26))
	var library := DialogueLibrary.new()
	library.load_dir()
	var sailor_line := library.get_dialogue(&"vermilion_sailor")
	assert_eq(sailor_line.variants.size(), 4, "DEP-03, TXT-01 (2 fois), puis TXT-02 sans condition")
	assert_eq(sailor_line.variants[0].if_flags, [SHIP_FLAG] as Array[StringName])
	assert_eq(sailor_line.variants[0].pages[0].text, "Le S.S. Anne a pris le large.")
	assert_true(sailor_line.variants[3].if_flags.is_empty())


# --- Habitants et décor --------------------------------------------------------------------

func test_people_follow_the_grid() -> void:
	var expected := {
		&"sailor": ["marin", &"sailor"], &"docker_1": ["docker_1", &"docker"],
		&"docker_2": ["docker_2", &"docker"], &"resident": ["habitante", &"lass"],
		&"kid": ["enfant", &"kid"], &"old_man": ["vieil_habitant", &"old_man"],
		&"pidgey_1": ["pidgey_1", &"pokemon/pidgey"], &"pidgey_2": ["pidgey_2", &"pokemon/pidgey"],
	}
	var roster := NpcRoster.load_for_map(&"vermilion_city")
	assert_eq(roster.get_all().size(), expected.size())
	for key: StringName in expected:
		var spec := roster.get_spec(key)
		assert_not_null(spec, String(key))
		if spec == null:
			continue
		var info: Array = expected[key]
		assert_eq(spec.cell, _plan.cell_of(info[0]), String(key))
		assert_eq(spec.sprite, info[1], String(key))
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
		if _plan.attr(info[0], "facing") != "":
			assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(info[0], "facing")))


func test_signs_and_arrival() -> void:
	var expected := {
		&"vermilion_city_sign": [Vector2i(29, 2), Vector2i.LEFT],
		&"vermilion_gym_sign": [Vector2i(47, 10), Vector2i.UP],
		&"vermilion_dock_sign": [Vector2i(34, 23), Vector2i.UP],
	}
	var found := 0
	for point: Node in _map.get_node(^"Interactables").get_children():
		var interact := point as InteractPoint
		if expected.has(interact.dialogue_id):
			found += 1
			assert_eq([interact.get_cell(), interact.facing], expected[interact.dialogue_id])
	assert_eq(found, 3, "trois panneaux")
	var arrival := _map.get_triggers().find_on_step(Vector2i(31, 1), Vector2i.DOWN)
	assert_not_null(arrival, "arrivée à Carmin")
	if arrival != null:
		assert_eq(arrival.cutscene_id, &"vermilion_arrival")


func test_props_never_block_a_walkable_cell() -> void:
	var blocking := _plan.blocking_cells()
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			if child is WorldProp:
				for cell: Vector2i in (child as WorldProp).get_solid_cells():
					assert_true(not _plan.is_walkable(cell) or blocking.has(cell),
						"%s bloque la case praticable %s" % [child.name, cell])


func test_dock_is_planked_and_bordered() -> void:
	var planks := 0
	var borders := 0
	for child: Node in _map.get_node(^"GroundDecals").get_children():
		if String(child.name).begins_with("Planks"):
			planks += 1
			assert_true((child as Sprite2D).region_enabled)
		if child is Sprite2D and String((child as Sprite2D).texture.resource_path).contains(
				"relief_quai_bois_"):
			borders += 1
	assert_eq(planks, 4, "quai, deux pontons, passerelle")
	assert_gt(borders, 40, "bords de quai en bois")


func test_node_budget_keeps_the_dock_in_the_map() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("vermilion_city : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET, "≤ 3 000 nœuds : pas de vermilion_dock (F-12)")
