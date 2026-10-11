extends GutTest
## Boîte à outils des grottes (`tools/cave_map_kit.gd`, jalon 12 T7) sur les vraies grilles du
## Mont Sélénite : source logique `Ground` (sol calme, gravats `RUBBLE`, solide), masque du sol
## peint (R gravats, G masse), racine extérieure, échelles appariées et orientées, points
## d'apparition par case, budget de halos. Sans construire de scène (T9).

const CaveKit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLOORS: Dictionary[StringName, Vector2i] = {
	&"mt_moon_1f": Vector2i(60, 46), &"mt_moon_b1f": Vector2i(40, 30),
	&"mt_moon_b2f": Vector2i(50, 38),
}


func _kit(map_id: StringName) -> RefCounted:
	return CaveKit.new(CaveKit.PLANS[map_id], FLOORS[map_id], 1, 2)


func test_grids_load_with_cave_walkables() -> void:
	for map_id: StringName in FLOORS:
		var kit := _kit(map_id)
		assert_eq(kit.errors, PackedStringArray(), "%s : grille lue" % map_id)


func test_wrong_size_is_an_error() -> void:
	var kit := CaveKit.new(CaveKit.PLANS[&"mt_moon_1f"], Vector2i(10, 10), 1, 2)
	assert_false(kit.errors.is_empty())


func test_logic_layer_follows_the_grid() -> void:
	for map_id: StringName in FLOORS:
		var kit := _kit(map_id)
		var root: Node2D = kit.make_root("Floor", map_id, "Mont Sélénite", &"")
		assert_false(root.get(&"interior"), "%s : grotte = extérieure (compagnon visible)" % map_id)
		assert_eq(root.get(&"region"), "")
		var ground := root.get_node(^"Ground") as TileMapLayer
		var plan: Object = kit.plan
		var rubble := 0
		for y: int in FLOORS[map_id].y:
			for x: int in FLOORS[map_id].x:
				var cell := Vector2i(x, y)
				var data := ground.get_cell_tile_data(cell)
				var mark: String = plan.call(&"at", cell)
				var walkable := CaveKit.WALKABLE.contains(mark)
				assert_eq(data.get_custom_data(OverworldTiles.DATA_SOLID), not walkable,
					"%s %s « %s » solide" % [map_id, cell, mark])
				assert_eq(data.get_custom_data(OverworldTiles.DATA_RUBBLE), mark == "g",
					"%s %s « %s » gravats" % [map_id, cell, mark])
				assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
				if mark == "g":
					rubble += 1
		assert_gt(rubble, 0, "%s : des gravats" % map_id)
		assert_eq(kit.rubble_cells.size(), rubble)
		root.free()


func test_logic_layer_reads_into_the_grid_world() -> void:
	var kit := _kit(&"mt_moon_1f")
	var root: Node2D = kit.make_root("Floor", &"mt_moon_1f", "Mont Sélénite", &"")
	var grid: GridWorld = (root as GameMap).get_grid()
	assert_false(grid.is_solid(Vector2i(16, 24)), "gravats G1 praticables")
	assert_false(grid.is_tall_grass(Vector2i(16, 24)), "pas des hautes herbes (moteur : T20)")
	assert_false(grid.is_solid(Vector2i(29, 44)), "arrivée de la Route 3")
	assert_true(grid.is_solid(Vector2i(0, 0)), "paroi")
	assert_true(grid.is_solid(Vector2i(29, 24)), "colonne K")
	root.free()


func test_mask_red_is_rubble_green_is_rock_mass() -> void:
	var kit := _kit(&"mt_moon_b2f")
	var root: Node2D = kit.make_root("Floor", &"mt_moon_b2f", "Mont Sélénite", &"")
	var mask: Image = kit.build_mask()
	assert_eq(mask.get_size(), FLOORS[&"mt_moon_b2f"])
	for cell: Vector2i in kit.rubble_cells:
		assert_eq(GroundMask.kind_at(mask, cell), GroundMask.Kind.PAVING, "R = gravats %s" % cell)
	for cell: Vector2i in kit.mass_cells:
		assert_eq(GroundMask.kind_at(mask, cell), GroundMask.Kind.PATH, "G = masse %s" % cell)
	for cell: Vector2i in kit.floor_cells:
		if not kit.rubble_cells.has(cell):
			assert_eq(GroundMask.kind_at(mask, cell), GroundMask.Kind.GRASS, "sol calme %s" % cell)
	root.free()


func test_ground_needs_the_series_14_textures() -> void:
	var kit := _kit(&"mt_moon_1f")
	kit.make_root("Floor", &"mt_moon_1f", "Mont Sélénite", &"")
	var ready := ResourceLoader.exists(CaveKit.FLOOR_TEXTURE) \
		and ResourceLoader.exists(CaveKit.RUBBLE_TEXTURE) \
		and ResourceLoader.exists(CaveKit.MASS_TEXTURE)
	if ready:
		pending("textures de la série 14 présentes : couvert par test_mt_moon_maps (T9)")
	else:
		assert_false(kit.add_ground("res://build/test_cave_mask.png"))
		assert_string_contains(" ".join(kit.errors), "texture de grotte absente")
	kit.discard()


