extends GutTest
## RestPoint, RestPointLibrary (jalon-07.md §3.3, T6) : format de data/world/rest_points.json,
## validation, enregistrement du dernier Centre utilisé (dossier 09 §7), réveil, toast.
## Le point de repos courant vit dans GameState.heal_map / heal_spawn (sauvegarde v3 inchangée).

const STATE_SCRIPT := "res://game/autoload/game_state.gd"

var _library: RestPointLibrary


func before_each() -> void:
	_library = RestPointLibrary.new()
	assert_true(_library.add_from_dict(_data(), "test"))


## La maison et le Centre de Jadielle, sous la forme du plan.
func _data() -> Dictionary:
	return {
		"registered_title": "Point de repos enregistré",
		"points": {
			"player_house_1f": {"spawn": "heal", "facing": "up",
				"wakeup_dialogue": "mom_wakeup", "registers": false},
			"viridian_center": {"spawn": "heal", "facing": "up",
				"wakeup_dialogue": "nurse_wakeup", "registers": true},
		},
	}


func _state() -> Node:
	return autofree((load(STATE_SCRIPT) as GDScript).new())


func test_points_are_read() -> void:
	assert_eq(_library.get_maps(), [&"player_house_1f", &"viridian_center"]
		as Array[StringName])
	var house := _library.get_point(&"player_house_1f")
	assert_eq(house.map, &"player_house_1f")
	assert_eq(house.spawn, &"heal")
	assert_eq(house.facing, Vector2i.UP)
	assert_eq(house.wakeup_dialogue, &"mom_wakeup")
	assert_false(house.registers, "la maison ne s'enregistre pas")
	var center := _library.get_point(&"viridian_center")
	assert_true(center.registers)
	assert_eq(center.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(center.source, "test")
	assert_null(_library.get_point(&"route_1"), "carte sans point de repos")
	assert_false(_library.has_point(&"route_1"))


func test_facing_and_registers_have_defaults() -> void:
	assert_true(_library.add_from_dict({"points": {"other": {"spawn": "s",
		"wakeup_dialogue": "d"}}}, "t"))
	var point := _library.get_point(&"other")
	assert_eq(point.facing, Vector2i.UP)
	assert_false(point.registers)


func test_invalid_points_are_rejected() -> void:
	var library := RestPointLibrary.new()
	var bad: Array = [
		"heal",
		{"wakeup_dialogue": "d"},
		{"spawn": "", "wakeup_dialogue": "d"},
		{"spawn": "s"},
		{"spawn": "s", "wakeup_dialogue": "d", "facing": "north"},
		{"spawn": "s", "wakeup_dialogue": "d", "registers": "oui"},
		{"spawn": "s", "wakeup_dialogue": "d", "typo": 1},
	]
	for i: int in bad.size():
		assert_false(library.add_from_dict({"points": {"bad_%d" % i: bad[i]}}, "t"),
			str(bad[i]))
	assert_push_error_count(bad.size())
	assert_eq(library.size(), 0)


func test_invalid_roots_are_rejected() -> void:
	var library := RestPointLibrary.new()
	assert_false(library.add_from_dict({"points": []}, "t"))
	assert_false(library.add_from_dict({"points": {}, "typo": 1}, "t"))
	assert_false(library.add_from_dict({"points": {}, "registered_title": " "}, "t"))
	assert_false(_library.add_from_dict({"points": {"viridian_center": {"spawn": "s",
		"wakeup_dialogue": "d"}}}, "autre"))
	assert_push_error_count(4)
	assert_string_contains(_library.get_errors()[0], "point déjà défini dans test")
	assert_eq(_library.get_point(&"viridian_center").spawn, &"heal", "le premier est gardé")


func test_missing_or_invalid_file_is_an_error() -> void:
	var library := RestPointLibrary.new()
	assert_false(library.load_file("res://tests/fixtures/nope.json"))
	assert_push_error("fichier introuvable")


# --- Enregistrement (dossier 09 §7) ----------------------------------------------------

func test_new_game_rests_at_home() -> void:
	var state := _state()
	assert_eq(state.heal_map, &"player_house_1f", "défaut de GameState = la maison")
	assert_eq(state.heal_spawn, &"heal")
	assert_true(_library.has_point(state.heal_map))
	assert_false(_library.get_point(state.heal_map).registers)


func test_healing_at_a_center_registers_it() -> void:
	var state := _state()
	assert_true(RestPointLibrary.register(state, _library.get_point(&"viridian_center")),
		"changement : toast")
	assert_eq(state.heal_map, &"viridian_center")
	assert_eq(state.heal_spawn, &"heal")


func test_second_heal_at_the_same_center_changes_nothing() -> void:
	var state := _state()
	var center := _library.get_point(&"viridian_center")
	RestPointLibrary.register(state, center)
	assert_false(RestPointLibrary.register(state, center), "aucun toast la seconde fois")
	assert_eq(state.heal_map, &"viridian_center")


func test_mom_never_registers_home() -> void:
	var state := _state()
	var house := _library.get_point(&"player_house_1f")
	assert_false(RestPointLibrary.register(state, house), "maison avant tout Centre")
	RestPointLibrary.register(state, _library.get_point(&"viridian_center"))
	assert_false(RestPointLibrary.register(state, house), "Maman soigne sans réenregistrer")
	assert_eq(state.heal_map, &"viridian_center", "le dernier Centre reste le point de retour")


func test_register_without_state_or_point_does_nothing() -> void:
	assert_false(RestPointLibrary.register(null, _library.get_point(&"viridian_center")))
	assert_false(RestPointLibrary.register(_state(), null))


# --- Réveil et toast -----------------------------------------------------------------

func test_wakeup_point_follows_the_saved_rest_point() -> void:
	var state := _state()
	assert_eq(_library.wakeup_point(state).wakeup_dialogue, &"mom_wakeup", "chez Maman")
	RestPointLibrary.register(state, _library.get_point(&"viridian_center"))
	var point := _library.wakeup_point(state)
	assert_eq(point.map, &"viridian_center")
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup", "au Centre, l'infirmière")


func test_unknown_rest_point_wakes_up_there_without_a_word() -> void:
	var state := _state()
	state.heal_map = &"old_center"
	state.heal_spawn = &"door"
	var point := _library.wakeup_point(state)
	assert_eq(point.map, &"old_center")
	assert_eq(point.spawn, &"door")
	assert_eq(point.facing, Vector2i.UP)
	assert_eq(point.wakeup_dialogue, &"", "aucun mot")
	assert_false(point.registers)
	state.heal_map = &"viridian_center"
	assert_eq(_library.wakeup_point(state).wakeup_dialogue, &"", "autre point d'apparition")


func test_registered_toast_names_the_zone_in_its_detail() -> void:
	assert_eq(_library.registered_toast("Jadielle"),
		PackedStringArray(["Point de repos enregistré", "Jadielle"]))
