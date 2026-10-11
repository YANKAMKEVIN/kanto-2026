extends GutTest
## Centre Pokémon du Mont Sélénite, carte `mt_moon_center` (jalon 12 T8, docs/tech/jalon-12.md
## §2.14 ; dossier 15 §4) : la définition commune des Centres (J7 T8, J10 T13) sans Boutique,
## titre « Mont Sélénite », bâtiment (`interiors.json`), lumière intérieure, sortie vers la Route
## 3 devant sa porte, point de repos (toast « Point de repos enregistré — Mont Sélénite »),
## service de la zone `mt_moon`. PNJ (infirmière, Stockage) : T18.

var _center: GameMap
var _viridian: GameMap


func before_all() -> void:
	_center = (load(MapCatalog.scene_path(&"mt_moon_center")) as PackedScene).instantiate()
	_viridian = (load(MapCatalog.scene_path(&"viridian_center")) as PackedScene).instantiate()
	add_child(_center)
	add_child(_viridian)


func after_all() -> void:
	_center.free()
	_viridian.free()


func test_metadata_and_category() -> void:
	assert_eq(_center.map_id, &"mt_moon_center")
	assert_eq(_center.display_name, "Mont Sélénite")
	assert_true(_center.interior, "bâtiment : le compagnon rentre")
	assert_eq(_center.light_profile, &"interior_warm")
	assert_true(MapCatalog.load_interiors().has(&"mt_moon_center"), "dans interiors.json")
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"mt_moon_center"), &"interior_warm")


func test_same_definition_as_the_other_centers() -> void:
	assert_eq(_center.blocked_cells, _viridian.blocked_cells)
	assert_eq((_center.get_node(^"Shell") as Sprite2D).texture,
		(_viridian.get_node(^"Shell") as Sprite2D).texture)
	assert_eq(_layout(_center.get_entities()), _layout(_viridian.get_entities()))
	assert_eq(_layout(_center.get_node(^"Interactables")),
		_layout(_viridian.get_node(^"Interactables")))
	assert_eq(_layout(_center.get_node(^"Spawns")), _layout(_viridian.get_node(^"Spawns")))
	assert_not_null(_center.get_node_or_null(^"%HealMachine"), "machine de soin")
	assert_eq(_center.get_node(^"Triggers").get_child_count(), 0)


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


func test_exit_leads_to_route_3_in_front_of_the_door() -> void:
	for cell: Vector2i in [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]:
		var warp := _center.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_3", &"from_center_e", Vector2i.DOWN])
	var route := (load(MapCatalog.scene_path(&"route_3")) as PackedScene).instantiate() \
		as GameMap
	assert_eq(route.get_spawn_cell(&"from_center_e"), Vector2i(62, 12), "devant la porte")
	route.free()


func test_rest_point_named_mont_selenite() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"mt_moon_center")
	assert_not_null(point)
	if point == null:
		return
	assert_true(point.registers)
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(point.facing, Vector2i.UP)
	assert_eq(_center.get_spawn_cell(point.spawn), Vector2i(7, 5))
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"mt_moon_center"), &"mt_moon")
	var zone := zones.get_zone(&"mt_moon")
	assert_eq(" — ".join(points.registered_toast(zone.name)),
		"Point de repos enregistré — Mont Sélénite", "dossier 15 §4")
