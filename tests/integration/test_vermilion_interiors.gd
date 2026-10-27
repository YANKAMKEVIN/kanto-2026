extends GutTest
## Intérieurs de Carmin-sur-Mer et bâtiment de sortie du souterrain de la Route 6 (jalon 15 T14,
## jalon-15.md §2.2 ; dossier 18 §8.2, §17) sur les vraies scènes : métadonnées et lumière,
## sorties (spawns `from_*` que la ville porte), Centre et Boutique = définitions de Jadielle,
## **Centre = point de repos avec Stockage** (contrat du J16), Boutique de Carmin, cases solides
## = grille de chaque pièce (`tools/plans/carmin_*.txt`), habitants (T-33 à T-36, A.4),
## bâtiment du souterrain (escalier, panneau T-14, porte de la Route 6).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const EXITS := [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
## Carte → [spawn de la ville, grille, praticables de la grille].
const ROOMS := {
	&"vermilion_center": [&"from_center", "", ""],
	&"vermilion_mart": [&"from_mart", "", ""],
	&"vermilion_fan_club": [&"from_fan_club", "carmin_fan_club.txt", ".Xcamp"],
	&"vermilion_fisher_house": [&"from_fisher_house", "carmin_pecheur.txt", ".Xh"],
	&"vermilion_house_1": [&"from_house_1", "carmin_maison_1.txt", ".Xh"],
	&"vermilion_house_2": [&"from_house_2", "carmin_maison_2.txt", ".Xh"],
}
## Carte → { PNJ : [apparence, dialogue] }.
const PEOPLE := {
	&"vermilion_fan_club": {
		&"chairman": [&"fan_club_chairman", &"vermilion_fan_club_chairman"],
		&"member_1": [&"lass_young", &"vermilion_fan_club_member"],
		&"member_2": [&"traveler", &"vermilion_fan_club_member_2"],
		&"meowth": [&"pokemon/meowth", &""],
	},
	&"vermilion_fisher_house": {&"fisher": [&"haru", &"vermilion_fisher"]},
	&"vermilion_house_1": {&"resident": [&"old_man", &"vermilion_house_1_resident"]},
	# Jalon 32 (N-14) : l'échangeur Piafabec → Canarticho [D].
	&"vermilion_house_2": {&"resident": [&"lass", &"vermilion_house_2_resident"],
		&"echangeur": [&"old_man", &"j32_trade_leon"]},
	&"vermilion_center": {&"nurse": [&"nurse", &""]},
	&"vermilion_mart": {&"clerk": [&"clerk", &""]},
}

var _maps: Dictionary = {}


func before_all() -> void:
	for id: StringName in ROOMS.keys() + [&"viridian_center", &"viridian_mart",
			&"route_6_underground_gate"]:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _terrain(map: GameMap) -> GridWorld:
	var grid := map.get_grid()
	var terrain := GridWorld.new(map.size)
	for y: int in map.size.y:
		for x: int in map.size.x:
			if grid.is_solid(Vector2i(x, y)):
				terrain.set_solid(Vector2i(x, y))
	return terrain


func test_metadata_light_and_catalog() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		assert_eq(map.map_id, id)
		assert_eq(map.size, Vector2i(15, 10), String(id))
		assert_eq(map.display_name, "Carmin-sur-Mer", String(id))
		assert_true(map.interior, String(id))
		assert_eq(lighting.get_map_profile(id), &"interior_warm", String(id))
		assert_eq(zones.zone_of(id), &"vermilion_city", String(id))
	var gate: GameMap = _maps[&"route_6_underground_gate"]
	assert_true(gate.interior)
	assert_eq(gate.size, Vector2i(10, 8))
	assert_eq(lighting.get_map_profile(&"route_6_underground_gate"), &"interior_warm")


func test_exits_lead_back_to_the_city() -> void:
	var city := (load(MapCatalog.scene_path(&"vermilion_city")) as PackedScene).instantiate() \
		as GameMap
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		for cell: Vector2i in EXITS:
			var warp := map.get_warps().find_on_push(cell, Vector2i.DOWN)
			assert_not_null(warp, "%s : sortie %s" % [id, cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], [&"vermilion_city",
					ROOMS[id][0]], String(id))
		assert_true(EXITS.has(map.get_spawn_cell(&"entrance")), String(id))
		assert_true(city.has_spawn(ROOMS[id][0]), "%s : la ville porte %s" % [id, ROOMS[id][0]])
	city.free()


func test_solid_cells_follow_the_room_grid() -> void:
	for id: StringName in ROOMS:
		if (ROOMS[id][1] as String).is_empty():
			continue
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/" + ROOMS[id][1]), plan.error)
		var walkable: String = ROOMS[id][2]
		assert_eq(plan.walkable, walkable, String(id))
		var terrain := _terrain(_maps[id])
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(terrain.is_solid(cell), not walkable.contains(plan.at(cell)),
					"%s %s « %s »" % [id, cell, plan.at(cell)])


