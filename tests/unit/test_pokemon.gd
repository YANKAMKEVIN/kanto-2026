extends GutTest
## Pokemon et MoveSlot : PV, PP, apprentissage (4 au maximum), XP et niveaux, évolution,
## aller-retour to_dict / from_dict (jalon 4 §2.1 et décisions de Kevin du §8).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
## Six IV à 0 puis un tirage de sexe (mâle).
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _create(species: StringName, level: int, draws: Array[int] = IV_0) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(draws))


func _ids(pokemon: Pokemon) -> Array[StringName]:
	var result: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		result.append(slot.move_id)
	return result


# --- PV et PP ---------------------------------------------------------------------------

func test_damage_is_bounded_and_faints_at_zero() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.max_hp(), 18)
	assert_eq(charmander.take_damage(5), 5)
	assert_eq(charmander.hp, 13)
	assert_false(charmander.is_fainted())
	assert_eq(charmander.take_damage(50), 13, "seuls les PV restants sont perdus")
	assert_eq(charmander.hp, 0)
	assert_true(charmander.is_fainted())
	assert_eq(charmander.take_damage(-3), 0, "dégâts négatifs ignorés")


func test_heal_full_restores_hp_and_pp() -> void:
	var charmander := _create(&"charmander", 5)
	charmander.take_damage(10)
	assert_true(charmander.moves[0].use())
	assert_eq(charmander.moves[0].pp, 34)
	charmander.heal_full()
	assert_eq(charmander.hp, 18)
	assert_eq(charmander.moves[0].pp, 35)


func test_move_slot_use_stops_at_zero() -> void:
	var slot := MoveSlot.new(&"tackle", 1)
	assert_true(slot.use())
	assert_false(slot.use())
	assert_eq(slot.pp, 0)
	slot.restore()
	assert_eq(slot.pp, 1)


func test_display_name_uses_the_nickname_first() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.display_name(_data), "Salamèche")
	charmander.nickname = "Braise"
	assert_eq(charmander.display_name(_data), "Braise")


# --- Apprentissage ----------------------------------------------------------------------

func test_learn_move_in_a_free_slot_or_already_known() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.learn_move(&"ember", _data), Pokemon.LearnResult.LEARNED)
	assert_eq(_ids(charmander), [&"scratch", &"growl", &"ember"] as Array[StringName])
	assert_eq(charmander.moves[2].pp, 25, "PP pleins")
	assert_eq(charmander.learn_move(&"ember", _data), Pokemon.LearnResult.ALREADY_KNOWN)
	assert_eq(charmander.moves.size(), 3)


func test_fifth_move_needs_a_choice_and_changes_nothing() -> void:
	var charmander := _create(&"charmander", 30)
	assert_eq(_ids(charmander), [&"ember", &"leer", &"rage", &"slash"] as Array[StringName])
	assert_eq(charmander.learn_move(&"flamethrower", _data), Pokemon.LearnResult.NEEDS_FORGET)
	assert_eq(_ids(charmander), [&"ember", &"leer", &"rage", &"slash"] as Array[StringName])
	assert_true(charmander.replace_move(2, &"flamethrower", _data))
	assert_eq(_ids(charmander), [&"ember", &"leer", &"flamethrower", &"slash"]
		as Array[StringName])
	assert_eq(charmander.moves[2].pp, 15)


func test_invalid_learning_is_refused() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.learn_move(&"splash", _data), Pokemon.LearnResult.INVALID)
	assert_push_error("capacité inconnue")
	assert_false(charmander.replace_move(5, &"ember", _data), "emplacement absent")
	assert_false(charmander.replace_move(0, &"growl", _data), "déjà connue")
	assert_false(charmander.replace_move(0, &"splash", _data), "inconnue")
	assert_push_error_count(4)
	assert_eq(_ids(charmander), [&"scratch", &"growl"] as Array[StringName])


# --- XP et niveaux ----------------------------------------------------------------------

