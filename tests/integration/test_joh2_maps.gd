extends GutTest
## Chapitre Johto, JOH2 : les trois cartes construites depuis leurs grilles
## (`tools/build_joh2_maps.gd`) et les intérieurs de Rosalia (`build_painted_interiors.gd
## --rosalia`) : grille = plan, raccords, arrivées, déclencheurs, lampes de nuit, Inès inévitable.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const EXTERIORS: Dictionary = {&"route_39": "route_39", &"route_38": "route_38",
	&"ecruteak_city": "rosalia"}
const INTERIORS: Array[StringName] = [&"ecruteak_center", &"ecruteak_mart",
	&"ecruteak_elders_house", &"ecruteak_house_1", &"ecruteak_house_2"]
## Positions de la grille qui ne sont pas dans la grille logique de la scène (PNJ et objets
## entrent au chargement de la carte, pas à la construction).
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "objet_visible"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _cache: Dictionary = {}
var _plans: Dictionary = {}


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


func _plan(id: StringName) -> PlanGrid:
	if not _plans.has(id):
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % EXTERIORS[id]), plan.error)
		_plans[id] = plan
	return _plans[id]


func _cells(id: StringName, position: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign((_plan(id).positions[position] as Dictionary)["cells"])
	return cells


## Cases atteignables à pied depuis [param from] sur la grille de la carte, sans [param banned].
func _reachable(map: GameMap, from: Array[Vector2i], banned: Array[Vector2i] = []) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in from:
		if not grid.is_solid(cell) and not banned.has(cell):
			seen[cell] = true
			queue.append(cell)
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in DIRS:
			var next := current + direction
			if seen.has(next) or not grid.is_in_bounds(next) or grid.is_solid(next) \
					or banned.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_maps_exist_with_their_ids_and_profiles() -> void:
	for id: StringName in EXTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.light_profile, &"johto_auto", String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
	assert_eq(_map(&"ecruteak_city").display_name, "Rosalia")
	assert_eq(_map(&"route_39").display_name, "Route 39")


## La grille fait foi : une case est praticable dans la scène si et seulement si elle l'est dans
## la grille et qu'aucune position bloquante (panneau, Pokémon du décor, examen) ne l'occupe.
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in EXTERIORS:
		var map := _map(id)
		var plan := _plan(id)
		var grid := map.get_grid()
		var blocking: Dictionary = {}
		for position: String in plan.positions:
			var entry: Dictionary = plan.positions[position]
			if entry["blocks"] and not NPC_KINDS.has(entry["kind"]):
				for cell: Vector2i in entry["cells"]:
					blocking[cell] = true
		var mismatches: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell)
				if expected_free == grid.is_solid(cell):
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_all_walkable_cells_are_connected() -> void:
	for id: StringName in EXTERIORS:
		var map := _map(id)
		var plan := _plan(id)
		var start := _cells(id, "from_route_38" if id != &"route_38" else "from_route_39")
		var reached := _reachable(map, start)
		var isolated: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if not map.get_grid().is_solid(cell) and not reached.has(cell):
					isolated.append(cell)
		assert_eq(isolated, [] as Array[Vector2i], "%s : cases isolées" % id)


