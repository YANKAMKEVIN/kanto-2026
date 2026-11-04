extends GutTest
## Chapitre Johto, JOH4 : les cinq cartes construites depuis leurs grilles
## (`tools/build_joh4_maps.gd`) et les intérieurs (`build_painted_interiors.gd --azalea`) : grille
## = plan, eau surfable, raccords, arrivées, déclencheurs, Félix et le Sbire E inévitables, herbes
## H1 et H3 obligatoires du Bois, lampes de nuit d'Écorcia.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const PLANS: Dictionary = {&"route_34": "route_34", &"ilex_forest": "ilex_forest",
	&"azalea_town": "azalea_town", &"slowpoke_well_b1f": "slowpoke_well_b1f",
	&"slowpoke_well_b2f": "slowpoke_well_b2f"}
const OUTDOORS: Array[StringName] = [&"route_34", &"ilex_forest", &"azalea_town"]
const CAVES: Dictionary = {&"slowpoke_well_b1f": &"cave_1f", &"slowpoke_well_b2f": &"cave_b1f"}
const INTERIORS: Array[StringName] = [&"azalea_center", &"azalea_mart", &"azalea_kurt_house",
	&"azalea_house_1", &"route_34_house"]
## Positions de la grille qui ne sont pas dans la grille logique de la scène (PNJ, objets et
## Ramoloss entrent au chargement de la carte, pas à la construction).
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "objet_visible"]
## PNJ posés sur une case bloquée de la grille (le Ramoloss de la margelle, E-31).
const NPC_ON_BLOCKED: Array[String] = ["azalea_town/ramoloss_margelle"]
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
		assert_true(plan.load_file("res://tools/plans/%s.txt" % PLANS[id]), plan.error)
		_plans[id] = plan
	return _plans[id]


func _cells(id: StringName, position: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign((_plan(id).positions[position] as Dictionary)["cells"])
	return cells


## Une case de la rangée 0 d'un extérieur passe à la rangée 1 (bord nord, en-tête de l'outil).
func _row1(cells: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in cells:
		out.append(cell + Vector2i.DOWN if cell.y == 0 else cell)
	return out


## Cases atteignables à pied depuis [param from], sans [param banned].
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
	for id: StringName in PLANS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
		assert_eq(map.light_profile, CAVES.get(id, &"johto_auto"), String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
	assert_eq(_map(&"azalea_town").display_name, "Écorcia")
	assert_eq(_map(&"ilex_forest").display_name, "Bois aux Chênes")
	assert_eq(_map(&"slowpoke_well_b2f").display_name, "Puits Ramoloss")


## La grille fait foi : une case est praticable dans la scène si et seulement si elle l'est dans
## la grille et qu'aucune position bloquante ne l'occupe ; l'eau `w` est surfable ; la rangée 0
## d'un extérieur est bloquée (bord nord).
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in PLANS:
		var map := _map(id)
		var plan := _plan(id)
		var grid := map.get_grid()
		var blocking: Dictionary = {}
		for position: String in plan.positions:
			var entry: Dictionary = plan.positions[position]
			if entry["blocks"] and not NPC_KINDS.has(entry["kind"]) \
					and not (entry["kind"] == "pokemon" and plan.attr(position, "espece") == "slowpoke"):
				for cell: Vector2i in entry["cells"]:
					blocking[cell] = true
		var mismatches: Array[Vector2i] = []
		var surf: Array[Vector2i] = plan.cells_of("w")
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if surf.has(cell):
					if not grid.is_surfable(cell):
						mismatches.append(cell)
					continue
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell) \
					and not (y == 0 and OUTDOORS.has(id))
				if expected_free == grid.is_solid(cell):
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)
	assert_eq(_plan(&"route_34").cells_of("w").size(), 45, "l'étang côtier se surfe (JH-36)")
	assert_gt(_plan(&"slowpoke_well_b1f").cells_of("w").size(), 0)
	assert_false(_map(&"route_34").get_grid().is_surfable(Vector2i(1, 10)), "la mer est un décor")


func test_all_walkable_cells_are_connected() -> void:
	var starts: Dictionary = {&"route_34": "from_ilex", &"ilex_forest": "from_azalea",
		&"azalea_town": "from_ilex", &"slowpoke_well_b1f": "from_azalea", &"slowpoke_well_b2f": "from_b1f"}
	for id: StringName in PLANS:
		var map := _map(id)
		var plan := _plan(id)
		var reached := _reachable(map, _row1(_cells(id, starts[id])))
		var isolated: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if not map.get_grid().is_solid(cell) and not reached.has(cell) \
						and not map.get_grid().is_surfable(cell):
					isolated.append(cell)
		assert_eq(isolated, [] as Array[Vector2i], "%s : cases isolées" % id)


func test_links_between_the_maps_and_the_coming_soon_exit() -> void:
	var chain: Array = [[&"route_34", &"ilex_forest", 3], [&"ilex_forest", &"azalea_town", 3],
		[&"azalea_town", &"slowpoke_well_b1f", 1], [&"slowpoke_well_b1f", &"slowpoke_well_b2f", 1]]
	for pair: Array in chain:
		for way: Array in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var count := 0
			for warp: Warp in _map(way[0]).get_warps().get_all():
				if warp.target_map == way[1]:
					count += 1
					var target := _map(way[1])
					assert_true(target.has_spawn(warp.target_spawn), "%s → %s / %s" % [way[0],
						way[1], warp.target_spawn])
					assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)),
						"%s / %s libre" % [way[1], warp.target_spawn])
			assert_eq(count, pair[2], "%s → %s" % way)
	# Bord nord : entrées et arrivées à la rangée 1.
	assert_eq(_map(&"ilex_forest").get_spawn_cell(&"from_route_34"), Vector2i(8, 1))
	assert_eq(_map(&"azalea_town").get_spawn_cell(&"from_ilex"), Vector2i(20, 1))
	assert_eq(_map(&"route_34").get_spawn_cell(&"from_ilex"), Vector2i(10, 47))
	assert_eq(_map(&"ilex_forest").get_spawn_cell(&"from_azalea"), Vector2i(36, 47))
	# Le puits : descente (37, 7), sortie (37, 8) ; échelles (3, 2) ↔ (37, 8), (3, 20) ↔ (3, 3).
	assert_eq(_map(&"azalea_town").get_spawn_cell(&"from_well"), Vector2i(37, 8))
	assert_eq(_map(&"slowpoke_well_b1f").get_spawn_cell(&"from_azalea"), Vector2i(3, 3))
	assert_eq(_map(&"slowpoke_well_b2f").get_spawn_cell(&"from_b1f"), Vector2i(3, 4))
	# Doublonville (JOH3) : « À venir » tant que la carte manque ; sinon trois arrivées attendues.
	var north: Array[Warp] = []
	for warp: Warp in _map(&"route_34").get_warps().get_all():
		if warp.cell.y == 1:
			north.append(warp)
	assert_eq(north.size(), 3, "trois cases du bord nord")
	for warp: Warp in north:
		if MapCatalog.has_map(&"goldenrod_city"):
			assert_eq(warp.target_map, &"goldenrod_city")
		else:
			assert_eq(warp.coming_soon, "Doublonville")
			assert_true(_map(&"route_34").has_spawn(warp.target_spawn))
	# Point de Vol : `from_center` devant le Centre (fly_points.json).
	assert_eq(_map(&"azalea_town").get_spawn_cell(&"from_center"), Vector2i(10, 21))


