extends GutTest
## Centre Pokémon de la Route 10, carte `route_10_center` (jalon 18 T12, jalon-18.md §4.1, §4.3) :
## la définition commune des Centres sans Boutique, titre « Route 10 », bâtiment
## (`interiors.json`), lumière intérieure, sortie vers la Route 10 devant la porte, point de repos
## (toast « Point de repos enregistré — Route 10 »), service de la zone `route_10`.
## PNJ (infirmière, Stockage) : T18.

var _center: GameMap
var _viridian: GameMap


func before_all() -> void:
	_center = (load(MapCatalog.scene_path(&"route_10_center")) as PackedScene).instantiate()
	_viridian = (load(MapCatalog.scene_path(&"viridian_center")) as PackedScene).instantiate()
	add_child(_center)
	add_child(_viridian)


func after_all() -> void:
	_center.free()
	_viridian.free()


func test_metadata_and_category() -> void:
	assert_eq(_center.map_id, &"route_10_center")
	assert_eq(_center.display_name, "Route 10")
	assert_true(_center.interior)
	assert_eq(_center.light_profile, &"interior_warm")
	assert_true(MapCatalog.load_interiors().has(&"route_10_center"))
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_10_center"), &"interior_warm")


func test_same_definition_as_the_other_centers() -> void:
	assert_eq(_center.blocked_cells, _viridian.blocked_cells)
	assert_eq((_center.get_node(^"Shell") as Sprite2D).texture,
		(_viridian.get_node(^"Shell") as Sprite2D).texture)
	assert_not_null(_center.get_node_or_null(^"%HealMachine"), "machine de soin")
	assert_eq(_center.get_node(^"Triggers").get_child_count(), 0)
	assert_eq(_center.get_spawn_cell(&"heal"), Vector2i(7, 5))
	assert_eq(_center.get_spawn_cell(&"entrance"), Vector2i(7, 8))


func test_exit_leads_to_route_10_in_front_of_the_door() -> void:
	for cell: Vector2i in [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]:
		var warp := _center.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_10", &"from_center", Vector2i.DOWN])
	var route := (load(MapCatalog.scene_path(&"route_10")) as PackedScene).instantiate() as GameMap
	assert_eq(route.get_spawn_cell(&"from_center"), Vector2i(7, 12), "devant la porte")
	route.free()


func test_rest_point_and_service() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"route_10_center")
	assert_not_null(point)
	if point == null:
		return
	assert_true(point.registers)
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(_center.get_spawn_cell(point.spawn), Vector2i(7, 5))
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"route_10_center"), &"route_10")
	assert_eq(" — ".join(points.registered_toast(zones.get_zone(&"route_10").name)),
		"Point de repos enregistré — Route 10")