func test_ladders_pair_up_across_floors() -> void:
	var expected := {
		&"mt_moon_1f": {"echelle_a": [&"mt_moon_b1f", &"arrivee_a", Vector2i.DOWN],
			"echelle_c": [&"mt_moon_b1f", &"arrivee_c", Vector2i.UP],
			"echelle_b": [&"mt_moon_b1f", &"arrivee_b", Vector2i.LEFT],
			"echelle_d": [&"mt_moon_b2f", &"arrivee_d", Vector2i.DOWN]},
		&"mt_moon_b1f": {"echelle_a": [&"mt_moon_1f", &"arrivee_a", Vector2i.DOWN],
			"echelle_b": [&"mt_moon_1f", &"arrivee_b", Vector2i.DOWN],
			"echelle_c": [&"mt_moon_1f", &"arrivee_c", Vector2i.UP]},
		&"mt_moon_b2f": {"echelle_d": [&"mt_moon_1f", &"arrivee_d", Vector2i.LEFT],
			"echelle_sortie": [&"route_4", &"from_mt_moon", Vector2i.RIGHT]},
	}
	for map_id: StringName in expected:
		var kit := _kit(map_id)
		var links: Array[Dictionary] = kit.ladder_links()
		assert_eq(kit.errors, PackedStringArray(), "%s : toutes les paires trouvées" % map_id)
		var seen: Dictionary = {}
		for link: Dictionary in links:
			seen[link["id"]] = [link["target_map"], link["target_spawn"], link["facing"]]
		assert_eq(seen, expected[map_id], "%s : échelles" % map_id)


func test_ladder_warp_is_a_step_on_without_direction() -> void:
	var kit := _kit(&"mt_moon_b2f")
	kit.make_root("Floor", &"mt_moon_b2f", "Mont Sélénite", &"")
	var warps := Node2D.new()
	warps.name = "Warps"
	kit.attach(kit.root, warps)
	var link: Dictionary = kit.ladder_links()[0]
	var warp: Node2D = kit.add_ladder("EchelleD", link)
	assert_eq(warp.get(&"trigger"), CaveKit.STEP_ON)
	assert_eq(warp.get(&"direction"), Vector2i.ZERO, "escalier : toute direction")
	assert_eq(warp.get(&"target_map"), &"mt_moon_1f")
	assert_eq(warp.get(&"target_spawn"), &"arrivee_d")
	assert_eq(warp.get(&"arrival_facing"), Vector2i.LEFT)
	assert_eq(warp.position, kit.world(Vector2i(46, 2)))
	kit.discard()


func test_arrival_facing_is_away_from_the_ladder() -> void:
	assert_eq(CaveKit.arrival_facing(Vector2i(7, 10), Vector2i(7, 9)), Vector2i.DOWN)
	assert_eq(CaveKit.arrival_facing(Vector2i(56, 8), Vector2i(57, 8)), Vector2i.LEFT)
	assert_eq(CaveKit.arrival_facing(Vector2i(3, 6), Vector2i(2, 6)), Vector2i.RIGHT)
	assert_eq(CaveKit.arrival_facing(Vector2i(51, 40), Vector2i(51, 41)), Vector2i.UP)
	assert_eq(CaveKit.arrival_facing(Vector2i(5, 5), Vector2i(5, 5)), Vector2i.DOWN)


func test_spawn_names_one_per_cell() -> void:
	var one: Array[Vector2i] = [Vector2i(7, 10)]
	assert_eq(CaveKit.spawn_names("arrivee_a", one), {"arrivee_a": Vector2i(7, 10)})
	var row: Array[Vector2i] = [Vector2i(74, 10), Vector2i(73, 10)]
	assert_eq(CaveKit.spawn_names("from_mt_moon", row),
		{"from_mt_moon_w": Vector2i(73, 10), "from_mt_moon_e": Vector2i(74, 10)},
		"Corde Sortie : from_mt_moon_w (caves.json)")
	var column: Array[Vector2i] = [Vector2i(0, 25), Vector2i(0, 26), Vector2i(0, 27)]
	assert_eq(CaveKit.spawn_names("from_pewter", column), {"from_pewter_n": Vector2i(0, 25),
		"from_pewter_c": Vector2i(0, 26), "from_pewter_s": Vector2i(0, 27)})
	var block: Array[Vector2i] = PlanGrid.parse_cells("0..1,0..1")
	assert_eq(CaveKit.spawn_names("x", block).size(), 4)


func test_route_3_exit_spawn_matches_caves_json() -> void:
	# La sortie de la Corde Sortie (caves.json) est un des points nommés de la Route 3.
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_3.txt"))
	var names := CaveKit.spawn_names("from_mt_moon", plan.cells_at("from_mt_moon"))
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var exit := caves.escape_target(&"mt_moon_1f")
	assert_true(names.has(String(exit.spawn)), "%s dans %s" % [exit.spawn, names.keys()])
	assert_eq(names[String(exit.spawn)], Vector2i(73, 10))


func test_glow_budget() -> void:
	var kit := _kit(&"mt_moon_b2f")
	kit.make_root("Floor", &"mt_moon_b2f", "Mont Sélénite", &"")
	kit.glows = Node2D.new()
	kit.glows.name = "Glows"
	kit.attach(kit.root, kit.glows)
	for i: int in LightGlowLibrary.MAX_PER_MAP:
		var glow: Node2D = kit.add_glow(&"projector", kit.cell_center(Vector2i(20, 30)))
		assert_eq(glow.get(&"glow_type"), &"projector")
	assert_eq(kit.errors, PackedStringArray(), "16 halos : dans le budget")
	assert_eq(kit.glow_count(), LightGlowLibrary.MAX_PER_MAP)
	kit.add_glow(&"lamp", kit.cell_center(Vector2i(24, 20)))
	assert_eq(kit.errors.size(), 1, "17e halo : hors budget")
	kit.add_glow(&"soleil", Vector2.ZERO)
	assert_string_contains(" ".join(kit.errors), "type inconnu")
	assert_eq(kit.cell_center(Vector2i(1, 2)), Vector2(144, 240))
	kit.discard()