func test_doors_lead_to_the_interiors_and_back() -> void:
	var doors: Array = [[&"azalea_town", Vector2i(10, 20), &"azalea_center"],
		[&"azalea_town", Vector2i(30, 20), &"azalea_mart"],
		[&"azalea_town", Vector2i(10, 30), &"azalea_kurt_house"],
		[&"azalea_town", Vector2i(30, 30), &"azalea_house_1"],
		[&"route_34", Vector2i(17, 9), &"route_34_house"]]
	for door: Array in doors:
		var outside := _map(door[0])
		var found := false
		for candidate: Warp in outside.get_warps().get_all():
			if candidate.cell == door[1]:
				found = true
				assert_eq(candidate.target_map, door[2], str(door[1]))
				assert_true(_map(door[2]).has_spawn(candidate.target_spawn))
		assert_true(found, "porte %s" % door[1])
		var back := 0
		for exit: Warp in _map(door[2]).get_warps().get_all():
			if exit.target_map == door[0]:
				back += 1
				assert_true(outside.has_spawn(exit.target_spawn), "%s → %s" % [door[2],
					exit.target_spawn])
		assert_gt(back, 0, "%s : sortie" % door[2])
	for pair: Array in [[&"azalea_center", &"nurse"], [&"azalea_mart", &"clerk"]]:
		var spec := NpcRoster.load_for_map(pair[0]).get_spec(pair[1])
		assert_not_null(spec, "%s : %s" % pair)


func _triggers(id: StringName) -> Dictionary:
	var out: Dictionary = {}
	for point: Node in _map(id).get_node(^"Triggers").get_children():
		var trigger := point as EventTriggerPoint
		out[trigger.cutscene_id] = trigger
	return out


