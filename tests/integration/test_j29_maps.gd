extends GutTest
## Cartes du jalon 29 (`docs/tech/jalon-29.md` §2.1) : chaque carte suit sa grille de
## `tools/plans/` (praticable, eau surfable, niveaux de sol de la Route Victoire), ses passages
## visent une carte et un point d'apparition existants, ses rochers, trous, interrupteurs et
## barrières sont ceux de la grille ; zones, grottes, lumière, intérieurs déclarés.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
## Carte → grille (cartes construites par tools/build_j29.gd).
const OUTDOOR: Dictionary = {
	&"route_22_west": "route_22_ouest",
	&"route_23": "route_23",
	&"victory_road_1f": "route_victoire_1f",
	&"victory_road_2f": "route_victoire_2f",
	&"victory_road_3f": "route_victoire_3f",
	&"indigo_plateau": "plateau_indigo",
}
const ALL_MAPS: Array[StringName] = [&"route_22_west", &"route_22_gate", &"route_23",
	&"victory_road_1f", &"victory_road_2f", &"victory_road_3f", &"indigo_plateau",
	&"indigo_plateau_lobby"]


func _plan(name: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % name), plan.error)
	return plan


func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func test_every_map_follows_its_grid() -> void:
	for map_id: StringName in OUTDOOR:
		var plan := _plan(OUTDOOR[map_id])
		var map := _map(map_id)
		assert_eq(map.map_id, map_id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		var grid := map.get_grid()
		var blocked: Array[Vector2i] = plan.blocking_cells()
		var diffs: Array[String] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var char: String = plan.at(cell)
				var free := not grid.is_solid(cell) and not grid.is_water(cell)
				var expected := plan.is_walkable(cell) and char != "w"
				# Positions bloquantes de la grille : PNJ et objets (occupants, pas des murs),
				# panneaux (cases bloquées), rochers, barrières (FlagGate).
				if blocked.has(cell):
					continue
				if free != expected:
					diffs.append("%s « %s »" % [cell, char])
				if char == "w" and not grid.is_surfable(cell):
					diffs.append("%s eau non surfable" % cell)
		assert_eq(diffs.size(), 0, "%s : %s" % [map_id, ", ".join(diffs.slice(0, 10))])


func test_victory_road_ground_levels() -> void:
	for map_id: StringName in [&"victory_road_1f", &"victory_road_2f", &"victory_road_3f"]:
		var plan := _plan(OUTDOOR[map_id])
		var grid := _map(map_id).get_grid()
		var wrong := 0
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var expected := GridWorld.Level.ANY
				match plan.at(cell):
					".", "E":
						expected = GridWorld.Level.LOW
					":":
						expected = GridWorld.Level.HIGH
					"=":
						expected = GridWorld.Level.STAIRS
				if grid.get_level(cell) != expected:
					wrong += 1
		assert_eq(wrong, 0, "%s : niveaux de sol" % map_id)


## Du sol bas, on ne monte au sol haut que par un escalier (RB : collisions par paires).
func test_levels_block_a_direct_step_between_low_and_high() -> void:
	var plan := _plan("route_victoire_1f")
	var grid := _map(&"victory_road_1f").get_grid()
	var checked := 0
	for y: int in plan.height - 1:
		for x: int in plan.width:
			var a := Vector2i(x, y)
			var b := Vector2i(x, y + 1)
			if plan.at(a) + plan.at(b) in [".:", ":."]:
				checked += 1
				assert_false(grid.can_enter(b, Vector2i.DOWN), "%s → %s" % [a, b])
	assert_gt(checked, 0, "des contacts bas / haut existent au 1F")


func test_warps_follow_the_grids_and_reach_existing_spawns() -> void:
	for map_id: StringName in OUTDOOR:
		var plan := _plan(OUTDOOR[map_id])
		var map := _map(map_id)
		var expected := 0
		for id: String in plan.positions:
			var kind: String = plan.positions[id]["kind"]
			if kind != "warp" and kind != "echelle":
				continue
			for cell: Vector2i in plan.cells_at(id):
				expected += 1
				var found: Warp = null
				for warp: Warp in map.get_warps().get_all():
					if warp.cell == cell:
						found = warp
				assert_not_null(found, "%s : %s en %s" % [map_id, id, cell])
				if found != null:
					assert_eq("%s:%s" % [found.target_map, found.target_spawn],
						plan.attr(id, "vers"), "%s %s" % [map_id, id])
		var falls := 0
		for warp: Warp in map.get_warps().get_all():
			if warp.trigger == Warp.Trigger.FALL:
				falls += 1
		assert_eq(map.get_warps().size() - falls, expected, "%s : aucun autre passage" % map_id)
	for map_id: StringName in ALL_MAPS:
		var map := _map(map_id)
		for warp: Warp in map.get_warps().get_all():
			if warp.target_map.is_empty():
				continue
			assert_true(MapCatalog.has_map(warp.target_map), "%s → %s" % [map_id, warp.target_map])
			if MapCatalog.has_map(warp.target_map):
				var target := _map(warp.target_map)
				assert_true(target.has_spawn(warp.target_spawn), "%s → %s:%s" % [map_id,
					warp.target_map, warp.target_spawn])


func test_boulder_setups_follow_the_grids() -> void:
	for map_id: StringName in [&"victory_road_1f", &"victory_road_2f", &"victory_road_3f"]:
		var plan := _plan(OUTDOOR[map_id])
		var map := _map(map_id)
		var setup := map.get_node_or_null(NodePath(BoulderSetup.NODE_NAME)) as BoulderSetup
		assert_not_null(setup, "%s : nœud Boulders" % map_id)
		if setup == null:
			continue
		var field := BoulderField.from_positions(plan.positions)
		var setup_field := setup.to_field()
		for flags: Array[StringName] in [[] as Array[StringName], [&"victory_road_3f_hole_1_filled"]
				as Array[StringName]]:
			var story := StoryFlags.new()
			for flag: StringName in flags:
				story.set_flag(flag)
			assert_eq(setup_field.boulders_at_load(story), field.boulders_at_load(story),
				"%s : rochers %s" % [map_id, flags])
		assert_eq(setup_field.switch_cells(), field.switch_cells(), "%s : interrupteurs" % map_id)
	# Le rocher tombé du 3F n'est au 2F qu'une fois le trou du 3F bouché.
	var setup_2f := (_map(&"victory_road_2f").get_node(NodePath(BoulderSetup.NODE_NAME))
		as BoulderSetup).to_field()
	var none := StoryFlags.new()
	var fallen := StoryFlags.new()
	fallen.set_flag(&"victory_road_3f_hole_1_filled")
	assert_false(setup_2f.boulders_at_load(none).has(Vector2i(23, 16)))
	assert_true(setup_2f.boulders_at_load(fallen).has(Vector2i(23, 16)))
	var setup_3f := (_map(&"victory_road_3f").get_node(NodePath(BoulderSetup.NODE_NAME))
		as BoulderSetup).to_field()
	assert_true(setup_3f.boulders_at_load(none).has(Vector2i(22, 15)))
	assert_false(setup_3f.boulders_at_load(fallen).has(Vector2i(22, 15)), "tombé au 2F")


func test_barriers_block_until_their_switch() -> void:
	for map_id: StringName in [&"victory_road_1f", &"victory_road_2f", &"victory_road_3f"]:
		var plan := _plan(OUTDOOR[map_id])
		var map := _map(map_id)
		map.apply_flag_gates(StoryFlags.new())
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "barriere":
				continue
			var flag := StringName(plan.attr(id, "ouverte_si"))
			for cell: Vector2i in plan.cells_at(id):
				assert_true(map.get_grid().is_occupied(cell), "%s : barrière fermée %s" % [map_id, cell])
			var flags := StoryFlags.new()
			flags.set_flag(flag)
			map.apply_flag_gates(flags)
			for cell: Vector2i in plan.cells_at(id):
				assert_false(map.get_grid().is_occupied(cell), "%s : barrière ouverte %s" % [map_id,
					cell])


func test_route_23_controls_are_row_triggers_going_north() -> void:
	var plan := _plan("route_23")
	var map := _map(&"route_23")
	var library := CutsceneLibrary.new()
	library.load_dir()
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "controle":
			continue
		var scene := StringName("route_23_check_" + id.trim_prefix("controle_"))
		assert_true(library.has_cutscene(scene), String(scene))
		for cell: Vector2i in plan.cells_at(id):
			var trigger := map.get_triggers().find_on_step(cell, Vector2i.UP)
			assert_not_null(trigger, "%s en %s" % [id, cell])
			if trigger != null:
				assert_eq(trigger.cutscene_id, scene)
			assert_null(map.get_triggers().find_on_step(cell, Vector2i.DOWN),
				"%s : rien en redescendant" % id)


func test_declared_in_zones_caves_lighting_interiors() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	# La Route Victoire est dans la zone de la Route 23 (aucune zone de plus sur la carte de Kanto).
	var expected := {&"route_22": [&"route_22_west", &"route_22_gate"],
		&"route_23": [&"route_23", &"victory_road_1f", &"victory_road_2f", &"victory_road_3f"],
		&"indigo_plateau": [&"indigo_plateau", &"indigo_plateau_lobby"]}
	for zone: StringName in expected:
		assert_true(zones.has_zone(zone), String(zone))
		for map_id: StringName in expected[zone]:
			assert_true((zones.get_zone(zone).maps as Array).has(map_id), "%s ∈ %s" % [map_id, zone])
	var interiors := MapCatalog.load_interiors()
	for map_id: StringName in ALL_MAPS:
		assert_eq(interiors.has(map_id), _map(map_id).interior, "intérieur : %s" % map_id)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	for map_id: StringName in ALL_MAPS:
		var map := _map(map_id)
		if not map.light_profile.is_empty():
			assert_true(lighting.has_profile(map.light_profile), String(map_id))


func test_npc_rosters_load_and_stand_on_walkable_cells() -> void:
	for map_id: StringName in ALL_MAPS:
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors().size(), 0, "%s : %s" % [map_id, roster.get_errors()])


