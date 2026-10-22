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
	assert_eq(rival.name, "{rival}", "prénom résolu à l'affichage (OUV.2)")
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


func test_real_rival_lab_keeps_the_bag_silent() -> void:
	var library := TrainerLibrary.new(_data)
	library.load_dir()
	assert_false(library.get_trainer(&"rival_lab").allow_bag, "décision n° 12")


## Rival n° 2 (jalon-07.md §3.8, dossier 09 §13) : IA smart, Roucool Nv. 7 puis le starter
## avantagé Nv. 8, 35 ₽ par niveau, SAC permis, défaite qui compte.
func test_real_rival_route22() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir())
	var rival := library.get_trainer(&"rival_route22")
	assert_not_null(rival)
	assert_eq(rival.name, "{rival}", "prénom résolu à l'affichage (OUV.2)")
	assert_eq(rival.ai, BattleAI.SMART)
	assert_eq(rival.make_ai().kind, BattleAI.SMART)
	assert_false(rival.can_lose, "défaite = retour au point de repos")
	assert_false(rival.heal_after)
	assert_true(rival.gives_exp)
	assert_eq(rival.prize_money, 0)
	assert_eq(rival.prize_per_level, 35)
	assert_true(rival.allow_bag)
	assert_true(rival.start_message, "« {rival} veut se battre ! »")
	assert_false(rival.end_message)
	var advantaged := {&"bulbasaur": &"charmander", &"charmander": &"squirtle",
		&"squirtle": &"bulbasaur"}
	for starter: StringName in advantaged:
		var team := rival.team_for(starter)
		assert_eq(team.size(), 2, String(starter))
		assert_eq([team[0].species, team[0].level], [&"pidgey", 7], String(starter))
		assert_eq([team[1].species, team[1].level], [advantaged[starter], 8], String(starter))


## Les 5 Dresseurs de la Forêt de Jade (dossier 10 §8, jalon-09.md §2.4.1) : montants fixes
## du dossier, IA débutante, SAC permis, messages génériques, défaite qui compte.
func test_real_viridian_forest_trainers() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var expected := {
		&"forest_scout_theo": ["Scout Théo", 72, [[&"caterpie", 6]]],
		&"forest_scout_noe": ["Scout Noé", 144, [[&"weedle", 6], [&"kakuna", 6]]],
		&"forest_youngster_tom": ["Gamin Tom", 84, [[&"rattata", 7]]],
		&"forest_scout_milo": ["Scout Milo", 144, [[&"caterpie", 6], [&"weedle", 6]]],
		&"forest_scout_eli": ["Scout Éli", 252,
			[[&"metapod", 7], [&"kakuna", 7], [&"caterpie", 7]]],
	}
	for id: StringName in expected:
		var trainer := library.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, expected[id][0], String(id))
		assert_eq(trainer.ai, BattleAI.RANDOM, String(id))
		assert_false(trainer.can_lose, "%s : défaite = retour au point de repos" % id)
		assert_false(trainer.heal_after, String(id))
		assert_true(trainer.gives_exp, String(id))
		assert_true(trainer.allow_bag, String(id))
		assert_true(trainer.start_message, String(id))
		assert_true(trainer.end_message, String(id))
		assert_eq(trainer.prize_per_level, 0, "%s : montant fixe" % id)
		assert_eq(trainer.prize_money, expected[id][1], String(id))
		assert_eq(trainer.prize_for(99), expected[id][1], "%s : indépendant du niveau" % id)
		var team: Array = []
		for slot: TrainerSlot in trainer.team_for(&"charmander"):
			team.append([slot.species, slot.level])
		assert_eq(team, expected[id][2], String(id))
		assert_eq(library.build_team(id, &"bulbasaur", GameRng.new(1)).size(),
			expected[id][2].size(), String(id))