func test_new_pokemon_has_the_exp_of_its_level() -> void:
	assert_eq(_create(&"charmander", 5).experience, 135)
	assert_eq(_create(&"charmander", 1).experience, 0)


func test_gain_exp_without_level_up() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.gain_exp(43, _data).size(), 0, "179 XP pour le niveau 6")
	assert_eq(charmander.experience, 178)
	assert_eq(charmander.level, 5)
	assert_eq(charmander.gain_exp(0, _data).size(), 0)


func test_gain_exp_climbs_several_levels_and_lists_new_moves() -> void:
	var charmander := _create(&"charmander", 5)
	charmander.take_damage(4)
	# Niveau 9 à 419 XP (medium_slow) : 419 − 135 = 284.
	var steps := charmander.gain_exp(284, _data)
	assert_eq(steps.size(), 4)
	assert_eq([steps[0].level, steps[3].level], [6, 9])
	assert_eq(steps[0].moves.size(), 0)
	assert_eq(steps[3].moves, [&"ember"] as Array[StringName], "Flammèche au niveau 9")
	assert_eq(charmander.level, 9)
	assert_eq(charmander.experience, 419)
	assert_eq(_ids(charmander), [&"scratch", &"growl"] as Array[StringName],
		"rien n'est appris d'office")
	# PV max N9, IV 0 : ⌊78·9/100⌋ + 19 = 26 ; les 4 PV perdus le restent.
	assert_eq(charmander.max_hp(), 26)
	assert_eq(charmander.hp, 22)
	var gained := 0
	for step: LevelUp in steps:
		gained += step.stat_gains[&"hp"]
	assert_eq(gained, 26 - 18)


func test_exp_is_capped_at_level_100() -> void:
	var cap := ExpCurve.exp_for_level(ExpCurve.Rate.MEDIUM_SLOW, 100)
	var charizard := _create(&"charizard", 99)
	var steps := charizard.gain_exp(10000000, _data)
	assert_eq(steps.size(), 1)
	assert_eq(charizard.level, 100)
	assert_eq(charizard.experience, cap)
	assert_eq(charizard.gain_exp(500, _data).size(), 0)
	assert_eq(charizard.experience, cap)


# --- Évolution --------------------------------------------------------------------------

func test_evolution_at_16_keeps_everything_but_the_species() -> void:
	var charmander := _create(&"charmander", 15)
	charmander.moves[0].use()
	# Niveau 16 à 2535 XP.
	charmander.gain_exp(2535 - charmander.experience, _data)
	assert_eq(charmander.level, 16)
	assert_eq(charmander.max_hp(), 38, "⌊78·16/100⌋ + 26")
	charmander.take_damage(10)
	assert_eq(Evolution.level_up_target(charmander, _data), &"charmeleon")
	var moves_before := _ids(charmander)
	assert_true(charmander.evolve_into(&"charmeleon", _data))
	assert_eq(charmander.species_id, &"charmeleon")
	assert_eq(charmander.display_name(_data), "Reptincel")
	assert_eq(charmander.level, 16)
	assert_eq(charmander.experience, 2535)
	assert_eq(_ids(charmander), moves_before)
	assert_eq(charmander.moves[0].pp, charmander.moves[0].max_pp - 1, "PP gardés")
	assert_eq(charmander.ivs[&"atk"], 0)
	# Reptincel N16, IV 0 : PV ⌊116·16/100⌋ + 26 = 44 ; Atq ⌊128·0,16⌋ + 5 = 25.
	assert_eq(charmander.max_hp(), 44)
	assert_eq(charmander.hp, 34, "10 PV perdus conservés")
	assert_eq(charmander.stats[&"atk"], 25)


func test_evolve_into_unknown_species_is_refused() -> void:
	var charmander := _create(&"charmander", 5)
	assert_false(charmander.evolve_into(&"mewthree", _data))
	assert_push_error("espèce inconnue")
	assert_eq(charmander.species_id, &"charmander")


