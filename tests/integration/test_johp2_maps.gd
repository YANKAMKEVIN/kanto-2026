extends GutTest
## Arc des Pierres, JOHP2 : les quatre cartes construites depuis leurs grilles
## (`tools/build_johp2_maps.gd`), les intérieurs (`build_painted_interiors.gd --cianwood`) et la
## variante ARC d'Oliville (`build_joh1_olivine.gd`) : grille = plan, aucune eau surfable (A-6),
## raccords, vannes et gués ([FlagGate]), pas de blocage possible, Goéland derrière la quête.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const PLANS: Array[StringName] = [&"goeland_deck", &"cianwood_city", &"tide_cave_1f", &"tide_cave_b1f"]
const INTERIORS: Array[StringName] = [&"cianwood_center", &"cianwood_goulven_house",
	&"cianwood_house_1"]
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
		var map := (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate() as GameMap
		_cache[id] = map
		map.get_grid()
	return _cache[id]


func _plan(id: StringName) -> Object:
	if not _plans.has(id):
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % id), plan.error)
		_plans[id] = plan
	return _plans[id]


## Carte cible du passage posé sur [param cell].
func _target(id: StringName, cell: Vector2i) -> StringName:
	var warps := _map(id).get_warps().get_at(cell)
	assert_eq(warps.size(), 1, "%s %s : un passage" % [id, cell])
	return warps[0].target_map if not warps.is_empty() else &""


func _gate(map: GameMap, path: NodePath) -> FlagGate:
	return map.get_node(path) as FlagGate


func _reachable(map: GameMap, from: Vector2i) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in DIRS:
			var next := current + direction
			if seen.has(next) or not grid.is_in_bounds(next) or not grid.can_enter(next, direction):
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
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
	assert_eq(_map(&"cianwood_city").display_name, "Irisia")
	assert_eq(_map(&"tide_cave_1f").display_name, "Grotte de la Marée")
	assert_eq(_map(&"goeland_deck").display_name, "Le Goéland")


## La grille fait foi : une case est praticable dans la scène si et seulement si elle l'est dans la
## grille et qu'aucune position bloquante ne l'occupe (les gués du B1F sont fermés par défaut).
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in PLANS:
		var map := _map(id)
		var plan: Object = _plan(id)
		var grid := map.get_grid()
		var occupied: Dictionary = {}
		for key: String in plan.positions:
			var entry: Dictionary = plan.positions[key]
			if entry["blocks"] and not NPC_KINDS.has(entry["kind"]):
				for cell: Vector2i in entry["cells"]:
					occupied[cell] = true
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var mark: String = plan.at(cell)
				var walkable: bool = plan.walkable.contains(mark) and not occupied.has(cell) \
					and not "ab".contains(mark)
				assert_eq(grid.can_enter(cell, Vector2i.DOWN), walkable, "%s %s « %s »" % [id, cell, mark])


func test_no_surfable_water_in_the_arc() -> void:
	for id: StringName in PLANS:
		assert_eq(_map(id).surf_cells.size(), 0, "%s : A-6" % id)


func test_cave_and_city_are_linked_both_ways() -> void:
	for way: Array in [[&"cianwood_city", Vector2i(4, 14), &"tide_cave_1f"],
			[&"cianwood_city", Vector2i(4, 15), &"tide_cave_1f"],
			[&"tide_cave_1f", Vector2i(24, 9), &"cianwood_city"],
			[&"tide_cave_1f", Vector2i(5, 16), &"tide_cave_b1f"],
			[&"tide_cave_b1f", Vector2i(3, 2), &"tide_cave_1f"]]:
		assert_eq(_target(way[0], way[1]), way[2], "%s %s" % [way[0], way[1]])
		var target := _map(way[2])
		for warp: Warp in _map(way[0]).get_warps().get_at(way[1]):
			assert_true(target.has_spawn(warp.target_spawn), String(warp.target_spawn))
			assert_true(target.get_grid().can_enter(target.get_spawn_cell(warp.target_spawn),
				Vector2i.DOWN), "%s / %s libre" % [way[2], warp.target_spawn])