## Jalon 14 (T5, jalon-14.md §2.11) : D1–D4 de la Route 25, équipes et récompenses de Rouge/Bleu
## (base de la classe × niveau du dernier Pokémon), capacités des tables de niveau.
func test_real_route_25_trainers() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var expected := {
		&"route_25_youngster_jules": ["Gamin Jules", 225, [[&"rattata", 15], [&"spearow", 15]]],
		&"route_25_hiker_gaston": ["Montagnard Gaston", 525,
			[[&"machop", 15], [&"geodude", 15]]],
		&"route_25_lass_zoe": ["Fillette Zoé", 225, [[&"nidoran_m", 15], [&"nidoran_f", 15]]],
		&"route_25_hiker_bernard": ["Montagnard Bernard", 595, [[&"onix", 17]]],
	}
	for id: StringName in expected:
		var trainer := library.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, expected[id][0], String(id))
		assert_eq(trainer.ai, BattleAI.RANDOM, String(id))
		assert_false(trainer.can_lose, String(id))
		assert_false(trainer.heal_after, String(id))
		assert_true(trainer.gives_exp, String(id))
		assert_eq(trainer.prize_money, expected[id][1], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team_for(&"charmander"):
			team.append([slot.species, slot.level])
		assert_eq(team, expected[id][2], String(id))
	var gaston := library.build_team(&"route_25_hiker_gaston", &"bulbasaur", GameRng.new(1))
	var machop := gaston.get_at(0)
	assert_eq(machop.moves.size(), 1, "Machoc 15 : Poing Karaté seul (table RB)")
	assert_eq(machop.moves[0].move_id, &"karate_chop")


func test_bag_and_prize_per_level_defaults() -> void:
	assert_true(_library.add_from_dict({"t": _valid_entry()}), _errors())
	var trainer := _library.get_trainer(&"t")
	assert_true(trainer.allow_bag, "SAC permis par défaut")
	assert_eq(trainer.prize_per_level, 0)


func test_bag_and_prize_per_level_are_read() -> void:
	var entry := _valid_entry()
	entry["bag"] = false
	entry["prize_money"] = 0
	entry["prize_per_level"] = 20
	assert_true(_library.add_from_dict({"t": entry}), _errors())
	var trainer := _library.get_trainer(&"t")
	assert_false(trainer.allow_bag)
	assert_eq(trainer.prize_per_level, 20)
	assert_eq(trainer.prize_for(9), 180)


func test_bag_and_prize_per_level_are_validated() -> void:
	var entry := _valid_entry()
	entry["bag"] = "non"
	entry["prize_per_level"] = -1
	assert_false(_library.add_from_dict({"t": entry}))
	assert_push_error_count(2)
	assert_string_contains(_errors(), "« bag » vaut true ou false")
	assert_string_contains(_errors(), "« prize_per_level » doit être un entier ≥ 0")
	assert_false(_library.has_trainer(&"t"))


func test_fixed_prize_and_prize_per_level_are_exclusive() -> void:
	var entry := _valid_entry()
	entry["prize_per_level"] = 35
	assert_false(_library.add_from_dict({"t": entry}), "prize_money 10 et prize_per_level 35")
	assert_push_error("sont exclusifs")
	assert_string_contains(_errors(), "sont exclusifs")
	var zero := _valid_entry()
	zero["prize_money"] = 0
	zero["prize_per_level"] = 35
	assert_true(TrainerLibrary.new(_fixture_data).add_from_dict({"z": zero}),
		"prize_money 0 : permis")


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


func test_start_message_is_optional_and_true_by_default() -> void:
	var quiet := _valid_entry()
	quiet["start_message"] = false
	assert_true(_library.add_from_dict({"usual": _valid_entry(), "quiet": quiet}, "t"))
	assert_true(_library.get_trainer(&"usual").start_message)
	assert_false(_library.get_trainer(&"quiet").start_message)
	# rival_lab l'a à faux (décision n° 17).
	var real := TrainerLibrary.new(_data)
	real.load_dir()
	assert_false(real.get_trainer(&"rival_lab").start_message)


func test_invalid_fields_are_rejected() -> void:
	var entry := _valid_entry()
	entry.erase("gives_exp")
	entry["ai"] = "genius"
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
	assert_string_contains(errors, "« ai » vaut random, smart")
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
	assert_string_contains(errors, "« moves » doit être une liste de 1 à 4")
	assert_string_contains(errors, "starter inconnu « pikachu »")
	assert_string_contains(errors, "team_by_starter « sprout » : une équipe de 1 à 6")
	assert_string_contains(errors, "« c » team : une équipe de 1 à 6")
	assert_eq(_library.get_ids().size(), 0)


# --- « switch » (jalon 13, IA qui change de Pokémon) ------------------------------------

func test_switch_defaults_to_false() -> void:
	assert_true(_library.add_from_dict({"t": _valid_entry()}), _errors())
	var trainer := _library.get_trainer(&"t")
	assert_false(trainer.can_switch)
	assert_false(trainer.make_ai().can_switch)


func test_switch_is_read_and_given_to_the_ai() -> void:
	var entry := _valid_entry()
	entry["ai"] = "smart"
	entry["switch"] = true
	assert_true(_library.add_from_dict({"t": entry}), _errors())
	var ai := _library.get_trainer(&"t").make_ai()
	assert_true(ai.can_switch)
	assert_eq(ai.kind, BattleAI.SMART)
	assert_false(ai.has_switched())


func test_switch_is_validated() -> void:
	var entry := _valid_entry()
	entry["switch"] = "oui"
	assert_false(_library.add_from_dict({"t": entry}))
	assert_push_error_count(1)
	assert_string_contains(_errors(), "« switch » vaut true ou false")


## Seuls Ondine et le rival n° 3 changent de Pokémon (T19) ; ni Pierre ni les autres. Jalon 16
## (décision de Kevin du 2026-10-15) : le rival n° 4 et Major Bob aussi. Jalon 19 (plan §2.6) :
## le rival n° 5 aussi.
func test_only_misty_surge_and_the_rivals_switch() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir())
	# Jalon 20 (T7, dossier 23 §11.3, §13.5) : Erika et Giovanni.
	var switching: Array[StringName] = [&"cerulean_gym_misty", &"rival_cerulean",
		&"rival_ss_anne", &"vermilion_gym_surge", &"rival_tower", &"celadon_gym_erika",
		&"giovanni_hideout", &"cinnabar_gym_blaine"]
	for id: StringName in library.get_ids():
		if not String(id).begins_with("qa_"):
			assert_eq(library.get_trainer(id).can_switch, switching.has(id), String(id))