func test_links_between_the_three_maps_and_the_coming_soon_exits() -> void:
	var chain: Array = [[&"route_39", &"route_38"], [&"route_38", &"ecruteak_city"]]
	for pair: Array in chain:
		for way: Array in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var count := 0
			for warp: Warp in _map(way[0]).get_warps().get_all():
				if warp.target_map == way[1]:
					count += 1
					var target := _map(way[1])
					assert_true(target.has_spawn(warp.target_spawn), "%s → %s / %s" % [way[0],
						way[1], warp.target_spawn])
					assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)))
			assert_eq(count, 3, "%s → %s : trois cases de bord" % way)
	# Raccords sur les mêmes rangées (dossier §3).
	assert_eq(_map(&"route_39").get_spawn_cell(&"from_route_38"), Vector2i(23, 3))
	assert_eq(_map(&"route_38").get_spawn_cell(&"from_route_39"), Vector2i(0, 3))
	assert_eq(_map(&"route_38").get_spawn_cell(&"from_ecruteak"), Vector2i(59, 14))
	assert_eq(_map(&"ecruteak_city").get_spawn_cell(&"from_route_38"), Vector2i(0, 14))
	# Oliville (JOH1), Route 37 (JOH3), Route 42 (JOH6), Bois de la Tour (JOH8) : « À venir »
	# tant que leur carte manque ; le raccord d'Oliville attend `from_olivine` (+ _1, _2).
	for spawn: StringName in [&"from_olivine", &"from_olivine_1", &"from_olivine_2"]:
		assert_true(_map(&"route_39").has_spawn(spawn), String(spawn))
	var labels: Dictionary = {}
	for id: StringName in EXTERIORS:
		for warp: Warp in _map(id).get_warps().get_all():
			if warp.is_coming_soon():
				labels[warp.coming_soon] = true
				assert_true(_map(id).has_spawn(warp.target_spawn), "%s : retour sur %s" % [id,
					warp.target_spawn])
	for expected: String in ["Route 42", "Tour Cendrée"]:
		assert_true(labels.has(expected), expected)
	# JOH3 : la Route 37 existe ; le sud de Rosalia y mène, une arrivée par case.
	if MapCatalog.has_map(&"route_37"):
		assert_false(labels.has("Route 37"), "Route 37 réelle (JOH3)")
	else:
		assert_true(labels.has("Route 37"), "Route 37 à venir")
	# JOH8 : le Bois de la Tour existe ; le chemin nord y mène.
	if MapCatalog.has_map(&"bell_tower_woods"):
		assert_false(labels.has("Bois de la Tour"), "Bois de la Tour construit (JOH8)")
	else:
		assert_true(labels.has("Bois de la Tour"), "Bois de la Tour à venir (JOH8)")
	if not MapCatalog.has_map(&"olivine_city"):
		assert_true(labels.has("Oliville"), "Oliville à venir (JOH1)")
	# Point de Vol : `from_center` devant le Centre (fly_points.json).
	assert_eq(_map(&"ecruteak_city").get_spawn_cell(&"from_center"), Vector2i(8, 30))


## QA A17 (2026-11-04) : le Centre n'avait pas d'infirmière. Centre et Boutique ont leur
## infirmière et leur vendeur derrière le comptoir, et le comptoir répond.
func test_center_and_mart_are_staffed() -> void:
	for pair: Array in [[&"ecruteak_center", &"nurse"], [&"ecruteak_mart", &"clerk"]]:
		var spec := NpcRoster.load_for_map(pair[0]).get_spec(pair[1])
		assert_not_null(spec, "%s : %s" % pair)
		if spec != null:
			assert_eq(spec.cell, Vector2i(7, 3), "%s derrière le comptoir" % pair[1])
		var counter: Node = null
		for point: Node in _map(pair[0]).get_node(^"Interactables").get_children():
			if point.get(&"dialogue_id") == pair[1]:
				counter = point
		assert_not_null(counter, "%s : on lui parle par-dessus le comptoir" % pair[1])


func test_doors_lead_to_the_interiors_and_back() -> void:
	var doors: Dictionary = {Vector2i(8, 29): &"ecruteak_center", Vector2i(18, 29): &"ecruteak_mart",
		Vector2i(21, 12): &"ecruteak_elders_house", Vector2i(35, 29): &"ecruteak_house_1",
		Vector2i(47, 29): &"ecruteak_house_2"}
	var city := _map(&"ecruteak_city")
	for cell: Vector2i in doors:
		var found := false
		for candidate: Warp in city.get_warps().get_all():
			if candidate.cell == cell:
				found = true
				assert_eq(candidate.target_map, doors[cell], str(cell))
				assert_true(_map(doors[cell]).has_spawn(candidate.target_spawn))
		assert_true(found, "porte %s" % cell)
		var back := 0
		for exit: Warp in _map(doors[cell]).get_warps().get_all():
			if exit.target_map == &"ecruteak_city":
				back += 1
				assert_true(city.has_spawn(exit.target_spawn), "%s → %s" % [doors[cell],
					exit.target_spawn])
		assert_gt(back, 0, "%s : sortie vers la ville" % doors[cell])


