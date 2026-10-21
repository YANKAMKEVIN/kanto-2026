extends GutTest
## Jalon 22 : cartes construites depuis les grilles (`tools/build_j22_maps.gd`, intérieurs de
## `tools/build_painted_interiors.gd`) : raccords, arrivées, Piste, pente, eau pêchable, PNJ.

const MAPS: Array[StringName] = [&"route_12_south", &"route_13", &"route_14", &"route_15",
	&"route_15_gate", &"route_15_gate_2f", &"route_16_west", &"route_16_gate", &"route_17",
	&"route_18", &"route_18_gate", &"fuchsia_city", &"route_12_rod_house", &"fuchsia_center",
	&"fuchsia_mart", &"fuchsia_meeting_room", &"fuchsia_grandpa_house",
	&"fuchsia_good_rod_house"]
## Cartes d'autres jalons pas encore construites : leurs passages sont « À venir ».
const FOREIGN: Array[StringName] = [&"route_12", &"route_16"]

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


func test_every_map_exists_with_its_id() -> void:
	for id: StringName in MAPS:
		assert_eq(_map(id).map_id, id)


func test_warps_lead_to_existing_spawns_on_walkable_cells() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		for warp: Warp in map.get_warps().get_all():
			if warp.is_coming_soon():
				assert_true(warp.target_map.is_empty(), "%s %s" % [id, warp.cell])
				continue
			assert_false(FOREIGN.has(warp.target_map), "%s → %s : pas encore construite"
				% [id, warp.target_map])
			var target := _map(warp.target_map) if MAPS.has(warp.target_map) else null
			if target == null:
				assert_true(ResourceLoader.exists("res://game/world/maps/%s.tscn"
					% warp.target_map), "%s → %s" % [id, warp.target_map])
				continue
			assert_true(target.has_spawn(warp.target_spawn), "%s %s → %s / %s" % [id,
				warp.cell, warp.target_map, warp.target_spawn])
			var cell := target.get_spawn_cell(warp.target_spawn)
			assert_false(target.get_grid().is_solid(cell), "%s / %s praticable"
				% [warp.target_map, warp.target_spawn])


func test_both_routes_reach_fuchsia_and_back() -> void:
	# Chemin des pêcheurs : 12 sud → 13 → 14 → 15 → Parmanie, et retour.
	var chain: Array = [[&"route_12_south", &"route_13"], [&"route_13", &"route_14"],
		[&"route_14", &"route_15"], [&"route_15", &"fuchsia_city"],
		[&"route_16_west", &"route_17"], [&"route_17", &"route_18"],
		[&"route_18", &"fuchsia_city"], [&"route_16_gate", &"route_16_west"],
		[&"route_15", &"route_15_gate"], [&"route_18", &"route_18_gate"]]
	for pair: Array in chain:
		for way: Array in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var found := false
			for warp: Warp in _map(way[0]).get_warps().get_all():
				found = found or warp.target_map == way[1]
			assert_true(found, "%s → %s" % way)


func test_foreign_routes_are_coming_soon_until_built() -> void:
	var labels: Array[String] = []
	for id: StringName in [&"route_12_south", &"route_16_gate"]:
		for warp: Warp in _map(id).get_warps().get_all():
			if warp.is_coming_soon():
				labels.append(warp.coming_soon)
	assert_has(labels, "Route 12")
	assert_has(labels, "Route 16")


func test_cycling_road_and_slope() -> void:
	var road := _map(&"route_17")
	assert_true(road.cycling_road, "Route 17 : toute la carte")
	assert_gt(road.slope_cells.size(), 100)
	for cell: Vector2i in road.slope_cells:
		assert_true(road.get_grid().is_slope(cell))
	# Trois paliers : bandes de rangées praticables sans pente entre deux tronçons de pente.
	var slope_rows: Dictionary = {}
	for cell: Vector2i in road.slope_cells:
		slope_rows[cell.y] = true
	var landings := 0
	var in_gap := false
	var seen_slope := false
	for y: int in road.size.y:
		if slope_rows.has(y):
			if in_gap and seen_slope:
				landings += 1
			in_gap = false
			seen_slope = true
		else:
			in_gap = true
	assert_gte(landings, 3, "paliers")
	for id: StringName in [&"route_16_west", &"route_18"]:
		var map := _map(id)
		assert_false(map.cycling_road, String(id))
		assert_gt(map.cycling_road_cells.size(), 0, String(id))
		assert_eq(map.slope_cells.size(), 0, "pente : Route 17 seulement")


func test_no_fishable_water_next_to_the_road() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		for cell: Vector2i in map.fishable_cells:
			assert_true(map.get_grid().is_water(cell), "%s %s" % [id, cell])
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				assert_false(map.is_cycling_road_at(cell + side), "%s %s" % [id, cell])
	assert_gt(_map(&"route_12_south").fishable_cells.size(), 0, "ponton")
	assert_gt(_map(&"fuchsia_city").fishable_cells.size(), 0, "étang")
	assert_gt(_map(&"route_18").fishable_cells.size(), 0, "étang de la Route 18")


func test_npcs_stand_on_their_cells() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		var roster := NpcRoster.load_for_map(id)
		assert_eq(roster.get_errors(), PackedStringArray(), String(id))
		for spec: NpcSpec in roster.get_all():
			assert_true(map.get_grid().is_in_bounds(spec.cell), "%s %s" % [id, spec.id])


func test_interiors_are_interiors() -> void:
	for id: StringName in [&"route_15_gate", &"route_15_gate_2f", &"route_16_gate",
			&"route_18_gate", &"route_12_rod_house", &"fuchsia_center", &"fuchsia_mart",
			&"fuchsia_meeting_room", &"fuchsia_grandpa_house", &"fuchsia_good_rod_house"]:
		assert_true(_map(id).interior, String(id))
	for id: StringName in [&"route_12_south", &"route_16_west", &"route_17", &"fuchsia_city"]:
		assert_false(_map(id).interior, String(id))
