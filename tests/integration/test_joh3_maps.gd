extends GutTest
## Chapitre Johto, JOH3 : les cinq cartes construites depuis leurs grilles
## (`tools/build_joh3_maps.gd`) et les intérieurs de Doublonville (`build_painted_interiors.gd
## --doublonville`) : grille = plan, raccords, portes, eau de l'étang, déclencheurs, PNJ des
## intérieurs, Anna inévitable, lampes de nuit (`jalon-joh3.md` §2.1 à §2.3).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const EXTERIORS: Dictionary = {&"route_37": "route_37", &"route_36": "route_36",
	&"route_35": "route_35", &"goldenrod_city": "doublonville",
	&"goldenrod_underground": "souterrain"}
const INTERIORS: Array[StringName] = [&"goldenrod_center", &"goldenrod_dept_store_1f",
	&"goldenrod_dept_store_2f", &"goldenrod_dept_store_3f", &"goldenrod_dept_store_roof",
	&"goldenrod_bond_house", &"goldenrod_house_1", &"goldenrod_house_2"]
## Arrivée de départ de chaque carte (parcours en largeur).
const STARTS: Dictionary = {&"route_37": "from_ecruteak", &"route_36": "from_route_37",
	&"route_35": "from_route_36", &"goldenrod_city": "from_route_35",
	&"goldenrod_underground": "from_goldenrod_west"}
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
		# Route 36 : la variante ARC (chemin des Ruines d'Alpha, JOHP1) est posée sur la carte.
		var variant := "ARC" if id == &"route_36" else ""
		assert_true(plan.load_file("res://tools/plans/%s.txt" % EXTERIORS[id], variant), plan.error)
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
					or grid.is_water(next) or banned.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	for warp: Warp in map.get_warps().get_all():
		if warp.cell == cell:
			return warp
	return null


func test_maps_exist_with_their_ids_and_profiles() -> void:
	for id: StringName in EXTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.light_profile,
			&"underground" if id == &"goldenrod_underground" else &"johto_auto", String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"golden_hour" if id == &"goldenrod_dept_store_roof"
			else &"interior_warm", String(id))
	assert_eq(_map(&"goldenrod_city").display_name, "Doublonville")
	assert_eq(_map(&"route_37").display_name, "Route 37")


## La grille fait foi : une case est praticable dans la scène si et seulement si elle l'est dans
## la grille (l'eau de l'étang se traverse en surfant seulement) et qu'aucune position bloquante
## (panneau, décor, examen, cache) ne l'occupe.
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
				if plan.at(cell) == "w":
					if not grid.is_water(cell) or grid.is_solid(cell):
						mismatches.append(cell)
					continue
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell)
				if expected_free == grid.is_solid(cell):
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_all_walkable_cells_are_connected() -> void:
	for id: StringName in EXTERIORS:
		var map := _map(id)
		var plan := _plan(id)
		var reached := _reachable(map, _cells(id, STARTS[id]))
		var isolated: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if not map.get_grid().is_solid(cell) and not map.get_grid().is_water(cell) \
						and not reached.has(cell):
					isolated.append(cell)
		assert_eq(isolated, [] as Array[Vector2i], "%s : cases isolées" % id)


func test_links_between_the_maps() -> void:
	var chain: Array = [[&"route_37", &"route_36"], [&"route_36", &"route_35"],
		[&"route_35", &"goldenrod_city"]]
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
	# Raccords du dossier §3.2 (colonnes différentes : warps case à case, dans l'ordre).
	assert_eq(_map(&"route_37").get_spawn_cell(&"from_route_36"), Vector2i(8, 39))
	assert_eq(_map(&"route_36").get_spawn_cell(&"from_route_35"), Vector2i(26, 19))
	assert_eq(_map(&"route_35").get_spawn_cell(&"from_route_36"), Vector2i(10, 0))
	assert_eq(_map(&"goldenrod_city").get_spawn_cell(&"from_route_35_2"), Vector2i(36, 0))
	var south := _warp_at(_map(&"route_35"), Vector2i(12, 43))
	assert_eq(south.target_spawn, &"from_route_35_2", "dernière case → dernière arrivée")
	# Rosalia (JOH2) et Route 34 (JOH4) : « À venir » tant que leur carte manque.
	if not MapCatalog.has_map(&"ecruteak_city"):
		assert_true(_warp_at(_map(&"route_37"), Vector2i(8, 0)).is_coming_soon())
	else:
		assert_eq(_warp_at(_map(&"route_37"), Vector2i(8, 0)).target_map, &"ecruteak_city")
	for spawn: StringName in [&"from_ecruteak", &"from_ecruteak_1", &"from_ecruteak_2"]:
		assert_true(_map(&"route_37").has_spawn(spawn), String(spawn))
	if not MapCatalog.has_map(&"route_34"):
		assert_eq(_warp_at(_map(&"goldenrod_city"), Vector2i(35, 59)).coming_soon, "Route 34")
	for spawn: StringName in [&"from_route_34", &"from_route_34_1", &"from_route_34_2"]:
		assert_true(_map(&"goldenrod_city").has_spawn(spawn), String(spawn))
	# Point de Vol : `from_center` devant le Centre (fly_points.json).
	assert_eq(_map(&"goldenrod_city").get_spawn_cell(&"from_center"), Vector2i(9, 28))


