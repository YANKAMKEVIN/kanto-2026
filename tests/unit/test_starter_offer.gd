extends GutTest
## StarterOffer : offre du labo (data/pokemon/starters.json) et choix du rival par
## l'avantage de type (jalon 4 §2.1 ; dossier 02 §7 et §9).

const FIXTURES := "res://tests/fixtures/pokemon/"

var _data: PokemonData
var _fixture_data: PokemonData
var _offer: StarterOffer


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_fixture_data = PokemonData.new()
	_fixture_data.load_dir(FIXTURES + "valid/")


func before_each() -> void:
	_offer = StarterOffer.new()


func _valid_dict() -> Dictionary:
	return {
		"map": "lab", "level": 5, "prompt": "CHOISIS",
		"choices": [
			{ "species": "a", "npc": "a_npc", "blurb": "A." },
			{ "species": "b", "npc": "b_npc", "blurb": "B." },
		],
		"open_flag": "open", "done_flag": "done", "chosen_scene": "scene",
	}


# --- Vraies données ---------------------------------------------------------------------

func test_real_offer_loads_with_the_final_texts() -> void:
	assert_true(_offer.load_file())
	assert_eq(_offer.get_errors().size(), 0)
	assert_true(_offer.check_species(_data))
	assert_eq(_offer.map_id, &"oak_lab")
	assert_eq(_offer.level, 5)
	assert_eq(_offer.prompt, "CHOISIS TON PREMIER PARTENAIRE")
	assert_eq(_offer.open_flag, &"starter_offered")
	assert_eq(_offer.done_flag, &"starter_chosen")
	assert_eq(_offer.chosen_scene, &"starter_chosen")
	assert_eq(_offer.get_species_ids(), [&"bulbasaur", &"charmander", &"squirtle"]
		as Array[StringName])
	assert_eq(_offer.get_npc_ids(), [&"bulbasaur", &"charmander", &"squirtle"]
		as Array[StringName])
	assert_eq(_offer.get_choice(&"bulbasaur").blurb, "Calme et tenace.")
	assert_eq(_offer.get_choice(&"charmander").blurb, "Fougueux et courageux.")
	assert_eq(_offer.get_choice(&"squirtle").blurb, "Vif et malicieux.")
	assert_null(_offer.get_choice(&"pikachu"))


func test_rival_takes_the_starter_with_the_type_advantage() -> void:
	_offer.load_file()
	assert_eq(_offer.rival_pick(&"bulbasaur", _data), &"charmander")
	assert_eq(_offer.rival_pick(&"charmander", _data), &"squirtle")
	assert_eq(_offer.rival_pick(&"squirtle", _data), &"bulbasaur")


func test_real_offered_npcs_exist_on_the_lab_map() -> void:
	_offer.load_file()
	var roster := NpcRoster.load_for_map(_offer.map_id)
	for option: StarterOption in _offer.get_choices():
		var spec := roster.get_spec(option.npc)
		assert_not_null(spec, String(option.npc))
		if spec != null:
			assert_eq(spec.sprite, option.species, "même sprite que l'espèce")


func test_starters_at_the_offered_level_know_one_to_four_moves() -> void:
	_offer.load_file()
	for species: StringName in _offer.get_species_ids():
		var count := _data.get_species(species).moves_at(_offer.level).size()
		assert_between(count, 1, 4, String(species))


# --- Fixture ----------------------------------------------------------------------------

func test_tie_keeps_the_file_order() -> void:
	assert_true(_offer.load_file(FIXTURES + "starters/tie.json"))
	assert_true(_offer.check_species(_fixture_data))
	assert_eq(_offer.level, 7)
	# Spectre contre Plante (Fleur, Arbre) : 1 partout → le premier du fichier restant.
	assert_eq(_offer.rival_pick(&"wisp", _fixture_data), &"flower")
	# Fleur (Plante) : Spectre 1 contre Plante 0,5 → Feu Follet.
	assert_eq(_offer.rival_pick(&"flower", _fixture_data), &"wisp")


func test_rival_pick_of_an_unknown_choice_is_an_error() -> void:
	_offer.load_file()
	assert_eq(_offer.rival_pick(&"pikachu", _data), &"")
	assert_push_error("n'est pas un choix")


# --- Validation -------------------------------------------------------------------------

func test_broken_json_reports_the_line() -> void:
	assert_false(_offer.load_file(FIXTURES + "starters/broken.json"))
	assert_push_error("ligne 4")


func test_missing_file_is_an_error() -> void:
	assert_false(_offer.load_file(FIXTURES + "starters/none.json"))
	assert_push_error("fichier introuvable")


func test_unknown_and_missing_keys_are_rejected() -> void:
	var dict := _valid_dict()
	dict.erase("prompt")
	dict["extra"] = 1
	assert_false(_offer.add_from_dict(dict, "t"))
	assert_push_error_count(2)
	assert_string_contains("\n".join(_offer.get_errors()), "clé inconnue « extra »")
	assert_string_contains("\n".join(_offer.get_errors()), "« prompt » est obligatoire")
	assert_eq(_offer.get_choices().size(), 0, "offre vide")


func test_invalid_values_are_rejected() -> void:
	var dict := _valid_dict()
	dict["level"] = 0
	dict["open_flag"] = ""
	assert_false(_offer.add_from_dict(dict, "t"))
	assert_push_error_count(2)


func test_invalid_choices_are_rejected() -> void:
	var dict := _valid_dict()
	dict["choices"] = [{ "species": "a", "npc": "x", "blurb": "A." }]
	assert_false(_offer.add_from_dict(dict, "t"))
	assert_push_error("au moins 2 choix")
	dict["choices"] = [
		{ "species": "a", "npc": "x", "blurb": "A.", "types": [] },
		{ "species": "a", "npc": "y", "blurb": "" },
		{ "species": "a", "npc": "z", "blurb": "Z." },
	]
	assert_false(_offer.add_from_dict(dict, "t"))
	assert_push_error_count(4, "1 + clé inconnue, texte vide, doublon")
	assert_eq(_offer.get_choices().size(), 0)


func test_unknown_offered_species_is_reported() -> void:
	assert_true(_offer.add_from_dict(_valid_dict(), "t"))
	assert_false(_offer.check_species(_data))
	assert_push_error_count(2, "a et b")
