extends GutTest
## Intérieurs d'Argenta (jalon 10 T13, docs/tech/jalon-10.md §2.2 ; dossier 12 §7, §8, §10,
## §19) sur les vraies scènes : métadonnées et lumière, sorties vers Argenta (spawns `from_*`
## que la carte de la ville du T11 doit porter), Centre et Boutique = définitions de Jadielle
## hors identifiants, point de repos, cases solides = grille de chaque pièce
## (`tools/plans/argenta_*.txt`), Musée (passage entre les salles, vitrines, laboratoire fermé),
## Arène (critères du §1.3 : caméra immobile, Pierre atteignable, vision de Liam, détour), PNJ
## posés sur leurs cases.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
## Carte → [taille, sortie (cases), carte et spawn de la sortie, grille (vide : Centre et
## Boutique), caractères praticables de la grille (cases des PNJ comprises)].
const ROOMS := {
	&"pewter_center": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"pewter_city", &"from_center"], "", ""],
	&"pewter_mart": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"pewter_city", &"from_mart"], "", ""],
	&"pewter_museum": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"pewter_city", &"from_museum"], "argenta_musee.txt", ".DX"],
	&"pewter_museum_science": [Vector2i(15, 10),
		[Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)], [&"pewter_museum", &"from_science"],
		"argenta_musee_science.txt", ".Xc"],
	&"pewter_gym": [Vector2i(15, 11), [Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9)],
		[&"pewter_city", &"from_gym"], "argenta_arene.txt", ".XPLG"],
	&"pewter_house_mason": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"pewter_city", &"from_house_mason"], "argenta_maison_tailleur.txt", ".Xae"],
	&"pewter_house_researcher": [Vector2i(15, 10),
		[Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"pewter_city", &"from_house_researcher"], "argenta_maison_chercheuse.txt", ".Xc"],
}
## PNJ attendus sur chaque carte (data/npcs/<carte>.json) : identifiant → case.
const NPCS := {
	&"pewter_center": {&"nurse": Vector2i(7, 3)},
	&"pewter_mart": {&"clerk": Vector2i(7, 3)},
	&"pewter_museum_science": {&"researcher": Vector2i(4, 6), &"researcher_f": Vector2i(10, 6)},
	&"pewter_gym": {&"brock": Vector2i(7, 2), &"camper_liam": Vector2i(2, 6),
		&"gym_guide": Vector2i(5, 8)},
	&"pewter_house_mason": {&"partner": Vector2i(3, 4), &"kid": Vector2i(12, 6)},
	&"pewter_house_researcher": {&"researcher": Vector2i(11, 5)},
}

var _maps: Dictionary = {}


func before_all() -> void:
	for id: StringName in ROOMS.keys() + [&"viridian_center", &"viridian_mart"]:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


## Copie des seules cases solides (sans l'occupation des PNJ).
func _terrain(map: GameMap) -> GridWorld:
	var grid := map.get_grid()
	var terrain := GridWorld.new(map.size)
	for y: int in map.size.y:
		for x: int in map.size.x:
			if grid.is_solid(Vector2i(x, y)):
				terrain.set_solid(Vector2i(x, y))
	return terrain


