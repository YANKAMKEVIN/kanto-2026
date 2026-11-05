extends GutTest
## Chapitre Johto, JOH6 (`jalon-joh6.md` §2.6, JH-46) : la variante de couleur dans la **vraie
## sauvegarde** (SaveSystem + GameState) : clé « variant » écrite seulement si non vide ; une partie
## sans la clé (toutes celles d'avant le JOH6) se relit identique ; un Léviator rouge dans l'équipe
## et au Stockage traverse écriture et relecture ; une variante inconnue est relue en forme normale
## sans refuser la partie. Aucun changement de version.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_joh6.json"

var _fs: MemoryFs
var _save: SaveSystem
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-04T21:00:00")
	state.new_game(10)
	return state


func _with_party() -> Node:
	var state := _state()
	for species: StringName in [&"blastoise", &"gyarados", &"raikou"]:
		state.party.add(PokemonFactory.create(_data, species, 55, GameRng.new(species.hash())))
	state.storage.add(PokemonFactory.create(_data, &"gyarados", 50, GameRng.new(7)))
	return state


func _reload() -> Node:
	var loaded := _state()
	assert_eq(_save.last_status, OK)
	assert_true(loaded.load_dict(_save.read(), _data), "partie relue")
	return loaded


func test_no_variant_key_is_written_for_normal_pokemon_and_the_version_is_unchanged() -> void:
	var state := _with_party()
	var dict: Dictionary = state.to_dict()
	assert_eq(SaveSystem.VERSION, 10, "pas de nouvelle version (v10 du JOH0)")
	for member: Dictionary in dict["party"]:
		assert_false(member.has("variant"), "%s : rien d'écrit" % member["species"])
	assert_eq(_save.write(dict), OK)
	var loaded := _reload()
	for i: int in loaded.party.size():
		assert_eq(loaded.party.get_at(i).variant, &"")
	assert_eq(JSON.parse_string(JSON.stringify(loaded.to_dict())),
		JSON.parse_string(JSON.stringify(dict)), "relecture identique")


func test_a_red_gyarados_survives_a_real_write_and_read_in_party_and_storage() -> void:
	var state := _with_party()
	state.party.get_at(1).variant = &"red"
	state.storage.get_all()[0].variant = &"red"
	var dict: Dictionary = state.to_dict()
	assert_eq(dict["party"][1]["variant"], "red")
	assert_false((dict["party"][0] as Dictionary).has("variant"))
	assert_eq(_save.write(dict), OK)
	var loaded := _reload()
	assert_eq(loaded.party.get_at(1).variant, &"red", "équipe")
	assert_eq(loaded.party.get_at(0).variant, &"", "les autres restent normaux")
	assert_eq(loaded.storage.get_all()[0].variant, &"red", "Stockage")
	# Seconde écriture : identique (la clé ne se perd pas et n'apparaît pas ailleurs).
	assert_eq(_save.write(loaded.to_dict()), OK)
	var again := _reload()
	assert_eq(JSON.parse_string(JSON.stringify(again.to_dict())),
		JSON.parse_string(JSON.stringify(loaded.to_dict())))


func test_an_unknown_variant_is_read_as_normal_without_refusing_the_save() -> void:
	var state := _with_party()
	var dict: Dictionary = state.to_dict()
	dict["party"][1]["variant"] = "shiny"
	assert_eq(_save.write(dict), OK)
	var loaded := _reload()
	assert_eq(loaded.party.size(), 3, "rien de perdu")
	assert_eq(loaded.party.get_at(1).variant, &"")
	assert_push_warning("variante inconnue")
