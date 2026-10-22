extends GutTest
## Panthéon dans la sauvegarde (jalon 30, sous-jalon 30A, T7 ; `jalon-30.md` §2.6, §5, §6 n° 5).
## « hall_of_fame » est un champ **facultatif** de la v7, comme « mount » (passe systèmes 2) :
## aucune nouvelle version ; écrit seulement si le Panthéon n'est pas vide ; une sauvegarde sans
## le champ (v7 du J15, ou v8 du J23 quand elle existera) se relit avec un Panthéon vide et se
## réécrit à l'identique.
## **Système de sauvegarde : à valider seul par Kevin sur le téléphone (règle 1 de CLAUDE.md).**

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j30.json"
const FIXTURE_V6_S21 := "res://tests/fixtures/save/v6_kevin_s21.json"

var _data: PokemonData
var _fs: MemoryFs
var _save: SaveSystem


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-22T10:00:00")
	state.new_game(30)
	state.party.add(PokemonFactory.create(_data, &"charizard", 65, GameRng.new(1)))
	state.party.add(PokemonFactory.create(_data, &"lapras", 58, GameRng.new(2)))
	state.starter_species = &"charmander"
	return state


func _fixture(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "fixture lisible : %s" % path)
	return parsed if parsed is Dictionary else {}


func _entry_of(state: Node) -> Dictionary:
	return HallOfFame.snapshot(state.party.get_all(), state.player_name, state.starter_species,
		state.play_time, "2026-10-22T21:04:00")


func test_no_new_save_version() -> void:
	assert_eq(SaveSystem.VERSION, 7, "champ facultatif : la version ne change pas")


func test_an_empty_hall_writes_no_field() -> void:
	var saved: Dictionary = _state().to_dict()
	assert_false(saved.has("hall_of_fame"), "fichier d'avant le J30")


func test_a_new_game_empties_the_hall() -> void:
	var state := _state()
	state.hall_of_fame.add(_entry_of(state))
	state.new_game(1)
	assert_true(state.hall_of_fame.is_empty())


func test_the_hall_is_written_and_read_back() -> void:
	var state := _state()
	assert_eq(state.hall_of_fame.add(_entry_of(state)), HallOfFame.AddResult.ADDED)
	assert_eq(state.hall_of_fame.add(_entry_of(state)), HallOfFame.AddResult.ADDED)
	assert_eq(_save.write(state.to_dict()), OK)
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	var loaded := _state()
	assert_true(loaded.load_dict(content, _data), "chargé sans entrée écartée")
	assert_eq(loaded.hall_of_fame.size(), 2)
	assert_eq(loaded.hall_of_fame.to_array(), state.hall_of_fame.to_array(), "à l'identique")
	var first: Dictionary = loaded.hall_of_fame.get_entry(0)
	assert_eq(first["team"][0]["species"], "charizard")
	assert_eq(first["team"][0]["uid"], state.party.get_at(0).uid, "identifiant individuel")
	assert_eq(_save.write(loaded.to_dict()), OK)
	assert_eq(JSON.parse_string(_fs.files[PATH]), JSON.parse_string(JSON.stringify(
		_with_version(state.to_dict()))), "réécrit à l'identique")


func test_loading_replaces_the_hall_of_the_session() -> void:
	var state := _state()
	state.hall_of_fame.add(_entry_of(state))
	var empty: Dictionary = _state().to_dict()
	state.load_dict(empty, _data)
	assert_true(state.hall_of_fame.is_empty(), "pas de fuite d'une partie à l'autre")


func test_a_v7_save_without_the_field_loads_and_rewrites_unchanged() -> void:
	# Aucune fixture v7 : la vraie partie v6 du S21 passée en v7 par le J15 (« daycare » vide).
	var original := _fixture(FIXTURE_V6_S21)
	assert_eq(int(original["version"]), 6)
	var v7: Dictionary = original.duplicate(true)
	v7["version"] = 7
	v7["daycare"] = {}
	assert_false(v7.has("hall_of_fame"))
	_fs.files[PATH] = JSON.stringify(v7, "\t")
	var content := _save.read()
	assert_eq(_save.last_status, OK, "acceptée")
	var state := _state()
	assert_true(state.load_dict(content, _data), "chargée sans entrée écartée")
	assert_true(state.hall_of_fame.is_empty(), "Panthéon vide")
	assert_eq(_save.write(state.to_dict()), OK)
	assert_eq(JSON.parse_string(_fs.files[PATH]), JSON.parse_string(JSON.stringify(v7)),
		"réécrite à l'identique, sans « hall_of_fame »")


func test_a_v6_save_is_migrated_and_gets_an_empty_hall() -> void:
	_fs.files[PATH] = FileAccess.get_file_as_string(FIXTURE_V6_S21)
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	var state := _state()
	assert_true(state.load_dict(content, _data))
	assert_true(state.hall_of_fame.is_empty())
	assert_false(state.to_dict().has("hall_of_fame"))


func test_a_later_version_dict_without_the_field_loads_with_an_empty_hall() -> void:
	# Le J23 passe la sauvegarde en v8 sur sa branche : GameState lit le dictionnaire migré, sans
	# regarder la version ; le champ du J30 reste facultatif dans la v8 (aucun conflit de numéro).
	var dict: Dictionary = _state().to_dict()
	dict["version"] = 8
	var loaded := _state()
	loaded.hall_of_fame.add(_entry_of(loaded))
	assert_true(loaded.load_dict(dict, _data))
	assert_true(loaded.hall_of_fame.is_empty())


func test_a_malformed_entry_is_dropped_and_reported() -> void:
	var state := _state()
	state.hall_of_fame.add(_entry_of(state))
	var dict: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	(dict["hall_of_fame"] as Array).append({"team": "rien"})
	var loaded := _state()
	assert_false(loaded.load_dict(dict, _data), "entrée écartée signalée")
	assert_push_error("Panthéon")
	assert_eq(loaded.hall_of_fame.size(), 1, "les entrées valides sont gardées")


func test_a_wrong_field_type_gives_an_empty_hall() -> void:
	var dict: Dictionary = _state().to_dict()
	dict["hall_of_fame"] = "texte"
	var loaded := _state()
	assert_true(loaded.load_dict(dict, _data), "champ illisible = absent")
	assert_true(loaded.hall_of_fame.is_empty())


func _with_version(dict: Dictionary) -> Dictionary:
	var result := dict.duplicate(true)
	result["version"] = SaveSystem.VERSION
	return result
