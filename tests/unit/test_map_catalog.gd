extends GutTest
## MapCatalog : identifiant de carte → chemin de scène.


func test_scene_path_follows_the_map_id() -> void:
	assert_eq(MapCatalog.scene_path(&"pallet_town"), "res://game/world/maps/pallet_town.tscn")
	assert_eq(MapCatalog.scene_path(&"player_house_1f"),
		"res://game/world/maps/player_house_1f.tscn")


func test_custom_directory() -> void:
	assert_eq(MapCatalog.scene_path(&"room", "res://tests/fixtures/maps/"),
		"res://tests/fixtures/maps/room.tscn")
	assert_eq(MapCatalog.scene_path(&"room", "res://tests/fixtures/maps"),
		"res://tests/fixtures/maps/room.tscn")


func test_empty_id() -> void:
	assert_eq(MapCatalog.scene_path(&""), "")
	assert_false(MapCatalog.has_map(&""))


func test_has_map() -> void:
	assert_true(MapCatalog.has_map(&"pallet_town"))
	assert_false(MapCatalog.has_map(&"does_not_exist"))


func test_qa_maps_are_recognised_by_their_prefix() -> void:
	assert_true(MapCatalog.is_qa_map(&"qa_forest_systems"))
	assert_false(MapCatalog.is_qa_map(&"viridian_forest"))
	assert_false(MapCatalog.is_qa_map(&"pallet_town"))
	assert_false(MapCatalog.is_qa_map(&""))
	assert_true(MapCatalog.has_map(&"qa_forest_systems"))
