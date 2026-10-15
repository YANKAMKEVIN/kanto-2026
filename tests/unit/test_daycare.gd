extends GutTest
## Pension Pokémon, logique pure (J15, 15.0 ; dossier 18 : V-1, V-2, F-1 à F-4, §6, décisions
## de Kevin du 2026-10-11) : Daycare, DaycareRules, DaycareConfig.

const OK := DaycareRules.Status.OK

var _data: PokemonData
var _rng: GameRng
var _config: DaycareConfig
var _party: Party
var _daycare: Daycare


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(15)
	_config = DaycareConfig.new()
	assert_true(_config.load_file(), "data/daycare/daycare.json se charge")
	_party = Party.new()
	_daycare = Daycare.new()


func _mon(species: StringName = &"rattata", level: int = 5) -> Pokemon:
	return PokemonFactory.create(_data, species, level, _rng)


## Équipe de [param count] Rattata, puis dépôt de [param mon] (ajouté en tête).
func _deposit(mon: Pokemon, others: int = 1) -> void:
	_party.add(mon)
	for i: int in others:
		_party.add(_mon(&"rattata", 3 + i))
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), OK)


## XP qu'il faut à [param mon] pour atteindre [param level].
func _exp_to(mon: Pokemon, level: int) -> int:
	var rate := _data.get_species(mon.species_id).growth_rate
	return ExpCurve.exp_for_level(rate, level) - mon.experience


# --- Données ---------------------------------------------------------------------------------

func test_config_reads_the_validated_values() -> void:
	assert_eq(_config.exp_per_step, 1, "F-1 : 1 XP par pas")
	assert_eq(_config.price_base, 100, "F-2")
	assert_eq(_config.price_per_level, 100, "F-2")
	assert_eq(_config.money_policy, DaycareConfig.MoneyPolicy.TAKE_ALL, "F-2 : tout l'argent")
	assert_true(_config.evolve_on_withdraw, "F-3")
	assert_eq(_config.get_errors().size(), 0)


func test_config_refuses_unknown_or_missing_keys_and_keeps_its_values() -> void:
	var config := DaycareConfig.new()
	config.price_base = 7
	assert_false(config.set_from_dict({"exp_per_step": 1, "oops": 2}))
	assert_false(config.set_from_dict({"exp_per_step": 1}))
	assert_false(config.set_from_dict({"exp_per_step": -1, "price_base": 1,
		"price_per_level": 1, "money_policy": "take_all", "evolve_on_withdraw": true}))
	assert_false(config.set_from_dict({"exp_per_step": 1, "price_base": 1,
		"price_per_level": 1, "money_policy": "free", "evolve_on_withdraw": true}))
	assert_eq(config.price_base, 7, "rien ne change sur une erreur")
	assert_eq(config.get_errors().size(), 4)
	assert_push_error_count(4)


# --- Dépôt -----------------------------------------------------------------------------------

func test_deposit_moves_the_same_instance_and_notes_its_level() -> void:
	var mon := _mon(&"pidgey", 8)
	_party.add(mon)
	_party.add(_mon())
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), OK)
	assert_same(_daycare.pokemon, mon)
	assert_eq(_party.size(), 1)
	assert_eq(_daycare.deposit_level, 8)
	assert_eq(_daycare.pending_exp, 0)


func test_deposit_of_the_last_able_pokemon_is_refused() -> void:
	var able := _mon()
	var fainted := _mon()
	fainted.take_damage(fainted.hp)
	_party.add(able)
	_party.add(fainted)
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), DaycareRules.Status.LAST_ABLE)
	assert_eq(_party.size(), 2, "rien ne change")
	assert_true(_daycare.is_empty())


func test_deposit_of_the_only_pokemon_is_refused() -> void:
	_party.add(_mon())
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data),
		DaycareRules.Status.LAST_POKEMON)
	assert_true(_daycare.is_empty())


func test_a_fainted_pokemon_can_be_deposited() -> void:
	var fainted := _mon()
	fainted.take_damage(fainted.hp)
	_party.add(fainted)
	_party.add(_mon())
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), OK)
	assert_same(_daycare.pokemon, fainted)
	assert_true(fainted.is_fainted(), "pas de soin au dépôt")


func test_deposit_is_refused_when_the_daycare_is_occupied() -> void:
	_deposit(_mon(), 2)
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), DaycareRules.Status.OCCUPIED)
	assert_eq(_party.size(), 2)


