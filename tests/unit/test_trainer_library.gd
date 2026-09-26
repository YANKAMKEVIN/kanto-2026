extends GutTest
## TrainerLibrary et TrainerData : data/trainers/, validation, équipes selon le starter,
## cohérence avec le choix du rival (jalon 4 §2.2, décisions de Kevin du §8).

const FIXTURES := "res://tests/fixtures/trainers/"

var _data: PokemonData
var _fixture_data: PokemonData
var _library: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_fixture_data = PokemonData.new()
	_fixture_data.load_dir("res://tests/fixtures/pokemon/valid/")


func before_each() -> void:
	_library = TrainerLibrary.new(_fixture_data)


func _valid_entry() -> Dictionary:
	return {
		"name": "Test", "ai": "random", "can_lose": false, "heal_after": false,
		"gives_exp": true, "prize_money": 10, "team": [{ "species": "sprout", "level": 5 }],
	}


func _errors() -> String:
	return "\n".join(_library.get_errors())


# --- Vraies données ---------------------------------------------------------------------

func test_real_rival_lab_loads() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir())
	assert_eq(library.get_errors().size(), 0)
	var rival := library.get_trainer(&"rival_lab")
	assert_eq(rival.name, "Le Rival")
	assert_eq(rival.ai, &"random")
	assert_true(rival.can_lose)
	assert_true(rival.heal_after)
	assert_false(rival.gives_exp, "premier combat : pas d'XP")
	assert_eq(rival.prize_money, 0, "premier combat : pas d'argent")
	assert_false(rival.end_message, "pas de « Tu as battu… » (décision de Kevin n° 15)")


func test_rival_team_matches_the_rival_pick_for_each_starter() -> void:
	var library := TrainerLibrary.new(_data)
	library.load_dir()
	var offer := StarterOffer.new()
	offer.load_file()
	var expected := {&"bulbasaur": &"charmander", &"charmander": &"squirtle",
		&"squirtle": &"bulbasaur"}
	for starter: StringName in offer.get_species_ids():
		var team := library.get_trainer(&"rival_lab").team_for(starter)
		assert_eq(team.size(), 1, String(starter))
		assert_eq(team[0].species, offer.rival_pick(starter, _data), String(starter))
		assert_eq(team[0].species, expected[starter], String(starter))
		assert_eq(team[0].level, offer.level, "même niveau que le starter")


func test_build_real_rival_team() -> void:
	var library := TrainerLibrary.new(_data)
	library.load_dir()
	var party := library.build_team(&"rival_lab", &"charmander", GameRng.new(3))
	assert_eq(party.size(), 1)
	assert_eq(party.get_lead().species_id, &"squirtle")
	assert_eq(party.get_lead().level, 5)
	assert_eq(party.get_lead().hp, party.get_lead().max_hp())


# --- Fixtures ---------------------------------------------------------------------------

func test_fixture_directory_and_fields() -> void:
	assert_true(_library.load_dir(FIXTURES + "valid/"))
	assert_eq(_library.get_errors().size(), 0, _errors())
	assert_eq(_library.get_ids(), [&"test_rival", &"youngster"] as Array[StringName])
	var joey := _library.get_trainer(&"youngster")
	assert_eq([joey.name, joey.can_lose, joey.heal_after, joey.gives_exp, joey.prize_money],
		["Gamin Joey", false, false, true, 64])
	assert_eq(joey.source, FIXTURES + "valid/youngsters.json")
	assert_eq(joey.make_ai().kind, &"random")
	assert_null(_library.get_trainer(&"nobody"))
	assert_false(_library.has_trainer(&"nobody"))


func test_team_by_starter_and_fixed_team() -> void:
	_library.load_dir(FIXTURES + "valid/")
	var rival := _library.get_trainer(&"test_rival")
	assert_eq(rival.team_for(&"sprout")[0].species, &"wisp")
	var two := rival.team_for(&"wisp")
	assert_eq([two[0].species, two[0].level, two[1].species, two[1].level],
		[&"tree", 6, &"flower", 4])
	assert_eq(rival.team_for(&"tree").size(), 0, "aucune équipe pour ce starter")
	var joey := _library.get_trainer(&"youngster")
	assert_eq(joey.team_for(&"anything")[0].species, &"vine", "équipe fixe")