func test_metadata_light_and_shell() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		assert_eq(map.map_id, id)
		assert_eq(map.size, ROOMS[id][0], String(id))
		assert_eq(map.display_name, "Argenta", "%s : titre de la ville" % id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
		assert_eq(lighting.get_map_profile(id), &"interior_warm", "%s au plan" % id)
		var shell := map.get_node(^"Shell") as Sprite2D
		assert_eq(shell.texture.get_size(), Vector2(map.size * Grid.TILE_SIZE), String(id))
		assert_true(map.get_entities().y_sort_enabled)


func test_exits_lead_back_with_the_planned_spawn() -> void:
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		var target: Array = ROOMS[id][2]
		for cell: Vector2i in ROOMS[id][1]:
			assert_false(map.get_grid().is_solid(cell), "%s : sortie %s praticable" % [id, cell])
			var warp := map.get_warps().find_on_push(cell, Vector2i.DOWN)
			assert_not_null(warp, "%s : sortie %s" % [id, cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], target, String(id))
				assert_eq(warp.facing, Vector2i.DOWN, "%s : tourné vers la ville" % id)
		var entry := &"from_hall" if id == &"pewter_museum_science" else &"entrance"
		assert_true((ROOMS[id][1] as Array).has(map.get_spawn_cell(entry)),
			"%s : on arrive sur la sortie" % id)


func test_solid_cells_follow_the_room_grid() -> void:
	for id: StringName in ROOMS:
		if (ROOMS[id][3] as String).is_empty():
			continue
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/" + ROOMS[id][3]), plan.error)
		var walkable: String = ROOMS[id][4]
		var terrain := _terrain(_maps[id])
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(terrain.is_solid(cell), not walkable.contains(plan.at(cell)),
					"%s %s « %s »" % [id, cell, plan.at(cell)])


func test_center_and_mart_are_the_viridian_definitions() -> void:
	for pair: Array in [[&"pewter_center", &"viridian_center"], [&"pewter_mart",
			&"viridian_mart"]]:
		var pewter: GameMap = _maps[pair[0]]
		var viridian: GameMap = _maps[pair[1]]
		assert_eq(pewter.blocked_cells, viridian.blocked_cells, String(pair[0]))
		assert_eq((pewter.get_node(^"Shell") as Sprite2D).texture,
			(viridian.get_node(^"Shell") as Sprite2D).texture)
		assert_eq(_layout(pewter.get_entities()), _layout(viridian.get_entities()),
			"%s : mêmes meubles aux mêmes places" % pair[0])
		assert_eq(_layout(pewter.get_node(^"Interactables")),
			_layout(viridian.get_node(^"Interactables")), String(pair[0]))
		assert_eq(_layout(pewter.get_node(^"Spawns")), _layout(viridian.get_node(^"Spawns")))
	# Le colis reste propre à Jadielle.
	assert_eq(_maps[&"pewter_mart"].get_node(^"Triggers").get_child_count(), 0)
	assert_eq(_maps[&"viridian_mart"].get_node(^"Triggers").get_child_count(), 1)
	assert_not_null(_maps[&"pewter_center"].get_node_or_null(^"%HealMachine"), "machine de soin")


## [nom, scène ou script, position] des enfants (PNJ créés à l'exécution exclus).
func _layout(parent: Node) -> Array:
	var rows: Array = []
	for child: Node in parent.get_children():
		if child is Npc:
			continue
		var source := child.scene_file_path
		if source.is_empty() and child.get_script() != null:
			source = (child.get_script() as Script).resource_path
		rows.append([String(child.name), source, (child as Node2D).position])
	return rows


func test_pewter_center_is_a_rest_point_named_argenta() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"pewter_center")
	assert_not_null(point, "point de repos du Centre d'Argenta")
	if point == null:
		return
	assert_true(point.registers)
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(point.facing, Vector2i.UP)
	var map: GameMap = _maps[&"pewter_center"]
	assert_eq(map.get_spawn_cell(point.spawn), Vector2i(7, 5))
	assert_not_null(InteractionFinder.find(map.get_grid(), map.get_interactions(),
		Vector2i(7, 5), Vector2i.UP), "au réveil, l'infirmière est devant")
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"pewter_center"), &"pewter_city")
	assert_eq(" — ".join(points.registered_toast(zones.get_zone(&"pewter_city").name)),
		"Point de repos enregistré — Argenta", "dossier 12 §8")


func test_npcs_stand_on_their_cells() -> void:
	for id: StringName in NPCS:
		var map: GameMap = _maps[id]
		for npc_id: StringName in NPCS[id]:
			var npc := map.get_npc(npc_id)
			assert_not_null(npc, "%s : %s" % [id, npc_id])
			if npc != null:
				assert_eq(npc.get_cell(), NPCS[id][npc_id], "%s : %s" % [id, npc_id])
				assert_true(CharacterLook.resolve(npc.get_spec().sprite).painted,
					"%s : %s peint" % [id, npc_id])
	assert_eq(_maps[&"pewter_museum"].get_node(^"Entities").get_children().filter(
		func(n: Node) -> bool: return n is Npc).size(), 0, "salle principale silencieuse")


func test_museum_rooms_are_linked_by_the_north_arch() -> void:
	var hall: GameMap = _maps[&"pewter_museum"]
	var science: GameMap = _maps[&"pewter_museum_science"]
	for x: int in [6, 7, 8]:
		var warp := hall.get_warps().find_on_step(Vector2i(x, 2), Vector2i.UP)
		assert_not_null(warp, "arche (%d, 2)" % x)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn],
				[&"pewter_museum_science", &"from_hall"])
	var reach := _terrain(hall).find_reachable(hall.get_spawn_cell(&"entrance"))
	assert_true(reach.has(Vector2i(7, 3)), "on atteint l'arche depuis l'entrée")
	assert_eq(hall.get_spawn_cell(&"from_science"), Vector2i(7, 3))
	assert_eq(science.get_spawn_cell(&"from_hall"), Vector2i(7, 8))