func test_deposit_of_a_missing_place_is_refused() -> void:
	_party.add(_mon())
	assert_eq(DaycareRules.deposit(_daycare, _party, 3, _data), DaycareRules.Status.NOT_FOUND)


# --- Pas -------------------------------------------------------------------------------------

func test_steps_accumulate_pending_exp_without_touching_the_pokemon() -> void:
	var mon := _mon(&"rattata", 5)
	var exp_before := mon.experience
	_deposit(mon)
	assert_eq(_daycare.add_steps(10, _config), 10)
	assert_eq(_daycare.add_steps(1, _config), 1)
	assert_eq(_daycare.add_steps(500, _config), 500)
	assert_eq(_daycare.pending_exp, 511)
	assert_eq(mon.experience, exp_before, "l'XP reste en attente")
	assert_eq(mon.level, 5, "rien pendant le séjour")


func test_steps_follow_exp_per_step() -> void:
	_config.exp_per_step = 3
	_deposit(_mon())
	assert_eq(_daycare.add_steps(4, _config), 12)


func test_no_step_no_exp_and_empty_daycare_ignores_steps() -> void:
	assert_eq(_daycare.add_steps(50, _config), 0, "Pension vide")
	_deposit(_mon())
	assert_eq(_daycare.add_steps(0, _config), 0)
	assert_eq(_daycare.add_steps(-3, _config), 0)
	assert_eq(_daycare.pending_exp, 0)
	assert_eq(_daycare.levels_gained(_data), 0)


func test_pending_exp_is_capped_at_level_100() -> void:
	var mon := _mon(&"rattata", 98)
	_deposit(mon)
	var room := _exp_to(mon, 100)
	assert_eq(_daycare.add_steps(room + 5000, _config), room)
	assert_eq(_daycare.add_steps(1, _config), 0, "plafond atteint")
	assert_eq(_daycare.level_after(_data), 100)
	var plan := DaycareRules.withdraw(_daycare, _party, 999_999, _config, _data)
	assert_eq(mon.level, 100)
	assert_eq(plan.levels_gained(), 2)


func test_a_level_100_pokemon_gains_nothing() -> void:
	_deposit(_mon(&"rattata", 100))
	assert_eq(_daycare.add_steps(1000, _config), 0)
	var preview := DaycareRules.preview(_daycare, _party, 1000, _config, _data)
	assert_eq(preview.levels_gained, 0)
	assert_eq(preview.price, 100)


# --- Aperçu et prix --------------------------------------------------------------------------

func test_price_is_base_plus_per_level() -> void:
	assert_eq(DaycareRules.price(0, _config), 100)
	assert_eq(DaycareRules.price(1, _config), 200)
	assert_eq(DaycareRules.price(7, _config), 800)


func test_preview_with_no_level_gained() -> void:
	var mon := _mon(&"rattata", 10)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 11) - 1, _config)
	var preview := DaycareRules.preview(_daycare, _party, 3000, _config, _data)
	assert_true(preview.is_ok())
	assert_same(preview.pokemon, mon)
	assert_eq(preview.levels_gained, 0)
	assert_eq(preview.level_after, 10)
	assert_eq(preview.price, 100)
	assert_eq(preview.paid, 100)
	assert_false(preview.is_short())


func test_preview_with_one_level_gained() -> void:
	var mon := _mon(&"rattata", 10)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 11), _config)
	var preview := DaycareRules.preview(_daycare, _party, 3000, _config, _data)
	assert_eq(preview.levels_gained, 1)
	assert_eq(preview.price, 200)


func test_preview_changes_nothing_and_matches_the_real_withdrawal() -> void:
	var mon := _mon(&"pidgey", 6)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 13) + 40, _config)
	var exp_before := mon.experience
	var preview := DaycareRules.preview(_daycare, _party, 5000, _config, _data)
	assert_eq(mon.experience, exp_before, "aperçu non destructif")
	assert_eq(mon.level, 6)
	assert_false(_daycare.is_empty())
	assert_eq(preview.levels_gained, 7)
	assert_eq(preview.price, 800)
	var plan := DaycareRules.withdraw(_daycare, _party, 5000, _config, _data)
	assert_true(plan.is_ok())
	assert_eq(mon.level, preview.level_after)
	assert_eq(plan.levels_gained(), preview.levels_gained)
	assert_eq(plan.price, preview.price)
	assert_eq(plan.paid, preview.paid)


