extends GutTest
## Sylphe SARL (jalon 26, T7 ; `docs/tech/jalon-26.md` §2.1, §2.2) : les douze scènes suivent leurs
## grilles (`tools/plans/sylphe_*.txt`, la grille fait foi) — cases bloquées, points
## d'apparition, escaliers, téléporteurs, portes d'ascenseur, portes à carte, sortie du 1F ;
## titre, lumière et catégorie (« grotte » de `caves.json`, comme le repaire Rocket).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const CAR := &"silph_co_elevator"
## Positions de la grille que la scène reproduit (le reste — Dresseurs, PNJ, objets, rival,
## Giovanni, déclencheurs — vient au T9).
const WARP_KINDS: Array[String] = ["escalier", "teleporteur", "ascenseur", "sortie", "warp"]

var _maps: Dictionary[StringName, GameMap] = {}
var _plans: Dictionary[StringName, PlanGrid] = {}


func before_all() -> void:
	for map_id: StringName in _ids():
		var plan := PlanGrid.new()
		var plan_name := "sylphe_ascenseur" if map_id == CAR \
			else "sylphe_" + String(map_id).trim_prefix("silph_co_")
		assert_true(plan.load_file("res://tools/plans/%s.txt" % plan_name), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


static func _ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for n: int in range(1, 12):
		ids.append(StringName("silph_co_%df" % n))
	ids.append(CAR)
	return ids


func test_metadata() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var interiors := MapCatalog.load_interiors()
	for map_id: StringName in _maps:
		var map := _maps[map_id]
		var plan := _plans[map_id]
		assert_eq(map.map_id, map_id)
		assert_eq(map.display_name, "Sylphe SARL", String(map_id))
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(map_id))
		assert_false(map.interior, "%s : « grotte » (compagnon visible, Corde Sortie)" % map_id)
		assert_false(interiors.has(map_id), String(map_id))
		assert_eq(map.light_profile, &"office", String(map_id))
		assert_eq(caves.cave_of(map_id), &"silph_co", String(map_id))
	var exit := caves.get_exits(&"silph_co")
	assert_eq(exit.size(), 1)
	assert_eq([exit[0].map, exit[0].spawn], [&"saffron_city", &"from_silph"],
		"Corde Sortie : devant la porte de la Sylphe")


func test_blocked_cells_follow_the_grid() -> void:
	for map_id: StringName in _maps:
		var plan := _plans[map_id]
		var grid := _maps[map_id].get_grid()
		var wrong: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if grid.is_solid(cell) == plan.is_walkable(cell):
					wrong.append(cell)
		assert_eq(wrong, [] as Array[Vector2i], "%s : cases bloquées = grille" % map_id)


func test_spawns_follow_the_grid() -> void:
	var count := 0
	for map_id: StringName in _maps:
		var plan := _plans[map_id]
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "spawn":
				continue
			count += 1
			assert_true(_maps[map_id].has_spawn(StringName(id)), "%s:%s" % [map_id, id])
			assert_eq(_maps[map_id].get_spawn_cell(StringName(id)), plan.cell_of(id),
				"%s:%s" % [map_id, id])
	assert_eq(count, 67, "points d'apparition des grilles")


func test_warps_follow_the_grid() -> void:
	var counts := {"escalier": 0, "teleporteur": 0, "ascenseur": 0, "sortie": 0, "warp": 0}
	for map_id: StringName in _maps:
		var plan := _plans[map_id]
		var expected := 0
		for id: String in plan.positions:
			var kind: String = plan.positions[id]["kind"]
			if not WARP_KINDS.has(kind):
				continue
			for cell: Vector2i in plan.cells_at(id):
				expected += 1
				counts[kind] += 1
				var found := _maps[map_id].get_warps().get_at(cell)
				var label := "%s:%s %s" % [map_id, id, cell]
				assert_eq(found.size(), 1, label)
				if found.size() != 1:
					continue
				_check_warp(map_id, plan, id, kind, found[0], label)
		assert_eq(_maps[map_id].get_warps().size(), expected, "%s : aucun autre passage" % map_id)
	assert_eq(counts, {"escalier": 20, "teleporteur": 34, "ascenseur": 11, "sortie": 2,
		"warp": 2})