func test_triggers_examens_and_barriers() -> void:
	var city := _map(&"ecruteak_city")
	var triggers: Dictionary = {}
	for point: Node in city.get_node(^"Triggers").get_children():
		var trigger := point as EventTriggerPoint
		triggers[trigger.cutscene_id] = trigger
	assert_eq(triggers.keys().size(), 3)
	var rockets: EventTriggerPoint = triggers.get(&"ecruteak_rockets")
	assert_not_null(rockets, "scène des Sbires")
	if rockets != null:
		var cells := rockets.get_cells()
		cells.sort()
		var expected: Array[Vector2i] = []
		for y: int in range(14, 17):
			for x: int in range(1, 3):
				expected.append(Vector2i(x, y))
		expected.sort()
		assert_eq(cells, expected, "les six cases de l'entrée (seul passage depuis la Route 38)")
		assert_eq(rockets.direction, Vector2i.ZERO)
	var bell: EventTriggerPoint = triggers.get(&"ecruteak_bell_tower_guard")
	assert_not_null(bell)
	if bell != null:
		assert_eq(bell.get_cells(), [Vector2i(42, 13), Vector2i(43, 13)] as Array[Vector2i])
		assert_eq(bell.direction, Vector2i.UP)
	var east: EventTriggerPoint = triggers.get(&"ecruteak_route_42_guard")
	assert_not_null(east)
	if east != null:
		assert_eq(east.get_cells().size(), 3, "toute la largeur de la rue de l'est")
		assert_eq(east.direction, Vector2i.RIGHT)
	# La porte de la Tour Cendrée s'examine (R-19) tant que la tour est fermée (JOH6).
	var door: Node = city.get_node(^"Interactables").get_node_or_null(^"PorteTourCendree")
	assert_not_null(door, "examen de la porte de la Tour Cendrée")
	if door != null:
		assert_eq(door.get(&"dialogue_id"), &"ecruteak_city_porte_tour_cendree")
		assert_eq(door.get(&"size"), Vector2i(2, 1))
		assert_eq(door.get(&"unless_flags"), [&"johto_burned_tower_open"] as Array[StringName])
	# Les gardes et les Sbires sont posés sur des cases libres de la grille.
	for id: StringName in EXTERIORS:
		var roster := NpcRoster.load_for_map(id)
		assert_eq(roster.get_errors(), PackedStringArray(), String(id))
		for spec: NpcSpec in roster.get_all():
			assert_true(_map(id).get_grid().is_in_bounds(spec.cell), "%s %s" % [id, spec.id])
			assert_false(_map(id).get_grid().is_solid(spec.cell), "%s %s sur une case libre" % [id,
				spec.id])


func test_ines_is_unavoidable_on_route_38() -> void:
	var map := _map(&"route_38")
	var start := _cells(&"route_38", "from_route_39")
	var goal := _cells(&"route_38", "warp_est")
	var with_ines := _reachable(map, start)
	for cell: Vector2i in goal:
		assert_true(with_ines.has(cell), "l'est se rejoint (%s)" % cell)
	# Sans sa case ni celle qu'elle voit (42, 15), le passage d'une case est coupé.
	var without := _reachable(map, start, [Vector2i(42, 14), Vector2i(42, 15)])
	for cell: Vector2i in goal:
		assert_false(without.has(cell), "Inès garde le seul passage (%s)" % cell)
	# Les herbes sont évitables : la Route 39 se traverse sans herbes (dossier §3).
	var plan := _plan(&"route_39")
	var grass: Array[Vector2i] = plan.cells_of("h")
	var no_grass := _reachable(_map(&"route_39"), _cells(&"route_39", "from_olivine"), grass)
	for cell: Vector2i in _cells(&"route_39", "warp_est"):
		assert_true(no_grass.has(cell), "Route 39 sans herbes")


func test_night_lights_are_grouped_and_hidden_by_default() -> void:
	for id: StringName in [&"route_39", &"ecruteak_city"]:
		var lights := _map(id).get_node(^"NightLights").get_children()
		assert_gt(lights.size(), 0, "%s : lampes de nuit" % id)
		for light: Node in lights:
			assert_true(light.is_in_group(WorldLighting.GROUP_NIGHT_LIGHTS), light.name)
			assert_false((light as CanvasItem).visible, "%s : éteinte le jour" % light.name)
			assert_true(light is LightGlow, light.name)
	assert_eq(_map(&"route_38").get_node(^"NightLights").get_child_count(), 0, "Route 38 : aucune")
