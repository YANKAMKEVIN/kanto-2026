extends GutTest
## Jalon 23 (T10, `jalon-23.md` §2.6, §2.7, §2.11) : cartes du Parc Safari, de la Porte, des maisons
## et de la maison du Gardien, construites depuis les grilles (`tools/build_j23_maps.gd`) ; portes
## de Parmanie ouvertes.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

## Carte → grille.
const MAPS: Dictionary[StringName, String] = {
	&"safari_zone_gate": "safari_porte", &"safari_zone_center": "safari_centre",
	&"safari_zone_east": "safari_est", &"safari_zone_north": "safari_nord",
	&"safari_zone_west": "safari_ouest",
	&"safari_zone_rest_house_center": "safari_maison_repos",
	&"safari_zone_rest_house_east": "safari_maison_repos",
	&"safari_zone_rest_house_north": "safari_maison_repos",
	&"safari_zone_rest_house_west": "safari_maison_repos",
	&"safari_zone_secret_house": "safari_maison_secrete",
	&"wardens_house": "parmanie_maison_gardien",
}

var _cache: Dictionary = {}


func after_all() -> void:
	for map: Variant in _cache.values():
		(map as Node).free()
	_cache.clear()


func _map(id: StringName) -> GameMap:
	if not _cache.has(id):
		var path := "res://game/world/maps/%s.tscn" % id
		assert_true(ResourceLoader.exists(path), path)
		var map := (load(path) as PackedScene).instantiate() as GameMap
		_cache[id] = map
		map.get_grid()
	return _cache[id]


func _plan(id: StringName) -> Object:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % MAPS[id]), MAPS[id])
	return plan


func test_every_map_is_its_grid() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		var plan := _plan(id)
		assert_eq(map.map_id, id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), "%s : dimensions" % id)
		var grid := map.get_grid()
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				# Rocher fixe du Gardien (§2.11) : sol praticable dans la grille, bloqué au J23.
				var rock: bool = plan.positions.has("rocher") and plan.cells_at("rocher").has(cell)
				if plan.is_walkable(cell) and not rock:
					assert_false(grid.is_solid(cell), "%s %s praticable" % [id, cell])
				else:
					assert_true(grid.is_solid(cell) or grid.is_water(cell), "%s %s bloquée (« %s »)" % [id, cell,
						plan.at(cell)])


func test_tall_grass_where_the_grid_says_h() -> void:
	for id: StringName in [&"safari_zone_center", &"safari_zone_east", &"safari_zone_north",
			&"safari_zone_west"]:
		var plan := _plan(id)
		var count := 0
		for cell: Vector2i in plan.cells_of("h"):
			assert_true(_map(id).get_grid().is_tall_grass(cell), "%s %s herbe" % [id, cell])
			count += 1
		assert_gt(count, 50, "%s : des herbes hautes" % id)


func test_warps_lead_to_existing_spawns_on_walkable_cells() -> void:
	for id: StringName in MAPS:
		for warp: Warp in _map(id).get_warps().get_all():
			assert_false(warp.is_coming_soon(), "%s %s : aucun « À venir »" % [id, warp.cell])
			var path := "res://game/world/maps/%s.tscn" % warp.target_map
			assert_true(ResourceLoader.exists(path), "%s → %s" % [id, warp.target_map])
			if not MAPS.has(warp.target_map) and warp.target_map != &"fuchsia_city":
				continue
			var target := _map(warp.target_map)
			assert_true(target.has_spawn(warp.target_spawn), "%s %s → %s / %s" % [id,
				warp.cell, warp.target_map, warp.target_spawn])
			assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)),
				"%s / %s praticable" % [warp.target_map, warp.target_spawn])


func test_links_are_reciprocal() -> void:
	var pairs: Array = [[&"safari_zone_gate", &"safari_zone_center"],
		[&"safari_zone_center", &"safari_zone_east"], [&"safari_zone_center", &"safari_zone_west"],
		[&"safari_zone_center", &"safari_zone_north"], [&"safari_zone_east", &"safari_zone_north"],
		[&"safari_zone_north", &"safari_zone_west"],
		[&"safari_zone_west", &"safari_zone_secret_house"],
		[&"safari_zone_center", &"safari_zone_rest_house_center"],
		[&"safari_zone_east", &"safari_zone_rest_house_east"],
		[&"safari_zone_north", &"safari_zone_rest_house_north"],
		[&"safari_zone_west", &"safari_zone_rest_house_west"],
		[&"safari_zone_gate", &"fuchsia_city"], [&"wardens_house", &"fuchsia_city"]]
	for pair: Array in pairs:
		for way: Array in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var found := false
			for warp: Warp in _map(way[0]).get_warps().get_all():
				found = found or warp.target_map == way[1]
			assert_true(found, "%s → %s" % way)


func test_fuchsia_opens_the_park_and_the_warden_house() -> void:
	var fuchsia := _map(&"fuchsia_city")
	var targets: Array[StringName] = []
	for warp: Warp in fuchsia.get_warps().get_all():
		targets.append(warp.target_map)
	assert_has(targets, &"safari_zone_gate")
	assert_has(targets, &"wardens_house")
	for spawn: StringName in [&"from_safari", &"from_wardens_house", &"from_gym"]:
		assert_true(fuchsia.has_spawn(spawn), spawn)


func test_gate_counter_triggers_both_ways() -> void:
	var triggers := _map(&"safari_zone_gate").get_triggers()
	for x: int in range(4, 8):
		var north := triggers.find_on_step(Vector2i(x, 4), Vector2i.UP)
		var south := triggers.find_on_step(Vector2i(x, 4), Vector2i.DOWN)
		assert_not_null(north, "comptoir (%d, 4) ↑" % x)
		assert_not_null(south, "comptoir (%d, 4) ↓" % x)
		if north != null and south != null:
			assert_eq(north.cutscene_id, &"j23_safari_gate_enter")
			assert_eq(south.cutscene_id, &"j23_safari_gate_leave")
	assert_true(_map(&"safari_zone_gate").has_spawn(SafariConfig.load_default().end_spawn),
		"arrivée de fin de visite")


func test_warden_rock_is_fixed_and_examined() -> void:
	var house := _map(&"wardens_house")
	assert_true(house.get_grid().is_solid(Vector2i(11, 3)), "rocher (11, 3) bloquant")
	var found := false
	for interaction: Interaction in house.get_interactions().get_at(Vector2i(11, 3)):
		found = found or interaction.dialogue_id == &"wardens_house_rocher"
	assert_true(found, "texte 46")
	assert_false(house.get_grid().is_solid(Vector2i(7, 7)), "case devant la porte libre")


func test_npcs_and_items_stand_on_their_cells() -> void:
	for id: StringName in MAPS:
		var plan := _plan(id)
		for spec: NpcSpec in NpcRoster.load_for_map(id).get_all():
			assert_true(plan.positions.has(String(spec.id)), "%s : %s dans la grille" % [id,
				spec.id])
			if plan.positions.has(String(spec.id)):
				assert_eq(spec.cell, plan.cell_of(String(spec.id)), "%s : %s" % [id, spec.id])


func test_park_maps_are_in_the_safari_zone() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for id: StringName in MAPS:
		var expected := &"fuchsia_city" if id == &"wardens_house" else &"safari_zone"
		assert_eq(zones.zone_of(id), expected, "%s : zone" % id)
