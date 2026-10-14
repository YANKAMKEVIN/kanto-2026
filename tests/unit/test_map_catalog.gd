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


## Cartes de QA encore livrées. Clôture du jalon 9 (T23) : la carte de QA des systèmes
## est retirée ; jalon 12 (T28) : `qa_moves_j12` ; jalon 13 (T22) : `qa_switch_j13` ; jalon 14
## (T24) : `qa_charge_j14`. Jalon 15 (T6) : `qa_daycare` est PROVISOIRE, à retirer au T23
## (liste alors vide).
const QA_MAPS_SHIPPED: Array[String] = ["qa_daycare.tscn"]


func test_only_planned_qa_maps_are_shipped() -> void:
	assert_false(MapCatalog.has_map(&"qa_forest_systems"))
	assert_false(MapCatalog.has_map(&"qa_moves_j12"))
	assert_false(MapCatalog.has_map(&"qa_switch_j13"))
	assert_false(MapCatalog.has_map(&"qa_charge_j14"))
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if file.begins_with("qa_"):
			assert_true(QA_MAPS_SHIPPED.has(file), "%s : carte de QA non prévue" % file)


func test_qa_maps_are_recognised_by_their_prefix() -> void:
	assert_true(MapCatalog.is_qa_map(&"qa_charge_j14"))
	assert_true(MapCatalog.is_qa_map(&"qa_anything"))
	assert_false(MapCatalog.is_qa_map(&"pallet_town"))
	assert_false(MapCatalog.is_qa_map(&""))


## `is_qa_map` reste après le T28 du J12 (le prochain jalon qui aura une carte de QA s'en servira).
func test_is_qa_map_reads_the_prefix() -> void:
	assert_true(MapCatalog.is_qa_map(&"qa_moves_j12"))
	assert_false(MapCatalog.is_qa_map(&"mt_moon_1f"))
	assert_false(MapCatalog.is_qa_map(&""))


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


## Jalon 12 (T7, docs/tech/jalon-12.md §2.3) : chaque carte de grotte (`data/world/caves.json`)
## est une scène extérieure (`interior = false`), absente de la liste des intérieurs ; la sortie
## de la Corde Sortie est une carte qui a son point d'apparition. En attente tant que les cartes
## du Mont Sélénite et de la Route 3 ne sont pas construites (T8, T9).
func test_cave_maps_are_outdoor_scenes_not_interiors() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), "caves.json lisible")
	var interiors := MapCatalog.load_interiors()
	var missing: Array[StringName] = []
	for map_id: StringName in caves.get_all_maps():
		assert_false(interiors.has(map_id), "%s : grotte, pas intérieur" % map_id)
		if not MapCatalog.has_map(map_id):
			missing.append(map_id)
			continue
		assert_false(_scene_interior(MapCatalog.scene_path(map_id)),
			"%s : interior = false (compagnon visible)" % map_id)
	if not missing.is_empty():
		pending("cartes de grotte pas encore construites (T9) : %s" % ", ".join(missing))


func test_cave_escape_targets_exist_with_their_spawn() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), "caves.json lisible")
	var missing: Array[StringName] = []
	for cave: StringName in caves.get_caves():
		var exit := caves.escape_target(caves.get_maps(cave)[0])
		assert_not_null(exit, "%s : sortie" % cave)
		if exit == null:
			continue
		if not MapCatalog.has_map(exit.map):
			missing.append(exit.map)
			continue
		assert_false(_scene_interior(MapCatalog.scene_path(exit.map)),
			"%s : la Corde ramène dehors" % exit.map)
		var map := (load(MapCatalog.scene_path(exit.map)) as PackedScene).instantiate()
		assert_not_null(map.get_node_or_null(NodePath("Spawns/%s" % exit.spawn)),
			"%s : point d'apparition %s" % [exit.map, exit.spawn])
		map.free()
	if not missing.is_empty():
		pending("sortie de grotte pas encore construite (T8) : %s" % ", ".join(missing))


func test_j13_qa_map_is_recognised_and_removed() -> void:
	assert_true(MapCatalog.is_qa_map(&"qa_switch_j13"))
	assert_false(MapCatalog.is_qa_map(&"cerulean_city"))
	assert_false(MapCatalog.is_qa_map(&""))
	assert_false(MapCatalog.has_map(&"qa_switch_j13"), "retirée au T22")