## QA A17 du 2026-10-23 : le warp `ToLeague` (12, 3) du hall donnait sur le mur du fond nu de la
## coque du Centre. La porte de la Ligue (`int_porte_ligue_01`, fiche `j29-porte-ligue.md`) est
## posée dans le mur au-dessus de (12, 3), sans emprise ; le warp reste atteignable depuis
## l'entrée et la case d'arrivée (12, 4) reste libre (ni mur, ni PNJ).
func test_indigo_plateau_lobby_league_door_is_drawn_above_its_warp() -> void:
	const GridPaths := preload("res://tests/helpers/grid_paths.gd")
	var lobby := _map(&"indigo_plateau_lobby")
	var door := lobby.find_child("LeagueDoor", true, false) as Node2D
	assert_not_null(door, "porte de la Ligue dessinée")
	if door == null:
		return
	assert_eq(door.scene_file_path, "res://game/world/props/painted/int_porte_ligue_01.tscn")
	assert_true(PaintedPropRules.is_traversable(&"int_porte_ligue_01"), "sans emprise")
	assert_eq(door.position.x, 12 * 96.0 + 48.0, "centrée sur la colonne 12")
	assert_eq(floori(door.position.y / 96.0), 2, "pied dans le mur, juste au-dessus de (12, 3)")
	var sprite := door.get_node(^"%Sprite") as Sprite2D
	var left := door.position.x + sprite.offset.x
	var right := left + sprite.texture.get_width()
	assert_true(left >= 11 * 96.0 and right <= 14 * 96.0, "pas plus large que les cases 11 à 13")
	var warp: Warp = null
	for candidate: Warp in lobby.get_warps().get_all():
		# J30 (fusion du J29) : la porte mène à la salle d'Olga.
		if candidate.target_map == &"league_lorelei":
			warp = candidate
	assert_not_null(warp, "warp ToLeague")
	if warp == null:
		return
	assert_eq(warp.cell, Vector2i(12, 3))
	assert_eq(lobby.get_spawn_cell(&"league_door"), Vector2i(12, 4))
	var size := Vector2i(15, 10)
	var grid := GridPaths.relief(lobby.get_grid(), size)
	var roster := NpcRoster.load_for_map(&"indigo_plateau_lobby")
	var npc_cells: Array[Vector2i] = []
	for spec: NpcSpec in roster.get_all():
		npc_cells.append(spec.cell)
		grid.set_solid(spec.cell)
	assert_false(npc_cells.has(Vector2i(12, 4)), "aucun PNJ sur l'arrivée (12, 4)")
	assert_false(grid.is_solid(Vector2i(12, 4)), "(12, 4) praticable")
	var stops := {}
	for candidate: Warp in lobby.get_warps().get_all():
		stops[candidate.cell] = true
	var dist := GridPaths.distances(grid, [lobby.get_spawn_cell(&"entrance")], stops)
	assert_true(dist.has(Vector2i(12, 4)), "(12, 4) atteinte depuis l'entrée")
	assert_true(dist.has(Vector2i(12, 3)), "warp de la Ligue atteint depuis l'entrée")
