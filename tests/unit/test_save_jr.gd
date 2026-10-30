extends GutTest
## Chantier JR (dossier-joueuse-rivale.md JR-1, JR-8) et costumes (dossier-costumes.md CO-9) :
## sauvegarde **v9**, champs « rival_look » et « player_costume » ; migration 8 → 9 sans rien
## inventer (rival garçon, tenue d'origine) ; valeur inconnue = défaut, sans erreur ; la joueuse
## (`player_look = heroine`) se recharge telle quelle.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_save_jr.json"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _new_state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-30T20:00:00")
	state.new_game(9)
	return state


func _round_trip(state: Node) -> Node:
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), _data))
	return loaded


func test_the_format_is_v9_and_the_step_8_to_9_invents_nothing() -> void:
	assert_eq(SaveSystem.VERSION, 9, "v9 : chantier JR (rival_look) et costumes (player_costume)")
	var bare := {"version": 8}
	assert_eq(SaveSystem.upgrade(bare, 9), OK)
	assert_eq(bare, {"version": 9}, "les défauts viennent de load_dict")
	assert_eq(SaveSystem.migration_note(8, 9), "sauvegarde v8 → v9")


func test_a_new_game_has_the_boy_rival_and_the_original_outfit() -> void:
	var state := _new_state()
	assert_eq(state.rival_look, &"rival")
	assert_eq(state.player_costume, &"")
	var dict: Dictionary = state.to_dict()
	assert_false(dict.has("rival_look"), "défaut : rien d'écrit (le fichier reste celui de la v8)")
	assert_false(dict.has("player_costume"), "tenue d'origine : rien d'écrit")
	state.rival_look = &"rivale"
	assert_eq(state.to_dict().get("rival_look"), "rivale")


func test_a_v8_save_loads_with_the_boy_rival_and_the_original_outfit() -> void:
	var state := _new_state()
	state.player_look = &"heroine"
	var content: Dictionary = state.to_dict()
	content.erase("rival_look")
	content.erase("player_costume")
	content["version"] = 8
	assert_eq(SaveSystem.upgrade(content), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(content, _data))
	assert_eq(loaded.rival_look, &"rival", "migration : le rival garçon (JR-8)")
	assert_eq(loaded.player_costume, &"", "migration : la tenue d'origine (CO-9)")
	assert_eq(loaded.player_look, &"heroine")


func test_the_heroine_and_the_girl_rival_survive_a_reload() -> void:
	var state := _new_state()
	state.player_look = &"heroine"
	state.rival_look = &"rivale"
	var loaded := _round_trip(state)
	assert_eq(loaded.player_look, &"heroine")
	assert_eq(loaded.rival_look, &"rivale")


func test_unknown_values_fall_back_to_the_defaults_without_error() -> void:
	var state := _new_state()
	var content: Dictionary = state.to_dict()
	for bad: Variant in ["inconnue", 12, null, ""]:
		content["player_look"] = bad
		content["rival_look"] = bad
		content["player_costume"] = "goku" if bad is String and bad == "" else bad
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(content, _data), "valeur %s" % str(bad))
		assert_eq(loaded.player_look, &"hero")
		assert_eq(loaded.rival_look, &"rival")
		assert_eq(loaded.player_costume, &"", "aucun costume connu de cette build")


func test_new_game_resets_the_looks() -> void:
	var state := _new_state()
	state.player_look = &"heroine"
	state.rival_look = &"rivale"
	state.new_game(9)
	assert_eq([state.player_look, state.rival_look, state.player_costume],
		[&"hero", &"rival", &""])
