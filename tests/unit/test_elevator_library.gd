extends GutTest
## ElevatorLibrary et ElevatorData (jalon 20 T5, docs/tech/jalon-20.md §2.3.1–§2.3.2) : lecture
## stricte de `data/world/elevators.json`, vraies données (magasin RdC → 5e sans le toit, repaire
## B1F / B2F / B4F avec la Clé), accord avec les grilles validées ; cartes, points d'apparition et
## objet clé vérifiés dès qu'ils existent (en attente sinon, comme `test_map_catalog`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")


func _floor(id: Variant, map: Variant = null) -> Dictionary:
	return {"id": id, "label": "Étage %s" % id, "map": map if map != null else "m_%s" % id,
		"spawn": "from_elevator"}


func _data(floors: Array, car: Variant = "cabine", key: Variant = "") -> Dictionary:
	return {"elevators": {"lift": {"car": car, "key": key, "floors": floors}}}


func _load_real() -> ElevatorLibrary:
	var library := ElevatorLibrary.new()
	assert_true(library.load_file(), "data/world/elevators.json valide")
	assert_eq(library.get_errors().size(), 0, "\n".join(library.get_errors()))
	return library


# --- Vraies données -------------------------------------------------------------------

func test_real_data_two_elevators() -> void:
	var library := _load_real()
	assert_eq(library.get_ids(), [&"celadon_dept", &"rocket_hideout"] as Array[StringName])
	assert_true(library.is_car(&"celadon_dept_elevator"))
	assert_true(library.is_car(&"rocket_hideout_elevator"))
	assert_false(library.is_car(&"celadon_dept_gf"), "un étage n'est pas une cabine")


func test_department_store_ground_to_fifth_without_the_roof() -> void:
	var store := _load_real().for_car(&"celadon_dept_elevator")
	assert_not_null(store)
	assert_eq(store.id, &"celadon_dept")
	assert_false(store.needs_key(), "le magasin n'exige aucune clé")
	assert_eq(store.floor_ids(), [&"gf", &"2f", &"3f", &"4f", &"5f"] as Array[StringName])
	var labels: Array[String] = []
	for entry: Dictionary in store.floors:
		labels.append(entry["label"])
		assert_eq(entry["spawn"], &"from_elevator")
	assert_eq(labels, ["RdC", "2e", "3e", "4e", "5e"] as Array[String])
	assert_true(store.floor_for_map(&"celadon_dept_roof").is_empty(), "pas le toit")
	assert_eq(store.default_floor()["map"], &"celadon_dept_gf")


func test_hideout_b1f_b2f_b4f_only_with_the_lift_key() -> void:
	var hideout := _load_real().for_car(&"rocket_hideout_elevator")
	assert_not_null(hideout)
	assert_eq(hideout.key, &"lift_key")
	assert_eq(hideout.floor_ids(), [&"b1f", &"b2f", &"b4f"] as Array[StringName])
	assert_true(hideout.floor_for_map(&"rocket_hideout_b3f").is_empty(), "jamais B3F")


func test_real_data_matches_the_validated_grids() -> void:
	var library := _load_real()
	var store_car := PlanGrid.new()
	assert_true(store_car.load_file("res://tools/plans/celadopole_magasin_ascenseur.txt"))
	assert_eq(",".join(library.get_elevator(&"celadon_dept").floor_ids()),
		store_car.attr("panneau_etages", "floors"), "panneau du magasin")
	var hideout_car := PlanGrid.new()
	assert_true(hideout_car.load_file("res://tools/plans/repaire_ascenseur.txt"))
	var hideout := library.get_elevator(&"rocket_hideout")
	assert_eq(String(hideout.key), hideout_car.attr("panneau", "cle"))
	var labels: PackedStringArray = []
	for entry: Dictionary in hideout.floors:
		labels.append(entry["label"])
	assert_eq(",".join(labels), hideout_car.attr("panneau", "etages"), "panneau du repaire")
	for grid: String in ["rdc", "2e", "3e", "4e", "5e"]:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/celadopole_magasin_%s.txt" % grid))
		var floor_id := StringName(plan.attr("ascenseur", "floor"))
		assert_true(library.get_elevator(&"celadon_dept").has_floor(floor_id),
			"%s : la porte d'ascenseur mène à un étage desservi (%s)" % [grid, floor_id])
		assert_true(plan.positions.has("from_elevator"), "%s : arrivée from_elevator" % grid)


