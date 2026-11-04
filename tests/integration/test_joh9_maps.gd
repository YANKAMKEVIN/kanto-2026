extends GutTest
## Chapitre Johto, JOH9 (`docs/tech/jalon-joh9.md` §2.1) : les sept cartes construites depuis
## leurs grilles (`tools/build_joh9_maps.gd`), les intérieurs (`build_painted_interiors.gd --joh9`)
## et les retouches de Kanto (`tools/build_joh9_route22.gd` : variante `JOH9` de la Route 22,
## déclencheur de l'épilogue au labo) : grille = plan, raccords, échelles, rochers de Force, lac
## surfable, déclencheurs, Vol interdit au sommet.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAPS: Dictionary = {&"silver_trail": "silver_trail", &"mt_silver_outside": "mt_silver_outside",
	&"mt_silver_1f": "mt_silver_1f", &"mt_silver_2f": "mt_silver_2f",
	&"mt_silver_3f": "mt_silver_3f", &"mt_silver_summit": "mt_silver_summit",
	&"route_28": "route_28"}
const CAVES: Array[StringName] = [&"mt_silver_1f", &"mt_silver_2f", &"mt_silver_3f"]
const INTERIORS: Array[StringName] = [&"mt_silver_center", &"route_28_gate", &"route_28_house"]
## Positions de la grille qui ne sont pas dans la grille logique de la scène (PNJ entrent au
## chargement ; rochers posés par `Boulders`).
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "rocher"]
## Destinations d'autres jalons (« À venir » tant que leur carte manque).
const OTHER_JALONS: Array[StringName] = [&"lake_of_rage"]
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
		assert_true(plan.load_file("res://tools/plans/%s.txt" % MAPS[id]), plan.error)
		_plans[id] = plan
	return _plans[id]


func _boulder_setup(map: GameMap) -> Node:
	return map.get_node_or_null(^"Boulders")


func test_maps_exist_with_their_ids_and_profiles() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
		assert_eq(map.light_profile, &"cave_1f" if CAVES.has(id) else &"johto_auto", String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_true(map.interior, String(id))
	assert_eq(_map(&"route_28").display_name, "Route 28")
	assert_eq(_map(&"mt_silver_1f").display_name, "Mont Argenté")


## La grille fait foi : praticable dans la scène si et seulement si praticable dans la grille et
## sans position bloquante (panneau, ruines) ; l'eau du lac est de l'eau surfable.
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in MAPS:
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
				var mark := plan.at(cell)
				if mark == "w":
					if not grid.is_surfable(cell):
						mismatches.append(cell)
					continue
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell)
				var free := not grid.is_solid(cell) and not grid.is_water(cell)
				if expected_free != free:
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


## Toutes les cases praticables se rejoignent (l'eau et les rochers comptent comme passables : Surf
## et Force).
func test_all_walkable_cells_are_connected() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		var plan := _plan(id)
		var grid := map.get_grid()
		var start: Vector2i = map.get_spawn_cell(map.get_spawn_names()[0]) \
			if map.has_method(&"get_spawn_names") else _first_spawn(id)
		var seen: Dictionary = {start: true}
		var queue: Array[Vector2i] = [start]
		var head := 0
		while head < queue.size():
			var current: Vector2i = queue[head]
			head += 1
			for direction: Vector2i in DIRS:
				var next := current + direction
				if seen.has(next) or not grid.is_in_bounds(next):
					continue
				if not plan.is_walkable(next):
					continue
				seen[next] = true
				queue.append(next)
		var isolated: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if plan.is_walkable(cell) and not seen.has(cell):
					isolated.append(cell)
		assert_eq(isolated, [] as Array[Vector2i], "%s : cases isolées" % id)


func _first_spawn(id: StringName) -> Vector2i:
	for position: String in _plan(id).positions:
		var entry: Dictionary = _plan(id).positions[position]
		if entry["kind"] == "spawn":
			return entry["cells"][0]
	return Vector2i.ZERO


## Chaque passage mène à une carte et une arrivée existantes, praticables (sauf le Lac Colère,
## carte du JOH6 : « À venir »).
func test_every_warp_reaches_an_existing_spawn() -> void:
	for id: StringName in MAPS.keys() + INTERIORS:
		for warp: Warp in _map(id).get_warps().get_all():
			if warp.target_map.is_empty():
				assert_false(warp.coming_soon.is_empty(), "%s : passage sans cible" % id)
				continue
			if OTHER_JALONS.has(warp.target_map) and not MapCatalog.has_map(warp.target_map):
				continue
			assert_true(MapCatalog.has_map(warp.target_map), "%s → %s" % [id, warp.target_map])
			var target := _map(warp.target_map)
			assert_true(target.has_spawn(warp.target_spawn), "%s → %s / %s" % [id,
				warp.target_map, warp.target_spawn])


