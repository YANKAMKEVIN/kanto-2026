extends GutTest
## Parcours complet du jalon 15 (intégration T13 + T14 + T18) sur les **vraies scènes** :
## Azuria → Route 5 → bâtiment d'entrée → passage souterrain → bâtiment de sortie → Route 6 →
## Carmin-sur-Mer, puis le retour. À chaque étape : depuis le point d'arrivée, un passage vers la
## carte suivante est atteignable à pied (relief seul, rebords compris, portes STEP_ON non
## traversées), sa destination n'est pas « à venir » et son point d'arrivée existe.

const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const FORWARD: Array[StringName] = [&"cerulean_city", &"route_5", &"route_5_underground_gate",
	&"underground_path", &"route_6_underground_gate", &"route_6", &"vermilion_city"]

var _maps: Dictionary = {}


func before_all() -> void:
	for id: StringName in FORWARD:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		map.rebuild_grid()
		_maps[id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


## Passage le plus proche de [param map] vers [param next], atteignable depuis [param spawn].
func _leg(map_id: StringName, spawn: StringName, next: StringName) -> Warp:
	var map: GameMap = _maps[map_id]
	assert_true(map.has_spawn(spawn), "%s/%s" % [map_id, spawn])
	if not map.has_spawn(spawn):
		return null
	var start := map.get_spawn_cell(spawn)
	var stops: Dictionary = {}
	for warp: Warp in map.get_warps().get_all():
		if warp.trigger == Warp.Trigger.STEP_ON:
			stops[warp.cell] = true
	var grid := GridPaths.relief(map.get_grid(), map.size)
	var dist := GridPaths.distances(grid, [start], stops)
	var best: Warp = null
	for warp: Warp in map.get_warps().get_all():
		if warp.target_map != next or not dist.has(warp.cell):
			continue
		if best == null or int(dist[warp.cell]) < int(dist[best.cell]):
			best = warp
	assert_not_null(best, "%s (%s) → %s : passage atteignable" % [map_id, spawn, next])
	if best != null:
		assert_false(best.is_coming_soon(), "%s → %s : pas « à venir »" % [map_id, next])
		var target: GameMap = _maps[next]
		assert_true(target.has_spawn(best.target_spawn),
			"%s → %s/%s : arrivée" % [map_id, next, best.target_spawn])
	return best


## Suit [param route] depuis [param spawn] ; renvoie les points d'arrivée successifs.
func _walk(route: Array[StringName], spawn: StringName) -> Array[StringName]:
	var arrivals: Array[StringName] = [spawn]
	for i: int in route.size() - 1:
		var warp := _leg(route[i], arrivals[-1], route[i + 1])
		if warp == null:
			break
		arrivals.append(warp.target_spawn)
	return arrivals


func test_cerulean_to_vermilion_through_the_underground() -> void:
	var arrivals := _walk(FORWARD, &"from_center")
	assert_eq(arrivals.size(), FORWARD.size(), "toutes les étapes franchies")
	if arrivals.size() == FORWARD.size():
		assert_eq(arrivals.slice(2, 6), [&"from_route_5", &"from_route_5_w",
			&"from_underground_w", &"from_underground"] as Array[StringName])


func test_vermilion_back_to_cerulean() -> void:
	var back := FORWARD.duplicate()
	back.reverse()
	var arrivals := _walk(back, &"from_center")
	assert_eq(arrivals.size(), back.size(), "toutes les étapes franchies")
	if arrivals.size() == back.size():
		# Escalier le plus proche de l'arrivée `from_route_6_w` : celui de l'est.
		assert_eq(arrivals.slice(2, 6), [&"from_route_6", &"from_route_6_w",
			&"from_underground_e", &"from_underground"] as Array[StringName])