func test_fainted_pokemon_stays_fainted_after_recalc() -> void:
	var charmander := _create(&"charmander", 15)
	charmander.take_damage(100)
	charmander.gain_exp(2535 - charmander.experience, _data)
	assert_eq(charmander.hp, 0)


# --- Sauvegarde -------------------------------------------------------------------------

func test_to_dict_round_trip() -> void:
	var squirtle := _create(&"squirtle", 5, [5, 10, 15, 20, 25, 30, 900])
	squirtle.nickname = "Bulle"
	squirtle.take_damage(3)
	squirtle.moves[1].use()
	squirtle.gain_exp(20, _data)
	var dict := squirtle.to_dict()
	assert_eq(dict["species"], "squirtle")
	assert_eq(dict["gender"], "female")
	assert_eq(dict["ivs"]["atk"], 9)
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(dict)), _data)
	assert_not_null(copy)
	assert_eq(copy.to_dict(), dict)
	assert_eq(copy.stats, squirtle.stats)
	assert_eq(copy.hp, squirtle.hp)
	assert_eq(copy.moves[1].pp, 29)


func test_meeting_data_round_trip() -> void:
	var charmander := _create(&"charmander", 5)
	assert_eq(charmander.origin, Pokemon.Origin.UNKNOWN)
	assert_eq(charmander.met_level, 0)
	charmander.record_meeting(Pokemon.Origin.STARTER, &"oak_lab", "2026-10-02T14:03:05", "Kevin")
	charmander.gain_exp(500, _data)
	assert_eq(charmander.met_level, 5, "le niveau de la rencontre ne bouge plus")
	var dict := charmander.to_dict()
	assert_eq(dict["met"], {"origin": "starter", "map": "oak_lab", "level": 5,
		"date": "2026-10-02T14:03:05", "trainer": "Kevin"})
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(dict)), _data)
	assert_eq(copy.origin, Pokemon.Origin.STARTER)
	assert_eq(copy.met_map, &"oak_lab")
	assert_eq(copy.met_level, 5)
	assert_eq(copy.met_date, "2026-10-02T14:03:05")
	assert_eq(copy.original_trainer, "Kevin")
	assert_eq(copy.to_dict(), dict)


func test_missing_or_unknown_meeting_data_falls_back_to_defaults() -> void:
	var dict := _create(&"squirtle", 5).to_dict()
	dict.erase("met")
	var copy := Pokemon.from_dict(dict, _data)
	assert_not_null(copy, "une sauvegarde d'avant le 5C.5 se charge")
	assert_eq(copy.origin, Pokemon.Origin.UNKNOWN)
	assert_eq(copy.met_map, &"")
	dict["met"] = {"origin": "trade", "level": 999, "map": 3}
	copy = Pokemon.from_dict(dict, _data)
	assert_eq(copy.origin, Pokemon.Origin.UNKNOWN, "manière inconnue → inconnue")
	assert_eq(copy.met_level, 100, "niveau borné")
	assert_eq(copy.met_map, &"")


func test_favorite_round_trip_and_default() -> void:
	# Jalon 6, T0 (jalon-06.md §5.1) : favori posé dans la sauvegarde v2.
	var squirtle := _create(&"squirtle", 5)
	assert_false(squirtle.favorite, "pas favori à la création")
	assert_eq(squirtle.to_dict()["favorite"], false)
	squirtle.favorite = true
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(squirtle.to_dict())), _data)
	assert_true(copy.favorite)
	assert_eq(copy.to_dict(), squirtle.to_dict())
	assert_true(squirtle.evolve_into(&"wartortle", _data))
	assert_true(squirtle.favorite, "l'évolution garde le favori")
	var dict := squirtle.to_dict()
	dict.erase("favorite")
	assert_false(Pokemon.from_dict(dict, _data).favorite, "sauvegarde v1 : faux")
	dict["favorite"] = "oui"
	assert_false(Pokemon.from_dict(dict, _data).favorite, "mal formé : faux, sans erreur")