# --- Retrait ---------------------------------------------------------------------------------

func test_withdraw_applies_pending_exp_through_gain_exp() -> void:
	var mon := _mon(&"rattata", 5)
	var exp_before := mon.experience
	_deposit(mon)
	var pending := _exp_to(mon, 8) + 3
	_daycare.add_steps(pending, _config)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_true(plan.is_ok())
	assert_same(plan.pokemon, mon)
	assert_eq(mon.level, 8)
	assert_eq(mon.experience, exp_before + pending, "toute l'XP en attente, une seule fois")
	assert_eq(plan.level_ups.size(), 3)
	assert_eq(plan.level_ups[0].level, 6)
	assert_eq(plan.level_ups[2].level, 8)
	assert_true(_daycare.is_empty(), "la Pension est vide")
	assert_eq(_daycare.pending_exp, 0)
	assert_same(_party.get_at(_party.size() - 1), mon, "en fin d'équipe")


func test_withdraw_on_an_empty_daycare_is_refused() -> void:
	_party.add(_mon())
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.EMPTY)
	assert_null(plan.pokemon)
	assert_eq(_party.size(), 1)


func test_withdraw_with_a_full_party_is_refused_and_nothing_changes() -> void:
	var mon := _mon()
	_deposit(mon, 1)
	for i: int in 5:
		_party.add(_mon())
	assert_true(_party.is_full())
	_daycare.add_steps(800, _config)
	var exp_before := mon.experience
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.PARTY_FULL)
	assert_eq(plan.paid, 0)
	assert_same(_daycare.pokemon, mon, "toujours gardé")
	assert_eq(_daycare.pending_exp, 800)
	assert_eq(mon.experience, exp_before)
	assert_eq(DaycareRules.preview(_daycare, _party, 3000, _config, _data).status,
		DaycareRules.Status.PARTY_FULL, "le gardien le sait avant la confirmation")


func test_not_enough_money_takes_it_all_and_returns_the_pokemon() -> void:
	var mon := _mon(&"rattata", 10)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 12), _config)
	var preview := DaycareRules.preview(_daycare, _party, 150, _config, _data)
	assert_true(preview.is_ok())
	assert_eq(preview.price, 300)
	assert_eq(preview.paid, 150)
	assert_true(preview.is_short())
	var plan := DaycareRules.withdraw(_daycare, _party, 150, _config, _data)
	assert_true(plan.is_ok(), "rendu quand même (F-2)")
	assert_eq(plan.price, 300)
	assert_eq(plan.paid, 150, "tout l'argent du joueur")
	assert_same(_party.get_at(_party.size() - 1), mon)


func test_withdraw_with_no_money_at_all_is_free() -> void:
	_deposit(_mon())
	var plan := DaycareRules.withdraw(_daycare, _party, 0, _config, _data)
	assert_true(plan.is_ok())
	assert_eq(plan.paid, 0)


func test_refuse_policy_refuses_without_change() -> void:
	_config.money_policy = DaycareConfig.MoneyPolicy.REFUSE
	var mon := _mon()
	_deposit(mon)
	var plan := DaycareRules.withdraw(_daycare, _party, 99, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.NO_MONEY)
	assert_same(_daycare.pokemon, mon)
	assert_eq(DaycareRules.payment(99, 100, _config), 0)
	assert_eq(DaycareRules.payment(100, 100, _config), 100)


func test_payment_is_the_price_when_money_suffices() -> void:
	assert_eq(DaycareRules.payment(5000, 300, _config), 300)
	assert_eq(DaycareRules.payment(300, 300, _config), 300)
	assert_eq(DaycareRules.payment(299, 300, _config), 299)


func test_withdraw_heals_fully() -> void:
	var mon := _mon(&"weedle", 5)
	_party.add(mon)
	_party.add(_mon())
	mon.take_damage(mon.hp)
	mon.status = StatusRules.POISON
	mon.moves[0].pp = 0
	assert_eq(DaycareRules.deposit(_daycare, _party, 0, _data), OK)
	_daycare.add_steps(_exp_to(mon, 6), _config)
	DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(mon.hp, mon.max_hp(), "PV pleins (après la montée de niveau)")
	assert_eq(mon.status, StatusRules.NONE, "statut effacé")
	assert_eq(mon.moves[0].pp, mon.moves[0].max_pp, "PP rendus")


