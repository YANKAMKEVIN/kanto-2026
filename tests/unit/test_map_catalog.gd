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
		# Jalon 15 (T6) : `qa_daycare` est PROVISOIRE, à retirer au T23 avec cette exception.
		if file.begins_with("qa_daycare"):
			continue
		assert_false(file.begins_with("qa_"), "%s : carte de QA livrée" % file)


## Jalon 10 : la liste des intérieurs (préchargement du SceneRouter) suit les scènes.
func test_interiors_list_matches_the_scenes() -> void:
	var listed := MapCatalog.load_interiors()
	assert_gte(listed.size(), 15)
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if not file.ends_with(".tscn"):
			continue
		var map_id := StringName(file.get_basename())
		assert_eq(listed.has(map_id), _scene_interior(MapCatalog.MAPS_DIR + file),
			"%s : liste des intérieurs à jour (data/world/interiors.json)" % map_id)
	for map_id: StringName in listed:
		assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)


func test_unreadable_interiors_list_is_empty() -> void:
	assert_eq(MapCatalog.load_interiors("res://does/not/exist.json"), [] as Array[StringName])
	assert_push_error_count(1)


## `interior` de la racine de la scène, sans l'instancier.
func _scene_interior(path: String) -> bool:
	var state := (load(path) as PackedScene).get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"interior":
			return bool(state.get_node_property_value(0, i))
	return false
