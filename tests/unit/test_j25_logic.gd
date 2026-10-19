extends GutTest
## Logique pure du jalon 25 (dossier 28, `jalon-25.md` §2.1, §2.3, §2.5) : interrupteur global du
## Manoir, machines de quiz de l'Arène, échanges fixes du Labo.

const TRADES := "res://tests/fixtures/trades/test_trades.json"

var _data: PokemonData
var _rng: GameRng
var _flags: StoryFlags


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(25)
	_flags = StoryFlags.new()


# --- Interrupteur du Manoir -------------------------------------------------------------------

func test_switch_starts_off_and_toggles() -> void:
	assert_false(MansionSwitch.is_on(_flags))
	assert_true(MansionSwitch.is_closed(_flags, MansionSwitch.GateSet.A), "jeu A fermé sur ARRÊT")
	assert_false(MansionSwitch.is_closed(_flags, MansionSwitch.GateSet.B), "jeu B ouvert sur ARRÊT")
	assert_true(MansionSwitch.toggle(_flags))
	assert_false(MansionSwitch.is_closed(_flags, MansionSwitch.GateSet.A))
	assert_true(MansionSwitch.is_closed(_flags, MansionSwitch.GateSet.B))
	assert_false(MansionSwitch.toggle(_flags))
	assert_false(MansionSwitch.is_on(_flags))


func test_switch_resets_only_when_entering_from_the_island() -> void:
	MansionSwitch.toggle(_flags)
	assert_false(MansionSwitch.reset_on_entry(_flags, &"pokemon_mansion_2f"), "escalier : gardé")
	assert_true(MansionSwitch.is_on(_flags))
	assert_true(MansionSwitch.reset_on_entry(_flags, &"cinnabar_island"), "porte : remis à ARRÊT")
	assert_false(MansionSwitch.is_on(_flags))
	assert_false(MansionSwitch.reset_on_entry(_flags, &"cinnabar_island"), "déjà sur ARRÊT")


func test_switch_survives_save_round_trip() -> void:
	MansionSwitch.toggle(_flags)
	var loaded := StoryFlags.new()
	loaded.load_array(_flags.to_array())
	assert_true(MansionSwitch.is_on(loaded), "un chargement ne remet pas à zéro")


# --- Quiz de l'Arène --------------------------------------------------------------------------

func test_quiz_data_matches_dossier() -> void:
	var quiz := GymQuiz.load_default()
	assert_eq(quiz.get_errors().size(), 0)
	assert_eq(quiz.ids(), [1, 2, 3, 4, 5, 6] as Array[int])
	var answers := {1: true, 2: false, 3: false, 4: false, 5: true, 6: false}
	for id: int in answers:
		assert_eq(quiz.resolve(id, answers[id], _flags), GymQuiz.Result.RIGHT, "question %d" % id)
		assert_eq(quiz.trainer_id(id), StringName("cinnabar_gym_%d" % (id + 1)))
	assert_eq(quiz.question_for_trainer(&"cinnabar_gym_1"), 0, "le Dresseur 1 n'a pas de machine")


func test_quiz_wrong_answer_fights_then_opens() -> void:
	var quiz := GymQuiz.load_default()
	assert_true(quiz.should_ask(1, _flags))
	assert_eq(quiz.resolve(1, false, _flags), GymQuiz.Result.WRONG_FIGHT)
	_flags.set_flag(TrainerRules.beaten_flag(&"cinnabar_gym_2"))
	quiz.open_gate(quiz.question_for_trainer(&"cinnabar_gym_2"), _flags)
	assert_true(_flags.has_flag(&"cinnabar_gym_gate_1"), "la victoire ouvre la herse")
	assert_false(quiz.should_ask(1, _flags))
	assert_eq(quiz.resolve(1, true, _flags), GymQuiz.Result.ALREADY_OPEN)


func test_quiz_wrong_answer_after_trainer_beaten() -> void:
	var quiz := GymQuiz.load_default()
	_flags.set_flag(TrainerRules.beaten_flag(&"cinnabar_gym_3"))
	assert_eq(quiz.resolve(2, true, _flags), GymQuiz.Result.WRONG_ALREADY_BEATEN)
	assert_eq(quiz.resolve(9, true, _flags), GymQuiz.Result.UNKNOWN)