func test_doors_and_stairs_lead_in_and_back() -> void:
	var doors: Dictionary = {Vector2i(9, 27): &"goldenrod_center",
		Vector2i(49, 27): &"goldenrod_dept_store_1f", Vector2i(23, 15): &"goldenrod_bond_house",
		Vector2i(23, 27): &"goldenrod_house_1", Vector2i(47, 15): &"goldenrod_house_2",
		Vector2i(31, 25): &"goldenrod_underground", Vector2i(39, 33): &"goldenrod_underground"}
	var city := _map(&"goldenrod_city")
	for cell: Vector2i in doors:
		var warp := _warp_at(city, cell)
		assert_not_null(warp, "porte %s" % cell)
		if warp == null:
			continue
		assert_eq(warp.target_map, doors[cell], str(cell))
		assert_true(_map(doors[cell]).has_spawn(warp.target_spawn), str(cell))
		var back := 0
		for exit: Warp in _map(doors[cell]).get_warps().get_all():
			if exit.target_map == &"goldenrod_city":
				back += 1
				assert_true(city.has_spawn(exit.target_spawn), "%s → %s" % [doors[cell],
					exit.target_spawn])
		assert_gt(back, 0, "%s : sortie vers la ville" % doors[cell])
	# Escaliers du Souterrain : on y entre dans le sens de la marche.
	var under := _map(&"goldenrod_underground")
	assert_eq(_warp_at(under, Vector2i(1, 5)).target_spawn, &"from_underground_w")
	assert_eq(_warp_at(under, Vector2i(38, 8)).target_spawn, &"from_underground_e")
	# Tour Radio (JOH5) : la porte mène au hall (« À venir » tant que la carte manque).
	var tower := _warp_at(city, Vector2i(10, 15))
	assert_eq(tower.target_map if not tower.is_coming_soon() else &"goldenrod_radio_tower_1f",
		&"goldenrod_radio_tower_1f")
	# Grand Magasin : RdC → 1er → 2e → toit, et retour.
	var floors: Array[StringName] = [&"goldenrod_dept_store_1f", &"goldenrod_dept_store_2f",
		&"goldenrod_dept_store_3f", &"goldenrod_dept_store_roof"]
	for i: int in floors.size() - 1:
		var up := false
		for warp: Warp in _map(floors[i]).get_warps().get_all():
			if warp.target_map == floors[i + 1]:
				up = true
				assert_true(_map(floors[i + 1]).has_spawn(warp.target_spawn))
		assert_true(up, "%s monte" % floors[i])
		var down := false
		for warp: Warp in _map(floors[i + 1]).get_warps().get_all():
			if warp.target_map == floors[i]:
				down = true
		assert_true(down, "%s descend" % floors[i + 1])


## QA du JOH1 et du JOH2 : un intérieur sans fichier de PNJ n'a ni infirmière ni vendeur.
func test_interiors_are_staffed_and_their_counters_answer() -> void:
	var staff: Array = [[&"goldenrod_center", &"nurse", &"nurse"],
		[&"goldenrod_center", &"orme", &""],
		[&"goldenrod_dept_store_1f", &"hostess", &"goldenrod_dept_hostess"],
		[&"goldenrod_dept_store_2f", &"clerk_a", &"goldenrod_dept_2f_clerk"],
		[&"goldenrod_dept_store_3f", &"clerk", &"goldenrod_dept_3f_clerk"],
		[&"goldenrod_dept_store_roof", &"old_man", &""],
		[&"goldenrod_bond_house", &"clemence", &""],
		[&"goldenrod_house_1", &"woman", &""], [&"goldenrod_house_2", &"man", &""]]
	for entry: Array in staff:
		var roster := NpcRoster.load_for_map(entry[0])
		assert_eq(roster.get_errors(), PackedStringArray(), String(entry[0]))
		var spec := roster.get_spec(entry[1])
		assert_not_null(spec, "%s : %s" % [entry[0], entry[1]])
		if spec == null:
			continue
		assert_false(_map(entry[0]).get_grid().is_solid(spec.cell), "%s sur une case libre"
			% entry[1])
		if StringName(entry[2]).is_empty():
			continue
		var counter: Node = null
		for point: Node in _map(entry[0]).get_node(^"Interactables").get_children():
			if point.get(&"dialogue_id") == entry[2]:
				counter = point
		assert_not_null(counter, "%s : on lui parle par-dessus le comptoir" % entry[1])
	# Panneau de la promotion (RdC) et distributeurs du toit.
	var dialogues: Array = []
	for map_id: StringName in [&"goldenrod_dept_store_1f", &"goldenrod_dept_store_roof"]:
		for point: Node in _map(map_id).get_node(^"Interactables").get_children():
			dialogues.append(point.get(&"dialogue_id"))
	for id: StringName in [&"goldenrod_dept_board", &"goldenrod_dept_roof_water",
			&"goldenrod_dept_roof_soda", &"goldenrod_dept_roof_lemonade"]:
		assert_true(dialogues.has(id), String(id))