func test_withdraw_heals_even_without_level_gained() -> void:
	var mon := _mon()
	_party.add(mon)
	_party.add(_mon())
	mon.take_damage(mon.hp - 1)
	DaycareRules.deposit(_daycare, _party, 0, _data)
	DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(mon.hp, mon.max_hp())


# --- Capacités et évolution ------------------------------------------------------------------

func test_moves_due_on_several_levels_are_listed_in_order_and_not_learned() -> void:
	var mon := _mon(&"bulbasaur", 5)
	var known := mon.moves.size()
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 14), _config)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.moves, [&"leech_seed", &"vine_whip"] as Array[StringName],
		"Vampigraine (7) puis Fouet Lianes (13)")
	assert_eq(mon.moves.size(), known, "rien n'est appris : le joueur choisira (V-2)")
	assert_false(mon.knows_move(&"leech_seed"))


func test_no_move_offered_without_a_level() -> void:
	var mon := _mon(&"bulbasaur", 5)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 6), _config)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.moves.size(), 0)


func test_evolution_is_offered_only_when_the_level_is_reached() -> void:
	var below := _mon(&"caterpie", 5)
	_deposit(below)
	_daycare.add_steps(_exp_to(below, 6), _config)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(below.level, 6)
	assert_eq(plan.evolution, &"", "seuil (7) pas atteint")
	assert_eq(below.species_id, &"caterpie")

	var reached := _mon(&"caterpie", 5)
	_party.add(reached)
	DaycareRules.deposit(_daycare, _party, _party.size() - 1, _data)
	_daycare.add_steps(_exp_to(reached, 9), _config)
	plan = DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(reached.level, 9)
	assert_eq(plan.evolution, &"metapod", "proposée au retrait (F-3)")
	assert_eq(reached.species_id, &"caterpie", "proposée, pas jouée")


func test_no_evolution_offered_without_a_level_gained() -> void:
	var mon := _mon(&"caterpie", 8)  # déjà au-delà du seuil (évolution annulée en combat)
	_deposit(mon)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.evolution, &"", "comme en combat : au prochain niveau gagné")


func test_evolution_can_be_disabled_by_data() -> void:
	_config.evolve_on_withdraw = false
	var mon := _mon(&"caterpie", 5)
	_deposit(mon)
	_daycare.add_steps(_exp_to(mon, 8), _config)
	var plan := DaycareRules.withdraw(_daycare, _party, 3000, _config, _data)
	assert_eq(plan.evolution, &"")


# --- Sauvegarde préparée (v7, non branchée) --------------------------------------------------

func test_to_dict_from_dict_round_trip() -> void:
	var mon := _mon(&"pidgey", 9)
	mon.nickname = "Plume"
	_deposit(mon)
	_daycare.add_steps(321, _config)
	var json := JSON.stringify(_daycare.to_dict())
	var parsed: Variant = JSON.parse_string(json)
	var copy := Daycare.from_dict(parsed, _data)
	assert_not_null(copy)
	assert_false(copy.is_empty())
	assert_eq(copy.pending_exp, 321)
	assert_eq(copy.deposit_level, 9)
	assert_eq(copy.exp_room, _daycare.exp_room)
	assert_eq(copy.pokemon.to_dict(), mon.to_dict())
	assert_eq(DaycareRules.preview(copy, _party, 3000, _config, _data).level_after,
		DaycareRules.preview(_daycare, _party, 3000, _config, _data).level_after)


func test_empty_daycare_round_trip() -> void:
	assert_eq(_daycare.to_dict(), {})
	var copy := Daycare.from_dict({}, _data)
	assert_not_null(copy)
	assert_true(copy.is_empty())


func test_from_dict_clamps_pending_exp_and_rejects_an_invalid_pokemon() -> void:
	var mon := _mon(&"rattata", 99)
	_deposit(mon)
	var dict := _daycare.to_dict()
	dict["pending_exp"] = 99_999_999
	dict["deposit_level"] = 120
	var copy := Daycare.from_dict(dict, _data)
	assert_eq(copy.pending_exp, copy.exp_room, "plafond du niveau 100")
	assert_eq(copy.deposit_level, 99, "niveau au dépôt invalide → niveau actuel")
	assert_null(Daycare.from_dict({"pokemon": {"species": "nope"}}, _data))
	assert_push_error_count(2)
