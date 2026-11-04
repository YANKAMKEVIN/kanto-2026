extends GutTest
## JOH5 (`docs/tech/jalon-joh5.md` §2.1, §2.7) : les six cartes de la Tour Radio construites par
## `tools/build_joh5_radio_tower.gd` suivent leurs grilles (`tools/plans/radio_tower_<n>f.txt`,
## elles font foi) : cases bloquées, escaliers appariés, sortie vers Doublonville, ascenseur fermé
## jusqu'à Cenere, déclencheurs et points de la grille, PNJ des données sur des cases libres, et
## les passages **inévitables** (dossier §5) : la case vue par le Sbire est le seul chemin.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR := "res://game/world/maps/"
const FLOORS: Array[int] = [1, 2, 3, 4, 5]
## Étage → [arrivée, but, cases qui coupent le seul passage : la case vue (ou la scène) et la
## case du gardien lui-même] (dossier §5, en-têtes des grilles).
const UNAVOIDABLE: Dictionary = {
	1: [Vector2i(11, 14), Vector2i(3, 1), [Vector2i(3, 2), Vector2i(4, 2)]],
	2: [Vector2i(3, 1), Vector2i(20, 1), [Vector2i(11, 11), Vector2i(11, 12)]],
	3: [Vector2i(20, 1), Vector2i(3, 1), [Vector2i(13, 12), Vector2i(13, 11)]],
	4: [Vector2i(3, 1), Vector2i(20, 1), [Vector2i(20, 3)]],
	5: [Vector2i(20, 1), Vector2i(12, 10), [Vector2i(12, 6), Vector2i(13, 6)]],
}


func _plan(floor_number: int) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/radio_tower_%df.txt" % floor_number), plan.error)
	return plan


func _map(map_id: String) -> Node2D:
	var packed := load(MAPS_DIR + map_id + ".tscn") as PackedScene
	assert_not_null(packed, map_id)
	var map := packed.instantiate() as Node2D
	add_child_autofree(map)
	return map


func _cell(node: Node2D) -> Vector2i:
	return Vector2i(int(node.position.x) / 96, int(node.position.y) / 96 - 1)


func test_every_floor_follows_its_grid() -> void:
	for floor_number: int in FLOORS:
		var map_id := "goldenrod_radio_tower_%df" % floor_number
		var plan := _plan(floor_number)
		var map := _map(map_id)
		assert_eq(map.get(&"map_id"), StringName(map_id))
		assert_eq(map.get(&"display_name"), "Tour Radio")
		assert_true(map.get(&"interior"), "%s : intérieur" % map_id)
		var blocked: Array[Vector2i] = map.get(&"blocked_cells")
		var expected: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				if not plan.is_walkable(Vector2i(x, y)):
					expected.append(Vector2i(x, y))
		blocked.sort()
		expected.sort()
		assert_eq(blocked, expected, "%s : cases bloquées = grille" % map_id)
		# Points d'apparition de la grille.
		for id: String in plan.positions:
			if plan.positions[id]["kind"] == "spawn":
				var marker := map.get_node_or_null("Spawns/" + id) as Node2D
				assert_not_null(marker, "%s : arrivée %s" % [map_id, id])
				if marker != null:
					assert_eq(_cell(marker), plan.cell_of(id), "%s : %s" % [map_id, id])


func test_stairs_and_exits_are_paired() -> void:
	for floor_number: int in FLOORS:
		var map_id := "goldenrod_radio_tower_%df" % floor_number
		var map := _map(map_id)
		for warp: Node in map.get_node(^"Warps").get_children():
			var target := String(warp.get(&"target_map"))
			var spawn := String(warp.get(&"target_spawn"))
			if target == "goldenrod_city":
				assert_eq(floor_number, 1, "sortie au 1F seulement")
				assert_eq(spawn, "retour_tour_radio")
				assert_eq(warp.get(&"trigger"), Warp.Trigger.PUSH)
				continue
			if warp.name == "ElevatorDoor":
				assert_eq(target, "goldenrod_radio_tower_elevator")
				assert_eq(warp.get(&"if_flags"), [&"johto_cenere_defeated"] as Array[StringName],
					"%s : ascenseur en panne jusqu'à Cenere" % map_id)
				continue
			var target_map := _map(target)
			assert_not_null(target_map.get_node_or_null("Spawns/" + spawn),
				"%s : %s → %s:%s" % [map_id, warp.name, target, spawn])