func test_build_team_is_reproducible() -> void:
	_library.load_dir(FIXTURES + "valid/")
	var first := _library.build_team(&"test_rival", &"wisp", GameRng.new(8))
	var second := _library.build_team(&"test_rival", &"wisp", GameRng.new(8))
	assert_eq(first.size(), 2)
	assert_eq(first.to_array(), second.to_array())


func test_build_team_errors() -> void:
	_library.load_dir(FIXTURES + "valid/")
	assert_null(_library.build_team(&"nobody", &"sprout", GameRng.new(1)))
	assert_null(_library.build_team(&"test_rival", &"tree", GameRng.new(1)))
	assert_push_error_count(2)


# --- Validation -------------------------------------------------------------------------

func test_broken_json_and_missing_dir() -> void:
	assert_false(_library.load_dir(FIXTURES + "bad_json/"))
	assert_push_error("broken.json, ligne 6")
	assert_false(_library.load_dir(FIXTURES + "nowhere/"))
	assert_push_error_count(2)


func test_duplicate_id_is_rejected() -> void:
	_library.load_dir(FIXTURES + "valid/")
	assert_false(_library.add_from_dict({"youngster": _valid_entry()}, "autre.json"))
	assert_push_error("déjà défini")
	assert_eq(_library.get_trainer(&"youngster").name, "Gamin Joey")


func test_end_message_is_optional_and_true_by_default() -> void:
	var quiet := _valid_entry()
	quiet["end_message"] = false
	assert_true(_library.add_from_dict({"usual": _valid_entry(), "quiet": quiet}, "t"))
	assert_true(_library.get_trainer(&"usual").end_message)
	assert_false(_library.get_trainer(&"quiet").end_message)


func test_invalid_fields_are_rejected() -> void:
	var entry := _valid_entry()
	entry.erase("gives_exp")
	entry["ai"] = "smart"
	entry["can_lose"] = "yes"
	entry["prize_money"] = -5
	entry["reward"] = 3
	entry["end_message"] = "no"
	assert_false(_library.add_from_dict({"bad": entry}, "t"))
	assert_push_error_count(6)
	assert_string_contains(_errors(), "« end_message » vaut true ou false")
	var errors := _errors()
	assert_string_contains(errors, "clé inconnue « reward »")
	assert_string_contains(errors, "« gives_exp » est obligatoire")
	assert_string_contains(errors, "« ai » vaut random")
	assert_string_contains(errors, "« can_lose » vaut true ou false")
	assert_string_contains(errors, "« prize_money » doit être un entier ≥ 0")
	assert_false(_library.has_trainer(&"bad"))


func test_team_and_team_by_starter_are_exclusive() -> void:
	var both := _valid_entry()
	both["team_by_starter"] = {"sprout": [{ "species": "wisp", "level": 5 }]}
	var neither := _valid_entry()
	neither.erase("team")
	assert_false(_library.add_from_dict({"both": both, "neither": neither}, "t"))
	assert_push_error_count(2)
	assert_string_contains(_errors(), "une et une seule")


func test_invalid_teams_are_rejected() -> void:
	var entry := _valid_entry()
	entry["team"] = [
		{ "species": "missingno", "level": 5 },
		{ "species": "sprout", "level": 0 },
		{ "species": "sprout", "level": 5, "moves": [] },
	]
	var by_starter := _valid_entry()
	by_starter.erase("team")
	by_starter["team_by_starter"] = {"pikachu": [{ "species": "sprout", "level": 5 }],
		"sprout": []}
	var too_many := _valid_entry()
	too_many["team"] = []
	for i: int in 7:
		too_many["team"].append({ "species": "sprout", "level": 5 })
	assert_false(_library.add_from_dict({"a": entry, "b": by_starter, "c": too_many}, "t"))
	assert_push_error_count(6)
	var errors := _errors()
	assert_string_contains(errors, "espèce inconnue « missingno »")
	assert_string_contains(errors, "« level » doit être un entier de 1 à 100")
	assert_string_contains(errors, "clé inconnue « moves »")
	assert_string_contains(errors, "starter inconnu « pikachu »")
	assert_string_contains(errors, "team_by_starter « sprout » : une équipe de 1 à 6")
	assert_string_contains(errors, "« c » team : une équipe de 1 à 6")
	assert_eq(_library.get_ids().size(), 0)