# --- « moment » (jalon 13 §2.8, Grand moment du rival à la victoire) ---------------------

func test_moment_defaults_to_any_outcome() -> void:
	assert_true(_library.add_from_dict({"t": _valid_entry()}), _errors())
	assert_false(_library.get_trainer(&"t").moment_on_win)


func test_moment_win_is_read() -> void:
	var entry := _valid_entry()
	entry["moment"] = "win"
	assert_true(_library.add_from_dict({"t": entry}), _errors())
	assert_true(_library.get_trainer(&"t").moment_on_win)


func test_moment_accepts_only_win() -> void:
	for value: Variant in ["loss", "", true, ["win"]]:
		var entry := _valid_entry()
		entry["moment"] = value
		assert_false(_library.add_from_dict({"t_%s" % str(value): entry}), str(value))
	assert_push_error_count(4)
	assert_string_contains(_errors(), "« moment » vaut \"win\"")


## Seuls les rivaux n° 3, n° 4 (J16) et n° 5 (J19) ont « moment »: "win" ; les rivaux n° 1 et
## n° 2 gardent un moment par combat, victoire comme défaite.
func test_real_rivals_moment_rule() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir())
	for id: StringName in library.get_ids():
		assert_eq(library.get_trainer(id).moment_on_win,
			[&"rival_cerulean", &"rival_ss_anne", &"rival_tower"].has(id), String(id))