func test_triggers_and_npcs_on_free_cells() -> void:
	var well: EventTriggerPoint = _triggers(&"azalea_town").get(&"azalea_well_guard")
	assert_not_null(well, "barrière du puits")
	if well != null:
		assert_eq(well.get_cells(), [Vector2i(37, 8)] as Array[Vector2i])
		assert_eq(well.direction, Vector2i.UP)
	var brace: EventTriggerPoint = _triggers(&"slowpoke_well_b2f").get(&"slowpoke_well_brace")
	assert_not_null(brace, "scène de Brace")
	if brace != null:
		assert_eq(brace.get_cells().size(), 3, "toute la largeur du couloir")
		assert_eq(brace.direction, Vector2i.UP)
	assert_true(_triggers(&"slowpoke_well_b1f").has(&"slowpoke_well_kurt_fall"), "chute de Fargas")
	# L'autel s'examine (E-5) ; le Canarticho est un examen sur une case bloquée.
	var shrine: Node = _map(&"ilex_forest").get_node(^"Interactables").get_node_or_null(^"Autel")
	assert_not_null(shrine)
	if shrine != null:
		assert_eq(shrine.get(&"dialogue_id"), &"ilex_forest_autel")
	assert_true(_map(&"ilex_forest").get_grid().is_solid(Vector2i(33, 43)), "Canarticho bloque sa case")
	for id: StringName in PLANS.keys() + INTERIORS:
		var roster := NpcRoster.load_for_map(id)
		assert_eq(roster.get_errors(), PackedStringArray(), String(id))
		for spec: NpcSpec in roster.get_all():
			assert_true(_map(id).get_grid().is_in_bounds(spec.cell), "%s %s" % [id, spec.id])
			if NPC_ON_BLOCKED.has("%s/%s" % [id, spec.id]):
				continue
			assert_false(_map(id).get_grid().is_solid(spec.cell), "%s %s sur une case libre" % [id,
				spec.id])


## Félix garde le passage de la clôture ; Sophie et Bruno sont évitables ; le Sbire E garde le
## goulet du B1F ; H1 et H3 du Bois sont obligatoires, H2 et H4 non ; la Route 34 se traverse sans
## herbes.
func test_unavoidable_guards_and_mandatory_grass() -> void:
	var road := _map(&"route_34")
	var north := _row1(_cells(&"route_34", "from_goldenrod"))
	var south := _cells(&"route_34", "warp_sud")
	var plan := _plan(&"route_34")
	var no_grass := _reachable(road, north, plan.cells_of("h"))
	for cell: Vector2i in south:
		assert_true(no_grass.has(cell), "Route 34 sans herbes")
	var without_felix := _reachable(road, north, [Vector2i(10, 40), Vector2i(11, 40)])
	for cell: Vector2i in south:
		assert_false(without_felix.has(cell), "Félix garde le seul passage (%s)" % cell)
	var avoiding := _reachable(road, north, [Vector2i(16, 22), Vector2i(16, 23), Vector2i(16, 24),
		Vector2i(7, 37), Vector2i(8, 37)])
	for cell: Vector2i in south:
		assert_true(avoiding.has(cell), "Sophie et Bruno évitables")
	var forest := _map(&"ilex_forest")
	var start := _row1(_cells(&"ilex_forest", "from_route_34"))
	var exit := _cells(&"ilex_forest", "warp_sud")
	var all_grass: Array[Vector2i] = _plan(&"ilex_forest").cells_of("h")
	var side: Array[Vector2i] = []
	for cell: Vector2i in all_grass:
		if cell.y >= 20 and cell.y <= 24 or cell.x >= 40:
			side.append(cell)
	assert_false(_reachable(forest, start, all_grass).has(exit[0]), "H1 et H3 obligatoires")
	assert_true(_reachable(forest, start, side).has(exit[0]), "H2 et H4 évitables")
	var b1f := _map(&"slowpoke_well_b1f")
	var down := _cells(&"slowpoke_well_b1f", "echelle_b2f")
	var arrival := _cells(&"slowpoke_well_b1f", "from_azalea")
	assert_true(_reachable(b1f, arrival).has(down[0]))
	assert_false(_reachable(b1f, arrival, [Vector2i(15, 4)]).has(down[0]), "Sbire E inévitable")
	assert_true(_reachable(b1f, arrival, [Vector2i(21, 3), Vector2i(21, 4), Vector2i(11, 21),
		Vector2i(12, 21), Vector2i(13, 21)]).has(down[0]), "Sbires F et G évitables")


func test_night_lights_of_azalea() -> void:
	var lights := _map(&"azalea_town").get_node(^"NightLights").get_children()
	assert_gt(lights.size(), 0)
	for light: Node in lights:
		assert_true(light.is_in_group(WorldLighting.GROUP_NIGHT_LIGHTS), light.name)
		assert_false((light as CanvasItem).visible, "%s : éteinte le jour" % light.name)
