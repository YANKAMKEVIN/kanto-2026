extends GutTest
## Intérieurs d'Oliville (JOH1 T6, jalon-joh1.md §2.1, §2.5, §2.6 ; dossier JOH 02 §3.3, §8) sur
## les vraies scènes : métadonnées et lumière, sorties vers `olivine_city`, escaliers du Centre et
## de la salle de repos dans les deux sens, cases réservées de la salle atteignables, grille
## `oliville_centre_etage.txt` = cases solides de la scène, point de repos et Boutique. La carte
## `olivine_city` n'est pas chargée ici. Sans PNJ (données écrites à part).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const DOOR_ROW: Array[Vector2i] = [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
const IDS: Array[StringName] = [&"olivine_center", &"olivine_center_room", &"olivine_mart",
	&"olivine_house_1", &"olivine_house_2"]
## Carte → [spawns des trois cases de la porte].
const EXITS := {
	&"olivine_center": [&"from_center", &"from_center", &"from_center_1"],
	&"olivine_mart": [&"from_mart", &"from_mart", &"from_mart_1"],
	&"olivine_house_1": [&"from_house_1", &"from_house_1", &"from_house_1"],
	&"olivine_house_2": [&"from_house_2", &"from_house_2", &"from_house_2"],
}

var _maps: Dictionary = {}


func before_all() -> void:
	for id: StringName in IDS:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _terrain(map: GameMap) -> GridWorld:
	var terrain := GridWorld.new(map.size)
	for y: int in map.size.y:
		for x: int in map.size.x:
			if map.get_grid().is_solid(Vector2i(x, y)):
				terrain.set_solid(Vector2i(x, y))
	return terrain


func test_scenes_metadata_and_light() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	for id: StringName in IDS:
		var map: GameMap = _maps[id]
		assert_eq(map.map_id, id)
		assert_eq(map.size, Vector2i(15, 10), String(id))
		assert_eq(map.display_name, "Oliville", String(id))
		assert_true(map.interior, String(id))
		var expected := &"johto_auto" if id == &"olivine_center_room" else &"interior_warm"
		assert_eq(map.light_profile, expected, String(id))
		var shell := map.get_node(^"Shell") as Sprite2D
		assert_eq(shell.texture.get_size(), Vector2(map.size * Grid.TILE_SIZE), String(id))


func test_interiors_json_lists_them() -> void:
	for id: StringName in IDS:
		assert_true(MapCatalog.scene_path(id).begins_with("res://"), String(id))
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/world/interiors.json"))
	for id: StringName in IDS:
		assert_true((data["maps"] as Array).has(String(id)), "interiors.json : %s" % id)


func test_exits_lead_to_olivine_city() -> void:
	for id: StringName in EXITS:
		var map: GameMap = _maps[id]
		assert_true(map.has_spawn(&"entrance"), String(id))
		for index: int in DOOR_ROW.size():
			var cell: Vector2i = DOOR_ROW[index]
			assert_false(map.get_grid().is_solid(cell), "%s : sortie %s" % [id, cell])
			var warp := map.get_warps().find_on_push(cell, Vector2i.DOWN)
			assert_not_null(warp, "%s : sortie %s" % [id, cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn],
					[&"olivine_city", (EXITS[id] as Array)[index]], "%s %s" % [id, cell])
				assert_eq(warp.facing, Vector2i.DOWN)
	assert_false(_maps[&"olivine_center_room"].get_warps().find_on_push(Vector2i(7, 8),
		Vector2i.DOWN) != null, "la salle de repos n'a pas de porte")


func test_center_arrivals_and_stairs_up() -> void:
	var map: GameMap = _maps[&"olivine_center"]
	assert_eq(map.get_spawn_cell(&"entrance"), Vector2i(7, 8))
	assert_eq(map.get_spawn_cell(&"heal"), Vector2i(7, 5))
	# QA A17 du 2026-11-06 : l'arrivée est sur le palier, pas dans la case fermée (13, 7) sous lui.
	assert_eq(map.get_spawn_cell(&"from_room"), Vector2i(13, 6))
	for cell: Vector2i in [Vector2i(13, 6), Vector2i(12, 6)]:
		assert_false(map.get_grid().is_solid(cell), "accès de l'escalier %s" % cell)
		var warp := map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "escalier %s" % cell)
		if warp != null:
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
			assert_eq([warp.target_map, warp.target_spawn],
				[&"olivine_center_room", &"from_stairs"])
			assert_eq(warp.facing, Vector2i.UP)
	# Le corps de l'escalier est solide, le terminal d'échange reste accessible.
	assert_true(map.get_grid().is_solid(Vector2i(13, 5)))
	assert_false(map.get_grid().is_solid(Vector2i(13, 4)))
	var reach := GridPaths.distances(_terrain(map), [map.get_spawn_cell(&"entrance")])
	for cell: Vector2i in [Vector2i(7, 5), Vector2i(1, 4), Vector2i(12, 4), Vector2i(13, 4),
			Vector2i(13, 6), Vector2i(13, 7)]:
		assert_true(reach.has(cell), "atteignable depuis l'entrée : %s" % cell)


