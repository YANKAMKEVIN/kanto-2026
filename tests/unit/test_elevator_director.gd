extends GutTest
## ElevatorPanelView et ElevatorDirector sans scène (jalon 20 T13, `jalon-20.md` §2.3.3 à §2.3.5) :
## vue du panneau (textes 158 et 159, étage courant marqué), position sauvée hors cabine et dans
## une cabine, refus sans panneau ouvert. Le parcours complet (vraie Boot) : test_elevator_flow.

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _library: ElevatorLibrary
var _state: Node
var _director: ElevatorDirector


func before_each() -> void:
	_library = ElevatorLibrary.new()
	assert_true(_library.load_file())
	_state = GameStateScript.new()
	_state.new_game(1)
	_director = ElevatorDirector.new()
	add_child_autofree(_director)
	_director.setup(_library, _state, null, null, null)
	_director.spawn_cell_source = func(map_id: StringName, spawn: StringName) -> Vector2i:
		return Vector2i(4, 2) if spawn == &"from_elevator" and map_id != &"" else Vector2i(-1, -1)


func after_each() -> void:
	_state.free()


func test_panel_view_texts_and_current_floor() -> void:
	var view := ElevatorPanelView.build(_library.get_elevator(&"celadon_dept"), &"3f")
	assert_eq([view.title, view.close_label], ["Quel étage ?", "FERMER"], "annexe A, 158 et 159")
	assert_eq(view.elevator_id, &"celadon_dept")
	assert_eq(view.floors.map(func(f: Dictionary) -> String: return f["label"]),
		["RdC", "2e", "3e", "4e", "5e"], "ordre des données, sans le toit")
	assert_eq(view.current_floor(), &"3f")
	assert_eq(view.choosable_ids(), [&"gf", &"2f", &"4f", &"5f"] as Array[StringName])


func test_panel_view_without_elevator_is_empty() -> void:
	var view := ElevatorPanelView.build(null, &"gf")
	assert_true(view.floors.is_empty())
	assert_eq(view.current_floor(), &"")


func test_stable_location_outside_a_car_is_unchanged() -> void:
	assert_eq(_director.stable_location(&"celadon_city", Vector2i(7, 8), Vector2i.LEFT),
		{"map": &"celadon_city", "cell": Vector2i(7, 8), "facing": Vector2i.LEFT})


func test_stable_location_in_a_car_is_the_current_floor_arrival() -> void:
	# Sans carte branchée, l'étage courant est inconnu : premier étage (save_target).
	var at := _director.stable_location(&"celadon_dept_elevator", Vector2i(1, 1), Vector2i.UP)
	assert_eq(at, {"map": &"celadon_dept_gf", "cell": Vector2i(4, 2), "facing": Vector2i.UP},
		"arrivée du RdC, orientation gardée faute de sortie connue")
	at = _director.stable_location(&"rocket_hideout_elevator", Vector2i(1, 1), Vector2i.UP)
	assert_eq(at["map"], &"rocket_hideout_b1f", "repaire : B1F")


func test_unknown_arrival_keeps_the_given_position() -> void:
	_director.spawn_cell_source = func(_m: StringName, _s: StringName) -> Vector2i:
		return Vector2i(-1, -1)
	var at := _director.stable_location(&"celadon_dept_elevator", Vector2i(1, 1), Vector2i.UP)
	assert_eq(at["map"], &"celadon_dept_elevator")
	assert_push_error_count(1)


func test_nothing_happens_outside_a_car() -> void:
	assert_false(_director.is_running())
	assert_false(_director.handle_back(), "retour Android non pris")
	assert_eq(_director.choose_floor(&"2f"), ElevatorRules.Status.UNKNOWN_FLOOR, "panneau fermé")
	assert_false(_director.open_panel(), "hors cabine")
	assert_push_error_count(1)