func test_doors_of_cianwood() -> void:
	assert_eq(_target(&"cianwood_city", Vector2i(21, 13)), &"cianwood_center")
	assert_eq(_target(&"cianwood_city", Vector2i(22, 13)), &"cianwood_center")
	assert_eq(_target(&"cianwood_city", Vector2i(10, 13)), &"cianwood_goulven_house")
	assert_eq(_target(&"cianwood_city", Vector2i(21, 21)), &"cianwood_house_1")
	for id: StringName in INTERIORS:
		assert_eq(_target(id, Vector2i(7, 8)), &"cianwood_city", String(id))
		for warp: Warp in _map(id).get_warps().get_all():
			assert_true(_map(&"cianwood_city").has_spawn(warp.target_spawn),
				"%s → %s" % [id, warp.target_spawn])


## §8.2 : les gués s'ouvrent l'un après l'autre, sans blocage ni Surf.
func test_valves_open_the_fords_in_order() -> void:
	var map := _map(&"tide_cave_b1f")
	var ford_a := _gate(map, ^"Entities/GueA")
	var ford_b := _gate(map, ^"Entities/GueB")
	var flags := StoryFlags.new()
	var vanne_2 := Vector2i(16, 2)
	var socle_side := Vector2i(7, 11)
	var start := Vector2i(3, 3)
	assert_true(_reachable(map, start).has(Vector2i(6, 2)), "vanne 1 abordable d'emblée")
	assert_false(_reachable(map, start).has(vanne_2), "pas de vanne 2 sans le premier gué")
	flags.set_flag(&"johto_tide_valve_1")
	ford_a.apply(flags)
	ford_a.apply_to_grid(map.get_grid())
	assert_true(_reachable(map, start).has(vanne_2), "le gué a mène au quai est")
	assert_false(_reachable(map, start).has(socle_side), "pas de socle sans le second gué")
	flags.set_flag(&"johto_tide_valves_done")
	ford_b.apply(flags)
	ford_b.apply_to_grid(map.get_grid())
	assert_true(_reachable(map, start).has(Vector2i(9, 11)), "le gué b mène à la rive sud")
	# Remet les gués fermés pour les tests suivants.
	flags = StoryFlags.new()
	for ford: FlagGate in [ford_a, ford_b]:
		ford.apply(flags)
		ford.apply_to_grid(map.get_grid())


func test_black_boat_follows_the_flag() -> void:
	var flags := StoryFlags.new()
	var boat := _gate(_map(&"cianwood_city"), ^"Decor/BateauNoir")
	assert_true(boat.is_open(flags), "le bateau noir à l'ancre")
	flags.set_flag(&"johto_stone_tide_lost")
	assert_false(boat.is_open(flags), "parti après le revers")
	for id: StringName in [&"cianwood_city", &"tide_cave_b1f"]:
		var hull := _map(id).get_node(^"Decor/BateauNoir/Coque") as Sprite2D
		assert_not_null(hull, "%s : bateau peint" % id)
		if hull != null:
			assert_eq(hull.texture.resource_path, "res://assets/world/props/prop_bateau_noir_01.png")


func test_cianwood_has_fishable_water_on_its_shores() -> void:
	var water := _map(&"cianwood_city").fishable_set()
	assert_true(water.has(Vector2i(31, 14)), "bout du quai")
	assert_true(water.has(Vector2i(16, 26)), "sud de la plage")
	assert_false(water.has(Vector2i(0, 0)), "le large")


## Variante ARC : le Goéland ne bloque rien sans la quête (Oliville de base inchangée).
func test_olivine_keeps_its_sea_until_the_quest() -> void:
	var map := _map(&"olivine_city")
	var boat := _gate(map, ^"Entities/Goeland")
	assert_false(boat.is_open(StoryFlags.new()), "base inchangée sans l'arc")
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_stones_quest")
	assert_true(boat.is_open(flags), "amarré pendant l'arc")
	assert_eq(boat.blocking_cells.size(), 24, "42..47 × 34..37")
	var hull := boat.get_node_or_null(^"Coque") as Sprite2D
	assert_not_null(hull, "Goéland peint")
	if hull != null:
		assert_eq(hull.texture.resource_path, "res://assets/world/props/prop_goeland_01.png")
	assert_not_null(map.get_node_or_null(^"Spawns/from_goeland"))
	assert_not_null(map.get_node_or_null(^"Triggers/BarriereMerSud"))