# --- Statut (jalon 9, T2 : sauvegarde v4) ---------------------------------------------

func test_a_new_pokemon_has_no_status() -> void:
	var charmander := _create(&"charmander", 9)
	assert_eq(charmander.status, StatusRules.NONE)
	assert_false(charmander.has_status(StatusRules.POISON))
	assert_false(charmander.has_status(StatusRules.NONE), "« aucun » n'est pas un statut")
	assert_eq(charmander.to_dict()["status"], "", "écrit vide")


func test_cure_status_returns_the_cured_status() -> void:
	var charmander := _create(&"charmander", 9)
	charmander.status = StatusRules.POISON
	assert_true(charmander.has_status(StatusRules.POISON))
	assert_eq(charmander.cure_status(), StatusRules.POISON)
	assert_eq(charmander.status, StatusRules.NONE)
	assert_eq(charmander.cure_status(), StatusRules.NONE, "rien à soigner")


func test_heal_full_also_cures_the_status() -> void:
	var charmander := _create(&"charmander", 9)
	charmander.take_damage(5)
	charmander.status = StatusRules.POISON
	charmander.heal_full()
	assert_eq(charmander.hp, charmander.max_hp())
	assert_eq(charmander.status, StatusRules.NONE, "Centre, Maman, réveil : statut effacé")


func test_status_round_trip() -> void:
	var charmander := _create(&"charmander", 9)
	charmander.take_damage(4)
	charmander.status = StatusRules.POISON
	var dict := charmander.to_dict()
	assert_eq(dict["status"], "poison")
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(dict)), _data)
	assert_eq(copy.status, StatusRules.POISON)
	assert_eq(copy.hp, charmander.hp)
	assert_eq(copy.to_dict(), dict)
	assert_true(charmander.evolve_into(&"charmeleon", _data))
	assert_eq(charmander.status, StatusRules.POISON, "l'évolution garde le statut")


func test_missing_status_means_none_without_warning() -> void:
	# Sauvegarde v3 (jalon 7) : pas de clé « status ».
	var dict := _create(&"charmander", 9).to_dict()
	dict.erase("status")
	var copy := Pokemon.from_dict(dict, _data)
	assert_not_null(copy, "un Pokémon v3 se charge")
	assert_eq(copy.status, StatusRules.NONE)
	assert_push_warning_count(0)


func test_unknown_or_malformed_status_is_dropped_with_a_warning_never_refused() -> void:
	var dict := _create(&"charmander", 9).to_dict()
	for odd: Variant in ["paralysis", 3, null, ["poison"]]:
		dict["status"] = odd
		var copy := Pokemon.from_dict(dict, _data)
		assert_not_null(copy, "statut %s : le Pokémon est gardé" % [odd])
		assert_eq(copy.status, StatusRules.NONE, "statut %s : aucun" % [odd])
	assert_push_warning_count(4)
	assert_push_error_count(0)


func test_from_dict_rejects_invalid_content() -> void:
	var dict := _create(&"squirtle", 5).to_dict()
	var bad := dict.duplicate(true)
	bad["species"] = "missingno"
	assert_null(Pokemon.from_dict(bad, _data))
	bad = dict.duplicate(true)
	bad["level"] = 101
	assert_null(Pokemon.from_dict(bad, _data))
	bad = dict.duplicate(true)
	bad["moves"] = []
	assert_null(Pokemon.from_dict(bad, _data))
	bad = dict.duplicate(true)
	bad["ivs"]["hp"] = 32
	assert_null(Pokemon.from_dict(bad, _data))
	bad = dict.duplicate(true)
	bad["moves"][0]["id"] = "splash"
	assert_null(Pokemon.from_dict(bad, _data))
	assert_push_error_count(5)
