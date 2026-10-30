extends GutTest
## Jalon 23 (`jalon-23.md` §2.15, dossier 26 §11, N-20) : sauvegarde **v8**, champ « safari »
## ({ active, steps_left, balls_left }) écrit seulement pendant une visite ; migration 7 → 8 sans
## rien inventer ; contenu invalide = aucune visite (jamais de pas ni de Balls rendus).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_save_j23.json"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _new_state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-22T02:00:00")
	state.new_game(23)
	return state


func _round_trip(state: Node) -> Node:
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), _data))
	return loaded


func test_the_format_is_v8_and_the_step_7_to_8_invents_nothing() -> void:
	assert_eq(SaveSystem.VERSION, 9, "v8 : jalon 23 (visite du Parc Safari), v9 JR")
	var bare := {"version": 7}
	assert_eq(SaveSystem.upgrade(bare, 8), OK)
	assert_eq(bare, {"version": 8}, "« safari » absent = aucune visite")
	assert_eq(SaveSystem.migration_note(7, 8), "sauvegarde v7 → v8")


func test_a_new_game_has_no_visit_and_writes_no_safari_field() -> void:
	var state := _new_state()
	assert_false(state.safari.active)
	assert_false(state.to_dict().has("safari"), "hors visite : rien d'écrit")


func test_an_active_visit_survives_a_reload() -> void:
	var state := _new_state()
	state.safari = SafariVisit.start(1000, SafariConfig.load_default())
	state.safari.steps_left = 123
	state.safari.balls_left = 7
	assert_eq(state.to_dict().get("safari"),
		{"active": true, "steps_left": 123, "balls_left": 7})
	var loaded := _round_trip(state)
	assert_true(loaded.safari.active)
	assert_eq([loaded.safari.steps_left, loaded.safari.balls_left], [123, 7])


func test_a_finished_visit_is_not_written_and_reloads_inactive() -> void:
	var state := _new_state()
	state.safari = SafariVisit.start(1000, SafariConfig.load_default())
	state.safari.finish()
	var loaded := _round_trip(state)
	assert_false(loaded.safari.active)


func test_an_invalid_safari_field_gives_no_visit() -> void:
	for bad: Variant in [{"active": true, "steps_left": -3, "balls_left": 5},
			{"active": true, "steps_left": 10, "balls_left": 0}, "texte", 12]:
		var state := _new_state()
		var content: Dictionary = state.to_dict()
		content["safari"] = bad
		var loaded: Node = autofree(GameStateScript.new())
		loaded.load_dict(content, _data)
		assert_false(loaded.safari.active, "invalide : %s" % str(bad))