func test_ladders_link_the_floors_both_ways() -> void:
	var pairs: Array = [[&"mt_silver_1f", &"mt_silver_2f"], [&"mt_silver_2f", &"mt_silver_3f"],
		[&"mt_silver_3f", &"mt_silver_summit"]]
	for pair: Array in pairs:
		for way: Array in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var count := 0
			for warp: Warp in _map(way[0]).get_warps().get_all():
				if warp.target_map == way[1]:
					count += 1
			assert_eq(count, 1, "%s → %s : une échelle" % way)


## Grotte 1F : deux rochers de Force sur leurs cases (A-15), lac surfable, sortie ouest vers la
## Route 28.
func test_first_floor_boulders_and_lake() -> void:
	var map := _map(&"mt_silver_1f")
	var setup := _boulder_setup(map)
	assert_not_null(setup, "nœud Boulders")
	if setup != null:
		assert_eq(setup.get(&"boulder_cells"), [Vector2i(12, 8), Vector2i(22, 4)] as Array[Vector2i])
	assert_eq(map.surf_cells.size(), _plan(&"mt_silver_1f").cells_of("w").size())
	var to_route := 0
	for warp: Warp in map.get_warps().get_all():
		if warp.target_map == &"route_28":
			to_route += 1
	assert_eq(to_route, 1, "sortie ouest (0, 23)")


func test_story_triggers_and_examines() -> void:
	var expected: Dictionary = {&"mt_silver_outside": [&"mt_silver_relay"],
		&"mt_silver_2f": [&"mt_silver_2f_rival"], &"mt_silver_3f": [&"mt_silver_3f_wind"],
		&"mt_silver_summit": [&"mt_silver_summit"],
		&"route_28_gate": [&"route_28_gate_check", &"route_28_gate_south"]}
	for id: StringName in expected:
		var scenes: Array[StringName] = []
		for trigger: Node in _map(id).get_node(^"Triggers").get_children():
			var scene: StringName = trigger.get(&"cutscene_id")
			if not scenes.has(scene):
				scenes.append(scene)
		assert_eq(scenes, expected[id] as Array[StringName], String(id))
	var dialogues: Array[StringName] = []
	for point: Node in _map(&"mt_silver_summit").get_node(^"Interactables").get_children():
		dialogues.append(point.get(&"dialogue_id"))
	assert_has(dialogues, &"mt_silver_summit_ruines")
	assert_has(dialogues, &"mt_silver_summit_echarpe")


func test_summit_forbids_fly_and_teleport() -> void:
	assert_true(_map(&"mt_silver_summit").no_fly)
	assert_true(_map(&"mt_silver_summit").no_teleport)
	for id: StringName in [&"silver_trail", &"mt_silver_outside", &"route_28"]:
		assert_false(_map(id).no_fly, String(id))


## Variante `JOH9` de la Route 22 ouest : la porte neuve et l'arrivée existent, actives avec
## `johto_arrived` seulement ; les cases du poste sont occupées (pas solides : la grille de base
## du J29 reste exacte, `test_j29_maps`).
func test_route_22_west_variant() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_22_ouest.txt", "JOH9"), plan.error)
	var map := _map(&"route_22_west")
	var door: Vector2i = plan.cell_of("porte_route_28")
	assert_true(map.has_spawn(&"from_route_28_gate"))
	assert_eq(map.get_spawn_cell(&"from_route_28_gate"), plan.cell_of("from_route_28_gate"))
	var trigger := map.get_node_or_null(^"Triggers/Joh9PorteRoute28")
	assert_not_null(trigger, "porte neuve : déclencheur vers la gauche")
	if trigger != null:
		assert_eq(trigger.get(&"cutscene_id"), &"route_22_route_28_door")
		assert_eq(trigger.get(&"direction"), Vector2i.LEFT)
		assert_eq(Vector2i((trigger as Node2D).position / 96.0), door + Vector2i(0, 1))
	for warp: Warp in map.get_warps().get_all():
		assert_ne(warp.target_map, &"route_28_gate", "aucun passage ajouté (test_j29_maps)")
	var gate := map.get_node_or_null(^"Entities/Joh9Poste") as FlagGate
	assert_not_null(gate)
	if gate != null:
		assert_eq(gate.if_flags, [&"johto_arrived"] as Array[StringName])
		assert_false(gate.is_open(StoryFlags.new()), "Kanto seul : pas de poste")
		assert_false(map.get_grid().is_solid(Vector2i(2, 11)), "case occupée, jamais solide")


func test_oak_lab_epilogue_trigger() -> void:
	var trigger := _map(&"oak_lab").get_node_or_null(^"Triggers/Joh9Epilogue")
	assert_not_null(trigger)
	if trigger != null:
		assert_eq(trigger.get(&"cutscene_id"), &"johto_epilogue")
		assert_eq(trigger.get(&"direction"), Vector2i.UP)