func test_center_and_mart_are_the_viridian_definitions() -> void:
	for pair: Array in [[&"vermilion_center", &"viridian_center"], [&"vermilion_mart",
			&"viridian_mart"]]:
		var here: GameMap = _maps[pair[0]]
		var there: GameMap = _maps[pair[1]]
		assert_eq(here.blocked_cells, there.blocked_cells, String(pair[0]))
		assert_eq((here.get_node(^"Shell") as Sprite2D).texture,
			(there.get_node(^"Shell") as Sprite2D).texture)
	assert_not_null(_maps[&"vermilion_center"].get_node_or_null(^"%HealMachine"))
	var center: GameMap = _maps[&"vermilion_center"]
	var terminal := center.get_interactions().find(Vector2i(1, 3),
		Vector2i.UP)
	assert_not_null(terminal, "Stockage au Centre (contrat du J16)")
	if terminal != null:
		assert_eq(terminal.dialogue_id, &"storage_terminal")
	assert_eq(_maps[&"vermilion_mart"].get_node(^"Triggers").get_child_count(), 0)


func test_center_is_the_rest_point_of_carmin() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"vermilion_center")
	assert_not_null(point, "point de repos (retour après une défaite à bord, J16)")
	if point == null:
		return
	assert_true(point.registers)
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(_maps[&"vermilion_center"].get_spawn_cell(point.spawn), Vector2i(7, 5))
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(" — ".join(points.registered_toast(zones.get_zone(&"vermilion_city").name)),
		"Point de repos enregistré — Carmin-sur-Mer")


func test_mart_sells_super_potion_for_700() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	var shop := shops.get_shop(&"vermilion_mart")
	assert_not_null(shop, "la Boutique de Carmin porte l'identifiant de sa carte")
	if shop != null:
		assert_true(shop.item_ids().has(&"super_potion"))
		assert_true(shop.item_ids().has(&"escape_rope"), "Corde Sortie (T16)")
	assert_eq(items.get_item(&"super_potion").price, 700)


func test_people_stand_on_their_cells_and_say_their_lines() -> void:
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for id: StringName in PEOPLE:
		var map: GameMap = _maps[id]
		var roster := NpcRoster.load_for_map(id)
		var expected: Dictionary = PEOPLE[id]
		assert_eq(roster.get_all().size(), expected.size(), String(id))
		for key: StringName in expected:
			var spec := roster.get_spec(key)
			assert_not_null(spec, "%s/%s" % [id, key])
			if spec == null:
				continue
			assert_eq(spec.sprite, expected[key][0], "%s/%s" % [id, key])
			assert_true(Npc.has_frames(spec.sprite), "%s/%s : planche" % [id, key])
			assert_eq(spec.dialogue, expected[key][1], "%s/%s" % [id, key])
			if not spec.dialogue.is_empty():
				assert_true(dialogues.has_dialogue(spec.dialogue), String(spec.dialogue))
			assert_not_null(map.get_npc(key), "%s/%s posé" % [id, key])
			if spec.dialogue.is_empty() or not spec.is_interactive():
				continue  # Infirmière et vendeur : on leur parle par-dessus le comptoir.
			var dist := GridPaths.distances(_terrain(map), [map.get_spawn_cell(
				&"entrance") if map.has_spawn(&"entrance") else Vector2i(7, 8)])
			var near := false
			for side: Vector2i in GridPaths.DIRECTIONS:
				near = near or dist.has(spec.cell + side)
			assert_true(near, "%s/%s : on peut lui parler" % [id, key])


func test_underground_gate_stairs_sign_and_door() -> void:
	var gate: GameMap = _maps[&"route_6_underground_gate"]
	for cell: Vector2i in [Vector2i(4, 7), Vector2i(5, 7)]:
		var warp := gate.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_not_null(warp, "porte sud %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_6", &"from_underground", Vector2i.DOWN])
	var suffixes := ["w", "e"]
	for i: int in 2:
		var cell := Vector2i(4 + i, 2)
		var warp := gate.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "escalier %s" % cell)
		if warp == null:
			continue
		assert_eq(warp.direction, Vector2i.ZERO, "escalier sans direction")
		assert_false(warp.is_coming_soon(), "escalier %s raccordé" % cell)
		assert_eq([warp.target_map, warp.target_spawn],
			[&"underground_path", StringName("from_route_6_" + suffixes[i])])
	assert_eq(gate.get_spawn_cell(&"from_route_6"), Vector2i(4, 6))
	assert_eq(gate.get_spawn_cell(&"from_underground_w"), Vector2i(4, 3))
	assert_eq(gate.get_spawn_cell(&"from_underground_e"), Vector2i(5, 3))
	var sign := gate.get_interactions().find(Vector2i(7, 2), Vector2i.UP)
	assert_not_null(sign, "panneau T-14")
	if sign != null:
		assert_eq(sign.dialogue_id, &"route_6_underground_gate_sign")
	var dist := GridPaths.distances(_terrain(gate), [Vector2i(4, 6)])
	assert_true(dist.has(Vector2i(4, 2)) and dist.has(Vector2i(7, 3)), "escalier et panneau")
