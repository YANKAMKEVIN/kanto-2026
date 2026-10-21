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


## Aucune carte de QA livrée. Clôture du jalon 9 (T23) : la carte de QA des systèmes est
## retirée ; jalon 12 (T28) : `qa_moves_j12` ; jalon 13 (T22) : `qa_switch_j13` ; jalon 14
## (T24) : `qa_charge_j14` ; jalon 15 (T23) : `qa_daycare` ; jalon 16 (T20) : `qa_dock_j16`,
## `qa_ship_j16`, `qa_gym_j16` ; jalon 17 (T28) : `qa_flash`, `qa_flash_entry` (les tests du
## voile et de Flash tournent sur la Cave Taupiqueur rendue obscure en mémoire) ; jalon 20 (T24) :
## `qa_gift_j20`, `qa_elevator_j20`, `_1f`, `_2f`, `qa_spin_j20` (le don, l'ascenseur et les dalles
## tournantes sont éprouvés sur la maison du toit, le grand magasin et le repaire Rocket).
## Passe systèmes 2 (T9) : les trois cartes de QA de la monture sont **encore là** (retirées à la
## clôture S2Z : vider [constant S2_QA_MAPS] et retirer leur test `test_qa_mount_maps.gd`).
const S2_QA_MAPS: Array[String] = ["qa_mount.tscn", "qa_mount_interieur.tscn",
	"qa_mount_piste.tscn", "qa_teleport.tscn", "qa_teleport_2.tscn", "qa_sea.tscn",
	"qa_sea_2.tscn"]


func test_no_qa_map_is_shipped() -> void:
	for map_id: StringName in [&"qa_forest_systems", &"qa_moves_j12", &"qa_switch_j13",
			&"qa_charge_j14", &"qa_daycare", &"qa_dock_j16", &"qa_ship_j16", &"qa_gym_j16",
			&"qa_flash", &"qa_flash_entry", &"qa_gift_j20", &"qa_elevator_j20",
			&"qa_elevator_j20_1f", &"qa_elevator_j20_2f", &"qa_spin_j20"]:
		assert_false(MapCatalog.has_map(map_id), "%s retirée" % map_id)
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if S2_QA_MAPS.has(file):
			continue
		assert_false(file.begins_with("qa_"), "%s : carte de QA livrée" % file)


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
		if S2_QA_MAPS.has(file):
			continue  # carte de QA de la passe systèmes 2 : hors de la liste de préchargement
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
		var exits := caves.get_exits(cave)
		assert_false(exits.is_empty(), "%s : sortie" % cave)
		for exit: CaveExit in exits:
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


## Jalon 17 (T6, jalon-17.md §2.3) : une grotte à plusieurs bouches (« escapes ») couvre chaque
## rangée de chacune de ses cartes, sans trou (les chevauchements sont refusés au chargement).
func test_cave_mouth_ranges_cover_every_row() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), "caves.json lisible")
	var missing: Array[StringName] = []
	var checked := 0
	for cave: StringName in caves.get_caves():
		if caves.get_exits(cave).size() < 2:
			continue
		checked += 1
		for map_id: StringName in caves.get_maps(cave):
			if not MapCatalog.has_map(map_id):
				missing.append(map_id)
				continue
			var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() \
				as GameMap
			var uncovered: Array[int] = []
			for row: int in map.size.y:
				if caves.escape_target(map_id, Vector2i(0, row)) == null:
					uncovered.append(row)
			assert_eq(uncovered, [] as Array[int], "%s : rangées sans bouche" % map_id)
			map.free()
	# Jalon 17 : la Cave Taupiqueur (T15) est intégrée, sa carte existe.
	assert_eq(missing, [] as Array[StringName], "cartes des grottes à deux bouches")
	assert_gt(checked, 0, "la Cave Taupiqueur a deux bouches")


func test_j13_qa_map_is_recognised_and_removed() -> void:
	assert_true(MapCatalog.is_qa_map(&"qa_switch_j13"))
	assert_false(MapCatalog.is_qa_map(&"cerulean_city"))
	assert_false(MapCatalog.is_qa_map(&""))
	assert_false(MapCatalog.has_map(&"qa_switch_j13"), "retirée au T22")


## Jalon 18 (T12) : Route 9, Route 10 (extérieures) et le Centre de la Route 10 (bâtiment).
func test_j18_route_maps_exist_with_their_category() -> void:
	var interiors := MapCatalog.load_interiors()
	for map_id: StringName in [&"route_9", &"route_10"]:
		assert_true(MapCatalog.has_map(map_id), String(map_id))
		assert_false(interiors.has(map_id), "%s : extérieur" % map_id)
		assert_false(_scene_interior(MapCatalog.scene_path(map_id)))
	assert_true(MapCatalog.has_map(&"route_10_center"))
	assert_true(interiors.has(&"route_10_center"))
	assert_true(_scene_interior(MapCatalog.scene_path(&"route_10_center")))