func test_room_arrivals_and_stairs_down() -> void:
	var map: GameMap = _maps[&"olivine_center_room"]
	var room_stairs: Vector2i = map.get_spawn_cell(&"from_stairs")
	assert_eq(room_stairs, Vector2i(12, 4))
	assert_eq(map.get_spawn_cell(&"lit"), Vector2i(3, 4))
	for cell: Vector2i in [Vector2i(12, 3), Vector2i(11, 3)]:
		var warp := map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "escalier %s" % cell)
		if warp != null:
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
			assert_eq([warp.target_map, warp.target_spawn],
				[&"olivine_center", &"from_room"])
			assert_eq(warp.facing, Vector2i.DOWN)
	# Aller-retour : les arrivées existent dans l'autre carte.
	assert_true((_maps[&"olivine_center"] as GameMap).has_spawn(&"from_room"))
	assert_false(map.get_grid().is_solid(Vector2i(3, 4)), "lit : arrivée libre")
	assert_true(map.get_grid().is_solid(Vector2i(2, 4)), "le lit est solide")


func test_room_grid_and_reserved_cells() -> void:
	var map: GameMap = _maps[&"olivine_center_room"]
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/oliville_centre_etage.txt"), plan.error)
	var terrain := _terrain(map)
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			assert_eq(terrain.is_solid(cell), not ".Xh".contains(plan.at(cell)),
				"%s « %s »" % [cell, plan.at(cell)])
	var reach := GridPaths.distances(terrain, [map.get_spawn_cell(&"from_stairs")])
	var reserved: Array[Vector2i] = plan.cells_of("h")
	assert_eq(reserved, [Vector2i(11, 5), Vector2i(9, 6)] as Array[Vector2i])
	for cell: Vector2i in reserved + [map.get_spawn_cell(&"lit"), Vector2i(11, 3)] \
			as Array[Vector2i]:
		assert_true(reach.has(cell), "atteignable depuis l'escalier : %s" % cell)
	# Table : les trois Pokémon sur sa rangée de devant (cases solides), observables de la rangée 5.
	for x: int in [6, 7, 8]:
		assert_true(terrain.is_solid(Vector2i(x, 4)), "table (%d, 4)" % x)
		assert_true(reach.has(Vector2i(x, 5)), "devant la table (%d, 5)" % x)
	assert_eq(GridPaths.cut_off(terrain, map.get_spawn_cell(&"from_stairs")).size(), 0,
		"aucune poche inaccessible")


func test_houses_reserved_cells() -> void:
	for pair: Array in [[&"olivine_house_1", "lavanville_maison_1.txt"],
			[&"olivine_house_2", "lavanville_maison_2.txt"]]:
		var map: GameMap = _maps[pair[0]]
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/" + pair[1]), plan.error)
		var terrain := _terrain(map)
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(terrain.is_solid(cell), not ".Xh".contains(plan.at(cell)),
					"%s %s" % [pair[0], cell])
		var reach := GridPaths.distances(terrain, [map.get_spawn_cell(&"entrance")])
		for cell: Vector2i in plan.cells_of("h"):
			assert_true(reach.has(cell), "%s : case réservée %s" % [pair[0], cell])


func test_center_rest_point_and_mart_shop() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"olivine_center")
	assert_not_null(point)
	if point != null:
		assert_true(point.registers)
		assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
		assert_eq(point.facing, Vector2i.UP)
		assert_eq(_maps[&"olivine_center"].get_spawn_cell(point.spawn), Vector2i(7, 5))
	var items := ItemLibrary.new()
	items.load_dir()
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(items), "\n".join(shops.get_errors()))
	var shop := shops.get_shop(&"olivine_mart")
	assert_not_null(shop)
	if shop != null:
		assert_eq(shop.item_ids(), [&"poke_ball", &"potion", &"super_potion", &"antidote",
			&"revive"])