func test_pond_is_surfable_and_fishable() -> void:
	var map := _map(&"route_35")
	var water: Array[Vector2i] = _plan(&"route_35").cells_of("w")
	assert_gt(water.size(), 0)
	for cell: Vector2i in water:
		assert_true(map.surf_cells.has(cell), "surfable %s" % cell)
	assert_true(map.fishable_cells.has(Vector2i(2, 14)), "bord de l'étang pêchable")
	assert_false(map.fishable_cells.has(Vector2i(5, 19)), "milieu de l'étang : pas depuis la berge")
	assert_eq(_map(&"route_36").surf_cells.size(), 0, "la rivière de la Route 36 ne se surfe pas")


func test_triggers_and_examens() -> void:
	var city := _map(&"goldenrod_city")
	var triggers: Dictionary = {}
	for point: Node in city.get_node(^"Triggers").get_children():
		var trigger := point as EventTriggerPoint
		triggers[trigger.cutscene_id] = trigger
	var arrival: EventTriggerPoint = triggers.get(&"goldenrod_arrival")
	assert_not_null(arrival)
	if arrival != null:
		assert_eq(arrival.get_cells().size(), 3, "toute la largeur de l'avenue")
		assert_eq(arrival.direction, Vector2i.ZERO)
	var guard: EventTriggerPoint = triggers.get(&"goldenrod_south_guard")
	assert_not_null(guard)
	if guard != null:
		assert_eq(guard.get_cells().size(), 3)
		assert_eq(guard.direction, Vector2i.DOWN)
	var speaker: Node = city.get_node(^"Interactables").get_node_or_null(^"HautParleur")
	assert_not_null(speaker, "haut-parleur de la place")
	if speaker != null:
		assert_eq(speaker.get(&"dialogue_id"), &"goldenrod_speaker")
	var gate: Node = _map(&"route_36").get_node(^"Interactables").get_node_or_null(^"GrilleParc")
	assert_not_null(gate)
	for id: StringName in EXTERIORS:
		var roster := NpcRoster.load_for_map(id)
		assert_eq(roster.get_errors(), PackedStringArray(), String(id))
		for spec: NpcSpec in roster.get_all():
			assert_true(_map(id).get_grid().is_in_bounds(spec.cell), "%s %s" % [id, spec.id])
			assert_false(_map(id).get_grid().is_solid(spec.cell), "%s %s sur une case libre" % [id,
				spec.id])


func test_anna_is_unavoidable_and_grass_is_avoidable() -> void:
	var map := _map(&"route_35")
	var start := _cells(&"route_35", "from_route_36")
	var goal := _cells(&"route_35", "warp_sud")
	var with_anna := _reachable(map, start, [Vector2i(12, 38)])
	for cell: Vector2i in goal:
		assert_true(with_anna.has(cell), "le sud se rejoint (%s)" % cell)
	var without := _reachable(map, start, [Vector2i(11, 38), Vector2i(12, 38)])
	for cell: Vector2i in goal:
		assert_false(without.has(cell), "Anna garde le seul passage (%s)" % cell)
	for id: StringName in [&"route_37", &"route_36", &"route_35"]:
		var grass: Array[Vector2i] = _plan(id).cells_of("h")
		var reached := _reachable(_map(id), _cells(id, STARTS[id]), grass)
		var exit := "warp_sud"
		for cell: Vector2i in _cells(id, exit):
			assert_true(reached.has(cell), "%s se traverse sans herbes" % id)


func test_night_lights_are_grouped_and_hidden_by_default() -> void:
	for id: StringName in [&"route_35", &"goldenrod_city"]:
		var lights := _map(id).get_node(^"NightLights").get_children()
		assert_gt(lights.size(), 0, "%s : lampes de nuit" % id)
		for light: Node in lights:
			assert_true(light.is_in_group(WorldLighting.GROUP_NIGHT_LIGHTS), light.name)
			assert_false((light as CanvasItem).visible, "%s : éteinte le jour" % light.name)
