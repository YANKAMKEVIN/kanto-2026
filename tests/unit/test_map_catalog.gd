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


## Clôture du jalon 9 (T23) : la carte de QA des systèmes est retirée, aucune autre ne reste.
func test_no_qa_map_is_shipped() -> void:
	assert_false(MapCatalog.has_map(&"qa_forest_systems"))
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		assert_false(file.begins_with("qa_"), "%s : carte de QA livrée" % file)
