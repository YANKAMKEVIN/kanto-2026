extends GutTest
## BadgeMoment : détails du Grand moment « badge » et souvenir de l'équipe (dossier 12 §13,
## arbitrage 12 ; jalon-10.md §2.8, T4).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _data: PokemonData
var _rng: GameRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(12)


func _party() -> Party:
	var party := Party.new()
	var charmander := PokemonFactory.create(_data, &"charmander", 14, _rng)
	charmander.nickname = "Braise"
	party.add(charmander)
	var pidgey := PokemonFactory.create(_data, &"pidgey", 11, _rng)
	pidgey.take_damage(pidgey.hp)
	party.add(pidgey)
	party.add(PokemonFactory.create(_data, &"rattata", 9, _rng))
	return party


func _expected_team() -> Array[Dictionary]:
	return [
		{"species": &"charmander", "level": 14, "nickname": "Braise"},
		{"species": &"pidgey", "level": 11, "nickname": ""},
		{"species": &"rattata", "level": 9, "nickname": ""},
	] as Array[Dictionary]


# --- Détails ---------------------------------------------------------------------------------

func test_details_keep_the_badge_and_the_team_in_order() -> void:
	var party := _party()
	assert_true(party.get_at(1).is_fainted(), "Roucool K.O.")
	var details := BadgeMoment.details(&"boulder", party)
	assert_eq(details.keys(), ["badge", "team"])
	assert_eq(details["badge"], "boulder")
	assert_true(details["badge"] is String, "JSON : une chaîne, pas un StringName")
	var team: Array = details["team"]
	assert_eq(team.size(), 3, "Pokémon K.O. compris")
	assert_eq(team[0], {"species": "charmander", "level": 14, "nickname": "Braise"})
	assert_eq(team[1], {"species": "pidgey", "level": 11, "nickname": ""}, "surnom vide")
	assert_eq(team[2]["species"], "rattata")
	for member: Dictionary in team:
		assert_eq(member.keys(), ["species", "level", "nickname"], "ni formes ni états")
	assert_eq(BadgeMoment.team_of(details), _expected_team())
	assert_eq(BadgeMoment.badge_of(details), &"boulder")


func test_details_are_a_snapshot_never_shared() -> void:
	var party := _party()
	var first := BadgeMoment.details(&"boulder", party)
	var second := BadgeMoment.details(&"boulder", party)
	(first["team"] as Array)[0]["level"] = 99
	assert_eq((second["team"] as Array)[0]["level"], 14, "un tableau neuf à chaque appel")
	party.get_at(0).level = 30
	party.get_at(0).nickname = "Autre"
	assert_eq((second["team"] as Array)[0]["level"], 14, "souvenir figé")
	assert_eq((second["team"] as Array)[0]["nickname"], "Braise")


func test_details_without_a_party() -> void:
	assert_eq(BadgeMoment.details(&"boulder", Party.new()), {"badge": "boulder", "team": []})
	assert_eq(BadgeMoment.details(&"boulder", null), {"badge": "boulder", "team": []})


# --- Aller-retour réel par la sauvegarde ------------------------------------------------------

## Le format de sauvegarde ne change pas (jalon-10.md §2.8) : un moment enregistré par
## GameState passe par to_dict → JSON → load_dict et redonne la même équipe.
func test_json_round_trip_through_game_state() -> void:
	var state: Node = GameStateScript.new()
	state.clock = FixedClock.new("2026-10-08T17:30:00")
	state.new_game(7)
	var party := _party()
	state.record_moment(BadgeMoment.TYPE, &"pewter_gym", BadgeMoment.details(&"boulder", party))
	var text := JSON.stringify(state.to_dict())
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary)
	var loaded: Node = GameStateScript.new()
	loaded.clock = FixedClock.new("2026-10-09T08:00:00")
	assert_true(loaded.load_dict(parsed, _data))
	var moments: Array[Dictionary] = loaded.moments
	assert_eq(moments.size(), 1)
	assert_eq(moments[0]["type"], "badge")
	assert_eq(moments[0]["map"], "pewter_gym")
	assert_eq(moments[0]["date"], "2026-10-08T17:30:00")
	var details: Dictionary = moments[0]["details"]
	assert_true((details["team"] as Array)[0]["level"] is float, "le JSON rend des flottants")
	assert_eq(BadgeMoment.team_of(details), _expected_team(), "team_of les remet en entiers")
	assert_eq(BadgeMoment.badge_of(details), &"boulder")
	assert_true(BadgeMoment.has_badge_moment(loaded.moments, &"boulder"))
	state.free()
	loaded.free()


# --- Lecture tolérante -----------------------------------------------------------------------

func test_team_of_drops_broken_entries() -> void:
	var details := {"badge": "boulder", "team": [
		"pikachu",
		{"species": "", "level": 5},
		{"species": "onix", "level": 12.5},
		{"species": "onix", "level": 0},
		{"species": "onix", "level": "12"},
		{"species": "onix"},
		{"species": 7, "level": 5},
		{"species": "geodude", "level": 12.0, "nickname": 3},
		{"species": "onix", "level": 14, "nickname": "Roc", "form": "x", "status": "psn"},
	]}
	assert_eq(BadgeMoment.team_of(details), [
		{"species": &"geodude", "level": 12, "nickname": ""},
		{"species": &"onix", "level": 14, "nickname": "Roc"},
	] as Array[Dictionary])


func test_team_of_without_a_team() -> void:
	assert_eq(BadgeMoment.team_of({}), [] as Array[Dictionary])
	assert_eq(BadgeMoment.team_of({"team": "abc"}), [] as Array[Dictionary])
	assert_eq(BadgeMoment.badge_of({}), &"")
	assert_eq(BadgeMoment.badge_of({"badge": 3}), &"")


# --- Un seul moment par badge ----------------------------------------------------------------

func test_has_badge_moment() -> void:
	var moments: Array[Dictionary] = []
	assert_false(BadgeMoment.has_badge_moment(moments, &"boulder"))
	moments.append({"type": "first_capture", "details": {"badge": "boulder"}})
	moments.append({"type": "badge", "details": "boulder"})
	assert_false(BadgeMoment.has_badge_moment(moments, &"boulder"), "autre type, mal formé")
	moments.append({"type": "badge", "details": {"badge": "cascade", "team": []}})
	assert_false(BadgeMoment.has_badge_moment(moments, &"boulder"))
	assert_true(BadgeMoment.has_badge_moment(moments, &"cascade"))
	moments.append({"type": "badge", "details": BadgeMoment.details(&"boulder", _party())})
	assert_true(BadgeMoment.has_badge_moment(moments, &"boulder"))
	assert_false(BadgeMoment.has_badge_moment(moments, &""))