func test_real_maps_and_spawns_exist_once_built() -> void:
	var library := _load_real()
	var missing: Array[StringName] = []
	for id: StringName in library.get_ids():
		var elevator := library.get_elevator(id)
		if not MapCatalog.has_map(elevator.car):
			missing.append(elevator.car)
		for entry: Dictionary in elevator.floors:
			var map_id: StringName = entry["map"]
			if not MapCatalog.has_map(map_id):
				missing.append(map_id)
				continue
			var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
			assert_not_null(map.get_node_or_null(NodePath("Spawns/%s" % entry["spawn"])),
				"%s : point d'apparition %s" % [map_id, entry["spawn"]])
			map.free()
	if not missing.is_empty():
		pending("cartes d'ascenseur pas encore construites (T16, T20) : %s"
			% ", ".join(missing))


func test_real_key_is_a_key_item_once_defined() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var library := _load_real()
	for id: StringName in library.get_ids():
		var key := library.get_elevator(id).key
		if key.is_empty():
			continue
		if not items.has_item(key):
			pending("objet « %s » créé au T7 (branche j20-t7-data)" % key)
			continue
		assert_true(items.get_item(key).is_key(), "%s : objet clé" % key)


# --- Lecture stricte ----------------------------------------------------------------------

func test_valid_dict() -> void:
	var library := ElevatorLibrary.new()
	assert_true(library.add_from_dict(_data([_floor("a"), _floor("b")], "cabine", "cle")))
	var lift := library.for_car(&"cabine")
	assert_not_null(lift)
	assert_eq(lift.key, &"cle")
	assert_eq(lift.get_floor(&"b")["map"], &"m_b")
	assert_true(lift.get_floor(&"z").is_empty())
	assert_null(library.for_car(&"ailleurs"), "hors cabine : null")


func test_missing_file() -> void:
	var library := ElevatorLibrary.new()
	assert_false(library.load_file("res://data/world/absent.json"))
	assert_push_error_count(1)


func test_doc_key_is_allowed() -> void:
	var data := _data([_floor("a")])
	data["_doc"] = "texte libre"
	assert_true(ElevatorLibrary.new().add_from_dict(data))


func test_unknown_keys_are_errors() -> void:
	var library := ElevatorLibrary.new()
	var bad_floor := _floor("a")
	bad_floor["toit"] = true
	var data := _data([bad_floor])
	data["autre"] = 1
	(data["elevators"]["lift"] as Dictionary)["vitesse"] = 2
	assert_false(library.add_from_dict(data))
	assert_eq(library.get_errors().size(), 3, "\n".join(library.get_errors()))
	assert_push_error_count(3)
	assert_eq(library.size(), 0, "ascenseur écarté")


func test_empty_floor_list_is_refused() -> void:
	var library := ElevatorLibrary.new()
	assert_false(library.add_from_dict(_data([])))
	assert_eq(library.size(), 0)
	assert_push_error_count(1)


func test_duplicate_floor_is_refused() -> void:
	var library := ElevatorLibrary.new()
	assert_false(library.add_from_dict(_data([_floor("a", "m1"), _floor("a", "m2")])))
	assert_eq(library.size(), 0)
	assert_push_error_count(1)


func test_same_map_twice_is_refused() -> void:
	var library := ElevatorLibrary.new()
	assert_false(library.add_from_dict(_data([_floor("a", "m"), _floor("b", "m")])))
	assert_push_error_count(1)


func test_car_is_not_a_floor() -> void:
	var library := ElevatorLibrary.new()
	assert_false(library.add_from_dict(_data([_floor("a", "cabine")], "cabine")))
	assert_push_error_count(1)


func test_duplicate_car_is_refused() -> void:
	var library := ElevatorLibrary.new()
	var data := {"elevators": {
		"un": {"car": "cabine", "key": "", "floors": [_floor("a")]},
		"deux": {"car": "cabine", "key": "", "floors": [_floor("b")]},
	}}
	assert_false(library.add_from_dict(data))
	assert_eq(library.get_ids(), [&"un"] as Array[StringName], "le premier est gardé")
	assert_push_error_count(1)


func test_bad_values_are_refused() -> void:
	for data: Dictionary in [
		_data([_floor("a")], ""), _data([_floor("a")], 3), _data([_floor("a")], "c", null),
		_data([_floor("")]), _data([_floor("a", 5)]), _data(["étage"]),
		{"elevators": []}, {"elevators": {"lift": "cabine"}},
	]:
		var library := ElevatorLibrary.new()
		assert_false(library.add_from_dict(data), str(data))
		assert_eq(library.size(), 0, str(data))
	assert_push_error_count(8)