func test_elevator_serves_the_five_floors() -> void:
	var elevators := ElevatorLibrary.new()
	assert_true(elevators.load_file())
	assert_true(elevators.is_car(&"goldenrod_radio_tower_elevator"))
	var car := _map("goldenrod_radio_tower_elevator")
	assert_not_null(car.get_node_or_null("Spawns/entrance"))
	for floor_number: int in FLOORS:
		var map := _map("goldenrod_radio_tower_%df" % floor_number)
		assert_not_null(map.get_node_or_null("Spawns/from_elevator"), "étage %d" % floor_number)


func test_triggers_points_and_doors() -> void:
	var triggers: Dictionary = {}
	var points: Dictionary = {}
	for floor_number: int in FLOORS:
		var map := _map("goldenrod_radio_tower_%df" % floor_number)
		for trigger: Node in map.get_node(^"Triggers").get_children():
			triggers[trigger.name] = trigger.get(&"cutscene_id")
		for point: Node in map.get_node(^"Interactables").get_children():
			points[point.name] = point.get(&"dialogue_id")
	assert_eq(triggers, {&"scene_bureau": &"goldenrod_radio_office",
		&"scene_cenere": &"goldenrod_radio_cenere", &"scene_impostor": &"goldenrod_radio_impostor",
		&"scene_sortie": &"goldenrod_radio_exit"})
	assert_eq(points.get(&"Open_porte_reserve"), &"goldenrod_radio_reserve_door")
	assert_eq(points.get(&"Open_porte_bureau"), &"goldenrod_radio_office_locked")
	assert_eq(points.get(&"Hidden_radio_3f_hidden_1"), &"radio_3f_hidden_1")
	assert_eq(points.get(&"Examine_pupitre_diffusion"), &"goldenrod_radio_console")
	var third := _map("goldenrod_radio_tower_3f")
	var reserve := third.get_node(^"%Entities/LockedDoor_porte_reserve") as FlagGate
	assert_eq(reserve.blocking_cells, [Vector2i(17, 11)] as Array[Vector2i])
	var flags := StoryFlags.new()
	reserve.apply(flags)
	assert_true(reserve.visible, "réserve fermée")
	flags.set_flag(&"johto_radio_staff_freed")
	reserve.apply(flags)
	assert_false(reserve.visible, "réserve ouverte")
	var fifth := _map("goldenrod_radio_tower_5f")
	var office := fifth.get_node(^"%Entities/LockedDoor_porte_bureau") as FlagGate
	office.apply(flags)
	assert_true(office.visible, "bureau fermé tant que Dante n'a pas parlé")
	flags.set_flag(&"johto_dante_revealed")
	office.apply(flags)
	assert_false(office.visible, "bureau ouvert")
	var scene_exit := (_map("goldenrod_radio_tower_1f").get_node(^"Triggers/scene_sortie")
		as Node2D)
	assert_eq(scene_exit.get(&"size"), Vector2i(22, 1), "toute la largeur du hall")


func test_npcs_stand_on_free_cells() -> void:
	for floor_number: int in FLOORS:
		var plan := _plan(floor_number)
		var roster := NpcRoster.load_for_map(StringName("goldenrod_radio_tower_%df" % floor_number))
		assert_not_null(roster)
		for spec: NpcSpec in roster.get_all():
			if spec.id == &"poke_balls":
				assert_false(plan.is_walkable(spec.cell), "les Poké Balls sont sur le bureau")
				continue
			assert_true(plan.is_walkable(spec.cell), "%dF : %s sur une case libre" % [floor_number,
				spec.id])


func test_unavoidable_passages() -> void:
	for floor_number: int in UNAVOIDABLE:
		var plan := _plan(floor_number)
		var entry: Array = UNAVOIDABLE[floor_number]
		assert_true(_reachable(plan, entry[0], entry[1], []), "%dF : chemin ouvert" % floor_number)
		assert_false(_reachable(plan, entry[0], entry[1], entry[2]),
			"%dF : %s est le seul passage" % [floor_number, entry[2]])


## Parcours en largeur sur les cases praticables, [param cut] exclues ; PNJ ignorés, escaliers et
## sorties traversables comme dans la grille.
func _reachable(plan: PlanGrid, from: Vector2i, to: Vector2i, cut: Array) -> bool:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			return true
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + step
			if seen.has(next) or cut.has(next) or next.x < 0 or next.y < 0 \
					or next.x >= plan.width or next.y >= plan.height:
				continue
			if not plan.is_walkable(next) or plan.at(next) == "K":
				continue
			seen[next] = true
			queue.append(next)
	return false
