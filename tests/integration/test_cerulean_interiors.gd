extends GutTest
## Intérieurs d'Azuria (jalon 13 T7, jalon-13.md §2.1, §2.5, §2.6 ; dossier 16 §4.3, §5, §9) sur
## les vraies scènes : métadonnées et lumière, sorties vers Azuria (spawns `from_*` que la ville
## porte), Centre et Boutique = définitions de Jadielle, point de repos, cases solides = grille
## de chaque pièce (`tools/plans/azuria_*.txt`), Arène (bassin bloqué, chemins secs, Ondine
## atteignable, deux Dresseurs évitables par leur file), cases des PNJ libres. Sans PNJ (T17).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
## Carte → [taille, sorties, [carte, spawn], grille, praticables de la grille].
const ROOMS := {
	&"cerulean_center": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"cerulean_city", &"from_center"], "", ""],
	&"cerulean_mart": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"cerulean_city", &"from_mart"], "", ""],
	&"cerulean_gym": [Vector2i(17, 13), [Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11)],
		[&"cerulean_city", &"from_gym"], "azuria_arene.txt", ".XONJG"],
	&"cerulean_bike_shop": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"cerulean_city", &"from_bike_shop"], "azuria_velos.txt", ".Xv"],
	&"cerulean_house": [Vector2i(15, 10), [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		[&"cerulean_city", &"from_house"], "azuria_maison.txt", ".Xh"],
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
		assert_eq(map.display_name, "Azuria", "%s : titre de la ville" % id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
		assert_eq(lighting.get_map_profile(id), &"interior_warm", "%s au plan" % id)
		var shell := map.get_node(^"Shell") as Sprite2D
		assert_eq(shell.texture.get_size(), Vector2(map.size * Grid.TILE_SIZE), String(id))


func test_exits_lead_back_with_the_planned_spawn() -> void:
	var city := (load(MapCatalog.scene_path(&"cerulean_city")) as PackedScene).instantiate() \
		as GameMap
	add_child(city)
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		var target: Array = ROOMS[id][2]
		for cell: Vector2i in ROOMS[id][1]:
			assert_false(map.get_grid().is_solid(cell), "%s : sortie %s praticable" % [id, cell])
			var warp := map.get_warps().find_on_push(cell, Vector2i.DOWN)
			assert_not_null(warp, "%s : sortie %s" % [id, cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], target, String(id))
				assert_eq(warp.facing, Vector2i.DOWN)
		assert_true((ROOMS[id][1] as Array).has(map.get_spawn_cell(&"entrance")),
			"%s : on arrive sur la sortie" % id)
		assert_true(city.has_spawn(target[1]), "%s : la ville porte %s" % [id, target[1]])
	city.free()


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
	for pair: Array in [[&"cerulean_center", &"viridian_center"], [&"cerulean_mart",
			&"viridian_mart"]]:
		var here: GameMap = _maps[pair[0]]
		var there: GameMap = _maps[pair[1]]
		assert_eq(here.blocked_cells, there.blocked_cells, String(pair[0]))
		assert_eq((here.get_node(^"Shell") as Sprite2D).texture,
			(there.get_node(^"Shell") as Sprite2D).texture)
		assert_eq(_props(here), _props(there), "%s : mêmes meubles" % pair[0])
	assert_eq(_maps[&"cerulean_mart"].get_node(^"Triggers").get_child_count(), 0)
	assert_not_null(_maps[&"cerulean_center"].get_node_or_null(^"%HealMachine"), "machine de soin")


## Noms des enfants d'`Entities` hors PNJ (créés à l'exécution).
func _props(map: GameMap) -> Array:
	var names: Array = []
	for child: Node in map.get_entities().get_children():
		if not child is Npc:
			names.append([String(child.name), (child as Node2D).position])
	return names


func test_cerulean_center_is_a_rest_point_named_azuria() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"cerulean_center")
	assert_not_null(point, "point de repos du Centre d'Azuria")
	if point == null:
		return
	assert_true(point.registers)
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(point.facing, Vector2i.UP)
	assert_eq(_maps[&"cerulean_center"].get_spawn_cell(point.spawn), Vector2i(7, 5))
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(" — ".join(points.registered_toast(zones.get_zone(&"cerulean_city").name)),
		"Point de repos enregistré — Azuria")


func test_rooms_have_their_people_on_the_reserved_cells() -> void:
	# T17 : chaque PNJ de data/npcs/<salle>.json est sur une case praticable de la grille ; Ondine
	# (T19) n'y est pas encore.
	for id: StringName in ROOMS:
		var roster := NpcRoster.load_for_map(id)
		var map: GameMap = _maps[id]
		for spec: NpcSpec in roster.get_all():
			assert_false(map.get_grid().is_solid(spec.cell), "%s : %s sur une case libre"
				% [id, spec.id])
		assert_null(map.get_npc(&"misty"), "%s : Ondine attend le T19" % id)


func test_gym_pool_is_blocked_and_the_paths_are_dry() -> void:
	var gym: GameMap = _maps[&"cerulean_gym"]
	var terrain := _terrain(gym)
	for y: int in range(4, 9):
		for x: int in range(5, 12):
			assert_true(terrain.is_solid(Vector2i(x, y)), "bassin (%d, %d)" % [x, y])
	var dist := GridPaths.distances(terrain, [gym.get_spawn_cell(&"entrance")])
	for cell: Vector2i in [Vector2i(8, 3), Vector2i(7, 3), Vector2i(2, 5), Vector2i(14, 7),
			Vector2i(6, 10)]:
		assert_true(dist.has(cell), "%s atteignable" % cell)
	assert_true(dist.has(Vector2i(7, 3)), "on parle à Ondine depuis (7, 3)")
	for name: String in ["DivingBoard"]:
		assert_not_null(gym.get_entities().get_node_or_null(NodePath(name)), name)
	assert_true(terrain.is_solid(Vector2i(12, 2)) and terrain.is_solid(Vector2i(13, 2)),
		"plongeoir")


func test_bike_shop_and_house_furniture() -> void:
	var shop: GameMap = _maps[&"cerulean_bike_shop"]
	for cell: Vector2i in [Vector2i(1, 3), Vector2i(2, 3), Vector2i(9, 4), Vector2i(11, 4),
			Vector2i(9, 3), Vector2i(12, 3), Vector2i(1, 6), Vector2i(2, 6)]:
		assert_true(shop.get_grid().is_solid(cell), "vélos, comptoir : %s" % cell)
	# On parle au vendeur depuis (12, 5) ou (13, 4).
	var dist := GridPaths.distances(_terrain(shop), [shop.get_spawn_cell(&"entrance")])
	assert_true(dist.has(Vector2i(12, 5)) and dist.has(Vector2i(13, 4)))
	var house: GameMap = _maps[&"cerulean_house"]
	var dist_h := GridPaths.distances(_terrain(house), [house.get_spawn_cell(&"entrance")])
	assert_true(dist_h.has(Vector2i(4, 5)), "l'habitante est accessible")
