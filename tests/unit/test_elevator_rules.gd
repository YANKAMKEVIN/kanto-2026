extends GutTest
## ElevatorRules (jalon 20 T5, docs/tech/jalon-20.md §2.3.2, §2.3.5 ; dossier 23 §9, §13.4) :
## panneau qui répond ou non (Clé Ascenseur), choix d'un étage, sortie de la cabine, étage
## d'entrée, et position sauvée (jamais la cabine). Sur les vraies données.

var _library: ElevatorLibrary
var _store: ElevatorData
var _hideout: ElevatorData


func before_each() -> void:
	_library = ElevatorLibrary.new()
	assert_true(_library.load_file())
	_store = _library.for_car(&"celadon_dept_elevator")
	_hideout = _library.for_car(&"rocket_hideout_elevator")


func _bag(items: Array[StringName] = []) -> Bag:
	var bag := Bag.new()
	for id: StringName in items:
		bag.add(id)
	return bag


# --- Clé -----------------------------------------------------------------------------------

func test_store_works_without_any_key() -> void:
	assert_true(ElevatorRules.can_operate(_store, _bag()))
	assert_true(ElevatorRules.can_operate(_store, null), "pas de Sac : le magasin marche")
	assert_eq(ElevatorRules.choose(_store, &"gf", &"5f", _bag()), ElevatorRules.Status.OK)


func test_hideout_refuses_without_the_lift_key() -> void:
	assert_false(ElevatorRules.can_operate(_hideout, _bag()))
	assert_false(ElevatorRules.can_operate(_hideout, null))
	assert_false(ElevatorRules.can_operate(_hideout, _bag([&"potion", &"nugget"])))
	for floor_id: StringName in [&"b1f", &"b2f", &"b4f", &"b3f"]:
		assert_eq(ElevatorRules.choose(_hideout, &"b1f", floor_id, _bag()),
			ElevatorRules.Status.NO_KEY, "sans la Clé, le panneau ne répond pas (%s)" % floor_id)


func test_hideout_works_with_the_lift_key() -> void:
	var bag := _bag([&"lift_key"])
	assert_true(ElevatorRules.can_operate(_hideout, bag))
	assert_eq(ElevatorRules.choose(_hideout, &"b1f", &"b4f", bag), ElevatorRules.Status.OK)
	assert_eq(ElevatorRules.choose(_hideout, &"b4f", &"b2f", bag), ElevatorRules.Status.OK)


# --- Étages ----------------------------------------------------------------------------------

func test_only_the_data_floors_are_allowed() -> void:
	var bag := _bag([&"lift_key"])
	assert_eq(ElevatorRules.choose(_hideout, &"b1f", &"b3f", bag),
		ElevatorRules.Status.UNKNOWN_FLOOR, "jamais B3F")
	assert_eq(ElevatorRules.choose(_store, &"gf", &"roof", bag),
		ElevatorRules.Status.UNKNOWN_FLOOR, "jamais le toit")
	assert_eq(ElevatorRules.choose(null, &"gf", &"2f", bag), ElevatorRules.Status.UNKNOWN_FLOOR)
	for floor_id: StringName in _store.floor_ids():
		var status := ElevatorRules.choose(_store, &"__", floor_id, null)
		assert_eq(status, ElevatorRules.Status.OK, "magasin : %s permis" % floor_id)


func test_same_floor_changes_nothing() -> void:
	assert_eq(ElevatorRules.choose(_store, &"3f", &"3f", null), ElevatorRules.Status.SAME_FLOOR)
	assert_eq(ElevatorRules.choose(_hideout, &"b2f", &"b2f", _bag([&"lift_key"])),
		ElevatorRules.Status.SAME_FLOOR)


func test_exit_target_follows_the_current_floor() -> void:
	assert_eq(ElevatorRules.exit_target(_store, &"5f"),
		{"map": &"celadon_dept_5f", "spawn": &"from_elevator"})
	assert_eq(ElevatorRules.exit_target(_hideout, &"b4f"),
		{"map": &"rocket_hideout_b4f", "spawn": &"from_elevator"})
	assert_eq(ElevatorRules.exit_target(_store, &"roof"), {}, "étage non desservi")
	assert_eq(ElevatorRules.exit_target(null, &"gf"), {})


func test_entry_floor_is_the_floor_left_behind() -> void:
	assert_eq(ElevatorRules.entry_floor(_store, &"celadon_dept_4f"), &"4f")
	assert_eq(ElevatorRules.entry_floor(_hideout, &"rocket_hideout_b2f"), &"b2f")


func test_entry_from_an_unknown_map_is_the_first_floor() -> void:
	assert_eq(ElevatorRules.entry_floor(_store, &"celadon_city"), &"gf")
	assert_eq(ElevatorRules.entry_floor(_store, &""), &"gf", "chargement d'une partie")
	assert_eq(ElevatorRules.entry_floor(_hideout, &"rocket_hideout_b3f"), &"b1f")
	assert_eq(ElevatorRules.entry_floor(null, &"x"), &"")


# --- Sauvegarde : jamais la cabine -------------------------------------------------------------

func test_save_target_is_the_current_floor_never_the_car() -> void:
	var target := ElevatorRules.save_target(_store, &"4f")
	assert_eq(target, {"map": &"celadon_dept_4f", "spawn": &"from_elevator"},
		"sauvée dans la cabine au 4e → devant la porte du 4e")
	for elevator: ElevatorData in [_store, _hideout]:
		for floor_id: StringName in elevator.floor_ids() + [&"inconnu", &""]:
			var saved := ElevatorRules.save_target(elevator, floor_id)
			assert_false(saved.is_empty(), "%s %s : une position" % [elevator.id, floor_id])
			assert_ne(saved.get("map"), elevator.car, "%s : jamais la cabine" % elevator.id)
			assert_false(_library.is_car(saved.get("map", &"")))


func test_save_target_of_an_unknown_floor_is_the_first_floor() -> void:
	assert_eq(ElevatorRules.save_target(_hideout, &"b3f")["map"], &"rocket_hideout_b1f")
	assert_eq(ElevatorRules.save_target(null, &"gf"), {})


func test_ride_scenario_store() -> void:
	# Entrée depuis le RdC, trajet au 5e, sortie au 5e ; FERMER (même étage) ne change rien.
	var current := ElevatorRules.entry_floor(_store, &"celadon_dept_gf")
	assert_eq(ElevatorRules.exit_target(_store, current)["map"], &"celadon_dept_gf")
	assert_eq(ElevatorRules.choose(_store, current, &"5f", null), ElevatorRules.Status.OK)
	current = &"5f"
	assert_eq(ElevatorRules.exit_target(_store, current)["map"], &"celadon_dept_5f")
	assert_eq(ElevatorRules.choose(_store, current, &"5f", null),
		ElevatorRules.Status.SAME_FLOOR)