func test_quiz_rejects_bad_file() -> void:
	var quiz := GymQuiz.new()
	assert_false(quiz.load_file("res://tests/fixtures/trades/absent.json"))
	assert_eq(quiz.get_errors().size(), 1)


func test_real_trade_file_loads() -> void:
	var trade := InGameTrade.load_default()
	assert_eq(trade.get_errors().size(), 0)
	assert_eq(trade.ids().size(), 3)
	assert_eq(str(trade.get_trade(&"cinnabar_trade_seel")["nickname"]), "Bibi")


# --- Échanges fixes ---------------------------------------------------------------------------

func _party(species: Array[StringName], level: int = 20) -> Party:
	var party := Party.new()
	for s: StringName in species:
		var p := PokemonFactory.create(_data, s, level, _rng)
		p.ensure_uid()
		party.add(p)
	return party


func test_trade_swaps_in_place_with_same_level() -> void:
	var trade := InGameTrade.new()
	assert_true(trade.load_file(TRADES))
	var party := _party([&"pidgey", &"raichu", &"rattata"])
	party.get_at(1).level = 31
	var dex := Pokedex.new()
	assert_eq(trade.candidates(&"test_trade_rattata", party), [1] as Array[int])
	var r := trade.execute(&"test_trade_rattata", 1, party, dex, _flags, _data, _rng, &"cinnabar_lab_reunion")
	assert_eq(r["status"], InGameTrade.Status.DONE)
	assert_eq(party.size(), 3, "taille d'équipe inchangée")
	var received: Pokemon = party.get_at(1)
	assert_eq(received.species_id, &"rattata")
	assert_eq(received.level, 31, "niveau du Pokémon donné")
	assert_eq(received.nickname, "Kourjus")
	assert_eq(received.original_trainer, "Hector")
	assert_eq(received.hp, received.max_hp(), "PV pleins")
	assert_eq(party.get_at(0).species_id, &"pidgey")
	assert_true(dex.is_caught(&"rattata"))
	assert_true(_flags.has_flag(&"test_trade_rattata_done"))


func test_trade_only_once() -> void:
	var trade := InGameTrade.new()
	trade.load_file(TRADES)
	var party := _party([&"raichu", &"raichu"])
	assert_eq(trade.execute(&"test_trade_rattata", 0, party, null, _flags, _data, _rng)["status"],
		InGameTrade.Status.DONE)
	var r := trade.execute(&"test_trade_rattata", 1, party, null, _flags, _data, _rng)
	assert_eq(r["status"], InGameTrade.Status.ALREADY_DONE)
	assert_eq(party.get_at(1).species_id, &"raichu", "rien ne change")


func test_trade_refuses_wrong_species_and_changes_nothing() -> void:
	var trade := InGameTrade.new()
	trade.load_file(TRADES)
	var party := _party([&"pidgey"])
	var before := party.get_at(0)
	assert_eq(trade.candidates(&"test_trade_rattata", party), [] as Array[int])
	var r := trade.execute(&"test_trade_rattata", 0, party, null, _flags, _data, _rng)
	assert_eq(r["status"], InGameTrade.Status.WRONG_SPECIES)
	assert_eq(party.get_at(0), before)
	assert_false(_flags.has_flag(&"test_trade_rattata_done"))
	assert_eq(trade.execute(&"test_trade_rattata", 5, party, null, _flags, _data, _rng)["status"],
		InGameTrade.Status.INVALID, "index hors équipe")


func test_trade_unknown_received_species_changes_nothing() -> void:
	var trade := InGameTrade.new()
	trade.load_file(TRADES)
	var party := _party([&"rattata"])
	var before := party.get_at(0)
	var r := trade.execute(&"test_trade_unknown", 0, party, null, _flags, _data, _rng)
	assert_eq(r["status"], InGameTrade.Status.INVALID)
	assert_eq(party.get_at(0), before)
	assert_false(_flags.has_flag(&"test_trade_unknown_done"))


func test_trade_of_the_companion_is_reported() -> void:
	var trade := InGameTrade.new()
	trade.load_file(TRADES)
	var party := _party([&"raichu"])
	var uid := party.get_at(0).uid
	var r := trade.execute(&"test_trade_rattata", 0, party, null, _flags, _data, _rng, &"", "", uid)
	assert_true(r["companion_cleared"])
	assert_ne(party.get_at(0).uid, uid, "le Pokémon reçu a son propre identifiant")