func test_museum_cases_and_the_closed_lab_are_examined() -> void:
	var hall: GameMap = _maps[&"pewter_museum"]
	var checks := [
		[hall, Vector2i(2, 5), Vector2i.UP, &"pewter_museum_dome"],
		[hall, Vector2i(12, 5), Vector2i.UP, &"pewter_museum_helix"],
		[hall, Vector2i(7, 6), Vector2i.UP, &"pewter_museum_moon_stone"],
		[hall, Vector2i(6, 5), Vector2i.RIGHT, &"pewter_museum_moon_stone"],
	]
	var science: GameMap = _maps[&"pewter_museum_science"]
	checks.append_array([
		[science, Vector2i(6, 3), Vector2i.UP, &"pewter_museum_lab_sign"],
		[science, Vector2i(7, 3), Vector2i.UP, &"pewter_museum_lab_door"],
		[science, Vector2i(8, 3), Vector2i.UP, &"pewter_museum_lab_door"],
		[science, Vector2i(3, 5), Vector2i.UP, &"pewter_museum_science_panel"],
		[science, Vector2i(11, 5), Vector2i.UP, &"pewter_museum_journal"],
	])
	for row: Array in checks:
		var map: GameMap = row[0]
		var found := InteractionFinder.find(map.get_grid(), map.get_interactions(), row[1], row[2])
		assert_not_null(found, "%s %s" % [row[3], row[1]])
		if found != null:
			assert_eq(found.dialogue_id, row[3])
	# Laboratoire fermé : aucun passage dans l'arche de la salle science.
	for x: int in [6, 7, 8]:
		assert_true(science.get_grid().is_solid(Vector2i(x, 2)), "porte fermée (%d, 2)" % x)
		assert_null(science.get_warps().find_on_step(Vector2i(x, 2), Vector2i.UP))
	assert_not_null(science.get_entities().get_node_or_null(^"LabDoor"), "porte peinte")


func test_gym_criteria_on_the_real_scene() -> void:
	var gym: GameMap = _maps[&"pewter_gym"]
	var rect := Rect2i(Vector2i.ZERO, gym.size * Grid.TILE_SIZE)
	assert_true(CameraFraming.is_static(rect, Vector2(1920, 1080)),
		"salle entière à l'écran : Pierre visible depuis l'entrée")
	var terrain := _terrain(gym)
	var entrance := gym.get_spawn_cell(&"entrance")
	assert_eq(entrance, Vector2i(7, 9))
	# Les PNJ occupent leur case : on les pose comme obstacles (sauf Liam, sa vision suit).
	for cell: Vector2i in [Vector2i(7, 2), Vector2i(2, 6), Vector2i(5, 8)]:
		terrain.set_solid(cell)
	var talk := Vector2i(7, 3)
	assert_eq(_distance(terrain, entrance, talk), 6, "chemin direct : 6 pas")
	var vision: Array[Vector2i] = []
	for x: int in range(3, 8):
		assert_false(terrain.is_solid(Vector2i(x, 6)), "vision de Liam (%d, 6)" % x)
		vision.append(Vector2i(x, 6))
	assert_true(terrain.is_solid(Vector2i(8, 6)), "le bloc central arrête sa vision")
	for cell: Vector2i in vision:
		terrain.set_solid(cell)
	assert_eq(_distance(terrain, entrance, talk), 12, "détour hors de sa vision : 12 pas")
	for name: String in ["PillarNorthWest", "PillarNorthEast", "CentralRocks",
			"RockStageWest", "RockStageEast"]:
		assert_not_null(gym.get_entities().get_node_or_null(NodePath(name)), name)


## Pas entre deux cases (parcours en largeur, 4 directions ; -1 si inaccessible).
func _distance(grid: GridWorld, from: Vector2i, to: Vector2i) -> int:
	var dist: Dictionary[Vector2i, int] = {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			return dist[cell]
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + d
			if grid.is_in_bounds(next) and not grid.is_solid(next) and not dist.has(next):
				dist[next] = dist[cell] + 1
				queue.append(next)
	return -1