func _check_warp(map_id: StringName, plan: PlanGrid, id: String, kind: String, warp: Warp,
		label: String) -> void:
	match kind:
		"escalier", "teleporteur":
			var vers := plan.attr(id, "vers")
			assert_eq(String(warp.target_map), vers.get_slice(":", 0), label)
			assert_eq(String(warp.target_spawn), vers.get_slice(":", 1), label)
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, label)
			assert_eq(warp.direction, Vector2i.ZERO, label)
			assert_eq(warp.is_teleport(), kind == "teleporteur", label)
			if kind == "teleporteur":
				assert_eq(warp.facing, Vector2i.ZERO, "%s : orientation conservée" % label)
			else:
				assert_eq(warp.facing, Vector2i.DOWN, "%s : arrivée tournée vers le bas" % label)
		"ascenseur":
			assert_eq([warp.target_map, warp.target_spawn], [CAR, &"entrance"], label)
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, label)
			assert_false(warp.is_teleport(), label)
		"sortie":
			assert_eq(map_id, CAR)
			assert_eq([warp.target_map, warp.target_spawn], [&"silph_co_1f", &"from_elevator"],
				"%s : réorientée par l'ascenseur" % label)
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, label)
		"warp":
			assert_eq(map_id, &"silph_co_1f")
			assert_eq([warp.target_map, warp.target_spawn], [&"saffron_city", &"from_silph"], label)
			assert_eq(warp.trigger, Warp.Trigger.PUSH, label)
			assert_eq(warp.direction, Vector2i.DOWN, label)


func test_key_doors_follow_the_grid() -> void:
	var total := 0
	for map_id: StringName in _maps:
		var plan := _plans[map_id]
		var by_id: Dictionary[String, Array] = {}
		for id: String in plan.positions:
			if plan.positions[id]["kind"] == "porte_carte":
				var door_id := plan.attr(id, "id")
				if not by_id.has(door_id):
					by_id[door_id] = []
				by_id[door_id].append_array(plan.cells_at(id))
		var doors: Array[KeyDoor] = []
		for node: Node in _maps[map_id].find_children("*", "KeyDoor", true, false):
			doors.append(node as KeyDoor)
		assert_eq(doors.size(), by_id.size(), "%s : une porte par id" % map_id)
		for door_id: String in by_id:
			total += 1
			var door := _maps[map_id].find_child("KeyDoor_" + door_id, true, false) as KeyDoor
			assert_not_null(door, "%s : KeyDoor_%s" % [map_id, door_id])
			if door == null:
				continue
			var cells: Array[Vector2i] = []
			cells.assign(by_id[door_id])
			cells.sort()
			var blocking := door.blocking_cells.duplicate()
			blocking.sort()
			assert_eq(blocking, cells, "%s : %s sur ses deux cases" % [map_id, door_id])
			assert_eq(door.door_id, StringName(door_id))
			assert_eq(door.key_item, &"card_key")
			assert_eq(door.get_open_flag(), StringName("door_%s_%s_open" % [map_id, door_id]))
	assert_eq(total, 20, "portes électroniques de RB")


func test_elevator_car() -> void:
	var car := _maps[CAR]
	assert_eq(car.get_spawn_cell(&"entrance"), Vector2i(1, 2))
	var panel := car.get_interactions().find(Vector2i(3, 0), Vector2i.UP)
	assert_not_null(panel, "panneau lu depuis (3, 1), tourné vers le haut")
	if panel != null:
		assert_eq(panel.dialogue_id, ElevatorDirector.PANEL_DIALOGUE)
		assert_eq(panel.kind, Interaction.Kind.EXAMINE)
	assert_null(car.get_interactions().find(Vector2i(3, 0), Vector2i.LEFT), "seulement de face")
	for cell: Vector2i in [Vector2i(1, 3), Vector2i(2, 3)]:
		assert_false(car.get_grid().is_solid(cell), "porte du bas %s" % cell)


func test_every_floor_arrival_is_in_front_of_its_way_in() -> void:
	# Escaliers et ascenseur : l'arrivée est une case devant (au sud), praticable et sans passage.
	for map_id: StringName in _maps:
		if map_id == CAR:
			continue
		var map := _maps[map_id]
		for warp: Warp in map.get_warps().get_all():
			if warp.is_teleport() or warp.trigger == Warp.Trigger.PUSH:
				continue
			var spawn: StringName = &"from_elevator" if warp.target_map == CAR \
				else StringName("from_" + String(warp.target_map).trim_prefix("silph_co_"))
			assert_true(map.has_spawn(spawn), "%s : %s" % [map_id, spawn])
			var arrival := map.get_spawn_cell(spawn)
			assert_eq(arrival, warp.cell + Vector2i.DOWN, "%s : %s devant %s" % [map_id, spawn,
				warp.cell])
			assert_true(map.get_warps().get_at(arrival).is_empty(), "%s : %s" % [map_id, spawn])

